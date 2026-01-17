--[[
    Spaghetti Mafia Hub v1.5 (ULTIMATE CFRAME EDITION)
    UI REDESIGN: DARK GLASSMORPHISM
    
    Update Log v1.5:
    1. R15 BANG: Now uses CFrame Math (Sine Wave) instead of Animation IDs. 
       (Bypasses Roblox Permissions 100%).
    2. Theme: Complete Dark/Glassmorphism Overhaul.
    3. UI: 'Closest Player' removed, Input box expanded.
    4. Logic: Auto-Sit checks every Heartbeat to prevent standing.
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

--// 2. CLEANUP & VARIABLES
if CoreGui:FindFirstChild("SpaghettiHub_Rel") then CoreGui.SpaghettiHub_Rel:Destroy() end
if CoreGui:FindFirstChild("SpaghettiLoading") then CoreGui.SpaghettiLoading:Destroy() end

local Settings = {
    Theme = {
        Gold = Color3.fromRGB(255, 200, 50), -- More vibrant Gold
        -- UI REDESIGN: Dark Glass Theme
        Dark = Color3.fromRGB(15, 15, 20), -- Deep Navy/Black
        Box = Color3.fromRGB(25, 25, 35), -- Slightly Lighter for elements
        Text = Color3.fromRGB(240, 240, 240),
        
        IceBlue = Color3.fromRGB(80, 200, 255),
        IceDark = Color3.fromRGB(10, 15, 25),
        
        ShardBlue = Color3.fromRGB(60, 160, 255),
        CrystalRed = Color3.fromRGB(255, 80, 80),
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

--// 3. UI FUNCTIONS
local Library = {}
function Library:Tween(obj, props, time, style) TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play() end

function Library:AddGlow(obj, color, thickness) 
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Settings.Theme.Gold
    s.Thickness = thickness or 1
    s.Transparency = 0.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    -- Subtle Pulse Animation
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

function Library:Corner(obj, r) local c = Instance.new("UICorner", obj); c.CornerRadius = UDim.new(0, r or 8); return c end
function Library:Gradient(obj, c1, c2, rot) local g = Instance.new("UIGradient", obj); g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}; g.Rotation = rot or 45; return g end

function Library:MakeDraggable(obj, isMiniPasta)
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
    flake.TextColor3 = Color3.fromRGB(200, 240, 255)
    flake.Size = UDim2.new(0, math.random(15, 25), 0, math.random(15, 25))
    flake.Position = UDim2.new(math.random(1, 100)/100, 0, -0.2, 0)
    flake.ZIndex = 1 
    flake.Name = "SnowFlake"
    
    local duration = math.random(4, 7)
    TweenService:Create(flake, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Position = UDim2.new(flake.Position.X.Scale, math.random(-30,30), 1.2, 0),
        Rotation = math.random(180, 360),
        TextTransparency = 1
    }):Play()
    
    Debris:AddItem(flake, duration)
end

--// HELPER FOR SITTING ANIMATION
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

--// 4. LOADING SCREEN (Modernized)
local LoadGui = Instance.new("ScreenGui"); LoadGui.Name = "SpaghettiLoading"; LoadGui.Parent = CoreGui
local LoadBox = Instance.new("Frame", LoadGui)
LoadBox.Size = UDim2.new(0, 260, 0, 180)
LoadBox.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadBox.AnchorPoint = Vector2.new(0.5, 0.5)
LoadBox.ClipsDescendants = true 
LoadBox.BorderSizePixel = 0
LoadBox.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
LoadBox.BackgroundTransparency = 1 
Library:Corner(LoadBox, 16)
Library:AddGlow(LoadBox, Settings.Theme.Gold, 2)

TweenService:Create(LoadBox, TweenInfo.new(0.5), {BackgroundTransparency = 0.05}):Play()

local PastaIcon = Instance.new("TextLabel", LoadBox)
PastaIcon.Size = UDim2.new(1, 0, 0.45, 0); PastaIcon.Position = UDim2.new(0,0,0.1,0)
PastaIcon.BackgroundTransparency = 1; PastaIcon.Text = "🍝"; PastaIcon.TextSize = 65; PastaIcon.ZIndex = 15
PastaIcon.TextTransparency = 1
TweenService:Create(PastaIcon, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
TweenService:Create(PastaIcon, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 10, Size = UDim2.new(1.1, 0, 0.50, 0)}):Play()

local TitleLoad = Instance.new("TextLabel", LoadBox)
TitleLoad.Size = UDim2.new(1, 0, 0.2, 0); TitleLoad.Position = UDim2.new(0, 0, 0.55, 0)
TitleLoad.BackgroundTransparency = 1; TitleLoad.Text = "SPAGHETTI HUB"; 
TitleLoad.Font = Enum.Font.GothamBlack; TitleLoad.TextColor3 = Settings.Theme.Gold; TitleLoad.TextSize = 20
TitleLoad.ZIndex = 15
TitleLoad.TextTransparency = 1
TweenService:Create(TitleLoad, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {TextTransparency = 0}):Play()

local SubLoad = Instance.new("TextLabel", LoadBox)
SubLoad.Size = UDim2.new(1, 0, 0.2, 0); SubLoad.Position = UDim2.new(0, 0, 0.70, 0)
SubLoad.BackgroundTransparency = 1; 
SubLoad.Text = "Loading Assets..."; 
SubLoad.Font = Enum.Font.GothamMedium; SubLoad.TextColor3 = Color3.fromRGB(180, 180, 190); SubLoad.TextSize = 13
SubLoad.ZIndex = 15
SubLoad.TextTransparency = 1
TweenService:Create(SubLoad, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.4), {TextTransparency = 0}):Play()

local LoadingBarBG = Instance.new("Frame", LoadBox)
LoadingBarBG.Size = UDim2.new(0.8, 0, 0, 4)
LoadingBarBG.Position = UDim2.new(0.1, 0, 0.9, 0)
LoadingBarBG.BackgroundColor3 = Color3.fromRGB(40,40,50)
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
TweenService:Create(PastaIcon, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
TweenService:Create(TitleLoad, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
TweenService:Create(SubLoad, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
TweenService:Create(LoadingBarBG, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
TweenService:Create(LoadingBarFill, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
task.wait(0.3)
LoadGui:Destroy()

--// FRIEND ALERTS
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

--// 5. MAIN GUI STRUCTURE (Redesigned)
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false

-- Mini Icon
local MiniPasta = Instance.new("TextButton", ScreenGui); 
MiniPasta.Size = UDim2.new(0, 55, 0, 55); 
MiniPasta.Position = UDim2.new(0.1, 0, 0.1, 0); 
MiniPasta.BackgroundColor3 = Color3.fromRGB(20, 20, 25); 
MiniPasta.Text = "🍝"; 
MiniPasta.TextSize = 30; 
MiniPasta.Visible = false; 
Library:Corner(MiniPasta, 16); 
Library:AddGlow(MiniPasta, Settings.Theme.Gold, 1); 
local CheckDrag = Library:MakeDraggable(MiniPasta, true) 

local MainFrame = Instance.new("Frame", ScreenGui); 
local NEW_WIDTH = 600
local NEW_HEIGHT = 440 
MainFrame.Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); 
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); -- Dark Background
MainFrame.ClipsDescendants = false; 
Library:Corner(MainFrame, 12); 

-- Main Glow/Shadow
local MainShadow = Instance.new("ImageLabel", MainFrame)
MainShadow.Name = "Shadow"
MainShadow.AnchorPoint = Vector2.new(0.5, 0.5)
MainShadow.BackgroundTransparency = 1
MainShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
MainShadow.Size = UDim2.new(1, 40, 1, 40)
MainShadow.ZIndex = -1
MainShadow.Image = "rbxassetid://6015897843" -- Soft glow image
MainShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
MainShadow.ImageTransparency = 0.4

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 1 
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Color = Color3.fromRGB(60, 60, 70) -- Subtle border

MainFrame.Size = UDim2.new(0,0,0,0); Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.6, Enum.EasingStyle.Quart) 

local MainScale = Instance.new("UIScale", MainFrame); MainScale.Scale = 1
local TopBar = Instance.new("Frame", MainFrame); TopBar.Size = UDim2.new(1,0,0,55); TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28); TopBar.BorderSizePixel = 0; Library:Corner(TopBar, 12); 
-- Mask the bottom corners of TopBar so it looks like a header
local TopBarMask = Instance.new("Frame", TopBar); TopBarMask.Size = UDim2.new(1,0,0.5,0); TopBarMask.Position = UDim2.new(0,0,0.5,0); TopBarMask.BackgroundColor3 = Color3.fromRGB(22, 22, 28); TopBarMask.BorderSizePixel = 0; TopBarMask.ZIndex = 0

Library:MakeDraggable(MainFrame)

local MainTitle = Instance.new("TextLabel", TopBar); MainTitle.Size = UDim2.new(0,300,0,30); MainTitle.Position = UDim2.new(0,20,0,6); MainTitle.BackgroundTransparency = 1; MainTitle.Text = "SPAGHETTI <font color='#FFC832'>MAFIA</font>"; MainTitle.RichText = true; MainTitle.Font = Enum.Font.GothamBlack; MainTitle.TextSize = 20; MainTitle.TextColor3 = Color3.new(1,1,1); MainTitle.TextXAlignment = Enum.TextXAlignment.Left; MainTitle.ZIndex = 2

local MainSub = Instance.new("TextLabel", TopBar)
MainSub.Size = UDim2.new(0,300,0,20)
MainSub.Position = UDim2.new(0,20,0,30)
MainSub.BackgroundTransparency = 1
MainSub.Text = "עולם הכיף | HUB v1.5" 
MainSub.Font = Enum.Font.GothamBold
MainSub.TextSize = 12
MainSub.TextColor3 = Settings.Theme.IceBlue
MainSub.TextXAlignment = Enum.TextXAlignment.Left
MainSub.ZIndex = 2

local CloseBtn = Instance.new("TextButton", TopBar); CloseBtn.Size = UDim2.new(0, 32, 0, 32); CloseBtn.Position = UDim2.new(1, -40, 0, 12); CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); CloseBtn.Text = "×"; CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200); CloseBtn.Font=Enum.Font.GothamMedium; CloseBtn.TextSize=24; Library:Corner(CloseBtn, 8); 
local CloseStroke = Instance.new("UIStroke", CloseBtn); CloseStroke.Color = Color3.fromRGB(60,60,70); CloseStroke.Thickness = 1
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniPasta.Visible = true; Library:Tween(MiniPasta, {Size = UDim2.new(0, 55, 0, 55)}, 0.4, Enum.EasingStyle.Back) end)

