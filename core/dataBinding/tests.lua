local testRunner = WowVision.testing.testRunner

testRunner:addSuite("dataBinding", {
    ["create returns correct binding type"] = function(t)
        local binding = WowVision.dataBinding:create({
            type = "Property",
            target = {},
            property = "value",
        })
        t:assertNotNil(binding)
        t:assertEqual(binding.class.typeKey, "Property")
    end,

    ["create errors on missing type"] = function(t)
        t:assertError(function()
            WowVision.dataBinding:create({})
        end)
    end,

    ["create errors on unknown type"] = function(t)
        t:assertError(function()
            WowVision.dataBinding:create({ type = "Unknown" })
        end)
    end,
})

testRunner:addSuite("dataBinding.Property", {
    ["readValue gets property"] = function(t)
        local target = { value = 42 }
        local binding = WowVision.dataBinding:create({
            type = "Property",
            target = target,
            property = "value",
        })
        t:assertEqual(binding:get(), 42)
    end,

    ["writeValue sets property"] = function(t)
        local target = { value = 0 }
        local binding = WowVision.dataBinding:create({
            type = "Property",
            target = target,
            property = "value",
        })
        binding:set(100)
        t:assertEqual(target.value, 100)
    end,

    ["fixedValue overrides set value"] = function(t)
        local target = { value = 0 }
        local binding = WowVision.dataBinding:create({
            type = "Property",
            target = target,
            property = "value",
            fixedValue = 999,
        })
        binding:set(100) -- Should be ignored, fixedValue used
        t:assertEqual(target.value, 999)
    end,
})

testRunner:addSuite("dataBinding.Method", {
    ["readValue calls getter"] = function(t)
        local target = {
            _value = 42,
            getValue = function(self)
                return self._value
            end,
            setValue = function(self, v)
                self._value = v
            end,
        }
        local binding = WowVision.dataBinding:create({
            type = "Method",
            target = target,
            getter = "getValue",
            setter = "setValue",
        })
        t:assertEqual(binding:get(), 42)
    end,

    ["writeValue calls setter"] = function(t)
        local target = {
            _value = 0,
            getValue = function(self)
                return self._value
            end,
            setValue = function(self, v)
                self._value = v
            end,
        }
        local binding = WowVision.dataBinding:create({
            type = "Method",
            target = target,
            getter = "getValue",
            setter = "setValue",
        })
        binding:set(100)
        t:assertEqual(target._value, 100)
    end,
})

testRunner:addSuite("dataBinding.Function", {
    ["readValue calls getter function"] = function(t)
        local value = 42
        local binding = WowVision.dataBinding:create({
            type = "Function",
            getter = function()
                return value
            end,
            setter = function(v)
                value = v
            end,
        })
        t:assertEqual(binding:get(), 42)
    end,

    ["writeValue calls setter function"] = function(t)
        local value = 0
        local binding = WowVision.dataBinding:create({
            type = "Function",
            getter = function()
                return value
            end,
            setter = function(v)
                value = v
            end,
        })
        binding:set(100)
        t:assertEqual(value, 100)
    end,
})

testRunner:addSuite("dataBinding.Field", {
    ["readValue uses field getter"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "name", default = "test" })
        local field = info:getField("name")
        local target = { name = "Alice" }

        local binding = WowVision.dataBinding:create({
            type = "Field",
            target = target,
            field = field,
        })
        t:assertEqual(binding:get(), "Alice")
    end,

    ["writeValue uses field setter"] = function(t)
        local info = WowVision.info.InfoManager:new()
        info:addField({ key = "name" })
        local field = info:getField("name")
        local target = {}

        local binding = WowVision.dataBinding:create({
            type = "Field",
            target = target,
            field = field,
        })
        binding:set("Bob")
        t:assertEqual(target.name, "Bob")
    end,
})
