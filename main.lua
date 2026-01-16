--[[
    Spaghetti Mafia Hub v1 (ULTIMATE FINAL - STABLE + WATER FIX)
    Updates:
    - PROFILE: Hebrew "ברוך הבא", Thick Gold Border, Large Avatar.
    - MAIN TAB: Premium Design (Thick Strokes, Dark Backgrounds).
    - LOGIC: Stable Auto-Farm (No crashes) merged with Water/Oxygen Fix.
    - FLY: Space/Ctrl controls added.
    - FULL CODE: Nothing removed.
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
        Gold = Color3.fromRGB(255, 200, 50), -- זהב עשיר
        Dark = Color3.fromRGB(12, 12, 14),
        Box = Color3.fromRGB(20, 20, 24),
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
    s.Thickness = 3.5 
    s.Transparency = 0.3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    task.spawn(function()
        while obj.Parent do
            TweenService:Create(s, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.6}):Play()
            task.wait(1.5)
            TweenService:Create(s, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.2}):Play()
            task.wait(1.5)
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

--// שלג
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

--// GUI ראשי
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
Library:AddGlow(MainFrame, Settings.Theme.Gold)

MainFrame.Size = UDim2.new(0,0,0,0); Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.6, Enum.EasingStyle.Quart) 

local MainScale = Instance.new("UIScale", MainFrame); MainScale.Scale = 1
local TopBar = Instance.new("Frame", MainFrame); TopBar.Size = UDim2.new(1,0,0,60); TopBar.BackgroundTransparency = 1; TopBar.BorderSizePixel = 0; Library:MakeDraggable(MainFrame)

local MainTitle = Instance.new("TextLabel", TopBar); MainTitle.Size = UDim2.new(0,300,0,30); MainTitle.Position = UDim2.new(0,25,0,10); MainTitle.BackgroundTransparency = 1; MainTitle.Text = "SPAGHETTI <font color='#FFD700'>MAFIA</font> HUB v1"; MainTitle.RichText = true; MainTitle.Font = Enum.Font.GothamBlack; MainTitle.TextSize = 22; MainTitle.TextColor3 = Color3.new(1,1,1); MainTitle.TextXAlignment = Enum.TextXAlignment.Left

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

-- ======================================================================================
--                        הטיימר המעוצב
-- ======================================================================================
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
        
        local TimerGradient = Instance.new("UIGradient", TimerWidget)
        TimerGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
        }
        TimerGradient.Rotation = 90

        local TimerStroke = Instance.new("UIStroke", TimerWidget)
        TimerStroke.Color = Settings.Theme.IceBlue
        TimerStroke.Thickness = 1.5
        TimerStroke.Transparency = 0.5
        TimerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local T_Header = Instance.new("TextLabel", TimerWidget)
        T_Header.Size = UDim2.new(1, 0, 0.35, 0)
        T_Header.Position = UDim2.new(0, 0, 0.1, 0)
        T_Header.BackgroundTransparency = 1
        T_Header.Text = "סופה הבאה:"
        T_Header.TextColor3 = Color3.fromRGB(180, 200, 220)
        T_Header.Font = Enum.Font.GothamBold
        T_Header.TextSize = 10
        T_Header.ZIndex = 2

        local T_Time = Instance.new("TextLabel", TimerWidget)
        T_Time.Size = UDim2.new(1, 0, 0.55, 0)
        T_Time.Position = UDim2.new(0, 0, 0.4, 0)
        T_Time.BackgroundTransparency = 1
        T_Time.Text = "00:00"
        T_Time.TextColor3 = Color3.fromRGB(255, 255, 255)
        T_Time.Font = Enum.Font.GothamBlack
        T_Time.TextSize = 18
        T_Time.ZIndex = 2

        local function UpdateStormTimer(val)
            local mins = math.floor(val / 60)
            local secs = val % 60
            
            if val <= 0 then
                T_Header.Text = "⚠️ סטטוס ⚠️"
                T_Header.TextColor3 = Color3.fromRGB(255, 100, 100)
                T_Time.Text = "סופה פעילה!"
                T_Time.TextSize = 13 
                T_Time.TextColor3 = Settings.Theme.CrystalRed
                TweenService:Create(TimerStroke, TweenInfo.new(0.5), {Color = Color3.fromRGB(255, 0, 0), Transparency = 0}):Play()
                TweenService:Create(TimerWidget, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(40, 10, 10)}):Play()
            elseif val <= 30 then
                T_Header.Text = "מתקרב..."
                T_Header.TextColor3 = Color3.fromRGB(255, 200, 100)
                T_Time.Text = string.format("%02d:%02d", mins, secs)
                T_Time.TextSize = 18
                T_Time.TextColor3 = Settings.Theme.Gold
                TweenService:Create(TimerStroke, TweenInfo.new(0.5), {Color = Settings.Theme.Gold, Transparency = 0.2}):Play()
            else
                T_Header.Text = "סופה הבאה:"
                T_Header.TextColor3 = Color3.fromRGB(150, 180, 200)
                T_Time.Text = string.format("%02d:%02d", mins, secs)
                T_Time.TextSize = 18
                T_Time.TextColor3 = Color3.fromRGB(255, 255, 255)
                TweenService:Create(TimerStroke, TweenInfo.new(0.5), {Color = Settings.Theme.IceBlue, Transparency = 0.6}):Play()
                TweenService:Create(TimerWidget, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(18, 18, 24)}):Play()
            end
        end

        StormValue.Changed:Connect(UpdateStormTimer)
        UpdateStormTimer(StormValue.Value)
    end
