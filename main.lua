--[[
    Spaghetti Mafia Hub v3.0 (FULL RESTORATION)
    
    FIX LOG:
    1. RESTORED: Winter Stats (Blue/Red Shards counters).
    2. RESTORED: All Target Buttons (Bang, Spectate, Headsit, Backpack).
    3. RESTORED: Keybinds in Main Tab & Settings.
    4. RESTORED: Rejoin Button & FOV Slider.
    5. VISUALS: Kept the new Premium Black/Gold Theme.
]]

--// AUTO EXECUTE
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
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// 1. WHITELIST
local WHITELIST_URL = "https://raw.githubusercontent.com/Spaghettimafiav1/Spaghettimafiav1/main/Whitelist.txt"
local function CheckWhitelist()
    local success, content = pcall(function() return game:HttpGet(WHITELIST_URL .. "?t=" .. tick()) end)
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
if Lighting:FindFirstChild("SpagBlur") then Lighting.SpagBlur:Destroy() end

local Settings = {
    Theme = {
        Gold = Color3.fromRGB(255, 190, 0), -- Golden
        Dark = Color3.fromRGB(12, 12, 12), -- Deep Black
        Box = Color3.fromRGB(20, 20, 20), -- Panel Color
        Text = Color3.fromRGB(240, 240, 240),
        IceBlue = Color3.fromRGB(100, 220, 255),
        CrystalRed = Color3.fromRGB(255, 70, 70),
        Discord = Color3.fromRGB(88, 101, 242)
    },
    Keys = { Menu = Enum.KeyCode.RightControl, Fly = Enum.KeyCode.E, Speed = Enum.KeyCode.F },
    Fly = { Enabled = false, Speed = 50 },
    Speed = { Enabled = false, Value = 16 },
    Farming = false,
    FarmSpeed = 450
}

local FarmBlacklist = {}
local SitAnimTrack = nil 
local isSittingAction = false 
local VisualToggles = {}

--// SOUNDS
local Sounds = {
    Click = "rbxassetid://6895079853", 
    Hover = "rbxassetid://6895079980", 
    StormStart = "rbxassetid://4612377184", 
    StormEnd = "rbxassetid://255318536"    
}
local function PlaySound(id)
    local s = Instance.new("Sound")
    s.SoundId = id; s.Parent = CoreGui; s.Volume = 1.0; s.PlayOnRemove = true; s.Name = "SpagAudio"; s:Destroy()
end

--// 3. UI HELPERS
local Library = {}
function Library:Tween(obj, props, time, style) 
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play() 
end
function Library:Corner(obj, r) local c = Instance.new("UICorner", obj); c.CornerRadius = UDim.new(0, r or 10); return c end
function Library:AddGlow(obj, color, thickness) 
    local s = Instance.new("UIStroke", obj); s.Color = color or Settings.Theme.Gold; s.Thickness = thickness or 1.5; s.Transparency = 0.6; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s 
end
function Library:AddHover(obj)
    obj.MouseEnter:Connect(function()
        Library:Tween(obj, {BackgroundColor3 = Color3.fromRGB(35,35,35)})
        local scale = Instance.new("UIScale", obj); scale.Scale = 1
        TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 1.02}):Play()
        PlaySound(Sounds.Hover)
        obj.MouseLeave:Connect(function()
            Library:Tween(obj, {BackgroundColor3 = Settings.Theme.Box})
            TweenService:Create(scale, TweenInfo.new(0.1), {Scale = 1}):Play()
            game:GetService("Debris"):AddItem(scale, 0.1)
        end)
    end)
    obj.MouseButton1Click:Connect(function() PlaySound(Sounds.Click) end)
end
function Library:MakeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true; dragStart = input.Position; startPos = obj.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) 
        end 
    end)
    obj.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    RunService.RenderStepped:Connect(function() 
        if dragging and dragInput then 
            local delta = dragInput.Position - dragStart
            TweenService:Create(obj, TweenInfo.new(0.05), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}):Play()
        end 
    end)
end

--// 4. LOADING SCREEN (Floating)
local Blur = Instance.new("BlurEffect", Lighting); Blur.Name = "SpagBlur"; Blur.Size = 0
TweenService:Create(Blur, TweenInfo.new(1), {Size = 24}):Play()

local LoadGui = Instance.new("ScreenGui"); LoadGui.Name = "SpaghettiLoading"; LoadGui.Parent = CoreGui
local LoadBox = Instance.new("Frame", LoadGui)
LoadBox.Size = UDim2.new(0, 280, 0, 200); LoadBox.Position = UDim2.new(0.5, 0, 0.5, 0); LoadBox.AnchorPoint = Vector2.new(0.5, 0.5)
LoadBox.BackgroundColor3 = Settings.Theme.Dark; LoadBox.BackgroundTransparency = 0.1
Library:Corner(LoadBox, 20); Library:AddGlow(LoadBox, Settings.Theme.Gold, 2)

