local module = WowVision.base.navigation.maps

local Beacon = WowVision.Class("Beacon")
module.Beacon = Beacon

function Beacon:initialize(waypoint)
    self.waypoint = waypoint
end

function Beacon:update()
    local x1, y1 = UnitPosition("player")
    local distanceSquared = (self.waypoint.x - x1) ^ 2 + (self.waypoint.y - y1) ^ 2
end
