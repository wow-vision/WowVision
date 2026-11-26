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

    ["a node that moves is weighed where it is now, and that place comes back"] = function(t)
        local at = { 100, 0 }
        local nodes = {
            { key = "fixed", x = 50, y = 0 },
            {
                key = "member",
                x = 100,
                y = 0,
                position = function()
                    return at[1], at[2]
                end,
            },
            { key = "away", position = function() end },
            { key = "group", children = { { key = "deep", x = 200, y = 0, position = function()
                return 5, 0
            end } } },
        }
        local function place(node)
            if node.position ~= nil then
                return node.position()
            end
            return node.x, node.y
        end
        local node, distance, x, y = nearest.pick(nodes, fromOrigin, nil, place)
        t:assertEqual(node.key, "deep", "a moving node one level down is read too")
        t:assertEqual(distance, 5)
        t:assertEqual(x, 5)
        t:assertEqual(y, 0)
        at = { 3, 0 }
        node, distance = nearest.pick(nodes, fromOrigin, nil, place)
        t:assertEqual(node.key, "member")
        t:assertEqual(distance, 3)
        -- without a place reader the fixed x, y count
        t:assertEqual((nearest.pick(nodes, fromOrigin)).key, "fixed")
    end,

    ["nothing placed, or no player position, gives nil"] = function(t)
        t:assertNil(nearest.pick({ { key = "loading" }, { key = "empty", children = {} } }, fromOrigin))
        t:assertNil(nearest.pick({ { key = "a", x = 1, y = 1 } }, function()
            return nil
        end))
        t:assertNil(nearest.pick(nil, fromOrigin))
    end,
})