local PastaIcon = Instance.new("TextLabel", LoadBox); PastaIcon.Text = "🍝"; PastaIcon.Size = UDim2.new(1,0,0.5,0); PastaIcon.BackgroundTransparency=1; PastaIcon.TextSize=80
task.spawn(function() local t=0; while LoadBox.Parent do t=t+0.1; PastaIcon.Position = UDim2.new(0,0,0.05+math.sin(t)*0.05,0); PastaIcon.Rotation=math.sin(t/2)*5; task.wait(0.03) end end)

local TitleLoad = Instance.new("TextLabel", LoadBox); TitleLoad.Text = "SPAGHETTI MAFIA v3"; TitleLoad.Size=UDim2.new(1,0,0.2,0); TitleLoad.Position=UDim2.new(0,0,0.55,0); TitleLoad.BackgroundTransparency=1; TitleLoad.TextColor3=Settings.Theme.Gold; TitleLoad.Font=Enum.Font.GothamBlack; TitleLoad.TextSize=22

local BarBG = Instance.new("Frame", LoadBox); BarBG.Size=UDim2.new(0.7,0,0,4); BarBG.Position=UDim2.new(0.15,0,0.85,0); BarBG.BackgroundColor3=Color3.fromRGB(40,40,40); Library:Corner(BarBG,5)
local BarFill = Instance.new("Frame", BarBG); BarFill.Size=UDim2.new(0,0,1,0); BarFill.BackgroundColor3=Settings.Theme.Gold; Library:Corner(BarFill,5)
Library:Tween(BarFill, {Size=UDim2.new(1,0,1,0)}, 2.5, Enum.EasingStyle.Exponential)

task.wait(2.8)
TweenService:Create(Blur, TweenInfo.new(0.5), {Size=0}):Play()
LoadGui:Destroy(); Blur:Destroy()

--// 5. MAIN GUI
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "SpaghettiHub_Rel"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false
local MiniPasta = Instance.new("TextButton", ScreenGui); MiniPasta.Size=UDim2.new(0,60,0,60); MiniPasta.Position=UDim2.new(0.05,0,0.1,0); MiniPasta.BackgroundColor3=Settings.Theme.Dark; MiniPasta.Text="🍝"; MiniPasta.TextSize=35; MiniPasta.Visible=false
Library:Corner(MiniPasta, 30); Library:AddGlow(MiniPasta, Settings.Theme.Gold, 2); Library:MakeDraggable(MiniPasta)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 620, 0, 480); MainFrame.Position = UDim2.new(0.5,0,0.5,0); MainFrame.AnchorPoint=Vector2.new(0.5,0.5)
MainFrame.BackgroundColor3 = Settings.Theme.Dark; MainFrame.BackgroundTransparency = 0.05
Library:Corner(MainFrame, 14); Library:AddGlow(MainFrame, Settings.Theme.Gold, 2)
MainFrame.ClipsDescendants = true
Library:MakeDraggable(MainFrame)

-- TOP BAR
local TopBar = Instance.new("Frame", MainFrame); TopBar.Size=UDim2.new(1,0,0,60); TopBar.BackgroundTransparency=1
local Title = Instance.new("TextLabel", TopBar); Title.Text="SPAGHETTI <font color='#FFC800'>MAFIA</font> v3.0"; Title.RichText=true; Title.Size=UDim2.new(0,300,0,30); Title.Position=UDim2.new(0,25,0,15); Title.BackgroundTransparency=1; Title.TextColor3=Color3.new(1,1,1); Title.Font=Enum.Font.GothamBlack; Title.TextSize=24; Title.TextXAlignment=Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar); CloseBtn.Size=UDim2.new(0,30,0,30); CloseBtn.Position=UDim2.new(1,-45,0,15); CloseBtn.BackgroundColor3=Settings.Theme.Box; CloseBtn.Text="×"; CloseBtn.TextColor3=Settings.Theme.Gold; CloseBtn.Font=Enum.Font.GothamBlack; CloseBtn.TextSize=22; Library:Corner(CloseBtn, 8)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible=false; MiniPasta.Visible=true end)
MiniPasta.MouseButton1Click:Connect(function() MiniPasta.Visible=false; MainFrame.Visible=true end)

