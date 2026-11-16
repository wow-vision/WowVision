local module = WowVision.base.navigation.maps
local L = module.L
local unitAim = WowVision.unitAim
local turnMath = WowVision.turnMath
local camera = WowVision.navigationCamera
local secrets = WowVision.secrets
local rangeCheck = LibStub("LibRangeCheck-3.0", true)

-- Turn the character to face a unit: the target, or the focus (an escort
-- NPC on focus keeps the target free for the fight). A sighted player sees
-- where the unit stands; the game gives addons no position for an NPC, but
-- it does answer whether the unit's nameplate is behind the camera.
--
-- Facts this rests on (WoW: Forever, in game 2026-11-12):
-- - C_NamePlate.GetNamePlateForUnit(unit) gives the unit's plate without
--   any unit comparison (UnitIsUnit is secret in instances). Addons may not
--   measure the plate ("Can't measure restricted regions"), but
--   C_NamePlateManager.IsNamePlateUnitBehindCamera answers every frame.
-- - In first person the unit changes between in front of the camera and
--   behind it exactly 90 degrees either side of its bearing, at any
--   distance (unitAim.lua).
-- - Camera sweeps started outside a key press must be primed
--   (turnByAngle's lateStart, turnTo.lua).
--
-- A press: snap the camera behind the character and into first person;
-- sweep the camera alone to the right until the plate's answer changes
-- (at most half a turn); that change gives the bearing. Within the turn
-- tolerance nothing more happens. Else the camera turns the short way to
-- the bearing and its stop hands it to the character, as a turn to
-- waypoint ends. Then the camera goes back behind the character.
--
-- A unit standing close can lose its plate in first person (the plate is
-- high above the view; in game on an escort, 2026-11-12), or never change
-- sides; with offscreen nameplates off any plate goes when its unit leaves
-- the screen, and a unit off screen has none at the press. Then the press
-- measures with the camera pulled in close behind the character: two
-- changes, the bearing in their middle (unitAim.closeBearing). A unit
-- nearer than that camera never goes behind it; the player stands at it.
--
-- The press holds the turn engine (holdTurns) from start to end, so turn
-- to waypoint and the pitch lock keep off the camera between its turns.

-- The measuring sweeps: degrees a frame (a change is placed to half of it,
-- so the bearing is good to about 3 degrees), as a speed between these
-- (360 at 60 fps; below 20 fps the step grows), and how far: in first
-- person the change comes within half a turn, behind the character the
-- second within a turn; a little more allows for the primed start.
local SWEEP_STEP = 6
local SWEEP_SPEED_MIN = 120
local SWEEP_SPEED_MAX = 360
local FIRST_PERSON_LIMIT = 200
local CLOSE_LIMIT = 400
-- Frames for the switch to first person to land and the plates to follow.
local VIEW_FRAMES = 3
-- In first person the camera is at the character's eyes.
local FIRST_PERSON_ZOOM = 0.5
-- Behind the character: the camera's distance in yards (a unit nearer
-- than that never goes behind the camera), a fast zoom, and the wait for
-- it to land: near that distance and still for ZOOM_STILL frames, at most
-- ZOOM_FRAMES (a zoom still running moves the two changes unevenly).
local CLOSE_ZOOM = 2
local ZOOM_SPEED = 50
local ZOOM_STILL = 2
local ZOOM_FRAMES = 60
-- Behind the character the in-front stretch is at least half a circle,
-- wider the nearer the unit; where plates went off screen it is about the
-- screen's width. Outside these the changes were not clean.
local WIDTH_MIN = 170
local WIDTH_ON_SCREEN_MIN = 40
local WIDTH_MAX = 330
-- How long a press may hold the turn engine at most (renewed at each
-- stage): a Lua error in a callback must not block turning for good.
local HOLD_SECONDS = 10
local KEEP_READINGS = 40

local alert = module:addAlert({ key = "turnToUnit", label = L["Turn to Unit"] })
alert:addOutput({
    type = "Sound",
    key = "facing",
    action = "facing",
    label = L["Facing Unit"],
    path = "Sound/WowVision/alerts/clack.mp3",
})

local waitFrame = CreateFrame("Frame")
local running = nil

