local Scan = WowVision.minimapScan

-- The minimap scanner's game half: moving Blizzard's minimap under the
-- resting mouse cursor and reading what the game names there.
--
-- No API lists minimap dots, but C_TooltipInfo.GetMinimapMouseover names
-- the ones under the cursor. Two ways to use that:
-- - shrunk: the minimap squeezed to a few pixels with its centre on the
--   cursor puts every dot in range under it, so one read names them all
--   (the walking check, and the sorting passes);
-- - at a point: the minimap at full size under the cursor, and
--   Minimap:UpdateMouseoverAtPoint (WoW: Forever) asks any point of it;
--   the points where a name answers give its offset from the player.
-- Tracking types switched one at a time sort the names (see logic.lua).
--
-- Everything the scan changes (points, size, alpha, zoom, tracking) is
-- captured first and restored at the end, on abort and on error. The
-- minimap is not a protected frame; the scanner still keeps out of
-- combat.

local Engine = {}
Scan.engine = Engine

local SHRUNK_SIZE = 15

function Engine.available()
    return C_TooltipInfo ~= nil
        and C_TooltipInfo.GetMinimapMouseover ~= nil
        and C_Minimap ~= nil
        and C_Minimap.GetViewRadius ~= nil
        and C_Minimap.GetTrackingInfo ~= nil
        and C_Minimap.GetTrackingFilter ~= nil
        and Minimap ~= nil
        and Minimap.UpdateMouseoverAtPoint ~= nil
end

function Engine.readDots()
    local ok, data = pcall(C_TooltipInfo.GetMinimapMouseover)
    if not ok then
        return {}
    end
    return Scan.parseMouseover(data, WowVision.isSecret)
end

-- Every tracking type: index, name, active, spell or filter, filter id
-- and name (Enum.MinimapTrackingFilter).
local filterNames = nil
function Engine.trackingTypes()
    if filterNames == nil then
        filterNames = {}
        for name, value in pairs(Enum.MinimapTrackingFilter or {}) do
            filterNames[value] = name
        end
    end
    local types = {}
    for index = 1, C_Minimap.GetNumTrackingTypes() do
        local info = C_Minimap.GetTrackingInfo(index)
        if info ~= nil then
            local filter = C_Minimap.GetTrackingFilter(index)
            tinsert(types, {
                index = index,
                name = tostring(info.name),
                active = info.active and true or false,
                isSpell = info.type == "spell",
                spellID = info.spellID,
                filterID = filter ~= nil and filter.filterID or nil,
                filter = filter ~= nil and filter.filterID ~= nil and filterNames[filter.filterID] or nil,
            })
        end
    end
    return types
end

-- withTracking false skips the tracking list (the walking check never
-- switches tracking).
function Engine.capture(withTracking)
    local points = {}
    for i = 1, Minimap:GetNumPoints() do
        points[i] = { Minimap:GetPoint(i) }
    end
    local width, height = Minimap:GetSize()
    return {
        points = points,
        width = width,
        height = height,
        alpha = Minimap:GetAlpha(),
        zoom = Minimap:GetZoom(),
        tracking = withTracking ~= false and Engine.trackingTypes() or {},
    }
end

-- Frame state only; tracking is restored separately (restoreTracking),
-- because the presence check never touches it.
function Engine.restoreFrame(state)
    pcall(Minimap.SetSize, Minimap, state.width, state.height)
    pcall(Minimap.SetAlpha, Minimap, state.alpha)
    pcall(Minimap.ClearAllPoints, Minimap)
    for _, point in ipairs(state.points) do
        pcall(Minimap.SetPoint, Minimap, unpack(point))
    end
    pcall(Minimap.SetZoom, Minimap, state.zoom)
end

-- Tracking spells are only touched when the scan switched them: turning a
-- spell on casts it.
function Engine.restoreTracking(state, spellsTouched)
    for _, t in ipairs(state.tracking) do
        if spellsTouched or not t.isSpell then
            local info = C_Minimap.GetTrackingInfo(t.index)
            if info ~= nil and (info.active and true or false) ~= t.active then
                pcall(C_Minimap.SetTracking, t.index, t.active)
            end
        end
    end
end

