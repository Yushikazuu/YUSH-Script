-- ╔══════════════════════════════════════════════════════════╗
-- ║          YUSH HUB | STEAL AN EGG SCRIPT V2             ║
-- ║          Keyless | Full Bypass | SAE Optimized          ║
-- ╚══════════════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- ╔══════════════════════════════════════╗
-- ║        STRONG BYPASS LAYER          ║
-- ╚══════════════════════════════════════╝

-- Block anti-cheat remotes
local blockedKeywords = {
    "anticheat","anti_cheat","detect","report","flag","ban",
    "cheatdetect","antifly","antispeed","antiteleport","antiexploit",
    "suspicious","violation","integrity","monitor","check"
}

local function isBlocked(name)
    name = tostring(name):lower()
    for _, kw in ipairs(blockedKeywords) do
        if name:find(kw, 1, true) then return true end
    end
    return false
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "FireServer" or method == "FireAllClients" then
        if isBlocked(self.Name) then return nil end
        if args[1] and isBlocked(tostring(args[1])) then return nil end
    end

    if method == "InvokeServer" then
        if isBlocked(self.Name) then return {} end
    end

    return oldNamecall(self, ...)
end)

-- Velocity spoofer (anti-speed detection)
local spoofVelocity = false
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if spoofVelocity and self == HRP and key == "Velocity" then
        return Vector3.new(0, 0, 0)
    end
    return oldIndex(self, key)
end)

-- Noclip engine
local noclipOn = false
RunService.Stepped:Connect(function()
    if noclipOn and Character then
        for _, p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- Safe teleport (incremental, bypass anti-tp)
local function SafeTP(target, steps, delay)
    steps = steps or 12
    delay = delay or 0.03
    local origin = HRP.CFrame
    for i = 1, steps do
        HRP.CFrame = origin:Lerp(target, i / steps)
        task.wait(delay)
    end
end

-- Anti-AFK engine
local VU = pcall(function() return game:GetService("VirtualUser") end) and game:GetService("VirtualUser")
RunService.Heartbeat:Connect(function()
    pcall(function() LocalPlayer:Move(Vector3.new(0,0,0)) end)
    if VU then pcall(function() VU:CaptureController() end) end
end)

-- Respawn safe re-hook
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HRP = c:WaitForChild("HumanoidRootPart")
    Humanoid = c:WaitForChild("Humanoid")
    noclipOn = false
    spoofVelocity = false
end)

-- ╔══════════════════════════════════════╗
-- ║          CONFIG SYSTEM              ║
-- ╚══════════════════════════════════════╝

local Config = {
    speed = 16,
    jumpPower = 50,
    minRarity = 1,
    minValue = 0,
    targetEgg = "Any",
    autoSteal = false,
    autoHatch = false,
    autoSell = false,
    autoTreadmill = false,
    autoFuse = false,
    autoFavorite = false,
    autoRift = false,
    autoProgress = false,
    autoTrail = false,
    autoBaseUpgrade = false,
    autoTreadmillUpgrade = false,
    autoClaimRewards = false,
    smartHop = false,
    invisPlayer = false,
    invisEgg = false,
    eggESP = false,
    playerESP = false,
    fpsUnlock = false,
    fpsCap = 60,
    keybinds = {},
}

-- ╔══════════════════════════════════════╗
-- ║             UI CONSTANTS            ║
-- ╚══════════════════════════════════════╝

local C = {
    bg       = Color3.fromRGB(13, 13, 20),
    panel    = Color3.fromRGB(20, 20, 32),
    panel2   = Color3.fromRGB(26, 26, 40),
    accent   = Color3.fromRGB(70, 130, 240),
    accentD  = Color3.fromRGB(50, 100, 200),
    text     = Color3.fromRGB(230, 230, 245),
    subtext  = Color3.fromRGB(130, 130, 160),
    togOn    = Color3.fromRGB(70, 130, 240),
    togOff   = Color3.fromRGB(50, 50, 75),
    border   = Color3.fromRGB(45, 45, 70),
    red      = Color3.fromRGB(220, 70, 70),
    gold     = Color3.fromRGB(255, 200, 50),
    green    = Color3.fromRGB(60, 200, 100),
    header   = Color3.fromRGB(16, 16, 26),
}

-- ╔══════════════════════════════════════╗
-- ║             GUI SETUP               ║
-- ╚══════════════════════════════════════╝

pcall(function()
    if LocalPlayer.PlayerGui:FindFirstChild("YushHub") then
        LocalPlayer.PlayerGui.YushHub:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YushHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    ScreenGui.Parent = game.CoreGui
end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- Main window (matches Nocturne V3 proportions)
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 680, 0, 420)
Main.Position = UDim2.new(0.5, -340, 0.5, -210)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = false
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = C.border
MainStroke.Thickness = 1.2

-- Drop shadow
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Position = UDim2.new(0, -10, 0, 8)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.5
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Shadow.Parent = Main
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 12)

-- Clip content inside main
local ClipFrame = Instance.new("Frame")
ClipFrame.Size = UDim2.new(1, 0, 1, 0)
ClipFrame.BackgroundTransparency = 1
ClipFrame.ClipsDescendants = true
ClipFrame.ZIndex = 2
ClipFrame.Parent = Main

-- ╔══════════════════════════════════════╗
-- ║             TOP BAR                 ║
-- ╚══════════════════════════════════════╝

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = C.header
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 3
TopBar.Parent = ClipFrame

