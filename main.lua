-- ════════════════════════════════════════════════════════════════════
--  YUSH HUB  |  Steal An Egg Script
--  Version 4.4.0  (Production)
--  Made by https://t.me/PrimeYush :)
--  Credits to @YushPogi
-- ════════════════════════════════════════════════════════════════════

local Library = loadstring(game:HttpGet("https://pastefy.app/2eRdp0K5/raw"))()

do
    local prev = _G.YushStealAnEgg
    if prev and type(prev.Unload) == "function" then pcall(prev.Unload) end
end

local HUB = { conns = {}, drawings = {}, highlights = {}, overlays = {}, dead = false }
_G.YushStealAnEgg = HUB
local function track(conn) table.insert(HUB.conns, conn); return conn end
local function trackDrawing(d) if d then table.insert(HUB.drawings, d) end; return d end

-- ════════════════════════════════════════════════════════════════════
-- WINDOW — YUSH HUB, left tabs, floating top-center, minimizable
-- ════════════════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Name             = "YUSH HUB",
    Subtitle         = "",
    LoadingAnimation = true,
    LoadingText      = "Yush",
    LoadingDuration  = 1.5,
    TabLocation      = "Left",
    Draggable        = true,
    HideClose        = true,
    Minimizable      = true,
    Position         = UDim2.new(0.5, 0, 0, 10),
    AnchorPoint      = Vector2.new(0.5, 0),
    ShowPlayerInfo   = true,  -- left sidebar: avatar + username only
    Theme            = "Dark",
})

-- ════════════════════════════════════════════════════════════════════
-- FPS / PING  OVERLAY  (top bar, always visible)
-- ════════════════════════════════════════════════════════════════════
local _fpsLabel   = nil
local _fpsFrames  = 0
local _fpsTimer   = 0
local _lastFps    = 0

local function buildFpsPingOverlay()
    pcall(function()
        local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
        local old = guiParent:FindFirstChild("_YushFpsPing")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name            = "_YushFpsPing"
        sg.ResetOnSpawn    = false
        sg.IgnoreGuiInset  = true
        sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
        sg.Parent          = guiParent
        table.insert(HUB.overlays, sg)

        local frame = Instance.new("Frame")
        frame.Size                 = UDim2.fromOffset(220, 24)
        frame.Position             = UDim2.new(0.5, -110, 0, 4)
        frame.BackgroundColor3     = Color3.fromRGB(12, 12, 14)
        frame.BackgroundTransparency = 0.18
        frame.BorderSizePixel      = 0
        frame.Parent               = sg

        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

        local stroke = Instance.new("UIStroke", frame)
        stroke.Color     = Color3.fromRGB(80, 80, 90)
        stroke.Thickness = 1
        stroke.Transparency = 0.5

        local lbl = Instance.new("TextLabel")
        lbl.Size                 = UDim2.fromScale(1, 1)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3           = Color3.fromRGB(230, 230, 230)
        lbl.Font                 = Enum.Font.GothamBold
        lbl.TextSize             = 12
        lbl.Text                 = "YUSH HUB  |  FPS: --  |  Ping: -- ms"
        lbl.Parent               = frame
        _fpsLabel = lbl
    end)
end

buildFpsPingOverlay()

-- ════════════════════════════════════════════════════════════════════
-- PLAYER INFO OVERLAY  (bottom-center)
-- ════════════════════════════════════════════════════════════════════
local function -- buildPlayerInfoOverlay()  -- removed: player card lives in left sidebar only
    pcall(function()
        local Players    = game:GetService("Players")
        local LP         = Players.LocalPlayer
        local guiParent  = (gethui and gethui()) or game:GetService("CoreGui")
        local old        = guiParent:FindFirstChild("_YushPlayerInfo")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name            = "_YushPlayerInfo"
        sg.ResetOnSpawn    = false
        sg.IgnoreGuiInset  = true
        sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
        sg.Parent          = guiParent
        table.insert(HUB.overlays, sg)

        local frame = Instance.new("Frame")
        frame.Size                 = UDim2.fromOffset(220, 52)
        frame.Position             = UDim2.new(0.5, -110, 1, -64)
        frame.BackgroundColor3     = Color3.fromRGB(12, 12, 14)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel      = 0
        frame.Parent               = sg

        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

        local stroke = Instance.new("UIStroke", frame)
        stroke.Color       = Color3.fromRGB(80, 80, 90)
        stroke.Thickness   = 1
        stroke.Transparency = 0.4

        -- Avatar
        local avatar = Instance.new("ImageLabel")
        avatar.Size                   = UDim2.fromOffset(38, 38)
        avatar.Position               = UDim2.fromOffset(7, 7)
        avatar.BackgroundTransparency = 1
        avatar.Image                  = "https://www.roblox.com/headshot-thumbnail/image?userId="
                                        .. LP.UserId
                                        .. "&width=420&height=420&format=png"
        avatar.Parent = frame
        Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

        local displayLbl = Instance.new("TextLabel")
        displayLbl.Size                 = UDim2.new(1, -54, 0, 22)
        displayLbl.Position             = UDim2.fromOffset(50, 6)
        displayLbl.BackgroundTransparency = 1
        displayLbl.TextColor3           = Color3.fromRGB(240, 240, 240)
        displayLbl.Font                 = Enum.Font.GothamBold
        displayLbl.TextSize             = 13
        displayLbl.TextXAlignment       = Enum.TextXAlignment.Left
        displayLbl.TextTruncate         = Enum.TextTruncate.AtEnd
        displayLbl.Text                 = LP.DisplayName
        displayLbl.Parent               = frame

        local userLbl = Instance.new("TextLabel")
        userLbl.Size                 = UDim2.new(1, -54, 0, 16)
        userLbl.Position             = UDim2.fromOffset(50, 30)
        userLbl.BackgroundTransparency = 1
        userLbl.TextColor3           = Color3.fromRGB(140, 140, 150)
        userLbl.Font                 = Enum.Font.Gotham
        userLbl.TextSize             = 11
        userLbl.TextXAlignment       = Enum.TextXAlignment.Left
        userLbl.TextTruncate         = Enum.TextTruncate.AtEnd
        userLbl.Text                 = "@" .. LP.Name
        userLbl.Parent               = frame
    end)
end

buildPlayerInfoOverlay()

-- ════════════════════════════════════════════════════════════════════
-- CONFIG / FLAG PERSISTENCE
-- ════════════════════════════════════════════════════════════════════
local HAS_CONFIG = type(Library.SaveConfig) == "function"
    and type(Library.LoadConfig) == "function"
    and type(Library.ListConfigs) == "function"
local CONFIG_NAME = "yushhub_stealanegg"

-- Auto-load last config on execute so toggles persist across rejoin
task.defer(function()
    if HAS_CONFIG then
        pcall(function()
            Library:LoadConfig(CONFIG_NAME)
        end)
    end
end)

-- Auto-save on leave / unload so state returns next execute
local function AutoSaveConfig()
    if HAS_CONFIG then
        pcall(function() Library:SaveConfig(CONFIG_NAME) end)
    end
end

local dropdownResync = {}
local function registerResync(handle, applyFn)
    if handle and applyFn then
        table.insert(dropdownResync, function() applyFn(handle:Get()) end)
    end
end
local function ResyncAll()
    for _, fn in ipairs(dropdownResync) do pcall(fn) end
end

-- ════════════════════════════════════════════════════════════════════
-- SERVICES & LOCALS
-- ════════════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local ReplicatedStorage = RS
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")

local LP          = Players.LocalPlayer
local LocalPlayer = LP

local function GetCamera()
    return Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end

-- Instant ProximityPrompt hold eliminator
pcall(function()
    local pps = game:GetService("ProximityPromptService")
    track(pps.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player == LP and tostring(prompt) == "CarryAreaEgg" then
            prompt.HoldDuration = 0
        end
    end))
end)

-- Anti-Robux purchase prompt
pcall(function()
    local coreGui = game:GetService("CoreGui")
    track(coreGui.ChildAdded:Connect(function(child)
        if child.Name == "PurchasePrompt" then
            task.wait(0.04)
            pcall(function()
                local cancel = child:FindFirstChild("CancelButton", true)
                if cancel and typeof(cancel) == "Instance" and cancel:IsA("GuiButton") then
                    pcall(function() cancel.MouseButton1Click:Fire() end)
                end
            end)
        end
    end))
end)

local function Notify(title, content, kind, dur)
    pcall(function()
        Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = dur or 2.5 })
    end)
end

