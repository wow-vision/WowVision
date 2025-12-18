local L = WowVision:getLocale()
local UnitType = WowVision.objects.UnitType
local objects = WowVision.objects

local pvp = objects:createUnitType("PVP")
pvp:setLabel("PVP")

pvp:addField({
    key = "active",
    get = function(params)
        if UnitExists(params.unit) then
            return UnitIsPVP(params.unit)
        end
        return false
    end,
})

pvp:addField({
    key = "status",
    get = function(params)
        if UnitExists(params.unit) and UnitIsPVP(params.unit) then
            return L["Enabled"]
        end
        return L["Disabled"]
    end,
})

pvp:registerTemplate({
    key = "default",
    name = "Default",
    format = "[PVP]: {status}",
})
