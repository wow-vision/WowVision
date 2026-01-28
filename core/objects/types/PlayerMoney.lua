local L = WowVision:getLocale()
local objects = WowVision.objects

local PlayerMoney = objects:createObjectType("PlayerMoney")
PlayerMoney:setLabel(L["Money"])

PlayerMoney:addField({
    key = "current",
    type = "Number",
    label = L["Current"],
    get = function(params)
        return GetMoney()
    end,
})

PlayerMoney:addField({
    key = "formatted",
    type = "String",
    label = L["Formatted"],
    get = function(params)
        return C_CurrencyInfo.GetCoinText(GetMoney())
    end,
})

function PlayerMoney:getFocusString(params)
    return self:renderTemplate("{formatted}", params)
end
