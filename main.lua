--[[
    Spaghetti Mafia Hub v2.5 (COMPACT PREMIUM EDITION)
    Updates:
    - GUI SIZE: Compact & Modern (Smaller, cleaner).
    - DESIGN: "Excessive" Polish - Gradient Borders, Breathing Glows, Smooth Tweens.
    - LOGIC: 100% Original v1 Logic (Untouched Auto Farm/WallCheck).
    - PANEL: User Profile integrated seamlessly.
]]

--// 1. SERVICES & SETUP
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

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// 2. WHITELIST (RAW LINK FIXED)
local WHITELIST_URL = "https://raw.githubusercontent.com/Spaghettimafiav1/Spaghettimafiav1/main/Whitelist.txt"

local function CheckWhitelist()
    local success, content = pcall(function()
        return game:HttpGet(WHITELIST_URL .. "?t=" .. tick())
    end)
    if success and content then
        if string.find(content, LocalPlayer.Name) then
            return true
        else
            LocalPlayer:Kick("Spaghetti Hub: Not Whitelisted.")
            return false
        end
    else
        return true -- Fail-safe
    end
end
if not CheckWhitelist() then return end

--// 3. UI RESET & VARIABLES
if CoreGui:FindFirstChild("SpaghettiHub_Rel") then CoreGui.SpaghettiHub_Rel:Destroy() end
if CoreGui:FindFirstChild("SpaghettiLoading") then CoreGui.SpaghettiLoading:Destroy() end

local Settings = {
    Theme = {
        Gold = Color3.fromRGB(255, 200, 0), -- Deep Gold
        Dark = Color3.fromRGB(12, 12, 15), -- Premium Dark
        Sidebar = Color3.fromRGB(18, 18, 22),
        Text = Color3.fromRGB(240, 240, 240),
        IceBlue = Color3.fromRGB(100, 220, 255),
        Discord = Color3.fromRGB(88, 101, 242),
        Danger = Color3.fromRGB(220, 60, 60)
    },
    Keys = { Menu = Enum.KeyCode.RightControl, Fly = Enum.KeyCode.E, Speed = Enum.KeyCode.F },
    Fly = { Enabled = false, Speed = 50 },
    Speed = { Enabled = false, Value = 16 },
    Farming = false,
    FarmSpeed = 450
}

local FarmConnection = nil
local FarmBlacklist = {}
local CurrentTween = nil

--// 4. DESIGN LIBRARY (THE "WOW" FACTOR)
local Library = {}

function Library:Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

function Library:Corner(obj, r)
    local c = Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end

function Library:AddGlow(obj, color, thickness)
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Settings.Theme.Gold
    s.Thickness = thickness or 2.5
    s.Transparency = 0.4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    -- Breathing Animation
    task.spawn(function()
        while obj.Parent do
            TweenService:Create(s, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.7}):Play()
            task.wait(2)
            TweenService:Create(s, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.2}):Play()
            task.wait(2)
        end
    end)
    return s
end

function Library:Gradient(obj, c1, c2)
    local g = Instance.new("UIGradient", obj)
    g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}
    g.Rotation = 45
    return g
end

function Library:MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = obj.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
    obj.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    RunService.RenderStepped:Connect(function() if dragging and dragInput then local delta = dragInput.Position - dragStart; obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end

--// SNOW SYSTEM (OPTIMIZED)
local function SpawnSnow(parent)
    if not parent.Parent or not parent.Visible then return end
    local flake = Instance.new("TextLabel", parent)
    flake.Text = "❄️"
    flake.BackgroundTransparency = 1
    flake.TextColor3 = Color3.fromRGB(200, 230, 255)
    flake.Size = UDim2.new(0, math.random(10, 25), 0, math.random(10, 25))
    flake.Position = UDim2.new(math.random(1, 100)/100, 0, -0.1, 0)
    flake.ZIndex = 1
    
    local duration = math.random(4, 8)
    TweenService:Create(flake, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Position = UDim2.new(flake.Position.X.Scale, math.random(-20,20), 1.1, 0),
        Rotation = math.random(90, 270)
    }):Play()
    Debris:AddItem(flake, duration)
