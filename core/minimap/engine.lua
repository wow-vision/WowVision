local Scan = WowVision.minimapScan

-- The minimap scanner's game half: moving Blizzard's minimap under the
-- resting mouse cursor and reading what the game names there.
--
-- No API lists minimap dots, but C_TooltipInfo.GetMinimapMouseover names
-- the ones under the cursor. Two ways to use that:
-- - shrunk: the minimap squeezed to a few pixels with its centre on the
--   cursor puts every dot in range under it, so one read names them all
--   (the walking check, and the sorting passes);
-- - at a point: the minimap (at a scale of its size, the dots keep theirs)
--   moved so that point lies under the cursor; the game names what is
--   there one frame later (Sku's grid scan). The points where a name answers give its offset from the
--   player. Minimap:UpdateMouseoverAtPoint, which asked any point in the
--   same frame, is a no-op since Forever build 70862 and goes in 1.60.2;
--   moving the minimap under the resting cursor still answers (measured
--   2026-11-10, /wv mscan sku: 13 dots placed, 1 frame a point, 0 frames
--   gives the last frame's names).
-- Tracking types switched one at a time sort the names (see logic.lua).
--
-- Everything the scan changes (points, size, alpha, zoom, tracking, the
-- minimap cluster's strata and level, hidden minimap children, the
-- minimap's clicks, the game tooltip's alpha, the cursor CVars) is
-- captured first and restored at the end, on abort and on error. The
-- minimap is not a protected frame; the scanner still keeps out of
-- combat.

local Engine = {}
Scan.engine = Engine

local SHRUNK_SIZE = 15

-- The running task (Engine.run), nil between frames.
local current = nil

function Engine.available()
    return C_TooltipInfo ~= nil
        and C_TooltipInfo.GetMinimapMouseover ~= nil
        and C_Minimap ~= nil
        and C_Minimap.GetViewRadius ~= nil
        and C_Minimap.GetTrackingInfo ~= nil
        and C_Minimap.GetTrackingFilter ~= nil
        and Minimap ~= nil
end

-- The game's above and below arrow atlases (the ones the quest line pins
-- use, Blizzard_SharedMapDataProviders) as texture fractions: { above,
-- below }, each { left, right, top, bottom, file }. Read once; nil parts
-- when the client lacks them. Only logged: they did not match the arrows
-- in the minimap tooltip (2026-09-28), see Scan.arrowLevel.
local ARROW_ATLASES = { above = "MiniMap-PositionArrowUp", below = "MiniMap-PositionArrowDown" }
local arrowAtlases = nil

function Engine.arrowAtlases()
    if arrowAtlases == nil then
        arrowAtlases = {}
        if C_Texture ~= nil and C_Texture.GetAtlasInfo ~= nil then
            for level, atlas in pairs(ARROW_ATLASES) do
                local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
                if ok and type(info) == "table" and info.topTexCoord ~= nil then
                    arrowAtlases[level] = {
                        left = info.leftTexCoord,
                        right = info.rightTexCoord,
                        top = info.topTexCoord,
                        bottom = info.bottomTexCoord,
                        file = info.filename or info.file,
                    }
                end
            end
        end
    end
    return arrowAtlases
end

-- The names the minimap's mouseover holds right now; a dot with an arrow
-- gets level "above" or "below".
local function readMouseover()
    local ok, data = pcall(C_TooltipInfo.GetMinimapMouseover)
    if not ok then
        return {}
    end
    local dots = Scan.parseMouseover(data, WowVision.isSecret)
    for _, dot in ipairs(dots) do
        if dot.arrow ~= nil then
            dot.level = Scan.arrowLevel(dot.arrow)
        end
    end
    return dots
end

-- The shrunk minimap under the resting cursor, as the game names it now
-- (give it a frame after placing it).
function Engine.readDots()
    return readMouseover()
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
-- because the walking check never touches it.
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

-- Inside a running task, once: as in Sku, the minimap's cluster on top
-- of every other frame and the minimap's own mouse-taking children
-- (other addons' icons, Questie's for one) hidden, so the cursor meets
-- the minimap itself (2026-11-09 a Questie icon held the mouse focus).
-- Both come back when the task ends. Returns how many children it hid.
-- Lying on top under the cursor, the minimap would take a click meant for
-- the world: Blizzard's OnClick pings the spot for the group, and a
-- ground spell placed in that moment would miss. So it takes no clicks
-- (the mouseover, which the reads need, stays). And the game shows its
-- minimap tooltip at the cursor while the minimap lies there (measured
-- 2026-11-10): invisible until a tenth of a second after the task, when
-- the minimap has left the cursor and Blizzard's OnLeave has hidden it.
local tooltipHolds = 0
local tooltipAlpha = 1

function Engine.clearWay()
    if current.wayCleared then
        return current.hiddenChildren
    end
    current.wayCleared = true
    local strata, level = MinimapCluster:GetFrameStrata(), MinimapCluster:GetFrameLevel()
    local clicks = Minimap.IsMouseClickEnabled ~= nil and Minimap:IsMouseClickEnabled() or nil
    local hidden = {}
    if tooltipHolds == 0 then
        tooltipAlpha = GameTooltip:GetAlpha()
    end
    tooltipHolds = tooltipHolds + 1
    Engine.onCleanup(function()
        for _, child in ipairs(hidden) do
            pcall(child.Show, child)
        end
        pcall(MinimapCluster.SetFrameStrata, MinimapCluster, strata)
        pcall(MinimapCluster.SetFrameLevel, MinimapCluster, level)
        if clicks ~= nil then
            pcall(Minimap.SetMouseClickEnabled, Minimap, clicks)
        end
        C_Timer.After(0.1, function()
            tooltipHolds = tooltipHolds - 1
            if tooltipHolds == 0 then
                GameTooltip:SetAlpha(tooltipAlpha)
            end
        end)
    end)
    GameTooltip:SetAlpha(0)
    pcall(Minimap.SetMouseClickEnabled, Minimap, false)
    MinimapCluster:SetFrameStrata("HIGH")
    MinimapCluster:SetFrameLevel(9002)
    for _, child in ipairs({ Minimap:GetChildren() }) do
        if child:IsShown() and child:IsMouseEnabled() then
            tinsert(hidden, child)
            child:Hide()
        end
    end
    current.hiddenChildren = #hidden
    return #hidden
end

function Engine.shrink(cursorX, cursorY)
    Engine.clearWay()
    local scale = Minimap:GetEffectiveScale()
    Minimap:SetAlpha(0)
    Minimap:SetSize(SHRUNK_SIZE, SHRUNK_SIZE)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale)
