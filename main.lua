--[[
    Spaghetti Mafia Hub v2.0 (Redesigned - Glassmorphism Edition)
    
    VISUAL OVERHAUL:
    - Theme: Dark Glassmorphism (30,30,30, 0.1 Transp)
    - Font: GothamBold
    - Layout: UIListLayout + Grid
    
    LOGIC: 100% PRESERVED FROM v1.5
]]

--// AUTO EXECUTE / SERVER HOP SUPPORT
if (syn and syn.queue_on_teleport) or queue_on_teleport then
    local teleport_func = syn and syn.queue_on_teleport or queue_on_teleport
    game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Started then
             local source = "loadstring(game:HttpGet('https://raw.githubusercontent.com/Spaghettimafiav1/Spaghettimafiav1/main/main.lua'))()" 
             pcall(function() teleport_func(source) end)
        end
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") 

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// 1. WHITELIST SYSTEM (PRESERVED)
local WHITELIST_URL = "https://raw.githubusercontent.com/Spaghettimafiav1/Spaghettimafiav1/main/Whitelist.txt"

local function CheckWhitelist()
    local success, content = pcall(function()
        return game:HttpGet(WHITELIST_URL .. "?t=" .. tick())
    end)
    
    if success and content then
        if string.find(content, LocalPlayer.Name) then
            print("[SYSTEM] Whitelist Confirmed.")
            return true
        else
            LocalPlayer:Kick("Spaghetti Hub: You are not on the whitelist! ("..LocalPlayer.Name..")")
            return false
        end
    else
        warn("[SYSTEM] Failed to connect to whitelist.")
        return true 
    end
end

if not CheckWhitelist() then return end

--// 2. CLEANUP & VARIABLES
if CoreGui:FindFirstChild("SpaghettiHub_Rel") then CoreGui.SpaghettiHub_Rel:Destroy() end
if CoreGui:FindFirstChild("SpaghettiLoading") then CoreGui.SpaghettiLoading:Destroy() end

-- Updated Theme Colors for the New Design
local Settings = {
    Theme = {
        Gold = Color3.fromRGB(255, 215, 0), 
        Dark = Color3.fromRGB(30, 30, 30), -- Requested Dark Background
        Content = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(255, 255, 255),
        Stroke = Color3.fromRGB(255, 255, 255),
        
        IceBlue = Color3.fromRGB(100, 220, 255),
        ShardBlue = Color3.fromRGB(50, 180, 255),
        CrystalRed = Color3.fromRGB(255, 70, 70),
        Discord = Color3.fromRGB(88, 101, 242)
    },
    Keys = { Menu = Enum.KeyCode.RightControl, Fly = Enum.KeyCode.E, Speed = Enum.KeyCode.F },
    Fly = { Enabled = false, Speed = 50 },
    Speed = { Enabled = false, Value = 16 },
    Farming = false,
    FarmSpeed = 450,
    Scale = 1
}

local VisualToggles = {}
local FarmConnection = nil
local FarmBlacklist = {}
local SitAnimTrack = nil 
local isSittingAction = false 

--// SOUND SYSTEM
local Sounds = {
    Click = "rbxassetid://4612375233",
    FriendJoin = "rbxassetid://5153734247",
    FriendLeft = "rbxassetid://5153734603",
    StormStart = "rbxassetid://4612377184", 
    StormEnd = "rbxassetid://255318536"    
}

local function PlaySound(id)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Parent = CoreGui
    s.Volume = 1.5
    s.PlayOnRemove = true
    s.Name = "SpagAudio"
    s:Destroy()
end

--// 3. UI FUNCTIONS (ADAPTED FOR NEW STYLE)
local Library = {}
function Library:Tween(obj, props, time, style) TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play() end

function Library:Corner(obj, r) 
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r or 10) 
    return c 
end

function Library:Stroke(obj, color, transp, thickness)
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Settings.Theme.Stroke
    s.Transparency = transp or 0.8
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

-- Preserved logic for draggable
function Library:MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    local isDraggingBool = false 
    
    obj.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true 
            dragStart = input.Position 
            startPos = obj.Position 
            isDraggingBool = false
            
            input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                end 
            end) 
        end 
    end)
    
    obj.InputChanged:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseMovement then 
            dragInput = input 
        end 
    end)
    
    RunService.RenderStepped:Connect(function() 
        if dragging and dragInput then 
            local delta = dragInput.Position - dragStart
            if delta.Magnitude > 5 then isDraggingBool = true end 
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
        end 
    end)
    
    return function() return isDraggingBool end 
end

local function SpawnSnow(parent)
    if not parent.Parent or not parent.Visible then return end
    local flake = Instance.new("TextLabel", parent)
    flake.Text = "❄️"
    flake.BackgroundTransparency = 1
    flake.TextColor3 = Color3.fromRGB(255, 255, 255)
    flake.Size = UDim2.new(0, math.random(20, 35), 0, math.random(20, 35))
    flake.Position = UDim2.new(math.random(1, 100)/100, 0, -0.2, 0)
    flake.ZIndex = 1 
    flake.Name = "SnowFlake"
    
    local duration = math.random(4, 7)
    TweenService:Create(flake, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Position = UDim2.new(flake.Position.X.Scale, math.random(-30,30), 1.2, 0),
        Rotation = math.random(180, 360)
    }):Play()
    
    Debris:AddItem(flake, duration)
end

--// HELPER FOR SITTING ANIMATION (PRESERVED)
local function PlaySit(play)
    if play then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            hum.Sit = true
            local animator = hum:FindFirstChild("Animator") or hum:WaitForChild("Animator")
            if not SitAnimTrack then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://2506281703" 
                SitAnimTrack = animator:LoadAnimation(anim)
            end
            SitAnimTrack:Play()
        end
    else
        if SitAnimTrack then
            SitAnimTrack:Stop()
            SitAnimTrack = nil
        end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then hum.Sit = false end
    end
end

--// 4. LOADING SCREEN (Refreshed Style)
local LoadGui = Instance.new("ScreenGui"); LoadGui.Name = "SpaghettiLoading"; LoadGui.Parent = CoreGui
local LoadBox = Instance.new("Frame", LoadGui)
LoadBox.Size = UDim2.new(0, 260, 0, 180)
LoadBox.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadBox.AnchorPoint = Vector2.new(0.5, 0.5)
LoadBox.ClipsDescendants = true 
LoadBox.BorderSizePixel = 0
LoadBox.BackgroundColor3 = Settings.Theme.Dark
LoadBox.BackgroundTransparency = 1 
Library:Corner(LoadBox, 16)
Library:Stroke(LoadBox, Settings.Theme.Gold, 0.5, 2)

