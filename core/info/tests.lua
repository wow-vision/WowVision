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
            default = function(obj)
                return obj.base .. "_suffix"
            end,
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
                { label = "Small", value = 1 },
                { label = "Medium", value = 2 },
                { label = "Large", value = 3 },
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
                { label = "Small", value = 1 },
                { label = "Medium", value = 2 },
            },
        })
        local field = info:getField("size")
        t:assertEqual(field:getDefault({}), 2)
    end,

    ["getChoiceByValue finds correct choice"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Choice",
            key = "size",
            choices = {
                { label = "Small", value = 1 },
                { label = "Medium", value = 2 },
            },
        })
        local field = info:getField("size")
        local choice = field:getChoiceByValue({}, 2)
        t:assertNotNil(choice)
        t:assertEqual(choice.label, "Medium")
    end,

    ["getValueString returns label for value"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Choice",
            key = "size",
            choices = {
                { label = "Small", value = 1 },
                { label = "Medium", value = 2 },
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
                { label = "Option A", value = 1 },
                { label = "Option B", value = 2 },
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

testRunner:addSuite("Field.Array", {
    ["requires elementField property"] = function(t)
        local info = WowVision.info.InfoManager:new()
        t:assertError(function()
            info:addField({
                type = "Array",
                key = "items",
                -- Missing elementField
            })
        end)
    end,

    ["accepts inline field definition"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "numbers",
            elementField = { type = "Number", minimum = 0 },
        })
        local field = info:getField("numbers")
        t:assertNotNil(field)
        t:assertNotNil(field:getElementField())
    end,

    ["accepts Field object as elementField"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ type = "Number", key = "template", minimum = 0 })
        local templateField = info:getField("template")

        info:addField({
            type = "Array",
            key = "numbers",
            elementField = templateField,
        })
        local field = info:getField("numbers")
        t:assertEqual(field:getElementField(), templateField)
    end,

    ["get returns entire array when no index"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 1, 2, 3 } }
        local arr = field:get(obj)
        t:assertEqual(#arr, 3)
        t:assertEqual(arr[2], 2)
    end,

    ["get returns element at index"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 10, 20, 30 } }
        t:assertEqual(field:get(obj, 1), 10)
        t:assertEqual(field:get(obj, 2), 20)
        t:assertEqual(field:get(obj, 3), 30)
    end,

    ["set replaces entire array when no index"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 1, 2, 3 } }
        field:set(obj, { 4, 5 })
        t:assertEqual(#obj.items, 2)
        t:assertEqual(obj.items[1], 4)
        t:assertEqual(obj.items[2], 5)
    end,

    ["set updates element at index"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 1, 2, 3 } }
        field:set(obj, 99, 2)
        t:assertEqual(obj.items[1], 1)
        t:assertEqual(obj.items[2], 99)
        t:assertEqual(obj.items[3], 3)
    end,

    ["set validates elements using elementField"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number", minimum = 0, maximum = 100 },
        })
        local field = info:getField("items")

        local obj = {}
        field:set(obj, { -5, 50, 150 })
        t:assertEqual(obj.items[1], 0) -- clamped to min
        t:assertEqual(obj.items[2], 50) -- unchanged
        t:assertEqual(obj.items[3], 100) -- clamped to max
    end,

    ["getDefault returns empty array"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")
        local default = field:getDefault({})
        t:assertNotNil(default)
        t:assertEqual(#default, 0)
    end,

    ["addElement appends to array"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 1, 2 } }
        local index = field:addElement(obj, 3)
        t:assertEqual(index, 3)
        t:assertEqual(obj.items[3], 3)
    end,

    ["addElement creates array if missing"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = {}
        field:addElement(obj, 42)
        t:assertNotNil(obj.items)
        t:assertEqual(obj.items[1], 42)
    end,

    ["removeElement removes at index"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 1, 2, 3 } }
        local removed = field:removeElement(obj, 2)
        t:assertEqual(removed, 2)
        t:assertEqual(#obj.items, 2)
        t:assertEqual(obj.items[2], 3)
    end,

    ["getLength returns array length"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 1, 2, 3, 4, 5 } }
        t:assertEqual(field:getLength(obj), 5)
    end,

    ["getLength returns 0 for missing array"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = {}
        t:assertEqual(field:getLength(obj), 0)
    end,

    ["getDefaultDB returns empty array"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")
        local db = field:getDefaultDB({})
        t:assertNotNil(db)
        t:assertEqual(#db, 0)
    end,

    ["setDB restores array with validation"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number", minimum = 0 },
        })
        local field = info:getField("items")

        local obj = {}
        local db = { items = { -10, 20, 30 } }
        field:setDB(obj, db)

        t:assertNotNil(obj.items)
        t:assertEqual(obj.items[1], 0) -- clamped
        t:assertEqual(obj.items[2], 20)
        t:assertEqual(obj.items[3], 30)
    end,

    ["setDB creates empty array when missing from db"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = {}
        local db = {}
        field:setDB(obj, db)

        t:assertNotNil(obj.items)
        t:assertEqual(#obj.items, 0)
    end,

    ["getValueString returns item count"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        t:assertEqual(field:getValueString({}, { 1, 2, 3 }), "3 items")
        t:assertEqual(field:getValueString({}, {}), "0 items")
        t:assertEqual(field:getValueString({}, nil), "0 items")
    end,

    ["getGenerator returns Button"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            label = "Items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 1, 2, 3 } }
        local gen = field:getGenerator(obj)
        t:assertEqual(gen[1], "Button")
        t:assertEqual(gen.label, "Items (3 items)")
    end,

    ["getGenerator shows 0 items for empty array"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            label = "Items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = {} }
        local gen = field:getGenerator(obj)
        t:assertEqual(gen.label, "Items (0 items)")
    end,

    ["buildArrayList creates list with elements and add button"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            label = "Items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 10, 20 } }
        local list = field:buildArrayList(obj)
        t:assertEqual(list[1], "List")
        t:assertEqual(list.label, "Items")
        -- 2 elements + 1 add button = 3 children
        t:assertEqual(#list.children, 3)
        -- Last child should be Add button
        t:assertEqual(list.children[3][1], "Button")
        t:assertEqual(list.children[3].label, "Add")
    end,

    ["createElementProxy reads from array"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 10, 20, 30 } }
        local proxy = field:createElementProxy(obj, 2)
        -- elementField.key defaults to "_element"
        t:assertEqual(proxy._element, 20)
    end,

    ["createElementProxy writes to array"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local obj = { items = { 10, 20, 30 } }
        local proxy = field:createElementProxy(obj, 2)
        proxy._element = 99
        t:assertEqual(obj.items[2], 99)
        -- Other elements unchanged
        t:assertEqual(obj.items[1], 10)
        t:assertEqual(obj.items[3], 30)
    end,

    ["createElementProxy validates on write"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number", minimum = 0, maximum = 100 },
        })
        local field = info:getField("items")

        local obj = { items = { 50 } }
        local proxy = field:createElementProxy(obj, 1)
        proxy._element = 150
        t:assertEqual(obj.items[1], 100) -- clamped to max
    end,

    ["buildArrayItem contains element generator and remove button"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number", label = "Value" },
        })
        local field = info:getField("items")

        local obj = { items = { 42 } }
        local item = field:buildArrayItem(obj, 1)
        t:assertEqual(item[1], "List")
        t:assertEqual(#item.children, 2)
        -- First child is the element editor (EditBox for Number)
        t:assertEqual(item.children[1][1], "EditBox")
        -- Second child is Remove button
        t:assertEqual(item.children[2][1], "Button")
        t:assertEqual(item.children[2].label, "Remove")
    end,

    ["set persists to db when persist is true"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            persist = true,
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local db = { items = {} }
        local obj = { items = {}, db = db }
        field:set(obj, { 1, 2, 3 })
        t:assertEqual(#db.items, 3)
        t:assertEqual(db.items[1], 1)
        t:assertEqual(db.items[2], 2)
        t:assertEqual(db.items[3], 3)
    end,

    ["set element persists to db"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            persist = true,
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local db = { items = { 10, 20, 30 } }
        local obj = { items = { 10, 20, 30 }, db = db }
        field:set(obj, 99, 2)
        t:assertEqual(db.items[2], 99)
    end,

    ["addElement persists to db"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            persist = true,
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local db = { items = { 1, 2 } }
        local obj = { items = { 1, 2 }, db = db }
        field:addElement(obj, 3)
        t:assertEqual(#db.items, 3)
        t:assertEqual(db.items[3], 3)
    end,

    ["removeElement persists to db"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            persist = true,
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local db = { items = { 1, 2, 3 } }
        local obj = { items = { 1, 2, 3 }, db = db }
        field:removeElement(obj, 2)
        t:assertEqual(#db.items, 2)
        t:assertEqual(db.items[1], 1)
        t:assertEqual(db.items[2], 3)
    end,

    ["set emits valueChange event"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local eventFired = false
        local eventObj, eventKey, eventValue
        field.events.valueChange:subscribe(nil, function(eventName, obj, key, value)
            eventFired = true
            eventObj = obj
            eventKey = key
            eventValue = value
        end)

        local obj = { items = {} }
        field:set(obj, { 1, 2, 3 })
        t:assertTrue(eventFired)
        t:assertEqual(eventObj, obj)
        t:assertEqual(eventKey, "items")
        t:assertEqual(#eventValue, 3)
    end,

    ["addElement emits valueChange event"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local eventFired = false
        field.events.valueChange:subscribe(nil, function()
            eventFired = true
        end)

        local obj = { items = { 1 } }
        field:addElement(obj, 2)
        t:assertTrue(eventFired)
    end,

    ["removeElement emits valueChange event"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local eventFired = false
        field.events.valueChange:subscribe(nil, function()
            eventFired = true
        end)

        local obj = { items = { 1, 2 } }
        field:removeElement(obj, 1)
        t:assertTrue(eventFired)
    end,

    ["does not persist when persist is false"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Array",
            key = "items",
            persist = false,
            elementField = { type = "Number" },
        })
        local field = info:getField("items")

        local db = { items = { 99 } }
        local obj = { items = {}, db = db }
        field:set(obj, { 1, 2, 3 })
        -- db should remain unchanged
        t:assertEqual(#db.items, 1)
        t:assertEqual(db.items[1], 99)
    end,
})

testRunner:addSuite("Field.Object", {
    ["getDefault returns empty object config"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")
        local default = field:getDefault({})
        t:assertNotNil(default)
        t:assertNil(default.type)
        t:assertNotNil(default.params)
    end,

    ["validate normalizes nil to default structure"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")
        local result = field:validate(nil)
        t:assertNotNil(result)
        t:assertNil(result.type)
        t:assertNotNil(result.params)
    end,

    ["validate preserves type and params"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")
        local result = field:validate({ type = "Health", params = { unit = "player" } })
        t:assertEqual(result.type, "Health")
        t:assertEqual(result.params.unit, "player")
    end,

    ["set stores validated value"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")

        local obj = {}
        field:set(obj, { type = "Health", params = { unit = "target" } })
        t:assertEqual(obj.obj.type, "Health")
        t:assertEqual(obj.obj.params.unit, "target")
    end,

    ["setType changes type and resets params"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")

        local obj = { obj = { type = "Aura", params = { unit = "player", instanceID = 123 } } }
        field:setType(obj, "Health")
        t:assertEqual(obj.obj.type, "Health")
        -- Params should be reset (instanceID should be gone)
        t:assertNil(obj.obj.params.instanceID)
    end,

    ["setParam updates specific param"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")

        local obj = { obj = { type = "Health", params = { unit = "player" } } }
        field:setParam(obj, "unit", "target")
        t:assertEqual(obj.obj.params.unit, "target")
    end,

    ["getGenerator returns Button"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
            label = "My Object",
        })
        local field = info:getField("obj")

        local obj = { obj = { type = nil, params = {} } }
        local gen = field:getGenerator(obj)
        t:assertEqual(gen[1], "Button")
    end,

    ["set persists to db when persist is true"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
            persist = true,
        })
        local field = info:getField("obj")

        local db = {}
        local obj = { db = db }
        field:set(obj, { type = "Health", params = { unit = "player" } })
        t:assertNotNil(db.obj)
        t:assertEqual(db.obj.type, "Health")
        t:assertEqual(db.obj.params.unit, "player")
    end,

    ["set emits valueChange event"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")

        local eventFired = false
        field.events.valueChange:subscribe(nil, function()
            eventFired = true
        end)

        local obj = {}
        field:set(obj, { type = "Health", params = {} })
        t:assertTrue(eventFired)
    end,

    ["setType emits valueChange event"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")

        local eventFired = false
        field.events.valueChange:subscribe(nil, function()
            eventFired = true
        end)

        local obj = { obj = { type = nil, params = {} } }
        field:setType(obj, "Health")
        t:assertTrue(eventFired)
    end,

    ["setParam emits valueChange event"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "Object",
            key = "obj",
        })
        local field = info:getField("obj")

        local eventFired = false
        field.events.valueChange:subscribe(nil, function()
            eventFired = true
        end)

        local obj = { obj = { type = "Health", params = {} } }
        field:setParam(obj, "unit", "player")
        t:assertTrue(eventFired)
    end,
})

testRunner:addSuite("Field.TrackingConfig", {
    ["getDefault returns empty tracking config"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")
        local default = field:getDefault({})
        t:assertNotNil(default)
        t:assertNil(default.type)
    end,

    ["validate normalizes nil to default structure"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")
        local result = field:validate(nil)
        t:assertNotNil(result)
        t:assertNil(result.type)
    end,

    ["validate preserves type and other fields"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")
        local result = field:validate({ type = "Health", units = { "player" } })
        t:assertEqual(result.type, "Health")
        t:assertNotNil(result.units)
        t:assertEqual(result.units[1], "player")
    end,

    ["set stores validated value"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local obj = {}
        field:set(obj, { type = "Health", units = { "target" } })
        t:assertEqual(obj.source.type, "Health")
        t:assertEqual(obj.source.units[1], "target")
    end,

    ["setType changes type and initializes defaults"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local obj = { source = { type = "Power", units = { "focus" } } }
        field:setType(obj, "Health")
        t:assertEqual(obj.source.type, "Health")
        -- Should have new defaults from getTrackingGenerator
        t:assertNotNil(obj.source.units)
    end,

    ["setType to nil clears config"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local obj = { source = { type = "Health", units = { "player" } } }
        field:setType(obj, nil)
        t:assertNil(obj.source.type)
    end,

    ["getValueString returns None when no type"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local L = WowVision:getLocale()
        t:assertEqual(field:getValueString({}, { type = nil }), L["None"])
    end,

    ["getValueString returns type label with units"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local result = field:getValueString({}, { type = "Health", units = { "player", "target" } })
        t:assertTrue(result:find("Health"))
        t:assertTrue(result:find("player"))
        t:assertTrue(result:find("target"))
    end,

    ["getGenerator returns Button"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
            label = "Source",
        })
        local field = info:getField("source")

        local obj = { source = { type = nil } }
        local gen = field:getGenerator(obj)
        t:assertEqual(gen[1], "Button")
    end,

    ["set persists to db when persist is true"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
            persist = true,
        })
        local field = info:getField("source")

        local db = {}
        local obj = { db = db }
        field:set(obj, { type = "Health", units = { "player" } })
        t:assertNotNil(db.source)
        t:assertEqual(db.source.type, "Health")
        t:assertEqual(db.source.units[1], "player")
    end,

    ["set emits valueChange event"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local eventFired = false
        field.events.valueChange:subscribe(nil, function()
            eventFired = true
        end)

        local obj = {}
        field:set(obj, { type = "Health", units = { "player" } })
        t:assertTrue(eventFired)
    end,

    ["setType emits valueChange event"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local eventFired = false
        field.events.valueChange:subscribe(nil, function()
            eventFired = true
        end)

        local obj = { source = { type = nil } }
        field:setType(obj, "Health")
        t:assertTrue(eventFired)
    end,

    ["setDB restores config from database"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local obj = {}
        local db = { source = { type = "Power", units = { "focus" } } }
        field:setDB(obj, db)

        t:assertNotNil(obj.source)
        t:assertEqual(obj.source.type, "Power")
        t:assertEqual(obj.source.units[1], "focus")
    end,

    ["setDB sets default when missing from db"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({
            type = "TrackingConfig",
            key = "source",
        })
        local field = info:getField("source")

        local obj = {}
        local db = {}
        field:setDB(obj, db)

        t:assertNotNil(obj.source)
        t:assertNil(obj.source.type)
    end,
})