end

--// 5. LOADING SCREEN (PREMIUM)
local LoadGui = Instance.new("ScreenGui"); LoadGui.Name = "SpaghettiLoading"; LoadGui.Parent = CoreGui
local LoadMain = Instance.new("Frame", LoadGui)
LoadMain.Size = UDim2.new(0, 280, 0, 200) -- Compact
LoadMain.Position = UDim2.new(0.5, 0, 0.5, 0); LoadMain.AnchorPoint = Vector2.new(0.5, 0.5)
LoadMain.BackgroundColor3 = Settings.Theme.Dark
Library:Corner(LoadMain, 16); Library:AddGlow(LoadMain, Settings.Theme.Gold, 3)

local PastaIcon = Instance.new("TextLabel", LoadMain)
PastaIcon.Size = UDim2.new(1, 0, 0.5, 0); PastaIcon.Position = UDim2.new(0,0,0.1,0)
PastaIcon.BackgroundTransparency = 1; PastaIcon.Text = "🍝"; PastaIcon.TextSize = 60
TweenService:Create(PastaIcon, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 10, Size = UDim2.new(1.1, 0, 0.55, 0)}):Play()

local TitleLoad = Instance.new("TextLabel", LoadMain)
TitleLoad.Size = UDim2.new(1, 0, 0.2, 0); TitleLoad.Position = UDim2.new(0, 0, 0.55, 0)
TitleLoad.BackgroundTransparency = 1; TitleLoad.Text = "SPAGHETTI MAFIA"; TitleLoad.Font = Enum.Font.GothamBlack; TitleLoad.TextColor3 = Settings.Theme.Gold; TitleLoad.TextSize = 20

local LoadBar = Instance.new("Frame", LoadMain)
LoadBar.Size = UDim2.new(0, 0, 0, 4); LoadBar.Position = UDim2.new(0.1, 0, 0.85, 0)
LoadBar.BackgroundColor3 = Settings.Theme.Gold; Library:Corner(LoadBar, 2)
TweenService:Create(LoadBar, TweenInfo.new(2.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0.8, 0, 0, 4)}):Play()

task.wait(2.5)
LoadGui:Destroy()

--// 6. MAIN GUI (COMPACT)
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui

-- Open Button
local MiniPasta = Instance.new("TextButton", ScreenGui)
MiniPasta.Size = UDim2.new(0, 50, 0, 50); MiniPasta.Position = UDim2.new(0.02, 0, 0.5, 0)
MiniPasta.BackgroundColor3 = Settings.Theme.Sidebar; MiniPasta.Text = "🍝"; MiniPasta.TextSize = 30
MiniPasta.Visible = false; Library:Corner(MiniPasta, 25); Library:AddGlow(MiniPasta, Settings.Theme.Gold, 2)
Library:MakeDraggable(MiniPasta)

-- Main Frame (COMPACT SIZE: 600x400)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 600, 0, 400) 
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Settings.Theme.Dark
MainFrame.ClipsDescendants = true
Library:Corner(MainFrame, 14); Library:AddGlow(MainFrame, Settings.Theme.Gold, 3.5)
Library:MakeDraggable(MainFrame)

-- Animation In
MainFrame.Size = UDim2.new(0,0,0,0)
Library:Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 400)}, 0.5)

