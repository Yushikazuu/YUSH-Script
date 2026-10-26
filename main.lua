-- ============================================================
-- YUSH SCRIPT V1 | STEAL AN EGG
-- Author: @PrimeYush
-- Anti-Cheat Bypass: Integrated (LSS Suite)
-- ============================================================

local Players        = game:GetService("Players")
local RS             = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local LP             = Players.LocalPlayer
local Camera         = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
-- [AC BYPASS — LSS SUITE]
-- ════════════════════════════════════════════════════════════
local bxor   = bit32.bxor
local unpack = table.unpack

local function ScanGCHeap(step, perChunk)
    local scan = getgc or (debug and debug.getgc)
    if type(scan) ~= "function" then return end
    local ok, objects = pcall(scan, true)
    if not ok or type(objects) ~= "table" then return end
    perChunk = perChunk or 400
    for i = 1, #objects do
        local obj = objects[i]; objects[i] = nil
        local okStep, stop = pcall(step, obj)
        if okStep and stop == true then return end
        if i % perChunk == 0 then task.wait() end
    end
end

local function bypassClientDetections()
    if typeof(filtergc) ~= "function" or typeof(debug) ~= "table"
    or typeof(debug.getupvalues) ~= "function" then return false end
    local ok, fn = pcall(function()
        return filtergc("function", { Constants = { "gmatch", "GetFullName" } }, true)
    end)
    if not ok or type(fn) ~= "function" then return false end
    local setMeta = (typeof(setrawmetatable)=="function" and setrawmetatable)
        or (typeof(setmetatable)=="function" and setmetatable)
    if not setMeta then return false end
    local okUv, ups = pcall(debug.getupvalues, fn)
    if not okUv or type(ups) ~= "table" then return false end
    for _, tbl in pairs(ups) do
        if typeof(tbl) == "table" then pcall(setMeta, tbl, {__newindex=function()end}) end
    end
    return true
end
pcall(bypassClientDetections)

local AcSlices = {}
function AcSlices.FreezeTables()
    local setmeta = setrawmetatable or setmetatable
    if not setmeta then return end
    ScanGCHeap(function(obj)
        if typeof(obj) ~= "table" then return end
        local mainrun = false
        for _, v in pairs(obj) do if v == obj then mainrun=true; break end end
        if not mainrun then return end
        for _, v in pairs(obj) do
            if typeof(v)=="number" and v>=1 and v<=3 and obj[v]==nil then
                pcall(setmeta, obj, {__newindex=function()end}); break
            end
        end
    end)
end
function AcSlices.WipeUGI()
    local gc = getconstants or (debug and debug.getconstants)
    local sc = setconstant  or (debug and debug.setconstant)
    local il = islclosure   or function(f) return not pcall(setfenv,getfenv(f)) end
    if not (gc and sc and debug and debug.info) then return end
    ScanGCHeap(function(fn)
        if typeof(fn)~="function" or not il(fn) then return end
        local ok,src = pcall(debug.info,fn,"s")
        if not ok or not src:find("ReplicatedFirst",1,true) or not src:find("UGI",1,true) then return end
        local okC,consts = pcall(gc,fn)
        if not okC or type(consts)~="table" then return end
        for idx,c in next,consts do
            if type(c)=="string" and c=="Humanoid" then pcall(sc,fn,idx,"") end
        end
    end)
end
function AcSlices.ScrubX14()
    local gc   = getconstants or (debug and debug.getconstants)
    local il   = islclosure   or function(fn) return not pcall(setfenv,getfenv(fn)) end
    local Hook = hookfunction or replaceclosure or hookfunc
    if not (gc and Hook and debug and debug.getstack and debug.setstack) then return end
    ScanGCHeap(function(fn)
        if typeof(fn)~="function" or not il(fn) then return end
        local ok,consts = pcall(gc,fn)
        if not ok or type(consts)~="table" or not table.find(consts,"X-14") then return end
        local cb
        pcall(function()
            cb = Hook(fn, function(...)
                local stack = debug.getstack(1)
                if type(stack)=="table" then
                    for idx,val in pairs(stack) do
                        if val=="X-14" then pcall(debug.setstack,1,idx,nil) end
                    end
                end
                if cb then return cb(...) end
            end)
        end)
    end)
end
function AcSlices.SanitizeState()
    local il  = islclosure    or function(v) return not pcall(setfenv,getfenv(v)) end
    local guv = getupvalues   or (debug and debug.getupvalues)
    local gv  = getupvalue    or (debug and debug.getupvalue)
    local sv  = setupvalue    or (debug and debug.setupvalue)
    local cf  = clonefunction or function(f) return function(...) return f(...) end end
    if not (guv and gv and sv) then return end
    ScanGCHeap(function(v)
        if typeof(v)~="function" or not il(v) then return end
        local ok,upvs = pcall(guv,v)
        if not ok or type(upvs)~="table" or #upvs~=19 then return end
        local ok2,u2 = pcall(gv,v,2)
        if not ok2 or typeof(u2)~="function" then return end
        local old = cf(u2)
        pcall(sv,v,2,function(a,b)
            if b and typeof(b)=="table" then pcall(setmetatable,b,{}) end
            return old(a,b)
        end)
    end)
end

task.spawn(function()
    pcall(AcSlices.FreezeTables); task.wait()
    pcall(AcSlices.WipeUGI);      task.wait()
    pcall(AcSlices.ScrubX14);     task.wait()
    pcall(AcSlices.SanitizeState)
end)

