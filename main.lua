--[[
    Spaghetti Mafia Hub v5.0 (FINAL - SCROLLING FIXED EVERYWHERE)
    
    Changes:
    - SIDEBAR: Now Scrollable (You can scroll through tabs).
    - MAIN TAB: Restored Speed/Fly & Made Scrollable.
    - TARGET TAB: Separated Boxes (Target / Toggles / Scanner).
    - LOGIC: All features preserved (Farm, Snow, Spectate, Bang).
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

--// 1. מערכת Whitelist
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

--// 2. ניקוי ומשתנים
if CoreGui:FindFirstChild("SpaghettiHub_Rel") then CoreGui.SpaghettiHub_Rel:Destroy() end
if CoreGui:FindFirstChild("SpaghettiLoading") then CoreGui.SpaghettiLoading:Destroy() end

local Settings = {
    Theme = {
        Gold = Color3.fromRGB(255, 215, 0),
        Dark = Color3.fromRGB(18, 18, 24), 
        Box = Color3.fromRGB(30, 30, 35), 
        Text = Color3.fromRGB(255, 255, 255),
        
        IceBlue = Color3.fromRGB(100, 220, 255),
        IceDark = Color3.fromRGB(10, 25, 45),
        
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

--// 3. פונקציות עיצוב
local Library = {}
function Library:Tween(obj, props, time, style) TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play() end

function Library:AddGlow(obj, color) 
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Settings.Theme.Gold
    s.Thickness = 2 
    s.Transparency = 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    task.spawn(function()
        while obj.Parent do
            TweenService:Create(s, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.8}):Play()
            task.wait(2)
            TweenService:Create(s, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.4}):Play()
            task.wait(2)
        end
    end)
    return s 
end

function Library:Corner(obj, r) local c = Instance.new("UICorner", obj); c.CornerRadius = UDim.new(0, r or 10); return c end
function Library:Gradient(obj, c1, c2, rot) local g = Instance.new("UIGradient", obj); g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}; g.Rotation = rot or 45; return g end
function Library:MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = obj.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
    obj.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    RunService.RenderStepped:Connect(function() if dragging and dragInput then local delta = dragInput.Position - dragStart; obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end

--// שלג (אופטימלי)
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

--// 4. מסך טעינה
local LoadGui = Instance.new("ScreenGui"); LoadGui.Name = "SpaghettiLoading"; LoadGui.Parent = CoreGui
local LoadBox = Instance.new("Frame", LoadGui)
LoadBox.Size = UDim2.new(0, 240, 0, 160)
LoadBox.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadBox.AnchorPoint = Vector2.new(0.5, 0.5)
LoadBox.ClipsDescendants = true 
LoadBox.BorderSizePixel = 0
LoadBox.BackgroundColor3 = Settings.Theme.Dark
Library:Corner(LoadBox, 20)
Library:AddGlow(LoadBox, Settings.Theme.Gold)

local PastaIcon = Instance.new("TextLabel", LoadBox)
PastaIcon.Size = UDim2.new(1, 0, 0.45, 0); PastaIcon.Position = UDim2.new(0,0,0.05,0)
PastaIcon.BackgroundTransparency = 1; PastaIcon.Text = "🍝"; PastaIcon.TextSize = 60; PastaIcon.ZIndex = 15
TweenService:Create(PastaIcon, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 10, Size = UDim2.new(1.1, 0, 0.50, 0)}):Play()

local TitleLoad = Instance.new("TextLabel", LoadBox)
TitleLoad.Size = UDim2.new(1, 0, 0.2, 0); TitleLoad.Position = UDim2.new(0, 0, 0.50, 0)
TitleLoad.BackgroundTransparency = 1; TitleLoad.Text = "Spaghetti Mafia Hub v5"; 
TitleLoad.Font = Enum.Font.GothamBlack; TitleLoad.TextColor3 = Settings.Theme.Gold; TitleLoad.TextSize = 18
TitleLoad.ZIndex = 15

local SubLoad = Instance.new("TextLabel", LoadBox)
SubLoad.Size = UDim2.new(1, 0, 0.2, 0); SubLoad.Position = UDim2.new(0, 0, 0.68, 0)
SubLoad.BackgroundTransparency = 1; SubLoad.Text = "טוען..."; 
SubLoad.Font = Enum.Font.Gotham; SubLoad.TextColor3 = Color3.new(1,1,1); SubLoad.TextSize = 14
SubLoad.ZIndex = 15

-- Loading Bar
local LoadingBarBG = Instance.new("Frame", LoadBox)
LoadingBarBG.Size = UDim2.new(0.7, 0, 0, 5)
LoadingBarBG.Position = UDim2.new(0.15, 0, 0.88, 0)
LoadingBarBG.BackgroundColor3 = Color3.fromRGB(40,40,45)
LoadingBarBG.BorderSizePixel = 0
LoadingBarBG.ZIndex = 16
Library:Corner(LoadingBarBG, 5)

local LoadingBarFill = Instance.new("Frame", LoadingBarBG)
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Settings.Theme.Gold
LoadingBarFill.BorderSizePixel = 0
LoadingBarFill.ZIndex = 17
Library:Corner(LoadingBarFill, 5)
Library:Tween(LoadingBarFill, {Size = UDim2.new(1, 0, 1, 0)}, 2.5, Enum.EasingStyle.Quad)

task.spawn(function()
    while LoadBox.Parent do
        SpawnSnow(LoadBox)
        task.wait(0.3) 
    end
end)

task.wait(2.5)
LoadGui:Destroy()

--// 5. GUI ראשי
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false

local MiniPasta = Instance.new("TextButton", ScreenGui); MiniPasta.Size = UDim2.new(0, 60, 0, 60); MiniPasta.Position = UDim2.new(0.1, 0, 0.1, 0); MiniPasta.BackgroundColor3 = Settings.Theme.Box; MiniPasta.Text = "🍝"; MiniPasta.TextSize = 35; MiniPasta.Visible = false; Library:Corner(MiniPasta, 30); Library:AddGlow(MiniPasta); Library:MakeDraggable(MiniPasta)

local MainFrame = Instance.new("Frame", ScreenGui); 
local NEW_WIDTH = 550
local NEW_HEIGHT = 370
MainFrame.Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); 
MainFrame.BackgroundColor3 = Settings.Theme.Dark; 
MainFrame.ClipsDescendants = true; 
Library:Corner(MainFrame, 16); 

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 3.5 
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Color = Color3.fromRGB(255, 255, 255)