-- Top Bar
local TopBar = Instance.new("Frame", MainFrame); TopBar.Size = UDim2.new(1,0,0,50); TopBar.BackgroundTransparency = 1
local MainTitle = Instance.new("TextLabel", TopBar); MainTitle.Size = UDim2.new(0,200,1,0); MainTitle.Position = UDim2.new(0,20,0,0); MainTitle.BackgroundTransparency=1; MainTitle.Text = "SPAGHETTI <font color='#FFD700'>MAFIA</font>"; MainTitle.RichText=true; MainTitle.Font=Enum.Font.GothamBlack; MainTitle.TextSize=18; MainTitle.TextColor3=Color3.new(1,1,1); MainTitle.TextXAlignment=Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar); CloseBtn.Size = UDim2.new(0, 25, 0, 25); CloseBtn.Position = UDim2.new(1, -35, 0.5, -12.5); CloseBtn.BackgroundColor3 = Color3.fromRGB(40,40,45); CloseBtn.Text = "_"; CloseBtn.TextColor3 = Settings.Theme.Gold; Library:Corner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniPasta.Visible = true end)
MiniPasta.MouseButton1Click:Connect(function() MiniPasta.Visible = false; MainFrame.Visible = true end)

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 160, 1, -50); Sidebar.Position = UDim2.new(0,0,0,50)
Sidebar.BackgroundColor3 = Settings.Theme.Sidebar; Sidebar.BorderSizePixel = 0
Library:Corner(Sidebar, 10)

-- Button Container
local SideBtns = Instance.new("Frame", Sidebar); SideBtns.Size = UDim2.new(1,0,0.75,0); SideBtns.BackgroundTransparency=1
local SideList = Instance.new("UIListLayout", SideBtns); SideList.Padding = UDim.new(0,8); SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
local SidePad = Instance.new("UIPadding", SideBtns); SidePad.PaddingTop = UDim.new(0,10)

-- User Panel (Bottom of Sidebar)
local UserPanel = Instance.new("Frame", Sidebar)
UserPanel.Size = UDim2.new(0.9, 0, 0.2, 0); UserPanel.Position = UDim2.new(0.05, 0, 0.78, 0)
UserPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Library:Corner(UserPanel, 8); Library:AddGlow(UserPanel, Settings.Theme.Gold, 2)

local Avatar = Instance.new("ImageLabel", UserPanel)
Avatar.Size = UDim2.new(0, 35, 0, 35); Avatar.Position = UDim2.new(0.1, 0, 0.5, -17.5)
Avatar.BackgroundTransparency = 1; Library:Corner(Avatar, 18)
task.spawn(function() Avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end)

local Welcome = Instance.new("TextLabel", UserPanel); Welcome.Size = UDim2.new(0.5, 0, 0.4, 0); Welcome.Position = UDim2.new(0.4, 0, 0.15, 0); Welcome.BackgroundTransparency=1; Welcome.Text="Welcome,"; Welcome.TextColor3=Color3.fromRGB(150,150,150); Welcome.Font=Enum.Font.Gotham; Welcome.TextSize=10; Welcome.TextXAlignment=Enum.TextXAlignment.Left
local NameUsr = Instance.new("TextLabel", UserPanel); NameUsr.Size = UDim2.new(0.5, 0, 0.4, 0); NameUsr.Position = UDim2.new(0.4, 0, 0.5, 0); NameUsr.BackgroundTransparency=1; NameUsr.Text=LocalPlayer.DisplayName; NameUsr.TextColor3=Settings.Theme.Gold; NameUsr.Font=Enum.Font.GothamBold; NameUsr.TextSize=12; NameUsr.TextXAlignment=Enum.TextXAlignment.Left; NameUsr.TextTruncate=Enum.TextTruncate.AtEnd

-- Content Area
local Container = Instance.new("Frame", MainFrame); Container.Size = UDim2.new(1, -170, 1, -60); Container.Position = UDim2.new(0, 170, 0, 55); Container.BackgroundTransparency = 1

-- Tab System
local function CreateTab(name, heb, isFirst)
    local btn = Instance.new("TextButton", SideBtns)
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.BackgroundColor3 = Settings.Theme.Dark
    btn.Text = "  " .. name .. "\n  <font size='10' color='#888'>"..heb.."</font>"
    btn.RichText = true
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Library:Corner(btn, 8)
    
    local page = Instance.new("Frame", Container); page.Size = UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.Visible=false; page.Name=name.."Page"
    
    btn.MouseButton1Click:Connect(function()
        for _,v in pairs(SideBtns:GetChildren()) do if v:IsA("TextButton") then Library:Tween(v, {BackgroundColor3=Settings.Theme.Dark, TextColor3=Color3.fromRGB(200,200,200)}) end end
        for _,v in pairs(Container:GetChildren()) do v.Visible = false end
        Library:Tween(btn, {BackgroundColor3=Color3.fromRGB(35,35,40), TextColor3=Settings.Theme.Gold})
        page.Visible = true
    end)
    
    if isFirst then 
        Library:Tween(btn, {BackgroundColor3=Color3.fromRGB(35,35,40), TextColor3=Settings.Theme.Gold})
        page.Visible = true 
    end
    return page
