--[[
╔══════════════════════════════════════════════════════════╗
║          YUSH HUB | STEAL AN EGG — v3.0                 ║
║          Professional Edition | Fixed & Improved         ║
║          Made by @YushPogi                               ║
╚══════════════════════════════════════════════════════════╝
--]]

-- ══════════════════════════════════════════════════════════
-- [[ ANTI CHEAT BYPASS ]]
-- ══════════════════════════════════════════════════════════
do
    local RS = game:GetService("RunService")
    if RS:IsServer() then return end

    pcall(function()
        workspace:SetAttribute("ClientObbyAntiTp", false)
    end)

    pcall(function()
        local ps = game:GetService("Players").LocalPlayer
            :WaitForChild("PlayerScripts", 3)
        if ps then
            for _, s in ipairs(ps:GetDescendants()) do
                if s:IsA("LocalScript") then
                    local n = s.Name:lower()
                    if n:find("antiteleport") or n:find("antitp")
                    or n:find("obbyanti") or n:find("anticheat") then
                        s.Disabled = true
                    end
                end
            end
        end
    end)

    pcall(function()
        local rep = game:GetService("ReplicatedStorage")
        local function hookRig()
            local ok, R = pcall(require, rep.Shared.Remotes)
            if ok and R and R.RigSync and R.RigSync.Refresh
            and not _G._YH_rig then
                _G._YH_rig = true
                R.RigSync.Refresh.OnClientEvent:Connect(function(d)
                    if type(d)=="string" and
                    (d:find("BeginImpulse") or d:find("BeginRagdoll")) then
                        return
                    end
                end)
            end
        end
        if rep:FindFirstChild("Shared") then hookRig()
        else
            rep.ChildAdded:Connect(function(c)
                if c.Name=="Shared" then hookRig() end
            end)
        end
    end)
end

-- ══════════════════════════════════════════════════════════
-- [[ SERVICES ]]
-- ══════════════════════════════════════════════════════════
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local RS2        = game:GetService("ReplicatedStorage")
local HttpSvc    = game:GetService("HttpService")
local Lighting   = game:GetService("Lighting")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
local hum  = char:WaitForChild("Humanoid")

lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end)

-- ══════════════════════════════════════════════════════════
-- [[ SETTINGS + AUTO SAVE ]]
-- ══════════════════════════════════════════════════════════
local SAVE_FILE = "YushHub_v3.json"

local S = {
    -- FARM
    AutoSteal       = false,
    InstantSteal    = false,
    AntiGuard       = false,
    AutoEquipBest   = false,
    AutoHatch       = false,
    AutoTreadmill   = false,
    FlightH         = 88,
    TweenSpd        = 60,
    CarrySpd        = 70,
    StealMinRarity  = 5,  -- 5 = Legendary default
    -- PLAYER
    WalkSpeed       = 16,
    NoClip          = false,
    InfJump         = false,
    Invisibility    = false,
    AntiRagdoll     = true,
    AntiTrap        = false,
    -- ESP
    ESPEggs         = false,
    ESPMinRar       = 7,
    ESPShowInfo     = true,
    ESPEggSz        = 0.5,
    ESPGuards       = false,
    ESPPlayers      = false,
    ESPPlayerInfo   = true,
    AutoHitPlayer   = false,
    AutoHitEggH     = false,
    -- PROGRESS
    AutoFuse        = false,
    FuseMaxRar      = 0,
    FuseSkipMut     = true,
    FuseEject       = false,
    AutoFavPet      = false,
    AutoFavEq       = false,
    AutoUnFavEq     = false,
    -- MISC
    AntiAFK         = false,
    FPSOpt          = false,
    HideOtherPets   = false,
    HideOtherEggs   = false,
    HideMyPets      = false,
    HideMyEggs      = false,
    HideMoneyAnim   = false,
}

local function saveSettings()
    pcall(function()
        if writefile then
            writefile(SAVE_FILE, HttpSvc:JSONEncode(S))
        end
    end)
end

local function loadSettings()
    pcall(function()
        if readfile and isfile and isfile(SAVE_FILE) then
            local data = HttpSvc:JSONDecode(readfile(SAVE_FILE))
            for k, v in pairs(data) do
                if S[k] ~= nil then S[k] = v end
            end
        end
    end)
end

loadSettings()

-- Auto save every 10s
task.spawn(function()
    while task.wait(10) do saveSettings() end
end)

-- ══════════════════════════════════════════════════════════
-- [[ HELPERS ]]
-- ══════════════════════════════════════════════════════════
local function tryReq(path)
    local ok, r = pcall(require, path)
    return ok and r or nil
end

local function getRemotes()
    return tryReq(RS2.Shared and RS2.Shared.Remotes)
        or tryReq(RS2.Library and RS2.Library.Client and RS2.Library.Client.Network)
end

local function getEggState()
    return tryReq(RS2.Client and RS2.Client.EggState)
end

local function getPlotState()
    return tryReq(RS2.Client and RS2.Client.PlotState)
end

local function getSaveData()
    local r = tryReq(RS2.Shared and RS2.Shared.Save)
    if r then return r.Get and r.Get() or r.Peek and r.Peek() end
end

local rarityN = {
    common=1, uncommon=2, rare=3, epic=4, legendary=5,
    mythic=6, cosmic=7, secret=8, eternal=9, divine=10,
    titan=11, ["light & dark"]=12,
}
local rarityLabels = {
    "Common","Uncommon","Rare","Epic","Legendary",
    "Mythic","Cosmic","Secret","Eternal","Divine","Titan","Light & Dark"
}

local function getRarity(cat)
    if not cat then return 1 end
    local assets = tryReq(RS2.Data and RS2.Data.Assets)
        or tryReq(RS2.Directory and RS2.Directory.Assets)
    if assets then
        local d = (assets.Directory or assets)[cat]
        if d and d.Rarity then
            local rv = d.Rarity
            if type(rv)=="table" then
                return rv.Rank or rv.RarityNumber or 1
            end
            if type(rv)=="string" then
                return rarityN[rv:lower()] or 1
            end
        end
    end
    return 1
end

local function getSafeZone()
    local w = workspace:FindFirstChild("World")
    local a = w and w:FindFirstChild("Areas")
    local s = a and a:FindFirstChild("StartArea")
    if s then
        if s:IsA("BasePart") then return s.Position + Vector3.new(0,3,0) end
        if s.PrimaryPart then return s.PrimaryPart.Position + Vector3.new(0,3,0) end
    end
    return Vector3.new(515, 74.4, -362.8)
end

local function getPlot()
    local ps = getPlotState()
    if ps and ps.ResolvePlot then
        local d = ps.ResolvePlot(lp)
        if d and d.CenterPoint and d.PetArea then
            return {
                CenterPoint = d.CenterPoint,
                PetArea     = d.PetArea,
                PlotFolder  = d.PlotFolder,
            }
        end
    end
    return nil
end

local function getCurrentSpeed()
    local h2 = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if h2 and h2.WalkSpeed > 0 then
        return math.max(h2.WalkSpeed * 3, S.TweenSpd)
    end
    return S.TweenSpd
end

local function tweenTo(target, spd)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return false end
    spd = spd or getCurrentSpeed()
    local dist = (target - h.Position).Magnitude
    if dist < 0.5 then return true end
    local info = TweenInfo.new(dist/math.max(spd,1), Enum.EasingStyle.Linear)
    local t = TweenSvc:Create(h, info, {CFrame = CFrame.new(target)})
    t:Play()
    t.Completed:Wait()
    return true
end

local function liftTo(y)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end
    h.CFrame = CFrame.new(h.Position.X, y, h.Position.Z)
    h.AssemblyLinearVelocity  = Vector3.zero
    h.AssemblyAngularVelocity = Vector3.zero
end

local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title=title or "Yush Hub", Text=text or "", Duration=3,
        })
    end)
end