-- Logo box (left of title, like Nocturne)
local LogoBox = Instance.new("Frame")
LogoBox.Size = UDim2.new(0, 54, 0, 54)
LogoBox.Position = UDim2.new(0, 14, 0.5, -27)
LogoBox.BackgroundColor3 = C.panel2
LogoBox.BorderSizePixel = 0
LogoBox.ZIndex = 4
LogoBox.Parent = ClipFrame
Instance.new("UICorner", LogoBox).CornerRadius = UDim.new(0, 6)

local LogoStroke = Instance.new("UIStroke", LogoBox)
LogoStroke.Color = C.accent
LogoStroke.Thickness = 1.5

local LogoLabel = Instance.new("TextLabel")
LogoLabel.Text = "🥚"
LogoLabel.TextScaled = true
LogoLabel.BackgroundTransparency = 1
LogoLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
LogoLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
LogoLabel.ZIndex = 5
LogoLabel.Parent = LogoBox

-- Title text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "YUSH HUB"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextColor3 = C.text
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 78, 0, 6)
TitleLabel.Size = UDim2.new(0.5, 0, 0, 18)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 3
TitleLabel.Parent = ClipFrame

local SubLabel = Instance.new("TextLabel")
SubLabel.Text = "STEAL AN EGG SCRIPT V2"
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 11
SubLabel.TextColor3 = C.subtext
SubLabel.BackgroundTransparency = 1
SubLabel.Position = UDim2.new(0, 78, 0, 26)
SubLabel.Size = UDim2.new(0.5, 0, 0, 14)
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.ZIndex = 3
SubLabel.Parent = ClipFrame

-- Separator line
local Divline = Instance.new("Frame")
Divline.Size = UDim2.new(1, 0, 0, 1)
Divline.Position = UDim2.new(0, 0, 0, 44)
Divline.BackgroundColor3 = C.border
Divline.BorderSizePixel = 0
Divline.ZIndex = 3
Divline.Parent = ClipFrame

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = C.subtext
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(1, -36, 0, 0)
CloseBtn.Size = UDim2.new(0, 36, 0, 44)
CloseBtn.ZIndex = 5
CloseBtn.Parent = ClipFrame

CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = C.red end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = C.subtext end)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- Minimize
local MinBtn = Instance.new("TextButton")
MinBtn.Text = "–"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.TextColor3 = C.subtext
MinBtn.BackgroundTransparency = 1
MinBtn.Position = UDim2.new(1, -68, 0, 0)
MinBtn.Size = UDim2.new(0, 32, 0, 44)
MinBtn.ZIndex = 5
MinBtn.Parent = ClipFrame

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local bodyFrame = ClipFrame:FindFirstChild("Body")
    local sidebarFrame = ClipFrame:FindFirstChild("Sidebar")
    if bodyFrame then bodyFrame.Visible = not minimized end
    if sidebarFrame then sidebarFrame.Visible = not minimized end
    TweenService:Create(Main, TweenInfo.new(0.25), {
        Size = minimized and UDim2.new(0, 680, 0, 44) or UDim2.new(0, 680, 0, 420)
    }):Play()
end)

-- Drag
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = inp.Position
        startPos = Main.Position
    end
end)
TopBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║             SIDEBAR TABS            ║
-- ╚══════════════════════════════════════╝

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 100, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = C.panel
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3
Sidebar.Parent = ClipFrame

local SideStroke = Instance.new("UIStroke", Sidebar)
SideStroke.Color = C.border
SideStroke.Thickness = 0
-- right border via frame
local SideBorderR = Instance.new("Frame")
SideBorderR.Size = UDim2.new(0, 1, 1, 0)
SideBorderR.Position = UDim2.new(1, -1, 0, 0)
SideBorderR.BackgroundColor3 = C.border
SideBorderR.BorderSizePixel = 0
SideBorderR.ZIndex = 4
SideBorderR.Parent = Sidebar

local SideList = Instance.new("UIListLayout", Sidebar)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding = UDim.new(0, 1)

local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 8)

-- Tab branding at bottom of sidebar
local SideBrand = Instance.new("TextLabel")
SideBrand.Text = "YUSH HUB"
SideBrand.Font = Enum.Font.GothamBold
SideBrand.TextSize = 9
SideBrand.TextColor3 = C.accent
SideBrand.BackgroundTransparency = 1
SideBrand.Position = UDim2.new(0, 0, 1, -24)
SideBrand.Size = UDim2.new(1, 0, 0, 20)
SideBrand.ZIndex = 4
SideBrand.Parent = Sidebar

-- ╔══════════════════════════════════════╗
-- ║          CONTENT BODY               ║
-- ╚══════════════════════════════════════╝

local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, -100, 1, -45)
Body.Position = UDim2.new(0, 100, 0, 45)
Body.BackgroundTransparency = 1
Body.ClipsDescendants = true
Body.ZIndex = 3
Body.Parent = ClipFrame

-- ╔══════════════════════════════════════╗
-- ║          TAB / PAGE BUILDER         ║
-- ╚══════════════════════════════════════╝

local TABS = {"FARM", "PLAYER", "PREDICTOR", "PROGRESS", "MISC", "SETTINGS"}
local Pages = {}
local TabBtns = {}
local activeTab = nil