local function safeCallback(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            pcall(Notify, "Yush HUB", "Error: " .. tostring(err), "Error", 4)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════
-- CLIENT AC NEUTRALIZER — LAYER 1
-- ════════════════════════════════════════════════════════════════════
local function bypassClientDetections()
    if typeof(filtergc) ~= "function" or typeof(debug) ~= "table"
        or typeof(debug.getupvalues) ~= "function" then
        return false, "no filtergc"
    end
    local ok, fn = pcall(function()
        return filtergc("function", { Constants = { "gmatch", "GetFullName" } }, true)
    end)
    if not ok or type(fn) ~= "function" then return false, "filter miss" end
    local setMeta = (typeof(setrawmetatable) == "function" and setrawmetatable)
        or (typeof(setmetatable) == "function" and setmetatable)
    if not setMeta then return false, "no setmeta" end
    local blocked = 0
    local okUv, ups = pcall(debug.getupvalues, fn)
    if not okUv or type(ups) ~= "table" then return false, "no upvalues" end
    for _, tbl in pairs(ups) do
        if typeof(tbl) == "table" then
            local okSet = pcall(setMeta, tbl, { __newindex = function() end })
            if okSet then blocked = blocked + 1 end
        end
    end
    return blocked > 0, blocked
end
pcall(bypassClientDetections)

-- Shared GC heap scanner (sliced, mobile-safe)
local function ScanGCHeap(step, perChunk)
    local scan = getgc or (debug and debug.getgc)
    if type(scan) ~= "function" then return end
    local ok, objects = pcall(scan, true)
    if not ok or type(objects) ~= "table" then return end
    perChunk = perChunk or 400
    for i = 1, #objects do
        local obj = objects[i]
        objects[i] = nil
        local okStep, stop = pcall(step, obj)
        if okStep and stop == true then return end
        if i % perChunk == 0 then task.wait() end
    end
end

-- AC Layers 2-5 (background, one-at-a-time)
local AcSlices = {}
do
    function AcSlices.FreezeTables()
        local setmeta = setrawmetatable or setmetatable
        local getmeta = getrawmetatable or getmetatable
        if not setmeta then return end
        ScanGCHeap(function(obj)
            if typeof(obj) ~= "table" or (getmeta and getmeta(obj)) then return end
            local mainrun = false
            for _, v in pairs(obj) do
                if v == obj then mainrun = true; break end
            end
            if not mainrun then return end
            for _, v in pairs(obj) do
                if typeof(v) == "number" and v >= 1 and v <= 3 and obj[v] == nil then
                    pcall(setmeta, obj, { __newindex = function() end }); break
                end
            end
        end)
    end

    function AcSlices.WipeUGI()
        local getconstants = getconstants or (debug and debug.getconstants)
        local setconstant  = setconstant  or (debug and debug.setconstant)
        local islclosure   = islclosure   or function(f) return not pcall(setfenv, getfenv(f)) end
        if not (getconstants and setconstant and debug and debug.info) then return end
        ScanGCHeap(function(Function)
            if typeof(Function) ~= "function" or not islclosure(Function) then return end
            local ok, Source = pcall(debug.info, Function, "s")
            if not ok or type(Source) ~= "string" then return end
            if not Source:find("ReplicatedFirst", 1, true) or not Source:find("UGI", 1, true) then return end
            local okC, Constants = pcall(getconstants, Function)
            if not okC or type(Constants) ~= "table" then return end
            for Index, Constant in next, Constants do
                if type(Constant) == "string" and Constant == "Humanoid" then
                    pcall(setconstant, Function, Index, "")
                end
            end
        end)
    end

    function AcSlices.ScrubX14()
        local getconstants = getconstants or (debug and debug.getconstants)
        local islclosure   = islclosure   or function(fn) return not pcall(setfenv, getfenv(fn)) end
        local HookFn       = hookfunction or replaceclosure or hookfunc
        if not (getconstants and HookFn and debug and debug.getstack and debug.setstack) then return end
        ScanGCHeap(function(fn)
            if typeof(fn) ~= "function" or not islclosure(fn) then return end
            local ok, consts = pcall(getconstants, fn)
            if not ok or type(consts) ~= "table" or not table.find(consts, "X-14") then return end
            local cb = nil
            pcall(function()
                cb = HookFn(fn, function(...)
                    local stack = debug.getstack(1)
                    if type(stack) == "table" then
                        for idx, val in pairs(stack) do
                            if val == "X-14" then pcall(debug.setstack, 1, idx, nil) end
                        end
                    end
                    if cb then return cb(...) end
                end)
            end)
        end)
    end

    function AcSlices.SanitizeState()
        local islclosure    = islclosure    or function(v) return not pcall(setfenv, getfenv(v)) end
        local getupvalues   = getupvalues   or (debug and debug.getupvalues)
        local getupvalue    = getupvalue    or (debug and debug.getupvalue)
        local setupvalue    = setupvalue    or (debug and debug.setupvalue)
        local clonefunction = clonefunction or function(f) return function(...) return f(...) end end
        if not (getupvalues and getupvalue and setupvalue) then return end
        ScanGCHeap(function(v)
            if typeof(v) ~= "function" or not islclosure(v) then return end
            local ok, upvs = pcall(getupvalues, v)
            if not ok or type(upvs) ~= "table" or #upvs ~= 19 then return end
            local ok2, u2 = pcall(getupvalue, v, 2)
            if not ok2 or typeof(u2) ~= "function" then return end
            local old = clonefunction(u2)
            pcall(setupvalue, v, 2, function(a, b)
                if b and typeof(b) == "table" then pcall(setmetatable, b, {}) end
                return old(a, b)
            end)
        end)
    end
end

task.spawn(function()
    pcall(AcSlices.FreezeTables); task.wait()
    pcall(AcSlices.WipeUGI);     task.wait()
    pcall(AcSlices.ScrubX14);    task.wait()
    pcall(AcSlices.SanitizeState)
end)

-- ════════════════════════════════════════════════════════════════════
-- CHARACTER HELPERS
-- ════════════════════════════════════════════════════════════════════
local function findChar() return LP.Character end
local function findHum()
    local ch = LP.Character
    return ch and ch:FindFirstChildOfClass("Humanoid")
end
local function findHRP()
    local ch = LP.Character
    return ch and (ch:FindFirstChild("HumanoidRootPart")
        or ch.PrimaryPart
        or ch:FindFirstChildWhichIsA("BasePart"))
end
local GetCharacter = findChar
local GetHumanoid  = findHum
local GetHRP       = findHRP
local function GetRootCFrame()
    local hrp = findHRP()
    return hrp and hrp.CFrame
end

-- ════════════════════════════════════════════════════════════════════
-- BAC TELEMETRY PACKET SPOOFER
-- ════════════════════════════════════════════════════════════════════
local bxor   = bit32.bxor
local unpack = table.unpack

local function isGuid(n)
    return #n==36 and n:sub(9,9)=="-" and n:sub(14,14)=="-"
        and n:sub(19,19)=="-" and n:sub(24,24)=="-"
        and n:gsub("-",""):match("^%x+$")~=nil
end

local remoteSet, anyRemote = {}, nil

local function scanRemotes()
    for _, s in ipairs(game:GetChildren()) do
        local ok, list = pcall(s.GetDescendants, s)
        if ok and list then
            for _, o in ipairs(list) do
                if o:IsA("RemoteEvent") and isGuid(o.Name) then
                    remoteSet[o] = true
                    anyRemote = anyRemote or o
                end
            end
        end
    end
end
scanRemotes()

local function parseCounter(v)
    if type(v) ~= "string" then return end
    local n = v:match("^X%-(%d+)$")
    return n and tonumber(n)
end

local function looksLikeState(t, r)
    if type(t) ~= "table" then return false end
    local hR, hM = false, false
    local ok = pcall(function()
        for _, v in pairs(t) do
            if v == r then hR = true
            elseif type(v) == "string" and v:match("^X%-%d+$") then hM = true end
        end
    end)
    return ok and hR and hM
end

local function findState(r)
    for l=2,24 do
        local _, fn = pcall(debug.info, l, "f")
        if type(fn) == "function" then
            local _, ups = pcall(debug.getupvalues, fn)
            if type(ups) == "table" then
                for _, v in pairs(ups) do
                    if looksLikeState(v, r) then return v end
                    if type(v) == "table" then
                        local nested
                        pcall(function()
                            for _, x in pairs(v) do
                                if looksLikeState(x, r) then nested = x; return end
                            end
                        end)
                        if nested then return nested end
                    end
                end
            end
        end
    end
end

local function mapState(st, a1, a2)
    local m = {}
    for k, v in pairs(st) do
        if type(v) == "string" then
            if v:match("^X%-%d+$") then m.marker = m.marker or k
            elseif a1 and v == a1 then m.arg1 = m.arg1 or k
            elseif a2 and v == a2 then m.arg2 = m.arg2 or k end
        end
    end
    return m
end

local model = nil

local function digits(n)
    n = n % 1000
    return math.floor(n/100), math.floor(n/10)%10, n%10
end

local function encode(m, c)
    local d1, d2, d3 = digits(c)
    return m.prefix .. string.char(bxor(d1, m.k1), bxor(d2, m.k2), bxor(d3, m.k3))
end

local function learn(r, a1, a2)
    local st = findState(r)
    if not st then return end
    local map = mapState(st, a1, a2)
    if not map.marker then return end
    local c = parseCounter(rawget(st, map.marker))
    if not c then return end
    local d1, d2, d3 = digits(c)
    local m = {
        state = st, map = map, remote = r,
        prefix = a1:sub(1, 9),
        k1 = bxor(a1:byte(10), d1),
        k2 = bxor(a1:byte(11), d2),
        k3 = bxor(a1:byte(12), d3),
        offset = c - os.time(),
        arg2 = a2
    }
    if encode(m, c) == a1 then return m end
end

local function liveCounter(m)
    if m.state and m.map.marker then
        local _, raw = pcall(rawget, m.state, m.map.marker)
        local c = parseCounter(raw)
        if c and math.abs((c - os.time()) - m.offset) <= 5 then return c end
    end
    return os.time() + m.offset
end

local function refreshArg2(m)
    if m.state and m.map.arg2 then
        local _, v = pcall(rawget, m.state, m.map.arg2)
        if type(v) == "string" then m.arg2 = v end
    end
    return m.arg2
end

local HookFn = hookfunction or replaceclosure or hookfunc or detour_function

if anyRemote and HookFn then
    local oldFire
    oldFire = HookFn(anyRemote.FireServer, function(self, ...)
        local args = table.pack(...)
        if not remoteSet[self] then return oldFire(self, unpack(args, 1, args.n)) end
        local a1 = args[1]
        if type(a1) == "string" and #a1 == 12 then
            if not model then
                model = learn(self, a1, args[2])
            else
                local c = parseCounter(rawget(model.state, model.map.marker))
                if c and encode(model, c) ~= a1 then
                    local m = learn(self, a1, args[2])
                    if m then m.spoofed = model.spoofed; model = m end
                end
            end
            return oldFire(self, unpack(args, 1, args.n))
        end
        if model and type(a1) == "string" and #a1 == 4 then
            local c = liveCounter(model)
            args[1] = encode(model, c)
            args[2] = refreshArg2(model)
            model.spoofed = (model.spoofed or 0) + 1
            return oldFire(self, unpack(args, 1, math.max(args.n, 2)))
        end
        return oldFire(self, unpack(args, 1, args.n))
    end)
end

task.spawn(function()
    while not HUB.dead do
        task.wait(10)
        local alive = false
        for r in pairs(remoteSet) do
            if r:IsDescendantOf(game) then alive = true; break end
        end
        if not alive then
            table.clear(remoteSet); anyRemote = nil; model = nil; scanRemotes()
        end
    end
end)

-- Memory Evidence Scrubber
task.spawn(function()
    if not (getgc or (debug and debug.getgc)) then return end
    local st = nil
    local misses = 0
    local function findIntegrityTable()
        local found = nil
        ScanGCHeap(function(o)
            if found then return true end
            if type(o) ~= "table" then return end
            local hit = false
            pcall(function()
                hit = (rawget(o, "ValidationLocked") ~= nil and rawget(o, "Evidence") ~= nil)
                    or (rawget(o, "ThreatLevel") ~= nil and rawget(o, "LastObservedSample") ~= nil)
            end)
            if hit then found = o; return true end
        end, 250)
        return found
    end
    track(LP.CharacterAdded:Connect(function()
        task.wait(1); st = findIntegrityTable()
    end))
    while not HUB.dead do
        if not st then
            st = findIntegrityTable()
            if not st then
                misses = misses + 1
                local waitFor = math.min(5 * (2 ^ math.min(misses - 1, 3)), 30)
                local slept = 0
                while slept < waitFor and not HUB.dead do
                    task.wait(0.5); slept = slept + 0.5
                end
            elseif misses > 0 then misses = 0 end
        end
        if st then
            pcall(function()
                local ev = rawget(st, "Evidence")
                if type(ev) == "table" then
                    if (tonumber(ev.Speed)    or 0) > 0 then rawset(ev, "Speed",    0) end
                    if (tonumber(ev.Teleport) or 0) > 0 then rawset(ev, "Teleport", 0) end
                    if (tonumber(ev.Flight)   or 0) > 0 then rawset(ev, "Flight",   0) end
                end
                if rawget(st, "ThreatLevel") ~= "Trusted" then rawset(st, "ThreatLevel", "Trusted") end
                if rawget(st, "ValidationLocked") == true  then rawset(st, "ValidationLocked", false) end
                if rawget(st, "FirstSuspiciousAt") ~= nil  then rawset(st, "FirstSuspiciousAt", nil) end
                if rawget(st, "KickQueued") == true         then rawset(st, "KickQueued",  false) end
                if rawget(st, "TamperScore") ~= nil         then rawset(st, "TamperScore",  0) end
                if rawget(st, "InvalidHeartbeatCount") ~= nil then rawset(st, "InvalidHeartbeatCount", 0) end
                local los = rawget(st, "LastObservedSample")
                if los ~= nil then
                    for _, k in ipairs({ "LastGameplayTrustedSample","LastValidatedSample",
                        "LastValidatedGroundedSample","LastConfirmedGroundSample","LastGoodSample" }) do
                        if rawget(st, k) == nil then rawset(st, k, los) end
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- GAME NETWORKING & MODULE INTEGRATION
-- ════════════════════════════════════════════════════════════════════
local EggState, PlotState, AreasData, RarityData, AssetsData, EggToolDisplay, AreaEggSlotIdentity
pcall(function() EggState      = require(RS.Client.EggState) end)
pcall(function() PlotState     = require(RS.Client.PlotState) end)
pcall(function() AreasData     = require(RS.Data.Areas) end)
pcall(function() RarityData    = require(RS.Data.Rarity) end)
pcall(function() AssetsData    = require(RS.Data.Assets) end)
local SaveModule
pcall(function() SaveModule    = require(RS.Shared.Save) end)
pcall(function() EggToolDisplay = require(RS.Shared.Eggs.EggToolDisplay) end)
pcall(function()
    AreaEggSlotIdentity =
        (RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Util")
            and require(RS.Shared.Util.AreaEggSlotIdentity))
        or (RS:FindFirstChild("Util") and require(RS.Util.AreaEggSlotIdentity))
        or (RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Utils")
            and require(RS.Shared.Utils.AreaEggSlotIdentity))
end)

local function GetNetRemote(name)
    local net = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
    return net and net:FindFirstChild(name)
end

local function GetLocalSlot()
    if PlotState and PlotState.ResolveLocalSlot then
        local ok, slot = pcall(PlotState.ResolveLocalSlot)
        if ok and slot then return slot end
    end
    return 1
end

local function GetLocalPlotCenter()
    local plotObj = PlotState and PlotState.ResolvePlot and PlotState.ResolvePlot()
    local pt = plotObj and plotObj.CenterPoint
        and (typeof(plotObj.CenterPoint) == "Vector3" and plotObj.CenterPoint
            or (plotObj.CenterPoint:IsA("BasePart") and plotObj.CenterPoint.Position))
    if pt then
        return Vector3.new(pt.X, math.max(pt.Y, 70.4), pt.Z),
               CFrame.new(pt.X, math.max(pt.Y, 70.4), pt.Z)
    end
    return Vector3.new(464.7, 70.4, -364.0), CFrame.new(464.7, 70.4, -364.0)
end

-- ════════════════════════════════════════════════════════════════════
-- MOVEMENT HELPERS
-- ════════════════════════════════════════════════════════════════════
local MAIN_ROAD_Z       = -364.5
local stealMovementMethod = "Fly Up & Down"  -- NEW DEFAULT: always fly high
local avoidTrapsEnabled = true

local Boss = {
    autoJoin   = false, autoMastery = false, claimed = {},
    arenaReady = false, autoFight = false, hazardImmune = false,
    arenaApproach = "Crystals First", glideSpeed = 260,
    engageDistance = 7, swingInterval = 0.15,
    _target = nil, _targetPart = nil, _targetAt = 0,
    _stepAt = 0, _swingAt = 0, _batAt = 0,
    hazardHook = false, hazardHookTried = false, _hazardRemotes = {},
}

local function SafeTeleport(targetPos)
    local root = findHRP()
    if not root or not targetPos then return false end
    root.CFrame = CFrame.new(targetPos.X, math.max(targetPos.Y, 70.0), targetPos.Z)
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function NeutralizeTraps()
    local debris = Workspace:FindFirstChild("__DEBRIS")
    if not debris then return end
    for _, d in ipairs(debris:GetChildren()) do
        if d.Name == "PlayerTrap" and d:GetAttribute("Owner") ~= LP.Name then
            if d:IsA("BasePart") then d.CanTouch = false; d.CanQuery = false end
            for _, c in ipairs(d:GetChildren()) do
                if c:IsA("BasePart") then
                    c.CanTouch = false; c.CanQuery = false
                    if c.Name == "Hitbox" then c.CFrame = CFrame.new(0, -999, 0) end
                end
            end
            local tt = d:FindFirstChildWhichIsA("TouchTransmitter", true)
            if tt then pcall(function() tt:Destroy() end) end
        end
    end
end

local glideSpeed = 750

local function MoveToPoint(target, speed, easeOut)
    local hrp = findHRP()
    if not hrp or not target then return false end
    local start = hrp.Position
    local dist  = (target - start).Magnitude
    if dist < 1.0 then
        hrp.CFrame = CFrame.new(target.X, math.max(target.Y, 70.0), target.Z)
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        return true
    end
    speed = math.clamp(tonumber(speed) or tonumber(glideSpeed) or 750, 50, 750)
    local t0, totalDist = os.clock(), dist
    while not HUB.dead do
        local dt     = RunService.Heartbeat:Wait()
        local curPos = hrp.Position
        local toTarget = target - curPos
        local remain   = toTarget.Magnitude
        if remain < 1.0 then break end
        local stepSpeed = speed
        if easeOut then
            local progress = 1 - math.clamp(remain / totalDist, 0, 1)
            stepSpeed = math.max(speed * (1 - progress * 0.8), 35)
        end
        local step = math.min(stepSpeed * dt, remain)
        local dir  = toTarget.Unit
        local nextPos = curPos + dir * step
        hrp.CFrame = CFrame.lookAt(nextPos, nextPos + dir)
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if os.clock() - t0 > (totalDist / 50 + 5) then break end
    end
    hrp.CFrame = CFrame.new(target.X, math.max(target.Y, 70.0), target.Z)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function FlyToPoint(target, speed, easeOut)
    local hrp = findHRP()
    if not hrp or not target then return false end
    local start = hrp.Position
    local dist  = (target - start).Magnitude
    if dist < 1.0 then
        hrp.CFrame = CFrame.new(target.X, math.max(target.Y, 70.0), target.Z)
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        return true
    end
    speed = math.clamp(tonumber(speed) or tonumber(glideSpeed) or 750, 50, 750)
    local moveTime = math.max(dist / speed, 0.02)
    if easeOut then moveTime = moveTime * 1.25 end
    local t0    = os.clock()
    local delta = target - start
    local dir   = delta.Magnitude > 0.001 and delta.Unit or Vector3.new(1, 0, 0)
    while os.clock() - t0 < moveTime and not HUB.dead do
        RunService.Heartbeat:Wait()
        local linearAlpha = math.clamp((os.clock() - t0) / moveTime, 0, 1)
        local a = linearAlpha
        if easeOut then a = math.sin(linearAlpha * (math.pi / 2)) end
        local cur = start:Lerp(target, a)
        hrp.CFrame = CFrame.lookAt(cur, cur + dir)
        local curSpeed = speed
        if easeOut then curSpeed = math.max(speed * (1 - linearAlpha * 0.8), 35) end
        hrp.AssemblyLinearVelocity  = Vector3.new(dir.X * curSpeed,
            math.clamp(dir.Y * curSpeed, -15, 150), dir.Z * curSpeed)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    hrp.CFrame = CFrame.new(target.X, math.max(target.Y, 70.0), target.Z)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    return true
end

-- ── NEW: Fly Up-and-Over method (avoids all guards on the ground) ─────────────
local FLY_STEAL_ALTITUDE = 95   -- bat-safe cruise altitude (not too high)

local function TravelFlyHighApproach(targetPos, speed)
    local hrp = findHRP()
    if not hrp or not targetPos then return false end
    if avoidTrapsEnabled then pcall(NeutralizeTraps) end
    local cur  = hrp.Position
    local altY = math.max(cur.Y, targetPos.Y, 70.4) + FLY_STEAL_ALTITUDE
    -- Phase 1: straight up
    FlyToPoint(Vector3.new(cur.X, altY, cur.Z), speed, false)
    -- Phase 2: horizontal cruise at altitude
    FlyToPoint(Vector3.new(targetPos.X, altY, targetPos.Z), speed, false)
    -- Phase 3: descend to egg
    FlyToPoint(Vector3.new(targetPos.X, math.max(targetPos.Y, 70.4) + 1.5, targetPos.Z), speed, true)
    return true
end

local function TravelFlyHighReturn(basePos, speed)
    local hrp = findHRP()
    if not hrp or not basePos then return false end
    local cur  = hrp.Position
    local altY = math.max(cur.Y, basePos.Y, 70.4) + FLY_STEAL_ALTITUDE
    -- Phase 1: ascend right after grabbing egg
    FlyToPoint(Vector3.new(cur.X, altY, cur.Z), speed, false)
    -- Phase 2: horizontal cruise to above base
    FlyToPoint(Vector3.new(basePos.X, altY, basePos.Z), speed, false)
    -- Phase 3: descend to base pen
    FlyToPoint(Vector3.new(basePos.X, math.max(basePos.Y, 70.4) + 1.5, basePos.Z), speed, true)
    return true
end
-- ─────────────────────────────────────────────────────────────────────────────

local SAFE_BOUNDARY_X  = 580
local SAFE_ZONE_SPEED  = 245

local function TravelRoadPath(targetPos, speed, isApproach)
    local hrp = findHRP()
    if not hrp or not targetPos then return false end
    if avoidTrapsEnabled then pcall(NeutralizeTraps) end
    local startPos = hrp.Position
    local safeY    = math.max(startPos.Y, targetPos.Y, 70.4)
    local isReturningToBase = (targetPos.X < 560)
    if isReturningToBase and startPos.X > SAFE_BOUNDARY_X then
        MoveToPoint(Vector3.new(startPos.X, safeY, MAIN_ROAD_Z), speed, false)
        MoveToPoint(Vector3.new(SAFE_BOUNDARY_X, safeY, MAIN_ROAD_Z), speed, false)
        MoveToPoint(Vector3.new(targetPos.X, safeY, MAIN_ROAD_Z), SAFE_ZONE_SPEED, false)
        MoveToPoint(targetPos + Vector3.new(0, 1.2, 0), SAFE_ZONE_SPEED, isApproach == true)
    else
        MoveToPoint(Vector3.new(startPos.X, safeY, MAIN_ROAD_Z), speed, false)
        MoveToPoint(Vector3.new(targetPos.X, safeY, MAIN_ROAD_Z), speed, false)
        MoveToPoint(targetPos + Vector3.new(0, 1.2, 0), speed, isApproach == true)
    end
    return true
end

local function TravelFlyDirect(targetPos, speed, isApproach)
    local hrp = findHRP()
    if not hrp or not targetPos then return false end
    if avoidTrapsEnabled then pcall(NeutralizeTraps) end
    local startPos = hrp.Position
    local isReturningToBase = (targetPos.X < 560)
    local flyAltitude = math.max(startPos.Y, targetPos.Y, 70.4) + 28
    if isReturningToBase and startPos.X > SAFE_BOUNDARY_X then
        FlyToPoint(Vector3.new(startPos.X, flyAltitude, startPos.Z), speed, false)
        FlyToPoint(Vector3.new(SAFE_BOUNDARY_X, flyAltitude, MAIN_ROAD_Z), speed, false)
        FlyToPoint(Vector3.new(SAFE_BOUNDARY_X, 70.4, MAIN_ROAD_Z), SAFE_ZONE_SPEED, false)
        MoveToPoint(Vector3.new(targetPos.X, 70.4, MAIN_ROAD_Z), SAFE_ZONE_SPEED, false)
        MoveToPoint(targetPos + Vector3.new(0, 1.2, 0), SAFE_ZONE_SPEED, isApproach == true)
    else
        local totalDist = (targetPos - startPos).Magnitude
        if totalDist < 25 then
            FlyToPoint(Vector3.new(targetPos.X, math.max(targetPos.Y, 70.0) + 1.2, targetPos.Z), speed, isApproach == true)
            return true
        end
        FlyToPoint(Vector3.new(startPos.X, flyAltitude, startPos.Z), speed, false)
        FlyToPoint(Vector3.new(targetPos.X, flyAltitude, targetPos.Z), speed, false)
        FlyToPoint(Vector3.new(targetPos.X, math.max(targetPos.Y, 70.0) + 1.2, targetPos.Z), speed, isApproach == true)
    end
    return true
end

local function TravelSafeWalk(targetPos)
    local hum = findHum()
    local hrp = findHRP()
    if not hum or not hrp or not targetPos then return false end
    if avoidTrapsEnabled then pcall(NeutralizeTraps) end
    local startPos = hrp.Position
    for _, pt in ipairs({
        Vector3.new(startPos.X, startPos.Y, MAIN_ROAD_Z),
        Vector3.new(targetPos.X, targetPos.Y, MAIN_ROAD_Z),
        targetPos + Vector3.new(0, 1.2, 0)
    }) do
        if HUB.dead then break end
        hum:MoveTo(pt)
        local t0 = os.clock()
        while (hrp.Position - pt).Magnitude > 4.5 and os.clock() - t0 < 5 and not HUB.dead do
            task.wait(0.05)
        end
    end
    return true
end

local function TravelToDestination(targetPos, speed, isApproach)
    if stealMovementMethod == "Fly Up & Down" then
        return TravelFlyHighApproach(targetPos, speed)
    elseif stealMovementMethod == "Fly Glide" then
        return TravelFlyDirect(targetPos, speed, isApproach)
    elseif stealMovementMethod == "Safe Walk" then
        return TravelSafeWalk(targetPos)
    else
        return TravelRoadPath(targetPos, speed, isApproach)
    end
end

-- ════════════════════════════════════════════════════════════════════
-- RARITY & AREA DICTIONARIES
-- ════════════════════════════════════════════════════════════════════
local RARITY_SCORE_MAP = {
    ["LightDark"]     = 1300, ["Light & Dark"] = 1300,
    ["Titan"]         = 1100, ["Divine"]        = 1000,
    ["Transcendent"]  = 1000, ["Superior"]      = 1000,
    ["Eternal"]       = 900,  ["Limited"]       = 900,
    ["Secret"]        = 800,  ["Exotic"]        = 800,
    ["Cosmic"]        = 700,  ["Exclusive"]     = 700,
    ["Admin"]         = 700,  ["Mythic"]        = 600,
    ["Mythical"]      = 600,  ["Prismatic"]     = 600,
    ["Rainbow"]       = 600,  ["Squishy God"]   = 600,
    ["BrainrotGod"]   = 600,  ["Legendary"]     = 500,
    ["Epic"]          = 400,  ["Rare"]          = 300,
    ["SuperRare"]     = 200,  ["Celestial"]     = 200,
    ["Uncommon"]      = 200,  ["Basic"]         = 100,
    ["Common"]        = 100,
}

local AREA_COORDINATES = {
    ["Base / Plot"]    = Vector3.new(491.7, 70.4, -364.4),
    ["Stands & Shops"] = Vector3.new(539.5, 68.0, -364.5),
    ["Forest"]         = Vector3.new(596.0, 68.0, -328.0),
    ["Lake"]           = Vector3.new(744.0, 68.5, -408.0),
    ["Desert"]         = Vector3.new(948.0, 69.5, -323.0),
    ["Jungle"]         = Vector3.new(1188.0, 68.5, -408.0),
    ["Snow"]           = Vector3.new(1492.0, 69.0, -315.0),
    ["Volcano"]        = Vector3.new(1882.0, 68.0, -398.0),
    ["Abyss Ocean"]    = Vector3.new(2280.0, 68.0, -326.0),
    ["Prehistoric"]    = Vector3.new(2812.0, 69.0, -398.0),
    ["Cosmic"]         = Vector3.new(3390.0, 68.0, -324.0),
    ["Cherry Blossom"] = Vector3.new(4028.0, 68.5, -396.0),
    ["Titan Temple"]   = Vector3.new(4796.0, 69.5, -328.0),
    ["Light Dark"]     = Vector3.new(5660.0, 70.0, -331.0),
    ["Dragon Event"]   = Vector3.new(539.5, 68.0, -318.0),
}

local AREA_NAMES = {
    "Forest","Lake","Desert","Jungle","Snow","Volcano","Abyss Ocean",
    "Prehistoric","Cosmic","Cherry Blossom","Titan Temple","Light Dark","Angels & Demons",
}

local RARITY_NAMES = {
    "Light & Dark","Titan","Divine","Superior","Eternal","Limited","Secret","Exotic",
    "Cosmic","Exclusive","Mythic","Rainbow","Squishy God","Celestial","Legendary",
    "Epic","Rare","SuperRare","Uncommon","Common",
}

local MUTATION_FILTERS = {
    "Normal Only","Mutated Only","Parasite / Infested","Rainbow Only","Gold Only","Silver Only","Monstrous"
}

-- ════════════════════════════════════════════════════════════════════
-- AUTOMATION STATE
-- ════════════════════════════════════════════════════════════════════
local autoStealEnabled         = false
local rareEggHunter            = true
local stealBigEggsOnly         = false
local selectedStealRarities    = {}
local selectedStealAreas       = {}
local selectedMutationTypes    = {}
local stealDelay               = 1.5
local ignoredEggs              = {}
local savedReturnCFrame        = nil

local autoHatchEnabled         = false
local autoPlantEnabled         = false
local hatchCheckDelay          = 2.0

local autoUpgradeBase          = false
local autoUpgradeTreadmill     = false
local autoBuyTrails            = false
local autoEquipBestPets        = false
local autoClaimRewards         = false

local autoSellPets             = false
local autoSellEggs             = false
local selectedSellPetRarities  = {}
local selectedSellEggRarities  = {}

local DEFAULT_LOW_TIER_SELL    = {
    ["Common"]=true,["Uncommon"]=true,["Rare"]=true,
    ["Epic"]=true,["Legendary"]=true,["Mythic"]=true,
}
local SELL_REQUEST_DELAY = 0.1

local noKnockbackEnabled = true
local batAuraEnabled     = false
local batAuraRadius      = 20
local batAuraDelay       = 0.2
local antiRagdollEnabled = true

-- ════════════════════════════════════════════════════════════════════
-- ANTI GUARD — NEW SYSTEM
-- Disables guard hitboxes near player, heals continuously, blocks
-- guard damage remotes, and forcibly ends any ragdoll state.
-- ════════════════════════════════════════════════════════════════════
local antiGuardEnabled = false

local GUARD_NAME_PATTERNS = {
    "guard", "warden", "foreguard", "areaguard", "nestguard",
    "fieldguard", "egguard", "authoredguard"
}

local function isGuardModel(model)
    if not model:IsA("Model") then return false end
    local name = model.Name:lower()
    for _, pat in ipairs(GUARD_NAME_PATTERNS) do
        if name:find(pat, 1, true) then return true end
    end
    return false
end

local function DisableNearbyGuards(radius)
    local hrp = findHRP()
    if not hrp then return end
    radius = radius or 80

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isGuardModel(obj) then
            local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if pp and (pp.Position - hrp.Position).Magnitude <= radius then
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        -- Make guard parts non-interactive
                        part.CanTouch = false
                        part.CanQuery = false
                        -- Sink hitbox out of the map
                        if part.Name:lower():find("hitbox") or part.Name:lower():find("hit") then
                            pcall(function()
                                part.CFrame = CFrame.new(part.Position.X, -500, part.Position.Z)
                            end)
                        end
                    end
                    if part:IsA("TouchTransmitter") then
                        pcall(function() part:Destroy() end)
                    end
                end

                -- Pause guard AI humanoid so it stops chasing
                local guardHum = obj:FindFirstChildOfClass("Humanoid")
                if guardHum then
                    pcall(function()
                        guardHum.WalkSpeed  = 0
                        guardHum.JumpPower  = 0
                    end)
                end
            end
        end
    end
end

local function AntiGuardHeal()
    local hum = findHum()
    if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
        hum.Health = hum.MaxHealth
    end
end

-- Block guard damage/knockback remotes
local _guardRemoteBlocked = {}
local function BlockGuardRemotes()
    if not HookFn then return end
    local candidates = {
        "RE/Guard/Hit", "RE/Guard/Knockback", "RE/Guard/Alert",
        "RE/EggWorld/GuardHit", "RE/NestGuard/Hit",
    }
    for _, name in ipairs(candidates) do
        local remote = GetNetRemote(name)
        if remote and remote:IsA("RemoteEvent") and not _guardRemoteBlocked[remote] then
            _guardRemoteBlocked[remote] = true
            -- Block OnClientEvent by clearing its connections
            pcall(function()
                if getconnections then
                    for _, conn in ipairs(getconnections(remote.OnClientEvent)) do
                        pcall(function() conn:Disable() end)
                    end
                end
            end)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════
-- EGG LOGIC HELPERS
-- ════════════════════════════════════════════════════════════════════
local function getSellRarityFilter(selected)
    if not selected or next(selected) == nil then return DEFAULT_LOW_TIER_SELL end
    return selected
end

local function GetEggRarityInfo(egg)
    if not egg then return "Common", 100 end
    if egg.Rarity then
        local r    = egg.Rarity
        local name = type(r) == "table" and (r.DisplayName or r._id or r.Name) or tostring(r)
        local score = RARITY_SCORE_MAP[name]
            or (type(r) == "table" and tonumber(r.RarityNumber) and r.RarityNumber * 100)
            or 100
        return name, score
    end
    local cat = egg.AssetCategory or egg.Category or egg.Name
    if cat and AssetsData then
        local assetsDir = AssetsData.Directory or AssetsData
        local aInfo = assetsDir[cat]
        if aInfo and aInfo.Rarity then
            local r    = aInfo.Rarity
            local name = type(r) == "table" and (r.DisplayName or r._id or r.Name) or tostring(r)
            local score = RARITY_SCORE_MAP[name]
                or (type(r) == "table" and tonumber(r.RarityNumber) and r.RarityNumber * 100)
                or 100
            return name, score
        end
    end
    local areaData  = AreasData and (AreasData.Directory or AreasData)
        and (AreasData.Directory or AreasData)[egg.AreaId]
    local rarity    = areaData and areaData.Rarity
    local rarityId  = (type(rarity)=="table" and (rarity._id or rarity.DisplayName or rarity.Name))
        or (type(rarity)=="string" and rarity) or "Common"
    local raritiesTable = RarityData and (RarityData.Rarities or RarityData) or {}
    local rInfo     = raritiesTable[rarityId] or {}
    local rarityDisplayName = (type(rInfo)=="table" and (rInfo.DisplayName or rInfo._id))
        or (type(rarity)=="table" and rarity.DisplayName) or rarityId or "Common"
    local baseScore = RARITY_SCORE_MAP[rarityDisplayName] or RARITY_SCORE_MAP[rarityId]
        or (type(rarity)=="table" and tonumber(rarity.RarityNumber) and rarity.RarityNumber * 100)
        or 100
    return rarityDisplayName, baseScore
end

local function isRarityAllowed(rarityName, filter)
    if not filter or type(filter) ~= "table" then return true end
    local count = 0
    for _ in pairs(filter) do count = count + 1 end
    if count == 0 then return true end
    if filter[rarityName] == true then return true end
    local rLower = string.lower(tostring(rarityName))
    for k, v in pairs(filter) do
        if type(v) == "string" and string.lower(v) == rLower then return true end
        if type(k) == "string" and string.lower(k) == rLower and v == true then return true end
    end
    return false
end

local function ResolveAreaId(name)
    local dir = AreasData and AreasData.Directory
    if type(dir) ~= "table" then return tostring(name) end
    local lower = string.lower(tostring(name))
    for id, info in pairs(dir) do
        if string.lower(tostring(id)) == lower then return id end
        if type(info) == "table" and info.DisplayName
            and string.lower(tostring(info.DisplayName)) == lower then return id end
    end
    return tostring(name)
end

local function isAreaAllowed(areaId, filter)
    if not filter or type(filter) ~= "table" then return true end
    local count = 0
    for _ in pairs(filter) do count = count + 1 end
    if count == 0 then return true end
    if filter[areaId] == true then return true end
    local aLower = string.lower(tostring(areaId))
    for k, v in pairs(filter) do
        if type(v) == "string" and (string.lower(v) == aLower
            or string.lower(tostring(ResolveAreaId(v))) == aLower) then return true end
        if type(k) == "string" and string.lower(k) == aLower and v == true then return true end
    end
    return false
end

local function isMutationAllowed(muts, record, filter)
    local isParasite = (record and record.HasParasite == true)
        or (type(muts) == "table" and (table.find(muts,"Parasite") or table.find(muts,"Monstrous")))
        or (record and (record.BaseMutation=="Parasite" or record.BaseMutation=="Monstrous"))
    if not filter or type(filter) ~= "table" then return true end
    local count = 0
    for _ in pairs(filter) do count = count + 1 end
    if count == 0 then return true end
    local hasMut = type(muts) == "table" and #muts > 0
    local allowed = false
    for _, opt in pairs(filter) do
        if type(opt) == "string" then
            if opt == "Normal Only" and not hasMut and not isParasite then allowed = true
            elseif opt == "Mutated Only" and (hasMut or isParasite) then allowed = true
            elseif (opt == "Parasite / Infested" or opt == "Monstrous") and isParasite then allowed = true
            elseif opt == "Silver Only" and type(muts)=="table" and table.find(muts,"Silver") then allowed = true
            elseif opt == "Gold Only" and type(muts)=="table"
                and (table.find(muts,"Gold") or table.find(muts,"Golden")) then allowed = true
            elseif opt == "Rainbow Only" and type(muts)=="table" and table.find(muts,"Rainbow") then allowed = true
            end
        end
    end
    return allowed
end

local function isBigEgg(record)
    if not record then return false end
    local scale      = tonumber(record.AssetScale) or 1
    local nestScale  = tonumber(record.NestScale)  or 1
    return scale >= 1.35 or nestScale >= 1.0
end

-- ════════════════════════════════════════════════════════════════════
-- MATCHING & CARRYING HELPERS
-- ════════════════════════════════════════════════════════════════════
local function GetMatchingFieldEggs(areasFilter, raritiesFilter, mutationsFilter)
    if not EggState or not EggState.ReadFieldEggs then return {} end
    local ok, snapshot = pcall(EggState.ReadFieldEggs)
    if not ok or not snapshot or not snapshot.Records then return {} end
    local matched = {}
    for _, record in ipairs(snapshot.Records) do
        if record.State == "Slot" and record.BoundsCFrame then
            local isIgnored = ignoredEggs[record.Uid]
                and (os.clock() - ignoredEggs[record.Uid] < 2.5)
            if not isIgnored and (not stealBigEggsOnly or isBigEgg(record)) then
                local areaOk   = isAreaAllowed(record.AreaId, areasFilter)
                local rarityName, baseScore = GetEggRarityInfo(record)
                local rarityOk = isRarityAllowed(rarityName, raritiesFilter)
                local muts     = record.Mutations or {}
                local mutOk    = isMutationAllowed(muts, record, mutationsFilter)
                if areaOk and rarityOk and mutOk then
                    local mutBonus = 0
                    for _, m in ipairs(muts) do
                        if m == "Rainbow" then mutBonus = mutBonus + 35
                        elseif m == "Gold" or m == "Golden" then mutBonus = mutBonus + 20
                        elseif m == "Silver" then mutBonus = mutBonus + 10 end
                    end
                    if record.HasParasite == true
                        or (type(muts)=="table" and (table.find(muts,"Parasite") or table.find(muts,"Monstrous"))) then
                        mutBonus = mutBonus + 800
                    end
                    if isBigEgg(record) then mutBonus = mutBonus + 600 end
                    table.insert(matched, { record = record, rarity = rarityName, score = baseScore + mutBonus })
                end
            end
        end
    end
    if #matched > 1 then
        table.sort(matched, function(a, b) return a.score > b.score end)
    end
    return matched
end

local function EnsureSavedReturnPosition()
    if not savedReturnCFrame then
        local hrp = findHRP()
        if hrp then savedReturnCFrame = hrp.CFrame end
    end
end

local function isPlayerCarryingEgg()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local dropGui = pg and pg:FindFirstChild("DropHeldEgg")
    if dropGui and dropGui.Enabled == true then return true end
    local char = LP.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Model") and (t.Name:lower():find("egg")
                or t:GetAttribute("Uid")
                or t:GetAttribute("AssetCategory")) then return true end
            if t:IsA("Tool") then
                if EggToolDisplay and EggToolDisplay.IsEggTool and EggToolDisplay.IsEggTool(t) then return true end
                if t:GetAttribute("IsEgg")==true or t:GetAttribute("Uid")~=nil
                    or t:GetAttribute("AssetCategory")~=nil then return true end
                local tName = t.Name:lower()
                if tName:find("egg") or (tName ~= "bat" and tName ~= "defaulttool"
                    and not tName:find("bat") and not tName:find("slap")
                    and not tName:find("coil") and not tName:find("potion")
                    and not tName:find("lantern")) then return true end
            end
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and EggToolDisplay and EggToolDisplay.IsEggTool
                and EggToolDisplay.IsEggTool(t) then return true end
        end
    end
    return false
end

local function PlantAllCarriedEggsInPen()
    local plotObj    = PlotState and PlotState.ResolvePlot and PlotState.ResolvePlot()
    local plotCenter = plotObj and plotObj.CenterPoint
        and plotObj.CenterPoint.Position or Vector3.new(464.7, 68.2, -364.0)
    local toolsToPlant = {}
    for _, t in ipairs(LP.Character:GetChildren()) do
        if t:IsA("Tool") and EggToolDisplay and EggToolDisplay.IsEggTool
            and EggToolDisplay.IsEggTool(t) then
            local uid = EggToolDisplay.GetToolUid(t)
            if uid then table.insert(toolsToPlant, uid) end
        end
    end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") and EggToolDisplay and EggToolDisplay.IsEggTool
            and EggToolDisplay.IsEggTool(t) then
            local uid = EggToolDisplay.GetToolUid(t)
            if uid then table.insert(toolsToPlant, uid) end
        end
    end
    local plantedCount = 0
    for _, eggUid in ipairs(toolsToPlant) do
        for attempt = 1, 3 do
            local offset = CFrame.new(math.random(-6, 6), 0, math.random(-6, 6))
            local ok, res = pcall(function()
                if EggState and EggState.PlantEgg then
                    return EggState.PlantEgg(eggUid, offset)
                end
                return false
            end)
            if ok and res then plantedCount = plantedCount + 1; break end
            task.wait(0.1)
        end
    end
    return plantedCount
end

-- ════════════════════════════════════════════════════════════════════
-- CORE STEAL LOGIC  (Fly Up & Down aware)
-- ════════════════════════════════════════════════════════════════════
local function StealSpecificEggRobust(targetItem)
    local record = targetItem.record or targetItem
    if not record or not record.Uid or not record.BoundsCFrame then return false end

    if EggState and EggState.ReadFieldEggs then
        local ok, snap = pcall(EggState.ReadFieldEggs)
        if ok and snap and snap.Records then
            local stillThere = false
            for _, r in ipairs(snap.Records) do
                if r.Uid == record.Uid and r.State == "Slot" then
                    stillThere = true; record = r; break
                end
            end
            if not stillThere then return false end
        end
    end

    local hrp = findHRP()
    if not hrp then return false end

    EnsureSavedReturnPosition()

    local targetPos = record.BoundsCFrame.Position
    local speed     = math.clamp(tonumber(glideSpeed) or 750, 50, 750)

    -- Disable anti-guard near the nest before approaching
    if antiGuardEnabled then pcall(DisableNearbyGuards, 90) end

    -- 1. Fly/travel TO the egg (Fly Up & Down ascends first, then descends)
    TravelToDestination(targetPos + Vector3.new(0, 1.2, 0), speed, true)
    hrp = findHRP()
    if hrp then
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 1.2, 0))
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    task.wait(0.5)

    -- 2. Claim / fire proximity prompt
    local slotKey = nil
    if AreaEggSlotIdentity and AreaEggSlotIdentity.LooksLikeFirstAreaUid
        and AreaEggSlotIdentity.LooksLikeFirstAreaUid(record.Uid) then
        slotKey = AreaEggSlotIdentity.SlotKey(record.AreaId, record.NestId)
    end

    local net          = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
    local carryRemote  = net and net:FindFirstChild("RF/EggWorld/AskFieldEggCarry")
    if carryRemote then
        pcall(function() carryRemote:InvokeServer({ Uid = record.Uid, FirstAreaSlotKey = slotKey }) end)
    end
    pcall(function()
        if EggState and EggState.CarryFieldEgg then
            EggState.CarryFieldEgg(record.Uid, slotKey)
        end
    end)

    local prompt = nil
    local hrpNow = findHRP()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Name == "CarryAreaEgg" and d.Enabled then
            local act = (d.ActionText or ""):lower()
            local obj = (d.ObjectText or ""):lower()
            if not act:find("skip") and not act:find("robux")
                and not obj:find("skip") and not obj:find("robux") then
                local p = d.Parent
                if p:IsA("Attachment") then p = p.Parent end
                if p and (p.Position - (hrpNow and hrpNow.Position or targetPos)).Magnitude < 14 then
                    prompt = d; break
                end
            end
        end
    end

    if prompt then
        prompt.HoldDuration = 0
        pcall(function() fireproximityprompt(prompt) end)
        pcall(function() fireproximityprompt(prompt, 0) end)
    end

    local safePlotCenter, _ = GetLocalPlotCenter()
    local tPickup = os.clock()
    local carried = false
    while os.clock() - tPickup < 1.5 and not HUB.dead do
        if isPlayerCarryingEgg() then carried = true; break end
        -- Anti-guard: disable guards while attempting pickup
        if antiGuardEnabled then pcall(DisableNearbyGuards, 60) end
        pcall(function()
            if EggState and EggState.CarryFieldEgg then
                EggState.CarryFieldEgg(record.Uid, slotKey)
            end
        end)
        if prompt then
            prompt.HoldDuration = 0
            pcall(function() fireproximityprompt(prompt) end)
        end
        task.wait(0.08)
    end

    if not carried then
        ignoredEggs[record.Uid] = os.clock()
        return false
    end

    -- 3. Return to base — Fly Up & Down goes HIGH then descends at base
    hrpNow = findHRP()
    if stealMovementMethod == "Fly Up & Down" and hrpNow then
        -- Fly high immediately after grabbing the egg
        TravelFlyHighReturn(safePlotCenter, speed)
    else
        -- Original two-phase glide back
        local curPos  = hrpNow and hrpNow.Position or targetPos
        local toBase  = safePlotCenter - curPos
        local distBase = toBase.Magnitude
        if distBase > 45 then
            local stagePos = safePlotCenter - toBase.Unit * 35
            stagePos = Vector3.new(stagePos.X, math.max(stagePos.Y, 70.4), stagePos.Z)
            TravelToDestination(stagePos, speed, false)
            local h2 = findHRP()
            if h2 then h2.AssemblyLinearVelocity  = Vector3.zero; h2.AssemblyAngularVelocity = Vector3.zero end
            task.wait(0.35)
        end
        TravelToDestination(safePlotCenter, 240, true)
    end

    local tDeliver = os.clock()
    while os.clock() - tDeliver < 1.5 and isPlayerCarryingEgg() and not HUB.dead do
        task.wait(0.08)
    end

    PlantAllCarriedEggsInPen()

    -- 4. Settle safely on base ground
    local char = LP.Character
    local h    = char and char:FindFirstChild("HumanoidRootPart")
    local hu   = char and char:FindFirstChildOfClass("Humanoid")
    if h then
        h.CFrame = CFrame.new(safePlotCenter.X, math.max(safePlotCenter.Y, 70.4), safePlotCenter.Z)
        h.AssemblyLinearVelocity  = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
    end
    if hu then
        hu.PlatformStand = false
        hu.AutoRotate    = true
        pcall(function() hu:ChangeState(Enum.HumanoidStateType.Running) end)
    end

    return carried or isPlayerCarryingEgg()
