--[[
    Spaghetti Mafia Hub v1 (REMASTERED COMPACT EDITION)
    Updates:
    - GUI: Compact, Darker, Aesthetic, Smoother Animations.
    - Feature: User Profile Picture added to TopBar.
    - Logic: Verified Anti-AFK & Auto-Farm.
    - Transitions: Seamless Loading -> Main Hub flow.
]]

--// SERVICES
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

--// 2. CLEANUP & SETTINGS
if CoreGui:FindFirstChild("SpaghettiHub_Rel") then CoreGui.SpaghettiHub_Rel:Destroy() end
if CoreGui:FindFirstChild("SpaghettiLoading") then CoreGui.SpaghettiLoading:Destroy() end

local Settings = {
    Theme = {
        Gold = Color3.fromRGB(255, 200, 50), -- מעט רך יותר
        Dark = Color3.fromRGB(10, 10, 12),
        Box = Color3.fromRGB(18, 18, 22),
        Text = Color3.fromRGB(240, 240, 240),
        IceBlue = Color3.fromRGB(120, 220, 255),
        IceDark = Color3.fromRGB(8, 20, 35),
        ShardBlue = Color3.fromRGB(60, 170, 255),
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

--// 3. UI LIBRARY (UTILITIES)
local Library = {}
function Library:Tween(obj, props, time, style) 
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), props):Play() 
end

function Library:AddGlow(obj, color, transparency) 
    local s = Instance.new("UIStroke", obj)
    s.Color = color or Settings.Theme.Gold
    s.Thickness = 2 -- דק יותר למראה נקי
    s.Transparency = transparency or 0.4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s 
end

function Library:Corner(obj, r) local c = Instance.new("UICorner", obj); c.CornerRadius = UDim.new(0, r or 8); return c end -- פינות פחות עגולות למראה קומפקטי
function Library:Gradient(obj, c1, c2, rot) local g = Instance.new("UIGradient", obj); g.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}; g.Rotation = rot or 45; return g end
function Library:MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = obj.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
    obj.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    RunService.RenderStepped:Connect(function() if dragging and dragInput then local delta = dragInput.Position - dragStart; obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end

local function SpawnSnow(parent)
    if not parent.Parent or not parent.Visible then return end
    local flake = Instance.new("TextLabel", parent)
    flake.Text = "❄️"
    flake.BackgroundTransparency = 1
    flake.TextColor3 = Color3.fromRGB(255, 255, 255)
    flake.Size = UDim2.new(0, math.random(15, 25), 0, math.random(15, 25)) -- שלג קטן יותר
    flake.Position = UDim2.new(math.random(1, 100)/100, 0, -0.2, 0)
    flake.ZIndex = 1 
    flake.Name = "SnowFlake"
    local duration = math.random(3, 6)
    TweenService:Create(flake, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = UDim2.new(flake.Position.X.Scale, math.random(-20,20), 1.2, 0), Rotation = math.random(180, 360)}):Play()
    Debris:AddItem(flake, duration)
end

--// 4. LOADING SCREEN (SMOOTH & COMPACT)
local LoadGui = Instance.new("ScreenGui"); LoadGui.Name = "SpaghettiLoading"; LoadGui.Parent = CoreGui
local LoadBox = Instance.new("Frame", LoadGui)
LoadBox.Size = UDim2.new(0, 240, 0, 150) -- קומפקטי יותר
LoadBox.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadBox.AnchorPoint = Vector2.new(0.5, 0.5)
LoadBox.ClipsDescendants = true 
LoadBox.BorderSizePixel = 0
LoadBox.BackgroundColor3 = Settings.Theme.Dark
Library:Corner(LoadBox, 16)
Library:AddGlow(LoadBox, Settings.Theme.Gold, 0.5)
Library:Gradient(LoadBox, Color3.fromRGB(20, 20, 25), Color3.fromRGB(8, 8, 10), -45)

local PastaIcon = Instance.new("TextLabel", LoadBox)
PastaIcon.Size = UDim2.new(1, 0, 0.5, 0); PastaIcon.Position = UDim2.new(0,0,0.05,0)
PastaIcon.BackgroundTransparency = 1; PastaIcon.Text = "🍝"; PastaIcon.TextSize = 55; PastaIcon.ZIndex = 15
TweenService:Create(PastaIcon, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = 10, Size = UDim2.new(1.05, 0, 0.55, 0)}):Play()