-- ══════════════════════════════════════════════════════════
-- [[ ANTI KNOCKBACK — ALWAYS ON ]]
-- ══════════════════════════════════════════════════════════
local _rigHooked = false
local function applyAntiKnockback(c)
    c = c or lp.Character
    if not c then return end
    local h2 = c:FindFirstChildOfClass("Humanoid")
    if h2 then pcall(function()
        h2:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h2:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
        h2:SetStateEnabled(Enum.HumanoidStateType.Physics,     false)
    end) end
    c.DescendantAdded:Connect(function(d)
        if not S.AntiRagdoll then return end
        if (d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint"))
        and d.Name:find("Ragdoll") then
            task.defer(function()
                if d and d.Parent then pcall(d.Destroy, d) end
            end)
        elseif d:IsA("Motor6D") and not d.Enabled then
            task.defer(function()
                if d and d.Parent then d.Enabled = true end
            end)
        end
    end)
    if not _rigHooked then
        _rigHooked = true
        pcall(function()
            local rem = getRemotes()
            if rem and rem.RigSync and rem.RigSync.Refresh then
                rem.RigSync.Refresh.OnClientEvent:Connect(function(d)
                    if not S.AntiRagdoll then return end
                    if type(d)=="string" and
                    (d:find("BeginImpulse") or d:find("BeginRagdoll")) then
                        return
                    end
                end)
            end
        end)
    end
end

lp.CharacterAdded:Connect(function(c)
    task.wait(0.3); applyAntiKnockback(c)
end)
task.spawn(applyAntiKnockback)

-- ══════════════════════════════════════════════════════════
-- [[ STEAL EGG CORE ]]
-- ══════════════════════════════════════════════════════════
local blockedEggs = {}

local function isHoldingEgg()
    local c = lp.Character
    if not c then return false end
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and
        ch:GetAttribute("ItemType") == "AssetEgg" then
            return true
        end
    end
    local pg = lp:FindFirstChild("PlayerGui")
    local dg = pg and pg:FindFirstChild("DropHeldEgg")
    return dg and dg.Enabled or false
end

local function getBestEgg()
    -- Clean expired blocks
    local now = os.clock()
    for uid, t in pairs(blockedEggs) do
        if now > t then blockedEggs[uid] = nil end
    end

    local eggs = {}
    local es = getEggState()

    if es and es.ReadFieldEggs then
        local ok, rec = pcall(es.ReadFieldEggs)
        if ok and rec then
            local list = rec.Records or rec
            for _, e in pairs(type(list)=="table" and list or {}) do
                if type(e)=="table" and e.Uid
                and (e.State=="Slot" or e.State=="Dropped")
                and not e.CarrierUserId
                and not blockedEggs[e.Uid] then
                    local r = getRarity(e.AssetCategory)
                    if r >= S.StealMinRarity then
                        table.insert(eggs, e)
                    end
                end
            end
        end
    end

    -- Workspace fallback
    local sf = workspace:FindFirstChild("AreaEggSlotsClient")
    if sf and #eggs == 0 then
        for _, sl in ipairs(sf:GetChildren()) do
            if not blockedEggs[sl.Name] then
                local hb = sl:FindFirstChild("Hitbox")
                local cat = sl:GetAttribute("AssetCategory") or sl.Name
                if hb and getRarity(cat) >= S.StealMinRarity then
                    table.insert(eggs, {
                        Uid          = sl.Name,
                        AssetCategory = cat,
                        State        = "Slot",
                        BottomCFrame = hb.CFrame,
                        BoundsCFrame = hb.CFrame,
                    })
                end
            end
        end
    end

    if #eggs == 0 then return nil end

    -- Sort: highest rarity first, dropped eggs get bonus score
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    table.sort(eggs, function(a, b)
        local ra = getRarity(a.AssetCategory)*1000
                + (a.State=="Dropped" and 500 or 0)
        local rb = getRarity(b.AssetCategory)*1000
                + (b.State=="Dropped" and 500 or 0)
        if h then
            local pa = (a.BottomCFrame or a.BoundsCFrame)
                and (a.BottomCFrame or a.BoundsCFrame).Position
            local pb = (b.BottomCFrame or b.BoundsCFrame)
                and (b.BottomCFrame or b.BoundsCFrame).Position
            if pa then ra = ra - (h.Position-pa).Magnitude*0.01 end
            if pb then rb = rb - (h.Position-pb).Magnitude*0.01 end
        end
        return ra > rb
    end)
    return eggs[1]
end

local function grabEgg(uid, slotKey)
    local rem = getRemotes()
    local es  = getEggState()
    local deadline = os.clock() + 4

    while os.clock() < deadline do
        if not S.AutoSteal then return false end
        if isHoldingEgg() then return true end

        -- Method 1: EggState.CarryFieldEgg
        pcall(function()
            if es and es.CarryFieldEgg then
                es.CarryFieldEgg(uid, slotKey)
            end
        end)
        -- Method 2: Remote invoke
        pcall(function()
            local rem2 = getRemotes()
            if rem2 and rem2.EggWorld and rem2.EggWorld.AskFieldEggCarry then
                rem2.EggWorld.AskFieldEggCarry:InvokeServer({
                    Uid=uid, FirstAreaSlotKey=slotKey
                })
            end
        end)
        -- Method 3: Networking package
        pcall(function()
            local net = RS2:FindFirstChild("Packages")
                and RS2.Packages:FindFirstChild("Networking")
            local rf = net and net:FindFirstChild("RF/EggWorld/AskFieldEggCarry")
            if rf then
                rf:InvokeServer({Uid=uid, FirstAreaSlotKey=slotKey})
            end
        end)
        -- Method 4: ProximityPrompt
        pcall(function()
            if fireproximityprompt then
                local sf = workspace:FindFirstChild("AreaEggSlotsClient")
                local sl = sf and sf:FindFirstChild(uid)
                if sl then
                    for _, d in ipairs(sl:GetDescendants()) do
                        if d:IsA("ProximityPrompt") and d.Enabled then
                            fireproximityprompt(d, 0)
                        end
                    end
                end
            end
        end)

        task.wait(0.06)
    end
    return isHoldingEgg()
end

local function placeEggInField()
    task.wait(0.4)
    local plot = getPlot()
    if not plot then return end

    local rem = getRemotes()
    local es  = getEggState()
    local pa  = plot.PetArea
    local cp  = plot.CenterPoint
    local unplaced, placed = {}, {}

    pcall(function()
        local snap
        if rem and rem.EggWorld and rem.EggWorld.AskLiveSnapshot then
            snap = rem.EggWorld.AskLiveSnapshot:InvokeServer()
        elseif es and es.ReadOwnedEggs then
            snap = es.ReadOwnedEggs()
        end
        if not snap then return end
        for _, v in ipairs(type(snap)=="table" and snap or {}) do
            if type(v)=="table" and v.OwnerUserId==lp.UserId then
                for k, rec in pairs(v.Records or {}) do
                    if type(rec)=="table" then
                        if rec.Placement then
                            table.insert(placed, {uid=k,
                                lc=rec.Placement.LocalCFrame})
                        else
                            table.insert(unplaced, k)
                        end
                    end
                end
                break
            end
        end
    end)

    if #unplaced == 0 then return end

    -- Move to pen
    local penPos = pa.Position + Vector3.new(0,3,0)
    local cPos   = cp.Position  + Vector3.new(0,3,0)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if h and (h.Position-cPos).Magnitude > 10 then
        tweenTo(cPos, getCurrentSpeed())
    end
    tweenTo(penPos, getCurrentSpeed())

    local function freeSlot()
        local sx = pa.Size.X/2-3
        local sz = pa.Size.Z/2-3
        for z=-sz,sz,5 do
            for x=-sx,sx,5 do
                local wp = pa.CFrame:PointToWorldSpace(Vector3.new(x,0,z))
                local free = true
                for _, pl in ipairs(placed) do
                    if pl.lc and type(pl.lc)=="string" then
                        local nums={}
                        for n in pl.lc:gmatch("[-0-9%.e]+") do
                            table.insert(nums, tonumber(n))
                        end
                        if #nums>=3 then
                            local pws = cp.CFrame:ToWorldSpace(
                                CFrame.new(unpack(nums))).Position
                            if (pws-wp).Magnitude<5 then
                                free=false; break
                            end
                        end
                    end
                end
                if free then
                    return wp, cp.CFrame:ToObjectSpace(CFrame.new(wp))
                end
            end
        end
        return nil, nil
    end

    for _, uid in ipairs(unplaced) do
        pcall(function()
            if es and es.WearEggTool then
                es.WearEggTool(uid)
            elseif rem and rem.EggWorld and rem.EggWorld.AskWearTool then
                rem.EggWorld.AskWearTool:InvokeServer(uid)
            end
        end)
        task.wait(0.2)

        local wp, lc = freeSlot()
        if not wp then break end

        pcall(function()
            if es and es.PlantEgg then
                es.PlantEgg(uid, lc)
            else
                local net = RS2:FindFirstChild("Packages")
                    and RS2.Packages:FindFirstChild("Networking")
                local rf = net and net:FindFirstChild("RF/EggWorld/AskPlaceEgg")
                if rf then rf:InvokeServer({Uid=uid, LocalCFrame=lc}) end
            end
        end)

        table.insert(placed, {uid=uid, lc=tostring(lc)})

        pcall(function()
            if es and es.DoffEggTool then
                es.DoffEggTool(uid)
            elseif rem and rem.EggWorld and rem.EggWorld.AskDoffTool then
                rem.EggWorld.AskDoffTool:InvokeServer(uid)
            end
        end)
        task.wait(0.15)
    end
end

-- ── CONTINUOUS STEAL LOOP ────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.1)
        if not S.AutoSteal then continue end

        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not h then continue end

        local egg = getBestEgg()
        if not egg then task.wait(0.8); continue end

        local pos = (egg.BottomCFrame or egg.BoundsCFrame)
            and (egg.BottomCFrame or egg.BoundsCFrame).Position
        if not pos then task.wait(0.3); continue end

        local spd = getCurrentSpeed()

        -- 1. Lift up
        liftTo(S.FlightH)
        task.wait(0.1)

        -- 2. Fly above egg
        if S.InstantSteal then
            h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if h then
                h.CFrame = CFrame.new(pos.X, S.FlightH, pos.Z)
                h.AssemblyLinearVelocity = Vector3.zero
            end
            task.wait(0.05)
        else
            tweenTo(Vector3.new(pos.X, S.FlightH, pos.Z), spd)
        end

        if not S.AutoSteal then continue end

        -- 3. Descend to egg
        if S.InstantSteal then
            h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if h then
                h.CFrame = CFrame.new(pos.X, pos.Y+2.5, pos.Z)
                h.AssemblyLinearVelocity = Vector3.zero
            end
            task.wait(0.08)
        else
            tweenTo(Vector3.new(pos.X, pos.Y+2.5, pos.Z), spd * 0.8)
            task.wait(0.05)
        end

        -- 4. Grab egg
        local slotKey = egg.NestId and egg.AreaId
            and (egg.AreaId..":"..egg.NestId) or nil
        local got = grabEgg(egg.Uid, slotKey)

        if not got then
            -- Block this egg and immediately try another
            blockedEggs[egg.Uid] = os.clock() + 5
            continue
        end

        -- 5. Lift back up with egg
        h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then
            h.CFrame = CFrame.new(h.Position.X, S.FlightH, h.Position.Z)
            h.AssemblyLinearVelocity  = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
        end
        task.wait(0.1)

        -- 6. Return to safe zone
        local safe = getSafeZone()
        local cspd = math.max(S.CarrySpd, spd)

        if S.InstantSteal then
            h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if h then
                h.CFrame = CFrame.new(safe)
                h.AssemblyLinearVelocity = Vector3.zero
            end
            task.wait(0.15)
        else
            tweenTo(Vector3.new(safe.X, S.FlightH, safe.Z), cspd)
            if not S.AutoSteal then continue end
            tweenTo(safe, cspd * 0.7)
        end

        -- 7. Brief wait for server registration
        task.wait(0.4)

        -- 8. Place egg in background, immediately look for next egg
        task.spawn(placeEggInField)
        -- Loop continues immediately to steal again
    end
