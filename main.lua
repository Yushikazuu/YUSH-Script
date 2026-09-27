--[[
  ╔══════════════════════════════════════════════════╗
  ║   YUSH HUB V3  |  STEAL AN EGG EDITION          ║
  ║   Made by https://t.me/PrimeYush :)              ║
  ║   Credits to @YushPogi                           ║
  ╚══════════════════════════════════════════════════╝
  IC BUTTON: Click [ › ] pill on the left to open menu
  Keybinds : RightShift = toggle | Delete = nuke gui
]]

-- ═══════════════════════════════════════════════════
--  POLYFILLS
-- ═══════════════════════════════════════════════════
if not hookmetamethod then hookmetamethod = function() return function(...) return ... end end end
if not getnamecallmethod then getnamecallmethod = function() return "" end end
if not fireproximityprompt then
    fireproximityprompt = function(pp)
        pcall(function() pp.Triggered:Fire(game.Players.LocalPlayer) end)
    end
end
if not setfpscap   then setfpscap   = function() end end
if not writefile   then writefile   = function() end end
if not readfile    then readfile    = function() return "{}" end end
if not isfile      then isfile      = function() return false end end
if not setclipboard then setclipboard = function() end end
if not syn         then syn = { protect_gui = function() end } end

-- ═══════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local Workspace        = game:GetService("Workspace")
local LocalPlayer      = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP       = Character:WaitForChild("HumanoidRootPart")
local Humanoid  = Character:WaitForChild("Humanoid")

-- ═══════════════════════════════════════════════════
--  ANTI-BAN CORE
-- ═══════════════════════════════════════════════════
local spoofVelocity = true

-- Keywords used by anti-cheat remotes / server scripts
local blockedKW = {
    "anticheat","anti_cheat","antiexploit","antifly","antispeed",
    "antiteleport","antijump","ban","bac","detect","report","flag",
    "cheatdetect","suspicious","violation","integrity","monitor",
    "check","exploit","hack","speedhack","teleportcheck"
}
local function isBlocked(name)
    name = tostring(name):lower()
    for _, kw in ipairs(blockedKW) do
        if name:find(kw, 1, true) then return true end
    end
    return false
end

-- Per-remote rate tracker to avoid suspicious fire bursts
local _rateTbl = {}
local RATE_CAP  = 6
local function rateLimited(remote)
    local now = tick()
    local id  = tostring(remote)
    _rateTbl[id] = _rateTbl[id] or {}
    local t = _rateTbl[id]
    for i = #t, 1, -1 do if now - t[i] > 1 then table.remove(t, i) end end
    if #t >= RATE_CAP then return true end
    table.insert(t, now)
    return false
end

-- Hook __namecall: block AC remotes + add micro-jitter to fire timing
pcall(function()
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args   = {...}
        if method == "FireServer" or method == "InvokeServer" then
            if isBlocked(self.Name) then
                return method == "InvokeServer" and {} or nil
            end
            if args[1] and isBlocked(tostring(args[1])) then
                return method == "InvokeServer" and {} or nil
            end
            if rateLimited(self) then
                task.wait(math.random(60, 180) / 1000)
            end
        end
        return oldNC(self, ...)
    end)
end)

-- Hook __index: spoof Velocity + AssemblyLinearVelocity to zero
pcall(function()
    local oldIdx
    oldIdx = hookmetamethod(game, "__index", function(self, key)
        if spoofVelocity and self == HRP then
            if key == "Velocity" or key == "AssemblyLinearVelocity" then
                return Vector3.new(0, 0, 0)
            end
            if key == "AssemblyAngularVelocity" then
                return Vector3.new(0, 0, 0)
            end
        end
        return oldIdx(self, key)
    end)
end)

-- Noclip loop
local noclipOn = false
RunService.Stepped:Connect(function()
    if noclipOn and Character then
        for _, p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- Anti-AFK heartbeat
local VU = pcall(function() return game:GetService("VirtualUser") end)
     and game:GetService("VirtualUser")
RunService.Heartbeat:Connect(function()
    pcall(function() LocalPlayer:Move(Vector3.new(0, 0, 0)) end)
    if VU then pcall(function() VU:CaptureController() end) end
end)

-- State masking helper
local function maskStates()
    pcall(function()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,  false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead,         false)
    end)
end
maskStates()

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HRP       = c:WaitForChild("HumanoidRootPart")
    Humanoid  = c:WaitForChild("Humanoid")
    noclipOn  = false
    task.wait(0.5)
    maskStates()
end)

-- ═══════════════════════════════════════════════════
--  SMART TELEPORT (ease-in-out + micro-jitter)
-- ═══════════════════════════════════════════════════
local function jit() return math.random(-8, 8) / 100 end  -- subtle path noise

local function SafeTP(targetCF, steps, delay)
    steps = steps or 20
    delay = delay or 0.022
    local origin = HRP.CFrame
    for i = 1, steps do
        local t = i / steps
        local ease = t < 0.5 and (2 * t * t) or (-1 + (4 - 2*t) * t)  -- ease in-out
        local mid  = origin:Lerp(targetCF, ease)
        mid = mid * CFrame.new(jit(), 0, jit())
        HRP.CFrame = mid
        task.wait(delay)
    end
    HRP.CFrame = targetCF
end

local function NaturalApproach(targetPos, approachDist)
    approachDist = approachDist or 4
    local dist = (HRP.Position - targetPos).Magnitude
    if dist <= approachDist then return end

    local goal = CFrame.new(targetPos + (HRP.Position - targetPos).Unit * approachDist)

    if dist <= 40 then
        SafeTP(goal, math.max(12, math.floor(dist)), 0.022)
    else
        -- Long distance: two-segment hop to avoid huge delta
        local mid = HRP.Position:Lerp(targetPos, 0.5)
        SafeTP(CFrame.new(mid), 12, 0.022)
        task.wait(0.08 + math.random(1, 6) / 100)
        local dist2 = (HRP.Position - targetPos).Magnitude
        SafeTP(CFrame.new(targetPos + (HRP.Position - targetPos).Unit * approachDist),
               math.max(10, math.floor(dist2)), 0.022)
    end
end

-- ═══════════════════════════════════════════════════
--  REMOTE UTILITIES
-- ═══════════════════════════════════════════════════
local _rCache = {}
local function findRemote(name, rtype)
    rtype = rtype or "RemoteEvent"
    local key = name .. rtype
    if _rCache[key] then return _rCache[key] end
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA(rtype) and v.Name:lower():find(name:lower(), 1, true) then
            _rCache[key] = v; return v
        end
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA(rtype) and v.Name:lower():find(name:lower(), 1, true) then
            _rCache[key] = v; return v
        end
    end
    return nil
end
-- Flush cache every 30s (remotes can change)
task.spawn(function()
    while true do task.wait(30); _rCache = {} end
end)

