--[[
    Spaghetti Mafia Hub v1.5 (ULTIMATE CFRAME EDITION)
    
    VISUAL OVERHAUL:
    - Deep Obsidian Theme (12,12,12)
    - Neon Gold Accents & Strokes
    - Strict Grid System (12px Padding)
    - Procedural CFrame Animations (R15 Compatible)
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

--// 1. WHITELIST SYSTEM
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

--// 2. CLEANUP & THEME DEFINITIONS
if CoreGui:FindFirstChild("SpaghettiHub_Rel") then CoreGui.SpaghettiHub_Rel:Destroy() end
if CoreGui:FindFirstChild("SpaghettiLoading") then CoreGui.SpaghettiLoading:Destroy() end

local Settings = {
    Theme = {
        Background = Color3.fromRGB(12, 12, 12), -- Deep Obsidian
        Panel = Color3.fromRGB(18, 18, 20),
        Gold = Color3.fromRGB(255, 215, 0), -- Neon Gold
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(150, 150, 150),
        
        IceBlue = Color3.fromRGB(100, 220, 255),
        IceDark = Color3.fromRGB(10, 15, 25),
        
        ShardBlue = Color3.fromRGB(50, 180, 255),
        CrystalRed = Color3.fromRGB(255, 70, 70),
        Discord = Color3.fromRGB(88, 101, 242),
        Success = Color3.fromRGB(50, 255, 120),
        Error = Color3.fromRGB(255, 60, 60)
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
local TrollConnection = nil -- For R15 Bang

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

--// 3. UI LIBRARY FUNCTIONS (MODERNIZED)
local Library = {}

function Library:Tween(obj, props, time, style, dir) 
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props):Play() 
end

function Library:Corner(obj, r) 
    local c = Instance.new("UICorner", obj); 
    c.CornerRadius = UDim.new(0, r or 8); -- Default 8px per request
    return c 
end

function Library:AddStroke(obj, color, thickness)
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Settings.Theme.Gold
    s.Thickness = thickness or 1.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = 0
    return s
end

function Library:AddPadding(obj, amount)
    local p = Instance.new("UIPadding", obj)
    p.PaddingTop = UDim.new(0, amount)
    p.PaddingBottom = UDim.new(0, amount)
    p.PaddingLeft = UDim.new(0, amount)
    p.PaddingRight = UDim.new(0, amount)
    return p
end

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
            if delta.Magnitude > 2 then isDraggingBool = true end 
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
    flake.Size = UDim2.new(0, math.random(15, 25), 0, math.random(15, 25))
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

--// 4. LOADING SCREEN (BREATHE & FLOAT)
local LoadGui = Instance.new("ScreenGui"); LoadGui.Name = "SpaghettiLoading"; LoadGui.Parent = CoreGui
local LoadBox = Instance.new("Frame", LoadGui)
LoadBox.Size = UDim2.new(0, 260, 0, 180)
LoadBox.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadBox.AnchorPoint = Vector2.new(0.5, 0.5)
LoadBox.BackgroundColor3 = Settings.Theme.Background 
LoadBox.BackgroundTransparency = 0.1
Library:Corner(LoadBox, 16)
Library:AddStroke(LoadBox, Settings.Theme.Gold, 2)

local LoadBlur = Instance.new("UIBlur", LoadGui); LoadBlur.Size = 15 

local PastaIcon = Instance.new("TextLabel", LoadBox)
PastaIcon.Size = UDim2.new(1, 0, 0.45, 0); PastaIcon.Position = UDim2.new(0,0,0.1,0)
PastaIcon.BackgroundTransparency = 1; PastaIcon.Text = "🍝"; PastaIcon.TextSize = 65; PastaIcon.ZIndex = 2
PastaIcon.AnchorPoint = Vector2.new(0.5, 0)
PastaIcon.Position = UDim2.new(0.5, 0, 0.1, 0)

-- Animation: Breathe & Float
task.spawn(function()
    local t = 0
    while LoadBox.Parent do
        t = t + 0.05
        local scale = 1 + math.sin(t * 3) * 0.1 -- Breathe
        local offset = math.sin(t * 2) * 5 -- Float
        PastaIcon.Scale = scale
        PastaIcon.Position = UDim2.new(0.5, 0, 0.1, offset)
        task.wait(0.016)
    end
end)

local TitleLoad = Instance.new("TextLabel", LoadBox)
TitleLoad.Size = UDim2.new(1, 0, 0.2, 0); TitleLoad.Position = UDim2.new(0, 0, 0.55, 0)
TitleLoad.BackgroundTransparency = 1; TitleLoad.Text = "SPAGHETTI MAFIA"; 
TitleLoad.Font = Enum.Font.GothamBlack; TitleLoad.TextColor3 = Settings.Theme.Gold; TitleLoad.TextSize = 20

local SubLoad = Instance.new("TextLabel", LoadBox)
SubLoad.Size = UDim2.new(1, 0, 0.2, 0); SubLoad.Position = UDim2.new(0, 0, 0.70, 0)
SubLoad.BackgroundTransparency = 1; SubLoad.Text = "Loading Assets..."; 
SubLoad.Font = Enum.Font.Gotham; SubLoad.TextColor3 = Settings.Theme.SubText; SubLoad.TextSize = 12

local LoadingBarBG = Instance.new("Frame", LoadBox)
LoadingBarBG.Size = UDim2.new(0.8, 0, 0, 4)
LoadingBarBG.Position = UDim2.new(0.1, 0, 0.88, 0)
LoadingBarBG.BackgroundColor3 = Color3.fromRGB(30,30,30)
Library:Corner(LoadingBarBG, 2)

local LoadingBarFill = Instance.new("Frame", LoadingBarBG)
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Settings.Theme.Gold
Library:Corner(LoadingBarFill, 2)

-- Visual: Glowing Bar
local Glow = Instance.new("ImageLabel", LoadingBarFill)
Glow.Size = UDim2.new(1, 20, 3, 0); Glow.Position = UDim2.new(0, -10, -1, 0)
Glow.BackgroundTransparency = 1; Glow.Image = "rbxassetid://5028857472"; Glow.ImageColor3 = Settings.Theme.Gold; Glow.ImageTransparency = 0.5

Library:Tween(LoadingBarFill, {Size = UDim2.new(1, 0, 1, 0)}, 2.0, Enum.EasingStyle.Sine)

task.wait(2.2)
Library:Tween(LoadBox, {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
Library:Tween(LoadBlur, {Size = 0}, 0.5)
task.wait(0.5)
LoadGui:Destroy()

--// 5. MAIN GUI STRUCTURE (GRID SYSTEM)
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false

local MiniPasta = Instance.new("TextButton", ScreenGui); 
MiniPasta.Size = UDim2.new(0, 60, 0, 60); 
MiniPasta.Position = UDim2.new(0.1, 0, 0.1, 0); 
MiniPasta.BackgroundColor3 = Settings.Theme.Panel; 
MiniPasta.Text = "🍝"; 
MiniPasta.TextSize = 35; 
MiniPasta.Visible = false; 
Library:Corner(MiniPasta, 30); 
Library:AddStroke(MiniPasta, Settings.Theme.Gold, 2); 
local CheckDrag = Library:MakeDraggable(MiniPasta) 

local MainFrame = Instance.new("Frame", ScreenGui); 
local NEW_WIDTH = 600
local NEW_HEIGHT = 450
MainFrame.Size = UDim2.new(0, 0, 0, 0) -- Tween in
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); 
MainFrame.BackgroundColor3 = Settings.Theme.Background; 
MainFrame.ClipsDescendants = true; 
Library:Corner(MainFrame, 12); 
Library:AddStroke(MainFrame, Settings.Theme.Gold, 2)

Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.6, Enum.EasingStyle.Back)
local MainDrag = Library:MakeDraggable(MainFrame)

-- Sidebar Area
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Settings.Theme.Panel
Sidebar.BorderSizePixel = 0
local SidebarGradient = Instance.new("UIGradient", Sidebar)
SidebarGradient.Rotation = -90
SidebarGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25,25,25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15,15,15))
}

