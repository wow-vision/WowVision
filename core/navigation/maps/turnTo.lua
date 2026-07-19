local module = WowVision.base.navigation.maps
local L = module.L

-- Turn the character to face the current route waypoint (Sku's camera trick,
-- rebuilt closed-loop):
--
-- Addons cannot turn the character directly (SetFacing is protected), but
-- the CAMERA rotates freely, and a MouselookStart/Stop flicker snaps the
-- character's facing to the camera yaw. So: flicker FIRST to align camera
-- and character (this replaces Sku's SetView(2) preset -- no dependency on
-- what a user saved in a camera slot, and nothing about their camera setup
-- is stomped except yaw), measure the bearing from the fresh facing, sweep
-- the camera that many degrees at a known speed, flicker to land, then
-- MEASURE the error and run up to two short corrective sweeps -- Sku aims
-- once, open loop, with a hard-coded five-degree fudge; we converge.
--
-- Manual turn keys abort immediately and restore the camera speed CVar;
-- translation (running, strafing) is allowed -- turning on the move works,
-- at reduced accuracy, and such turns are excluded from calibration.

local YAW_SPEED = 400 -- cameraYawMoveSpeed while sweeping
-- The MoveView argument MULTIPLIES the cvar speed. But sweep length has a
-- FLOOR: timers and the stop land on frame boundaries, so the shortest
-- possible sweep covers a frame or two of rotation -- ~95 degrees at the
-- 4x factor (measured). So: TWO TIERS. Big turns sweep fast; turns below
-- the fast tier's floor sweep at 1x, whose floor is a few degrees. Each
-- tier calibrates independently.
local TIERS = {
    fast = { factor = 4, assumedSpeed = 1600, assumedCoast = 72 },
    slow = { factor = 1, assumedSpeed = 400, assumedCoast = 10 },
}
-- Use the fast tier only when the angle clears its floor with margin.
local FAST_THRESHOLD = 130
-- Changing the sweep setup invalidates stored calibrations.
local CALIBRATION_VERSION = 3
local TOLERANCE = 3 -- degrees: already facing it, skip the sweep
-- MoveViewStop does not halt instantly: the camera eases out past the
-- stop, so after stopping we wait for the glide to settle before the final
-- snap. Corrective re-sweeps are disabled for now: single sweep, settle,
-- snap, done.
local SETTLE_DELAY = 0.1
-- The glide covers ground after the stop, and it grows with speed: end the
-- sweep this many seconds early and let the coast finish the angle. Tune
-- together with YAW_SPEED -- landing consistently short means lower it,
-- consistently past means raise it.
local GLIDE_ALLOWANCE = 0.06