end

-- The game works out the cursor's minimap mouseover when something moves
-- under it. Each shrunk read shifts the minimap by one unit, back and
-- forth (it stays under the cursor), so a switched tracking filter or a
-- dot that came into range is named. The soft cursor mode the scan used
-- since 2026-10-16 is gone: since build 70862 the read that named dots
-- (/wv mscan sku, 2026-11-10) had it off.
local nudged = false

function Engine.nudge()
    local point, relativeTo, relativePoint, x, y = Minimap:GetPoint(1)
    if point == nil then
        return
    end
    nudged = not nudged
    Minimap:ClearAllPoints()
    Minimap:SetPoint(point, relativeTo, relativePoint, x + (nudged and 1 or -1), y)
end

-- Inside a running task, the shrunk minimap under the cursor: up to
-- maxFrames frames, each nudged, until a read names something; the last
-- read (empty when nothing is in range).
function Engine.readFirst(maxFrames)
    local dots = {}
    for _ = 1, maxFrames or 6 do
        Engine.nudge()
        Engine.wait()
        dots = readMouseover()
        if #dots > 0 then
            return dots
        end
    end
    return dots
end

-- ---- asking at a point ----
-- The game works out what lies under the cursor once a frame: the
-- minimap moved so a point lies under the resting cursor names that
-- point's dots the next frame (several moves in one frame read the last
-- frame's names, measured 2026-11-10).

