-- A WowNav route walked with WowVision's own beacon: the normal Path (beacon, arrival cue, Ctrl-W/S, Shift-F12, the
-- turn key all read it as before), whose waypoints are the route's (route.lua) and whose moving on is decided by
-- route.lua with WowNav's rules. The path mirrors the route: its waypoints follow route.path (a re-entry shortens it),
-- its current waypoint follows route.pathIndex.

local maps = WowVision.base.navigation.maps

local WowNavPath = WowVision.Class("WowNavPath", maps.Path)
WowVision.WowNavPath = WowNavPath

-- engine: the wownav module (it speaks and reacts to the route's events); route: the running wownavRoute.
function WowNavPath:initialize(engine, route, label)
    maps.Path.initialize(self)
    self.engine = engine
    self.route = route
    self.label = label
    self:sync()
end

-- The waypoints of the route as positions for the beacon; the last one carries the target's name.
function WowNavPath:sync()
    local route = self.route
    if route.path == self.mirrored then
        return
    end
    self.mirrored = route.path
    local N = route.N
    local waypoints = {}
    for i, id in ipairs(route.path or {}) do
        local x, y, z = N.Position(id)
        waypoints[i] = { id = id, x = x, y = y, z = z }
    end
    if #waypoints > 0 then
        waypoints[#waypoints].n = self.label
    end
    self.waypoints = waypoints
    self.currentIndex = nil
end

-- The current waypoint follows the route; the beacon retargets when it changes.
function WowNavPath:follow()
    self:sync()
    local index = self.route.pathIndex
    if index ~= self.currentIndex then
        self.currentIndex = index
        self.currentWaypoint = self.waypoints[index]
        self.beacon = self.currentWaypoint and maps.Beacon:new(self.currentWaypoint) or nil
    end
end

function WowNavPath:start()
    self.active = true
    self.complete = false
    self.currentIndex = nil
    self:follow()
end

-- Ctrl-W / Ctrl-S: the route's own step (his /vn next and /vn prev), with WowVision's arrival cue.
function WowNavPath:moveBy(offset)
    if not self.active or self.complete or not self.route.active then
        return nil
    end
    if not self.route:selectIndex(self.route.pathIndex + offset) then
        return nil
    end
    self.events.arriveAtWaypoint:emit(self, self.currentWaypoint)
    self:follow()
    return self.currentWaypoint
end

function WowNavPath:finish()
    self.active = false
    self.complete = true
    self.beacon = nil
end

function WowNavPath:update()
    if not self.active or self.complete then
        return nil
    end
    local x, y = UnitPosition("player")
    if x == nil then
        return
    end
    local event = self.route:update(x, y)
    if event ~= nil then
        if event.kind == "advance" then
            self.events.arriveAtWaypoint:emit(self, self.currentWaypoint)
        end
        self:follow()
        self.engine:onRouteEvent(self, event)
    end
    if self.beacon and not self.complete then
        self.beacon:update()
    end
end
