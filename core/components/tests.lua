local testRunner = WowVision.testing.testRunner

-- Helper: create a simple base class for testing
local function createTestBaseClass()
    local TestBase = WowVision.Class("TestBase"):include(WowVision.InfoClass)
    TestBase.info:addFields({
        { key = "key", required = true },
        { key = "label", default = "" },
    })
    function TestBase:initialize(config)
        self:setInfo(config)
    end
    return TestBase
end

-- ComponentRegistry tests
testRunner:addSuite("ComponentRegistry", {
    ["creates with valid type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        t:assertNotNil(registry)
        t:assertNotNil(registry.types)
        t:assertNotNil(registry.components)
    end,

    ["errors on unknown type"] = function(t)
        t:assertError(function()
            WowVision.components.ComponentRegistry:new({
                type = "nonexistent",
            })
        end)
    end,

    ["createType registers type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        t:assertNotNil(registry.types:get("Widget"))
    end,

    ["createComponent registers component"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        registry:createComponent({ key = "myWidget", type = "Widget" })
        t:assertNotNil(registry.components:get("myWidget"))
    end,

    ["getComponent retrieves component"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        local created = registry:createComponent({ key = "myWidget", type = "Widget", label = "Test" })
        local retrieved = registry:getComponent("myWidget")
        t:assertEqual(created, retrieved)
    end,

    ["createComponent errors on unknown type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        t:assertError(function()
            registry:createComponent({ key = "test", type = "Unknown" })
        end)
    end,
})

-- ClassRegistryType tests
testRunner:addSuite("ClassRegistryType", {
    ["createType creates class inheriting from baseClass"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        local WidgetClass = registry:createType({ key = "Widget" })
        t:assertTrue(WidgetClass:isSubclassOf(TestBase))
    end,

    ["createType with parent inherits from parent type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        local WidgetClass = registry:createType({ key = "Widget" })
        local ButtonClass = registry:createType({ key = "Button", parent = "Widget" })
        t:assertTrue(ButtonClass:isSubclassOf(WidgetClass))
        t:assertTrue(ButtonClass:isSubclassOf(TestBase))
    end,

    ["createType errors on unknown parent"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        t:assertError(function()
            registry:createType({ key = "Widget", parent = "Unknown" })
        end)
    end,

    ["createType applies classNamePrefix"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
            classNamePrefix = "UI",
        })
        local WidgetClass = registry:createType({ key = "Widget" })
        t:assertEqual(WidgetClass.name, "UIWidget")
    end,

    ["createType applies classNameSuffix"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
            classNameSuffix = "Element",
        })
        local WidgetClass = registry:createType({ key = "Widget" })
        t:assertEqual(WidgetClass.name, "WidgetElement")
    end,

    ["createType applies both prefix and suffix"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
            classNamePrefix = "UI",
            classNameSuffix = "Element",
        })
        local WidgetClass = registry:createType({ key = "Widget" })
        t:assertEqual(WidgetClass.name, "UIWidgetElement")
    end,

    ["createType applies mixins"] = function(t)
        local TestBase = createTestBaseClass()
        local testMixin = {
            testMethod = function(self)
                return "mixin works"
            end,
        }
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
            mixins = { testMixin },
        })
        local WidgetClass = registry:createType({ key = "Widget" })
        t:assertNotNil(WidgetClass.testMethod)
    end,

    ["createComponent creates instance of type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        local WidgetClass = registry:createType({ key = "Widget" })
        local instance = registry:createComponent({ key = "myWidget", type = "Widget", label = "Test Label" })
        t:assertTrue(instance:isInstanceOf(WidgetClass))
        t:assertEqual(instance.label, "Test Label")
    end,

    ["createComponent passes config to instance"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        local instance = registry:createComponent({ key = "myWidget", type = "Widget", label = "My Label" })
        t:assertEqual(instance.key, "myWidget")
        t:assertEqual(instance.label, "My Label")
    end,
})