-- ═══════════════════════════════════════════════════
--  EGG UTILITIES
-- ═══════════════════════════════════════════════════
local RarityOrder = {
    Common=1, Uncommon=2, Rare=3, Epic=4,
    Legendary=5, Mythical=6, Secret=7, Exclusive=8,
}

local function getEggPos(egg)
    local ok, pos = pcall(function()
        local r = egg:FindFirstChild("Root") or egg:FindFirstChildOfClass("BasePart")
        return r and r.Position or egg:GetModelCFrame().Position
    end)
    return ok and pos or nil
end

local function getEggs()
    local result = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") then
            local n = v.Name:lower()
            if n:find("egg") or v:GetAttribute("IsEgg") or v:GetAttribute("EggType") then
                if v:FindFirstChildOfClass("BasePart") then
                    table.insert(result, v)
                end
            end
        end
    end
    return result
end

local function getEggRarityTier(egg)
    local r = egg:GetAttribute("Rarity")
             or (egg:FindFirstChild("Rarity") and egg.Rarity.Value)
             or "Common"
    return RarityOrder[r] or 0
end

local function getClosestEgg(minTier)
    minTier = minTier or 1
    local best, bestDist = nil, math.huge
    for _, egg in pairs(getEggs()) do
        local pos = getEggPos(egg)
        if pos then
            local d = (HRP.Position - pos).Magnitude
            if d < bestDist and getEggRarityTier(egg) >= minTier then
                bestDist = d; best = egg
            end
        end
    end
    return best, bestDist
end

-- Core steal: try every method available
local STEAL_REMOTE_NAMES = {
    "StealEgg","PickupEgg","GrabEgg","TakeEgg","CollectEgg","ClaimEgg",
    "SnatchEgg","steal","grab","pickup","collect","take","Steal","Grab",
    "Pickup","Collect","GetEgg","EggSteal","EggPickup","EggGrab",
}
local function tryStealEgg(egg)
    if not egg or not egg.Parent then return end
    local pos = getEggPos(egg)
    if not pos then return end

    -- Method 1: ProximityPrompts (most reliable in SAE)
    local function triggerPrompts(obj)
        for _, d in pairs(obj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                if not isBlocked(d.ActionText) and not isBlocked(d.ObjectText) then
                    pcall(function() fireproximityprompt(d) end)
                end
            end
        end
    end
    triggerPrompts(egg)
    if egg.Parent then triggerPrompts(egg.Parent) end

    -- Method 2: Named steal remotes
    for _, name in ipairs(STEAL_REMOTE_NAMES) do
        local r = findRemote(name)
        if r then
            pcall(function() r:FireServer(egg) end)
            task.wait(0.03)
            pcall(function() r:FireServer() end)
            break
        end
    end

    -- Method 3: Simulate touch to trigger server-side handlers
    local bp = egg:FindFirstChildOfClass("BasePart")
    if bp then
        pcall(function() bp.Touched:Fire(HRP) end)
        pcall(function() HRP.Touched:Fire(bp) end)
    end
end

-- ═══════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════
local Config = {
    speed            = 50,
    jumpPower        = 100,
    minRarity        = 1,
    stealRange       = 80,
    stealDelay       = 0.6,
    autoSteal        = false,
    autoHatch        = false,
    autoSell         = false,
    autoTreadmill    = false,
    autoFuse         = false,
    autoFavorite     = false,
    autoRift         = false,
    autoBaseUpgrade  = false,
    autoTreadUpgrade = false,
    autoClaimRewards = false,
    infJump          = false,
    noclip           = false,
    antiTrap         = false,
    antiRagdoll      = false,
    invisPlayer      = false,
    invisEgg         = false,
    eggESP           = false,
    playerESP        = false,
    fpsCap           = 60,
}

-- ═══════════════════════════════════════════════════
--  COLORS
-- ═══════════════════════════════════════════════════
local C = {
    bg      = Color3.fromRGB(10,  10,  16),
    panel   = Color3.fromRGB(18,  18,  28),
    panel2  = Color3.fromRGB(24,  24,  38),
    accent  = Color3.fromRGB(90,  148, 255),
    accentD = Color3.fromRGB(58,  100, 210),
    text    = Color3.fromRGB(228, 228, 245),
    sub     = Color3.fromRGB(115, 115, 150),
    togOn   = Color3.fromRGB(72,  200, 118),
    togOff  = Color3.fromRGB(48,  48,  70),
    border  = Color3.fromRGB(36,  36,  58),
    red     = Color3.fromRGB(220, 70,  70),
    gold    = Color3.fromRGB(255, 200, 50),
    green   = Color3.fromRGB(72,  200, 118),
    header  = Color3.fromRGB(13,  13,  20),
}

-- ═══════════════════════════════════════════════════
--  GUI SETUP
-- ═══════════════════════════════════════════════════
-- Clean up old instances
pcall(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("YushHub") then pg.YushHub:Destroy() end
end)
pcall(function()
    local cg = game:GetService("CoreGui")
    if cg:FindFirstChild("YushHub") then cg.YushHub:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "YushHub"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.IgnoreGuiInset  = true

local ok = false
pcall(function()
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    ScreenGui.Parent = game:GetService("CoreGui")
    ok = true
end)
if not ok then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ───────────────────────────────────────
--  IC PILL  (always visible, left edge)
-- ───────────────────────────────────────
local ICPill = Instance.new("Frame")
ICPill.Name            = "ICPill"
ICPill.Size            = UDim2.new(0, 26, 0, 68)
ICPill.Position        = UDim2.new(0, 0, 0.5, -34)
ICPill.BackgroundColor3= C.accentD
ICPill.BorderSizePixel = 0
ICPill.ZIndex          = 300
ICPill.Parent          = ScreenGui
Instance.new("UICorner", ICPill).CornerRadius = UDim.new(0, 7)

local ICArrow = Instance.new("TextButton")
ICArrow.Text             = "›"
ICArrow.Font             = Enum.Font.GothamBold
ICArrow.TextSize         = 20
ICArrow.TextColor3       = C.text
ICArrow.BackgroundTransparency = 1
ICArrow.Size             = UDim2.new(1, 0, 0, 42)
ICArrow.Position         = UDim2.new(0, 0, 0, 6)
ICArrow.ZIndex           = 301
ICArrow.Parent           = ICPill

local ICTag = Instance.new("TextLabel")
ICTag.Text             = "Y"
ICTag.Font             = Enum.Font.GothamBold
ICTag.TextSize         = 9
ICTag.TextColor3       = C.accent
ICTag.BackgroundTransparency = 1
ICTag.Size             = UDim2.new(1, 0, 0, 14)
ICTag.Position         = UDim2.new(0, 0, 1, -18)
ICTag.ZIndex           = 301
ICTag.Parent           = ICPill

-- IC pill drag
local icDragging, icDragStart, icStartPos
ICPill.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        icDragging  = true
        icDragStart = inp.Position
        icStartPos  = ICPill.Position
    end
end)
ICPill.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then icDragging = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if icDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - icDragStart
        ICPill.Position = UDim2.new(
            icStartPos.X.Scale, icStartPos.X.Offset + d.X,
            icStartPos.Y.Scale, icStartPos.Y.Offset + d.Y
        )
    end
end)