local TitleLoad = Instance.new("TextLabel", LoadBox)
TitleLoad.Size = UDim2.new(1, 0, 0.2, 0); TitleLoad.Position = UDim2.new(0, 0, 0.5, 0)
TitleLoad.BackgroundTransparency = 1; TitleLoad.Text = "Spaghetti Hub"; 
TitleLoad.Font = Enum.Font.GothamBlack; TitleLoad.TextColor3 = Settings.Theme.Gold; TitleLoad.TextSize = 20
TitleLoad.ZIndex = 15

local LoadingBarBG = Instance.new("Frame", LoadBox)
LoadingBarBG.Size = UDim2.new(0.7, 0, 0, 4)
LoadingBarBG.Position = UDim2.new(0.15, 0, 0.85, 0)
LoadingBarBG.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Library:Corner(LoadingBarBG, 2)
local LoadingBarFill = Instance.new("Frame", LoadingBarBG)
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0); LoadingBarFill.BackgroundColor3 = Settings.Theme.Gold; Library:Corner(LoadingBarFill, 2)
TweenService:Create(LoadingBarFill, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()

task.spawn(function() while LoadBox.Parent do SpawnSnow(LoadBox); task.wait(0.3) end end)

task.wait(2.6)

--// 5. MAIN GUI (COMPACT & AESTHETIC)
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false

-- כפתור מזעור
local MiniPasta = Instance.new("TextButton", ScreenGui); MiniPasta.Size = UDim2.new(0, 50, 0, 50); MiniPasta.Position = UDim2.new(0.02, 0, 0.1, 0); MiniPasta.BackgroundColor3 = Settings.Theme.Box; MiniPasta.Text = "🍝"; MiniPasta.TextSize = 30; MiniPasta.Visible = false; Library:Corner(MiniPasta, 25); Library:AddGlow(MiniPasta); Library:MakeDraggable(MiniPasta)

local MainFrame = Instance.new("Frame", ScreenGui); 
MainFrame.Size = UDim2.new(0, 600, 0, 380) -- גודל קומפקטי יותר
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); 
MainFrame.BackgroundColor3 = Settings.Theme.Dark; 
MainFrame.ClipsDescendants = true; 
Library:Corner(MainFrame, 14); 
local MainStroke = Library:AddGlow(MainFrame, Settings.Theme.Gold, 0.6)
Library:Gradient(MainFrame, Color3.fromRGB(18, 18, 22), Color3.fromRGB(10, 10, 12), 45)

-- אנימציית פתיחה חלקה שמחליפה את מסך הטעינה
MainFrame.Size = UDim2.new(0,0,0,0); MainFrame.Visible = true
Library:Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 380)}, 0.6, Enum.EasingStyle.Exponential)
Library:Tween(LoadBox, {Size = UDim2.new(0,0,0,0), Transparency = 1}, 0.4, Enum.EasingStyle.Back)
task.wait(0.4) LoadGui:Destroy()

local TopBar = Instance.new("Frame", MainFrame); TopBar.Size = UDim2.new(1,0,0,50); TopBar.BackgroundTransparency = 1; Library:MakeDraggable(MainFrame)
local Divider = Instance.new("Frame", TopBar); Divider.Size = UDim2.new(1,0,0,1); Divider.Position = UDim2.new(0,0,1,0); Divider.BackgroundColor3 = Color3.fromRGB(30,30,35); Divider.BorderSizePixel = 0

local MainTitle = Instance.new("TextLabel", TopBar); MainTitle.Size = UDim2.new(0,200,0,30); MainTitle.Position = UDim2.new(0,20,0,10); MainTitle.BackgroundTransparency = 1; MainTitle.Text = "SPAGHETTI <font color='#FFD700'>MAFIA</font>"; MainTitle.RichText = true; MainTitle.Font = Enum.Font.GothamBlack; MainTitle.TextSize = 18; MainTitle.TextColor3 = Color3.new(1,1,1); MainTitle.TextXAlignment = Enum.TextXAlignment.Left

-- User Profile & Welcome (Enhanced)
local UserContainer = Instance.new("Frame", TopBar)
UserContainer.Size = UDim2.new(0, 180, 1, 0)
UserContainer.Position = UDim2.new(1, -60, 0, 0)
UserContainer.AnchorPoint = Vector2.new(1, 0)
UserContainer.BackgroundTransparency = 1