local SidebarContent = Instance.new("Frame", Sidebar)
SidebarContent.Size = UDim2.new(1, 0, 1, 0)
SidebarContent.BackgroundTransparency = 1
Library:AddPadding(SidebarContent, 10)

-- Header Logo
local LogoText = Instance.new("TextLabel", SidebarContent)
LogoText.Size = UDim2.new(1, 0, 0, 30)
LogoText.BackgroundTransparency = 1
LogoText.Text = "MAFIA <font color='#FFD700'>HUB</font>"
LogoText.RichText = true
LogoText.Font = Enum.Font.GothamBlack
LogoText.TextSize = 20
LogoText.TextColor3 = Color3.new(1,1,1)

local LogoSub = Instance.new("TextLabel", SidebarContent)
LogoSub.Size = UDim2.new(1, 0, 0, 15)
LogoSub.Position = UDim2.new(0,0,0,25)
LogoSub.BackgroundTransparency = 1
LogoSub.Text = "Ultimate Edition"
LogoSub.Font = Enum.Font.Gotham; LogoSub.TextSize = 10
LogoSub.TextColor3 = Settings.Theme.Gold

-- Navigation
local NavContainer = Instance.new("ScrollingFrame", SidebarContent)
NavContainer.Size = UDim2.new(1, 0, 1, -120)
NavContainer.Position = UDim2.new(0, 0, 0, 50)
NavContainer.BackgroundTransparency = 1
NavContainer.ScrollBarThickness = 0
NavContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavContainer.CanvasSize = UDim2.new(0,0,0,0)

local NavList = Instance.new("UIListLayout", NavContainer); NavList.Padding = UDim.new(0, 8); NavList.SortOrder = Enum.SortOrder.LayoutOrder