-- ───────────────────────────────────────
--  MAIN FRAME  (hidden by default)
-- ───────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 540, 0, 370)
Main.Position         = UDim2.new(0, 32, 0.5, -185)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel  = 0
Main.ClipsDescendants = false
Main.Visible          = false   -- hidden until IC clicked
Main.ZIndex           = 100
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color     = C.border
mainStroke.Thickness = 1.2

local Shadow = Instance.new("Frame")
Shadow.Size                = UDim2.new(1, 18, 1, 18)
Shadow.Position            = UDim2.new(0, -9, 0, 7)
Shadow.BackgroundColor3    = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.55
Shadow.BorderSizePixel     = 0
Shadow.ZIndex              = 99
Shadow.Parent              = Main
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 12)

-- Clip container (needed to clip scrolling content cleanly)
local Clip = Instance.new("Frame")
Clip.Size               = UDim2.new(1, 0, 1, 0)
Clip.BackgroundTransparency = 1
Clip.ClipsDescendants   = true
Clip.ZIndex             = 101
Clip.Parent             = Main

-- ───────────────────────────────────────
--  TOP BAR
-- ───────────────────────────────────────
local TopBar = Instance.new("Frame")
TopBar.Name             = "TopBar"
TopBar.Size             = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = C.header
TopBar.BorderSizePixel  = 0
TopBar.ZIndex           = 102
TopBar.Parent           = Clip

-- Logo badge (inside TopBar, no layout conflicts)
local LogoBadge = Instance.new("Frame")
LogoBadge.Size             = UDim2.new(0, 30, 0, 30)
LogoBadge.Position         = UDim2.new(0, 10, 0, 5)
LogoBadge.BackgroundColor3 = C.panel2
LogoBadge.BorderSizePixel  = 0
LogoBadge.ZIndex           = 103
LogoBadge.Parent           = TopBar
Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(0, 6)
local logoStroke = Instance.new("UIStroke", LogoBadge)
logoStroke.Color     = C.accent
logoStroke.Thickness = 1.2
local logoTxt = Instance.new("TextLabel")
logoTxt.Text               = "🥚"
logoTxt.TextScaled         = true
logoTxt.BackgroundTransparency = 1
logoTxt.Size               = UDim2.new(0.8, 0, 0.8, 0)
logoTxt.Position           = UDim2.new(0.1, 0, 0.1, 0)
logoTxt.ZIndex             = 104
logoTxt.Parent             = LogoBadge

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Text              = "YUSH HUB"
TitleLbl.Font              = Enum.Font.GothamBold
TitleLbl.TextSize          = 13
TitleLbl.TextColor3        = C.text
TitleLbl.BackgroundTransparency = 1
TitleLbl.Position          = UDim2.new(0, 48, 0, 4)
TitleLbl.Size              = UDim2.new(0, 160, 0, 16)
TitleLbl.TextXAlignment    = Enum.TextXAlignment.Left
TitleLbl.ZIndex            = 103
TitleLbl.Parent            = TopBar

local SubLbl = Instance.new("TextLabel")
SubLbl.Text                = "STEAL AN EGG  •  V3"
SubLbl.Font                = Enum.Font.Gotham
SubLbl.TextSize            = 9
SubLbl.TextColor3          = C.sub
SubLbl.BackgroundTransparency = 1
SubLbl.Position            = UDim2.new(0, 48, 0, 22)
SubLbl.Size                = UDim2.new(0, 160, 0, 14)
SubLbl.TextXAlignment      = Enum.TextXAlignment.Left
SubLbl.ZIndex              = 103
SubLbl.Parent              = TopBar

-- Bypass status indicator
local StatusDot = Instance.new("Frame")
StatusDot.Size             = UDim2.new(0, 6, 0, 6)
StatusDot.Position         = UDim2.new(1, -88, 0.5, -3)
StatusDot.BackgroundColor3 = C.green
StatusDot.BorderSizePixel  = 0
StatusDot.ZIndex           = 103
StatusDot.Parent           = TopBar
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text             = "BYPASS ON"
StatusLbl.Font             = Enum.Font.Gotham
StatusLbl.TextSize         = 9
StatusLbl.TextColor3       = C.green
StatusLbl.BackgroundTransparency = 1
StatusLbl.Position         = UDim2.new(1, -82, 0.5, -6)
StatusLbl.Size             = UDim2.new(0, 76, 0, 12)
StatusLbl.TextXAlignment   = Enum.TextXAlignment.Left
StatusLbl.ZIndex           = 103
StatusLbl.Parent           = TopBar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Text             = "–"
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextSize         = 15
MinBtn.TextColor3       = C.sub
MinBtn.BackgroundTransparency = 1
MinBtn.Position         = UDim2.new(1, -62, 0, 0)
MinBtn.Size             = UDim2.new(0, 28, 0, 40)
MinBtn.ZIndex           = 104
MinBtn.Parent           = TopBar
MinBtn.MouseEnter:Connect(function() MinBtn.TextColor3 = C.text end)
MinBtn.MouseLeave:Connect(function() MinBtn.TextColor3 = C.sub end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
        Size = minimized and UDim2.new(0, 540, 0, 40) or UDim2.new(0, 540, 0, 370)
    }):Play()
    MinBtn.Text = minimized and "□" or "–"
end)

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text             = "✕"
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 11
CloseBtn.TextColor3       = C.sub
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position         = UDim2.new(1, -34, 0, 0)
CloseBtn.Size             = UDim2.new(0, 34, 0, 40)
CloseBtn.ZIndex           = 104
CloseBtn.Parent           = TopBar
CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = C.red end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = C.sub end)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    ICArrow.Text = "›"
end)

-- Topbar divider
local Div = Instance.new("Frame")
Div.Size             = UDim2.new(1, 0, 0, 1)
Div.Position         = UDim2.new(0, 0, 0, 40)
Div.BackgroundColor3 = C.border
Div.BorderSizePixel  = 0
Div.ZIndex           = 102
Div.Parent           = Clip

-- Drag logic
local drag, dragStart, startPos
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true; dragStart = inp.Position; startPos = Main.Position
    end
end)
TopBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                                   startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- IC arrow toggles main menu
local menuOpen = false
ICArrow.MouseButton1Click:Connect(function()
    menuOpen   = not menuOpen
    Main.Visible = menuOpen
    ICArrow.Text = menuOpen and "‹" or "›"
    if menuOpen then
        local p = ICPill.AbsolutePosition
        Main.Position = UDim2.new(0, p.X + 32, 0, math.max(4, p.Y - 150))
    end
end)