end

local Tab_Event = CreateTab("Winter Event", "אירוע חורף", true)
local Tab_Main = CreateTab("Main", "ראשי", false)
local Tab_Settings = CreateTab("Settings", "הגדרות", false)
local Tab_Credits = CreateTab("Credits", "קרדיטים", false)

--// 7. ORIGINAL LOGIC (AUTO FARM V1)
task.spawn(function() while true do task.wait(60); pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end)

local function GetClosestTarget()
    local drops = Workspace:FindFirstChild("StormDrops"); if not drops then return nil end
    local closest, dist = nil, math.huge; local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then for _, v in pairs(drops:GetChildren()) do if v:IsA("BasePart") and not FarmBlacklist[v] then local mag = (hrp.Position - v.Position).Magnitude; if mag < dist then dist = mag; closest = v end end end end
    return closest
end

local function UltraSafeDisable() -- פונקציית החסימה המקורית
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
    Settings.Farming = v; if not v then FarmBlacklist = {}; if CurrentTween then CurrentTween:Cancel() end end
    
    if not FarmConnection and v then
        FarmConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and Settings.Farming then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid"); if hum then hum.Sit = false; hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
                UltraSafeDisable()
            end
        end)
    elseif not v and FarmConnection then 
        FarmConnection:Disconnect(); FarmConnection = nil 
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid"); if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
        end
    end

    if v then
        task.spawn(function()
            while Settings.Farming do
                local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local target = GetClosestTarget()
                if char and hrp and target then
                    local distance = (hrp.Position - target.Position).Magnitude
                    local tween = TweenService:Create(hrp, TweenInfo.new(distance / Settings.FarmSpeed, Enum.EasingStyle.Linear), {CFrame = target.CFrame}); tween:Play()
                    local start = tick(); local stuckStart = tick() 
                    repeat task.wait() 
                        if not target.Parent or not Settings.Farming then if CurrentTween then CurrentTween:Cancel() end; break end
                        local currentDist = (hrp.Position - target.Position).Magnitude
                        if currentDist < 8 then
                            target.CanTouch = true; hrp.CFrame = target.CFrame 
                            if (tick() - stuckStart) > 0.6 then if CurrentTween then CurrentTween:Cancel() end; FarmBlacklist[target] = true; break end
                        else stuckStart = tick() end
                        if (tick() - start) > (distance / Settings.FarmSpeed) + 1.5 then if CurrentTween then CurrentTween:Cancel() end; break end
                    until not target.Parent
                else task.wait(0.1) end
                task.wait()
            end
        end)
    end
end

--// 8. TABS CONTENT (COMPACT & PRETTY)
local Scroll = Instance.new("ScrollingFrame", Tab_Event); Scroll.Size = UDim2.new(1,0,1,0); Scroll.BackgroundTransparency=1; Scroll.ScrollBarThickness=2
local List = Instance.new("UIListLayout", Scroll); List.Padding = UDim.new(0,10); List.HorizontalAlignment = Enum.HorizontalAlignment.Center; List.SortOrder = Enum.SortOrder.LayoutOrder
local Pad = Instance.new("UIPadding", Scroll); Pad.PaddingTop = UDim.new(0,10)

-- Snow in Event Tab
local EventSnow = Instance.new("Frame", Tab_Event); EventSnow.Size = UDim2.new(1,0,1,0); EventSnow.BackgroundTransparency=1; EventSnow.ClipsDescendants=true; EventSnow.ZIndex=0
task.spawn(function() while Tab_Event.Parent do if Tab_Event.Visible then SpawnSnow(EventSnow) end; task.wait(0.5) end end)