-- Profile Area
local ProfileArea = Instance.new("Frame", SidebarContent)
ProfileArea.Size = UDim2.new(1, 0, 0, 60)
ProfileArea.Position = UDim2.new(0, 0, 1, -60)
ProfileArea.BackgroundColor3 = Color3.fromRGB(12,12,12)
Library:Corner(ProfileArea, 8)
Library:AddStroke(ProfileArea, Settings.Theme.Gold, 1)

local P_Avatar = Instance.new("ImageLabel", ProfileArea)
P_Avatar.Size = UDim2.new(0, 40, 0, 40)
P_Avatar.Position = UDim2.new(0, 10, 0.5, 0)
P_Avatar.AnchorPoint = Vector2.new(0, 0.5)
P_Avatar.BackgroundColor3 = Settings.Theme.Gold
Library:Corner(P_Avatar, 20)
task.spawn(function() P_Avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end)

local P_Name = Instance.new("TextLabel", ProfileArea)
P_Name.Size = UDim2.new(0, 80, 0, 20); P_Name.Position = UDim2.new(0, 60, 0.2, 0); P_Name.BackgroundTransparency=1
P_Name.Text = LocalPlayer.DisplayName; P_Name.Font=Enum.Font.GothamBold; P_Name.TextSize=12; P_Name.TextColor3=Color3.new(1,1,1); P_Name.TextXAlignment=Enum.TextXAlignment.Left

local P_Rank = Instance.new("TextLabel", ProfileArea)
P_Rank.Size = UDim2.new(0, 80, 0, 15); P_Rank.Position = UDim2.new(0, 60, 0.55, 0); P_Rank.BackgroundTransparency=1
P_Rank.Text = "Whitelist: Active"; P_Rank.Font=Enum.Font.Gotham; P_Rank.TextSize=9; P_Rank.TextColor3=Settings.Theme.Success; P_Rank.TextXAlignment=Enum.TextXAlignment.Left

-- Content Area
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -160, 1, 0)
Content.Position = UDim2.new(0, 160, 0, 0)
Content.BackgroundTransparency = 1
Library:AddPadding(Content, 12)

-- Top Bar (Close Button + Storm Timer)
local TopBar = Instance.new("Frame", Content)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Settings.Theme.Error
CloseBtn.Font = Enum.Font.GothamBold
Library:Corner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniPasta.Visible = true end)

local StormWidget = Instance.new("Frame", TopBar)
StormWidget.Size = UDim2.new(0, 140, 0, 32)
StormWidget.Position = UDim2.new(1, -180, 0, 4)
StormWidget.BackgroundColor3 = Color3.fromRGB(20,20,25)
Library:Corner(StormWidget, 6)
Library:AddStroke(StormWidget, Settings.Theme.IceBlue, 1)

local S_Icon = Instance.new("TextLabel", StormWidget)
S_Icon.Text = "⛈️"
S_Icon.Size = UDim2.new(0, 30, 1, 0)
S_Icon.BackgroundTransparency = 1

local S_Time = Instance.new("TextLabel", StormWidget)
S_Time.Size = UDim2.new(1, -35, 1, 0)
S_Time.Position = UDim2.new(0, 35, 0, 0)
S_Time.BackgroundTransparency = 1
S_Time.Text = "00:00"
S_Time.TextColor3 = Settings.Theme.IceBlue
S_Time.Font = Enum.Font.GothamBold
S_Time.TextXAlignment = Enum.TextXAlignment.Left

--// 6. STORM TIMER LOGIC
task.spawn(function()
    local StormValue = ReplicatedStorage:WaitForChild("StormTimeLeft", 5)
    if StormValue then
        local wasStorming = false
        StormValue.Changed:Connect(function(val)
            local mins = math.floor(val / 60)
            local secs = val % 60
            S_Time.Text = string.format("%02d:%02d", mins, secs)
            
            if val <= 0 then
                if not wasStorming then wasStorming = true; PlaySound(Sounds.StormStart) end
                S_Time.Text = "ACTIVE!"
                S_Time.TextColor3 = Settings.Theme.CrystalRed
                StormWidget.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
            else
                if wasStorming then wasStorming = false; PlaySound(Sounds.StormEnd) end
                S_Time.TextColor3 = Settings.Theme.IceBlue
                StormWidget.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
            end
        end)
    end
end)

--// 7. TAB SYSTEM
local Pages = Instance.new("Frame", Content)
Pages.Size = UDim2.new(1, 0, 1, -50)
Pages.Position = UDim2.new(0, 0, 0, 50)
Pages.BackgroundTransparency = 1

