local info = WowVision.info
local L = WowVision:getLocale()

local NumberField, parent = info:CreateFieldClass("Number")

function NumberField:setup(config)
    parent.setup(self, config)
    self.minimum = config.minimum
    self.maximum = config.maximum
end

function NumberField:getInfo()
    local result = parent.getInfo(self)
    result.minimum = self.minimum
    result.maximum = self.maximum
    return result
end

function NumberField:validate(value)
    local number = tonumber(value)
    if number == nil then
        error("Could not validate " .. tostring(value) .. " as Number.")
    end
    local minimum = self.minimum
    if type(minimum) == "function" then
        minimum = minimum(value)
    end
    if minimum and number < minimum then
        number = minimum
    end
    local maximum = self.maximum
    if type(maximum) == "function" then
        maximum = maximum(value)
    end
    if maximum and number > maximum then
        number = maximum
    end
    return number
end

function NumberField:getGenerator(obj)
    return {
        "EditBox",
        label = self:getLabel(),
        autoInputOnFocus = false,
        type = "decimal",
        bind = { type = "Field", target = obj, field = self },
    }
end

NumberField:addOperator({
    key = "eq",
    label = L["equal to"],
    operands = { "Number", "Number" },
    func = function(a, b)
        return a == b
    end,
})

NumberField:addOperator({
    key = "neq",
    label = L["not equal to"],
    operands = { "Number", "Number" },
    func = function(a, b)
        return a ~= b
    end,
})

NumberField:addOperator({
    key = "lt",
    label = L["less than"],
    operands = { "Number", "Number" },
    func = function(a, b)
        return a < b
    end,
})

NumberField:addOperator({
    key = "leq",
    label = L["less than or equal to"],
    operands = { "Number", "Number" },
    func = function(a, b)
        return a <= b
    end,
})

NumberField:addOperator({
    key = "gt",
    label = L["greater than"],
    operands = { "Number", "Number" },
    func = function(a, b)
        return a > b
    end,
})

NumberField:addOperator({
    key = "geq",
    label = L["greater than or equal to"],
    operands = { "Number", "Number" },
    func = function(a, b)
        return a >= b
    end,
})
