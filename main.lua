-- ================================
-- YUSH HUB | STEAL AN EGG SCRIPT
-- ================================

-- [[ ANTI CHEAT BYPASS ]]
local RunService = game:GetService("RunService")
if RunService:IsStudio() then return end
if RunService:IsServer() then return end

pcall(function()
    local fn = function() return true end
    local ok, r = pcall(debug.info, fn, "f")
    if not ok or r ~= fn then return end
    local ok2, r2 = pcall(debug.info, 2, "f")
    if not ok2 or r2 ~= pcall then return end
end)

-- [[ SERVICES ]]
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
local hum  = char:WaitForChild("Humanoid")

lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
    task.spawn(applyAntiKnockback)
end)

-- [[ FLAGS ]]
local Enabled = {
    AutoSteal      = false,
    AntiGuard      = false,
    AutoEquipBest  = false,
    AutoHatch      = false,
    AutoTreadmill  = false,
}

local FLIGHT_Y       = 88
local STEAL_SPEED    = 400
local RETURN_SPEED   = 450

-- ============================================================
-- [[ HELPERS ]]
-- ============================================================
local function getRemotes()
    local ok, r = pcall(require, ReplicatedStorage.Shared.Remotes)
    if ok then return r end
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

local rarityNum = {
    common=1, uncommon=2, rare=3, epic=4, legendary=5,
    mythic=6, cosmic=7, secret=8, eternal=9, divine=10,
    titan=11, ["light & dark"]=12,
}

local function getRarity(cat)
    if not cat then return 1 end
    local ok, assets = pcall(require, ReplicatedStorage.Data.Assets)
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
    pcall(function()
        local w = workspace:FindFirstChild("World")
        local a = w and w:FindFirstChild("Areas")
        local s = a and a:FindFirstChild("StartArea")
        if s and s:IsA("BasePart") then return s.Position + Vector3.new(0,3,0) end
        if s and s.PrimaryPart   then return s.PrimaryPart.Position + Vector3.new(0,3,0) end
    end)
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

local function tweenTo(target, speed)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end
    speed = speed or 350
    local dist = (target - h.Position).Magnitude
    if dist < 0.3 then return end
    local t = TweenService:Create(h,
        TweenInfo.new(dist / speed, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(target)}
    )
    t:Play(); t.Completed:Wait()
end

local function liftTo(y)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end
    h.CFrame = CFrame.new(h.Position.X, y, h.Position.Z)
    h.AssemblyLinearVelocity    = Vector3.zero
    h.AssemblyAngularVelocity   = Vector3.zero
end

-- ============================================================
-- [[ ANTI KNOCKBACK / RAGDOLL — ALWAYS ON ]]
-- ============================================================
function applyAntiKnockback()
    local c = lp.Character
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
        if (d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint"))
            and d.Name:find("Ragdoll") then
            task.defer(function() if d and d.Parent then pcall(d.Destroy,d) end end)
        elseif d:IsA("Motor6D") and not d.Enabled then
            task.defer(function() if d and d.Parent then d.Enabled = true end end)
        end
    end)
    -- block rig sync impulse
    pcall(function()
        local rem = getRemotes()
        if rem and rem.RigSync and rem.RigSync.Refresh and not _G._YH_RigHook then
            _G._YH_RigHook = true
            rem.RigSync.Refresh.OnClientEvent:Connect(function(data)
                if type(data) == "string" and
                   (data:find("BeginImpulse") or data:find("BeginRagdoll")) then
                    return
                end
            end)
        end
    end)
end

task.spawn(applyAntiKnockback)