end

local function HatchAllReadyEggs()
    if not EggState or not EggState.ReadOwnedEggs then return 0 end
    local ok, snapshot = pcall(EggState.ReadOwnedEggs, LP.UserId)
    if not ok or not snapshot then return 0 end
    local count   = 0
    local records = snapshot.Records or snapshot
    if typeof(records) == "table" then
        for uid, eggData in pairs(records) do
            if typeof(eggData) == "table" then
                local isReady = false
                if EggState.IsReadyToHatch then
                    isReady = EggState.IsReadyToHatch(eggData)
                else
                    isReady = eggData.Placement ~= nil
                end
                if isReady then
                    pcall(function()
                        if EggState.BeginHatch  then EggState.BeginHatch(uid)  end
                        task.wait(0.05)
                        if EggState.FinishHatch then EggState.FinishHatch(uid) end
                        count = count + 1
                    end)
                end
            end
        end
    end
    return count
end

local function StealBestEggOnce()
    pcall(HatchAllReadyEggs)
    local eggs = GetMatchingFieldEggs(selectedStealAreas, selectedStealRarities, selectedMutationTypes)
    if #eggs == 0 then return false end
    return StealSpecificEggRobust(eggs[1])
end

-- ════════════════════════════════════════════════════════════════════
-- BASE / HOMESTEAD / REWARDS
-- ════════════════════════════════════════════════════════════════════
local function UpgradeHomesteadBase()
    local re1 = GetNetRemote("RE/Homestead/AskNearbyPurchase")
    if re1 then pcall(function() re1:FireServer() end) end
    local re2 = GetNetRemote("RE/Homestead/AskBaseTierRaise")
    if re2 then pcall(function() re2:FireServer() end) end