TweenService:Create(LoadBox, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()

local PastaIcon = Instance.new("TextLabel", LoadBox)
PastaIcon.Size = UDim2.new(1, 0, 0.45, 0); PastaIcon.Position = UDim2.new(0,0,0.05,0)
PastaIcon.BackgroundTransparency = 1; PastaIcon.Text = "🍝"; PastaIcon.TextSize = 60; PastaIcon.ZIndex = 15
PastaIcon.TextTransparency = 1
TweenService:Create(PastaIcon, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

local TitleLoad = Instance.new("TextLabel", LoadBox)
TitleLoad.Size = UDim2.new(1, 0, 0.2, 0); TitleLoad.Position = UDim2.new(0, 0, 0.50, 0)
TitleLoad.BackgroundTransparency = 1; TitleLoad.Text = "SPAGHETTI HUB"; 
TitleLoad.Font = Enum.Font.GothamBold; TitleLoad.TextColor3 = Settings.Theme.Gold; TitleLoad.TextSize = 20
TitleLoad.ZIndex = 15
TitleLoad.TextTransparency = 1
TweenService:Create(TitleLoad, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {TextTransparency = 0}):Play()

local SubLoad = Instance.new("TextLabel", LoadBox)
SubLoad.Size = UDim2.new(1, 0, 0.2, 0); SubLoad.Position = UDim2.new(0, 0, 0.68, 0)
SubLoad.BackgroundTransparency = 1; 
SubLoad.Text = "Loading Logic..."; 
SubLoad.Font = Enum.Font.GothamBold; SubLoad.TextColor3 = Color3.new(0.8,0.8,0.8); SubLoad.TextSize = 12
SubLoad.ZIndex = 15
SubLoad.TextTransparency = 1
TweenService:Create(SubLoad, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.4), {TextTransparency = 0}):Play()

local LoadingBarBG = Instance.new("Frame", LoadBox)
LoadingBarBG.Size = UDim2.new(0.7, 0, 0, 4)
LoadingBarBG.Position = UDim2.new(0.15, 0, 0.88, 0)
LoadingBarBG.BackgroundColor3 = Color3.fromRGB(50,50,50)
LoadingBarBG.BorderSizePixel = 0
LoadingBarBG.ZIndex = 16
LoadingBarBG.BackgroundTransparency = 1
Library:Corner(LoadingBarBG, 2)
TweenService:Create(LoadingBarBG, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.5), {BackgroundTransparency = 0}):Play()

local LoadingBarFill = Instance.new("Frame", LoadingBarBG)
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Settings.Theme.Gold
LoadingBarFill.BorderSizePixel = 0
LoadingBarFill.ZIndex = 17
Library:Corner(LoadingBarFill, 2)
Library:Tween(LoadingBarFill, {Size = UDim2.new(1, 0, 1, 0)}, 2.5, Enum.EasingStyle.Quad)

task.spawn(function()
    while LoadBox.Parent do
        SpawnSnow(LoadBox)
        task.wait(0.3) 
    end
end)

task.wait(2.5)
TweenService:Create(LoadBox, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
task.wait(0.3)
LoadGui:Destroy()

--// FRIEND ALERTS (PRESERVED)
task.spawn(function()
    Players.PlayerAdded:Connect(function(player)
        pcall(function()
            if LocalPlayer:IsFriendsWith(player.UserId) then
                PlaySound(Sounds.FriendJoin)
            end
        end)
    end)
    Players.PlayerRemoving:Connect(function(player)
        pcall(function()
            if LocalPlayer:IsFriendsWith(player.UserId) then
                PlaySound(Sounds.FriendLeft)
            end
        end)
    end)
end)

--// 5. MAIN GUI STRUCTURE (COMPLETE REDESIGN)
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false

-- Minimised Button
local MiniPasta = Instance.new("TextButton", ScreenGui); 
MiniPasta.Size = UDim2.new(0, 60, 0, 60); 
MiniPasta.Position = UDim2.new(0.1, 0, 0.1, 0); 
MiniPasta.BackgroundColor3 = Settings.Theme.Dark; 
MiniPasta.Text = "🍝"; 
MiniPasta.TextSize = 35; 
MiniPasta.Visible = false; 
Library:Corner(MiniPasta, 20); 
Library:Stroke(MiniPasta, Settings.Theme.Gold, 0.5, 2)
local CheckDrag = Library:MakeDraggable(MiniPasta) 

-- Main Frame
local MainFrame = Instance.new("Frame", ScreenGui); 
local NEW_WIDTH = 650
local NEW_HEIGHT = 450
MainFrame.Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); 
MainFrame.BackgroundColor3 = Settings.Theme.Dark
MainFrame.BackgroundTransparency = 0.1 -- Dark Glassmorphism
MainFrame.ClipsDescendants = true; 
Library:Corner(MainFrame, 16); 
Library:Stroke(MainFrame, Color3.fromRGB(255,255,255), 0.8, 1) -- Thin White Glow

-- Open Animation
MainFrame.Size = UDim2.new(0,0,0,0); Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.6, Enum.EasingStyle.Quart) 

local MainScale = Instance.new("UIScale", MainFrame); MainScale.Scale = 1
Library:MakeDraggable(MainFrame)

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Sidebar.BackgroundTransparency = 0.5
Sidebar.BorderSizePixel = 0
Library:Corner(Sidebar, 16) -- Rounded Left

-- Fix Sidebar Corners (Right Side Flat)
local SidePatch = Instance.new("Frame", Sidebar)
SidePatch.Size = UDim2.new(0, 20, 1, 0)
SidePatch.Position = UDim2.new(1, -10, 0, 0)
SidePatch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SidePatch.BackgroundTransparency = 0
SidePatch.BorderSizePixel = 0
SidePatch.ZIndex = -1

