--[[
    Spaghetti Mafia Hub v1 (COMPACT & CLEAN EDITION)
    
    Style: Minimalist, Dark Matte, Gold Accents.
    Size: Small (500x330).
    Logic: 100% Preserved.
]]

--// 1. SERVICES & LOGIC (NO CHANGES)
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

--// WHITELIST
local WHITELIST_URL = "https://raw.githubusercontent.com/Spaghettimafiav1/Spaghettimafiav1/main/Whitelist.txt"

local function CheckWhitelist()
    local success, content = pcall(function()
        return game:HttpGet(WHITELIST_URL .. "?t=" .. tick())
    end)
    if success and content then
        if string.find(content, LocalPlayer.Name) then
            return true
        else
            LocalPlayer:Kick("Not Whitelisted: "..LocalPlayer.Name)
            return false
        end
    else
        return true 
    end
end
if not CheckWhitelist() then return end

--// CLEANUP
if CoreGui:FindFirstChild("SpaghettiHub_Rel") then CoreGui.SpaghettiHub_Rel:Destroy() end
if CoreGui:FindFirstChild("SpaghettiLoading") then CoreGui.SpaghettiLoading:Destroy() end

--// SETTINGS
local Settings = {
    Theme = {
        Main = Color3.fromRGB(20, 20, 20),      -- רקע ראשי כהה
        Sidebar = Color3.fromRGB(15, 15, 15),   -- צד כהה יותר
        Item = Color3.fromRGB(30, 30, 30),      -- צבע כפתורים
        Accent = Color3.fromRGB(255, 200, 0),   -- זהב עדין
        Text = Color3.fromRGB(240, 240, 240),
        TextDark = Color3.fromRGB(150, 150, 150),
        Ice = Color3.fromRGB(100, 200, 255)
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

--// LIBRARY (UI UTILS)
local Library = {}

function Library:Tween(obj, props, time) 
    TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play() 
end

function Library:Corner(obj, r) 
    local c = Instance.new("UICorner", obj); c.CornerRadius = UDim.new(0, r or 6); return c 
end

function Library:Stroke(obj, color, thick)
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Settings.Theme.Item
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = 0.8
    return s
end

function Library:MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = obj.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
    obj.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    RunService.RenderStepped:Connect(function() if dragging and dragInput then local delta = dragInput.Position - dragStart; obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end

--// SNOW (Reduced size for aesthetics)
local function SpawnSnow(parent)
    if not parent.Parent or not parent.Visible then return end
    local flake = Instance.new("Frame", parent)
    flake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    flake.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4)) -- נקודות קטנות במקום טקסט
    flake.Position = UDim2.new(math.random(1, 100)/100, 0, -0.1, 0)
    flake.BorderSizePixel = 0
    Library:Corner(flake, 4)
    flake.BackgroundTransparency = 0.5
    
    local duration = math.random(3, 6)
    TweenService:Create(flake, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Position = UDim2.new(flake.Position.X.Scale, math.random(-20,20), 1.1, 0),
        BackgroundTransparency = 1
    }):Play()
    Debris:AddItem(flake, duration)
end

--// 4. GUI SETUP (COMPACT)
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false

-- כפתור פתיחה קטן
local Mini = Instance.new("TextButton", ScreenGui)
Mini.Size = UDim2.new(0, 40, 0, 40) -- קטן יותר
Mini.Position = UDim2.new(0.02, 0, 0.5, -20)
Mini.BackgroundColor3 = Settings.Theme.Main
Mini.Text = "🍝"
Mini.TextSize = 20
Mini.Visible = false
Library:Corner(Mini, 8)
Library:Stroke(Mini, Settings.Theme.Accent, 2)

-- מסגרת ראשית (הוקטנה משמעותית)
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 330) -- Compact Size
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Settings.Theme.Main
Main.ClipsDescendants = true
Library:Corner(Main, 8)
Library:Stroke(Main, Settings.Theme.Accent, 1)
Library:MakeDraggable(Main)

