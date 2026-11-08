-- Visited waypoints (Navigation menu): the destinations picked in the navigation window (F10) are remembered once
-- they are reached -- the picked destination only, not the waypoints of the route there -- and count as visited for
-- the set minutes (a respawn timer, on the real clock, across reloads and logouts). The destination list then says
-- "Visited" first. Remembered per character (the module's data); the module's Enabled toggle switches it all off.
--
-- Two key bindings (none set by default) lead to the nearest unvisited destination of the same name as the last one
-- picked (the next Peacebloom, the next Sack of Hay): one routes there, one sets it as a direct point. Chained, they
-- walk all spawns of an object.
local store = WowVision.visitedStore
local maps = WowVision.base.navigation.maps

local module = WowVision.base.navigation:createModule("visited")
local L = module.L
module:setLabel(L["Visited Waypoints"])
local settings = module:hasSettings()

settings:add({
    key = "minutes",
    type = "Number",
    label = L["Visited For (Minutes)"],
    default = 15,
    min = 1,
    max = 1440,
})

function module:getDefaultData()
    return { points = {} }
end

local function now()
    return GetServerTime ~= nil and GetServerTime() or time()
end

local function points(self)
    if self.data == nil then
        return nil
    end
    if self.data.points == nil then
        self.data.points = {}
    end
    return self.data.points
end

local function keyOf(wp)
    local _, _, _, map = UnitPosition("player")
    return store.key(wp, map)
end

function module:isVisited(wp)
    local list = points(self)
    if not self:getEnabled() or list == nil or wp == nil then
        return false
    end
    return store.isVisited(list, keyOf(wp), now(), self.settings.minutes)
end

-- A picked destination was reached.
function module:markVisited(wp)
    local list = points(self)
    if not self:getEnabled() or list == nil or wp == nil then
        return
    end
    local t = now()
    store.prune(list, t, self.settings.minutes)
    store.mark(list, keyOf(wp), t)
end

function module:forget()
    local list = points(self)
    if list ~= nil then
        store.forget(list)
    end
    WowVision:notify(L["Visited waypoints forgotten"])
end

function module:getGraphMenuItems(builder)
    builder:addItem(
        WowVision.graph.ControlId.structural("forgetVisited"),
        WowVision.graph.nodes.button({
            label = L["Forget Visited Waypoints"],
            onActivate = function()
                module:forget()
            end,
        })
    )
end

-- The nearest unvisited destination named like the last one picked in F10; routed to, or set as a direct point.
function module:goToNext(direct)
    local last = maps.lastDestination
    if last == nil then
        WowVision:notify(L["Choose a destination in the navigation window first"])
        return false
    end
    local lastKey = keyOf(last)
    local best = store.nearest(maps:destinationsNamed(last.n, direct), function(wp)
        return keyOf(wp) == lastKey or self:isVisited(wp)
    end)
    local name = store.baseName(last.n, function(s)
        return s
    end)
    if best == nil then
        WowVision:notify(string.format(L["No unvisited %s found"], name or ""))
        return false
    end
    return maps:goToDestination(best.waypoint, direct)
end

module:registerBinding({
    type = "Script",
    key = "visited/routeToNext",
    label = L["Route to the Nearest Unvisited of the Same Name"],
    inputs = {},
    script = "/run WowVision.base.navigation.visited:goToNext(false)",
})

module:registerBinding({
    type = "Script",
    key = "visited/directToNext",
    label = L["Direct to the Nearest Unvisited of the Same Name"],
    inputs = {},
    script = "/run WowVision.base.navigation.visited:goToNext(true)",
})