end

local function UpgradeTreadmillTier()
    local rf = GetNetRemote("RF/Treadmill/AskTierRaise")
    if rf then pcall(function() rf:InvokeServer() end) end
end

local function EquipBestPets()
    local rf = GetNetRemote("RF/Haul/WearBest") or GetNetRemote("RF/PenRoster/ConfirmEquipBestBadge")
    if rf then pcall(function() rf:InvokeServer() end) end
end

-- ════════════════════════════════════════════════════════════════════
-- BOSS ARENA (Abyss Overlord)
-- ════════════════════════════════════════════════════════════════════
Boss.Data        = nil
Boss.MasteryData = nil

function Boss.EnsureData()
    if Boss._dataTried then return end
    Boss._dataTried = true
    pcall(function() Boss.Data        = require(RS.Data.BossEvent)  end)
    pcall(function() Boss.MasteryData = require(RS.Data.BossMastery) end)
end

Boss.MilestoneFallback = { "Mastery3","Mastery5","Mastery10","Mastery15","Mastery20","Mastery30" }

function Boss.Snapshot()
    local rf = GetNetRemote("RF/BossEvent/AskSnapshot")
    if not rf then return nil end
    local ok, res = pcall(function() return rf:InvokeServer() end)
    if ok and type(res) == "table" then return res end
