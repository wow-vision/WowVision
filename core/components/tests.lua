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

    ["getComponents returns all components"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        local w1 = registry:createComponent({ key = "widget1", type = "Widget" })
        local w2 = registry:createComponent({ key = "widget2", type = "Widget" })

        local components = registry:getComponents()
        t:assertEqual(#components, 2)
        t:assertEqual(components[1], w1)
        t:assertEqual(components[2], w2)
    end,

    ["getComponentsOfType filters by type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        registry:createType({ key = "Button" })
        local w1 = registry:createComponent({ key = "widget1", type = "Widget" })
        local b1 = registry:createComponent({ key = "button1", type = "Button" })
        local w2 = registry:createComponent({ key = "widget2", type = "Widget" })

        local widgets = registry:getComponentsOfType("Widget")
        t:assertEqual(#widgets, 2)
        t:assertEqual(widgets[1], w1)
        t:assertEqual(widgets[2], w2)
    end,

    ["getComponentsOfType includes subclasses"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        registry:createType({ key = "Button", parent = "Widget" })
        local w1 = registry:createComponent({ key = "widget1", type = "Widget" })
        local b1 = registry:createComponent({ key = "button1", type = "Button" })

        local widgets = registry:getComponentsOfType("Widget")
        t:assertEqual(#widgets, 2)
    end,

    ["getComponentsOfType errors on unknown type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        t:assertError(function()
            registry:getComponentsOfType("Unknown")
        end)
    end,

    ["forEachComponent iterates all components"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        registry:createComponent({ key = "widget1", type = "Widget" })
        registry:createComponent({ key = "widget2", type = "Widget" })
        registry:createComponent({ key = "widget3", type = "Widget" })

        local count = 0
        local keys = {}
        registry:forEachComponent(function(component, key)
            count = count + 1
            tinsert(keys, key)
        end)
        t:assertEqual(count, 3)
        t:assertEqual(keys[1], "widget1")
        t:assertEqual(keys[2], "widget2")
        t:assertEqual(keys[3], "widget3")
    end,

    ["forEachComponentOfType filters by type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        registry:createType({ key = "Button" })
        registry:createComponent({ key = "widget1", type = "Widget" })
        registry:createComponent({ key = "button1", type = "Button" })
        registry:createComponent({ key = "widget2", type = "Widget" })

        local count = 0
        registry:forEachComponentOfType("Widget", function(component, key)
            count = count + 1
        end)
        t:assertEqual(count, 2)
    end,

    ["forEachComponentOfType includes subclasses"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        registry:createType({ key = "Widget" })
        registry:createType({ key = "Button", parent = "Widget" })
        registry:createComponent({ key = "widget1", type = "Widget" })
        registry:createComponent({ key = "button1", type = "Button" })

        local count = 0
        registry:forEachComponentOfType("Widget", function(component, key)
            count = count + 1
        end)
        t:assertEqual(count, 2) -- Both Widget and Button (which extends Widget)
    end,

    ["forEachComponentOfType errors on unknown type"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.ComponentRegistry:new({
            type = "class",
            baseClass = TestBase,
        })
        t:assertError(function()
            registry:forEachComponentOfType("Unknown", function() end)
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

-- WowVision.components namespace tests
testRunner:addSuite("components namespace", {
    ["createRegistry returns ComponentRegistry instance"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.createRegistry({
            type = "class",
            baseClass = TestBase,
        })
        t:assertNotNil(registry)
        t:assertTrue(registry:isInstanceOf(WowVision.components.ComponentRegistry))
    end,

    ["createRegistry registers by path when provided"] = function(t)
        local TestBase = createTestBaseClass()
        local registry = WowVision.components.createRegistry({
            type = "class",
            baseClass = TestBase,
            path = "test.widgets",
        })
        local retrieved = WowVision.components.registries:get("test.widgets")
        t:assertEqual(registry, retrieved)
        -- Cleanup
        WowVision.components.registries.items["test.widgets"] = nil
    end,

    ["createRegistry without path does not register"] = function(t)
        local TestBase = createTestBaseClass()
        local initialCount = #WowVision.components.registries.items
        WowVision.components.createRegistry({
            type = "class",
            baseClass = TestBase,
        })
        -- Registry count should increase but no path-based lookup
        t:assertEqual(#WowVision.components.registries.items, initialCount)
    end,

    ["createType creates type via path"] = function(t)
        local TestBase = createTestBaseClass()
        WowVision.components.createRegistry({
            type = "class",
            baseClass = TestBase,
            path = "test.elements",
        })
        local typeClass = WowVision.components.createType("test.elements", { key = "Button" })
        t:assertNotNil(typeClass)
        t:assertTrue(typeClass:isSubclassOf(TestBase))
        -- Cleanup
        WowVision.components.registries.items["test.elements"] = nil
    end,

    ["createType errors on unknown path"] = function(t)
        t:assertError(function()
            WowVision.components.createType("nonexistent.path", { key = "Widget" })
        end)
    end,

    ["createComponent creates component via path"] = function(t)
        local TestBase = createTestBaseClass()
        WowVision.components.createRegistry({
            type = "class",
            baseClass = TestBase,
            path = "test.items",
        })
        WowVision.components.createType("test.items", { key = "Item" })
        local component = WowVision.components.createComponent("test.items", {
            key = "sword",
            type = "Item",
            label = "Sword",
        })
        t:assertNotNil(component)
        t:assertEqual(component.key, "sword")
        t:assertEqual(component.label, "Sword")
        -- Cleanup
        WowVision.components.registries.items["test.items"] = nil
    end,

    ["createComponent errors on unknown path"] = function(t)
        t:assertError(function()
            WowVision.components.createComponent("nonexistent.path", { key = "test", type = "Widget" })
        end)
    end,

    ["full workflow via namespace methods"] = function(t)
        local TestBase = createTestBaseClass()

        -- Create registry with path
        local registry = WowVision.components.createRegistry({
            type = "class",
            baseClass = TestBase,
            path = "test.full",
        })

        -- Create types via path
        WowVision.components.createType("test.full", { key = "Widget" })
        WowVision.components.createType("test.full", { key = "Button", parent = "Widget" })

        -- Create components via path
        local widget = WowVision.components.createComponent("test.full", {
            key = "myWidget",
            type = "Widget",
        })
        local button = WowVision.components.createComponent("test.full", {
            key = "myButton",
            type = "Button",
        })

        -- Verify via registry methods
        t:assertEqual(registry:getComponent("myWidget"), widget)
        t:assertEqual(registry:getComponent("myButton"), button)

        local allComponents = registry:getComponents()
        t:assertEqual(#allComponents, 2)

        local widgets = registry:getComponentsOfType("Widget")
        t:assertEqual(#widgets, 2) -- Both Widget and Button (extends Widget)

        local buttons = registry:getComponentsOfType("Button")
        t:assertEqual(#buttons, 1)

        -- Cleanup
        WowVision.components.registries.items["test.full"] = nil
    end,
})
