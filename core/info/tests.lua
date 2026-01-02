local testRunner = WowVision.testing.testRunner

testRunner:addSuite("InfoManager", {
    ["addField creates field with key"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "test", default = "value" })
        t:assertNotNil(info:getField("test"))
    end,

    ["addField stores default value"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "name", default = "Bob" })
        local field = info:getField("name")
        t:assertEqual(field:getDefault({}), "Bob")
    end,

    ["addFields adds multiple fields"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addFields({
            { key = "a" },
            { key = "b" },
            { key = "c" },
        })
        t:assertNotNil(info:getField("a"))
        t:assertNotNil(info:getField("b"))
        t:assertNotNil(info:getField("c"))
    end,

    ["clone creates independent copy"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "original", default = 1 })

        local clone = info:clone()
        clone:addField({ key = "cloneOnly", default = 2 })

        t:assertNotNil(clone:getField("original"))
        t:assertNotNil(clone:getField("cloneOnly"))
        t:assertNil(info:getField("cloneOnly"))
    end,

    ["set applies values to object"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "name" })
        info:addField({ key = "age" })

        local obj = {}
        info:set(obj, { name = "Alice", age = 30 })

        t:assertEqual(obj.name, "Alice")
        t:assertEqual(obj.age, 30)
    end,

    ["set applies defaults when value not provided"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "name", default = "Unknown" })

        local obj = {}
        info:set(obj, {})

        t:assertEqual(obj.name, "Unknown")
    end,
})

testRunner:addSuite("Field.String", {
    ["getGenerator returns EditBox"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ type = "String", key = "name", label = "Name" })
        local field = info:getField("name")
        local gen = field:getGenerator({})
        t:assertEqual(gen[1], "EditBox")
    end,
})

testRunner:addSuite("Field.Number", {
    ["validates numeric input"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ type = "Number", key = "count", default = 0 })
        local field = info:getField("count")
        t:assertEqual(field:validate("42"), 42)
    end,

    ["clamps to minimum"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ type = "Number", key = "count", minimum = 0 })
        local field = info:getField("count")
        t:assertEqual(field:validate(-5), 0)
    end,

    ["clamps to maximum"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ type = "Number", key = "count", maximum = 100 })
        local field = info:getField("count")
        t:assertEqual(field:validate(150), 100)
    end,
})

testRunner:addSuite("Field.Bool", {
    ["getGenerator returns Checkbox"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ type = "Bool", key = "enabled", label = "Enabled" })
        local field = info:getField("enabled")
        local gen = field:getGenerator({})
        t:assertEqual(gen[1], "Checkbox")
    end,
})

testRunner:addSuite("Field.Choice", {
    ["getDefault returns first choice when no default specified"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Choice",
            key = "size",
            choices = {
                { key = "small", label = "Small", value = 1 },
                { key = "medium", label = "Medium", value = 2 },
                { key = "large", label = "Large", value = 3 },
            },
        })
        local field = info:getField("size")
        t:assertEqual(field:getDefault({}), 1)
    end,

    ["getDefault returns explicit default over first choice"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Choice",
            key = "size",
            default = 2,
            choices = {
                { key = "small", label = "Small", value = 1 },
                { key = "medium", label = "Medium", value = 2 },
            },
        })
        local field = info:getField("size")
        t:assertEqual(field:getDefault({}), 2)
    end,

    ["getChoiceByKey finds correct choice"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Choice",
            key = "size",
            choices = {
                { key = "small", label = "Small", value = 1 },
                { key = "medium", label = "Medium", value = 2 },
            },
        })
        local field = info:getField("size")
        local choice = field:getChoiceByKey({}, "medium")
        t:assertNotNil(choice)
        t:assertEqual(choice.value, 2)
    end,

    ["getChoiceByValue finds correct choice"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Choice",
            key = "size",
            choices = {
                { key = "small", label = "Small", value = 1 },
                { key = "medium", label = "Medium", value = 2 },
            },
        })
        local field = info:getField("size")
        local choice = field:getChoiceByValue({}, 2)
        t:assertNotNil(choice)
        t:assertEqual(choice.key, "medium")
    end,

    ["getValueString returns label for value"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Choice",
            key = "size",
            choices = {
                { key = "small", label = "Small", value = 1 },
                { key = "medium", label = "Medium", value = 2 },
            },
        })
        local field = info:getField("size")
        t:assertEqual(field:getValueString({}, 2), "Medium")
    end,
})

testRunner:addSuite("Field.Category", {
    ["stores child fields"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Category",
            key = "settings",
            fields = {
                { key = "volume", type = "Number", default = 50 },
                { key = "muted", type = "Bool", default = false },
            },
        })
        local field = info:getField("settings")
        t:assertNotNil(field:getField("volume"))
        t:assertNotNil(field:getField("muted"))
    end,

    ["getDefault builds nested defaults"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Category",
            key = "settings",
            fields = {
                { key = "volume", type = "Number", default = 50 },
                { key = "muted", type = "Bool", default = false },
            },
        })
        local field = info:getField("settings")
        local defaults = field:getDefault({})
        t:assertEqual(defaults.volume, 50)
        t:assertEqual(defaults.muted, false)
    end,

    ["addField adds to category"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Category",
            key = "settings",
            fields = {},
        })
        local field = info:getField("settings")
        field:addField({ key = "newField", default = "test" })
        t:assertNotNil(field:getField("newField"))
    end,
})