-- A press ends when its unit changes: the game's events, since the unit's
-- identity is secret in instances (as core/targeting/range.lua does).
local UNIT_EVENTS = { PLAYER_TARGET_CHANGED = "target", PLAYER_FOCUS_CHANGED = "focus" }
local eventFrame = CreateFrame("Frame")
for event in pairs(UNIT_EVENTS) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end
eventFrame:SetScript("OnEvent", function(_, event)
    if running ~= nil and UNIT_EVENTS[event] == running.unit then
        running.unitChanged = true
    end
end)

-- The press log, kept in WowVisionDump.turnToUnit so it is in the
-- SavedVariables after a /reload: one line per press.
local function readings()
    WowVisionDump = WowVisionDump or {}
    if type(WowVisionDump.turnToUnit) ~= "table" then
        WowVisionDump.turnToUnit = {}
    end
    return WowVisionDump.turnToUnit
end

local function note(run, line)
    tinsert(run.lines, line)
end

-- The facing in degrees (nil where the game hides it: instances).
local function facingDegrees()
    local ok, facing = pcall(GetPlayerFacing)
    if ok and type(facing) == "number" and not secrets.isSecret(facing) then
        return math.deg(facing)
    end
    return nil
end

local function cameraZoom()
    local ok, zoom = pcall(GetCameraZoom)
    if ok and type(zoom) == "number" and not secrets.isSecret(zoom) then
        return zoom
    end
    return nil
end

-- For the log: the unit's distance as LibRangeCheck tells it.
local function rangeText(unit)
    if rangeCheck == nil then
        return "range unknown"
    end
    local ok, minRange, maxRange = pcall(rangeCheck.GetRange, rangeCheck, unit)
    if not ok or minRange == nil or secrets.isSecret(minRange) or secrets.isSecret(maxRange) then
        return "range unknown"
    end
    return "range " .. minRange .. " to " .. tostring(maxRange or "far")
end

local function findPlate(unit)
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok then
        return plate
    end
    return nil
end

-- Whether the press's unit is in front of the camera now: true, false,
-- "changed" (the target or focus is another unit now), "gone" (its plate
-- is not there), or nil (the game will not say).
local function inFront(run)
    if run.unitChanged then
        return "changed"
    end
    local plate = findPlate(run.unit)
    if plate == nil then
        return "gone"
    end
    local token = plate.unitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    local manager = C_NamePlateManager
    if token == nil or manager == nil or manager.IsNamePlateUnitBehindCamera == nil then
        return nil
    end
    local ok, behind = pcall(manager.IsNamePlateUnitBehindCamera, token)
    if not ok or secrets.isSecret(behind) then
        return nil
    end
    return behind == false
end

-- The sweeps set the camera's turn speed (cameraYawMoveSpeed). Whether the
-- game lets an addon write it in combat is not known; a refused write would
-- break the sweep, so each press writes the value it has first.
local function cameraSpeedWritable()
    local okRead, value = pcall(GetCVar, "cameraYawMoveSpeed")
    if not okRead or value == nil then
        return false
    end
    local ok, result = pcall(SetCVar, "cameraYawMoveSpeed", value)
    return ok and result ~= false
end

-- Run fn after frames real frames, unless the press ended meanwhile.
local function afterFrames(run, frames, fn)
    local last = GetTime()
    local seen = 0
    waitFrame:SetScript("OnUpdate", function(self)
        local now = GetTime()
        if now <= last then
            return
        end
        last = now
        seen = seen + 1
        if seen >= frames then
            self:SetScript("OnUpdate", nil)
            if running == run then
                fn()
            end
        end
    end)
end

-- End the press. message nil: facing the unit (the alert); "": quietly;
-- else it is said. The camera goes back behind the character in any case.
local function finish(run, message)
    if running ~= run then
        return
    end
    running = nil
    module:releaseTurns()
    waitFrame:SetScript("OnUpdate", nil)
    if run.zoomSpeed ~= nil then
        pcall(SetCVar, "cameraZoomSpeed", run.zoomSpeed)
    end
    camera.align()
    if run.freeLookOff then
        camera.endGamepadTurn()
    end
    local facing = facingDegrees()
    if run.facing ~= nil and facing ~= nil then
        -- positive = turned right, as the bearing
        note(run, string.format("turned %.1f", turnMath.wrap(run.facing - facing)))
    end
    note(run, message or "facing")
    local list = readings()
    tinsert(list, date("%Y-%m-%d %H:%M:%S") .. " " .. run.unit .. ": " .. table.concat(run.lines, ", "))
    while #list > KEEP_READINGS do
        tremove(list, 1)
    end
    if message == nil then
        module:fireAlert("turnToUnit", { action = "facing" })
    elseif message ~= "" then
        WowVision:notify(message)
    end