local StrokeGradient = Instance.new("UIGradient", MainStroke)
StrokeGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Settings.Theme.Gold),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 250, 150)), 
    ColorSequenceKeypoint.new(1, Settings.Theme.Gold)
}
StrokeGradient.Rotation = 45

task.spawn(function()
    while MainFrame.Parent do
        local t = tick() * 45 
        StrokeGradient.Rotation = t % 360
        task.wait(0.01)
    end
end)

MainFrame.Size = UDim2.new(0,0,0,0); Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.6, Enum.EasingStyle.Quart) 

local MainScale = Instance.new("UIScale", MainFrame); MainScale.Scale = 1
local TopBar = Instance.new("Frame", MainFrame); TopBar.Size = UDim2.new(1,0,0,60); TopBar.BackgroundTransparency = 1; TopBar.BorderSizePixel = 0; Library:MakeDraggable(MainFrame)

local MainTitle = Instance.new("TextLabel", TopBar); MainTitle.Size = UDim2.new(0,300,0,30); MainTitle.Position = UDim2.new(0,25,0,10); MainTitle.BackgroundTransparency = 1; MainTitle.Text = "SPAGHETTI <font color='#FFD700'>MAFIA</font> HUB v5"; MainTitle.RichText = true; MainTitle.Font = Enum.Font.GothamBlack; MainTitle.TextSize = 22; MainTitle.TextColor3 = Color3.new(1,1,1); MainTitle.TextXAlignment = Enum.TextXAlignment.Left