-- אנימציית פתיחה
Main.Size = UDim2.new(0,0,0,0)
Library:Tween(Main, {Size = UDim2.new(0, 520, 0, 330)}, 0.4)

-- Sidebar (Left)
local Side = Instance.new("Frame", Main)
Side.Size = UDim2.new(0, 130, 1, 0)
Side.BackgroundColor3 = Settings.Theme.Sidebar
Side.BorderSizePixel = 0
local SideList = Instance.new("UIListLayout", Side); SideList.Padding = UDim.new(0, 5); SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center
local SidePad = Instance.new("UIPadding", Side); SidePad.PaddingTop = UDim.new(0, 15)

-- Title
local Title = Instance.new("TextLabel", Side)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "MAFIA <font color='#FFD700'>HUB</font>"
Title.RichText = true
Title.Font = Enum.Font.GothamBlack
Title.TextColor3 = Color3.new(1,1,1)
Title.TextSize = 16

-- Container (Right)
local PageContainer = Instance.new("Frame", Main)
PageContainer.Size = UDim2.new(1, -130, 1, 0)
PageContainer.Position = UDim2.new(0, 130, 0, 0)
PageContainer.BackgroundTransparency = 1

-- Close Button
local Close = Instance.new("TextButton", PageContainer)
Close.Size = UDim2.new(0, 25, 0, 25)
Close.Position = UDim2.new(1, -30, 0, 10)
Close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
Close.Text = ""
Library:Corner(Close, 4)
Close.MouseButton1Click:Connect(function()
    Main.Visible = false; Mini.Visible = true
end)
Mini.MouseButton1Click:Connect(function()
    Mini.Visible = false; Main.Visible = true
end)

--// TAB SYSTEM
local function CreateTab(name, icon)
    local btn = Instance.new("TextButton", Side)
    btn.Size = UDim2.new(0.85, 0, 0, 35) -- כפתור נמוך וקומפקטי
    btn.BackgroundColor3 = Settings.Theme.Sidebar
    btn.Text = "  " .. name
    btn.Font = Enum.Font.GothamMedium
    btn.TextColor3 = Settings.Theme.TextDark
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Library:Corner(btn, 6)
    
    local page = Instance.new("ScrollingFrame", PageContainer)
    page.Size = UDim2.new(1, 0, 1, -40)
    page.Position = UDim2.new(0, 0, 0, 40)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 2
    page.BorderSizePixel = 0
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8) -- צמצום רווחים
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local pad = Instance.new("UIPadding", page); pad.PaddingTop = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        for _,v in pairs(Side:GetChildren()) do if v:IsA("TextButton") then 
            Library:Tween(v, {BackgroundColor3 = Settings.Theme.Sidebar, TextColor3 = Settings.Theme.TextDark}) 
        end end
        for _,v in pairs(PageContainer:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
        
        Library:Tween(btn, {BackgroundColor3 = Settings.Theme.Item, TextColor3 = Settings.Theme.Accent})
        page.Visible = true
    end)
    
    return page, btn
end

local Tab_Event, Btn_Event = CreateTab("Winter Event", "❄️")
local Tab_Main, Btn_Main = CreateTab("Main", "🏠")
local Tab_Settings, Btn_Settings = CreateTab("Settings", "⚙️")
local Tab_Credits, Btn_Credits = CreateTab("Credits", "👥")

-- Select First
Library:Tween(Btn_Event, {BackgroundColor3 = Settings.Theme.Item, TextColor3 = Settings.Theme.Ice})
Tab_Event.Visible = true

--// WIDGETS (COMPACT VERSIONS)

-- 1. Farm Toggle (Compact)
local FarmCard = Instance.new("Frame", Tab_Event)
FarmCard.Size = UDim2.new(0.92, 0, 0, 50) -- נמוך
FarmCard.BackgroundColor3 = Settings.Theme.Item
Library:Corner(FarmCard, 6)
local FarmBtn = Instance.new("TextButton", FarmCard)
FarmBtn.Size = UDim2.new(1,0,1,0); FarmBtn.BackgroundTransparency=1; FarmBtn.Text=""; 