end

-- The short way from where the measuring sweep stopped to the bearing; the
-- turn's stop hands the camera to the character.
local function approach(run, angle)
    note(run, string.format("approach %.1f", angle))
    local started = module:turnByAngle(angle, {
        keepCamera = true,
        lateStart = true,
        onDone = function(how)
            if how ~= "landed" then
                finish(run, "")
            elseif run.unitChanged then
                finish(run, L["Lost the nameplate"])
            else
                finish(run)
            end
        end,
    })
    if started ~= true then
        -- (the stop lies well off the bearing: never "facing")
        finish(run, "")
    end
end

local measure, zoomClose

-- Pull the camera in close behind the character, then measure again.
local function measureClose(run)
    note(run, "close")
    module:holdTurns(HOLD_SECONDS)
    camera.align()
    -- The snap out of first person lands a frame later: read the zoom then.
    afterFrames(run, VIEW_FRAMES, function()
        zoomClose(run)
    end)
end

zoomClose = function(run)
    local okSpeed, speed = pcall(GetCVar, "cameraZoomSpeed")
    if okSpeed and speed ~= nil and run.zoomSpeed == nil then
        run.zoomSpeed = speed
    end
    pcall(SetCVar, "cameraZoomSpeed", ZOOM_SPEED)
    local zoom = cameraZoom()
    if zoom ~= nil and zoom > CLOSE_ZOOM then
        CameraZoomIn(zoom - CLOSE_ZOOM)
    end
    local frames, lastZoom, still = 0, zoom, 0
    local function wait()
        afterFrames(run, 1, function()
            frames = frames + 1
            local now = cameraZoom()
            if now ~= nil and lastZoom ~= nil and math.abs(now - lastZoom) < 0.01 then
                still = still + 1
            else
                still = 0
            end
            lastZoom = now
            local near = now ~= nil and math.abs(now - CLOSE_ZOOM) <= 0.3
            if (near and still >= ZOOM_STILL) or frames >= ZOOM_FRAMES then
                return measure(run, true)
            end
            wait()
        end)
    end
    wait()
end

