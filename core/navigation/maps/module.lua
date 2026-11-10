local module = WowVision.base.navigation:createModule("maps")
local L = module.L
module:setLabel(L["Beacon and Routes"])
local settings = module:hasSettings()

module.datasets = WowVision.Registry:new()

-- All beacon feedback lives under one alert whose outputs are action-scoped:
-- Beacon.lua fires module:fireAlert("beacon", { action = ... }) and only the
-- output matching that action plays. Each output keeps its own enable + sound,
-- so every cue stays independently configurable under a single settings group.
local beaconAlert = module:addAlert({ key = "beacon", label = L["Beacon"] })
beaconAlert:addOutput({
    type = "Beacon",
    key = "beacon",
    action = "tick",
    label = L["Beacon Sound"],
    beacon = "WowVision/probe_mid_1",
})
beaconAlert:addOutput({
    type = "Sound",
    key = "aligned",
    action = "aligned",
    label = L["Beacon Aligned"],
    path = "Sound/WowVision/alerts/clack.mp3",
})
beaconAlert:addOutput({
    type = "Sound",
    key = "unaligned",
    action = "unaligned",
    label = L["Beacon Off Course"],
    path = "Sound/WowVision/alerts/click.mp3",
})
beaconAlert:addOutput({
    type = "Sound",
    key = "arrived",
    action = "arrived",
    label = L["Waypoint Reached"],
    path = "Sound/WowVision/alerts/success2.mp3",
})

-- How close (yards) counts as reaching a waypoint. Waypoints are treated
-- as points; the player tunes THREE arrival radii -- short, medium, long
-- -- and Alt-P cycles between them mid-route for precise or forgiving
-- movement on demand. The same radius is the minimum for WowNav's
-- waypoints, which also carry their own (camelot/wownav/module.lua).
local arrivalRanges = {
    { key = "arrivalShort", label = L["Short Range"], default = 0.3 },
    { key = "arrivalMedium", label = L["Medium Range"], default = 1 },
    { key = "arrivalLong", label = L["Long Range"], default = 3 },
}
-- Which of the three is active: a dropdown above the sliders, also cycled
-- in the field by the Alt-P binding.
settings:add({
    key = "arrivalRange",
    type = "Choice",
    label = L["Arrival Radius"],
    default = 2,
    choices = (function()
        local choices = {}
        for index, range in ipairs(arrivalRanges) do
            tinsert(choices, { label = range.label, value = index })
        end
        return choices
    end)(),
})
for _, range in ipairs(arrivalRanges) do
    settings:add({
        key = range.key,
        type = "Number",
        label = range.label,
        default = range.default,
        min = 0.1,
        max = 20,
        step = 0.1,
    })
end

function module:arrivalDistance()
    local range = arrivalRanges[self.settings.arrivalRange] or arrivalRanges[2]
    return self.settings[range.key] or range.default
end

-- The settings keys of the active radius and its three values, for code
-- that follows a change of the arrival distance.
module.arrivalDistanceKeys = { "arrivalRange" }
for _, range in ipairs(arrivalRanges) do
    tinsert(module.arrivalDistanceKeys, range.key)
end

settings:addRef("beacon", beaconAlert.parameters)

-- Alt-P cycles short -> medium -> long without opening settings.
function module:cycleArrivalDistance()
    local index = (self.settings.arrivalRange or 2) % #arrivalRanges + 1
    self.settings.arrivalRange = index
    local range = arrivalRanges[index]
    -- one decimal at most: "0.3 yards", "3 yards"
    local yards = string.format("%.1f", self.settings[range.key] or range.default):gsub("%.0$", "")
    WowVision:speak(string.format("%s, %s %s", range.label, yards, L["yards"]))
end

module:registerBinding({
    type = "Script",
    key = "maps/cycleArrivalDistance",
    label = L["Cycle Arrival Distance"],
    inputs = { "ALT-P" },
    script = "/run WowVision.base.navigation.maps:cycleArrivalDistance()",
})

-- Distance in yards from the player to a world position, nil without a
-- position (loading screens, instances the API cannot place).
function module:distanceTo(x, y)
    local px, py = UnitPosition("player")
    if px == nil or x == nil then
        return nil
    end
    local dx, dy = x - px, y - py
    return math.sqrt(dx * dx + dy * dy)
end

-- Relative direction words from the player to (x, y), using Beacon's
-- verified bearing math: 0 = dead ahead, positive = to the right.
function module:directionTo(x, y)
    local px, py = UnitPosition("player")
    local facing = GetPlayerFacing()
    if px == nil or facing == nil or x == nil then
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

    local absolute = math.abs(relative)
    if absolute <= 30 then
        return L["ahead"]
    elseif absolute >= 150 then
        return L["behind"]
    end
    local side = relative > 0 and L["right"] or L["left"]
    if absolute < 75 then
        return L["ahead"] .. " " .. side
    elseif absolute > 105 then
        return L["behind"] .. " " .. side
    end
    return side
