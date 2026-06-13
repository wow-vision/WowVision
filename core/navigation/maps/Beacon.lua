local module = WowVision.base.navigation.maps

local Beacon = WowVision.Class("Beacon")
module.Beacon = Beacon

local atan2 = math.atan2
local sqrt = math.sqrt
local deg = math.deg
local abs = math.abs

-- How close to dead-ahead (degrees) counts as aligned for the click/clack cue.
local ALIGN_DEGREES = 10

function Beacon:initialize(waypoint)
    self.waypoint = waypoint
    self.nextPlay = 0
end

-- Returns distance (yards) to the waypoint and the bearing to it RELATIVE to the
-- player's facing, in degrees in (-180, 180]. 0 = dead ahead, positive = the
-- target is to the player's right.
--
-- The bearing is the world angle to the target measured clockwise from the
-- facing axis (-atan2(dy, dx)) plus the player's normalized facing. This matches
-- the convention the directional sound files are authored in (degree -180..180).
function Beacon:compute()
    local px, py = UnitPosition("player")
    local facing = GetPlayerFacing()
    if not px or not facing then
        return nil
    end
    local wp = self.waypoint
    local dx = wp.x - px
    local dy = wp.y - py
    local distance = sqrt(dx * dx + dy * dy)

    local bearing = -deg(atan2(dy, dx))
    local facingDeg = deg(facing)
    if facingDeg > 180 then
        facingDeg = facingDeg - 360
    end
    local relative = bearing + facingDeg
    if relative > 180 then
        relative = relative - 360
    elseif relative < -180 then
        relative = relative + 360
    end

    return distance, relative
end

-- Edge-triggered alignment cue. Initialized silently so a cue only fires when the
-- player actually crosses the alignment threshold by turning.
function Beacon:updateAlignment(relative)
    local within = abs(relative) <= ALIGN_DEGREES
    if self.aligned == nil then
        self.aligned = within
    elseif within and not self.aligned then
        self.aligned = true
        module:fireAlert("aligned", {})
    elseif not within and self.aligned then
        self.aligned = false
        module:fireAlert("unaligned", {})
    end
end

function Beacon:update()
    local distance, relative = self:compute()
    if not distance then
        return
    end

    -- Check alignment every frame (not gated by the ping throttle) so turning
    -- onto or off the target is responsive.
    self:updateAlignment(relative)

    -- Ping faster the more directly the target is ahead, so turning toward it is
    -- audible feedback: ~0.7s off-axis down to ~0.3s when aimed at it.
    local pingRate = 1.3
    local off = abs(relative)
    if off < 45 then
        pingRate = 1.3 - (1 - off / 45)
    end
    if pingRate < 0.2 then
        pingRate = 0.2
    elseif pingRate > 0.7 then
        pingRate = 0.7
    end

    local now = GetTime()
    if now < self.nextPlay then
        return
    end
    self.nextPlay = now + pingRate

    -- The Beacon output maps yards to the file's compressed distance index and
    -- plays the directional sound.
    module:fireAlert("beacon", { angle = relative, distance = distance })
end
