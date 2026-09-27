-- ============================================================
-- YUSH HUB | STEAL AN EGG SCRIPT
-- Version 2.0 — Professional Edition
-- ============================================================

-- ============================================================
-- [[ IMPROVED ANTI CHEAT BYPASS ]]
-- ============================================================
local _G_anticheat = {}

do
    -- Environment integrity checks
    local RunService = game:GetService("RunService")
    
    -- Server/Studio guard
    if RunService:IsServer() then return end
    
    -- Studio bypass (allow dev testing)
    local inStudio = RunService:IsStudio()
    
    -- Debug.info stack integrity
    local function checkStack()
        local fn = function() return true end
        local ok1, r1 = pcall(debug.info, fn, "f")
        if not ok1 or r1 ~= fn then return false end
        local ok2, r2 = pcall(debug.info, 2, "f")
        if not ok2 then return false end
        return true
    end
    
    if not inStudio and not checkStack() then return end
    
    -- Anti-detection: Disable common telemetry
    pcall(function()
        local AnalyticsService = game:GetService("AnalyticsService")
        -- suppress
    end)
    
    -- Hook RigSync to block ragdoll/impulse signals
    pcall(function()
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        local RS = game:GetService("ReplicatedStorage")
        
        -- Try to hook the rig sync remote
        local function hookRigSync()
            local shared = RS:FindFirstChild("Shared")
            local remotes = shared and shared:FindFirstChild("Remotes")
            if remotes then
                local ok, R = pcall(require, remotes)
                if ok and R and R.RigSync and R.RigSync.Refresh then
                    if not _G_anticheat.rigHooked then
                        _G_anticheat.rigHooked = true
                        R.RigSync.Refresh.OnClientEvent:Connect(function(data)
                            if type(data) == "string" then
                                if data:find("BeginImpulse") or data:find("BeginRagdoll") then
                                    return -- block
                                end
                            end
                        end)
                    end
                end
            end
        end
        
        if RS:FindFirstChild("Shared") then
            hookRigSync()
        else
            RS.ChildAdded:Connect(function(c)
                if c.Name == "Shared" then hookRigSync() end
            end)
        end
    end)
    
    -- Anti-teleport bypass
    pcall(function()
        workspace:SetAttribute("ClientObbyAntiTp", false)
    end)
    
    -- Disable anti-tp scripts
    pcall(function()
        local ps = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
        if ps then
            for _, script in ipairs(ps:GetDescendants()) do
                if script:IsA("LocalScript") and 
                   (script.Name:lower():find("antiteleport") or 
                    script.Name:lower():find("antitp") or
                    script.Name:lower():find("obbyanti")) then
                    script.Disabled = true
                end
            end
        end
    end)
end

-- ============================================================
-- [[ SERVICES ]]
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider   = game:GetService("ContentProvider")
local Lighting          = game:GetService("Lighting")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
local hum  = char:WaitForChild("Humanoid")

lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end)

-- ============================================================
-- [[ SETTINGS / ENABLED FLAGS ]]
-- ============================================================
local Settings = {
    -- FARM
    AutoSteal       = false,
    AntiGuard       = false,
    AutoEquipBest   = false,
    AutoHatch       = false,
    AutoTreadmill   = false,
    FlightHeight    = 88,
    StealSpeed      = 400,
    ReturnSpeed     = 450,
    
    -- PLAYER
    WalkSpeed       = 16,
    NoClip          = false,
    InfiniteJump    = false,
    Invisibility    = false,
    AntiRagdoll     = true,  -- auto on
    AntiTrap        = false,
    
    -- ESP
    ESPEggs         = false,
    ESPEggSize      = 0.5,
    ESPMinRarity    = 7,
    ESPShowInfo     = true,
    ESPOwnBase      = false,
    ESPGuards       = false,
    ESPGuardSize    = 1,
    ESPLostParts    = false,
    ESPPlayers      = false,
    ESPPlayerInfo   = true,
    ESPPlayerSize   = 1,
    AutoHitPlayer   = false,
    AutoHitEggHolder = false,
    
    -- PROGRESS
    AutoFuse        = false,
    FusePriority    = "Lowest Rarity First",
    FuseMaxRarity   = 0,
    FuseSkipMutated = true,
    FuseEjectIncomplete = false,
    AutoFavPet      = false,
    AutoFavEquipped = false,
    AutoUnFavEquipped = false,
    
    -- MISC
    AntiAFK         = false,
    FPSOptimizer    = false,
    HideOtherPets   = false,
    HideOtherEggs   = false,
    HideYourPets    = false,
    HideYourEggs    = false,
    HideMoneyAnim   = false,
    ReduceLag       = false,
}

-- ============================================================
-- [[ HELPERS ]]
-- ============================================================
local function getRemotes()
    local ok, r = pcall(require, ReplicatedStorage.Shared.Remotes)
    if ok then return r end
    local ok2, r2 = pcall(require, ReplicatedStorage.Library.Client.Network)
    if ok2 then return r2 end
    return nil
end

local function getEggState()
    local ok, r = pcall(require, ReplicatedStorage.Client.EggState)
    if ok then return r end
    return nil
end

local function getPlotState()
    local ok, r = pcall(require, ReplicatedStorage.Client.PlotState)
    if ok then return r end
    return nil
end

local function getSave()
    local ok, r = pcall(require, ReplicatedStorage.Shared.Save)
    if ok then
        return r.Get and r.Get() or r.Peek and r.Peek()
    end
    return nil
end

local rarityNum = {
    common=1, uncommon=2, rare=3, epic=4, legendary=5,
    mythic=6, cosmic=7, secret=8, eternal=9, divine=10,
    titan=11, ["light & dark"]=12,
}

local rarityNames = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine","Titan","Light & Dark"}

local function getRarity(cat)
    if not cat then return 1 end
    local ok, assets = pcall(require, ReplicatedStorage.Data.Assets)
    if not ok then
        ok, assets = pcall(require, ReplicatedStorage.Directory.Assets)
    end
    if ok and assets then
        local d = (assets.Directory or assets)[cat]
        if d and d.Rarity then
            local rv = d.Rarity
            if type(rv) == "table" then return rv.Rank or rv.RarityNumber or 1 end
            if type(rv) == "string" then return rarityNum[rv:lower()] or 1 end
        end
    end
    return 1
end

local function getSafeZone()
    local world = workspace:FindFirstChild("World")
    local areas = world and world:FindFirstChild("Areas")
    local s = areas and areas:FindFirstChild("StartArea")
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
                Slot        = d.Slot,
            }
        end
    end
    return nil
end

local function tweenTo(target, speed)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end
    speed = speed or 350
    local dist = (target - h.Position).Magnitude
    if dist < 0.3 then return end
    local t = TweenService:Create(h,
        TweenInfo.new(dist/speed, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(target)}
    )
    t:Play(); t.Completed:Wait()
end

local function liftTo(y)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end
    h.CFrame = CFrame.new(h.Position.X, y, h.Position.Z)
    h.AssemblyLinearVelocity  = Vector3.zero
    h.AssemblyAngularVelocity = Vector3.zero
end

local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = title or "Yush Hub",
            Text     = text  or "",
            Duration = duration or 3,
        })
    end)
end

-- ============================================================
-- [[ ANTI KNOCKBACK / RAGDOLL — ALWAYS ON ]]
-- ============================================================
local _rigHookDone = false

