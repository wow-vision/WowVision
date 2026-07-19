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
-- Any commanded movement or turning aborts immediately and restores the
-- camera speed CVar.

local YAW_SPEED = 400 -- degrees/second while sweeping (via cameraYawMoveSpeed)
local TOLERANCE = 3 -- degrees: already facing it, skip the sweep
-- MoveViewStop does not halt instantly: the camera eases out past the
-- stop, so after stopping we wait for the glide to settle before the final
-- snap. Corrective re-sweeps are disabled for now: single sweep, settle,
-- snap, done.
local SETTLE_DELAY = 0.35
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
local calibration = nil -- { speed, coast }

local function wrapDegrees(value)
    while value > 180 do
        value = value - 360
    end
    while value <= -180 do
        value = value + 360
    end
    return value
end

local function recordSample(duration, turned, startFacing, endFacing)
    tinsert(samples, { duration = duration, turned = turned, startFacing = startFacing, endFacing = endFacing })
    if #samples > 50 then
        tremove(samples, 1)
    end
    local usable = 0
    for _, sample in ipairs(samples) do
        if sample.turned ~= nil and sample.turned >= 1 then
            usable = usable + 1
        end
    end
    if usable < 3 then
        return
    end
    local n, sumX, sumY, sumXY, sumXX = #samples, 0, 0, 0, 0
    for _, sample in ipairs(samples) do
        sumX = sumX + sample.duration
        sumY = sumY + sample.turned
        sumXY = sumXY + sample.duration * sample.turned
        sumXX = sumXX + sample.duration * sample.duration
    end
    local denom = n * sumXX - sumX * sumX
    if math.abs(denom) < 1e-6 then
        return -- all samples the same size; no usable spread
    end
    local speed = (n * sumXY - sumX * sumY) / denom
    local coast = (sumY - speed * sumX) / n
    -- Sanity clamp: reject nonsense fits rather than aiming with them.
    if speed > 100 and speed < 1200 and coast > -30 and coast < 90 then
        calibration = { speed = speed, coast = coast }
        -- Persist so calibration survives reloads (hidden settings).
        module.settings.turnSpeed = speed
        module.settings.turnCoast = coast
    end
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

local function playerInterfered()
    local flags = WowVision.movement.flags
    return WowVision.movement:isTranslating() or flags.turnLeft or flags.turnRight
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

    -- One sweep toward the target; the character follows at the final
    -- snap after the glide settles. Aim with the measured calibration when
    -- one exists, else the constants.
    local duration
    if calibration ~= nil then
        duration = (math.abs(relative) - calibration.coast) / calibration.speed
    else
        duration = math.abs(relative) / YAW_SPEED - GLIDE_ALLOWANCE
    end
    if duration < 0.02 then
        duration = 0.02
    end
    state.duration = duration

    if relative > 0 then
        CAMERA_RIGHT_START(1)
    else
        CAMERA_LEFT_START(1)
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
                local endFacing = math.deg(GetPlayerFacing() or 0)
                local turned = math.abs(wrapDegrees((current.startFacing or 0) - endFacing))
                recordSample(current.duration, turned, current.startFacing, endFacing)
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
        if calibration ~= nil then
            tinsert(lines, string.format("fit: speed %.1f deg/s, coast %.1f deg", calibration.speed, calibration.coast))
        else
            tinsert(lines, "fit: none yet (need 3+ samples of different sizes)")
        end
        tinsert(lines, string.format("constants: speed %d, allowance %.2f, settle %.2f", YAW_SPEED, GLIDE_ALLOWANCE, SETTLE_DELAY))
        for i, sample in ipairs(samples) do
            tinsert(lines, string.format(
                "%d: duration %.3fs -> turned %.1f deg (facing %.1f -> %.1f)",
                i,
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
settings:add({ key = "turnSpeed", type = "Number", persist = true, showInUI = false })
settings:add({ key = "turnCoast", type = "Number", persist = true, showInUI = false })

local turnToEnableParent = module.onFullEnable
function module:onFullEnable(...)
    if turnToEnableParent ~= nil then
        turnToEnableParent(self, ...)
    end
    local speed = self.settings.turnSpeed
    local coast = self.settings.turnCoast
    if speed ~= nil and coast ~= nil and speed > 100 and speed < 1200 then
        calibration = { speed = speed, coast = coast }
    end
end

module:registerBinding({
    type = "Script",
    key = "maps/turnToWaypoint",
    label = L["Turn to Waypoint"],
    inputs = { "I" },
    script = "/run WowVision.base.navigation.maps:turnToWaypoint()",
})
