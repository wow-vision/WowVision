local testRunner = WowVision.testing.testRunner
local input = WowVision.input

-- Helper to create a binding without WoW API activation
local function createTestBinding(info)
    local binding = input.Binding:new(info)
    binding.inputManager = input
    return binding
end

testRunner:addSuite("Binding", {
    ["initialize sets up inputs array"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        t:assertNotNil(binding.inputs)
        t:assertEqual(binding.inputs._type, "array")
    end,

    ["initialize sets up activated array"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        t:assertNotNil(binding.activated)
        t:assertEqual(#binding.activated, 0)
    end,

    ["initialize applies info fields"] = function(t)
        local binding = createTestBinding({
            key = "test",
            type = "Function",
            label = "Test Binding",
            vital = true,
        })
        t:assertEqual(binding.key, "test")
        t:assertEqual(binding.type, "Function")
        t:assertEqual(binding.label, "Test Binding")
        t:assertTrue(binding.vital)
    end,

    ["getLabel returns label"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function", label = "My Label" })
        t:assertEqual(binding:getLabel(), "My Label")
    end,

    ["getDefaultDB returns inputs structure"] = function(t)
        local binding = createTestBinding({
            key = "test",
            type = "Function",
            inputs = { "A", "B" },
        })
        local db = binding:getDefaultDB()
        t:assertNotNil(db.inputs)
        t:assertEqual(db.inputs._type, "array")
        t:assertEqual(#db.inputs, 2)
        t:assertEqual(db.inputs[1], "A")
        t:assertEqual(db.inputs[2], "B")
    end,

    ["setDB uses same reference as db.inputs"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        local db = { inputs = { _type = "array", "X", "Y", "Z" } }
        binding:setDB(db)
        t:assertEqual(#binding.inputs, 3)
        t:assertEqual(binding.inputs[1], "X")
        t:assertEqual(binding.inputs[2], "Y")
        t:assertEqual(binding.inputs[3], "Z")
        t:assertEqual(binding.inputs, db.inputs)
    end,

    ["addInput adds to inputs array"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        binding.inputManager = nil -- Disable conflict checking
        binding:addInput("A")
        binding:addInput("B")
        t:assertEqual(#binding.inputs, 2)
        t:assertEqual(binding.inputs[1], "A")
        t:assertEqual(binding.inputs[2], "B")
    end,

    ["addInput mutates shared db.inputs"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        binding.inputManager = nil
        local db = { inputs = { _type = "array" } }
        binding:setDB(db)
        binding:addInput("NEW")
        t:assertEqual(#db.inputs, 1)
        t:assertEqual(db.inputs[1], "NEW")
        t:assertEqual(binding.inputs, db.inputs)
    end,

    ["removeInput removes from inputs array"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        binding.inputManager = nil
        binding:addInput("A")
        binding:addInput("B")
        binding:addInput("C")
        binding:removeInput("B")
        t:assertEqual(#binding.inputs, 2)
        t:assertEqual(binding.inputs[1], "A")
        t:assertEqual(binding.inputs[2], "C")
    end,

    ["setInputs replaces all inputs"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        binding.inputManager = nil
        binding:addInput("OLD")
        binding:setInputs({ "NEW1", "NEW2" })
        t:assertEqual(#binding.inputs, 2)
        t:assertEqual(binding.inputs[1], "NEW1")
        t:assertEqual(binding.inputs[2], "NEW2")
    end,

    ["setInputs updates both binding.inputs and db.inputs"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        binding.inputManager = nil
        local db = { inputs = { _type = "array", "OLD" } }
        binding:setDB(db)
        binding:setInputs({ "NEW1", "NEW2" })
        t:assertEqual(#binding.inputs, 2)
        t:assertEqual(binding.inputs[1], "NEW1")
        t:assertEqual(binding.inputs[2], "NEW2")
        t:assertEqual(binding.inputs, db.inputs)
    end,

    ["doesInputConflict returns nil without inputManager"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        binding.inputManager = nil
        t:assertNil(binding:doesInputConflict("A"))
    end,

    ["deactivateAll clears activated array"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        -- Manually add mock activated entries
        binding.activated = {
            { deactivate = function() end },
            { deactivate = function() end },
        }
        binding:deactivateAll()
        t:assertEqual(#binding.activated, 0)
    end,

    ["dorment defaults to false"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        t:assertFalse(binding.dorment)
    end,

    ["conflictingAddons defaults to empty array"] = function(t)
        local binding = createTestBinding({ key = "test", type = "Function" })
        t:assertNotNil(binding.conflictingAddons)
        t:assertEqual(#binding.conflictingAddons, 0)
    end,
})

testRunner:addSuite("BindingSet", {
    ["initialize creates empty structures"] = function(t)
        local set = input.BindingSet:new()
        t:assertNotNil(set.bindingSet)
        t:assertNotNil(set.orderedBindings)
        t:assertEqual(#set.orderedBindings, 0)
    end,

    ["add adds binding to set"] = function(t)
        local set = input.BindingSet:new()
        local binding = createTestBinding({ key = "test", type = "Function" })
        local result = set:add(binding)
        t:assertTrue(result)
        t:assertEqual(#set.orderedBindings, 1)
        t:assertEqual(set.orderedBindings[1], binding)
    end,

    ["add prevents duplicates"] = function(t)
        local set = input.BindingSet:new()
        local binding = createTestBinding({ key = "test", type = "Function" })
        set:add(binding)
        local result = set:add(binding)
        t:assertFalse(result)
        t:assertEqual(#set.orderedBindings, 1)
    end,

    ["add allows multiple different bindings"] = function(t)
        local set = input.BindingSet:new()
        local binding1 = createTestBinding({ key = "test1", type = "Function" })
        local binding2 = createTestBinding({ key = "test2", type = "Function" })
        set:add(binding1)
        set:add(binding2)
        t:assertEqual(#set.orderedBindings, 2)
    end,

    ["getDefaultDB builds structure from bindings"] = function(t)
        local set = input.BindingSet:new()
        local binding1 = createTestBinding({ key = "first", type = "Function", inputs = { "A" } })
        local binding2 = createTestBinding({ key = "second", type = "Function", inputs = { "B", "C" } })
        set:add(binding1)
        set:add(binding2)
        local db = set:getDefaultDB()
        t:assertNotNil(db.first)
        t:assertNotNil(db.second)
        t:assertEqual(#db.first.inputs, 1)
        t:assertEqual(#db.second.inputs, 2)
    end,

    ["getDefaultDB skips bindings without key"] = function(t)
        local set = input.BindingSet:new()
        local binding = createTestBinding({ type = "Function", inputs = { "A" } })
        binding.key = nil
        set:add(binding)
        local db = set:getDefaultDB()
        -- Should be empty since binding has no key
        local count = 0
        for _ in pairs(db) do
            count = count + 1
        end
        t:assertEqual(count, 0)
    end,

    ["setDB propagates to bindings"] = function(t)
        local set = input.BindingSet:new()
        local binding = createTestBinding({ key = "test", type = "Function" })
        set:add(binding)
        local db = {
            test = { inputs = { _type = "array", "X", "Y" } },
        }
        set:setDB(db)
        t:assertEqual(#binding.inputs, 2)
        t:assertEqual(binding.inputs[1], "X")
    end,
})

testRunner:addSuite("ActivationSet", {
    ["initialize creates empty activations"] = function(t)
        local set = input.ActivationSet:new()
        t:assertNotNil(set.activations)
        t:assertEqual(#set.activations, 0)
    end,

    ["add adds activation info"] = function(t)
        local set = input.ActivationSet:new()
        local info = { binding = "test", type = "Click" }
        set:add(info)
        t:assertEqual(#set.activations, 1)
    end,

    ["add sets enabled to true by default"] = function(t)
        local set = input.ActivationSet:new()
        local info = { binding = "test" }
        set:add(info)
        t:assertTrue(set.activations[1].enabled)
    end,

    ["add preserves explicit enabled=false"] = function(t)
        local set = input.ActivationSet:new()
        local info = { binding = "test", enabled = false }
        set:add(info)
        t:assertFalse(set.activations[1].enabled)
    end,

    ["add initializes activated array"] = function(t)
        local set = input.ActivationSet:new()
        local info = { binding = "test" }
        set:add(info)
        t:assertNotNil(set.activations[1].activated)
        t:assertEqual(#set.activations[1].activated, 0)
    end,

    ["add returns the info object"] = function(t)
        local set = input.ActivationSet:new()
        local info = { binding = "test" }
        local result = set:add(info)
        t:assertEqual(result, info)
    end,

    ["deactivateAll clears all activated arrays"] = function(t)
        local set = input.ActivationSet:new()
        -- Create mock bindings with deactivate methods
        local mockBinding = {
            deactivate = function(self, activated) end,
        }
        local info1 = { binding = mockBinding, activated = { {}, {} } }
        local info2 = { binding = mockBinding, activated = { {} } }
        set.activations = { info1, info2 }
        set:deactivateAll()
        t:assertEqual(#info1.activated, 0)
        t:assertEqual(#info2.activated, 0)
    end,
})

--
-- Activator tests (the new keymap + action + activator path)
--

local function makeTestKeymap(key, inputs, emulatedKey)
    if input:getBinding(key) == nil then
        input:createBinding({
            type = "Click",
            key = key,
            dorment = true,
            label = key,
            inputs = inputs,
            emulatedKey = emulatedKey,
        })
    end
    return input:getBinding(key)
end

testRunner:addSuite("InputActivator", {
    ["unknown keymap and action error"] = function(t)
        t:assertError(function()
            WowVision.inputActivator:activate({ binding = "noSuchKeymap", type = "Click" })
        end)
        makeTestKeymap("activatorTestA", { "F13" }, "LeftButton")
        t:assertError(function()
            WowVision.inputActivator:activate({ binding = "activatorTestA", type = "NoSuchAction" })
        end)
    end,

    ["activation configures one frame per input and releases them"] = function(t)
        makeTestKeymap("activatorTestB", { "F13", "F14" }, "LeftButton")
        local configured = {}
        local cleared = 0
        WowVision.inputActions:register("activatorTestAction", {
            configure = function(frame, spec, emulatedKey)
                tinsert(configured, emulatedKey)
            end,
            clear = function(frame, spec)
                cleared = cleared + 1
            end,
        })
        local handle = WowVision.inputActivator:activate({
            binding = "activatorTestB",
            type = "activatorTestAction",
        })
        t:assertTrue(handle.active)
        t:assertEqual(#handle.frames, 2)
        t:assertEqual(configured[1], "LeftButton", "keymap default emulated key applies")
        handle:release()
        t:assertFalse(handle.active)
        t:assertEqual(cleared, 2)
        t:assertEqual(#handle.frames, 0)
        handle:release() -- releasing twice is harmless
        t:assertEqual(cleared, 2)
    end,

    ["spec emulatedKey overrides the keymap default"] = function(t)
        makeTestKeymap("activatorTestC", { "F13" }, "LeftButton")
        local seen = nil
        WowVision.inputActions:register("activatorTestAction2", {
            configure = function(frame, spec, emulatedKey)
                seen = emulatedKey
            end,
            clear = function(frame, spec) end,
        })
        local handle = WowVision.inputActivator:activate({
            binding = "activatorTestC",
            type = "activatorTestAction2",
            emulatedKey = "RightButton",
        })
        t:assertEqual(seen, "RightButton")
        handle:release()
    end,

    ["a keymap with no inputs yields an inactive handle"] = function(t)
        makeTestKeymap("activatorTestD", {}, "LeftButton")
        local handle = WowVision.inputActivator:activate({
            binding = "activatorTestD",
            type = "Click",
        })
        t:assertFalse(handle.active)
        handle:release()
    end,
})
