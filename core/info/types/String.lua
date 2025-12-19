local info = WowVision.info
local L = WowVision:getLocale()

local String = info:createFieldType("String")

String:addOperator({
    key = "eq",
    label = L["equal to"],
    operands = { "String", "String" },
    func = function(a, b)
        return a == b
    end,
})
