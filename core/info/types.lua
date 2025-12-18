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

local String = info:createFieldType("String")

local Bool = info:createFieldType("Bool")

-- Operators are added after locale is available
function info:addOperators()
    local L = WowVision:getLocale()

    Number:addOperator({
        key = "eq",
        label = L["equal to"],
        operands = { "Number", "Number" },
        func = function(a, b)
            return a == b
        end,
    })

    Number:addOperator({
        key = "neq",
        label = L["not equal to"],
        operands = { "Number", "Number" },
        func = function(a, b)
            return a ~= b
        end,
    })

    Number:addOperator({
        key = "lt",
        label = L["less than"],
        operands = { "Number", "Number" },
        func = function(a, b)
            return a < b
        end,
    })

    Number:addOperator({
        key = "leq",
        label = L["less than or equal to"],
        operands = { "Number", "Number" },
        func = function(a, b)
            return a <= b
        end,
    })

    Number:addOperator({
        key = "gt",
        label = L["greater than"],
        operands = { "Number", "Number" },
        func = function(a, b)
            return a > b
        end,
    })

    Number:addOperator({
        key = "geq",
        label = L["greater than or equal to"],
        operands = { "Number", "Number" },
        func = function(a, b)
            return a >= b
        end,
    })

    String:addOperator({
        key = "eq",
        label = L["equal to"],
        operands = { "String", "String" },
        func = function(a, b)
            return a == b
        end,
    })

    Bool:addOperator({
        key = "eq",
        label = L["equal to"],
        operands = { "Bool", "Bool" },
        func = function(a, b)
            return a == b
        end,
    })
end
