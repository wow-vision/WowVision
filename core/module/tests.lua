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

    ["registerDropdownMenu adds menu to registry"] = function(t)
        local module = createTestModule("test")
        module:registerDropdownMenu("TestMenu", { label = "Test" })
        t:assertNotNil(module.registeredDropdownMenus["TestMenu"])
    end,

    ["unregisterDropdownMenu removes menu from registry"] = function(t)
        local module = createTestModule("test")
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

    ["getDefaultDBRecursive does not include bindings"] = function(t)
        local module = createTestModule("test")
        local db = module:getDefaultDBRecursive()
        t:assertNil(db.bindings)
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
