local L = WowVision:getLocale()
local objects = WowVision.objects

local PlayerXP = objects:createObjectType("PlayerXP")
PlayerXP:setLabel(L["XP"])

PlayerXP:addField({
    key = "current",
    type = "Number",
    label = L["Current"],
    get = function(params)
        return UnitXP("player")
    end,
})

PlayerXP:addField({
    key = "maximum",
    type = "Number",
    label = L["Maximum"],
    get = function(params)
        return UnitXPMax("player")
    end,
})

PlayerXP:addField({
    key = "percent",
    type = "Number",
    label = L["Percent"],
    get = function(params)
        return math.floor(UnitXP("player") / UnitXPMax("player") * 100)
    end,
})

-- The level the bar fills towards: the maximum is what the NEXT level
-- costs, so the line names it. nil at the level cap, where there is none.
PlayerXP:addField({
    key = "nextLevel",
    type = "Number",
    label = L["Next Level"],
    get = function(params)
        local level = UnitLevel("player")
        if GetMaxPlayerLevel ~= nil and level >= GetMaxPlayerLevel() then
            return nil
        end
        return level + 1
    end,
})

-- Rested XP: the extra stretch the bar shows ahead of the fill. nil when
-- there is none or XP gain is switched off, where the bar hides it too.
PlayerXP:addField({
    key = "rested",
    type = "Number",
    label = L["Rested"],
    get = function(params)
        local rested = GetXPExhaustion()
        if rested == nil or rested <= 0 or IsXPUserDisabled() then
            return nil
        end
        return rested
    end,
})

function PlayerXP:getFocusString(params)
    if self:get(params, "nextLevel") == nil then
        return self:renderTemplate("[XP]: {percent}% ({current} [of] {maximum})", params)
    end
    if self:get(params, "rested") == nil then
        return self:renderTemplate("[XP]: {percent}% ({current} [of] {maximum} [to level] {nextLevel})", params)
    end
    return self:renderTemplate(
        "[XP]: {percent}% ({current} [of] {maximum} [to level] {nextLevel}), [rested] {rested}",
        params
    )
end