-- STORM WIDGET (Restored)
task.spawn(function()
    local StormValue = ReplicatedStorage:WaitForChild("StormTimeLeft", 5)
    if StormValue then
        local Widget = Instance.new("Frame", TopBar); Widget.Size=UDim2.new(0,120,0,35); Widget.Position=UDim2.new(1,-180,0.5,-17); Widget.BackgroundColor3=Settings.Theme.Box; Library:Corner(Widget,8)
        local WText = Instance.new("TextLabel", Widget); WText.Size=UDim2.new(1,0,1,0); WText.BackgroundTransparency=1; WText.TextColor3=Settings.Theme.IceBlue; WText.Font=Enum.Font.GothamBold; WText.TextSize=14
        StormValue.Changed:Connect(function(v)
            local m = math.floor(v/60); local s = v%60
            if v<=0 then WText.Text="STORM ACTIVE!"; WText.TextColor3=Settings.Theme.CrystalRed else WText.Text=string.format("%02d:%02d", m, s); WText.TextColor3=Settings.Theme.IceBlue end
        end)
    end
end)

-- SIDEBAR
local Sidebar = Instance.new("Frame", MainFrame); Sidebar.Size=UDim2.new(0,160,1,-60); Sidebar.Position=UDim2.new(0,0,0,60); Sidebar.BackgroundColor3=Color3.fromRGB(15,15,15); Library:Corner(Sidebar,0)
local Profile = Instance.new("Frame", Sidebar); Profile.Size=UDim2.new(1,0,0,70); Profile.Position=UDim2.new(0,0,1,-70); Profile.BackgroundTransparency=1
local Avatar = Instance.new("ImageLabel", Profile); Avatar.Size=UDim2.new(0,40,0,40); Avatar.Position=UDim2.new(0,15,0,15); Avatar.BackgroundColor3=Settings.Theme.Gold; Library:Corner(Avatar,20)
Avatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
local Name = Instance.new("TextLabel", Profile); Name.Text=LocalPlayer.Name; Name.Size=UDim2.new(0,90,0,20); Name.Position=UDim2.new(0,65,0,25); Name.BackgroundTransparency=1; Name.TextColor3=Settings.Theme.Gold; Name.Font=Enum.Font.GothamBold; Name.TextSize=12; Name.TextXAlignment=Enum.TextXAlignment.Left

local TabContainer = Instance.new("Frame", MainFrame); TabContainer.Size=UDim2.new(1,-160,1,-60); TabContainer.Position=UDim2.new(0,160,0,60); TabContainer.BackgroundTransparency=1; TabContainer.ClipsDescendants=true
local TabBtns = Instance.new("ScrollingFrame", Sidebar); TabBtns.Size=UDim2.new(1,0,1,-80); TabBtns.BackgroundTransparency=1; TabBtns.ScrollBarThickness=0
local TabList = Instance.new("UIListLayout", TabBtns); TabList.Padding=UDim.new(0,10); TabList.HorizontalAlignment=Enum.HorizontalAlignment.Center
local TabPad = Instance.new("UIPadding", TabBtns); TabPad.PaddingTop=UDim.new(0,20)

local function CreateTab(name, icon, order)
    local btn = Instance.new("TextButton", TabBtns); btn.Size=UDim2.new(0.85,0,0,45); btn.BackgroundColor3=Settings.Theme.Dark; btn.Text=icon.."  "..name; btn.TextColor3=Color3.fromRGB(150,150,150); btn.Font=Enum.Font.GothamBold; btn.TextSize=13; btn.TextXAlignment=Enum.TextXAlignment.Left; btn.LayoutOrder=order
    Library:Corner(btn, 8)
    
    local page = Instance.new("Frame", TabContainer); page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1; page.Visible=false; page.Name=name.."Page"
    local pPad = Instance.new("UIPadding", page); pPad.PaddingTop=UDim.new(0,15); pPad.PaddingLeft=UDim.new(0,15); pPad.PaddingRight=UDim.new(0,15); pPad.PaddingBottom=UDim.new(0,15)
    
    btn.MouseButton1Click:Connect(function()
        for _,v in pairs(TabBtns:GetChildren()) do if v:IsA("TextButton") then Library:Tween(v, {BackgroundColor3=Settings.Theme.Dark, TextColor3=Color3.fromRGB(150,150,150)}) end end
        Library:Tween(btn, {BackgroundColor3=Color3.fromRGB(25,25,25), TextColor3=Settings.Theme.Gold})
        
        for _,v in pairs(TabContainer:GetChildren()) do v.Visible=false end
        page.Visible=true
        page.Position = UDim2.new(0.5,0,0,0); Library:Tween(page, {Position=UDim2.new(0,0,0,0)}, 0.3)
    end)
    if order==1 then 
        Library:Tween(btn, {BackgroundColor3=Color3.fromRGB(25,25,25), TextColor3=Settings.Theme.Gold})
        page.Visible=true 
    end
    return page
