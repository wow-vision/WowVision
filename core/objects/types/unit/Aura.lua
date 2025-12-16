local L = WowVision:getLocale()
local objects = WowVision.objects

local Aura = objects:createUnitType("Aura")

Aura:addParameter({
    type = "Number",
    key = "instanceID",
})

function Aura:validParams(params)
    if params.unit == nil then
        return false, false
    end
    return true, params.instanceID ~= nil
end

local function getAuraFromParams(params)
    local valid, unique = Aura:validParams(params)
    if not unique then
        return nil
    end
    return C_UnitAuras.GetAuraDataByAuraInstanceID(params.unit, params.instanceID)
end

local function forEachAuraFiltered(unit, filter, callback)
    local slots = { C_UnitAuras.GetAuraSlots(unit, filter) }
    for i = 2, #slots do
        local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        callback(aura)
    end
end

local function forEachAura(unit, callback)
    forEachAuraFiltered(unit, "HELPFUL", callback)
    forEachAuraFiltered(unit, "HARMFUL", callback)
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

function Aura:getObjectParams(unit, data)
    return {
        type = "Aura",
        unit = unit.id,
        instanceID = data.auraInstanceID,
    }
end

local function addAuraField(field)
    local auraKey = field.auraKey or field.key
    local compute = field.compute
    if not field.getCached then
        if compute ~= nil then
            field.getCached = function(cache)
                local value = cache[auraKey]
                if value ~= nil then
                    return compute(value)
                end
                return nil
            end
        else
            field.getCached = function(cache)
                return cache[auraKey]
            end
        end
    end

    if not field.get then
        if compute ~= nil then
            field.get = function(params)
                local aura = getAuraFromParams(params)
                if aura == nil then
                    return nil
                end
                local value = aura[auraKey]
                if value == nil then
                    return nil
                end
                return compute(value)
            end
        else
            field.get = function(params)
                local aura = getAuraFromParams(params)
                if aura == nil then
                    return nil
                end
                return aura[auraKey]
            end
        end
    end

    Aura:addField(field)
end

local function addAuraFields(fields)
    for _, field in ipairs(fields) do
        addAuraField(field)
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

local function fullUpdate(unit)
    local changes = {
        added = {},
        updated = {},
        removed = {},
    }
    forEachAura(unit.id, function(data)
        local instanceID = data.auraInstanceID
        if unit.objects[instanceID] == nil then
            changes.added[instanceID] = data
        else
            changes.updated[instanceID] = data
        end
    end)
    for id, _ in pairs(unit.objects) do
        if changes.added[id] == nil and changes.updated[id] == nil then
            changes.removed[id] = true
        end
    end
    for id, _ in pairs(changes.removed) do
        Aura:removeObject(unit, id)
    end
    for id, data in pairs(changes.updated) do
        Aura:modifyObject(unit, id, data)
    end
    for id, data in pairs(changes.added) do
        Aura:addObject(unit, id, data)
    end
end

function Aura:onUnitAdd(unit)
    unit.frame:RegisterUnitEvent("UNIT_AURA", unit.id)
    unit.frame:SetScript("OnEvent", function(frame, event, id, data)
        if unit.guid == nil then
            return
        end
        self:onEvent(event, unit, data)
    end)
end

function Aura:onUnitChange(unit)
    if unit.guid == nil then
        return
    end
    fullUpdate(unit)
end

function Aura:onEvent(event, unit, data)
    if event ~= "UNIT_AURA" then
        return
    end
    if data.isFullUpdate then
        fullUpdate(unit)
        return
    end
    if data.addedAuras then
        for _, aura in pairs(data.addedAuras) do
            self:addObject(unit, aura.auraInstanceID, aura)
        end
    end
    if data.updatedAuraInstanceIDs then
        for _, id in pairs(data.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit.id, id)
            if aura == nil then
                error("This should be impossible, nil aura in UNIT_AURA update event.")
            end
            self:modifyObject(unit, id, aura)
        end
    end
    if data.removedAuraInstanceIDs then
        for _, id in pairs(data.removedAuraInstanceIDs) do
            self:removeObject(unit, id)
        end
    end
end

function Aura:getFocusString(params)
    return self:renderTemplate("{name} stacks {applications}", params)
end