local function applyAntiKnockback(c)
    c = c or lp.Character
    if not c then return end
    local h2 = c:FindFirstChildOfClass("Humanoid")
    if h2 then
        pcall(function()
            h2:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            h2:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
            h2:SetStateEnabled(Enum.HumanoidStateType.Physics,     false)
        end)
    end
    c.DescendantAdded:Connect(function(d)
        if not Settings.AntiRagdoll then return end
        if (d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint"))
            and d.Name:find("Ragdoll") then
            task.defer(function() if d and d.Parent then pcall(d.Destroy,d) end end)
        elseif d:IsA("Motor6D") and not d.Enabled then
            task.defer(function() if d and d.Parent then d.Enabled = true end end)
        end
    end)
    if not _rigHookDone then
        _rigHookDone = true
        pcall(function()
            local rem = getRemotes()
            if rem and rem.RigSync and rem.RigSync.Refresh then
                rem.RigSync.Refresh.OnClientEvent:Connect(function(data)
                    if not Settings.AntiRagdoll then return end
                    if type(data) == "string" and
                       (data:find("BeginImpulse") or data:find("BeginRagdoll")) then
                        return
                    end
                end)
            end
        end)
    end
end

lp.CharacterAdded:Connect(function(c) task.wait(0.3); applyAntiKnockback(c) end)
task.spawn(applyAntiKnockback)

-- ============================================================
-- [[ ANTI TRAP ]]
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if not Settings.AntiTrap then continue end
        local c = lp.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then continue end
        -- Prevent being stuck: if velocity is nearly zero for too long, teleport slightly
        local vel = h.AssemblyLinearVelocity
        if vel.Magnitude < 0.1 and hum and hum.WalkSpeed > 0 and hum.MoveDirection.Magnitude > 0 then
            h.CFrame = h.CFrame + Vector3.new(0, 0.5, 0)
        end
        -- Disable collision traps
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                pcall(function() p.CanCollide = false end)
            end
        end
    end
end)

-- ============================================================
-- [[ STEAL EGG ]]
-- ============================================================
local function isHoldingEgg()
    local c = lp.Character
    if not c then return false end
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch:GetAttribute("ItemType") == "AssetEgg" then return true end
    end
    local pg = lp:FindFirstChild("PlayerGui")
    local dg = pg and pg:FindFirstChild("DropHeldEgg")
    return dg and dg.Enabled or false
end

local function getBestEgg()
    local eggs = {}
    local eggState = getEggState()
    
    if eggState and eggState.ReadFieldEggs then
        local ok, rec = pcall(eggState.ReadFieldEggs)
        if ok and rec then
            local list = rec.Records or rec
            for _, e in pairs(type(list)=="table" and list or {}) do
                if e and e.Uid and (e.State=="Slot" or e.State=="Dropped") and not e.CarrierUserId then
                    table.insert(eggs, e)
                end
            end
        end
    end
    
    -- Fallback: workspace AreaEggSlotsClient
    local sf = workspace:FindFirstChild("AreaEggSlotsClient")
    if sf and #eggs == 0 then
        for _, slot in ipairs(sf:GetChildren()) do
            local hb = slot:FindFirstChild("Hitbox")
            if hb then
                table.insert(eggs, {
                    Uid          = slot.Name,
                    AssetCategory = slot:GetAttribute("AssetCategory") or slot.Name,
                    State        = "Slot",
                    BottomCFrame = hb.CFrame,
                    BoundsCFrame = hb.CFrame,
                })
            end
        end
    end
    
    if #eggs == 0 then return nil end
    
    -- Sort: dropped first (bonus score), then by rarity
    table.sort(eggs, function(a, b)
        local sa = getRarity(a.AssetCategory) * 1000 + (a.State=="Dropped" and 500 or 0)
        local sb = getRarity(b.AssetCategory) * 1000 + (b.State=="Dropped" and 500 or 0)
        -- subtract distance penalty
        local ha = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if ha then
            local pa = (a.BottomCFrame or a.BoundsCFrame) and (a.BottomCFrame or a.BoundsCFrame).Position
            local pb = (b.BottomCFrame or b.BoundsCFrame) and (b.BottomCFrame or b.BoundsCFrame).Position
            if pa then sa = sa - (ha.Position - pa).Magnitude * 0.01 end
            if pb then sb = sb - (ha.Position - pb).Magnitude * 0.01 end
        end
        return sa > sb
    end)
    return eggs[1]
end

local blockedEggs = {}

local function grabEgg(uid, slotKey)
    local rem      = getRemotes()
    local eggState = getEggState()
    local deadline = os.clock() + 3.5
    
    while os.clock() < deadline do
        if not Settings.AutoSteal then return false end
        if isHoldingEgg() then return true end
        
        pcall(function()
            if eggState and eggState.CarryFieldEgg then
                eggState.CarryFieldEgg(uid, slotKey)
            end
        end)
        pcall(function()
            if rem and rem.EggWorld and rem.EggWorld.AskFieldEggCarry then
                rem.EggWorld.AskFieldEggCarry:InvokeServer({Uid=uid,FirstAreaSlotKey=slotKey})
            end
        end)
        pcall(function()
            local networking = ReplicatedStorage:FindFirstChild("Packages")
                and ReplicatedStorage.Packages:FindFirstChild("Networking")
            local rf = networking and networking:FindFirstChild("RF/EggWorld/AskFieldEggCarry")
            if rf then rf:InvokeServer({Uid=uid, FirstAreaSlotKey=slotKey}) end
        end)
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
        task.wait(0.05)
    end
    return isHoldingEgg()
end

local function placeEggInField()
    task.wait(0.5)
    local plot = getPlot()
    if not plot then return end
    
    local rem      = getRemotes()
    local eggState = getEggState()
    local petArea  = plot.PetArea
    local center   = plot.CenterPoint
    
    local unplaced, placed = {}, {}
    
    pcall(function()
        local snap
        if rem and rem.EggWorld and rem.EggWorld.AskLiveSnapshot then
            snap = rem.EggWorld.AskLiveSnapshot:InvokeServer()
        elseif eggState and eggState.ReadOwnedEggs then
            snap = eggState.ReadOwnedEggs()
        end
        if not snap then return end
        local recs = {}
        for _, v in ipairs(type(snap)=="table" and snap or {}) do
            if type(v)=="table" and v.OwnerUserId == lp.UserId then
                recs = v.Records or {}; break
            end
        end
        for k, v in pairs(recs) do
            if type(v)=="table" then
                if v.Placement then table.insert(placed, {uid=k, lc=v.Placement.LocalCFrame})
                else table.insert(unplaced, k) end
            end
        end
    end)
    
    if #unplaced == 0 then return end
    
    -- Navigate to pen
    local penPos = petArea.Position + Vector3.new(0,3,0)
    local cPos   = center.Position  + Vector3.new(0,3,0)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if h and (h.Position - cPos).Magnitude > 10 then tweenTo(cPos, 200) end
    tweenTo(penPos, 150)
    
    local function freeSlot()
        local sx = petArea.Size.X/2 - 3
        local sz = petArea.Size.Z/2 - 3
        for z = -sz, sz, 5 do
            for x = -sx, sx, 5 do
                local wp = petArea.CFrame:PointToWorldSpace(Vector3.new(x,0,z))
                local free = true
                for _, pl in ipairs(placed) do
                    if pl.lc and type(pl.lc)=="string" then
                        local nums={}
                        for n in pl.lc:gmatch("[-0-9%.e]+") do table.insert(nums,tonumber(n)) end
                        if #nums>=3 then
                            local pws = center.CFrame:ToWorldSpace(CFrame.new(unpack(nums))).Position
                            if (pws-wp).Magnitude < 5 then free=false; break end
                        end
                    end
                end
                if free then return wp, center.CFrame:ToObjectSpace(CFrame.new(wp)) end
            end
        end
        return nil, nil
    end
    
    for _, uid in ipairs(unplaced) do
        if not Settings.AutoSteal then break end
        
        -- Equip
        pcall(function()
            if eggState and eggState.WearEggTool then eggState.WearEggTool(uid)
            elseif rem and rem.EggWorld and rem.EggWorld.AskWearTool then
                rem.EggWorld.AskWearTool:InvokeServer(uid)
            end
        end)
        task.wait(0.2)
        
        local wp, lc = freeSlot()
        if not wp then break end
        
        pcall(function()
            if eggState and eggState.PlantEgg then eggState.PlantEgg(uid, lc)
            else
                local net = ReplicatedStorage:FindFirstChild("Packages")
                    and ReplicatedStorage.Packages:FindFirstChild("Networking")
                local rf = net and net:FindFirstChild("RF/EggWorld/AskPlaceEgg")
                if rf then rf:InvokeServer({Uid=uid, LocalCFrame=lc}) end
            end
        end)
        table.insert(placed, {uid=uid, lc=tostring(lc)})
        
        -- Unequip
        pcall(function()
            if eggState and eggState.DoffEggTool then eggState.DoffEggTool(uid)
            elseif rem and rem.EggWorld and rem.EggWorld.AskDoffTool then
                rem.EggWorld.AskDoffTool:InvokeServer(uid)
            end
        end)
        task.wait(0.15)
    end
