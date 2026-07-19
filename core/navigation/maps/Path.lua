--A path contains a list of waypoints
--When the start method is called, the path will constantly check the current waypoint to determine if the player has reached it.
-- Upon reaching the waypoint, the path will check for the next.
local module = WowVision.base.navigation.maps

local function distanceSquared(x1, y1, x2, y2)
    return (x2 - x1) ^ 2 + (y2 - y1) ^ 2
end

local Path = WowVision.Class("Path")
module.Path = Path

function Path:initialize()
    self.waypoints = {}
    self.active = false
    self.complete = false
    self.events = {
        arriveAtWaypoint = WowVision.Event:new("arriveAtWaypoint"),
        complete = WowVision.Event:new("complete"),
    }
    self.beacon = nil
end

function Path:add(waypoint)
    tinsert(self.waypoints, waypoint)
end

function Path:start()
    self.beacon = nil
    self.active = true
    self.currentIndex = 1
    self.currentWaypoint = self.waypoints[1]
    if self.waypoints[1] then
        self.beacon = module.Beacon:new(self.waypoints[1])
    end
end

-- Manually shift the active waypoint (Sku's next/previous waypoint keys,
-- for when you are displaced or realigning after a mistake). Treated
-- exactly like arriving: the arrival cue fires and the beacon retargets.
-- The index clamps at the route's ends -- only physically reaching the
-- final waypoint completes the route. Returns the new waypoint, or nil if
-- already at that end.
function Path:moveBy(offset)
    if not self.active or self.complete then
        return nil
    end
    local target = self.currentIndex + offset
    if target > #self.waypoints then
        target = #self.waypoints
    elseif target < 1 then
        target = 1
    end
    if target == self.currentIndex then
        return nil
    end
    self.events.arriveAtWaypoint:emit(self, self.currentWaypoint)
    self.currentIndex = target
    self.currentWaypoint = self.waypoints[target]
    self.beacon = module.Beacon:new(self.currentWaypoint)
    return self.currentWaypoint
end

function Path:update()
    if not self.active or self.complete then
        return nil
    end
    if self.currentIndex > #self.waypoints then
        self.events.complete:emit(self)
        self.active = false
        self.complete = true
        self.beacon = nil
        return
    end
    local x1, y1 = UnitPosition("player")
    local x2, y2 = self.currentWaypoint.x, self.currentWaypoint.y
    local range = module:arrivalDistance()
    if distanceSquared(x1, y1, x2, y2) <= range * range then
        self.events.arriveAtWaypoint:emit(self, self.currentWaypoint)
        self.currentIndex = self.currentIndex + 1
        self.currentWaypoint = self.waypoints[self.currentIndex]
        if self.currentWaypoint then
            self.beacon = module.Beacon:new(self.currentWaypoint)
        else
            self.beacon = nil
        end
    end
    if self.beacon then
        self.beacon:update()
    end
end
