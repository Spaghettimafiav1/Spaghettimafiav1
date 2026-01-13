--[[
    Spaghetti Mafia Hub v1 (ULTIMATE COMPACT FIXED)
    Updates:
    - Restored ALL logic (nothing deleted).
    - GUI Resized to be Small & Aesthetic (Mini-Mode).
    - Cleaner Fonts & Darker Theme.
    - Preserved: Whitelist, AutoExec, Farm, Fly, Credits.
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

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// 1. מערכת Whitelist (המקורית)
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
        Gold = Color3.fromRGB(255, 200, 50), -- קצת יותר עדין
        Dark = Color3.fromRGB(15, 15, 15),   -- שחור מט נקי
        Box = Color3.fromRGB(25, 25, 25),    -- אפור כהה מאוד
        Text = Color3.fromRGB(240, 240, 240),
        
        IceBlue = Color3.fromRGB(100, 200, 255),
        IceDark = Color3.fromRGB(10, 15, 25),
        
        ShardBlue = Color3.fromRGB(50, 180, 255),
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

--// 3. פונקציות עיצוב (Glow ו-Tween מקוריים)
local Library = {}
function Library:Tween(obj, props, time, style) TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play() end

function Library:AddGlow(obj, color) 
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Settings.Theme.Gold
    s.Thickness = 2 -- הקטנתי טיפה את העובי שיראה אסתטי בקטן
    s.Transparency = 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    task.spawn(function()
        while obj.Parent do
            TweenService:Create(s, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.8}):Play()
            task.wait(1.5)
            TweenService:Create(s, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.4}):Play()
            task.wait(1.5)
        end
    end)
    return s 
end

function Library:Corner(obj, r) local c = Instance.new("UICorner", obj); c.CornerRadius = UDim.new(0, r or 8); return c end -- רדיוס קטן יותר
function Library:Gradient(obj, c1, c2, rot) local g = Instance.new("UIGradient", obj); g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}; g.Rotation = rot or 45; return g end
function Library:MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = obj.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
    obj.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    RunService.RenderStepped:Connect(function() if dragging and dragInput then local delta = dragInput.Position - dragStart; obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end

--// שלג (הפונקציה המקורית)
local function SpawnSnow(parent)
    if not parent.Parent or not parent.Visible then return end
    local flake = Instance.new("TextLabel", parent)
    flake.Text = "❄️"
    flake.BackgroundTransparency = 1
    flake.TextColor3 = Color3.fromRGB(255, 255, 255)
    flake.Size = UDim2.new(0, math.random(10, 20), 0, math.random(10, 20)) -- הקטנתי את השלג שיתאים ל-GUI הקטן
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

--// 4. מסך טעינה (מוקטן)
local LoadGui = Instance.new("ScreenGui"); LoadGui.Name = "SpaghettiLoading"; LoadGui.Parent = CoreGui
local LoadBox = Instance.new("Frame", LoadGui)
LoadBox.Size = UDim2.new(0, 200, 0, 140) -- הקטנתי
LoadBox.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadBox.AnchorPoint = Vector2.new(0.5, 0.5)
LoadBox.ClipsDescendants = true 
LoadBox.BorderSizePixel = 0
LoadBox.BackgroundColor3 = Settings.Theme.Dark
Library:Corner(LoadBox, 12)
Library:AddGlow(LoadBox, Settings.Theme.Gold)

local PastaIcon = Instance.new("TextLabel", LoadBox)
PastaIcon.Size = UDim2.new(1, 0, 0.5, 0); PastaIcon.Position = UDim2.new(0,0,0.1,0)
PastaIcon.BackgroundTransparency = 1; PastaIcon.Text = "🍝"; PastaIcon.TextSize = 50; PastaIcon.ZIndex = 15
TweenService:Create(PastaIcon, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 10, Size = UDim2.new(1.1, 0, 0.55, 0)}):Play()

local TitleLoad = Instance.new("TextLabel", LoadBox)
TitleLoad.Size = UDim2.new(1, 0, 0.2, 0); TitleLoad.Position = UDim2.new(0, 0, 0.55, 0)
TitleLoad.BackgroundTransparency = 1; TitleLoad.Text = "Spaghetti Mafia"; 
TitleLoad.Font = Enum.Font.GothamBlack; TitleLoad.TextColor3 = Settings.Theme.Gold; TitleLoad.TextSize = 16
TitleLoad.ZIndex = 15

