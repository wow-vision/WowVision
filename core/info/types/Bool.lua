local info = WowVision.info
local L = WowVision:getLocale()

local Bool = info:createFieldType("Bool")

Bool:addOperator({
    key = "eq",
    label = L["equal to"],
    operands = { "Bool", "Bool" },
    func = function(a, b)
        return a == b
    end,
})
