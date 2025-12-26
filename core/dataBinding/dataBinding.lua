local dataBinding = {
    types = WowVision.Registry:new(),
}

WowVision.dataBinding = dataBinding

-- Base DataBinding class
local DataBinding = WowVision.Class("DataBinding"):include(WowVision.InfoClass)
dataBinding.DataBinding = DataBinding

DataBinding.info:addFields({
    { key = "fixedValue" },
})

function DataBinding:initialize(config)
    self:setInfo(config)
end

function DataBinding:readValue()
    error("DataBinding:readValue() must be overridden")
end

function DataBinding:get()
    return self:readValue()
end

function DataBinding:writeValue(value)
    error("DataBinding:writeValue() must be overridden")
end

function DataBinding:set(value)
    if self.fixedValue ~= nil then
        value = self.fixedValue
    end
    self:writeValue(value)
end

-- Creates a new DataBinding subclass and registers it
function dataBinding:createType(key, parentKey)
    local parentClass = parentKey and self.types:get(parentKey) or self.DataBinding
    local newClass = WowVision.Class(key .. "DataBinding", parentClass):include(WowVision.InfoClass)
    newClass.typeKey = key
    self.types:register(key, newClass)
    return newClass, parentClass
end

-- Factory that creates the right binding type from config
function dataBinding:create(config)
    if not config then
        return nil
    end
    local bindingType = config.type
    if not bindingType then
        error("DataBinding config requires a 'type' field")
    end
    local BindingClass = self.types:get(bindingType)
    if not BindingClass then
        error("Unknown binding type: " .. tostring(bindingType))
    end
    return BindingClass:new(config)
end
