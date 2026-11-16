local testRunner = WowVision.testing.testRunner
local graph = WowVision.graph
local doublePress = graph.doublePress
local ControlId = graph.ControlId
local Builder = graph.Builder
local KeyGraph = graph.KeyGraph

-- A slot node: filled carries an item name, empty reads "Empty" and says so through isEmpty.
local function slot(name)
    return {
        announcements = { { text = name or "Empty" } },
        isEmpty = function()
            return name == nil
        end,
    }
end

-- A KeyGraph over slots (nil = empty), as a column or (row = true) one row.
local function slotGraph(names, count, row)
    local state = graph.newState()
    local kg = KeyGraph:new(function()
        local b = Builder:new(state.expanded)
        if row then
            b:startRow()
        end
        for i = 1, count do
            b:addItem(ControlId.structural("s" .. i), slot(names[i]))
        end
        if row then
            b:endRow()
        end
        return b:build()
    end, state)
    kg:rerender()
    return kg, state
end

testRunner:addSuite("DoublePress", {
    ["the same key twice within the window doubles"] = function(t)
        local state = doublePress.newState()
        t:assertFalse(doublePress.press(state, "down", 10, "screen", "a"), "a first press never doubles")
        doublePress.settle(state, "b")
        t:assertTrue(doublePress.press(state, "down", 10.2, "screen", "b"))
        doublePress.settle(state, "c")
        t:assertTrue(doublePress.press(state, "down", 10.4, "screen", "c"), "keeping the rhythm doubles again")
    end,

    ["too slow, another key, another screen or moved focus is a plain press"] = function(t)
        local state = doublePress.newState()
        doublePress.press(state, "down", 10, "screen", "a")
        doublePress.settle(state, "b")
        t:assertFalse(doublePress.press(state, "down", 10.3, "screen", "b"), "too slow")
        doublePress.settle(state, "c")
        t:assertFalse(doublePress.press(state, "up", 10.4, "screen", "c"), "down then up")
        doublePress.settle(state, "b")
        t:assertFalse(doublePress.press(state, "up", 10.5, "other", "b"), "another screen")
        doublePress.settle(state, "a")
        t:assertFalse(doublePress.press(state, "up", 10.6, "other", "x"), "focus moved by a rebuild")
        doublePress.settle(state, "y")
        doublePress.reset(state)
        t:assertFalse(doublePress.press(state, "up", 10.7, "other", "y"), "another input in between")
    end,

    ["a press dispatched out of order is a plain press"] = function(t)
        local state = doublePress.newState()
        doublePress.press(state, "down", 10.2, "screen", "a")
        doublePress.settle(state, "a")
        t:assertFalse(doublePress.press(state, "down", 10.1, "screen", "a"), "earlier than the previous press")
    end,

    ["a skip passes the empty slots and lands on the next item"] = function(t)
        local kg, state = slotGraph({ "Bread", nil, nil, "Water", nil }, 5)
        local move = kg:moveSkippingEmpty("down")
        t:assertTrue(move.moved)
        t:assertEqual(state.curKey.key, "s4")
        t:assertEqual(move.from.id.key, "s1")
    end,

    ["a skip always moves at least one step"] = function(t)
        local kg, state = slotGraph({ "Bread", "Water", nil }, 3)
        kg:moveSkippingEmpty("down")
        t:assertEqual(state.curKey.key, "s2")
    end,

    ["with no item left the skip ends on the last slot"] = function(t)
        local kg, state = slotGraph({ "Bread", nil, nil }, 3)
        kg:moveSkippingEmpty("down")
        t:assertEqual(state.curKey.key, "s3")
        t:assertFalse(kg:moveSkippingEmpty("down").moved, "at the end nothing moves")
        kg:moveSkippingEmpty("up")
        t:assertEqual(state.curKey.key, "s1", "back up to the item")
    end,

    ["a skip runs along a row"] = function(t)
        local kg, state = slotGraph({ nil, nil, "Fireball", nil, "Frost Nova" }, 5, true)
        kg:moveSkippingEmpty("right")
        t:assertEqual(state.curKey.key, "s3")
        kg:moveSkippingEmpty("right")
        t:assertEqual(state.curKey.key, "s5")
    end,

    ["nodes without isEmpty are a plain step"] = function(t)
        local plain = graph.newState()
        local pkg = KeyGraph:new(function()
            local b = Builder:new(plain.expanded)
            b:addLabel(ControlId.structural("a"), "A"):addLabel(ControlId.structural("b"), "B")
            b:addLabel(ControlId.structural("c"), "C")
            return b:build()
        end, plain)
        pkg:rerender()
        pkg:moveSkippingEmpty("down")
        t:assertEqual(plain.curKey.key, "b")
    end,
})