end)

-- ══════════════════════════════════════════════════════════
-- [[ FARM LOOPS ]]
-- ══════════════════════════════════════════════════════════

-- Anti Guard
task.spawn(function()
    while task.wait(0.08) do
        if not S.AntiGuard then continue end
        local c = lp.Character
        if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanTouch = false end)
            end
        end
    end
end)

-- Auto Equip Best
task.spawn(function()
    while task.wait(5) do
        if not S.AutoEquipBest then continue end
        pcall(function()
            local rem = getRemotes()
            if rem and rem.Haul and rem.Haul.WearBest then
                rem.Haul.WearBest:InvokeServer()
                return
            end
            local net = RS2:FindFirstChild("Network")
            local eb  = net and net:FindFirstChild("Backpack: EquipBest")
            if eb then eb:InvokeServer() end
        end)
    end
end)

-- Auto Hatch
task.spawn(function()
    while task.wait(2) do
        if not S.AutoHatch then continue end
        pcall(function()
            local es  = getEggState()
            local rem = getRemotes()
            if not es then return end
            local snap
            if rem and rem.EggWorld and rem.EggWorld.AskLiveSnapshot then
                snap = rem.EggWorld.AskLiveSnapshot:InvokeServer()
            elseif es.ReadOwnedEggs then
                snap = es.ReadOwnedEggs()
            end
            if not snap then return end
            for _, v in ipairs(type(snap)=="table" and snap or {}) do
                if type(v)=="table" and v.OwnerUserId==lp.UserId then
                    for k, rec in pairs(v.Records or {}) do
                        if type(rec)=="table" and rec.Placement then
                            local ready = false
                            if es.IsReadyToHatch then
                                pcall(function()
                                    ready = es.IsReadyToHatch(k)
                                end)
                            end
                            if ready then
                                if es.BeginHatch then
                                    pcall(es.BeginHatch, k)
                                    task.wait(0.3)
                                end
                                if es.FinishHatch then
                                    pcall(es.FinishHatch, k)
                                end
                            end
                        end
                    end
                    break
                end
            end
        end)
    end
end)

-- Auto Treadmill
local function checkTreadmill()
    local ok, md = pcall(require, RS2.Client and RS2.Client.MusicDirector)
    if ok and md and md.HasCustomTreadmill then
        local ok2, r = pcall(md.HasCustomTreadmill)
        if ok2 then return r == true end
    end
    return false
end

local function exitTreadmill()
    pcall(function()
        local rem = getRemotes()
        if rem and rem.Treadmill and rem.Treadmill.AskDoff then
            rem.Treadmill.AskDoff:InvokeServer()
        end
        local net = RS2:FindFirstChild("Network")
        local ru  = net and net:FindFirstChild("Treadmills: RequestUnequip")
        if ru then ru:InvokeServer() end
    end)
end

UIS.JumpRequest:Connect(function()
    if S.AutoTreadmill and checkTreadmill() then exitTreadmill() end
end)