local function CreateTab(name, icon, order, color)
    -- Button
    local btn = Instance.new("TextButton", NavContainer)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(12,12,12) -- Transparent-ish
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.LayoutOrder = order
    
    local i = Instance.new("TextLabel", btn)
    i.Text = icon
    i.Size = UDim2.new(0, 30, 1, 0)
    i.BackgroundTransparency = 1
    i.TextSize = 16
    
    local t = Instance.new("TextLabel", btn)
    t.Text = name
    t.Size = UDim2.new(1, -40, 1, 0)
    t.Position = UDim2.new(0, 35, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = Settings.Theme.SubText
    t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Page
    local page = Instance.new("ScrollingFrame", Pages)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.Visible = false
    page.Name = name.."Page"
    
    local pad = Library:AddPadding(page, 5)
    
    btn.MouseButton1Click:Connect(function()
        -- Reset all buttons
        for _, b in pairs(NavContainer:GetChildren()) do
            if b:IsA("TextButton") then
                TweenService:Create(b:FindFirstChildOfClass("TextLabel"), TweenInfo.new(0.2), {TextColor3 = Settings.Theme.SubText}):Play()
            end
        end
        -- Reset all pages
        for _, p in pairs(Pages:GetChildren()) do p.Visible = false end
        
        -- Activate
        page.Visible = true
        TweenService:Create(t, TweenInfo.new(0.2), {TextColor3 = color or Settings.Theme.Gold}):Play()
    end)
    
    return page, btn
end

--// 8. PAGE CONTENT CREATION

-- [ WINTER EVENT ]
local WinterPage, WinterBtn = CreateTab("Winter Event", "❄️", 1, Settings.Theme.IceBlue)
local WinterGrid = Instance.new("UIGridLayout", WinterPage)
WinterGrid.CellSize = UDim2.new(0.48, 0, 0, 100)
WinterGrid.CellPadding = UDim2.new(0.04, 0, 0, 10)

-- Farm Toggle Card
local FarmCard = Instance.new("TextButton", WinterPage)
FarmCard.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
Library:Corner(FarmCard, 8); Library:AddStroke(FarmCard, Settings.Theme.IceBlue, 1.5)
local F_Title = Instance.new("TextLabel", FarmCard); F_Title.Text = "Auto Farm"; F_Title.Size=UDim2.new(1,0,0,30); F_Title.Position=UDim2.new(0,0,0,10); F_Title.Font=Enum.Font.GothamBold; F_Title.TextColor3=Color3.new(1,1,1); F_Title.BackgroundTransparency=1; F_Title.TextSize=16
local F_Heb = Instance.new("TextLabel", FarmCard); F_Heb.Text = "חווה אוטומטית"; F_Heb.Size=UDim2.new(1,0,0,20); F_Heb.Position=UDim2.new(0,0,0,35); F_Heb.Font=Enum.Font.Gotham; F_Heb.TextColor3=Settings.Theme.IceBlue; F_Heb.BackgroundTransparency=1; F_Heb.TextSize=12
local F_Status = Instance.new("Frame", FarmCard); F_Status.Size=UDim2.new(0, 60, 0, 6); F_Status.Position=UDim2.new(0.5, -30, 0.8, 0); F_Status.BackgroundColor3=Color3.fromRGB(50,50,50); Library:Corner(F_Status, 3)

-- Logic integration
local function ToggleFarm(v)
    Settings.Farming = v; if not v then FarmBlacklist = {} end
    F_Status.BackgroundColor3 = v and Settings.Theme.Success or Color3.fromRGB(50,50,50)
    Library:Tween(FarmCard, {BackgroundColor3 = v and Color3.fromRGB(30, 50, 70) or Color3.fromRGB(20, 30, 40)})
    
    if not FarmConnection and v then
        FarmConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and Settings.Farming then
                -- Smart Noclip only if storm is active
                local stormVal = ReplicatedStorage:FindFirstChild("StormTimeLeft")
                if stormVal and stormVal.Value <= 0 then
                     for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
                     -- Ultra Safe Logic
                     local char = LocalPlayer.Character
                     local hrp = char:FindFirstChild("HumanoidRootPart")
                     if hrp then
                        local r = Region3.new(hrp.Position - Vector3.new(30,30,30), hrp.Position + Vector3.new(30,30,30))
                        for _,v in pairs(workspace:FindPartsInRegion3(r, nil, 100)) do 
                            if v.Name:lower():find("door") or v.Name:lower():find("portal") then v.CanTouch = false end 
                        end
                     end
                end

                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then 
                    if not isSittingAction then
                        if hum.Sit then hum.Sit = false end 
                        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) 
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
                local drops = Workspace:FindFirstChild("StormDrops")
                local target = nil
                local dist = math.huge
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if drops and hrp then
                    for _, val in pairs(drops:GetChildren()) do 
                        if val:IsA("BasePart") and not FarmBlacklist[val] then 
                            local mag = (hrp.Position - val.Position).Magnitude
                            if mag < dist then dist = mag; target = val end 
                        end 
                    end
                end

                if hrp and target then
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
                                tween:Cancel(); FarmBlacklist[target] = true; break
                            end
                        else
                            stuckStart = tick()
                        end
                        if (tick() - start) > (distance / Settings.FarmSpeed) + 1.5 then 
                            tween:Cancel(); break 
                        end
                    until not target.Parent
                else task.wait(0.1) end
                task.wait()
            end
        end)
    end
