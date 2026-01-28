local L = WowVision:getLocale()
local objects = WowVision.objects

local Health = objects:createUnitType("Health")

Health:addField({
    key = "current",
    type = "Number",
    label = L["Current"],
    getCached = function(cache)
        return cache.current
    end,
    get = function(params)
        return UnitHealth(params.unit)
    end,
})

Health:addField({
    key = "minimum",
    type = "Number",
    label = L["Minimum"],
    default = 0,
})

Health:addField({
    key = "maximum",
    type = "Number",
    label = L["Maximum"],
    getCached = function(cache)
        return cache.maximum
    end,
    get = function(params)
        return UnitHealthMax(params.unit)
    end,
})

function Health:onUnitAdd(unit)
    unit.frame:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", unit.id)
    unit.frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit.id)
    unit.frame:SetScript("OnEvent", function(frame, event, id)
        if unit.guid == nil then
            return
        end
        self:onEvent(event, unit)
    end)
end

function Health:onUnitChange(unit)
    if unit.guid == nil then
        return
    end
    local data = {
        current = UnitHealth(unit.id),
        maximum = UnitHealthMax(unit.id),
    }
    self:addObject(unit, "Health", data)
end

function Health:onEvent(event, unit)
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        self:modifyObject(unit, "Health", {
            current = UnitHealth(unit.id),
        })
    elseif event == "UNIT_MAXHEALTH" then
        self:modifyObject(unit, "Health", {
            maximum = UnitHealthMax(unit.id),
        })
    end
end

Health:registerTemplate({
    key = "default",
    name = "Default",
    format = "{current}/{maximum} [Health]",
})
