local info = WowVision.info
local L = WowVision:getLocale()

local BoolField, parent = info:CreateFieldClass("Bool")
BoolField.resolveFunctions = true

function BoolField:getGenerator(obj)
    return { "Checkbox", label = self:getLabel(), bind = { type = "Field", target = obj, field = self } }
end

BoolField:addOperator({
    key = "eq",
    label = L["equal to"],
    operands = { "Bool", "Bool" },
    func = function(a, b)
        return a == b
    end,
})