end

local Page_Winter = CreateTab("Winter", "❄️", 1)
local Page_Main = CreateTab("Main", "🏠", 2)
local Page_Target = CreateTab("Target", "🎯", 3)
local Page_Settings = CreateTab("Settings", "⚙️", 4)
local Page_Credits = CreateTab("Credits", "📜", 5)

--// 6. CONTENT: WINTER TAB (RESTORED STATS & BUTTON)
local WinterScroll = Instance.new("ScrollingFrame", Page_Winter); WinterScroll.Size=UDim2.new(1,0,1,0); WinterScroll.BackgroundTransparency=1; WinterScroll.ScrollBarThickness=2
local WinterList = Instance.new("UIListLayout", WinterScroll); WinterList.Padding=UDim.new(0,15)

-- Auto Farm Button
local FarmBtn = Instance.new("TextButton", WinterScroll); FarmBtn.Size=UDim2.new(1,0,0,80); FarmBtn.BackgroundColor3=Color3.fromRGB(25,35,50); FarmBtn.Text=""; Library:Corner(FarmBtn, 12); Library:AddGlow(FarmBtn, Settings.Theme.IceBlue, 1.5); Library:AddHover(FarmBtn)
local FTitle = Instance.new("TextLabel", FarmBtn); FTitle.Text="Auto Farm Winter"; FTitle.Size=UDim2.new(1,-80,0,30); FTitle.Position=UDim2.new(0,20,0,15); FTitle.BackgroundTransparency=1; FTitle.TextColor3=Settings.Theme.IceBlue; FTitle.Font=Enum.Font.GothamBlack; FTitle.TextSize=20; FTitle.TextXAlignment=Enum.TextXAlignment.Left
local FSub = Instance.new("TextLabel", FarmBtn); FSub.Text="Collects Shards & Crystals automatically"; FSub.Size=UDim2.new(1,-80,0,20); FSub.Position=UDim2.new(0,20,0,45); FSub.BackgroundTransparency=1; FSub.TextColor3=Color3.fromRGB(150,200,220); FSub.Font=Enum.Font.Gotham; FSub.TextSize=12; FSub.TextXAlignment=Enum.TextXAlignment.Left
local FInd = Instance.new("Frame", FarmBtn); FInd.Size=UDim2.new(0,50,0,28); FInd.Position=UDim2.new(1,-70,0.5,-14); FInd.BackgroundColor3=Color3.fromRGB(40,40,60); Library:Corner(FInd,20)
local FDot = Instance.new("Frame", FInd); FDot.Size=UDim2.new(0,24,0,24); FDot.Position=UDim2.new(0,2,0.5,-12); FDot.BackgroundColor3=Color3.fromRGB(200,200,200); Library:Corner(FDot,20)

-- Stats Grid (Restored!)
local StatsGrid = Instance.new("Frame", WinterScroll); StatsGrid.Size=UDim2.new(1,0,0,140); StatsGrid.BackgroundTransparency=1
local SLayout = Instance.new("UIGridLayout", StatsGrid); SLayout.CellSize=UDim2.new(0.48,0,0,65); SLayout.CellPadding=UDim2.new(0.04,0,0.04,0)

local function CreateStatBox(title, color)
    local b = Instance.new("Frame", StatsGrid); b.BackgroundColor3=Settings.Theme.Box; Library:Corner(b,10); Library:AddGlow(b, color, 1)
    local t = Instance.new("TextLabel", b); t.Text=title; t.Size=UDim2.new(1,0,0,20); t.Position=UDim2.new(0,0,0.1,0); t.BackgroundTransparency=1; t.TextColor3=color; t.Font=Enum.Font.GothamBold; t.TextSize=12
    local v = Instance.new("TextLabel", b); v.Text="0"; v.Size=UDim2.new(1,0,0,30); v.Position=UDim2.new(0,0,0.4,0); v.BackgroundTransparency=1; v.TextColor3=Color3.new(1,1,1); v.Font=Enum.Font.GothamBlack; v.TextSize=22
    return v
end

local ValBlues = CreateStatBox("Total Blues 🧊", Settings.Theme.IceBlue)
local ValReds = CreateStatBox("Total Reds 💎", Settings.Theme.CrystalRed)
local SesBlues = CreateStatBox("Session Blues 🧊", Settings.Theme.IceBlue)
local SesReds = CreateStatBox("Session Reds 💎", Settings.Theme.CrystalRed)

