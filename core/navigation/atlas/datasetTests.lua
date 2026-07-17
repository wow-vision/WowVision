local testRunner = WowVision.testing.testRunner

local function newDataset()
    return WowVision.MapDataset:new({ key = "test", label = "Test" })
end

testRunner:addSuite("MapDataset", {
    ["bidirectional links materialize the reverse edge"] = function(t)
        local dataset = newDataset()
        dataset:addWaypoints({
            { id = "a", x = 0, y = 0, cId = 0, n = "A", links = { b = true } },
            { id = "b", x = 10, y = 0, cId = 0, n = "B" },
        })
        t:assertEqual(dataset:getWaypoint("b").links.a, 1)
        t:assertEqual(dataset:getWaypoint("a").links.b, true)
    end,

    ["reverse edges wait for targets in later chunks"] = function(t)
        local dataset = newDataset()
        dataset:addWaypoints({
            { id = "a", x = 0, y = 0, cId = 0, n = "A", links = { b = true } },
        })
        t:assertNil(dataset:getWaypoint("b"))
        dataset:addWaypoints({
            { id = "b", x = 10, y = 0, cId = 0, n = "B" },
        })
        t:assertEqual(dataset:getWaypoint("b").links.a, 1)
    end,

    ["one-way links stay one-way"] = function(t)
        local dataset = newDataset()
        dataset:addWaypoints({
            { id = "cliff", x = 0, y = 0, cId = 0, n = "Cliff top", links = { ground = 1 } },
            { id = "ground", x = 0, y = 30, cId = 0, n = "Cliff base" },
        })
        t:assertNil(dataset:getWaypoint("ground").links)
    end,

    ["redundant two-sided declarations stay stable"] = function(t)
        local dataset = newDataset()
        dataset:addWaypoints({
            { id = "a", x = 0, y = 0, cId = 0, n = "A", links = { b = true } },
            { id = "b", x = 10, y = 0, cId = 0, n = "B", links = { a = true } },
        })
        t:assertEqual(dataset:getWaypoint("a").links.b, true)
        t:assertEqual(dataset:getWaypoint("b").links.a, true)
    end,

    ["waypoints bucket by map and continent"] = function(t)
        local dataset = newDataset()
        dataset:addWaypoints({
            { id = "a", x = 0, y = 0, mapId = 1453, cId = 0, n = "A" },
            { id = "b", x = 10, y = 0, mapId = 1453, cId = 0, n = "B" },
            { id = "c", x = 20, y = 0, mapId = 1454, cId = 1, n = "C" },
        })
        local map = dataset:getWaypointsByMap(1453)
        t:assertNotNil(map.a)
        t:assertNotNil(map.b)
        t:assertNil(map.c)
        t:assertNotNil(dataset:getWaypointsByContinent(1).c)
        t:assertEqual(dataset:getWaypointCount(), 3)
    end,

    ["the router walks shipped-once links in both directions"] = function(t)
        -- The chain ships a->b->c with single bidirectional declarations;
        -- routing c-to-a exercises the materialized reverses.
        local dataset = newDataset()
        dataset:addWaypoints({
            { id = "a", x = 0, y = 0, cId = 0, n = "A", links = { b = true } },
            { id = "b", x = 10, y = 0, cId = 0, n = "B", links = { c = true } },
            { id = "c", x = 20, y = 0, cId = 0, n = "C" },
        })
        local waypoints = dataset:getWaypointsByContinent(0)
        local route = WowVision.Router.route(waypoints, 21, 0, "a", { entryCount = 1 })
        t:assertNotNil(route)
        t:assertEqual(route.waypoints[1].id, "c")
        t:assertEqual(route.waypoints[3].id, "a")
    end,
})