local FTitle = Instance.new("TextLabel", FarmCard)
FTitle.Text = "Auto Farm"; FTitle.Font = Enum.Font.GothamBold; FTitle.TextColor3 = Settings.Theme.Text; FTitle.TextSize = 14
FTitle.Size = UDim2.new(0, 100, 1, 0); FTitle.Position = UDim2.new(0, 15, 0, 0); FTitle.BackgroundTransparency = 1; FTitle.TextXAlignment = Enum.TextXAlignment.Left

local FStatus = Instance.new("Frame", FarmCard)
FStatus.Size = UDim2.new(0, 40, 0, 20); FStatus.Position = UDim2.new(1, -55, 0.5, -10); FStatus.BackgroundColor3 = Color3.fromRGB(50,50,50)
Library:Corner(FStatus, 10)
local FDot = Instance.new("Frame", FStatus); FDot.Size = UDim2.new(0,16,0,16); FDot.Position = UDim2.new(0,2,0.5,-8); FDot.BackgroundColor3=Color3.fromRGB(200,200,200); Library:Corner(FDot,10)

local isFarming = false
local function UpdateFarm(val)
    isFarming = val
    ToggleFarm(val) -- Logic Function
    Library:Tween(FStatus, {BackgroundColor3 = val and Settings.Theme.Ice or Color3.fromRGB(50,50,50)})
    Library:Tween(FDot, {Position = val and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)})
end
FarmBtn.MouseButton1Click:Connect(function() UpdateFarm(not isFarming) end)

-- 2. Stats Grid (Compact)
local StatGrid = Instance.new("Frame", Tab_Event)
StatGrid.Size = UDim2.new(0.92, 0, 0, 60)
StatGrid.BackgroundTransparency = 1
local GL = Instance.new("UIGridLayout", StatGrid); GL.CellSize = UDim2.new(0.48, 0, 1, 0); GL.CellPadding = UDim2.new(0.04, 0, 0, 0)

local function MakeStat(name, color)
    local f = Instance.new("Frame", StatGrid); f.BackgroundColor3 = Settings.Theme.Item; Library:Corner(f, 6)
    local t = Instance.new("TextLabel", f); t.Text=name; t.Position=UDim2.new(0,10,0,5); t.TextColor3=color; t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextSize=12; t.TextXAlignment=Enum.TextXAlignment.Left
    local v = Instance.new("TextLabel", f); v.Text="0"; v.Position=UDim2.new(0,10,0,25); v.TextColor3=Color3.new(1,1,1); v.BackgroundTransparency=1; v.Font=Enum.Font.GothamBlack; v.TextSize=18; v.TextXAlignment=Enum.TextXAlignment.Left
    return v
end
local ValBlue = MakeStat("Ice Shards", Settings.Theme.Ice)
local ValRed = MakeStat("Crystals", Settings.Theme.Accent)

-- Logic for Stats
task.spawn(function()
    while true do
        task.wait(1)
        if LocalPlayer:FindFirstChild("Shards") then ValBlue.Text = tostring(LocalPlayer.Shards.Value) end
        if LocalPlayer:FindFirstChild("Crystals") then ValRed.Text = tostring(LocalPlayer.Crystals.Value) end
    end
end)

