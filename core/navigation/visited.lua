-- Visited waypoints (Navigation menu): the destinations picked in the navigation window (F10) are remembered once
-- they are reached -- the picked destination only, not the waypoints of the route there -- and count as visited for
-- the set minutes (a respawn timer, on the real clock, across reloads and logouts). The destination list then says
-- "Visited" first. Remembered per character (the module's data); the module's Enabled toggle switches it all off.
--
-- Two key bindings (none set by default) lead to the nearest unvisited destination of the same name as the last one
-- picked (the next Peacebloom, the next Sack of Hay): one routes there, one sets it as a direct point. Chained, they
-- walk all spawns of an object. They pick as auto mode does (the route key by the shortest walk) and do not offer a
-- spot they led to again until another destination is picked; while an auto chain runs, either key steps it on.
--
-- Auto mode chains that by itself (Shift-F10 on a destination in F10): each one reached leads on to the next
-- unvisited one of the same name, until none is left. Auto Direct sets a direct point to the nearest in a straight
-- line; Auto Route routes to the one the shortest walk reaches, of the AUTO_CANDIDATES nearest. It needs the visited
-- waypoints switched on: they are what the chain skips. The chain leads only the legs it starts: any other guidance
-- (another destination, a beacon, Ctrl-Shift-R) or Shift-F12 ends it, and so does its last spot; Ctrl-Shift-N
-- restarts a leg and keeps the chain. Ctrl-W and Ctrl-S step through the chain like through a route: past the end of
-- a leg (a direct point is a leg of one point) the next spot -- one led to before, or the nearest one the chain has
-- not led to yet -- and before its start the spot before; a leg that found no route is stepped past the same way.
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

-- How many of the nearest unvisited ones a route to the next is measured by the walk (a route engine plans one
-- route each).
local AUTO_CANDIDATES = 8

-- Where the next leg after `last` may go: the nearest unvisited one of its name (direct), or the AUTO_CANDIDATES
-- nearest for the walk to decide, as { waypoint, distance }; none that is `last` or in seen ({ [key] = true }). Then
-- the waypoints and engine they came from (maps:destinationsNamed).
local function nextCandidates(self, last, direct, seen)
    local lastKey = keyOf(last)
    local function skip(wp)
        local key = keyOf(wp)
        return key == lastKey or seen[key] or self:isVisited(wp)
    end
    local found, waypoints, engine = maps:destinationsNamed(last.n, direct)
    if direct then
        local best = store.nearest(found, skip)
        return best ~= nil and { best } or {}, waypoints, engine
    end
    return store.nearestN(found, skip, AUTO_CANDIDATES), waypoints, engine
end

local function sayNoneLeft(last)
    local name = store.baseName(last.n, function(s)
        return s
    end)
    WowVision:notify(string.format(L["No unvisited %s found"], name or ""))
end

-- The keys' own memory: { last = the spot they led to, seen = { [key] = true } (every spot they led to since a
-- destination was picked another way: one left before it was reached is not visited and would come back) }.
module.steps = nil

-- The nearest unvisited destination named like the last one picked in F10: set as a direct point, or routed to the
-- one the shortest walk reaches. A running auto chain steps on instead (as Ctrl-W past the end of its leg).
function module:goToNext(direct)
    if self.auto ~= nil then
        return self:stepAuto(1)
    end
    local last = maps.lastDestination
    if last == nil then
        WowVision:notify(L["Choose a destination in the navigation window first"])
        return false
    end
    local steps = self.steps
    if steps == nil or steps.last ~= last then
        steps = { seen = {} }
        self.steps = steps
    end
    steps.seen[keyOf(last)] = true
    local candidates, waypoints, engine = nextCandidates(self, last, direct, steps.seen)
    if #candidates == 0 then
        sayNoneLeft(last)
        return false
    end
    if direct then
        steps.last = candidates[1].waypoint
        return maps:goToDestination(steps.last, true)
    end
    return maps:routeToNearestWalk(candidates, function(wp)
        steps.last = wp
    end, waypoints, engine)
end

-- The running chain: { mode = "direct" | "route", targets = { [wp] = true } (the destinations the leg it leads may
-- end at), history = { wp, ... } (the spots it led to, in order), index (the current one), seen = { [key] = true }
-- (every spot it led to: a skipped one is not visited and would come back) }.
module.auto = nil

