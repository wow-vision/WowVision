local testRunner = WowVision.testing.testRunner
local Route = WowVision.wownavRoute
local catalog = WowVision.wownavCatalog
local text = WowVision.wownavText
local dock = WowVision.wownavDock

-- WowNav routes on Broesel's real data: tools/headless-tests.lua loads the engine (camelot/wownav/engine) and the
-- packed data of mapdata/WowNavPacked (run tools/wownav-pack.lua first). Without the data only the parts that need
-- no network run.
local N = _G.WowVisionNavigationNavNetwork
local G = _G.WowVisionNavigationGuidance
local R = _G.WowVisionNavigationTargetResolver
local C = _G.WowVisionNavigationTargetCatalog
local haveNetwork = N ~= nil and N.Job ~= nil and type(_G.WVN7Index) == "table" and next(_G.WVN7Index) ~= nil

local STORMWIND, ELWYNN, UNDERCITY = 84, 37, 1458

-- A game stand-in: the player's position, clock and movement, changed by the test.
local function newGame()
    local game = { x = nil, y = nil, map = 0, t = 0, swimming = false, facing = 0, moving = false, speed = 7 }
    game.env = {
        N = N, G = G, R = R, C = C,
        position = function()
            return game.x, game.y, game.map
        end,
        swimming = function()
            return game.swimming
        end,
        now = function()
            return game.t
        end,
        facing = function()
            return game.facing
        end,
        moving = function()
            return game.moving
        end,
        speed = function()
            return game.speed
        end,
    }
    return game
end

local function setup()
    N.LoadIndex()
    N.ActionAllowed = function(action)
        local c = type(action) == "table" and action.conditions or nil
        return type(c) == "table" and c.status == "unconditional" and c.proof ~= nil
    end
    N.SetComfort(50)
    G.arrivalMin = 3
    N.activeMapId = 0
end

-- Runs a job to its end in slices, as the module does per frame; returns its results and the number of slices.
local function runJob(job)
    local clock = 0
    local slices = 0
    while true do
        slices = slices + 1
        local done, a, b = job:Step(2, function()
            clock = clock + 1
            return clock
        end)
        if done then
            return a, b, slices
        end
        if slices > 100000 then
            error("job does not end")
        end
    end
end

-- the first waypoint of a zone whose position binds to the network without a floor question
local function bindablePosition(zoneId, game, route)
    N.LoadZone(zoneId)
    for i = 0, 2000 do
        local x, y, z = N.Position(zoneId * N.ZONE_BASE + i)
        route.anchor.last = z
        if route:startBinding(x, y) then
            game.x, game.y = x, y
            return x, y, z
        end
    end
end