end

-- Main steal loop
local stealRunning = false
task.spawn(function()
    while task.wait(0.05) do
        if not Settings.AutoSteal then continue end
        if stealRunning then continue end
        stealRunning = true
        
        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not h then stealRunning = false; continue end
        
        -- 1. Lift
        liftTo(Settings.FlightHeight)
        task.wait(0.12)
        
        -- 2. Find egg
        local egg = getBestEgg()
        if not egg then stealRunning = false; task.wait(1); continue end
        
        local pos = (egg.BottomCFrame or egg.BoundsCFrame) and
                    (egg.BottomCFrame or egg.BoundsCFrame).Position
        if not pos then stealRunning = false; task.wait(0.5); continue end
        
        -- 3. Fly above egg
        tweenTo(Vector3.new(pos.X, Settings.FlightHeight, pos.Z), Settings.StealSpeed)
        if not Settings.AutoSteal then stealRunning = false; continue end
        
        -- 4. Descend
        tweenTo(Vector3.new(pos.X, pos.Y+2.5, pos.Z), 280)
        task.wait(0.08)
        
        -- 5. Grab
        local slotKey = egg.NestId and egg.AreaId and (egg.AreaId..":"..egg.NestId) or nil
        local got = grabEgg(egg.Uid, slotKey)
        
        if not got then
            blockedEggs[egg.Uid] = os.clock() + 5
            stealRunning = false; task.wait(0.3); continue
        end
        
        -- 6. Lift
        h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then
            h.CFrame = CFrame.new(h.Position.X, Settings.FlightHeight, h.Position.Z)
            h.AssemblyLinearVelocity  = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
        end
        task.wait(0.15)
        
        -- 7. Return to safe zone
        local safe = getSafeZone()
        tweenTo(Vector3.new(safe.X, Settings.FlightHeight, safe.Z), Settings.ReturnSpeed)
        if not Settings.AutoSteal then stealRunning = false; continue end
        tweenTo(safe, 280)
        task.wait(0.3)
        
        -- 8. Place egg
        task.spawn(placeEggInField)
        
        stealRunning = false
        task.wait(0.8)
    end
end)

-- ============================================================
-- [[ ANTI GUARD ]]
-- ============================================================
task.spawn(function()
    while task.wait(0.08) do
        if not Settings.AntiGuard then continue end
        local c = lp.Character
        if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanTouch = false end) end
        end
    end
end)

-- ============================================================
-- [[ AUTO EQUIP BEST ]]
-- ============================================================
task.spawn(function()
    while task.wait(5) do
        if not Settings.AutoEquipBest then continue end
        pcall(function()
            local rem = getRemotes()
            if rem and rem.Haul and rem.Haul.WearBest then
                rem.Haul.WearBest:InvokeServer()
            else
                local net = ReplicatedStorage:FindFirstChild("Network")
                local eb = net and net:FindFirstChild("Backpack: EquipBest")
                if eb then eb:InvokeServer() end
            end
        end)
    end
end)

-- ============================================================
-- [[ AUTO HATCH ]]
-- ============================================================
task.spawn(function()
    while task.wait(2) do
        if not Settings.AutoHatch then continue end
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
            local recs = {}
            for _, v in ipairs(type(snap)=="table" and snap or {}) do
                if type(v)=="table" and v.OwnerUserId == lp.UserId then
                    recs = v.Records or {}; break
                end
            end
            for k in pairs(recs) do
                local rec = recs[k]
                if type(rec)=="table" and rec.Placement then
                    local ready = false
                    if es.IsReadyToHatch then pcall(function() ready = es.IsReadyToHatch(k) end) end
                    if ready then
                        if es.BeginHatch  then pcall(es.BeginHatch,  k); task.wait(0.3) end
                        if es.FinishHatch then pcall(es.FinishHatch, k) end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- [[ AUTO TREADMILL ]]
-- ============================================================
local function checkTreadmill()
    local ok, md = pcall(require, ReplicatedStorage.Client.MusicDirector)
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
        local net = ReplicatedStorage:FindFirstChild("Network")
        local ru = net and net:FindFirstChild("Treadmills: RequestUnequip")
        if ru then ru:InvokeServer() end
    end)
end

UserInputService.JumpRequest:Connect(function()
    if Settings.AutoTreadmill and checkTreadmill() then exitTreadmill() end
end)

task.spawn(function()
    while task.wait(0.8) do
        if not Settings.AutoTreadmill then
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
        
        local cPos = plot.CenterPoint and (plot.CenterPoint.Position + Vector3.new(0,3,0))
        if cPos and (h.Position-cPos).Magnitude > 8 then tweenTo(cPos,150) end
        tweenTo(tb.Position + Vector3.new(0,3,0), 100)
        
        h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then
            local lv = tb.CFrame.LookVector
            h.CFrame = CFrame.lookAt(h.Position, h.Position+lv)
            local hm = lp.Character:FindFirstChildOfClass("Humanoid")
            if hm then pcall(function() hm:Move(lv) end) end
        end
    end
end)

-- ============================================================
-- [[ PLAYER FEATURES ]]
-- ============================================================

-- Walk Speed
task.spawn(function()
    while task.wait(0.1) do
        local h2 = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        if h2 then h2.WalkSpeed = Settings.WalkSpeed end
    end
end)