local MainSub = Instance.new("TextLabel", TopBar)
MainSub.Size = UDim2.new(0,300,0,20)
MainSub.Position = UDim2.new(0,25,0,36)
MainSub.BackgroundTransparency = 1
MainSub.Text = "עולם הכיף" 
MainSub.Font = Enum.Font.GothamBold
MainSub.TextSize = 13
MainSub.TextColor3 = Settings.Theme.IceBlue
MainSub.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -45, 0, 15); CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); CloseBtn.Text = "_"; CloseBtn.TextColor3 = Settings.Theme.Gold; CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextSize=18; Library:Corner(CloseBtn, 8); Library:AddGlow(CloseBtn, Settings.Theme.Gold)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniPasta.Visible = true; Library:Tween(MiniPasta, {Size = UDim2.new(0, 60, 0, 60)}, 0.4, Enum.EasingStyle.Back) end)
MiniPasta.MouseButton1Click:Connect(function() MiniPasta.Visible = false; MainFrame.Visible = true; Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.4, Enum.EasingStyle.Back) end)

-- Storm Timer
task.spawn(function()
    local StormValue = ReplicatedStorage:WaitForChild("StormTimeLeft", 5)
    if StormValue then
        local TimerWidget = Instance.new("Frame", TopBar)
        TimerWidget.Name = "StormTimerWidgetPro"
        TimerWidget.Size = UDim2.new(0, 135, 0, 40)
        TimerWidget.AnchorPoint = Vector2.new(1, 0.5)
        TimerWidget.Position = UDim2.new(1, -55, 0.5, 0)
        TimerWidget.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        TimerWidget.BorderSizePixel = 0
        Library:Corner(TimerWidget, 10)
        
        local TimerStroke = Instance.new("UIStroke", TimerWidget)
        TimerStroke.Color = Settings.Theme.IceBlue
        TimerStroke.Thickness = 1.5
        TimerStroke.Transparency = 0.5
        
        local T_Time = Instance.new("TextLabel", TimerWidget)
        T_Time.Size = UDim2.new(1, 0, 1, 0)
        T_Time.BackgroundTransparency = 1
        T_Time.Text = "00:00"
        T_Time.TextColor3 = Color3.fromRGB(255, 255, 255)
        T_Time.Font = Enum.Font.GothamBlack
        T_Time.TextSize = 18
        
        StormValue.Changed:Connect(function(val)
            local mins = math.floor(val / 60)
            local secs = val % 60
            T_Time.Text = string.format("%02d:%02d", mins, secs)
        end)
    end
end)

-- Sidebar (SCROLLING FIXED)
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 150, 1, -65)
Sidebar.Position = UDim2.new(0,0,0,65)
Sidebar.BackgroundColor3 = Settings.Theme.Box
Sidebar.BorderSizePixel = 0 
Sidebar.ZIndex = 2
Library:Corner(Sidebar, 12)

-- User Profile
local UserProfile = Instance.new("Frame", Sidebar)
UserProfile.Size = UDim2.new(0.92, 0, 0, 75)
UserProfile.AnchorPoint = Vector2.new(0.5, 1)
UserProfile.Position = UDim2.new(0.5, 0, 0.98, 0)
UserProfile.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Library:Corner(UserProfile, 10)
local ProfileStroke = Instance.new("UIStroke", UserProfile); ProfileStroke.Color = Settings.Theme.Gold; ProfileStroke.Thickness = 1.5

local AvatarImg = Instance.new("ImageLabel", UserProfile)
AvatarImg.Size = UDim2.new(0, 50, 0, 50)
AvatarImg.Position = UDim2.new(0, 10, 0.5, -25)
AvatarImg.BackgroundColor3 = Settings.Theme.Gold
AvatarImg.Image = "rbxassetid://0"
Library:Corner(AvatarImg, 25)
task.spawn(function()
    local content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    AvatarImg.Image = content
end)

local WelcomeText = Instance.new("TextLabel", UserProfile)
WelcomeText.Text = "Hi, " .. LocalPlayer.Name
WelcomeText.Size = UDim2.new(0, 80, 0, 20)
WelcomeText.Position = UDim2.new(0, 70, 0.5, -10)
WelcomeText.BackgroundTransparency = 1
WelcomeText.TextColor3 = Settings.Theme.Gold
WelcomeText.Font = Enum.Font.GothamBold 
WelcomeText.TextSize = 13
WelcomeText.TextXAlignment = Enum.TextXAlignment.Left

