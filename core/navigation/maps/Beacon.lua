local module = WowVision.base.navigation.maps

local Beacon = WowVision.Class("Beacon")
module.Beacon = Beacon

local atan2 = math.atan2
local sqrt = math.sqrt
local deg = math.deg
local floor = math.floor
local abs = math.abs

function Beacon:initialize(waypoint)
    self.waypoint = waypoint
    -- Resolved lazily so the beacon audio pack is registered by the time we play.
    self.source = module:getBeaconSource()
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

function Beacon:update()
    if not self.source then
        return
    end
    local distance, relative = self:compute()
    if not distance then
        return
    end

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

    -- The file's distance index is a compressed proximity bucket (~6 yards per
    -- step), NOT raw yards, so the beacon stays audible out to a long range
    -- instead of collapsing to the near-silent max-distance file a few yards out.
    local fileDistance = floor((distance + 5) / 6)
    if fileDistance < 1 then
        fileDistance = 1
    end

    self.source:play(relative, fileDistance)
end