end

function Boss.IsOpen()
    Boss.EnsureData()
    local snap = Boss.Snapshot()
    if snap then
        if snap.Open ~= nil then return snap.Open == true end
        if snap.BossHealth and snap.BossMaxHealth then
            return (tonumber(snap.BossHealth) or 0) > 0
        end
    end
    if Boss.Data and type(Boss.Data.SecondsUntilNextOpen) == "function" then
        local ok, secs = pcall(function() return Boss.Data.SecondsUntilNextOpen() end)
        if ok and tonumber(secs) then return tonumber(secs) <= 0 end
    end
    return false
end

function Boss.SecondsUntilOpen()
    Boss.EnsureData()
    if Boss.Data and type(Boss.Data.SecondsUntilNextOpen) == "function" then
        local ok, secs = pcall(function() return Boss.Data.SecondsUntilNextOpen() end)
        if ok and tonumber(secs) then return tonumber(secs) end
    end
end

function Boss.Join()
    local rf = GetNetRemote("RF/BossEvent/AskEnter")
    if not rf then return false end
    local ok, res = pcall(function() return rf:InvokeServer() end)
    return ok and res ~= false and res ~= nil
end

function Boss.ClaimMastery()
    Boss.EnsureData()
    local rf = GetNetRemote("RF/BossMastery/AskClaimMilestone")
    if not rf then return 0 end
    local ids = {}
    if Boss.MasteryData and type(Boss.MasteryData.Milestones) == "table" then
        for _, m in pairs(Boss.MasteryData.Milestones) do
            if type(m)=="table" and type(m.Id)=="string" and not Boss.claimed[m.Id] then
                table.insert(ids, m.Id)
            end
        end
    end
    if #ids == 0 then
        for _, id in ipairs(Boss.MilestoneFallback) do
            if not Boss.claimed[id] then table.insert(ids, id) end
        end
    end
    local claimed = 0
    for _, id in ipairs(ids) do
        local ok, res = pcall(function() return rf:InvokeServer(id) end)
        if ok and res ~= false and res ~= nil then
            Boss.claimed[id] = true; claimed = claimed + 1
        end
    end
    return claimed
end

function Boss.IsInArena()
    return LP:GetAttribute("InBossArena") == true
end

function Boss.FindBat()
    local char = LP.Character
    if not char then return nil end
    local held = char:FindFirstChildWhichIsA("Tool")
    if held and held:GetAttribute("IsBat") == true then return held end
    local bag = LP:FindFirstChild("Backpack")
    if bag then
        for _, c in ipairs(bag:GetChildren()) do
            if c:IsA("Tool") and c:GetAttribute("IsBat") == true then
                c.Parent = char; return c
            end
        end
    end
    local wear = GetNetRemote("RF/Codex/AskWearFieldBat")
    if wear then pcall(function() wear:InvokeServer() end) end
    task.wait(0.25)
    if bag then
        for _, c in ipairs(bag:GetChildren()) do
            if c:IsA("Tool") and c:GetAttribute("IsBat") == true then
                c.Parent = char; return c
            end
        end
    end
end

function Boss.FindTarget()
    local arena = Workspace:FindFirstChild("BossArena")
    if not arena then return nil end
    local root  = findHRP()
    if not root then return nil end
    local best, bestDist = nil, math.huge
    local towers = arena:FindFirstChild("CrystalTowers")
    if towers then
        for _, tower in ipairs(towers:GetChildren()) do
            local hb = tower:FindFirstChild("Hitbox", true)
            if hb and hb:IsA("BasePart") then
                local hp = tonumber(hb:GetAttribute("Health"))
                if hp == nil or hp > 0 then
                    local d = (root.Position - hb.Position).Magnitude
                    if d < bestDist then best, bestDist = hb, d end
                end
            end
        end
    end
    if best and Boss.arenaApproach == "Crystals First" then return best, "Crystal" end
    local boss = arena:FindFirstChild("Boss")
    if boss then
        local aim = boss:FindFirstChild("UpperHand1.R", true) or boss.PrimaryPart
        if aim and aim:IsA("BasePart") then
            local d = (root.Position - aim.Position).Magnitude
            if d < bestDist then best, bestDist = aim, d end
        end
    end
    return best, (best and "Boss" or nil)
end

function Boss.GlideStep(target)
    local root = findHRP()
    if not root or not target then return false end
    local offset = root.Position - target.Position
    offset = Vector3.new(offset.X, 0, offset.Z)
    if offset.Magnitude < 0.5 then offset = Vector3.new(0, 0, 1) end
    local destination = target.Position + offset.Unit * 5
    local toGo  = destination - root.Position
    local remain = toGo.Magnitude
    if remain < 1.0 then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        return true
    end
    local now  = os.clock()
    local dt   = math.clamp(now - (Boss._stepAt or now), 0.001, 0.1)
    Boss._stepAt = now
    local speed = math.clamp(tonumber(Boss.glideSpeed) or 260, 60, 500)
    local dir   = toGo.Unit
    local step  = math.min(speed * dt, remain)
    local nextPos = root.Position + dir * step
    local face  = Vector3.new(dir.X, 0, dir.Z)
    if face.Magnitude < 0.01 then face = root.CFrame.LookVector end
    root.CFrame = CFrame.lookAt(nextPos, nextPos + face.Unit)
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return false
end

function Boss.EnsureBat()
    local char = LP.Character
    if not char then return nil end
    local held = char:FindFirstChildWhichIsA("Tool")
    if held and held:GetAttribute("IsBat") == true then return held end
    local now = os.clock()
    if now - (Boss._batAt or 0) < 1.5 then return nil end
    Boss._batAt = now
    return Boss.FindBat()
end

function Boss.CurrentTarget()
    local now  = os.clock()
    local held = Boss._targetPart
    if held and held.Parent and (now - (Boss._targetAt or 0)) < 0.35 then
        local hp = tonumber(held:GetAttribute("Health"))
        if hp == nil or hp > 0 then return held, Boss._target end
    end
    local part, kind = Boss.FindTarget()
    Boss._targetPart, Boss._target, Boss._targetAt = part, kind, now
    return part, kind
end

function Boss.Fight()
    if not Boss.IsInArena() then return false end
    local root = findHRP()
    if not root then return false end
    local target, kind = Boss.CurrentTarget()
    if not target then return false end
    local dist = (root.Position - target.Position).Magnitude
    if dist > Boss.engageDistance then
        Boss.GlideStep(target); Boss._target = kind; return true
    end
    local now = os.clock()
    if now - (Boss._swingAt or 0) < Boss.swingInterval then return true end
    Boss._swingAt = now
    local bat   = Boss.EnsureBat()
    if bat then pcall(function() bat:Activate() end) end
    local swing = GetNetRemote("RE/BatSwing/Trigger")
    if swing then pcall(function() swing:FireServer() end) end
    return true
end

do
    local hazard   = GetNetRemote("RE/BossEvent/HazardHit")
    local blackHole= GetNetRemote("RE/BossEvent/BlackHoleHit")
    for _, remote in ipairs({ hazard, blackHole }) do
        if type(remote) == "userdata" and remote:IsA("RemoteEvent") then
            Boss._hazardRemotes[remote] = true
        end
    end
end

function Boss.InstallHazardHook()
    if Boss.hazardHook then return true end
    if Boss.hazardHookTried then return false end
    Boss.hazardHookTried = true
    local touchOnly = false
    pcall(function()
        touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    end)
    if touchOnly then
        Notify("Boss Hazards", "Hazard immunity not supported on mobile", "Error"); return false
    end
    if not HookFn then return false end
    local hazard = GetNetRemote("RE/BossEvent/HazardHit")
    if type(hazard) ~= "userdata" or not hazard:IsA("RemoteEvent") then return false end
    local oldFire = hazard.FireServer
    if type(oldFire) ~= "function" then return false end
    local ok = pcall(function()
        HookFn(oldFire, function(self, ...)
            if Boss.hazardImmune and Boss._hazardRemotes[self] then return end
            return oldFire(self, ...)
        end)
    end)
    Boss.hazardHook = ok
    return ok
end

local function DropHeldEgg()
    local rf = GetNetRemote("RF/EggWorld/AskFieldEggDrop")
    if rf then pcall(function() rf:InvokeServer() end) end
    if EggState and EggState.DropFieldEgg then pcall(EggState.DropFieldEgg) end
end

local function BuyAffordableTrails()
    local rf         = GetNetRemote("RF/Trailwear/AskPurchase")
    local TrailsData = RS:FindFirstChild("Data") and RS.Data:FindFirstChild("Trails")
        and require(RS.Data.Trails)
    local save = nil
    pcall(function() save = SaveModule and SaveModule.Get and SaveModule.Get() end)
    if not rf or not TrailsData or not save then return end
    local myMoney = tonumber(save.Money) or 0
    local inv     = save.TrailInventory or {}
    for _, t in pairs(TrailsData.Directory or TrailsData) do
        if type(t)=="table" and t._id and not inv[t._id] then
            local price = tonumber(t.Price) or math.huge
            if myMoney >= price then
                pcall(function() rf:InvokeServer(t._id) end)
                task.wait(0.25)
            end
        end
    end
end

local function SetNoKnockback(enabled)
    noKnockbackEnabled = enabled
    if enabled then
        pcall(function()
            local rigSync = GetNetRemote("RE/RigSync/Refresh")
            if rigSync and getconnections then
                for _, conn in ipairs(getconnections(rigSync.OnClientEvent)) do
                    pcall(function() conn:Disconnect() end)
                end
            end
        end)
    end
end

pcall(function() if avoidTrapsEnabled then NeutralizeTraps() end end)
pcall(function() if noKnockbackEnabled then SetNoKnockback(true) end end)

local function SellSelectedPets()
    local re = GetNetRemote("RE/PetSatchel/SellPet")
    if not re or not SaveModule then return end
    local save = nil
    pcall(function() save = SaveModule.Get and SaveModule.Get() end)
    local inv = save and save.Inventory
    if type(inv) ~= "table" then return end
    for uid, petData in pairs(inv) do
        if type(petData)=="table" and not petData.Locked then
            local rName = petData.Rarity or "Common"
            if isRarityAllowed(rName, getSellRarityFilter(selectedSellPetRarities)) then
                pcall(function() re:FireServer(uid) end)
                task.wait(0.08)
            end
        end
    end
end

local function SellSelectedEggs()
    if not SaveModule then return end
    local save = nil
    pcall(function() save = SaveModule.Get and SaveModule.Get() end)
    if not save then return end
    local inv  = save.EggInventory
    if type(inv) ~= "table" then return end
    local wear = GetNetRemote("RF/EggWorld/AskWearTool")
    local sell = GetNetRemote("RE/PetSatchel/SellPet")
    if not wear or not sell then return end
    for uid, eggData in pairs(inv) do
        if type(eggData)=="table" and not eggData.Placement and not eggData.Locked then
            local rName = GetEggRarityInfo(eggData)
            if isRarityAllowed(rName, getSellRarityFilter(selectedSellEggRarities)) then
                pcall(function() wear:InvokeServer(uid) end)
                pcall(function() sell:FireServer({ uid }) end)
                task.wait(SELL_REQUEST_DELAY)
            end
        end
    end