-- ============================================================
-- [[ AUTO STEAL ]]
-- ============================================================
local function getBestEgg()
    local eggs = {}
    local eggState = getEggState()

    if eggState and eggState.ReadFieldEggs then
        local ok, rec = pcall(eggState.ReadFieldEggs)
        if ok and rec then
            local list = rec.Records or rec
            for _, e in pairs(type(list) == "table" and list or {}) do
                if e and e.Uid
                   and (e.State == "Slot" or e.State == "Dropped")
                   and not e.CarrierUserId then
                    table.insert(eggs, e)
                end
            end
        end
    end

    -- fallback: workspace slots
    local slotsFolder = workspace:FindFirstChild("AreaEggSlotsClient")
    if slotsFolder and #eggs == 0 then
        for _, slot in ipairs(slotsFolder:GetChildren()) do
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
    table.sort(eggs, function(a,b)
        return getRarity(a.AssetCategory) > getRarity(b.AssetCategory)
    end)
    return eggs[1]
end

local function isHoldingEgg()
    local c = lp.Character
    if not c then return false end
    for _, ch in ipairs(c:GetChildren()) do
        if ch:IsA("Tool") and ch:GetAttribute("ItemType") == "AssetEgg" then
            return true
        end
    end
    local pg = lp:FindFirstChild("PlayerGui")
    local dg = pg and pg:FindFirstChild("DropHeldEgg")
    return dg and dg.Enabled or false
end

local function grabEgg(uid, slotKey)
    local rem      = getRemotes()
    local eggState = getEggState()
    local deadline = os.clock() + 3.5

    while os.clock() < deadline do
        if isHoldingEgg() then return true end

        pcall(function()
            if eggState and eggState.CarryFieldEgg then
                eggState.CarryFieldEgg(uid, slotKey)
            end
        end)
        pcall(function()
            if rem and rem.EggWorld and rem.EggWorld.AskFieldEggCarry then
                rem.EggWorld.AskFieldEggCarry:InvokeServer({Uid=uid, FirstAreaSlotKey=slotKey})
            end
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
    task.wait(0.4)
    local plot = getPlot()
    if not plot then return end

    local rem      = getRemotes()
    local eggState = getEggState()
    local petArea  = plot.PetArea
    local center   = plot.CenterPoint

    -- get unplaced eggs
    local unplaced = {}
    local placed   = {}

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
            if v.OwnerUserId == lp.UserId then recs = v.Records or {}; break end
        end
        for k, v in pairs(recs) do
            if type(v)=="table" then
                if v.Placement then table.insert(placed, {uid=k, lc=v.Placement.LocalCFrame})
                else table.insert(unplaced, k) end
            end
        end
    end)

    if #unplaced == 0 then return end

    -- move to pen
    local penPos = petArea.Position + Vector3.new(0, 3, 0)
    local cPos   = center.Position  + Vector3.new(0, 3, 0)
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if h and (h.Position - cPos).Magnitude > 8 then tweenTo(cPos, 200) end
    tweenTo(penPos, 150)

    -- find free slot
    local function freeSlot()
        local sx = petArea.Size.X/2 - 3
        local sz = petArea.Size.Z/2 - 3
        for z = -sz, sz, 5 do
            for x = -sx, sx, 5 do
                local wp = petArea.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
                local ok = true
                for _, pl in ipairs(placed) do
                    if pl.lc and type(pl.lc)=="string" then
                        local nums={}
                        for n in pl.lc:gmatch("[-0-9%.e]+") do table.insert(nums,tonumber(n)) end
                        if #nums>=3 then
                            local pws = center.CFrame:ToWorldSpace(CFrame.new(unpack(nums))).Position
                            if (pws-wp).Magnitude < 5 then ok=false; break end
                        end
                    end
                end
                if ok then return wp, center.CFrame:ToObjectSpace(CFrame.new(wp)) end
            end
        end
        return nil, nil
    end

    for _, uid in ipairs(unplaced) do
        -- equip
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
                local rf  = net and net:FindFirstChild("RF/EggWorld/AskPlaceEgg")
                if rf then rf:InvokeServer({Uid=uid, LocalCFrame=lc}) end
            end
        end)
        table.insert(placed, {uid=uid, lc=tostring(lc)})

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
task.spawn(function()
    while task.wait(0.05) do
        if not Enabled.AutoSteal then continue end
        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not h then continue end

        -- lift up
        liftTo(FLIGHT_Y)
        task.wait(0.15)

        local egg = getBestEgg()
        if not egg then task.wait(1); continue end

        local pos = (egg.BottomCFrame or egg.BoundsCFrame) and
                    (egg.BottomCFrame or egg.BoundsCFrame).Position
        if not pos then task.wait(0.5); continue end

        -- fly horizontally above egg
        tweenTo(Vector3.new(pos.X, FLIGHT_Y, pos.Z), STEAL_SPEED)

        -- descend to egg
        local groundPos = Vector3.new(pos.X, pos.Y + 2.5, pos.Z)
        tweenTo(groundPos, 300)
        task.wait(0.1)

        -- grab
        local slotKey = egg.NestId and egg.AreaId
            and (egg.AreaId..":"..egg.NestId) or nil
        local got = grabEgg(egg.Uid, slotKey)

        if not got then task.wait(0.5); continue end

        -- lift back up
        h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then
            h.CFrame = CFrame.new(h.Position.X, FLIGHT_Y, h.Position.Z)
            h.AssemblyLinearVelocity  = Vector3.zero
            h.AssemblyAngularVelocity = Vector3.zero
        end
        task.wait(0.2)

        -- fly to safe zone
        local safe = getSafeZone()
        tweenTo(Vector3.new(safe.X, FLIGHT_Y, safe.Z), RETURN_SPEED)
        tweenTo(safe, 300)
        task.wait(0.3)

        -- auto place
        task.spawn(placeEggInField)
        task.wait(1)
    end
end)