for i, tabName in ipairs(TABS) do
    -- Sidebar button
    local btn = Instance.new("TextButton")
    btn.Name = tabName
    btn.Text = tabName
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextColor3 = C.subtext
    btn.BackgroundColor3 = C.panel
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.LayoutOrder = i
    btn.ZIndex = 4
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 0)

    -- Active indicator bar
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 0.6, 0)
    bar.Position = UDim2.new(0, 0, 0.2, 0)
    bar.BackgroundColor3 = C.accent
    bar.BorderSizePixel = 0
    bar.Visible = false
    bar.ZIndex = 5
    bar.Parent = btn

    TabBtns[tabName] = {btn = btn, bar = bar}

    -- Content page — two column layout matching Nocturne
    local page = Instance.new("Frame")
    page.Name = tabName
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ZIndex = 3
    page.Parent = Body
    Pages[tabName] = page

    -- Left column
    local leftCol = Instance.new("ScrollingFrame")
    leftCol.Name = "Left"
    leftCol.Size = UDim2.new(0.5, -1, 1, -10)
    leftCol.Position = UDim2.new(0, 8, 0, 5)
    leftCol.BackgroundTransparency = 1
    leftCol.BorderSizePixel = 0
    leftCol.ScrollBarThickness = 2
    leftCol.ScrollBarImageColor3 = C.accent
    leftCol.CanvasSize = UDim2.new(0,0,0,0)
    leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftCol.ZIndex = 3
    leftCol.Parent = page

    local ll = Instance.new("UIListLayout", leftCol)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding = UDim.new(0, 5)

    -- Column divider
    local colDiv = Instance.new("Frame")
    colDiv.Size = UDim2.new(0, 1, 1, -10)
    colDiv.Position = UDim2.new(0.5, -1, 0, 5)
    colDiv.BackgroundColor3 = C.border
    colDiv.BorderSizePixel = 0
    colDiv.ZIndex = 3
    colDiv.Parent = page

    -- Right column
    local rightCol = Instance.new("ScrollingFrame")
    rightCol.Name = "Right"
    rightCol.Size = UDim2.new(0.5, -9, 1, -10)
    rightCol.Position = UDim2.new(0.5, 2, 0, 5)
    rightCol.BackgroundTransparency = 1
    rightCol.BorderSizePixel = 0
    rightCol.ScrollBarThickness = 2
    rightCol.ScrollBarImageColor3 = C.accent
    rightCol.CanvasSize = UDim2.new(0,0,0,0)
    rightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
    rightCol.ZIndex = 3
    rightCol.Parent = page

    local rl = Instance.new("UIListLayout", rightCol)
    rl.SortOrder = Enum.SortOrder.LayoutOrder
    rl.Padding = UDim.new(0, 5)

    btn.MouseButton1Click:Connect(function()
        if activeTab == tabName then return end
        activeTab = tabName
        for name, p in pairs(Pages) do
            p.Visible = (name == tabName)
        end
        for name, t in pairs(TabBtns) do
            if name == tabName then
                t.btn.TextColor3 = C.text
                t.btn.BackgroundTransparency = 0
                t.btn.BackgroundColor3 = C.panel2
                t.bar.Visible = true
            else
                t.btn.TextColor3 = C.subtext
                t.btn.BackgroundTransparency = 1
                t.bar.Visible = false
            end
        end
    end)
end

-- Column getters
local function L(tab) return Pages[tab]:FindFirstChild("Left") end
local function R(tab) return Pages[tab]:FindFirstChild("Right") end

-- ╔══════════════════════════════════════╗
-- ║          UI ELEMENT BUILDERS        ║
-- ╚══════════════════════════════════════╝

-- Section header (like "WEAPON HACKS" / "MEMORY HACKS" in Nocturne)
local function AddHeader(col, text)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = C.subtext
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.ZIndex = 3
    lbl.Parent = col
end

-- Toggle row (matching Nocturne's label + toggle layout)
local function AddToggle(col, label, default, onChange)
    local state = default or false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 32)
    row.BackgroundTransparency = 1
    row.ZIndex = 3
    row.Parent = col

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = C.text
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 2, 0, 0)
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = row

    local togBg = Instance.new("Frame")
    togBg.Size = UDim2.new(0, 40, 0, 20)
    togBg.Position = UDim2.new(1, -42, 0.5, -10)
    togBg.BackgroundColor3 = state and C.togOn or C.togOff
    togBg.BorderSizePixel = 0
    togBg.ZIndex = 4
    togBg.Parent = row
    Instance.new("UICorner", togBg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = state and UDim2.new(0, 23, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = togBg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 6
    btn.Parent = row

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(togBg, TweenInfo.new(0.18), {BackgroundColor3 = state and C.togOn or C.togOff}):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = state and UDim2.new(0, 23, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
        if onChange then onChange(state) end
    end)

    return {frame = row, getState = function() return state end}
end

-- Slider row
local function AddSlider(col, label, min, max, default, fmt, onChange)
    local val = default
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -4, 0, 44)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 3
    frame.Parent = col

    local lbl = Instance.new("TextLabel")
    lbl.Text = label .. ": " .. (fmt and string.format(fmt, val) or val)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = C.text
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 2, 0, 0)
    lbl.Size = UDim2.new(1, -4, 0, 20)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -4, 0, 6)
    track.Position = UDim2.new(0, 2, 0, 28)
    track.BackgroundColor3 = C.togOff
    track.BorderSizePixel = 0
    track.ZIndex = 4
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local sliding = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lbl.Text = label .. ": " .. (fmt and string.format(fmt, val) or val)
            if onChange then onChange(val) end
        end
    end)
end

-- Button
local function AddButton(col, label, onClick)
    local btn = Instance.new("TextButton")
    btn.Text = label
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = C.text
    btn.BackgroundColor3 = C.accentD
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, -4, 0, 28)
    btn.ZIndex = 4
    btn.Parent = col
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.accentD}):Play()
    end)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- Dropdown
