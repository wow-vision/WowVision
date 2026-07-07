local info = WowVision.info
local L = WowVision:getLocale()

local TrackingConfigField, parent = info:CreateFieldClass("TrackingConfig")

function TrackingConfigField:setup(config)
    parent.setup(self, config)
    self.requireUnique = config.requireUnique or false
end

-- Value is { type = "Health", units = { "player" }, ... }
-- Structure varies by object type (UnitType uses units array, others use params)
function TrackingConfigField:getDefault(obj)
    return { type = nil }
end

function TrackingConfigField:validate(value)
    if value == nil then
        return { type = nil }
    end
    if type(value) ~= "table" then
        return { type = nil }
    end
    -- If it's an Object instance (has a class), pass through directly
    if value.class then
        return value
    end
    -- Keep all fields from value, just ensure type exists
    local result = {}
    for k, v in pairs(value) do
        result[k] = v
    end
    if result.type == nil then
        result.type = nil
    end
    return result
end

function TrackingConfigField:getValueString(obj, value)
    if not value or not value.type then
        return L["None"]
    end
    local objectType = WowVision.objects.types:get(value.type)
    if objectType then
        -- For UnitType, show units; for others show type label
        if value.units and #value.units > 0 then
            return (objectType.label or value.type) .. " (" .. table.concat(value.units, ", ") .. ")"
        end
        return objectType.label or value.type
    end
    return value.type
end

-- Helper to persist and emit change event
function TrackingConfigField:onConfigChanged(obj)
    local value = obj[self.key]
    if self.persist and obj.db then
        obj.db[self.key] = WowVision.info.deepCopy(value)
    end
    self.events.valueChange:emit(obj, self.key, value)
end

-- Set the tracking config value
function TrackingConfigField:set(obj, value)
    local oldValue = obj[self.key]
    local newValue = self:validate(value)

    -- Check if value actually changed
    if WowVision.info.valuesEqual(oldValue, newValue) then
        return false
    end

    obj[self.key] = newValue
    self:onConfigChanged(obj)
    return true
end

-- Set just the type, resetting config to defaults
function TrackingConfigField:setType(obj, typeKey)
    local oldValue = obj[self.key]
    -- If type isn't changing, don't reset config
    if oldValue and oldValue.type == typeKey then
        return false
    end

    local value = { type = typeKey }
    if typeKey then
        local objectType = WowVision.objects.types:get(typeKey)
        if objectType then
            -- Fresh config scaffolding for the new type
            value.params = {}
            value.type = typeKey
            -- Populate parameter field defaults for params not already at top level
            if objectType.parameters and value.params then
                for _, paramField in ipairs(objectType.parameters.fields) do
                    if value[paramField.key] == nil and value.params[paramField.key] == nil then
                        local default = paramField:getDefault(value.params)
                        if default ~= nil then
                            value.params[paramField.key] = default
                        end
                    end
                end
            end
        end
    end
    obj[self.key] = value
    self:onConfigChanged(obj)
    return true
end

-- Restore from DB
function TrackingConfigField:setDB(obj, db)
    obj.db = nil -- Temporarily disable to avoid re-persisting
    local dbValue = db[self.key]
    if dbValue then
        self:set(obj, dbValue)
    else
        self:set(obj, self:getDefault(obj))
    end
    obj.db = db
end
