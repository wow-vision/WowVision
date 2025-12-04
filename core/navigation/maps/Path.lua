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
    if distanceSquared(x1, y1, x2, y2) <= 9 then
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