-- ============================================================
-- [[ ANTI GUARD ]]
-- ============================================================
task.spawn(function()
    while task.wait(0.08) do
        if not Enabled.AntiGuard then continue end
        local c = lp.Character
        if not c then continue end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function() p.CanTouch = false end)
            end
        end
    end
end)

-- ============================================================
-- [[ AUTO EQUIP BEST ]]
-- ============================================================
task.spawn(function()
    while task.wait(5) do
        if not Enabled.AutoEquipBest then continue end
        pcall(function()
            local rem = getRemotes()
            if rem and rem.Haul and rem.Haul.WearBest then
                rem.Haul.WearBest:InvokeServer()
            end
        end)
    end
end)

-- ============================================================
-- [[ AUTO HATCH ]]
-- ============================================================
task.spawn(function()
    while task.wait(2) do
        if not Enabled.AutoHatch then continue end
        pcall(function()
            local es  = getEggState()
            local rem = getRemotes()
            if not es then return end
            local snap
            if rem and rem.EggWorld and rem.EggWorld.AskLiveSnapshot then
                snap = rem.EggWorld.AskLiveSnapshot:InvokeServer()
            elseif es.ReadOwnedEggs then snap = es.ReadOwnedEggs() end
            if not snap then return end
            local recs = {}
            for _, v in ipairs(type(snap)=="table" and snap or {}) do
                if v.OwnerUserId == lp.UserId then recs = v.Records or {}; break end
            end
            for k, v in pairs(recs) do
                if type(v)=="table" and v.Placement then
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
    end)
end

-- jump = exit treadmill
UserInputService.JumpRequest:Connect(function()
    if Enabled.AutoTreadmill and checkTreadmill() then
        exitTreadmill()
    end
end)

task.spawn(function()
    while task.wait(0.8) do
        if not Enabled.AutoTreadmill then
            if checkTreadmill() then exitTreadmill() end
            continue
        end
        if checkTreadmill() then continue end   -- already on it

        local plot = getPlot()
        if not plot or not plot.PlotFolder then continue end
        local tb = plot.PlotFolder:FindFirstChild("TreadmillBottom")
        if not tb then continue end

        local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not h then continue end

        local cPos = plot.CenterPoint and (plot.CenterPoint.Position + Vector3.new(0,3,0))
        if cPos and (h.Position - cPos).Magnitude > 8 then tweenTo(cPos, 150) end
        tweenTo(tb.Position + Vector3.new(0,3,0), 100)

        -- face treadmill
        h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if h then
            local lv = tb.CFrame.LookVector
            h.CFrame = CFrame.lookAt(h.Position, h.Position + lv)
            local hm = lp.Character:FindFirstChildOfClass("Humanoid")
            if hm then pcall(function() hm:Move(lv) end) end
        end
    end
end)

-- ============================================================
-- [[ UI ]]
-- ============================================================
local SG = Instance.new("ScreenGui")
SG.Name              = "YushHub"
SG.ResetOnSpawn      = false
SG.DisplayOrder      = 9999
SG.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset    = true
SG.Parent            = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

-- ── FPS/PING BAR ─────────────────────────────────────────
local HudF = Instance.new("Frame")
HudF.Name                   = "Hud"
HudF.Size                   = UDim2.new(0, 240, 0, 32)
HudF.Position               = UDim2.new(0.5, -120, 0, 8)
HudF.BackgroundColor3       = Color3.fromRGB(8, 10, 20)
HudF.BackgroundTransparency = 0.05
HudF.BorderSizePixel        = 0
HudF.Active                 = true
HudF.Draggable              = true
HudF.Parent                 = SG

Instance.new("UICorner", HudF).CornerRadius = UDim.new(0, 7)
local hs = Instance.new("UIStroke", HudF)
hs.Color = Color3.fromRGB(0, 200, 255); hs.Thickness = 1.2

local HudLbl = Instance.new("TextLabel", HudF)
HudLbl.Size                 = UDim2.new(1, 0, 1, 0)
HudLbl.BackgroundTransparency = 1
HudLbl.Font                 = Enum.Font.GothamBold
HudLbl.TextSize             = 12
HudLbl.TextColor3           = Color3.fromRGB(220, 230, 255)
HudLbl.RichText             = true
HudLbl.Text                 = "FPS: -- | PING: --ms"

local fpsCount, fpsFrames, fpsLast = 60, 0, os.clock()
RunService.RenderStepped:Connect(function()
    fpsFrames += 1
    local now = os.clock()
    if now - fpsLast >= 1 then
        fpsCount  = math.round(fpsFrames / (now - fpsLast))
        fpsFrames = 0
        fpsLast   = now
        local ping = 0
        pcall(function()
            local dp = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
            ping = math.round(dp:GetValue())
        end)
        HudLbl.Text = string.format(
            '<font color="#00FF88">FPS: %d</font>  |  <font color="#FFD700">PING: %dms</font>',
            fpsCount, ping)
    end
end)

-- ── MAIN WINDOW ──────────────────────────────────────────
local Win = Instance.new("Frame")
Win.Name                    = "Win"
Win.Size                    = UDim2.new(0, 240, 0, 40)
Win.Position                = UDim2.new(0.5, -120, 0, 46)
Win.BackgroundColor3        = Color3.fromRGB(8, 10, 20)
Win.BackgroundTransparency  = 0.05
Win.BorderSizePixel         = 0
Win.ClipsDescendants        = true
Win.Parent                  = SG

Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 8)
local ws = Instance.new("UIStroke", Win)
ws.Color = Color3.fromRGB(0, 200, 255); ws.Thickness = 1.2

