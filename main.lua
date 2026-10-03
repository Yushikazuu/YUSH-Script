--[[
    YUSH HUB | Steal An Egg
    Made by https://t.me/PrimeYush :)
    Credits to @YushPogi
--]]

if not game then error("Run inside a Roblox executor.") end

-- ============================================================
-- SERVICES
-- ============================================================
local Players         = game:GetService("Players")
local RS              = game:GetService("ReplicatedStorage")
local RunService      = game:GetService("RunService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local LP              = Players.LocalPlayer
local bxor            = bit32.bxor

-- ============================================================
-- [1] GC HEAP SCANNER
-- ============================================================
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

-- ============================================================
-- [2] CLIENT DETECTION BYPASS
-- ============================================================
local function bypassClientDetections()
    if typeof(filtergc) ~= "function" or typeof(debug) ~= "table"
        or typeof(debug.getupvalues) ~= "function" then return end
    local ok, fn = pcall(function()
        return filtergc("function", { Constants = { "gmatch", "GetFullName" } }, true)
    end)
    if not ok or type(fn) ~= "function" then return end
    local setMeta = setrawmetatable or setmetatable
    if not setMeta then return end
    local okUv, ups = pcall(debug.getupvalues, fn)
    if not okUv or type(ups) ~= "table" then return end
    for _, tbl in pairs(ups) do
        if typeof(tbl) == "table" then
            pcall(setMeta, tbl, { __newindex = function() end })
        end
    end
end
pcall(bypassClientDetections)

-- ============================================================
-- [3] AC SLICES
-- ============================================================
local AcSlices = {}

function AcSlices.FreezeTables()
    local setmeta = setrawmetatable or setmetatable
    local getmeta = getrawmetatable or getmetatable
    if not setmeta then return end
    ScanGCHeap(function(obj)
        if typeof(obj) ~= "table" or (getmeta and getmeta(obj)) then return end
        local selfRef = false
        for _, v in pairs(obj) do if v == obj then selfRef = true; break end end
        if not selfRef then return end
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
    ScanGCHeap(function(fn)
        if typeof(fn) ~= "function" or not islclosure(fn) then return end
        local ok, src = pcall(debug.info, fn, "s")
        if not ok or type(src) ~= "string" then return end
        if not src:find("ReplicatedFirst", 1, true) or not src:find("UGI", 1, true) then return end
        local okC, consts = pcall(getconstants, fn)
        if not okC or type(consts) ~= "table" then return end
        for idx, c in next, consts do
            if type(c) == "string" and c == "Humanoid" then pcall(setconstant, fn, idx, "") end
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

task.spawn(function()
    pcall(AcSlices.FreezeTables); task.wait()
    pcall(AcSlices.WipeUGI);     task.wait()
    pcall(AcSlices.ScrubX14);    task.wait()
    pcall(AcSlices.SanitizeState)
end)

-- ============================================================
-- [4] BAC TELEMETRY SPOOFER
-- ============================================================
local remoteSet, anyRemote = {}, nil

local function isGuid(n)
    return #n==36 and n:sub(9,9)=="-" and n:sub(14,14)=="-"
        and n:sub(19,19)=="-" and n:sub(24,24)=="-"
        and n:gsub("-",""):match("^%x+$")~=nil
end

local function scanRemotes()
    for _, s in ipairs(game:GetChildren()) do
        local ok, list = pcall(s.GetDescendants, s)
        if ok and list then
            for _, o in ipairs(list) do
                if o:IsA("RemoteEvent") and isGuid(o.Name) then
                    remoteSet[o] = true; anyRemote = anyRemote or o
                end
            end
        end
    end
end
scanRemotes()

local function parseCounter(v)
    if type(v)~="string" then return end
    local n=v:match("^X%-(%d+)$"); return n and tonumber(n)
end

local function looksLikeState(t,r)
    if type(t)~="table" then return false end
    local hR,hM=false,false
    pcall(function()
        for _,v in pairs(t) do
            if v==r then hR=true
            elseif type(v)=="string" and v:match("^X%-%d+$") then hM=true end
        end
    end)
    return hR and hM
end

local function findState(r)
    for l=2,24 do
        local _,fn=pcall(debug.info,l,"f")
        if type(fn)=="function" then
            local _,ups=pcall(debug.getupvalues,fn)
            if type(ups)=="table" then
                for _,v in pairs(ups) do
                    if looksLikeState(v,r) then return v end
                    if type(v)=="table" then
                        local nested; pcall(function()
                            for _,x in pairs(v) do if looksLikeState(x,r) then nested=x; return end end
                        end)
                        if nested then return nested end
                    end
                end
            end
        end
    end
end

local function mapState(st,a1,a2)
    local m={}
    for k,v in pairs(st) do
        if type(v)=="string" then
            if v:match("^X%-%d+$")  then m.marker=m.marker or k
            elseif a1 and v==a1     then m.arg1=m.arg1 or k
            elseif a2 and v==a2     then m.arg2=m.arg2 or k end
        end
    end
    return m
end

local bac_model=nil
local function digits(n) n=n%1000; return math.floor(n/100),math.floor(n/10)%10,n%10 end
local function encode(m,c)
    local d1,d2,d3=digits(c)
    return m.prefix..string.char(bxor(d1,m.k1),bxor(d2,m.k2),bxor(d3,m.k3))
end
local function learn(r,a1,a2)
    local st=findState(r); if not st then return end
    local map=mapState(st,a1,a2); if not map.marker then return end
    local c=parseCounter(rawget(st,map.marker)); if not c then return end
    local d1,d2,d3=digits(c)
    local m={state=st,map=map,remote=r,prefix=a1:sub(1,9),
        k1=bxor(a1:byte(10),d1),k2=bxor(a1:byte(11),d2),k3=bxor(a1:byte(12),d3),
        offset=c-os.time(),arg2=a2}
    if encode(m,c)==a1 then return m end
end
local function liveCounter(m)
    if m.state and m.map.marker then
        local _,raw=pcall(rawget,m.state,m.map.marker)
        local c=parseCounter(raw)
        if c and math.abs((c-os.time())-m.offset)<=5 then return c end
    end
    return os.time()+m.offset
end
local function refreshArg2(m)
    if m.state and m.map.arg2 then
        local _,v=pcall(rawget,m.state,m.map.arg2)
        if type(v)=="string" then m.arg2=v end
    end
    return m.arg2
end

local HookFn=hookfunction or replaceclosure or hookfunc or detour_function
if anyRemote and HookFn then
    local oldFire
    oldFire=HookFn(anyRemote.FireServer,function(self,...)
        local args=table.pack(...)
        if not remoteSet[self] then return oldFire(self,table.unpack(args,1,args.n)) end
        local a1=args[1]
        if type(a1)=="string" and #a1==12 then
            if not bac_model then bac_model=learn(self,a1,args[2])
            else
                local c=parseCounter(rawget(bac_model.state,bac_model.map.marker))
                if c and encode(bac_model,c)~=a1 then
                    local m=learn(self,a1,args[2])
                    if m then m.spoofed=bac_model.spoofed; bac_model=m end
                end
            end
            return oldFire(self,table.unpack(args,1,args.n))
        end
        if bac_model and type(a1)=="string" and #a1==4 then
            local c=liveCounter(bac_model)
            args[1]=encode(bac_model,c); args[2]=refreshArg2(bac_model)
            bac_model.spoofed=(bac_model.spoofed or 0)+1
            return oldFire(self,table.unpack(args,1,math.max(args.n,2)))
        end
        return oldFire(self,table.unpack(args,1,args.n))
    end)
end

task.spawn(function()
    while true do
        task.wait(10)
        local alive=false
        for r in pairs(remoteSet) do if r:IsDescendantOf(game) then alive=true; break end end
        if not alive then table.clear(remoteSet); anyRemote=nil; bac_model=nil; scanRemotes() end
    end
end)

-- ============================================================
-- [5] EVIDENCE SCRUBBER
-- ============================================================
task.spawn(function()
    if not (getgc or (debug and debug.getgc)) then return end
    local st,misses=nil,0
    local function findIT()
        local found=nil
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
                local w=math.min(5*(2^math.min(misses-1,3)),30); local s=0
                while s<w do task.wait(0.5); s=s+0.5 end
            else misses=0 end
        end
        if st then pcall(function()
            local ev=rawget(st,"Evidence")
            if type(ev)=="table" then
                if (tonumber(ev.Speed) or 0)>0    then rawset(ev,"Speed",0) end
                if (tonumber(ev.Teleport) or 0)>0  then rawset(ev,"Teleport",0) end
                if (tonumber(ev.Flight) or 0)>0    then rawset(ev,"Flight",0) end
            end
            if rawget(st,"ThreatLevel")~="Trusted"     then rawset(st,"ThreatLevel","Trusted") end
            if rawget(st,"ValidationLocked")==true       then rawset(st,"ValidationLocked",false) end
            if rawget(st,"FirstSuspiciousAt")~=nil       then rawset(st,"FirstSuspiciousAt",nil) end
            if rawget(st,"KickQueued")==true             then rawset(st,"KickQueued",false) end
            if rawget(st,"TamperScore")~=nil             then rawset(st,"TamperScore",0) end
            if rawget(st,"InvalidHeartbeatCount")~=nil   then rawset(st,"InvalidHeartbeatCount",0) end
            local los=rawget(st,"LastObservedSample")
            if los~=nil then
                for _,key in ipairs({"LastGameplayTrustedSample","LastValidatedSample",
                    "LastValidatedGroundedSample","LastConfirmedGroundSample","LastGoodSample"}) do
                    if rawget(st,key)==nil then rawset(st,key,los) end
                end
            end
        end) end
        task.wait(0.2)
    end
end)

-- ============================================================
-- GAME MODULES
-- ============================================================
local EggState, AssetsData, RarityData, EggToolDisplay
pcall(function() EggState      = require(RS.Client.EggState) end)
pcall(function() AssetsData    = require(RS.Data.Assets) end)
pcall(function() RarityData    = require(RS.Data.Rarity) end)
pcall(function() EggToolDisplay= require(RS.Shared.Eggs.EggToolDisplay) end)

local function findRemote(name, fallback)
    local net = RS:FindFirstChild("Packages") and RS.Packages:FindFirstChild("Networking")
    local r = (net and (net:FindFirstChild(name,true) or net:FindFirstChild(name)))
           or RS:FindFirstChild(name,true)
    if not r and fallback then
        r = (net and (net:FindFirstChild(fallback,true) or net:FindFirstChild(fallback)))
         or RS:FindFirstChild(fallback,true)
    end
    return r
end

local CarryRemote = findRemote("RF/EggWorld/AskFieldEggCarry","AskFieldEggCarry")

-- Prompt hold bypass
pcall(function()
    local pps = game:GetService("ProximityPromptService")
    pps.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player == LP then prompt.HoldDuration = 0 end
    end)
end)

-- Cancel purchase popups
pcall(function()
    game:GetService("CoreGui").ChildAdded:Connect(function(child)
        if child.Name == "PurchasePrompt" then
            task.wait(0.04)
            local cancel = child:FindFirstChild("CancelButton", true)
            if cancel and cancel:IsA("GuiButton") then
                pcall(function() cancel.MouseButton1Click:Fire() end)
            end
        end
    end)
end)

-- ============================================================
-- RARITY TABLES
-- ============================================================
local RARITY_SCORE = {
    ["Light & Dark"]=1300,["Titan"]=1100,["Divine"]=1000,["Transcendent"]=1000,
    ["Superior"]=1000,["Eternal"]=900,["Limited"]=900,["Secret"]=800,["Exotic"]=800,
    ["Cosmic"]=700,["Exclusive"]=700,["Admin"]=700,["Mythic"]=600,["Mythical"]=600,
    ["Prismatic"]=600,["Rainbow"]=600,["Legendary"]=500,["Epic"]=400,
    ["Rare"]=300,["Uncommon"]=200,["Common"]=100,
}
local RARITY_COLOR = {
    ["Light & Dark"]=Color3.fromRGB(255,255,255),
    ["Titan"]=Color3.fromRGB(255,140,0),
    ["Divine"]=Color3.fromRGB(244,63,94),
    ["Eternal"]=Color3.fromRGB(217,70,239),
    ["Secret"]=Color3.fromRGB(249,115,22),
    ["Cosmic"]=Color3.fromRGB(6,182,212),
    ["Mythic"]=Color3.fromRGB(139,92,246),
    ["Legendary"]=Color3.fromRGB(251,191,36),
    ["Epic"]=Color3.fromRGB(168,85,247),
    ["Rare"]=Color3.fromRGB(59,130,246),
    ["Uncommon"]=Color3.fromRGB(34,197,94),
    ["Common"]=Color3.fromRGB(148,163,184),
}

local function rarityOf(record)
    if not record then return "Common",100 end
    local r = record.Rarity
    if r then
        local name = type(r)=="table" and (r.DisplayName or r._id or r.Name) or tostring(r)
        return name, RARITY_SCORE[name] or 100
    end
    return "Common",100
end

-- ============================================================
-- PET PREDICTION
-- ============================================================
local function assetsDir()
    if not AssetsData then return nil end
    return AssetsData.Directory or AssetsData.Assets or AssetsData
end

local function norm(s) return tostring(s or ""):lower():gsub("[%s_%-%.]","") end

local function assetInfo(cat)
    local dir = assetsDir(); if not dir or cat=="" then return nil end
    if dir[cat] then return dir[cat] end
    local key = norm(cat)
    for k, v in pairs(dir) do
        if norm(k)==key then return v end
        if type(v)=="table" and (norm(v.DisplayName)==key or norm(v.Name)==key or norm(v._id)==key) then
            return v
        end
    end
    return nil
end

local function imageId(v)
    if not v or v=="" then return "" end
    if type(v)=="number" then return "rbxassetid://"..tostring(v) end
    local t=tostring(v)
    if t:match("^%d+$") then return "rbxassetid://"..t end
    return t
end

local function predictPet(record)
    if not record then return "Unknown","" end
    local cat = tostring(record.AssetCategory or record.Category or record.Name or "")
    local info = assetInfo(cat)
    local petName, icon = cat, ""
    if type(info)=="table" then
        petName = info.DisplayName or info.Name or cat
        icon    = imageId(info.Icon or info.Image or info.Thumbnail or "")
        if type(info.Pet)=="table" then
            petName = info.Pet.DisplayName or info.Pet.Name or petName
            icon    = imageId(info.Pet.Icon or info.Pet.Image or icon)
        end
        if type(info.Animal)=="table" then
            petName = info.Animal.DisplayName or info.Animal.Name or petName
            icon    = imageId(info.Animal.Icon or info.Animal.Image or icon)
        end
    end
    -- Nice-format fallback
    if petName == cat then
        petName = cat:gsub("(%l)(%u)","%1 %2"):gsub("_"," ")
    end
    return petName, icon
end

-- ============================================================
-- MONEY FORMATTING
-- ============================================================
local function fmt(n)
    n = tonumber(n) or 0
    if n>=1e15 then return string.format("%.2fQ",n/1e15) end
    if n>=1e12 then return string.format("%.2fT",n/1e12) end
    if n>=1e9  then return string.format("%.2fB",n/1e9)  end
    if n>=1e6  then return string.format("%.2fM",n/1e6)  end
    if n>=1e3  then return string.format("%.1fK",n/1e3)  end
    return tostring(math.floor(n))
end

local function eggValue(record)
    local cat = tostring(record.AssetCategory or record.Category or "")
    local info = assetInfo(cat)
    local raw = 0
    if type(info)=="table" then
        raw = tonumber(info.Money or info.Cash or info.Income or info.EarningRate or info.Price or 0) or 0
    end
    if raw <= 0 then
        local _, score = rarityOf(record); raw = score * 10000
    end
    local scale = tonumber(record.AssetScale or record.Scale or 1) or 1
    local mult  = 1
    local muts  = record.Mutations or {}
    if type(muts)=="table" then
        for _, m in ipairs(muts) do
            local t=tostring(m):lower()
            if t:find("rainbow") then mult=mult*3
            elseif t:find("gold") then mult=mult*2
            elseif t:find("silver") then mult=mult*1.5 end
        end
    end
    if record.HasParasite then mult=mult*5 end
    return raw * scale * mult
end

-- ============================================================
-- BEST EGG SCANNER
-- ============================================================
local function getBestEgg()
    if not EggState or not EggState.ReadFieldEggs then return nil end
    local ok, snap = pcall(EggState.ReadFieldEggs)
    if not ok or not snap then return nil end
    local records = snap.Records or snap
    if type(records) ~= "table" then return nil end

    local best, bestScore = nil, -1
    for _, rec in pairs(records) do
        if type(rec)=="table" and rec.BoundsCFrame
            and (rec.State=="Slot" or rec.State==nil or rec.State==0) then
            local _, rScore = rarityOf(rec)
            local muts = rec.Mutations or {}
            local bonus = 0
            if type(muts)=="table" then
                for _, m in ipairs(muts) do
                    local t=tostring(m):lower()
                    if t:find("rainbow") then bonus=bonus+500
                    elseif t:find("gold") then bonus=bonus+200
                    elseif t:find("silver") then bonus=bonus+100 end
                end
            end
            if rec.HasParasite then bonus=bonus+1000 end
            local scale = tonumber(rec.AssetScale or 1) or 1
            if scale>=1.35 then bonus=bonus+600 end
            local score = rScore + bonus + (eggValue(rec)/1e6)
            if score > bestScore then best=rec; bestScore=score end
        end
    end
    return best
end

-- ============================================================
-- STEAL ENGINE
-- ============================================================
local DEAD     = false
local loopOn   = false
local tpMode   = true   -- teleport (true) or glide (false)
local busy     = false
local ignored  = {}

local function findHRP()
    local ch=LP.Character
    return ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
end
local function findHum()
    local ch=LP.Character
    return ch and ch:FindFirstChildOfClass("Humanoid")
end

local function suppressRagdoll()
    local ch=LP.Character; if not ch then return end
    local hum=ch:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
        if hum.PlatformStand then hum.PlatformStand=false end
    end
    for _, d in ipairs(ch:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint") then
            pcall(function() d:Destroy() end)
        end
    end
end

local function neutralizeTraps()
    local debris=workspace:FindFirstChild("__DEBRIS"); if not debris then return end
    for _, d in ipairs(debris:GetChildren()) do
        if d.Name=="PlayerTrap" and d:GetAttribute("Owner")~=LP.Name then
            if d:IsA("BasePart") then d.CanTouch=false; d.CanQuery=false end
            for _, c in ipairs(d:GetChildren()) do
                if c:IsA("BasePart") then
                    c.CanTouch=false; c.CanQuery=false
                    if c.Name=="Hitbox" then c.CFrame=CFrame.new(0,-999,0) end
                end
            end
        end
    end
end

local statusText = "Idle"

local function triggerPrompts(model, pos)
    if model then
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                pcall(function()
                    p.HoldDuration=0; p.RequiresLineOfSight=false
                    if typeof(fireproximityprompt)=="function" then fireproximityprompt(p,0) end
                end)
            end
        end
    end
    local slots=workspace:FindFirstChild("AreaEggSlotsClient"); if not slots then return end
    for _, m in ipairs(slots:GetChildren()) do
        local part = m:FindFirstChildWhichIsA("BasePart") or m.PrimaryPart
        if part and (part.Position-pos).Magnitude<=18 then
            for _, p in ipairs(m:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    pcall(function()
                        p.HoldDuration=0; p.RequiresLineOfSight=false
                        if typeof(fireproximityprompt)=="function" then fireproximityprompt(p,0) end
                    end)
                end
            end
        end
    end
end

local function hasEgg(uid)
    for _, container in ipairs({LP.Character, LP:FindFirstChild("Backpack")}) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    local tuid = tool:GetAttribute("UID") or tool:GetAttribute("EggUid")
                    if tostring(tuid)==tostring(uid) then return true end
                end
            end
        end
    end
    return false
end

local function fireCarry(uid)
    if not CarryRemote then return end
    pcall(function()
        if CarryRemote:IsA("RemoteFunction") then
            CarryRemote:InvokeServer({Uid=uid})
        else
            CarryRemote:FireServer({Uid=uid})
        end
    end)
end

local function stealEgg(record)
    if busy or not record or not record.Uid or not record.BoundsCFrame then return false end
    if ignored[record.Uid] and (os.clock()-ignored[record.Uid])<4 then return false end

    local root = findHRP()
    local hum  = findHum()
    if not root or not hum then return false end

    busy = true
    local uid = record.Uid
    local targetCF = record.BoundsCFrame
    local targetPos = targetCF.Position

    statusText = "Streaming area..."
    pcall(function() LP:RequestStreamAroundAsync(targetPos) end)

    -- Safety floor
    local floor = Instance.new("Part")
    floor.Size = Vector3.new(24,1,24)
    floor.CFrame = CFrame.new(targetPos-Vector3.new(0,3.5,0))
    floor.Anchored = true; floor.Transparency = 1; floor.CanCollide = true
    floor.Parent = workspace
    task.delay(10, function() pcall(function() floor:Destroy() end) end)

    suppressRagdoll()
    neutralizeTraps()

    if tpMode then
        -- TELEPORT MODE
        statusText = "Teleporting..."
        root.CFrame = targetCF * CFrame.new(0,0.4,0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.05)
    else
        -- GLIDE MODE
        statusText = "Gliding..."
        local start = root.Position
        local dist  = (targetPos - start).Magnitude
        local speed = 750
        local t0    = os.clock()
        while (os.clock()-t0) < (dist/speed + 2) and not DEAD do
            local dt = RunService.Heartbeat:Wait()
            local curPos = root.Position
            local diff   = targetPos - curPos
            if diff.Magnitude < 3 then break end
            local step   = math.min(speed*dt, diff.Magnitude)
            local newPos = curPos + diff.Unit * step
            root.CFrame = CFrame.lookAt(newPos, newPos + diff.Unit)
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end

    -- Find physical model
    local physModel = record.PhysicalModel
    if not physModel then
        local slots = workspace:FindFirstChild("AreaEggSlotsClient")
        if slots then
            for _, m in ipairs(slots:GetChildren()) do
                if m.Name==uid or m:GetAttribute("UID")==uid or m:GetAttribute("Uid")==uid then
                    physModel = m; break
                end
            end
        end
    end

    statusText = "Picking up..."
    local deadline = os.clock() + 3
    local lastFire = 0
    while os.clock() < deadline and not DEAD do
        if hasEgg(uid) then
            statusText = "Secured! ✓"
            busy = false
            return true
        end
        triggerPrompts(physModel, targetPos)
        local now = os.clock()
        if now - lastFire >= 0.15 then
            lastFire = now
            fireCarry(uid)
        end
        RunService.Heartbeat:Wait()
    end

    ignored[uid] = os.clock()
    statusText = "Missed — retrying..."
    busy = false
    return false
end

-- ============================================================
-- GUI BUILDER  (Lennon Hub / YUSH HUB style)
-- ============================================================
local function getGuiParent()
    local p
    pcall(function() if typeof(gethui)=="function" then p=gethui() end end)
    if not p then pcall(function() p=game:GetService("CoreGui") end) end
    if not p then p=LP:FindFirstChildOfClass("PlayerGui") end
    return p or workspace
end

local guiParent = getGuiParent()
local oldGui = guiParent:FindFirstChild("YushHub_SAE")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name          = "YushHub_SAE"
ScreenGui.ResetOnSpawn  = false
ScreenGui.IgnoreGuiInset= true
ScreenGui.ZIndexBehavior= Enum.ZIndexBehavior.Global
pcall(function() ScreenGui.DisplayOrder=999999 end)
ScreenGui.Parent = guiParent

-- ── CARD ────────────────────────────────────────────────────
local Card = Instance.new("Frame")
Card.Name            = "Card"
Card.Size            = UDim2.fromOffset(225, 195)
Card.Position        = UDim2.fromOffset(12, 70)
Card.BackgroundColor3= Color3.fromRGB(10, 12, 20)
Card.BorderSizePixel = 0
Card.Active          = true
Card.Parent          = ScreenGui
Instance.new("UICorner", Card).CornerRadius = UDim.new(0,14)

local CardGrad = Instance.new("UIGradient")
CardGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15,17,28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25,12,38)),
})
CardGrad.Rotation = 140
CardGrad.Parent = Card