-- Title
local AppTitle = Instance.new("TextLabel", Sidebar)
AppTitle.Size = UDim2.new(1, 0, 0, 60)
AppTitle.BackgroundTransparency = 1
AppTitle.Text = "SPAGHETTI\n<font color='#FFD700'>MAFIA</font>"
AppTitle.RichText = true
AppTitle.Font = Enum.Font.GothamBold
AppTitle.TextSize = 18
AppTitle.TextColor3 = Color3.new(1,1,1)

-- User Profile (Bottom Left)
local UserProfile = Instance.new("Frame", Sidebar)
UserProfile.Size = UDim2.new(0.9, 0, 0, 50)
UserProfile.Position = UDim2.new(0.05, 0, 0.88, 0)
UserProfile.BackgroundColor3 = Color3.fromRGB(40,40,40)
Library:Corner(UserProfile, 10)
local UserImg = Instance.new("ImageLabel", UserProfile)
UserImg.Size = UDim2.new(0, 34, 0, 34)
UserImg.Position = UDim2.new(0, 8, 0.5, 0)
UserImg.AnchorPoint = Vector2.new(0, 0.5)
UserImg.BackgroundColor3 = Settings.Theme.Gold
Library:Corner(UserImg, 17)
local UserName = Instance.new("TextLabel", UserProfile)
UserName.Size = UDim2.new(1, -50, 1, 0)
UserName.Position = UDim2.new(0, 48, 0, 0)
UserName.BackgroundTransparency = 1
UserName.Text = LocalPlayer.Name
UserName.Font = Enum.Font.GothamBold
UserName.TextColor3 = Color3.fromRGB(200,200,200)
UserName.TextSize = 11
UserName.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    pcall(function()
        UserImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
end)

-- Content Area
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -160, 1, 0)
Content.Position = UDim2.new(0, 160, 0, 0)
Content.BackgroundTransparency = 1

-- Top Bar (Close Button + Storm Widget)
local TopBar = Instance.new("Frame", Content)
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, 0)
CloseBtn.AnchorPoint = Vector2.new(0, 0.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
Library:Corner(CloseBtn, 8)

CloseBtn.MouseButton1Click:Connect(function() 
    MainFrame.Visible = false; 
    MiniPasta.Visible = true; 
    Library:Tween(MiniPasta, {Size = UDim2.new(0, 60, 0, 60)}, 0.4, Enum.EasingStyle.Back) 
end)

MiniPasta.MouseButton1Click:Connect(function() 
    if CheckDrag() == false then 
        MiniPasta.Visible = false; 
        MainFrame.Visible = true; 
        Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.4, Enum.EasingStyle.Back) 
    end
end)

-- Storm Widget (Preserved Logic)
local StormWidget = Instance.new("Frame", TopBar)
StormWidget.Size = UDim2.new(0, 150, 0, 34)
StormWidget.Position = UDim2.new(0, 20, 0.5, 0)
StormWidget.AnchorPoint = Vector2.new(0, 0.5)
StormWidget.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Library:Corner(StormWidget, 10)
local StormStroke = Library:Stroke(StormWidget, Settings.Theme.IceBlue, 0.5, 1)

local StormIcon = Instance.new("TextLabel", StormWidget)
StormIcon.Text = "⚡"
StormIcon.Size = UDim2.new(0, 30, 1, 0)
StormIcon.BackgroundTransparency = 1
StormIcon.TextSize = 14
local StormTime = Instance.new("TextLabel", StormWidget)
StormTime.Size = UDim2.new(1, -40, 1, 0)
StormTime.Position = UDim2.new(0, 30, 0, 0)
StormTime.BackgroundTransparency = 1
StormTime.Text = "00:00"
StormTime.Font = Enum.Font.GothamBold
StormTime.TextSize = 14
StormTime.TextColor3 = Settings.Theme.IceBlue
StormTime.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    local StormValue = ReplicatedStorage:WaitForChild("StormTimeLeft", 5)
    local wasStorming = false
    
    if StormValue then
        local function UpdateStormTimer(val)
            local mins = math.floor(val / 60)
            local secs = val % 60
            if val <= 0 then
                if not wasStorming then wasStorming = true; PlaySound(Sounds.StormStart) end
                StormTime.Text = "ACTIVE!"
                StormTime.TextColor3 = Settings.Theme.CrystalRed
                StormStroke.Color = Settings.Theme.CrystalRed
                TweenService:Create(StormWidget, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(50, 20, 20)}):Play()
            else
                if wasStorming then wasStorming = false; PlaySound(Sounds.StormEnd) end
                StormTime.Text = string.format("%02d:%02d", mins, secs)
                if val <= 30 then
                    StormTime.TextColor3 = Settings.Theme.Gold
                    StormStroke.Color = Settings.Theme.Gold
                else
                    StormTime.TextColor3 = Settings.Theme.IceBlue
                    StormStroke.Color = Settings.Theme.IceBlue
                    TweenService:Create(StormWidget, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(20, 20, 30)}):Play()
                end
            end
        end
        StormValue.Changed:Connect(UpdateStormTimer)
        UpdateStormTimer(StormValue.Value)
    end
end)

-- Navigation System
local NavContainer = Instance.new("ScrollingFrame", Sidebar)
NavContainer.Size = UDim2.new(1, 0, 1, -120)
NavContainer.Position = UDim2.new(0, 0, 0, 60)
NavContainer.BackgroundTransparency = 1
NavContainer.ScrollBarThickness = 0
local NavList = Instance.new("UIListLayout", NavContainer)
NavList.HorizontalAlignment = Enum.HorizontalAlignment.Center
NavList.Padding = UDim.new(0, 10)

local PagesContainer = Instance.new("Frame", Content)
PagesContainer.Size = UDim2.new(1, -40, 1, -60)
PagesContainer.Position = UDim2.new(0, 20, 0, 50)
PagesContainer.BackgroundTransparency = 1

local Tabs = {}
local CurrentTab = nil

local function SwitchTab(tabName)
    for name, page in pairs(Tabs) do
        page.Visible = (name == tabName)
    end
end