local SubLoad = Instance.new("TextLabel", LoadBox)
SubLoad.Size = UDim2.new(1, 0, 0.2, 0); SubLoad.Position = UDim2.new(0, 0, 0.75, 0)
SubLoad.BackgroundTransparency = 1; SubLoad.Text = "Loading..."; 
SubLoad.Font = Enum.Font.Gotham; SubLoad.TextColor3 = Color3.new(1,1,1); SubLoad.TextSize = 12
SubLoad.ZIndex = 15

task.spawn(function()
    while LoadBox.Parent do
        SpawnSnow(LoadBox)
        task.wait(0.3) 
    end
end)

task.wait(2)
LoadGui:Destroy()

--// 5. GUI ראשי (גרסת MINI COMPACT)
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false

local MiniPasta = Instance.new("TextButton", ScreenGui); MiniPasta.Size = UDim2.new(0, 45, 0, 45); MiniPasta.Position = UDim2.new(0.02, 0, 0.5, 0); MiniPasta.BackgroundColor3 = Settings.Theme.Box; MiniPasta.Text = "🍝"; MiniPasta.TextSize = 25; MiniPasta.Visible = false; Library:Corner(MiniPasta, 12); Library:AddGlow(MiniPasta); Library:MakeDraggable(MiniPasta)

local MainFrame = Instance.new("Frame", ScreenGui); 
-- השינוי הגדול: מידות קטנות יותר
MainFrame.Size = UDim2.new(0, 500, 0, 340) 
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); 
MainFrame.BackgroundColor3 = Settings.Theme.Dark; 
MainFrame.ClipsDescendants = true; 
Library:Corner(MainFrame, 12); 
Library:AddGlow(MainFrame, Settings.Theme.Gold)

MainFrame.Size = UDim2.new(0,0,0,0); Library:Tween(MainFrame, {Size = UDim2.new(0, 500, 0, 340)}, 0.5, Enum.EasingStyle.Back) 

local MainScale = Instance.new("UIScale", MainFrame); MainScale.Scale = 1
local TopBar = Instance.new("Frame", MainFrame); TopBar.Size = UDim2.new(1,0,0,40); TopBar.BackgroundTransparency = 1; TopBar.BorderSizePixel = 0; Library:MakeDraggable(MainFrame)

local MainTitle = Instance.new("TextLabel", TopBar); MainTitle.Size = UDim2.new(0,200,0,30); MainTitle.Position = UDim2.new(0,15,0,5); MainTitle.BackgroundTransparency = 1; MainTitle.Text = "SPAGHETTI <font color='#FFD700'>MAFIA</font>"; MainTitle.RichText = true; MainTitle.Font = Enum.Font.GothamBlack; MainTitle.TextSize = 16; MainTitle.TextColor3 = Color3.new(1,1,1); MainTitle.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar); CloseBtn.Size = UDim2.new(0, 25, 0, 25); CloseBtn.Position = UDim2.new(1, -35, 0, 8); CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); CloseBtn.Text = "_"; CloseBtn.TextColor3 = Settings.Theme.Gold; CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextSize=14; Library:Corner(CloseBtn, 6); Library:AddGlow(CloseBtn, Settings.Theme.Gold)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniPasta.Visible = true; Library:Tween(MiniPasta, {Size = UDim2.new(0, 45, 0, 45)}, 0.4, Enum.EasingStyle.Elastic) end)
MiniPasta.MouseButton1Click:Connect(function() MiniPasta.Visible = false; MainFrame.Visible = true; Library:Tween(MainFrame, {Size = UDim2.new(0, 500, 0, 340)}, 0.4, Enum.EasingStyle.Back) end)

--// Sidebar (קטן יותר)
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 130, 1, -45)
Sidebar.Position = UDim2.new(0,0,0,45)
Sidebar.BackgroundColor3 = Settings.Theme.Box
Sidebar.BorderSizePixel = 0 
Sidebar.ZIndex = 2
Library:Corner(Sidebar, 8)

local SideBtnContainer = Instance.new("Frame", Sidebar)
SideBtnContainer.Size = UDim2.new(1, 0, 1, 0)
SideBtnContainer.BackgroundTransparency = 1