-- ═══════════════════════════════════════════════════
--  SIDEBAR + BODY
-- ═══════════════════════════════════════════════════
local Sidebar = Instance.new("Frame")
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0, 82, 1, -41)
Sidebar.Position         = UDim2.new(0, 0, 0, 41)
Sidebar.BackgroundColor3 = C.panel
Sidebar.BorderSizePixel  = 0
Sidebar.ZIndex           = 102
Sidebar.Parent           = Clip

local sideBorderLine = Instance.new("Frame")
sideBorderLine.Size             = UDim2.new(0, 1, 1, 0)
sideBorderLine.Position         = UDim2.new(1, -1, 0, 0)
sideBorderLine.BackgroundColor3 = C.border
sideBorderLine.BorderSizePixel  = 0
sideBorderLine.ZIndex           = 103
sideBorderLine.Parent           = Sidebar

-- UIListLayout for tab buttons ONLY (no other absolute children in sidebar)
local sideList = Instance.new("UIListLayout", Sidebar)
sideList.SortOrder  = Enum.SortOrder.LayoutOrder
sideList.Padding    = UDim.new(0, 0)

local sidePad = Instance.new("UIPadding", Sidebar)
sidePad.PaddingTop = UDim.new(0, 8)

local Body = Instance.new("Frame")
Body.Name               = "Body"
Body.Size               = UDim2.new(1, -82, 1, -41)
Body.Position           = UDim2.new(0, 82, 0, 41)
Body.BackgroundTransparency = 1
Body.ClipsDescendants   = true
Body.ZIndex             = 102
Body.Parent             = Clip

-- ═══════════════════════════════════════════════════
--  TABS
-- ═══════════════════════════════════════════════════
local TABS    = {"FARM", "PLAYER", "BYPASS", "TOOLS", "MISC"}
local ICONS   = {FARM="🥚", PLAYER="⚡", BYPASS="🛡", TOOLS="🔧", MISC="⚙"}
local Pages   = {}
local TabBtns = {}
local activeTab = nil

for i, tabName in ipairs(TABS) do
    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Name             = tabName
    btn.Text             = ""
    btn.BackgroundColor3 = C.panel
    btn.BackgroundTransparency = 1
    btn.Size             = UDim2.new(1, 0, 0, 50)
    btn.LayoutOrder      = i
    btn.ZIndex           = 104
    btn.Parent           = Sidebar

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Text          = ICONS[tabName] or "•"
    iconLbl.TextScaled    = true
    iconLbl.BackgroundTransparency = 1
    iconLbl.Size          = UDim2.new(0, 20, 0, 20)
    iconLbl.Position      = UDim2.new(0.5, -10, 0, 7)
    iconLbl.ZIndex        = 105
    iconLbl.Parent        = btn

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Text          = tabName
    nameLbl.Font          = Enum.Font.GothamBold
    nameLbl.TextSize      = 8
    nameLbl.TextColor3    = C.sub
    nameLbl.BackgroundTransparency = 1
    nameLbl.Size          = UDim2.new(1, 0, 0, 13)
    nameLbl.Position      = UDim2.new(0, 0, 0, 30)
    nameLbl.ZIndex        = 105
    nameLbl.Parent        = btn

    local selBar = Instance.new("Frame")
    selBar.Size             = UDim2.new(0, 3, 0.65, 0)
    selBar.Position         = UDim2.new(0, 0, 0.175, 0)
    selBar.BackgroundColor3 = C.accent
    selBar.BorderSizePixel  = 0
    selBar.Visible          = false
    selBar.ZIndex           = 106
    selBar.Parent           = btn
    Instance.new("UICorner", selBar).CornerRadius = UDim.new(1, 0)

    TabBtns[tabName] = {btn=btn, bar=selBar, name=nameLbl}

    -- Page frame
    local page = Instance.new("Frame")
    page.Name               = tabName
    page.Size               = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible            = false
    page.ZIndex             = 102
    page.Parent             = Body
    Pages[tabName]          = page

    -- Left scrolling column
    local lCol = Instance.new("ScrollingFrame")
    lCol.Name               = "Left"
    lCol.Size               = UDim2.new(0.5, -3, 1, -8)
    lCol.Position           = UDim2.new(0, 6, 0, 4)
    lCol.BackgroundTransparency = 1
    lCol.BorderSizePixel    = 0
    lCol.ScrollBarThickness = 2
    lCol.ScrollBarImageColor3 = C.accent
    lCol.AutomaticCanvasSize= Enum.AutomaticSize.Y
    lCol.CanvasSize         = UDim2.new(0, 0, 0, 0)
    lCol.ZIndex             = 103
    lCol.Parent             = page
    local ll = Instance.new("UIListLayout", lCol)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding   = UDim.new(0, 4)

    -- Column divider
    local cDiv = Instance.new("Frame")
    cDiv.Size             = UDim2.new(0, 1, 1, -8)
    cDiv.Position         = UDim2.new(0.5, -1, 0, 4)
    cDiv.BackgroundColor3 = C.border
    cDiv.BorderSizePixel  = 0
    cDiv.ZIndex           = 103
    cDiv.Parent           = page

    -- Right scrolling column
    local rCol = Instance.new("ScrollingFrame")
    rCol.Name               = "Right"
    rCol.Size               = UDim2.new(0.5, -9, 1, -8)
    rCol.Position           = UDim2.new(0.5, 2, 0, 4)
    rCol.BackgroundTransparency = 1
    rCol.BorderSizePixel    = 0
    rCol.ScrollBarThickness = 2
    rCol.ScrollBarImageColor3 = C.accent
    rCol.AutomaticCanvasSize= Enum.AutomaticSize.Y
    rCol.CanvasSize         = UDim2.new(0, 0, 0, 0)
    rCol.ZIndex             = 103
    rCol.Parent             = page
    local rl = Instance.new("UIListLayout", rCol)
    rl.SortOrder = Enum.SortOrder.LayoutOrder
    rl.Padding   = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        if activeTab == tabName then return end
        activeTab = tabName
        for n, p in pairs(Pages) do p.Visible = (n == tabName) end
        for n, t in pairs(TabBtns) do
            local active = (n == tabName)
            t.btn.BackgroundTransparency = active and 0 or 1
            t.btn.BackgroundColor3       = C.panel2
            t.bar.Visible                = active
            t.name.TextColor3            = active and C.accent or C.sub
        end
    end)
end

local function L(tab) return Pages[tab]:FindFirstChild("Left")  end
local function R(tab) return Pages[tab]:FindFirstChild("Right") end

