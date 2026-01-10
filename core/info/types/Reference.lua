local info = WowVision.info

local ReferenceField, parent = info:CreateFieldClass("Reference")

function ReferenceField:setup(config)
    parent.setup(self, config)
    self.field = config.field
    if not self.field then
        error("Reference field must have a 'field' property pointing to another Field.")
    end
end

function ReferenceField:getInfo()
    local result = parent.getInfo(self)
    result.field = self.field
    return result
end

-- Delegate get to the referenced field
function ReferenceField:get(obj, ...)
    return self.field:get(obj, ...)
end

-- Read-only: set does nothing
function ReferenceField:set(obj, ...)
    -- No-op: Reference fields are read-only
end

-- No persistence: getDefaultDB returns nil
function ReferenceField:getDefaultDB(obj)
    return nil
end

-- No persistence: setDB does nothing
function ReferenceField:setDB(obj, db)
    -- No-op: Reference fields don't persist
end

-- Delegate getDefault to the referenced field
function ReferenceField:getDefault(obj)
    return self.field:getDefault(obj)
end

-- Delegate getValueString to the referenced field
function ReferenceField:getValueString(obj, value)
    return self.field:getValueString(obj, value)
end

-- Delegate getLabel - use our label if set, otherwise referenced field's label
function ReferenceField:getLabel()
    if self.label then
        return self.label
    end
    return self.field:getLabel()
end