local CardStroke = Instance.new("UIStroke")
CardStroke.Thickness   = 1.8
CardStroke.Color       = Color3.fromRGB(200,30,40)
CardStroke.Transparency= 0.1
CardStroke.Parent      = Card
local StrokeGrad = Instance.new("UIGradient")
StrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,50,60)),
    ColorSequenceKeypoint.new(0.33,Color3.fromRGB(255,120,50)),
    ColorSequenceKeypoint.new(0.66,Color3.fromRGB(120,50,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,50,60)),
})
StrokeGrad.Rotation = 0
StrokeGrad.Parent = CardStroke

-- ── HEADER ──────────────────────────────────────────────────
local Header = Instance.new("Frame")
Header.Size            = UDim2.new(1,0,0,28)
Header.BackgroundColor3= Color3.fromRGB(175,22,32)
Header.BorderSizePixel = 0
Header.ZIndex          = 2
Header.Parent          = Card
Instance.new("UICorner", Header).CornerRadius = UDim.new(0,14)
-- Patch bottom corners
local HFix = Instance.new("Frame")
HFix.Size            = UDim2.new(1,0,0.5,0)
HFix.Position        = UDim2.new(0,0,0.5,0)
HFix.BackgroundColor3= Color3.fromRGB(175,22,32)
HFix.BorderSizePixel = 0
HFix.ZIndex          = 2
HFix.Parent          = Header

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Text              = "YUSH HUB"
TitleLbl.Size              = UDim2.new(1,-36,1,0)
TitleLbl.Position          = UDim2.fromOffset(10,0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font              = Enum.Font.GothamBlack
TitleLbl.TextSize          = 12
TitleLbl.TextColor3        = Color3.fromRGB(255,255,255)
TitleLbl.TextXAlignment    = Enum.TextXAlignment.Left
TitleLbl.ZIndex            = 3
TitleLbl.Parent            = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text              = "×"
CloseBtn.Size              = UDim2.fromOffset(20,20)
CloseBtn.Position          = UDim2.new(1,-24,0.5,-10)
CloseBtn.BackgroundColor3  = Color3.fromRGB(60,10,15)
CloseBtn.BorderSizePixel   = 0
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextSize          = 14
CloseBtn.TextColor3        = Color3.fromRGB(255,255,255)
CloseBtn.ZIndex            = 4
CloseBtn.Parent            = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,5)

