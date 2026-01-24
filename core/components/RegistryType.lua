local RegistryType = WowVision.Class("RegistryType"):include(WowVision.InfoClass)

function RegistryType:initialize(registry, config)
    self.registry = registry
    self:setInfo(config)
end

function RegistryType:createType(config)
    error("RegistryType:createType must be implemented by subclass")
end

function RegistryType:createComponent(typeClass, config)
    error("RegistryType:createComponent must be implemented by subclass")
end

WowVision.components.RegistryType = RegistryType