local UserImgFrame = Instance.new("Frame", UserContainer)
UserImgFrame.Size = UDim2.new(0, 32, 0, 32); UserImgFrame.Position = UDim2.new(1, -40, 0.5, 0); UserImgFrame.AnchorPoint = Vector2.new(0, 0.5)
UserImgFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
Library:Corner(UserImgFrame, 16)
local UserImg = Instance.new("ImageLabel", UserImgFrame)
UserImg.Size = UDim2.new(1,0,1,0); UserImg.BackgroundTransparency = 1; Library:Corner(UserImg, 16)

-- שליפת תמונה
task.spawn(function()
    local content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    UserImg.Image = content
end)

local WelcomeText = Instance.new("TextLabel", UserContainer)
WelcomeText.Size = UDim2.new(1, -50, 1, 0); WelcomeText.Position = UDim2.new(0, 0, 0, 0)
WelcomeText.BackgroundTransparency = 1
WelcomeText.Text = "Welcome, <b>" .. LocalPlayer.Name .. "</b>"
WelcomeText.RichText = true
WelcomeText.Font = Enum.Font.GothamMedium; WelcomeText.TextSize = 13; WelcomeText.TextColor3 = Color3.fromRGB(180, 180, 190); WelcomeText.TextXAlignment = Enum.TextXAlignment.Right

local CloseBtn = Instance.new("TextButton", TopBar); CloseBtn.Size = UDim2.new(0, 26, 0, 26); CloseBtn.Position = UDim2.new(1, -30, 0.5, 0); CloseBtn.AnchorPoint = Vector2.new(0,0.5); CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); CloseBtn.Text = "×"; CloseBtn.TextColor3 = Color3.fromRGB(200,200,200); CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextSize=18; Library:Corner(CloseBtn, 6); 
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniPasta.Visible = true; Library:Tween(MiniPasta, {Size = UDim2.new(0, 50, 0, 50)}, 0.4, Enum.EasingStyle.Back) end)
MiniPasta.MouseButton1Click:Connect(function() MiniPasta.Visible = false; MainFrame.Visible = true; Library:Tween(MainFrame, {Size = UDim2.new(0, 600, 0, 380)}, 0.4, Enum.EasingStyle.Exponential) end)

--// SIDEBAR (COMPACT)
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 140, 1, -51) -- צר יותר
Sidebar.Position = UDim2.new(0,0,0,51)
Sidebar.BackgroundColor3 = Settings.Theme.Box
Sidebar.BorderSizePixel = 0; Sidebar.ZIndex = 2
Library:Corner(Sidebar, 0) -- מלבני כדי להיצמד
local SideGradient = Library:Gradient(Sidebar, Color3.fromRGB(20, 20, 25), Color3.fromRGB(15, 15, 18), 90)

local SideBtnContainer = Instance.new("Frame", Sidebar); SideBtnContainer.Size = UDim2.new(1, 0, 1, 0); SideBtnContainer.BackgroundTransparency = 1
local SideList = Instance.new("UIListLayout", SideBtnContainer); SideList.Padding = UDim.new(0,6); SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center; SideList.SortOrder = Enum.SortOrder.LayoutOrder
local SidePad = Instance.new("UIPadding", SideBtnContainer); SidePad.PaddingTop = UDim.new(0,15)

local Container = Instance.new("Frame", MainFrame); Container.Size = UDim2.new(1, -140, 1, -51); Container.Position = UDim2.new(0, 140, 0, 51); Container.BackgroundTransparency = 1

