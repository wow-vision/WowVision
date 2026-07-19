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

local YAW_SPEED = 360 -- degrees/second while sweeping (via cameraYawMoveSpeed)
local TOLERANCE = 2 -- degrees: close enough to stop iterating
local MAX_SWEEPS = 3

-- Positive relative bearing = target to the RIGHT (Beacon's convention).
-- Verified in game: MoveViewLeftStart yaws the character's facing RIGHT
-- after a mouselook snap (the camera orbits opposite the view direction).
local CAMERA_RIGHT_START = MoveViewLeftStart
local CAMERA_LEFT_START = MoveViewRightStart

local turning = nil -- { waypoint, sweeps, savedYawSpeed }

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
    local relative = relativeBearing(state.waypoint.x, state.waypoint.y)
    if relative == nil then
        finishTurn(false)
        return
    end
    if math.abs(relative) <= TOLERANCE or state.sweeps >= MAX_SWEEPS then
        finishTurn(true)
        return
    end
    state.sweeps = state.sweeps + 1

    -- Sweep the camera by the remaining angle at the speed we set; the
    -- character follows at the next snap.
    if relative > 0 then
        CAMERA_RIGHT_START(1)
    else
        CAMERA_LEFT_START(1)
    end
    C_Timer.After(math.abs(relative) / YAW_SPEED, function()
        stopCamera()
        sweepStep()
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
        sweeps = 0,
        savedYawSpeed = GetCVar("cameraYawMoveSpeed"),
    }
    SetCVar("cameraYawMoveSpeed", YAW_SPEED)
    sweepStep()
    return true
end

module:registerBinding({
    type = "Script",
    key = "maps/turnToWaypoint",
    label = L["Turn to Waypoint"],
    inputs = { "I" },
    script = "/run WowVision.base.navigation.maps:turnToWaypoint()",
})
