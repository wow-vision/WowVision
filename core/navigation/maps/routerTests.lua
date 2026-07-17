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
            { id = "island", x = 100, y = 100, links = {} },
        })
        -- Entry seeding considers the island too, so route TO it succeeds
        -- directly; route THROUGH the graph to it must fail when entries
        -- are limited to the connected part.
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
})