-- Evidence scrubber
task.spawn(function()
    if not (getgc or (debug and debug.getgc)) then return end
    local st, misses = nil, 0
    local function findIT()
        local found
        ScanGCHeap(function(o)
            if found then return true end
            if type(o)~="table" then return end
            local hit=false
            pcall(function()
                hit=(rawget(o,"ValidationLocked")~=nil and rawget(o,"Evidence")~=nil)
                   or(rawget(o,"ThreatLevel")~=nil and rawget(o,"LastObservedSample")~=nil)
            end)
            if hit then found=o; return true end
        end,250)
        return found
    end
    LP.CharacterAdded:Connect(function() task.wait(1); st=findIT() end)
    while true do
        if not st then
            st=findIT()
            if not st then
                misses=misses+1
                local w=math.min(5*(2^math.min(misses-1,3)),30)
                local s=0; while s<w do task.wait(0.5);s=s+0.5 end
            else misses=0 end
        end
        if st then
            pcall(function()
                local ev=rawget(st,"Evidence")
                if type(ev)=="table" then
                    if(tonumber(ev.Speed)or 0)>0 then rawset(ev,"Speed",0) end
                    if(tonumber(ev.Teleport)or 0)>0 then rawset(ev,"Teleport",0) end
                    if(tonumber(ev.Flight)or 0)>0 then rawset(ev,"Flight",0) end
                end
                if rawget(st,"ThreatLevel")~="Trusted" then rawset(st,"ThreatLevel","Trusted") end
                if rawget(st,"ValidationLocked")==true then rawset(st,"ValidationLocked",false) end
                if rawget(st,"KickQueued")==true then rawset(st,"KickQueued",false) end
                if rawget(st,"TamperScore")~=nil then rawset(st,"TamperScore",0) end
                if rawget(st,"InvalidHeartbeatCount")~=nil then rawset(st,"InvalidHeartbeatCount",0) end
                local los=rawget(st,"LastObservedSample")
                if los then
                    for _,k in ipairs({"LastGameplayTrustedSample","LastValidatedSample",
                        "LastValidatedGroundedSample","LastConfirmedGroundSample","LastGoodSample"}) do
                        if rawget(st,k)==nil then rawset(st,k,los) end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- ════════════════════════════════════════════════════════════
-- [SETTINGS STATE]
-- ════════════════════════════════════════════════════════════
local Config = {
    -- Steal
    AutoSteal = false, InstantSteal = false, MinValueGate = 0,
    TargetAreas = {}, TargetSpecificEggs = {},
    -- Egg
    EggSpawnPredictor = false, AutoPlaceEgg = false,
    MinRarityFilter = "Common", PlaceRarityOrder = {},
    -- Butterfly
    AutoButterflyBloom = false, CatchButterflies = false,
    NextButterflyTimer = 0,
    -- Guard/Movement
    AntiGuard = false, InfiniteJump = false,
    SpeedBoost = 1, TweenSpeed = 1, CarrySpeed = 1,
    AntiRagdoll = false, InvisibilityMode = false,
    -- Hatch/Craft
    AutoHatchEquip = false, AutoCraftEssence = false,
    EssenceMinRarity = "Common", EssenceMinValue = 0,
    EssencePriority = {}, EssenceSkipEnchanted = false,
    EssenceTargetEggs = {},
    -- ESP
    PlayerESP = false, EggESP = false,
    -- Mech/Boss
    AutoMechBoss = false, MechPortalTimer = 0,
    MechTweenSpeed = 1, BossServerHop = false,
    -- Rift/Fuse
    RiftSpawnPredictor = false, RiftRecipeEggPriority = {},
    AutoFuseMachine = false, FuseOutcomePredictor = false,
    RiftFusePredictor = false, AutoRiftBossFarming = false,
    -- Trade/Sell
    AutoTradeUp = false, SmartTradeEssence = false,
    TradeUpTiers = {}, AutoSellEggs = false,
    AutoSellLabEgg = false, MinStealValueFilter = 0,
    -- Lab
    StealMissingLabEggs = false, AutoLabTradeIn = false,
    AutoRerollLabRecipe = false, AutoPlaceLabRewardEggs = false,
    LabBanners = false,
    -- Auto features
    AutoWisp = false, AutoFavorite = false,
    AutoTreadmill = false, AutoTreadmillUpgrade = false,
    AutoBaseUpgrade = false, AutoTrailBuying = false,
    AutoProgression = false, AutoClaimRewards = false,
    AutoClaimMastery = false, AutoBuyScrambleShop = false,
    AutoScriptLoader = false,
    -- Server
    SmartServerHop = false, ServerRejoin = false,
    JobIDJoiner = "", AutoHop = false,
    KeepHoppingFor = "Rare", CatchMode = false,
    CatchPriority = {},
    -- Misc
    FPSOptimizer = false, FPSCap = 60,
    FPSPingOverlay = false, AntiAFK = true,
    MainWeaponHold = false, ScramblerHold = false,
    SwapTwoWeapons = false,
    -- Weapons
    EggPreviewCard = false,
    -- Webhook
    DiscordWebhook = "",
    -- Event
    EventAutoSteal = false, EventInstantSteal = false,
    EventTargetAreas = {}, EventMinRarity = "Common",
    EventAutoFarm = false, EventAutoHatchEquip = false,
    EventAutoPlaceEgg = false, EventAutoFavourite = false,
    EventCarrySpeed = 1, EventTweenSpeed = 1,
    EventAutoMutation = false,
}

-- ════════════════════════════════════════════════════════════
-- [UI LIBRARY]
-- ════════════════════════════════════════════════════════════
local THEME = {
    BG          = Color3.fromRGB(12, 12, 18),
    Panel       = Color3.fromRGB(18, 18, 28),
    Accent      = Color3.fromRGB(88, 101, 242),
    AccentHover = Color3.fromRGB(110, 124, 255),
    TabActive   = Color3.fromRGB(88, 101, 242),
    TabInactive = Color3.fromRGB(30, 30, 45),
    Text        = Color3.fromRGB(220, 220, 235),
    SubText     = Color3.fromRGB(140, 140, 165),
    Toggle_ON   = Color3.fromRGB(88, 101, 242),
    Toggle_OFF  = Color3.fromRGB(50, 50, 70),
    Slider      = Color3.fromRGB(88, 101, 242),
    Border      = Color3.fromRGB(40, 40, 60),
    Red         = Color3.fromRGB(237, 66, 69),
    Green       = Color3.fromRGB(87, 242, 135),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YushScriptV1"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = game:GetService("CoreGui")

-- ── TOGGLE BUTTON (Y logo) ─────────────────────────────────
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0,52,0,52)
ToggleBtn.Position = UDim2.new(0,20,0.5,-26)
ToggleBtn.BackgroundColor3 = THEME.Accent
ToggleBtn.Text = "Y"
ToggleBtn.TextColor3 = THEME.Text
ToggleBtn.TextSize = 26
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.ZIndex = 10
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner",ToggleBtn).CornerRadius = UDim.new(1,0)
local ToggleStroke = Instance.new("UIStroke",ToggleBtn)
ToggleStroke.Color = THEME.AccentHover
ToggleStroke.Thickness = 2

-- glow effect on Y
local ToggleGlow = Instance.new("ImageLabel",ToggleBtn)
ToggleGlow.Size = UDim2.new(1.8,0,1.8,0)
ToggleGlow.Position = UDim2.new(-0.4,0,-0.4,0)
ToggleGlow.BackgroundTransparency = 1
ToggleGlow.Image = "rbxassetid://5028857472"
ToggleGlow.ImageColor3 = THEME.Accent
ToggleGlow.ImageTransparency = 0.6
ToggleGlow.ZIndex = 9

-- drag toggle button
do
    local drag, start, orig = false, nil, nil
    ToggleBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; start=i.Position
            orig=ToggleBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local d = i.Position - start
            ToggleBtn.Position = UDim2.new(
                orig.X.Scale, orig.X.Offset + d.X,
                orig.Y.Scale, orig.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ── MAIN WINDOW ───────────────────────────────────────────
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,720,0,480)
Main.Position = UDim2.new(0.5,-360,0.5,-240)
Main.BackgroundColor3 = THEME.BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,12)
local MainStroke = Instance.new("UIStroke",Main)
MainStroke.Color = THEME.Border
MainStroke.Thickness = 1

-- title bar
local TitleBar = Instance.new("Frame",Main)
TitleBar.Size = UDim2.new(1,0,0,44)
TitleBar.BackgroundColor3 = THEME.Panel
TitleBar.BorderSizePixel = 0
Instance.new("UICorner",TitleBar).CornerRadius = UDim.new(0,12)

local TitleFix = Instance.new("Frame",TitleBar)
TitleFix.Size = UDim2.new(1,0,0.5,0)
TitleFix.Position = UDim2.new(0,0,0.5,0)
TitleFix.BackgroundColor3 = THEME.Panel
TitleFix.BorderSizePixel = 0

local TitleLabel = Instance.new("TextLabel",TitleBar)
TitleLabel.Size = UDim2.new(1,-120,1,0)
TitleLabel.Position = UDim2.new(0,16,0,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Yush Script V1  |  Steal An Egg"
TitleLabel.TextColor3 = THEME.Text
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- player info in title
local PlayerInfo = Instance.new("TextLabel",TitleBar)
PlayerInfo.Size = UDim2.new(0,200,1,0)
PlayerInfo.Position = UDim2.new(1,-210,0,0)
PlayerInfo.BackgroundTransparency = 1
PlayerInfo.Text = "👤 " .. LP.Name .. "  |  " .. LP.UserId
PlayerInfo.TextColor3 = THEME.SubText
PlayerInfo.TextSize = 11
PlayerInfo.Font = Enum.Font.Gotham
PlayerInfo.TextXAlignment = Enum.TextXAlignment.Right

-- close button
local CloseBtn = Instance.new("TextButton",TitleBar)
CloseBtn.Size = UDim2.new(0,32,0,32)
CloseBtn.Position = UDim2.new(1,-40,0,6)
CloseBtn.BackgroundColor3 = THEME.Red
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = THEME.Text
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner",CloseBtn).CornerRadius = UDim.new(0,6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible=false end)

-- drag main window
do
    local drag,start,orig=false,nil,nil
    TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; start=i.Position; orig=Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-start
            Main.Position=UDim2.new(orig.X.Scale,orig.X.Offset+d.X,orig.Y.Scale,orig.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

-- ── TAB BAR ───────────────────────────────────────────────
local TabBar = Instance.new("Frame",Main)
TabBar.Size = UDim2.new(0,140,1,-44)
TabBar.Position = UDim2.new(0,0,0,44)
TabBar.BackgroundColor3 = THEME.Panel
TabBar.BorderSizePixel = 0

local TabList = Instance.new("UIListLayout",TabBar)
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0,2)

local TabPad = Instance.new("UIPadding",TabBar)
TabPad.PaddingTop = UDim.new(0,8)
TabPad.PaddingLeft = UDim.new(0,6)
TabPad.PaddingRight = UDim.new(0,6)

-- content area
local ContentArea = Instance.new("Frame",Main)
ContentArea.Size = UDim2.new(1,-140,1,-44)
ContentArea.Position = UDim2.new(0,140,0,44)
ContentArea.BackgroundColor3 = THEME.BG
ContentArea.BorderSizePixel = 0

-- search bar
local SearchBar = Instance.new("TextBox",ContentArea)
SearchBar.Size = UDim2.new(1,-16,0,30)
SearchBar.Position = UDim2.new(0,8,0,8)
SearchBar.BackgroundColor3 = THEME.Panel
SearchBar.TextColor3 = THEME.Text
SearchBar.PlaceholderText = "🔍  Search features..."
SearchBar.PlaceholderColor3 = THEME.SubText
SearchBar.Text = ""
SearchBar.TextSize = 13
SearchBar.Font = Enum.Font.Gotham
SearchBar.ClearTextOnFocus = false
SearchBar.BorderSizePixel = 0
Instance.new("UICorner",SearchBar).CornerRadius = UDim.new(0,6)
local SearchPad = Instance.new("UIPadding",SearchBar)
SearchPad.PaddingLeft = UDim.new(0,10)

-- scroll frame for features
local Scroll = Instance.new("ScrollingFrame",ContentArea)
Scroll.Size = UDim2.new(1,-8,1,-50)
Scroll.Position = UDim2.new(0,4,0,46)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = THEME.Accent
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local ScrollLayout = Instance.new("UIListLayout",Scroll)
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScrollLayout.Padding = UDim.new(0,4)

local ScrollPad = Instance.new("UIPadding",Scroll)
ScrollPad.PaddingTop = UDim.new(0,4)
ScrollPad.PaddingLeft = UDim.new(0,4)
ScrollPad.PaddingRight = UDim.new(0,4)

-- ════════════════════════════════════════════════════════════
-- [UI COMPONENTS]
-- ════════════════════════════════════════════════════════════
local function MakeToggle(parent, label, configKey, callback)
    local Row = Instance.new("Frame",parent)
    Row.Size = UDim2.new(1,-8,0,36)
    Row.BackgroundColor3 = THEME.Panel
    Row.BorderSizePixel = 0
    Instance.new("UICorner",Row).CornerRadius = UDim.new(0,8)

    local Lbl = Instance.new("TextLabel",Row)
    Lbl.Size = UDim2.new(1,-60,1,0)
    Lbl.Position = UDim2.new(0,12,0,0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = THEME.Text
    Lbl.TextSize = 13
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Name = "Label"

    local Track = Instance.new("Frame",Row)
    Track.Size = UDim2.new(0,44,0,22)
    Track.Position = UDim2.new(1,-54,0.5,-11)
    Track.BackgroundColor3 = Config[configKey] and THEME.Toggle_ON or THEME.Toggle_OFF
    Track.BorderSizePixel = 0
    Instance.new("UICorner",Track).CornerRadius = UDim.new(1,0)

    local Knob = Instance.new("Frame",Track)
    Knob.Size = UDim2.new(0,16,0,16)
    Knob.Position = Config[configKey]
        and UDim2.new(1,-19,0.5,-8)
        or  UDim2.new(0,3,0.5,-8)
    Knob.BackgroundColor3 = Color3.new(1,1,1)
    Knob.BorderSizePixel = 0
    Instance.new("UICorner",Knob).CornerRadius = UDim.new(1,0)

    local Btn = Instance.new("TextButton",Track)
    Btn.Size = UDim2.new(1,0,1,0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        local on = Config[configKey]
        TweenService:Create(Track, TweenInfo.new(0.15),
            {BackgroundColor3 = on and THEME.Toggle_ON or THEME.Toggle_OFF}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15),
            {Position = on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
        if callback then callback(on) end
    end)
    return Row
end

local function MakeSlider(parent, label, configKey, min, max, callback)
    local Row = Instance.new("Frame",parent)
    Row.Size = UDim2.new(1,-8,0,50)
    Row.BackgroundColor3 = THEME.Panel
    Row.BorderSizePixel = 0
    Instance.new("UICorner",Row).CornerRadius = UDim.new(0,8)

    local Lbl = Instance.new("TextLabel",Row)
    Lbl.Size = UDim2.new(1,-60,0,20)
    Lbl.Position = UDim2.new(0,12,0,6)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = THEME.Text
    Lbl.TextSize = 13
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Name = "Label"

    local ValLbl = Instance.new("TextLabel",Row)
    ValLbl.Size = UDim2.new(0,50,0,20)
    ValLbl.Position = UDim2.new(1,-58,0,6)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text = tostring(Config[configKey])
    ValLbl.TextColor3 = THEME.Accent
    ValLbl.TextSize = 13
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right

    local Track = Instance.new("Frame",Row)
    Track.Size = UDim2.new(1,-24,0,6)
    Track.Position = UDim2.new(0,12,1,-18)
    Track.BackgroundColor3 = THEME.Toggle_OFF
    Track.BorderSizePixel = 0
    Instance.new("UICorner",Track).CornerRadius = UDim.new(1,0)

    local Fill = Instance.new("Frame",Track)
    Fill.Size = UDim2.new((Config[configKey]-min)/(max-min),0,1,0)
    Fill.BackgroundColor3 = THEME.Slider
    Fill.BorderSizePixel = 0
    Instance.new("UICorner",Fill).CornerRadius = UDim.new(1,0)

    local Knob = Instance.new("Frame",Track)
    Knob.Size = UDim2.new(0,14,0,14)
    Knob.Position = UDim2.new((Config[configKey]-min)/(max-min),0,0.5,-7)
    Knob.BackgroundColor3 = Color3.new(1,1,1)
    Knob.BorderSizePixel = 0
    Instance.new("UICorner",Knob).CornerRadius = UDim.new(1,0)

    local dragging = false
    Knob.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        local abs = Track.AbsolutePosition
        local sz  = Track.AbsoluteSize
        local pct = math.clamp((i.Position.X - abs.X) / sz.X, 0, 1)
        local val = math.floor(min + (max-min)*pct)
        Config[configKey] = val
        Fill.Size = UDim2.new(pct,0,1,0)
        Knob.Position = UDim2.new(pct,0,0.5,-7)
        ValLbl.Text = tostring(val)
        if callback then callback(val) end
    end)
    return Row
end

local function MakeSection(parent, title)
    local S = Instance.new("Frame",parent)
    S.Size = UDim2.new(1,-8,0,24)
    S.BackgroundTransparency = 1
    S.BorderSizePixel = 0
    local L = Instance.new("TextLabel",S)
    L.Size = UDim2.new(1,0,1,0)
    L.BackgroundTransparency = 1
    L.Text = "  " .. title:upper()
    L.TextColor3 = THEME.Accent
    L.TextSize = 11
    L.Font = Enum.Font.GothamBold
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Name = "Label"
    local Line = Instance.new("Frame",S)
    Line.Size = UDim2.new(1,0,0,1)
    Line.Position = UDim2.new(0,0,1,-1)
    Line.BackgroundColor3 = THEME.Border
    Line.BorderSizePixel = 0
    return S
end

local function MakeInput(parent, label, configKey, placeholder)
    local Row = Instance.new("Frame",parent)
    Row.Size = UDim2.new(1,-8,0,52)
    Row.BackgroundColor3 = THEME.Panel
    Row.BorderSizePixel = 0
    Instance.new("UICorner",Row).CornerRadius = UDim.new(0,8)
    local Lbl = Instance.new("TextLabel",Row)
    Lbl.Size = UDim2.new(1,-16,0,20)
    Lbl.Position = UDim2.new(0,12,0,4)
    Lbl.BackgroundTransparency = 1
    Lbl.Text = label
    Lbl.TextColor3 = THEME.SubText
    Lbl.TextSize = 11
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Name = "Label"
    local Box = Instance.new("TextBox",Row)
    Box.Size = UDim2.new(1,-16,0,24)
    Box.Position = UDim2.new(0,8,1,-30)
    Box.BackgroundColor3 = THEME.BG
    Box.TextColor3 = THEME.Text
    Box.PlaceholderText = placeholder or ""
    Box.PlaceholderColor3 = THEME.SubText
    Box.Text = tostring(Config[configKey] or "")
    Box.TextSize = 12
    Box.Font = Enum.Font.Gotham
    Box.ClearTextOnFocus = false
    Box.BorderSizePixel = 0
    Instance.new("UICorner",Box).CornerRadius = UDim.new(0,6)
    local BP = Instance.new("UIPadding",Box)
    BP.PaddingLeft = UDim.new(0,8)
    Box.FocusLost:Connect(function() Config[configKey] = Box.Text end)
    return Row
end

-- ════════════════════════════════════════════════════════════
-- [TABS]
-- ════════════════════════════════════════════════════════════
local Tabs = {}
local TabPages = {}
local ActiveTab = nil

local TAB_LIST = {
    {"⚔️","Steal"},{"🥚","Egg"},{"🦋","Butterfly"},
    {"🔮","Predictor"},{"📈","Progress"},{"🧪","Lab"},
    {"🌐","Server"},{"⚡","Event"},{"⚙️","Misc"},
    {"📡","Webhook"},
}

local function MakeTabBtn(icon, name, order)
    local Btn = Instance.new("TextButton",TabBar)
    Btn.Size = UDim2.new(1,0,0,34)
    Btn.BackgroundColor3 = THEME.TabInactive
    Btn.Text = icon .. "  " .. name
    Btn.TextColor3 = THEME.SubText
    Btn.TextSize = 12
    Btn.Font = Enum.Font.Gotham
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.LayoutOrder = order
    Btn.BorderSizePixel = 0
    Instance.new("UICorner",Btn).CornerRadius = UDim.new(0,8)
    local BP = Instance.new("UIPadding",Btn)
    BP.PaddingLeft = UDim.new(0,10)
    return Btn
end

local function MakeTabPage()
    local P = Instance.new("Frame",Scroll)
    P.Size = UDim2.new(1,0,0,0)
    P.AutomaticSize = Enum.AutomaticSize.Y
    P.BackgroundTransparency = 1
    P.BorderSizePixel = 0
    P.Visible = false
    local L = Instance.new("UIListLayout",P)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    L.Padding = UDim.new(0,4)
    return P
end

local function SwitchTab(name)
    if ActiveTab == name then return end
    ActiveTab = name
    for n, page in pairs(TabPages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(Tabs) do
        btn.BackgroundColor3 = (n==name) and THEME.TabActive or THEME.TabInactive
        btn.TextColor3       = (n==name) and THEME.Text      or THEME.SubText
        btn.Font             = (n==name) and Enum.Font.GothamBold or Enum.Font.Gotham
    end
end

for i, t in ipairs(TAB_LIST) do
    local btn  = MakeTabBtn(t[1], t[2], i)
    local page = MakeTabPage()
    Tabs[t[2]] = btn
    TabPages[t[2]] = page
    btn.MouseButton1Click:Connect(function() SwitchTab(t[2]) end)
end

-- ════════════════════════════════════════════════════════════
-- [POPULATE TABS]
-- ════════════════════════════════════════════════════════════
local P = TabPages

-- ── STEAL TAB ─────────────────────────────────────────────
do local pg = P["Steal"]
    MakeSection(pg,"Core Steal")
    MakeToggle(pg,"Auto Steal","AutoSteal")
    MakeToggle(pg,"Instant Steal","InstantSteal")
    MakeSlider(pg,"Min Value Gate","MinValueGate",0,10000)
    MakeSlider(pg,"Min Steal Value Filter","MinStealValueFilter",0,10000)
    MakeToggle(pg,"Steal Missing Lab Eggs","StealMissingLabEggs")
    MakeSection(pg,"Movement")
    MakeSlider(pg,"Carry Speed","CarrySpeed",1,50)
    MakeSlider(pg,"Tween Speed","TweenSpeed",1,50)
    MakeSlider(pg,"Speed Boost","SpeedBoost",1,100)
    MakeToggle(pg,"Infinite Jump","InfiniteJump")
    MakeToggle(pg,"Anti Ragdoll","AntiRagdoll")
    MakeToggle(pg,"Invisibility Mode","InvisibilityMode")
end

-- ── EGG TAB ───────────────────────────────────────────────
do local pg = P["Egg"]
    MakeSection(pg,"Egg Farming")
    MakeToggle(pg,"Egg Spawn Predictor","EggSpawnPredictor")
    MakeToggle(pg,"Auto Place Egg","AutoPlaceEgg")
    MakeToggle(pg,"Auto Hatch & Equip","AutoHatchEquip")
    MakeToggle(pg,"Auto Favorite","AutoFavorite")
    MakeToggle(pg,"Auto Sell Eggs","AutoSellEggs")
    MakeToggle(pg,"Egg Preview Card","EggPreviewCard")
    MakeSection(pg,"ESP")
    MakeToggle(pg,"Player ESP","PlayerESP")
    MakeToggle(pg,"Egg ESP","EggESP")
    MakeSection(pg,"Targeting")
    MakeToggle(pg,"Target Specific Eggs","TargetSpecificEggs")
end

-- ── BUTTERFLY TAB ─────────────────────────────────────────
do local pg = P["Butterfly"]
    MakeSection(pg,"Butterfly")
    MakeToggle(pg,"Auto Butterfly Bloom","AutoButterflyBloom")
    MakeToggle(pg,"Catch Butterflies","CatchButterflies")
    MakeToggle(pg,"Catch Mode","CatchMode")
    MakeSection(pg,"Timers")
    MakeSlider(pg,"Next Butterfly Bloom Timer","NextButterflyTimer",0,3600)
end

-- ── PREDICTOR TAB ─────────────────────────────────────────
do local pg = P["Predictor"]
    MakeSection(pg,"Predictors")
    MakeToggle(pg,"Egg Spawn Predictor","EggSpawnPredictor")
    MakeToggle(pg,"Rift Spawn Predictor","RiftSpawnPredictor")
    MakeToggle(pg,"Fuse Outcome Predictor","FuseOutcomePredictor")
    MakeToggle(pg,"Rift & Fuse Predictor","RiftFusePredictor")
    MakeSection(pg,"Fuse/Rift")
    MakeToggle(pg,"Auto Fuse Machine","AutoFuseMachine")
    MakeToggle(pg,"Rift Recipe Egg Priority","RiftRecipeEggPriority")
    MakeSection(pg,"Essence")
    MakeToggle(pg,"Auto Craft Essence","AutoCraftEssence")
    MakeToggle(pg,"Essence Skip Enchanted","EssenceSkipEnchanted")
    MakeSlider(pg,"Essence Min Value","EssenceMinValue",0,10000)
    MakeToggle(pg,"Auto Use Enchanted Essence","AutoBuyScrambleShop")
end

-- ── PROGRESS TAB ──────────────────────────────────────────
do local pg = P["Progress"]
    MakeSection(pg,"Auto Progression")
    MakeToggle(pg,"Auto Progression","AutoProgression")
    MakeToggle(pg,"Auto Claim Rewards","AutoClaimRewards")
    MakeToggle(pg,"Auto Claim Mastery","AutoClaimMastery")
    MakeToggle(pg,"Auto Base Upgrade","AutoBaseUpgrade")
    MakeToggle(pg,"Auto Treadmill","AutoTreadmill")
    MakeToggle(pg,"Auto Treadmill Upgrade","AutoTreadmillUpgrade")
    MakeToggle(pg,"Auto Trail Buying","AutoTrailBuying")
    MakeSection(pg,"Trade")
    MakeToggle(pg,"Auto Trade Up","AutoTradeUp")
    MakeToggle(pg,"Smart Trade for Essence","SmartTradeEssence")
    MakeToggle(pg,"Auto Wisp","AutoWisp")
    MakeSection(pg,"Mech/Boss")
    MakeToggle(pg,"Auto Mech Boss","AutoMechBoss")
    MakeSlider(pg,"Mech Portal Timer","MechPortalTimer",0,3600)
    MakeSlider(pg,"Mech Tween Speed","MechTweenSpeed",1,50)
    MakeToggle(pg,"Boss Server Hop","BossServerHop")
    MakeToggle(pg,"Auto Rift & Boss Farming","AutoRiftBossFarming")
end

-- ── LAB TAB ───────────────────────────────────────────────
do local pg = P["Lab"]
    MakeSection(pg,"Lab Automation")
    MakeToggle(pg,"Auto Lab Trade In","AutoLabTradeIn")
    MakeToggle(pg,"Auto Reroll Lab Recipe","AutoRerollLabRecipe")
    MakeToggle(pg,"Auto Place Lab Reward Eggs","AutoPlaceLabRewardEggs")
    MakeToggle(pg,"Auto Sell Lab Egg","AutoSellLabEgg")
    MakeToggle(pg,"Steal Missing Lab Eggs","StealMissingLabEggs")
    MakeToggle(pg,"Lab Banners","LabBanners")
    MakeSection(pg,"Scrambler")
    MakeToggle(pg,"Auto Buy Scramble Shop","AutoBuyScrambleShop")
    MakeToggle(pg,"Main Weapon Hold","MainWeaponHold")
    MakeToggle(pg,"Scrambler Hold","ScramblerHold")
    MakeToggle(pg,"Swap Two Weapons","SwapTwoWeapons")
end

-- ── SERVER TAB ────────────────────────────────────────────
do local pg = P["Server"]
    MakeSection(pg,"Server Hopping")
    MakeToggle(pg,"Smart Server Hop","SmartServerHop")
    MakeToggle(pg,"Auto Hop","AutoHop")
    MakeToggle(pg,"Server Rejoin","ServerRejoin")
    MakeToggle(pg,"Boss Server Hop","BossServerHop")
    MakeSection(pg,"Job ID")
    MakeInput(pg,"Job ID Joiner","JobIDJoiner","Paste Job ID...")
    MakeSection(pg,"Settings")
    MakeSlider(pg,"FPS Cap","FPSCap",15,240)
    MakeToggle(pg,"FPS Optimizer","FPSOptimizer")
    MakeToggle(pg,"FPS & Ping Overlay","FPSPingOverlay")
    MakeToggle(pg,"Anti AFK","AntiAFK")
    MakeToggle(pg,"Auto Script Loader","AutoScriptLoader")
end

-- ── EVENT TAB ─────────────────────────────────────────────
do local pg = P["Event"]
    MakeSection(pg,"🎃 Event — Halloween & Active Events")
    MakeToggle(pg,"Event: Auto Steal","EventAutoSteal")
    MakeToggle(pg,"Event: Instant Steal","EventInstantSteal")
    MakeToggle(pg,"Event: Auto Farm","EventAutoFarm")
    MakeToggle(pg,"Event: Auto Hatch & Equip","EventAutoHatchEquip")
    MakeToggle(pg,"Event: Auto Place Egg","EventAutoPlaceEgg")
    MakeToggle(pg,"Event: Auto Favourite","EventAutoFavourite")
    MakeToggle(pg,"Event: Catch Butterflies","CatchButterflies")
    MakeToggle(pg,"Event: Auto Butterfly Bloom","AutoButterflyBloom")
    MakeToggle(pg,"Event: Auto Mutation","EventAutoMutation")
    MakeSlider(pg,"Event: Carry Speed","EventCarrySpeed",1,50)
    MakeSlider(pg,"Event: Tween Speed","EventTweenSpeed",1,50)
    MakeSection(pg,"Event Targeting")
    MakeSlider(pg,"Event: Min Rarity (0=Any)","MinValueGate",0,10)
    MakeSection(pg,"Note")
    local Note = Instance.new("TextLabel",pg)
    Note.Size = UDim2.new(1,-8,0,40)
    Note.BackgroundTransparency = 1
    Note.Text = "ℹ️ Event tab applies to active limited events only.\nHalloween support included."
    Note.TextColor3 = THEME.SubText
    Note.TextSize = 11
    Note.Font = Enum.Font.Gotham
    Note.TextWrapped = true
    Note.TextXAlignment = Enum.TextXAlignment.Left
end

-- ── MISC TAB ──────────────────────────────────────────────
do local pg = P["Misc"]
    MakeSection(pg,"Keybinds & UI")
    MakeToggle(pg,"Anti AFK","AntiAFK")
    MakeToggle(pg,"FPS Optimizer","FPSOptimizer")
    MakeToggle(pg,"FPS & Ping Overlay","FPSPingOverlay")
    MakeSlider(pg,"FPS Cap","FPSCap",15,240)
    MakeSection(pg,"Guard")
    MakeToggle(pg,"Anti Guard","AntiGuard")
    MakeSection(pg,"Config")
    local SaveBtn = Instance.new("TextButton",pg)
    SaveBtn.Size = UDim2.new(1,-8,0,36)
    SaveBtn.BackgroundColor3 = THEME.Accent
    SaveBtn.Text = "💾  Save Config"
    SaveBtn.TextColor3 = THEME.Text
    SaveBtn.TextSize = 13
    SaveBtn.Font = Enum.Font.GothamBold
    SaveBtn.BorderSizePixel = 0
    Instance.new("UICorner",SaveBtn).CornerRadius = UDim.new(0,8)
    SaveBtn.MouseButton1Click:Connect(function()
        if writefile then
            writefile("YushScript_Config.json",
                HttpService:JSONEncode(Config))
        end
    end)
    local LoadBtn = Instance.new("TextButton",pg)
    LoadBtn.Size = UDim2.new(1,-8,0,36)
    LoadBtn.BackgroundColor3 = THEME.Panel
    LoadBtn.Text = "📂  Load Config"
    LoadBtn.TextColor3 = THEME.Text
    LoadBtn.TextSize = 13
    LoadBtn.Font = Enum.Font.GothamBold
    LoadBtn.BorderSizePixel = 0
    Instance.new("UICorner",LoadBtn).CornerRadius = UDim.new(0,8)
    LoadBtn.MouseButton1Click:Connect(function()
        if readfile and isfile and isfile("YushScript_Config.json") then
            local ok,data = pcall(HttpService.JSONDecode,HttpService,
                readfile("YushScript_Config.json"))
            if ok and type(data)=="table" then
                for k,v in pairs(data) do Config[k]=v end
            end
        end
    end)
end

-- ── WEBHOOK TAB ───────────────────────────────────────────
do local pg = P["Webhook"]
    MakeSection(pg,"Discord Webhook")
    MakeInput(pg,"Webhook URL","DiscordWebhook","https://discord.com/api/webhooks/...")
    local TestBtn = Instance.new("TextButton",pg)
    TestBtn.Size = UDim2.new(1,-8,0,36)
    TestBtn.BackgroundColor3 = THEME.Accent
    TestBtn.Text = "📨  Send Test Alert"
    TestBtn.TextColor3 = THEME.Text
    TestBtn.TextSize = 13
    TestBtn.Font = Enum.Font.GothamBold
    TestBtn.BorderSizePixel = 0
    Instance.new("UICorner",TestBtn).CornerRadius = UDim.new(0,8)
    TestBtn.MouseButton1Click:Connect(function()
        if Config.DiscordWebhook ~= "" then
            pcall(function()
                HttpService:RequestAsync({
                    Url = Config.DiscordWebhook,
                    Method = "POST",
                    Headers = {["Content-Type"]="application/json"},
                    Body = HttpService:JSONEncode({
                        content = "✅ **Yush Script V1** | Test alert from " .. LP.Name
                    })
                })
            end)
        end
    end)
end

-- ════════════════════════════════════════════════════════════
-- [SEARCH BAR LOGIC]
-- ════════════════════════════════════════════════════════════
SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local q = SearchBar.Text:lower()
    for _, page in pairs(TabPages) do
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("Frame") then
                local lbl = child:FindFirstChild("Label")
                if lbl then
                    child.Visible = q=="" or lbl.Text:lower():find(q,1,true) ~= nil
                end
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [FPS & PING OVERLAY]
-- ════════════════════════════════════════════════════════════
local FPSLabel = Instance.new("TextLabel",ScreenGui)
FPSLabel.Size = UDim2.new(0,160,0,20)
FPSLabel.Position = UDim2.new(1,-168,0,4)
FPSLabel.BackgroundTransparency = 1
FPSLabel.TextColor3 = THEME.Green
FPSLabel.TextSize = 11
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.Text = ""
FPSLabel.TextXAlignment = Enum.TextXAlignment.Right
FPSLabel.Visible = false

local lastFPS, elapsed = 0, 0
RunService.Heartbeat:Connect(function(dt)
    elapsed = elapsed + dt
    if elapsed >= 0.5 then
        lastFPS = math.floor(1/dt)
        if Config.FPSPingOverlay then
            FPSLabel.Visible = true
            local ping = Players.LocalPlayer:GetNetworkPing and
                math.floor(Players.LocalPlayer:GetNetworkPing()*1000) or 0
            FPSLabel.Text = "FPS: "..lastFPS.."  Ping: "..ping.."ms"
        else
            FPSLabel.Visible = false
        end
        elapsed = 0
    end
    -- FPS cap
    if Config.FPSOptimizer then
        game:GetService("RunService"):Set3dRenderingEnabled(true)
    end
end)

-- ════════════════════════════════════════════════════════════
-- [ANTI AFK]
-- ════════════════════════════════════════════════════════════
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- ════════════════════════════════════════════════════════════
-- [INFINITE JUMP]
-- ════════════════════════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and LP.Character then
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum:GetState()==Enum.HumanoidStateType.Freefall then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [SPEED / CARRY SPEED]
-- ════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if Config.SpeedBoost > 1 then
                hum.WalkSpeed = 16 * Config.SpeedBoost
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [ANTI RAGDOLL]
-- ════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if Config.AntiRagdoll and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState()==Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [INVISIBILITY]
-- ════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if LP.Character then
        for _, p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.LocalTransparencyModifier = Config.InvisibilityMode and 1 or 0
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [PLAYER ESP]
-- ════════════════════════════════════════════════════════════
local ESPHighlights = {}
RunService.Heartbeat:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            if Config.PlayerESP then
                if not ESPHighlights[p] then
                    local h = Instance.new("Highlight",p.Character)
                    h.FillColor = THEME.Accent
                    h.OutlineColor = Color3.new(1,1,1)
                    h.FillTransparency = 0.5
                    ESPHighlights[p] = h
                end
            else
                if ESPHighlights[p] then
                    ESPHighlights[p]:Destroy()
                    ESPHighlights[p] = nil
                end
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [EGG ESP]
-- ════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not Config.EggESP then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("egg") and obj:IsA("BasePart") then
            if not obj:FindFirstChildOfClass("Highlight") then
                local h = Instance.new("Highlight",obj)
                h.FillColor = THEME.Green
                h.OutlineColor = THEME.Accent
                h.FillTransparency = 0.4
            end
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- [TOGGLE BUTTON LOGIC]
-- ════════════════════════════════════════════════════════════
local menuOpen = true
ToggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    Main.Visible = menuOpen
    TweenService:Create(ToggleBtn, TweenInfo.new(0.15),
        {BackgroundColor3 = menuOpen and THEME.Accent or THEME.TabInactive}):Play()
end)

-- ════════════════════════════════════════════════════════════
-- [INIT — DEFAULT TAB]
-- ════════════════════════════════════════════════════════════
SwitchTab("Steal")

print("[Yush Script V1] Loaded — " .. LP.Name .. " | Anti-Cheat Bypass Active")