-- Farm Button (Centerpiece)
local FarmBtn = Instance.new("TextButton", Scroll); FarmBtn.Size = UDim2.new(0.95, 0, 0, 60); FarmBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 70); FarmBtn.Text = ""; FarmBtn.LayoutOrder = 1
Library:Corner(FarmBtn, 10); Library:AddGlow(FarmBtn, Settings.Theme.IceBlue, 2)

local FTitle = Instance.new("TextLabel", FarmBtn); FTitle.Size = UDim2.new(1,-60,1,0); FTitle.Position=UDim2.new(0,15,0,0); FTitle.Text="Toggle Auto Farm ❄️"; FTitle.Font=Enum.Font.GothamBold; FTitle.TextSize=16; FTitle.TextColor3=Color3.new(1,1,1); FTitle.TextXAlignment=Enum.TextXAlignment.Left; FTitle.BackgroundTransparency=1
local FSwitch = Instance.new("Frame", FarmBtn); FSwitch.Size=UDim2.new(0,40,0,22); FSwitch.Position=UDim2.new(1,-55,0.5,-11); FSwitch.BackgroundColor3=Color3.fromRGB(40,40,60); Library:Corner(FSwitch,20)
local FDot = Instance.new("Frame", FSwitch); FDot.Size=UDim2.new(0,18,0,18); FDot.Position=UDim2.new(0,2,0.5,-9); FDot.BackgroundColor3=Color3.fromRGB(200,200,200); Library:Corner(FDot,20)

FarmBtn.MouseButton1Click:Connect(function() 
    isFarming = not isFarming; ToggleFarm(isFarming)
    if isFarming then Library:Tween(FSwitch,{BackgroundColor3=Settings.Theme.IceBlue}); Library:Tween(FDot,{Position=UDim2.new(1,-20,0.5,-9)}) else Library:Tween(FSwitch,{BackgroundColor3=Color3.fromRGB(40,40,60)}); Library:Tween(FDot,{Position=UDim2.new(0,2,0.5,-9)}) end
end)

-- Stats Grid
local StatGrid = Instance.new("Frame", Scroll); StatGrid.Size=UDim2.new(0.95,0,0,60); StatGrid.BackgroundTransparency=1; StatGrid.LayoutOrder=2
local GLayout = Instance.new("UIGridLayout", StatGrid); GLayout.CellSize=UDim2.new(0.48,0,1,0); GLayout.CellPadding=UDim2.new(0.04,0,0,0)

local BlueBox = Instance.new("Frame", StatGrid); BlueBox.BackgroundColor3=Color3.fromRGB(20,40,60); Library:Corner(BlueBox,8); Library:AddGlow(BlueBox, Settings.Theme.IceBlue, 1)
local BlueVal = Instance.new("TextLabel", BlueBox); BlueVal.Size=UDim2.new(1,0,1,0); BlueVal.BackgroundTransparency=1; BlueVal.Text="0"; BlueVal.TextColor3=Color3.new(1,1,1); BlueVal.Font=Enum.Font.GothamBold; BlueVal.TextSize=20
local BlueLbl = Instance.new("TextLabel", BlueBox); BlueLbl.Size=UDim2.new(1,0,0.3,0); BlueLbl.BackgroundTransparency=1; BlueLbl.Text="Blue Shards"; BlueLbl.TextColor3=Settings.Theme.IceBlue; BlueLbl.Font=Enum.Font.Gotham; BlueLbl.TextSize=10

local RedBox = Instance.new("Frame", StatGrid); RedBox.BackgroundColor3=Color3.fromRGB(60,20,20); Library:Corner(RedBox,8); Library:AddGlow(RedBox, Settings.Theme.CrystalRed, 1)
local RedVal = Instance.new("TextLabel", RedBox); RedVal.Size=UDim2.new(1,0,1,0); RedVal.BackgroundTransparency=1; RedVal.Text="0"; RedVal.TextColor3=Color3.new(1,1,1); RedVal.Font=Enum.Font.GothamBold; RedVal.TextSize=20
local RedLbl = Instance.new("TextLabel", RedBox); RedLbl.Size=UDim2.new(1,0,0.3,0); RedLbl.BackgroundTransparency=1; RedLbl.Text="Red Crystals"; RedLbl.TextColor3=Settings.Theme.CrystalRed; RedLbl.Font=Enum.Font.Gotham; RedLbl.TextSize=10

