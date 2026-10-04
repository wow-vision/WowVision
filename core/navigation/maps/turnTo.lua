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

local TOLERANCE = 3 -- degrees: already facing it, do nothing
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

local function release(turn)
    if current == turn then
        current = nil
        turnFrame:SetScript("OnUpdate", nil)
    end
end

local function stopSweep(turn)
    stopCamera()
    restoreYawSpeed()
    camera.transfer()
    turn.stopFrame = turn.sweep.frames
    turn.framesSinceStop = 0
    turn.landX, turn.landY = UnitPosition("player")
    pitchLock.afterTurn()
end

local function measure(turn)
    local endFacing = GetPlayerFacing()
    if endFacing == nil then
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
            release(turn)
            measure(turn)
        end
        return
    end
    local flags = WowVision.movement.flags
    if flags.turnLeft or flags.turnRight then
        -- The player took over: stop where we are, no pulse.
        stopCamera()
        restoreYawSpeed()
        release(turn)
        return
    end
    if #turn.frameMs < 24 then
        tinsert(turn.frameMs, string.format("%.0f", delta * 1000))
    end
    local action, fraction = turn.sweep:frame(delta)
    if action == "stop" then
        stopSweep(turn)
    elseif action == "trim" then
        SetCVar("cameraYawMoveSpeed", turn.cvar * fraction)
    end
end

-- Turn to the active route's current waypoint.
function module:turnToWaypoint()
    local waypoint = self.path ~= nil and self.path.currentWaypoint or nil
    if waypoint == nil then
        WowVision:speak(L["No active waypoint"])
        return false
    end
    if current ~= nil then
        return false
    end
    local px, py = UnitPosition("player")
    local facing = GetPlayerFacing()
    if px == nil or facing == nil then
        -- Retail hides the player's facing and position in instances.
        WowVision:speak(L["Turning is not available here"])
        return false
    end
    local frameTime = turnMath.frameTime(GetFramerate())

    -- Aim at the bearing the waypoint will have when the turn lands. Close
    -- to a waypoint the bearing moves fast; without the lead, moving
    -- players circle it.
    local raw = turnMath.relativeBearing(px, py, facing, waypoint.x, waypoint.y)
    local relative = raw
    local moving = 0
    local direction = turnMath.moveDirection(facing, WowVision.movement.flags)
    local speed = GetUnitSpeed("player")
    if direction ~= nil and speed ~= nil and not WowVision.isSecret(speed) and speed > 0 then
        moving = speed
        local _, steps = turnMath.plan(math.abs(raw), frameTime)
        local landsIn = (steps + 2) * frameTime + LEAD_EXTRA
        local lx, ly = turnMath.leadPoint(px, py, waypoint.x, waypoint.y, direction, speed * landsIn)
        relative = turnMath.relativeBearing(lx, ly, facing, waypoint.x, waypoint.y)
    end

    if math.abs(relative) <= TOLERANCE then
        pitchLock.alreadyFacing()
        return true
    end

    local target = math.abs(relative)
    local sweepSpeed, steps = turnMath.plan(target, frameTime)
    local cvar = math.min(sweepSpeed, turnMath.CVAR_MAX)
    local turn = {
        x = waypoint.x,
        y = waypoint.y,
        target = target,
        direction = relative > 0 and 1 or -1,
        speed = sweepSpeed,
        steps = steps,
        cvar = cvar,
        frameTime = frameTime,
        settleFrames = math.max(SETTLE_MIN_FRAMES, math.ceil(SETTLE_MIN_TIME / frameTime - 1e-9)),
        sweep = turnMath.newSweep(target, sweepSpeed, steps),
        startFacing = facing,
        lastTime = GetTime(),
        frameMs = {},
        lead = relative - raw,
        moving = moving,
    }
    current = turn

    pitchLock.noteTurn()
    stopCamera()
    camera.align()
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
        release(turn)
        addLog("watchdog stopped a turn")
    end)
    return true
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