local SideList = Instance.new("UIListLayout", SideBtnContainer); SideList.Padding = UDim.new(0,8); SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center; SideList.SortOrder = Enum.SortOrder.LayoutOrder
local SidePad = Instance.new("UIPadding", SideBtnContainer); SidePad.PaddingTop = UDim.new(0,10)

local Container = Instance.new("Frame", MainFrame); Container.Size = UDim2.new(1, -140, 1, -50); Container.Position = UDim2.new(0, 140, 0, 45); Container.BackgroundTransparency = 1

local currentTab = nil

-- פונקציית יצירת טאב (כפתורים קטנים יותר)
local function CreateTab(name, icon, order, isWinter)
    local btn = Instance.new("TextButton", SideBtnContainer)
    btn.Size = UDim2.new(0.85,0,0,32) -- כפתור נמוך
    btn.BackgroundColor3 = Settings.Theme.Dark
    btn.Text = "  " .. icon .. " " .. name
    btn.RichText = true
    btn.TextColor3 = isWinter and Color3.fromRGB(150, 180, 200) or Color3.fromRGB(150,150,150)
    btn.Font = Enum.Font.GothamMedium -- פונט נקי יותר
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 3
    btn.LayoutOrder = order
    btn.BorderSizePixel = 0
    Library:Corner(btn, 6)
    
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
        
        local activeColor = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold
        local activeBG = isWinter and Settings.Theme.IceDark or Color3.fromRGB(35, 35, 40)
        
        Library:Tween(btn, {BackgroundColor3 = activeBG, TextColor3 = activeColor})
        page.Visible = true
    end)
    
    if order == 1 then 
        currentTab = btn
        local activeColor = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold
        local activeBG = isWinter and Settings.Theme.IceDark or Color3.fromRGB(35, 35, 40)
        Library:Tween(btn, {BackgroundColor3 = activeBG, TextColor3 = activeColor})
        page.Visible = true 
    end
    return page
end

local Tab_Event_Page = CreateTab("Winter", "❄️", 1, true) 
local Tab_Main_Page = CreateTab("Main", "🏠", 2, false)
local Tab_Settings_Page = CreateTab("Config", "⚙️", 3, false)
local Tab_Credits_Page = CreateTab("Credits", "👥", 4, false)

local function AddLayout(p) 
    local l = Instance.new("UIListLayout", p); l.Padding = UDim.new(0,8); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local pad = Instance.new("UIPadding", p); pad.PaddingTop = UDim.new(0,5) 
end
AddLayout(Tab_Main_Page); AddLayout(Tab_Settings_Page)

--// 6. מערכות לוגיקה (FARM LOGIC - ללא שינוי בכלל!)
task.spawn(function() while true do task.wait(60); pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end end)

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
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid"); if hum then hum.Sit = false; hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end
                UltraSafeDisable()
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
    Settings.Fly.Enabled = v; local char = LocalPlayer.Character; if not char then return end; local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid")
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

--// 7. Event Tab (Compact Design)
local EventBackground = Instance.new("Frame", Tab_Event_Page)
EventBackground.Size = UDim2.new(1,0,1,0)
EventBackground.ZIndex = 0
Library:Gradient(EventBackground, Color3.fromRGB(15, 30, 50), Color3.fromRGB(5, 10, 20), 45)

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
EventLayout.Padding = UDim.new(0, 10) -- פחות מרווח
EventLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
EventLayout.SortOrder = Enum.SortOrder.LayoutOrder 
local EventPad = Instance.new("UIPadding", Tab_Farm_Scroll); EventPad.PaddingTop = UDim.new(0,10)

-- 1. כפתור החווה (דק יותר)
local FarmBtn = Instance.new("TextButton", Tab_Farm_Scroll)
FarmBtn.Size = UDim2.new(0.96, 0, 0, 55) -- היה 70
FarmBtn.BackgroundColor3 = Color3.fromRGB(30, 50, 70)
FarmBtn.Text = ""
FarmBtn.LayoutOrder = 1
Library:Corner(FarmBtn, 8)
Library:AddGlow(FarmBtn, Settings.Theme.IceBlue)

local FarmTitle = Instance.new("TextLabel", FarmBtn)
FarmTitle.Size = UDim2.new(1, -60, 1, 0)
FarmTitle.Position = UDim2.new(0, 15, 0, 0)
FarmTitle.Text = "Auto Farm ❄️"
FarmTitle.RichText = true
FarmTitle.TextColor3 = Color3.new(1,1,1)
FarmTitle.Font = Enum.Font.GothamBold
FarmTitle.TextSize = 16
FarmTitle.TextXAlignment = Enum.TextXAlignment.Left
FarmTitle.BackgroundTransparency = 1
FarmTitle.ZIndex = 6

