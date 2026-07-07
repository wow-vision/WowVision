-- The WowVision class library: classes with native FIELDS and DB persistence.
-- Replaces middleclass + InfoClass (see docs/src/developer/class-system.md).
--
-- Design rules (do not break these):
-- * All metatable magic lives HERE and only here. Downstream code is plain
--   Lua: `obj.enabled = false` validates, stores, persists, and emits.
-- * Field declarations live in module-local maps keyed by class, NEVER on
--   class tables -- a child declaring fields cannot touch its parent.
-- * Field definition objects are STABLE: subscribers attach to
--   Class:getField(key).events and must survive schema recomputes.
-- * A db "pair" is { char = node?, global = node? }. A field's `global` flag
--   (DEFAULT TRUE) picks the side; a missing side falls back to the other,
--   which structurally enforces "character containers force character
--   children" -- a char-only pair can never reach the global store.
--
-- Class creation:  local My = WowVision.Class("My", Parent)
-- Fields:          My:addFields({ { key = "enabled", type = "Bool",
--                      default = true, persist = true, global = false } })
-- Instances:       local obj = My:new(...)   -- calls My.initialize(obj, ...)
-- DB:              obj:setDB({ char = node, global = node })
--
-- This file loads before everything else (including the WowVision global),
-- so it publishes through the addon namespace and depends on nothing.

local void, WowVisionNamespace = ...

local classes = {
    debug = false, -- true: warn on scope misdeclarations and similar
}
WowVisionNamespace.classes = classes

local function warn(message)
    if classes.debug then
        print("WowVision class warning: " .. message)
    end
end

-- ---------------------------------------------------------------------------
-- Small pure helpers
-- ---------------------------------------------------------------------------

local function deepEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    for k, v in pairs(a) do
        if not deepEqual(v, b[k]) then
            return false
        end
    end
    for k in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    if value.class ~= nil then
        return value -- never copy class instances
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deepCopy(v)
    end
    return copy
end

classes.deepEqual = deepEqual
classes.deepCopy = deepCopy

-- A minimal event with the same contract as WowVision.Event (this file loads
-- before core/Event.lua, so it carries its own): handlers subscribed with a
-- subscriber receive (subscriber, eventName, ...), bare handlers (eventName, ...).
local EventAPI = {}
local eventMeta = { __index = EventAPI }

function classes.newEvent(name)
    return setmetatable({ name = name, subscribers = {}, handlers = {} }, eventMeta)
end

function EventAPI:subscribe(subscriber, handler)
    if subscriber == nil then
        tinsert(self.handlers, handler)
        return
    end
    if self.subscribers[subscriber] == nil then
        self.subscribers[subscriber] = { handler }
        return
    end
    tinsert(self.subscribers[subscriber], handler)
end

function EventAPI:unsubscribe(subscriber)
    self.subscribers[subscriber] = nil
end

function EventAPI:emit(...)
    for subscriber, handlers in pairs(self.subscribers) do
        local handlerList = {}
        for _, handler in ipairs(handlers) do
            tinsert(handlerList, handler)
        end
        for _, handler in ipairs(handlerList) do
            handler(subscriber, self.name, ...)
        end
    end
    local handlerList = {}
    for _, handler in ipairs(self.handlers) do
        tinsert(handlerList, handler)
    end
    for _, handler in ipairs(handlerList) do
        handler(self.name, ...)
    end
end

-- ---------------------------------------------------------------------------
-- Field types: a plain registry. A type is a table of optional functions:
--   validate(field, value) -> value          (error() to reject)
--   toDB(field, obj, value) -> dbValue       (runtime -> persisted; default identity)
--   fromDB(field, obj, dbValue, pair) -> value
--   setDB(field, obj, pair)                  (containers take over restore wholesale)
--   getDefaultDB(field, obj, scope, forcedChar) -> dbValue (containers recurse)
--   control(field, owner)                    (graph settings control; wired later)
-- ---------------------------------------------------------------------------

local fieldTypes = {}
classes.fieldTypes = fieldTypes

function classes.registerFieldType(key, fieldType)
    fieldTypes[key] = fieldType
    return fieldType