-- Sweep the camera alone to the right until the unit has changed between
-- in front and behind once (first person) or twice (close, behind the
-- character); then the bearing, and the approach.
measure = function(run, close)
    if not close then
        local zoom = cameraZoom()
        if zoom ~= nil and zoom > FIRST_PERSON_ZOOM then
            -- The view switch was refused: no first person, no 90 degrees.
            note(run, string.format("not in first person, zoom %.1f", zoom))
            return finish(run, L["Turning is not available here"])
        end
    end
    local needed = close and 2 or 1
    -- Behind the character a missing plate counts as "not in front": with
    -- offscreen nameplates off (the game's default) a plate is there only
    -- while its unit is on screen, and the screen's edges lie the same angle
    -- either side of the bearing too, so the middle still holds.
    local sawGone = false
    local function state()
        local now = inFront(run)
        if now == true or now == false then
            run.plateSeen = true
        elseif close and now == "gone" then
            sawGone = true
            return false
        end
        return now
    end
    local last = state()
    if last == "changed" then
        return finish(run, L["Lost the nameplate"])
    elseif last == "gone" then
        note(run, "plate gone before the sweep")
        return measureClose(run)
    elseif last == nil then
        return finish(run, L["Nameplate position is hidden here"])
    end
    module:holdTurns(HOLD_SECONDS)
    local previous = 0
    local stoppedAt = 0
    local changes = {}
    local ended = nil
    local frameTime = turnMath.frameTime(GetFramerate())
    local speed = math.max(SWEEP_SPEED_MIN, math.min(SWEEP_SPEED_MAX, SWEEP_STEP / frameTime))
    local started = module:turnByAngle(close and CLOSE_LIMIT or FIRST_PERSON_LIMIT, {
        cameraOnly = true,
        lateStart = true,
        fixedSpeed = speed,
        onFrame = function(moved)
            stoppedAt = moved
            local now = state()
            if now == "changed" or now == "gone" then
                ended = now
                return true
            end
            if now == nil then
                -- no answer this frame: a change may lie anywhere since the
                -- last one, so previous stays there
                return false
            end
            if now ~= last then
                tinsert(changes, { at = (previous + moved) / 2, cameIn = now })
                last = now
                if #changes >= needed then
                    return true
                end
            end
            previous = moved
            return false
        end,
        onDone = function(how)
            if running ~= run then
                return
            end
            for _, change in ipairs(changes) do
                note(run, string.format("change %.1f %s", change.at, change.cameIn and "in" or "out"))
            end
            if how ~= "landed" then
                return finish(run, "")
            elseif ended == "changed" then
                return finish(run, L["Lost the nameplate"])
            elseif ended == "gone" or #changes < needed then
                note(run, ended == "gone" and "plate gone in the sweep" or "no change")
                if not close then
                    return measureClose(run)
                end
                -- (behind the character state() never says "gone")
                return finish(run, run.plateSeen and L["Could not turn to it"] or L["No nameplate"])
            end
            local bearing, width
            if close then
                bearing, width = unitAim.closeBearing(changes[1], changes[2])
                note(run, string.format("width %.1f%s", width, sawGone and " on screen" or ""))
                if width < (sawGone and WIDTH_ON_SCREEN_MIN or WIDTH_MIN) or width > WIDTH_MAX then
                    return finish(run, L["Could not turn to it"])
                end
            else
                bearing = unitAim.firstPersonBearing(changes[1].at, changes[1].cameIn)
            end
            note(run, string.format("bearing %.1f", bearing))
            if math.abs(bearing) <= module.TURN_TOLERANCE then
                note(run, "already facing")
                return finish(run)
            end
            approach(run, turnMath.wrap(bearing - stoppedAt))
        end,
    })
    if started ~= true then
        finish(run, "")
    end
end

-- Turn to face unit ("target" or "focus").
function module:turnToUnit(unit)
    if self:isTurning() then
        -- a turn, or a press, still has the camera
        return false
    end
    if running ~= nil then
        -- a press whose hold ran out (a Lua error in a callback): undo it
        finish(running, "")
    end
    if not UnitExists(unit) then
        WowVision:notify(unit == "focus" and L["No focus"] or L["No target"])
        return false
    end
    local hasPlate = findPlate(unit) ~= nil
    if not hasPlate and IsInInstance() then
        -- Instances hide friendly nameplates from addons (forbidden frames).
        local reaction = UnitReaction("player", unit)
        if reaction ~= nil and not secrets.isSecret(reaction) and reaction >= 5 then
            WowVision:notify(L["Friendly nameplates are hidden here"])
            return false
        end
    end
    if not cameraSpeedWritable() then
        WowVision:notify(L["Turning is not available here"])
        return false
    end
    local run = {
        unit = unit,
        facing = facingDegrees(),
        lines = {},
    }
    running = run
    module:holdTurns(HOLD_SECONDS)
    note(run, (InCombatLockdown() and "in combat" or "no combat") .. ", " .. (IsInInstance() and "instance" or "world"))
    note(run, rangeText(unit))
    if run.facing ~= nil then
        note(run, string.format("facing %.1f", run.facing))
    end
    -- Free look (gamepad) goes off with the camera behind the character, as
    -- in every turn (camera.lua), and stays off for the whole press.
    camera.align()
    run.freeLookOff = camera.beginGamepadTurn()
    if not hasPlate then
        -- off screen with offscreen nameplates off, or out of plate range:
        -- only the close sweep can find it
        note(run, "no plate at the press")
        measureClose(run)
        return true
    end
    camera.firstPerson()
    afterFrames(run, VIEW_FRAMES, function()
        measure(run, false)
    end)
    return true
end

-- Copyable diagnostics: the press log, also printed to chat.
module:registerCommand({
    name = "unitturnlog",
    description = "Show the last turns to a unit",
    func = function()
        local list = readings()
        local lines = { string.format("%d presses", #list) }
        for _, line in ipairs(list) do
            tinsert(lines, line)
        end
        for _, line in ipairs(lines) do
            print(line)
        end
        WowVision.testing.showResults(table.concat(lines, string.char(10)))
        WowVision:speak(lines[1])
    end,
})

module:registerBinding({
    type = "Script",
    key = "maps/turnToTarget",
    label = L["Turn to Target"],
    inputs = { "CTRL-I" },
    script = "/run WowVision.base.navigation.maps:turnToUnit('target')",
})

module:registerBinding({
    type = "Script",
    key = "maps/turnToFocus",
    label = L["Turn to Focus"],
    inputs = { "CTRL-U" },
    script = "/run WowVision.base.navigation.maps:turnToUnit('focus')",
})
