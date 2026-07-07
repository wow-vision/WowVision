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
-- db form, plus the type stamp. The old info:getData equivalent.
local function instanceToConfig(field, instance)
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