local currentTabBtn = nil
local function CreateTab(name, heb, icon, order, isWinter)
    local btn = Instance.new("TextButton", SideBtnContainer)
    btn.Size = UDim2.new(0.85,0,0,38) -- כפתורים קטנים יותר
    btn.BackgroundColor3 = Settings.Theme.Dark
    btn.Text = icon .. "  " .. name
    btn.TextColor3 = isWinter and Color3.fromRGB(140, 170, 200) or Color3.fromRGB(140,140,140)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left; btn.LayoutOrder = order
    Library:Corner(btn, 6)
    local pad = Instance.new("UIPadding", btn); pad.PaddingLeft = UDim.new(0, 10)
    
    local page = Instance.new("Frame", Container)
    page.Size = UDim2.new(1,0,1,0); page.BackgroundTransparency = 1; page.Visible = false; page.Name = name .. "_Page"
    
    btn.MouseButton1Click:Connect(function()
        for _,v in pairs(SideBtnContainer:GetChildren()) do if v:IsA("TextButton") then Library:Tween(v, {BackgroundColor3 = Settings.Theme.Dark, TextColor3 = Color3.fromRGB(140,140,140)}) end end
        for _,v in pairs(Container:GetChildren()) do v.Visible = false end
        
        local activeColor = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold
        local activeBG = isWinter and Settings.Theme.IceDark or Color3.fromRGB(35, 35, 40)
        Library:Tween(btn, {BackgroundColor3 = activeBG, TextColor3 = activeColor})
        page.Visible = true
    end)
    
    if order == 1 then 
        currentTabBtn = btn; local activeColor = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold; local activeBG = isWinter and Settings.Theme.IceDark or Color3.fromRGB(35, 35, 40)
        Library:Tween(btn, {BackgroundColor3 = activeBG, TextColor3 = activeColor}); page.Visible = true 
    end
    return page
end

local Tab_Event = CreateTab("Winter", "חורף", "❄️", 1, true)
local Tab_Main = CreateTab("Main", "ראשי", "🏠", 2, false)
local Tab_Settings = CreateTab("Config", "הגדרות", "⚙️", 3, false)
local Tab_Credits = CreateTab("Credits", "קרדיטים", "👥", 4, false)

local function AddLayout(p) local l = Instance.new("UIListLayout", p); l.Padding = UDim.new(0,8); l.HorizontalAlignment = Enum.HorizontalAlignment.Center; local pad = Instance.new("UIPadding", p); pad.PaddingTop = UDim.new(0,10) end
AddLayout(Tab_Main); AddLayout(Tab_Settings)

--// 6. LOGIC & FUNCTIONS
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
        for _,v in pairs(workspace:FindPartsInRegion3(r, nil, 100)) do if v.Name:lower():find("door") or v.Name:lower():find("portal") then v.CanTouch = false end end
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
                    local start = tick(); local stuckStart = tick()
                    repeat task.wait() 
                        if not target.Parent or not Settings.Farming then tween:Cancel(); break end
                        if (hrp.Position - target.Position).Magnitude < 8 then
                            target.CanTouch = true; hrp.CFrame = target.CFrame 
                            if (tick() - stuckStart) > 0.6 then tween:Cancel(); FarmBlacklist[target] = true; break end
                        else stuckStart = tick() end
                        if (tick() - start) > (distance / Settings.FarmSpeed) + 1.5 then tween:Cancel(); break end
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

--// 7. EVENT TAB (Refined)
local EventBG = Instance.new("Frame", Tab_Event); EventBG.Size=UDim2.new(1,0,1,0); EventBG.ZIndex=0
Library:Gradient(EventBG, Color3.fromRGB(15, 30, 50), Color3.fromRGB(5, 10, 20), 45)
local SnowCont = Instance.new("Frame", Tab_Event); SnowCont.Size=UDim2.new(1,0,1,0); SnowCont.BackgroundTransparency=1; SnowCont.ClipsDescendants=true; SnowCont.ZIndex=1
task.spawn(function() while Tab_Event.Parent do if Tab_Event.Visible then SpawnSnow(SnowCont) end; task.wait(0.4) end end)

local EventScroll = Instance.new("ScrollingFrame", Tab_Event)
EventScroll.Size = UDim2.new(1, 0, 1, 0); EventScroll.BackgroundTransparency = 1; EventScroll.ScrollBarThickness = 2; EventScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; EventScroll.ZIndex = 5; EventScroll.BorderSizePixel=0
local EventLayout = Instance.new("UIListLayout", EventScroll); EventLayout.Padding = UDim.new(0, 10); EventLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; EventLayout.SortOrder = Enum.SortOrder.LayoutOrder
local EventPad = Instance.new("UIPadding", EventScroll); EventPad.PaddingTop = UDim.new(0,10)