-- ═══════════════════════════════════════════════════
--  UI COMPONENT BUILDERS
-- ═══════════════════════════════════════════════════
local function AddHeader(col, text)
    local lbl = Instance.new("TextLabel")
    lbl.Text          = "─ " .. text .. " ─"
    lbl.Font          = Enum.Font.GothamBold
    lbl.TextSize      = 9
    lbl.TextColor3    = C.accent
    lbl.BackgroundTransparency = 1
    lbl.Size          = UDim2.new(1, -4, 0, 20)
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    lbl.ZIndex        = 103
    lbl.Parent        = col
    return lbl
end

local function AddInfo(col, text)
    local lbl = Instance.new("TextLabel")
    lbl.Text          = text
    lbl.Font          = Enum.Font.Gotham
    lbl.TextSize      = 10
    lbl.TextColor3    = C.sub
    lbl.BackgroundTransparency = 1
    lbl.Size          = UDim2.new(1, -4, 0, 18)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex        = 103
    lbl.Parent        = col
    return lbl
end

local function AddToggle(col, label, default, onChange)
    local state = default or false
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -4, 0, 30)
    row.BackgroundColor3 = C.panel
    row.BorderSizePixel  = 0
    row.ZIndex           = 103
    row.Parent           = col
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Text          = label
    lbl.Font          = Enum.Font.Gotham
    lbl.TextSize      = 10
    lbl.TextColor3    = state and C.text or C.sub
    lbl.BackgroundTransparency = 1
    lbl.Position      = UDim2.new(0, 8, 0, 0)
    lbl.Size          = UDim2.new(1, -46, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate  = Enum.TextTruncate.AtEnd
    lbl.ZIndex        = 104
    lbl.Parent        = row

    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(0, 30, 0, 15)
    bg.Position         = UDim2.new(1, -36, 0.5, -7)
    bg.BackgroundColor3 = state and C.togOn or C.togOff
    bg.BorderSizePixel  = 0
    bg.ZIndex           = 104
    bg.Parent           = row
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 11, 0, 11)
    knob.Position         = state and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,2,0.5,-5)
    knob.BackgroundColor3 = C.text
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 105
    knob.Parent           = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function set(s)
        state = s
        TweenService:Create(bg,   TweenInfo.new(0.14), {BackgroundColor3 = s and C.togOn or C.togOff}):Play()
        TweenService:Create(knob, TweenInfo.new(0.14), {Position = s and UDim2.new(1,-13,0.5,-5) or UDim2.new(0,2,0.5,-5)}):Play()
        lbl.TextColor3 = s and C.text or C.sub
        if onChange then onChange(s) end
    end

    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then set(not state) end
    end)
    return set
end

local function AddSlider(col, label, min, max, default, fmt, onChange)
    local val   = default or min
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, -4, 0, 42)
    frame.BackgroundColor3 = C.panel
    frame.BorderSizePixel  = 0
    frame.ZIndex           = 103
    frame.Parent           = col
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)

    local lbl = Instance.new("TextLabel")
    lbl.Text          = label .. ": " .. (fmt and string.format(fmt, val) or val)
    lbl.Font          = Enum.Font.Gotham
    lbl.TextSize      = 10
    lbl.TextColor3    = C.text
    lbl.BackgroundTransparency = 1
    lbl.Position      = UDim2.new(0, 8, 0, 4)
    lbl.Size          = UDim2.new(1, -16, 0, 16)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex        = 104
    lbl.Parent        = frame

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1, -16, 0, 5)
    track.Position         = UDim2.new(0, 8, 0, 29)
    track.BackgroundColor3 = C.togOff
    track.BorderSizePixel  = 0
    track.ZIndex           = 104
    track.Parent           = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((val - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 105
    fill.Parent           = track
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
            lbl.Text  = label .. ": " .. (fmt and string.format(fmt, val) or val)
            if onChange then onChange(val) end
        end
    end)
end

local function AddButton(col, label, onClick)
    local btn = Instance.new("TextButton")
    btn.Text             = label
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 10
    btn.TextColor3       = C.text
    btn.BackgroundColor3 = C.accentD
    btn.BorderSizePixel  = 0
    btn.Size             = UDim2.new(1, -4, 0, 28)
    btn.ZIndex           = 104
    btn.Parent           = col
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = C.accentD}):Play()
    end)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