MiniPasta.MouseButton1Click:Connect(function() 
    if CheckDrag() == false then 
        MiniPasta.Visible = false; 
        MainFrame.Visible = true; 
        Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.4, Enum.EasingStyle.Back) 
    end
end)

--// STORM TIMER + SOUNDS (Redesigned)
task.spawn(function()
    local StormValue = ReplicatedStorage:WaitForChild("StormTimeLeft", 5)
    
    if StormValue then
        local wasStorming = false
        local TimerWidget = Instance.new("Frame", TopBar)
        TimerWidget.Name = "StormTimerWidgetPro"
        TimerWidget.Size = UDim2.new(0, 140, 0, 36)
        TimerWidget.AnchorPoint = Vector2.new(1, 0.5)
        TimerWidget.Position = UDim2.new(1, -50, 0.5, 0)
        TimerWidget.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        TimerWidget.BorderSizePixel = 0
        TimerWidget.ZIndex = 2
        Library:Corner(TimerWidget, 8)
        
        local TimerStroke = Instance.new("UIStroke", TimerWidget)
        TimerStroke.Color = Color3.fromRGB(60, 60, 80)
        TimerStroke.Thickness = 1 
        TimerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local T_Header = Instance.new("TextLabel", TimerWidget)
        T_Header.Size = UDim2.new(1, 0, 0.4, 0)
        T_Header.Position = UDim2.new(0, 0, 0.05, 0)
        T_Header.BackgroundTransparency = 1
        T_Header.Text = "NEXT STORM"
        T_Header.TextColor3 = Color3.fromRGB(150, 150, 170)
        T_Header.Font = Enum.Font.GothamBold
        T_Header.TextSize = 9
        T_Header.ZIndex = 3

        local T_Time = Instance.new("TextLabel", TimerWidget)
        T_Time.Size = UDim2.new(1, 0, 0.6, 0)
        T_Time.Position = UDim2.new(0, 0, 0.35, 0)
        T_Time.BackgroundTransparency = 1
        T_Time.Text = "00:00"
        T_Time.TextColor3 = Color3.fromRGB(255, 255, 255)
        T_Time.Font = Enum.Font.GothamBold
        T_Time.TextSize = 16
        T_Time.ZIndex = 3

        local function UpdateStormTimer(val)
            local mins = math.floor(val / 60)
            local secs = val % 60
            
            if val <= 0 then
                if not wasStorming then
                    wasStorming = true
                    PlaySound(Sounds.StormStart)
                end
                T_Header.Text = "STATUS"
                T_Header.TextColor3 = Color3.fromRGB(255, 100, 100)
                T_Time.Text = "STORM ACTIVE!"
                T_Time.TextSize = 12 
                T_Time.TextColor3 = Settings.Theme.CrystalRed
                TweenService:Create(TimerStroke, TweenInfo.new(0.5), {Color = Color3.fromRGB(255, 50, 50), Transparency = 0}):Play()
                TweenService:Create(TimerWidget, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(40, 15, 15)}):Play()
            else
                if wasStorming then
                    wasStorming = false
                    PlaySound(Sounds.StormEnd)
                end
                
                if val <= 30 then
                    T_Header.Text = "INCOMING"
                    T_Header.TextColor3 = Color3.fromRGB(255, 220, 100)
                    T_Time.Text = string.format("%02d:%02d", mins, secs)
                    T_Time.TextSize = 16
                    T_Time.TextColor3 = Settings.Theme.Gold
                    TweenService:Create(TimerStroke, TweenInfo.new(0.5), {Color = Settings.Theme.Gold, Transparency = 0.2}):Play()
                else
                    T_Header.Text = "NEXT STORM"
                    T_Header.TextColor3 = Color3.fromRGB(150, 160, 180)
                    T_Time.Text = string.format("%02d:%02d", mins, secs)
                    T_Time.TextSize = 16
                    T_Time.TextColor3 = Color3.fromRGB(255, 255, 255)
                    TweenService:Create(TimerStroke, TweenInfo.new(0.5), {Color = Color3.fromRGB(60, 60, 80), Transparency = 0}):Play()
                    TweenService:Create(TimerWidget, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(25, 25, 35)}):Play()
                end
            end
        end

        StormValue.Changed:Connect(UpdateStormTimer)
        UpdateStormTimer(StormValue.Value)
    end
end)

--// SIDEBAR (Redesigned)
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 160, 1, -55)
Sidebar.Position = UDim2.new(0,0,0,55)
Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Sidebar.BorderSizePixel = 0 
Sidebar.ZIndex = 1
Library:Corner(Sidebar, 0) -- Flat left side
-- Add a subtle line separating sidebar
local SideLine = Instance.new("Frame", Sidebar)
SideLine.Size = UDim2.new(0, 1, 1, 0)
SideLine.Position = UDim2.new(1, -1, 0, 0)
SideLine.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SideLine.BorderSizePixel = 0

-- USER PROFILE (Cleaned up)
local UserProfile = Instance.new("Frame", Sidebar)
UserProfile.Name = "UserProfileContainer"
UserProfile.Size = UDim2.new(0.9, 0, 0, 70)
UserProfile.AnchorPoint = Vector2.new(0.5, 1)
UserProfile.Position = UDim2.new(0.5, 0, 0.96, 0)
UserProfile.BackgroundColor3 = Color3.fromRGB(25, 25, 30) 
UserProfile.BorderSizePixel = 0
UserProfile.ZIndex = 2
Library:Corner(UserProfile, 8)
local UserStroke = Instance.new("UIStroke", UserProfile); UserStroke.Color = Color3.fromRGB(50, 50, 60); UserStroke.Thickness = 1

local AvatarFrame = Instance.new("Frame", UserProfile)
AvatarFrame.Size = UDim2.new(0, 45, 0, 45)
AvatarFrame.Position = UDim2.new(0, 10, 0.5, 0)
AvatarFrame.AnchorPoint = Vector2.new(0, 0.5)
AvatarFrame.BackgroundColor3 = Settings.Theme.Gold
AvatarFrame.BorderSizePixel = 0
AvatarFrame.ZIndex = 3
local AvatarCorner = Instance.new("UICorner", AvatarFrame); AvatarCorner.CornerRadius = UDim.new(1, 0)

