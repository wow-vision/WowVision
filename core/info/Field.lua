local Field = WowVision.Class("InfoField")
WowVision.info.Field = Field

-- Helper to compare two values for equality (shallow for tables)
local function valuesEqual(a, b)
    if a == b then
        return true
    end
    -- For tables, do shallow comparison
    if type(a) == "table" and type(b) == "table" then
        -- Check if same keys and values (one level deep)
        for k, v in pairs(a) do
            if b[k] ~= v then
                return false
            end
        end
        for k, v in pairs(b) do
            if a[k] ~= v then
                return false
            end
        end
        return true
    end
    return false
end

-- Deep copy a table (handles nested tables, preserves non-table values)
local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    -- Skip class instances (have metatable with class)
    if value.class then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deepCopy(v)
    end
    return copy
end

-- Export for use by other field types
WowVision.info.valuesEqual = valuesEqual
WowVision.info.deepCopy = deepCopy

-- Class-level operators table (subclasses get their own via CreateFieldClass)
Field.operators = {}

-- Static method to add operators to a Field class
function Field.static:addOperator(info)
    local operator = WowVision.info.Operator:new(info)
    self.operators[info.key] = operator
    return operator
end

function Field:initialize(info)
    self.events = { valueChange = WowVision.Event:new("valueChange") }
    self:setup(info)
end

function Field:setup(info)
    if not info.key then
        error("All info fields must have a key.")
    end
    self.key = info.key
    self.typeKey = info.type
    self.required = info.required or false
    self.once = info.once or false
    self.default = info.default
    local strategy = info.getStrategy
    if strategy then
        if type(strategy) == "string" then
            strategy = { strategy }
        end
        if strategy[1] ~= "key" and strategy[1] ~= "adaptive" then
            error("getStrategy, if specified, must be one of {key, adaptive}.")
        end
        self.getStrategy = strategy
    else
        self.getStrategy = { "adaptive" }
    end
    self.getFunc = info.get
    self.setFunc = info.set
    self.getValueStringFunc = info.getValueString
    self.compareMode = info.compareMode or "deep" -- "deep" or "direct"
    self.label = info.label
    self.persist = info.persist or false
    self.showInUI = info.showInUI ~= false
end

function Field:getInfo()
    local result = {
        key = self.key,
        type = self.typeKey,
        required = self.required,
        once = self.once,
        default = self.default,
        getStrategy = self.getStrategy,
        get = self.getFunc,
        set = self.setFunc,
        getValueString = self.getValueStringFunc,
        compareMode = self.compareMode,
        label = self.label,
        persist = self.persist,
        showInUI = self.showInUI,
    }
    return result
end

-- Base validate - subclasses override
function Field:validate(value)
    return value
end

-- Base getDefaultDB - subclasses can override
function Field:getDefaultDB(obj)
    return self:getDefault(obj)
end

-- Base setDB - subclasses can override
function Field:setDB(obj, db)
    obj.db = nil
    local value = db[self.key]
    self:set(obj, value)
    obj.db = db
end

function Field:compare(a, b)
    if self.compareMode == "direct" then
        return a == b
    end
    -- Deep comparison
    return WowVision:recursiveComp(a, b)
end

function Field:getLabel()
    return self.label
end

function Field:getValueString(obj, value)
    if self.getValueStringFunc then
        return self.getValueStringFunc(obj, value)
    end
    if value == nil then
        return nil
    end
    return tostring(value)
end

function Field:get(obj, ...)
    local strategy = self.getStrategy
    if strategy[1] == "key" then
        return obj[strategy[2] or self.key]
    end
    if self.getFunc then
        return self.getFunc(obj, self.key)
    end
    return obj[self.key]
end

function Field:getData(obj)
    return self:get(obj)
end

function Field:getDefault(obj)
    if type(self.default) == "function" then
        return self.default(obj)
    end
    return self.default
end

function Field:set(obj, ...)
    local value = ...
    value = self:validate(value)
    local oldValue = self:get(obj)

    -- Check if value actually changed
    if valuesEqual(oldValue, value) then
        return false
    end

    local persistValue = value
    if self.setFunc then
        persistValue = self.setFunc(obj, self.key, value) or value
    else
        obj[self.key] = value
    end
    if self.persist and obj.db then
        obj.db[self.key] = persistValue
    end
    self.events.valueChange:emit(obj, self.key, persistValue)
    return true
end

function Field:setInfo(obj, info, ignoreRequired, applyMode)
    local ignoreRequired = ignoreRequired or false
    local applyMode = applyMode or "merge"
    local newValue = info[self.key]

    if applyMode == "replace" then
        -- Replace mode: always set value from config, default, or nil
        if self.once and self:get(obj) ~= nil and newValue ~= nil then
            error("Field " .. self.key .. " cannot be overwritten.")
        end
        if newValue ~= nil then
            self:set(obj, newValue)
        elseif self.default ~= nil then
            self:set(obj, self:getDefault(obj))
        elseif not self.required then
            self:set(obj, nil)
        end
        -- Check required after setting
        if not ignoreRequired and self.required and self:get(obj) == nil then
            error("Field " .. self.key .. " must have a value.")
        end
    else
        -- Merge mode (default): only set if provided or if current is nil
        local currentValue = self:get(obj)
        if newValue == nil then
            if currentValue == nil and self.default ~= nil then
                self:set(obj, self:getDefault(obj))
            elseif ignoreRequired == false and self.required and currentValue == nil then
                error("Field " .. self.key .. " must have a value.")
            end
        else
            if self.once and currentValue ~= nil then
                error("Field " .. self.key .. " cannot be overwritten.")
            end
            self:set(obj, newValue)
        end
    end
end

-- Operator class for field comparisons
local Operator = WowVision.Class("InfoFieldOperator"):include(WowVision.InfoClass)
WowVision.info.Operator = Operator
Operator.info:addFields({
    { key = "key", required = true },
    { key = "label" },
    { key = "symbol" },
    {
        key = "operands",
        required = true,
        default = function()
            return {}
        end,
    },
    { key = "func", required = true },
})

function Operator:initialize(info)
    self:setInfo(info)
end

function Operator:evaluate(...)
    return self.func(...)
end
