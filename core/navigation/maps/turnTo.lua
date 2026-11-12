local module = WowVision.base.navigation.maps
local L = module.L
local turnMath = WowVision.turnMath
local camera = WowVision.navigationCamera
local pitchLock = WowVision.pitchLock

-- Turn the character to face the current route waypoint.
--
-- Addons cannot turn the character, so the CAMERA turns and a mouselook
-- pulse hands its yaw to the character (camera.lua). The camera is first
-- snapped straight behind the character, then swept by the bearing.
--
-- The engine moves the camera in whole frames, measured in Sku on 400
-- turns at 20 and 77 to 125 fps:
-- 1. Once per frame, by speed times that frame's REAL duration. Nothing
--    moves between frames.
-- 2. Every frame after the key press moves, except the one whose OnUpdate
--    stops the sweep.
-- 3. The elapsed time an OnUpdate sees is the duration of the step that
--    follows it, so the stop decision is fully informed.
-- 4. cameraYawMoveSpeed is read every frame, so one frame's step can be
--    trimmed by lowering it.
-- So nothing needs learning: the real speed was the asked speed (ratio
-- 1.00, spread 0.01) and the only "latency" is that one idle frame. A
-- calibration in seconds learns one frame at one frame rate and is wrong
-- at the next; WowVision's self-calibration was removed for that reason.
-- A timer cannot stop the sweep either: C_Timer fires on frame boundaries
-- and slips a whole frame at 2 percent jitter.
--
-- So: plan the speed so the angle is a whole number of frames
-- (turnMath.plan), count real frame durations in an OnUpdate, trim the
-- last step, stop, pulse in that same frame, and release two frames later
-- when the pulse has landed. No corrective sweeps: a command into a
-- running stop fights the idle frame.
--
-- A press while a turn runs is ignored (the running turn aims at a fresh
-- bearing anyway). Manual turn keys abort. Turning on the move is allowed:
-- the aim leads to where the player will be when the turn lands.
--
-- module:turnByAngle runs the same sweep for other callers (turn to unit,
-- turnToUnit.lua), with options that turn to waypoint does not use.

local TOLERANCE = 3 -- degrees: already facing it, do nothing
module.TURN_TOLERANCE = TOLERANCE
local SETTLE_MIN_FRAMES = 2
local SETTLE_MIN_TIME = 0.05
-- Lead: the turn lands its steps plus the idle frame plus the pulse frame
-- after the press, plus this much.
local LEAD_EXTRA = 0.03
local LOG_SIZE = 30

-- Positive relative bearing = target to the RIGHT. Verified in game:
-- MoveViewLeftStart yaws the character's facing RIGHT after a pulse (the
-- camera orbits opposite the view direction).
local CAMERA_RIGHT_START = MoveViewLeftStart
local CAMERA_LEFT_START = MoveViewRightStart

local turnFrame = CreateFrame("Frame")
local current = nil
-- The player's Mouse Look Speed while a turn has it; kept outside the turn
-- so it can never be captured twice.
local savedYawSpeed = nil
local log = {}

local function stopCamera()
    MoveViewLeftStop()
    MoveViewRightStop()
end

local function restoreYawSpeed()
    if savedYawSpeed ~= nil then
        SetCVar("cameraYawMoveSpeed", savedYawSpeed)
        savedYawSpeed = nil
    end
end

local function addLog(line)
    tinsert(log, line)
    if #log > LOG_SIZE then
        tremove(log, 1)
    end
end

-- how: "landed", "aborted" (the player turned) or "watchdog".
local function release(turn, how)
    if current == turn then
        current = nil
        turnFrame:SetScript("OnUpdate", nil)
        if turn.freeLookOff then
            camera.endGamepadTurn()
        end
        if turn.onDone ~= nil then
            turn.onDone(how)
        end
    end
end

local function stopSweep(turn)
    stopCamera()
    restoreYawSpeed()
    if not turn.cameraOnly then
        camera.transfer()
    end
    turn.stopFrame = turn.sweep.frames
    turn.framesSinceStop = 0
    turn.landX, turn.landY = UnitPosition("player")
    if not turn.cameraOnly then
        pitchLock.afterTurn()
    end