local AvatarImg = Instance.new("ImageLabel", AvatarFrame)
AvatarImg.Size = UDim2.new(0.92, 0, 0.92, 0)
AvatarImg.Position = UDim2.new(0.5, 0, 0.5, 0)
AvatarImg.AnchorPoint = Vector2.new(0.5, 0.5)
AvatarImg.BackgroundTransparency = 1
AvatarImg.Image = ""
AvatarImg.ZIndex = 4
local AvatarImgCorner = Instance.new("UICorner", AvatarImg); AvatarImgCorner.CornerRadius = UDim.new(1, 0)

local WelcomeText = Instance.new("TextLabel", UserProfile)
WelcomeText.Text = "Welcome," 
WelcomeText.Size = UDim2.new(0, 80, 0, 15)
WelcomeText.Position = UDim2.new(0, 65, 0, 16)
WelcomeText.BackgroundTransparency = 1
WelcomeText.TextColor3 = Color3.fromRGB(150, 150, 160)
WelcomeText.Font = Enum.Font.GothamBold 
WelcomeText.TextSize = 11
WelcomeText.TextXAlignment = Enum.TextXAlignment.Left
WelcomeText.ZIndex = 3

local UsernameText = Instance.new("TextLabel", UserProfile)
UsernameText.Text = LocalPlayer.Name
UsernameText.Size = UDim2.new(0, 80, 0, 18)
UsernameText.Position = UDim2.new(0, 65, 0, 32)
UsernameText.BackgroundTransparency = 1
UsernameText.TextColor3 = Settings.Theme.Gold
UsernameText.Font = Enum.Font.GothamBlack 
UsernameText.TextSize = 13
UsernameText.TextXAlignment = Enum.TextXAlignment.Left
UsernameText.TextTruncate = Enum.TextTruncate.AtEnd
UsernameText.ZIndex = 3

