-- Complex field types for the class library (core/Class.lua): the component
-- array. Loads right after Class.lua; depends on nothing else.
--
-- A ComponentArray field holds an array of class INSTANCES built by a
-- factory from plain config tables; it persists as configs stamped with a
-- .type key. The api methods keep the OLD ComponentArrayField calling
-- convention (field:addElement(obj, x), ...) so the graph field controls
-- work unchanged.
--
-- def keys: factory(config) -> instance, getTypeKey(instance) -> string,
--           availableTypes = list|function

local void, WowVisionNamespace = ...
local classes = WowVisionNamespace.classes

-- Instance storage works for class instances (managed _values) and plain
-- containers (the value sits at obj[key]) alike.
local function setStored(field, obj, instances)
    local values = rawget(obj, "_values")
    if values ~= nil then
        values[field.key] = instances
    else
        rawset(obj, field.key, instances)
    end
end

-- One instance -> one persistable config: every field's current value in
-- db form. The old info:getData equivalent, exposed for default builders.
local function instanceConfig(instance)
    local config = {}
    for _, instanceField in ipairs(instance.class:getFields()) do
        local value = instanceField:get(instance)
        if type(value) ~= "function" and value ~= nil then
            if instanceField.fieldType.toDB ~= nil then
                config[instanceField.key] = instanceField.fieldType.toDB(instanceField, instance, value)
            elseif type(value) ~= "table" or value.class == nil then
                config[instanceField.key] = classes.deepCopy(value)
            end
        end
    end
    return config
end
classes.instanceConfig = instanceConfig

-- The component-array flavor adds the type stamp.
local function instanceToConfig(field, instance)
    local config = instanceConfig(instance)
    config.type = field.getTypeKey(instance)
    return config
end

local function instancesToConfigs(field, instances)
    local result = { _type = "array" }
    for _, instance in ipairs(instances or {}) do
        tinsert(result, instanceToConfig(field, instance))
    end
    return result
end

-- The store side this array lives in, honoring the field's own scope.
local function arrayStore(field, pair)
    return classes.resolveStore(field, classes.constrainPair(field, pair))
end