-- ── EGG CARD BODY ───────────────────────────────────────────
local Body = Instance.new("Frame")
Body.Size            = UDim2.new(1,-16,0,100)
Body.Position        = UDim2.fromOffset(8,34)
Body.BackgroundColor3= Color3.fromRGB(6,8,16)
Body.BorderSizePixel = 0
Body.Parent          = Card
Instance.new("UICorner", Body).CornerRadius = UDim.new(0,10)
local BodyStroke = Instance.new("UIStroke")
BodyStroke.Color       = Color3.fromRGB(35,35,55)
BodyStroke.Thickness   = 1
BodyStroke.Parent      = Body

-- "BEST EGG" header row
local BestEggLbl = Instance.new("TextLabel")
BestEggLbl.Text             = "BEST EGG"
BestEggLbl.Size             = UDim2.new(1,0,0,14)
BestEggLbl.Position         = UDim2.fromOffset(8,5)
BestEggLbl.BackgroundTransparency= 1
BestEggLbl.Font             = Enum.Font.GothamBold
BestEggLbl.TextSize         = 8
BestEggLbl.TextColor3       = Color3.fromRGB(130,135,165)
BestEggLbl.TextXAlignment   = Enum.TextXAlignment.Left
BestEggLbl.Parent           = Body

-- Egg icon box
local IconBox = Instance.new("Frame")
IconBox.Size            = UDim2.fromOffset(44,44)
IconBox.Position        = UDim2.fromOffset(6,20)
IconBox.BackgroundColor3= Color3.fromRGB(18,20,32)
IconBox.BorderSizePixel = 0
IconBox.Parent          = Body
Instance.new("UICorner", IconBox).CornerRadius = UDim.new(0,8)
local IconStroke = Instance.new("UIStroke")
IconStroke.Color    = Color3.fromRGB(50,50,80)
IconStroke.Thickness= 1
IconStroke.Parent   = IconBox