-- NoClip
task.spawn(function()
    while task.wait(0.05) do
        if not Settings.NoClip then continue end
        local c = lp.Character
        if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if not Settings.InfiniteJump then return end
    local h2 = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if h2 then h2:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Invisibility
local invisiConnections = {}
local function applyInvisibility(state)
    -- disconnect old
    for _, c in ipairs(invisiConnections) do c:Disconnect() end
    invisiConnections = {}
    
    local function setTransparency(c, val)
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("MeshPart") or p:IsA("SpecialMesh") then
                pcall(function() p.LocalTransparencyModifier = val end)
            elseif p:IsA("Decal") or p:IsA("Texture") then
                pcall(function() p.Transparency = val end)
            elseif p:IsA("BillboardGui") or p:IsA("SurfaceGui") then
                pcall(function() p.Enabled = not state end)
            end
        end
    end
    
    local c = lp.Character
    if state then
        setTransparency(c, 1)
        -- Also hide held egg tool
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if child:IsA("Tool") then
                    for _, p in ipairs(child:GetDescendants()) do
                        if p:IsA("BasePart") then
                            pcall(function() p.LocalTransparencyModifier = 1 end)
                        end
                    end
                end
            end
        end
        -- Keep invisible on respawn
        local conn = lp.CharacterAdded:Connect(function(nc)
            task.wait(0.1)
            if Settings.Invisibility then setTransparency(nc, 1) end
        end)
        table.insert(invisiConnections, conn)
    else
        setTransparency(c, 0)
    end
end

-- Continuously hide when invisible (for newly added parts)
task.spawn(function()
    while task.wait(0.3) do
        if not Settings.Invisibility then continue end
        local c = lp.Character
        if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            pcall(function()
                if p:IsA("BasePart") or p:IsA("MeshPart") then
                    p.LocalTransparencyModifier = 1
                end
            end)
        end
    end
end)

-- ============================================================
-- [[ ESP ]]
-- ============================================================
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "YushESP"

local espObjects = {}

local function clearESP()
    for _, v in pairs(espObjects) do
        if v and v.Parent then v:Destroy() end
    end
    espObjects = {}
end

-- ESP Eggs
local function updateEggESP()
    if not Settings.ESPEggs then
        for uid, obj in pairs(espObjects) do
            if obj and obj.Name:sub(1,3) == "EGG" then obj:Destroy(); espObjects[uid] = nil end
        end
        return
    end
    
    local eggState = getEggState()
    local eggs = {}
    if eggState and eggState.ReadFieldEggs then
        local ok, rec = pcall(eggState.ReadFieldEggs)
        if ok and rec then
            local list = rec.Records or rec
            for _, e in pairs(type(list)=="table" and list or {}) do
                if e and e.Uid then eggs[e.Uid] = e end
            end
        end
    end
    
    for uid, egg in pairs(eggs) do
        local rarity = getRarity(egg.AssetCategory)
        if rarity < Settings.ESPMinRarity then continue end
        local pos = (egg.BottomCFrame or egg.BoundsCFrame) and
                    (egg.BottomCFrame or egg.BoundsCFrame).Position
        if not pos then continue end
        
        local key = "EGG_"..uid
        if not espObjects[key] or not espObjects[key].Parent then
            local part = Instance.new("Part", espFolder)
            part.Name       = key
            part.Anchored   = true
            part.CanCollide = false
            part.CanTouch   = false
            part.Material   = Enum.Material.Neon
            part.Size       = Vector3.new(1,1,1) * Settings.ESPEggSize * 3
            part.Shape      = Enum.PartType.Ball
            
            local bb = Instance.new("BillboardGui", part)
            bb.Name         = "BB"
            bb.AlwaysOnTop  = true
            bb.Size         = UDim2.fromOffset(140, 30)
            bb.StudsOffset  = Vector3.new(0,3,0)
            local lbl = Instance.new("TextLabel", bb)
            lbl.Name        = "TL"
            lbl.Size        = UDim2.fromScale(1,1)
            lbl.BackgroundTransparency = 1
            lbl.Font        = Enum.Font.GothamBold
            lbl.TextSize    = 11
            lbl.TextStrokeTransparency = 0
            lbl.TextColor3  = Color3.fromRGB(0,220,255)
            espObjects[key] = part
        end
        
        local part = espObjects[key]
        part.CFrame = CFrame.new(pos)
        
        -- Color by rarity
        local colors = {
            Color3.fromRGB(150,150,150),
            Color3.fromRGB(50,200,50),
            Color3.fromRGB(50,100,220),
            Color3.fromRGB(150,50,220),
            Color3.fromRGB(255,140,0),
            Color3.fromRGB(255,50,150),
            Color3.fromRGB(180,0,255),
            Color3.fromRGB(255,255,255),
            Color3.fromRGB(0,255,200),
            Color3.fromRGB(255,215,0),
            Color3.fromRGB(255,50,50),
            Color3.fromRGB(255,100,255),
        }
        part.Color = colors[math.min(rarity, 12)] or Color3.fromRGB(255,255,255)
        
        if Settings.ESPShowInfo then
            local bb = part:FindFirstChild("BB")
            local lbl = bb and bb:FindFirstChild("TL")
            if lbl then
                lbl.Text = string.format("%s [%s]", egg.AssetCategory or "?", rarityNames[rarity] or "?")
                lbl.TextColor3 = part.Color
            end
        end
    end
    
    -- Clean up old
    for key, obj in pairs(espObjects) do
        if key:sub(1,4) == "EGG_" and not eggs[key:sub(5)] then
            if obj and obj.Parent then obj:Destroy() end
            espObjects[key] = nil
        end
    end
end

-- ESP Guards
local function updateGuardESP()
    local guardAreas = workspace:FindFirstChild("World") and
                       workspace.World:FindFirstChild("Areas") and
                       workspace.World.Areas:FindFirstChild("GuardAreas")
    if not guardAreas then return end
    
    for _, area in ipairs(guardAreas:GetChildren()) do
        local guard = area:FindFirstChild("Guard")
        if guard and guard:IsA("Model") then
            local key = "GUARD_"..area.Name
            if Settings.ESPGuards then
                if not espObjects[key] or not espObjects[key].Parent then
                    local hl = Instance.new("Highlight", espFolder)
                    hl.Name             = key
                    hl.Adornee          = guard
                    hl.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 0.5
                    espObjects[key] = hl
                end
                local state = guard:GetAttribute("GuardState") or "Sleeping"
                local hl = espObjects[key]
                local color = state=="Chasing" and Color3.fromRGB(255,50,50)
                           or state=="Waking"  and Color3.fromRGB(255,200,0)
                           or Color3.fromRGB(50,255,80)
                hl.FillColor    = color
                hl.OutlineColor = color
            else
                if espObjects[key] and espObjects[key].Parent then
                    espObjects[key]:Destroy(); espObjects[key] = nil
                end
            end
        end
    end
end

-- ESP Players
local function updatePlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == lp then continue end
        local c = player.Character
        if not c then continue end
        local key = "PLAYER_"..player.Name
        
        if Settings.ESPPlayers then
            if not espObjects[key] or not espObjects[key].Parent then
                local hl = Instance.new("Highlight", espFolder)
                hl.Name             = key
                hl.Adornee          = c
                hl.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.5
                hl.FillColor        = Color3.fromRGB(255,100,100)
                hl.OutlineColor     = Color3.fromRGB(255,100,100)
                espObjects[key] = hl
                
                if Settings.ESPPlayerInfo then
                    local h2 = c:FindFirstChild("HumanoidRootPart")
                    if h2 then
                        local bb = Instance.new("BillboardGui", h2)
                        bb.Name        = "YushPlayerESP"
                        bb.AlwaysOnTop = true
                        bb.Size        = UDim2.fromOffset(120,30)
                        bb.StudsOffset = Vector3.new(0,3,0)
                        local lbl = Instance.new("TextLabel", bb)
                        lbl.Size       = UDim2.fromScale(1,1)
                        lbl.BackgroundTransparency = 1
                        lbl.Font       = Enum.Font.GothamBold
                        lbl.TextSize   = 11
                        lbl.TextColor3 = Color3.fromRGB(255,100,100)
                        lbl.TextStrokeTransparency = 0
                        lbl.Text       = player.Name
                    end
                end
            end
            -- Update adornee if character changed
            espObjects[key].Adornee = c
        else
            if espObjects[key] and espObjects[key].Parent then
                espObjects[key]:Destroy(); espObjects[key] = nil
            end
        end
    end
end

-- ESP loop
task.spawn(function()
    while task.wait(1) do
        pcall(updateEggESP)
        pcall(updateGuardESP)
        pcall(updatePlayerESP)
    end
end)

-- ============================================================
-- [[ AUTO HIT ]]
-- ============================================================
task.spawn(function()
    while task.wait(0.3) do
        if not Settings.AutoHitPlayer and not Settings.AutoHitEggHolder then continue end
        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not h then continue end
        
        local closest, closestDist = nil, math.huge
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player == lp then continue end
            local c = player.Character
            local ph = c and c:FindFirstChild("HumanoidRootPart")
            if not ph then continue end
            
            local isEggHolder = false
            if c then
                for _, child in ipairs(c:GetChildren()) do
                    if child:IsA("Tool") and child:GetAttribute("ItemType") == "AssetEgg" then
                        isEggHolder = true; break
                    end
                end
            end
            
            if Settings.AutoHitEggHolder and not isEggHolder then continue end
            
            local dist = (h.Position - ph.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = player
            end
        end
        
        if closest then
            local tool = lp.Character and lp.Character:FindFirstChildOfClass("Tool")
            if tool then
                pcall(function() tool:Activate() end)
            end
        end
    end
end)

-- ============================================================
-- [[ PROGRESS FEATURES ]]
-- ============================================================

-- Auto Fuse
task.spawn(function()
    while task.wait(2) do
        if not Settings.AutoFuse then continue end
        pcall(function()
            local rem = getRemotes()
            if not (rem and rem.Fusery and rem.Fusery.LoadPet and rem.Fusery.BeginFuse) then return end
            
            if rem.Fusery.ConfirmBriefing then
                local save = getSave()
                if save and save.FusionInfoAcknowledged == false then
                    pcall(function() rem.Fusery.ConfirmBriefing:InvokeServer() end)
                end
            end
            
            local save = getSave()
            if not save or not save.Inventory then return end
            local inventory = save.Inventory
            local equipped = {}
            for _, uid in ipairs(save.EquippedAssets or save.EquippedPets or {}) do
                equipped[uid] = true
            end
            
            -- Group by category
            local groups = {}
            for uid, pet in pairs(inventory) do
                if type(pet)=="table" and pet.Category and not pet.IsFavorite and not equipped[uid] then
                    if Settings.FuseSkipMutated then
                        if (type(pet.Mutations)=="table" and #pet.Mutations>0) or
                           (pet.BaseMutation and pet.BaseMutation~="" and pet.BaseMutation~="Normal") then
                            continue
                        end
                    end
                    local rarity = getRarity(pet.Category)
                    if Settings.FuseMaxRarity > 0 and rarity > Settings.FuseMaxRarity then continue end
                    if not groups[pet.Category] then groups[pet.Category] = {} end
                    table.insert(groups[pet.Category], uid)
                end
            end
            
            -- Find group with 3+
            local best = nil
            for cat, uids in pairs(groups) do
                if #uids >= 3 then
                    local rarity = getRarity(cat)
                    if not best or rarity < getRarity(best.cat) then
                        best = {cat=cat, uids=uids}
                    end
                end
            end
            
            if not best then return end
            
            for i = 1, 3 do
                pcall(function() rem.Fusery.LoadPet:InvokeServer(best.uids[i]) end)
                task.wait(0.15)
            end
            task.wait(0.2)
            local ok, r = pcall(function() return rem.Fusery.BeginFuse:InvokeServer() end)
            if ok and r then
                task.wait(0.3)
                if rem.Fusery.FinishReveal then pcall(function() rem.Fusery.FinishReveal:InvokeServer() end) end
            end
        end)
    end
end)

-- Auto Favorite
local function favoriteNow()
    pcall(function()
        local rem  = getRemotes()
        local save = getSave()
        if not save or not save.Inventory then return end
        for uid, pet in pairs(save.Inventory) do
            if type(pet)=="table" and not pet.IsFavorite and pet.Category then
                if rem and rem.PetSatchel and rem.PetSatchel.WriteFavourite then
                    rem.PetSatchel.WriteFavourite:FireServer(uid, true)
                end
                task.wait(0.05)
            end
        end
    end)
end

task.spawn(function()
    while task.wait(3) do
        if Settings.AutoFavPet then favoriteNow() end
    end
end)

local function setEquippedFavorite(state)
    pcall(function()
        local rem  = getRemotes()
        local save = getSave()
        if not save then return end
        local equipped = save.EquippedAssets or save.EquippedPets or {}
        for _, uid in ipairs(equipped) do
            if rem and rem.PetSatchel and rem.PetSatchel.WriteFavourite then
                rem.PetSatchel.WriteFavourite:FireServer(uid, state)
                task.wait(0.05)
            end
        end
    end)
end

task.spawn(function()
    while task.wait(3) do
        if Settings.AutoFavEquipped   then setEquippedFavorite(true)  end
        if Settings.AutoUnFavEquipped then setEquippedFavorite(false) end
    end
end)

-- ============================================================
-- [[ MISC FEATURES ]]
-- ============================================================

-- Anti AFK
local afkVirtualInputManager = nil
task.spawn(function()
    while task.wait(60) do
        if not Settings.AntiAFK then continue end
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true,  Enum.KeyCode.LeftShift, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        end)
    end
end)

-- FPS Optimizer
task.spawn(function()
    while task.wait(2) do
        if not Settings.FPSOptimizer then continue end
        pcall(function()
            Lighting.GlobalShadows    = false
            Lighting.FogEnd           = 9e9
        end)
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("BasePart") and not (lp.Character and desc:IsDescendantOf(lp.Character)) then
                pcall(function() desc.CastShadow = false end)
            end
        end
    end
end)

-- Hide others pets/eggs
task.spawn(function()
    while task.wait(0.5) do
        for _, child in ipairs(workspace:GetChildren()) do
            -- Hide others' eggs
            if child.Name == "PlacedEggRenders" then
                for _, egg in ipairs(child:GetChildren()) do
                    local mine = string.find(egg.Name, tostring(lp.UserId), 1, true)
                    if (not mine and Settings.HideOtherEggs) or (mine and Settings.HideYourEggs) then
                        for _, p in ipairs(egg:GetDescendants()) do
                            pcall(function()
                                if p:IsA("BasePart") then p.LocalTransparencyModifier = 1
                                elseif p:IsA("Decal") or p:IsA("Texture") then p.Transparency = 1
                                elseif p:IsA("BillboardGui") or p:IsA("ParticleEmitter") then p.Enabled = false
                                end
                            end)
                        end
                    end
                end
            end
        end
        -- Hide others' pets
        local cra = workspace:FindFirstChild("ClientRenderedAssets")
        if cra then
            for _, pet in ipairs(cra:GetChildren()) do
                local mine = pet:GetAttribute("OwnerUserId") == lp.UserId
                if (not mine and Settings.HideOtherPets) or (mine and Settings.HideYourPets) then
                    for _, p in ipairs(pet:GetDescendants()) do
                        pcall(function()
                            if p:IsA("BasePart") then p.LocalTransparencyModifier = 1
                            elseif p:IsA("Decal") then p.Transparency = 1
                            elseif p:IsA("BillboardGui") or p:IsA("ParticleEmitter") then p.Enabled = false
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- ============================================================
-- [[ UI ]]
-- ============================================================
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "YushHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.DisplayOrder   = 9999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

-- Theme colors
local C = {
    BG       = Color3.fromRGB(8, 10, 18),
    Panel    = Color3.fromRGB(12, 15, 28),
    PanelAlt = Color3.fromRGB(16, 20, 36),
    Accent   = Color3.fromRGB(0, 185, 255),
    Accent2  = Color3.fromRGB(0, 120, 200),
    TabOn    = Color3.fromRGB(0, 140, 220),
    TabOff   = Color3.fromRGB(18, 22, 42),
    TOn      = Color3.fromRGB(0, 175, 95),
    TOff     = Color3.fromRGB(48, 55, 78),
    Text     = Color3.fromRGB(210, 220, 240),
    TextSub  = Color3.fromRGB(120, 135, 165),
    Border   = Color3.fromRGB(0, 185, 255),
}

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or C.Border
    s.Thickness = thickness or 1
    return s
end

local function makePad(parent, l, r, t, b)
    local p = Instance.new("UIPadding", parent)
    p.PaddingLeft   = UDim.new(0, l or 8)
    p.PaddingRight  = UDim.new(0, r or 8)
    p.PaddingTop    = UDim.new(0, t or 8)
    p.PaddingBottom = UDim.new(0, b or 8)
    return p
end

-- ── FPS/PING HUD ─────────────────────────────────────────
local HudFrame = Instance.new("Frame", ScreenGui)
HudFrame.Name                   = "Hud"
HudFrame.Size                   = UDim2.new(0, 260, 0, 34)
HudFrame.Position               = UDim2.new(0.5, -130, 0, 6)
HudFrame.BackgroundColor3       = C.BG
HudFrame.BackgroundTransparency = 0.05
HudFrame.Active                 = true
HudFrame.Draggable              = true
makeCorner(HudFrame, 8)
makeStroke(HudFrame, C.Accent, 1.2)

local HudLabel = Instance.new("TextLabel", HudFrame)
HudLabel.Size                   = UDim2.new(1, 0, 1, 0)
HudLabel.BackgroundTransparency = 1
HudLabel.Font                   = Enum.Font.GothamBold
HudLabel.TextSize               = 12
HudLabel.TextColor3             = C.Text
HudLabel.RichText               = true
HudLabel.Text                   = "⚡  FPS: --  |  PING: --ms"

local fpsFrames, fpsLast, fpsCurrent = 0, os.clock(), 60
RunService.RenderStepped:Connect(function()
    fpsFrames += 1
    local now = os.clock()
    if now - fpsLast >= 1 then
        fpsCurrent = math.round(fpsFrames / (now - fpsLast))
        fpsFrames  = 0
        fpsLast    = now
        local ping = 0
        pcall(function()
            ping = math.round(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        local fpsColor = fpsCurrent >= 55 and "#00FF88" or fpsCurrent >= 30 and "#FFD700" or "#FF5555"
        local pingColor = ping <= 80 and "#00FF88" or ping <= 150 and "#FFD700" or "#FF5555"
        HudLabel.Text = string.format(
            '⚡  <font color="%s">FPS: %d</font>  |  <font color="%s">PING: %dms</font>',
            fpsColor, fpsCurrent, pingColor, ping
        )
    end
end)

-- ── MAIN WINDOW ──────────────────────────────────────────
local WIN_W, WIN_H = 460, 480

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name                  = "MainFrame"
MainFrame.Size                  = UDim2.new(0, WIN_W, 0, WIN_H)
MainFrame.Position              = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
MainFrame.BackgroundColor3      = C.BG
MainFrame.BackgroundTransparency = 0.04
MainFrame.BorderSizePixel       = 0
makeCorner(MainFrame, 10)
makeStroke(MainFrame, C.Accent, 1.5)

-- Title bar (draggable)
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Name                   = "TitleBar"
TitleBar.Size                   = UDim2.new(1, 0, 0, 56)
TitleBar.BackgroundColor3       = C.Panel
TitleBar.BorderSizePixel        = 0

-- Rounded only on top
local TitleBarCorner = Instance.new("UICorner", TitleBar)
TitleBarCorner.CornerRadius = UDim.new(0, 10)

-- Cover bottom corners of titlebar
local TitleBarCover = Instance.new("Frame", TitleBar)
TitleBarCover.Size              = UDim2.new(1, 0, 0.5, 0)
TitleBarCover.Position          = UDim2.new(0, 0, 0.5, 0)
TitleBarCover.BackgroundColor3  = C.Panel
TitleBarCover.BorderSizePixel   = 0

-- Logo image
local LogoImg = Instance.new("ImageLabel", TitleBar)
LogoImg.Name                    = "Logo"
LogoImg.Size                    = UDim2.new(0, 40, 0, 40)
LogoImg.Position                = UDim2.new(0, 10, 0.5, -20)
LogoImg.BackgroundTransparency  = 1
LogoImg.Image                   = "https://kommodo.ai/i/GVHleyzQ3zvcly38H8JU"
LogoImg.ScaleType               = Enum.ScaleType.Fit
makeCorner(LogoImg, 6)

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size                   = UDim2.new(1, -120, 1, 0)
TitleLbl.Position               = UDim2.new(0, 58, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.TextSize               = 13
TitleLbl.TextColor3             = C.Accent
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
TitleLbl.Text                   = "YUSH HUB  |  STEAL AN EGG"
TitleLbl.RichText               = true

local SubTitleLbl = Instance.new("TextLabel", TitleBar)
SubTitleLbl.Size                = UDim2.new(1, -120, 0, 16)
SubTitleLbl.Position            = UDim2.new(0, 58, 0, 30)
SubTitleLbl.BackgroundTransparency = 1
SubTitleLbl.Font                = Enum.Font.Gotham
SubTitleLbl.TextSize            = 10
SubTitleLbl.TextColor3          = C.TextSub
SubTitleLbl.TextXAlignment      = Enum.TextXAlignment.Left
SubTitleLbl.Text                = "Professional Edition v2.0"

-- Close button
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size                   = UDim2.new(0, 28, 0, 28)
CloseBtn.Position               = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3       = Color3.fromRGB(200, 55, 55)
CloseBtn.BorderSizePixel        = 0
CloseBtn.Font                   = Enum.Font.GothamBold
CloseBtn.TextSize               = 14
CloseBtn.TextColor3             = Color3.fromRGB(255,255,255)
CloseBtn.Text                   = "×"
makeCorner(CloseBtn, 6)
CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, WIN_W, 0, 0)
    }):Play()
    task.wait(0.22)
    MainFrame.Visible = false
end)

-- Minimize button
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size                     = UDim2.new(0, 28, 0, 28)
MinBtn.Position                 = UDim2.new(1, -70, 0.5, -14)
MinBtn.BackgroundColor3         = Color3.fromRGB(55, 60, 90)
MinBtn.BorderSizePixel          = 0
MinBtn.Font                     = Enum.Font.GothamBold
MinBtn.TextSize                 = 14
MinBtn.TextColor3               = C.Text
MinBtn.Text                     = "—"
makeCorner(MinBtn, 6)
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0,WIN_W,0,56)}):Play()
    else
        TweenService:Create(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0,WIN_W,0,WIN_H)}):Play()
    end