-- wp becomes the chain's current spot, after the one it is at (what came after that is dropped).
local function setCurrent(auto, wp)
    for i = #auto.history, auto.index + 1, -1 do
        auto.history[i] = nil
    end
    tinsert(auto.history, wp)
    auto.index = #auto.history
    auto.seen[keyOf(wp)] = true
    auto.targets = { [wp] = true }
end

-- A chain's leg goes through maps:leadingChain: guidance started any other way ends the chain.
local function lead(start)
    return maps:leadingChain(start)
end

local function autoAllowed(self)
    if self:getEnabled() then
        return true
    end
    WowVision:notify(L["Auto mode needs Visited Waypoints switched on"])
    return false
end

-- Shift-F10 on a destination in F10: the chain starts there, its first leg from the entry point picked in F10
-- (start, nil: the one F10 would preselect).
function module:startAuto(wp, mode, start)
    if not autoAllowed(self) then
        return false
    end
    self:endAuto()
    local auto = { mode = mode, history = {}, index = 0, seen = {} }
    setCurrent(auto, wp)
    self.auto = auto
    WowVision:notify(mode == "route" and L["Auto Route"] or L["Auto Direct"])
    maps:closeWindowsForGuidance(true)
    return lead(function()
        return maps:goToDestination(wp, mode == "direct", start)
    end)
end

-- The chain ends: Shift-F12, guidance it did not start, its last spot, Visited Waypoints switched off.
function module:endAuto()
    if self.auto == nil then
        return
    end
    self.auto = nil
end

-- Whether wp is where the running chain's leg leads (Ctrl-Shift-N keeps the chain then).
function module:leads(wp)
    return self.auto ~= nil and wp ~= nil and self.auto.targets[wp] == true
end

-- A picked destination was reached (maps:arrivalFor, after markVisited): the chain that led there goes on, a frame
-- later -- the arrival's own words come first, and a route engine finishes its arrival before the next route starts.
function module:continueAuto(wp)
    local auto = self.auto
    if auto == nil or not auto.targets[wp] then
        return
    end
    auto.targets = {}
    if not autoAllowed(self) then
        self:endAuto()
        return
    end
    C_Timer.After(0, function()
        if self.auto == auto then
            self:autoStep(auto, wp, 1)
        end
    end)
end

-- The next leg of a chain after `last`: the nearest unvisited one of its name it has not led to, or the end of the
-- chain (said; the leg it leads stays).
function module:autoNext(auto, last)
    local direct = auto.mode == "direct"
    local candidates, waypoints, engine = nextCandidates(self, last, direct, auto.seen)
    if #candidates == 0 then
        sayNoneLeft(last)
        self:endAuto()
        return false
    end
    if direct then
        setCurrent(auto, candidates[1].waypoint)
        return lead(function()
            return maps:goToDestination(candidates[1].waypoint, true)
        end)
    end
    -- the walk decides which one, perhaps later (a route engine plans in the background): every candidate may be it
    auto.targets = {}
    for _, candidate in ipairs(candidates) do
        auto.targets[candidate.waypoint] = true
    end
    return lead(function()
        return maps:routeToNearestWalk(candidates, function(wp)
            if self.auto == auto then
                setCurrent(auto, wp)
            end
        end, waypoints, engine)
    end)
end

-- Ctrl-W / Ctrl-S past the ends of the leg a chain leads, or on a leg that found no route (maps:stepWaypoint): the
-- spot after (one led to before, or the next of the chain) or before. The leg's destinations not reached are passed
-- over from then on. False when no chain runs: the step says the route's end as before.
function module:stepAuto(offset)
    local auto = self.auto
    local current = auto ~= nil and auto.history[auto.index] or nil
    if current == nil then
        return false
    end
    for wp in pairs(auto.targets) do
        auto.seen[keyOf(wp)] = true
    end
    self:autoStep(auto, current, offset)
    return true
end

-- One spot on in the chain from `current` (offset 1, an arrival or Ctrl-W) or back (-1): the one led to before
-- (after a step back), else the next of the chain.
function module:autoStep(auto, current, offset)
    local step = offset > 0 and 1 or -1
    local wp = auto.history[auto.index + step]
    if wp == nil and step < 0 then
        WowVision:notify(L["Start of route"])
        return false
    end
    if wp == nil then
        return self:autoNext(auto, current)
    end
    auto.index = auto.index + step
    auto.targets = { [wp] = true }
    return lead(function()
        return maps:goToDestination(wp, auto.mode == "direct")
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