task.spawn(function()
    while task.wait(0.8) do
        if not S.AutoTreadmill then
            if checkTreadmill() then exitTreadmill() end
            continue
        end
        if checkTreadmill() then continue end

        local plot = getPlot()
        if not plot or not plot.PlotFolder then continue end
        local tb = plot.PlotFolder:FindFirstChild("TreadmillBottom")
        if not tb then continue end

        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not h then continue end

        local cPos = plot.CenterPoint
            and (plot.CenterPoint.Position + Vector3.new(0,3,0))
        if cPos and (h.Position-cPos).Magnitude > 8 then
            tweenTo(cPos, 120)
        end
        tweenTo(tb.Position + Vector3.new(0,3,0), 80)

        h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then
            local lv = tb.CFrame.LookVector
            h.CFrame = CFrame.lookAt(h.Position, h.Position+lv)
            local hm2 = lp.Character:FindFirstChildOfClass("Humanoid")
            if hm2 then pcall(function() hm2:Move(lv) end) end
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- [[ PLAYER FEATURES ]]
-- ══════════════════════════════════════════════════════════

-- Walk Speed
task.spawn(function()
    while task.wait(0.1) do
        local h2 = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if h2 then h2.WalkSpeed = S.WalkSpeed end
    end
end)

-- NoClip
task.spawn(function()
    while task.wait(0.05) do
        if not S.NoClip then continue end
        local c = lp.Character
        if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanCollide = false end)
            end
        end
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if S.InfJump then
        local h2 = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if h2 then h2:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Invisibility loop
task.spawn(function()
    while task.wait(0.3) do
        if not S.Invisibility then continue end
        local c = lp.Character
        if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            pcall(function()
                if p:IsA("BasePart") or p:IsA("MeshPart") then
                    p.LocalTransparencyModifier = 1
                elseif p:IsA("Decal") or p:IsA("Texture") then
                    p.Transparency = 1
                end
            end)
        end
        -- Hide held egg tool too
        for _, ch in ipairs(c:GetChildren()) do
            if ch:IsA("Tool") then
                for _, p in ipairs(ch:GetDescendants()) do
                    pcall(function()
                        if p:IsA("BasePart") then
                            p.LocalTransparencyModifier = 1
                        end
                    end)
                end
            end
        end
    end
end)

-- Anti Trap
task.spawn(function()
    while task.wait(0.1) do
        if not S.AntiTrap then continue end
        local c = lp.Character
        if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
                pcall(function() p.CanCollide = false end)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- [[ ESP ]]
-- ══════════════════════════════════════════════════════════
local espFolder = Instance.new("Folder", workspace)
espFolder.Name  = "YushESP"
local espObj    = {}

local rarityColors = {
    Color3.fromRGB(155,155,155), Color3.fromRGB(50,205,50),
    Color3.fromRGB(70,130,230),  Color3.fromRGB(155,60,220),
    Color3.fromRGB(255,140,0),   Color3.fromRGB(255,50,180),
    Color3.fromRGB(180,0,255),   Color3.fromRGB(255,255,255),
    Color3.fromRGB(0,255,200),   Color3.fromRGB(255,215,0),
    Color3.fromRGB(255,50,50),   Color3.fromRGB(255,120,255),
}

task.spawn(function()
    while task.wait(0.9) do
        local active = {}

        -- Egg ESP
        if S.ESPEggs then
            local es = getEggState()
            local eggs = {}
            if es and es.ReadFieldEggs then
                local ok, rec = pcall(es.ReadFieldEggs)
                if ok and rec then
                    for _, e in pairs(rec.Records or rec) do
                        if type(e)=="table" and e.Uid then
                            eggs[e.Uid] = e
                        end
                    end
                end
            end
            local sf = workspace:FindFirstChild("AreaEggSlotsClient")
            if sf then
                for _, sl in ipairs(sf:GetChildren()) do
                    if not eggs[sl.Name] then
                        local hb = sl:FindFirstChild("Hitbox")
                        if hb then
                            eggs[sl.Name] = {
                                Uid=sl.Name,
                                AssetCategory=sl:GetAttribute("AssetCategory") or sl.Name,
                                State="Slot", BottomCFrame=hb.CFrame,
                            }
                        end
                    end
                end
            end

            for uid, egg in pairs(eggs) do
                local rar = getRarity(egg.AssetCategory)
                if rar < S.ESPMinRar then continue end
                local pos = (egg.BottomCFrame or egg.BoundsCFrame)
                    and (egg.BottomCFrame or egg.BoundsCFrame).Position
                if not pos then continue end
                local key = "EGG_"..uid; active[key]=true
                if not espObj[key] or not espObj[key].Parent then
                    local part = Instance.new("Part", espFolder)
                    part.Name="yh_"..key; part.Anchored=true
                    part.CanCollide=false; part.CanTouch=false
                    part.Material=Enum.Material.Neon
                    part.Shape=Enum.PartType.Ball; part.CastShadow=false
                    local bb = Instance.new("BillboardGui", part)
                    bb.AlwaysOnTop=true
                    bb.Size=UDim2.fromOffset(140,24)
                    bb.StudsOffset=Vector3.new(0,3,0)
                    local lbl = Instance.new("TextLabel", bb)
                    lbl.Name="TL"; lbl.Size=UDim2.fromScale(1,1)
                    lbl.BackgroundTransparency=1
                    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10
                    lbl.TextStrokeTransparency=0
                    espObj[key] = part
                end
                local pt  = espObj[key]
                local col = rarityColors[math.min(rar,12)]
                pt.CFrame = CFrame.new(pos)
                pt.Color  = col
                pt.Size   = Vector3.new(1,1,1) * S.ESPEggSz * 2.5
                if S.ESPShowInfo then
                    local bb  = pt:FindFirstChildOfClass("BillboardGui")
                    local lbl = bb and bb:FindFirstChild("TL")
                    if lbl then
                        lbl.Text = (egg.AssetCategory or "?")
                            .." [".. (rarityLabels[rar] or "?").."]"
                        lbl.TextColor3 = col
                    end
                end
            end
        end

        -- Guard ESP
        local ga = workspace:FindFirstChild("World")
        ga = ga and ga:FindFirstChild("Areas")
        ga = ga and ga:FindFirstChild("GuardAreas")
        if ga then
            for _, area in ipairs(ga:GetChildren()) do
                local guard = area:FindFirstChild("Guard")
                if guard and guard:IsA("Model") then
                    local key = "GUARD_"..area.Name
                    if S.ESPGuards then
                        active[key]=true
                        if not espObj[key] or not espObj[key].Parent then
                            local hl = Instance.new("Highlight", espFolder)
                            hl.Name=key
                            hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                            hl.FillTransparency=0.5
                            espObj[key]=hl
                        end
                        local st  = guard:GetAttribute("GuardState") or "Sleeping"
                        local col = st=="Chasing"
                            and Color3.fromRGB(255,50,50)
                            or st=="Waking"
                            and Color3.fromRGB(255,200,0)
                            or Color3.fromRGB(50,255,80)
                        espObj[key].Adornee     = guard
                        espObj[key].FillColor   = col
                        espObj[key].OutlineColor= col
                    end
                end
            end
        end

        -- Player ESP
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl==lp then continue end
            local c2 = pl.Character
            if not c2 then continue end
            local key = "PLAYER_"..pl.Name
            if S.ESPPlayers then
                active[key]=true
                if not espObj[key] or not espObj[key].Parent then
                    local hl = Instance.new("Highlight", espFolder)
                    hl.Name=key; hl.Adornee=c2
                    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency=0.5
                    hl.FillColor=Color3.fromRGB(255,80,80)
                    hl.OutlineColor=Color3.fromRGB(255,80,80)
                    espObj[key]=hl
                    if S.ESPPlayerInfo then
                        local ph = c2:FindFirstChild("HumanoidRootPart")
                        if ph then
                            local bb = Instance.new("BillboardGui", ph)
                            bb.Name="YH_PESP"; bb.AlwaysOnTop=true
                            bb.Size=UDim2.fromOffset(110,22)
                            bb.StudsOffset=Vector3.new(0,3,0)
                            local lb = Instance.new("TextLabel", bb)
                            lb.Size=UDim2.fromScale(1,1)
                            lb.BackgroundTransparency=1
                            lb.Font=Enum.Font.GothamBold; lb.TextSize=10
                            lb.TextColor3=Color3.fromRGB(255,80,80)
                            lb.TextStrokeTransparency=0; lb.Text=pl.Name
                        end
                    end
                end
                espObj[key].Adornee = c2
            end
        end

        -- Clean stale
        for k, o in pairs(espObj) do
            if not active[k] then
                if o and o.Parent then o:Destroy() end
                espObj[k]=nil
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- [[ AUTO HIT ]]
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.25) do
        if not S.AutoHitPlayer and not S.AutoHitEggH then continue end
        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not h then continue end
        local best, bd = nil, math.huge
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl==lp then continue end
            local c2 = pl.Character
            local ph = c2 and c2:FindFirstChild("HumanoidRootPart")
            if not ph then continue end
            if S.AutoHitEggH then
                local holding = false
                if c2 then for _, ch in ipairs(c2:GetChildren()) do
                    if ch:IsA("Tool") and
                    ch:GetAttribute("ItemType")=="AssetEgg" then
                        holding=true; break
                    end
                end end
                if not holding then continue end
            end
            local d = (h.Position-ph.Position).Magnitude
            if d < bd then bd=d; best=pl end
        end
        if best then
            local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- [[ PROGRESS — FUSE ]]
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(2) do
        if not S.AutoFuse then continue end
        pcall(function()
            local rem = getRemotes()
            if not (rem and rem.Fusery
            and rem.Fusery.LoadPet and rem.Fusery.BeginFuse) then
                return
            end
            local save = getSaveData()
            if not save or not save.Inventory then return end
            if save.FusionInfoAcknowledged==false
            and rem.Fusery.ConfirmBriefing then
                pcall(function() rem.Fusery.ConfirmBriefing:InvokeServer() end)
            end
            local eq = {}
            for _, uid in ipairs(save.EquippedAssets or save.EquippedPets or {}) do
                eq[uid]=true
            end
            local groups = {}
            for uid, pet in pairs(save.Inventory) do
                if type(pet)=="table" and pet.Category
                and not pet.IsFavorite and not eq[uid] then
                    if S.FuseSkipMut then
                        if (type(pet.Mutations)=="table" and #pet.Mutations>0)
                        or (pet.BaseMutation and pet.BaseMutation~=""
                            and pet.BaseMutation~="Normal") then
                            continue
                        end
                    end
                    local r = getRarity(pet.Category)
                    if S.FuseMaxRar>0 and r>S.FuseMaxRar then continue end
                    if not groups[pet.Category] then
                        groups[pet.Category]={rarity=r, uids={}}
                    end
                    table.insert(groups[pet.Category].uids, uid)
                end
            end
            local best = nil
            for _, g in pairs(groups) do
                if #g.uids>=3 then
                    if not best or g.rarity < best.rarity then best=g end
                end
            end
            if not best then return end
            for i=1,3 do
                pcall(function()
                    rem.Fusery.LoadPet:InvokeServer(best.uids[i])
                end)
                task.wait(0.15)
            end
            task.wait(0.2)
            local ok,r = pcall(function()
                return rem.Fusery.BeginFuse:InvokeServer()
            end)
            if ok and r then
                task.wait(0.3)
                if rem.Fusery.FinishReveal then
                    pcall(function() rem.Fusery.FinishReveal:InvokeServer() end)
                end
            end
        end)
    end
end)

-- ══════════════════════════════════════════════════════════
-- [[ PROGRESS — FAVORITE ]]
-- ══════════════════════════════════════════════════════════
local function favoriteNow()
    pcall(function()
        local rem  = getRemotes()
        local save = getSaveData()
        if not save or not save.Inventory then return end
        for uid, pet in pairs(save.Inventory) do
            if type(pet)=="table" and not pet.IsFavorite and pet.Category then
                if rem and rem.PetSatchel and rem.PetSatchel.WriteFavourite then
                    rem.PetSatchel.WriteFavourite:FireServer(uid, true)
                    task.wait(0.04)
                end
            end
        end
    end)
end

local function setEquippedFav(state)
    pcall(function()
        local rem  = getRemotes()
        local save = getSaveData()
        if not save then return end
        for _, uid in ipairs(save.EquippedAssets or save.EquippedPets or {}) do
            if rem and rem.PetSatchel and rem.PetSatchel.WriteFavourite then
                rem.PetSatchel.WriteFavourite:FireServer(uid, state)
                task.wait(0.04)
            end
        end
    end)
end

task.spawn(function()
    while task.wait(3) do
        if S.AutoFavPet  then task.spawn(favoriteNow) end
        if S.AutoFavEq   then task.spawn(function() setEquippedFav(true)  end) end
        if S.AutoUnFavEq then task.spawn(function() setEquippedFav(false) end) end
    end
end)

-- ══════════════════════════════════════════════════════════
-- [[ MISC LOOPS ]]
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(55) do
        if not S.AntiAFK then continue end
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true,  Enum.KeyCode.LeftShift, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end)
    end
end)

