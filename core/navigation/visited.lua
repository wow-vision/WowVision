-- Visited waypoints (Navigation menu): the destinations picked in the navigation window (F10) are remembered once
-- they are reached -- the picked destination only, not the waypoints of the route there -- and count as visited for
-- the set minutes (a respawn timer, on the real clock, across reloads and logouts). The destination list then says
-- "Visited" first. Remembered per character (the module's data); the module's Enabled toggle switches it all off.
--
-- Two key bindings (none set by default) lead to the nearest unvisited destination of the same name as the last one
-- picked (the next Peacebloom, the next Sack of Hay): one routes there, one sets it as a direct point. Chained, they
-- walk all spawns of an object.
--
-- Auto mode chains that by itself (Shift-F10 on a destination in F10): each one reached leads on to the next
-- unvisited one of the same name, until none is left. Auto Direct sets a direct point to the nearest in a straight
-- line; Auto Route routes to the one the shortest walk reaches, of the AUTO_CANDIDATES nearest. It needs the visited
-- waypoints switched on: they are what the chain skips. The chain belongs to the destinations it picked: another
-- destination picked, or Shift-F12, and the arrival that would continue it never comes (a replaced route never
-- arrives); Ctrl-Shift-N restarts a leg and keeps the chain.
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
    WowVision:speak(L["Visited waypoints forgotten"])
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
        WowVision:speak(L["Choose a destination in the navigation window first"])
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
        WowVision:speak(string.format(L["No unvisited %s found"], name or ""))
        return false
    end
    return maps:goToDestination(best.waypoint, direct)
end

-- How many of the nearest unvisited ones Auto Route measures by the walk (a route engine plans one route each).
local AUTO_CANDIDATES = 8

-- The running chain: { mode = "direct" | "route", targets = { [wp] = true } }, the destinations it led to last.
module.auto = nil

local function autoAllowed(self)
    if self:getEnabled() then
        return true
    end
    WowVision:speak(L["Auto mode needs Visited Waypoints switched on"])
    return false
end

-- Shift-F10 on a destination in F10: the chain starts there.
function module:startAuto(wp, mode)
    if not autoAllowed(self) then
        return false
    end
    self.auto = { mode = mode, targets = { [wp] = true } }
    WowVision:speak(mode == "route" and L["Auto Route"] or L["Auto Direct"])
    return maps:goToDestination(wp, mode == "direct")
end

-- A picked destination was reached (maps:arrivalFor, after markVisited): the chain that led there goes on, a frame
-- later -- the arrival's own words come first, and a route engine finishes its arrival before the next route starts.
function module:continueAuto(wp)
    local auto = self.auto
    if auto == nil or not auto.targets[wp] then
        return
    end
    self.auto = nil
    if not autoAllowed(self) then
        return
    end
    C_Timer.After(0, function()
        self:autoNext(auto.mode, wp)
    end)
end

-- The next leg of a chain after `last`: the nearest unvisited one of its name, or the end of the chain.
function module:autoNext(mode, last)
    local direct = mode == "direct"
    local lastKey = keyOf(last)
    local function skip(wp)
        return keyOf(wp) == lastKey or self:isVisited(wp)
    end
    local found = maps:destinationsNamed(last.n, direct)
    local candidates
    if direct then
        local best = store.nearest(found, skip)
        candidates = best ~= nil and { best } or {}
    else
        candidates = store.nearestN(found, skip, AUTO_CANDIDATES)
    end
    if #candidates == 0 then
        local name = store.baseName(last.n, function(s)
            return s
        end)
        WowVision:speak(string.format(L["No unvisited %s found"], name or ""))
        return false
    end
    if direct then
        local wp = candidates[1].waypoint
        self.auto = { mode = mode, targets = { [wp] = true } }
        return maps:goToDestination(wp, true)
    end
    -- the walk decides which one, perhaps later (a route engine plans in the background): every candidate may be it
    local auto = { mode = mode, targets = {} }
    for _, candidate in ipairs(candidates) do
        auto.targets[candidate.waypoint] = true
    end
    self.auto = auto
    return maps:routeToNearestWalk(candidates, function(wp)
        if self.auto == auto then
            auto.targets = { [wp] = true }
        end
    end)
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
