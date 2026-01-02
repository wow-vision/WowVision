local testRunner = WowVision.testing.testRunner

testRunner:addSuite("Parameter", {
    ["getDefaultDB returns default value"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "Bool", key = "enabled", default = true })
        t:assertEqual(param:getDefaultDB(), true)
    end,

    ["getDefaultDB calls function default"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({
            type = "Bool",
            key = "enabled",
            default = function() return false end,
        })
        t:assertEqual(param:getDefaultDB(), false)
    end,

    ["getValue reads from db"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "Bool", key = "enabled", default = false })
        local db = { enabled = true }
        param:setDB(db)
        t:assertEqual(param:getValue(), true)
    end,

    ["setValue writes to db"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "Bool", key = "enabled", default = false })
        local db = { enabled = false }
        param:setDB(db)
        param:setValue(true)
        t:assertEqual(db.enabled, true)
    end,

    ["setValue emits valueChange event"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "Bool", key = "enabled", default = false })
        local db = { enabled = false }
        param:setDB(db)

        local eventFired = false
        param.events.valueChange:subscribe(param, function()
            eventFired = true
        end)
        param:setValue(true)
        t:assertTrue(eventFired)
    end,

    ["getLabel returns label"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "Bool", key = "enabled", label = "Enable Feature" })
        t:assertEqual(param:getLabel(), "Enable Feature")
    end,
})

testRunner:addSuite("Parameter.Category", {
    ["add creates child parameter"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local child = category:add({ type = "Bool", key = "enabled", default = true })
        t:assertNotNil(child)
        t:assertEqual(category:get("enabled"), child)
    end,

    ["add errors on duplicate key"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        category:add({ type = "Bool", key = "enabled", default = true })
        t:assertError(function()
            category:add({ type = "Bool", key = "enabled", default = false })
        end)
    end,

    ["add errors on unknown type"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        t:assertError(function()
            category:add({ type = "UnknownType", key = "test" })
        end)
    end,

    ["getDefaultDB builds nested structure"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        category:add({ type = "Bool", key = "enabled", default = true })
        category:add({ type = "Number", key = "count", default = 5 })
        local defaults = category:getDefaultDB()
        t:assertEqual(defaults.enabled, true)
        t:assertEqual(defaults.count, 5)
    end,

    ["nested categories build nested defaults"] = function(t)
        local root = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local sub = root:add({ type = "Category", key = "sub", label = "Sub" })
        sub:add({ type = "Bool", key = "flag", default = true })

        local defaults = root:getDefaultDB()
        t:assertNotNil(defaults.sub)
        t:assertEqual(defaults.sub.flag, true)
    end,

    ["setDB propagates to children"] = function(t)
        local root = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        root:add({ type = "Bool", key = "enabled", default = false })
        root:add({ type = "Number", key = "count", default = 0 })

        local db = { enabled = true, count = 10 }
        root:setDB(db)

        t:assertEqual(root:get("enabled"):getValue(), true)
        t:assertEqual(root:get("count"):getValue(), 10)
    end,
})

testRunner:addSuite("Parameter.Bool", {
    ["toggle flips value"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "Bool", key = "enabled", default = false })
        local db = { enabled = false }
        param:setDB(db)

        param:toggle()
        t:assertEqual(param:getValue(), true)
        param:toggle()
        t:assertEqual(param:getValue(), false)
    end,

    ["getGenerator returns Checkbox"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "Bool", key = "enabled", label = "Enabled" })
        local gen = param:getGenerator()
        t:assertEqual(gen[1], "Checkbox")
        t:assertEqual(gen.label, "Enabled")
    end,
})

testRunner:addSuite("Parameter.String", {
    ["getGenerator returns EditBox"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "String", key = "name", label = "Name" })
        param:setDB({ name = "test" })
        local gen = param:getGenerator()
        t:assertEqual(gen[1], "EditBox")
        t:assertEqual(gen.label, "Name")
    end,
})

testRunner:addSuite("Parameter.Number", {
    ["getGenerator returns EditBox with decimal type"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({ type = "Number", key = "count", label = "Count" })
        param:setDB({ count = 5 })
        local gen = param:getGenerator()
        t:assertEqual(gen[1], "EditBox")
        t:assertEqual(gen.type, "decimal")
    end,
})

testRunner:addSuite("Parameter.Choice", {
    ["addChoice adds to choices array"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({
            type = "Choice",
            key = "size",
            label = "Size",
            choices = {},
        })
        param:addChoice({ label = "Small", value = 1 })
        param:addChoice({ label = "Large", value = 2 })
        t:assertEqual(#param.choices, 2)
    end,

    ["buildDropdown creates list with choices"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({
            type = "Choice",
            key = "size",
            label = "Size",
            choices = {
                { label = "Small", value = 1 },
                { label = "Large", value = 2 },
            },
        })
        local dropdown = param:buildDropdown()
        t:assertEqual(dropdown[1], "List")
        t:assertEqual(#dropdown.children, 2)
        t:assertEqual(dropdown.children[1].label, "Small")
    end,

    ["getGenerator returns Button"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local param = category:add({
            type = "Choice",
            key = "size",
            label = "Size",
            choices = {},
        })
        local gen = param:getGenerator()
        t:assertEqual(gen[1], "Button")
    end,
})

testRunner:addSuite("Parameter.Ref", {
    ["ref flag is set"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local target = category:add({ type = "Bool", key = "target", label = "Target" })
        local ref = category:addRef("ref", target)
        t:assertTrue(ref.ref)
    end,

    ["getDefaultDB returns nil"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local target = category:add({ type = "Bool", key = "target", label = "Target", default = true })
        local ref = category:addRef("ref", target)
        t:assertNil(ref:getDefaultDB())
    end,

    ["getGenerator returns target generator for non-category"] = function(t)
        local category = WowVision.parameters.Category:new({ key = "root", label = "Root" })
        local target = category:add({ type = "Bool", key = "target", label = "Target" })
        local ref = category:addRef("ref", target)
        local gen = ref:getGenerator()
        t:assertEqual(gen[1], "Checkbox")
    end,
})