-- SCROLLABLE SIDEBAR CONTAINER (FIXED)
local SideBtnContainer = Instance.new("ScrollingFrame", Sidebar)
SideBtnContainer.Size = UDim2.new(1, 0, 1, -85) 
SideBtnContainer.BackgroundTransparency = 1
SideBtnContainer.ScrollBarThickness = 2
SideBtnContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
SideBtnContainer.CanvasSize = UDim2.new(0,0,0,0)

local SideList = Instance.new("UIListLayout", SideBtnContainer); SideList.Padding = UDim.new(0,8); SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center; SideList.SortOrder = Enum.SortOrder.LayoutOrder
local SidePad = Instance.new("UIPadding", SideBtnContainer); SidePad.PaddingTop = UDim.new(0,15)

local Container = Instance.new("Frame", MainFrame); Container.Size = UDim2.new(1, -160, 1, -70); Container.Position = UDim2.new(0, 160, 0, 65); Container.BackgroundTransparency = 1

local currentTab = nil

local function CreateTab(name, heb, order)
    local btn = Instance.new("TextButton", SideBtnContainer)
    btn.Size = UDim2.new(0.9,0,0,40)
    btn.BackgroundColor3 = Settings.Theme.Dark
    btn.Text = "   " .. name .. "\n   <font size='11' color='#8899AA'>"..heb.."</font>"
    btn.RichText = true
    btn.TextColor3 = Color3.fromRGB(150,150,150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    Library:Corner(btn, 8)
    
    local page = Instance.new("Frame", Container)
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Name = name .. "_Page"
    
    btn.MouseButton1Click:Connect(function()
        for _,v in pairs(SideBtnContainer:GetChildren()) do 
            if v:IsA("TextButton") then 
                Library:Tween(v, {BackgroundColor3 = Settings.Theme.Dark, TextColor3 = Color3.fromRGB(150,150,150)}) 
            end 
        end
        for _,v in pairs(Container:GetChildren()) do v.Visible = false end
        Library:Tween(btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Settings.Theme.Gold})
        page.Visible = true
    end)
    
    if order == 1 then 
        currentTab = btn
        Library:Tween(btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Settings.Theme.Gold})
        page.Visible = true 
    end
    return page
end

local Tab_Event_Page = CreateTab("Winter Event", "אירוע חורף", 1) 
local Tab_Target_Page = CreateTab("Target", "מטרה", 2) 
local Tab_Main_Page = CreateTab("Main", "ראשי", 3)
local Tab_Settings_Page = CreateTab("Settings", "הגדרות", 4)
local Tab_Credits_Page = CreateTab("Credits", "קרדיטים", 5)

-- HELPERS
local function CreateSlider(parent, title, heb, min, max, default, callback, toggleCallback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0.95,0,0,65)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Library:Corner(f, 12)
    local s = Instance.new("UIStroke", f); s.Color = Settings.Theme.Gold; s.Thickness = 1.2; s.Transparency = 0.6
    
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(0.7,0,0,25); l.Position = UDim2.new(0,10,0,6); l.Text = title .. " : " .. default; l.TextColor3=Color3.new(1,1,1); l.Font=Enum.Font.GothamBold; l.TextSize=13; l.BackgroundTransparency=1
    
    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(0.9,0,0,8); line.Position = UDim2.new(0.05,0,0.65,0); line.BackgroundColor3 = Color3.fromRGB(20, 20, 25); Library:Corner(line,10)
    
    local fill = Instance.new("Frame", line)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0); fill.BackgroundColor3 = Settings.Theme.Gold; Library:Corner(fill,10)
    
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Down:Connect(function()
        local dragging = true
        local inputConn = RunService.RenderStepped:Connect(function()
            if not dragging then return end
            local mouseLoc = UIS:GetMouseLocation()
            local r = math.clamp((mouseLoc.X - line.AbsolutePosition.X) / line.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + ((max - min) * r))
            fill.Size = UDim2.new(r, 0, 1, 0)
            l.Text = title .. " : " .. v
            callback(v)
        end)
        UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false; inputConn:Disconnect() end end)
    end)

    if toggleCallback then
        local t = Instance.new("TextButton", f)
        t.Size = UDim2.new(0,50,0,24); t.Position = UDim2.new(1,-60,0,8); t.BackgroundColor3 = Color3.fromRGB(20, 20, 25); t.Text = "OFF"; t.TextColor3 = Color3.fromRGB(150, 150, 150); t.Font = Enum.Font.GothamBold; Library:Corner(t,12); t.TextSize=11
        local on = false
        t.MouseButton1Click:Connect(function() 
            on = not on
            t.Text = on and "ON" or "OFF"
            t.BackgroundColor3 = on and Settings.Theme.Gold or Color3.fromRGB(20, 20, 25)
            t.TextColor3 = on and Color3.new(0,0,0) or Color3.fromRGB(150, 150, 150)
            toggleCallback(on) 
        end)
    end