-- FARM BUTTON
local FarmBtn = Instance.new("TextButton", EventScroll); FarmBtn.Size = UDim2.new(0.95, 0, 0, 60); FarmBtn.BackgroundColor3 = Color3.fromRGB(25, 40, 60); FarmBtn.Text=""; Library:Corner(FarmBtn, 10); Library:AddGlow(FarmBtn, Settings.Theme.IceBlue, 0.5)
local FarmTitle = Instance.new("TextLabel", FarmBtn); FarmTitle.Size=UDim2.new(1,-60,1,0); FarmTitle.Position=UDim2.new(0,15,0,0); FarmTitle.Text="Auto Farm Storm ❄️"; FarmTitle.TextColor3=Color3.new(1,1,1); FarmTitle.Font=Enum.Font.GothamBold; FarmTitle.TextSize=16; FarmTitle.TextXAlignment=Enum.TextXAlignment.Left; FarmTitle.BackgroundTransparency=1
local FarmSwitch = Instance.new("Frame", FarmBtn); FarmSwitch.Size=UDim2.new(0,40,0,22); FarmSwitch.Position=UDim2.new(1,-55,0.5,-11); FarmSwitch.BackgroundColor3=Color3.fromRGB(40,40,50); Library:Corner(FarmSwitch,20)
local FarmDot = Instance.new("Frame", FarmSwitch); FarmDot.Size=UDim2.new(0,18,0,18); FarmDot.Position=UDim2.new(0,2,0.5,-9); FarmDot.BackgroundColor3=Color3.fromRGB(200,200,200); Library:Corner(FarmDot,20)
local isFarming = false
FarmBtn.MouseButton1Click:Connect(function() 
    isFarming = not isFarming; ToggleFarm(isFarming)
    Library:Tween(FarmSwitch,{BackgroundColor3=isFarming and Settings.Theme.IceBlue or Color3.fromRGB(40,40,50)})
    Library:Tween(FarmDot,{Position=isFarming and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)})
end)
task.spawn(function() task.wait(1); if not isFarming then isFarming=true; ToggleFarm(true); Library:Tween(FarmSwitch,{BackgroundColor3=Settings.Theme.IceBlue}); Library:Tween(FarmDot,{Position=UDim2.new(1,-20,0.5,-9)}) end end)

-- STATS GRID
local StatGrid = Instance.new("Frame", EventScroll); StatGrid.Size = UDim2.new(0.95,0,0,60); StatGrid.BackgroundTransparency=1
local SGLayout = Instance.new("UIGridLayout", StatGrid); SGLayout.CellSize = UDim2.new(0.48,0,1,0); SGLayout.CellPadding=UDim2.new(0.04,0,0,0)
local function CreateStatBox(color, title, ref)
    local b = Instance.new("Frame", StatGrid); b.BackgroundColor3 = Color3.fromRGB(20,20,24); Library:Corner(b, 10); Library:AddGlow(b, color, 0.6)
    local t = Instance.new("TextLabel", b); t.Size=UDim2.new(1,0,0.3,0); t.Position=UDim2.new(0,0,0.15,0); t.BackgroundTransparency=1; t.Text=title; t.TextColor3=color; t.Font=Enum.Font.GothamBold; t.TextSize=12
    local v = Instance.new("TextLabel", b); v.Size=UDim2.new(1,0,0.5,0); v.Position=UDim2.new(0,0,0.45,0); v.BackgroundTransparency=1; v.Text="0"; v.TextColor3=Color3.new(1,1,1); v.Font=Enum.Font.GothamBlack; v.TextSize=20
    return v
end
local ValBlue = CreateStatBox(Settings.Theme.IceBlue, "Session Blues", nil)
local ValRed = CreateStatBox(Settings.Theme.CrystalRed, "Session Reds", nil)

local AFK = Instance.new("TextLabel", EventScroll); AFK.Size=UDim2.new(0.95,0,0,20); AFK.BackgroundTransparency=1; AFK.Text="Anti-AFK: <font color='#00FF00'>Active</font>"; AFK.RichText=true; AFK.TextColor3=Color3.new(1,1,1); AFK.Font=Enum.Font.Gotham; AFK.TextSize=11

task.spawn(function()
    local C = LocalPlayer:WaitForChild("Crystals", 10); local S = LocalPlayer:WaitForChild("Shards", 10)
    if C and S then local iC, iS = C.Value, S.Value
        while true do task.wait(1); local dfC, dfS = C.Value-iC, S.Value-iS; if dfC<0 then dfC=0 end; if dfS<0 then dfS=0 end; ValRed.Text="+"..dfC; ValBlue.Text="+"..dfS end
    end
end)