task.spawn(function()
    local content = "rbxassetid://0"
    pcall(function()
        content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    AvatarImg.Image = content
end)

-- SIDEBAR SCROLLING FRAME
local SideBtnContainer = Instance.new("ScrollingFrame", Sidebar)
SideBtnContainer.Size = UDim2.new(1, 0, 1, -80) 
SideBtnContainer.BackgroundTransparency = 1
SideBtnContainer.ScrollBarThickness = 2
SideBtnContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
SideBtnContainer.CanvasSize = UDim2.new(0,0,0,0)

local SideList = Instance.new("UIListLayout", SideBtnContainer); SideList.Padding = UDim.new(0,6); SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center; SideList.SortOrder = Enum.SortOrder.LayoutOrder
local SidePad = Instance.new("UIPadding", SideBtnContainer); SidePad.PaddingTop = UDim.new(0,15)

local Container = Instance.new("Frame", MainFrame); Container.Size = UDim2.new(1, -160, 1, -55); Container.Position = UDim2.new(0, 160, 0, 55); Container.BackgroundTransparency = 1

local currentTab = nil

local function CreateTab(name, heb, order, isWinter)
    local btn = Instance.new("TextButton", SideBtnContainer)
    btn.Size = UDim2.new(0.85,0,0,42)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 22) -- Matches sidebar initially
    btn.Text = "   " .. name .. "\n   <font size='10' color='#777788'>"..heb.."</font>"
    btn.RichText = true
    btn.TextColor3 = Color3.fromRGB(140, 140, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 3
    btn.LayoutOrder = order
    btn.BorderSizePixel = 0
    Library:Corner(btn, 8)
    
    -- Visual Indicator
    local Indicator = Instance.new("Frame", btn)
    Indicator.Size = UDim2.new(0, 3, 0.6, 0)
    Indicator.Position = UDim2.new(0, 0, 0.2, 0)
    Indicator.BackgroundColor3 = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold
    Indicator.BackgroundTransparency = 1 -- Hidden by default
    Indicator.BorderSizePixel = 0
    Library:Corner(Indicator, 4)
    
    local page = Instance.new("Frame", Container)
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Name = name .. "_Page"
    
    btn.MouseButton1Click:Connect(function()
        for _,v in pairs(SideBtnContainer:GetChildren()) do 
            if v:IsA("TextButton") then 
                Library:Tween(v, {BackgroundColor3 = Color3.fromRGB(18, 18, 22), TextColor3 = Color3.fromRGB(140, 140, 150)}) 
                local ind = v:FindFirstChild("Frame")
                if ind then Library:Tween(ind, {BackgroundTransparency = 1}) end
            end 
        end
        for _,v in pairs(Container:GetChildren()) do v.Visible = false end
        
        local activeColor = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold
        local activeBG = Color3.fromRGB(30, 30, 36)
        
        Library:Tween(btn, {BackgroundColor3 = activeBG, TextColor3 = Color3.new(1,1,1)})
        Library:Tween(Indicator, {BackgroundTransparency = 0})
        page.Visible = true
    end)
    
    if order == 1 then 
        currentTab = btn
        local activeColor = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold
        local activeBG = Color3.fromRGB(30, 30, 36)
        Library:Tween(btn, {BackgroundColor3 = activeBG, TextColor3 = Color3.new(1,1,1)})
        Library:Tween(Indicator, {BackgroundTransparency = 0})
        page.Visible = true 
    end
    return page
end

-- TABS DEFINITION
local Tab_Event_Page = CreateTab("Winter Event", "אירוע חורף", 1, true) 
local Tab_Main_Page = CreateTab("Main", "ראשי", 2, false)
local Tab_Target_Page = CreateTab("Target", "שחקנים", 3, false) 
local Tab_Settings_Page = CreateTab("Settings", "הגדרות", 4, false)
local Tab_Credits_Page = CreateTab("Credits", "קרדיטים", 5, false)

local function AddLayout(p) 
    local l = Instance.new("UIListLayout", p); l.Padding = UDim.new(0,12); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local pad = Instance.new("UIPadding", p); pad.PaddingTop = UDim.new(0,15) 
end
AddLayout(Tab_Main_Page); AddLayout(Tab_Settings_Page)

--// 6. LOGIC SYSTEMS (UNCHANGED)
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

--// 7. EVENT TAB (WINTER) - Redesigned
local EventBackground = Instance.new("Frame", Tab_Event_Page)
EventBackground.Size = UDim2.new(1,0,1,0)
EventBackground.ZIndex = 0
Library:Gradient(EventBackground, Color3.fromRGB(15, 20, 30), Color3.fromRGB(10, 10, 15), 45)

local EventSnowContainer = Instance.new("Frame", Tab_Event_Page)
EventSnowContainer.Size = UDim2.new(1,0,1,0)
EventSnowContainer.BackgroundTransparency = 1
EventSnowContainer.ClipsDescendants = true
EventSnowContainer.ZIndex = 1

task.spawn(function()
    while Tab_Event_Page.Parent do
        if Tab_Event_Page.Visible then SpawnSnow(EventSnowContainer) end
        task.wait(0.4) 
    end
end)

local Tab_Farm_Scroll = Instance.new("ScrollingFrame", Tab_Event_Page)
Tab_Farm_Scroll.Size = UDim2.new(1, 0, 1, 0)
Tab_Farm_Scroll.BackgroundTransparency = 1
Tab_Farm_Scroll.ScrollBarThickness = 2
Tab_Farm_Scroll.ScrollBarImageColor3 = Settings.Theme.IceBlue
Tab_Farm_Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Tab_Farm_Scroll.BorderSizePixel = 0
Tab_Farm_Scroll.ZIndex = 5

local EventLayout = Instance.new("UIListLayout", Tab_Farm_Scroll)
EventLayout.Padding = UDim.new(0, 15)
EventLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
EventLayout.SortOrder = Enum.SortOrder.LayoutOrder 
local EventPad = Instance.new("UIPadding", Tab_Farm_Scroll); EventPad.PaddingTop = UDim.new(0,15)

-- Farm Button (Redesigned)
local FarmBtn = Instance.new("TextButton", Tab_Farm_Scroll)
FarmBtn.Size = UDim2.new(0.95, 0, 0, 75)
FarmBtn.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
FarmBtn.Text = ""
FarmBtn.LayoutOrder = 1
Library:Corner(FarmBtn, 12)
local FarmStroke = Instance.new("UIStroke", FarmBtn); FarmStroke.Color = Settings.Theme.IceBlue; FarmStroke.Thickness = 1; FarmStroke.Transparency = 0.5

local FarmTitle = Instance.new("TextLabel", FarmBtn)
FarmTitle.Size = UDim2.new(1, -70, 1, 0)
FarmTitle.Position = UDim2.new(0, 20, 0, 0)
FarmTitle.Text = "AUTO FARM <font color='#87CEFA'>❄️</font>\n<font size='12' color='#AABBDD'>הפעלת חווה אוטומטית</font>"
FarmTitle.RichText = true
FarmTitle.TextColor3 = Color3.new(1,1,1)
FarmTitle.Font = Enum.Font.GothamBlack
FarmTitle.TextSize = 18
FarmTitle.TextXAlignment = Enum.TextXAlignment.Left
FarmTitle.BackgroundTransparency = 1
FarmTitle.ZIndex = 6

local FarmSwitch = Instance.new("Frame", FarmBtn)
FarmSwitch.Size = UDim2.new(0, 50, 0, 28)
FarmSwitch.Position = UDim2.new(1, -70, 0.5, -14)
FarmSwitch.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
Library:Corner(FarmSwitch, 20)
local FarmDot = Instance.new("Frame", FarmSwitch)
FarmDot.Size = UDim2.new(0, 24, 0, 24)
FarmDot.Position = UDim2.new(0, 2, 0.5, -12)
FarmDot.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
Library:Corner(FarmDot, 20)

local isFarming = false
FarmBtn.MouseButton1Click:Connect(function() 
    isFarming = not isFarming; ToggleFarm(isFarming)
    if isFarming then 
        Library:Tween(FarmSwitch,{BackgroundColor3=Settings.Theme.IceBlue})
        Library:Tween(FarmDot,{Position=UDim2.new(1,-26,0.5,-12), BackgroundColor3=Color3.new(1,1,1)}) 
        Library:Tween(FarmStroke, {Transparency = 0, Color = Settings.Theme.IceBlue})
    else 
        Library:Tween(FarmSwitch,{BackgroundColor3=Color3.fromRGB(40,45,55)}) 
        Library:Tween(FarmDot,{Position=UDim2.new(0,2,0.5,-12), BackgroundColor3=Color3.fromRGB(150,150,160)}) 
        Library:Tween(FarmStroke, {Transparency = 0.5})
    end 
end)

task.spawn(function()
    task.wait(1) 
    if not isFarming then
        isFarming = true
        ToggleFarm(true)
        if FarmSwitch and FarmDot then
            Library:Tween(FarmSwitch,{BackgroundColor3=Settings.Theme.IceBlue})
            Library:Tween(FarmDot,{Position=UDim2.new(1,-26,0.5,-12), BackgroundColor3=Color3.new(1,1,1)})
        end
    end
end)

-- Balance Stats (Redesigned)
local BalanceLabel = Instance.new("TextLabel", Tab_Farm_Scroll)
BalanceLabel.Size = UDim2.new(0.95,0,0,20)
BalanceLabel.Text = "TOTAL BALANCE (סה''כ בתיק)"
BalanceLabel.TextColor3 = Settings.Theme.Gold
BalanceLabel.Font=Enum.Font.GothamBold
BalanceLabel.TextSize=12
BalanceLabel.BackgroundTransparency=1
BalanceLabel.LayoutOrder = 2
BalanceLabel.ZIndex = 6
BalanceLabel.TextXAlignment = Enum.TextXAlignment.Left

local BalanceContainer = Instance.new("Frame", Tab_Farm_Scroll)
BalanceContainer.Size = UDim2.new(0.95, 0, 0, 70)
BalanceContainer.BackgroundTransparency = 1
BalanceContainer.LayoutOrder = 3
local BalanceGrid = Instance.new("UIGridLayout", BalanceContainer)
BalanceGrid.CellSize = UDim2.new(0.48, 0, 1, 0)
BalanceGrid.CellPadding = UDim2.new(0.04, 0, 0, 0)
BalanceGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

local TotBlues = Instance.new("Frame", BalanceContainer); TotBlues.BackgroundColor3 = Color3.fromRGB(15, 20, 30); Library:Corner(TotBlues, 10); 
local StrokeTotalB = Instance.new("UIStroke", TotBlues); StrokeTotalB.Color = Settings.Theme.ShardBlue; StrokeTotalB.Transparency=0.7; StrokeTotalB.Thickness=1
local T_TitleB = Instance.new("TextLabel", TotBlues); T_TitleB.Size = UDim2.new(1,0,0.3,0); T_TitleB.Position=UDim2.new(0,0,0.15,0); T_TitleB.BackgroundTransparency=1; T_TitleB.Text="BLUE SHARDS 🧊"; T_TitleB.TextColor3=Settings.Theme.ShardBlue; T_TitleB.Font=Enum.Font.GothamBold; T_TitleB.TextSize=11; T_TitleB.ZIndex=6
local T_ValB = Instance.new("TextLabel", TotBlues); T_ValB.Size = UDim2.new(1,0,0.5,0); T_ValB.Position=UDim2.new(0,0,0.45,0); T_ValB.BackgroundTransparency=1; T_ValB.Text="..."; T_ValB.TextColor3=Color3.new(1,1,1); T_ValB.Font=Enum.Font.GothamBlack; T_ValB.TextSize=22; T_ValB.ZIndex=6

local TotReds = Instance.new("Frame", BalanceContainer); TotReds.BackgroundColor3 = Color3.fromRGB(20, 15, 15); Library:Corner(TotReds, 10); 
local StrokeTotalR = Instance.new("UIStroke", TotReds); StrokeTotalR.Color = Settings.Theme.CrystalRed; StrokeTotalR.Transparency=0.7; StrokeTotalR.Thickness=1
local T_TitleR = Instance.new("TextLabel", TotReds); T_TitleR.Size = UDim2.new(1,0,0.3,0); T_TitleR.Position=UDim2.new(0,0,0.15,0); T_TitleR.BackgroundTransparency=1; T_TitleR.Text="RED CRYSTALS 💎"; T_TitleR.TextColor3=Settings.Theme.CrystalRed; T_TitleR.Font=Enum.Font.GothamBold; T_TitleR.TextSize=11; T_TitleR.ZIndex=6
local T_ValR = Instance.new("TextLabel", TotReds); T_ValR.Size = UDim2.new(1,0,0.5,0); T_ValR.Position=UDim2.new(0,0,0.45,0); T_ValR.BackgroundTransparency=1; T_ValR.Text="..."; T_ValR.TextColor3=Color3.new(1,1,1); T_ValR.Font=Enum.Font.GothamBlack; T_ValR.TextSize=22; T_ValR.ZIndex=6

-- Session Stats (Redesigned)
local StatsLabel = Instance.new("TextLabel", Tab_Farm_Scroll)
StatsLabel.Size = UDim2.new(0.95,0,0,20)
StatsLabel.Text = "SESSION EARNINGS (נאספו בסופה)"
StatsLabel.TextColor3 = Color3.fromRGB(180,200,220)
StatsLabel.Font=Enum.Font.GothamBold
StatsLabel.TextSize=12
StatsLabel.BackgroundTransparency=1
StatsLabel.LayoutOrder = 4
StatsLabel.ZIndex = 6
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left

local StatsContainer = Instance.new("Frame", Tab_Farm_Scroll)
StatsContainer.Size = UDim2.new(0.95, 0, 0, 70)
StatsContainer.BackgroundTransparency = 1
StatsContainer.LayoutOrder = 5
local StatsGrid = Instance.new("UIGridLayout", StatsContainer)
StatsGrid.CellSize = UDim2.new(0.48, 0, 1, 0)
StatsGrid.CellPadding = UDim2.new(0.04, 0, 0, 0)
StatsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

local BoxBlue = Instance.new("Frame", StatsContainer); BoxBlue.BackgroundColor3 = Color3.fromRGB(15, 20, 30); Library:Corner(BoxBlue, 10); 
local StrokeBlue = Instance.new("UIStroke", BoxBlue); StrokeBlue.Color = Settings.Theme.IceBlue; StrokeBlue.Transparency=0.7; StrokeBlue.Thickness=1
local TitleBlue = Instance.new("TextLabel", BoxBlue); TitleBlue.Size = UDim2.new(1, 0, 0.3, 0); TitleBlue.Position = UDim2.new(0,0,0.15,0); TitleBlue.BackgroundTransparency = 1; TitleBlue.Text = "BLUES (Session)"; TitleBlue.TextColor3 = Settings.Theme.IceBlue; TitleBlue.Font = Enum.Font.GothamBold; TitleBlue.TextSize = 10; TitleBlue.ZIndex=6
local ValBlue = Instance.new("TextLabel", BoxBlue); ValBlue.Size = UDim2.new(1, 0, 0.5, 0); ValBlue.Position = UDim2.new(0,0,0.45,0); ValBlue.BackgroundTransparency = 1; ValBlue.Text = "0"; ValBlue.TextColor3 = Color3.new(1, 1, 1); ValBlue.Font = Enum.Font.GothamBlack; ValBlue.TextSize = 22; ValBlue.ZIndex=6

local BoxRed = Instance.new("Frame", StatsContainer); BoxRed.BackgroundColor3 = Color3.fromRGB(20, 15, 15); Library:Corner(BoxRed, 10); 
local StrokeRed = Instance.new("UIStroke", BoxRed); StrokeRed.Color = Settings.Theme.CrystalRed; StrokeRed.Transparency=0.7; StrokeRed.Thickness=1
local TitleRed = Instance.new("TextLabel", BoxRed); TitleRed.Size = UDim2.new(1, 0, 0.3, 0); TitleRed.Position = UDim2.new(0,0,0.15,0); TitleRed.BackgroundTransparency = 1; TitleRed.Text = "REDS (Session)"; TitleRed.TextColor3 = Settings.Theme.CrystalRed; TitleRed.Font = Enum.Font.GothamBold; TitleRed.TextSize = 10; TitleRed.ZIndex=6
local ValRed = Instance.new("TextLabel", BoxRed); ValRed.Size = UDim2.new(1, 0, 0.5, 0); ValRed.Position = UDim2.new(0,0,0.45,0); ValRed.BackgroundTransparency = 1; ValRed.Text = "0"; ValRed.TextColor3 = Color3.new(1, 1, 1); ValRed.Font = Enum.Font.GothamBlack; ValRed.TextSize = 22; ValRed.ZIndex=6

local AFKStatus = Instance.new("TextLabel", Tab_Farm_Scroll)
AFKStatus.Size = UDim2.new(0.95, 0, 0, 20)
AFKStatus.BackgroundTransparency = 1
AFKStatus.Text = "ANTI-AFK: <font color='#00FF00'>Active (Jumper)</font> ⚡"
AFKStatus.RichText = true
AFKStatus.TextColor3 = Color3.new(1, 1, 1)
AFKStatus.Font = Enum.Font.GothamMedium
AFKStatus.TextSize = 11
AFKStatus.LayoutOrder = 6
AFKStatus.ZIndex = 6

task.spawn(function()
    local CrystalsRef = LocalPlayer:WaitForChild("Crystals", 10)
    local ShardsRef = LocalPlayer:WaitForChild("Shards", 10)
    if not CrystalsRef or not ShardsRef then return end
    local InitC = CrystalsRef.Value; local InitS = ShardsRef.Value
    while true do
        task.wait(0.5)
        pcall(function()
            local CurC = CrystalsRef.Value; local CurS = ShardsRef.Value
            local SesC = CurC - InitC; local SesS = CurS - InitS
            if SesC < 0 then SesC = 0 end; if SesS < 0 then SesS = 0 end
            ValRed.Text = "+"..tostring(SesC); ValBlue.Text = "+"..tostring(SesS)
            T_ValR.Text = tostring(CurC); T_ValB.Text = tostring(CurS)
        end)
    end
end)

--// 8. COMPONENTS (Redesigned)
local function CreateSlider(parent, title, heb, min, max, default, callback, toggleCallback, toggleName)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0.95,0,0,75)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    Library:Corner(f, 10)
    
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Color3.fromRGB(50, 50, 60)
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(0.7,0,0,25)
    l.Position = UDim2.new(0,12,0,8)
    l.Text = title .. "\n<font size='10' color='#888899'>"..heb.."</font>"
    l.RichText = true
    l.TextColor3=Color3.new(1,1,1)
    l.Font=Enum.Font.GothamBold
    l.TextSize=14
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.BackgroundTransparency=1
    
    local valLabel = Instance.new("TextLabel", f)
    valLabel.Size = UDim2.new(0, 50, 0, 20)
    valLabel.Position = UDim2.new(1, -60, 0, 8)
    valLabel.Text = tostring(default)
    valLabel.TextColor3 = Settings.Theme.Gold
    valLabel.Font = Enum.Font.GothamBlack
    valLabel.TextSize = 14
    valLabel.BackgroundTransparency = 1
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(0.9,0,0,6)
    line.Position = UDim2.new(0.05,0,0.65,0)
    line.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Library:Corner(line,4)
    
    local fill = Instance.new("Frame", line)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Settings.Theme.Gold
    Library:Corner(fill,4)
    
    local grad = Instance.new("UIGradient", fill)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Settings.Theme.Gold),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 100))
    }
    
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
            local r = math.clamp((mouseLoc.X - line.AbsolutePosition.X) / line.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + ((max - min) * r))
            fill.Size = UDim2.new(r, 0, 1, 0)
            valLabel.Text = tostring(v)
            callback(v)
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end)

    if toggleCallback then
        -- Move Value label left to make room for toggle
        valLabel.Position = UDim2.new(1, -120, 0, 8)
        
        local t = Instance.new("TextButton", f)
        t.Size = UDim2.new(0,44,0,22)
        t.Position = UDim2.new(1,-54,0,8)
        t.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        t.Text = "OFF"
        t.TextColor3 = Color3.fromRGB(150, 150, 150)
        t.Font = Enum.Font.GothamBold
        Library:Corner(t,6)
        t.TextSize=10
        
        local ts = Instance.new("UIStroke", t)
        ts.Color = Color3.fromRGB(60,60,70)
        ts.Thickness = 1
        
        local on = false
        local function Update(s) 
            on=s
            t.Text=on and "ON" or "OFF"
            t.BackgroundColor3=on and Settings.Theme.Gold or Color3.fromRGB(30, 30, 35)
            t.TextColor3=on and Color3.new(0,0,0) or Color3.fromRGB(150, 150, 150)
            ts.Color = on and Settings.Theme.Gold or Color3.fromRGB(60,60,70)
            toggleCallback(on) 
        end
        t.MouseButton1Click:Connect(function() Update(not on) end)
        if toggleName then VisualToggles[toggleName] = function(v) Update(v) end end
    end