local EggImg = Instance.new("ImageLabel")
EggImg.Size                 = UDim2.fromScale(0.82,0.82)
EggImg.Position             = UDim2.fromScale(0.09,0.09)
EggImg.BackgroundTransparency= 1
EggImg.Image                = ""
EggImg.ScaleType            = Enum.ScaleType.Fit
EggImg.Parent               = IconBox

-- Pet name (main)
local PetNameLbl = Instance.new("TextLabel")
PetNameLbl.Name             = "PetName"
PetNameLbl.Text             = "Scanning..."
PetNameLbl.Size             = UDim2.new(1,-62,0,22)
PetNameLbl.Position         = UDim2.fromOffset(56,18)
PetNameLbl.BackgroundTransparency= 1
PetNameLbl.Font             = Enum.Font.GothamBold
PetNameLbl.TextSize         = 13
PetNameLbl.TextColor3       = Color3.fromRGB(240,242,255)
PetNameLbl.TextXAlignment   = Enum.TextXAlignment.Left
PetNameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
PetNameLbl.Parent           = Body

-- Value
local ValueLbl = Instance.new("TextLabel")
ValueLbl.Name               = "Value"
ValueLbl.Text               = "--"
ValueLbl.Size               = UDim2.new(1,-62,0,15)
ValueLbl.Position           = UDim2.fromOffset(56,40)
ValueLbl.BackgroundTransparency= 1
ValueLbl.Font               = Enum.Font.GothamSemibold
ValueLbl.TextSize           = 10
ValueLbl.TextColor3         = Color3.fromRGB(255,200,70)
ValueLbl.TextXAlignment     = Enum.TextXAlignment.Left
ValueLbl.Parent             = Body

