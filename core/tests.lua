local testRunner = WowVision.testing.testRunner

-- Registry tests
testRunner:addSuite("Registry", {
    ["register stores item by key"] = function(t)
        local reg = WowVision.Registry:new()
        reg:register("foo", "bar")
        t:assertEqual(reg:get("foo"), "bar")
    end,

    ["get returns nil for unknown key"] = function(t)
        local reg = WowVision.Registry:new()
        t:assertNil(reg:get("unknown"))
    end,

    ["get returns default for unknown key"] = function(t)
        local reg = WowVision.Registry:new({ default = "fallback" })
        t:assertEqual(reg:get("unknown"), "fallback")
    end,

    ["get accepts inline default"] = function(t)
        local reg = WowVision.Registry:new()
        t:assertEqual(reg:get("unknown", "inline"), "inline")
    end,

    ["register errors on duplicate without allowReplace"] = function(t)
        local reg = WowVision.Registry:new()
        reg:register("key", "value1")
        t:assertError(function()
            reg:register("key", "value2")
        end)
    end,

    ["register replaces with allowReplace"] = function(t)
        local reg = WowVision.Registry:new({ allowReplace = true })
        reg:register("key", "value1")
        reg:register("key", "value2")
        t:assertEqual(reg:get("key"), "value2")
    end,

    ["items are iterable in order"] = function(t)
        local reg = WowVision.Registry:new()
        reg:register("a", 1)
        reg:register("b", 2)
        reg:register("c", 3)
        t:assertEqual(reg.items[1], 1)
        t:assertEqual(reg.items[2], 2)
        t:assertEqual(reg.items[3], 3)
    end,
})

-- Event tests
testRunner:addSuite("Event", {
    ["emit calls subscriber handler"] = function(t)
        local event = WowVision.Event:new("test")
        local called = false
        local subscriber = {}
        event:subscribe(subscriber, function()
            called = true
        end)
        event:emit()
        t:assertTrue(called)
    end,

    ["emit passes arguments to handler"] = function(t)
        local event = WowVision.Event:new("test")
        local receivedArg = nil
        local subscriber = {}
        event:subscribe(subscriber, function(sub, name, arg)
            receivedArg = arg
        end)
        event:emit("hello")
        t:assertEqual(receivedArg, "hello")
    end,

    ["emit calls handler without subscriber"] = function(t)
        local event = WowVision.Event:new("test")
        local called = false
        event:subscribe(nil, function()
            called = true
        end)
        event:emit()
        t:assertTrue(called)
    end,

    ["unsubscribe removes subscriber"] = function(t)
        local event = WowVision.Event:new("test")
        local callCount = 0
        local subscriber = {}
        event:subscribe(subscriber, function()
            callCount = callCount + 1
        end)
        event:emit()
        event:unsubscribe(subscriber)
        event:emit()
        t:assertEqual(callCount, 1)
    end,

    ["multiple handlers for same subscriber"] = function(t)
        local event = WowVision.Event:new("test")
        local callCount = 0
        local subscriber = {}
        event:subscribe(subscriber, function()
            callCount = callCount + 1
        end)
        event:subscribe(subscriber, function()
            callCount = callCount + 1
        end)
        event:emit()
        t:assertEqual(callCount, 2)
    end,
})

