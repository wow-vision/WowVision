local info = WowVision.info
local L = WowVision:getLocale()

local StringField, parent = info:CreateFieldClass("String")
StringField.resolveFunctions = true

function StringField:getGenerator(obj)
    return {
        "EditBox",
        label = self:getLabel(),
        autoInputOnFocus = false,
        bind = { type = "Field", target = obj, field = self },
    }
end

StringField:addOperator({
    key = "eq",
    label = L["equal to"],
    operands = { "String", "String" },
    func = function(a, b)
        return a == b
    end,
})