local function CreateTab(name, icon, isDefault)
    local btn = Instance.new("TextButton", NavContainer)
    btn.Size = UDim2.new(0.85, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    Library:Corner(btn, 10)
    
    local i = Instance.new("TextLabel", btn)
    i.Text = icon
    i.Size = UDim2.new(0, 40, 1, 0)
    i.BackgroundTransparency = 1
    i.TextSize = 16
    
    local t = Instance.new("TextLabel", btn)
    t.Text = name
    t.Size = UDim2.new(1, -40, 1, 0)
    t.Position = UDim2.new(0, 40, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = Color3.fromRGB(150, 150, 150)
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    
    local function UpdateState(active)
        if active then
            Library:Tween(btn, {BackgroundTransparency = 0.9})
            Library:Tween(t, {TextColor3 = Settings.Theme.Gold})
        else
            Library:Tween(btn, {BackgroundTransparency = 1})
            Library:Tween(t, {TextColor3 = Color3.fromRGB(150, 150, 150)})
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        if CurrentTab then CurrentTab(false) end
        CurrentTab = UpdateState
        UpdateState(true)
        SwitchTab(name)
    end)
    
    local page = Instance.new("ScrollingFrame", PagesContainer)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.Visible = false
    page.Name = name .. "_Page"
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0,0,0,0)
    
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 10)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 5)
    
    Tabs[name] = page
    
    if isDefault then
        CurrentTab = UpdateState
        UpdateState(true)
        page.Visible = true
    end
    
    return page
end

--// 6. LOGIC SYSTEMS (FARM LOGIC & SMART ANTI-SIT)
task.spawn(function() 
    while true do 
        task.wait(30) -- Anti-AFK
        pcall(function() 
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new()) 
        end) 
    end 
end)

local function GetClosestTarget()
    local drops = Workspace:FindFirstChild("StormDrops"); if not drops then return nil end
    local closest, dist = nil, math.huge; local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then for _, v in pairs(drops:GetChildren()) do if v:IsA("BasePart") and not FarmBlacklist[v] then local mag = (hrp.Position - v.Position).Magnitude; if mag < dist then dist = mag; closest = v end end end end
    return closest
end

local function UltraSafeDisable()
    local char = LocalPlayer.Character; if not char then return end
    for _, part in pairs(char:GetChildren()) do if part:IsA("BasePart") then part.CanTouch = false end end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local r = Region3.new(hrp.Position - Vector3.new(30,30,30), hrp.Position + Vector3.new(30,30,30))
        for _,v in pairs(workspace:FindPartsInRegion3(r, nil, 100)) do 
            if v.Name:lower():find("door") or v.Name:lower():find("portal") then v.CanTouch = false end 
        end
    end
end

local function ToggleFarm(v)
    Settings.Farming = v; if not v then FarmBlacklist = {} end
    if not FarmConnection and v then
        FarmConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and Settings.Farming then
                
                -- Smart Noclip: Only if Storm is Active
                local stormVal = ReplicatedStorage:FindFirstChild("StormTimeLeft")
                local isStorming = stormVal and stormVal.Value <= 0
                
                if isStorming then
                     for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
                     UltraSafeDisable()
                end

                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then 
                    -- ABSOLUTE ANTI-SIT FIX:
                    if not isSittingAction then
                        if hum.Sit then hum.Sit = false end 
                        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) 
                    else
                        -- If we ARE sitting, ensure Seated state is enabled so we don't glitch
                        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                    end
                end
            end
        end)
    elseif not v and FarmConnection then 
        FarmConnection:Disconnect()
        FarmConnection = nil 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) 
        end
    end

    if v then
        task.spawn(function()
            while Settings.Farming do
                local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local target = GetClosestTarget()
                if char and hrp and target then
                    local distance = (hrp.Position - target.Position).Magnitude
                    local tween = TweenService:Create(hrp, TweenInfo.new(distance / Settings.FarmSpeed, Enum.EasingStyle.Linear), {CFrame = target.CFrame}); tween:Play()
                    local start = tick()
                    local stuckStart = tick() 
                    
                    repeat task.wait() 
                        if not target.Parent or not Settings.Farming then tween:Cancel(); break end
                        local currentDist = (hrp.Position - target.Position).Magnitude
                        
                        if currentDist < 8 then
                            target.CanTouch = true
                            hrp.CFrame = target.CFrame 
                            if (tick() - stuckStart) > 0.6 then
                                tween:Cancel()
                                FarmBlacklist[target] = true
                                break
                            end
                        else
                            stuckStart = tick()
                        end
                        if (tick() - start) > (distance / Settings.FarmSpeed) + 1.5 then 
                            tween:Cancel()
                            break 
                        end
                    until not target.Parent
                else task.wait(0.1) end
                task.wait()
            end
        end)
    end
end

local function ToggleFly(v)
    Settings.Fly.Enabled = v
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    if v then
        if hrp:FindFirstChild("F_V") then hrp.F_V:Destroy() end
        if hrp:FindFirstChild("F_G") then hrp.F_G:Destroy() end

        local bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bv.Name = "F_V"
        
        local bg = Instance.new("BodyGyro", hrp)
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.P = 9e4
        bg.Name = "F_G"
        
        hum.PlatformStand = true
        
        task.spawn(function()
            while Settings.Fly.Enabled and char.Parent and hum.Health > 0 do
                if hum.Sit then hum.Sit = false end
                local cam = workspace.CurrentCamera
                local d = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - Vector3.new(0, 1, 0) end
                
                bv.Velocity = d * Settings.Fly.Speed
                bg.CFrame = cam.CFrame
                RunService.RenderStepped:Wait()
            end
            if hrp:FindFirstChild("F_V") then hrp.F_V:Destroy() end
            if hrp:FindFirstChild("F_G") then hrp.F_G:Destroy() end
            hum.PlatformStand = false
        end)
    else
        if hrp:FindFirstChild("F_V") then hrp.F_V:Destroy() end
        if hrp:FindFirstChild("F_G") then hrp.F_G:Destroy() end
        hum.PlatformStand = false
    end
end

--// 7. TAB CONSTRUCTION
local Tab_Event = CreateTab("Winter Event", "❄️", true)
local Tab_Main = CreateTab("Main", "🏠", false)
local Tab_Target = CreateTab("Target", "🎯", false)
local Tab_Settings = CreateTab("Settings", "⚙️", false)
local Tab_Credits = CreateTab("Credits", "👥", false)

--// TAB 1: WINTER EVENT
-- Auto Farm Button
local FarmHero = Instance.new("Frame", Tab_Event)
FarmHero.Size = UDim2.new(1, 0, 0, 80)
FarmHero.BackgroundColor3 = Settings.Theme.Content
Library:Corner(FarmHero, 10)
Library:Stroke(FarmHero, Settings.Theme.Stroke, 0.9, 1)