end)
-- ======================================================================================


--// Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 150, 1, -65)
Sidebar.Position = UDim2.new(0,0,0,65)
Sidebar.BackgroundColor3 = Settings.Theme.Box
Sidebar.BorderSizePixel = 0 
Sidebar.ZIndex = 2
Library:Corner(Sidebar, 12)

-- ======================================================================================
--                        פרופיל משתמש - עיצוב זהב עברית (ברוך הבא)
-- ======================================================================================
local UserProfile = Instance.new("Frame", Sidebar)
UserProfile.Name = "UserProfileContainer"
UserProfile.Size = UDim2.new(0.92, 0, 0, 75)
UserProfile.AnchorPoint = Vector2.new(0.5, 1)
UserProfile.Position = UDim2.new(0.5, 0, 0.98, 0)
UserProfile.BackgroundColor3 = Color3.fromRGB(20, 20, 25) -- כהה יותר
UserProfile.BorderSizePixel = 0
UserProfile.ZIndex = 10
Library:Corner(UserProfile, 12)

-- מסגרת זהב עבה מסביב להכל
local ProfileStroke = Instance.new("UIStroke", UserProfile)
ProfileStroke.Color = Settings.Theme.Gold
ProfileStroke.Thickness = 2.5
ProfileStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- תמונת פרופיל מוגדלת
local AvatarFrame = Instance.new("Frame", UserProfile)
AvatarFrame.Size = UDim2.new(0, 55, 0, 55)
AvatarFrame.Position = UDim2.new(0, 10, 0.5, 0)
AvatarFrame.AnchorPoint = Vector2.new(0, 0.5)
AvatarFrame.BackgroundColor3 = Settings.Theme.Gold
AvatarFrame.BorderSizePixel = 0
AvatarFrame.ZIndex = 11
local AvatarCorner = Instance.new("UICorner", AvatarFrame); AvatarCorner.CornerRadius = UDim.new(1, 0)

-- זוהר סביב התמונה
local AvatarGlow = Instance.new("UIStroke", AvatarFrame)
AvatarGlow.Color = Settings.Theme.Gold
AvatarGlow.Thickness = 2
AvatarGlow.Transparency = 0.5
AvatarGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local AvatarImg = Instance.new("ImageLabel", AvatarFrame)
AvatarImg.Size = UDim2.new(0.9, 0, 0.9, 0)
AvatarImg.Position = UDim2.new(0.5, 0, 0.5, 0)
AvatarImg.AnchorPoint = Vector2.new(0.5, 0.5)
AvatarImg.BackgroundTransparency = 1
AvatarImg.Image = ""
AvatarImg.ZIndex = 12
local AvatarImgCorner = Instance.new("UICorner", AvatarImg); AvatarImgCorner.CornerRadius = UDim.new(1, 0)

-- טקסט ברוך הבא (בעברית)
local WelcomeText = Instance.new("TextLabel", UserProfile)
WelcomeText.Text = "ברוך הבא," -- עברית
WelcomeText.Size = UDim2.new(0, 80, 0, 15)
WelcomeText.Position = UDim2.new(0, 75, 0, 18)
WelcomeText.BackgroundTransparency = 1
WelcomeText.TextColor3 = Color3.fromRGB(255, 255, 255)
WelcomeText.Font = Enum.Font.GothamBold -- פונט מודגש
WelcomeText.TextSize = 14
WelcomeText.TextXAlignment = Enum.TextXAlignment.Left
WelcomeText.ZIndex = 11

