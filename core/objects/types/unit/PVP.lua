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

function pvp:getFocusString(params)
    if self:get(params, "active") then
        return L["PVP"] .. ": " .. L["Enabled"]
    end
    return L["PVP"] .. ": " .. L["Disabled"]
end