-- title row
local TitleRow = Instance.new("Frame", Win)
TitleRow.Size                = UDim2.new(1, 0, 0, 40)
TitleRow.BackgroundTransparency = 1

local TitleLbl = Instance.new("TextLabel", TitleRow)
TitleLbl.Size                = UDim2.new(1, -48, 1, 0)
TitleLbl.Position            = UDim2.new(0, 10, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font                = Enum.Font.GothamBold
TitleLbl.TextSize            = 10
TitleLbl.TextColor3          = Color3.fromRGB(0, 215, 255)
TitleLbl.TextXAlignment      = Enum.TextXAlignment.Left
TitleLbl.Text                = "YUSH HUB  |  STEAL AN EGG"

local CollapseBtn = Instance.new("TextButton", TitleRow)
CollapseBtn.Size             = UDim2.new(0, 32, 0, 26)
CollapseBtn.Position         = UDim2.new(1, -38, 0, 7)
CollapseBtn.BackgroundColor3 = Color3.fromRGB(18, 24, 42)
CollapseBtn.BorderSizePixel  = 0
CollapseBtn.Font             = Enum.Font.GothamBold
CollapseBtn.TextSize         = 13
CollapseBtn.TextColor3       = Color3.fromRGB(0, 215, 255)
CollapseBtn.Text             = ">"
Instance.new("UICorner", CollapseBtn).CornerRadius = UDim.new(0, 6)

-- separator
local Sep = Instance.new("Frame", Win)
Sep.Size                 = UDim2.new(1, -20, 0, 1)
Sep.Position             = UDim2.new(0, 10, 0, 40)
Sep.BackgroundColor3     = Color3.fromRGB(0, 200, 255)
Sep.BackgroundTransparency = 0.5
Sep.BorderSizePixel      = 0

-- content
local Content = Instance.new("Frame", Win)
Content.Name             = "Content"
Content.Position         = UDim2.new(0, 0, 0, 44)
Content.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding           = UDim.new(0, 5)
Layout.SortOrder         = Enum.SortOrder.LayoutOrder

local Pad = Instance.new("UIPadding", Content)
Pad.PaddingLeft   = UDim.new(0, 8)
Pad.PaddingRight  = UDim.new(0, 8)
Pad.PaddingTop    = UDim.new(0, 5)
Pad.PaddingBottom = UDim.new(0, 8)

-- ── TOGGLE FACTORY ───────────────────────────────────────
local function newToggle(labelText, default, onChange)
    local row = Instance.new("Frame", Content)
    row.Size             = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = Color3.fromRGB(14, 18, 32)
    row.BorderSizePixel  = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", row)
    lbl.Size             = UDim2.new(1, -54, 1, 0)
    lbl.Position         = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 10
    lbl.TextColor3       = Color3.fromRGB(195, 210, 230)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text             = labelText

    local track = Instance.new("Frame", row)
    track.Size           = UDim2.new(0, 36, 0, 18)
    track.Position       = UDim2.new(1, -44, 0.5, -9)
    track.BackgroundColor3 = default
        and Color3.fromRGB(0, 175, 95)
        or  Color3.fromRGB(55, 60, 80)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size            = UDim2.new(0, 14, 0, 14)
    knob.Position        = default
        and UDim2.new(1, -16, 0.5, -7)
        or  UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = default or false
    local function set(v)
        state = v
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = state
                and Color3.fromRGB(0, 175, 95)
                or  Color3.fromRGB(55, 60, 80)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state
                and UDim2.new(1, -16, 0.5, -7)
                or  UDim2.new(0, 2, 0.5, -7)
        }):Play()
        onChange(state)
    end

    local btn = Instance.new("TextButton", row)
    btn.Size             = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.MouseButton1Click:Connect(function() set(not state) end)

    if default then onChange(true) end
    return row
end

newToggle("Auto Steal Egg",  false, function(v) Enabled.AutoSteal     = v end)
newToggle("Anti Guard",       false, function(v) Enabled.AntiGuard     = v end)
newToggle("Auto Equip Best",  false, function(v) Enabled.AutoEquipBest = v end)
newToggle("Auto Hatch",       false, function(v) Enabled.AutoHatch      = v end)
newToggle("Auto Treadmill",   false, function(v)
    Enabled.AutoTreadmill = v
    if not v then exitTreadmill() end
end)

-- resize content
local function resizeContent()
    Content.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 13)
end
Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeContent)
resizeContent()

-- ── COLLAPSE LOGIC ───────────────────────────────────────
local expanded = false
local H_CLOSED = 40

local function expandedH()
    return 44 + Content.AbsoluteSize.Y
end

CollapseBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    CollapseBtn.Text = expanded and "∨" or ">"
    TweenService:Create(Win, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 240, 0, expanded and expandedH() or H_CLOSED)
    }):Play()
end)

-- ── DRAG (title row) ─────────────────────────────────────
do
    local drag, ds, sp = false, nil, nil
    TitleRow.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; ds = i.Position; sp = Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            Win.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end
