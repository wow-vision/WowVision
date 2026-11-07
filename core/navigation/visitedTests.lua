local testRunner = WowVision.testing.testRunner
local store = WowVision.visitedStore

testRunner:addSuite("VisitedWaypoints", {
    ["a destination is keyed by its id, a virtual one by map and position"] = function(t)
        t:assertEqual(store.key({ id = "685d4527", x = 1, y = 2 }, 0), "685d4527")
        t:assertEqual(store.key({ id = "wownav:creature_8259", x = 1, y = 2 }, 0), "wownav:creature_8259")
        local a = store.key({ id = "navigation:target", virtual = true, x = 100.4, y = -50.6 }, 0)
        local b = store.key({ id = "navigation:target", virtual = true, x = 100.9, y = -50.2 }, 0)
        t:assertEqual(a, b, "the same spot on a 2 yd grid")
        t:assertTrue(a ~= store.key({ id = "navigation:target", virtual = true, x = 100.4, y = -50.6 }, 1),
            "another map, another key")
    end,

    ["a destination counts as visited for the set minutes"] = function(t)
        local points = {}
        store.mark(points, "inn", 1000)
        t:assertTrue(store.isVisited(points, "inn", 1000, 15))
        t:assertTrue(store.isVisited(points, "inn", 1000 + 15 * 60 - 1, 15))
        t:assertFalse(store.isVisited(points, "inn", 1000 + 15 * 60, 15), "after 15 minutes no longer")
        t:assertFalse(store.isVisited(points, "forge", 1000, 15), "never reached")
        store.mark(points, "inn", 5000)
        t:assertTrue(store.isVisited(points, "inn", 5000 + 60, 15), "reached again: counts from then")
    end,

    ["what no longer counts is dropped; forgetting drops everything"] = function(t)
        local points = { old = 0, fresh = 1000 }
        store.prune(points, 1000 + 5 * 60, 10)
        t:assertNil(points.old)
        t:assertEqual(points.fresh, 1000)
        store.forget(points)
        t:assertNil(next(points))
    end,

    ["the same object: the route data's name before its first field, case-folded"] = function(t)
        t:assertEqual(store.baseName("Kobold Vermin;Elwynn Forest;1;48.89;36.44"), "kobold vermin")
        t:assertEqual(store.baseName("Kobold Vermin;Elwynn Forest;2;49.55;36.06"), "kobold vermin")
        t:assertEqual(store.baseName("Peacebloom"), "peacebloom")
        t:assertEqual(store.baseName("  Peacebloom "), "peacebloom")
        t:assertNil(store.baseName(nil))
    end,

    ["the nearest candidate that is not ruled out"] = function(t)
        local candidates = {
            { waypoint = { id = "a" }, distance = 5 },
            { waypoint = { id = "b" }, distance = 9 },
            { waypoint = { id = "c" }, distance = 20 },
        }
        local visited = { a = true }
        local best = store.nearest(candidates, function(wp)
            return visited[wp.id] == true
        end)
        t:assertEqual(best.waypoint.id, "b")
        t:assertNil(store.nearest(candidates, function()
            return true
        end))
    end,

    ["the nearest few not ruled out, nearest first"] = function(t)
        local candidates = {
            { waypoint = { id = "far" }, distance = 30 },
            { waypoint = { id = "a" }, distance = 5 },
            { waypoint = { id = "b" }, distance = 9 },
            { waypoint = { id = "c" }, distance = 20 },
        }
        local list = store.nearestN(candidates, function(wp)
            return wp.id == "a"
        end, 2)
        t:assertEqual(#list, 2)
        t:assertEqual(list[1].waypoint.id, "b")
        t:assertEqual(list[2].waypoint.id, "c")
    end,
})