-- 3. Sliders & Toggles (Compact)
local function CreateSlider(parent, name, min, max, default, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0.92, 0, 0, 40) -- Slim
    f.BackgroundColor3 = Settings.Theme.Item
    Library:Corner(f, 6)
    
    local t = Instance.new("TextLabel", f); t.Text = name; t.Size=UDim2.new(0.4,0,1,0); t.Position=UDim2.new(0,10,0,0); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamMedium; t.TextColor3=Settings.Theme.Text; t.TextSize=13; t.TextXAlignment=Enum.TextXAlignment.Left
    
    local val = Instance.new("TextLabel", f); val.Text = tostring(default); val.Size=UDim2.new(0,30,1,0); val.Position=UDim2.new(1,-35,0,0); val.BackgroundTransparency=1; val.Font=Enum.Font.Gotham; val.TextColor3=Settings.Theme.TextDark; val.TextSize=12
    
    local bar = Instance.new("Frame", f); bar.Size = UDim2.new(0.4, 0, 0, 4); bar.Position = UDim2.new(0.45, 0, 0.5, -2); bar.BackgroundColor3 = Color3.fromRGB(50,50,50); Library:Corner(bar, 2)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new(0,0,1,0); fill.BackgroundColor3 = Settings.Theme.Accent; Library:Corner(fill, 2)
    
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text=""
    
    local function Update(input)
        local r = math.clamp((input.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        Library:Tween(fill, {Size = UDim2.new(r,0,1,0)}, 0.1)
        local v = math.floor(min + (max-min)*r)
        val.Text = tostring(v)
        callback(v)
    end
    
    btn.MouseButton1Down:Connect(function()
        local con = UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then con:Disconnect() end end)
        Update({Position = UIS:GetMouseLocation()}) -- Instant click
    end)
end

CreateSlider(Tab_Main, "WalkSpeed", 16, 200, 16, function(v) Settings.Speed.Value = v; if Settings.Speed.Enabled then LocalPlayer.Character.Humanoid.WalkSpeed = v end end)
CreateSlider(Tab_Main, "FlySpeed", 20, 200, 50, function(v) Settings.Fly.Speed = v end)

local function CreateToggle(parent, name, callback)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.92,0,0,35); f.BackgroundColor3 = Settings.Theme.Item; Library:Corner(f,6)
    local t = Instance.new("TextLabel", f); t.Text=name; t.Position=UDim2.new(0,10,0,0); t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamMedium; t.TextColor3=Settings.Theme.Text; t.TextSize=13; t.TextXAlignment=Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0,30,0,30); btn.Position=UDim2.new(1,-35,0,2.5); btn.BackgroundColor3=Color3.fromRGB(50,50,50); btn.Text=""; Library:Corner(btn,4)
    
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        Library:Tween(btn, {BackgroundColor3 = on and Settings.Theme.Accent or Color3.fromRGB(50,50,50)})
        callback(on)
    end)
end

CreateToggle(Tab_Main, "Enable Speed (Key: F)", function(v) 
    Settings.Speed.Enabled = v 
    if not v then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end
end)

CreateToggle(Tab_Main, "Enable Fly (Key: E)", function(v) 
    Settings.Fly.Enabled = v
    ToggleFly(v) 
end)