end
FarmCard.MouseButton1Click:Connect(function() ToggleFarm(not Settings.Farming) end)

-- Stats Cards
local function CreateStat(name, color)
    local f = Instance.new("Frame", WinterPage)
    f.BackgroundColor3 = Color3.fromRGB(18,18,20)
    Library:Corner(f, 8); Library:AddStroke(f, color, 1)
    local t = Instance.new("TextLabel", f); t.Text = name; t.Size = UDim2.new(1,0,0,20); t.Position=UDim2.new(0,0,0,10); t.TextColor3 = color; t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold
    local v = Instance.new("TextLabel", f); v.Text = "0"; v.Size = UDim2.new(1,0,0,40); v.Position=UDim2.new(0,0,0,40); v.TextColor3 = Color3.new(1,1,1); v.BackgroundTransparency=1; v.Font=Enum.Font.GothamBlack; v.TextSize=24
    return v
end

local StatShards = CreateStat("Shards (כחול)", Settings.Theme.ShardBlue)
local StatCrystals = CreateStat("Crystals (אדום)", Settings.Theme.CrystalRed)

task.spawn(function()
    while true do
        pcall(function()
            local s = LocalPlayer:FindFirstChild("Shards")
            local c = LocalPlayer:FindFirstChild("Crystals")
            if s then StatShards.Text = tostring(s.Value) end
            if c then StatCrystals.Text = tostring(c.Value) end
        end)
        task.wait(1)
    end
end)

-- [ MAIN TAB ]
local MainPage, MainBtn = CreateTab("Main", "🏠", 2, Settings.Theme.Gold)
local MainList = Instance.new("UIListLayout", MainPage); MainList.Padding = UDim.new(0, 10)

local function CreateSlider(title, min, max, default, callback)
    local f = Instance.new("Frame", MainPage)
    f.Size = UDim2.new(1, 0, 0, 50)
    f.BackgroundColor3 = Settings.Theme.Panel
    Library:Corner(f, 6)
    
    local lbl = Instance.new("TextLabel", f)
    lbl.Text = title
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.Size = UDim2.new(0, 100, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLbl = Instance.new("TextLabel", f)
    valLbl.Text = tostring(default)
    valLbl.Position = UDim2.new(1, -45, 0, 0)
    valLbl.Size = UDim2.new(0, 30, 0, 30)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3 = Settings.Theme.Gold
    valLbl.Font = Enum.Font.Gotham
    
    local sliderBG = Instance.new("Frame", f)
    sliderBG.Size = UDim2.new(0.9, 0, 0, 4)
    sliderBG.Position = UDim2.new(0.05, 0, 0.7, 0)
    sliderBG.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Library:Corner(sliderBG, 2)
    
    local fill = Instance.new("Frame", sliderBG)
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Settings.Theme.Gold
    Library:Corner(fill, 2)
    
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
            local r = math.clamp((mouseLoc.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + ((max - min) * r))
            fill.Size = UDim2.new(r, 0, 1, 0)
            valLbl.Text = tostring(v)
            callback(v)
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end)
end

local function CreateToggle(title, callback)
    local f = Instance.new("TextButton", MainPage)
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = Settings.Theme.Panel
    f.Text = ""
    Library:Corner(f, 6)
    
    local lbl = Instance.new("TextLabel", f)
    lbl.Text = title
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local indicator = Instance.new("Frame", f)
    indicator.Size = UDim2.new(0, 30, 0, 16)
    indicator.Position = UDim2.new(1, -45, 0.5, -8)
    indicator.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Library:Corner(indicator, 8)
    
    local dot = Instance.new("Frame", indicator)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = Color3.fromRGB(200,200,200)
    Library:Corner(dot, 6)
    
    local on = false
    f.MouseButton1Click:Connect(function()
        on = not on
        callback(on)
        Library:Tween(indicator, {BackgroundColor3 = on and Settings.Theme.Gold or Color3.fromRGB(40,40,40)})
        Library:Tween(dot, {Position = on and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)})
    end)
end

-- WalkSpeed Logic & UI
CreateSlider("Walk Speed", 16, 250, 16, function(v) 
    Settings.Speed.Value = v
    if Settings.Speed.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)
CreateToggle("Enable Speed (Toggle)", function(v)
    Settings.Speed.Enabled = v
    if not v and LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end
end)