classes.registerFieldType("ComponentArray", {
    -- Assignment accepts instances or configs; configs go through the factory.
    validate = function(field, value)
        if value == nil then
            return {}
        end
        local instances = {}
        for _, item in ipairs(value) do
            if type(item) == "table" and item.class ~= nil then
                tinsert(instances, item)
            else
                tinsert(instances, field.factory(item))
            end
        end
        return instances
    end,

    toDB = function(field, obj, value)
        return instancesToConfigs(field, value)
    end,

    -- Restore: build instances from the stored configs, binding each to its
    -- config entry so instance field writes persist in place.
    setDB = function(field, obj, pair)
        local constrained = classes.constrainPair(field, pair)
        local store = classes.resolveStore(field, constrained)
        if store == nil then
            return
        end
        if store[field.key] == nil then
            store[field.key] = { _type = "array" }
        end
        local base = classes.subPair(constrained, field.key)
        local instances = {}
        for index, config in ipairs(store[field.key]) do
            local instance = field.factory(config)
            instance:setDB(classes.subPair(base, index))
            tinsert(instances, instance)
        end
        setStored(field, obj, instances)
    end,

    getDefaultDB = function(field, obj, scope, forcedChar)
        -- Arrays start empty; existing instances persist through toDB.
        return { _type = "array" }
    end,

    api = {
        getAvailableTypes = function(field)
            if type(field.availableTypes) == "function" then
                return field.availableTypes()
            end
            return field.availableTypes or {}
        end,

        getTypeLabel = function(field, typeEntry)
            if type(typeEntry) == "table" then
                return typeEntry.label or typeEntry.key
            end
            return typeEntry
        end,

        getTypeKeyFromEntry = function(field, typeEntry)
            if type(typeEntry) == "table" then
                return typeEntry.key
            end
            return typeEntry
        end,

        getLength = function(field, obj)
            local instances = field:get(obj)
            return instances ~= nil and #instances or 0
        end,

        addElement = function(field, obj, instanceOrConfig)
            local instance
            if type(instanceOrConfig) == "table" and instanceOrConfig.class ~= nil then
                instance = instanceOrConfig
            else
                instance = field.factory(instanceOrConfig)
            end
            local instances = field:get(obj) or {}
            tinsert(instances, instance)
            setStored(field, obj, instances)

            local pair = rawget(obj, "_db")
            if pair ~= nil then
                local constrained = classes.constrainPair(field, pair)
                local store = classes.resolveStore(field, constrained)
                if store ~= nil then
                    if store[field.key] == nil then
                        store[field.key] = { _type = "array" }
                    end
                    tinsert(store[field.key], instanceToConfig(field, instance))
                    local base = classes.subPair(constrained, field.key)
                    instance:setDB(classes.subPair(base, #store[field.key]))
                end
            end
            field.events.valueChange:emit(obj, field.key, instances)
            return #instances
        end,

        removeElement = function(field, obj, index)
            local instances = field:get(obj)
            if instances == nil or instances[index] == nil then
                return nil
            end
            local removed = tremove(instances, index)
            local pair = rawget(obj, "_db")
            if pair ~= nil then
                local store = arrayStore(field, pair)
                if store ~= nil and store[field.key] ~= nil then
                    tremove(store[field.key], index)
                end
                -- Later instances' db entries shifted down: rebind them.
                local constrained = classes.constrainPair(field, pair)
                local base = classes.subPair(constrained, field.key)
                for i = index, #instances do
                    instances[i]:setDB(classes.subPair(base, i))
                end
            end
            field.events.valueChange:emit(obj, field.key, instances)
            return removed
        end,
    },
})

-- ---------------------------------------------------------------------------
-- TrackingConfig: an object-tracking configuration table, e.g.
-- { type = "Health", units = { "player" } } or { type = "Cooldown",
-- params = { ... } }. def key: requireUnique (read by the graph control).
-- ---------------------------------------------------------------------------

classes.registerFieldType("TrackingConfig", {
    default = function(field, obj)
        return { type = nil }
    end,

    validate = function(field, value)
        if value == nil or type(value) ~= "table" then
            return { type = nil }
        end
        if value.class ~= nil then
            return value -- an Object instance passes through directly
        end
        local result = {}
        for k, v in pairs(value) do
            result[k] = v
        end
        return result
    end,

    toDB = function(field, obj, value)
        return classes.deepCopy(value)
    end,

    fromDB = function(field, obj, dbValue)
        return classes.deepCopy(dbValue)
    end,

    valueString = function(field, obj, value)
        local L = WowVision:getLocale()
        if value == nil or value.type == nil then
            return L["None"]
        end
        local objectType = WowVision.objects.types:get(value.type)
        if objectType ~= nil then
            if value.units ~= nil and #value.units > 0 then
                return (objectType.label or value.type) .. " (" .. table.concat(value.units, ", ") .. ")"
            end
            return objectType.label or value.type
        end
        return value.type
    end,

    api = {
        -- Change the tracked type, resetting the config to that type's
        -- scaffolding (fresh params; unit-based types track the player).
        setType = function(field, obj, typeKey)
            local oldValue = field:get(obj)
            if oldValue ~= nil and oldValue.type == typeKey then
                return false
            end
            local value = { type = typeKey }
            if typeKey ~= nil then
                local objectType = WowVision.objects.types:get(typeKey)
                if objectType ~= nil then
                    value.params = {}
                    if objectType:isInstanceOf(WowVision.objects.UnitType) then
                        value.unit = "player"
                        value.units = { "player" }
                    end
                    if objectType.parameters ~= nil then
                        for _, paramField in ipairs(objectType.parameters.fields) do
                            if value.params[paramField.key] == nil then
                                local default = paramField:getDefault(value.params)
                                if default ~= nil then
                                    value.params[paramField.key] = default
                                end
                            end
                        end
                    end
                end
            end
            return field:set(obj, value)
        end,
    },
})

-- ---------------------------------------------------------------------------
-- Template: nil (use default), { key = "templateKey" }, or
-- { format = "custom string" }. def key: getTemplates(obj) -> registry.
-- ---------------------------------------------------------------------------

classes.registerFieldType("Template", {
    validate = function(field, value)
        if value == nil or type(value) ~= "table" then
            return nil
        end
        if value.format ~= nil then
            return { format = value.format }
        end
        if value.key ~= nil then
            return { key = value.key }
        end
        return nil
    end,

    valueString = function(field, obj, value)
        local L = WowVision:getLocale()
        if value == nil then
            return L["Default"]
        end
        if value.format ~= nil then
            return L["Custom"]
        end
        if value.key ~= nil then
            local templates = field:getAvailableTemplates(obj)
            if templates ~= nil then
                local template = templates:get(value.key)
                if template ~= nil then
                    return template.name
                end
            end
            return value.key
        end
        return L["Default"]
    end,

    api = {
        getAvailableTemplates = function(field, obj)
            if field.getTemplates ~= nil then
                return field.getTemplates(obj)
            end
            return nil
        end,

        -- The renderable format string or Template instance, nil for default.
        resolve = function(field, obj)
            local value = field:get(obj)
            if value == nil then
                return nil
            end
            if value.format ~= nil then
                return value.format
            end
            if value.key ~= nil then
                local templates = field:getAvailableTemplates(obj)
                if templates ~= nil then
                    return templates:get(value.key)
                end
            end
            return nil
        end,
    },
})

-- ---------------------------------------------------------------------------
-- Alert: the value is a live Alert instance created lazily from the def's
-- alert/outputs config; its whole state (enabled plus outputs) persists as
-- one nested table managed by the Alert's own setDB.
-- def keys: alert = { key?, label? }, outputs = { {type=..., key=...}, ... }
-- ---------------------------------------------------------------------------

local function getAlertFor(field, obj)
    local values = rawget(obj, "_values")
    local storage = values ~= nil and values or obj
    local alert = storage[field.key]
    if alert == nil or alert.class == nil then
        local alertConfig = field.alert or {}
        alert = WowVision.alerts.Alert:new({
            key = alertConfig.key or field.key,
            label = alertConfig.label or field:getLabel(),
        })
        for _, outputConfig in ipairs(field.outputs or {}) do
            alert:addOutput(outputConfig)
        end
        storage[field.key] = alert
    end
    return alert
end

classes.registerFieldType("Alert", {
    -- Assignment takes a db-shaped table and applies it to the alert.
    validate = function(field, value)
        return value
    end,

    toDB = function(field, obj, value)
        local alert = getAlertFor(field, obj)
        if alert.db ~= nil then
            return classes.deepCopy(alert.db)
        end
        return alert:getDefaultDBRecursive()
    end,

    setDB = function(field, obj, pair)
        local store = classes.resolveStore(field, classes.constrainPair(field, pair))
        if store == nil then
            return
        end
        local alert = getAlertFor(field, obj)
        if store[field.key] == nil then
            store[field.key] = alert:getDefaultDBRecursive()
        end
        alert:setDB(store[field.key])
    end,

    getDefaultDB = function(field, obj, scope, forcedChar)
        return getAlertFor(field, obj):getDefaultDBRecursive()
    end,

    api = {
        getAlert = getAlertFor,
    },
})

-- ---------------------------------------------------------------------------
-- Spell: a spell id, accepting a spell name and resolving it. WoW API calls
-- happen only at set/speak time, so this loads headless.
-- ---------------------------------------------------------------------------

local function spellName(spellID)
    if spellID == nil then
        return nil
    end
    if GetSpellInfo ~= nil then
        return (GetSpellInfo(spellID))
    end
    if C_Spell ~= nil and C_Spell.GetSpellInfo ~= nil then
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        return spellInfo ~= nil and spellInfo.name or nil
    end
    return nil
end

local function spellIDByName(name)
    if name == nil or name == "" then
        return nil
    end
    if GetSpellInfo ~= nil then
        local found, _, _, _, _, _, id = GetSpellInfo(name)
        if found ~= nil then
            return id
        end
        return nil
    end
    if C_Spell ~= nil and C_Spell.GetSpellInfo ~= nil then
        local spellInfo = C_Spell.GetSpellInfo(name)
        return spellInfo ~= nil and spellInfo.spellID or nil
    end
    return nil
end

classes.registerFieldType("Spell", {
    validate = function(field, value)
        if value == nil then
            return nil
        end
        local number = tonumber(value)
        if number ~= nil then
            return number
        end
        return spellIDByName(value)
    end,

    valueString = function(field, obj, value)
        if value == nil then
            return nil
        end
        local name = spellName(value)
        if name ~= nil then
            return name .. " (" .. value .. ")"
        end
        return tostring(value)
    end,
})

-- ---------------------------------------------------------------------------
-- Category: an organizational settings sub-screen. Holds child fields (def
-- key `fields`) over a nested table aliased into the db, plus refs to
-- InfoFrame parameter trees (alert params) added via field:addRef. The
-- nested table persists BY REFERENCE, so child writes flow to the db
-- without copying.
-- ---------------------------------------------------------------------------

classes.registerFieldType("Category", {
    validate = function(field, value)
        if value == nil or type(value) ~= "table" then
            return {}
        end
        return value
    end,

    default = function(field, obj)
        local result = {}
        for _, subField in ipairs(field:getSubFields()) do
            local default = subField:getDefault(result)
            if default ~= nil then
                result[subField.key] = default
            end
        end
        return result
    end,

    api = {
        addRef = function(field, key, target)
            if field.refs == nil then
                field.refs = {}
            end
            tinsert(field.refs, { key = key, target = target })
        end,

        getSubFields = function(field)
            if field._subFields == nil then
                field._subFields = {}
                for _, def in ipairs(field.fields or {}) do
                    tinsert(field._subFields, classes.newField(def))
                end
            end
            return field._subFields
        end,

        addField = function(field, def)
            field.fields = field.fields or {}
            tinsert(field.fields, def)
            field._subFields = nil
            return field
        end,

        addFields = function(field, defs)
            for _, def in ipairs(defs) do
                field:addField(def)
            end
            return field
        end,
    },
})