-- Returns true when every type matches the captured state again.
function Engine.trackingRestored(state)
    for _, t in ipairs(state.tracking) do
        local info = C_Minimap.GetTrackingInfo(t.index)
        if info == nil or (info.active and true or false) ~= t.active then
            return false, t.name
        end
    end
    return true
end

function Engine.shrink(cursorX, cursorY)
    local scale = Minimap:GetEffectiveScale()
    Minimap:SetAlpha(0)
    Minimap:SetSize(SHRUNK_SIZE, SHRUNK_SIZE)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale)
end

-- Full size, centred on the cursor.
function Engine.fullSize(state, cursorX, cursorY)
    local scale = Minimap:GetEffectiveScale()
    Minimap:SetSize(state.width, state.height)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale)
end

-- ---- asking at a point ----
-- Minimap:UpdateMouseoverAtPoint (Forever) names the dots at a screen
-- point in the frame it is called in; the next frame the cursor's own
-- mouseover is back. It answered only with the minimap under the resting
-- cursor (measured 2026-09-24).

-- A reader for the minimap as it lies now: offset (units from its
-- centre) -> dots there.
function Engine.pointReader()
    local cx, cy = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    return function(ox, oy)
        local ok = pcall(Minimap.UpdateMouseoverAtPoint, Minimap, (cx + ox) * scale, (cy + oy) * scale)
        if not ok then
            return {}
        end
        return Engine.readDots()
    end
end

-- The client limits how much Lua time runs per second and in one burst
-- (GetScriptBucketThrottleLimits, Forever; the limits are only known at
-- runtime, what happens past them is not documented). Work split over
-- frames stays at a quarter of both, and at most FRAME_BUDGET ms a frame.
-- Returns ms per frame and the limits read.
local FRAME_BUDGET = 4
local MIN_BUDGET = 0.5

function Engine.frameBudget()
    local budget = FRAME_BUDGET
    local limits = nil
    if GetScriptBucketThrottleLimits ~= nil then
        local ok, result = pcall(GetScriptBucketThrottleLimits)
        if ok and type(result) == "table" then
            limits = result
            local fps = math.max(GetFramerate() or 60, 20)
            local perSecond = result.luaScriptBucketThrottleMaxMsPerSecondNormal
            local burst = result.luaScriptBucketThrottleMaxMsBurstNormal
            if type(perSecond) == "number" and not WowVision.isSecret(perSecond) and perSecond > 0 then
                budget = math.min(budget, perSecond / fps / 4)
            end
            if type(burst) == "number" and not WowVision.isSecret(burst) and burst > 0 then
                budget = math.min(budget, burst / 4)
            end
        end
    end
    return math.max(budget, MIN_BUDGET), limits
end

-- True when the cursor rests over the game world (nothing else would let
-- the minimap receive it).
function Engine.cursorOverWorld()
    if GetMouseFoci == nil then
        return true
    end
    for _, focus in ipairs(GetMouseFoci()) do
        if focus ~= WorldFrame then
            return false
        end
    end
    return true
end

-- ---- frame runner ----
-- A scan is written as straight code in a coroutine; Engine.wait() hands
-- one frame back to the game. Abort checks run after every frame and end
-- the coroutine through an error carrying the reason.

local ABORT = {}

function Engine.abort(reason)
    error({ [ABORT] = true, reason = reason }, 0)
end

function Engine.isAbort(err)
    return type(err) == "table" and err[ABORT] == true
end

-- task.body(), task.check() -> reason or nil after each frame,
-- task.finish(ok, abortReason, err). Cleanups registered with
-- Engine.onCleanup run first, newest first, however the task ends (WoW's
-- Lua cannot yield inside pcall, so a task cannot guard its own waits).
local current = nil

function Engine.onCleanup(fn)
    tinsert(current.cleanups, fn)
end

function Engine.run(task)
    local co = coroutine.create(task.body)
    task.cleanups = {}
    local function finish(ok, reason, err)
        for i = #task.cleanups, 1, -1 do
            pcall(task.cleanups[i])
        end
        task.cleanups = {}
        task.finish(ok, reason, err)
    end
    local function step()
        current = task
        local ok, err = coroutine.resume(co)
        current = nil
        if not ok then
            if Engine.isAbort(err) then
                finish(false, err.reason)
            else
                finish(false, nil, err)
            end
            return
        end
        if coroutine.status(co) == "dead" then
            finish(true)
            return
        end
        C_Timer.After(0, function()
            local okCheck, reason = pcall(task.check or function() end)
            if not okCheck then
                finish(false, nil, reason)
                return
            end
            if reason ~= nil then
                finish(false, reason)
                return
            end
            step()
        end)
    end
    step()