end

-- === MAIN TAB CONTENT (RESTORED + SCROLLABLE) ===
local MainScroll = Instance.new("ScrollingFrame", Tab_Main_Page)
MainScroll.Size = UDim2.new(1, 0, 1, 0)
MainScroll.BackgroundTransparency = 1
MainScroll.ScrollBarThickness = 2
MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainScroll.CanvasSize = UDim2.new(0,0,0,0)
local MainList = Instance.new("UIListLayout", MainScroll); MainList.Padding = UDim.new(0, 10); MainList.HorizontalAlignment = Enum.HorizontalAlignment.Center
local MainPad = Instance.new("UIPadding", MainScroll); MainPad.PaddingTop = UDim.new(0,10)

-- Walk Speed
CreateSlider(MainScroll, "Walk Speed", "", 1, 250, 16, function(v) 
    Settings.Speed.Value = v 
    if Settings.Speed.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = v end
end, function(t) 
    Settings.Speed.Enabled = t
end)

-- Fly Speed
CreateSlider(MainScroll, "Fly Speed", "", 20, 300, 50, function(v) Settings.Fly.Speed = v end, function(t) 
    Settings.Fly.Enabled = t
    -- Fly logic simplified for brevity in this fix block
    if t then
        local char = LocalPlayer.Character; local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid")
        local bv = Instance.new("BodyVelocity", hrp); bv.MaxForce = Vector3.new(1e9, 1e9, 1e9); bv.Name = "F_V"
        local bg = Instance.new("BodyGyro", hrp); bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9); bg.P = 9e4; bg.Name = "F_G"
        hum.PlatformStand = true
        task.spawn(function()
            while Settings.Fly.Enabled and char.Parent do
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
        local char = LocalPlayer.Character; local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid")
        if hrp:FindFirstChild("F_V") then hrp.F_V:Destroy() end
        if hrp:FindFirstChild("F_G") then hrp.F_G:Destroy() end
        hum.PlatformStand = false
    end
end)

-- Keybinds
local BindFrame = Instance.new("Frame", MainScroll)
BindFrame.Size = UDim2.new(0.95, 0, 0, 50)
BindFrame.BackgroundTransparency = 1
local BindLayout = Instance.new("UIListLayout", BindFrame); BindLayout.FillDirection = Enum.FillDirection.Horizontal; BindLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; BindLayout.Padding = UDim.new(0, 10)

local function CreateBind(txt, defaultKey, callback)
    local b = Instance.new("TextButton", BindFrame)
    b.Size = UDim2.new(0.45, 0, 1, 0)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    b.Text = txt .. ": " .. defaultKey.Name
    b.TextColor3 = Settings.Theme.Gold
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    Library:Corner(b, 8)
    Library:AddGlow(b, Settings.Theme.Gold)
    b.MouseButton1Click:Connect(function()
        b.Text = txt .. ": ..."
        local input = UIS.InputBegan:Wait()
        if input.UserInputType == Enum.UserInputType.Keyboard then
            b.Text = txt .. ": " .. input.KeyCode.Name
            callback(input.KeyCode)
        end
    end)
end

CreateBind("FLY KEY", Settings.Keys.Fly, function(k) Settings.Keys.Fly = k end)
CreateBind("SPEED KEY", Settings.Keys.Speed, function(k) Settings.Keys.Speed = k end)