-- Rarity pill
local RarityPill = Instance.new("Frame")
RarityPill.Size            = UDim2.fromOffset(58,16)
RarityPill.Position        = UDim2.fromOffset(56,58)
RarityPill.BackgroundColor3= Color3.fromRGB(139,92,246)
RarityPill.BorderSizePixel = 0
RarityPill.Parent          = Body
Instance.new("UICorner", RarityPill).CornerRadius = UDim.new(1,0)
local RarityLbl = Instance.new("TextLabel")
RarityLbl.Text             = "Common"
RarityLbl.Size             = UDim2.fromScale(1,1)
RarityLbl.BackgroundTransparency= 1
RarityLbl.Font             = Enum.Font.GothamBold
RarityLbl.TextSize         = 8
RarityLbl.TextColor3       = Color3.fromRGB(255,255,255)
RarityLbl.Parent           = RarityPill

-- Status bar
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Text             = "Idle"
StatusLbl.Size             = UDim2.new(1,-12,0,12)
StatusLbl.Position         = UDim2.fromOffset(6,84)
StatusLbl.BackgroundTransparency= 1
StatusLbl.Font             = Enum.Font.Gotham
StatusLbl.TextSize         = 8
StatusLbl.TextColor3       = Color3.fromRGB(100,110,140)
StatusLbl.TextXAlignment   = Enum.TextXAlignment.Left
StatusLbl.Parent           = Body