end

local function measure(turn)
    local endFacing = GetPlayerFacing()
    if endFacing == nil or WowVision.isSecret(endFacing) or WowVision.isSecret(turn.startFacing) then
        return
    end
    local turned = turnMath.turned(turn.startFacing, endFacing, turn.direction, turn.target)
    local aimError = 0
    local landDistance = -1
    if turn.landX ~= nil then
        aimError = turnMath.relativeBearing(turn.landX, turn.landY, endFacing, turn.x, turn.y)
        landDistance = math.sqrt((turn.x - turn.landX) ^ 2 + (turn.y - turn.landY) ^ 2)
    end
    addLog(string.format(
        "target %.1f turned %.1f error %.1f | speed %.0f frames %d/%d trim %s fps %.0f frame ms %s | lead %.1f, aim at landing %.1f, %.1f yd, moving %.1f",
        turn.target,
        turned,
        turned - turn.target,
        turn.speed,
        turn.steps,
        turn.stopFrame,
        turn.sweep.trim and string.format("%.2f", turn.sweep.trim) or "-",
        1 / turn.frameTime,
        table.concat(turn.frameMs, "/"),
        turn.lead,
        aimError,
        landDistance,
        turn.moving
    ))
end

local function onUpdate()
    local turn = current
    if turn == nil then
        turnFrame:SetScript("OnUpdate", nil)
        return
    end
    -- Count real frame advances only (GetTime is fixed within a frame).
    local now = GetTime()
    if now <= turn.lastTime then
        return
    end
    local delta = now - turn.lastTime
    turn.lastTime = now
    if turn.stopFrame ~= nil then
        turn.framesSinceStop = turn.framesSinceStop + 1
        if turn.framesSinceStop >= turn.settleFrames then
            release(turn, "landed")
            -- (only turns to a point have an aim to measure against)
            if turn.x ~= nil then
                measure(turn)
            end
        end
        return
    end
    local flags = WowVision.movement.flags
    if flags.turnLeft or flags.turnRight then
        -- The player took over: stop where we are, no pulse.
        stopCamera()
        restoreYawSpeed()
        release(turn, "aborted")
        return
    end
    if #turn.frameMs < 24 then
        tinsert(turn.frameMs, string.format("%.0f", delta * 1000))
    end
    if turn.onFrame ~= nil and turn.onFrame(turn.sweep.committed * turn.speed + turn.startStep) then
        stopSweep(turn)
        return
    end
    local action, fraction = turn.sweep:frame(delta)
    if action == "stop" then
        stopSweep(turn)
    elseif action == "trim" then
        SetCVar("cameraYawMoveSpeed", turn.cvar * fraction)
    end
end