-- שם המשתמש
local UsernameText = Instance.new("TextLabel", UserProfile)
UsernameText.Text = LocalPlayer.Name
UsernameText.Size = UDim2.new(0, 90, 0, 20)
UsernameText.Position = UDim2.new(0, 75, 0, 36)
UsernameText.BackgroundTransparency = 1
UsernameText.TextColor3 = Settings.Theme.Gold
UsernameText.Font = Enum.Font.GothamBlack -- פונט עבה
UsernameText.TextSize = 16
UsernameText.TextXAlignment = Enum.TextXAlignment.Left
UsernameText.TextTruncate = Enum.TextTruncate.AtEnd
UsernameText.ZIndex = 11

task.spawn(function()
    local content = "rbxassetid://0"
    pcall(function()
        content = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    AvatarImg.Image = content
end)
-- ======================================================================================

local SideBtnContainer = Instance.new("Frame", Sidebar)
SideBtnContainer.Size = UDim2.new(1, 0, 1, -85) 
SideBtnContainer.BackgroundTransparency = 1

local SideList = Instance.new("UIListLayout", SideBtnContainer); SideList.Padding = UDim.new(0,8); SideList.HorizontalAlignment = Enum.HorizontalAlignment.Center; SideList.SortOrder = Enum.SortOrder.LayoutOrder
local SidePad = Instance.new("UIPadding", SideBtnContainer); SidePad.PaddingTop = UDim.new(0,15)

local Container = Instance.new("Frame", MainFrame); Container.Size = UDim2.new(1, -160, 1, -70); Container.Position = UDim2.new(0, 160, 0, 65); Container.BackgroundTransparency = 1

local currentTab = nil

-- פונקציית יצירת טאב
local function CreateTab(name, heb, order, isWinter)
    local btn = Instance.new("TextButton", SideBtnContainer)
    btn.Size = UDim2.new(0.9,0,0,40)
    btn.BackgroundColor3 = Settings.Theme.Dark
    btn.Text = "   " .. name .. "\n   <font size='11' color='#8899AA'>"..heb.."</font>"
    btn.RichText = true
    btn.TextColor3 = isWinter and Color3.fromRGB(150, 180, 200) or Color3.fromRGB(150,150,150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 3
    btn.LayoutOrder = order
    btn.BorderSizePixel = 0
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
        
        local activeColor = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold
        local activeBG = isWinter and Settings.Theme.IceDark or Color3.fromRGB(30, 30, 35)
        
        Library:Tween(btn, {BackgroundColor3 = activeBG, TextColor3 = activeColor})
        page.Visible = true
    end)
    
    if order == 1 then 
        currentTab = btn
        local activeColor = isWinter and Settings.Theme.IceBlue or Settings.Theme.Gold
        local activeBG = isWinter and Settings.Theme.IceDark or Color3.fromRGB(30, 30, 35)
        Library:Tween(btn, {BackgroundColor3 = activeBG, TextColor3 = activeColor})
        page.Visible = true 
    end
    return page
end

local Tab_Event_Page = CreateTab("Winter Event", "אירוע חורף", 1, true) 
local Tab_Main_Page = CreateTab("Main", "ראשי", 2, false)
local Tab_Settings_Page = CreateTab("Settings", "הגדרות", 3, false)
local Tab_Credits_Page = CreateTab("Credits", "קרדיטים", 4, false)

local function AddLayout(p) 
    local l = Instance.new("UIListLayout", p); l.Padding = UDim.new(0,10); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local pad = Instance.new("UIPadding", p); pad.PaddingTop = UDim.new(0,5) 
end
AddLayout(Tab_Main_Page); AddLayout(Tab_Settings_Page)

--// 6. מערכות לוגיקה
task.spawn(function() 
    while true do 
        task.wait(30)
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

-- ======================================================================================
--                        מערכת ה-AUTO FARM (STABLE + WATER FIX)
-- ======================================================================================
local function ToggleFarm(v)
    Settings.Farming = v; if not v then FarmBlacklist = {} end
    if not FarmConnection and v then
        FarmConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and Settings.Farming then
                -- Ghost Mode (No Collisions) - מעבר דרך קירות בטוח
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do 
                    if part:IsA("BasePart") then part.CanCollide = false end 
                end
                
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then 
                    if hum.Sit then hum.Sit = false end 
                    
                    -- FIX: Disable Swimming State (Walk through water)
                    -- מכריח את השחקן להיות במצב הליכה גם במים
                    hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) 
                    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                    
                    -- Infinite Oxygen (לא טובעים)
                    hum.Air = 100
                end
            end
        end)
    elseif not v and FarmConnection then 
        FarmConnection:Disconnect()
        FarmConnection = nil 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            -- החזרת מצב שחייה
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
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
                        
                        -- Optimization: Don't calculate if too close
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
                
                -- תוספת: שליטה עם SPACE ו-CTRL
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