-- Inside a running task: the minimap at scale times its captured size
-- (state), a reader offset (full-size units from its centre) -> dots
-- there, the point laid under the cursor (cursorX, cursorY as
-- GetCursorPosition gave them). The dots keep their size at any scale.
-- Each question takes one frame; two frames first for the new size (the
-- first frame after the minimap arrives reads empty).
function Engine.pointReader(state, cursorX, cursorY, scale)
    scale = scale or 1
    Engine.clearWay()
    local s = Minimap:GetEffectiveScale()
    local cx, cy = cursorX / s, cursorY / s
    Minimap:SetSize(state.width * scale, state.height * scale)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx, cy)
    Engine.wait(2)
    return function(ox, oy)
        Minimap:ClearAllPoints()
        Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx - ox * scale, cy - oy * scale)
        Engine.wait()
        return readMouseover()
    end
end

-- The minimap has an indoor scale besides the outdoor one; the game
-- switches between them going in and out of buildings (MINIMAP_UPDATE_ZOOM;
-- Warcraft Wiki), and indoors it shows only that building. IsIndoors()
-- does not tell (it is about mounting): large parts of Stormwind read
-- outdoors there while the minimap is in its indoor scale (2026-11-10: at
-- zoom 0 the view radius is 233.3 yards outdoors, 150 in that scale).
-- The view radius in yards, nil when the game gives none (or a secret).
function Engine.viewRadius()
    local radius = C_Minimap.GetViewRadius()
    if type(radius) ~= "number" or WowVision.isSecret(radius) or radius <= 0 then
        return nil
    end
    return radius
end

-- Inside a scan or walking check (zoom 0): true in the indoor scale.
function Engine.minimapIndoors()
    local radius = Engine.viewRadius()
    return radius ~= nil and radius < Scan.Walk.RADIUS * 0.8
end

-- Why the cursor is busy for the player, or nil: a spell waiting to be
-- placed (ground targeting), something held on the cursor, a mouse button
-- down. No minimap goes under the cursor then.
function Engine.cursorBusy()
    if SpellIsTargeting ~= nil and SpellIsTargeting() then
        return "targeting"
    end
    if GetCursorInfo ~= nil and GetCursorInfo() ~= nil then
        return "holding"
    end
    if IsMouseButtonDown ~= nil and IsMouseButtonDown() then
        return "button"
    end
    return nil
end

-- True when the cursor rests over the game world (nothing else would let
-- the minimap receive it); otherwise false and the name of the frame in
-- the way, so the cancel message can say what it was.
function Engine.cursorOverWorld()
    if GetMouseFoci == nil then
        return true
    end
    for _, focus in ipairs(GetMouseFoci()) do
        if focus ~= WorldFrame then
            local ok, name = pcall(function()
                if focus.GetDebugName ~= nil then
                    return focus:GetDebugName()
                end
                return focus:GetName()
            end)
            if not ok or name == nil or name == "" then
                name = "unnamed frame"
            end
            return false, tostring(name)
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
-- (current, the running task, is declared at the top.)

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

-- Inside a running task: read each frame (nudged) until two reads in a
-- row agree and name something (the dots settle one or two frames after a
-- tracking switch; two empty reads in a row are not trusted, the names
-- can come a few frames late), at most maxFrames frames.
function Engine.readSettled(maxFrames)
    local last, lastSig = nil, nil
    for frame = 1, maxFrames or 6 do
        Engine.nudge()
        Engine.wait()
        local dots = Engine.readDots()
        local sig = Scan.signature(dots)
        if frame >= 2 and sig == lastSig and #dots > 0 then
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
        local ok, was = pcall(GetCVar, name)
        if ok and was ~= nil then
            saved[name] = was
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