-- Fly Logic & UI
local function ToggleFly(v)
    Settings.Fly.Enabled = v
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    if v then
        local bv = Instance.new("BodyVelocity", hrp); bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bv.Name = "F_V"
        local bg = Instance.new("BodyGyro", hrp); bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9); bg.P = 9e4; bg.Name = "F_G"
        hum.PlatformStand = true
        
        task.spawn(function()
            while Settings.Fly.Enabled and char.Parent and hum.Health > 0 do
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

CreateSlider("Fly Speed", 20, 300, 50, function(v) Settings.Fly.Speed = v end)
CreateToggle("Enable Fly (Toggle)", function(v) ToggleFly(v) end)

-- [ TARGET TAB ]
local TargetPage, TargetBtn = CreateTab("Target", "🎯", 3, Settings.Theme.CrystalRed)
local TargetScroll = Instance.new("ScrollingFrame", TargetPage)
TargetScroll.Size = UDim2.new(1, 0, 1, 0)
TargetScroll.BackgroundTransparency = 1
TargetScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TargetScroll.CanvasSize = UDim2.new(0,0,0,0)
TargetScroll.ScrollBarThickness = 2
local TargetList = Instance.new("UIListLayout", TargetScroll); TargetList.Padding = UDim.new(0, 12)

-- Header Box (Player Input)
local TargetHeader = Instance.new("Frame", TargetScroll)
TargetHeader.Size = UDim2.new(1, 0, 0, 70)
TargetHeader.BackgroundColor3 = Settings.Theme.Panel
Library:Corner(TargetHeader, 8); Library:AddStroke(TargetHeader, Settings.Theme.Gold, 1)

local T_Avatar = Instance.new("ImageLabel", TargetHeader)
T_Avatar.Size = UDim2.new(0, 50, 0, 50)
T_Avatar.Position = UDim2.new(0, 10, 0.5, 0); T_Avatar.AnchorPoint = Vector2.new(0, 0.5)
T_Avatar.BackgroundColor3 = Color3.fromRGB(30,30,30)
T_Avatar.Image = "rbxassetid://0"
Library:Corner(T_Avatar, 25); Library:AddStroke(T_Avatar, Settings.Theme.Gold, 1)

local T_Input = Instance.new("TextBox", TargetHeader)
T_Input.Size = UDim2.new(0.6, 0, 0, 30)
T_Input.Position = UDim2.new(0, 70, 0.2, 0)
T_Input.BackgroundColor3 = Color3.fromRGB(12,12,12)
T_Input.Text = ""
T_Input.PlaceholderText = "Player Name..."
T_Input.TextColor3 = Color3.new(1,1,1)
T_Input.Font = Enum.Font.GothamBold
Library:Corner(T_Input, 6)

local T_Status = Instance.new("TextLabel", TargetHeader)
T_Status.Size = UDim2.new(0, 100, 0, 15)
T_Status.Position = UDim2.new(0, 70, 0.7, 0)
T_Status.Text = "WAITING"
T_Status.TextColor3 = Settings.Theme.SubText
T_Status.Font = Enum.Font.GothamBold
T_Status.TextXAlignment = Enum.TextXAlignment.Left
T_Status.BackgroundTransparency = 1

local function GetPlayer(name)
    name = name:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
            return p
        end
    end
    return nil
end

T_Input.FocusLost:Connect(function()
    local p = GetPlayer(T_Input.Text)
    if p then
        T_Input.Text = p.Name
        T_Avatar.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        T_Status.Text = "ONLINE"
        T_Status.TextColor3 = Settings.Theme.Success
    else
        T_Avatar.Image = "rbxassetid://0"
        T_Status.Text = "NOT FOUND"
        T_Status.TextColor3 = Settings.Theme.Error
    end
end)

-- Action Grid
local ActionContainer = Instance.new("Frame", TargetScroll)
ActionContainer.Size = UDim2.new(1, 0, 0, 140)
ActionContainer.BackgroundTransparency = 1
local ActionGrid = Instance.new("UIGridLayout", ActionContainer)
ActionGrid.CellSize = UDim2.new(0.48, 0, 0, 60)
ActionGrid.CellPadding = UDim2.new(0.04, 0, 0.1, 0)

local function CreateActionBtn(name, sub, callback)
    local b = Instance.new("TextButton", ActionContainer)
    b.BackgroundColor3 = Settings.Theme.Panel
    Library:Corner(b, 8); Library:AddStroke(b, Settings.Theme.SubText, 1)
    
    local t = Instance.new("TextLabel", b); t.Text = name; t.Size = UDim2.new(1,0,0,20); t.Position=UDim2.new(0,0,0,10); t.Font=Enum.Font.GothamBlack; t.TextColor3=Color3.new(1,1,1); t.BackgroundTransparency=1
    local s = Instance.new("TextLabel", b); s.Text = sub; s.Size = UDim2.new(1,0,0,15); s.Position=UDim2.new(0,0,0,32); s.Font=Enum.Font.Gotham; s.TextColor3=Settings.Theme.SubText; s.BackgroundTransparency=1; s.TextSize=11

    local on = false
    b.MouseButton1Click:Connect(function()
        on = not on
        callback(on)
        Library:Tween(b, {BackgroundColor3 = on and Settings.Theme.Gold or Settings.Theme.Panel})
        t.TextColor3 = on and Color3.new(0,0,0) or Color3.new(1,1,1)
        s.TextColor3 = on and Color3.fromRGB(50,50,50) or Settings.Theme.SubText
    end)
end

-- 1. BANG (R15 COMPATIBLE CFrame SINE WAVE)
CreateActionBtn("BANG", "פיצוץ", function(state)
    if not state then
        if TrollConnection then TrollConnection:Disconnect(); TrollConnection = nil end
        if LocalPlayer.Character then
            -- Stop R6 Anim if any
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then for _, anim in pairs(hum:GetPlayingAnimationTracks()) do if anim.Animation.AnimationId == "rbxassetid://148840371" then anim:Stop() end end end
        end
        return
    end
    
    local target = GetPlayer(T_Input.Text)
    if target and target.Character and LocalPlayer.Character then
        local P = Players.LocalPlayer
        local C = P.Character
        local H = C:WaitForChild('Humanoid')
        
        -- R6 Fallback
        if H.RigType == Enum.HumanoidRigType.R6 then
            local AnimID = "rbxassetid://148840371"
            local A = Instance.new("Animation"); A.AnimationId = AnimID
            local Track = H:LoadAnimation(A); Track.Looped = true; Track:Play(); Track:AdjustSpeed(2.5)
        end
        
        -- Universal CFrame Loop
        TrollConnection = RunService.Stepped:Connect(function()
            if not target.Character or not P.Character then 
                if TrollConnection then TrollConnection:Disconnect() end
                return 
            end
            pcall(function()
                local targetHRP = target.Character:WaitForChild('HumanoidRootPart')
                local myHRP = C:WaitForChild('HumanoidRootPart')
                
                -- Sine wave math for thrust motion
                local velocity = 20 
                local distance = 0.5 
                local thrust = math.sin(tick() * velocity) * distance
                
                local behindPos = targetHRP.CFrame * CFrame.new(0, 0, 1.1 + thrust)
                myHRP.CFrame = CFrame.lookAt(behindPos.Position, targetHRP.Position)
            end)
        end)
    end
end)

-- 2. SPECTATE
CreateActionBtn("SPECTATE", "צפייה", function(state)
    local target = GetPlayer(T_Input.Text)
    if state and target and target.Character then
        workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
    else
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end)

-- Helper for Sitting
local function PlaySit(play)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if not hum then return end
    if play then
        hum.Sit = true
        if not SitAnimTrack then
            local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://2506281703" 
            local animator = hum:FindFirstChild("Animator") or hum:WaitForChild("Animator")
            SitAnimTrack = animator:LoadAnimation(anim)
        end
        SitAnimTrack:Play()
    else
        if SitAnimTrack then SitAnimTrack:Stop(); SitAnimTrack = nil end
        hum.Sit = false
    end
end

-- 3. HEADSIT
local HeadSitConnection = nil
CreateActionBtn("HEADSIT", "על הראש", function(state)
    isSittingAction = state
    if not state then
        PlaySit(false)
        if HeadSitConnection then HeadSitConnection:Disconnect(); HeadSitConnection = nil end
        return
    end
    
    local target = GetPlayer(T_Input.Text)
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

-- 4. BACKPACK
local BackpackConnection = nil
CreateActionBtn("BACKPACK", "על הגב", function(state)
    isSittingAction = state
    if not state then
        PlaySit(false)
        if BackpackConnection then BackpackConnection:Disconnect(); BackpackConnection = nil end
        return
    end
    
    local target = GetPlayer(T_Input.Text)
    if target and target.Character then
         PlaySit(true)
         BackpackConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                 if not target.Character or not LocalPlayer.Character then return end
                 local h = LocalPlayer.Character.Humanoid
                 if not h.Sit then h.Sit = true end 
                 LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0.7, 0.5) * CFrame.Angles(0, math.rad(180), 0)
                 LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.zero
            end)
         end)
    end