end

local function DeleteOwnPetRenders()
    local count = 0
    local function sweep(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                pcall(function() child:Destroy(); count = count + 1 end)
            end
        end
    end
    sweep(Workspace:FindFirstChild("Pets"))
    sweep(Workspace:FindFirstChild("RenderedPets"))
    return count
end

local function ClaimAllAvailableRewards()
    pcall(function()
        local rf1 = GetNetRemote("RF/AwayEarnings/AskCollect")
        if rf1 then rf1:InvokeServer() end
    end)
    pcall(function()
        local rf2 = GetNetRemote("RF/Codex/AskRedeemAll")
        if rf2 then rf2:InvokeServer() end
    end)
    pcall(function()
        local rf3 = GetNetRemote("RF/GroupPerk/RedeemPerk")
        if rf3 then rf3:InvokeServer() end
    end)
    pcall(Boss.ClaimMastery)
end


-- Persist toggles when leaving the game
pcall(function()
    game:BindToClose(function()
        AutoSaveConfig()
    end)
end)
pcall(function()
    track(Players.LocalPlayer.OnTeleport:Connect(function()
        AutoSaveConfig()
    end))
end)

-- ════════════════════════════════════════════════════════════════════
-- WORKER LOOPS
-- ════════════════════════════════════════════════════════════════════

-- 1. Auto Steal
task.spawn(function()
    while not HUB.dead do
        if autoStealEnabled then
            rareEggHunter = true
            selectedStealRarities = {}   -- empty = all rarities, sorted highest first
            selectedStealAreas = {}      -- empty = all areas
            selectedMutationTypes = {}   -- none = any mutation
            -- sync travel speed to current walk so egg delivery never fails
            local hum = findHum()
            if hum then
                local ws = tonumber(hum.WalkSpeed) or 16
                glideSpeed = math.clamp(math.floor(ws * 6 + 80), 100, 420)
            end
            pcall(StealBestEggOnce)
        end
        task.wait(stealDelay)
    end
end)

-- 2. Auto Hatch & Plant
task.spawn(function()
    while not HUB.dead do
        if autoHatchEnabled then pcall(HatchAllReadyEggs) end
        if autoPlantEnabled then pcall(PlantAllCarriedEggsInPen) end
        task.wait(hatchCheckDelay)
    end
end)

-- 3. Base / Homestead / Sales
task.spawn(function()
    while not HUB.dead do
        if autoUpgradeBase    then pcall(UpgradeHomesteadBase)      end
        if autoUpgradeTreadmill then pcall(UpgradeTreadmillTier)    end
        if autoEquipBestPets  then pcall(EquipBestPets)             end
        if autoClaimRewards   then pcall(ClaimAllAvailableRewards)  end
        if Boss.autoMastery   then pcall(Boss.ClaimMastery)         end
        if autoSellPets       then pcall(SellSelectedPets)          end
        if autoSellEggs       then pcall(SellSelectedEggs)          end
        task.wait(2.5)
    end
end)

-- 4. Boss Arena worker
task.spawn(function()
    while not HUB.dead do
        if Boss.autoJoin or Boss.autoFight then
            if Boss.IsInArena() then
                if Boss.autoFight then pcall(Boss.Fight) end
                RunService.Heartbeat:Wait()
            else
                local ok, open = pcall(Boss.IsOpen)
                Boss.arenaReady = (ok and open == true)
                if Boss.arenaReady then pcall(Boss.Join) end
                task.wait(2)
            end
        else
            task.wait(1)
        end
    end
end)

-- 5. Bat Aura
task.spawn(function()
    local batRe = GetNetRemote("RE/BatSwing/Trigger")
    while not HUB.dead do
        if batAuraEnabled and batRe then
            local hrp = findHRP()
            if hrp then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local oHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if oHrp and (oHrp.Position - hrp.Position).Magnitude <= batAuraRadius then
                            pcall(function() batRe:FireServer() end)
                            break
                        end
                    end
                end
            end
        end
        task.wait(batAuraDelay)
    end
end)

-- 6. Trap Neutralizer
task.spawn(function()
    local debris = Workspace:FindFirstChild("__DEBRIS")
    if debris then
        track(debris.ChildAdded:Connect(function(child)
            if avoidTrapsEnabled and child.Name == "PlayerTrap" then
                task.wait(0.05)
                if child:GetAttribute("Owner") ~= LP.Name then
                    if child:IsA("BasePart") then child.CanTouch = false end
                    for _, c in ipairs(child:GetChildren()) do
                        if c:IsA("BasePart") then c.CanTouch = false end
                    end
                end
            end
        end))
    end
    while not HUB.dead do
        if avoidTrapsEnabled or autoStealEnabled then pcall(NeutralizeTraps) end
        task.wait(1.5)
    end
end)

-- 7. Anti Guard worker  (NEW)
task.spawn(function()
    while not HUB.dead do
        if antiGuardEnabled then
            pcall(DisableNearbyGuards, 80)
            pcall(AntiGuardHeal)
            pcall(BlockGuardRemotes)
        end
        task.wait(0.3)
    end
end)

-- 8. FPS / Ping update
track(RunService.RenderStepped:Connect(function(dt)
    if HUB.dead then return end
    _fpsFrames = _fpsFrames + 1
    _fpsTimer  = _fpsTimer  + dt
    if _fpsTimer >= 0.5 then
        _lastFps   = math.floor(_fpsFrames / _fpsTimer + 0.5)
        _fpsFrames = 0
        _fpsTimer  = 0
    end
    if _fpsLabel then
        local ping = 0
        pcall(function()
            ping = math.floor((LP:GetNetworkPing() or 0) * 1000 + 0.5)
        end)
        local t = string.format("YUSH HUB | FPS: %d | Ping: %d ms", _lastFps, ping)
        _fpsLabel.Text = t
        -- tight width to text
        if _fpsLabel.Parent then
            local bounds = _fpsLabel.TextBounds
            if bounds and bounds.X > 0 then
                _fpsLabel.Parent.Size = UDim2.fromOffset(math.max(bounds.X + 28, 180), 24)
            end
        end
    end
end))

-- ════════════════════════════════════════════════════════════════════
-- VISUALS & ESP
-- ════════════════════════════════════════════════════════════════════
local esp = {
    enabled      = false, eggs = true, traps = false,
    players      = false, guards = false, rareEggsOnly = false,
    showPetIcons = true,  maxDistance = 800,
    eggColor     = Color3.fromRGB(255, 200, 50),
    rareEggColor = Color3.fromRGB(255, 60, 220),
    trapColor    = Color3.fromRGB(255, 60, 60),
    playerColor  = Color3.fromRGB(100, 220, 100),
    guardColor   = Color3.fromRGB(255, 60, 60),
}

local hasDrawing    = type(Drawing) == "table" and type(Drawing.new) == "function"
local trackedEspObjects = {}
local espBillboards = {}
local espContainer  = nil

local function getEspContainer()
    if espContainer and espContainer.Parent then return espContainer end
    local p = nil
    pcall(function() p = (gethui and gethui()) end)
    if not p then pcall(function() p = game:GetService("CoreGui") end) end
    if not p then p = LP:FindFirstChild("PlayerGui") or Workspace end
    pcall(function()
        for _, c in ipairs(p:GetChildren()) do
            if c:IsA("Folder") and c.Name == "SAE_Esp_Holder" then c:Destroy() end
        end
    end)
    espContainer = Instance.new("Folder")
    espContainer.Name = "SAE_Esp_Holder"
    pcall(function() espContainer.Parent = p end)
    return espContainer
end

local function updateEggBillboard(key, pos, icon)
    local bb = espBillboards[key]
    if not bb or not bb.gui or not bb.gui.Parent then
        local holder = getEspContainer()
        local part   = Instance.new("Part")
        part.Name = "EspAnchor"; part.Size = Vector3.new(1,1,1)
        part.Transparency = 1; part.Anchored = true
        part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
        part.CFrame = CFrame.new(pos); part.Parent = holder
        local gui = Instance.new("BillboardGui")
        gui.Name = "EggIconBillboard"; gui.Adornee = part
        gui.Size = UDim2.fromOffset(28,28)
        gui.StudsOffset = Vector3.new(-2.2,1.2,0)
        gui.AlwaysOnTop = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = part
        local img = Instance.new("ImageLabel")
        img.Name = "PetImage"; img.Size = UDim2.fromScale(1,1)
        img.BackgroundTransparency = 1; img.ScaleType = Enum.ScaleType.Fit
        img.Image = icon or ""; img.Parent = gui
        bb = { part = part, gui = gui, img = img }
        espBillboards[key] = bb
    else
        bb.part.CFrame = CFrame.new(pos)
        bb.img.Image   = icon or ""
        bb.gui.Enabled = (icon ~= nil and icon ~= "")
    end
    return bb
end

local function createDrawingObject()
    if not hasDrawing then return {} end
    local o = {}
    o.name = trackDrawing(Drawing.new("Text"))
    o.name.Size = 13; o.name.Center = true; o.name.Outline = true; o.name.Visible = false
    o.dist = trackDrawing(Drawing.new("Text"))
    o.dist.Size = 11; o.dist.Center = true; o.dist.Outline = true; o.dist.Visible = false
    o.box  = trackDrawing(Drawing.new("Square"))
    o.box.Thickness = 1.5; o.box.Filled = false; o.box.Visible = false
    return o
end

track(RunService.RenderStepped:Connect(function()
    if HUB.dead or not esp.enabled then
        for _, obj in pairs(trackedEspObjects) do
            if obj.name then obj.name.Visible = false end
            if obj.dist then obj.dist.Visible = false end
            if obj.box  then obj.box.Visible  = false end
        end
        for _, bb in pairs(espBillboards) do
            if bb.gui then bb.gui.Enabled = false end
        end
        return
    end

    local hrp   = findHRP()
    local myPos = hrp and hrp.Position or Vector3.zero
    local renderItems = {}
    local activeBbKeys = {}

    if esp.eggs and EggState and EggState.ReadFieldEggs then
        local ok, snap = pcall(EggState.ReadFieldEggs)
        if ok and snap and snap.Records then
            for _, egg in ipairs(snap.Records) do
                if egg.State == "Slot" and egg.BoundsCFrame then
                    local pos  = egg.BoundsCFrame.Position
                    local dist = (pos - myPos).Magnitude
                    if esp.maxDistance <= 0 or dist <= esp.maxDistance then
                        local muts   = egg.Mutations or {}
                        local isRare = #muts > 0
                        if not esp.rareEggsOnly or isRare then
                            local mutText  = isRare and (" [" .. table.concat(muts,",") .. "]") or ""
                            local rName    = GetEggRarityInfo(egg)
                            local label    = (egg.AssetCategory or "Egg") .. " (" .. rName .. ")" .. mutText
                            local cat      = egg.AssetCategory
                            local aInfo    = AssetsData and (AssetsData.Directory or AssetsData)
                                and (AssetsData.Directory or AssetsData)[cat]
                            local petIcon  = aInfo and (aInfo.Icon or (aInfo.Egg and aInfo.Egg.Icon)) or ""
                            local itemColor = isRare and esp.rareEggColor or esp.eggColor
                            table.insert(renderItems, { Key=egg.Uid, Pos=pos, Name=label, Color=itemColor, Dist=dist })
                            if esp.showPetIcons and petIcon ~= "" then
                                activeBbKeys[egg.Uid] = true
                                updateEggBillboard(egg.Uid, pos, petIcon)
                            end
                        end
                    end
                end
            end
        end
    end

    if esp.traps then
        local debris = Workspace:FindFirstChild("__DEBRIS")
        if debris then
            for _, trap in ipairs(debris:GetChildren()) do
                if trap.Name == "PlayerTrap" and trap:IsA("BasePart") then
                    local pos  = trap.Position
                    local dist = (pos - myPos).Magnitude
                    if esp.maxDistance <= 0 or dist <= esp.maxDistance then
                        local owner = trap:GetAttribute("Owner") or "Enemy"
                        table.insert(renderItems, { Key=trap, Pos=pos+Vector3.new(0,1.5,0),
                            Name="[TRAP] @"..owner, Color=esp.trapColor, Dist=dist })
                    end
                end
            end
        end
    end

    if esp.players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local oHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if oHrp then
                    local dist = (oHrp.Position - myPos).Magnitude
                    if esp.maxDistance <= 0 or dist <= esp.maxDistance then
                        table.insert(renderItems, { Key=p, Pos=oHrp.Position,
                            Name=p.DisplayName.." (@"..p.Name..")", Color=esp.playerColor, Dist=dist })
                    end
                end
            end
        end
    end

    for k, bb in pairs(espBillboards) do
        if not activeBbKeys[k] and bb.gui then bb.gui.Enabled = false end
    end

    local cam = GetCamera()
    local activeKeys = {}
    for _, item in ipairs(renderItems) do
        activeKeys[item.Key] = true
        local obj = trackedEspObjects[item.Key]
        if not obj then obj = createDrawingObject(); trackedEspObjects[item.Key] = obj end
        local screenPos, onScreen = nil, false
        if cam then screenPos, onScreen = cam:WorldToViewportPoint(item.Pos) end
        if onScreen and hasDrawing and screenPos then
            if obj.name then
                obj.name.Text     = item.Name
                obj.name.Position = Vector2.new(screenPos.X, screenPos.Y - 14)
                obj.name.Color    = item.Color
                obj.name.Visible  = true
            end
            if obj.dist then
                obj.dist.Text     = math.floor(item.Dist) .. " studs"
                obj.dist.Position = Vector2.new(screenPos.X, screenPos.Y + 2)
                obj.dist.Color    = Color3.fromRGB(220, 220, 220)
                obj.dist.Visible  = true
            end
        else
            if obj.name then obj.name.Visible = false end
            if obj.dist then obj.dist.Visible = false end
            if obj.box  then obj.box.Visible  = false end
        end
    end
    for k, obj in pairs(trackedEspObjects) do
        if not activeKeys[k] then
            if obj.name then obj.name.Visible = false end
            if obj.dist then obj.dist.Visible = false end
            if obj.box  then obj.box.Visible  = false end
        end
    end
end))

-- Fullbright
local fullbrightEnabled = false
local defaultAmbient    = Lighting.Ambient
local defaultOutdoor    = Lighting.OutdoorAmbient
local defaultBrightness = Lighting.Brightness
local defaultClockTime  = Lighting.ClockTime

local function SetFullbright(v)
    fullbrightEnabled = v
    if v then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = 2; Lighting.ClockTime = 14
    else
        Lighting.Ambient        = defaultAmbient
        Lighting.OutdoorAmbient = defaultOutdoor
        Lighting.Brightness     = defaultBrightness
        Lighting.ClockTime      = defaultClockTime
    end
end

-- ════════════════════════════════════════════════════════════════════
-- MOVEMENT & PLAYER MODIFIERS
-- ════════════════════════════════════════════════════════════════════
local walkSpeedEnabled = false
local walkSpeedVal     = 24
local jumpPowerEnabled = false
local jumpPowerVal     = 60
local infiniteJump     = false
local flying           = false
local flySpeed         = 60
local antiAFK          = false

local function ApplyWalkSpeed(v)
    walkSpeedVal = v
    local hum = findHum()
    if hum and walkSpeedEnabled then hum.WalkSpeed = v end
end

local function ApplyJumpPower(v)
    jumpPowerVal = v
    local hum = findHum()
    if hum and jumpPowerEnabled then hum.UseJumpPower = true; hum.JumpPower = v end
end

track(RunService.Stepped:Connect(function()
    if HUB.dead then return end
    local hum = findHum()
    if hum then
        if walkSpeedEnabled then hum.WalkSpeed = walkSpeedVal end
        if jumpPowerEnabled then hum.UseJumpPower = true; hum.JumpPower = jumpPowerVal end
    end
end))

track(UserInputService.JumpRequest:Connect(function()
    if HUB.dead then return end
    local hum = findHum()
    if hum then hum.Jump = true; hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

local function startFly()
    if flying then return end
    local hrp = findHRP(); local hum = findHum()
    if not (hrp and hum) then return end
    flying = true; hrp.Anchored = true
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1,1,1) * 1e5
    bodyGyro.P        = 1e5
    bodyGyro.CFrame   = hrp.CFrame
    bodyGyro.Parent   = hrp
    HUB._fly = {
        hrp = hrp, gyro = bodyGyro,
        conn = track(RunService.RenderStepped:Connect(function(dt)
            if not flying or HUB.dead then return end
            local cam = GetCamera()
            if not cam then return end
            local look     = cam.CFrame.LookVector
            local right    = cam.CFrame.RightVector
            local flatLook = Vector3.new(look.X, 0, look.Z)
            flatLook = flatLook.Magnitude > 0.001 and flatLook.Unit or Vector3.new(0,0,-1)
            local flatRight = Vector3.new(right.X, 0, right.Z)
            flatRight = flatRight.Magnitude > 0.001 and flatRight.Unit or Vector3.new(1,0,0)
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W)          then dir = dir + flatLook  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S)          then dir = dir - flatLook  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A)          then dir = dir - flatRight end
            if UserInputService:IsKeyDown(Enum.KeyCode.D)          then dir = dir + flatRight end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then dir = dir - Vector3.new(0,1,0) end
            if dir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + dir.Unit * flySpeed * math.min(dt, 0.1)
            end
            bodyGyro.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look)
        end))
    }
