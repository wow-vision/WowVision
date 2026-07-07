local info = WowVision.info
local L = WowVision:getLocale()

local ObjectField, parent = info:CreateFieldClass("Object")

function ObjectField:setup(config)
    parent.setup(self, config)
end

-- Value is { type = "Health", params = { unit = "player" } }
function ObjectField:getDefault(obj)
    return { type = nil, params = {} }
end

function ObjectField:validate(value)
    if value == nil then
        return { type = nil, params = {} }
    end
    if type(value) ~= "table" then
        return { type = nil, params = {} }
    end
    return {
        type = value.type,
        params = value.params or {},
    }
end

function ObjectField:getValueString(obj, value)
    if not value or not value.type then
        return L["None"]
    end
    local objectType = WowVision.objects.types:get(value.type)
    if objectType then
        return objectType:getDefinitionLabel(value.params)
    end
    return value.type
end

-- Helper to persist and emit change event
function ObjectField:onObjectChanged(obj)
    local value = obj[self.key]
    if self.persist and obj.db then
        obj.db[self.key] = WowVision.info.deepCopy(value)
    end
    self.events.valueChange:emit(obj, self.key, value)
end

-- Set the object value
function ObjectField:set(obj, value)
    obj[self.key] = self:validate(value)
    self:onObjectChanged(obj)
end

-- Set just the type, resetting params to defaults
function ObjectField:setType(obj, typeKey)
    local value = obj[self.key] or { type = nil, params = {} }
    value.type = typeKey
    -- Reset params to defaults for new type
    value.params = {}
    if typeKey then
        local objectType = WowVision.objects.types:get(typeKey)
        if objectType and objectType.parameters then
            -- Get default values from parameter fields
            for _, field in ipairs(objectType.parameters.fields) do
                local default = field:getDefault({})
                if default ~= nil then
                    value.params[field.key] = default
                end
            end
        end
    end
    obj[self.key] = value
    self:onObjectChanged(obj)
end

-- Set a specific param value
function ObjectField:setParam(obj, paramKey, paramValue)
    local value = obj[self.key] or { type = nil, params = {} }
    value.params[paramKey] = paramValue
    obj[self.key] = value
    self:onObjectChanged(obj)
end

-- Restore from DB
function ObjectField:setDB(obj, db)
    obj.db = nil -- Temporarily disable to avoid re-persisting
    local dbValue = db[self.key]
    if dbValue then
        self:set(obj, dbValue)
    else
        self:set(obj, self:getDefault(obj))
    end
    obj.db = db
end

-- Creates a proxy for params that redirects writes through setParam
function ObjectField:createParamsProxy(obj)
    local objectField = self
    return setmetatable({}, {
        __index = function(t, k)
            local value = obj[objectField.key] or { type = nil, params = {} }
            return value.params[k]
        end,
        __newindex = function(t, k, v)
            objectField:setParam(obj, k, v)
        end,
    })
end

-- Returns a button that opens the object editor