local function AddDropdown(col, label, options, default, onChange)
    local selected = default or options[1]
    local open = false

    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, -4, 0, 28)
    wrapper.BackgroundTransparency = 1
    wrapper.ZIndex = 10
    wrapper.ClipsDescendants = false
    wrapper.Parent = col

    local lbl = Instance.new("TextLabel")
    lbl.Text = label
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = C.subtext
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 10
    lbl.Parent = wrapper

    local btn = Instance.new("TextButton")
    btn.Text = selected .. " ▾"
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.TextColor3 = C.text
    btn.BackgroundColor3 = C.panel2
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0.4, 2, 0, 2)
    btn.Size = UDim2.new(0.6, -2, 1, -4)
    btn.ZIndex = 11
    btn.Parent = wrapper
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local dropFrame = Instance.new("Frame")
    dropFrame.BackgroundColor3 = C.panel2
    dropFrame.BorderSizePixel = 0
    dropFrame.Position = UDim2.new(0.4, 2, 1, 2)
    dropFrame.Size = UDim2.new(0.6, -2, 0, #options * 24)
    dropFrame.Visible = false
    dropFrame.ZIndex = 20
    dropFrame.Parent = wrapper
    Instance.new("UICorner", dropFrame).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", dropFrame).Color = C.border

    local dList = Instance.new("UIListLayout", dropFrame)
    dList.SortOrder = Enum.SortOrder.LayoutOrder

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Text = opt
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 11
        optBtn.TextColor3 = opt == selected and C.accent or C.text
        optBtn.BackgroundTransparency = 1
        optBtn.Size = UDim2.new(1, 0, 0, 24)
        optBtn.LayoutOrder = i
        optBtn.ZIndex = 21
        optBtn.Parent = dropFrame

        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            btn.Text = opt .. " ▾"
            dropFrame.Visible = false
            open = false
            for _, child in pairs(dropFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = child.Text == opt and C.accent or C.text
                end
            end
            if onChange then onChange(opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function()
        open = not open
        dropFrame.Visible = open
    end)
end

-- Info label
local function AddInfo(col, text)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = C.subtext
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -4, 0, 18)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3
    lbl.Parent = col
    return lbl
end

-- ╔══════════════════════════════════════╗
-- ║         HELPER: FIND THINGS         ║
-- ╚══════════════════════════════════════╝

local function findRemote(name, rtype)
    rtype = rtype or "RemoteEvent"
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA(rtype) and v.Name:lower():find(name:lower(), 1, true) then
            return v
        end
    end
    return nil
end

local function getEggs()
    local eggs = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name:lower():find("egg") and v:IsA("Model") or v:IsA("BasePart") then
            table.insert(eggs, v)
        end
    end
    return eggs
end

local function getClosestEgg()
    local closest, dist = nil, math.huge
    for _, egg in pairs(getEggs()) do
        local pos = egg:IsA("Model") and egg:GetModelCFrame().Position or egg.Position
        local d = (HRP.Position - pos).Magnitude
        if d < dist then dist = d; closest = egg end
    end
    return closest, dist
end

local function getPlayers()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p) end
    end
    return list
end