-- Rejoin Button (Compact)
local Rejoin = Instance.new("TextButton", Tab_Settings)
Rejoin.Size = UDim2.new(0.92, 0, 0, 35)
Rejoin.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
Rejoin.Text = "Rejoin Server"
Rejoin.TextColor3 = Color3.new(1,1,1)
Rejoin.Font = Enum.Font.GothamBold
Rejoin.TextSize = 13
Library:Corner(Rejoin, 6)
Rejoin.MouseButton1Click:Connect(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

--// CREDITS (COMPACT & CLEAN)
local CreditCont = Instance.new("Frame", Tab_Credits); CreditCont.Size = UDim2.new(0.92, 0, 0, 180); CreditCont.BackgroundTransparency=1
-- נשתמש במיקום ידני כדי שזה יראה טוב
local function MiniCred(name, role, udimPos)
    local c = Instance.new("Frame", CreditCont)
    c.Size = UDim2.new(0.47, 0, 0, 80) -- כרטיס קטן
    c.Position = udimPos
    c.BackgroundColor3 = Settings.Theme.Item
    Library:Corner(c, 6)
    Library:Stroke(c, Settings.Theme.Accent, 1)
    
    local t = Instance.new("TextLabel", c); t.Text = name; t.Size=UDim2.new(1,0,0,20); t.Position=UDim2.new(0,0,0.2,0); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBold; t.TextColor3=Settings.Theme.Accent; t.TextSize=14
    local r = Instance.new("TextLabel", c); r.Text = role; r.Size=UDim2.new(1,0,0,15); r.Position=UDim2.new(0,0,0.5,0); r.BackgroundTransparency=1; r.Font=Enum.Font.Gotham; r.TextColor3=Settings.Theme.TextDark; r.TextSize=11
end

MiniCred("Neho", "Founder", UDim2.new(0.26, 0, 0, 0)) -- Top Center
MiniCred("BadShot", "Co-Founder", UDim2.new(0, 0, 0, 90)) -- Bottom Left
MiniCred("xyth", "Manager", UDim2.new(0.53, 0, 0, 90)) -- Bottom Right

--// LOGIC FUNCTIONS (SAME AS ORIGINAL)
function ToggleFarm(v)
    Settings.Farming = v; if not v then FarmBlacklist = {} end
    if not FarmConnection and v then
        FarmConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and Settings.Farming then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid"); if hum then hum.Sit = false; hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
                if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                   -- Safety disable touch
                end
            end
        end)
    elseif not v and FarmConnection then FarmConnection:Disconnect(); FarmConnection = nil end

    if v then
        task.spawn(function()
            while Settings.Farming do
                local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local target = GetClosestTarget()
                if char and hrp and target then
                    local distance = (hrp.Position - target.Position).Magnitude
                    local tween = TweenService:Create(hrp, TweenInfo.new(distance / Settings.FarmSpeed, Enum.EasingStyle.Linear), {CFrame = target.CFrame}); tween:Play()
                    local start = tick()
                    repeat task.wait() 
                        if not target.Parent or not Settings.Farming then tween:Cancel(); break end
                        if (hrp.Position - target.Position).Magnitude < 8 then target.CanTouch = true; hrp.CFrame = target.CFrame; task.wait(0.2) break end
                        if (tick() - start) > (distance / Settings.FarmSpeed) + 1.5 then tween:Cancel(); break end
                    until not target.Parent
                else task.wait(0.1) end
                task.wait()
            end
        end)
    end
end

function GetClosestTarget()
    local drops = Workspace:FindFirstChild("StormDrops"); if not drops then return nil end
    local closest, dist = nil, math.huge; local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then for _, v in pairs(drops:GetChildren()) do if v:IsA("BasePart") and not FarmBlacklist[v] then local mag = (hrp.Position - v.Position).Magnitude; if mag < dist then dist = mag; closest = v end end end end
    return closest
end

function ToggleFly(v)
    -- Same old fly logic
    local char = LocalPlayer.Character; if not char then return end; local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid")
    if v then
        local bv = Instance.new("BodyVelocity",hrp); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Name="F_V"; local bg = Instance.new("BodyGyro",hrp); bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.P=9e4; bg.Name="F_G"; hum.PlatformStand=true
        task.spawn(function()
            while Settings.Fly.Enabled and char.Parent do
                local cam = workspace.CurrentCamera; local d = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
                bv.Velocity = d * Settings.Fly.Speed; bg.CFrame = cam.CFrame; RunService.Heartbeat:Wait()
            end
            if hrp:FindFirstChild("F_V") then hrp.F_V:Destroy() end; if hrp:FindFirstChild("F_G") then hrp.F_G:Destroy() end; hum.PlatformStand=false
        end)
    else if hrp:FindFirstChild("F_V") then hrp.F_V:Destroy() end; if hrp:FindFirstChild("F_G") then hrp.F_G:Destroy() end; hum.PlatformStand=false end
end

-- Input Handling
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Menu then Main.Visible = not Main.Visible end
        if i.KeyCode == Settings.Keys.Fly then Settings.Fly.Enabled = not Settings.Fly.Enabled; ToggleFly(Settings.Fly.Enabled) end
        if i.KeyCode == Settings.Keys.Speed then Settings.Speed.Enabled = not Settings.Speed.Enabled end
    end
end)

-- Auto Start Farm Logic
task.spawn(function()
    task.wait(1)
    if not isFarming then UpdateFarm(true) end
end)

-- Background Snow (Event Tab)
task.spawn(function()
    while Tab_Event.Parent do
        if Tab_Event.Visible then SpawnSnow(Tab_Event) end
        task.wait(0.5)
    end
end)

print("Spaghetti Mafia Compact Loaded")
