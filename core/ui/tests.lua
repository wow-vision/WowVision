local testRunner = WowVision.testing.testRunner

--
-- UIManager Tests
--

testRunner:addSuite("UIManager", {
    ["CreateElementType errors on missing parent"] = function(t)
        t:assertError(function()
            WowVision.ui:CreateElementType("TestElement_NoParent", "NonExistentParent")
        end)
    end,

    ["CreateElementType creates new type with parent"] = function(t)
        -- UIElement is registered as "Element"
        local newType, parentClass = WowVision.ui:CreateElementType("TestElement_1", "Element")
        t:assertNotNil(newType)
        t:assertNotNil(parentClass)
        t:assertEqual(newType.typeKey, "TestElement_1")
    end,

    ["CreateElementType returns parent class"] = function(t)
        local _, parentClass = WowVision.ui:CreateElementType("TestElement_2", "Element")
        -- UIElement doesn't have typeKey set (it's the base)
        t:assertNotNil(parentClass)
    end,

    ["CreateElementType registers in elementTypes"] = function(t)
        WowVision.ui:CreateElementType("TestElement_3", "Element")
        local registered = WowVision.ui.elementTypes:get("TestElement_3")
        t:assertNotNil(registered)
        t:assertNotNil(registered.class)
    end,

    ["CreateElementType copies generationConditions from parent"] = function(t)
        -- Get Widget which has generationConditions
        local parentData = WowVision.ui.elementTypes:get("Widget")
        if parentData and parentData.generationConditions and next(parentData.generationConditions) then
            local _, _, newData = WowVision.ui:CreateElementType("TestElement_4", "Widget")
            -- Should have inherited conditions
            for k, v in pairs(parentData.generationConditions) do
                t:assertEqual(newData.generationConditions[k], v)
            end
        else
            -- Parent has no conditions, just verify table exists
            local _, _, newData = WowVision.ui:CreateElementType("TestElement_4b", "Element")
            t:assertNotNil(newData.generationConditions)
        end
    end,

    ["CreateElement errors on missing type"] = function(t)
        t:assertError(function()
            WowVision.ui:CreateElement("NonExistentElement", {})
        end)
    end,

    ["CreateElement creates instance"] = function(t)
        WowVision.ui:CreateElementType("TestElement_5", "Element")
        local element = WowVision.ui:CreateElement("TestElement_5", {})
        t:assertNotNil(element)
    end,

    ["CreateElement sets ui reference"] = function(t)
        WowVision.ui:CreateElementType("TestElement_6", "Element")
        local element = WowVision.ui:CreateElement("TestElement_6", {})
        t:assertEqual(element.ui, WowVision.ui)
    end,

    ["CreateElement applies config"] = function(t)
        WowVision.ui:CreateElementType("TestElement_7", "Element")
        local element = WowVision.ui:CreateElement("TestElement_7", { label = "Test Label" })
        t:assertEqual(element.label, "Test Label")
    end,
})

--
-- WindowManager Tests
--

testRunner:addSuite("WindowManager", {
    ["CreateWindowType creates new type"] = function(t)
        local newType = WowVision.WindowManager:CreateWindowType("TestWindowType_1")
        t:assertNotNil(newType)
    end,

    ["CreateWindowType with parent inherits"] = function(t)
        local newType, parentClass = WowVision.WindowManager:CreateWindowType("TestWindowType_2", "Window")
        t:assertNotNil(newType)
        t:assertNotNil(parentClass)
    end,

    ["CreateWindowType errors on missing parent"] = function(t)
        t:assertError(function()
            WowVision.WindowManager:CreateWindowType("TestWindowType_3", "NonExistentWindow")
        end)
    end,

    ["CreateWindowType registers in windowTypes"] = function(t)
        WowVision.WindowManager:CreateWindowType("TestWindowType_4")
        local registered = WowVision.WindowManager.windowTypes:get("TestWindowType_4")
        t:assertNotNil(registered)
    end,

    ["CreateWindow creates instance"] = function(t)
        local window = WowVision.WindowManager:CreateWindow("ManualWindow", {
            name = "TestWindow_1",
            rootElement = "Panel",
        })
        t:assertNotNil(window)
        t:assertEqual(window.name, "TestWindow_1")
    end,

    ["CreateWindow errors on missing type"] = function(t)
        t:assertError(function()
            WowVision.WindowManager:CreateWindow("NonExistentWindowType", { name = "test" })
        end)
    end,
})

--
-- Window Tests
--

-- Helper to create test windows
local function createManualWindow(config)
    local defaults = { name = "test_" .. math.random(10000), rootElement = "Panel" }
    for k, v in pairs(config or {}) do
        defaults[k] = v
    end
    return WowVision.WindowManager:CreateWindow("ManualWindow", defaults)
end

local function createFrameWindow(config)
    local defaults = { name = "test_" .. math.random(10000), frameName = "TestFrame", rootElement = "Panel" }
    for k, v in pairs(config or {}) do
        defaults[k] = v
    end
    return WowVision.WindowManager:CreateWindow("FrameWindow", defaults)
end

local function createCustomWindow(config)
    local defaults = {
        name = "test_" .. math.random(10000),
        rootElement = "Panel",
        isOpenFunc = function() return false end,
    }
    for k, v in pairs(config or {}) do
        defaults[k] = v
    end
    return WowVision.WindowManager:CreateWindow("CustomWindow", defaults)
end

