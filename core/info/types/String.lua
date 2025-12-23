local info = WowVision.info
local L = WowVision:getLocale()

local StringField, parent = info:CreateFieldClass("String")

StringField:addOperator({
    key = "eq",
    label = L["equal to"],
    operands = { "String", "String" },
    func = function(a, b)
        return a == b
    end,
})