end

classes.registerFieldType("Generic", {})

classes.registerFieldType("Bool", {
    validate = function(field, value)
        if value == nil then
            return nil
        end
        return value == true
    end,
})

classes.registerFieldType("String", {
    validate = function(field, value)
        if value == nil then
            return nil
        end
        if type(value) ~= "string" then
            return tostring(value)
        end
        return value
    end,
})

classes.registerFieldType("Number", {
    validate = function(field, value)
        if value == nil then
            return nil
        end
        local number = tonumber(value)
        if number == nil then
            error("Field " .. field.key .. " requires a number, got " .. tostring(value))
        end
        if field.min ~= nil and number < field.min then
            number = field.min
        end
        if field.max ~= nil and number > field.max then
            number = field.max
        end
        return number
    end,
})

classes.registerFieldType("Choice", {
    validate = function(field, value)
        if value == nil then
            return nil
        end
        local choices = field.choices
        if type(choices) == "function" then
            return value -- dynamic choices validate at UI level
        end
        for _, choice in ipairs(choices or {}) do
            local allowed = type(choice) == "table" and choice.value or choice
            if allowed == value then
                return value
            end
        end
        error("Field " .. field.key .. " does not allow value " .. tostring(value))
    end,
})

-- A nested plain table stored and persisted whole (assignment replaces it).
classes.registerFieldType("Table", {
    validate = function(field, value)
        if value == nil then
            return nil
        end
        if type(value) ~= "table" then
            error("Field " .. field.key .. " requires a table")
        end
        return value
    end,
    toDB = function(field, obj, value)
        return deepCopy(value)
    end,
    fromDB = function(field, obj, dbValue)
        return deepCopy(dbValue)
    end,
})

-- ---------------------------------------------------------------------------
-- DB pairs
-- ---------------------------------------------------------------------------

-- The side a field persists to: its global flag (DEFAULT GLOBAL) when that
-- side exists, else whichever side does. Char-only pairs therefore force
-- every descendant to char -- the nesting rule, enforced structurally.
local function resolveStore(field, pair)
    local wantsGlobal = field.global ~= false
    if wantsGlobal then
        if pair.global ~= nil then
            return pair.global
        end
        if pair.char ~= nil then
            warn("global field " .. field.key .. " persisted to a character-only pair")
        end
        return pair.char
    end
    if pair.char ~= nil then
        return pair.char
    end
    if pair.global ~= nil then
        warn("character field " .. field.key .. " persisted to a global-only pair")
    end
    return pair.global
end
classes.resolveStore = resolveStore

-- A container field's own scope constrains the pair before descending: a
-- character-scoped container drops the global side entirely, so nothing
-- beneath it can ever reach the global store (the nesting rule).
local function constrainPair(field, pair)
    if field.global == false then
        if pair.char ~= nil then
            return { char = pair.char }
        end
        warn("character container " .. field.key .. " descending a global-only pair")
        return { char = pair.global }
    end
    return pair
end
classes.constrainPair = constrainPair

-- Descend one key into both sides of a pair, creating tables on sides that
-- exist (children must be able to persist). Missing sides stay missing.
local function subPair(pair, key)
    local sub = {}
    if pair.char ~= nil then
        if pair.char[key] == nil then
            pair.char[key] = {}
        end
        sub.char = pair.char[key]
    end
    if pair.global ~= nil then
        if pair.global[key] == nil then
            pair.global[key] = {}
        end
        sub.global = pair.global[key]
    end
    return sub
end
classes.subPair = subPair

-- ---------------------------------------------------------------------------
-- Container field types: children are class INSTANCES; setDB recurses with
-- threaded sub-pairs. `Dict` is keyed (Module.submodules), `InstanceArray`
-- is indexed. Both leave child creation to the owning code.
-- ---------------------------------------------------------------------------

local function childrenOf(field, obj)
    return obj[field.key]
end