end

local function CreateSquareBind(parent, id, title, heb, default, callback)
    local f = Instance.new("TextButton", parent)
    local sizeY = id==3 and 55 or 70
    f.Position = id==1 and UDim2.new(0,0,0,0) or (id==2 and UDim2.new(0.52,0,0,0) or UDim2.new(0,0,0,0))
    f.Size = UDim2.new(id==3 and 1 or 0.48,0,0,sizeY)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    f.Text=""
    f.AutoButtonColor=false
    Library:Corner(f, 10)
    
    local s = Instance.new("UIStroke", f)
    s.Color = Color3.fromRGB(50, 50, 60)
    s.Thickness = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1,0,0,20)
    t.Position = UDim2.new(0,0,id==3 and 0.1 or 0.15,0)
    t.Text=title
    t.TextColor3=Color3.fromRGB(180,180,180)
    t.Font=Enum.Font.GothamBold
    t.TextSize=12
    t.BackgroundTransparency=1
    
    local h = Instance.new("TextLabel", f)
    h.Size = UDim2.new(1,0,0,15)
    h.Position = UDim2.new(0,0,0.35,0)
    h.Text=heb
    h.TextColor3=Color3.fromRGB(100,100,110)
    h.Font=Enum.Font.GothamMedium
    h.TextSize=10
    h.BackgroundTransparency=1
    
    local k = Instance.new("TextLabel", f)
    k.Size = UDim2.new(1,0,0,30)
    k.Position = UDim2.new(0,0,id==3 and 0.5 or 0.6,0)
    k.Text=default.Name
    k.TextColor3=Settings.Theme.Gold
    k.Font=Enum.Font.GothamBlack
    k.TextSize=18
    k.BackgroundTransparency=1
    
    f.MouseButton1Click:Connect(function() 
        k.Text="..."
        k.TextColor3=Color3.fromRGB(100, 255, 100)
        local i=UIS.InputBegan:Wait() 
        if i.UserInputType==Enum.UserInputType.Keyboard then 
            k.Text=i.KeyCode.Name
            k.TextColor3=Settings.Theme.Gold
            callback(i.KeyCode) 
        end 
    end)
    return f
end