end

-- "120 yards, ahead left" for a world position, or nil without a position.
function module:whereText(x, y)
    local distance = self:distanceTo(x, y)
    if distance == nil then
        return nil
    end
    local text = string.format("%d %s", distance, L["yards"])
    local direction = self:directionTo(x, y)
    if direction ~= nil then
        text = text .. ", " .. direction
    end
    return text
end

-- Sku's distance key: speaks how far the waypoint being walked to is. The
-- distance goes to speech only, never to the chat.
function module:announceDistance()
    local waypoint = self.path ~= nil and self.path.currentWaypoint or nil
    if waypoint == nil then
        WowVision:notify(L["No active waypoint"])
        return false
    end
    local distance = self:distanceTo(waypoint.x, waypoint.y)
    if distance == nil then
        WowVision:notify(L["Position unavailable"])
        return false
    end
    WowVision:speak(string.format("%d %s", distance, L["yards"]))
    return true
end

-- Sku announces on Alt Gr, which Windows reports as Ctrl and Alt held
-- together, so Ctrl+Alt does the same. Alt Gr is no key the binding system
-- can take on its own, so the update loop watches the chord and a held chord
-- repeats while the player walks. Typing with Alt Gr (@, {, [) must stay
-- silent: a focused edit box, or Shift, holds the announcement back.
local DISTANCE_REPEAT_SECONDS = 1

settings:add({
    key = "announceDistanceAltGr",
    type = "Bool",
    label = L["Announce Distance with Alt Gr"],
    default = true,
})

function module:updateDistanceKey()
    local held = self.settings.announceDistanceAltGr
        and IsControlKeyDown()
        and IsAltKeyDown()
        and not IsShiftKeyDown()
        and GetCurrentKeyBoardFocus() == nil
    if not held then
        self.distanceKeyAt = nil
        return
    end
    local now = GetTime()
    if self.distanceKeyAt == nil or now - self.distanceKeyAt >= DISTANCE_REPEAT_SECONDS then
        self.distanceKeyAt = now
        self:announceDistance()
    end
end

-- The same announcement on a key of the player's choosing; no default key,
-- Alt Gr is covered above.
module:registerBinding({
    type = "Script",
    key = "maps/announceDistance",
    label = L["Announce Distance"],
    inputs = {},
    script = "/run WowVision.base.navigation.maps:announceDistance()",
})

function module:newDataset(key)
    local data = WowVision.Dataset:new()
    self.datasets:register(key, data)
    return data
end

-- All waypoints on the player's continent from enabled atlas datasets,
-- merged into one id -> waypoint map for the router. World coordinates are
-- continent-wide, so routes can leave the current zone.
function module:currentWaypoints()
    local _, _, _, instanceId = UnitPosition("player")
    local merged = {}
    WowVision.atlas:forEachEnabledDataset(function(dataset)
        local bucket = dataset.waypointsByContinent[instanceId]
        if bucket ~= nil then
            for id, wp in pairs(bucket) do
                merged[id] = wp
            end
        end
    end)
    return merged
end

-- Destinations to pick from by name (F10, /beacon to): the route data's
-- waypoints, or with an active engine its own targets only (engine:search,
-- see setRouteEngine). The engine's setting chooses between the two.
function module:destinationWaypoints()
    local engine = self:activeRouteEngine()
    if engine ~= nil then
        return {}, engine
    end
    return self:currentWaypoints(), nil
end

-- Route to the nearest waypoint whose name contains the fragment
-- (case-insensitive): the test path for routed navigation before the
-- destination picker exists.
function module:navigateToName(fragment)
    local px, py = UnitPosition("player")
    if px == nil then
        WowVision:notify(L["Position unavailable"])
        return false
    end
    local waypoints, engine = self:destinationWaypoints()
    local foldCase = WowVision.utils.foldCase
    local needle = foldCase(fragment)
    local matches = WowVision.Router.nearest(waypoints, px, py, 1, function(wp)
        return wp.n ~= nil and (wp.search or foldCase(wp.n)):find(needle, 1, true) ~= nil
    end)
    local target = matches[1] and matches[1].waypoint
    local _, _, _, map = UnitPosition("player")
    if engine ~= nil then
        -- the engine's nearest hit wins when it is nearer than the route data's
        local hit = (engine:search(fragment, px, py, map) or {})[1]
        if hit ~= nil and (target == nil or hit.distance <= matches[1].distance) then
            target = hit
        end
    end
    if target == nil then
        WowVision:notify(L["No route found"] .. " " .. fragment)
        return false
    end
    WowVision:notify(target.n)
    -- the destination of Ctrl-Shift-N and the visited waypoints, as if picked in F10
    self.lastDestination = target
    local onArrive = self:arrivalFor(target)
    if engine ~= nil then
        -- no window to pick the entry point in: the one F10 would preselect
        local start = self:preselectedEntry(self:entryPoints(waypoints, px, py, map, engine))
        if self:routeTo(target.x, target.y, target.n, onArrive, target.z, target, start and start.waypoint) then
            return true
        end
    end
    return self:navigateTo(target.id, waypoints, { onArrive = onArrive })
end

-- How many entry points F10 offers.
module.ENTRY_COUNT = 20

-- Whether the player swims or dives: an entry point in water is preselected then.
function module:inWater()
    return (IsSwimming ~= nil and IsSwimming() == true) or (IsSubmerged ~= nil and IsSubmerged() == true)
end

-- The entry points of a route: the nearest points of the network, nearest
-- first, as { waypoint, distance }. The route data's linked waypoints, or with
-- an active engine its own (engine:entryPoints). Both kinds of data
-- route from the one the player picks; the engine never looks for a start of
-- its own.
function module:entryPoints(waypoints, px, py, map, engine)
    if engine ~= nil then
        local entries = {}
        for _, row in ipairs(engine:entryPoints(px, py, map, self.ENTRY_COUNT, self:inWater()) or {}) do
            tinsert(entries, { waypoint = row, distance = row.distance })
        end
        return entries
    end
    return WowVision.Router.nearest(waypoints, px, py, self.ENTRY_COUNT, WowVision.Router.hasLinks)
end

-- The entry point preselected: the nearest, while swimming the nearest in
-- water (only the engine's points know water). Second result: true when
-- swimming found none in water.
function module:preselectedEntry(entries)
    return WowVision.Router.preselectEntry(entries, self:inWater())
end

-- Straight-line beacon to a world position (no routing). onArrive, if
-- given, runs after "Arrived" is spoken.
function module:beaconTo(wx, wy, label, onArrive)
    self:guidanceStarts()
    local px, py = UnitPosition("player")
    local path = self.Path:new()
    path:add({ x = wx, y = wy, n = label })
    path.events.complete:subscribe(self, function()
        self.path = nil
        WowVision:notify(L["Arrived"])
        if onArrive ~= nil then
            onArrive()
        end
    end)
    self:pathfind(path)
    self:closeWindowsForGuidance()
    if px ~= nil then
        local dx, dy = wx - px, wy - py
        local distance = math.sqrt(dx * dx + dy * dy)
        WowVision:notify(string.format("%s %d %s", L["Beacon set"], distance, L["yards"]))
    else
        WowVision:notify(L["Beacon set"])
    end
end

-- The destination last picked (F10's Enter, the visited waypoints' keys):
-- what "the nearest unvisited of the same name" is named like.
module.lastDestination = nil

-- An auto chain (navigation/visited.lua) leads only the legs it starts
-- itself, through leadingChain (Ctrl-Shift-N on its leg too): any other
-- guidance -- another destination, a beacon, Ctrl-Shift-R -- ends it.
module.chainLeg = false

function module:guidanceStarts()
    if self.chainLeg then
        return
    end
    local visited = WowVision.base.navigation.visited
    if visited ~= nil then
        visited:endAuto()
    end
end

-- Guidance the player started is under way: every open window closes (setting, Navigation menu), so the keys are free
-- for walking. Not for a leg an auto chain leads on its own (force: the leg the player started the chain with). Called
-- once the route stands, before its summary is said; a route that was not found leaves the windows open.
function module:closeWindowsForGuidance(force)
    if self.chainLeg and not force then
        return
    end
    if WowVision.base.navigation.settings.closeWindowsOnRoute then
        WowVision.UIHost:closeAllWindows()
    end
end

function module:leadingChain(start)
    self.chainLeg = true
    local ok, result = pcall(start)
    self.chainLeg = false
    if not ok then
        geterrorhandler()(result)
        return false
    end
    return result
end

-- What runs when a picked destination is reached: it is remembered as
-- visited (navigation/visited.lua), then its own onArrive runs, then an
-- auto chain that led there goes on to the next one. The route's waypoints
-- on the way are never remembered, only the destination.
function module:arrivalFor(wp)
    local onArrive = wp.onArrive
    return function()
        local visited = WowVision.base.navigation.visited
        if visited ~= nil then
            visited:markVisited(wp)
        end
        if onArrive ~= nil then
            onArrive()
        end
        if visited ~= nil then
            visited:continueAuto(wp)
        end
    end
end

-- The destinations named like `name` (the same object: the route data's
-- name before its first field, WowNav's whole name), as { waypoint,
-- distance } -- the route data's, or an active engine's (direct: without its
-- reachability check). Then the waypoints and engine of
-- module:destinationWaypoints they came from.
function module:destinationsNamed(name, direct)
    local px, py, _, map = UnitPosition("player")
    local store = WowVision.visitedStore
    local fold = WowVision.utils.foldCase
    local base = store.baseName(name, fold)
    if px == nil or base == nil then
        return {}
    end
    local found = {}
    local function add(wp)
        if store.baseName(wp.n, fold) == base then
            local dx, dy = wp.x - px, wp.y - py
            tinsert(found, { waypoint = wp, distance = math.sqrt(dx * dx + dy * dy) })
        end
    end
    local waypoints, engine = self:destinationWaypoints()
    for _, wp in pairs(waypoints) do
        add(wp)
    end
    if engine ~= nil then
        for _, row in ipairs(engine:search(base, px, py, map, { direct = direct }) or {}) do
            add(row)
        end
    end
    return found, waypoints, engine
end

-- To a destination without the window: a direct point, or a route from the
-- entry point `start` (an entry of module:entryPoints, the one picked in
-- F10) or else the one F10 would preselect (as /beacon to). It becomes the last
-- picked destination and is remembered as visited once reached. A virtual
-- destination (wp.virtual: the corpse) is a position without links, routed
-- to with a straight last leg, its routeData handed to a route engine; too
-- far from the network it gets a straight beacon, as the scanner's targets.
function module:goToDestination(wp, direct, start)
    self.lastDestination = wp
    local onArrive = self:arrivalFor(wp)
    if direct then
        self:directTo(wp.x, wp.y, wp.n, onArrive)
        return true
    end
    local px, py, _, map = UnitPosition("player")
    if px == nil then
        WowVision:notify(L["Position unavailable"])
        return false
    end
    WowVision:notify(wp.n)
    local waypoints, engine = self:destinationWaypoints()
    if engine ~= nil then
        local data = wp
        if wp.virtual then
            data = wp.routeData
        end
        local entry = start or self:preselectedEntry(self:entryPoints(waypoints, px, py, map, engine))
        if self:routeTo(wp.x, wp.y, wp.n, onArrive, wp.z, data, entry and entry.waypoint) then
            return true
        end
    end
    if wp.virtual then
        waypoints[wp.id] = wp
    end
    local entry = engine == nil and (start or self:preselectedEntry(self:entryPoints(waypoints, px, py, map, nil)))
        or nil
    local routed = self:navigateTo(wp.id, waypoints, { entryId = entry and entry.waypoint.id, onArrive = onArrive })
    if not routed and wp.virtual then
        self:beaconTo(wp.x, wp.y, wp.n, onArrive)
        return true
    end
    return routed
end

-- Auto Route (navigation/visited.lua): of several destinations ({ waypoint,
-- distance }), the one the shortest walk from here reaches, routed to from
-- the entry point F10 would preselect. The route data: one search for all
-- (Router.nearestByWalk, whose route is followed); a route engine: its own
-- pick (engine:routeToNearest, which plans them in the background).
-- onChosen(wp) runs for the one picked before its route starts; it becomes
-- the last picked destination. waypoints, engine: as destinationsNamed gave
-- them (module:destinationWaypoints), so they are not merged again.
function module:routeToNearestWalk(candidates, onChosen, waypoints, engine)
    self:guidanceStarts()
    local px, py, _, map = UnitPosition("player")
    if px == nil then
        WowVision:notify(L["Position unavailable"])
        return false
    end
    local function chosen(wp)
        self.lastDestination = wp
        if onChosen ~= nil then
            onChosen(wp)
        end
    end
    if waypoints == nil then
        waypoints, engine = self:destinationWaypoints()
    end
    if engine ~= nil and engine.routeToNearest ~= nil then
        local start = self:preselectedEntry(self:entryPoints(waypoints, px, py, map, engine))
        local targets = {}
        for _, candidate in ipairs(candidates) do
            local wp = candidate.waypoint
            tinsert(targets, {
                x = wp.x,
                y = wp.y,
                z = wp.z,
                label = wp.n,
                data = wp.virtual and wp.routeData or wp,
                start = start and start.waypoint,
                onArrive = self:arrivalFor(wp),
                onChosen = function()
                    chosen(wp)
                end,
            })
        end
        if engine:routeToNearest(targets) then
            return true
        end
    end
    local list = {}
    for _, candidate in ipairs(candidates) do
        tinsert(list, candidate.waypoint)
    end
    local entry = engine == nil and self:preselectedEntry(self:entryPoints(waypoints, px, py, map, nil)) or nil
    local opts = { entryId = entry and entry.waypoint.id }
    local wp, route = WowVision.Router.nearestByWalk(waypoints, px, py, list, opts)
    if wp == nil then
        WowVision:notify(L["No route found"] .. " " .. (route ~= nil and L[route] or ""))
        return false
    end
    chosen(wp)
    WowVision:notify(wp.n)
    opts.onArrive = self:arrivalFor(wp)
    opts.route = route
    return self:navigateTo(wp.id, waypoints, opts)
end

-- Ctrl-Shift-N: the last destination's route again, from where the player
-- stands (WowNav's /vn new, without its penalty on the current link). The
-- route data enter at the nearest waypoints, as for /beacon to; a route
-- engine starts at the player's position only when that is clear
-- (engine:startHere says why not). Whatever guided before ends, a transit
-- waiting for its far end too.
function module:restartRoute()
    local wp = self.lastDestination
    if wp == nil then
        WowVision:notify(L["No route to start again"])
        return false
    end
    -- an auto chain's leg starts again and the chain goes on
    local visited = WowVision.base.navigation.visited
    if not self.chainLeg and visited ~= nil and visited:leads(wp) then
        return self:leadingChain(function()
            return self:restartRoute()
        end)
    end
    local px, py, _, map = UnitPosition("player")
    if px == nil then
        WowVision:notify(L["Position unavailable"])
        return false
    end
    local onArrive = self:arrivalFor(wp)
    local waypoints, engine = self:destinationWaypoints()
    if engine ~= nil then
        local start = engine.startHere ~= nil and engine:startHere(px, py, map) or nil
        if start == nil then
            return false
        end
        local data = wp
        if wp.virtual then
            data = wp.routeData
        end
        if self:routeTo(wp.x, wp.y, wp.n, onArrive, wp.z, data, start) then
            return true
        end
        WowVision:notify(L["No route found"])
        return false
    end
    if wp.virtual then
        waypoints[wp.id] = wp
    end
    local routed = self:navigateTo(wp.id, waypoints, { onArrive = onArrive })
    if not routed and wp.virtual then
        self:beaconTo(wp.x, wp.y, wp.n, onArrive)
    end
    return routed
end

module:registerBinding({
    type = "Script",
    key = "maps/restartRoute",
    label = L["Start the Route Again From Here"],
    inputs = { "CTRL-SHIFT-N" },
    script = "/run WowVision.base.navigation.maps:restartRoute()",
})

-- Ctrl-Shift-R: the running route turned around ("I have to go back"). The
-- new route starts at the previous route's destination and ends where that
-- route started (the entry point picked in F10), and it goes on at the
-- waypoint the beacon leads to now, so the player walks back from where they
-- are. A route engine turns its own route (engine:reverseRoute, nil when none
-- of its routes runs); the route data's route enters the network at the
-- previous destination, or its last linked waypoint when that has no links.
-- The start becomes the last destination for Ctrl-Shift-N.
function module:reverseRoute()
    self:guidanceStarts()
    local engine = self:activeRouteEngine()
    if engine ~= nil and engine.reverseRoute ~= nil then
        local handled = engine:reverseRoute()
        if handled ~= nil then
            return handled
        end
    end
    local route, path = self.lastRoute, self.path
    local current = path ~= nil and path.currentWaypoint or nil
    local entry = nil
    if path ~= nil then
        for i = #path.waypoints, 1, -1 do
            if WowVision.Router.hasLinks(path.waypoints[i]) then
                entry = path.waypoints[i]
                break
            end
        end
    end
    if route == nil or path ~= route.path or path.complete or current == nil or entry == nil
        or route.start == nil or route.start.id == nil then
        WowVision:notify(L["No route to reverse"])
        return false
    end
    local start = route.start
    local intro = string.format(L["Route reversed, back to %s"], start.n or L["the start of the previous route"])
    -- said and remembered only when the way back was found
    if not self:navigateTo(start.id, route.waypoints, { entryId = entry.id, resume = current, intro = intro }) then
        return false
    end
    self.lastDestination = start
    return true
end

module:registerBinding({
    type = "Script",
    key = "maps/reverseRoute",
    label = L["Reverse Route"],
    inputs = { "CTRL-SHIFT-R" },
    script = "/run WowVision.base.navigation.maps:reverseRoute()",
})

-- Exactly one point, no route (F10's "Direct", WowNav's /vn direct): a
-- straight beacon to the destination, whatever guidance ran before (a route
-- engine's too) ends first. Arrival says the point's name; onArrive runs
-- after it.
function module:directTo(wx, wy, label, onArrive)
    self:guidanceStarts()
    local engine = self.routeEngine
    if engine ~= nil and engine.cancel ~= nil then
        engine:cancel()
    end
    self:stopPath()
    local path = self.Path:new()
    path:add({ x = wx, y = wy, n = label })
    path.events.complete:subscribe(self, function()
        self.path = nil
        WowVision:notify(L["Arrived"] .. (label ~= nil and (" " .. label) or ""))
        if onArrive ~= nil then
            onArrive()
        end
    end)
    self:pathfind(path)
    self:closeWindowsForGuidance()
    WowVision:notify(string.format(L["Direct: %s, %d yards"], label or "", self:distanceTo(wx, wy) or 0))
end

-- Another route engine can take over the routing (camelot/wownav registers
-- WowNav). While its setting is on it gets every route request: the F10
-- window's Enter (the scanner's Enter and the places list open F10 first,
-- as with the route data), /beacon to. F10 works the same for both: the
-- player picks the entry point from the engine's nearest points, then the
-- destination. The engine computes the route from that entry point and hands
-- back a Path through pathfind; everything after that (beacon, arrival cue,
-- Ctrl-W/S, Shift-F12, the turn key) stays the same. engine: isActive(),
-- entryPoints(px, py, map, count, swimming) -> its nearest points to start
-- at, nearest first, { {id, n, x, y, z, water, distance} }, routeTo(target) ->
-- true when it took the request (false: not here, the request goes the old
-- way; target.start is the chosen entry point's row, the route starts there),
-- search(text, px, py, map, opts) -> rows, info: its targets matching the
-- text ("" = all), nearest first, { {id, n, x, y, z, detail, distance} }
-- (opts.direct: for F10's Direct, no reachability check)
-- (detail: said after the distance), info { capped, shown, total } when the
-- engine cut the list; cancel() -> true when it ended guidance of its own
-- (Shift-F12); startAt(px, py, map) -> the start at the player's position
-- when it is clear, else nil and why ("ambiguous": the floor is not clear),
-- with startHere saying why (Ctrl-Shift-N, the route to the target);
-- unitTarget(creatureId, px, py, map) -> its row of that creature near the
-- player, nil without one (the route to the target, targetRoute.lua).
-- While it is active, F10 lists its targets only.
function module:setRouteEngine(engine)
    self.routeEngine = engine
end

function module:activeRouteEngine()
    local engine = self.routeEngine
    if engine ~= nil and engine:isActive() then
        return engine
    end
    return nil
end

-- The one route request to the engine: to a world position (z when the
-- target knows it), from the entry point `start` (a row of
-- engine:entryPoints). data: the destination row when it came from the
-- engine's own list (its target data). True when the active engine took it;
-- false leaves it to the caller.
function module:routeTo(wx, wy, label, onArrive, z, data, start)
    self:guidanceStarts()
    local engine = self:activeRouteEngine()
    if engine == nil then
        return false
    end
    return engine:routeTo({ x = wx, y = wy, z = z, label = label, onArrive = onArrive, data = data, start = start })
        == true
end

-- Open the navigation window aimed at a world position: the scanner's
-- Enter. The window snapshots the network, adds the position as a
-- destination of its own (a waypoint without links, so the route ends with
-- a straight last leg), preselects the closest entry point, and lands on
-- that destination; Enter there routes. Without map data on this continent
-- there is nothing to route through, so a straight beacon is set instead.
-- An active route engine gets the same window: the player picks the entry
-- point from its network.
-- data: what the target's source knows for a route engine (the scanner's group members: { unit }).
-- match: what the target is, for a route engine that knows it with its height ({ kind, id, name }: the scanner's
-- NPCs and objects, see module:engineMatch).
function module:openNavigationTo(wx, wy, label, onArrive, data, match)
    if self:activeRouteEngine() == nil and next(self:currentWaypoints()) == nil then
        self:beaconTo(wx, wy, label, onArrive)
        return false
    end
    self.pendingTarget = { x = wx, y = wy, label = label, onArrive = onArrive, data = data, match = match }
    WowVision.UIHost:openWindow("atlas")
    return true
end

-- The route engine's own row for a target another source names (pendingTarget with .match): WowNav looks for the
-- same creature, else a target of that name, near the position, and its row brings the height. Nil without an
-- engine, a match, or a hit; a group member (data.unit) is followed live and never matched.
function module:engineMatch(engine, target, map)
    if engine == nil or engine.matchTarget == nil or target == nil or target.match == nil then
        return nil
    end
    if type(target.data) == "table" and target.data.unit ~= nil then
        return nil
    end
    local ok, row = pcall(engine.matchTarget, engine, target.match, target.x, target.y, map)
    if not ok then
        geterrorhandler()(row)
        return nil
    end
    return row
end

-- F10. From the quest log the window opens aimed at the quest's next target (as the scanner's Enter on that
-- quest), where there is a network to route through; otherwise as usual.
function module:openNavigationFromKey()
    local quests = WowVision.base.quests
    local questId = quests ~= nil and quests.safeLogQuest ~= nil and quests:safeLogQuest() or nil
    if questId ~= nil and (self:activeRouteEngine() ~= nil or next(self:currentWaypoints()) ~= nil) then
        local ok, target = pcall(quests.questNavigationTarget, quests, questId)
        if not ok then
            geterrorhandler()(target)
            target = nil
        end
        if target ~= nil then
            self:openNavigationTo(target.x, target.y, target.label, target.onArrive, nil, target.match)
            return
        end
    end
    WowVision.UIHost:openWindow("atlas")
end

-- Map-percentage coordinates ("50.5 30.4") on the current zone map, the
-- numbers quest guides use: converted to a world position, then a straight
-- beacon. GetWorldPosFromMapPos returns coordinates in UnitPosition's
-- convention, which is exactly what Beacon consumes.
function module:beaconToMapCoords(xPercent, yPercent)
    local mapId = C_Map.GetBestMapForUnit("player")
    if mapId == nil then
        WowVision:notify(L["Position unavailable"])
        return false
    end
    local _, worldPos = C_Map.GetWorldPosFromMapPos(mapId, CreateVector2D(xPercent / 100, yPercent / 100))
    if worldPos == nil then
        WowVision:notify(L["Position unavailable"])
        return false
    end
    local wx, wy = worldPos:GetXY()
    self:beaconTo(wx, wy, string.format("%.1f %.1f", xPercent, yPercent))
    return true
end

-- Route to a waypoint through the link graph and follow it with the beacon.
-- opts passes through to the router (entryId for a user-chosen entry point);
-- opts.onArrive runs after "Arrived" is spoken; opts.route: a route already
-- searched (Router.nearestByWalk), followed without a search of its own;
-- opts.resume (a waypoint): the route goes on at this waypoint, or the
-- nearest of its own, and its summary counts from there.
function module:navigateTo(waypointId, waypoints, opts)
    self:guidanceStarts()
    local px, py = UnitPosition("player")
    if px == nil then
        WowVision:notify(L["Position unavailable"])
        return false
    end
    waypoints = waypoints or self:currentWaypoints()
    local route = opts ~= nil and opts.route or nil
    local reason
    if route == nil then
        route, reason = WowVision.Router.route(waypoints, px, py, waypointId, opts)
    end
    if route == nil then
        -- The router's reasons are keys ("no entry"); spoken translated.
        WowVision:notify(L["No route found"] .. " " .. (reason ~= nil and L[reason] or ""))
        return false
    end
    local path = self.Path:new()
    for _, wp in ipairs(route.waypoints) do
        path:add(wp)
    end
    -- what Ctrl-Shift-R turns around: the route's first waypoint, in its network
    self.lastRoute = { path = path, start = route.waypoints[1], waypoints = waypoints }
    path.events.complete:subscribe(self, function()
        self.path = nil
        local last = route.waypoints[#route.waypoints]
        WowVision:notify(L["Arrived"] .. (last.n ~= nil and (" " .. last.n) or ""))
        if opts ~= nil and opts.onArrive ~= nil then
            opts.onArrive()
        end
    end)
    self:pathfind(path)
    self:closeWindowsForGuidance()
    local count, distance = #route.waypoints, route.distance
    local resumeIndex = opts ~= nil and opts.resume ~= nil and WowVision.Router.resumeIndex(route.waypoints, opts.resume)
        or nil
    if resumeIndex ~= nil then
        path:resumeAt(resumeIndex)
        count = count - resumeIndex + 1
        distance = WowVision.Router.remainingDistance(route.waypoints, resumeIndex, px, py)
    end
    local text = string.format("%d %s, %d %s", count, L["waypoints"], distance, L["yards"])
    -- The destination is off the network: say how much is walked straight,
    -- without a road to follow. A leg inside the arrival distance is no
    -- walk of its own, so it goes unsaid ("last 0 yards direct").
    local lastLeg = route.lastLeg ~= nil and math.floor(route.lastLeg + 0.5) or 0
    if lastLeg > self:arrivalDistance() then
        text = text .. ", " .. string.format(L["last %d yards direct"], lastLeg)
    end
    if opts ~= nil and opts.intro ~= nil then
        text = opts.intro .. ". " .. text
    end
    WowVision:notify(text)
    return true
end

-- How long after the waypoint-reached cue the count of the waypoints left
-- is spoken, so the cue is heard first and the path has moved on.
local REMAINING_DELAY = 0.3

function module:pathfind(path)
    self.beacon = nil
    self.path = path
    path.events.arriveAtWaypoint:subscribe(self, function()
        module:fireAlert("beacon", { action = "arrived" })
        if not self.stepping and WowVision.base.navigation.settings.announceRemaining then
            C_Timer.After(REMAINING_DELAY, function()
                self:announceRemaining(path)
            end)
        end
    end)
    self.path:start()
end

-- The waypoints still ahead on the route, the one the beacon now leads to
-- included (the Ctrl-W count). Nil once the route ended or another began.
function module:remainingWaypoints(path)
    if path == nil or path ~= self.path or not path.active or path.complete or path.currentIndex == nil then
        return nil
    end
    local remaining = #path.waypoints - path.currentIndex + 1
    if remaining < 1 then
        return nil
    end
    return remaining
end

-- After a waypoint reached: "3 remaining". The last waypoint says Arrived
-- instead, so nothing is said once none is left.
function module:announceRemaining(path)
    local remaining = self:remainingWaypoints(path)
    if remaining ~= nil then
        WowVision:speak(string.format(L["%d remaining"], remaining))
    end
end

-- Sku's next/previous waypoint keys: manually step along the active route
-- when displaced or realigning. The step plays the arrival cue (moveBy
-- emits arriveAtWaypoint) and announces how many waypoints remain,
-- current one included, like Sku's count-down.
function module:stepWaypoint(offset)
    local visited = WowVision.base.navigation.visited
    if self.path == nil then
        -- an auto chain whose leg found no route steps on all the same
        if visited ~= nil and visited:stepAuto(offset) then
            return true
        end
        WowVision:notify(L["No active waypoint"])
        return false
    end
    -- the step speaks its own count; the arrival cue's count would repeat it
    self.stepping = true
    local waypoint = self.path:moveBy(offset)
    self.stepping = false
    if waypoint == nil then
        -- past the ends of an auto chain's leg: its next or previous spot (navigation/visited.lua)
        if visited ~= nil and visited:stepAuto(offset) then
            return true
        end
        WowVision:notify(offset > 0 and L["End of route"] or L["Start of route"])
        return false
    end
    local remaining = #self.path.waypoints - self.path.currentIndex + 1
    WowVision:speak(string.format("%d %s", remaining, L["remaining"]))
    return true
end

module:registerBinding({
    type = "Script",
    key = "maps/nextWaypoint",
    label = L["Next Waypoint"],
    inputs = { "CTRL-W" },
    script = "/run WowVision.base.navigation.maps:stepWaypoint(1)",
})

module:registerBinding({
    type = "Script",
    key = "maps/previousWaypoint",
    label = L["Previous Waypoint"],
    inputs = { "CTRL-S" },
    script = "/run WowVision.base.navigation.maps:stepWaypoint(-1)",
})

-- Whether a beacon leads the way (a route or a straight line).
function module:isGuiding()
    return self.path ~= nil
end

function module:stopPath()
    self.path = nil
    self.beacon = nil
end

-- Shift-F12 and "/beacon stop" end whatever leads the way, a route or a
-- straight beacon (the beacon alert falls silent with it).
function module:cancelNavigation()
    -- a route engine may hold guidance without a beacon (a search, a transit waiting for its far end)
    local engine = self.routeEngine
    local engineStopped = engine ~= nil and engine.cancel ~= nil and engine:cancel() == true
    local visited = WowVision.base.navigation.visited
    if visited ~= nil then
        visited:endAuto()
    end
    if not self:isGuiding() then
        if engineStopped then
            WowVision:notify(L["Beacon stopped"])
            return true
        end
        WowVision:notify(L["No active waypoint"])
        return false
    end
    self:stopPath()
    WowVision:notify(L["Beacon stopped"])
    return true
end

module:registerBinding({
    type = "Script",
    key = "maps/cancelNavigation",
    label = L["Cancel Navigation"],
    inputs = { "SHIFT-F12" },
    script = "/run WowVision.base.navigation.maps:cancelNavigation()",
})

function module:updatePath()
    if self.path then
        self.path:update()
    end
end

-- /beacon            -> report current map position (and active beacon bearing)
-- /beacon x y        -> beacon to MAP coordinates on the current zone map
--                       ("50.5 30.4", the numbers quest guides use)
-- /beacon world x y  -> beacon to raw world coordinates
-- /beacon stop       -> clear the active beacon
function module:handleBeaconCommand(args)
    args = args and strtrim(args) or ""

    if args == "" then
        local px, py = UnitPosition("player")
        if not px then
            WowVision:speak(L["Position unavailable"])
            return
        end
        local mapId = C_Map.GetBestMapForUnit("player")
        local mapPos = mapId ~= nil and C_Map.GetPlayerMapPosition(mapId, "player") or nil
        if mapPos ~= nil then
            local mx, my = mapPos:GetXY()
            WowVision:speak(string.format("%.1f %.1f", mx * 100, my * 100))
        else
            WowVision:speak(string.format("Position x %.1f y %.1f", px, py))
        end
        if self.path and self.path.beacon then
            local distance, relative = self.path.beacon:compute()
            if distance then
                WowVision:speak(string.format("Beacon %.0f %s, %.0f degrees", distance, L["yards"], relative))
            end
        end
        return
    end

    local fragment = args:match("^[Tt]o%s+(.+)$")
    if fragment ~= nil then
        self:navigateToName(fragment)
        return
    end

    if args:lower() == "stop" then
        self:cancelNavigation()
        return
    end

    local worldX, worldY = args:match("^[Ww]orld%s+(-?%d+%.?%d*)%s+(-?%d+%.?%d*)$")
    worldX, worldY = tonumber(worldX), tonumber(worldY)
    if worldX ~= nil and worldY ~= nil then
        self:beaconTo(worldX, worldY)
        return
    end

    local x, y = args:match("^(-?%d+%.?%d*)%s+(-?%d+%.?%d*)$")
    x, y = tonumber(x), tonumber(y)
    if not x or not y then
        WowVision:speak("Usage beacon x y")
        return
    end
    self:beaconToMapCoords(x, y)
end

module:registerCommand({
    name = "beacon",
    scope = "Global",
    description = "Set a navigation beacon. Usage: /beacon x y (map coordinates), /beacon to name, /beacon world x y, /beacon stop, or /beacon for current position.",
    func = function(args)
        module:handleBeaconCommand(args)
    end,
})

function module:onEnable()
    self:hasUpdate(function(self)
        self:updatePath()
        self:updateDistanceKey()
    end)
end