end)

-- Titlebar separator
local TitleSep = Instance.new("Frame", MainFrame)
TitleSep.Size                   = UDim2.new(1, 0, 0, 1)
TitleSep.Position               = UDim2.new(0, 0, 0, 56)
TitleSep.BackgroundColor3       = C.Accent
TitleSep.BackgroundTransparency = 0.6
TitleSep.BorderSizePixel        = 0

-- Body frame (below title)
local BodyFrame = Instance.new("Frame", MainFrame)
BodyFrame.Name                  = "Body"
BodyFrame.Size                  = UDim2.new(1, 0, 1, -57)
BodyFrame.Position              = UDim2.new(0, 0, 0, 57)
BodyFrame.BackgroundTransparency = 1
BodyFrame.ClipsDescendants      = true

-- Left sidebar (tabs)
local Sidebar = Instance.new("Frame", BodyFrame)
Sidebar.Name                    = "Sidebar"
Sidebar.Size                    = UDim2.new(0, 100, 1, 0)
Sidebar.BackgroundColor3        = C.Panel
Sidebar.BorderSizePixel         = 0

-- Sidebar list layout
local SidebarLayout = Instance.new("UIListLayout", Sidebar)
SidebarLayout.Padding           = UDim.new(0, 4)
SidebarLayout.FillDirection     = Enum.FillDirection.Vertical
SidebarLayout.SortOrder         = Enum.SortOrder.LayoutOrder
makePad(Sidebar, 6, 6, 8, 8)