local FarmSwitch = Instance.new("Frame", FarmBtn)
FarmSwitch.Size = UDim2.new(0, 40, 0, 22) -- קטן יותר
FarmSwitch.Position = UDim2.new(1, -50, 0.5, -11)
FarmSwitch.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
Library:Corner(FarmSwitch, 20)
local FarmDot = Instance.new("Frame", FarmSwitch)
FarmDot.Size = UDim2.new(0, 18, 0, 18)
FarmDot.Position = UDim2.new(0, 2, 0.5, -9)
FarmDot.BackgroundColor3 = Color3.fromRGB(180, 200, 220)
Library:Corner(FarmDot, 20)

local isFarming = false
FarmBtn.MouseButton1Click:Connect(function() 
    isFarming = not isFarming; ToggleFarm(isFarming)
    if isFarming then 
        Library:Tween(FarmSwitch,{BackgroundColor3=Settings.Theme.IceBlue})
        Library:Tween(FarmDot,{Position=UDim2.new(1,-20,0.5,-9)}) 
    else 
        Library:Tween(FarmSwitch,{BackgroundColor3=Color3.fromRGB(40,40,60)}) 
        Library:Tween(FarmDot,{Position=UDim2.new(0,2,0.5,-9)}) 
    end 
end)

-- AUTO START FARM
task.spawn(function()
    task.wait(1) 
    if not isFarming then
        isFarming = true
        ToggleFarm(true)
        if FarmSwitch and FarmDot then
            Library:Tween(FarmSwitch,{BackgroundColor3=Settings.Theme.IceBlue})
            Library:Tween(FarmDot,{Position=UDim2.new(1,-20,0.5,-9)})
        end
    end
end)

-- 2. Total Balance (Compact)
local BalanceLabel = Instance.new("TextLabel", Tab_Farm_Scroll)
BalanceLabel.Size = UDim2.new(0.96,0,0,20)
BalanceLabel.Text = "Total Balance (סה''כ) 💰"
BalanceLabel.TextColor3 = Settings.Theme.Gold
BalanceLabel.Font=Enum.Font.GothamBold
BalanceLabel.TextSize=12
BalanceLabel.BackgroundTransparency=1
BalanceLabel.LayoutOrder = 2
BalanceLabel.ZIndex = 6

local BalanceContainer = Instance.new("Frame", Tab_Farm_Scroll)
BalanceContainer.Size = UDim2.new(0.96, 0, 0, 50) -- דק יותר
BalanceContainer.BackgroundTransparency = 1
BalanceContainer.LayoutOrder = 3
local BalanceGrid = Instance.new("UIGridLayout", BalanceContainer)
BalanceGrid.CellSize = UDim2.new(0.48, 0, 1, 0)
BalanceGrid.CellPadding = UDim2.new(0.04, 0, 0, 0)
BalanceGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

local TotBlues = Instance.new("Frame", BalanceContainer); TotBlues.BackgroundColor3 = Color3.fromRGB(15, 30, 50); Library:Corner(TotBlues, 8); local StrokeTotalB = Library:AddGlow(TotBlues, Settings.Theme.ShardBlue)
local T_TitleB = Instance.new("TextLabel", TotBlues); T_TitleB.Size = UDim2.new(1,0,0.4,0); T_TitleB.Position=UDim2.new(0,0,0.1,0); T_TitleB.BackgroundTransparency=1; T_TitleB.Text="Ice Shards"; T_TitleB.TextColor3=Settings.Theme.ShardBlue; T_TitleB.Font=Enum.Font.GothamBold; T_TitleB.TextSize=11; T_TitleB.ZIndex=6
local T_ValB = Instance.new("TextLabel", TotBlues); T_ValB.Size = UDim2.new(1,0,0.5,0); T_ValB.Position=UDim2.new(0,0,0.45,0); T_ValB.BackgroundTransparency=1; T_ValB.Text="..."; T_ValB.TextColor3=Color3.new(1,1,1); T_ValB.Font=Enum.Font.GothamBlack; T_ValB.TextSize=18; T_ValB.ZIndex=6

