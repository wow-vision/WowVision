local L = WowVision:getLocale()
local objects = WowVision.objects

local Aura = objects:createUnitType("Aura")

function Aura:validParams(params)
    if params.unit == nil then
        return false, false
    end
    return true, params.instanceID ~= nil
end

local function getAuraFromParams(params)
    local valid, unique = self:validParams(params)
    if not unique then
        return nil
    end
    return C_UnitAuras.GetAuraDataByAuraInstanceID(params.unit, params.instanceID)
end

function Aura:getCache(params)
    local valid, unique = self:validParams(params)
    if not unique then
        return nil
    end
    local unitTable = self.units[params.unit]
    if unitTable == nil then
        return nil
    end
    local obj = unitTable.objects[params.instanceID]
    if obj == nil then
        return nil
    end
    return obj.data
end

local function addAuraField(field)
    if field.auraKey == nil then
        field.auraKey = field.key
    end

    if field.getCached == nil then
        field.getCached = function(cache)
            return cache[field.auraKey]
        end
    else
        local getFunc = field.getCached
        field.getCached = function(cache)
            return getFunc(cache)
        end
    end

    field.get = function(params)
        local aura = getAuraFromParams(params)
        if aura then
            return aura[field.auraKey]
        end
        return nil
    end

    Aura:addField(field)
end

local function addAuraFields(fields)
    for _, field in ipairs(fields) do
        addAuraField(unpack(field))
    end
end

addAuraFields({
    { key = "applications" },
    { key = "auraInstanceID" },
    { key = "canApplyAura" },
    { key = "charges" },
    { key = "dispelName" },
    { key = "duration" },
    { key = "expirationTime" },
    { key = "icon" },
    { key = "isBossAura" },
    { key = "isFromPlayerOrPlayerPet" },
    { key = "isHarmful" },
    { key = "isHelpful" },
    { key = "isNameplateOnly" },
    { key = "isRaid" },
    { key = "isStealable" },
    { key = "maxCharges" },
    { key = "name" },
    { key = "nameplateShowAll" },
    { key = "nameplateShowPersonal" },
    { key = "points" },
    { key = "sourceUnit" },
    { key = "spellId" },
    { key = "timeMod" },
})