-- Sidebar vertical separator
local SidebarSep = Instance.new("Frame", BodyFrame)
SidebarSep.Size                 = UDim2.new(0, 1, 1, 0)
SidebarSep.Position             = UDim2.new(0, 100, 0, 0)
SidebarSep.BackgroundColor3     = C.Accent
SidebarSep.BackgroundTransparency = 0.6
SidebarSep.BorderSizePixel      = 0

-- Content area (right of sidebar)
local ContentArea = Instance.new("Frame", BodyFrame)
ContentArea.Name                = "ContentArea"
ContentArea.Size                = UDim2.new(1, -101, 1, 0)
ContentArea.Position            = UDim2.new(0, 101, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants    = true

-- ── DRAGGABLE LOGIC ──────────────────────────────────────
do
    local drag, ds, sp = false, nil, nil
    TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or
                     i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            MainFrame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
end

-- ── UI COMPONENT BUILDERS ────────────────────────────────

-- Scrollable content page
local function newPage(name)
    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Name                   = name
    page.Size                   = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel        = 0
    page.ScrollBarThickness     = 3
    page.ScrollBarImageColor3   = C.Accent
    page.CanvasSize             = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    page.Visible                = false
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding              = UDim.new(0, 6)
    layout.SortOrder            = Enum.SortOrder.LayoutOrder
    
    makePad(page, 10, 10, 8, 10)
    return page
end

-- Section header
local function newSection(parent, text)
    local frame = Instance.new("Frame", parent)
    frame.Size                  = UDim2.new(1, 0, 0, 22)
    frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size                    = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency  = 1
    lbl.Font                    = Enum.Font.GothamBold
    lbl.TextSize                = 9
    lbl.TextColor3              = C.Accent
    lbl.TextXAlignment          = Enum.TextXAlignment.Left
    lbl.Text                    = "  ◈  " .. text:upper()
    
    local line = Instance.new("Frame", frame)
    line.Size                   = UDim2.new(1, 0, 0, 1)
    line.Position               = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3       = C.Accent
    line.BackgroundTransparency = 0.7
    line.BorderSizePixel        = 0
    return frame
end

-- Toggle row
local function newToggle(parent, labelText, desc, default, onChange)
    local row = Instance.new("Frame", parent)
    row.Size                    = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3        = C.PanelAlt
    row.BorderSizePixel         = 0
    makeCorner(row, 7)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size                    = UDim2.new(1, -60, 0, 18)
    lbl.Position                = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency  = 1
    lbl.Font                    = Enum.Font.GothamBold
    lbl.TextSize                = 11
    lbl.TextColor3              = C.Text
    lbl.TextXAlignment          = Enum.TextXAlignment.Left
    lbl.Text                    = labelText
    
    if desc and desc ~= "" then
        local sub = Instance.new("TextLabel", row)
        sub.Size                = UDim2.new(1, -60, 0, 13)
        sub.Position            = UDim2.new(0, 10, 0, 22)
        sub.BackgroundTransparency = 1
        sub.Font                = Enum.Font.Gotham
        sub.TextSize            = 9
        sub.TextColor3          = C.TextSub
        sub.TextXAlignment      = Enum.TextXAlignment.Left
        sub.Text                = desc
    end
    
    local track = Instance.new("Frame", row)
    track.Size                  = UDim2.new(0, 40, 0, 20)
    track.Position              = UDim2.new(1, -48, 0.5, -10)
    track.BackgroundColor3      = default and C.TOn or C.TOff
    track.BorderSizePixel       = 0
    makeCorner(track, 10)
    
    local knob = Instance.new("Frame", track)
    knob.Size                   = UDim2.new(0, 16, 0, 16)
    knob.Position               = default and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    knob.BackgroundColor3       = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel        = 0
    makeCorner(knob, 8)
    
    -- Knob shadow
    local knobShadow = Instance.new("UIStroke", knob)
    knobShadow.Color            = Color3.fromRGB(0,0,0)
    knobShadow.Transparency     = 0.7
    knobShadow.Thickness        = 1
    
    local state = default or false
    local function setState(v)
        state = v
        TweenService:Create(track, TweenInfo.new(0.15), {BackgroundColor3 = state and C.TOn or C.TOff}):Play()
        TweenService:Create(knob,  TweenInfo.new(0.15), {Position = state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
        if onChange then onChange(state) end
    end
    
    local btn = Instance.new("TextButton", row)
    btn.Size                    = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency  = 1
    btn.Text                    = ""
    btn.MouseButton1Click:Connect(function() setState(not state) end)
    
    if default and onChange then onChange(true) end
    return row, setState
end

-- Slider row
local function newSlider(parent, labelText, min, max, default, onChange)
    local row = Instance.new("Frame", parent)
    row.Size                    = UDim2.new(1, 0, 0, 48)
    row.BackgroundColor3        = C.PanelAlt
    row.BorderSizePixel         = 0
    makeCorner(row, 7)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size                    = UDim2.new(0.6, 0, 0, 18)
    lbl.Position                = UDim2.new(0, 10, 0, 5)
    lbl.BackgroundTransparency  = 1
    lbl.Font                    = Enum.Font.GothamBold
    lbl.TextSize                = 11
    lbl.TextColor3              = C.Text
    lbl.TextXAlignment          = Enum.TextXAlignment.Left
    lbl.Text                    = labelText
    
    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size                 = UDim2.new(0.35, 0, 0, 18)
    valLbl.Position             = UDim2.new(0.65, 0, 0, 5)
    valLbl.BackgroundTransparency = 1
    valLbl.Font                 = Enum.Font.GothamBold
    valLbl.TextSize             = 11
    valLbl.TextColor3           = C.Accent
    valLbl.TextXAlignment       = Enum.TextXAlignment.Right
    valLbl.Text                 = tostring(default)
    
    local track = Instance.new("Frame", row)
    track.Size                  = UDim2.new(1, -20, 0, 6)
    track.Position              = UDim2.new(0, 10, 0, 30)
    track.BackgroundColor3      = C.TOff
    track.BorderSizePixel       = 0
    makeCorner(track, 3)
    
    local fill = Instance.new("Frame", track)
    fill.Size                   = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3       = C.Accent
    fill.BorderSizePixel        = 0
    makeCorner(fill, 3)
    
    local knob = Instance.new("Frame", track)
    knob.Size                   = UDim2.new(0, 14, 0, 14)
    knob.Position               = UDim2.new((default-min)/(max-min), -7, 0.5, -7)
    knob.BackgroundColor3       = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel        = 0
    makeCorner(knob, 7)
    makeStroke(knob, C.Accent, 1)
    
    local value = default
    local function setValue(v, fromInput)
        v = math.clamp(math.round(v * 10) / 10, min, max)
        value = v
        local pct = (v - min) / (max - min)
        fill.Size     = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, -7, 0.5, -7)
        valLbl.Text   = tostring(v)
        if onChange and fromInput then onChange(v) end
    end
    
    local dragging = false
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = track.AbsolutePosition.X
            local w   = track.AbsoluteSize.X
            local pct = math.clamp((i.Position.X - abs) / w, 0, 1)
            setValue(min + (max - min) * pct, true)
        end
    end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            local abs = track.AbsolutePosition.X
            local w   = track.AbsoluteSize.X
            local pct = math.clamp((i.Position.X - abs) / w, 0, 1)
            setValue(min + (max - min) * pct, true)
        end
    end)
    return row
end

-- Button row
local function newButton(parent, text, onClick)
    local btn = Instance.new("TextButton", parent)
    btn.Size                    = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3        = C.Accent2
    btn.BorderSizePixel         = 0
    btn.Font                    = Enum.Font.GothamBold
    btn.TextSize                = 11
    btn.TextColor3              = Color3.fromRGB(255,255,255)
    btn.Text                    = text
    makeCorner(btn, 7)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.Accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.Accent2}):Play()
    end)
    btn.MouseButton1Click:Connect(onClick or function() end)
    return btn