task.spawn(function()
    while task.wait(2) do
        if not S.FPSOpt then continue end
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd        = 9e9
        end)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name=="PlacedEggRenders" then
                for _, egg in ipairs(child:GetChildren()) do
                    local mine = string.find(
                        egg.Name, tostring(lp.UserId), 1, true)
                    local hide = (not mine and S.HideOtherEggs)
                             or (mine     and S.HideMyEggs)
                    if hide then
                        for _, p in ipairs(egg:GetDescendants()) do
                            pcall(function()
                                if p:IsA("BasePart") then
                                    p.LocalTransparencyModifier=1
                                elseif p:IsA("Decal") or p:IsA("Texture") then
                                    p.Transparency=1
                                elseif p:IsA("BillboardGui")
                                    or p:IsA("ParticleEmitter") then
                                    p.Enabled=false
                                end
                            end)
                        end
                    end
                end
            end
        end
        local cra = workspace:FindFirstChild("ClientRenderedAssets")
        if cra then
            for _, pet in ipairs(cra:GetChildren()) do
                local mine = pet:GetAttribute("OwnerUserId")==lp.UserId
                local hide = (not mine and S.HideOtherPets)
                         or (mine     and S.HideMyPets)
                if hide then
                    for _, p in ipairs(pet:GetDescendants()) do
                        pcall(function()
                            if p:IsA("BasePart") then
                                p.LocalTransparencyModifier=1
                            elseif p:IsA("Decal") then
                                p.Transparency=1
                            elseif p:IsA("BillboardGui")
                                or p:IsA("ParticleEmitter") then
                                p.Enabled=false
                            end
                        end)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    local terrain = workspace:FindFirstChild("Terrain")
    if not terrain then return end
    terrain.ChildAdded:Connect(function(c)
        if S.HideMoneyAnim and
        (c.Name=="SyncedIncomeCashAttachment"
        or c.Name=="SyncedIncomeCash") then
            c:Destroy()
        end
    end)
end)

-- ══════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════
-- [[ UI ]]
-- ══════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════

local SG = Instance.new("ScreenGui")
SG.Name            = "YushHub"
SG.ResetOnSpawn    = false
SG.DisplayOrder    = 9999
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset  = true
SG.Parent          = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

-- Colors
local C = {
    BG     = Color3.fromRGB(9, 11, 21),
    Panel  = Color3.fromRGB(13, 16, 32),
    Alt    = Color3.fromRGB(18, 22, 42),
    Acc    = Color3.fromRGB(0, 190, 255),
    Acc2   = Color3.fromRGB(0, 125, 210),
    TOn    = Color3.fromRGB(0, 180, 100),
    TOff   = Color3.fromRGB(42, 50, 76),
    TabOn  = Color3.fromRGB(0, 145, 228),
    TabOff = Color3.fromRGB(14, 18, 36),
    Text   = Color3.fromRGB(215, 226, 248),
    Sub    = Color3.fromRGB(110, 128, 165),
}

-- Shorthand builders
local function mkCorner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end
local function mkStroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.Acc; s.Thickness = th or 1.2
    return s
end
local function mkPad(p, l, r, t, b)
    local pd = Instance.new("UIPadding", p)
    pd.PaddingLeft   = UDim.new(0, l or 8)
    pd.PaddingRight  = UDim.new(0, r or 8)
    pd.PaddingTop    = UDim.new(0, t or 8)
    pd.PaddingBottom = UDim.new(0, b or 8)
end
local function mkList(p, dir, gap)
    local l = Instance.new("UIListLayout", p)
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, gap or 5)
    return l
end

-- ── MAIN WINDOW ──────────────────────────────────────────
local WIN_W     = 420
local TITLE_H   = 52
local BODY_H    = 400
local TOTAL_H   = TITLE_H + BODY_H
local expanded  = false

local Win = Instance.new("Frame", SG)
Win.Name                  = "Win"
Win.Size                  = UDim2.new(0, WIN_W, 0, TITLE_H)
Win.Position              = UDim2.new(0.5, -WIN_W/2, 0, 6)
Win.BackgroundColor3      = C.BG
Win.BorderSizePixel       = 0
Win.ClipsDescendants      = true
mkCorner(Win, 10)
mkStroke(Win, C.Acc, 1.4)

-- ── TITLE BAR ────────────────────────────────────────────
local TBar = Instance.new("Frame", Win)
TBar.Name             = "TBar"
TBar.Size             = UDim2.new(1, 0, 0, TITLE_H)
TBar.BackgroundColor3 = C.Panel
TBar.BorderSizePixel  = 0
mkCorner(TBar, 10)
-- Cover lower rounded corners
Instance.new("Frame", TBar).Size     = UDim2.new(1,0,0.5,0)
Instance.new("Frame", TBar).Position = UDim2.new(0,0,0.5,0)
do
    local cov = TBar:FindFirstChildOfClass("Frame")
    if cov then
        cov.BackgroundColor3 = C.Panel
        cov.BorderSizePixel  = 0
    end
end

-- Separator under title
local TBarSep = Instance.new("Frame", Win)
TBarSep.Size             = UDim2.new(1,0,0,1)
TBarSep.Position         = UDim2.new(0,0,0,TITLE_H)
TBarSep.BackgroundColor3 = C.Acc
TBarSep.BackgroundTransparency = 0.55
TBarSep.BorderSizePixel  = 0

-- Logo circle
local Logo = Instance.new("Frame", TBar)
Logo.Size             = UDim2.new(0,36,0,36)
Logo.Position         = UDim2.new(0,8,0.5,-18)
Logo.BackgroundColor3 = C.Alt
Logo.BorderSizePixel  = 0
mkCorner(Logo, 18)
mkStroke(Logo, C.Acc, 1)
local LogoImg = Instance.new("ImageLabel", Logo)
LogoImg.Size                  = UDim2.new(1,0,1,0)
LogoImg.BackgroundTransparency= 1
LogoImg.ScaleType             = Enum.ScaleType.Fit
LogoImg.Image                 = ""
pcall(function()
    LogoImg.Image = "https://kommodo.ai/i/GVHleyzQ3zvcly38H8JU"
end)
local LogoFallback = Instance.new("TextLabel", Logo)
LogoFallback.Size                  = UDim2.new(1,0,1,0)
LogoFallback.BackgroundTransparency= 1
LogoFallback.Font                  = Enum.Font.GothamBold
LogoFallback.TextSize              = 16
LogoFallback.TextColor3            = C.Acc
LogoFallback.Text                  = "Y"

-- Title text
local TitleLbl = Instance.new("TextLabel", TBar)
TitleLbl.Size                  = UDim2.new(0, 160, 0, 16)
TitleLbl.Position              = UDim2.new(0, 52, 0, 8)
TitleLbl.BackgroundTransparency= 1
TitleLbl.Font                  = Enum.Font.GothamBold
TitleLbl.TextSize              = 11
TitleLbl.TextColor3            = C.Acc
TitleLbl.TextXAlignment        = Enum.TextXAlignment.Left
TitleLbl.Text                  = "YUSH HUB  |  STEAL AN EGG"

-- FPS/PING label (integrated in title bar)
local FpsLbl = Instance.new("TextLabel", TBar)
FpsLbl.Size                   = UDim2.new(0, 160, 0, 14)
FpsLbl.Position               = UDim2.new(0, 52, 0, 26)
FpsLbl.BackgroundTransparency = 1
FpsLbl.Font                   = Enum.Font.Gotham
FpsLbl.TextSize               = 9
FpsLbl.TextColor3             = C.Sub
FpsLbl.TextXAlignment         = Enum.TextXAlignment.Left
FpsLbl.RichText               = true
FpsLbl.Text                   = "FPS: --  |  PING: --ms"

-- FPS/PING update
local _fF, _fL, _fC = 0, os.clock(), 60
RunService.RenderStepped:Connect(function()
    _fF += 1
    local now = os.clock()
    if now - _fL >= 1 then
        _fC = math.round(_fF/(now-_fL)); _fF=0; _fL=now
        local ping=0
        pcall(function()
            ping = math.round(
                game:GetService("Stats").Network
                    .ServerStatsItem["Data Ping"]:GetValue())
        end)
        local fc = _fC>=55 and "#00FF88"
               or _fC>=30 and "#FFD700" or "#FF5555"
        local pc = ping<=80 and "#00FF88"
               or ping<=150 and "#FFD700" or "#FF5555"
        FpsLbl.Text = string.format(
            '<font color="%s">FPS: %d</font>  |  <font color="%s">PING: %dms</font>',
            fc, _fC, pc, ping)
    end
end)

-- Collapse / Expand button (> or ∨)
local ColBtn = Instance.new("TextButton", TBar)
ColBtn.Size             = UDim2.new(0, 32, 0, 32)
ColBtn.Position         = UDim2.new(1, -38, 0.5, -16)
ColBtn.BackgroundColor3 = C.Alt
ColBtn.BorderSizePixel  = 0
ColBtn.Font             = Enum.Font.GothamBold
ColBtn.TextSize         = 14
ColBtn.TextColor3       = C.Acc
ColBtn.Text             = ">"
mkCorner(ColBtn, 7)
mkStroke(ColBtn, C.Acc, 1)

ColBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    ColBtn.Text = expanded and "∨" or ">"
    TweenSvc:Create(Win, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, WIN_W, 0, expanded and TOTAL_H or TITLE_H)
    }):Play()
end)

-- ── DRAG (title bar) ─────────────────────────────────────
do
    local drag, ds, sp = false, nil, nil
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=Win.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            Win.Position=UDim2.new(
                sp.X.Scale, sp.X.Offset+d.X,
                sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=false
        end
    end)
end

-- ── BODY ─────────────────────────────────────────────────
local Body = Instance.new("Frame", Win)
Body.Name                 = "Body"
Body.Size                 = UDim2.new(1,0,0,BODY_H)
Body.Position             = UDim2.new(0,0,0,TITLE_H+1)
Body.BackgroundTransparency=1
Body.ClipsDescendants     = true

-- Sidebar
local SIDEBAR_W = 88
local Sidebar = Instance.new("Frame", Body)
Sidebar.Name             = "Sidebar"
Sidebar.Size             = UDim2.new(0, SIDEBAR_W, 1, 0)
Sidebar.BackgroundColor3 = C.Panel
Sidebar.BorderSizePixel  = 0

-- Sidebar separator
local SBsep = Instance.new("Frame", Body)
SBsep.Size             = UDim2.new(0,1,1,0)
SBsep.Position         = UDim2.new(0, SIDEBAR_W, 0, 0)
SBsep.BackgroundColor3 = C.Acc
SBsep.BackgroundTransparency = 0.6
SBsep.BorderSizePixel  = 0

-- Content area
local ContentArea = Instance.new("Frame", Body)
ContentArea.Name             = "Content"
ContentArea.Size             = UDim2.new(1, -(SIDEBAR_W+1), 1, 0)
ContentArea.Position         = UDim2.new(0, SIDEBAR_W+1, 0, 0)
ContentArea.BackgroundTransparency=1
ContentArea.ClipsDescendants = true

-- Tab buttons + layout
local TabHolder = Instance.new("Frame", Sidebar)
TabHolder.Size             = UDim2.new(1,0,0,0)
TabHolder.Position         = UDim2.new(0,0,0,6)
TabHolder.BackgroundTransparency=1
TabHolder.AutomaticSize    = Enum.AutomaticSize.Y
mkList(TabHolder, nil, 3)
mkPad(TabHolder, 5,5,0,0)

-- Avatar area at bottom of sidebar
local AvatarFrame = Instance.new("Frame", Sidebar)
AvatarFrame.Size             = UDim2.new(1,0,0,72)
AvatarFrame.Position         = UDim2.new(0,0,1,-76)
AvatarFrame.BackgroundTransparency=1

local AvatarImg = Instance.new("ImageLabel", AvatarFrame)
AvatarImg.Size                 = UDim2.new(0,42,0,42)
AvatarImg.Position             = UDim2.new(0.5,-21,0,4)
AvatarImg.BackgroundColor3     = C.Alt
AvatarImg.BorderSizePixel      = 0
AvatarImg.ScaleType            = Enum.ScaleType.Crop
mkCorner(AvatarImg, 21)
mkStroke(AvatarImg, C.Acc, 1.2)

-- Load avatar async
task.spawn(function()
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(
            lp.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size48x48)
    end)
    if ok and url then AvatarImg.Image = url end
end)

local UsernameLabel = Instance.new("TextLabel", AvatarFrame)
UsernameLabel.Size                 = UDim2.new(1,-4,0,16)
UsernameLabel.Position             = UDim2.new(0,2,0,50)
UsernameLabel.BackgroundTransparency=1
UsernameLabel.Font                 = Enum.Font.GothamBold
UsernameLabel.TextSize             = 8
UsernameLabel.TextColor3           = C.Text
UsernameLabel.Text                 = lp.Name
UsernameLabel.TextTruncate         = Enum.TextTruncate.AtEnd

-- ── PAGES ────────────────────────────────────────────────
local pages  = {}
local tBtns  = {}

local function selectTab(name)
    for n, pg in pairs(pages) do pg.Visible = (n==name) end
    for n, b  in pairs(tBtns) do
        local on = (n==name)
        TweenSvc:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = on and C.TabOn or C.TabOff
        }):Play()
        local ic = b:FindFirstChild("Ic")
        local lb = b:FindFirstChild("Lb")
        if ic then ic.TextColor3 = on and C.Text or C.Sub end
        if lb then lb.TextColor3 = on and C.Text or C.Sub end
    end
end

local TABS = {
    {n="FARM",     ic="🌾"},
    {n="PLAYER",   ic="👤"},
    {n="PROGRESS", ic="📈"},
    {n="MISC",     ic="⚙️"},
}

for i, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton", TabHolder)
    btn.Name             = tab.n
    btn.Size             = UDim2.new(1,0,0,54)
    btn.BackgroundColor3 = C.TabOff
    btn.BorderSizePixel  = 0
    btn.Text             = ""
    btn.LayoutOrder      = i
    mkCorner(btn, 7)

    local ic = Instance.new("TextLabel", btn)
    ic.Name             = "Ic"
    ic.Size             = UDim2.new(1,0,0,24)
    ic.Position         = UDim2.new(0,0,0,6)
    ic.BackgroundTransparency=1
    ic.Font             = Enum.Font.Gotham
    ic.TextSize         = 18
    ic.TextColor3       = C.Sub
    ic.Text             = tab.ic

    local lb = Instance.new("TextLabel", btn)
    lb.Name             = "Lb"
    lb.Size             = UDim2.new(1,0,0,12)
    lb.Position         = UDim2.new(0,0,0,32)
    lb.BackgroundTransparency=1
    lb.Font             = Enum.Font.GothamBold
    lb.TextSize         = 7
    lb.TextColor3       = C.Sub
    lb.Text             = tab.n

    local pg = Instance.new("ScrollingFrame", ContentArea)
    pg.Name                 = tab.n.."_Pg"
    pg.Size                 = UDim2.new(1,0,1,0)
    pg.BackgroundTransparency=1
    pg.BorderSizePixel      = 0
    pg.ScrollBarThickness   = 3
    pg.ScrollBarImageColor3 = C.Acc
    pg.CanvasSize           = UDim2.new(0,0,0,0)
    pg.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    pg.Visible              = false
    mkList(pg, nil, 4)
    mkPad(pg, 8,10,6,8)

    pages[tab.n] = pg
    tBtns[tab.n] = btn
    btn.MouseButton1Click:Connect(function() selectTab(tab.n) end)
end

-- ── COMPONENT BUILDERS ───────────────────────────────────
local function section(parent, text)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(1,0,0,20)
    f.BackgroundTransparency=1
    local lbl = Instance.new("TextLabel", f)
    lbl.Size             = UDim2.new(1,-6,1,0)
    lbl.Position         = UDim2.new(0,4,0,0)
    lbl.BackgroundTransparency=1
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 8
    lbl.TextColor3       = C.Acc
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = "◈  "..text:upper()
    local sep = Instance.new("Frame", f)
    sep.Size             = UDim2.new(1,-4,0,1)
    sep.Position         = UDim2.new(0,2,1,-1)
    sep.BackgroundColor3 = C.Acc
    sep.BackgroundTransparency=0.65
    sep.BorderSizePixel  = 0
    return f
end

-- Toggle: returns (frame, setState function)
local function toggle(parent, label, desc, default, onChange)
    local rowH = (desc and desc~="") and 42 or 34
    local row  = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1,0,0,rowH)
    row.BackgroundColor3 = C.Alt
    row.BorderSizePixel  = 0
    mkCorner(row, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size             = UDim2.new(1,-58,0,16)
    lbl.Position         = UDim2.new(0,10,0,5)
    lbl.BackgroundTransparency=1
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 10
    lbl.TextColor3       = C.Text
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = label

    if desc and desc~="" then
        local sub = Instance.new("TextLabel", row)
        sub.Size             = UDim2.new(1,-58,0,12)
        sub.Position         = UDim2.new(0,10,0,21)
        sub.BackgroundTransparency=1
        sub.Font             = Enum.Font.Gotham
        sub.TextSize         = 8
        sub.TextColor3       = C.Sub
        sub.TextXAlignment   = Enum.TextXAlignment.Left
        sub.Text             = desc
    end

    local track = Instance.new("Frame", row)
    track.Size             = UDim2.new(0,38,0,19)
    track.Position         = UDim2.new(1,-46,0.5,-9)
    track.BackgroundColor3 = default and C.TOn or C.TOff
    track.BorderSizePixel  = 0
    mkCorner(track, 10)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0,15,0,15)
    knob.Position         = default
        and UDim2.new(1,-17,0.5,-7)
        or  UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel  = 0
    mkCorner(knob, 8)

    local state = default or false
    local function setState(v, noSave)
        state = v
        TweenSvc:Create(track, TweenInfo.new(0.14), {
            BackgroundColor3 = v and C.TOn or C.TOff
        }):Play()
        TweenSvc:Create(knob, TweenInfo.new(0.14), {
            Position = v
                and UDim2.new(1,-17,0.5,-7)
                or  UDim2.new(0,2,0.5,-7)
        }):Play()
        if onChange then onChange(v) end
        if not noSave then saveSettings() end
    end

    local btn = Instance.new("TextButton", row)
    btn.Size             = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency=1
    btn.Text             = ""
    btn.MouseButton1Click:Connect(function() setState(not state) end)

    if default and onChange then onChange(true) end
    return row, setState