local FarmLabel = Instance.new("TextLabel", FarmHero)
FarmLabel.Text = "AUTO FARM"
FarmLabel.Font = Enum.Font.GothamBold
FarmLabel.TextSize = 22
FarmLabel.TextColor3 = Settings.Theme.Text
FarmLabel.Size = UDim2.new(0, 200, 1, 0)
FarmLabel.Position = UDim2.new(0, 20, 0, 0)
FarmLabel.BackgroundTransparency = 1
FarmLabel.TextXAlignment = Enum.TextXAlignment.Left

local FarmToggle = Instance.new("TextButton", FarmHero)
FarmToggle.Size = UDim2.new(0, 100, 0, 40)
FarmToggle.Position = UDim2.new(1, -120, 0.5, 0)
FarmToggle.AnchorPoint = Vector2.new(0, 0.5)
FarmToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FarmToggle.Text = "OFF"
FarmToggle.TextColor3 = Color3.fromRGB(150, 150, 150)
FarmToggle.Font = Enum.Font.GothamBold
Library:Corner(FarmToggle, 8)
local FarmStroke = Library:Stroke(FarmToggle, Color3.fromRGB(100,100,100), 0.5, 1)

local isFarming = false
FarmToggle.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    ToggleFarm(isFarming)
    if isFarming then
        FarmToggle.Text = "ACTIVE"
        FarmToggle.BackgroundColor3 = Settings.Theme.Gold
        FarmToggle.TextColor3 = Color3.new(0,0,0)
        FarmStroke.Color = Settings.Theme.Gold
    else
        FarmToggle.Text = "OFF"
        FarmToggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        FarmToggle.TextColor3 = Color3.fromRGB(150, 150, 150)
        FarmStroke.Color = Color3.fromRGB(100,100,100)
    end
end)

-- Stats
local StatsGrid = Instance.new("Frame", Tab_Event)
StatsGrid.Size = UDim2.new(1, 0, 0, 100)
StatsGrid.BackgroundTransparency = 1
local GLayout = Instance.new("UIGridLayout", StatsGrid)
GLayout.CellSize = UDim2.new(0.48, 0, 1, 0)
GLayout.CellPadding = UDim2.new(0.04, 0, 0, 0)

local function CreateStatCard(parent, title, color)
    local f = Instance.new("Frame", parent)
    f.BackgroundColor3 = Settings.Theme.Content
    Library:Corner(f, 10)
    Library:Stroke(f, color, 0.5, 1)
    
    local t = Instance.new("TextLabel", f)
    t.Text = title
    t.Size = UDim2.new(1, -20, 0, 30)
    t.Position = UDim2.new(0, 10, 0, 5)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = color
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    
    local v = Instance.new("TextLabel", f)
    v.Text = "0"
    v.Size = UDim2.new(1, -20, 0, 50)
    v.Position = UDim2.new(0, 10, 0, 30)
    v.BackgroundTransparency = 1
    v.Font = Enum.Font.GothamBold
    v.TextColor3 = Color3.new(1,1,1)
    v.TextSize = 24
    v.TextXAlignment = Enum.TextXAlignment.Left
    
    return v
end

local ValBlue = CreateStatCard(StatsGrid, "TOTAL SHARDS", Settings.Theme.ShardBlue)
local ValRed = CreateStatCard(StatsGrid, "TOTAL CRYSTALS", Settings.Theme.CrystalRed)

task.spawn(function()
    local CrystalsRef = LocalPlayer:WaitForChild("Crystals", 10)
    local ShardsRef = LocalPlayer:WaitForChild("Shards", 10)
    if not CrystalsRef or not ShardsRef then return end
    local InitC = CrystalsRef.Value; local InitS = ShardsRef.Value
    while true do
        task.wait(1)
        pcall(function()
            local CurC = CrystalsRef.Value; local CurS = ShardsRef.Value
            local SesC = CurC - InitC; local SesS = CurS - InitS
            if SesC < 0 then SesC = 0 end; if SesS < 0 then SesS = 0 end
            ValRed.Text = "+"..tostring(SesC)
            ValBlue.Text = "+"..tostring(SesS)
        end)
    end
end)