end

local function stopFly()
    flying = false
    local f = HUB._fly
    if f then
        pcall(function() f.conn:Disconnect() end)
        pcall(function() f.hrp.Anchored = false end)
        pcall(function() f.gyro:Destroy() end)
        HUB._fly = nil
    end
end

local antiAfkConn = nil
local function SetAntiAFK(v)
    antiAFK = v
    if v and not antiAfkConn then
        antiAfkConn = track(LocalPlayer.Idled:Connect(function()
            if antiAFK then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end
        end))
    elseif not v and antiAfkConn then
        pcall(function() antiAfkConn:Disconnect() end)
        antiAfkConn = nil
    end
end

-- Anti-Ragdoll heartbeat
track(RunService.Heartbeat:Connect(function()
    if HUB.dead then return end
    if antiRagdollEnabled then
        local hum = findHum()
        if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end))

-- ════════════════════════════════════════════════════════════════════
-- UI  —  TABS  (Left side layout requested; TabLocation = "Left")
-- ════════════════════════════════════════════════════════════════════
local EggsTab     = Window:AddTab({ Name = "Eggs",     Subtitle = "Steal, hatch & plant", Icon = "crown"  })
local BaseTab     = Window:AddTab({ Name = "Base",     Subtitle = "Homestead & training", Icon = "bolt"   })
local CombatTab   = Window:AddTab({ Name = "Combat",   Subtitle = "Guard, bat & defense", Icon = "combat" })
local PlayerTab   = Window:AddTab({ Name = "Player",   Subtitle = "Movement & teleports", Icon = "player" })
local SettingsTab = Window:AddTab({ Name = "Settings", Subtitle = "Configs & unloader",   Icon = "gear"   })

-- ─── TAB 1: EGGS ─────────────────────────────────────────────────────────────
local StealSub   = EggsTab:AddSubTab("Auto Steal")
local HatchSub   = EggsTab:AddSubTab("Auto Hatch & Plant")
local EggEspSub  = EggsTab:AddSubTab("Egg Tracker ESP")

StealSub:AddToggle({
    Name = "Auto Steal Eggs", Default = false, Flag = "steal_auto",
    Callback = safeCallback(function(v)
        autoStealEnabled = v
        if v then
            EnsureSavedReturnPosition()
            -- lock travel speed to current WalkSpeed so delivery never fails
            local hum = findHum()
            if hum then
                local ws = tonumber(hum.WalkSpeed) or 16
                glideSpeed = math.clamp(ws * 8, 120, 450)  -- scale walk into travel speed
            end
        end
        Notify("Auto Steal", v and "Enabled — highest rarity first" or "Disabled", v and "Success" or "Error")
    end)
})
StealSub:AddDropdown({
    Name = "Movement Method",
    Options = { "Fly Up & Down", "Tween Glide", "Fly Glide", "Safe Walk" },
    Default = "Fly Up & Down", Flag = "steal_method",
    Callback = function(v) stealMovementMethod = v end
})
StealSub:AddToggle({
    Name = "Anti Guard (Guards Cannot Hit You)", Default = false, Flag = "anti_guard_main",
    Callback = safeCallback(function(v)
        antiGuardEnabled = v
        if v then
            pcall(BlockGuardRemotes)
            pcall(DisableNearbyGuards, 100)
            Notify("Anti Guard", "Active — guards disabled near you", "Success")
        else
            Notify("Anti Guard", "Disabled", "Error")
        end
    end)
})
StealSub:AddButton({
    Name = "Steal Best Egg Now", Primary = true,
    Callback = safeCallback(function()
        -- always pick most valuable / highest rarity; filters forced off
        rareEggHunter = true
        selectedStealRarities = {}
        selectedStealAreas = {}
        selectedMutationTypes = {}
        local ok = StealBestEggOnce()
        Notify("Steal Egg", ok and "Going for target egg" or "No matching egg found", ok and "Success" or "Info")
    end)
})

HatchSub:AddToggle({
    Name = "Auto Hatch Ready Eggs", Default = false, Flag = "hatch_auto",
    Callback = safeCallback(function(v)
        autoHatchEnabled = v
        Notify("Auto Hatch", v and "Enabled" or "Disabled", v and "Success" or "Error")
    end)
})
HatchSub:AddToggle({
    Name = "Auto Place Egg (Base Pen)", Default = false, Flag = "plant_auto",
    Callback = function(v)
        autoPlantEnabled = v
        Notify("Auto Place", v and "Enabled" or "Disabled", v and "Success" or "Error")
    end
})
HatchSub:AddSlider({
    Name = "Hatch Check Delay", Min = 0.5, Max = 10, Default = 2.0, Suffix = "s", Flag = "hatch_gap",
    Callback = function(v) hatchCheckDelay = v end
})
HatchSub:AddButton({
    Name = "Hatch All Ready Eggs Now", Primary = true,
    Callback = safeCallback(function()
        local count = HatchAllReadyEggs()
        Notify("Hatch", "Hatched " .. count .. " egg(s)", "Success")
    end)
})
HatchSub:AddButton({
    Name = "Place Carried Eggs in Pen Now",
    Callback = safeCallback(function()
        local count = PlantAllCarriedEggsInPen()
        Notify("Plant Eggs", "Planted " .. count .. " egg(s)", "Success")
    end)
})

EggEspSub:AddToggle({
    Name = "Egg ESP Enabled", Default = false, Flag = "esp_eggs_enabled",
    Callback = safeCallback(function(v)
        esp.enabled = v
        Notify("Egg ESP", v and "Enabled" or "Disabled", v and "Success" or "Error")
    end)
})
EggEspSub:AddToggle({
    Name = "Show 3D Pet Image Badges", Default = true, Flag = "esp_pet_icons",
    Callback = function(v) esp.showPetIcons = v end
})
EggEspSub:AddToggle({
    Name = "Trap ESP (Enemy Traps)", Default = false, Flag = "esp_traps",
    Callback = function(v) esp.traps = v end
})
EggEspSub:AddToggle({
    Name = "Show Mutated / Rare Eggs Only", Default = false, Flag = "esp_eggs_rare_only",
    Callback = function(v) esp.rareEggsOnly = v end
})
EggEspSub:AddSlider({
    Name = "Max ESP Distance", Min = 100, Max = 2500, Default = 800, Suffix = " studs", Flag = "esp_max_dist",
    Callback = function(v) esp.maxDistance = v end
})

-- ─── TAB 2: BASE ─────────────────────────────────────────────────────────────
do
local UpgradesSub = BaseTab:AddSubTab("Homestead & Treadmill")
local PetsSub     = BaseTab:AddSubTab("Pets & Satchel")
local SalesSub    = BaseTab:AddSubTab("Auto Sell")
local EventsSub   = BaseTab:AddSubTab("Events & Bosses")
local RewardsSub  = BaseTab:AddSubTab("Claim Rewards")

UpgradesSub:AddToggle({
    Name = "Auto Upgrade Base / Plot", Default = false, Flag = "up_base_auto",
    Callback = function(v) autoUpgradeBase = v end
})
UpgradesSub:AddToggle({
    Name = "Auto Upgrade Treadmill Tier", Default = false, Flag = "up_tread_auto",
    Callback = function(v) autoUpgradeTreadmill = v end
})
UpgradesSub:AddToggle({
    Name = "Auto Buy Speed Trails", Default = false, Flag = "auto_buy_trails",
    Callback = function(v) autoBuyTrails = v end
})
UpgradesSub:AddButton({ Name = "Upgrade Base Now", Primary = true, Callback = safeCallback(function()
    UpgradeHomesteadBase(); Notify("Base", "Upgrade requested", "Success")
end) })
UpgradesSub:AddButton({ Name = "Upgrade Treadmill Now", Callback = safeCallback(function()
    UpgradeTreadmillTier(); Notify("Treadmill", "Upgrade requested", "Success")
end) })

PetsSub:AddToggle({
    Name = "Auto Equip Best Pets", Default = false, Flag = "equip_best_pets",
    Callback = function(v) autoEquipBestPets = v end
})
PetsSub:AddButton({ Name = "Equip Best Pets Now", Primary = true, Callback = safeCallback(function()
    EquipBestPets(); Notify("Pets", "Equipped best pets", "Success")
end) })

SalesSub:AddToggle({ Name = "Auto Sell Low-Tier Pets", Default = false, Flag = "auto_sell_pets",
    Callback = function(v) autoSellPets = v end })
SalesSub:AddMultiDropdown({ Name = "Pet Sell Rarities", Options = RARITY_NAMES, Default = {}, Flag = "sell_pet_rarities",
    Callback = function(sel) selectedSellPetRarities = sel end })
SalesSub:AddToggle({ Name = "Auto Sell Low-Tier Eggs", Default = false, Flag = "auto_sell_eggs",
    Callback = function(v) autoSellEggs = v end })
SalesSub:AddMultiDropdown({ Name = "Egg Sell Rarities", Options = RARITY_NAMES, Default = {}, Flag = "sell_egg_rarities",
    Callback = function(sel) selectedSellEggRarities = sel end })
SalesSub:AddButton({ Name = "Sell Selected Pets Now", Primary = true, Callback = safeCallback(function()
    SellSelectedPets(); Notify("Sales", "Sold matching pets", "Success")
end) })
SalesSub:AddButton({ Name = "Sell Selected Eggs Now", Callback = safeCallback(function()
    SellSelectedEggs(); Notify("Sales", "Sold matching eggs", "Success")
end) })

EventsSub:AddToggle({ Name = "FULL AUTO Boss Fight", Default = false, Flag = "auto_fight_boss",
    Callback = safeCallback(function(v)
        Boss.autoFight = v
        if v then Boss.autoJoin = true; Boss.autoMastery = true
            if Boss.hazardImmune then pcall(Boss.InstallHazardHook) end
            Notify("Boss Auto", "Full auto: joins, fights and claims", "Success")
        else Notify("Boss Auto", "Disabled", "Error") end
    end)
})
EventsSub:AddDropdown({ Name = "Boss Targeting",
    Options = { "Crystals First","Boss First" }, Default = "Crystals First", Flag = "boss_targeting",
    Callback = function(v) Boss.arenaApproach = v end })
EventsSub:AddToggle({ Name = "Hazard Immunity", Default = false, Flag = "boss_hazard_imm2",
    Callback = safeCallback(function(v)
        Boss.hazardImmune = v
        if v then Boss.InstallHazardHook() end
        Notify("Hazards", v and "Immune" or "Normal damage", v and "Success" or "Info")
    end)
})
EventsSub:AddToggle({ Name = "Auto Join Boss Arena", Default = false, Flag = "auto_join_boss",
    Callback = safeCallback(function(v) Boss.autoJoin = v
        Notify("Boss Arena", v and "Will join when open" or "Disabled", v and "Success" or "Error")
    end)
})
EventsSub:AddToggle({ Name = "Auto Claim Boss Mastery", Default = false, Flag = "auto_boss_mastery",
    Callback = safeCallback(function(v) Boss.autoMastery = v
        Notify("Boss Mastery", v and "Enabled" or "Disabled", v and "Success" or "Error")
    end)
})
EventsSub:AddButton({ Name = "Join Boss Arena Now", Primary = true, Callback = safeCallback(function()
    if Boss.Join() then Notify("Boss Arena", "Entered Abyss Overlord", "Success")
    else Notify("Boss Arena", "Closed — opens every 30 min", "Error") end
end) })
EventsSub:AddButton({ Name = "Claim Boss Mastery Now", Callback = safeCallback(function()
    local n = Boss.ClaimMastery()
    if n and n > 0 then Notify("Boss Mastery", "Claimed " .. n .. " reward(s)", "Success")
    else Notify("Boss Mastery", "Nothing to claim yet", "Info") end
end) })
EventsSub:AddButton({ Name = "Boss Arena Status", Callback = safeCallback(function()
    local snap = Boss.Snapshot()
    if snap and snap.Open then
        Notify("Boss Arena", "OPEN — " .. math.floor(tonumber(snap.BossHealth) or 0)
            .. "/" .. math.floor(tonumber(snap.BossMaxHealth) or 0) .. " HP", "Success")
    else
        local secs = Boss.SecondsUntilOpen()
        local eta  = secs and string.format("%dm %ds", math.floor(secs/60), secs%60) or "unknown"
        Notify("Boss Arena", "Closed — next in " .. eta, "Info")
    end
end) })