-- Start the sweep for a turn of relative degrees (positive = right); turn
-- holds the caller's fields (turnToPoint's aim point and lead, or
-- turnByAngle's options).
local function startTurn(relative, frameTime, turn)
    if turn.lateStart and not turn.primed then
        -- A sweep started outside a key press first jumps by the distance it
        -- would have covered meanwhile (warcraft.wiki.gg, API_MoveViewLeftStart).
        -- Speed 0 first and the real start a frame later, as the wiki says,
        -- and it moves exactly one frame step more than it counts (in game,
        -- 2026-11-12); the sweep below takes that step off.
        turn.primed = true
        current = turn
        MoveViewLeftStart(0)
        MoveViewRightStart(0)
        C_Timer.After(0, function()
            if current == turn then
                current = nil
                startTurn(relative, turnMath.frameTime(GetFramerate()), turn)
            end
        end)
        return true
    end
    local target = math.abs(relative)
    local sweepSpeed, steps = turnMath.plan(target, frameTime)
    if turn.fixedSpeed ~= nil then
        -- A search sweep: a steady speed instead of the fewest frames (steps
        -- then only sizes the watchdog).
        sweepSpeed = turn.fixedSpeed
        steps = math.max(1, math.ceil(target / (sweepSpeed * frameTime) - 1e-9))
    end
    local cvar = math.min(sweepSpeed, turnMath.CVAR_MAX)
    -- The primed start's extra step: not swept, but reported to onFrame.
    turn.startStep = 0
    if turn.lateStart then
        turn.startStep = math.min(sweepSpeed * frameTime, target)
    end
    turn.target = target
    turn.direction = relative > 0 and 1 or -1
    turn.speed = sweepSpeed
    turn.steps = steps
    turn.cvar = cvar
    turn.frameTime = frameTime
    turn.settleFrames = math.max(SETTLE_MIN_FRAMES, math.ceil(SETTLE_MIN_TIME / frameTime - 1e-9))
    if turn.cameraOnly then
        -- No pulse to wait for: release in the next frame.
        turn.settleFrames = 1
    end
    turn.sweep = turnMath.newSweep(target - turn.startStep, sweepSpeed, steps)
    if turn.startStep >= target then
        -- The primed step alone covers it (very low frame rates): stop at
        -- once instead of a forced minimal trim.
        turn.sweep.stopNext = true
    end
    -- nil where the game hides the facing; measure() then logs nothing
    turn.startFacing = GetPlayerFacing()
    turn.lastTime = GetTime()
    turn.frameMs = {}
    turn.lead = turn.lead or 0
    turn.moving = turn.moving or 0
    current = turn

    pitchLock.noteTurn()
    stopCamera()
    if not turn.cameraOnly then
        if not turn.keepCamera then
            camera.align()
        end
        -- With the gamepad, free look is off for the turn (camera.lua). Only now,
        -- with the camera straight behind the character: free look going off
        -- hands any camera offset to the character, and pressing the stick
        -- nudges the camera. (False when a caller holds it off already.)
        turn.freeLookOff = camera.beginGamepadTurn()
    end
    if savedYawSpeed == nil then
        savedYawSpeed = GetCVar("cameraYawMoveSpeed")
    end
    SetCVar("cameraYawMoveSpeed", cvar)
    if turn.direction > 0 then
        CAMERA_RIGHT_START(sweepSpeed / cvar)
    else
        CAMERA_LEFT_START(sweepSpeed / cvar)
    end
    turnFrame:SetScript("OnUpdate", onUpdate)

    -- Watchdog: if the frame counter never runs (an error in it), the
    -- camera must not keep spinning nor the speed stay changed.
    C_Timer.After((steps + 1 + turn.settleFrames) * frameTime * 4 + 1, function()
        if current ~= turn then
            return
        end
        if turn.stopFrame == nil then
            stopCamera()
        end
        restoreYawSpeed()
        addLog("watchdog stopped a turn")
        release(turn, "watchdog")
    end)
    return true
end

-- Without a beacon the turn key asks this for a facing to turn to instead (radians, as
-- GetPlayerFacing; nil: nothing here). WowNav routes set it at a tram, ship or zeppelin dock (the
-- boarding point, or the noted dock near it) and at a fishing spot (its water).
module.facingWithoutWaypoint = nil

-- A caller that runs several turns in a row (turnToUnit.lua) holds the
-- camera between them: until then, or for at most the seconds given (a
-- callback error must not block turning for good), turn to waypoint is
-- refused as during a running turn, and the pitch lock does not level.
local heldUntil = 0

function module:holdTurns(seconds)
    heldUntil = GetTime() + seconds
end

function module:releaseTurns()
    heldUntil = 0
end

-- Far enough that the lead of a moving player does not bend the bearing to it.
local FACING_REACH = 10000

