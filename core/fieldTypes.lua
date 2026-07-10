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

-- Find and remove an instance's bound config table from whichever side's
-- array holds it (identity match through the instance's own db pair).
local function removeConfigOf(field, pair, instance)
    local bound = rawget(instance, "_db")
    local config = bound ~= nil and (bound.char or bound.global) or nil
    if config == nil then
        return nil
    end
    local constrained = classes.constrainPair(field, pair)
    for _, side in ipairs({ "global", "char" }) do
        local store = constrained[side]
        if store ~= nil and store[field.key] ~= nil then
            for i, entry in ipairs(store[field.key]) do
                if entry == config then
                    tremove(store[field.key], i)
                    return config
                end
            end
        end
    end
    return config
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

    -- Restore: build instances from BOTH stores (account first, then
    -- character), binding each to its config table -- bindings hold the
    -- table itself, so array positions never matter after this.
    setDB = function(field, obj, pair)
        local constrained = classes.constrainPair(field, pair)
        local instances = {}
        for _, side in ipairs({ "global", "char" }) do
            local store = constrained[side]
            if store ~= nil then
                if store[field.key] == nil then
                    store[field.key] = { _type = "array" }
                end
                for _, config in ipairs(store[field.key]) do
                    local instance = field.factory(config)
                    instance:setDB({ [side] = config })
                    rawset(instance, "_scopeSide", side)
                    tinsert(instances, instance)
                end
            end
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
                -- New components follow the field scope: account-wide by
                -- default, character when that side is all there is.
                local side = "char"
                if field.global ~= false and constrained.global ~= nil then
                    side = "global"
                elseif constrained.char == nil and constrained.global ~= nil then
                    side = "global"
                end
                local store = constrained[side]
                if store ~= nil then
                    if store[field.key] == nil then
                        store[field.key] = { _type = "array" }
                    end
                    local config = instanceToConfig(field, instance)
                    tinsert(store[field.key], config)
                    instance:setDB({ [side] = config })
                    rawset(instance, "_scopeSide", side)
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
                removeConfigOf(field, pair, removed)
            end
            field.events.valueChange:emit(obj, field.key, instances)
            return removed
        end,

        -- The store side an instance lives in.
        scopeOf = function(field, instance)
            return rawget(instance, "_scopeSide") or "char"
        end,

        -- Move one component between stores: its config table leaves the
        -- source array, joins the target, and the instance rebinds to the
        -- same table on its new side. Values are untouched.
        setComponentScope = function(field, obj, instance, scope)
            local side = scope == "global" and "global" or "char"
            if (rawget(instance, "_scopeSide") or "char") == side then
                return false
            end
            local pair = rawget(obj, "_db")
            if pair == nil then
                return false
            end
            local constrained = classes.constrainPair(field, pair)
            local target = constrained[side]
            if target == nil then
                return false
            end
            local config = removeConfigOf(field, pair, instance)
            if config == nil then
                config = instanceToConfig(field, instance)
            end
            if target[field.key] == nil then
                target[field.key] = { _type = "array" }
            end
            tinsert(target[field.key], config)
            instance:setDB({ [side] = config })
            rawset(instance, "_scopeSide", side)
            field.events.valueChange:emit(obj, field.key, field:get(obj))
            return true
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


-- ---------------------------------------------------------------------------
-- Time: a number spoken as a duration ("1 hour 5 seconds") or a timestamp.
-- def key: timeType = "duration" (default) | "timestamp".
-- ---------------------------------------------------------------------------

local function formatDuration(seconds)
    if seconds == nil then
        return nil
    end
    local L = WowVision:getLocale()
    seconds = math.floor(seconds)
    if seconds < 0 then
        seconds = 0
    end
    local days = math.floor(seconds / 86400)
    seconds = seconds - days * 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds - hours * 3600
    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60
    local parts = {}
    if days > 0 then
        tinsert(parts, days .. " " .. (days == 1 and L["day"] or L["days"]))
    end
    if hours > 0 then
        tinsert(parts, hours .. " " .. (hours == 1 and L["hour"] or L["hours"]))
    end
    if minutes > 0 then
        tinsert(parts, minutes .. " " .. (minutes == 1 and L["minute"] or L["minutes"]))
    end
    if seconds > 0 or #parts == 0 then
        tinsert(parts, seconds .. " " .. (seconds == 1 and L["second"] or L["seconds"]))
    end
    return table.concat(parts, " ")
end

local function formatTime(field, value)
    if value == nil then
        return nil
    end
    if field.timeType == "timestamp" then
        return date("%B %d, %Y %I:%M %p", value)
    end
    return formatDuration(value)
end

classes.registerFieldType("Time", {
    validate = classes.fieldTypes.Number.validate,
    valueString = function(field, obj, value)
        return formatTime(field, value)
    end,
    api = {
        formatTime = function(field, value)
            return formatTime(field, value)
        end,
        -- Template context builders format raw values through this.
        formatForDisplay = function(field, value)
            return formatTime(field, value)
        end,
    },
})

-- ---------------------------------------------------------------------------
-- VoicePack: a voice pack key, spoken as the pack label.
-- ---------------------------------------------------------------------------

classes.registerFieldType("VoicePack", {
    valueString = function(field, obj, value)
        if value ~= nil then
            local voicePacks = WowVision.audio.packs:get("Voice")
            local pack = voicePacks.packs:get(value)
            if pack ~= nil then
                return pack:getLabel()
            end
        end
        return nil
    end,
})

-- ---------------------------------------------------------------------------
-- DataBrowse: a path into a data directory (sound picker, beacon picker).
-- def key: directory = DataDirectory | function(obj) -> DataDirectory.
-- ---------------------------------------------------------------------------

classes.registerFieldType("DataBrowse", {
    valueString = function(field, obj, value)
        if value == nil then
            return nil
        end
        local directory = field:getDirectory(obj)
        if directory ~= nil then
            local source = directory:getPath(value)
            if source ~= nil and source.getLabel ~= nil then
                return source:getLabel()
            end
        end
        return tostring(value)
    end,
    api = {
        getDirectory = function(field, obj)
            if type(field.directory) == "function" then
                return field.directory(obj)
            end
            return field.directory
        end,
    },
})

-- ---------------------------------------------------------------------------
-- Array: a list of scalar elements, each validated by an element field.
-- def key: elementField = a field definition table (key defaults to
-- _element). The api mirrors the old ArrayField the graph control uses.
-- ---------------------------------------------------------------------------

local function arrayStorageOf(field, obj)
    local values = rawget(obj, "_values")
    return values ~= nil and values or obj
end

local function arrayOf(field, obj, create)
    local holder = arrayStorageOf(field, obj)
    local arr = holder[field.key]
    if arr == nil and create then
        arr = {}
        holder[field.key] = arr
    end
    return arr
end

local function arrayChanged(field, obj)
    local arr = arrayOf(field, obj)
    if field.persist and obj.db ~= nil then
        local dbArr = {}
        for i, v in ipairs(arr or {}) do
            dbArr[i] = v
        end
        obj.db[field.key] = dbArr
    end
    field.events.valueChange:emit(obj, field.key, arr)
end

classes.registerFieldType("Array", {
    default = function(field, obj)
        return {}
    end,

    valueString = function(field, obj, value)
        if value == nil then
            return "0 items"
        end
        return #value .. " items"
    end,

    api = {
        getElementField = function(field)
            if field._elementField == nil then
                local def = {}
                for k, v in pairs(field.elementField or {}) do
                    def[k] = v
                end
                def.key = def.key or "_element"
                field._elementField = classes.newField(def)
            end
            return field._elementField
        end,

        validateElement = function(field, value)
            local elementField = field:getElementField()
            if elementField.validate ~= nil then
                return elementField.validate(elementField, value)
            end
            if elementField.fieldType.validate ~= nil then
                return elementField.fieldType.validate(elementField, value)
            end
            return value
        end,

        -- Index-aware get/set, matching the old ArrayField the element
        -- proxies rely on.
        get = function(field, obj, index)
            local arr = arrayOf(field, obj)
            if index ~= nil then
                return arr ~= nil and arr[index] or nil
            end
            return arr
        end,

        set = function(field, obj, value, index)
            if index ~= nil then
                local arr = arrayOf(field, obj, true)
                arr[index] = field:validateElement(value)
            else
                local holder = arrayStorageOf(field, obj)
                if value ~= nil then
                    local validated = {}
                    for i, v in ipairs(value) do
                        validated[i] = field:validateElement(v)
                    end
                    holder[field.key] = validated
                else
                    holder[field.key] = {}
                end
            end
            arrayChanged(field, obj)
        end,

        setDB = function(field, obj, pair)
            local store = classes.resolveStore(field, classes.constrainPair(field, pair))
            local arr = store ~= nil and store[field.key] or nil
            field:set(obj, arr or {})
        end,

        addElement = function(field, obj, value)
            local arr = arrayOf(field, obj, true)
            tinsert(arr, field:validateElement(value))
            arrayChanged(field, obj)
            return #arr
        end,

        removeElement = function(field, obj, index)
            local arr = arrayOf(field, obj)
            if arr ~= nil and arr[index] ~= nil then
                local removed = tremove(arr, index)
                arrayChanged(field, obj)
                return removed
            end
            return nil
        end,

        getLength = function(field, obj)
            local arr = arrayOf(field, obj)
            return arr ~= nil and #arr or 0
        end,

        createElementProxy = function(field, obj, index)
            local elementKey = field:getElementField().key
            return setmetatable({}, {
                __index = function(t, k)
                    if k == elementKey then
                        return field:get(obj, index)
                    end
                end,
                __newindex = function(t, k, v)
                    if k == elementKey then
                        field:set(obj, v, index)
                    end
                end,
            })
        end,
    },
})


-- ---------------------------------------------------------------------------
-- FieldSet: a standalone, self-owned collection of fields -- the InfoFrame
-- and standalone-InfoManager replacement (alert/output parameters, object
-- type parameters). The set IS the value owner: field values live on it and
-- restore from a single db node. `set.info = set` keeps the old render
-- surface (renderers read owner.info.fields and owner.children).
-- ---------------------------------------------------------------------------

local FieldSet = {}
local fieldSetMeta = { __index = FieldSet }

function classes.newFieldSet(config)
    config = config or {}
    local set = setmetatable({
        key = config.key,
        label = config.label,
        fields = {},
        children = {},
    }, fieldSetMeta)
    set.info = set
    return set
end

function FieldSet:add(def)
    if def.persist == nil then
        def.persist = true
    end
    local field = classes.newField(def)
    field._set = self -- bound operations (field:toggle()) default to the set
    tinsert(self.fields, field)
    self.fields[field.key] = field
    return field
end

FieldSet.addField = FieldSet.add

function FieldSet:addFields(defs)
    local result = {}
    for _, def in ipairs(defs) do
        tinsert(result, self:add(def))
    end
    return result
end

function FieldSet:getField(key)
    return self.fields[key]
end

-- The old InfoFrame:get returned the field object; keep that.
FieldSet.get = FieldSet.getField

function FieldSet:addRef(key, target)
    tinsert(self.children, { key = key, label = target.label, ref = true, target = target })
end

-- Both calling conventions: (key) reads this set's own value;
-- (obj, key) reads through the schema on an external object.
function FieldSet:getFieldValue(a, b)
    local obj, key = self, a
    if b ~= nil then
        obj, key = a, b
    end
    local field = self.fields[key]
    if field == nil then
        return nil
    end
    return field:get(obj)
end

function FieldSet:setFieldValue(a, b, c)
    local obj, key, value = self, a, b
    if c ~= nil or (b ~= nil and self.fields[a] == nil) then
        obj, key, value = a, b, c
    end
    local field = self.fields[key]
    if field ~= nil then
        field:set(obj, value)
    end
end

-- Apply a config table onto an external object through the schema:
-- validation, defaults, and required checks (the old InfoManager:set).
function FieldSet:applyTo(obj, config, ignoreRequired)
    config = config or {}
    for _, field in ipairs(self.fields) do
        local value = config[field.key]
        if value == nil then
            value = field:getDefault(obj)
        end
        if value ~= nil then
            field:set(obj, value)
        elseif field.required and not ignoreRequired then
            error("Field " .. field.key .. " must have a value")
        end
    end
    return obj
end

function FieldSet:getDefaultDB()
    local result = {}
    for _, field in ipairs(self.fields) do
        if field.persist then
            local default = field:getDefault(self)
            if field.fieldType.toDB ~= nil and default ~= nil then
                result[field.key] = field.fieldType.toDB(field, self, default)
            else
                result[field.key] = default
            end
        end
    end
    return result
end

function FieldSet:setDB(db)
    for _, field in ipairs(self.fields) do
        if field.persist then
            field:setDB(self, db)
        end
    end
    self.db = db
end