RewardsSub:AddToggle({ Name = "Auto Claim Away Earnings & Codex", Default = false, Flag = "claim_auto_rewards",
    Callback = function(v) autoClaimRewards = v end })
RewardsSub:AddButton({ Name = "Claim All Rewards Now", Primary = true, Callback = safeCallback(function()
    ClaimAllAvailableRewards(); Notify("Rewards", "Claimed all ready rewards", "Success")
end) })
end

-- ─── TAB 3: COMBAT  (Anti Guard card FIRST, then Bat, then Defense) ──────────
do
-- ══ ANTI GUARD CARD ══ (separate, above all other combat tools)
local AntiGuardSub = CombatTab:AddSubTab("Anti Guard")
local BatSub       = CombatTab:AddSubTab("Bat & Slap Aura")
local GuardSub     = CombatTab:AddSubTab("Defense & Guards")

AntiGuardSub:AddToggle({
    Name = "Anti Guard (Guards Cannot Harm You)",
    Default = false, Flag = "anti_guard_main",
    Callback = safeCallback(function(v)
        antiGuardEnabled = v
        if v then
            pcall(BlockGuardRemotes)
            pcall(DisableNearbyGuards, 100)
            Notify("Anti Guard", "Active — guards disabled near you", "Success")
        else
            Notify("Anti Guard", "Disabled", "Error")
        end
    end)
})
AntiGuardSub:AddSlider({
    Name = "Guard Disable Radius", Min = 20, Max = 200, Default = 80, Suffix = " studs",
    Flag = "anti_guard_radius",
    Callback = function(v)
        -- radius is used inline inside DisableNearbyGuards via the worker
    end
})
AntiGuardSub:AddToggle({
    Name = "Auto Heal (Max HP always)", Default = false, Flag = "anti_guard_heal",
    Callback = function(v)
        if v then
            -- Heal loop is covered by the anti-guard worker when antiGuardEnabled
            antiGuardEnabled = antiGuardEnabled or v
        end
    end
})
AntiGuardSub:AddButton({
    Name = "Disable All Nearby Guards Now", Primary = true,
    Callback = safeCallback(function()
        pcall(DisableNearbyGuards, 150)
        pcall(BlockGuardRemotes)
        Notify("Anti Guard", "All nearby guards disabled", "Success")
    end)
})

BatSub:AddToggle({ Name = "Bat / Slap Aura", Default = false, Flag = "bat_aura_enabled",
    Callback = safeCallback(function(v)
        batAuraEnabled = v
        Notify("Bat Aura", v and "Enabled" or "Disabled", v and "Success" or "Error")
    end)
})
BatSub:AddSlider({ Name = "Aura Radius", Min = 5, Max = 50, Default = 20, Suffix = " studs", Flag = "bat_radius",
    Callback = function(v) batAuraRadius = v end })
BatSub:AddSlider({ Name = "Swing Delay", Min = 0.05, Max = 1.0, Default = 0.2, Suffix = "s", Flag = "bat_delay",
    Callback = function(v) batAuraDelay = v end })
BatSub:AddButton({ Name = "Swing Bat Once", Primary = true, Callback = safeCallback(function()
    local re = GetNetRemote("RE/BatSwing/Trigger")
    if re then re:FireServer() end
    Notify("Bat", "Triggered swing", "Info")
end) })

GuardSub:AddToggle({ Name = "Anti-Trap (Destroy Enemy Hitboxes)", Default = true, Flag = "avoid_traps",
    Callback = safeCallback(function(v)
        avoidTrapsEnabled = v
        if v then pcall(NeutralizeTraps) end
        Notify("Anti-Trap", v and "Active" or "Disabled", v and "Success" or "Error")
    end)
})
GuardSub:AddToggle({ Name = "No Knockback / Ragdoll Immunity", Default = true, Flag = "no_knockback",
    Callback = safeCallback(function(v)
        SetNoKnockback(v)
        Notify("Knockback", v and "Ragdoll immunity active" or "Enabled", v and "Success" or "Error")
    end)
})
GuardSub:AddToggle({ Name = "Anti-Ragdoll (Quick Standup)", Default = true, Flag = "anti_ragdoll",
    Callback = function(v) antiRagdollEnabled = v end })
end

-- ─── TAB 4: PLAYER ───────────────────────────────────────────────────────────
do
local MoveSub     = PlayerTab:AddSubTab("Movement")
local AreaTpSub   = PlayerTab:AddSubTab("Area Travel")
local PlotTpSub   = PlayerTab:AddSubTab("Plot Travel")
local PlayerTpSub = PlayerTab:AddSubTab("Player Travel")
local PerfSub     = PlayerTab:AddSubTab("Visuals & FPS")

MoveSub:AddToggle({ Name = "Enable WalkSpeed", Default = false, Flag = "speed_enabled",
    Callback = safeCallback(function(v)
        walkSpeedEnabled = v
        if not v then local hum = findHum(); if hum then hum.WalkSpeed = 16 end end
        Notify("WalkSpeed", v and "Enabled" or "Disabled", v and "Success" or "Error")
    end)
})
MoveSub:AddSlider({ Name = "WalkSpeed Value", Min = 16, Max = 10000, Default = 24,
    Suffix = " studs/s", Flag = "speed_val", Callback = function(v) ApplyWalkSpeed(v) end })
MoveSub:AddToggle({ Name = "Enable JumpPower", Default = false, Flag = "jump_enabled",
    Callback = safeCallback(function(v)
        jumpPowerEnabled = v
        if not v then local hum = findHum(); if hum then hum.JumpPower = 50 end end
        Notify("JumpPower", v and "Enabled" or "Disabled", v and "Success" or "Error")
    end)
})
MoveSub:AddSlider({ Name = "JumpPower Value", Min = 50, Max = 300, Default = 60,
    Suffix = "", Flag = "jump_val", Callback = function(v) ApplyJumpPower(v) end })
MoveSub:AddToggle({ Name = "Infinite Jump", Default = false, Flag = "inf_jump",
    Callback = function(v) infiniteJump = v end })
MoveSub:AddToggle({ Name = "Smooth Fly (WASD + Space/Shift)", Default = false, Flag = "fly_enabled",
    Callback = safeCallback(function(v)
        if v then startFly() else stopFly() end
        Notify("Fly", v and "Enabled" or "Disabled", v and "Success" or "Error")
    end)
})
MoveSub:AddSlider({ Name = "Fly Speed", Min = 20, Max = 250, Default = 60, Suffix = " studs/s",
    Flag = "fly_speed", Callback = function(v) flySpeed = v end })
MoveSub:AddToggle({ Name = "Anti-AFK (Bypass 20min Kick)", Default = false, Flag = "anti_afk",
    Callback = function(v) SetAntiAFK(v) end })

local selectedAreaTp = "Base / Plot"
local areaKeys = {}
for k in pairs(AREA_COORDINATES) do table.insert(areaKeys, k) end
table.sort(areaKeys)
AreaTpSub:AddDropdown({ Name = "Select Area", Options = areaKeys, Items = areaKeys,
    Default = "Base / Plot", Flag = "tele_area", Callback = function(v) selectedAreaTp = v end })
AreaTpSub:AddButton({ Name = "Travel to Selected Area", Primary = true, Callback = safeCallback(function()
    local pos = AREA_COORDINATES[selectedAreaTp]
    if selectedAreaTp == "Base / Plot" then pos = GetLocalPlotCenter() end
    if pos then
        Notify("Travel", "Traveling to " .. selectedAreaTp, "Info")
        TravelRoadPath(pos, glideSpeed or 200)
        Notify("Travel", "Arrived at " .. selectedAreaTp, "Success")
    else Notify("Travel", "Area position not found", "Error") end
end) })

local selectedPlotNum = "My Plot"
local plotOptions = { "Plot 1","Plot 2","Plot 3","Plot 4","Plot 5","Plot 6","Plot 7","My Plot" }
PlotTpSub:AddDropdown({ Name = "Select Plot", Options = plotOptions, Items = plotOptions,
    Default = "My Plot", Flag = "tele_plot", Callback = function(v) selectedPlotNum = v end })
PlotTpSub:AddButton({ Name = "Travel to Plot", Primary = true, Callback = safeCallback(function()
    local slotNum = selectedPlotNum == "My Plot" and GetLocalSlot()
        or tonumber(selectedPlotNum:match("%d+")) or 1
    local plot    = Workspace.Plots:FindFirstChild(tostring(slotNum))
    local targetPos = plot and (plot:FindFirstChild("CenterPoint") and plot.CenterPoint.Position
        or plot:GetPivot().Position)
    if targetPos then
        TravelRoadPath(targetPos + Vector3.new(0,2,0), glideSpeed or 200)
        Notify("Plot", "Arrived at Plot " .. slotNum, "Success")
    else Notify("Plot", "Plot not found", "Error") end
end) })

local selectedPlayerName = nil
local function GetPlayerList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(names, p.Name) end
    end
    table.sort(names)
    if #names == 0 then names = { "(no other players)" } end
    return names
end
local playerDropdown = PlayerTpSub:AddDropdown({ Name = "Select Player", Options = GetPlayerList(),
    Items = GetPlayerList(), Default = nil, Flag = "tele_plr",
    Callback = function(v) selectedPlayerName = v end })
PlayerTpSub:AddButton({ Name = "Refresh Player List", Callback = function()
    playerDropdown:SetOptions(GetPlayerList()); Notify("Players", "Refreshed", "Info")
end })
PlayerTpSub:AddButton({ Name = "Travel to Player", Primary = true, Callback = safeCallback(function()
    if not selectedPlayerName then return end
    local targetPlr = Players:FindFirstChild(selectedPlayerName)
    local tHrp = targetPlr and targetPlr.Character
        and targetPlr.Character:FindFirstChild("HumanoidRootPart")
    if tHrp then
        TravelRoadPath(tHrp.Position + Vector3.new(0,2,0), glideSpeed or 200)
        Notify("Player", "Arrived at " .. selectedPlayerName, "Success")
    else Notify("Player", "Player unavailable", "Error") end
end) })

PerfSub:AddToggle({ Name = "Fullbright (Daylight Visuals)", Default = false, Flag = "fullbright",
    Callback = function(v) SetFullbright(v) end })
PerfSub:AddButton({ Name = "Delete Own Pet Renders (FPS Boost)", Primary = true,
    Callback = safeCallback(function()
        local count = DeleteOwnPetRenders()
        Notify("Performance", "Removed " .. count .. " rendered pet(s)", "Success")
    end)
})
end

-- ─── TAB 5: SETTINGS ─────────────────────────────────────────────────────────
do
local ConfigSub = SettingsTab:AddSubTab("Configuration")

if HAS_CONFIG then
    ConfigSub:AddInput({ Name = "Config Name", Default = CONFIG_NAME, Flag = "cfg_name",
        Callback = function(v) if v and #v > 0 then CONFIG_NAME = v end end })
    ConfigSub:AddButton({ Name = "Save Config", Primary = true, Callback = safeCallback(function()
        local ok, err = Library:SaveConfig(CONFIG_NAME)
        Notify("Config", ok and ("Saved '" .. CONFIG_NAME .. "'")
            or ("Save failed: " .. tostring(err)), ok and "Success" or "Error")
    end) })
    ConfigSub:AddButton({ Name = "Load Config", Callback = safeCallback(function()
        local ok, err = Library:LoadConfig(CONFIG_NAME)
        if ok then ResyncAll(); Notify("Config", "Loaded '" .. CONFIG_NAME .. "'", "Success")
        else Notify("Config", "Load failed: " .. tostring(err), "Error") end
    end) })
end

ConfigSub:AddKeybind({ Name = "Toggle UI", Default = Enum.KeyCode.RightControl, Flag = "ui_toggle_key",
    OnPress = function() Window:Toggle() end })
ConfigSub:AddDivider()
ConfigSub:AddButton({ Name = "Unload Yush HUB", Callback = safeCallback(function()
    pcall(function() HUB.Unload() end)
end) })
ConfigSub:AddParagraph({
    Title   = "YUSH HUB  |  Steal An Egg Script",
    Content = "Version 4.4.0 (Production)\n"
        .. "Anti Guard System · Fly Up & Down Steal · BAC Telemetry Spoofer · UGI Neutralizer · "
        .. "Evidence Scrubber · Rarity Filter · ESP Tracker · Boss Auto Fight\n"
        .. "Made by https://t.me/PrimeYush :)\n"
        .. "Credits to @YushPogi"
})
end

-- ════════════════════════════════════════════════════════════════════
-- HUB CLEANUP & UNLOAD
-- ════════════════════════════════════════════════════════════════════
HUB.Unload = function()
    AutoSaveConfig()
    HUB.dead = true

    for _, c in ipairs(HUB.conns) do pcall(function() c:Disconnect() end) end
    HUB.conns = {}

    for _, d in ipairs(HUB.drawings) do pcall(function() d:Remove() end) end
    HUB.drawings = {}

    for _, h in ipairs(HUB.highlights) do pcall(function() h:Destroy() end) end
    HUB.highlights = {}

    -- Destroy overlay GUIs
    for _, sg in ipairs(HUB.overlays) do pcall(function() sg:Destroy() end) end
    HUB.overlays = {}

    stopFly()
    SetFullbright(false)

    local hum = findHum()
    if hum then
        hum.PlatformStand = false
        hum.WalkSpeed     = 16
        hum.JumpPower     = 50
    end

    pcall(function() Window:Destroy() end)
    _G.YushStealAnEgg = nil
end

Notify("YUSH HUB", "Steal An Egg Script loaded!", "Success", 3.5)