-- Turn to face the world point (x, y), aiming where it lies when the turn lands.
local function turnToPoint(x, y)
    if module:isTurning() then
        return false
    end
    local px, py = UnitPosition("player")
    local facing = GetPlayerFacing()
    if px == nil or facing == nil then
        -- Retail hides the player's facing and position in instances.
        WowVision:notify(L["Turning is not available here"])
        return false
    end
    local frameTime = turnMath.frameTime(GetFramerate())

    -- Aim at the bearing the waypoint will have when the turn lands. Close
    -- to a waypoint the bearing moves fast; without the lead, moving
    -- players circle it.
    local raw = turnMath.relativeBearing(px, py, facing, x, y)
    local relative = raw
    local moving = 0
    local direction = turnMath.moveDirection(facing, WowVision.movement.flags)
    local speed = GetUnitSpeed("player")
    if direction ~= nil and speed ~= nil and not WowVision.isSecret(speed) and speed > 0 then
        moving = speed
        local _, steps = turnMath.plan(math.abs(raw), frameTime)
        local landsIn = (steps + 2) * frameTime + LEAD_EXTRA
        local lx, ly = turnMath.leadPoint(px, py, x, y, direction, speed * landsIn)
        relative = turnMath.relativeBearing(lx, ly, facing, x, y)
    end

    if math.abs(relative) <= TOLERANCE then
        pitchLock.alreadyFacing()
        return true
    end
    return startTurn(relative, frameTime, {
        x = x,
        y = y,
        lead = relative - raw,
        moving = moving,
    })
end

-- Turn to the active route's current waypoint; with no beacon to facingWithoutWaypoint's facing.
function module:turnToWaypoint()
    local waypoint = self.path ~= nil and self.path.currentWaypoint or nil
    if waypoint == nil then
        local facing = self.facingWithoutWaypoint and self.facingWithoutWaypoint()
        if facing ~= nil then
            return self:turnToFacing(facing)
        end
        WowVision:notify(L["No active waypoint"])
        return false
    end
    return turnToPoint(waypoint.x, waypoint.y)
end

-- Turn to a facing (radians, as GetPlayerFacing), with the same sweep.
function module:turnToFacing(facing)
    local px, py = UnitPosition("player")
    if px == nil then
        WowVision:notify(L["Turning is not available here"])
        return false
    end
    return turnToPoint(px + math.cos(facing) * FACING_REACH, py + math.sin(facing) * FACING_REACH)
end

-- True while a turn runs or the camera is held (see holdTurns).
function module:isTurning()
    return current ~= nil or GetTime() < heldUntil
end

-- The same sweep by relative degrees (positive = right), for callers that
-- find the angle themselves (turnToUnit.lua). Needs neither the player's
-- position nor facing. options (all optional):
--   onDone(how)  when the turn ends: "landed", "aborted" or "watchdog"
--   cameraOnly   sweep the camera from where it is and leave the character
--                alone: no snap, no free-look change, no pulse; released
--                the frame after the stop
--   keepCamera   no snap at the start (the caller placed the camera); the
--                stop still pulses
--   lateStart    the call comes from a timer or an OnUpdate, not a key
--                press: primed (see startTurn)
--   fixedSpeed   degrees per second, for a search sweep
--   onFrame(moved) every frame before the step, with the degrees the camera
--                has turned so far; true stops the sweep there
-- Returns false while another turn runs, "facing" within the tolerance
-- (nothing turns, onDone is not called), true when the turn started.
function module:turnByAngle(relative, options)
    if current ~= nil then
        return false
    end
    if math.abs(relative) <= TOLERANCE then
        return "facing"
    end
    local turn = {}
    for key, value in pairs(options or {}) do
        turn[key] = value
    end
    return startTurn(relative, turnMath.frameTime(GetFramerate()), turn)
end

-- Copyable diagnostics: one line per turn, also printed to chat.
module:registerCommand({
    name = "turnlog",
    description = "Show the last turns to waypoint",
    func = function()
        local sum, count = 0, 0
        for _, line in ipairs(log) do
            local err = tonumber(line:match("error (%-?[%d%.]+)"))
            if err ~= nil then
                sum = sum + math.abs(err)
                count = count + 1
            end
        end
        local summary = count > 0 and string.format("%d turns, mean error %.1f degrees", count, sum / count)
            or "No turns yet"
        local lines = { summary }
        for _, line in ipairs(log) do
            tinsert(lines, line)
        end
        for _, line in ipairs(lines) do
            print(line)
        end
        WowVision.testing.showResults(table.concat(lines, string.char(10)))
        WowVision:speak(summary)
    end,
})

module:registerBinding({
    type = "Script",
    key = "maps/turnToWaypoint",
    label = L["Turn to Waypoint"],
    inputs = { "I" },
    script = "/run WowVision.base.navigation.maps:turnToWaypoint()",
})
