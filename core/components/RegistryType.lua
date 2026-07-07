local RegistryType = WowVision.Class("RegistryType")

function RegistryType:initialize(registry, config)
    self.registry = registry
    self:applyFields(config)
end

function RegistryType:createType(config)
    error("RegistryType:createType must be implemented by subclass")
end

function RegistryType:createComponent(typeClass, config)
    error("RegistryType:createComponent must be implemented by subclass")
end

function RegistryType:isComponentOfType(component, typeClass)
    error("RegistryType:isComponentOfType must be implemented by subclass")
end

WowVision.components.RegistryType = RegistryType