--// 9. MAIN TAB (SELF TOOLS) - Redesigned
local MainScroll = Instance.new("ScrollingFrame", Tab_Main_Page)
MainScroll.Size = UDim2.new(1, 0, 1, 0)
MainScroll.BackgroundTransparency = 1
MainScroll.ScrollBarThickness = 2
MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainScroll.CanvasSize = UDim2.new(0,0,0,0)
local MainList = Instance.new("UIListLayout", MainScroll); MainList.SortOrder = Enum.SortOrder.LayoutOrder; MainList.Padding = UDim.new(0, 12); MainList.HorizontalAlignment = Enum.HorizontalAlignment.Center
local MainPad = Instance.new("UIPadding", MainScroll); MainPad.PaddingTop = UDim.new(0,5)

CreateSlider(MainScroll, "WALK SPEED", "מהירות הליכה", 1, 250, 16, function(v) 
    Settings.Speed.Value = v 
    if Settings.Speed.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end, function(t) 
    Settings.Speed.Enabled = t
    if not t and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16 
    end
end, "Speed")

CreateSlider(MainScroll, "FLY SPEED", "מהירות תעופה", 20, 300, 50, function(v) Settings.Fly.Speed = v end, function(t) ToggleFly(t) end, "Fly")
local BindCont = Instance.new("Frame", MainScroll); BindCont.Size = UDim2.new(0.95,0,0,70); BindCont.BackgroundTransparency = 1; CreateSquareBind(BindCont, 1, "FLY", "תעופה", Settings.Keys.Fly, function(k) Settings.Keys.Fly = k end); CreateSquareBind(BindCont, 2, "SPEED", "מהירות", Settings.Keys.Speed, function(k) Settings.Keys.Speed = k end)

--// 10. TARGET TAB (PLAYERS & TOOLS) - Redesigned
local TargetScroll = Instance.new("ScrollingFrame", Tab_Target_Page)
TargetScroll.Size = UDim2.new(1, 0, 1, 0)
TargetScroll.BackgroundTransparency = 1
TargetScroll.ScrollBarThickness = 4 
TargetScroll.ScrollBarImageColor3 = Settings.Theme.Gold 
TargetScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TargetScroll.CanvasSize = UDim2.new(0,0,0,0)
local TargetList = Instance.new("UIListLayout", TargetScroll); TargetList.SortOrder = Enum.SortOrder.LayoutOrder; TargetList.Padding = UDim.new(0, 15); TargetList.HorizontalAlignment = Enum.HorizontalAlignment.Center
local TargetPad = Instance.new("UIPadding", TargetScroll); TargetPad.PaddingTop = UDim.new(0,5)

local IgnoreList = {
    ["קולה"] = true, ["קולה מכשפות"] = true, ["קולה תות"] = true, ["קפה סטארבלוקס"] = true,
    ["רוטב חריף"] = true, ["שוקו"] = true, ["שיקוי אהבה"] = true, ["שיקוי הזקן המשוגע"] = true,
    ["שיקוי קרח"] = true, ["אבטיח"] = true, ["בורגר רדוף רוחות"] = true, ["בלוקס אנרגיה"] = true,
    ["גלידה"] = true, ["דובי"] = true, ["המבורגר"] = true, ["טאקו"] = true, ["כסף פליז"] = true,
    ["נקניקייה"] = true, ["סנדוויץ"] = true, ["עוגה"] = true, ["עוף"] = true, ["פייר קולה"] = true,
    ["פיצה"] = true, ["Cola"] = true, ["Pizza"] = true, ["Burger"] = true
}

local function GetPlayer(name)
    name = name:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
            return p
        end
    end
    return nil
end

-- BOX 1: HEADER (Redesigned)
local TargetBox = Instance.new("Frame", TargetScroll)
TargetBox.Size = UDim2.new(0.95, 0, 0, 95)
TargetBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Library:Corner(TargetBox, 12)
local TBStroke = Instance.new("UIStroke", TargetBox); TBStroke.Color = Color3.fromRGB(50,50,60); TBStroke.Thickness = 1

local TargetInput = Instance.new("TextBox", TargetBox)
TargetInput.Size = UDim2.new(0.7, 0, 0, 45) 
TargetInput.Position = UDim2.new(0.05, 0, 0.25, 0)
TargetInput.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
TargetInput.Text = ""
TargetInput.PlaceholderText = "Search Player..."
TargetInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
TargetInput.TextColor3 = Color3.new(1,1,1)
TargetInput.Font = Enum.Font.GothamBold
TargetInput.TextSize = 14
Library:Corner(TargetInput, 8)
local TIStroke = Instance.new("UIStroke", TargetInput); TIStroke.Color = Color3.fromRGB(60,60,70); TIStroke.Thickness = 1

-- HEADER TEXT
local TitleBox1 = Instance.new("TextLabel", TargetBox)
TitleBox1.Size = UDim2.new(0, 100, 0, 15)
TitleBox1.Position = UDim2.new(1, -110, 0, 8)
TitleBox1.Text = "TARGET PLAYER (מטרה)"
TitleBox1.TextColor3 = Settings.Theme.Gold
TitleBox1.BackgroundTransparency = 1
TitleBox1.Font = Enum.Font.GothamBold
TitleBox1.TextSize = 10
TitleBox1.TextXAlignment = Enum.TextXAlignment.Right

-- AVATAR
local TargetAvatar = Instance.new("ImageLabel", TargetBox)
TargetAvatar.Size = UDim2.new(0, 45, 0, 45)
TargetAvatar.Position = UDim2.new(0.8, 0, 0.25, 0) 
TargetAvatar.BackgroundColor3 = Color3.fromRGB(30,30,40)
TargetAvatar.Image = "rbxassetid://0"
Library:Corner(TargetAvatar, 25)
local TAStroke = Instance.new("UIStroke", TargetAvatar); TAStroke.Color = Color3.fromRGB(60,60,70); TAStroke.Thickness = 1

-- STATUS UI
local StatusContainer = Instance.new("Frame", TargetBox)
StatusContainer.Size = UDim2.new(0, 60, 0, 15)
StatusContainer.Position = UDim2.new(0.8, 0, 0.75, 0)
StatusContainer.BackgroundTransparency = 1

local StatusLayout = Instance.new("UIListLayout", StatusContainer)
StatusLayout.FillDirection = Enum.FillDirection.Horizontal
StatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
StatusLayout.Padding = UDim.new(0, 5)

local StatusDot = Instance.new("Frame", StatusContainer)
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.BackgroundColor3 = Color3.fromRGB(100,100,110)
StatusDot.LayoutOrder = 2
Library:Corner(StatusDot, 4)

local StatusText = Instance.new("TextLabel", StatusContainer)
StatusText.Size = UDim2.new(0, 40, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "WAITING"
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 9
StatusText.TextColor3 = Color3.fromRGB(100,100,110)
StatusText.LayoutOrder = 1

-- LIVE STATUS CHECKER
task.spawn(function()
    while true do
        task.wait(1)
        if TargetInput.Text ~= "" then
            local p = GetPlayer(TargetInput.Text)
            if p then
                 StatusText.Text = "ONLINE"
                 StatusText.TextColor3 = Color3.fromRGB(50, 255, 100)
                 StatusDot.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
            else
                 StatusText.Text = "OFFLINE"
                 StatusText.TextColor3 = Color3.fromRGB(255, 50, 50)
                 StatusDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            end
        else
            StatusText.Text = "WAITING"
            StatusText.TextColor3 = Color3.fromRGB(100, 100, 110)
            StatusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
        end
    end
end)

TargetInput.FocusLost:Connect(function()
    local p = GetPlayer(TargetInput.Text)
    if p then
        TargetInput.Text = p.Name
        PlaySound(Sounds.Click)
        local content = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        TargetAvatar.Image = content
    else
        TargetAvatar.Image = "rbxassetid://0"
    end
end)

-- BOX 2: ACTIONS (Redesigned)
local ActionBox = Instance.new("Frame", TargetScroll)
ActionBox.Size = UDim2.new(0.95, 0, 0, 180)
ActionBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
ActionBox.ClipsDescendants = true 
Library:Corner(ActionBox, 12)
local ABStroke = Instance.new("UIStroke", ActionBox); ABStroke.Color = Color3.fromRGB(50,50,60); ABStroke.Thickness = 1

local TitleBox2 = Instance.new("TextLabel", ActionBox)
TitleBox2.Size = UDim2.new(0, 100, 0, 15)
TitleBox2.Position = UDim2.new(1, -110, 0, 8)
TitleBox2.Text = "ACTIONS (פעולות)"
TitleBox2.TextColor3 = Settings.Theme.Gold
TitleBox2.BackgroundTransparency = 1
TitleBox2.Font = Enum.Font.GothamBold
TitleBox2.TextSize = 10
TitleBox2.TextXAlignment = Enum.TextXAlignment.Right

-- GRID LAYOUT
local ActionGrid = Instance.new("UIGridLayout", ActionBox)
ActionGrid.CellSize = UDim2.new(0.45, 0, 0.35, 0) 
ActionGrid.CellPadding = UDim2.new(0.05, 0, 0.10, 0)
ActionGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
ActionGrid.VerticalAlignment = Enum.VerticalAlignment.Center
local ActionPad = Instance.new("UIPadding", ActionBox)
ActionPad.PaddingTop = UDim.new(0, 30) 
ActionPad.PaddingBottom = UDim.new(0, 10)

local function CreateToggleBtn(parent, text, callback)
    local b = Instance.new("TextButton", parent)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(180, 180, 190)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    Library:Corner(b, 8)
    local bs = Instance.new("UIStroke", b); bs.Color = Color3.fromRGB(50,50,60); bs.Thickness=1
    
    local state = false
    b.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        if state then
            Library:Tween(b, {BackgroundColor3 = Settings.Theme.Gold, TextColor3 = Color3.new(0,0,0)})
            Library:Tween(bs, {Color = Settings.Theme.Gold})
        else
            Library:Tween(b, {BackgroundColor3 = Color3.fromRGB(30, 30, 38), TextColor3 = Color3.fromRGB(180, 180, 190)})
            Library:Tween(bs, {Color = Color3.fromRGB(50,50,60)})
        end
    end)
    return b