-- Positive relative bearing = target to the RIGHT (Beacon's convention).
-- Verified in game: MoveViewLeftStart yaws the character's facing RIGHT
-- after a mouselook snap (the camera orbits opposite the view direction).
local CAMERA_RIGHT_START = MoveViewLeftStart
local CAMERA_LEFT_START = MoveViewRightStart

local turning = nil -- { waypoint, savedYawSpeed, startFacing, requested, duration }
local sweepAimed

-- ---------------------------------------------------------------------------
-- Self-calibration: every completed turn records (commanded duration,
-- degrees actually turned). With three or more samples a least-squares fit
-- gives the TRUE effective sweep speed (slope) and the coast the glide adds
-- (intercept), and later turns aim with those instead of the constants.
-- /wv turnlog dumps the samples and the current fit, copyable.
-- ---------------------------------------------------------------------------

local samples = {}
local calibrations = { fast = nil, slow = nil } -- tier -> { speed, coast }

local function wrapDegrees(value)
    while value > 180 do
        value = value - 360
    end
    while value <= -180 do
        value = value + 360
    end
    return value
end

local function fitTier(tier)
    local n, sumX, sumY, sumXY, sumXX = 0, 0, 0, 0, 0
    for _, sample in ipairs(samples) do
        if sample.tier == tier and sample.turned ~= nil and sample.turned >= 1 then
            n = n + 1
            sumX = sumX + sample.duration
            sumY = sumY + sample.turned
            sumXY = sumXY + sample.duration * sample.turned
            sumXX = sumXX + sample.duration * sample.duration
        end
    end
    if n < 3 then
        return
    end
    local denom = n * sumXX - sumX * sumX
    if math.abs(denom) < 1e-6 then
        return -- no usable spread
    end
    local speed = (n * sumXY - sumX * sumY) / denom
    local coast = (sumY - speed * sumX) / n
    -- Sanity clamp: reject nonsense fits rather than aiming with them.
    if speed > 50 and speed < 4000 and coast > -30 and coast < 150 then
        calibrations[tier] = { speed = speed, coast = coast }
        -- Persist so calibration survives reloads (hidden settings).
        module.settings["turnSpeed_" .. tier] = speed
        module.settings["turnCoast_" .. tier] = coast
        module.settings.turnCalVersion = CALIBRATION_VERSION
    end
end

local function recordSample(tier, duration, turned, startFacing, endFacing)
    tinsert(samples, {
        tier = tier,
        duration = duration,
        turned = turned,
        startFacing = startFacing,
        endFacing = endFacing,
    })
    if #samples > 60 then
        tremove(samples, 1)
    end
    fitTier(tier)
end

local function snapCharacterToCamera()
    MouselookStart()
    MouselookStop()
end

-- Relative bearing to (x, y) in degrees, positive = right (Beacon math).
local function relativeBearing(x, y)
    local px, py = UnitPosition("player")
    local facing = GetPlayerFacing()
    if px == nil or facing == nil then
        return nil
    end
    local bearing = -math.deg(math.atan2(y - py, x - px))
    local facingDeg = math.deg(facing)
    if facingDeg > 180 then
        facingDeg = facingDeg - 360
    end
    local relative = bearing + facingDeg
    if relative > 180 then
        relative = relative - 360
    elseif relative <= -180 then
        relative = relative + 360
    end
    return relative
end

local function stopCamera()
    MoveViewLeftStop()
    MoveViewRightStop()
end

local function finishTurn(announce)
    local state = turning
    turning = nil
    if state == nil then
        return
    end
    stopCamera()
    SetCVar("cameraYawMoveSpeed", state.savedYawSpeed)
    if announce then
        local name = state.waypoint.n
        WowVision:speak(name ~= nil and (L["Facing"] .. " " .. name) or L["Facing"])
    end
end

-- Moving is ALLOWED during a turn (hold W and hit the key to curve toward
-- the waypoint, like Sku) -- it just costs accuracy, since the bearing
-- shifts under us mid-sweep. Only the manual turn keys abort: they fight
-- the camera sweep directly.
local function playerInterfered()
    local flags = WowVision.movement.flags
    return flags.turnLeft or flags.turnRight
end

-- Turns taken while moving skip calibration: the follow-camera and the
-- shifting bearing corrupt the duration-to-degrees measurement.
local function noteMovement(state)
    if WowVision.movement:isTranslating() then
        state.moved = true
    end
end

-- The mouselook flicker applies its facing change on the NEXT frame, not
-- synchronously -- reading GetPlayerFacing right after the snap returns the
-- old value (proven by calibration logs with identical start and end
-- facings while the character visibly turned). Every measurement therefore
-- waits a beat after its snap.
local SNAP_LATENCY = 0.05

local function sweepStep()
    local state = turning
    if state == nil then
        return
    end
    if playerInterfered() then
        finishTurn(false)
        return
    end
    noteMovement(state)

    snapCharacterToCamera()
    C_Timer.After(SNAP_LATENCY, function()
        if turning ~= state then
            return
        end
        sweepAimed(state)
    end)
end

sweepAimed = function(state)
    if playerInterfered() then
        finishTurn(false)
        return
    end
    noteMovement(state)
    local relative = relativeBearing(state.waypoint.x, state.waypoint.y)
    if relative == nil then
        finishTurn(false)
        return
    end
    if math.abs(relative) <= TOLERANCE then
        finishTurn(true)
        return
    end

    state.startFacing = math.deg(GetPlayerFacing() or 0)
    state.requested = relative

    -- Pick the tier: fast only when the angle clears the fast floor.
    local angle = math.abs(relative)
    local tierName = angle >= FAST_THRESHOLD and "fast" or "slow"
    local tier = TIERS[tierName]
    state.tier = tierName

    -- One sweep toward the target; the character follows at the final
    -- snap after the glide settles. Aim with the tier's measured
    -- calibration when one exists, else its assumptions.
    local calibration = calibrations[tierName]
    local duration
    if calibration ~= nil then
        duration = (angle - calibration.coast) / calibration.speed
    else
        duration = (angle - tier.assumedCoast) / tier.assumedSpeed
    end
    if duration < 0.02 then
        duration = 0.02
    end
    state.duration = duration

    if relative > 0 then
        CAMERA_RIGHT_START(tier.factor)
    else
        CAMERA_LEFT_START(tier.factor)
    end
    C_Timer.After(duration, function()
        stopCamera()
        C_Timer.After(SETTLE_DELAY, function()
            local current = turning
            if current == nil then
                return
            end
            snapCharacterToCamera()
            -- The snap lands next frame; measure after it has.
            C_Timer.After(SNAP_LATENCY, function()
                if turning ~= current then
                    return
                end
                noteMovement(current)
                local endFacing = math.deg(GetPlayerFacing() or 0)
                local turned = math.abs(wrapDegrees((current.startFacing or 0) - endFacing))
                if not current.moved then
                    recordSample(current.tier, current.duration, turned, current.startFacing, endFacing)
                end
                finishTurn(true)
            end)
        end)
    end)
end

-- Turn to the active route's current waypoint.
function module:turnToWaypoint()
    if turning ~= nil then
        finishTurn(false)
    end
    local waypoint = self.path ~= nil and self.path.currentWaypoint or nil
    if waypoint == nil then
        WowVision:speak(L["No active waypoint"])
        return false
    end
    turning = {
        waypoint = waypoint,
        savedYawSpeed = GetCVar("cameraYawMoveSpeed"),
    }
    SetCVar("cameraYawMoveSpeed", YAW_SPEED)
    sweepStep()
    return true
end

-- Copyable diagnostics for tuning: every sample plus the current fit.
module:registerCommand({
    name = "turnlog",
    description = "Show turn-to-waypoint calibration samples",
    func = function()
        local lines = {}
        for tierName, tier in pairs(TIERS) do
            local calibration = calibrations[tierName]
            if calibration ~= nil then
                tinsert(lines, string.format("%s fit: speed %.1f deg/s, coast %.1f deg", tierName, calibration.speed, calibration.coast))
            else
                tinsert(lines, string.format("%s fit: none yet (assumed %d deg/s, %d coast)", tierName, tier.assumedSpeed, tier.assumedCoast))
            end
        end
        tinsert(lines, string.format("fast threshold: %d deg, settle %.2f", FAST_THRESHOLD, SETTLE_DELAY))
        for i, sample in ipairs(samples) do
            tinsert(lines, string.format(
                "%d [%s]: duration %.3fs -> turned %.1f deg (facing %.1f -> %.1f)",
                i,
                sample.tier or "?",
                sample.duration or -1,
                sample.turned or -1,
                sample.startFacing or -1,
                sample.endFacing or -1
            ))
        end
        WowVision.testing.showResults(table.concat(lines, string.char(10)))
        WowVision:speak(#samples .. " samples. " .. lines[1])
    end,
})

-- Persisted calibration (hidden from the settings screen); restored on
-- enable so a reload keeps aiming with measured numbers.
local settings = module:hasSettings()
settings:add({ key = "turnSpeed_fast", type = "Number", persist = true, showInUI = false })
settings:add({ key = "turnCoast_fast", type = "Number", persist = true, showInUI = false })
settings:add({ key = "turnSpeed_slow", type = "Number", persist = true, showInUI = false })
settings:add({ key = "turnCoast_slow", type = "Number", persist = true, showInUI = false })
settings:add({ key = "turnCalVersion", type = "Number", persist = true, showInUI = false })

local turnToEnableParent = module.onFullEnable
function module:onFullEnable(...)
    if turnToEnableParent ~= nil then
        turnToEnableParent(self, ...)
    end
    if self.settings.turnCalVersion == CALIBRATION_VERSION then
        for tierName in pairs(TIERS) do
            local speed = self.settings["turnSpeed_" .. tierName]
            local coast = self.settings["turnCoast_" .. tierName]
            if speed ~= nil and coast ~= nil and speed > 50 and speed < 4000 then
                calibrations[tierName] = { speed = speed, coast = coast }
            end
        end
    end
end

module:registerBinding({
    type = "Script",
    key = "maps/turnToWaypoint",
    label = L["Turn to Waypoint"],
    inputs = { "I" },
    script = "/run WowVision.base.navigation.maps:turnToWaypoint()",
})