-- The list rows of one zone: his search with an empty text from a waypoint of that zone (the nearest 1000 targets).
-- text: a search word (the empty search lists the nearest 1000 of the continent only)
local function zoneRows(zoneId, text)
    N.LoadZone(zoneId)
    local x, y = N.Position(zoneId * N.ZONE_BASE + 1)
    local rows = catalog.search(N, C, 0, text or "", x, y, { german = false })
    local out = {}
    for _, r in ipairs(rows) do
        if r.zoneId == zoneId then
            out[#out + 1] = r
        end
    end
    return out
end

local function rowsWith(rows, category)
    for _, r in ipairs(rows) do
        if r.detail ~= nil and r.detail:find(category, 1, true) then
            return r
        end
    end
end

local suite = {
    ["a transit is proven in the plane: left the source, then in the arrival volume"] = function(t)
        local game = newGame()
        local route = Route.new(game.env)
        local action = {
            kind = "lift", fromNativeMap = 0, toNativeMap = 0, timing = { timeout_seconds = 16.667 },
            arrival = { mode = "transport_stop_volume" },
            sourceVolume = { radius = 2, x = 1596.0, y = 282.4, z = 55.4 },
            arrivalVolume = { radius = 2, x = 1602.0, y = 287.0, z = -41.2 },
        }
        route:startAction(action, {})
        -- standing at the top: never an arrival, even with a wide arrival distance
        t:assertNil(route:observeAction(1596.0, 282.4, 0, 5))
        -- the ride goes down: the source is left, the arrival circle (widened to 5) holds the player
        t:assertNil(route:observeAction(1599.0, 285.0, 0, 5), "nearer the source than the arrival: not yet")
        t:assertEqual(route:observeAction(1601.5, 286.5, 0, 5), "arrived")
    end,

    ["a transit into another map needs the map change"] = function(t)
        local game = newGame()
        local route = Route.new(game.env)
        local action = {
            kind = "tram", fromNativeMap = 0, toNativeMap = 369, timing = { timeout_seconds = 30 },
            arrival = { mode = "native_map_volume" },
            sourceVolume = { radius = 10, x = -8346.5, y = 514.0, z = 96.6 },
            arrivalVolume = { radius = 10, x = 68.3, y = 2490.9, z = -4.3 },
        }
        route:startAction(action, {})
        t:assertNil(route:observeAction(68.3, 2490.9, 0, 3), "the same point on the old map")
        t:assertEqual(route:observeAction(70, 2492, 369, 3), "arrived")
    end,

    ["a transit that takes longer than its three phases ends"] = function(t)
        local game = newGame()
        local route = Route.new(game.env)
        route:startAction({ timing = { timeout_seconds = 10 }, fromNativeMap = 0, toNativeMap = 0,
            sourceVolume = { radius = 2, x = 0, y = 0 }, arrivalVolume = { radius = 2, x = 50, y = 0 } }, {})
        game.t = 29
        t:assertNil(route:observeAction(0, 0, 0, 3))
        game.t = 31
        t:assertEqual(route:observeAction(0, 0, 0, 3), "timeout")
    end,

    ["turning on the spot is no travel for the stagnation window"] = function(t)
        local game = newGame()
        local route = Route.new(game.env)
        game.speed = 0
        route:checkApproach(0, 0, 50, 0)
        route:checkApproach(3, 0, 50, 1)
        t:assertEqual(route.stagnationTravel, 0, "speed 0: the position noise is not counted")
        game.speed = nil
        route:checkApproach(6, 0, 50, 2)
        t:assertEqual(route.stagnationTravel, 3, "unknown speed (secret): counted, his fallback")
    end,

    ["a list row says how its target resolved (his Describe)"] = function(t)
        t:assertEqual(text.describe({ quality = "exact" }), "")
        t:assertEqual(text.describe({ quality = "approximate", deltaXY = 0.5 }), "", "under a yard says nothing")
        local inexact = text.describe({ quality = "approximate", deltaXY = 4.2, zUnknown = true })
        t:assertNotNil(inexact:find("inexact +4.2 yards", 1, true), inexact)
        t:assertNotNil(inexact:find("height unknown", 1, true), inexact)
        t:assertNotNil(text.describe({ quality = "ambiguous" }):find("choose the floor", 1, true))
        t:assertNotNil(text.describe({ quality = "unroutable" }):find("no network point", 1, true))
        t:assertNotNil(text.describe({ quality = "approximate", deltaXY = 0, normalizedWater = true, divingDepth = 3 })
            :find("diving depth 3.0", 1, true))
    end,

    ["his choke fallback switch is read from WowVisionNavigationDB"] = function(t)
        local saved = _G.WowVisionNavigationDB
        _G.WowVisionNavigationDB = nil
        t:assertTrue(Route.chokeFallback(), "on without settings")
        _G.WowVisionNavigationDB = { chokeFallback = false }
        t:assertFalse(Route.chokeFallback())
        _G.WowVisionNavigationDB = { chokeFallback = true }
        t:assertTrue(Route.chokeFallback())
        _G.WowVisionNavigationDB = saved
    end,

    ["a dyn target is named from its key and place, with its suffix"] = function(t)
        t:assertEqual(text.targetName({ nameKey = "portal", nameParam = "Darnassus" }), "Portal to Darnassus")
        t:assertEqual(text.targetName({ nameKey = "elevator", nameParam = "Undercity",
            nameSuffix = { key = "upper" } }), "Elevator: Undercity (upper)")
        t:assertEqual(text.targetName({ nameKey = "tram_entrance" }), "Deeprun Tram entrance")
        t:assertEqual(text.targetName({ nameEn = "Guard", nameDe = "Wache" }, true), "Wache")
        t:assertEqual(text.targetName({ nameEn = "Guard", nameDe = "Wache" }, false), "Guard")
        t:assertEqual(text.categories({ category = { "quest_giver", "trainer" } }), "quest giver, trainer")
        t:assertEqual(text.categories({ category = "object_type_5" }), "object type 5")
        -- automatic waypoints: his order decides the type when several codes are set
        t:assertEqual(text.autoType(2), "gate")
        t:assertEqual(text.autoType(1 + 2), "gate")
        t:assertEqual(text.autoType(1 + 16), "level change")
        t:assertEqual(text.autoType(0), "waypoint")
        t:assertEqual(text.autoName(2, 33.6), "Automatic: gate, height 34")
    end,
}

if haveNetwork then
    suite["the packed data decodes and a route is searched in time slices"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local x, y = bindablePosition(STORMWIND, game, route)
        t:assertNotNil(x, "a bindable Stormwind waypoint")
        local start = route:startBinding(x, y)
        local farId = STORMWIND * N.ZONE_BASE + 3000
        local result, _, slices = runJob(N.Job(function()
            return N.RouteIds(start, farId)
        end))
        t:assertNotNil(result, "a route across Stormwind")
        t:assertTrue(slices > 1, "the search yielded at least once")
    end

    suite["his outposts (Z2): a route into the enemy capital warns, the own capital does not"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local x, y = bindablePosition(STORMWIND, game, route)
        local start = route:startBinding(x, y)
        local farId = STORMWIND * N.ZONE_BASE + 3000
        local function routeAs(faction)
            N.SetPlayerFaction(faction)
            local result = runJob(N.Job(function()
                return N.RouteIds(start, farId)
            end))
            N.SetPlayerFaction(nil)
            return result
        end
        local horde = routeAs("Horde")
        t:assertNotNil(horde, "an outpost never makes a route fail")
        t:assertEqual(horde.outpost, "target", "Stormwind is an Alliance capital: the target lies in it")
        t:assertNil(routeAs("Alliance").outpost, "no warning in the own capital")
        t:assertTrue(WowVisionNavigationText("outpost_target") ~= "outpost_target", "the warning has a text")
    end

    suite["a whole search that missed its target answers later targets from inside it (same answers)"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local x, y = bindablePosition(STORMWIND, game, route)
        local start = route:startBinding(x, y)
        local zone = N.LoadZone(STORMWIND)
        local targets = {}
        for i = 0, zone.n - 1, 50 do
            targets[#targets + 1] = zone.base + i
        end
        -- each target alone, outside a job: no cache
        local plain, missed = {}, 0
        for i, id in ipairs(targets) do
            plain[i] = N.RouteIds(start, id) ~= nil
            if not plain[i] then
                missed = missed + 1
            end
        end
        t:assertTrue(missed > 1, "some waypoints cannot be reached from here")
        -- all of them in one job: after the first miss the others come from the reached set
        local cached = runJob(N.Job(function()
            local out = {}
            for i, id in ipairs(targets) do
                out[i] = N.RouteIds(start, id) ~= nil
            end
            return out
        end))
        for i = 1, #targets do
            t:assertEqual(cached[i], plain[i], "waypoint " .. targets[i])
        end
    end

    suite["the continent catalogue lists both layers with categories and zone"] = function(t)
        setup()
        local rows = zoneRows(STORMWIND)
        t:assertTrue(#rows > 100)
        local innkeeper = rowsWith(rows, "innkeeper")
        t:assertNotNil(innkeeper, "Stormwind has an innkeeper")
        local dyn = 0
        for _, r in ipairs(rows) do
            if r.layer == "dyn" then
                dyn = dyn + 1
            end
        end
        t:assertTrue(dyn > 0, "Stormwind has dyn targets (portals, tram entrance, crossings)")
        local contract = catalog.contract(innkeeper, 0)
        t:assertTrue(C.Validate(contract), "a row makes a valid target")
    end

    suite["the search reads the compact catalogue in place: nearest 1000, cut list said, text per class"] = function(t)
        setup()
        local x, y = N.Position(STORMWIND * N.ZONE_BASE + 1)
        local all, info = catalog.search(N, C, 0, "", x, y, { german = false })
        t:assertEqual(#all, C.SEARCH_LIMIT, "an empty search lists the nearest targets, at most the limit")
        t:assertTrue(info.capped, "the continent has more targets than the limit")
        t:assertTrue(info.total > C.SEARCH_LIMIT)
        for i = 2, #all do
            -- his C.Nearest sorts by the squared distance in steps of 1/16 yd2: entries of one step keep
            -- catalogue order
            t:assertTrue(all[i].distance >= all[i - 1].distance - 0.01, "nearest first")
        end
        local provider = C.providers["package_logical_" .. STORMWIND]
        t:assertNotNil(provider and provider.compact, "the logical catalogue is kept compact")
        t:assertNil(provider.compact.expanded, "no table per target was built")
        -- the category, a name and the zone are searched
        local inns, innInfo = catalog.search(N, C, 0, "innkeeper", x, y, { german = false })
        t:assertTrue(#inns > 0)
        t:assertFalse(innInfo.capped)
        t:assertNotNil(inns[1].detail:find("innkeeper", 1, true), inns[1].detail)
        local zoneName = N.index[STORMWIND].name
        local inZone = catalog.search(N, C, 0, zoneName, x, y, { german = false })
        t:assertTrue(#inZone > 0, "the zone name finds the zone's targets")
        local again = catalog.search(N, C, 0, "  INNKEEPER ", x, y, { german = false })
        t:assertEqual(#again, #inns, "case and spaces around the text do not matter")
        -- automatic waypoints only with showauto, and only near the player
        local plain = catalog.search(N, C, 0, "automatic", x, y, { german = false })
        t:assertEqual(#plain, 0)
        local auto = catalog.search(N, C, 0, "automatic", x, y, { german = false, showAuto = true })
        t:assertTrue(#auto > 0)
        t:assertNotNil(auto[1].nodeId)
    end

    suite["a target is resolved, routed and walked to with his arrival rules"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local x, y = bindablePosition(STORMWIND, game, route)
        local rows = zoneRows(STORMWIND)
        local target = rowsWith(rows, "innkeeper")
        local outcome = runJob(N.Job(route.prepare, route, catalog.contract(target, 0), { nativeMapId = 0 }))
        if outcome.kind == "choose" then
            target.levels = nil
            outcome = runJob(N.Job(route.prepare, route,
                (function()
                    local c = catalog.contract(target, 0)
                    c.heightBand = 1
                    return c
                end)(), { nativeMapId = 0 }))
        end
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
        route:begin(outcome.plan, catalog.contract(target, 0), outcome.result, target.n)
        t:assertTrue(route.active)
        -- walk: stand on each waypoint in turn
        local arrived
        for step = 1, 2000 do
            game.t = game.t + 0.3
            local id = route.path[route.pathIndex]
            game.x, game.y = N.Position(id)
            game.moving, game.facing = true, 0
            local event = route:update(game.x, game.y)
            if event and event.kind == "arrived" then
                arrived = event
                break
            end
        end
        t:assertNotNil(arrived, "the route ends at the target")
    end

    suite["automatic waypoints nearby: nearest first, named by type and height, routed to straight"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local x, y = bindablePosition(STORMWIND, game, route)
        local points = catalog.autoPoints(N, x, y, nil, 40)
        t:assertTrue(#points > 0)
        t:assertTrue(#points <= 40)
        for i, p in ipairs(points) do
            t:assertTrue(p.distance <= catalog.NODE_SELECTION_RADIUS)
            t:assertNotNil(p.nodeId)
            t:assertTrue(p.n:find("Automatic: ", 1, true) == 1, p.n)
            if i > 1 then
                t:assertTrue(p.distance >= points[i - 1].distance)
            end
        end
        local far = points[#points]
        local outcome = runJob(N.Job(route.prepareNode, route, far.nodeId))
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
        t:assertEqual(outcome.plan.path[#outcome.plan.path], far.nodeId)
        -- his start-point mode: a nearby waypoint as the start
        local fixed = runJob(N.Job(route.prepareNode, route, far.nodeId, points[1].nodeId))
        t:assertEqual(fixed.kind, "start")
        t:assertEqual(fixed.plan.path[1], points[1].nodeId)
    end

    suite["a scanner target (a position without height) is resolved and routed like a list target"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        bindablePosition(STORMWIND, game, route)
        local rows = zoneRows(STORMWIND)
        local npc = rowsWith(rows, "innkeeper")
        local contract = { id = "wowvision:scanner", kind = "live", nameEn = "Scanner target", nativeMapId = 0,
            coordinateSpace = "world", x = npc.x, y = npc.y, zStatus = "unknown" }
        local outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }))
        t:assertTrue(outcome.kind == "start" or outcome.kind == "choose", tostring(outcome.reason))
    end

    suite["Stormwind to an Ironforge innkeeper ends at the tram entrance, walking only"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        bindablePosition(STORMWIND, game, route)
        local rows = zoneRows(87, "innkeeper")
        local target = rowsWith(rows, "innkeeper")
        t:assertNotNil(target, "Ironforge has an innkeeper")
        local contract = catalog.contract(target, 0)
        local outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }))
        if outcome.kind == "choose" then
            contract.heightBand = 1
            outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }))
        end
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
        local action = outcome.plan.pendingAction
        t:assertNotNil(action, "the route uses a transit")
        t:assertEqual(action.kind, "tram")
        t:assertEqual(action.activation and action.activation.mode, "walk_into_volume", "walked into, never ridden")
    end

    suite["a target over several certified floors asks the floor and marks the reachable ones"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        bindablePosition(STORMWIND, game, route)
        local rows = zoneRows(STORMWIND)
        local stacked
        for _, r in ipairs(rows) do
            if r.levels ~= nil and #r.levels > 1 then
                stacked = r
                break
            end
        end
        t:assertNotNil(stacked, "Stormwind has a target over several floors")
        local outcome = runJob(N.Job(route.prepare, route, catalog.contract(stacked, 0), { nativeMapId = 0 }))
        t:assertEqual(outcome.kind, "choose")
        t:assertEqual(#outcome.result.bands, #stacked.levels, "exactly the certified floors")
        local any = false
        for i = 1, #stacked.levels do
            any = any or outcome.reachable[i] == true
        end
        t:assertTrue(any, "at least one floor has a path from here")
        local chosen = catalog.contract(stacked, 0)
        for i = 1, #stacked.levels do
            if outcome.reachable[i] then
                chosen.heightBand = i
                break
            end
        end
        local second = runJob(N.Job(route.prepare, route, chosen, { nativeMapId = 0 }))
        t:assertEqual(second.kind, "start", tostring(second.reason))
    end

    suite["the choke fallback steps back once at a gate when the player drifted sideways"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local zone = N.LoadZone(STORMWIND)
        -- a GATE waypoint and a neighbour of it
        local gateId, fromId
        for i = 0, zone.n - 1 do
            local id = zone.base + i
            if G.Choke(id) then
                local adj = zone.adj[i + 1]
                if adj and #adj >= 2 then
                    gateId, fromId = id, zone.base + adj[1]
                    break
                end
            end
        end
        t:assertNotNil(gateId, "Stormwind has gates")
        route.active = true
        route.path = { fromId, gateId }
        route.pathIndex = 2
        local ax, ay = N.Position(fromId)
        local bx, by = N.Position(gateId)
        local dx, dy = bx - ax, by - ay
        local l = math.sqrt(dx * dx + dy * dy)
        -- 20 yd beside the middle of the run-up segment
        local px, py = (ax + bx) / 2 - dy / l * 20, (ay + by) / 2 + dx / l * 20
        game.t = 100
        t:assertEqual(route:handleBlockage(px, py), "fallback")
        t:assertEqual(route.pathIndex, 1)
        route.pathIndex = 2
        game.t = 110
        t:assertNil(route:handleBlockage(px, py), "the same waypoint is locked for 20 s")
    end

    suite["a route over an Undercity lift ends at the lift and continues from its far end"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local zone = N.LoadZone(UNDERCITY)
        local lift
        for _, action in ipairs(zone.actions) do
            if action.kind == "lift" then
                lift = action
                break
            end
        end
        t:assertNotNil(lift)
        -- from the lift's start to a point next to its far end: the route takes the lift
        local plan = runJob(N.Job(route.planToNode, route, lift.toNode, { id = lift.fromNode }))
        t:assertNotNil(plan)
        t:assertNotNil(plan.pendingAction, "the route uses the lift")
        t:assertEqual(plan.path[#plan.path], lift.fromNode, "cut at the lift")
        route:startAction(plan.pendingAction, { contract = {} }, lift.toNode, nil)
        local tx, ty = N.Position(lift.toNode)
        local fx, fy = N.Position(lift.fromNode)
        t:assertNil(route:observeAction(fx, fy, 0, 3))
        route:observeAction(tx, ty, 0, 3)
        local request, toNode, targetNodeId = route:actionArrival()
        t:assertNotNil(request)
        t:assertEqual(toNode, lift.toNode)
        t:assertEqual(targetNodeId, lift.toNode, "the target binding travels with the transit")
        local _, _, tz = N.Position(lift.toNode)
        t:assertEqual(route.anchor.last, tz, "the height of the far end anchors the next start")
        -- the continuation routes from the far end to the kept binding, without resolving the target again
        local outcome = runJob(N.Job(route.continueTo, route, toNode, targetNodeId, nil))
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
    end

    -- The Deeprun Tram (map 369): two lines, each with a dock in Stormwind (y about 2490) and in Ironforge (y about 9).
    local TRAM_MAP = 369
    local function tramDocks()
        N.LoadZone(499)      -- in the game the player's zone is decoded ahead (module.lua, his PreloadNeighbours)
        local found = {}
        local rows = catalog.search(N, C, TRAM_MAP, "", 0, 1250, { german = false })
        for _, r in ipairs(rows) do
            if dock.isDockRow(r) then
                local line = r.tid:match("animation%%3A(%d+)")
                local side = r.y > 1000 and "stormwind" or "ironforge"
                found[side .. line] = r
            end
        end
        return found
    end

    -- his dock module asks the client for the player's map (UnitPosition); the test stands on the tram map
    local function onTramMap(fn)
        local saved = _G.UnitPosition
        _G.UnitPosition = function()
            return 0, 0, 0, TRAM_MAP
        end
        local ok, err = pcall(fn)
        _G.UnitPosition = saved
        _G.WowVisionNavigationDockNavigation:Reset(false)
        text.say = nil
        if not ok then
            error(err, 0)
        end
    end

    suite["at a tram dock the other dock of the line is noted, not walked to (his passive mode)"] = function(t)
        setup()
        N.activeMapId = TRAM_MAP
        onTramMap(function()
            local docks = tramDocks()
            local from, to, other = docks.stormwind176080, docks.ironforge176080, docks.ironforge176082
            t:assertNotNil(from, "the Stormwind dock of line 176080")
            t:assertNotNil(to, "the Ironforge dock of line 176080")
            t:assertNotNil(other, "the Ironforge dock of line 176082")
            local said = {}
            text.say = function(message)
                said[#said + 1] = message
            end
            -- standing at the Stormwind dock counts as having reached it
            local outcome, target = dock.choose(N, to, from.x, from.y)
            t:assertEqual(outcome, "passive")
            t:assertEqual(target.id, to.tid)
            t:assertNil(said[1], "his text is replaced by the module's (dock.passiveText)")
            local Dock = _G.WowVisionNavigationDockNavigation
            t:assertEqual(Dock.passive.id, to.tid)
            -- near the noted dock the turn key faces it; far from it there is nothing to face
            t:assertNil(dock.alignment(N, from.x, from.y))
            local px, py, id = dock.alignment(N, to.x + 10, to.y)
            t:assertNotNil(px, "the turn key has a point")
            t:assertTrue(math.abs(px - to.x) < 0.01 and math.abs(py - to.y) < 0.01)
            t:assertTrue(id:find("^dock%-passive:") ~= nil)
            -- the Ironforge dock of the other line is taken as this line's own
            Dock:Reset(false)
            local outcome2, target2 = dock.choose(N, other, from.x, from.y)
            t:assertEqual(outcome2, "passive")
            t:assertEqual(target2.id, to.tid, "the dock of the line the player stands at")
            -- choosing the dock the player is at ("toward Ironforge", in Stormwind) means riding from it
            Dock:Reset(false)
            local outcome3, target3, _, source3 = dock.choose(N, from, from.x, from.y)
            t:assertEqual(outcome3, "passive")
            t:assertEqual(target3.id, to.tid)
            t:assertEqual(source3.id, from.tid)
            local ride = dock.passiveText(source3, target3)
            t:assertNotNil(ride:find("the Deeprun Tram", 1, true), ride)
            -- anywhere on the platform (within 30 yd) counts as standing at the dock; far away it does not
            Dock:Reset(false)
            t:assertEqual(dock.choose(N, to, from.x + 20, from.y), "passive")
            Dock:Reset(false)
            t:assertEqual(dock.choose(N, to, from.x, from.y - 300), "route")
            -- a dock chosen by its position (scanner, places list) is that dock
            local byPosition = dock.rowAt(N, to.x + 1, to.y)
            t:assertNotNil(byPosition, "the dock by its position")
            t:assertEqual(byPosition.tid, to.tid)
            t:assertNil(dock.rowAt(N, to.x + 50, to.y))
            -- the route data's own tram point at the Ironforge end (walk test 2026-10-22), chosen in Stormwind: a ride
            Dock:Reset(false)
            local ride = dock.rideFor(N, 10.7, 2488.2, 15.1, 8.2)
            t:assertNotNil(ride, "a target at the far end is a ride")
            t:assertEqual(dock.choose(N, ride, 10.7, 2488.2), "passive")
            t:assertNil(dock.rideFor(N, from.x, from.y - 300, 15.1, 8.2), "not from outside a station")
            t:assertNil(dock.rideFor(N, from.x, from.y, from.x + 20, from.y),
                "not for a target in the player's station")
        end)
    end

    suite["a dock is walked to; at its waiting node the dock is reached, then the other dock is noted"] = function(t)
        setup()
        N.activeMapId = TRAM_MAP
        onTramMap(function()
            local docks = tramDocks()
            local to, far = docks.stormwind176080, docks.ironforge176080
            local game = newGame()
            game.map = TRAM_MAP
            local route = Route.new(game.env)
            -- from a platform waypoint of the Stormwind station, away from the dock
            local x, y
            for i = 0, 2000 do
                local nx, ny, nz = N.Position(499 * N.ZONE_BASE + i)
                if nx and ny > 2400 and nz > -6 then
                    route.anchor.last = nz
                    if route:startBinding(nx, ny) and (nx - to.x) ^ 2 + (ny - to.y) ^ 2 > 400 then
                        x, y = nx, ny
                        break
                    end
                end
            end
            t:assertNotNil(x, "a platform waypoint away from the dock")
            game.x, game.y = x, y
            -- (inside the station a dock choice rides; the route to the dock is what the scanner or a far start gets)
            local target = dock.target(N, to)
            t:assertNotNil(target, "the dock's full target")
            local contract = catalog.contract(to, TRAM_MAP)
            local result = runJob(N.Job(route.prepare, route, contract, { nativeMapId = TRAM_MAP }))
            t:assertEqual(result.kind, "start", tostring(result.reason))
            t:assertEqual(result.plan.path[#result.plan.path], target.nodeId,
                "the route ends at the dock's waiting node")
            -- data 9423773 had that node down in the track bed (the route was cut before the drop); since 5b8b5f2 it
            -- stands on the platform: either way the route ends up there (platform -4 to -5, track bed -11 to -14)
            local cut = dock.trimDrop(N, result.plan.path)
            local walked = cut or result.plan.path
            local _, _, endZ = N.Position(walked[#walked])
            t:assertTrue(endZ > -6, "the route ends on the platform, height " .. tostring(endZ))
            route:begin(result.plan, contract, result.result, to.n)
            t:assertNil(route.logicalTarget, "no logical end point behind a dock's waiting node")
            local nx, ny = N.Position(target.nodeId)
            local inside = (nx - target.x) ^ 2 + (ny - target.y) ^ 2 <= target.waitingRadius ^ 2
            route.waitCheck = dock.waitAreaCheck(N, target)
            -- data 9423773: the waiting point at track level, the node on the platform 7 yd away, so no circle rule
            -- that could never be met; where the node lies in the circle, his circle rule ends the route
            if inside then
                t:assertNotNil(route.waitCheck, "his circle rule where the waiting node lies in it")
            else
                t:assertNil(route.waitCheck, "no circle rule that could never be met")
            end
            local arrived
            route.pathIndex = #route.path
            for _ = 1, 20 do
                game.t = game.t + 0.3
                local event = route:update(nx, ny)
                if event and event.kind == "arrived" then
                    arrived = event
                    break
                end
            end
            t:assertNotNil(arrived, "the route ends at the waiting node")
            local said = {}
            text.say = function(message)
                said[#said + 1] = message
            end
            -- (the headless tests have no beacon paths: a stand-in for the boarding beacon)
            local stand = dock.boardingPath == nil
            if stand then
                dock.boardingPath = function()
                    return {}
                end
            end
            local boarding = dock.arrived(N, target, nx, ny)
            if stand then
                dock.boardingPath = nil
            end
            if inside then
                t:assertNotNil(boarding, "the boarding beacon at the waiting point")
            else
                t:assertNil(boarding, "no boarding beacon 7 yd from the waiting point")
            end
            t:assertNotNil(said[1] and said[1]:find("the Deeprun Tram", 1, true), tostring(said[1]))
            local Dock = _G.WowVisionNavigationDockNavigation
            t:assertNotNil(Dock.reached, "the dock stays reached")
            -- at the waiting point itself the turn key faces the boarding point a few yards ahead
            local px, py, id = dock.alignment(N, target.x, target.y)
            t:assertNotNil(px, "the turn key has a point")
            t:assertTrue(id:find("^dock%-boarding:") ~= nil)
            local ahead = math.sqrt((px - target.x) ^ 2 + (py - target.y) ^ 2)
            t:assertTrue(math.abs(ahead - target.boardingPreviewDistance) < 0.01)
            -- from the waiting node the Ironforge dock is noted, not walked to
            local next = dock.choose(N, far, nx, ny)
            t:assertEqual(next, "passive")
            -- and standing at the waiting node without the route counts as well
            Dock:Reset(false)
            t:assertEqual(dock.choose(N, far, nx, ny), "passive")
        end)
    end

    suite["the boarding points of the docks are list entries"] = function(t)
        setup()
        N.activeMapId = TRAM_MAP
        onTramMap(function()
            local docks = tramDocks()
            local from = docks.stormwind176080
            local rows = dock.boardingRows(N, from.x, from.y)
            t:assertEqual(#rows, 4, "one per tram dock")
            for _, r in ipairs(rows) do
                t:assertEqual(r.n, "At the vehicle")
                t:assertNotNil(r.boardingTargetId)
            end
            local hits = catalog.search(N, C, TRAM_MAP, "at the vehicle", from.x, from.y,
                { german = false, extra = rows })
            t:assertEqual(#hits, 4)
            t:assertTrue(hits[1].distance <= hits[2].distance)
        end)
    end

    suite["a walk-in target: on foot, the prepoint said, no arrival before the capture circle"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        bindablePosition(STORMWIND, game, route)
        local rows = zoneRows(STORMWIND)
        local entrance
        for _, r in ipairs(rows) do
            if r.activationMode == "walk_into_trigger" then
                local outcome, target = dock.activation(N, r)
                if outcome == "route" then
                    entrance = { row = r, target = target }
                    break
                end
            end
        end
        t:assertNotNil(entrance, "Stormwind has a proven walk-in entrance (portal or tram entrance)")
        local target = entrance.target
        local contract = catalog.contract(entrance.row, 0)
        t:assertEqual(contract.activationMode, "walk_into_trigger")
        local outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }))
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
        t:assertNil(outcome.plan.pendingAction, "on foot: no transit on the way")
        route:begin(outcome.plan, contract, outcome.result, entrance.row.n)
        route.activation = target
        t:assertNil(route.logicalTarget, "no logical end point behind a walk-in target")
        local seen = {}
        for _ = 1, 3000 do
            game.t = game.t + 0.3
            local x, y
            if route.pathIndex >= #route.path then
                if not seen.prepoint then
                    x, y = target.activationPreX, target.activationPreY
                elseif not seen.waited then
                    -- at the last waypoint but outside the capture circle: no arrival
                    x, y = N.Position(route.path[#route.path])
                    if (x - target.x) ^ 2 + (y - target.y) ^ 2 <= target.activationCaptureRadius ^ 2 then
                        x = x + target.activationCaptureRadius + 1
                    end
                    seen.waited = true
                else
                    x, y = target.x, target.y
                end
            else
                x, y = N.Position(route.path[route.pathIndex])
            end
            game.x, game.y, game.moving = x, y, true
            local event = route:update(x, y)
            if event then
                seen[event.kind] = true
                if event.kind == "activation" then
                    break
                end
            end
        end
        t:assertTrue(seen.prepoint == true, "the prepoint is said")
        t:assertNil(seen.arrived, "no arrival at a walk-in target")
        t:assertTrue(seen.activation == true, "the capture circle is said")
        t:assertTrue(route.activationInside == true)
    end
end

testRunner:addSuite("WowNav routes", suite)
