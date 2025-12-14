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

function PlayerMoney:getFocusString(params)
    return C_CurrencyInfo.GetCoinText(self:get(params, "current"))
end
