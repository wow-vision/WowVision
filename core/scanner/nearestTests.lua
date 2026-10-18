local testRunner = WowVision.testing.testRunner
local nearest = WowVision.scannerNearest

local function fromOrigin(x, y)
    return math.sqrt(x * x + y * y)
end

testRunner:addSuite("ScannerNearest", {
    ["the closest placed node wins"] = function(t)
        local nodes = {
            { key = "a", label = "far", x = 100, y = 0 },
            { key = "b", label = "near", x = 10, y = 0 },
            { key = "c", label = "middle", x = 50, y = 0 },
        }
        local node, distance = nearest.pick(nodes, fromOrigin)
        t:assertEqual(node.key, "b")
        t:assertEqual(distance, 10)
    end,

    ["subcategories without a position are searched, lazy lists resolved once"] = function(t)
        local calls = 0
        local nodes = {
            {
                key = "nearby",
                children = function()
                    calls = calls + 1
                    return { { key = "q1", x = 30, y = 40 } }
                end,
            },
            { key = "inProgress", children = { { key = "q2", x = 3, y = 4 }, { key = "loading" } } },
        }
        local node, distance = nearest.pick(nodes, fromOrigin)
        t:assertEqual(node.key, "q2")
        t:assertEqual(distance, 5)
        t:assertEqual(calls, 1)
        t:assertEqual(type(nodes[1].children), "table", "the resolved list is kept on the node")
    end,

    ["a placed node with spawns beneath counts by its own position, not its children"] = function(t)
        local nodes = {
            { key = "giver", x = 20, y = 0, children = { { key = "spawn", x = 1, y = 0 } } },
            { key = "other", x = 15, y = 0 },
        }
        local node = nearest.pick(nodes, fromOrigin)
        t:assertEqual(node.key, "other")
    end,

    ["nothing placed, or no player position, gives nil"] = function(t)
        t:assertNil(nearest.pick({ { key = "loading" }, { key = "empty", children = {} } }, fromOrigin))
        t:assertNil(nearest.pick({ { key = "a", x = 1, y = 1 } }, function()
            return nil
        end))
        t:assertNil(nearest.pick(nil, fromOrigin))
    end,
})
