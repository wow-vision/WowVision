local testRunner = WowVision.testing.testRunner

-- Helper to create standalone test modules (not attached to WowVision.base)
local function createTestModule(key)
    local module = WowVision.Module:new(key or "testModule")
    module:setLabel(key or "testModule")
    return module
end

testRunner:addSuite("Module", {
    ["createModule creates submodule with key"] = function(t)
        local parent = createTestModule("parent")
        local sub = parent:createModule("sub1")
        t:assertNotNil(sub)
        t:assertEqual(sub.key, "sub1")
    end,

    ["createModule sets parent reference"] = function(t)
        local parent = createTestModule("parent")
        local sub = parent:createModule("sub2")
        t:assertEqual(sub.parent, parent)
    end,

    ["createModule adds to submodules array"] = function(t)
        local parent = createTestModule("parent")
        t:assertEqual(#parent.submodules, 0)
        parent:createModule("sub3")
        t:assertEqual(#parent.submodules, 1)
    end,

    ["createModule assigns submodule to parent key"] = function(t)
        local parent = createTestModule("parent")
        local sub = parent:createModule("sub4")
        t:assertEqual(parent.sub4, sub)
    end,

    ["createModule does not overwrite existing key"] = function(t)
        local parent = createTestModule("parent")
        parent.existingKey = "original"
        parent:createModule("existingKey")
        t:assertEqual(parent.existingKey, "original")
    end,

    ["setParent sets parent reference"] = function(t)
        local parent1 = createTestModule("parent1")
        local parent2 = createTestModule("parent2")
        local sub = parent1:createModule("sub")
        sub:setParent(parent2)
        t:assertEqual(sub.parent, parent2)
    end,

    ["getLabel returns label"] = function(t)
        local module = createTestModule("test")
        module:setLabel("Test Label")
        t:assertEqual(module:getLabel(), "Test Label")
    end,

    ["setLabel sets label"] = function(t)
        local module = createTestModule("test")
        module:setLabel("New Label")
        t:assertEqual(module.label, "New Label")
    end,

    ["isVital returns vital flag"] = function(t)
        local module = createTestModule("test")
        t:assertFalse(module:isVital())
        module:setVital(true)
        t:assertTrue(module:isVital())
    end,

    ["setVital sets vital flag"] = function(t)
        local module = createTestModule("test")
        module:setVital(true)
        t:assertTrue(module.vital)
        module:setVital(false)
        t:assertFalse(module.vital)
    end,

    ["getEnabled returns enabled state"] = function(t)
        local module = createTestModule("test")
        t:assertTrue(module:getEnabled())
    end,

    ["hasUI creates elementGenerator on first call"] = function(t)
        local module = createTestModule("test")
        t:assertNil(module.elementGenerator)
        local gen = module:hasUI()
        t:assertNotNil(gen)
        t:assertNotNil(module.elementGenerator)
    end,

    ["hasUI returns same generator on subsequent calls"] = function(t)
        local module = createTestModule("test")
        local gen1 = module:hasUI()
        local gen2 = module:hasUI()
        t:assertEqual(gen1, gen2)
    end,

    ["hasUI creates registeredWindows table"] = function(t)
        local module = createTestModule("test")
        module:hasUI()
        t:assertNotNil(module.registeredWindows)
    end,

    ["hasUI creates registeredDropdownMenus table"] = function(t)
        local module = createTestModule("test")
        module:hasUI()
        t:assertNotNil(module.registeredDropdownMenus)
    end,

    ["hasSettings creates settingsRoot on first call"] = function(t)
        local module = createTestModule("test")
        t:assertNil(module.settingsRoot)
        local root = module:hasSettings()
        t:assertNotNil(root)
        t:assertNotNil(module.settingsRoot)
    end,

    ["hasSettings returns same root on subsequent calls"] = function(t)
        local module = createTestModule("test")
        local root1 = module:hasSettings()
        local root2 = module:hasSettings()
        t:assertEqual(root1, root2)
    end,

    ["getDefaultSettings returns empty table without settingsRoot"] = function(t)
        local module = createTestModule("test")
        local defaults = module:getDefaultSettings()
        t:assertNotNil(defaults)
        local count = 0
        for _ in pairs(defaults) do
            count = count + 1
        end
        t:assertEqual(count, 0)
    end,

    ["getDefaultSettings returns settingsRoot defaults"] = function(t)
        local module = createTestModule("test")
        local root = module:hasSettings()
        root:add({ type = "Bool", key = "enabled", default = true })
        local defaults = module:getDefaultSettings()
        t:assertEqual(defaults.enabled, true)
    end,

    ["getDefaultBindings returns bindings default DB"] = function(t)
        local module = createTestModule("test")
        local defaults = module:getDefaultBindings()
        t:assertNotNil(defaults)
    end,

    ["getDefaultData returns empty table"] = function(t)
        local module = createTestModule("test")
        local data = module:getDefaultData()
        t:assertNotNil(data)
        local count = 0
        for _ in pairs(data) do
            count = count + 1
        end
        t:assertEqual(count, 0)
    end,

    ["registerEvent validates event type"] = function(t)
        local module = createTestModule("test")
        t:assertError(function()
            module:registerEvent("invalid", "SOME_EVENT")
        end)
    end,

    ["registerEvent accepts 'event' type"] = function(t)
        local module = createTestModule("test")
        t:assertEqual(#module.registeredEvents, 0)
        module:registerEvent("event", "PLAYER_LOGIN")
        t:assertEqual(#module.registeredEvents, 1)
    end,

    ["registerEvent accepts 'unit' type"] = function(t)
        local module = createTestModule("test")
        t:assertEqual(#module.registeredEvents, 0)
        module:registerEvent("unit", "UNIT_HEALTH", "player")
        t:assertEqual(#module.registeredEvents, 1)
    end,

    ["registerEvent stores event info correctly"] = function(t)
        local module = createTestModule("test")
        module:registerEvent("unit", "UNIT_AURA", "player", "target")
        local lastEvent = module.registeredEvents[#module.registeredEvents]
        t:assertEqual(lastEvent.type, "unit")
        t:assertEqual(lastEvent.event, "UNIT_AURA")
        t:assertEqual(lastEvent.args[1], "player")
        t:assertEqual(lastEvent.args[2], "target")
    end,

    ["registerDropdownMenu adds menu to registry"] = function(t)
        local module = createTestModule("test")
        module:hasUI() -- Initialize registeredDropdownMenus
        module:registerDropdownMenu("TestMenu", { label = "Test" })
        t:assertNotNil(module.registeredDropdownMenus["TestMenu"])
    end,

    ["unregisterDropdownMenu removes menu from registry"] = function(t)
        local module = createTestModule("test")
        module:hasUI()
        module:registerDropdownMenu("TestMenu2", { label = "Test" })
        module:unregisterDropdownMenu("TestMenu2")
        t:assertNil(module.registeredDropdownMenus["TestMenu2"])
    end,

    ["hasUpdate sets _updateFunc"] = function(t)
        local module = createTestModule("test")
        local func = function() end
        module:hasUpdate(func)
        t:assertEqual(module._updateFunc, func)
    end,

    ["getDefaultDBRecursive includes enabled state"] = function(t)
        local module = createTestModule("test")
        local db = module:getDefaultDBRecursive()
        t:assertNotNil(db.enabled)
        t:assertTrue(db.enabled)
    end,

    ["getDefaultDBRecursive includes submodules"] = function(t)
        local module = createTestModule("test")
        local child = module:createModule("child")
        child:setLabel("child")
        local db = module:getDefaultDBRecursive()
        t:assertNotNil(db.submodules)
        t:assertNotNil(db.submodules.child)
    end,

    ["getDefaultDBRecursive includes alerts"] = function(t)
        local module = createTestModule("test")
        local db = module:getDefaultDBRecursive()
        t:assertNotNil(db.alerts)
    end,

    ["getDefaultDBRecursive includes bindings"] = function(t)
        local module = createTestModule("test")
        local db = module:getDefaultDBRecursive()
        t:assertNotNil(db.bindings)
    end,

    ["getDefaultDBRecursive includes settings"] = function(t)
        local module = createTestModule("test")
        local db = module:getDefaultDBRecursive()
        t:assertNotNil(db.settings)
    end,

    ["getDefaultDBRecursive includes data"] = function(t)
        local module = createTestModule("test")
        local db = module:getDefaultDBRecursive()
        t:assertNotNil(db.data)
    end,

    ["module starts with empty submodules"] = function(t)
        local module = createTestModule("test")
        t:assertEqual(#module.submodules, 0)
    end,

    ["module starts with empty registeredEvents"] = function(t)
        local module = createTestModule("test")
        t:assertEqual(#module.registeredEvents, 0)
    end,

    ["module starts with empty alerts"] = function(t)
        local module = createTestModule("test")
        local count = 0
        for _ in pairs(module.alerts) do
            count = count + 1
        end
        t:assertEqual(count, 0)
    end,

    ["createComponentRegistry creates registry"] = function(t)
        local module = createTestModule("test")
        local TestBase = WowVision.Class("TestBase"):include(WowVision.InfoClass)
        TestBase.info:addFields({ { key = "key", required = true } })
        function TestBase:initialize(config)
            self:setInfo(config)
        end

        local registry = module:createComponentRegistry({
            key = "widgets",
            type = "class",
            baseClass = TestBase,
        })
        t:assertNotNil(registry)
        t:assertTrue(registry:isInstanceOf(WowVision.components.ComponentRegistry))
    end,

    ["createComponentRegistry assigns to module key"] = function(t)
        local module = createTestModule("test")
        local TestBase = WowVision.Class("TestBase2"):include(WowVision.InfoClass)
        TestBase.info:addFields({ { key = "key", required = true } })
        function TestBase:initialize(config)
            self:setInfo(config)
        end

        local registry = module:createComponentRegistry({
            key = "elements",
            type = "class",
            baseClass = TestBase,
        })
        t:assertEqual(module.elements, registry)
    end,
})
