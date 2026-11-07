local testRunner = WowVision.testing.testRunner
local Route = WowVision.wownavRoute
local catalog = WowVision.wownavCatalog
local text = WowVision.wownavText
local dock = WowVision.wownavDock
local fishing = WowVision.wownavFishing

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

    ["a portal is walked into before the route's end, or proven by its teleport alone"] = function(t)
        local game = newGame()
        local route = Route.new(game.env)
        local portal = {
            kind = "portal", fromNativeMap = 1, toNativeMap = 1, timing = { timeout_seconds = 30 },
            activation = { mode = "walk_into_volume" }, arrival = { mode = "same_map_distinct_volume" },
            sourceVolume = { radius = 10, x = 9947.5, y = 2630.0 },
            arrivalVolume = { radius = 10, x = 8786.4, y = 967.4 },
        }
        route.pendingAction = portal
        t:assertNil(route:walkInTransit(9974.0, 2664.0, 9990.0, 2680.0), "43 yd from its centre: not yet")
        t:assertNil(route:walkInTransit(9960.3, 2653.5, 9974.0, 2664.0), "16.7 yd from its edge: not yet")
        local ahead = route:walkInTransit(9955.0, 2648.0, 9960.3, 2653.5)
        t:assertEqual(ahead and ahead.kind, "transitAhead", "within 15 yd of the portal: said before it")
        t:assertNil(route:walkInTransit(9951.3, 2640.3, 9960.3, 2653.5), "said once")
        local entered = route:walkInTransit(9951.6, 2636.8, 9951.3, 2640.3)
        t:assertEqual(entered and entered.kind, "transit", "in the portal, not at the route's last waypoint")
        t:assertTrue(entered.sourceEntered == true)
        t:assertTrue(entered.announced == true, "not said again in the portal")
        local jumped = route:walkInTransit(8787.0, 968.0, 9951.3, 2640.3)
        t:assertTrue(jumped ~= nil and jumped.teleported == true, "out at its far end between two updates")
        t:assertNil(route:walkInTransit(8787.0, 968.0, 8790.0, 970.0), "in the arrival volume without a jump")
        route.pendingAction = { kind = "lift", activation = { mode = "board" }, sourceVolume = portal.sourceVolume,
            arrivalVolume = portal.arrivalVolume }
        t:assertNil(route:walkInTransit(9951.6, 2636.8, 9951.3, 2640.3), "a lift is boarded, not walked into")
        route.pendingAction = nil

        -- the continuation from the teleport event goes on at the next observation
        route:startAction(portal, {}, nil, nil, jumped)
        t:assertEqual(route:observeAction(8787.0, 968.0, 1, 3), "arrived")
        -- the route ended at its last waypoint, outside the portal, and no observation saw the player inside it
        route:startAction(portal, {})
        t:assertNil(route:observeAction(9958.2, 2631.0, 1, 3), "at the route's end, 10.8 yd from the centre")
        t:assertEqual(route:observeAction(8787.0, 968.0, 1, 3), "arrived", "the jump to the far end proves it")
        -- a lift's far end needs the source left: no jump rule there
        route:startAction({ kind = "lift", fromNativeMap = 0, toNativeMap = 0, timing = { timeout_seconds = 30 },
            arrival = { mode = "transport_stop_volume" },
            sourceVolume = { radius = 2, x = 0, y = 0 }, arrivalVolume = { radius = 2, x = 100, y = 0 } }, {})
        t:assertNil(route:observeAction(10, 0, 0, 3))
        t:assertNil(route:observeAction(100, 0, 0, 3), "a lift is not proven by a jump")
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

    ["a target without a height on its network point is reached, no unchecked last stretch"] = function(t)
        t:assertTrue(Route.reachesTarget(nil, 1.5))
        t:assertTrue(Route.reachesTarget({ quality = "exact" }, 1.5))
        t:assertTrue(Route.reachesTarget({ quality = "approximate", deltaXY = 0, zUnknown = true }, 1.5),
            "a quest marker or the current target on Forever: no height, on the network")
        t:assertFalse(Route.reachesTarget({ quality = "approximate", deltaXY = 4.2, zUnknown = true }, 1.5),
            "the network ends before the target")
        t:assertFalse(Route.reachesTarget({ quality = "approximate", deltaXY = 0, normalizedWater = true }, 1.5),
            "under water the diving stays unchecked")
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

    ["a transit that waits for a signal has no time limit; the others end after theirs"] = function(t)
        local clock = 0
        local route = Route.new({ now = function()
            return clock
        end })
        local far = { x = 1e6, y = 1e6, radius = 1 }
        local timed = { kind = "portal", timing = { timeout_seconds = 30 }, sourceVolume = far, arrivalVolume = far }
        local bridge = { kind = "wind_bridge", timing = { no_time_limit = true }, sourceVolume = far, arrivalVolume = far }
        route:startAction(timed)
        clock = 30 * Route.ACTION_PHASES + 1
        t:assertEqual(route:observeAction(0, 0, 0, 0), "timeout")
        clock = 0
        route:startAction(bridge)
        clock = 3600
        t:assertNil(route:observeAction(0, 0, 0, 0), "the Wind Bridge comes when it comes")
        t:assertNotNil(route.action)
    end,

    ["an action bound to a faction is only for that faction's players"] = function(t)
        local saved = N.playerFaction
        N.SetPlayerFaction("Horde")
        t:assertTrue(N.FactionAction({}), "an action without a faction is for everybody")
        t:assertTrue(N.FactionAction({ faction = "horde" }))
        t:assertFalse(N.FactionAction({ faction = "alliance" }))
        N.playerFaction = saved
    end,

    ["a dyn target is named from its key and place, with its suffix"] = function(t)
        t:assertEqual(text.targetName({ nameKey = "portal", nameParam = "Darnassus" }), "Portal to Darnassus")
        t:assertEqual(text.targetName({ nameKey = "elevator", nameParam = "Undercity",
            nameSuffix = { key = "upper" } }), "Elevator: Undercity (upper)")
        t:assertEqual(text.targetName({ nameKey = "tram_entrance" }), "Deeprun Tram entrance")
        t:assertEqual(text.targetName({ nameKey = "fishing_spot_shore", nameParam = "Crystal Lake",
            nameSuffix = { key = "number", value = 2 } }), "Fishing spot on the shore: Crystal Lake (2)")
        t:assertEqual(text.targetName({ nameKey = "fishing_spot_structure", nameParam = "Goldshire" }),
            "Fishing spot on pier or quay: Goldshire")
        -- a dungeon with several entrances names the wing (German: nameWingDe); the transitions of Zephras Isle
        local wing = { nameKey = "dungeon_entrance", nameParam = "Scarlet Monastery", nameWing = "Graveyard",
            nameWingDe = "Friedhof" }
        t:assertEqual(text.targetName(wing, false), "Dungeon entrance: Scarlet Monastery, Graveyard")
        t:assertEqual(text.targetName(wing, true), "Dungeon entrance: Scarlet Monastery, Friedhof")
        t:assertEqual(text.targetName({ nameKey = "dungeon_entrance", nameParam = "Zul'Farrak" }),
            "Dungeon entrance: Zul'Farrak")
        t:assertEqual(text.targetName({ nameKey = "wind_bridge_wait", nameEn = "x" }), "Wind Bridge waiting point")
        t:assertEqual(text.targetName({ nameKey = "valanaar_arrival_horde" }), "Horde arrival in Valanaar Sanctuary")
        t:assertEqual(text.targetName({ nameEn = "Guard", nameDe = "Wache" }, true), "Wache")
        t:assertEqual(text.targetName({ nameEn = "Guard", nameDe = "Wache" }, false), "Guard")
        t:assertEqual(text.categories({ category = { "quest_giver", "trainer" } }), "quest giver, trainer")
        t:assertEqual(text.categories({ category = "object_type_5" }), "object type 5")
        -- automatic waypoints: named by their height only
        t:assertEqual(text.autoName(33.6), "Auto, height 34")
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

    suite["a start beside the network binds to the nearest cell within 30 yd (his 3 yd said no network)"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local zone = N.LoadZone(STORMWIND)
        -- a point 10 or 20 yd from a waypoint that his radius does not bind
        local x, y
        for i = 0, zone.n - 1, 7 do
            local nx, ny, nz = N.Position(zone.base + i)
            for _, d in ipairs({ 10, 20 }) do
                for a = 0, 7 do
                    local cx, cy = nx + d * math.cos(a * math.pi / 4), ny + d * math.sin(a * math.pi / 4)
                    route.anchor.last = nz
                    local opts = route:startOptions()
                    opts.radius = nil
                    if x == nil and N.Bind(cx, cy, nil, opts) == nil then
                        x, y = cx, cy
                    end
                end
            end
            if x ~= nil then
                break
            end
        end
        t:assertNotNil(x, "a Stormwind point beside the network")
        local id, binding = route:startBinding(x, y)
        t:assertNotNil(id, "the start binds")
        t:assertTrue(binding.cellDistance <= Route.START_RADIUS, "to a cell within the start radius")
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

    suite["automatic waypoints nearby: nearest first, named by height, routed to straight"] = function(t)
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
            t:assertTrue(p.n:find("Auto, height ", 1, true) == 1, p.n)
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

    suite["F10's Direct lists the targets without the reachability check (his /vn direct list)"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local x, y = bindablePosition(STORMWIND, game, route)
        local routed, info = catalog.search(N, C, 0, "", x, y, { german = false })
        local direct, directInfo = catalog.search(N, C, 0, "", x, y, { german = false, direct = true })
        t:assertEqual(#direct, C.SEARCH_LIMIT, "the nearest 1000, none dropped")
        t:assertEqual(directInfo.total, info.total, "the same matches")
        for _, row in ipairs(direct) do
            t:assertNil(row.resolution, "nothing resolved: no route leads to a direct point")
        end
        -- every routed hit is a direct hit too, the direct list reaches no farther
        t:assertTrue(direct[#direct].distance <= routed[#routed].distance)
    end

    suite["a scanner target is found in the catalogue: by creature, else by name, near its position"] = function(t)
        setup()
        local rows = zoneRows(STORMWIND)
        local innkeeper = rowsWith(rows, "innkeeper")
        t:assertNotNil(innkeeper, "Stormwind has an innkeeper")
        t:assertNotNil(innkeeper.creatureEntry, "a creature's row carries its creature ID")
        -- the quest database's spawn lies a few yards off the catalogue's point
        local x, y = innkeeper.x + 12, innkeeper.y - 9
        local byId = catalog.matchRow(N, C, 0, { kind = "npc", id = innkeeper.creatureEntry, name = "someone else" }, x, y)
        t:assertNotNil(byId, "the same creature near the position")
        t:assertEqual(byId.id, innkeeper.id)
        t:assertNotNil(byId.z, "the catalogue's row brings the height")
        local byName = catalog.matchRow(N, C, 0, { kind = "object", name = "  " .. innkeeper.n:upper() .. " " }, x, y)
        t:assertNotNil(byName, "the same name near the position, case and spaces aside")
        t:assertEqual(byName.id, innkeeper.id)
        local english = catalog.matchRow(N, C, 0, { name = innkeeper.nameEn }, x, y)
        t:assertEqual(english and english.id, innkeeper.id, "the English name finds it too")
        t:assertNil(catalog.matchRow(N, C, 0, { name = "No Such Target Anywhere" }, x, y), "an unknown name")
        t:assertNil(catalog.matchRow(N, C, 0, { name = innkeeper.n }, innkeeper.x + 500, innkeeper.y),
            "too far from the position: another place")
        t:assertNil(catalog.matchRow(N, C, 0, nil, x, y))
        t:assertNil(catalog.matchRow(N, C, 0, { name = "" }, x, y))
    end

    suite["F10's entry points: the nearest 50, waypoints beside the player always, farther ones with the setting"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local x, y = bindablePosition(STORMWIND, game, route)
        local function sorted(list)
            for i = 2, #list do
                if list[i].distance < list[i - 1].distance then
                    return false
                end
            end
            return true
        end
        local near = catalog.autoPoints(N, x, y, catalog.ENTRY_NEAR)
        t:assertTrue(#near > 0, "the player stands on a waypoint")
        t:assertTrue(#near < catalog.ENTRY_COUNT, "the waypoints beside him leave room for targets")
        local entries = catalog.entryPoints(N, C, 0, x, y, catalog.ENTRY_COUNT, { german = false })
        t:assertEqual(#entries, catalog.ENTRY_COUNT)
        t:assertTrue(sorted(entries), "nearest first")
        local auto, beyond = 0, false
        for _, e in ipairs(entries) do
            if e.nodeId ~= nil then
                auto = auto + 1
                t:assertTrue(e.distance <= catalog.ENTRY_NEAR, "without the setting only the waypoints beside him")
                t:assertNotNil(e.n:find("^Auto, height %-?%d+$"), "an automatic waypoint says its height: " .. e.n)
            else
                t:assertNotNil(e.tid, "a target of the catalogue")
                t:assertNotNil(e.resolution and e.resolution.endNodeId, "a start needs its network point")
                t:assertNil(e.n:find("%d%d%d"), "a target's name has no coordinates: " .. e.n)
                beyond = beyond or e.distance > catalog.ENTRY_NEAR
            end
        end
        t:assertEqual(auto, #near, "every waypoint within the radius is listed")
        t:assertTrue(beyond, "the rest of the list is targets farther away")
        local withAuto = catalog.entryPoints(N, C, 0, x, y, catalog.ENTRY_COUNT, { showAuto = true, german = false })
        t:assertEqual(#withAuto, catalog.ENTRY_COUNT)
        t:assertTrue(sorted(withAuto), "nearest first, both kinds")
        local far = 0
        for _, e in ipairs(withAuto) do
            if e.nodeId ~= nil then
                t:assertNotNil(e.n:find("^Auto, height %-?%d+$"), e.n)
                far = far + (e.distance > catalog.ENTRY_NEAR and 1 or 0)
            end
        end
        t:assertTrue(far > 0, "the setting mixes in the waypoints farther away")
        t:assertEqual(text.autoName(nil), "Auto, height unknown", "a missing height is never said as 0")
        t:assertEqual(text.autoName(-12.6), "Auto, height -13")
    end

    suite["standing at a flight master, it heads the entry points; the route starts at its network point"] = function(t)
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        bindablePosition(STORMWIND, game, route)
        local master = rowsWith(zoneRows(STORMWIND), "flight master")
        t:assertNotNil(master, "Stormwind has a flight master")
        local x, y = master.x + 1, master.y
        for _, showAuto in ipairs({ false, true }) do
            local entries = catalog.entryPoints(N, C, 0, x, y, 20, { showAuto = showAuto, german = false })
            local found
            for i, e in ipairs(entries) do
                if e.tid == master.tid then
                    found = i
                end
            end
            t:assertNotNil(found, "the flight master is an entry point (showAuto " .. tostring(showAuto) .. ")")
            for i = 1, found - 1 do
                t:assertTrue(entries[i].distance <= entries[found].distance, "only nearer points before it")
            end
        end
        -- the start is the flight master's network point, resolved when the route is asked for
        local entries = catalog.entryPoints(N, C, 0, x, y, 20, { german = false })
        local picked
        for _, e in ipairs(entries) do
            if e.tid == master.tid then
                picked = e
            end
        end
        local startId = catalog.startNode(N, R, catalog.activeNav(), picked, 0)
        t:assertNotNil(startId)
        local target = rowsWith(zoneRows(STORMWIND), "innkeeper")
        local contract = catalog.contract(target, 0)
        local outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }, startId))
        if outcome.kind == "choose" then
            contract.heightBand = 1
            outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }, startId))
        end
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
        t:assertEqual(outcome.plan.path[1], startId, "the route starts at the picked entry point")
        -- an automatic waypoint starts at itself
        local node = catalog.autoPoints(N, x, y, nil, 1)[1]
        t:assertEqual(catalog.startNode(N, R, catalog.activeNav(), node, 0), node.nodeId)
    end

    suite["a route from a picked target begins at the target itself, then at its network point"] = function(t)
        setup()
        local LOCH_MODAN = 1432
        local game = newGame()
        local route = Route.new(game.env)
        N.LoadZone(LOCH_MODAN)
        -- Thorgrum Borrelson, the gryphon master of Thelsamar: his network point lies on the road, yards away
        local master = zoneRows(LOCH_MODAN, "thorgrum")[1]
        t:assertNotNil(master, "Loch Modan's gryphon master")
        game.x, game.y = master.x + 1, master.y
        local picked
        for _, e in ipairs(catalog.entryPoints(N, C, 0, game.x, game.y, 20, { german = false })) do
            if e.tid == master.tid then
                picked = e
            end
        end
        t:assertNotNil(picked, "he is an entry point")
        local startId, startZ = catalog.startNode(N, R, catalog.activeNav(), picked, 0)
        local sx, sy = N.Position(startId)
        t:assertTrue(Route.distance(sx, sy, master.x, master.y) > Route.ARRIVAL_START_RADIUS, "not where he stands")
        route.anchor.last = startZ
        -- a quest giver farther away (not the gryphon master, who gives quests too)
        local target
        for _, r in ipairs(zoneRows(LOCH_MODAN)) do
            if target == nil and r.tid ~= master.tid and r.detail ~= nil and r.detail:find("quest giver", 1, true)
                and Route.distance(r.x, r.y, master.x, master.y) > 200 then
                target = r
            end
        end
        t:assertNotNil(target, "a quest giver away from him")
        local contract = catalog.contract(target, 0)
        local outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }, startId))
        if outcome.kind == "choose" then
            contract.heightBand = 1
            outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }, startId))
        end
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
        route:begin(outcome.plan, contract, outcome.result, target.n)
        route:prependStart(picked.x, picked.y, picked.z)
        local fx, fy = N.Position(route.path[1])
        t:assertEqual(route.pathIndex, 1)
        t:assertTrue(Route.distance(fx, fy, master.x, master.y) < 0.01, "the first waypoint is the gryphon master")
        t:assertEqual(route.path[2], startId, "then his network point")
        -- standing at him: the first waypoint is reached, the route goes on to his network point
        local event
        for _ = 1, 3 do
            game.t = game.t + 0.5
            event = route:update(game.x, game.y) or event
        end
        t:assertEqual(event and event.kind, "advance")
        t:assertEqual(route.pathIndex, 2)
    end

    suite["swimming: water entry points are marked, the nearest in reach joins a list without one"] = function(t)
        setup()
        -- a water waypoint with a checked exit, and a land waypoint less than 90 yd from it
        local water, land
        for _, zoneId in ipairs({ STORMWIND, ELWYNN }) do
            N.LoadZone(zoneId)
            for i = 0, 20000 do
                local id = zoneId * N.ZONE_BASE + i
                if not N.Exists(id) then
                    break
                end
                if water == nil and N.Area(id) == "WATER" and not N.NoExit(id) then
                    water = id
                end
            end
            if water ~= nil then
                local wx, wy = N.Position(water)
                for i = 0, 20000 do
                    local id = zoneId * N.ZONE_BASE + i
                    if not N.Exists(id) then
                        break
                    end
                    local lx, ly = N.Position(id)
                    if N.Area(id) ~= "WATER" and (lx - wx) ^ 2 + (ly - wy) ^ 2 < 90 * 90 then
                        land = id
                        break
                    end
                end
                break
            end
        end
        t:assertNotNil(water, "the data has a water waypoint")
        t:assertNotNil(land, "with land near it")
        local wx, wy = N.Position(water)
        for _, showAuto in ipairs({ true, false }) do
            local inWater = catalog.entryPoints(N, C, 0, wx, wy, 20, { showAuto = showAuto, swimming = true,
                german = false })
            local marked
            for _, e in ipairs(inWater) do
                if e.nodeId == water then
                    marked = e
                end
                if e.water then
                    t:assertNotNil(e.nodeId, "only the network's waypoints are water points")
                end
            end
            t:assertNotNil(marked, "swimming on it, the water waypoint is listed (showAuto " .. tostring(showAuto) .. ")")
            t:assertTrue(marked.water, "and marked water")
        end
        -- one entry asked for, without the setting: swimming adds the nearest water point, whatever the setting
        local lx, ly = N.Position(land)
        local dry = catalog.entryPoints(N, C, 0, lx, ly, 1, { german = false })
        t:assertEqual(#dry, 1)
        if not dry[1].water then
            local wet = catalog.entryPoints(N, C, 0, lx, ly, 1, { swimming = true, german = false })
            t:assertEqual(#wet, 2)
            local waterRows = 0
            for _, e in ipairs(wet) do
                if e.water then
                    waterRows = waterRows + 1
                    t:assertNotNil(e.nodeId)
                    t:assertTrue(e.distance <= N.WATER_EXIT_RADIUS)
                end
            end
            t:assertEqual(waterRows, 1)
            t:assertTrue(wet[2].distance >= wet[1].distance, "at its place by distance")
        end
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
            -- choosing the dock the player is near ("toward Ironforge", in Stormwind) walks to it, no ride is noted
            Dock:Reset(false)
            local outcome3, target3 = dock.choose(N, from, from.x + 20, from.y)
            t:assertEqual(outcome3, "route")
            t:assertEqual(target3.id, from.tid)
            -- the dock of the other line in the same station is walked to as well, not swapped for a far one
            local beside = docks.stormwind176082
            if beside ~= nil then
                Dock:Reset(false)
                local outcome4, target4 = dock.choose(N, beside, from.x, from.y)
                t:assertEqual(outcome4, "route")
                t:assertEqual(target4.id, beside.tid)
            end
            t:assertNil(Dock.passive, "nothing noted")
            -- the ride text names where the noted dock's line goes
            Dock:Reset(false)
            local _, noted, _, at = dock.choose(N, to, from.x, from.y)
            local ride = dock.passiveText(at, noted)
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

    suite["Menethil: the dock to Auberdine is walked to from beside the dock to the Southshore ferry"] = function(t)
        setup()
        -- where the walk test of 2026-11-02 stood: 32 yd from the Southshore ferry dock, which shares its position
        -- with the dock to Auberdine (two lines, one pier); the game noted the Auberdine dock instead of walking there
        local x, y = -3695.9, -575.9
        local saved = _G.UnitPosition
        _G.UnitPosition = function()
            return x, y, 0, 0
        end
        local Dock = _G.WowVisionNavigationDockNavigation
        local choosePassive = Dock.ChoosePassive
        local ok, err = pcall(function()
            local auberdine
            for _, r in ipairs(catalog.search(N, C, 0, "auberdine", x, y, { german = false })) do
                if auberdine == nil and dock.isDockRow(r) and Route.distance(r.x, r.y, x, y) < 100 then
                    auberdine = r
                end
            end
            t:assertNotNil(auberdine, "the Menethil dock to Auberdine")
            local outcome, target, why = dock.choose(N, auberdine, x, y)
            t:assertEqual(outcome, "route", tostring(why))
            t:assertEqual(target.id, auberdine.tid)
            -- a dock of the own station is never noted, whatever his ride rule would say (the game's case)
            Dock:Reset(false)
            Dock.ChoosePassive = function()
                return true
            end
            local outcome2, target2, why2 = dock.choose(N, auberdine, x, y)
            t:assertEqual(outcome2, "route", tostring(why2))
            t:assertEqual(target2.id, auberdine.tid)
            -- a dock far away still is (the ride rule is asked)
            Dock:Reset(false)
            t:assertEqual(dock.choose(N, auberdine, x, y - 300), "route", "away from every dock: walked to")
        end)
        Dock.ChoosePassive = choosePassive
        _G.UnitPosition = saved
        Dock:Reset(false)
        if not ok then
            error(err, 0)
        end
    end

    suite["Menethil: the route to a ship dock ends at the dock, where the boarding beacon has its point"] = function(t)
        setup()
        -- the walk test's start of 2026-11-02; the pier slopes down 3.6 yd to the dock to Auberdine
        local x, y = -3707.1, -712.0
        local saved = _G.UnitPosition
        _G.UnitPosition = function()
            return x, y, 0, 0
        end
        local ok, err = pcall(function()
            local game = newGame()
            game.x, game.y = x, y
            local route = Route.new(game.env)
            local auberdine
            for _, r in ipairs(catalog.search(N, C, 0, "auberdine", x, y, { german = false })) do
                if auberdine == nil and dock.isDockRow(r) and Route.distance(r.x, r.y, x, y) < 200 then
                    auberdine = r
                end
            end
            t:assertNotNil(auberdine, "the Menethil dock to Auberdine")
            local target, nav = dock.target(N, auberdine)
            t:assertEqual(target.facilityKind, "boat")
            local start = catalog.autoPoints(N, x, y, nil, 1)[1]
            local outcome = runJob(N.Job(route.prepare, route, catalog.contract(auberdine, 0), { nativeMapId = 0 },
                start.nodeId))
            t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
            -- the route is not cut on the pier (the tram's drop rule): its end lies at the dock
            local ex, ey = N.Position(outcome.plan.path[#outcome.plan.path])
            local reach = target.waitingRadius + target.boardingPreviewDistance
            t:assertTrue(Route.distance(ex, ey, target.x, target.y) <= reach,
                "the route ends within the boarding beacon's reach of the dock")
            -- walked with the dock's arrival rule (module.lua: route.waitCheck), the route ends
            route:begin(outcome.plan, catalog.contract(auberdine, 0), outcome.result, auberdine.n)
            route.waitCheck = dock.waitAreaCheck(N, target)
            local arrived
            for _ = 1, 2000 do
                game.t = game.t + 0.3
                game.x, game.y = N.Position(route.path[route.pathIndex])
                x, y = game.x, game.y
                game.moving = true
                local event = route:update(game.x, game.y)
                if event and event.kind == "arrived" then
                    arrived = event
                    break
                end
            end
            t:assertNotNil(arrived, "the route to the dock ends")
            ex, ey = game.x, game.y
            -- arrived there, his boarding beacon has its point
            x, y = ex, ey
            local Dock = _G.WowVisionNavigationDockNavigation
            Dock:Reset(false)
            Dock:Arrival(target, dock.nav(N, target.zoneId), ex, ey)
            t:assertNotNil(dock.alignment(N, ex, ey), "the boarding point is the next point")
        end)
        _G.UnitPosition = saved
        _G.WowVisionNavigationDockNavigation:Reset(false)
        if not ok then
            error(err, 0)
        end
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
            -- picked as a route's destination, a boarding point is routed to like any place (from a waypoint nearby)
            local game = newGame()
            game.map = TRAM_MAP
            local route = Route.new(game.env)
            local point = hits[1]
            local start = catalog.autoPoints(N, from.x, from.y, nil, 1)[1]
            t:assertNotNil(start, "a waypoint at the dock")
            local contract = { id = "wowvision:boarding", kind = "live", nameEn = point.n, nativeMapId = TRAM_MAP,
                coordinateSpace = "world", x = point.x, y = point.y, z = point.z,
                zStatus = point.z == nil and "unknown" or "known" }
            local outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = TRAM_MAP }, start.nodeId))
            t:assertTrue(outcome.kind == "start" or outcome.kind == "choose", tostring(outcome.reason))
        end)
    end

    suite["a compact class names a dungeon entrance from its key; a dyn entrance names its wing"] = function(t)
        setup()
        local catalogue = N.LogicalTargets(1446)
        t:assertNotNil(catalogue, "Tanaris")
        local classes = C.ValidateCatalog(catalogue)
        local found
        for _, class in ipairs(classes) do
            if class.nameKey == "dungeon_entrance" then
                found = class
            end
        end
        t:assertNotNil(found, "Tanaris has a dungeon entrance in its logical catalogue")
        t:assertEqual(found.nameParam, "Zul'Farrak")
        t:assertEqual(found.nameMapId, 209)
        local rows = zoneRows(18, "graveyard")
        local graveyard
        for _, r in ipairs(rows) do
            if r.n == "Dungeon entrance: Scarlet Monastery, Graveyard" then
                graveyard = r
            end
        end
        t:assertNotNil(graveyard, "Tirisfal lists the Scarlet Monastery graveyard wing")
    end

    suite["a fishing spot: listed by name, the arrival on its place says where the water is, I faces it"] = function(t)
        setup()
        local rows = zoneRows(ELWYNN, "fishing spot")
        local row
        for _, r in ipairs(rows) do
            if r.kind == "fishing_spot" then
                row = row or r
                t:assertNotNil(r.n:find("^Fishing spot on "), r.n)
                t:assertEqual(r.layer, "dyn")
            end
        end
        t:assertNotNil(row, "Elwynn has fishing spots")
        local german = catalog.search(N, C, 0, "angelplatz", row.x, row.y, { german = false })
        t:assertTrue(#german > 0, "the German search word finds them too")
        local contract = catalog.contract(row, 0)
        t:assertTrue(C.Validate(contract), "a fishing spot makes a valid target")
        local spot = fishing.spot(N, contract)
        t:assertNotNil(spot, "the full row with the direction to the water")
        local said
        local savedSay, savedFacing = text.say, _G.GetPlayerFacing
        text.say = function(message)
            said = message
        end
        -- facing east (angle 0): the water's sector follows from the row's direction
        _G.GetPlayerFacing = function()
            return 0
        end
        t:assertFalse(fishing.arrived(N, contract, row.x + 30, row.y, 3), "not on the place: no arrival")
        t:assertFalse(fishing.reached())
        t:assertTrue(fishing.arrived(N, contract, row.x, row.y, 3))
        t:assertTrue(fishing.reached())
        t:assertNotNil(said and said:find("^" .. row.n:gsub("%p", "%%%0") .. " reached%. The water is "), said)
        t:assertNotNil(said:find("Cast range about 10 to 20 yards. Press I to turn to the water.", 1, true), said)
        local px, py, id = fishing.alignment(N, row.x + 1, row.y)
        t:assertEqual(id, "fishing-water:" .. row.tid)
        t:assertTrue(math.abs(px - (spot.x + spot.fishingDirX * 15)) < 0.01, "I faces the water point")
        t:assertTrue(math.abs(py - (spot.y + spot.fishingDirY * 15)) < 0.01)
        t:assertNil(fishing.alignment(N, row.x + 25, row.y), "off the place, I has no water to face")
        fishing.reset()
        t:assertFalse(fishing.reached())
        text.say, _G.GetPlayerFacing = savedSay, savedFacing
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

    suite["the route to the target: a creature is found by its ID near the player, only there"] = function(t)
        setup()
        -- Innkeeper Allison of Stormwind, creature 6740
        local inn = zoneRows(STORMWIND, "allison")[1]
        t:assertNotNil(inn, "the innkeeper is listed")
        local row = catalog.creatureRow(N, C, 0, 6740, inn.x + 10, inn.y + 10, 120)
        t:assertNotNil(row)
        t:assertEqual(row.tid, inn.tid, "the same target as the list's")
        t:assertTrue(row.distance < 15)
        t:assertNil(catalog.creatureRow(N, C, 0, 6740, inn.x + 300, inn.y, 120), "too far: another spawn")
        t:assertNil(catalog.creatureRow(N, C, 0, 999999, inn.x, inn.y, 120), "no such creature")
    end

    -- A portal of map: a route from a waypoint of the source zone to the portal's far end, walked waypoint by
    -- waypoint; the game teleports the player once he is in the portal's source volume, at its height. unseen: the
    -- teleport comes before any update sees him in it. Returns the transit event, the continuation's state after the
    -- landing, the walked route, the index of the waypoint the player walked to at the transit and at the portal ahead.
    local function throughPortal(t, map, zoneId, portalId, unseen, radius)
        setup()
        N.activeMapId = map
        local game = newGame()
        game.map = map
        local route = Route.new(game.env)
        local zone = N.LoadZone(zoneId)
        local portal
        for _, action in ipairs(zone.actions) do
            if action.id == portalId then
                portal = action
            end
        end
        t:assertNotNil(portal, portalId)
        local sv, av = portal.sourceVolume, portal.arrivalVolume
        sv.radius = radius or sv.radius
        local startId
        for i = 0, 5000 do
            local id = zoneId * N.ZONE_BASE + i
            local x, y = N.Position(id)
            if startId == nil and x ~= nil and Route.distance(x, y, sv.x, sv.y) > 80 then
                startId = id
            end
        end
        local plan = runJob(N.Job(route.planToNode, route, portal.toNode, { id = startId }))
        t:assertNotNil(plan, "a route to the far end")
        t:assertEqual(plan.pendingAction and plan.pendingAction.id, portalId, "the route takes the portal")
        route:begin(plan, {}, { quality = "exact" }, "far end")
        local transit, teleported, ahead, transitAt, aheadAt
        for _ = 1, 400 do
            game.t = game.t + 0.3
            local x, y, z
            if teleported then
                x, y = av.x, av.y
            else
                x, y, z = N.Position(route.path[route.pathIndex])
                teleported = Route.inVolume2D(sv, x, y) and math.abs(z - sv.z) <= (sv.half_z or sv.radius or 0)
                if teleported and unseen then
                    x, y = av.x, av.y
                end
            end
            game.x, game.y, game.moving = x, y, true
            local at = route.pathIndex
            local event = route:update(x, y)
            if event and event.kind == "transitAhead" then
                t:assertNil(ahead, "the portal ahead is said once")
                ahead, aheadAt = event, at
            elseif event and event.kind == "transit" then
                transit, transitAt = event, at
                break
            end
        end
        t:assertNotNil(transit, "the route waits for the portal")
        t:assertNotNil(ahead, "the portal is said before it")
        route:startAction(transit.action, {}, portal.toNode, nil, transit)
        -- at the route's end the player walks on into the portal, which teleports him (no observation inside it)
        local state = route:observeAction(game.x, game.y, map, 3)
        if state == nil then
            state = route:observeAction(av.x + 1, av.y + 1, map, 3)
        end
        return transit, state, route, transitAt, aheadAt
    end

    suite["a portal crossed before the route's end: the route waits for it as the player walks in"] = function(t)
        -- Darnassus to Rut'theran: the route crosses the portal (waypoints 7.9 and 9.3 yd from its centre) before its
        -- end, 10.8 yd outside
        local transit, state = throughPortal(t, 1, 1457, "portal:areatrigger:527", false)
        t:assertTrue(transit.sourceEntered == true, "in the portal, before the route's last waypoint")
        t:assertTrue(transit.announced == true, "said before the portal, not again in it")
        t:assertEqual(state, "arrived", "the route goes on in Rut'theran")
        transit, state = throughPortal(t, 1, 1457, "portal:areatrigger:527", true)
        t:assertTrue(transit.teleported == true, "only the landing was seen")
        t:assertTrue(transit.announced == true, "said before the teleport")
        t:assertEqual(state, "arrived")
    end

    suite["a portal at the route's last waypoint: the route waits for it, seen in it or not"] = function(t)
        -- Rut'theran to Darnassus: the route's last waypoint lies 10.4 yd from the centre of the 10 yd portal (data
        -- 0d79304), so the volume is widened to put it on the rim, the case this test is about
        local radius = 11
        local transit, state, route, at = throughPortal(t, 1, 57, "portal:areatrigger:542", false, radius)
        t:assertEqual(at, #route.path, "in the portal at the route's last waypoint")
        t:assertTrue(transit.sourceEntered == true)
        t:assertTrue(transit.announced == true, "said before the portal, not again in it")
        t:assertEqual(state, "arrived", "the route goes on in Darnassus")
        transit, state = throughPortal(t, 1, 57, "portal:areatrigger:542", true, radius)
        t:assertTrue(transit.teleported == true, "only the landing was seen")
        t:assertTrue(transit.announced == true, "said before the teleport")
        t:assertEqual(state, "arrived")
    end

    suite["a portal walked into after the route's end: its teleport alone proves it"] = function(t)
        -- The route ends at the portal without seeing the player in it (his transit at the last waypoint); the next
        -- observation is already at the far end, a jump of more than Route.TELEPORT_JUMP
        local transit, _, route = throughPortal(t, 1, 57, "portal:areatrigger:542", false)
        local action = transit.action
        local sv, av = action.sourceVolume, action.arrivalVolume
        route:reset()
        route:startAction(action, {}, action.toNode, nil, { kind = "transit", action = action, announced = true })
        t:assertNil(route:observeAction(sv.x + sv.radius + 2, sv.y, 1, 3), "outside the portal: nothing yet")
        t:assertEqual(route:observeAction(av.x, av.y, 1, 3), "arrived", "the jump to the far end proves the portal")
    end

    suite["a portal above the route: walking beneath it does not end the route"] = function(t)
        -- Stormwind's Wizard's Sanctum: the ramp up the tower passes 4.1 yd beside the centre of the portal at its top,
        -- 39 yd below it; the route ends 11.7 yd from the centre of the 7 yd portal, at its height
        local transit, state, route, at, aheadAt = throughPortal(t, 0, STORMWIND, "portal:areatrigger:704", false)
        t:assertEqual(at, #route.path, "the transit at the route's last waypoint, not on the ramp below the portal")
        t:assertNil(transit.sourceEntered, "the route ends outside the portal")
        t:assertTrue(transit.announced == true, "said before the portal, not again at the route's end")
        local _, _, z = N.Position(route.path[aheadAt])
        local sv = transit.action.sourceVolume
        t:assertTrue(math.abs(z - sv.z) <= sv.radius + Route.TRANSIT_HEIGHT, "said at the portal's height, not below it")
        t:assertEqual(state, "arrived", "the landing below proves the portal")
    end

    suite["a portal that drops straight down is a link like any other: the route goes on to the portal trainer"] = function(t)
        -- The Wizard's Sanctum again: its portal's source and far end lie 6.4 yd apart in the plane, so leaving the
        -- one cannot be told from arriving at the other there; its two waypoints (the ramp's end above, the room
        -- below) lie 14.3 yd apart, and the player is through once he is nearer to the one below
        setup()
        local game = newGame()
        local route = Route.new(game.env)
        local trainer = zoneRows(STORMWIND, "Larimaine")[1]
        t:assertNotNil(trainer, "Larimaine Purdue, the portal trainer")
        local startId = STORMWIND * N.ZONE_BASE + 1
        game.x, game.y = N.Position(startId)
        local outcome = runJob(N.Job(route.prepare, route, catalog.contract(trainer, 0), { nativeMapId = 0 }, startId))
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
        t:assertEqual(outcome.plan.pendingAction and outcome.plan.pendingAction.id, "portal:areatrigger:704",
            "up the ramp and through the portal at the top")
        route:begin(outcome.plan, catalog.contract(trainer, 0), outcome.result, trainer.n)
        local transit
        for _ = 1, 3000 do
            game.t = game.t + 0.3
            game.x, game.y = N.Position(route.path[route.pathIndex])
            game.moving = true
            local event = route:update(game.x, game.y)
            if event and event.kind == "transit" then
                transit = event
                break
            end
        end
        t:assertNotNil(transit, "the route reaches the portal")
        local action = transit.action
        route:startAction(action, {}, route.targetBindingId, route.result, transit)
        local fx, fy = N.Position(action.fromNode)
        t:assertNil(route:observeAction(fx, fy, 0, 3), "at the ramp's end: not through yet")
        local sv, av = action.sourceVolume, action.arrivalVolume
        t:assertNil(route:observeAction(sv.x, sv.y - 2, 0, 3), "on the portal's near side above: not through yet")
        t:assertEqual(route:observeAction(av.x, av.y, 0, 3), "arrived", "landed in the room below")
        local _, toNode, targetNodeId, result = route:actionArrival()
        t:assertEqual(toNode, action.toNode)
        local next = runJob(N.Job(route.continueTo, route, toNode, targetNodeId, result))
        t:assertEqual(next.kind, "start", tostring(next.reason))
        local lx, ly = N.Position(next.plan.path[#next.plan.path])
        t:assertEqual(next.plan.path[#next.plan.path], targetNodeId, "the route goes on to the trainer's binding")
        local _, _, lz = N.Position(targetNodeId)
        t:assertTrue(Route.distance(lx, ly, trainer.x, trainer.y) < 20 and math.abs(lz - trainer.z) < 3, "in the room below, by the trainer")
    end
end

if haveNetwork then
    local function northshire(name)
        setup()
        N.LoadZone(ELWYNN)
        return zoneRows(ELWYNN, name)[1]
    end

    -- a route from a row to itself as the module starts it: bound like F10's entry point
    local function startAt(row, game)
        local route = Route.new(game.env)
        local id, z = catalog.startNode(N, R, { nativeMapId = 0 }, row, 0)
        route.anchor.last = z
        local contract = catalog.contract(row, 0)
        local outcome = runJob(N.Job(route.prepare, route, contract, { nativeMapId = 0 }, id))
        route:begin(outcome.plan, contract, outcome.result, row.n)
        return route, outcome, contract
    end

    suite["a point on a link routes to itself without leaving it"] = function(t)
        setup()
        local id = nil
        for _, row in ipairs(zoneRows(ELWYNN)) do
            local result = R:Resolve({ nativeMapId = 0 }, catalog.contract(row, 0), {})
            if result ~= nil and result.binding ~= nil and result.binding.type == "link" then
                id = result.endNodeId
                break
            end
        end
        t:assertTrue(id ~= nil, "a target on a link")
        local route = N.RouteIds(id, id)
        t:assertEqual(#route.path, 1)
        t:assertEqual(route.path[1], id)
        t:assertEqual(route.length, 0)
    end

    suite["two points on a link are joined by it, a one way link only forwards"] = function(t)
        setup()
        local zone = N.LoadZone(ELWYNN)
        local both, forward
        for k = 1, #zone.lu do
            both = both or (zone.ldir[k] == 0 and k or nil)
            forward = forward or (zone.ldir[k] == 1 and k or nil)
        end
        local a, b = N.LinkpointNode(zone, both, 50), N.LinkpointNode(zone, both, 200)
        local across = N.RouteIds(b, a)
        t:assertEqual(#across.path, 2)
        t:assertEqual(across.path[1], b)
        t:assertEqual(across.path[2], a)
        t:assertTrue(math.abs(across.length - zone.llen[both] * 150 / 256) < 0.001)
        -- a penalty on the link leaves it to the search
        local u, v = zone.base + zone.lu[both], zone.base + zone.lv[both]
        local avoided = N.RouteIds(b, a, { [u] = { [v] = 1000 }, [v] = { [u] = 1000 } })
        t:assertTrue(avoided == nil or #avoided.path > 2, "the search decides")
        local c, d = N.LinkpointNode(zone, forward, 50), N.LinkpointNode(zone, forward, 200)
        t:assertEqual(#N.RouteIds(c, d).path, 2, "along its direction")
        local back = N.RouteIds(d, c)
        t:assertTrue(back == nil or #back.path > 2, "against it, only over other links")
    end

    suite["the same spot: floors apart is not, a missing height does not count"] = function(t)
        t:assertTrue(Route.sameSpot({ x = 1, y = 1, z = 5 }, { x = 1, y = 2, z = 6 }))
        t:assertEqual(Route.sameSpot({ x = 1, y = 1 }, { x = 1, y = 4 }), false, "too far in the plane")
        t:assertEqual(Route.sameSpot({ x = 1, y = 1, z = 5 }, { x = 1, y = 1, z = 15 }), false, "another floor")
        t:assertTrue(Route.sameSpot({ x = 1, y = 1, z = 5 }, { x = 1, y = 1 }))
        t:assertEqual(Route.sameSpot({ x = 1, y = 1 }, nil), false)
    end

    suite["start and target on one spot: arrived at once, from afar straight to it"] = function(t)
        local deputy = northshire("deputy willem")
        local game = newGame()
        game.x, game.y = deputy.x, deputy.y
        local route, outcome, contract = startAt(deputy, game)
        t:assertEqual(outcome.kind, "start", tostring(outcome.reason))
        t:assertEqual(#route.path, 2, "his network point and the logical end")
        t:assertTrue(Route.sameSpot(deputy, contract))
        t:assertTrue(route:dropToEnd())
        t:assertEqual(#route.path, 1)
        t:assertEqual(route:update(game.x, game.y).kind, "arrived")

        game.x = deputy.x + 20
        route = startAt(deputy, game)
        route:dropToEnd()
        t:assertNil(route:update(game.x, game.y), "not there yet")
        game.x, game.t = deputy.x, game.t + 1
        t:assertEqual(route:update(game.x, game.y).kind, "arrived")
    end
end

testRunner:addSuite("WowNav routes", suite)