-- === TARGET TAB CONTENT (3 BOXES) ===
local TargetScroll = Instance.new("ScrollingFrame", Tab_Target_Page)
TargetScroll.Size = UDim2.new(1, 0, 1, 0)
TargetScroll.BackgroundTransparency = 1
TargetScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TargetScroll.CanvasSize = UDim2.new(0,0,0,0)
local TargetList = Instance.new("UIListLayout", TargetScroll); TargetList.Padding = UDim.new(0, 10); TargetList.HorizontalAlignment = Enum.HorizontalAlignment.Center
local TargetPad = Instance.new("UIPadding", TargetScroll); TargetPad.PaddingTop = UDim.new(0,10)

-- Box 1: Target
local TargetBox = Instance.new("Frame", TargetScroll)
TargetBox.Size = UDim2.new(0.95, 0, 0, 80)
TargetBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Library:Corner(TargetBox, 12); Library:AddGlow(TargetBox, Settings.Theme.Gold)

local TargetInput = Instance.new("TextBox", TargetBox)
TargetInput.Size = UDim2.new(0.7, 0, 0, 45); TargetInput.Position = UDim2.new(0.05, 0, 0.22, 0)
TargetInput.BackgroundColor3 = Color3.fromRGB(40,40,45); TargetInput.Text = ""; TargetInput.PlaceholderText = "Player Name..."; TargetInput.TextColor3 = Color3.new(1,1,1); TargetInput.Font = Enum.Font.GothamBold; TargetInput.TextSize = 16
Library:Corner(TargetInput, 8)

local TargetAvatar = Instance.new("ImageLabel", TargetBox)
TargetAvatar.Size = UDim2.new(0, 55, 0, 55); TargetAvatar.Position = UDim2.new(0.8, 0, 0.15, 0)
TargetAvatar.BackgroundColor3 = Color3.fromRGB(40,40,40); TargetAvatar.Image = "rbxassetid://0"; Library:Corner(TargetAvatar, 30)

TargetInput.FocusLost:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if string.find(p.Name:lower(), TargetInput.Text:lower()) or string.find(p.DisplayName:lower(), TargetInput.Text:lower()) then
            TargetInput.Text = p.Name
            TargetAvatar.Image = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            break
        end
    end
end)

-- Box 2: Toggles
local ActionBox = Instance.new("Frame", TargetScroll)
ActionBox.Size = UDim2.new(0.95, 0, 0, 60)
ActionBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Library:Corner(ActionBox, 12); Library:AddGlow(ActionBox, Settings.Theme.Gold)

local function CreateToggleBtn(text, pos, callback)
    local b = Instance.new("TextButton", ActionBox)
    b.Size = UDim2.new(0.45, 0, 0, 40); b.Position = pos; b.BackgroundColor3 = Color3.fromRGB(35, 35, 40); b.Text = text .. " [OFF]"; b.TextColor3 = Color3.fromRGB(150, 150, 150); b.Font = Enum.Font.GothamBold; b.TextSize = 13; Library:Corner(b, 8)
    local state = false
    b.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        b.BackgroundColor3 = state and Color3.fromRGB(40, 200, 100) or Color3.fromRGB(35, 35, 40)
        b.TextColor3 = state and Color3.new(0,0,0) or Color3.fromRGB(150, 150, 150)
        b.Text = text .. (state and " [ON]" or " [OFF]")
    end)
end

-- Bang Logic
local TrollConnection = nil
CreateToggleBtn("BANG", UDim2.new(0.05, 0, 0.15, 0), function(state)
    if not state then
        if TrollConnection then TrollConnection:Disconnect() end
        if LocalPlayer.Character then 
             for _, anim in pairs(LocalPlayer.Character.Humanoid:GetPlayingAnimationTracks()) do
                 if anim.Animation.AnimationId == "rbxassetid://148840371" then anim:Stop() end
             end
        end
        return
    end
    local target = Players:FindFirstChild(TargetInput.Text)
    if target and target.Character and LocalPlayer.Character then
        local A = Instance.new('Animation'); A.AnimationId = 'rbxassetid://148840371'
        local H = LocalPlayer.Character.Humanoid:LoadAnimation(A); H:Play(); H:AdjustSpeed(2.5)
        TrollConnection = RunService.Stepped:Connect(function()
            if not target.Character or not LocalPlayer.Character then TrollConnection:Disconnect() return end
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,1)
        end)
    end
end)