--// TAB 2: MAIN
local function CreateSlider(parent, title, min, max, default, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 60)
    f.BackgroundColor3 = Settings.Theme.Content
    Library:Corner(f, 10)
    Library:Stroke(f, Settings.Theme.Stroke, 0.9, 1)
    
    local t = Instance.new("TextLabel", f)
    t.Text = title .. ": " .. default
    t.Size = UDim2.new(1, -20, 0, 20)
    t.Position = UDim2.new(0, 10, 0, 10)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = Settings.Theme.Text
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 40)
    bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Library:Corner(bar, 3)
    
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Settings.Theme.Gold
    Library:Corner(fill, 3)
    
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    
    btn.MouseButton1Down:Connect(function()
        local dragging = true
        local inputConn
        inputConn = RunService.RenderStepped:Connect(function()
            if not dragging then inputConn:Disconnect(); return end
            local mouseLoc = UIS:GetMouseLocation()
            local r = math.clamp((mouseLoc.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + ((max - min) * r))
            fill.Size = UDim2.new(r, 0, 1, 0)
            t.Text = title .. ": " .. v
            callback(v)
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end)
end

CreateSlider(Tab_Main, "Walk Speed", 16, 250, 16, function(v) 
    Settings.Speed.Value = v 
    if Settings.Speed.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)

CreateSlider(Tab_Main, "Fly Speed", 20, 300, 50, function(v) Settings.Fly.Speed = v end)

local function CreateBind(parent, title, default, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = Settings.Theme.Content
    Library:Corner(f, 10)
    
    local t = Instance.new("TextLabel", f)
    t.Text = title
    t.Size = UDim2.new(0.5, 0, 1, 0)
    t.Position = UDim2.new(0, 15, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = Color3.fromRGB(200, 200, 200)
    t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(0, 80, 0, 26)
    b.Position = UDim2.new(1, -90, 0.5, 0)
    b.AnchorPoint = Vector2.new(0, 0.5)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    b.Text = default.Name
    b.TextColor3 = Settings.Theme.Gold
    b.Font = Enum.Font.GothamBold
    Library:Corner(b, 6)
    
    b.MouseButton1Click:Connect(function()
        b.Text = "..."
        local i = UIS.InputBegan:Wait()
        if i.UserInputType == Enum.UserInputType.Keyboard then
            b.Text = i.KeyCode.Name
            callback(i.KeyCode)
        end
    end)
end

CreateBind(Tab_Main, "Toggle Fly Key", Settings.Keys.Fly, function(k) Settings.Keys.Fly = k end)
CreateBind(Tab_Main, "Toggle Speed Key", Settings.Keys.Speed, function(k) Settings.Keys.Speed = k end)

--// TAB 3: TARGET
local SearchBox = Instance.new("Frame", Tab_Target)
SearchBox.Size = UDim2.new(1, 0, 0, 60)
SearchBox.BackgroundColor3 = Settings.Theme.Content
Library:Corner(SearchBox, 10)
Library:Stroke(SearchBox, Settings.Theme.Stroke, 0.9, 1)

local TargetAvatar = Instance.new("ImageLabel", SearchBox)
TargetAvatar.Size = UDim2.new(0, 40, 0, 40)
TargetAvatar.Position = UDim2.new(0, 10, 0.5, 0)
TargetAvatar.AnchorPoint = Vector2.new(0, 0.5)
TargetAvatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TargetAvatar.Image = "rbxassetid://0"
Library:Corner(TargetAvatar, 20)

local TargetInput = Instance.new("TextBox", SearchBox)
TargetInput.Size = UDim2.new(1, -140, 0, 40)
TargetInput.Position = UDim2.new(0, 60, 0.5, 0)
TargetInput.AnchorPoint = Vector2.new(0, 0.5)
TargetInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TargetInput.Text = ""
TargetInput.PlaceholderText = "Search Player..."
TargetInput.TextColor3 = Color3.new(1,1,1)
TargetInput.Font = Enum.Font.GothamBold
TargetInput.TextSize = 14
Library:Corner(TargetInput, 8)

local StatusTxt = Instance.new("TextLabel", SearchBox)
StatusTxt.Size = UDim2.new(0, 70, 1, 0)
StatusTxt.Position = UDim2.new(1, -80, 0, 0)
StatusTxt.BackgroundTransparency = 1
StatusTxt.Text = "WAITING"
StatusTxt.Font = Enum.Font.GothamBold
StatusTxt.TextSize = 12
StatusTxt.TextColor3 = Color3.fromRGB(100, 100, 100)

local function GetPlayer(name)
    name = name:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
            return p
        end
    end
    return nil
end

TargetInput.FocusLost:Connect(function()
    local p = GetPlayer(TargetInput.Text)
    if p then
        TargetInput.Text = p.Name
        PlaySound(Sounds.Click)
        local content = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        TargetAvatar.Image = content
        StatusTxt.Text = "ONLINE"
        StatusTxt.TextColor3 = Color3.fromRGB(50, 255, 100)
    else
        TargetAvatar.Image = "rbxassetid://0"
        StatusTxt.Text = "OFFLINE"
        StatusTxt.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end)

local ActionGrid = Instance.new("Frame", Tab_Target)
ActionGrid.Size = UDim2.new(1, 0, 0, 150)
ActionGrid.BackgroundTransparency = 1
local AL = Instance.new("UIGridLayout", ActionGrid)
AL.CellSize = UDim2.new(0.48, 0, 0.45, 0)
AL.CellPadding = UDim2.new(0.04, 0, 0.1, 0)

local function CreateActionBtn(text, callback)
    local b = Instance.new("TextButton", ActionGrid)
    b.BackgroundColor3 = Settings.Theme.Content
    b.Text = text
    b.TextColor3 = Color3.fromRGB(200, 200, 200)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    Library:Corner(b, 10)
    local s = Library:Stroke(b, Settings.Theme.Stroke, 0.9, 1)
    
    local state = false
    b.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        if state then
            b.BackgroundColor3 = Settings.Theme.Gold
            b.TextColor3 = Color3.new(0,0,0)
            s.Color = Settings.Theme.Gold
        else
            b.BackgroundColor3 = Settings.Theme.Content
            b.TextColor3 = Color3.fromRGB(200, 200, 200)
            s.Color = Settings.Theme.Stroke
        end
    end)
end

-- 1. BANG (UPDATED: ULTIMATE CFRAME VERSION)
local TrollConnection = nil
CreateActionBtn("BANG (R6/R15)", function(state)
    if not state then
        if TrollConnection then TrollConnection:Disconnect() TrollConnection = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
             -- Stop R6 Anim if any
             for _, anim in pairs(LocalPlayer.Character.Humanoid:GetPlayingAnimationTracks()) do
                 if anim.Animation.AnimationId == "rbxassetid://148840371" then anim:Stop() end
             end
        end
        return
    end
    
    local target = GetPlayer(TargetInput.Text)
    if target and target.Character and LocalPlayer.Character then
        local P = Players.LocalPlayer
        local C = P.Character or P.CharacterAdded:Wait()
        local H = C:WaitForChild('Humanoid')
        
        -- R6 uses the Animation (Still works fine)
        if H.RigType == Enum.HumanoidRigType.R6 then
            local AnimID = "rbxassetid://148840371"
            local A = Instance.new("Animation")
            A.AnimationId = AnimID
            local Track = H:LoadAnimation(A)
            Track.Looped = true
            Track:Play()
            Track:AdjustSpeed(2.5)
        end
        
        -- R15 & R6 Positioning Loop
        TrollConnection = RunService.Stepped:Connect(function()
            if not target.Character or not P.Character then 
                if TrollConnection then TrollConnection:Disconnect() end
                return 
            end
            pcall(function()
                local targetHRP = target.Character:WaitForChild('HumanoidRootPart')
                local myHRP = C:WaitForChild('HumanoidRootPart')
                
                -- CFRAME MATH (SINE WAVE) - WORKS ON EVERYTHING
                local velocity = 20 -- Speed of thrust
                local distance = 0.5 -- Distance of thrust
                local thrust = math.sin(tick() * velocity) * distance
                
                local behindPos = targetHRP.CFrame * CFrame.new(0, 0, 1.1 + thrust)
                myHRP.CFrame = CFrame.lookAt(behindPos.Position, targetHRP.Position)
            end)
        end)
    end
end)

-- 2. SPECTATE
CreateActionBtn("SPECTATE", function(state)
    local target = GetPlayer(TargetInput.Text)
    if state and target and target.Character then
        workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
    else
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end)

-- 3. HEADSIT (UPDATED: HEARTBEAT SIT LOOP)
local HeadSitConnection = nil
CreateActionBtn("HEADSIT", function(state)
    isSittingAction = state 
    if not state then
        PlaySit(false) 
        if HeadSitConnection then HeadSitConnection:Disconnect() HeadSitConnection = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Sit = false 
        end
        return
    end
    
    local target = GetPlayer(TargetInput.Text)
    if target and target.Character then
         PlaySit(true) 
         HeadSitConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                 if not target.Character or not LocalPlayer.Character then return end
                 local h = LocalPlayer.Character.Humanoid
                 if not h.Sit then h.Sit = true end 
                 
                 LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.Head.CFrame * CFrame.new(0, 1.5, 0)
                 LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.zero
            end)
         end)
    end
end)

-- 4. BACKPACK (UPDATED: HEARTBEAT SIT LOOP)
local BackpackConnection = nil
CreateActionBtn("BACKPACK", function(state)
    isSittingAction = state 
    if not state then
        PlaySit(false) 
        if BackpackConnection then BackpackConnection:Disconnect() BackpackConnection = nil end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Sit = false 
        end
        return
    end
    
    local target = GetPlayer(TargetInput.Text)
    if target and target.Character then
         PlaySit(true) 
         BackpackConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                 if not target.Character or not LocalPlayer.Character then return end
                 local h = LocalPlayer.Character.Humanoid
                 if not h.Sit then h.Sit = true end 

                 -- LOWERED BY 0.8 (from 1.5 to 0.7)
                 LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0.7, 0.5) * CFrame.Angles(0, math.rad(180), 0)
                 LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.zero
            end)
         end)
    end
