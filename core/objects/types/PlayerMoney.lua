local L = WowVision:getLocale()
local objects = WowVision.objects

local PlayerMoney = objects:createObjectType("PlayerMoney")
PlayerMoney:setLabel(L["Money"])

PlayerMoney:addField({
    key = "current",
    get = function(params)
        return GetMoney()
    end,
})

PlayerMoney:addField({
    key = "formatted",
    get = function(params)
        return C_CurrencyInfo.GetCoinText(GetMoney())
    end,
})

function PlayerMoney:getFocusString(params)
    return self:renderTemplate("{formatted}", params)
end