task.spawn(function()
    while true do task.wait(0.5)
        pcall(function() BlueVal.Text = LocalPlayer.Shards.Value; RedVal.Text = LocalPlayer.Crystals.Value end)
    end
end)

-- Main & Settings Elements
local function AddSlider(tab, name, min, max, default, callback)
    local f = Instance.new("Frame", tab); f.Size=UDim2.new(0.9,0,0,50); f.BackgroundColor3=Settings.Theme.Box; Library:Corner(f,8); Library:AddGlow(f,Color3.fromRGB(60,60,60),1)
    local lbl = Instance.new("TextLabel", f); lbl.Size=UDim2.new(1,0,0.5,0); lbl.Position=UDim2.new(0,10,0,0); lbl.BackgroundTransparency=1; lbl.Text=name; lbl.TextColor3=Color3.new(1,1,1); lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local line = Instance.new("Frame", f); line.Size=UDim2.new(0.9,0,0,6); line.Position=UDim2.new(0.05,0,0.6,0); line.BackgroundColor3=Color3.fromRGB(40,40,40); Library:Corner(line,3)
    local fill = Instance.new("Frame", line); fill.Size=UDim2.new((default-min)/(max-min),0,1,0); fill.BackgroundColor3=Settings.Theme.Gold; Library:Corner(fill,3)
    local btn = Instance.new("TextButton", f); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Down:Connect(function() local move = UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then local r=math.clamp((i.Position.X-line.AbsolutePosition.X)/line.AbsoluteSize.X,0,1); fill.Size=UDim2.new(r,0,1,0); callback(math.floor(min+((max-min)*r))) end end); UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then move:Disconnect() end end) end)
end

local MainScroll = Instance.new("ScrollingFrame", Tab_Main); MainScroll.Size=UDim2.new(1,0,1,0); MainScroll.BackgroundTransparency=1; MainScroll.ScrollBarThickness=2
local MainList = Instance.new("UIListLayout", MainScroll); MainList.Padding=UDim.new(0,10); MainList.HorizontalAlignment=Enum.HorizontalAlignment.Center
local MainPad = Instance.new("UIPadding", MainScroll); MainPad.PaddingTop=UDim.new(0,10)

AddSlider(MainScroll, "Walk Speed", 16, 200, 16, function(v) Settings.Speed.Value=v; if Settings.Speed.Enabled and LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed=v end end)
AddSlider(MainScroll, "Fly Speed", 20, 200, 50, function(v) Settings.Fly.Speed=v end)