end)

local ScannerFrame = Instance.new("Frame", Tab_Target)
ScannerFrame.Size = UDim2.new(1, 0, 0, 200)
ScannerFrame.BackgroundColor3 = Settings.Theme.Content
Library:Corner(ScannerFrame, 10)
Library:Stroke(ScannerFrame, Settings.Theme.Stroke, 0.9, 1)

local ScanBtn = Instance.new("TextButton", ScannerFrame)
ScanBtn.Size = UDim2.new(1, -20, 0, 30)
ScanBtn.Position = UDim2.new(0, 10, 0, 10)
ScanBtn.BackgroundColor3 = Settings.Theme.Gold
ScanBtn.Text = "SCAN INVENTORY"
ScanBtn.TextColor3 = Color3.new(0,0,0)
ScanBtn.Font = Enum.Font.GothamBold
Library:Corner(ScanBtn, 8)

local ScanResults = Instance.new("ScrollingFrame", ScannerFrame)
ScanResults.Size = UDim2.new(1, -20, 1, -50)
ScanResults.Position = UDim2.new(0, 10, 0, 45)
ScanResults.BackgroundTransparency = 1
ScanResults.ScrollBarThickness = 2
local SL = Instance.new("UIListLayout", ScanResults); SL.Padding = UDim.new(0, 5)

local IgnoreList = {
    ["קולה"] = true, ["קולה מכשפות"] = true, ["קולה תות"] = true, ["קפה סטארבלוקס"] = true,
    ["רוטב חריף"] = true, ["שוקו"] = true, ["שיקוי אהבה"] = true, ["שיקוי הזקן המשוגע"] = true,
    ["שיקוי קרח"] = true, ["אבטיח"] = true, ["בורגר רדוף רוחות"] = true, ["בלוקס אנרגיה"] = true,
    ["גלידה"] = true, ["דובי"] = true, ["המבורגר"] = true, ["טאקו"] = true, ["כסף פליז"] = true,
    ["נקניקייה"] = true, ["סנדוויץ"] = true, ["עוגה"] = true, ["עוף"] = true, ["פייר קולה"] = true,
    ["פיצה"] = true, ["Cola"] = true, ["Pizza"] = true, ["Burger"] = true
}