end

-- Inside a running task: give the game one frame.
function Engine.wait(frames)
    for _ = 1, frames or 1 do
        coroutine.yield()
    end
end

-- Inside a running task: read each frame until two reads in a row agree
-- (the dots settle one or two frames after a tracking switch), at most
-- maxFrames frames.
function Engine.readSettled(maxFrames)
    local last, lastSig = nil, nil
    for frame = 1, maxFrames or 6 do
        Engine.wait()
        local dots = Engine.readDots()
        local sig = Scan.signature(dots)
        if frame >= 2 and sig == lastSig then
            return dots
        end
        last, lastSig = dots, sig
    end
    return last or {}
end

-- ---- cursor centring ----
-- A resting keyboard player's cursor can sit anywhere. The game centres
-- it when mouselook starts with these CVars set; a mouselook of a tenth
-- of a second moves nothing else. The CVars are saved ones, so they go
-- back afterwards.
local CENTRE_CVARS = {
    CursorCenteredYPos = "0.5",
    CursorFreelookCentering = "1",
    CursorStickyCentering = "1",
}

-- Inside a running task.
function Engine.centreCursor()
    if MouselookStart == nil or IsMouselooking == nil or IsMouselooking() then
        return
    end
    local saved = {}
    for name, value in pairs(CENTRE_CVARS) do
        local ok, current = pcall(GetCVar, name)
        if ok and current ~= nil then
            saved[name] = current
            pcall(SetCVar, name, value)
        end
    end
    local done = false
    local function undo()
        if done then
            return
        end
        done = true
        MouselookStop()
        for name, value in pairs(saved) do
            pcall(SetCVar, name, value)
        end
    end
    Engine.onCleanup(undo)
    MouselookStart()
    local started = GetTime()
    while GetTime() - started < 0.1 do
        Engine.wait()
    end
    undo()
end

-- ---- nearby NPCs, for real names ----

local rangeCheck = LibStub("LibRangeCheck-3.0", true)
local NEARBY_UNITS = { "softinteract", "target", "mouseover" }
for i = 1, 40 do
    tinsert(NEARBY_UNITS, "nameplate" .. i)
end

-- Friendly NPC nameplates are off by default; without them only the
-- target, soft interact and mouseover can be read.
function Engine.friendlyPlatesShown()
    local getBool = C_CVar ~= nil and C_CVar.GetCVarBool or GetCVarBool
    if getBool == nil then
        return false
    end
    local ok, shown = pcall(getBool, "nameplateShowFriendlyNpcs")
    return ok and shown == true
end

-- The NPCs around the player as Scan.pickName candidates: name, the
-- unit tooltip's lines below it, and range when LibRangeCheck can tell.
-- Secret values (restricted clients) are skipped.
function Engine.nearbyNpcs()
    local isSecret = WowVision.isSecret
    local out, seen = {}, {}
    for _, unit in ipairs(NEARBY_UNITS) do
        if UnitExists(unit) and not UnitIsPlayer(unit) then
            local guid = UnitGUID(unit)
            local name = UnitName(unit)
            if guid ~= nil and not isSecret(guid) and not seen[guid] and name ~= nil and not isSecret(name) then
                seen[guid] = true
                local lines = {}
                local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
                if ok and type(data) == "table" and type(data.lines) == "table" then
                    for i = 2, #data.lines do
                        local text = data.lines[i].leftText
                        if text ~= nil and not isSecret(text) then
                            tinsert(lines, text)
                        end
                    end
                end
                local candidate = { name = name, lines = lines }
                if rangeCheck ~= nil then
                    local okRange, minRange, maxRange = pcall(rangeCheck.GetRange, rangeCheck, unit)
                    if okRange then
                        candidate.minRange, candidate.maxRange = minRange, maxRange
                    end
                end
                tinsert(out, candidate)
            end
        end
    end
    return out
end