end

-- 1. BANG
local TrollConnection = nil
CreateToggleBtn(ActionBox, "BANG 💥", function(state)
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
        
        -- R6 uses the Animation
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
                
                -- CFRAME MATH (SINE WAVE)
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
CreateToggleBtn(ActionBox, "SPECTATE 👁️", function(state)
    local target = GetPlayer(TargetInput.Text)
    if state and target and target.Character then
        workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
    else
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end)

-- 3. HEADSIT
local HeadSitConnection = nil
CreateToggleBtn(ActionBox, "HEADSIT 🤠", function(state)
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

-- 4. BACKPACK
local BackpackConnection = nil
CreateToggleBtn(ActionBox, "BACKPACK 🎒", function(state)
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

-- BOX 3: SCANNER (Redesigned)
local ScannerBox = Instance.new("Frame", TargetScroll)
ScannerBox.Size = UDim2.new(0.95, 0, 0, 250)
ScannerBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Library:Corner(ScannerBox, 12)
local SBStroke = Instance.new("UIStroke", ScannerBox); SBStroke.Color = Color3.fromRGB(50,50,60); SBStroke.Thickness = 1

-- HEBREW HEADER FOR BOX 3
local TitleBox3 = Instance.new("TextLabel", ScannerBox)
TitleBox3.Size = UDim2.new(0, 100, 0, 15)
TitleBox3.Position = UDim2.new(1, -110, 0, 8)
TitleBox3.Text = "INVENTORY SCAN (סורק)"
TitleBox3.TextColor3 = Settings.Theme.Gold
TitleBox3.BackgroundTransparency = 1
TitleBox3.Font = Enum.Font.GothamBold
TitleBox3.TextSize = 10
TitleBox3.TextXAlignment = Enum.TextXAlignment.Right

local ScanButton = Instance.new("TextButton", ScannerBox)
ScanButton.Size = UDim2.new(0.9, 0, 0, 40)
ScanButton.Position = UDim2.new(0.05, 0, 0.12, 0)
ScanButton.BackgroundColor3 = Settings.Theme.Gold
-- FIXED TEXT
ScanButton.Text = "SCAN INVENTORY 🔍" 
ScanButton.TextColor3 = Color3.new(0,0,0)
ScanButton.Font = Enum.Font.GothamBold
ScanButton.TextSize = 14
Library:Corner(ScanButton, 8)
-- Button Pulse
task.spawn(function()
    while ScanButton.Parent do
        Library:Tween(ScanButton, {BackgroundColor3 = Color3.fromRGB(255, 230, 100)}, 1)
        task.wait(1)
        Library:Tween(ScanButton, {BackgroundColor3 = Settings.Theme.Gold}, 1)
        task.wait(1)
    end
end)

local ScanResults = Instance.new("ScrollingFrame", ScannerBox)
ScanResults.Size = UDim2.new(0.9, 0, 0.65, 0)
ScanResults.Position = UDim2.new(0.05, 0, 0.30, 0)
ScanResults.BackgroundTransparency = 1
ScanResults.ScrollBarThickness = 2 
ScanResults.ScrollBarImageColor3 = Settings.Theme.Gold
ScanResults.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScanResults.CanvasSize = UDim2.new(0,0,0,0)
local ScanList = Instance.new("UIListLayout", ScanResults); ScanList.SortOrder = Enum.SortOrder.LayoutOrder; ScanList.Padding = UDim.new(0,5)

ScanButton.MouseButton1Click:Connect(function()
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
        row.Size = UDim2.new(1, 0, 0, 50)
        row.BackgroundTransparency = 1
        
        local rowBg = Instance.new("Frame", row)
        rowBg.Size=UDim2.new(1,0,1,-4); rowBg.BackgroundColor3=Color3.fromRGB(30,30,35); Library:Corner(rowBg,6)
        
        -- IMAGE ON RIGHT
        local icon = Instance.new("ImageLabel", row)
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.Position = UDim2.new(1, -10, 0.5, 0)
        icon.BackgroundTransparency = 1
        if itemsIcon[name] then icon.Image = itemsIcon[name] else icon.Image = "rbxassetid://6503956166" end 
        
        -- TEXT ALIGNED LEFT
        local txt = Instance.new("TextLabel", row)
        txt.Size = UDim2.new(1, -60, 1, 0)
        txt.Position = UDim2.new(0, 10, 0, 0)
        txt.BackgroundTransparency = 1
        txt.Text = name
        txt.TextColor3 = Color3.fromRGB(220, 220, 230)
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 13
        txt.TextXAlignment = Enum.TextXAlignment.Left
        
        local cnt = Instance.new("TextLabel", row)
        cnt.Size = UDim2.new(0, 50, 1, 0)
        cnt.Position = UDim2.new(1, -100, 0, 0)
        cnt.BackgroundTransparency = 1
        cnt.Text = "x"..count
        cnt.TextColor3 = Settings.Theme.Gold
        cnt.Font=Enum.Font.GothamBlack
        cnt.TextSize=14
        cnt.TextXAlignment=Enum.TextXAlignment.Right
    end
    
    if not found then
        local msg = Instance.new("TextLabel", ScanResults); msg.Size=UDim2.new(1,0,0,20); msg.BackgroundTransparency=1; msg.Text="No rare items found."; msg.TextColor3=Color3.fromRGB(150,150,150); msg.Font=Enum.Font.Gotham; msg.TextSize=14
    end
end)


--// 11. OTHER TABS (SETTINGS, CREDITS) - Redesigned
CreateSlider(Tab_Settings_Page, "FOV", "שדה ראייה", 70, 120, 70, function(v) Camera.FieldOfView = v end)
CreateSlider(Tab_Settings_Page, "GUI SCALE", "גודל ממשק", 5, 15, 10, function(v) 
    local scale = v / 10
    Library:Tween(MainScale, {Scale = scale}, 0.5, Enum.EasingStyle.Quart)
end)
local MenuBindCont = Instance.new("Frame", Tab_Settings_Page); MenuBindCont.Size = UDim2.new(0.95,0,0,75); MenuBindCont.BackgroundTransparency = 1; CreateSquareBind(MenuBindCont, 3, "MENU KEY", "מקש תפריט", Settings.Keys.Menu, function(k) Settings.Keys.Menu = k end)

local RejoinBtn = Instance.new("TextButton", Tab_Settings_Page)
RejoinBtn.Size = UDim2.new(0.95, 0, 0, 50)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
RejoinBtn.Text = "REJOIN SERVER 🔄"
RejoinBtn.TextColor3 = Color3.new(1,1,1)
RejoinBtn.Font = Enum.Font.GothamBlack
RejoinBtn.TextSize = 14
Library:Corner(RejoinBtn, 10)
Library:AddGlow(RejoinBtn, Color3.fromRGB(200, 60, 60), 1)
RejoinBtn.MouseButton1Click:Connect(function() 
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- CREDITS (Redesigned)
local CreditBG = Instance.new("Frame", Tab_Credits_Page)
CreditBG.Size = UDim2.new(1,0,1,0)
CreditBG.BackgroundColor3 = Color3.fromRGB(10,10,12)
CreditBG.ZIndex=0
Library:Corner(CreditBG, 0)
local CreditSnow = Instance.new("Frame", Tab_Credits_Page)
CreditSnow.Size = UDim2.new(1,0,1,0); CreditSnow.BackgroundTransparency=1; CreditSnow.ClipsDescendants=true; CreditSnow.ZIndex=1
task.spawn(function() while Tab_Credits_Page.Parent do if Tab_Credits_Page.Visible then SpawnSnow(CreditSnow) end; task.wait(0.5) end end)

local function CreateCreditCard(parent, name, role, discord, decal, pos, size)
    local c = Instance.new("Frame", parent)
    c.Size = size or UDim2.new(0.44, 0, 0, 110)
    c.Position = pos or UDim2.new(0,0,0,0)
    c.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    c.ZIndex = 2
    Library:Corner(c, 12)
    local cs = Instance.new("UIStroke", c); cs.Color = Color3.fromRGB(50,50,60); cs.Thickness=1
    
    local imgCont = Instance.new("Frame", c)
    imgCont.Size = UDim2.new(0, 55, 0, 55)
    imgCont.Position = UDim2.new(0.5, -27, 0.12, 0)
    imgCont.BackgroundColor3 = Color3.fromRGB(40,40,45)
    imgCont.ZIndex = 3
    Library:Corner(imgCont, 30)
    local ims = Instance.new("UIStroke", imgCont); ims.Color = Settings.Theme.Gold; ims.Thickness=1
    
    local img = Instance.new("ImageLabel", imgCont)
    img.Size = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://" .. decal 
    img.ZIndex = 4
    Library:Corner(img, 30)
    
    local tName = Instance.new("TextLabel", c)
    tName.Size = UDim2.new(1,0,0,20)
    tName.Position = UDim2.new(0,0,0.62,0)
    tName.BackgroundTransparency = 1
    tName.Text = name; tName.Font=Enum.Font.GothamBlack; tName.TextSize=14; tName.TextColor3 = Settings.Theme.Gold; tName.ZIndex=3
    
    local tRole = Instance.new("TextLabel", c)
    tRole.Size = UDim2.new(1,0,0,15)
    tRole.Position = UDim2.new(0,0,0.74,0)
    tRole.BackgroundTransparency = 1
    tRole.Text = role; tRole.TextColor3 = Settings.Theme.IceBlue; tRole.Font=Enum.Font.GothamBold; tRole.TextSize=10; tRole.ZIndex=3
    
    local btn = Instance.new("TextButton", c)
    btn.Size = UDim2.new(0, 100, 0, 20)
    btn.Position = UDim2.new(0.5, -50, 0.90, 0)
    btn.BackgroundColor3 = Settings.Theme.Discord
    btn.Text="Copy Discord 👾"
    btn.TextColor3=Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 9
    btn.ZIndex=3
    Library:Corner(btn, 10)
    btn.MouseButton1Click:Connect(function() 
        setclipboard(discord)
        local old = btn.Text; btn.Text="Copied!"; btn.BackgroundColor3=Color3.fromRGB(60,200,100)
        task.wait(1)
        btn.Text=old; btn.BackgroundColor3=Settings.Theme.Discord 
    end)
end

CreateCreditCard(Tab_Credits_Page, "Neho", "Founder", "nx3ho", "97462570733982", UDim2.new(0.04, 0, 0.05, 0)) 
CreateCreditCard(Tab_Credits_Page, "BadShot", "CoFounder", "8adshot3", "133430813410950", UDim2.new(0.52, 0, 0.05, 0))
CreateCreditCard(Tab_Credits_Page, "xyth", "Manager", "sc4rlxrd", "106705865211282", UDim2.new(0.28, 0, 0.45, 0))

local SceneContainer = Instance.new("Frame", Tab_Credits_Page)
SceneContainer.Size = UDim2.new(1, 0, 0.35, 0)
SceneContainer.Position = UDim2.new(0, 0, 0.65, 0)
SceneContainer.BackgroundTransparency = 1
SceneContainer.ClipsDescendants = true 
SceneContainer.ZIndex = 3
local Hill1 = Instance.new("Frame", SceneContainer); Hill1.Size = UDim2.new(0.6, 0, 1, 0); Hill1.Position = UDim2.new(-0.1, 0, 0.4, 0); Hill1.BackgroundColor3 = Color3.fromRGB(25, 30, 40); Hill1.BorderSizePixel=0; Library:Corner(Hill1, 100)
local Hill2 = Instance.new("Frame", SceneContainer); Hill2.Size = UDim2.new(0.7, 0, 1.2, 0); Hill2.Position = UDim2.new(0.4, 0, 0.5, 0); Hill2.BackgroundColor3 = Color3.fromRGB(30, 35, 45); Hill2.BorderSizePixel=0; Library:Corner(Hill2, 100)
local SnowmanFrame = Instance.new("Frame", SceneContainer); SnowmanFrame.Size = UDim2.new(0, 80, 0, 80); SnowmanFrame.Position = UDim2.new(0.15, 0, 0.35, 0); SnowmanFrame.BackgroundTransparency = 1; SnowmanFrame.ZIndex = 4
local SnowmanBody = Instance.new("TextLabel", SnowmanFrame); SnowmanBody.Text = "⛄"; SnowmanBody.Size = UDim2.new(1, 0, 1, 0); SnowmanBody.BackgroundTransparency = 1; SnowmanBody.TextSize = 60; SnowmanBody.ZIndex = 4
task.spawn(function() local t = 0; while SnowmanFrame.Parent do t = t + 0.15; SnowmanBody.Rotation = math.sin(t) * 5; task.wait(0.03) end end)
local Tree1 = Instance.new("TextLabel", SceneContainer); Tree1.Text = "🌲"; Tree1.Size = UDim2.new(0, 90, 0, 90); Tree1.Position = UDim2.new(0.78, 0, 0.35, 0); Tree1.BackgroundTransparency = 1; Tree1.TextSize = 80; Tree1.ZIndex=4
local Tree2 = Instance.new("TextLabel", SceneContainer); Tree2.Text = "🌲"; Tree2.Size = UDim2.new(0, 70, 0, 70); Tree2.Position = UDim2.new(0.68, 0, 0.5, 0); Tree2.BackgroundTransparency = 1; Tree2.TextSize = 60; Tree2.ZIndex=4

--// 12. FINALIZE & LOOPS
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Menu then 
            if MainFrame.Visible then 
                Library:Tween(MainFrame, {Size = UDim2.new(0,0,0,0)}, 0.4, Enum.EasingStyle.Back); 
                task.wait(0.3); 
                MainFrame.Visible = false 
                MiniPasta.Visible = true 
                Library:Tween(MiniPasta, {Size = UDim2.new(0, 55, 0, 55)}, 0.4, Enum.EasingStyle.Back)
            else 
                MiniPasta.Visible = false
                MainFrame.Visible = true; 
                MainFrame.Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT); 
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

task.spawn(function()
    while true do
        if MiniPasta and MiniPasta.Visible then
            local scale = 1 + math.sin(tick() * 3) * 0.1
            MiniPasta.Rotation = math.sin(tick() * 2) * 5
        end
        task.wait(0.1)
    end
end)

for _, btn in pairs(SideBtnContainer:GetChildren()) do
    if btn:IsA("TextButton") then
        btn.MouseEnter:Connect(function() 
             -- Only tween if not current tab
             if btn ~= currentTab then
                 Library:Tween(btn, {BackgroundColor3 = Color3.fromRGB(28, 28, 35)}, 0.3) 
             end
        end)
        btn.MouseLeave:Connect(function() 
             if btn ~= currentTab then
                 Library:Tween(btn, {BackgroundColor3 = Color3.fromRGB(18, 18, 22)}, 0.3) 
             end
        end)
    end
end

if RejoinBtn then
    RejoinBtn.MouseEnter:Connect(function() Library:Tween(RejoinBtn, {BackgroundColor3 = Color3.fromRGB(230, 80, 80)}, 0.2) end)
    RejoinBtn.MouseLeave:Connect(function() Library:Tween(RejoinBtn, {BackgroundColor3 = Color3.fromRGB(200, 60, 60)}, 0.2) end)
end

print("[SYSTEM] Spaghetti Mafia Hub v1.5 (REDESIGN) Loaded")