end)

-- SCANNER
local ScannerFrame = Instance.new("Frame", TargetScroll)
ScannerFrame.Size = UDim2.new(1, 0, 0, 200)
ScannerFrame.BackgroundColor3 = Settings.Theme.Panel
Library:Corner(ScannerFrame, 8); Library:AddStroke(ScannerFrame, Settings.Theme.Gold, 1)

local ScanBtn = Instance.new("TextButton", ScannerFrame)
ScanBtn.Size = UDim2.new(1, -20, 0, 30)
ScanBtn.Position = UDim2.new(0, 10, 0, 10)
ScanBtn.BackgroundColor3 = Settings.Theme.Gold
ScanBtn.Text = "Scan Inventory (סרוק)"
ScanBtn.Font = Enum.Font.GothamBold; ScanBtn.TextColor3 = Color3.new(0,0,0); ScanBtn.TextSize = 14
Library:Corner(ScanBtn, 6)

local ScanResults = Instance.new("ScrollingFrame", ScannerFrame)
ScanResults.Size = UDim2.new(1, -20, 1, -50)
ScanResults.Position = UDim2.new(0, 10, 0, 45)
ScanResults.BackgroundTransparency = 1
ScanResults.ScrollBarThickness = 2
local ScanList = Instance.new("UIListLayout", ScanResults); ScanList.Padding = UDim.new(0, 5)