end

-- Slider with reliable drag
local sliderDrags = {}
local activeDrag  = nil

RunService.RenderStepped:Connect(function()
    if not activeDrag then return end
    local info   = sliderDrags[activeDrag]
    if not info then activeDrag=nil; return end
    local mouse  = UIS:GetMouseLocation()
    local abs    = info.track.AbsolutePosition
    local sz     = info.track.AbsoluteSize
    if sz.X == 0 then return end
    local pct    = math.clamp((mouse.X - abs.X) / sz.X, 0, 1)
    local raw    = info.min + (info.max - info.min) * pct
    local v      = math.clamp(
        math.round(raw / info.step) * info.step,
        info.min, info.max)
    if v ~= info.value then
        info.value = v
        info.fill.Size     = UDim2.new(pct, 0, 1, 0)
        info.knob.Position = UDim2.new(pct, -7, 0.5, -7)
        info.valLbl.Text   = info.step < 1
            and string.format("%.1f", v) or tostring(v)
        if info.onChange then info.onChange(v) end
        saveSettings()
    end
end)

UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then
        activeDrag = nil
    end
end)

local sliderCount = 0
local function slider(parent, label, min, max, default, step, onChange)
    step = step or 1
    sliderCount += 1
    local id = "slider_"..sliderCount

    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1,0,0,46)
    row.BackgroundColor3 = C.Alt
    row.BorderSizePixel  = 0
    mkCorner(row, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size             = UDim2.new(0.65,0,0,16)
    lbl.Position         = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency=1
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 10
    lbl.TextColor3       = C.Text
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = label

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size             = UDim2.new(0.3,0,0,16)
    valLbl.Position         = UDim2.new(0.7,0,0,4)
    valLbl.BackgroundTransparency=1
    valLbl.Font             = Enum.Font.GothamBold
    valLbl.TextSize         = 10
    valLbl.TextColor3       = C.Acc
    valLbl.TextXAlignment   = Enum.TextXAlignment.Right
    valLbl.Text             = step<1
        and string.format("%.1f",default) or tostring(default)

    local track = Instance.new("Frame", row)
    track.Size             = UDim2.new(1,-20,0,5)
    track.Position         = UDim2.new(0,10,0,30)
    track.BackgroundColor3 = C.TOff
    track.BorderSizePixel  = 0
    mkCorner(track, 3)

    local pctDefault = (default-min)/math.max(max-min,1)

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new(pctDefault,0,1,0)
    fill.BackgroundColor3 = C.Acc
    fill.BorderSizePixel  = 0
    mkCorner(fill, 3)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.new(0,14,0,14)
    knob.Position         = UDim2.new(pctDefault,-7,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel  = 0
    mkCorner(knob, 7)
    mkStroke(knob, C.Acc, 1.2)

    -- Store drag info
    sliderDrags[id] = {
        track   = track,
        fill    = fill,
        knob    = knob,
        valLbl  = valLbl,
        min     = min,
        max     = max,
        step    = step,
        value   = default,
        onChange= onChange,
    }

    -- Invisible button over track to catch all input
    local hitBtn = Instance.new("TextButton", track)
    hitBtn.Size             = UDim2.new(1,14,0,20)
    hitBtn.Position         = UDim2.new(0,-7,0.5,-10)
    hitBtn.BackgroundTransparency=1
    hitBtn.Text             = ""
    hitBtn.ZIndex           = 5

    hitBtn.MouseButton1Down:Connect(function()
        activeDrag = id
        -- Immediate snap to click position
        local mouse = UIS:GetMouseLocation()
        local abs   = track.AbsolutePosition
        local sz    = track.AbsoluteSize
        if sz.X == 0 then return end
        local pct   = math.clamp((mouse.X - abs.X) / sz.X, 0, 1)
        local raw   = min + (max-min)*pct
        local v     = math.clamp(math.round(raw/step)*step, min, max)
        sliderDrags[id].value = v
        fill.Size     = UDim2.new(pct,0,1,0)
        knob.Position = UDim2.new(pct,-7,0.5,-7)
        valLbl.Text   = step<1 and string.format("%.1f",v) or tostring(v)
        if onChange then onChange(v) end
        saveSettings()
    end)

    return row
end

-- Button
local function button(parent, text, onClick)
    local b = Instance.new("TextButton", parent)
    b.Size             = UDim2.new(1,0,0,30)
    b.BackgroundColor3 = C.Acc2
    b.BorderSizePixel  = 0
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 10
    b.TextColor3       = Color3.fromRGB(255,255,255)
    b.Text             = text
    mkCorner(b, 7)
    b.MouseEnter:Connect(function()
        TweenSvc:Create(b,TweenInfo.new(0.1),{BackgroundColor3=C.Acc}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenSvc:Create(b,TweenInfo.new(0.1),{BackgroundColor3=C.Acc2}):Play()
    end)
    b.MouseButton1Click:Connect(onClick or function() end)
    return b
end

-- Priority picker (< label >)
local function picker(parent, label, options, defaultIdx, onChange)
    local idx = defaultIdx or 1
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1,0,0,38)
    row.BackgroundColor3 = C.Alt
    row.BorderSizePixel  = 0
    mkCorner(row, 7)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size             = UDim2.new(0.45,0,0,16)
    lbl.Position         = UDim2.new(0,10,0,5)
    lbl.BackgroundTransparency=1
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 10
    lbl.TextColor3       = C.Text
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = label

    local leftBtn = Instance.new("TextButton", row)
    leftBtn.Size             = UDim2.new(0,22,0,22)
    leftBtn.Position         = UDim2.new(1,-106,0.5,-11)
    leftBtn.BackgroundColor3 = C.Panel
    leftBtn.BorderSizePixel  = 0
    leftBtn.Font             = Enum.Font.GothamBold
    leftBtn.TextSize         = 12
    leftBtn.TextColor3       = C.Acc
    leftBtn.Text             = "<"
    mkCorner(leftBtn, 5)

    local valLbl2 = Instance.new("TextLabel", row)
    valLbl2.Size             = UDim2.new(0,60,0,22)
    valLbl2.Position         = UDim2.new(1,-82,0.5,-11)
    valLbl2.BackgroundColor3 = C.Panel
    valLbl2.BorderSizePixel  = 0
    valLbl2.Font             = Enum.Font.GothamBold
    valLbl2.TextSize         = 9
    valLbl2.TextColor3       = C.Text
    valLbl2.Text             = options[idx] or ""
    mkCorner(valLbl2, 5)

    local rightBtn = Instance.new("TextButton", row)
    rightBtn.Size             = UDim2.new(0,22,0,22)
    rightBtn.Position         = UDim2.new(1,-20,0.5,-11)
    rightBtn.BackgroundColor3 = C.Panel
    rightBtn.BorderSizePixel  = 0
    rightBtn.Font             = Enum.Font.GothamBold
    rightBtn.TextSize         = 12
    rightBtn.TextColor3       = C.Acc
    rightBtn.Text             = ">"
    mkCorner(rightBtn, 5)

    local function update(newIdx)
        idx = math.clamp(newIdx, 1, #options)
        valLbl2.Text = options[idx]
        if onChange then onChange(options[idx], idx) end
        saveSettings()
    end

    leftBtn.MouseButton1Click:Connect(function()  update(idx-1) end)
    rightBtn.MouseButton1Click:Connect(function() update(idx+1) end)
    update(idx)
    return row
end

local function hint(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size                 = UDim2.new(1,0,0,18)
    l.BackgroundTransparency=1
    l.Font                 = Enum.Font.Gotham
    l.TextSize             = 8
    l.TextColor3           = C.Sub
    l.TextXAlignment       = Enum.TextXAlignment.Left
    l.TextWrapped          = true
    l.Text                 = "  ℹ  "..text
    return l
end

-- ══════════════════════════════════════════════════════════
-- [[ BUILD TAB PAGES ]]
-- ══════════════════════════════════════════════════════════

-- ── FARM ─────────────────────────────────────────────────
local fp = pages["FARM"]

section(fp, "Steal Settings")

-- Steal Priority picker
local priOptions = {
    "Common","Uncommon","Rare","Epic",
    "Legendary","Mythic","Cosmic","Secret","Eternal","Divine"
}
local priRarityMap = {1,2,3,4,5,6,7,8,9,10}
local defaultPriIdx = 5  -- Legendary

-- Find saved priority index
for i, v in ipairs(priRarityMap) do
    if v == S.StealMinRarity then defaultPriIdx=i; break end
end

picker(fp, "Steal Priority", priOptions, defaultPriIdx, function(val, idx)
    S.StealMinRarity = priRarityMap[idx]
end)

toggle(fp, "Auto Steal Egg", "Steals the rarest matching egg continuously",
    S.AutoSteal, function(v)
        S.AutoSteal = v
    end)
toggle(fp, "Instant Steal", "Teleport to egg instead of tweening",
    S.InstantSteal, function(v) S.InstantSteal = v end)
toggle(fp, "Anti Guard", "Prevents guards from registering hits",
    S.AntiGuard, function(v) S.AntiGuard = v end)

section(fp, "Speed Config")
slider(fp, "Tween Speed (studs/s)", 20, 300, S.TweenSpd, 5, function(v)
    S.TweenSpd = v
end)
slider(fp, "Carry Speed (studs/s)", 20, 300, S.CarrySpd, 5, function(v)
    S.CarrySpd = v
end)
slider(fp, "Flight Height", 78, 130, S.FlightH, 1, function(v)
    S.FlightH = v
end)

section(fp, "Automation")
toggle(fp, "Auto Equip Best", "Auto-equips strongest pets every 5s",
    S.AutoEquipBest, function(v) S.AutoEquipBest = v end)
toggle(fp, "Auto Hatch", "Hatches eggs that are ready in your pen",
    S.AutoHatch, function(v) S.AutoHatch = v end)
toggle(fp, "Auto Treadmill", "Walks on treadmill (jump to exit)",
    S.AutoTreadmill, function(v)
        S.AutoTreadmill = v
        if not v then exitTreadmill() end
    end)
button(fp, "⏏  Exit Treadmill Now", function() exitTreadmill() end)
hint(fp, "Anti Knockback & Auto Place Egg are always active.")
hint(fp, "All settings auto-save and restore on next execution.")

-- ── PLAYER ───────────────────────────────────────────────
local pp = pages["PLAYER"]

section(pp, "Movement")
slider(pp, "Walk Speed", 16, 500, S.WalkSpeed, 1, function(v)
    S.WalkSpeed = v
    local h2 = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if h2 then h2.WalkSpeed = v end
end)
toggle(pp, "No Clip", "Walk through walls and objects",
    S.NoClip, function(v) S.NoClip = v end)
toggle(pp, "Infinite Jump", "Jump from anywhere repeatedly",
    S.InfJump, function(v) S.InfJump = v end)

section(pp, "Stealth")
toggle(pp, "Invisibility", "Hides you & held egg from other players",
    S.Invisibility, function(v)
        S.Invisibility = v
        if not v then
            local c = lp.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    pcall(function()
                        if p:IsA("BasePart") or p:IsA("MeshPart") then
                            p.LocalTransparencyModifier = 0
                        end
                    end)
                end
            end
        end
    end)
toggle(pp, "Anti Ragdoll", "Blocks all ragdoll & knockback effects",
    S.AntiRagdoll, function(v) S.AntiRagdoll = v end)
toggle(pp, "Anti Trap", "Prevents getting stuck in traps/objects",
    S.AntiTrap, function(v) S.AntiTrap = v end)

section(pp, "ESP — Eggs")
toggle(pp, "ESP Eggs", "Shows egg markers in the world",
    S.ESPEggs, function(v)
        S.ESPEggs = v
        if not v then
            for k, o in pairs(espObj) do
                if k:sub(1,4)=="EGG_" and o and o.Parent then
                    o:Destroy(); espObj[k]=nil
                end
            end
        end
    end)
toggle(pp, "ESP Show Info", "Display name + rarity on markers",
    S.ESPShowInfo, function(v) S.ESPShowInfo = v end)
slider(pp, "ESP Min Rarity (1-12)", 1, 12, S.ESPMinRar, 1,
    function(v) S.ESPMinRar = v end)
slider(pp, "ESP Egg Size", 0.2, 4, S.ESPEggSz, 0.1,
    function(v) S.ESPEggSz = v end)

section(pp, "ESP — Guards & Players")
toggle(pp, "ESP Guards", "Highlights guards by alert state",
    S.ESPGuards, function(v)
        S.ESPGuards = v
        if not v then
            for k, o in pairs(espObj) do
                if k:sub(1,6)=="GUARD_" and o and o.Parent then
                    o:Destroy(); espObj[k]=nil
                end
            end
        end
    end)
toggle(pp, "ESP Players", "Highlights other players through walls",
    S.ESPPlayers, function(v)
        S.ESPPlayers = v
        if not v then
            for k, o in pairs(espObj) do
                if k:sub(1,7)=="PLAYER_" and o and o.Parent then
                    o:Destroy(); espObj[k]=nil
                end
            end
        end
    end)
toggle(pp, "ESP Player Info", "Show player names above heads",
    S.ESPPlayerInfo, function(v) S.ESPPlayerInfo = v end)

section(pp, "Combat")
toggle(pp, "Auto Hit Nearest Player", "Auto-swings tool at closest player",
    S.AutoHitPlayer, function(v) S.AutoHitPlayer = v end)
toggle(pp, "Auto Hit Egg Holders", "Only targets players holding eggs",
    S.AutoHitEggH, function(v) S.AutoHitEggH = v end)

-- ── PROGRESS ─────────────────────────────────────────────
local prg = pages["PROGRESS"]

section(prg, "Fuse Machine")
toggle(prg, "Auto Fuse Machine", "Fuses 3 matching pets automatically",
    S.AutoFuse, function(v) S.AutoFuse = v end)
toggle(prg, "Skip Mutated Pets", "Never fuse Rainbow/Golden/Silver pets",
    S.FuseSkipMut, function(v) S.FuseSkipMut = v end)
toggle(prg, "Eject Incomplete Slots", "Eject if < 3 matching pets in machine",
    S.FuseEject, function(v) S.FuseEject = v end)
slider(prg, "Max Rarity to Fuse (0=All)", 0, 12, S.FuseMaxRar, 1,
    function(v) S.FuseMaxRar = v end)

section(prg, "Pet Favorite")
toggle(prg, "Auto Favorite Pet", "Favorites unfavorited pets every 3s",
    S.AutoFavPet, function(v) S.AutoFavPet = v end)
button(prg, "★  Favorite All Pets Now", function()
    task.spawn(favoriteNow)
    notify("Yush Hub", "Favoriting all pets…")
end)

section(prg, "Equipped Pets")
toggle(prg, "Auto Favorite Equipped", "Keeps equipped pets favorited",
    S.AutoFavEq, function(v) S.AutoFavEq = v end)
toggle(prg, "Auto UnFavorite Equipped", "Keeps equipped pets unfavorited",
    S.AutoUnFavEq, function(v) S.AutoUnFavEq = v end)
button(prg, "✓  Favorite Equipped Now", function()
    task.spawn(function() setEquippedFav(true) end)
    notify("Yush Hub", "Favoriting equipped pets…")
end)
button(prg, "✗  UnFavorite Equipped Now", function()
    task.spawn(function() setEquippedFav(false) end)
    notify("Yush Hub", "UnFavoriting equipped pets…")
end)

-- ── MISC ─────────────────────────────────────────────────
local mc = pages["MISC"]

section(mc, "Performance")
toggle(mc, "FPS Optimizer", "Removes shadows & particles globally",
    S.FPSOpt, function(v) S.FPSOpt = v end)
toggle(mc, "Hide Others' Pets", "Hides other players' pets locally",
    S.HideOtherPets, function(v) S.HideOtherPets = v end)
toggle(mc, "Hide Others' Eggs", "Hides other players' placed eggs",
    S.HideOtherEggs, function(v) S.HideOtherEggs = v end)
toggle(mc, "Hide Your Pets", "Hides your own pets from view",
    S.HideMyPets, function(v) S.HideMyPets = v end)
toggle(mc, "Hide Your Eggs", "Hides your own placed eggs locally",
    S.HideMyEggs, function(v) S.HideMyEggs = v end)
toggle(mc, "Hide Money Animations", "Removes floating money popups",
    S.HideMoneyAnim, function(v) S.HideMoneyAnim = v end)

section(mc, "Utilities")
toggle(mc, "Anti AFK", "Prevents auto-kick every 55 seconds",
    S.AntiAFK, function(v) S.AntiAFK = v end)
button(mc, "🔄  Rejoin This Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
end)
button(mc, "💀  Reset Character", function() lp:LoadCharacter() end)
button(mc, "📋  Copy Job ID", function()
    if setclipboard then
        setclipboard(game.JobId)
        notify("Yush Hub", "Job ID copied!")
    end
end)

section(mc, "Info")
hint(mc, "Yush Hub v3.0 — Steal An Egg Script")
hint(mc, "Made by @YushPogi  •  All settings auto-save.")

-- ══════════════════════════════════════════════════════════
-- [[ INIT ]]
-- ══════════════════════════════════════════════════════════
selectTab("FARM")

-- Money animation hook
task.spawn(function()
    local terrain = workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.ChildAdded:Connect(function(c)
            if S.HideMoneyAnim and
            (c.Name=="SyncedIncomeCashAttachment"
            or c.Name=="SyncedIncomeCash") then
                c:Destroy()
            end
        end)
    end
end)

-- Open animation
Win.Size = UDim2.new(0, WIN_W, 0, 0)
TweenSvc:Create(Win, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
    Size = UDim2.new(0, WIN_W, 0, TITLE_H)
}):Play()

notify("Yush Hub", "v3.0 Loaded ✅  Press > to open menu")