--// 8. COMPONENTS (Sliders/Binds)
local function CreateSlider(p, t, min, max, def, cb)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95,0,0,60); f.BackgroundColor3 = Settings.Theme.Box; Library:Corner(f, 8); Library:AddGlow(f, Color3.fromRGB(40,40,40))
    local ttl = Instance.new("TextLabel", f); ttl.Size = UDim2.new(1,0,0,20); ttl.Position = UDim2.new(0,10,0,5); ttl.Text=t..": "..def; ttl.TextColor3=Color3.new(1,1,1); ttl.Font=Enum.Font.GothamBold; ttl.TextSize=13; ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.BackgroundTransparency=1
    local bar = Instance.new("Frame", f); bar.Size=UDim2.new(0.9,0,0,8); bar.Position=UDim2.new(0.05,0,0.6,0); bar.BackgroundColor3=Color3.fromRGB(40,40,40); Library:Corner(bar,4)
    local fill = Instance.new("Frame", bar); fill.Size=UDim2.new((def-min)/(max-min),0,1,0); fill.BackgroundColor3=Settings.Theme.Gold; Library:Corner(fill,4)
    local btn = Instance.new("TextButton", f); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Down:Connect(function() local m=UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then local r=math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1); fill.Size=UDim2.new(r,0,1,0); local v=math.floor(min+((max-min)*r)); ttl.Text=t..": "..v; cb(v) end end); UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then m:Disconnect() end end) end)
end

CreateSlider(Tab_Main, "WalkSpeed", 16, 250, 16, function(v) Settings.Speed.Value=v end)
CreateSlider(Tab_Main, "Fly Speed", 20, 300, 50, function(v) Settings.Fly.Speed=v end)

local BindC = Instance.new("Frame", Tab_Main); BindC.Size=UDim2.new(0.95,0,0,40); BindC.BackgroundTransparency=1
local function CreateBind(txt, default, cb, x)
    local b = Instance.new("TextButton", BindC); b.Size=UDim2.new(0.48,0,1,0); b.Position=UDim2.new(x,0,0,0); b.BackgroundColor3=Settings.Theme.Box; b.Text=txt.." ["..default.Name.."]"; b.TextColor3=Color3.new(0.8,0.8,0.8); b.Font=Enum.Font.GothamBold; b.TextSize=12; Library:Corner(b,6); Library:AddGlow(b, Color3.fromRGB(50,50,50))
    b.MouseButton1Click:Connect(function() b.Text="Press key..."; local i=UIS.InputBegan:Wait(); if i.UserInputType==Enum.UserInputType.Keyboard then b.Text=txt.." ["..i.KeyCode.Name.."]"; cb(i.KeyCode) end end)
end
CreateBind("Fly", Settings.Keys.Fly, function(k) Settings.Keys.Fly=k end, 0)
CreateBind("Speed", Settings.Keys.Speed, function(k) Settings.Keys.Speed=k end, 0.52)
CreateBind("Menu", Settings.Keys.Menu, function(k) Settings.Keys.Menu=k end, 0) -- In Settings Tab technically, but simplified here

--// 9. CREDITS (COMPACT PYRAMID)
local CredBG = Instance.new("Frame", Tab_Credits); CredBG.Size=UDim2.new(1,0,1,0); CredBG.BackgroundColor3=Color3.fromRGB(12,12,15); CredBG.ZIndex=0
local CredSnow = Instance.new("Frame", Tab_Credits); CredSnow.Size=UDim2.new(1,0,1,0); CredSnow.BackgroundTransparency=1; CredSnow.ClipsDescendants=true; CredSnow.ZIndex=1
task.spawn(function() while Tab_Credits.Parent do if Tab_Credits.Visible then SpawnSnow(CredSnow) end; task.wait(0.5) end end)