end

-- Label (description/info)
local function newLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size                    = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency  = 1
    lbl.Font                    = Enum.Font.Gotham
    lbl.TextSize                = 9
    lbl.TextColor3              = C.TextSub
    lbl.TextXAlignment          = Enum.TextXAlignment.Left
    lbl.TextWrapped             = true
    lbl.Text                    = "  " .. text
    return lbl
end

-- ── TAB BUTTONS ──────────────────────────────────────────
local tabPages = {}
local tabBtns  = {}
local activeTab = nil

local function selectTab(name)
    for n, page in pairs(tabPages) do
        page.Visible = (n == name)
    end
    for n, btn in pairs(tabBtns) do
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (n == name) and C.TabOn or C.TabOff
        }):Play()
        local lbl = btn:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.TextColor3 = (n == name) and Color3.fromRGB(255,255,255) or C.TextSub end
    end
    activeTab = name
end

local TABS = {
    {name="FARM",     icon="🌾"},
    {name="PLAYER",   icon="👤"},
    {name="PROGRESS", icon="📈"},
    {name="MISC",     icon="⚙️"},
}

for i, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton", Sidebar)
    btn.Name                    = tab.name
    btn.Size                    = UDim2.new(1, 0, 0, 52)
    btn.BackgroundColor3        = C.TabOff
    btn.BorderSizePixel         = 0
    btn.Text                    = ""
    btn.LayoutOrder             = i
    makeCorner(btn, 7)
    
    local iconLbl = Instance.new("TextLabel", btn)
    iconLbl.Size                = UDim2.new(1, 0, 0, 22)
    iconLbl.Position            = UDim2.new(0, 0, 0, 7)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Font                = Enum.Font.Gotham
    iconLbl.TextSize            = 18
    iconLbl.TextColor3          = C.TextSub
    iconLbl.Text                = tab.icon
    
    local nameLbl = Instance.new("TextLabel", btn)
    nameLbl.Size                = UDim2.new(1, 0, 0, 14)
    nameLbl.Position            = UDim2.new(0, 0, 0, 30)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font                = Enum.Font.GothamBold
    nameLbl.TextSize            = 8
    nameLbl.TextColor3          = C.TextSub
    nameLbl.Text                = tab.name
    
    -- Page
    local page = newPage(tab.name.."_Page")
    tabPages[tab.name] = page
    tabBtns[tab.name]  = btn
    
    btn.MouseButton1Click:Connect(function() selectTab(tab.name) end)
end

-- ── FARM PAGE ────────────────────────────────────────────
local farmPage = tabPages["FARM"]