-- ── TOGGLE ROW (TELEPORT + LOOP) ────────────────────────────
local function makeRow(parent, yPos, label, defaultOn, callback)
    local row = Instance.new("Frame")
    row.Size            = UDim2.new(1,-16,0,28)
    row.Position        = UDim2.fromOffset(8, yPos)
    row.BackgroundColor3= Color3.fromRGB(6,8,16)
    row.BorderSizePixel = 0
    row.Parent          = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color    = Color3.fromRGB(35,35,55)
    rowStroke.Thickness= 1
    rowStroke.Parent   = row

    local lbl = Instance.new("TextLabel")
    lbl.Text             = label
    lbl.Size             = UDim2.new(1,-52,1,0)
    lbl.Position         = UDim2.fromOffset(8,0)
    lbl.BackgroundTransparency= 1
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextSize         = 10
    lbl.TextColor3       = Color3.fromRGB(200,205,230)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = row

    local state = defaultOn

    local bg = Instance.new("Frame")
    bg.Size            = UDim2.fromOffset(36,18)
    bg.Position        = UDim2.new(1,-44,0.5,-9)
    bg.BackgroundColor3= state and Color3.fromRGB(34,197,94) or Color3.fromRGB(38,38,58)
    bg.BorderSizePixel = 0
    bg.Parent          = row
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size            = UDim2.fromOffset(13,13)
    knob.Position        = state and UDim2.fromOffset(20,2.5) or UDim2.fromOffset(2.5,2.5)
    knob.BackgroundColor3= Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.Parent          = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    -- Checkmark label (like Lennon Hub)
    local checkLbl = Instance.new("TextLabel")
    checkLbl.Text             = state and "✔" or ""
    checkLbl.Size             = UDim2.fromOffset(18,18)
    checkLbl.Position         = UDim2.new(1,-66,0.5,-9)
    checkLbl.BackgroundTransparency= 1
    checkLbl.Font             = Enum.Font.GothamBold
    checkLbl.TextSize         = 10
    checkLbl.TextColor3       = Color3.fromRGB(34,197,94)
    checkLbl.Parent           = row

    local btn = Instance.new("TextButton")
    btn.Size               = UDim2.fromScale(1,1)
    btn.BackgroundTransparency= 1
    btn.Text               = ""
    btn.Parent             = row

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(bg, TweenInfo.new(0.18),{
            BackgroundColor3= state and Color3.fromRGB(34,197,94) or Color3.fromRGB(38,38,58)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18),{
            Position= state and UDim2.fromOffset(20,2.5) or UDim2.fromOffset(2.5,2.5)
        }):Play()
        checkLbl.Text = state and "✔" or ""
        callback(state)
    end)

    return row