local TotReds = Instance.new("Frame", BalanceContainer); TotReds.BackgroundColor3 = Color3.fromRGB(30, 15, 15); Library:Corner(TotReds, 8); local StrokeTotalR = Library:AddGlow(TotReds, Settings.Theme.CrystalRed)
local T_TitleR = Instance.new("TextLabel", TotReds); T_TitleR.Size = UDim2.new(1,0,0.4,0); T_TitleR.Position=UDim2.new(0,0,0.1,0); T_TitleR.BackgroundTransparency=1; T_TitleR.Text="Crystals"; T_TitleR.TextColor3=Settings.Theme.CrystalRed; T_TitleR.Font=Enum.Font.GothamBold; T_TitleR.TextSize=11; T_TitleR.ZIndex=6
local T_ValR = Instance.new("TextLabel", TotReds); T_ValR.Size = UDim2.new(1,0,0.5,0); T_ValR.Position=UDim2.new(0,0,0.45,0); T_ValR.BackgroundTransparency=1; T_ValR.Text="..."; T_ValR.TextColor3=Color3.new(1,1,1); T_ValR.Font=Enum.Font.GothamBlack; T_ValR.TextSize=18; T_ValR.ZIndex=6

-- 3. Session Stats (Compact)
local StatsLabel = Instance.new("TextLabel", Tab_Farm_Scroll)
StatsLabel.Size = UDim2.new(0.96,0,0,20)
StatsLabel.Text = "Collected in Storm (נאסף בסשן) 📥"
StatsLabel.TextColor3 = Color3.fromRGB(200,230,255)
StatsLabel.Font=Enum.Font.GothamBold
StatsLabel.TextSize=12
StatsLabel.BackgroundTransparency=1
StatsLabel.LayoutOrder = 4
StatsLabel.ZIndex = 6

local StatsContainer = Instance.new("Frame", Tab_Farm_Scroll)
StatsContainer.Size = UDim2.new(0.96, 0, 0, 50) -- דק יותר
StatsContainer.BackgroundTransparency = 1
StatsContainer.LayoutOrder = 5
local StatsGrid = Instance.new("UIGridLayout", StatsContainer)
StatsGrid.CellSize = UDim2.new(0.48, 0, 1, 0)
StatsGrid.CellPadding = UDim2.new(0.04, 0, 0, 0)
StatsGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

local BoxBlue = Instance.new("Frame", StatsContainer); BoxBlue.BackgroundColor3 = Color3.fromRGB(15, 30, 50); Library:Corner(BoxBlue, 8); local StrokeBlue = Library:AddGlow(BoxBlue, Settings.Theme.IceBlue)
local TitleBlue = Instance.new("TextLabel", BoxBlue); TitleBlue.Size = UDim2.new(1, 0, 0.4, 0); TitleBlue.Position = UDim2.new(0,0,0.1,0); TitleBlue.BackgroundTransparency = 1; TitleBlue.Text = "Shards +"; TitleBlue.TextColor3 = Settings.Theme.IceBlue; TitleBlue.Font = Enum.Font.GothamBold; TitleBlue.TextSize = 11; TitleBlue.ZIndex=6
local ValBlue = Instance.new("TextLabel", BoxBlue); ValBlue.Size = UDim2.new(1, 0, 0.5, 0); ValBlue.Position = UDim2.new(0,0,0.45,0); ValBlue.BackgroundTransparency = 1; ValBlue.Text = "0"; ValBlue.TextColor3 = Color3.new(1, 1, 1); ValBlue.Font = Enum.Font.GothamBlack; ValBlue.TextSize = 18; ValBlue.ZIndex=6

local BoxRed = Instance.new("Frame", StatsContainer); BoxRed.BackgroundColor3 = Color3.fromRGB(30, 15, 15); Library:Corner(BoxRed, 8); local StrokeRed = Library:AddGlow(BoxRed, Settings.Theme.CrystalRed)
local TitleRed = Instance.new("TextLabel", BoxRed); TitleRed.Size = UDim2.new(1, 0, 0.4, 0); TitleRed.Position = UDim2.new(0,0,0.1,0); TitleRed.BackgroundTransparency = 1; TitleRed.Text = "Crystals +"; TitleRed.TextColor3 = Settings.Theme.CrystalRed; TitleRed.Font = Enum.Font.GothamBold; TitleRed.TextSize = 11; TitleRed.ZIndex=6
local ValRed = Instance.new("TextLabel", BoxRed); ValRed.Size = UDim2.new(1, 0, 0.5, 0); ValRed.Position = UDim2.new(0,0,0.45,0); ValRed.BackgroundTransparency = 1; ValRed.Text = "0"; ValRed.TextColor3 = Color3.new(1, 1, 1); ValRed.Font = Enum.Font.GothamBlack; ValRed.TextSize = 18; ValRed.ZIndex=6