-- Logic Update Loop
task.spawn(function()
    local CRef = LocalPlayer:WaitForChild("Crystals", 10); local SRef = LocalPlayer:WaitForChild("Shards", 10)
    if CRef and SRef then
        local iC = CRef.Value; local iS = SRef.Value
        while true do
            wait(0.5)
            ValReds.Text = tostring(CRef.Value); ValBlues.Text = tostring(SRef.Value)
            SesReds.Text = "+"..tostring(CRef.Value - iC); SesBlues.Text = "+"..tostring(SRef.Value - iS)
        end
    end
end)

-- Farm Logic
local function ToggleFarm(v)
    Settings.Farming = v
    if v then
        Library:Tween(FInd, {BackgroundColor3=Settings.Theme.IceBlue}); Library:Tween(FDot, {Position=UDim2.new(1,-26,0.5,-12)})
        task.spawn(function()
            while Settings.Farming do
                pcall(function()
                    local drops = Workspace:FindFirstChild("StormDrops")
                    if drops then
                        for _,d in pairs(drops:GetChildren()) do
                            if d:IsA("BasePart") and LocalPlayer.Character then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = d.CFrame
                                LocalPlayer.Character.Humanoid.Sit = false
                                wait(0.2)
                            end
                            if not Settings.Farming then break end
                        end
                    end
                end)
                wait(0.5)
            end
        end)
    else
        Library:Tween(FInd, {BackgroundColor3=Color3.fromRGB(40,40,60)}); Library:Tween(FDot, {Position=UDim2.new(0,2,0.5,-12)})
    end
end
FarmBtn.MouseButton1Click:Connect(function() ToggleFarm(not Settings.Farming) end)


--// 7. CONTENT: MAIN TAB (RESTORED SLIDERS & BINDS)
local MainListLayout = Instance.new("UIListLayout", Page_Main); MainListLayout.Padding=UDim.new(0,15)

local function CreateSlider(parent, name, min, max, def, callback, keybindRef)
    local f = Instance.new("Frame", parent); f.Size=UDim2.new(1,0,0,70); f.BackgroundColor3=Settings.Theme.Box; Library:Corner(f,10); Library:AddGlow(f, Settings.Theme.Gold, 1)
    local title = Instance.new("TextLabel", f); title.Text=name; title.Size=UDim2.new(1,0,0,25); title.Position=UDim2.new(0,15,0,5); title.BackgroundTransparency=1; title.TextColor3=Color3.new(1,1,1); title.Font=Enum.Font.GothamBold; title.TextXAlignment=Enum.TextXAlignment.Left
    
    local bar = Instance.new("Frame", f); bar.Size=UDim2.new(0.65,0,0,6); bar.Position=UDim2.new(0,15,0,45); bar.BackgroundColor3=Color3.fromRGB(40,40,40); Library:Corner(bar,3)
    local fill = Instance.new("Frame", bar); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=Settings.Theme.Gold; Library:Corner(fill,3)
    local val = Instance.new("TextLabel", f); val.Text=tostring(def); val.Size=UDim2.new(0,40,0,20); val.Position=UDim2.new(0.7,0,0,38); val.BackgroundTransparency=1; val.TextColor3=Settings.Theme.Gold; val.Font=Enum.Font.GothamBold

    local btn = Instance.new("TextButton", f); btn.Size=UDim2.new(0.65,0,0,20); btn.Position=UDim2.new(0,15,0,38); btn.BackgroundTransparency=1; btn.Text=""
    btn.MouseButton1Down:Connect(function()
        local c; c=RunService.RenderStepped:Connect(function()
            if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then c:Disconnect() return end
            local s = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
            fill.Size=UDim2.new(s,0,1,0); local res = math.floor(min+(max-min)*s); val.Text=tostring(res); callback(res)
        end)
    end)
    
    -- RESTORED KEYBIND BUTTON
    local kb = Instance.new("TextButton", f); kb.Size=UDim2.new(0,80,0,30); kb.Position=UDim2.new(1,-95,0.5,-15); kb.BackgroundColor3=Color3.fromRGB(30,30,30); kb.Text=keybindRef.Name; kb.TextColor3=Color3.fromRGB(150,150,150); kb.Font=Enum.Font.GothamBold; Library:Corner(kb,6)
    kb.MouseButton1Click:Connect(function()
        kb.Text="..."; local i=UIS.InputBegan:Wait()
        if i.UserInputType==Enum.UserInputType.Keyboard then 
            Settings.Keys[name] = i.KeyCode; kb.Text=i.KeyCode.Name 
            keybindRef = i.KeyCode -- Update Ref
        end
    end)