-- Utils tests
testRunner:addSuite("utils", {
    ["splitString splits by delimiter"] = function(t)
        local result = WowVision.utils.splitString("a,b,c", ",")
        t:assertEqual(#result, 3)
        t:assertEqual(result[1], "a")
        t:assertEqual(result[2], "b")
        t:assertEqual(result[3], "c")
    end,

    ["splitString handles no delimiter"] = function(t)
        local result = WowVision.utils.splitString("hello", ",")
        t:assertEqual(#result, 1)
        t:assertEqual(result[1], "hello")
    end,

    ["splitString handles empty parts"] = function(t)
        local result = WowVision.utils.splitString("a,,c", ",")
        t:assertEqual(#result, 3)
        t:assertEqual(result[1], "a")
        t:assertEqual(result[2], "")
        t:assertEqual(result[3], "c")
    end,

    ["splitString handles multi-char delimiter"] = function(t)
        local result = WowVision.utils.splitString("a::b::c", "::")
        t:assertEqual(#result, 3)
        t:assertEqual(result[1], "a")
        t:assertEqual(result[2], "b")
        t:assertEqual(result[3], "c")
    end,
})

-- Dataset tests
testRunner:addSuite("Dataset", {
    ["addPoint stores point"] = function(t)
        local ds = WowVision.Dataset:new()
        ds:addPoint({ id = 1, name = "test" })
        t:assertNotNil(ds.pointsById[1])
    end,

    ["addPoint requires id"] = function(t)
        local ds = WowVision.Dataset:new()
        t:assertError(function()
            ds:addPoint({ name = "no id" })
        end)
    end,

    ["clear removes all points"] = function(t)
        local ds = WowVision.Dataset:new()
        ds:addPoint({ id = 1 })
        ds:addPoint({ id = 2 })
        ds:clear()
        t:assertEqual(#ds.data, 0)
        t:assertNil(ds.pointsById[1])
    end,

    ["filter creates filtered dataset"] = function(t)
        local ds = WowVision.Dataset:new()
        -- Note: validateFilter compares two fields, so we need a threshold field
        ds:addPoint({ id = 1, value = 10, threshold = 15 })
        ds:addPoint({ id = 2, value = 20, threshold = 15 })
        ds:addPoint({ id = 3, value = 30, threshold = 15 })

        local filtered = ds:filter({ { "value", ">", "threshold" } })
        t:assertEqual(#filtered.data, 2)
    end,

    -- Note: validateFilter compares two FIELDS in the data object (both operands are keys)
    ["validateFilter equality"] = function(t)
        local ds = WowVision.Dataset:new()
        t:assertTrue(ds:validateFilter({ a = 10, b = 10 }, { "a", "=", "b" }))
        t:assertFalse(ds:validateFilter({ a = 10, b = 20 }, { "a", "=", "b" }))
    end,

    ["validateFilter inequality"] = function(t)
        local ds = WowVision.Dataset:new()
        t:assertTrue(ds:validateFilter({ a = 10, b = 20 }, { "a", "~=", "b" }))
        t:assertFalse(ds:validateFilter({ a = 10, b = 10 }, { "a", "~=", "b" }))
    end,

    ["validateFilter less than"] = function(t)
        local ds = WowVision.Dataset:new()
        t:assertTrue(ds:validateFilter({ a = 5, b = 10 }, { "a", "<", "b" }))
        t:assertFalse(ds:validateFilter({ a = 10, b = 10 }, { "a", "<", "b" }))
    end,

    ["validateFilter greater than"] = function(t)
        local ds = WowVision.Dataset:new()
        t:assertTrue(ds:validateFilter({ a = 15, b = 10 }, { "a", ">", "b" }))
        t:assertFalse(ds:validateFilter({ a = 10, b = 10 }, { "a", ">", "b" }))
    end,
})

-- ViewList tests
-- Helper to create a ViewList-enabled object (ViewList is a mixin)
local function createViewList()
    local list = setmetatable({}, { __index = WowVision.ViewList })
    list:setupViewList()
    return list
end

testRunner:addSuite("ViewList", {
    ["add appends item"] = function(t)
        local list = createViewList()
        list:add("item1")
        list:add("item2")
        t:assertEqual(#list.items, 2)
        t:assertEqual(list.items[1], "item1")
    end,

    ["add inserts at index"] = function(t)
        local list = createViewList()
        list:add("a")
        list:add("c")
        list:add(2, "b")
        t:assertEqual(list.items[2], "b")
    end,

    ["remove removes item"] = function(t)
        local list = createViewList()
        list:add("a")
        list:add("b")
        list:remove("a")
        t:assertEqual(#list.items, 1)
        t:assertEqual(list.items[1], "b")
    end,

    ["clear removes all items"] = function(t)
        local list = createViewList()
        list:add("a")
        list:add("b")
        list:clear()
        t:assertEqual(#list.items, 0)
    end,

    ["getFocus returns current item"] = function(t)
        local list = createViewList()
        list:add("a")
        list:add("b")
        list.index = 2
        t:assertEqual(list:getFocus(), "b")
    end,

    ["focusIndex sets index"] = function(t)
        local list = createViewList()
        list:add("a")
        list:add("b")
        list:add("c")
        list:focusIndex(2)
        t:assertEqual(list.index, 2)
    end,

    ["focusDirection moves forward"] = function(t)
        local list = createViewList()
        list:add("a")
        list:add("b")
        list:add("c")
        list.index = 1
        list:focusDirection(1)
        t:assertEqual(list.index, 2)
    end,

    ["focusDirection moves backward"] = function(t)
        local list = createViewList()
        list:add("a")
        list:add("b")
        list:add("c")
        list.index = 3
        list:focusDirection(-1)
        t:assertEqual(list.index, 2)
    end,

    ["focusDirection wraps when enabled"] = function(t)
        local list = createViewList()
        list.wrap = true
        list:add("a")
        list:add("b")
        list:add("c")
        list.index = 3
        list:focusDirection(1)
        t:assertEqual(list.index, 1)
    end,

    ["focusDirection respects reverse"] = function(t)
        local list = createViewList()
        list.reverse = true
        list:add("a")
        list:add("b")
        list:add("c")
        list.index = 2
        list:focusDirection(1) -- Should go backward due to reverse
        t:assertEqual(list.index, 1)
    end,
})