-- Rarity map (common SAE rarity names)
local RarityOrder = {
    ["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3,
    ["Epic"] = 4, ["Legendary"] = 5, ["Mythical"] = 6,
    ["Godly"] = 7, ["Exclusive"] = 8
}

local function getRarity(egg)
    -- Try to read rarity from egg attributes or children
    local attr = egg:GetAttribute("Rarity") or egg:GetAttribute("rarity")
    if attr then return attr end
    local rl = egg:FindFirstChild("Rarity") or egg:FindFirstChild("rarity")
    if rl and rl:IsA("StringValue") then return rl.Value end
    return "Unknown"
end

-- ╔══════════════════════════════════════╗
-- ║          FARM TAB FEATURES          ║
-- ╚══════════════════════════════════════╝

-- Left: Auto Steal controls
AddHeader(L("FARM"), "AUTO STEAL")

local autoStealActive = false
local stealLoop

AddToggle(L("FARM"), "AUTO STEAL EGG", false, function(state)
    autoStealActive = state
    Config.autoSteal = state
    spoofVelocity = state
    if state then
        stealLoop = task.spawn(function()
            while autoStealActive do
                local egg, dist = getClosestEgg()
                if egg then
                    local pos = egg:IsA("Model") and egg:GetModelCFrame() or egg.CFrame
                    -- Walk close first then interact
                    if dist > 6 then
                        SafeTP(pos * CFrame.new(0, 0, 4), 6, 0.02)
                    end
                    -- Try fire steal remote
                    local stealRemote = findRemote("steal") or findRemote("grab") or findRemote("collect")
                    if stealRemote then
                        pcall(function() stealRemote:FireServer(egg) end)
                    end
                    -- Also try proximity prompt
                    local pp = egg:FindFirstChildOfClass("ProximityPrompt")
                    if pp then
                        pcall(function()
                            fireproximityprompt(pp)
                        end)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end)

AddToggle(L("FARM"), "INSTANT STEAL", false, function(state)
    -- Hook proximity prompt to fire instantly
    if state then
        for _, pp in pairs(Workspace:GetDescendants()) do
            if pp:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(pp) end)
            end
        end
        Workspace.DescendantAdded:Connect(function(d)
            if state and d:IsA("ProximityPrompt") then
                task.wait(0.05)
                pcall(function() fireproximityprompt(d) end)
            end
        end)
    end
end)

AddSlider(L("FARM"), "Steal Range", 5, 100, 20, "%d studs", function(v)
    Config.stealRange = v
end)

AddDropdown(L("FARM"), "Target Egg", {"Any","Rare+","Epic+","Legendary+","Mythical+","Godly+"}, "Any", function(v)
    Config.targetEgg = v
end)

AddSlider(L("FARM"), "Min Rarity Tier", 1, 8, 1, "Tier %d", function(v)
    Config.minRarity = v
end)

AddButton(L("FARM"), "STEAL CLOSEST EGG NOW", function()
    local egg, dist = getClosestEgg()
    if egg then
        local pos = egg:IsA("Model") and egg:GetModelCFrame() or egg.CFrame
        SafeTP(pos * CFrame.new(0, 0, 3), 8, 0.025)
        local stealRemote = findRemote("steal") or findRemote("grab") or findRemote("collect")
        if stealRemote then pcall(function() stealRemote:FireServer(egg) end) end
        local pp = egg:FindFirstChildOfClass("ProximityPrompt")
        if pp then pcall(function() fireproximityprompt(pp) end) end
    end
end)

-- Right: Auto progression tools
AddHeader(R("FARM"), "AUTO TOOLS")

AddToggle(R("FARM"), "AUTO HATCH & EQUIP", false, function(state)
    Config.autoHatch = state
    if state then
        task.spawn(function()
            while Config.autoHatch do
                local hatchRemote = findRemote("hatch") or findRemote("open")
                local equipRemote = findRemote("equip")
                if hatchRemote then pcall(function() hatchRemote:FireServer() end) end
                if equipRemote then pcall(function() equipRemote:FireServer() end) end
                task.wait(1)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO TREADMILL", false, function(state)
    Config.autoTreadmill = state
    if state then
        task.spawn(function()
            while Config.autoTreadmill do
                local treadRemote = findRemote("treadmill") or findRemote("tread") or findRemote("run")
                if treadRemote then pcall(function() treadRemote:FireServer() end) end
                local treadObj = Workspace:FindFirstChild("Treadmill", true)
                if treadObj then
                    local pp = treadObj:FindFirstChildOfClass("ProximityPrompt")
                    if pp then pcall(function() fireproximityprompt(pp) end) end
                    if (HRP.Position - treadObj.Position).Magnitude > 8 then
                        SafeTP(CFrame.new(treadObj.Position + Vector3.new(0, 3, 0)), 6, 0.02)
                    end
                end
                task.wait(0.8)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO PET SELLING", false, function(state)
    Config.autoSell = state
    if state then
        task.spawn(function()
            while Config.autoSell do
                local sellRemote = findRemote("sell") or findRemote("trade")
                if sellRemote then pcall(function() sellRemote:FireServer() end) end
                task.wait(1.5)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO FUSE", false, function(state)
    Config.autoFuse = state
    if state then
        task.spawn(function()
            while Config.autoFuse do
                local fuseRemote = findRemote("fuse") or findRemote("combine") or findRemote("merge")
                if fuseRemote then pcall(function() fuseRemote:FireServer() end) end
                task.wait(2)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO FAVORITE PETS", false, function(state)
    Config.autoFavorite = state
    if state then
        task.spawn(function()
            while Config.autoFavorite do
                local favRemote = findRemote("favorite") or findRemote("fav")
                if favRemote then pcall(function() favRemote:FireServer() end) end
                task.wait(2)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO RIFT/BOSS FARM", false, function(state)
    Config.autoRift = state
    if state then
        task.spawn(function()
            while Config.autoRift do
                local riftRemote = findRemote("rift") or findRemote("boss") or findRemote("raid")
                if riftRemote then pcall(function() riftRemote:FireServer() end) end
                -- Teleport to rift if found
                local rift = Workspace:FindFirstChild("Rift", true) or Workspace:FindFirstChild("Boss", true)
                if rift then
                    SafeTP(CFrame.new(rift.Position + Vector3.new(0, 5, 0)), 6, 0.02)
                end
                task.wait(3)
            end
        end)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║         PLAYER TAB FEATURES         ║
-- ╚══════════════════════════════════════╝

AddHeader(L("PLAYER"), "MOVEMENT")

AddToggle(L("PLAYER"), "SPEED BOOST", false, function(state)
    spoofVelocity = state
    Humanoid.WalkSpeed = state and Config.speed or 16
end)

AddSlider(L("PLAYER"), "Walk Speed", 16, 200, 80, "%d", function(v)
    Config.speed = v
    if Humanoid.WalkSpeed > 16 then Humanoid.WalkSpeed = v end
end)

AddToggle(L("PLAYER"), "INFINITE JUMP", false, function(state)
    Config.infJump = state
end)
UserInputService.JumpRequest:Connect(function()
    if Config.infJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

AddSlider(L("PLAYER"), "Jump Power", 50, 500, 100, "%d", function(v)
    Humanoid.JumpPower = v
end)

AddToggle(L("PLAYER"), "NOCLIP", false, function(state)
    noclipOn = state
    if not state then
        for _, p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end)

AddHeader(R("PLAYER"), "STEALTH & ESP")

-- Invisibility (player + egg)
AddToggle(R("PLAYER"), "INVISIBILITY (PLAYER)", false, function(state)
    Config.invisPlayer = state
    for _, part in pairs(Character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.Transparency = state and 1 or 0
        end
    end
    -- Keep HRP visible locally for camera
    if HRP then HRP.Transparency = 1 end
end)

AddToggle(R("PLAYER"), "INVIS EGG (STEAL STEALTH)", false, function(state)
    Config.invisEgg = state
    -- When stealing, make carried egg invisible
    if state then
        for _, v in pairs(Character:GetDescendants()) do
            if v.Name:lower():find("egg") then
                if v:IsA("BasePart") then v.Transparency = 1 end
            end
        end
    end
end)

-- Player ESP
local espConnections = {}
AddToggle(R("PLAYER"), "PLAYER ESP", false, function(state)
    Config.playerESP = state
    for _, c in pairs(espConnections) do c:Disconnect() end
    espConnections = {}

    if state then
        local function drawESP(plr)
            if plr == LocalPlayer then return end
            local conn = RunService.RenderStepped:Connect(function()
                if not Config.playerESP then return end
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local pHRP = plr.Character.HumanoidRootPart
                    local existing = pHRP:FindFirstChild("_ESP")
                    if not existing then
                        local box = Instance.new("SelectionBox")
                        box.Name = "_ESP"
                        box.Adornee = plr.Character
                        box.Color3 = Color3.fromRGB(70, 130, 240)
                        box.LineThickness = 0.05
                        box.SurfaceTransparency = 0.8
                        box.SurfaceColor3 = Color3.fromRGB(70, 130, 240)
                        box.Parent = pHRP
                    end
                end
            end)
            table.insert(espConnections, conn)
        end
        for _, p in pairs(Players:GetPlayers()) do drawESP(p) end
        Players.PlayerAdded:Connect(drawESP)
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v.Name == "_ESP" then v:Destroy() end
                end
            end
        end
    end
end)

-- Egg ESP
AddToggle(R("PLAYER"), "EGG ESP", false, function(state)
    Config.eggESP = state
    task.spawn(function()
        while Config.eggESP do
            for _, egg in pairs(getEggs()) do
                if not egg:FindFirstChild("_EggESP") then
                    local hl = Instance.new("SelectionBox")
                    hl.Name = "_EggESP"
                    hl.Adornee = egg
                    hl.Color3 = Color3.fromRGB(255, 200, 50)
                    hl.LineThickness = 0.04
                    hl.SurfaceTransparency = 0.85
                    hl.SurfaceColor3 = Color3.fromRGB(255, 200, 50)
                    hl.Parent = egg
                end
            end
            task.wait(1)
        end
        -- Cleanup
        for _, egg in pairs(getEggs()) do
            local hl = egg:FindFirstChild("_EggESP")
            if hl then hl:Destroy() end
        end
    end)
end)

AddToggle(R("PLAYER"), "ANTI HIT", false, function(state)
    -- Simulate anti-hit by making character non-collidable to projectiles
    if state then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = false
            end
        end
    else
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanTouch = true
            end
        end
    end
end)

AddToggle(R("PLAYER"), "ANTI TRAP", false, function(state)
    if state then
        task.spawn(function()
            while Config.antiTrap do
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v.Name:lower():find("trap") and v:IsA("BasePart") then
                        v.CanTouch = false
                    end
                end
                task.wait(0.5)
            end
        end)
    end
    Config.antiTrap = state
end)

AddToggle(R("PLAYER"), "ANTI RAGDOLL", false, function(state)
    if state then
        task.spawn(function()
            while Config.antiRagdoll do
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                task.wait(0.3)
            end
        end)
    end
    Config.antiRagdoll = state
end)

-- ╔══════════════════════════════════════╗
-- ║       PREDICTOR TAB FEATURES        ║
-- ╚══════════════════════════════════════╝

AddHeader(L("PREDICTOR"), "EGG PREDICTOR")

local predResultLabel = AddInfo(L("PREDICTOR"), "Predict: —")

AddButton(L("PREDICTOR"), "PREDICT CLOSEST EGG", function()
    local egg, dist = getClosestEgg()
    if egg then
        local rarity = getRarity(egg)
        local val = egg:GetAttribute("Value") or egg:GetAttribute("value") or "?"
        local name = egg.Name
        predResultLabel.Text = string.format("Egg: %s | Rarity: %s | Val: %s", name, rarity, tostring(val))
        predResultLabel.TextColor3 = C.gold
    else
        predResultLabel.Text = "No egg found nearby."
    end
end)

AddToggle(L("PREDICTOR"), "EGG PREVIEW CARD (AUTO)", false, function(state)
    if state then
        task.spawn(function()
            while Config.eggPreview do
                local egg, _ = getClosestEgg()
                if egg then
                    local rarity = getRarity(egg)
                    local val = egg:GetAttribute("Value") or "?"
                    predResultLabel.Text = string.format("[LIVE] %s | %s | Val:%s", egg.Name, rarity, tostring(val))
                end
                task.wait(0.5)
            end
        end)
    end
    Config.eggPreview = state
end)

AddButton(L("PREDICTOR"), "SCAN ALL EGGS IN MAP", function()
    local eggs = getEggs()
    predResultLabel.Text = string.format("Found %d eggs in workspace.", #eggs)
end)

AddHeader(R("PREDICTOR"), "RIFT & FUSE PREDICTOR")

local riftLabel = AddInfo(R("PREDICTOR"), "Rift Outcome: —")

AddButton(R("PREDICTOR"), "PREDICT RIFT SPAWN", function()
    -- Read rift seed/timer attributes if present
    local rift = Workspace:FindFirstChild("Rift", true)
    if rift then
        local timer = rift:GetAttribute("Timer") or rift:GetAttribute("SpawnTimer") or "?"
        local reward = rift:GetAttribute("Reward") or rift:GetAttribute("reward") or "?"
        riftLabel.Text = string.format("Rift in: %s | Drop: %s", tostring(timer), tostring(reward))
    else
        riftLabel.Text = "No rift detected in workspace."
    end
end)

local fuseLabel = AddInfo(R("PREDICTOR"), "Fuse Outcome: —")

AddButton(R("PREDICTOR"), "PREDICT FUSE OUTCOME", function()
    -- Read fuse table from ReplicatedStorage if exists
    local fuseTable = ReplicatedStorage:FindFirstChild("FuseData", true) or ReplicatedStorage:FindFirstChild("Combinations", true)
    if fuseTable then
        fuseLabel.Text = "Fuse data found: " .. fuseTable.Name
    else
        fuseLabel.Text = "Fuse: No data table found."
    end
end)

AddToggle(R("PREDICTOR"), "RIFT RECIPE EGG PRIORITY", false, function(state)
    Config.riftPriority = state
end)

AddToggle(R("PREDICTOR"), "EGG SPAWN PREDICTOR", false, function(state)
    Config.spawnPredict = state
    if state then
        task.spawn(function()
            while Config.spawnPredict do
                local eggs = getEggs()
                predResultLabel.Text = string.format("[SCAN] %d eggs live in map.", #eggs)
                task.wait(2)
            end
        end)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║        PROGRESS TAB FEATURES        ║
-- ╚══════════════════════════════════════╝

AddHeader(L("PROGRESS"), "AUTO PROGRESSION")

AddToggle(L("PROGRESS"), "AUTO PROGRESSION", false, function(state)
    Config.autoProgress = state
    if state then
        task.spawn(function()
            while Config.autoProgress do
                local progRemote = findRemote("progress") or findRemote("advance") or findRemote("quest")
                if progRemote then pcall(function() progRemote:FireServer() end) end
                task.wait(3)
            end
        end)
    end
end)

AddToggle(L("PROGRESS"), "AUTO CLAIM REWARDS", false, function(state)
    Config.autoClaimRewards = state
    if state then
        task.spawn(function()
            while Config.autoClaimRewards do
                local claimRemote = findRemote("claim") or findRemote("reward") or findRemote("daily")
                if claimRemote then pcall(function() claimRemote:FireServer() end) end
                task.wait(5)
            end
        end)
    end
end)

AddToggle(L("PROGRESS"), "AUTO BASE UPGRADE", false, function(state)
    Config.autoBaseUpgrade = state
    if state then
        task.spawn(function()
            while Config.autoBaseUpgrade do
                local upgrRemote = findRemote("upgrade") or findRemote("base")
                if upgrRemote then pcall(function() upgrRemote:FireServer() end) end
                task.wait(4)
            end
        end)
    end
end)

AddToggle(L("PROGRESS"), "AUTO TREADMILL UPGRADE", false, function(state)
    Config.autoTreadmillUpgrade = state
    if state then
        task.spawn(function()
            while Config.autoTreadmillUpgrade do
                local tUpgr = findRemote("treadmillupgrade") or findRemote("upgradeTreadmill")
                if tUpgr then pcall(function() tUpgr:FireServer() end) end
                task.wait(4)
            end
        end)
    end
end)

AddToggle(L("PROGRESS"), "AUTO TRAIL BUYING", false, function(state)
    Config.autoTrail = state
    if state then
        task.spawn(function()
            while Config.autoTrail do
                local trailRemote = findRemote("trail") or findRemote("buytrail")
                if trailRemote then pcall(function() trailRemote:FireServer() end) end
                task.wait(5)
            end
        end)
    end
end)

AddHeader(R("PROGRESS"), "SERVER TOOLS")

AddToggle(R("PROGRESS"), "SMART SERVER HOP", false, function(state)
    Config.smartHop = state
    if state then
        task.spawn(function()
            while Config.smartHop do
                task.wait(30)
                if Config.smartHop then
                    pcall(function()
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end)
                end
            end
        end)
    end
end)

local jobLabel = AddInfo(R("PROGRESS"), "Job ID: " .. game.JobId)

AddButton(R("PROGRESS"), "COPY JOB ID", function()
    setclipboard(game.JobId)
    jobLabel.Text = "Job ID copied!"
    task.delay(2, function() jobLabel.Text = "Job ID: " .. game.JobId end)
end)

AddButton(R("PROGRESS"), "REJOIN SERVER", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

AddButton(R("PROGRESS"), "HOP TO NEW SERVER", function()
    local servers = {}
    local ok, pages = pcall(function()
        return game:GetService("HttpService"):JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=25")
        )
    end)
    if ok and pages and pages.data then
        for _, s in ipairs(pages.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                table.insert(servers, s.id)
            end
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    else
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║          MISC TAB FEATURES          ║
-- ╚══════════════════════════════════════╝

AddHeader(L("MISC"), "PERFORMANCE")

-- FPS display overlay
local fpsLabel = AddInfo(L("MISC"), "FPS: — | Ping: —")
local fpsCount = 0
local lastFps = tick()

RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    if tick() - lastFps >= 1 then
        local fps = fpsCount
        local ping = LocalPlayer:GetNetworkPing and math.floor(LocalPlayer:GetNetworkPing() * 1000) or 0
        fpsLabel.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
        fpsCount = 0
        lastFps = tick()
    end
end)

AddToggle(L("MISC"), "FPS UNLOCKER", false, function(state)
    pcall(function() setfpscap(state and 0 or 60) end)
end)

AddSlider(L("MISC"), "FPS Cap", 30, 240, 60, "%d fps", function(v)
    pcall(function() setfpscap(v) end)
end)

AddToggle(L("MISC"), "ANTI-AFK", true, function(state)
    -- handled by top-level heartbeat; this is visual
end)

AddHeader(L("MISC"), "KEYBINDS")

local keybindLabel = AddInfo(L("MISC"), "RightShift = Toggle UI")
AddInfo(L("MISC"), "Delete = Emergency Close")

-- Search bar (filter feature names)
AddHeader(R("MISC"), "SEARCH FEATURES")

local searchBox = Instance.new("TextBox")
searchBox.PlaceholderText = "Search features..."
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 12
searchBox.TextColor3 = C.text
searchBox.PlaceholderColor3 = C.subtext
searchBox.BackgroundColor3 = C.panel2
searchBox.BorderSizePixel = 0
searchBox.Size = UDim2.new(1, -4, 0, 28)
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 4
searchBox.Parent = R("MISC")
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 5)
local searchPad = Instance.new("UIPadding", searchBox)
searchPad.PaddingLeft = UDim.new(0, 8)

local searchResults = AddInfo(R("MISC"), "Type to search features.")

local allFeatureNames = {
    "Auto Steal Egg","Instant Steal","Auto Hatch","Auto Treadmill","Auto Pet Selling",
    "Auto Fuse","Auto Favorite","Auto Rift","Speed Boost","Infinite Jump","Invisibility",
    "Anti Hit","Anti Trap","Anti Ragdoll","Player ESP","Egg ESP","Egg Predictor",
    "Rift Predictor","Fuse Predictor","Auto Progression","Auto Claim Rewards",
    "Auto Base Upgrade","Auto Trail","Smart Server Hop","FPS Unlocker","Anti-AFK"
}

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = searchBox.Text:lower()
    if query == "" then
        searchResults.Text = "Type to search features."
        return
    end
    local found = {}
    for _, name in ipairs(allFeatureNames) do
        if name:lower():find(query, 1, true) then
            table.insert(found, name)
        end
    end
    if #found == 0 then
        searchResults.Text = "No matches."
    else
        searchResults.Text = table.concat(found, "\n")
        searchResults.Size = UDim2.new(1, -4, 0, #found * 16 + 4)
    end
end)

-- ╔══════════════════════════════════════╗
-- ║        SETTINGS TAB FEATURES        ║
-- ╚══════════════════════════════════════╝

AddHeader(L("SETTINGS"), "UI SETTINGS")

AddToggle(L("SETTINGS"), "DARK MODE (DEFAULT)", true, function(state)
    if not state then
        Main.BackgroundColor3 = Color3.fromRGB(230, 230, 240)
    else
        Main.BackgroundColor3 = C.bg
    end
end)

AddToggle(L("SETTINGS"), "SHOW FPS OVERLAY", true, function(state)
    fpsLabel.Visible = state
end)

AddToggle(L("SETTINGS"), "COMPACT MODE", false, function(state)
    if state then
        TweenService:Create(Main, TweenInfo.new(0.25), {Size = UDim2.new(0, 580, 0, 360)}):Play()
    else
        TweenService:Create(Main, TweenInfo.new(0.25), {Size = UDim2.new(0, 680, 0, 420)}):Play()
    end
end)

AddHeader(R("SETTINGS"), "BYPASS SETTINGS")

AddToggle(R("SETTINGS"), "VELOCITY SPOOFER", true, function(state)
    spoofVelocity = state
end)

AddToggle(R("SETTINGS"), "REMOTE BLOCKER", true, function(state)
    -- visual indicator; hook is always active
end)

AddButton(R("SETTINGS"), "NUKE ANTI-CHEAT REMOTES", function()
    local count = 0
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and isBlocked(v.Name) then
            pcall(function() v:Destroy() end)
            count = count + 1
        end
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and isBlocked(v.Name) then
            pcall(function() v:Destroy() end)
            count = count + 1
        end
    end
end)

AddButton(R("SETTINGS"), "SAVE CONFIG", function()
    pcall(function()
        writefile("YushHub_Config.json", HttpService:JSONEncode(Config))
    end)
end)

AddButton(R("SETTINGS"), "LOAD CONFIG", function()
    pcall(function()
        if isfile("YushHub_Config.json") then
            local loaded = HttpService:JSONDecode(readfile("YushHub_Config.json"))
            for k, v in pairs(loaded) do Config[k] = v end
        end
    end)
end)

AddButton(R("SETTINGS"), "RESET ALL", function()
    for _, page in pairs(Pages) do
        for _, col in pairs(page:GetChildren()) do
            if col:IsA("ScrollingFrame") then
                for _, elem in pairs(col:GetChildren()) do
                    if elem:IsA("Frame") then elem:Destroy() end
                end
            end
        end
    end
end)

-- ╔══════════════════════════════════════╗
-- ║        GLOBAL KEYBINDS              ║
-- ╚══════════════════════════════════════╝

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
    if inp.KeyCode == Enum.KeyCode.Delete then
        ScreenGui:Destroy()
    end
end)

-- ╔══════════════════════════════════════╗
-- ║          OPEN DEFAULT TAB           ║
-- ╚══════════════════════════════════════╝

TabBtns["FARM"].btn.MouseButton1Click:Fire()

print("[Yush Hub] Loaded | SAE Script V2 | RightShift to toggle | Delete to close")