--// 8. רכיבים וטאבים אחרים (עיצוב פרימיום ל-MAIN)
local function CreateSlider(parent, title, heb, min, max, default, callback, toggleCallback, toggleName)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0.95,0,0,65)
    f.BackgroundColor3 = Color3.fromRGB(10, 10, 15) -- רקע כהה יותר
    Library:Corner(f, 8)
    
    -- מסגרת זהב עבה
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Settings.Theme.Gold
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(0.7,0,0,25)
    l.Position = UDim2.new(0,10,0,6)
    l.Text = title .. " ("..heb..") : " .. default
    l.TextColor3=Color3.new(1,1,1)
    l.Font=Enum.Font.GothamBold
    l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.BackgroundTransparency=1
    
    local line = Instance.new("Frame", f)
    line.Size = UDim2.new(0.9,0,0,10)
    line.Position = UDim2.new(0.05,0,0.65,0)
    line.BackgroundColor3 = Color3.fromRGB(30,30,35)
    Library:Corner(line,5)
    
    local fill = Instance.new("Frame", line)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Settings.Theme.Gold
    Library:Corner(fill,5)
    
    local grad = Instance.new("UIGradient", fill)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Settings.Theme.Gold),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 150))
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
            l.Text = title .. " (" .. heb .. ") : " .. v
            callback(v)
        end)
        
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end)

    if toggleCallback then
        local t = Instance.new("TextButton", f)
        t.Size = UDim2.new(0,50,0,22)
        t.Position = UDim2.new(1,-60,0,8)
        t.BackgroundColor3 = Color3.fromRGB(40,40,40)
        t.Text = "OFF"
        t.TextColor3 = Color3.new(1,1,1)
        t.Font = Enum.Font.GothamBold
        Library:Corner(t,4)
        t.TextSize=12
        
        local on = false
        local function Update(s) 
            on=s
            t.Text=on and "ON" or "OFF"
            t.BackgroundColor3=on and Settings.Theme.Gold or Color3.fromRGB(40,40,40)
            t.TextColor3=on and Color3.new(0,0,0) or Color3.new(1,1,1)
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
    f.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- כהה יותר
    f.Text=""
    f.AutoButtonColor=false
    Library:Corner(f, 8)
    
    -- מסגרת זהב עבה לכפתורים ב-MAIN
    local s = Instance.new("UIStroke", f)
    s.Color = Settings.Theme.Gold
    s.Thickness = 2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1,0,0,20)
    t.Position = UDim2.new(0,0,id==3 and 0.1 or 0.15,0)
    t.Text=title
    t.TextColor3=Color3.fromRGB(200,200,200)
    t.Font=Enum.Font.Gotham
    t.TextSize=12
    t.BackgroundTransparency=1
    
    local h = Instance.new("TextLabel", f)
    h.Size = UDim2.new(1,0,0,15)
    h.Position = UDim2.new(0,0,0.35,0)
    h.Text=heb
    h.TextColor3=Color3.fromRGB(150,150,150)
    h.Font=Enum.Font.Gotham
    h.TextSize=10
    h.BackgroundTransparency=1
    
    local k = Instance.new("TextLabel", f)
    k.Size = UDim2.new(1,0,0,30)
    k.Position = UDim2.new(0,0,id==3 and 0.5 or 0.6,0)
    k.Text=default.Name
    k.TextColor3=Settings.Theme.Gold
    k.Font=Enum.Font.GothamBold
    k.TextSize=18
    k.BackgroundTransparency=1
    
    f.MouseButton1Click:Connect(function() 
        k.Text="..."
        local i=UIS.InputBegan:Wait() 
        if i.UserInputType==Enum.UserInputType.Keyboard then 
            k.Text=i.KeyCode.Name
            callback(i.KeyCode) 
        end 
    end)
    return f