end

makeRow(Card, 140, "TELEPORT", true, function(on)
    tpMode = on
    statusText = on and "Teleport mode" or "Glide mode"
end)

makeRow(Card, 172, "LOOP", false, function(on)
    loopOn = on
    statusText = on and "Loop started..." or "Idle"
end)

-- ── DRAG ────────────────────────────────────────────────────
local dragging, dragStart, startPos = false, nil, nil
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Card.Position
    end
end)
Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement
        or input.UserInputType==Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Card.Position = UDim2.fromOffset(startPos.X.Offset+d.X, startPos.Y.Offset+d.Y)
    end
end)

-- ── CLOSE ───────────────────────────────────────────────────
CloseBtn.MouseButton1Click:Connect(function()
    DEAD = true; loopOn = false
    TweenService:Create(Card, TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.In), {
        Size=UDim2.fromOffset(0,0),
        Position=Card.Position+UDim2.fromOffset(112,97)
    }):Play()
    task.delay(0.25, function() pcall(function() ScreenGui:Destroy() end) end)
end)

-- ── ENTRY ANIMATION ─────────────────────────────────────────
Card.Size     = UDim2.fromOffset(0,0)
Card.Position = UDim2.fromOffset(124, 167)
TweenService:Create(Card, TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Size     = UDim2.fromOffset(225,195),
    Position = UDim2.fromOffset(12,70)
}):Play()