classes.registerFieldType("Dict", {
    setDB = function(field, obj, pair)
        local base = subPair(constrainPair(field, pair), field.key)
        for key, child in pairs(childrenOf(field, obj) or {}) do
            child:setDB(subPair(base, key))
        end
    end,
    getDefaultDB = function(field, obj, scope, forcedChar)
        local result = {}
        for key, child in pairs(childrenOf(field, obj) or {}) do
            result[key] = child:getDefaultDB(scope, forcedChar)
        end
        return result
    end,
})

classes.registerFieldType("InstanceArray", {
    setDB = function(field, obj, pair)
        local base = subPair(constrainPair(field, pair), field.key)
        for index, child in ipairs(childrenOf(field, obj) or {}) do
            child:setDB(subPair(base, index))
        end
    end,
    getDefaultDB = function(field, obj, scope, forcedChar)
        local result = { _type = "array" }
        for _, child in ipairs(childrenOf(field, obj) or {}) do
            tinsert(result, child:getDefaultDB(scope, forcedChar))
        end
        return result
    end,
})

-- ---------------------------------------------------------------------------
-- Field definition objects
-- ---------------------------------------------------------------------------

local FieldAPI = {}
local fieldMeta = { __index = FieldAPI }

function FieldAPI:getLabel()
    return self.label or self.key
end

function FieldAPI:getDefault(obj)
    if type(self.default) == "function" then
        return self.default(obj)
    end
    return deepCopy(self.default)
end

-- Built field objects are cached per raw definition table so they are STABLE:
-- recomputing a class schema returns the same objects, and event subscribers
-- survive. Sibling classes inheriting the same declaration share one object.
local builtFields = setmetatable({}, { __mode = "k" })

local function buildField(def)
    local built = builtFields[def]
    if built ~= nil then
        return built
    end
    if def.key == nil then
        error("Every field requires a key")
    end
    local typeKey = def.type or "Generic"
    local fieldType = fieldTypes[typeKey]
    if fieldType == nil then
        error("Unknown field type " .. tostring(typeKey) .. " on field " .. def.key)
    end
    built = setmetatable({}, fieldMeta)
    for k, v in pairs(def) do
        built[k] = v
    end
    built.events = { valueChange = classes.newEvent("valueChange") }
    -- Custom accessors are declared as `get`/`set` but stored under names
    -- that cannot collide with field API methods. Merged defs from
    -- updateField already carry getFunc/setFunc, which pairs() copied above.
    if def.get ~= nil then
        built.getFunc = def.get
    end
    if def.set ~= nil then
        built.setFunc = def.set
    end
    built.get = nil
    built.set = nil
    built.fieldType = fieldType
    builtFields[def] = built
    return built
end

-- ---------------------------------------------------------------------------
-- Per-class schema: declarations in external weak maps, effective field list
-- computed by a super-chain walk, cached per class, invalidated by a global
-- generation counter (handles parents declaring after children computed).
-- ---------------------------------------------------------------------------

local declaredDefs = setmetatable({}, { __mode = "k" }) -- class -> raw def tables
local schemaCache = setmetatable({}, { __mode = "k" }) -- class -> {generation, list, byKey}
local schemaGeneration = 0

local function computeSchema(class)
    local cached = schemaCache[class]
    if cached ~= nil and cached.generation == schemaGeneration then
        return cached
    end

    local chain = {}
    local c = class
    while c ~= nil do
        tinsert(chain, 1, c) -- root first: parents declare before children
        c = c.super
    end

    local list, byKey = {}, {}
    for _, cls in ipairs(chain) do
        for _, def in ipairs(declaredDefs[cls] or {}) do
            local field = buildField(def)
            local existingIndex = byKey[field.key]
            if existingIndex ~= nil then
                list[existingIndex] = field -- child redeclaration replaces in place
            else
                tinsert(list, field)
                byKey[field.key] = #list
            end
        end
    end

    cached = { generation = schemaGeneration, list = list, byKey = byKey }
    schemaCache[class] = cached
    return cached
end

local function fieldFor(class, key)
    local schema = computeSchema(class)
    local index = schema.byKey[key]
    if index == nil then
        return nil
    end
    return schema.list[index]
end