testRunner:addSuite("Window", {
    ["checkState returns false when state unchanged"] = function(t)
        local window = createManualWindow()
        local changed, isOpen = window:checkState()
        t:assertFalse(changed)
        t:assertFalse(isOpen)
    end,

    ["checkState returns true when state changes"] = function(t)
        -- Use CustomWindow since ManualWindow.isOpen() returns _isCurrentlyOpen
        -- which means it can never detect a state change on its own
        local isOpenValue = false
        local window = createCustomWindow({
            isOpenFunc = function() return isOpenValue end,
        })
        -- Initially closed, checkState should return no change
        local changed1, _ = window:checkState()
        t:assertFalse(changed1)
        -- Now open it externally
        isOpenValue = true
        local changed2, isOpen2 = window:checkState()
        t:assertTrue(changed2)
        t:assertTrue(isOpen2)
    end,

    ["canOpen returns true without conflicting addons"] = function(t)
        local window = createManualWindow()
        t:assertTrue(window:canOpen())
    end,

    ["canOpen returns false with conflicting addon"] = function(t)
        -- Temporarily add a fake loaded addon
        local originalLoaded = WowVision.loadedAddons
        WowVision.loadedAddons = { FakeAddon = true }
        local window = createManualWindow({ conflictingAddons = { "FakeAddon" } })
        t:assertFalse(window:canOpen())
        WowVision.loadedAddons = originalLoaded
    end,

    ["checkConflictingAddons returns false without loadedAddons"] = function(t)
        local originalLoaded = WowVision.loadedAddons
        WowVision.loadedAddons = nil
        local window = createManualWindow({ conflictingAddons = { "SomeAddon" } })
        t:assertFalse(window._hasConflictingAddon)
        WowVision.loadedAddons = originalLoaded
    end,

    ["checkConflictingAddons returns false without conflictingAddons"] = function(t)
        local window = createManualWindow()
        t:assertFalse(window._hasConflictingAddon)
    end,

    ["buildRootElement handles string rootElement"] = function(t)
        local window = createManualWindow({ rootElement = "Panel" })
        local built = window:buildRootElement()
        t:assertEqual(built[1], "Panel")
    end,

    ["buildRootElement handles table rootElement"] = function(t)
        local window = createManualWindow({ rootElement = { "List", label = "My List" } })
        local built = window:buildRootElement()
        t:assertEqual(built[1], "List")
        t:assertEqual(built.label, "My List")
    end,

    ["buildRootElement merges props"] = function(t)
        local window = createManualWindow({ rootElement = "Panel" })
        local built = window:buildRootElement({ customProp = "value" })
        t:assertEqual(built.customProp, "value")
    end,

    ["needsPolling returns false for ManualWindow"] = function(t)
        local window = createManualWindow()
        t:assertFalse(window:needsPolling())
    end,

    ["getOpenInstance returns nil when not open"] = function(t)
        local window = createManualWindow()
        t:assertNil(window:getOpenInstance())
    end,

    ["hookEscape defaults to false"] = function(t)
        local window = createManualWindow()
        t:assertFalse(window.hookEscape)
    end,

    ["innate defaults to false"] = function(t)
        local window = createManualWindow()
        t:assertFalse(window.innate)
    end,

    ["generated defaults to false"] = function(t)
        local window = createManualWindow()
        t:assertFalse(window.generated)
    end,
})

testRunner:addSuite("FrameWindow", {
    ["needsPolling returns true"] = function(t)
        local window = createFrameWindow()
        t:assertTrue(window:needsPolling())
    end,

    ["isOpen returns false when frame not found"] = function(t)
        local window = createFrameWindow({ frameName = "NonExistentFrame_12345" })
        t:assertFalse(window:isOpen())
    end,

    ["getFrame returns nil when frame not found"] = function(t)
        local window = createFrameWindow({ frameName = "NonExistentFrame_12345" })
        t:assertNil(window:getFrame())
    end,

    ["getFrame caches found frame"] = function(t)
        -- Create a real frame for testing
        local testFrame = CreateFrame("Frame", "TestFrameForCaching_" .. math.random(10000))
        local window = createFrameWindow({ frameName = testFrame:GetName() })
        window:getFrame()
        t:assertEqual(window._cachedFrame, testFrame)
    end,

    ["frameName is required"] = function(t)
        t:assertError(function()
            WowVision.WindowManager:CreateWindow("FrameWindow", {
                name = "test",
                rootElement = "Panel",
                -- Missing frameName
            })
        end)
    end,
})

testRunner:addSuite("CustomWindow", {
    ["needsPolling returns true"] = function(t)
        local window = createCustomWindow()
        t:assertTrue(window:needsPolling())
    end,

    ["isOpen calls isOpenFunc"] = function(t)
        local called = false
        local window = createCustomWindow({
            isOpenFunc = function()
                called = true
                return true
            end,
        })
        local result = window:isOpen()
        t:assertTrue(called)
        t:assertTrue(result)
    end,

    ["isOpenFunc is required"] = function(t)
        t:assertError(function()
            WowVision.WindowManager:CreateWindow("CustomWindow", {
                name = "test",
                rootElement = "Panel",
                -- Missing isOpenFunc
            })
        end)
    end,
})

testRunner:addSuite("ManualWindow", {
    ["isOpen returns internal state"] = function(t)
        local window = createManualWindow()
        t:assertFalse(window:isOpen())
        window._isCurrentlyOpen = true
        t:assertTrue(window:isOpen())
    end,

    ["needsPolling returns false"] = function(t)
        local window = createManualWindow()
        t:assertFalse(window:needsPolling())
    end,
})