-- 4. AFK Status
local AFKStatus = Instance.new("TextLabel", Tab_Farm_Scroll)
AFKStatus.Size = UDim2.new(0.96, 0, 0, 20)
AFKStatus.BackgroundTransparency = 1
AFKStatus.Text = "Anti-AFK: Active"
AFKStatus.TextColor3 = Color3.fromRGB(100,255,100)
AFKStatus.Font = Enum.Font.Gotham
AFKStatus.TextSize = 10
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

--// 8. רכיבים וטאבים אחרים (SLIDERS וכו' - מוקטנים)
local function CreateSlider(parent, title, heb, min, max, default, callback, toggleCallback, toggleName)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.96,0,0,55); f.BackgroundColor3 = Settings.Theme.Box; Library:Corner(f, 8); Library:AddGlow(f, Color3.fromRGB(50,50,50)) -- נמוך יותר (55)
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(0.7,0,0,25); l.Position = UDim2.new(0,10,0,5); l.Text = title; l.TextColor3=Color3.new(1,1,1); l.Font=Enum.Font.GothamBold; l.TextSize=12; l.TextXAlignment=Enum.TextXAlignment.Left; l.BackgroundTransparency=1
    local line = Instance.new("Frame", f); line.Size = UDim2.new(0.9,0,0,8); line.Position = UDim2.new(0.05,0,0.6,0); line.BackgroundColor3 = Color3.fromRGB(50,50,50); Library:Corner(line,4)
    local fill = Instance.new("Frame", line); fill.Size = UDim2.new((default-min)/(max-min),0,1,0); fill.BackgroundColor3 = Settings.Theme.Gold; Library:Corner(fill,4)
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Down:Connect(function() 
        local move = UIS.InputChanged:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.MouseMovement then 
                local r = math.clamp((i.Position.X - line.AbsolutePosition.X)/line.AbsoluteSize.X,0,1)
                fill.Size = UDim2.new(r,0,1,0)
                local v = math.floor(min+((max-min)*r))
                l.Text = title.." : "..v
                callback(v) 
            end 
        end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then move:Disconnect() end end) 
    end)
    if toggleCallback then
        local t = Instance.new("TextButton", f); t.Size = UDim2.new(0,40,0,20); t.Position = UDim2.new(1,-50,0,8); t.BackgroundColor3 = Color3.fromRGB(40,40,40); t.Text = "OFF"; t.TextColor3 = Color3.new(1,1,1); t.Font = Enum.Font.GothamBold; t.TextSize=10; Library:Corner(t,4)
        local on = false; local function Update(s) on=s; t.Text=on and "ON" or "OFF"; t.BackgroundColor3=on and Settings.Theme.Gold or Color3.fromRGB(40,40,40); t.TextColor3=on and Color3.new(0,0,0) or Color3.new(1,1,1); toggleCallback(on) end
        t.MouseButton1Click:Connect(function() Update(not on) end)
        if toggleName then VisualToggles[toggleName] = function(v) Update(v) end end
    end
end

local function CreateSquareBind(parent, id, title, heb, default, callback)
    local f = Instance.new("TextButton", parent); local sizeY = id==3 and 50 or 60; 
    f.Position = id==1 and UDim2.new(0,0,0,0) or (id==2 and UDim2.new(0.52,0,0,0) or UDim2.new(0,0,0,0)); 
    f.Size = UDim2.new(id==3 and 1 or 0.48,0,0,sizeY); 
    f.BackgroundColor3 = Settings.Theme.Box; f.Text=""; f.AutoButtonColor=false; Library:Corner(f, 8); Library:AddGlow(f, Color3.fromRGB(50,50,50))
    local t = Instance.new("TextLabel", f); t.Size = UDim2.new(1,0,0,20); t.Position = UDim2.new(0,0,0.1,0); t.Text=title; t.TextColor3=Color3.fromRGB(150,150,150); t.Font=Enum.Font.Gotham; t.TextSize=11; t.BackgroundTransparency=1
    local k = Instance.new("TextLabel", f); k.Size = UDim2.new(1,0,0,20); k.Position = UDim2.new(0,0,0.5,0); k.Text=default.Name; k.TextColor3=Settings.Theme.Gold; k.Font=Enum.Font.GothamBold; k.TextSize=16; k.BackgroundTransparency=1
    f.MouseButton1Click:Connect(function() k.Text="..."; local i=UIS.InputBegan:Wait(); if i.UserInputType==Enum.UserInputType.Keyboard then k.Text=i.KeyCode.Name; callback(i.KeyCode) end end)
    return f