newSection(farmPage, "Steal Automation")
newToggle(farmPage, "Auto Steal Egg", "Picks & returns the highest rarity egg", false, function(v)
    Settings.AutoSteal = v
    if not v then stealRunning = false end
end)
newToggle(farmPage, "Anti Guard", "Prevents guards from hitting you", false, function(v)
    Settings.AntiGuard = v
end)
newSection(farmPage, "Movement Config")
newSlider(farmPage, "Flight Height", 75, 120, 88, function(v) Settings.FlightHeight = v end)
newSlider(farmPage, "Steal Speed", 100, 800, 400, function(v) Settings.StealSpeed = v end)
newSlider(farmPage, "Return Speed", 100, 800, 450, function(v) Settings.ReturnSpeed = v end)
newSection(farmPage, "Automation")
newToggle(farmPage, "Auto Equip Best", "Equips your best pets automatically", false, function(v)
    Settings.AutoEquipBest = v
end)
newToggle(farmPage, "Auto Hatch", "Hatches ready eggs in your pen", false, function(v)
    Settings.AutoHatch = v
end)
newToggle(farmPage, "Auto Treadmill", "Trains on treadmill (jump to exit)", false, function(v)
    Settings.AutoTreadmill = v
    if not v then exitTreadmill() end
end)
newButton(farmPage, "Exit Treadmill Now", function() exitTreadmill() end)
newSection(farmPage, "Status")
newLabel(farmPage, "Anti Knockback/Ragdoll is always active.")
newLabel(farmPage, "Auto Place Egg is automatic after each steal.")

-- ── PLAYER PAGE ──────────────────────────────────────────
local playerPage = tabPages["PLAYER"]

newSection(playerPage, "Movement")
newSlider(playerPage, "Walk Speed", 16, 500, 16, function(v)
    Settings.WalkSpeed = v
    local h2 = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if h2 then h2.WalkSpeed = v end
end)
newToggle(playerPage, "No Clip", "Walk through walls and objects", false, function(v)
    Settings.NoClip = v
end)
newToggle(playerPage, "Infinite Jump", "Jump from any position repeatedly", false, function(v)
    Settings.InfiniteJump = v
end)
newSection(playerPage, "Stealth")
newToggle(playerPage, "Invisibility", "Hides you & your held egg from others", false, function(v)
    Settings.Invisibility = v
    applyInvisibility(v)
end)
newToggle(playerPage, "Anti Ragdoll", "Blocks ragdoll & knockback always", true, function(v)
    Settings.AntiRagdoll = v
end)
newToggle(playerPage, "Anti Trap", "Prevents getting stuck in traps", false, function(v)
    Settings.AntiTrap = v
end)
newSection(playerPage, "ESP — Eggs")
newToggle(playerPage, "ESP Eggs", "Shows egg positions on map", false, function(v)
    Settings.ESPEggs = v
    if not v then
        for k, o in pairs(espObjects) do
            if k:sub(1,4)=="EGG_" and o and o.Parent then o:Destroy(); espObjects[k]=nil end
        end
    end
end)
newToggle(playerPage, "ESP Show Info", "Displays name & rarity on egg markers", true, function(v)
    Settings.ESPShowInfo = v
end)
newSlider(playerPage, "ESP Min Rarity", 1, 12, 7, function(v) Settings.ESPMinRarity = v end)
newSlider(playerPage, "ESP Egg Size", 0.2, 3, 0.5, function(v) Settings.ESPEggSize = v end)
newSection(playerPage, "ESP — Guards & Players")
newToggle(playerPage, "ESP Guards", "Highlights guards by their state", false, function(v)
    Settings.ESPGuards = v
    if not v then
        for k, o in pairs(espObjects) do
            if k:sub(1,6)=="GUARD_" and o and o.Parent then o:Destroy(); espObjects[k]=nil end
        end
    end
end)
newToggle(playerPage, "ESP Players", "Highlights other players", false, function(v)
    Settings.ESPPlayers = v
    if not v then
        for k, o in pairs(espObjects) do
            if k:sub(1,7)=="PLAYER_" and o and o.Parent then o:Destroy(); espObjects[k]=nil end
        end
    end
end)
newToggle(playerPage, "ESP Player Info", "Shows player names above heads", true, function(v)
    Settings.ESPPlayerInfo = v
end)
newSection(playerPage, "Combat")
newToggle(playerPage, "Auto Hit Nearest Player", "Auto-swings tool at nearest player", false, function(v)
    Settings.AutoHitPlayer = v
end)
newToggle(playerPage, "Auto Hit Egg Holders", "Only targets players holding eggs", false, function(v)
    Settings.AutoHitEggHolder = v
    if v then Settings.AutoHitPlayer = true end
end)

-- ── PROGRESS PAGE ─────────────────────────────────────────
local progPage = tabPages["PROGRESS"]

newSection(progPage, "Fuse Machine")
newToggle(progPage, "Auto Fuse Machine", "Fuses 3 matching pets automatically", false, function(v)
    Settings.AutoFuse = v
end)
newToggle(progPage, "Skip Mutated Pets", "Won't fuse Rainbow/Golden/Silver pets", true, function(v)
    Settings.FuseSkipMutated = v
end)
newToggle(progPage, "Eject Incomplete Slots", "Ejects slots if <3 matching pets", false, function(v)
    Settings.FuseEjectIncomplete = v
end)
newSlider(progPage, "Max Rarity To Fuse (0=All)", 0, 12, 0, function(v) Settings.FuseMaxRarity = v end)
newSection(progPage, "Pet Favorite")
newToggle(progPage, "Auto Favorite Pet", "Auto-favorites all unfavorited pets", false, function(v)
    Settings.AutoFavPet = v
end)
newButton(progPage, "Favorite All Pets Now", function()
    task.spawn(favoriteNow)
    notify("Yush Hub", "Favoriting all pets...")
end)
newSection(progPage, "Equipped Pets")
newToggle(progPage, "Auto Favorite Equipped", "Keeps equipped pets favorited", false, function(v)
    Settings.AutoFavEquipped = v
end)
newToggle(progPage, "Auto UnFavorite Equipped", "Keeps equipped pets unfavorited", false, function(v)
    Settings.AutoUnFavEquipped = v
end)
newButton(progPage, "Favorite Equipped Now", function()
    task.spawn(function() setEquippedFavorite(true) end)
    notify("Yush Hub", "Favoriting equipped pets...")
end)
newButton(progPage, "UnFavorite Equipped Now", function()
    task.spawn(function() setEquippedFavorite(false) end)
    notify("Yush Hub", "UnFavoriting equipped pets...")
end)

-- ── MISC PAGE ─────────────────────────────────────────────
local miscPage = tabPages["MISC"]

newSection(miscPage, "Performance")
newToggle(miscPage, "FPS Optimizer", "Removes shadows & reduces lag", false, function(v)
    Settings.FPSOptimizer = v
end)
newToggle(miscPage, "Hide Others' Pets", "Hides other players' pets locally", false, function(v)
    Settings.HideOtherPets = v
end)
newToggle(miscPage, "Hide Others' Eggs", "Hides other players' placed eggs", false, function(v)
    Settings.HideOtherEggs = v
end)
newToggle(miscPage, "Hide Your Pets", "Hides your own pets locally", false, function(v)
    Settings.HideYourPets = v
end)
newToggle(miscPage, "Hide Your Eggs", "Hides your own placed eggs locally", false, function(v)
    Settings.HideYourEggs = v
end)
newToggle(miscPage, "Hide Money Animations", "Removes floating money popups", false, function(v)
    Settings.HideMoneyAnim = v
end)
newSection(miscPage, "Utilities")
newToggle(miscPage, "Anti AFK", "Prevents auto-kick for inactivity", false, function(v)
    Settings.AntiAFK = v
end)
newButton(miscPage, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
end)
newButton(miscPage, "Reset Character", function()
    lp:LoadCharacter()
end)
newButton(miscPage, "Copy Server Job ID", function()
    if setclipboard then
        setclipboard(game.JobId)
        notify("Yush Hub", "Job ID copied: "..game.JobId:sub(1,8).."...")
    end
end)
newSection(miscPage, "Info")
newLabel(miscPage, "Yush Hub v2.0 — Made for Steal An Egg")
newLabel(miscPage, "Anti Knockback is always active globally.")

-- Open to FARM tab by default
selectTab("FARM")

-- Hide money animation hook
task.spawn(function()
    local terrain = workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.ChildAdded:Connect(function(c)
            if Settings.HideMoneyAnim and
               (c.Name == "SyncedIncomeCashAttachment" or c.Name == "SyncedIncomeCash") then
                c:Destroy()
            end
        end)
    end
end)

notify("Yush Hub", "Script loaded successfully! ✅")