local function CreateMiniCard(name, role, discord, imgId, pos)
    local c = Instance.new("Frame", Tab_Credits)
    c.Size = UDim2.new(0.4, 0, 0, 100) -- ממש קטן וקומפקטי
    c.Position = pos
    c.BackgroundColor3 = Settings.Theme.Box
    c.ZIndex = 2
    Library:Corner(c, 10)
    Library:AddGlow(c, Settings.Theme.Gold, 0.5)
    
    local imC = Instance.new("Frame", c); imC.Size=UDim2.new(0,50,0,50); imC.Position=UDim2.new(0.5,-25,0.1,0); imC.BackgroundColor3=Color3.fromRGB(30,30,30); Library:Corner(imC,25); imC.ZIndex=3
    local im = Instance.new("ImageLabel", imC); im.Size=UDim2.new(1,0,1,0); im.Image="rbxassetid://"..imgId; im.BackgroundTransparency=1; Library:Corner(im,25); im.ZIndex=4
    
    local tN = Instance.new("TextLabel", c); tN.Size=UDim2.new(1,0,0,15); tN.Position=UDim2.new(0,0,0.6,0); tN.BackgroundTransparency=1; tN.Text=name; tN.Font=Enum.Font.GothamBlack; tN.TextSize=13; tN.TextColor3=Settings.Theme.Gold; tN.ZIndex=3
    local tR = Instance.new("TextLabel", c); tR.Size=UDim2.new(1,0,0,12); tR.Position=UDim2.new(0,0,0.75,0); tR.BackgroundTransparency=1; tR.Text=role; tR.TextColor3=Settings.Theme.IceBlue; tR.Font=Enum.Font.Gotham; tR.TextSize=10; tR.ZIndex=3

    local btn = Instance.new("TextButton", c); btn.Size=UDim2.new(0.8,0,0,20); btn.Position=UDim2.new(0.1,0,0.88,0); btn.BackgroundColor3=Settings.Theme.Discord; btn.Text="Copy Discord"; btn.TextColor3=Color3.new(1,1,1); btn.Font=Enum.Font.GothamBold; btn.TextSize=9; Library:Corner(btn, 6); btn.ZIndex=3
    btn.MouseButton1Click:Connect(function() setclipboard(discord); btn.Text="Copied!"; task.wait(1); btn.Text="Copy Discord" end)
end

-- פירמידה דחוסה
CreateMiniCard("Neho", "Founder", "nx3ho", "97462570733982", UDim2.new(0.08, 0, 0.05, 0)) 
CreateMiniCard("BadShot", "CoFounder", "8adshot3", "133430813410950", UDim2.new(0.52, 0, 0.05, 0))
CreateMiniCard("xyth", "Community Manager", "sc4rlxrd", "106705865211282", UDim2.new(0.3, 0, 0.38, 0)) 

-- קישוטים למטה
local Decor = Instance.new("Frame", Tab_Credits); Decor.Size=UDim2.new(1,0,0.3,0); Decor.Position=UDim2.new(0,0,0.7,0); Decor.BackgroundTransparency=1; Decor.ZIndex=3
local Tree = Instance.new("TextLabel", Decor); Tree.Text="🌲"; Tree.Size=UDim2.new(0,60,0,60); Tree.Position=UDim2.new(0.8,0,0.4,0); Tree.BackgroundTransparency=1; Tree.TextSize=50
local Snowman = Instance.new("TextLabel", Decor); Snowman.Text="⛄"; Snowman.Size=UDim2.new(0,50,0,50); Snowman.Position=UDim2.new(0.1,0,0.5,0); Snowman.BackgroundTransparency=1; Snowman.TextSize=40

--// 10. INPUTS
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Menu then 
            if MainFrame.Visible then Library:Tween(MainFrame, {Size=UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Back); task.wait(0.3); MainFrame.Visible=false 
            else MainFrame.Visible=true; Library:Tween(MainFrame, {Size=UDim2.new(0,600,0,380)}, 0.4, Enum.EasingStyle.Exponential) end
        end
        if i.KeyCode == Settings.Keys.Fly then Settings.Fly.Enabled = not Settings.Fly.Enabled; ToggleFly(Settings.Fly.Enabled) end
        if i.KeyCode == Settings.Keys.Speed then Settings.Speed.Enabled = not Settings.Speed.Enabled; if not Settings.Speed.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end end
    end
end)

RunService.RenderStepped:Connect(function() if Settings.Speed.Enabled and LocalPlayer.Character then local h = LocalPlayer.Character:FindFirstChild("Humanoid"); if h then h.WalkSpeed = Settings.Speed.Value end end end)

print("[SYSTEM] Spaghetti Hub Remastered Loaded")