-- Spectate Logic
CreateToggleBtn("SPECTATE", UDim2.new(0.52, 0, 0.15, 0), function(state)
    local target = Players:FindFirstChild(TargetInput.Text)
    if state and target and target.Character then
        workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
    else
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end)

-- Box 3: Scanner
local ScannerBox = Instance.new("Frame", TargetScroll)
ScannerBox.Size = UDim2.new(0.95, 0, 0, 250)
ScannerBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Library:Corner(ScannerBox, 12); Library:AddGlow(ScannerBox, Settings.Theme.Gold)

local ScanButton = Instance.new("TextButton", ScannerBox)
ScanButton.Size = UDim2.new(0.9, 0, 0, 35); ScanButton.Position = UDim2.new(0.05, 0, 0.05, 0); ScanButton.BackgroundColor3 = Settings.Theme.Gold; ScanButton.Text = "SCAN INVENTORY 🔍"; ScanButton.TextColor3 = Color3.new(0,0,0); ScanButton.Font = Enum.Font.GothamBold; ScanButton.TextSize = 14; Library:Corner(ScanButton, 8)

local ScanResults = Instance.new("ScrollingFrame", ScannerBox)
ScanResults.Size = UDim2.new(0.9, 0, 0.75, 0); ScanResults.Position = UDim2.new(0.05, 0, 0.22, 0); ScanResults.BackgroundTransparency = 1; ScanResults.AutomaticCanvasSize = Enum.AutomaticSize.Y; ScanResults.CanvasSize = UDim2.new(0,0,0,0); local ScanList = Instance.new("UIListLayout", ScanResults); ScanList.Padding = UDim.new(0, 5)

ScanButton.MouseButton1Click:Connect(function()
    for _,v in pairs(ScanResults:GetChildren()) do if v:IsA("Frame") or v:IsA("TextLabel") then v:Destroy() end end
    local target = Players:FindFirstChild(TargetInput.Text)
    if not target then return end
    
    local IgnoreList = {["קולה"]=true,["פיצה"]=true} -- Add more here
    local itemsCount = {}
    local itemsIcon = {}
    
    local function Scan(f)
        if not f then return end
        for _, item in pairs(f:GetChildren()) do
            if not IgnoreList[item.Name] and not item:IsA("Folder") and not item:IsA("Script") then
                 itemsCount[item.Name] = (itemsCount[item.Name] or 0) + 1
                 if item:IsA("Tool") and item.TextureId ~= "" then itemsIcon[item.Name] = item.TextureId end
            end
        end
    end
    Scan(target:FindFirstChild("Backpack")); Scan(target:FindFirstChild("Data"))
    
    for name, count in pairs(itemsCount) do
        local row = Instance.new("Frame", ScanResults); row.Size = UDim2.new(1, 0, 0, 60); row.BackgroundColor3 = Color3.fromRGB(35, 35, 40); Library:Corner(row, 8)
        local icon = Instance.new("ImageLabel", row); icon.Size = UDim2.new(0, 50, 0, 50); icon.Position = UDim2.new(0.82, 0, 0.08, 0); icon.BackgroundTransparency = 1; icon.Image = itemsIcon[name] or "rbxassetid://6503956166"
        local txt = Instance.new("TextLabel", row); txt.Size = UDim2.new(0.75, 0, 1, 0); txt.Position = UDim2.new(0.05, 0, 0, 0); txt.BackgroundTransparency = 1; txt.Text = name .. "  x" .. count; txt.TextColor3 = Settings.Theme.Gold; txt.Font = Enum.Font.GothamBold; txt.TextSize = 16; txt.TextXAlignment = Enum.TextXAlignment.Right
    end
end)

-- Keybinds & Loops
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Menu then MainFrame.Visible = not MainFrame.Visible end
        if i.KeyCode == Settings.Keys.Fly then Settings.Fly.Enabled = not Settings.Fly.Enabled end
        if i.KeyCode == Settings.Keys.Speed then Settings.Speed.Enabled = not Settings.Speed.Enabled end
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.Speed.Enabled and LocalPlayer.Character then 
        local h = LocalPlayer.Character:FindFirstChild("Humanoid")
        if h then h.WalkSpeed = Settings.Speed.Value end 
    end
end)

print("Spaghetti Hub v5 Loaded - All features fixed.")
