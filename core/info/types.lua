local info = WowVision.info

local Number = info:createFieldType("Number")

Number.parameters:addFields({
    { key = "minimum" },
    { key = "maximum" },
})

function Number:validate(field, value)
    local number = tonumber(value)
    if number == nil then
        error("Could not validate " .. value .. " as Number.")
    end
    local minimum = field.minimum
    if type(minimum) == "function" then
        minimum = minimum(value)
    end
    if number < minimum then
        number = minimum
    end
    local maximum = field.maximum
    if type(maximum) == "function" then
        maximum = maximum(value)
    end
    if number > maximum then
        number = maximum
    end
    return number
end

Number:addOperator({
    key = "eq",
    operands = { "Number", "Number" },
    func = function(a, b)
        return a == b
    end,
})

Number:addOperator({
    key = "neq",
    operands = { "Number", "Number" },
    func = function(a, b)
        return a ~= b
    end,
})

Number:addOperator({
    key = "lt",
    operands = { "Number", "Number" },
    func = function(a, b)
        return a < b
    end,
})