-- Settings Rejoin
local SettList = Instance.new("UIListLayout", Tab_Settings); SettList.Padding=UDim.new(0,10); SettList.HorizontalAlignment=Enum.HorizontalAlignment.Center
local SettPad = Instance.new("UIPadding", Tab_Settings); SettPad.PaddingTop=UDim.new(0,10)
local Rejoin = Instance.new("TextButton", Tab_Settings); Rejoin.Size=UDim2.new(0.9,0,0,40); Rejoin.BackgroundColor3=Settings.Theme.Danger; Rejoin.Text="Rejoin Server 🔄"; Rejoin.TextColor3=Color3.new(1,1,1); Rejoin.Font=Enum.Font.GothamBold; Rejoin.TextSize=14; Library:Corner(Rejoin,8)
Rejoin.MouseButton1Click:Connect(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

-- CREDITS (COMPACT PYRAMID)
local CreditsBG = Instance.new("Frame", Tab_Credits); CreditsBG.Size=UDim2.new(1,0,1,0); CreditsBG.BackgroundTransparency=1; CreditsBG.ZIndex=0
-- Snow Scenery
local Hill1 = Instance.new("Frame", CreditsBG); Hill1.Size=UDim2.new(0.6,0,0.4,0); Hill1.Position=UDim2.new(-0.1,0,0.7,0); Hill1.BackgroundColor3=Color3.fromRGB(240,248,255); Library:Corner(Hill1,80)
local Hill2 = Instance.new("Frame", CreditsBG); Hill2.Size=UDim2.new(0.7,0,0.5,0); Hill2.Position=UDim2.new(0.4,0,0.6,0); Hill2.BackgroundColor3=Color3.fromRGB(230,240,250); Library:Corner(Hill2,80)
local Snowman = Instance.new("TextLabel", CreditsBG); Snowman.Text="⛄"; Snowman.Size=UDim2.new(0,50,0,50); Snowman.Position=UDim2.new(0.1,0,0.65,0); Snowman.BackgroundTransparency=1; Snowman.TextSize=40; Snowman.Rotation=-8

local function CreditCard(name, role, discord, id, pos)
    local c = Instance.new("Frame", Tab_Credits); c.Size=UDim2.new(0.42,0,0,110); c.Position=pos; c.BackgroundColor3=Settings.Theme.Box; Library:Corner(c,10); Library:AddGlow(c, Settings.Theme.Gold, 2)
    local img = Instance.new("ImageLabel", c); img.Size=UDim2.new(0,50,0,50); img.Position=UDim2.new(0.5,-25,0.1,0); img.BackgroundTransparency=1; img.Image="rbxassetid://"..id; Library:Corner(img,25)
    local t = Instance.new("TextLabel", c); t.Size=UDim2.new(1,0,0,15); t.Position=UDim2.new(0,0,0.6,0); t.BackgroundTransparency=1; t.Text=name; t.TextColor3=Settings.Theme.Gold; t.Font=Enum.Font.GothamBold; t.TextSize=12
    local r = Instance.new("TextLabel", c); r.Size=UDim2.new(1,0,0,15); r.Position=UDim2.new(0,0,0.73,0); r.BackgroundTransparency=1; r.Text=role; r.TextColor3=Settings.Theme.IceBlue; r.Font=Enum.Font.Gotham; r.TextSize=10
    local b = Instance.new("TextButton", c); b.Size=UDim2.new(0,80,0,20); b.Position=UDim2.new(0.5,-40,0.85,0); b.BackgroundColor3=Settings.Theme.Discord; b.Text="Discord"; b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; b.TextSize=10; Library:Corner(b,10)
    b.MouseButton1Click:Connect(function() setclipboard(discord); b.Text="Copied!"; task.wait(1); b.Text="Discord" end)
end

CreditCard("Neho", "Founder", "nx3ho", "97462570733982", UDim2.new(0.06,0,0.05,0))
CreditCard("BadShot", "CoFounder", "8adshot3", "133430813410950", UDim2.new(0.52,0,0.05,0))
CreditCard("xyth", "Community Manager", "sc4rlxrd", "106705865211282", UDim2.new(0.29,0,0.35,0))

--// 9. INPUT HANDLING
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Menu then 
            if MainFrame.Visible then Library:Tween(MainFrame, {Size=UDim2.new(0,0,0,0)}, 0.3); task.wait(0.3); MainFrame.Visible=false 
            else MainFrame.Visible=true; MainFrame.Size=UDim2.new(0,600,0,400); Library:Tween(MainFrame, {Size=UDim2.new(0,600,0,400)}, 0.5) end 
        end
        if i.KeyCode == Settings.Keys.Fly then Settings.Fly.Enabled = not Settings.Fly.Enabled; ToggleFly(Settings.Fly.Enabled) end
        if i.KeyCode == Settings.Keys.Speed then Settings.Speed.Enabled = not Settings.Speed.Enabled end
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.Speed.Enabled and LocalPlayer.Character then local h = LocalPlayer.Character:FindFirstChild("Humanoid"); if h then h.WalkSpeed = Settings.Speed.Value end end
end)

print("[SYSTEM] Spaghetti Mafia Hub v2.5 (COMPACT & POWERFUL) Loaded")
