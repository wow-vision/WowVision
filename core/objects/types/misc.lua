local L = WowVision:getLocale()
local objects = WowVision.objects

local PlayerXP = objects:createObjectType("PlayerXP")
PlayerXP:setLabel(L["XP"])

PlayerXP:addField({
    key = "current",
    get = function(params)
        return UnitXP("player")
    end,
})

PlayerXP:addField({
    key = "maximum",
    get = function(params)
        return UnitXPMax("player")
    end,
})

PlayerXP:addField({
    key = "percent",
    get = function(params)
        return math.floor(UnitXP("player") / UnitXPMax("player") * 100)
    end,
})

function PlayerXP:getFocusString(params)
    return L["XP"]
        .. ": "
        .. self:get(params, "percent")
        .. "% ("
        .. self:get(params, "current")
        .. " "
        .. L["of"]
        .. " "
        .. self:get(params, "maximum")
        .. ")"
end

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