-- ---------------------------------------------------------------------------
-- Instance field access (the metamethods)
-- ---------------------------------------------------------------------------

local function getField(obj, field)
    if field.getFunc ~= nil then
        return field.getFunc(obj, field.key)
    end
    local values = rawget(obj, "_values")
    local value = values[field.key]
    if value == nil and field.default ~= nil then
        -- Materialize the default lazily so tables get a stable per-instance copy.
        value = FieldAPI.getDefault(field, obj)
        values[field.key] = value
    end
    return value
end

local function persistField(obj, field, value)
    if not field.persist then
        return
    end
    local pair = rawget(obj, "_db")
    if pair == nil then
        return
    end
    if type(value) == "function" then
        return -- functions cannot serialize to SavedVariables
    end
    local store = resolveStore(field, pair)
    if store == nil then
        return
    end
    if field.fieldType.toDB ~= nil then
        store[field.key] = field.fieldType.toDB(field, obj, value)
    else
        store[field.key] = value
    end
end

local function setField(obj, field, value)
    -- validate ALWAYS runs when defined: per-field validate wins, else type
    if field.validate ~= nil then
        value = field.validate(field, value)
    elseif field.fieldType.validate ~= nil then
        value = field.fieldType.validate(field, value)
    end

    local old = getField(obj, field)
    if deepEqual(old, value) then
        return false
    end

    if field.once and old ~= nil then
        error("Field " .. field.key .. " cannot be overwritten")
    end

    local persistValue = value
    if field.setFunc ~= nil then
        -- Custom setters own storage; their return value (if any) is what persists.
        persistValue = field.setFunc(obj, field.key, value) or value
    else
        rawget(obj, "_values")[field.key] = value
    end

    persistField(obj, field, persistValue)
    field.events.valueChange:emit(obj, field.key, persistValue)
    return true
end

local function makeInstanceMeta(class)
    return {
        __index = function(obj, key)
            local field = fieldFor(class, key)
            if field ~= nil then
                return getField(obj, field)
            end
            return class[key] -- methods + class attributes, through the class chain
        end,
        __newindex = function(obj, key, value)
            local field = fieldFor(class, key)
            if field ~= nil then
                setField(obj, field, value)
                return
            end
            rawset(obj, key, value) -- plain instance variables stay plain
        end,
    }
end

-- ---------------------------------------------------------------------------
-- The class prototype: everything a class can do
-- ---------------------------------------------------------------------------

local ClassProto = {}

function ClassProto:new(...)
    local instance = setmetatable({}, self._instanceMeta)
    rawset(instance, "_values", {})
    rawset(instance, "class", self)
    instance:initialize(...)
    return instance
end

function ClassProto:initialize() end

function ClassProto:addFields(defs)
    local declared = declaredDefs[self]
    if declared == nil then
        declared = {}
        declaredDefs[self] = declared
    end
    for _, def in ipairs(defs) do
        tinsert(declared, def)
    end
    schemaGeneration = schemaGeneration + 1
    return self
end

function ClassProto:addField(def)
    return self:addFields({ def })
end

-- Override an inherited (or own) field: the effective definition is merged
-- with the updates and appended to THIS class's declarations, so the parent
-- and sibling classes are untouched.
function ClassProto:updateField(updates)
    if updates.key == nil then
        error("updateField requires a key")
    end
    local existing = fieldFor(self, updates.key)
    if existing == nil then
        error("No field to update matching " .. updates.key)
    end
    local merged = {}
    for k, v in pairs(existing) do
        if k ~= "fieldType" and k ~= "events" then
            merged[k] = v
        end
    end
    for k, v in pairs(updates) do
        merged[k] = v
    end
    setmetatable(merged, nil)
    self:addField(merged)
    return fieldFor(self, updates.key)
end

function ClassProto:updateFields(defs)
    local result = {}
    for _, def in ipairs(defs) do
        tinsert(result, self:updateField(def))
    end
    return result
end

function ClassProto:getFields()
    return computeSchema(self).list
end

function ClassProto:getField(key)
    return fieldFor(self, key)
end