end

CreateSlider(Tab_Main_Page, "Walk Speed", "מהירות הליכה", 1, 250, 16, function(v) 
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

CreateSlider(Tab_Main_Page, "Fly Speed", "מהירות תעופה", 20, 300, 50, function(v) Settings.Fly.Speed = v end, function(t) ToggleFly(t) end, "Fly")
local BindCont = Instance.new("Frame", Tab_Main_Page); BindCont.Size = UDim2.new(0.95,0,0,70); BindCont.BackgroundTransparency = 1; CreateSquareBind(BindCont, 1, "FLY", "תעופה", Settings.Keys.Fly, function(k) Settings.Keys.Fly = k end); CreateSquareBind(BindCont, 2, "SPEED", "מהירות", Settings.Keys.Speed, function(k) Settings.Keys.Speed = k end)

CreateSlider(Tab_Settings_Page, "FOV", "שדה ראייה", 70, 120, 70, function(v) Camera.FieldOfView = v end)

CreateSlider(Tab_Settings_Page, "GUI Scale", "גודל ממשק", 5, 15, 10, function(v) 
    local scale = v / 10
    Library:Tween(MainScale, {Scale = scale}, 0.5, Enum.EasingStyle.Quart)
end)

local MenuBindCont = Instance.new("Frame", Tab_Settings_Page); MenuBindCont.Size = UDim2.new(0.95,0,0,60); MenuBindCont.BackgroundTransparency = 1; CreateSquareBind(MenuBindCont, 3, "MENU KEY", "מקש תפריט", Settings.Keys.Menu, function(k) Settings.Keys.Menu = k end)

--// REJOIN BUTTON
local RejoinBtn = Instance.new("TextButton", Tab_Settings_Page)
RejoinBtn.Size = UDim2.new(0.95, 0, 0, 40)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
RejoinBtn.Text = "Rejoin Server 🔄"
RejoinBtn.TextColor3 = Color3.new(1,1,1)
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.TextSize = 14
Library:Corner(RejoinBtn, 8)
Library:AddGlow(RejoinBtn, Color3.fromRGB(200, 60, 60))
RejoinBtn.MouseButton1Click:Connect(function() 
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- CREDITS
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
    c.BackgroundColor3 = Settings.Theme.Box
    c.ZIndex = 2
    Library:Corner(c, 12)
    Library:AddGlow(c, Settings.Theme.Gold)
    
    local imgCont = Instance.new("Frame", c)
    imgCont.Size = UDim2.new(0, 60, 0, 60)
    imgCont.Position = UDim2.new(0.5, -30, 0.1, 0)
    imgCont.BackgroundColor3 = Color3.fromRGB(30,30,35)
    imgCont.ZIndex = 3
    Library:Corner(imgCont, 30)
    
    local img = Instance.new("ImageLabel", imgCont)
    img.Size = UDim2.new(1, 0, 1, 0)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://" .. decal 
    img.ZIndex = 4
    Library:Corner(img, 30)
    
    local tName = Instance.new("TextLabel", c)
    tName.Size = UDim2.new(1,0,0,20)
    tName.Position = UDim2.new(0,0,0.60,0)
    tName.BackgroundTransparency = 1
    tName.Text = name; tName.Font=Enum.Font.GothamBlack; tName.TextSize=15; tName.TextColor3 = Settings.Theme.Gold; tName.ZIndex=3
    
    local tRole = Instance.new("TextLabel", c)
    tRole.Size = UDim2.new(1,0,0,15)
    tRole.Position = UDim2.new(0,0,0.72,0)
    tRole.BackgroundTransparency = 1
    tRole.Text = role; tRole.TextColor3 = Settings.Theme.IceBlue; tRole.Font=Enum.Font.GothamBold; tRole.TextSize=11; tRole.ZIndex=3
    
    local btn = Instance.new("TextButton", c)
    btn.Size = UDim2.new(0, 100, 0, 22)
    btn.Position = UDim2.new(0.5, -50, 0.88, 0)
    btn.BackgroundColor3 = Settings.Theme.Discord
    btn.Text="Copy Discord 👾"
    btn.TextColor3=Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
    btn.ZIndex=3
    Library:Corner(btn, 11)
    btn.MouseButton1Click:Connect(function() 
        setclipboard(discord)
        local old = btn.Text; btn.Text="Copied!"; btn.BackgroundColor3=Color3.fromRGB(60,200,100)
        task.wait(1)
        btn.Text=old; btn.BackgroundColor3=Settings.Theme.Discord 
    end)
end

CreateCreditCard(Tab_Credits_Page, "Neho", "Founder", "nx3ho", "97462570733982", UDim2.new(0.04, 0, 0.05, 0)) 
CreateCreditCard(Tab_Credits_Page, "BadShot", "CoFounder", "8adshot3", "133430813410950", UDim2.new(0.52, 0, 0.05, 0)) 
CreateCreditCard(Tab_Credits_Page, "xyth", "Community Manager", "sc4rlxrd", "106705865211282", UDim2.new(0.28, 0, 0.45, 0)) 

local SceneContainer = Instance.new("Frame", Tab_Credits_Page); SceneContainer.Size = UDim2.new(1, 0, 0.35, 0); SceneContainer.Position = UDim2.new(0, 0, 0.65, 0); SceneContainer.BackgroundTransparency = 1; SceneContainer.ZIndex=3
local Hill1 = Instance.new("Frame", SceneContainer); Hill1.Size = UDim2.new(0.6, 0, 1, 0); Hill1.Position = UDim2.new(-0.1, 0, 0.4, 0); Hill1.BackgroundColor3 = Color3.fromRGB(240, 248, 255); Hill1.BorderSizePixel=0; Library:Corner(Hill1, 100)
local Hill2 = Instance.new("Frame", SceneContainer); Hill2.Size = UDim2.new(0.7, 0, 1.2, 0); Hill2.Position = UDim2.new(0.4, 0, 0.5, 0); Hill2.BackgroundColor3 = Color3.fromRGB(230, 240, 250); Hill2.BorderSizePixel=0; Library:Corner(Hill2, 100)
local Snowman = Instance.new("TextLabel", SceneContainer); Snowman.Text = "⛄"; Snowman.Size = UDim2.new(0, 70, 0, 70); Snowman.Position = UDim2.new(0.1, 0, 0.45, 0); Snowman.BackgroundTransparency = 1; Snowman.TextSize = 60; Snowman.Rotation = -8; Snowman.ZIndex=4
local Tree1 = Instance.new("TextLabel", SceneContainer); Tree1.Text = "🌲"; Tree1.Size = UDim2.new(0, 90, 0, 90); Tree1.Position = UDim2.new(0.82, 0, 0.35, 0); Tree1.BackgroundTransparency = 1; Tree1.TextSize = 80; Tree1.ZIndex=4
local Tree2 = Instance.new("TextLabel", SceneContainer); Tree2.Text = "🌲"; Tree2.Size = UDim2.new(0, 70, 0, 70); Tree2.Position = UDim2.new(0.72, 0, 0.5, 0); Tree2.BackgroundTransparency = 1; Tree2.TextSize = 60; Tree2.ZIndex=4

--// 9. ניהול מקשים ולולאות
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Menu then if MainFrame.Visible then Library:Tween(MainFrame, {Size = UDim2.new(0,0,0,0)}, 0.4, Enum.EasingStyle.Back); task.wait(0.3); MainFrame.Visible = false else MainFrame.Visible = true; MainFrame.Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT); Library:Tween(MainFrame, {Size = UDim2.new(0, NEW_WIDTH, 0, NEW_HEIGHT)}, 0.5, Enum.EasingStyle.Back) end end
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
        btn.MouseEnter:Connect(function() Library:Tween(btn, {Size = UDim2.new(0.95, 0, 0, 40)}, 0.3, Enum.EasingStyle.Quart) end)
        btn.MouseLeave:Connect(function() Library:Tween(btn, {Size = UDim2.new(0.9, 0, 0, 40)}, 0.3, Enum.EasingStyle.Quart) end)
    end
end

if RejoinBtn then
    RejoinBtn.MouseEnter:Connect(function() Library:Tween(RejoinBtn, {BackgroundColor3 = Color3.fromRGB(230, 80, 80)}, 0.2) end)
    RejoinBtn.MouseLeave:Connect(function() Library:Tween(RejoinBtn, {BackgroundColor3 = Color3.fromRGB(200, 60, 60)}, 0.2) end)
end

print("[SYSTEM] Spaghetti Mafia Hub v1 (FULL PREMIUM) Loaded")