end

CreateSlider(Page_Main, "Speed", 16, 300, 16, function(v) 
    Settings.Speed.Value=v; if Settings.Speed.Enabled and LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed=v end 
end, Settings.Keys.Speed)

CreateSlider(Page_Main, "Fly", 20, 300, 50, function(v) Settings.Fly.Speed=v end, Settings.Keys.Fly)

-- Fly Logic
local function ToggleFly(v)
    Settings.Fly.Enabled = v
    local char = LocalPlayer.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid")
    if v then
        local bv = Instance.new("BodyVelocity", hrp); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Name="F_V"
        local bg = Instance.new("BodyGyro", hrp); bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.P=9e4; bg.Name="F_G"
        hum.PlatformStand=true
        task.spawn(function()
            while Settings.Fly.Enabled and char.Parent do
                hum.Sit=false
                local cam = workspace.CurrentCamera; local d = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d=d-Vector3.new(0,1,0) end
                bv.Velocity = d * Settings.Fly.Speed; bg.CFrame = cam.CFrame
                RunService.RenderStepped:Wait()
            end
            if hrp:FindFirstChild("F_V") then hrp.F_V:Destroy() end
            if hrp:FindFirstChild("F_G") then hrp.F_G:Destroy() end
            hum.PlatformStand=false
        end)
    else
        if hrp:FindFirstChild("F_V") then hrp.F_V:Destroy() end
        if hrp:FindFirstChild("F_G") then hrp.F_G:Destroy() end
        hum.PlatformStand=false
    end
end

-- Keybind Listeners
UIS.InputBegan:Connect(function(i,g)
    if not g then
        if i.KeyCode == Settings.Keys.Fly then ToggleFly(not Settings.Fly.Enabled) end
        if i.KeyCode == Settings.Keys.Speed then 
            Settings.Speed.Enabled = not Settings.Speed.Enabled
            if LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed = Settings.Speed.Enabled and Settings.Speed.Value or 16 end
        end
        if i.KeyCode == Settings.Keys.Menu then MainFrame.Visible = not MainFrame.Visible; MiniPasta.Visible = not MainFrame.Visible end
    end
end)


--// 8. CONTENT: TARGET TAB (RESTORED ALL ACTIONS)
local TargetSplit = Instance.new("Frame", Page_Target); TargetSplit.Size=UDim2.new(1,0,0,160); TargetSplit.BackgroundTransparency=1
local LeftT = Instance.new("Frame", TargetSplit); LeftT.Size=UDim2.new(0.3,0,1,0); LeftT.BackgroundTransparency=1
local RightT = Instance.new("Frame", TargetSplit); RightT.Size=UDim2.new(0.68,0,1,0); RightT.Position=UDim2.new(0.32,0,0,0); RightT.BackgroundTransparency=1

-- Avatar
local AVBox = Instance.new("Frame", LeftT); AVBox.Size=UDim2.new(1,0,1,0); AVBox.BackgroundColor3=Settings.Theme.Box; Library:Corner(AVBox,12); Library:AddGlow(AVBox, Settings.Theme.Gold, 1)
local TAvatar = Instance.new("ImageLabel", AVBox); TAvatar.Size=UDim2.new(0.8,0,0.6,0); TAvatar.Position=UDim2.new(0.1,0,0.1,0); TAvatar.BackgroundTransparency=1; TAvatar.Image="rbxassetid://0"; Library:Corner(TAvatar,100)
local TStatus = Instance.new("TextLabel", AVBox); TStatus.Text="WAITING"; TStatus.Size=UDim2.new(1,0,0,20); TStatus.Position=UDim2.new(0,0,0.8,0); TStatus.BackgroundTransparency=1; TStatus.TextColor3=Color3.fromRGB(150,150,150); TStatus.Font=Enum.Font.GothamBold

-- Input & Grid
local TInput = Instance.new("TextBox", RightT); TInput.Size=UDim2.new(1,0,0,45); TInput.BackgroundColor3=Settings.Theme.Box; TInput.Text=""; TInput.PlaceholderText="Player Name..."; TInput.TextColor3=Color3.new(1,1,1); TInput.Font=Enum.Font.GothamBold; TInput.TextSize=16; Library:Corner(TInput, 8); Library:AddGlow(TInput, Settings.Theme.Gold, 1)
local ActGrid = Instance.new("Frame", RightT); ActGrid.Size=UDim2.new(1,0,0,100); ActGrid.Position=UDim2.new(0,0,0.35,0); ActGrid.BackgroundTransparency=1
local ActLay = Instance.new("UIGridLayout", ActGrid); ActLay.CellSize=UDim2.new(0.48,0,0,45); ActLay.CellPadding=UDim2.new(0.04,0,0.1,0)

