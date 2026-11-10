local testRunner = WowVision.testing.testRunner
local Router = WowVision.Router

-- Build a waypoint map from { id, x, y, links = { ids } } shorthand.
local function graph(nodes)
    local waypoints = {}
    for _, node in ipairs(nodes) do
        local links = {}
        for _, id in ipairs(node.links or {}) do
            links[id] = true
        end
        waypoints[node.id] = { id = node.id, x = node.x, y = node.y, links = links }
    end
    return waypoints
end

local function ids(route)
    local result = {}
    for _, wp in ipairs(route.waypoints) do
        tinsert(result, wp.id)
    end
    return table.concat(result, ",")
end

testRunner:addSuite("MapRouter", {
    ["routes a straight chain"] = function(t)
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = { "a", "c" } },
            { id = "c", x = 20, y = 0, links = { "b" } },
        })
        local route = Router.route(waypoints, -5, 0, "c", { entryCount = 1 })
        t:assertNotNil(route)
        t:assertEqual(ids(route), "a,b,c")
        t:assertEqual(route.distance, 25) -- 5 to enter + 10 + 10
    end,

    ["prefers the shorter branch"] = function(t)
        -- Two ways from a to d: through b (short) or through c (long detour).
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b", "c" } },
            { id = "b", x = 10, y = 0, links = { "a", "d" } },
            { id = "c", x = 0, y = 50, links = { "a", "d" } },
            { id = "d", x = 20, y = 0, links = { "b", "c" } },
        })
        local route = Router.route(waypoints, 0, 0, "d", { entryCount = 1 })
        t:assertEqual(ids(route), "a,b,d")
    end,

    ["a longer first hop can still win"] = function(t)
        -- The nearest waypoint is a dead end; the route should enter the
        -- graph through the slightly farther connected one.
        local waypoints = graph({
            { id = "deadEnd", x = 1, y = 0, links = {} },
            { id = "door", x = 4, y = 0, links = { "goal" } },
            { id = "goal", x = 10, y = 0, links = { "door" } },
        })
        local route = Router.route(waypoints, 0, 0, "goal", { entryCount = 2 })
        t:assertNotNil(route)
        t:assertEqual(ids(route), "door,goal")
    end,

    ["destination can be the entry waypoint"] = function(t)
        local waypoints = graph({
            { id = "a", x = 3, y = 4, links = {} },
        })
        local route = Router.route(waypoints, 0, 0, "a")
        t:assertEqual(ids(route), "a")
        t:assertEqual(route.distance, 5)
    end,

    ["unreachable destinations report cleanly"] = function(t)
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = { "a" } },
            { id = "island", x = 100, y = 100, links = { "shore" } },
            { id = "shore", x = 110, y = 100, links = { "island" } },
        })
        -- The island is linked, just not to the player's part, so no last
        -- leg applies; entries limited to the connected part must fail.
        local route, reason = Router.route(waypoints, 0, 0, "island", { entryCount = 2 })
        t:assertNil(route)
        t:assertEqual(reason, "unreachable")
    end,

    ["unknown destination reports cleanly"] = function(t)
        local waypoints = graph({ { id = "a", x = 0, y = 0 } })
        local route, reason = Router.route(waypoints, 0, 0, "nope")
        t:assertNil(route)
        t:assertEqual(reason, "unknown destination")
    end,

    ["empty graphs report no entry"] = function(t)
        local route, reason = Router.route({}, 0, 0, "a")
        t:assertNil(route)
        t:assertEqual(reason, "unknown destination")
        local waypoints = graph({ { id = "far", x = 0, y = 0 } })
        route, reason = Router.route(waypoints, 0, 0, "far", { entryCount = 0 })
        t:assertNil(route)
        t:assertEqual(reason, "no entry")
    end,

    ["links are directed as stored"] = function(t)
        -- a -> b only; routing to a from beyond b cannot go backwards.
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = {} },
        })
        local route = Router.route(waypoints, -1, 0, "b", { entryCount = 1 })
        t:assertEqual(ids(route), "a,b")
        local back, reason = Router.route(waypoints, 11, 0, "a", { entryCount = 1 })
        t:assertNil(back)
        t:assertEqual(reason, "unreachable")
    end,

    ["broken link targets are skipped"] = function(t)
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "missing", "b" } },
            { id = "b", x = 10, y = 0, links = { "a" } },
        })
        local route = Router.route(waypoints, 0, 0, "b", { entryCount = 1 })
        t:assertEqual(ids(route), "a,b")
    end,

    ["finds optimal routes in a grid"] = function(t)
        -- A 5x5 lattice with unit spacing: the best a->z path length is
        -- manhattan (8 edges) since links are axis-aligned.
        local nodes = {}
        local function key(cx, cy)
            return cx .. ":" .. cy
        end
        for cx = 0, 4 do
            for cy = 0, 4 do
                local links = {}
                if cx > 0 then
                    tinsert(links, key(cx - 1, cy))
                end
                if cx < 4 then
                    tinsert(links, key(cx + 1, cy))
                end
                if cy > 0 then
                    tinsert(links, key(cx, cy - 1))
                end
                if cy < 4 then
                    tinsert(links, key(cx, cy + 1))
                end
                tinsert(nodes, { id = key(cx, cy), x = cx, y = cy, links = links })
            end
        end
        local waypoints = graph(nodes)
        local route = Router.route(waypoints, 0, 0, key(4, 4), { entryCount = 1 })
        t:assertNotNil(route)
        t:assertEqual(route.distance, 8)
        t:assertEqual(#route.waypoints, 9)
    end,

    ["multi-entry may enter the graph directly at the destination"] = function(t)
        -- With every waypoint seeded as an entry, a crow-flies entry that
        -- ties the through-graph route is legitimate: the player walks
        -- straight there. Real data keeps entries local by density.
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = { "a" } },
        })
        local route = Router.route(waypoints, 0, 0, "b", { entryCount = 5 })
        t:assertEqual(ids(route), "b")
        t:assertEqual(route.distance, 10)
    end,

    ["a chosen entry overrides proximity"] = function(t)
        -- The nearest waypoint would win by distance; the picked entry is
        -- used instead (the user knows their 3D surroundings better).
        local waypoints = graph({
            { id = "below", x = 1, y = 0, links = { "elsewhere" } },
            { id = "bridge", x = 3, y = 0, links = { "goal" } },
            { id = "elsewhere", x = 50, y = 50, links = { "below" } },
            { id = "goal", x = 10, y = 0, links = { "bridge" } },
        })
        local route = Router.route(waypoints, 0, 0, "goal", { entryId = "bridge" })
        t:assertEqual(ids(route), "bridge,goal")
        local missing, reason = Router.route(waypoints, 0, 0, "goal", { entryId = "nope" })
        t:assertNil(missing)
        t:assertEqual(reason, "no entry")
    end,

    ["a resumed route finds the waypoint by id, else the nearest"] = function(t)
        local waypoints = {
            { id = "a", x = 0, y = 0 },
            { id = "b", x = 10, y = 0 },
            { id = "c", x = 20, y = 0 },
        }
        t:assertEqual(Router.resumeIndex(waypoints, { id = "c", x = 0, y = 0 }), 3, "the id wins over the position")
        t:assertEqual(Router.resumeIndex(waypoints, { x = 11, y = 2 }), 2)
        t:assertEqual(Router.resumeIndex(waypoints, { id = "gone", x = 19, y = 0 }), 3)
        t:assertNil(Router.resumeIndex({}, { x = 0, y = 0 }))
    end,

    ["a resumed route prefers a waypoint on the same floor"] = function(t)
        local waypoints = {
            { id = "upstairs", x = 0, y = 0, z = 30 },
            { id = "downstairs", x = 3, y = 0, z = 0 },
        }
        t:assertEqual(Router.resumeIndex(waypoints, { x = 0, y = 0, z = 1 }), 2)
        t:assertEqual(Router.resumeIndex(waypoints, { x = 0, y = 0 }), 1, "no height known: only the plane counts")
    end,

    ["the remaining distance counts from the player over the waypoints left"] = function(t)
        local waypoints = {
            { id = "a", x = 0, y = 0 },
            { id = "b", x = 10, y = 0 },
            { id = "c", x = 20, y = 0 },
        }
        t:assertEqual(Router.remainingDistance(waypoints, 2, 10, 5), 15)
        t:assertEqual(Router.remainingDistance(waypoints, 1, 0, 0), 20)
    end,

    ["an unlinked destination ends with a straight last leg"] = function(t)
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 100, y = 0, links = { "a" } },
            { id = "wolf", x = 100, y = 30 },
        })
        local route = Router.route(waypoints, 0, 0, "wolf", { entryCount = 1 })
        t:assertNotNil(route)
        t:assertEqual(ids(route), "a,b,wolf")
        t:assertEqual(route.lastLeg, 30)
        t:assertEqual(route.distance, 130) -- real yards, not the weighted cost
    end,

    ["the last leg prefers a close exit over a short route"] = function(t)
        -- "road" is closer along the graph but 50 yards from the spawn;
        -- "cave" costs 60 more route yards and leaves only 5 straight.
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "road", "c1" } },
            { id = "road", x = 50, y = 0, links = { "a" } },
            { id = "c1", x = 0, y = 60, links = { "a", "cave" } },
            { id = "cave", x = 50, y = 55, links = { "c1" } },
            { id = "spawn", x = 50, y = 50 },
        })
        local route = Router.route(waypoints, 0, 0, "spawn", { entryCount = 1 })
        t:assertEqual(ids(route), "a,c1,cave,spawn")
        t:assertEqual(route.lastLeg, 5)
    end,

    ["a linked destination has no last leg"] = function(t)
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = { "a" } },
        })
        local route = Router.route(waypoints, 0, 0, "b", { entryCount = 1 })
        t:assertNil(route.lastLeg)
    end,

    ["hasLinks tells network waypoints from bare spawns"] = function(t)
        t:assertEqual(Router.hasLinks({ links = { b = true } }), true)
        t:assertEqual(Router.hasLinks({ links = {} }), false)
        t:assertEqual(Router.hasLinks({}), false)
    end,

    ["a one-way link into an unlinked destination beats the last leg"] = function(t)
        -- The spawn has no links of its own but a one-way link reaches it:
        -- the real edge wins over the weighted straight leg.
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = { "a" } },
            { id = "spawn", x = 10, y = 20 },
        })
        waypoints.b.links.spawn = 1
        local route = Router.route(waypoints, 0, 0, "spawn", { entryCount = 1 })
        t:assertEqual(ids(route), "a,b,spawn")
        t:assertNil(route.lastLeg)
    end,

    ["last-leg exits stay within the distance limit"] = function(t)
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = { "a" } },
            { id = "far", x = 10, y = 600 },
        })
        local route, reason = Router.route(waypoints, 0, 0, "far", { entryCount = 1 })
        t:assertNil(route)
        t:assertEqual(reason, "unreachable")
        route = Router.route(waypoints, 0, 0, "far", { entryCount = 1, maxExitDistance = 1000 })
        t:assertNotNil(route)
        t:assertEqual(route.waypoints[#route.waypoints].id, "far")
        t:assertNotNil(route.lastLeg)
    end,

    ["nearest sorts, limits, and filters"] = function(t)
        local waypoints = graph({
            { id = "close", x = 1, y = 0 },
            { id = "mid", x = 5, y = 0 },
            { id = "far", x = 20, y = 0 },
        })
        local all = Router.nearest(waypoints, 0, 0)
        t:assertEqual(#all, 3)
        t:assertEqual(all[1].waypoint.id, "close")
        t:assertEqual(all[3].waypoint.id, "far")

        local two = Router.nearest(waypoints, 0, 0, 2)
        t:assertEqual(#two, 2)

        local filtered = Router.nearest(waypoints, 0, 0, nil, function(wp)
            return wp.id ~= "close"
        end)
        t:assertEqual(filtered[1].waypoint.id, "mid")
    end,

    ["the nearest entry is preselected, while swimming the nearest in water"] = function(t)
        local entries = {
            { waypoint = { id = "shore" }, distance = 2 },
            { waypoint = { id = "lake", water = true }, distance = 6 },
            { waypoint = { id = "deep", water = true }, distance = 9 },
        }
        local entry, noWater = Router.preselectEntry(entries, false)
        t:assertEqual(entry.waypoint.id, "shore")
        t:assertFalse(noWater)
        entry, noWater = Router.preselectEntry(entries, true)
        t:assertEqual(entry.waypoint.id, "lake", "the nearest water entry, not the nearest")
        t:assertFalse(noWater)
        t:assertEqual(entries[1].waypoint.id, "shore", "the list keeps its order by distance")

        entry, noWater = Router.preselectEntry({ entries[1] }, true)
        t:assertEqual(entry.waypoint.id, "shore", "no water entry: the nearest")
        t:assertTrue(noWater)
        t:assertNil(Router.preselectEntry({}, true))
    end,

    ["nearest by walk: the shorter walk wins over the nearer straight line"] = function(t)
        -- A river between: "near" is 10 yd across it but 60 yd round by the bridge; "far" is 25 yd on this side.
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b", "bridge" } },
            { id = "b", x = 25, y = 0, links = { "a" } },
            { id = "bridge", x = 0, y = 30, links = { "a", "c" } },
            { id = "c", x = 0, y = 10, links = { "bridge" } },
        })
        local near = { id = "near", x = -1, y = 10 }
        local far = { id = "far", x = 26, y = 0 }
        waypoints.near, waypoints.far = near, far
        local wp, route = Router.nearestByWalk(waypoints, 0, 0, { near, far }, { entryId = "a", maxExitDistance = 2 })
        t:assertEqual(wp and wp.id, "far")
        -- the route comes along, as Router.route gives it: a, b, then the last leg to far
        local ids = {}
        for _, step in ipairs(route.waypoints) do
            tinsert(ids, step.id)
        end
        t:assertEqual(table.concat(ids, " "), "a b far")
        t:assertEqual(route.lastLeg, 1)
        t:assertEqual(route.distance, 26)
        local direct = Router.route(waypoints, 0, 0, "far", { entryId = "a", maxExitDistance = 2 })
        t:assertEqual(route.distance, direct.distance, "the same as a search to it")
    end,

    ["nearest by walk: a linked target is reached on the network"] = function(t)
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = { "a", "c" } },
            { id = "c", x = 20, y = 0, links = { "b" } },
        })
        local wp, route = Router.nearestByWalk(waypoints, 0, 0, { waypoints.c, waypoints.b }, { entryId = "a" })
        t:assertEqual(wp.id, "b")
        t:assertEqual(#route.waypoints, 2)
        t:assertNil(route.lastLeg)
        t:assertEqual(route.distance, 10)
    end,

    ["nearest by walk: a target without links of its own, linked into"] = function(t)
        -- "spawn" is reached over b's one-way link (10 yd); "other" only over a last leg of 3 yd, weighted
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b", "c" } },
            { id = "b", x = 10, y = 0, links = { "a", "spawn" } },
            { id = "c", x = 0, y = 5, links = { "a" } },
            { id = "spawn", x = 20, y = 0 },
        })
        local other = { id = "other", x = 0, y = 8 }
        waypoints.other = other
        t:assertEqual(Router.nearestByWalk(waypoints, 0, 0, { other, waypoints.spawn }, { entryId = "a" }).id, "spawn")
    end,

    ["nearest by walk: nothing reachable"] = function(t)
        local waypoints = graph({
            { id = "a", x = 0, y = 0, links = { "b" } },
            { id = "b", x = 10, y = 0, links = { "a" } },
        })
        local lost = { id = "lost", x = 5000, y = 0 }
        waypoints.lost = lost
        local wp, reason = Router.nearestByWalk(waypoints, 0, 0, { lost }, { entryId = "a" })
        t:assertNil(wp)
        t:assertEqual(reason, "unreachable")
        t:assertEqual(select(2, Router.nearestByWalk(waypoints, 0, 0, { lost }, { entryId = "x" })), "no entry")
    end,
})