local IgnoreList = { ["Cola"] = true, ["Pizza"] = true, ["Burger"] = true } -- Shortened for brevity, assumes standard ignore

ScanBtn.MouseButton1Click:Connect(function()
    for _,v in pairs(ScanResults:GetChildren()) do if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end end
    local target = GetPlayer(T_Input.Text)
    if not target then return end
    
    local itemsCount = {}
    local itemsIcon = {}

    local function ScanFolder(f)
        if not f then return end
        for _, item in pairs(f:GetChildren()) do
            if item:IsA("Tool") and not IgnoreList[item.Name] then
                 itemsCount[item.Name] = (itemsCount[item.Name] or 0) + 1
                 if item.TextureId ~= "" then itemsIcon[item.Name] = item.TextureId end
            end
        end
    end
    
    ScanFolder(target:FindFirstChild("Backpack"))
    ScanFolder(target:FindFirstChild("Inventory")) -- Custom Inventory folder support
    if target.Character then for _,c in pairs(target.Character:GetChildren()) do if c:IsA("Tool") then ScanFolder({c}) end end end

    for name, count in pairs(itemsCount) do
        local row = Instance.new("Frame", ScanResults)
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        Library:Corner(row, 4)
        
        local ico = Instance.new("ImageLabel", row)
        ico.Size = UDim2.new(0, 30, 0, 30); ico.Position = UDim2.new(0, 5, 0.5, 0); ico.AnchorPoint = Vector2.new(0, 0.5); ico.BackgroundTransparency = 1
        if itemsIcon[name] then ico.Image = itemsIcon[name] else ico.Image = "rbxassetid://6503956166" end
        
        local txt = Instance.new("TextLabel", row)
        txt.Text = name .. " (x"..count..")"
        txt.Size = UDim2.new(1, -50, 1, 0); txt.Position = UDim2.new(0, 45, 0, 0)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.new(1,1,1); txt.Font = Enum.Font.Gotham; txt.TextXAlignment = Enum.TextXAlignment.Left
    end
end)

-- [ CREDITS TAB ]
local CreditsPage, CreditsBtn = CreateTab("Credits", "ℹ️", 4, Settings.Theme.ShardBlue)
local CreditsList = Instance.new("UIListLayout", CreditsPage); CreditsList.Padding = UDim.new(0, 10)

local function CreateCredit(name, role, discord)
    local f = Instance.new("Frame", CreditsPage)
    f.Size = UDim2.new(1, 0, 0, 60)
    f.BackgroundColor3 = Settings.Theme.Panel
    Library:Corner(f, 8); Library:AddStroke(f, Settings.Theme.Gold, 1)
    
    local n = Instance.new("TextLabel", f)
    n.Text = name
    n.Size = UDim2.new(1, -20, 0, 20); n.Position = UDim2.new(0, 10, 0, 10)
    n.Font = Enum.Font.GothamBlack; n.TextColor3 = Settings.Theme.Gold; n.BackgroundTransparency=1; n.TextXAlignment = Enum.TextXAlignment.Left; n.TextSize = 16
    
    local r = Instance.new("TextLabel", f)
    r.Text = role
    r.Size = UDim2.new(1, -20, 0, 20); r.Position = UDim2.new(0, 10, 0, 30)
    r.Font = Enum.Font.Gotham; r.TextColor3 = Settings.Theme.SubText; r.BackgroundTransparency=1; r.TextXAlignment = Enum.TextXAlignment.Left
    
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(0, 80, 0, 24); b.Position = UDim2.new(1, -90, 0.5, -12)
    b.BackgroundColor3 = Settings.Theme.Discord
    b.Text = "Discord"
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    Library:Corner(b, 4)
    b.MouseButton1Click:Connect(function() setclipboard(discord) b.Text="Copied!" task.wait(1) b.Text="Discord" end)
end

CreateCredit("Neho", "Founder", "nx3ho")
CreateCredit("BadShot", "CoFounder", "8adshot3")

--// 9. FINAL TOUCHES & LOOPS
UIS.InputBegan:Connect(function(i,g)
    if not g and i.KeyCode == Settings.Keys.Menu then 
        MainFrame.Visible = not MainFrame.Visible
        MiniPasta.Visible = not MainFrame.Visible
    end
end)

-- Run Anti-AFK
task.spawn(function() 
    while true do 
        task.wait(60)
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    end 
end)

-- Main Loop for Speed enforcement
RunService.RenderStepped:Connect(function()
    if Settings.Speed.Enabled and LocalPlayer.Character then 
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        if h and h.WalkSpeed ~= Settings.Speed.Value then h.WalkSpeed = Settings.Speed.Value end
    end
end)

-- Start Tabs
CreditsBtn.MouseButton1Click:Fire() -- Load something initally
MainBtn.MouseButton1Click:Fire()

print("[SYSTEM] Spaghetti Mafia Hub v1.5 (Visual Overhaul) Loaded")