-- Apply a config table to an instance: declared keys set through the field
-- path; required fields must end up non-nil. Replaces InfoClass:setInfo.
function ClassProto:applyFields(config, ignoreRequired)
    config = config or {}
    for _, field in ipairs(self.class:getFields()) do
        local value = config[field.key]
        if value ~= nil then
            setField(self, field, value)
        elseif field.required and not ignoreRequired and getField(self, field) == nil then
            error("Field " .. field.key .. " must have a value")
        end
    end
    if self.onSetInfo ~= nil then
        self:onSetInfo()
    end
end
-- ClassProto methods run on instances too (obj:applyFields) via class chain;
-- applyFields above expects an instance as self.

-- Restore an instance from a db pair, then bind the pair for future persists.
-- Assignment during restore goes through the normal set path (validation and
-- valueChange both fire) but never writes back -- persistence is suspended.
function ClassProto:setDB(pair)
    if pair.char == nil and pair.global == nil and (pair[1] ~= nil or next(pair) ~= nil) then
        -- Convenience: a bare node means a single-sided character pair.
        pair = { char = pair }
    end
    rawset(self, "_db", nil)
    for _, field in ipairs(self.class:getFields()) do
        if field.persist then
            local fieldType = field.fieldType
            if fieldType.setDB ~= nil then
                fieldType.setDB(field, self, pair)
            else
                local store = resolveStore(field, pair)
                local dbValue = store ~= nil and store[field.key] or nil
                local value
                if dbValue == nil then
                    value = field:getDefault(self)
                elseif fieldType.fromDB ~= nil then
                    value = fieldType.fromDB(field, self, dbValue, pair)
                else
                    value = dbValue
                end
                setField(self, field, value)
            end
        end
    end
    rawset(self, "_db", pair)
    if self.onSetDB ~= nil then
        self:onSetDB(pair)
    end
end

-- The default db tree for one store ("global" or "char"). forcedChar tracks
-- descent through a character-scoped container: below one, every field is
-- char regardless of its own flag (the nesting rule).
function ClassProto:getDefaultDB(scope, forcedChar)
    local result = {}
    for _, field in ipairs(self.class:getFields()) do
        if field.persist then
            local fieldGlobal = field.global ~= false and not forcedChar
            local fieldType = field.fieldType
            if fieldType.getDefaultDB ~= nil then
                -- Containers exist in BOTH trees (their children may split).
                result[field.key] = fieldType.getDefaultDB(field, self, scope, forcedChar or field.global == false)
            elseif (scope == "global") == fieldGlobal then
                local default = field:getDefault(self)
                if fieldType.toDB ~= nil and default ~= nil then
                    result[field.key] = fieldType.toDB(field, self, default)
                else
                    result[field.key] = default
                end
            end
        end
    end
    return result
end

function ClassProto:isInstanceOf(class)
    local c = self.class
    while c ~= nil do
        if c == class then
            return true
        end
        c = c.super
    end
    return false
end

function ClassProto:isSubclassOf(class)
    local c = self.super
    while c ~= nil do
        if c == class then
            return true
        end
        c = c.super
    end
    return false
end

function ClassProto:include(mixin)
    for k, v in pairs(mixin) do
        if k ~= "included" then
            self[k] = v
        end
    end
    if mixin.included ~= nil then
        mixin.included(mixin, self)
    end
    return self
end

-- ---------------------------------------------------------------------------
-- Class creation
-- ---------------------------------------------------------------------------

local classMeta = {
    __tostring = function(class)
        return "class " .. class.name
    end,
}

function classes.NewClass(name, super)
    if type(name) ~= "string" then
        error("Class name must be a string")
    end
    local class = { name = name, super = super }
    class.static = class -- middleclass compatibility: Class.static.foo == Class.foo
    class._instanceMeta = makeInstanceMeta(class)
    local meta = { __index = super or ClassProto, __tostring = classMeta.__tostring }
    setmetatable(class, meta)
    return class
end

-- THE class factory for the whole addon (replaces middleclass, whose
-- assignment this overwrites -- this file loads after libs).
WowVisionNamespace.Class = classes.NewClass