end

CreateSlider(Tab_Main_Page, "Walk Speed", "מהירות", 1, 250, 16, function(v) Settings.Speed.Value = v end, function(t) 
    Settings.Speed.Enabled = t
    if not t and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16 
    end
end, "Speed")

CreateSlider(Tab_Main_Page, "Fly Speed", "תעופה", 20, 300, 50, function(v) Settings.Fly.Speed = v end, function(t) ToggleFly(t) end, "Fly")
local BindCont = Instance.new("Frame", Tab_Main_Page); BindCont.Size = UDim2.new(0.96,0,0,60); BindCont.BackgroundTransparency = 1; CreateSquareBind(BindCont, 1, "FLY", "תעופה", Settings.Keys.Fly, function(k) Settings.Keys.Fly = k end); CreateSquareBind(BindCont, 2, "SPEED", "מהירות", Settings.Keys.Speed, function(k) Settings.Keys.Speed = k end)

CreateSlider(Tab_Settings_Page, "FOV", "שדה ראייה", 70, 120, 70, function(v) Camera.FieldOfView = v end)

CreateSlider(Tab_Settings_Page, "GUI Scale", "גודל ממשק", 5, 15, 10, function(v) 
    local scale = v / 10
    Library:Tween(MainScale, {Scale = scale}, 0.5, Enum.EasingStyle.Quart)
end)

local MenuBindCont = Instance.new("Frame", Tab_Settings_Page); MenuBindCont.Size = UDim2.new(0.96,0,0,50); MenuBindCont.BackgroundTransparency = 1; CreateSquareBind(MenuBindCont, 3, "MENU KEY", "מקש תפריט", Settings.Keys.Menu, function(k) Settings.Keys.Menu = k end)