ScanBtn.MouseButton1Click:Connect(function()
    for _,v in pairs(ScanResults:GetChildren()) do if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end end
    local target = GetPlayer(TargetInput.Text)
    
    if not target then 
         local err = Instance.new("TextLabel", ScanResults); err.Size=UDim2.new(1,0,0,20); err.BackgroundTransparency=1; err.Text="Player not found!"; err.TextColor3=Color3.fromRGB(255,50,50); err.Font=Enum.Font.GothamBold; err.TextSize=14
         return 
    end

    local itemsCount = {}
    local itemsIcon = {}

    local function ScanFolder(f)
        if not f then return end
        for _, item in pairs(f:GetChildren()) do
            -- Filter out TextLabels or non-items
            if item:IsA("TextLabel") then continue end
            
            if not IgnoreList[item.Name] and not item:IsA("Folder") then
                 itemsCount[item.Name] = (itemsCount[item.Name] or 0) + 1
                 if item:IsA("Tool") and item.TextureId ~= "" then
                     itemsIcon[item.Name] = item.TextureId
                 end
            end
        end
    end
    
    ScanFolder(target:FindFirstChild("Backpack"))
    ScanFolder(target:FindFirstChild("Data"))
    ScanFolder(target:FindFirstChild("Inventory"))
    if target.Character then 
        for _,c in pairs(target.Character:GetChildren()) do 
            if c:IsA("Tool") and not IgnoreList[c.Name] then 
                itemsCount[c.Name] = (itemsCount[c.Name] or 0) + 1 
                if c.TextureId ~= "" then itemsIcon[c.Name] = c.TextureId end
            end 
        end 
    end

    local found = false
    for name, count in pairs(itemsCount) do
        found = true
        local row = Instance.new("Frame", ScanResults)
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundTransparency = 1
        
        -- IMAGE ON RIGHT
        local icon = Instance.new("ImageLabel", row)
        icon.Size = UDim2.new(0, 30, 0, 30)
        icon.Position = UDim2.new(0, 0, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.BackgroundTransparency = 1
        if itemsIcon[name] then icon.Image = itemsIcon[name] else icon.Image = "rbxassetid://6503956166" end 
        
        -- TEXT ALIGNED RIGHT
        local txt = Instance.new("TextLabel", row)
        txt.Size = UDim2.new(1, -40, 1, 0)
        txt.Position = UDim2.new(0, 40, 0, 0)
        txt.BackgroundTransparency = 1
        txt.Text = name .. "  x" .. count
        txt.TextColor3 = Settings.Theme.Text
        txt.Font = Enum.Font.GothamMedium
        txt.TextSize = 14
        txt.TextXAlignment = Enum.TextXAlignment.Left
    end
    
    if not found then
        local msg = Instance.new("TextLabel", ScanResults); msg.Size=UDim2.new(1,0,0,20); msg.BackgroundTransparency=1; msg.Text="No rare items found."; msg.TextColor3=Color3.fromRGB(150,150,150); msg.Font=Enum.Font.Gotham; msg.TextSize=14
    end
end)

--// TAB 4: SETTINGS
CreateSlider(Tab_Settings, "Camera FOV", 70, 120, 70, function(v) Camera.FieldOfView = v end)
CreateSlider(Tab_Settings, "Menu Scale", 5, 15, 10, function(v) 
    local scale = v / 10
    Library:Tween(MainScale, {Scale = scale}, 0.5, Enum.EasingStyle.Quart)
end)
CreateBind(Tab_Settings, "Menu Keybind", Settings.Keys.Menu, function(k) Settings.Keys.Menu = k end)

local RejoinBtn = Instance.new("TextButton", Tab_Settings)
RejoinBtn.Size = UDim2.new(1, 0, 0, 50)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
RejoinBtn.Text = "REJOIN SERVER"
RejoinBtn.TextColor3 = Color3.new(1,1,1)
RejoinBtn.Font = Enum.Font.GothamBold
Library:Corner(RejoinBtn, 10)
RejoinBtn.MouseButton1Click:Connect(function() 
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

--// TAB 5: CREDITS
local function CreateCreditCard(name, role, discord, id)
    local f = Instance.new("Frame", Tab_Credits)
    f.Size = UDim2.new(1, 0, 0, 70)
    f.BackgroundColor3 = Settings.Theme.Content
    Library:Corner(f, 10)
    Library:Stroke(f, Settings.Theme.Stroke, 0.9, 1)
    
    local img = Instance.new("ImageLabel", f)
    img.Size = UDim2.new(0, 50, 0, 50)
    img.Position = UDim2.new(0, 10, 0.5, 0)
    img.AnchorPoint = Vector2.new(0, 0.5)
    img.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    img.Image = "rbxassetid://" .. id
    Library:Corner(img, 25)
    
    local t = Instance.new("TextLabel", f)
    t.Text = name
    t.Size = UDim2.new(0, 100, 0, 20)
    t.Position = UDim2.new(0, 70, 0.5, -10)
    t.AnchorPoint = Vector2.new(0, 0.5)
    t.BackgroundTransparency = 1
    t.TextColor3 = Settings.Theme.Gold
    t.Font = Enum.Font.GothamBold
    t.TextSize = 16
    t.TextXAlignment = Enum.TextXAlignment.Left
    
    local r = Instance.new("TextLabel", f)
    r.Text = role
    r.Size = UDim2.new(0, 100, 0, 20)
    r.Position = UDim2.new(0, 70, 0.5, 10)
    r.AnchorPoint = Vector2.new(0, 0.5)
    r.BackgroundTransparency = 1
    r.TextColor3 = Settings.Theme.IceBlue
    r.Font = Enum.Font.GothamMedium
    r.TextSize = 12
    r.TextXAlignment = Enum.TextXAlignment.Left
    
    local d = Instance.new("TextButton", f)
    d.Size = UDim2.new(0, 100, 0, 30)
    d.Position = UDim2.new(1, -110, 0.5, 0)
    d.AnchorPoint = Vector2.new(0, 0.5)
    d.BackgroundColor3 = Settings.Theme.Discord
    d.Text = "COPY DISCORD"
    d.TextColor3 = Color3.new(1,1,1)
    d.Font = Enum.Font.GothamBold
    d.TextSize = 11
    Library:Corner(d, 6)
    
    d.MouseButton1Click:Connect(function()
        setclipboard(discord)
        d.Text = "COPIED!"
        task.wait(1)
        d.Text = "COPY DISCORD"
    end)
end

CreateCreditCard("Neho", "Founder", "nx3ho", "97462570733982") 
CreateCreditCard("BadShot", "CoFounder", "8adshot3", "133430813410950")
CreateCreditCard("xyth", "Community Manager", "sc4rlxrd", "106705865211282")

--// 8. FINAL LOOPS & INPUTS
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Menu then 
            if MainFrame.Visible then 
                Library:Tween(MainFrame, {Size = UDim2.new(0,0,0,0)}, 0.4, Enum.EasingStyle.Back); 
                task.wait(0.3); 
                MainFrame.Visible = false 
                MiniPasta.Visible = true 
                Library:Tween(MiniPasta, {Size = UDim2.new(0, 60, 0, 60)}, 0.4, Enum.EasingStyle.Back)
            else 
                MiniPasta.Visible = false
                MainFrame.Visible = true; 
                MainFrame.Size = UDim2.new(0, 0, 0, 0); 
                Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.5, Enum.EasingStyle.Back) 
            end 
        end

        if i.KeyCode == Settings.Keys.Fly then Settings.Fly.Enabled = not Settings.Fly.Enabled; ToggleFly(Settings.Fly.Enabled); if VisualToggles["Fly"] then VisualToggles["Fly"](Settings.Fly.Enabled) end end
        if i.KeyCode == Settings.Keys.Speed then 
            Settings.Speed.Enabled = not Settings.Speed.Enabled
            if not Settings.Speed.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = 16
            end
            if VisualToggles["Speed"] then VisualToggles["Speed"](Settings.Speed.Enabled) end 
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.Speed.Enabled and LocalPlayer.Character then 
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        if h then 
            if h.WalkSpeed ~= Settings.Speed.Value then
                h.WalkSpeed = Settings.Speed.Value
            end
        end 
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5) 
    if Settings.Speed.Enabled then
        local h = newChar:WaitForChild("Humanoid", 5)
        if h then h.WalkSpeed = Settings.Speed.Value end
    end
end)

print("[SYSTEM] Spaghetti Mafia Hub v2.0 (Redesign) Loaded")