local targetPlr = nil
local function GetPlayer(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name:lower() or p.DisplayName:lower():sub(1, #name) == name:lower() then return p end
    end
end
TInput.FocusLost:Connect(function()
    local p = GetPlayer(TInput.Text)
    if p then 
        targetPlr=p; TInput.Text=p.Name; TAvatar.Image=Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150); TStatus.Text="ONLINE"; TStatus.TextColor3=Color3.fromRGB(50,255,100) 
    else 
        targetPlr=nil; TStatus.Text="OFFLINE"; TStatus.TextColor3=Color3.fromRGB(255,50,50) 
    end
end)

local function CreateActBtn(txt, cb)
    local b = Instance.new("TextButton", ActGrid); b.BackgroundColor3=Color3.fromRGB(25,25,30); b.Text=txt; b.TextColor3=Color3.fromRGB(150,150,150); b.Font=Enum.Font.GothamBold; Library:Corner(b,8); Library:AddHover(b)
    local on = false
    b.MouseButton1Click:Connect(function()
        on = not on
        if on then b.BackgroundColor3=Settings.Theme.Gold; b.TextColor3=Color3.new(0,0,0) else b.BackgroundColor3=Color3.fromRGB(25,25,30); b.TextColor3=Color3.fromRGB(150,150,150) end
        cb(on)
    end)
end

-- TARGET ACTIONS
local TrollCon = nil
CreateActBtn("BANG (R15)", function(v)
    if not v then if TrollCon then TrollCon:Disconnect() end return end
    if targetPlr and targetPlr.Character and LocalPlayer.Character then
        TrollCon = RunService.Stepped:Connect(function()
            pcall(function()
                local tHRP = targetPlr.Character.HumanoidRootPart; local mHRP = LocalPlayer.Character.HumanoidRootPart
                local thrust = math.sin(tick()*25)*0.5
                mHRP.CFrame = tHRP.CFrame * CFrame.new(0,0,1.1+thrust)
                mHRP.CFrame = CFrame.lookAt(mHRP.Position, tHRP.Position)
            end)
        end)
    end
end)

CreateActBtn("SPECTATE", function(v)
    if v and targetPlr then workspace.CurrentCamera.CameraSubject = targetPlr.Character.Humanoid else workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid end
end)

local HeadSitCon = nil
CreateActBtn("HEADSIT", function(v)
    if not v then if HeadSitCon then HeadSitCon:Disconnect() end; LocalPlayer.Character.Humanoid.Sit=false; return end
    if targetPlr and targetPlr.Character then
        LocalPlayer.Character.Humanoid.Sit=true
        HeadSitCon = RunService.Heartbeat:Connect(function()
            pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlr.Character.Head.CFrame * CFrame.new(0,1.5,0) end)
        end)
    end
end)

local BackSitCon = nil
CreateActBtn("BACKPACK", function(v)
    if not v then if BackSitCon then BackSitCon:Disconnect() end; LocalPlayer.Character.Humanoid.Sit=false; return end
    if targetPlr and targetPlr.Character then
        LocalPlayer.Character.Humanoid.Sit=true
        BackSitCon = RunService.Heartbeat:Connect(function()
            pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlr.Character.HumanoidRootPart.CFrame * CFrame.new(0,0.5,0.5) * CFrame.Angles(0,math.rad(180),0) end)
        end)
    end
end)

-- SCANNER (RESTORED)
local ScanBox = Instance.new("ScrollingFrame", Page_Target); ScanBox.Size=UDim2.new(1,0,0,180); ScanBox.Position=UDim2.new(0,0,0,180); ScanBox.BackgroundTransparency=1
local ScanList = Instance.new("UIListLayout", ScanBox); ScanList.Padding=UDim.new(0,5)
local ScanBtn = Instance.new("TextButton", Page_Target); ScanBtn.Size=UDim2.new(1,0,0,30); ScanBtn.Position=UDim2.new(0,0,0,370); ScanBtn.BackgroundColor3=Settings.Theme.Gold; ScanBtn.Text="Scan Inventory 🔍"; ScanBtn.Font=Enum.Font.GothamBold; ScanBtn.TextSize=14; Library:Corner(ScanBtn,8)