local function AddDropdown(col, label, opts, default, onChange)
    local sel  = default or opts[1]
    local open = false

    local wrap = Instance.new("Frame")
    wrap.Size             = UDim2.new(1, -4, 0, 30)
    wrap.BackgroundColor3 = C.panel
    wrap.BorderSizePixel  = 0
    wrap.ClipsDescendants = false
    wrap.ZIndex           = 110
    wrap.Parent           = col
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 5)

    local labelLbl = Instance.new("TextLabel")
    labelLbl.Text          = label
    labelLbl.Font          = Enum.Font.Gotham
    labelLbl.TextSize      = 10
    labelLbl.TextColor3    = C.sub
    labelLbl.BackgroundTransparency = 1
    labelLbl.Position      = UDim2.new(0, 8, 0, 0)
    labelLbl.Size          = UDim2.new(0.42, 0, 1, 0)
    labelLbl.TextXAlignment = Enum.TextXAlignment.Left
    labelLbl.ZIndex        = 111
    labelLbl.Parent        = wrap

    local btn = Instance.new("TextButton")
    btn.Text             = sel .. " ▾"
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 10
    btn.TextColor3       = C.text
    btn.BackgroundColor3 = C.panel2
    btn.BorderSizePixel  = 0
    btn.Position         = UDim2.new(0.42, 2, 0, 3)
    btn.Size             = UDim2.new(0.58, -10, 1, -6)
    btn.ZIndex           = 112
    btn.Parent           = wrap
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local drop = Instance.new("Frame")
    drop.BackgroundColor3 = C.panel2
    drop.BorderSizePixel  = 0
    drop.Position         = UDim2.new(0.42, 2, 1, 2)
    drop.Size             = UDim2.new(0.58, -10, 0, #opts * 22)
    drop.Visible          = false
    drop.ZIndex           = 120
    drop.Parent           = wrap
    Instance.new("UICorner", drop).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", drop).Color        = C.border
    Instance.new("UIListLayout", drop).SortOrder = Enum.SortOrder.LayoutOrder

    for i, opt in ipairs(opts) do
        local ob = Instance.new("TextButton")
        ob.Text          = opt
        ob.Font          = Enum.Font.Gotham
        ob.TextSize      = 10
        ob.TextColor3    = opt == sel and C.accent or C.text
        ob.BackgroundTransparency = 1
        ob.Size          = UDim2.new(1, 0, 0, 22)
        ob.LayoutOrder   = i
        ob.ZIndex        = 121
        ob.Parent        = drop
        ob.MouseButton1Click:Connect(function()
            sel = opt; btn.Text = opt .. " ▾"
            drop.Visible = false; open = false
            for _, c in pairs(drop:GetChildren()) do
                if c:IsA("TextButton") then c.TextColor3 = c.Text == opt and C.accent or C.text end
            end
            if onChange then onChange(opt) end
        end)
    end
    btn.MouseButton1Click:Connect(function()
        open = not open; drop.Visible = open
    end)
end

-- ═══════════════════════════════════════════════════
--  FARM TAB
-- ═══════════════════════════════════════════════════
AddHeader(L("FARM"), "AUTO STEAL")

local instantGrabConn = nil
local stealToggleFn   = nil
local autoStealActive = false

stealToggleFn = AddToggle(L("FARM"), "AUTO STEAL EGG", false, function(state)
    autoStealActive    = state
    Config.autoSteal   = state
    spoofVelocity      = state
    if state then
        task.spawn(function()
            while autoStealActive do
                local egg, dist = getClosestEgg(Config.minRarity)
                if egg then
                    local pos = getEggPos(egg)
                    if pos then
                        if dist > 7 then NaturalApproach(pos, 5) end
                        task.wait(0.05 + math.random(1, 12) / 100)
                        tryStealEgg(egg)
                    end
                end
                task.wait(Config.stealDelay + math.random(1, 45) / 100)
            end
        end)
    end
end)

-- Instant grab: fires on any new ProximityPrompt or egg model added
local instantGrabActive = false
AddToggle(L("FARM"), "INSTANT GRAB (NEW EGGS)", false, function(state)
    instantGrabActive = state
    if state then
        Workspace.DescendantAdded:Connect(function(d)
            if not instantGrabActive then return end
            if d:IsA("ProximityPrompt") then
                task.wait(0.06)
                pcall(function() fireproximityprompt(d) end)
            elseif d:IsA("Model") then
                local n = d.Name:lower()
                if n:find("egg") and not isBlocked(n) then
                    task.wait(0.08)
                    tryStealEgg(d)
                end
            end
        end)
    end
end)

AddSlider(L("FARM"), "Steal Delay", 30, 300, 60, "%dms", function(v)
    Config.stealDelay = v / 100
end)

AddSlider(L("FARM"), "Steal Range", 10, 200, 80, "%d stds", function(v)
    Config.stealRange = v
end)

AddDropdown(L("FARM"), "Min Rarity",
    {"Any","Uncommon+","Rare+","Epic+","Legendary+","Mythical+"},
    "Any",
    function(v)
        local m = {["Any"]=1,["Uncommon+"]=2,["Rare+"]=3,["Epic+"]=4,["Legendary+"]=5,["Mythical+"]=6}
        Config.minRarity = m[v] or 1
    end
)

AddButton(L("FARM"), "STEAL CLOSEST NOW", function()
    task.spawn(function()
        local egg, dist = getClosestEgg(1)
        if egg then
            local pos = getEggPos(egg)
            if pos and dist > 7 then NaturalApproach(pos, 5) end
            task.wait(0.05)
            tryStealEgg(egg)
        end
    end)
end)

AddButton(L("FARM"), "STEAL ALL NEARBY", function()
    task.spawn(function()
        for _, egg in pairs(getEggs()) do
            local pos = getEggPos(egg)
            if pos then
                local d = (HRP.Position - pos).Magnitude
                if d <= Config.stealRange then
                    if d > 7 then NaturalApproach(pos, 5) end
                    task.wait(0.06 + math.random(1, 8)/100)
                    tryStealEgg(egg)
                    task.wait(Config.stealDelay + math.random(1, 30)/100)
                end
            end
        end
    end)
end)

AddHeader(R("FARM"), "AUTO TOOLS")

AddToggle(R("FARM"), "AUTO HATCH & EQUIP", false, function(state)
    Config.autoHatch = state
    if state then
        task.spawn(function()
            while Config.autoHatch do
                for _, n in ipairs({"HatchEgg","OpenEgg","hatch","open","Hatch","HatchPet"}) do
                    local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                end
                task.wait(0.9 + math.random(1, 25)/100)
                for _, n in ipairs({"EquipPet","equip","Equip","SetPet"}) do
                    local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                end
                task.wait(1.3 + math.random(1, 30)/100)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO TREADMILL", false, function(state)
    Config.autoTreadmill = state
    if state then
        task.spawn(function()
            while Config.autoTreadmill do
                local tObj = Workspace:FindFirstChild("Treadmill",true)
                          or Workspace:FindFirstChild("treadmill",true)
                          or Workspace:FindFirstChild("Conveyor",true)
                if tObj then
                    local tp = tObj:IsA("Model") and tObj:GetModelCFrame().Position or tObj.Position
                    if (HRP.Position - tp).Magnitude > 6 then
                        SafeTP(CFrame.new(tp + Vector3.new(0, 3, 2)), 8, 0.025)
                    end
                    local pp = tObj:FindFirstChild("ProximityPrompt",true)
                    if pp then pcall(function() fireproximityprompt(pp) end) end
                    for _, n in ipairs({"Treadmill","treadmill","run","Run"}) do
                        local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                    end
                end
                task.wait(1 + math.random(1, 25)/100)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO SELL PETS", false, function(state)
    Config.autoSell = state
    if state then
        task.spawn(function()
            while Config.autoSell do
                for _, n in ipairs({"SellPet","SellEgg","sell","Sell","Trade"}) do
                    local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                end
                task.wait(1.6 + math.random(1, 50)/100)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO FUSE PETS", false, function(state)
    Config.autoFuse = state
    if state then
        task.spawn(function()
            while Config.autoFuse do
                for _, n in ipairs({"FuseEgg","FusePet","fuse","combine","merge","Fuse"}) do
                    local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                end
                task.wait(2.1 + math.random(1, 60)/100)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO RIFT FARM", false, function(state)
    Config.autoRift = state
    if state then
        task.spawn(function()
            while Config.autoRift do
                local rift = Workspace:FindFirstChild("Rift",true)
                          or Workspace:FindFirstChild("Portal",true)
                          or Workspace:FindFirstChild("Boss",true)
                if rift then
                    local rp = rift:IsA("Model") and rift:GetModelCFrame().Position or rift.Position
                    if (HRP.Position - rp).Magnitude > 8 then
                        SafeTP(CFrame.new(rp + Vector3.new(0, 5, 0)), 10, 0.025)
                    end
                    local pp = rift:FindFirstChild("ProximityPrompt",true)
                    if pp then pcall(function() fireproximityprompt(pp) end) end
                    for _, n in ipairs({"EnterRift","rift","boss","portal"}) do
                        local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                    end
                end
                task.wait(3.2 + math.random(1, 100)/100)
            end
        end)
    end
end)

AddToggle(R("FARM"), "AUTO CLAIM REWARDS", false, function(state)
    Config.autoClaimRewards = state
    if state then
        task.spawn(function()
            while Config.autoClaimRewards do
                for _, n in ipairs({"ClaimReward","Claim","claim","reward","DailyReward","Daily"}) do
                    local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                end
                task.wait(32 + math.random(1, 100)/100)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
--  PLAYER TAB
-- ═══════════════════════════════════════════════════
AddHeader(L("PLAYER"), "MOVEMENT")

AddToggle(L("PLAYER"), "SPEED BOOST", false, function(state)
    Humanoid.WalkSpeed = state and Config.speed or 16
    spoofVelocity      = state
end)

AddSlider(L("PLAYER"), "Walk Speed", 16, 150, 50, "%d", function(v)
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

AddSlider(L("PLAYER"), "Jump Power", 50, 400, 100, "%d", function(v)
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

AddToggle(L("PLAYER"), "ANTI TRAP", false, function(state)
    Config.antiTrap = state
    if state then
        task.spawn(function()
            while Config.antiTrap do
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v.Name:lower():find("trap") and v:IsA("BasePart") then
                        pcall(function() v.CanTouch = false end)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end)

AddToggle(L("PLAYER"), "ANTI RAGDOLL", false, function(state)
    Config.antiRagdoll = state
    if state then
        task.spawn(function()
            while Config.antiRagdoll do
                pcall(function()
                    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,    false)
                    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                end)
                task.wait(0.3)
            end
        end)
    end
end)

AddHeader(R("PLAYER"), "STEALTH")

AddToggle(R("PLAYER"), "INVISIBILITY", false, function(state)
    Config.invisPlayer = state
    for _, p in pairs(Character:GetDescendants()) do
        if p:IsA("BasePart") or p:IsA("Decal") then
            pcall(function() p.Transparency = state and 1 or 0 end)
        end
    end
    if HRP then HRP.Transparency = 1 end
end)

AddToggle(R("PLAYER"), "INVIS EGG ON CARRY", false, function(state)
    Config.invisEgg = state
    if state then
        task.spawn(function()
            while Config.invisEgg do
                for _, v in pairs(Character:GetDescendants()) do
                    if v.Name:lower():find("egg") and v:IsA("BasePart") then
                        pcall(function() v.Transparency = 1 end)
                    end
                end
                task.wait(0.25)
            end
        end)
    end
end)

AddToggle(R("PLAYER"), "ANTI HIT", false, function(state)
    task.spawn(function()
        while true do
            if state then
                for _, p in pairs(Character:GetDescendants()) do
                    if p:IsA("BasePart") then pcall(function() p.CanTouch = false end) end
                end
            end
            task.wait(0.2)
        end
    end)
end)

AddHeader(R("PLAYER"), "ESP")

local espBoxes = {}
AddToggle(R("PLAYER"), "EGG ESP (HIGHLIGHT)", false, function(state)
    Config.eggESP = state
    for _, h in pairs(espBoxes) do if h and h.Parent then h:Destroy() end end
    espBoxes = {}
    if state then
        task.spawn(function()
            while Config.eggESP do
                for _, h in pairs(espBoxes) do if h and h.Parent then h:Destroy() end end
                espBoxes = {}
                for _, egg in pairs(getEggs()) do
                    local ok, sb = pcall(function()
                        local s = Instance.new("SelectionBox")
                        s.Adornee           = egg
                        s.Color3            = C.gold
                        s.LineThickness     = 0.07
                        s.SurfaceTransparency = 0.75
                        s.SurfaceColor3     = C.gold
                        s.Parent            = ScreenGui
                        return s
                    end)
                    if ok then table.insert(espBoxes, sb) end
                end
                task.wait(0.8)
            end
        end)
    end
end)

local playerBBs = {}
AddToggle(R("PLAYER"), "PLAYER ESP (NAME)", false, function(state)
    Config.playerESP = state
    for _, b in pairs(playerBBs) do if b and b.Parent then b:Destroy() end end
    playerBBs = {}
    if state then
        task.spawn(function()
            while Config.playerESP do
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and not playerBBs[plr.Name] then
                            local bb = Instance.new("BillboardGui")
                            bb.Size        = UDim2.new(0, 120, 0, 36)
                            bb.StudsOffset = Vector3.new(0, 3, 0)
                            bb.AlwaysOnTop = true
                            bb.Adornee     = hrp
                            bb.Parent      = ScreenGui
                            local nl = Instance.new("TextLabel", bb)
                            nl.Text       = plr.Name
                            nl.Font       = Enum.Font.GothamBold
                            nl.TextSize   = 13
                            nl.TextColor3 = C.accent
                            nl.BackgroundTransparency = 1
                            nl.Size       = UDim2.new(1, 0, 1, 0)
                            playerBBs[plr.Name] = bb
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
--  BYPASS TAB
-- ═══════════════════════════════════════════════════
AddHeader(L("BYPASS"), "ANTI-BAN LAYERS")

local bypassInfoLbl = AddInfo(L("BYPASS"), "All layers active by default")

AddToggle(L("BYPASS"), "VELOCITY SPOOFER", true, function(state)
    spoofVelocity        = state
    StatusDot.BackgroundColor3 = state and C.green or C.red
    StatusLbl.Text             = state and "BYPASS ON" or "BYPASS OFF"
    StatusLbl.TextColor3       = state and C.green or C.red
    bypassInfoLbl.Text         = "Velocity Spoof: " .. (state and "ON ✓" or "OFF ✗")
end)

AddToggle(L("BYPASS"), "STATE MASKING", true, function(state)
    if state then maskStates() end
end)

AddToggle(L("BYPASS"), "REMOTE AC BLOCKER", true, function()
    -- Always active via hook; toggle just for visual feedback
    bypassInfoLbl.Text = "Remote blocker: always on (hook-level)"
end)

AddButton(L("BYPASS"), "NUKE AC REMOTES", function()
    local n = 0
    local function nuke(obj)
        for _, v in pairs(obj:GetDescendants()) do
            if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and isBlocked(v.Name) then
                pcall(function() v:Destroy(); n = n + 1 end)
            end
        end
    end
    nuke(ReplicatedStorage)
    nuke(Workspace)
    bypassInfoLbl.Text = "Nuked " .. n .. " AC remotes ✓"
end)

AddButton(L("BYPASS"), "FLUSH REMOTE CACHE", function()
    _rCache = {}
    _rateTbl = {}
    bypassInfoLbl.Text = "Cache flushed ✓"
end)

AddButton(L("BYPASS"), "RE-APPLY STATE MASK", function()
    maskStates()
    bypassInfoLbl.Text = "State mask reapplied ✓"
end)

AddHeader(R("BYPASS"), "SERVER HOP")

AddButton(R("BYPASS"), "HOP (LEAST PLAYERS)", function()
    task.spawn(function()
        local ok, res = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=25")
            )
        end)
        local best, bestN = nil, math.huge
        if ok and res and res.data then
            for _, s in ipairs(res.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers and s.playing < bestN then
                    best = s.id; bestN = s.playing
                end
            end
        end
        if best then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best, LocalPlayer) end)
        else
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        end
    end)
end)

AddButton(R("BYPASS"), "REJOIN SERVER", function()
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end)

local jidLbl = AddInfo(R("BYPASS"), "Job: " .. tostring(game.JobId):sub(1,18) .. "...")
AddButton(R("BYPASS"), "COPY JOB ID", function()
    pcall(function() setclipboard(game.JobId) end)
    jidLbl.Text = "Copied! ✓"
    task.delay(2, function() jidLbl.Text = "Job: " .. tostring(game.JobId):sub(1,18) .. "..." end)
end)

AddHeader(R("BYPASS"), "SMART HOP TIMER")
AddToggle(R("BYPASS"), "AUTO HOP (60s)", false, function(state)
    if state then
        task.spawn(function()
            while state do
                task.wait(60)
                if state then
                    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
--  TOOLS TAB
-- ═══════════════════════════════════════════════════
AddHeader(L("TOOLS"), "PROGRESSION")

AddToggle(L("TOOLS"), "AUTO BASE UPGRADE", false, function(state)
    Config.autoBaseUpgrade = state
    if state then
        task.spawn(function()
            while Config.autoBaseUpgrade do
                for _, n in ipairs({"UpgradeBase","BaseUpgrade","upgrade","Upgrade"}) do
                    local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                end
                task.wait(4.2 + math.random(1, 100)/100)
            end
        end)
    end
end)

AddToggle(L("TOOLS"), "AUTO TREADMILL UPG", false, function(state)
    Config.autoTreadUpgrade = state
    if state then
        task.spawn(function()
            while Config.autoTreadUpgrade do
                for _, n in ipairs({"UpgradeTreadmill","TreadmillUpgrade","treadmillupgrade"}) do
                    local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                end
                task.wait(4.2 + math.random(1, 100)/100)
            end
        end)
    end
end)

AddToggle(L("TOOLS"), "AUTO FAVORITE PETS", false, function(state)
    Config.autoFavorite = state
    if state then
        task.spawn(function()
            while Config.autoFavorite do
                for _, n in ipairs({"FavoritePet","favorite","fav","Favorite"}) do
                    local r = findRemote(n); if r then pcall(function() r:FireServer() end); break end
                end
                task.wait(2.1 + math.random(1, 50)/100)
            end
        end)
    end
end)

AddHeader(R("TOOLS"), "REMOTE SCANNER")

local scanLbl = AddInfo(R("TOOLS"), "Press scan to list remotes")
scanLbl.Size        = UDim2.new(1, -4, 0, 80)
scanLbl.TextWrapped = true
scanLbl.TextYAlignment = Enum.TextYAlignment.Top

AddButton(R("TOOLS"), "SCAN RS REMOTES", function()
    local found = {}
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(found, (v:IsA("RemoteFunction") and "[RF]" or "[RE]") .. " " .. v.Name)
        end
    end
    if #found > 0 then
        local txt = table.concat(found, "\n")
        scanLbl.Text = txt
        pcall(function() setclipboard(txt) end)
    else
        scanLbl.Text = "No remotes in RS"
    end
end)

AddHeader(R("TOOLS"), "CONFIG")

AddButton(R("TOOLS"), "SAVE CONFIG", function()
    pcall(function() writefile("YushHub_SAE.json", HttpService:JSONEncode(Config)) end)
    scanLbl.Text = "Config saved!"
end)

AddButton(R("TOOLS"), "LOAD CONFIG", function()
    pcall(function()
        if isfile("YushHub_SAE.json") then
            local ld = HttpService:JSONDecode(readfile("YushHub_SAE.json"))
            for k, v in pairs(ld) do Config[k] = v end
            scanLbl.Text = "Config loaded!"
        end
    end)
end)

AddButton(R("TOOLS"), "RESET CONFIG", function()
    for k, v in pairs(Config) do
        if type(v) == "boolean" then Config[k] = false
        elseif type(v) == "number" then Config[k] = 0 end
    end
    scanLbl.Text = "Config reset!"
end)

-- ═══════════════════════════════════════════════════
--  MISC TAB
-- ═══════════════════════════════════════════════════
AddHeader(L("MISC"), "PERFORMANCE")

local fpsLbl   = AddInfo(L("MISC"), "FPS: — | Ping: —ms")
local fpsCnt   = 0
local lastFT   = tick()
RunService.RenderStepped:Connect(function()
    fpsCnt = fpsCnt + 1
    if tick() - lastFT >= 1 then
        local fps  = fpsCnt
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        fpsLbl.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
        fpsCnt = 0; lastFT = tick()
    end
end)

AddToggle(L("MISC"), "FPS UNLOCKER", false, function(state)
    pcall(function() setfpscap(state and 0 or 60) end)
end)

AddSlider(L("MISC"), "FPS Cap", 30, 240, 60, "%dfps", function(v)
    Config.fpsCap = v
    pcall(function() setfpscap(v) end)
end)

AddToggle(L("MISC"), "ANTI AFK", true, function() end)

AddHeader(L("MISC"), "KEYBINDS")
AddInfo(L("MISC"), "[ RightShift ] Toggle Menu")
AddInfo(L("MISC"), "[ F9 ]  Toggle Auto Steal")
AddInfo(L("MISC"), "[ Delete ]  Destroy Script")

AddHeader(R("MISC"), "CREDITS")
local credLines = {
    "YUSH HUB V3",
    "Steal An Egg Edition",
    "─────────────────",
    "t.me/PrimeYush",
    "@YushPogi",
    "─────────────────",
    "Anti-Ban: ACTIVE",
}
for _, line in ipairs(credLines) do AddInfo(R("MISC"), line) end

AddHeader(R("MISC"), "KEYBIND HINT")
AddInfo(R("MISC"), "Click [ › ] pill = open menu")
AddInfo(R("MISC"), "Drag pill to reposition it")
AddInfo(R("MISC"), "Drag topbar to move window")

-- ═══════════════════════════════════════════════════
--  GLOBAL KEYBINDS
-- ═══════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        menuOpen     = not menuOpen
        Main.Visible = menuOpen
        ICArrow.Text = menuOpen and "‹" or "›"
    elseif inp.KeyCode == Enum.KeyCode.Delete then
        ScreenGui:Destroy()
    elseif inp.KeyCode == Enum.KeyCode.F9 then
        autoStealActive = not autoStealActive
        Config.autoSteal = autoStealActive
        spoofVelocity    = autoStealActive
        if stealToggleFn then stealToggleFn(autoStealActive) end
    end
end)

-- ═══════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════
TabBtns["FARM"].btn.MouseButton1Click:Fire()

print([[
╔═══════════════════════════════════════╗
║  YUSH HUB V3 | STEAL AN EGG LOADED   ║
║  Click [ › ] pill on left to open    ║
║  RightShift = toggle | F9 = steal    ║
║  Delete = destroy gui                ║
╚═══════════════════════════════════════╝]])
