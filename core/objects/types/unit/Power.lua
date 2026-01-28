local L = WowVision:getLocale()
local UnitType = WowVision.objects.UnitType
local objects = WowVision.objects
local powersDB = WowVision.gameDB:get("Power")

local Power = objects:createUnitType("Power")

Power:addParameter({
    key = "powerType",
    type = "Choice",
    label = L["Power Type"],
    choices = function()
        local result = {}
        for _, power in ipairs(powersDB.items) do
            tinsert(result, {
                key = power.key,
                label = power.label,
                value = power.key,
            })
        end
        return result
    end,
})

function Power:validParams(params)
    if params.unit == nil then
        return false, false
    end
    return true, params.powerType ~= nil
end

Power:addField({
    key = "minimum",
    type = "Number",
    label = L["Minimum"],
    getCached = function(cache)
        return cache.minimum
    end,
    get = function(params)
        if params.powerType == nil then
            return 0
        end
        local power = powersDB:get(params.powerType)
        if power == nil then
            error("Unknown power type " .. params.powerType .. ".")
        end
        return power.minimum
    end,
})

Power:addField({
    key = "current",
    type = "Number",
    label = L["Current"],
    getCached = function(cache)
        return cache.current
    end,
    get = function(params)
        if params.powerType == nil then
            return UnitPower(params.unit)
        end
        local power = powersDB:get(params.powerType)
        if power == nil then
            error("Unknown power type " .. params.powerType .. ".")
        end
        return UnitPower(params.unit, power.id)
    end,
})

Power:addField({
    key = "maximum",
    type = "Number",
    label = L["Maximum"],
    getCached = function(cache)
        return cache.maximum
    end,
    get = function(params)
        if params.powerType == nil then
            return UnitPowerMax(params.unit)
        end
        local power = powersDB:get(params.powerType)
        if power == nil then
            error("Unknown power type " .. params.powerType .. ".")
        end
        return UnitPowerMax(params.unit, power.id)
    end,
})

function Power:getCache(params)
    if params.unit == nil or params.powerType == nil then
        return nil
    end
    local unitTable = self.units[params.unit]
    if unitTable then
        local power = unitTable.objects[params.powerType]
        if power then
            return power.data
        end
    end
    return nil
end

function Power:getObjectParams(unit, data)
    return {
        type = self.key,
        unit = unit.id,
        powerType = data.key,
    }
end

function Power:onUnitAdd(unit)
    unit.frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", unit.id)
    unit.frame:RegisterUnitEvent("UNIT_MAXPOWER", unit.id)
    unit.frame:SetScript("OnEvent", function(frame, event, target, powerType)
        if unit.guid ~= nil then
            self:onEvent(event, unit, powerType)
        end
    end)
end

function Power:onUnitChange(unit)
    if unit.guid == nil then
        return
    end
    for _, power in ipairs(powersDB.items) do
        local powerMax = UnitPowerMax(unit.id, power.id)
        if powerMax > 0 then
            local powerCurrent = UnitPower(unit.id, power.id)
            local data =
                { key = power.key, id = power.id, minimum = power.minimum, current = powerCurrent, maximum = powerMax }
            self:addObject(unit, power.key, data)
        end
    end
end

function Power:onEvent(event, unit, powerType)
    local key = strlower(powerType)
    local power = unit.objects[key]
    if power == nil then
        --should be impossible
        error("Unknown power type" .. powerType)
    end
    power = power.data
    if event == "UNIT_POWER_FREQUENT" then
        self:modifyObject(unit, key, { current = UnitPower(unit.id, power.id) })
    elseif event == "UNIT_MAXPOWER" then
        self:modifyObject(unit, key, { maximum = UnitPowerMax(unit.id, power.id) })
    end
end

Power:addField({
    key = "label",
    type = "String",
    label = L["Label"],
    get = function(params)
        if params.powerType then
            local powerType = powersDB:get(params.powerType)
            return powerType.label
        end
        local _, name = UnitPowerType(params.unit)
        return name
    end,
})

Power:registerTemplate({
    key = "default",
    name = "Default",
    format = "{current}/{maximum} {label}",
})