ScanBtn.MouseButton1Click:Connect(function()
    for _,v in pairs(ScanBox:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    if not targetPlr then return end
    
    local items = {}
    local function scan(loc)
        if not loc then return end
        for _,v in pairs(loc:GetChildren()) do
            if v:IsA("Tool") or (v:IsA("Folder") == false and not v:IsA("Script")) then
                items[v.Name] = (items[v.Name] or 0) + 1
            end
        end
    end
    scan(targetPlr:FindFirstChild("Backpack"))
    if targetPlr.Character then scan(targetPlr.Character) end
    
    for name, count in pairs(items) do
        local row = Instance.new("Frame", ScanBox); row.Size=UDim2.new(1,0,0,30); row.BackgroundTransparency=1
        local txt = Instance.new("TextLabel", row); txt.Size=UDim2.new(0.9,0,1,0); txt.Position=UDim2.new(0.05,0,0,0); txt.Text=name.." x"..count; txt.TextColor3=Settings.Theme.Text; txt.Font=Enum.Font.Gotham; txt.TextXAlignment=Enum.TextXAlignment.Left; txt.BackgroundTransparency=1
    end
end)

--// 9. CONTENT: SETTINGS (RESTORED)
local SetList = Instance.new("UIListLayout", Page_Settings); SetList.Padding=UDim.new(0,15)

CreateSlider(Page_Settings, "Field of View", 70, 120, 70, function(v) workspace.CurrentCamera.FieldOfView=v end, {Name="N/A"})

local Rejoin = Instance.new("TextButton", Page_Settings); Rejoin.Size=UDim2.new(1,0,0,50); Rejoin.BackgroundColor3=Settings.Theme.CrystalRed; Rejoin.Text="Rejoin Server 🔄"; Rejoin.TextColor3=Color3.new(1,1,1); Rejoin.Font=Enum.Font.GothamBold; Rejoin.TextSize=16; Library:Corner(Rejoin,10); Library:AddHover(Rejoin)
Rejoin.MouseButton1Click:Connect(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)

local MenuKey = Instance.new("TextButton", Page_Settings); MenuKey.Size=UDim2.new(1,0,0,50); MenuKey.BackgroundColor3=Settings.Theme.Box; MenuKey.Text="Menu Key: RightControl"; MenuKey.TextColor3=Settings.Theme.Gold; MenuKey.Font=Enum.Font.GothamBold; Library:Corner(MenuKey,10)
MenuKey.MouseButton1Click:Connect(function() 
    MenuKey.Text="..."
    local i = UIS.InputBegan:Wait()
    if i.UserInputType == Enum.UserInputType.Keyboard then Settings.Keys.Menu = i.KeyCode; MenuKey.Text="Menu Key: "..i.KeyCode.Name end
end)

--// 10. CONTENT: CREDITS (RESTORED)
local CreditList = Instance.new("UIListLayout", Page_Credits); CreditList.Padding=UDim.new(0,10)
local function AddCredit(name, role, disc)
    local f = Instance.new("Frame", Page_Credits); f.Size=UDim2.new(1,0,0,60); f.BackgroundColor3=Settings.Theme.Box; Library:Corner(f,10); Library:AddGlow(f, Settings.Theme.Gold, 1)
    local n = Instance.new("TextLabel", f); n.Text=name; n.Size=UDim2.new(1,0,0,20); n.Position=UDim2.new(0,15,0,10); n.BackgroundTransparency=1; n.TextColor3=Settings.Theme.Gold; n.Font=Enum.Font.GothamBold; n.TextXAlignment=Enum.TextXAlignment.Left
    local r = Instance.new("TextLabel", f); r.Text=role; r.Size=UDim2.new(1,0,0,20); r.Position=UDim2.new(0,15,0,30); n.BackgroundTransparency=1; r.TextColor3=Settings.Theme.IceBlue; r.Font=Enum.Font.Gotham; r.TextXAlignment=Enum.TextXAlignment.Left; r.BackgroundTransparency=1
    local copy = Instance.new("TextButton", f); copy.Size=UDim2.new(0,80,0,30); copy.Position=UDim2.new(1,-95,0.5,-15); copy.BackgroundColor3=Settings.Theme.Discord; copy.Text="Discord"; copy.TextColor3=Color3.new(1,1,1); Library:Corner(copy,6)
    copy.MouseButton1Click:Connect(function() setclipboard(disc) end)
end

AddCredit("Neho", "Founder", "nx3ho")
AddCredit("BadShot", "Co-Founder", "8adshot3")
AddCredit("xyth", "Manager", "sc4rlxrd")

print("Spaghetti Mafia Hub v3.0 (Fixed & Restored) Loaded.")