--// REJOIN BUTTON (קטן יותר)
local RejoinBtn = Instance.new("TextButton", Tab_Settings_Page)
RejoinBtn.Size = UDim2.new(0.96, 0, 0, 35)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
RejoinBtn.Text = "Rejoin Server 🔄"
RejoinBtn.TextColor3 = Color3.new(1,1,1)
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.TextSize = 12
Library:Corner(RejoinBtn, 8)
Library:AddGlow(RejoinBtn, Color3.fromRGB(180, 50, 50))
RejoinBtn.MouseButton1Click:Connect(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

-- CREDITS UPDATED (פירמידה קטנה יותר)
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
    c.Size = size or UDim2.new(0.40, 0, 0, 100) -- כרטיס קטן יותר (היה 130)
    c.Position = pos or UDim2.new(0,0,0,0)
    c.BackgroundColor3 = Settings.Theme.Box
    c.ZIndex = 2
    Library:Corner(c, 10)
    Library:AddGlow(c, Settings.Theme.Gold)
    
    local imgCont = Instance.new("Frame", c)
    imgCont.Size = UDim2.new(0, 50, 0, 50) -- תמונה קטנה יותר
    imgCont.Position = UDim2.new(0.5, -25, 0.1, 0)
    imgCont.BackgroundColor3 = Color3.fromRGB(30,30,35)
    imgCont.ZIndex = 3
    Library:Corner(imgCont, 25)
    
    local img = Instance.new("ImageLabel", imgCont)
    img.Size = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://" .. decal 
    img.ZIndex = 4
    Library:Corner(img, 25)
    
    local tName = Instance.new("TextLabel", c)
    tName.Size = UDim2.new(1,0,0,15)
    tName.Position = UDim2.new(0,0,0.6,0)
    tName.BackgroundTransparency = 1
    tName.Text = name; tName.Font=Enum.Font.GothamBlack; tName.TextSize=12; tName.TextColor3 = Settings.Theme.Gold; tName.ZIndex=3
    
    local tRole = Instance.new("TextLabel", c)
    tRole.Size = UDim2.new(1,0,0,12)
    tRole.Position = UDim2.new(0,0,0.75,0)
    tRole.BackgroundTransparency = 1
    tRole.Text = role; tRole.TextColor3 = Settings.Theme.IceBlue; tRole.Font=Enum.Font.GothamBold; tRole.TextSize=10; tRole.ZIndex=3
    
    local btn = Instance.new("TextButton", c)
    btn.Size = UDim2.new(0, 80, 0, 20)
    btn.Position = UDim2.new(0.5, -40, 0.9, 0)
    btn.BackgroundColor3 = Settings.Theme.Discord
    btn.Text="Copy Discord"
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

-- יצירת הכרטיסים בפירמידה (מיקומים מותאמים לגודל החדש)
CreateCreditCard(Tab_Credits_Page, "Neho", "Founder", "nx3ho", "97462570733982", UDim2.new(0.04, 0, 0.05, 0)) 
CreateCreditCard(Tab_Credits_Page, "BadShot", "CoFounder", "8adshot3", "133430813410950", UDim2.new(0.56, 0, 0.05, 0))
CreateCreditCard(Tab_Credits_Page, "xyth", "Manager", "sc4rlxrd", "106705865211282", UDim2.new(0.30, 0, 0.45, 0)) 

-- תפאורה למטה
local SceneContainer = Instance.new("Frame", Tab_Credits_Page); SceneContainer.Size = UDim2.new(1, 0, 0.35, 0); SceneContainer.Position = UDim2.new(0, 0, 0.65, 0); SceneContainer.BackgroundTransparency = 1; SceneContainer.ZIndex=3
local Hill1 = Instance.new("Frame", SceneContainer); Hill1.Size = UDim2.new(0.6, 0, 1, 0); Hill1.Position = UDim2.new(-0.1, 0, 0.4, 0); Hill1.BackgroundColor3 = Color3.fromRGB(20, 25, 30); Hill1.BorderSizePixel=0; Library:Corner(Hill1, 80)
local Hill2 = Instance.new("Frame", SceneContainer); Hill2.Size = UDim2.new(0.7, 0, 1.2, 0); Hill2.Position = UDim2.new(0.4, 0, 0.5, 0); Hill2.BackgroundColor3 = Color3.fromRGB(25, 30, 35); Hill2.BorderSizePixel=0; Library:Corner(Hill2, 80)
local Snowman = Instance.new("TextLabel", SceneContainer); Snowman.Text = "⛄"; Snowman.Size = UDim2.new(0, 50, 0, 50); Snowman.Position = UDim2.new(0.1, 0, 0.45, 0); Snowman.BackgroundTransparency = 1; Snowman.TextSize = 40; Snowman.Rotation = -8; Snowman.ZIndex=4
local Tree1 = Instance.new("TextLabel", SceneContainer); Tree1.Text = "🌲"; Tree1.Size = UDim2.new(0, 60, 0, 60); Tree1.Position = UDim2.new(0.82, 0, 0.35, 0); Tree1.BackgroundTransparency = 1; Tree1.TextSize = 50; Tree1.ZIndex=4
local Tree2 = Instance.new("TextLabel", SceneContainer); Tree2.Text = "🌲"; Tree2.Size = UDim2.new(0, 50, 0, 50); Tree2.Position = UDim2.new(0.72, 0, 0.5, 0); Tree2.BackgroundTransparency = 1; Tree2.TextSize = 40; Tree2.ZIndex=4

--// 9. ניהול מקשים
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Menu then if MainFrame.Visible then Library:Tween(MainFrame, {Size = UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Back); task.wait(0.3); MainFrame.Visible = false else MainFrame.Visible = true; MainFrame.Size = UDim2.new(0, 500, 0, 340); Library:Tween(MainFrame, {Size = UDim2.new(0, 500, 0, 340)}, 0.5, Enum.EasingStyle.Elastic) end end
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
    if Settings.Speed.Enabled and LocalPlayer.Character then local h = LocalPlayer.Character:FindFirstChild("Humanoid"); if h then h.WalkSpeed = Settings.Speed.Value end end
end)

print("[SYSTEM] Spaghetti Mafia Hub v1 (MINI COMPACT) Loaded")
