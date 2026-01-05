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

testRunner:addSuite("Field", {
    ["getDefaultDB returns default value"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "name", default = "DefaultName" })
        local field = info:getField("name")
        t:assertEqual(field:getDefaultDB({}), "DefaultName")
    end,

    ["getDefaultDB calls default function with obj"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            key = "computed",
            default = function(obj) return obj.base .. "_suffix" end,
        })
        local field = info:getField("computed")
        t:assertEqual(field:getDefaultDB({ base = "test" }), "test_suffix")
    end,

    ["setDB restores value to object"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "name" })
        local field = info:getField("name")

        local obj = {}
        local db = { name = "RestoredValue" }
        field:setDB(obj, db)

        t:assertEqual(obj.name, "RestoredValue")
    end,

    ["setDB sets obj.db after restoring"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "name" })
        local field = info:getField("name")

        local obj = {}
        local db = { name = "Value" }
        field:setDB(obj, db)

        t:assertEqual(obj.db, db)
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

    ["getDefaultDB builds nested structure"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Category",
            key = "settings",
            fields = {
                { key = "volume", type = "Number", default = 75 },
                { key = "enabled", type = "Bool", default = true },
            },
        })
        local field = info:getField("settings")
        local db = field:getDefaultDB({})
        t:assertEqual(db.volume, 75)
        t:assertEqual(db.enabled, true)
    end,

    ["setDB restores nested values"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Category",
            key = "settings",
            fields = {
                { key = "volume", type = "Number" },
                { key = "muted", type = "Bool" },
            },
        })
        local field = info:getField("settings")

        local obj = {}
        local db = { settings = { volume = 50, muted = true } }
        field:setDB(obj, db)

        t:assertNotNil(obj.settings)
        t:assertEqual(obj.settings.volume, 50)
        t:assertEqual(obj.settings.muted, true)
    end,

    ["setDB creates nested object if missing"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Category",
            key = "config",
            fields = {
                { key = "name", default = "test" },
            },
        })
        local field = info:getField("config")

        local obj = {} -- No obj.config initially
        local db = { config = { name = "restored" } }
        field:setDB(obj, db)

        t:assertNotNil(obj.config)
        t:assertEqual(obj.config.name, "restored")
    end,
})

testRunner:addSuite("Field.Reference", {
    ["requires field property"] = function(t)
        local info = WowVision.info.InfoManager:new()
        t:assertError(function()
            info:addField({
                type = "Reference",
                key = "ref",
                -- Missing field property
            })
        end)
    end,

    ["get delegates to referenced field"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "source", default = "hello" })
        local sourceField = info:getField("source")

        info:addField({
            type = "Reference",
            key = "ref",
            field = sourceField,
        })
        local refField = info:getField("ref")

        local obj = { source = "world" }
        t:assertEqual(refField:get(obj), "world")
    end,

    ["set does nothing (read-only)"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "source", default = "original" })
        local sourceField = info:getField("source")

        info:addField({
            type = "Reference",
            key = "ref",
            field = sourceField,
        })
        local refField = info:getField("ref")

        local obj = { source = "original" }
        refField:set(obj, "modified")
        t:assertEqual(obj.source, "original")
    end,

    ["getDefaultDB returns nil"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "source", default = "value" })
        local sourceField = info:getField("source")

        info:addField({
            type = "Reference",
            key = "ref",
            field = sourceField,
        })
        local refField = info:getField("ref")

        t:assertNil(refField:getDefaultDB({}))
    end,

    ["setDB does nothing"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "source", default = "original" })
        local sourceField = info:getField("source")

        info:addField({
            type = "Reference",
            key = "ref",
            field = sourceField,
        })
        local refField = info:getField("ref")

        local obj = { source = "original" }
        local db = { ref = "should_be_ignored" }
        refField:setDB(obj, db)
        -- Source should remain unchanged
        t:assertEqual(obj.source, "original")
        -- ref key should not be set on obj
        t:assertNil(obj.ref)
    end,

    ["getDefault delegates to referenced field"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "source", default = "defaultValue" })
        local sourceField = info:getField("source")

        info:addField({
            type = "Reference",
            key = "ref",
            field = sourceField,
        })
        local refField = info:getField("ref")

        t:assertEqual(refField:getDefault({}), "defaultValue")
    end,

    ["getLabel uses own label if set"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "source", label = "Source Label" })
        local sourceField = info:getField("source")

        info:addField({
            type = "Reference",
            key = "ref",
            field = sourceField,
            label = "Reference Label",
        })
        local refField = info:getField("ref")

        t:assertEqual(refField:getLabel(), "Reference Label")
    end,

    ["getLabel falls back to referenced field label"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "source", label = "Source Label" })
        local sourceField = info:getField("source")

        info:addField({
            type = "Reference",
            key = "ref",
            field = sourceField,
        })
        local refField = info:getField("ref")

        t:assertEqual(refField:getLabel(), "Source Label")
    end,

    ["getValueString delegates to referenced field"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Choice",
            key = "source",
            choices = {
                { key = "a", label = "Option A", value = 1 },
                { key = "b", label = "Option B", value = 2 },
            },
        })
        local sourceField = info:getField("source")

        info:addField({
            type = "Reference",
            key = "ref",
            field = sourceField,
        })
        local refField = info:getField("ref")

        t:assertEqual(refField:getValueString({}, 2), "Option B")
    end,
})