-- ── RARITY PILL PULSE ───────────────────────────────────────
task.spawn(function()
    while not DEAD do
        TweenService:Create(RarityPill,TweenInfo.new(0.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
            BackgroundTransparency=0.35
        }):Play()
        task.wait(0.65)
        TweenService:Create(RarityPill,TweenInfo.new(0.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
            BackgroundTransparency=0
        }):Play()
        task.wait(0.65)
    end
end)

-- ── STROKE ROTATION ─────────────────────────────────────────
task.spawn(function()
    while not DEAD do
        StrokeGrad.Rotation = (StrokeGrad.Rotation + 1.2) % 360
        task.wait(0.016)
    end
end)

-- ── VALUE COUNTER ANIMATION ─────────────────────────────────
local displayedValue = 0
task.spawn(function()
    while not DEAD do
        local target = displayedValue
        -- smooth tick toward target
        task.wait(0.04)
    end
end)

-- ============================================================
-- MAIN UPDATE LOOP
-- ============================================================
local lastScan  = 0
local lastSteal = 0
local currentRecord = nil

RunService.Heartbeat:Connect(function()
    if DEAD then return end

    -- UI status sync
    StatusLbl.Text = statusText

    -- Scan every 0.5s
    if os.clock() - lastScan >= 0.5 then
        lastScan = os.clock()
        local egg = getBestEgg()
        if egg then
            currentRecord = egg
            local rName, _ = rarityOf(egg)
            local val      = eggValue(egg)
            displayedValue = val

            -- Smooth value animation
            local current = tonumber(ValueLbl.Text:match("[%d%.]+") or "0") or 0
            local displayVal = current + (val - current) * 0.35
            ValueLbl.Text = "$" .. fmt(displayVal) .. "/s"

            -- Pet prediction
            local petName, petIcon = predictPet(egg)
            PetNameLbl.Text = petName

            -- Rarity pill
            local pillColor = RARITY_COLOR[rName] or Color3.fromRGB(148,163,184)
            RarityLbl.Text  = rName
            TweenService:Create(RarityPill, TweenInfo.new(0.25), {
                BackgroundColor3 = pillColor
            }):Play()

            -- Egg icon
            if petIcon and petIcon ~= "" then
                EggImg.Image = petIcon
                EggImg.ImageColor3 = Color3.fromRGB(255,255,255)
            else
                EggImg.Image      = ""
                EggImg.ImageColor3= pillColor
            end

            -- Color-tint body stroke to rarity
            TweenService:Create(BodyStroke, TweenInfo.new(0.4), {
                Color = pillColor
            }):Play()

            if statusText == "Idle" or statusText == "Scanning..." then
                statusText = "Target locked"
                StatusLbl.TextColor3 = Color3.fromRGB(100,220,120)
            end
        else
            currentRecord        = nil
            PetNameLbl.Text      = "No eggs found"
            ValueLbl.Text        = "--"
            RarityLbl.Text       = "---"
            StatusLbl.TextColor3 = Color3.fromRGB(100,110,140)
            if statusText == "Target locked" then statusText = "Scanning..." end
        end
    end

    -- Steal loop
    if loopOn and not busy and currentRecord and (os.clock()-lastSteal >= 0.7) then
        lastSteal = os.clock()
        task.spawn(function()
            local ok = stealEgg(currentRecord)
            if ok then
                StatusLbl.TextColor3 = Color3.fromRGB(80,220,100)
            end
        end)
    end
end)

print("[YUSH HUB] Steal An Egg ready. Made by https://t.me/PrimeYush :)")
