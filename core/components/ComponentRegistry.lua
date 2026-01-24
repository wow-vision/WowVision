local ComponentRegistry = WowVision.Class("ComponentRegistry"):include(WowVision.InfoClass)
ComponentRegistry.info:addFields({
    { key = "type", required = true },
})

function ComponentRegistry:initialize(config)
    self.types = WowVision.Registry:new()
    self.components = WowVision.Registry:new()
    self:setInfo(config)

    local registryTypeClass = WowVision.components.registryTypes:get(self.type)
    if not registryTypeClass then
        error("ComponentRegistry: Unknown registry type '" .. self.type .. "'")
    end

    self.registryType = registryTypeClass:new(self, config)
end

function ComponentRegistry:getComponent(key)
    return self.components:get(key)
end

function ComponentRegistry:createType(config)
    local created = self.registryType:createType(config)
    self.types:register(config.key, created)
    return created
end

function ComponentRegistry:createComponent(config)
    local typeClass = self.types:get(config.type)
    if not typeClass then
        error("ComponentRegistry: Unknown type '" .. config.type .. "'")
    end

    local component = self.registryType:createComponent(typeClass, config)
    self.components:register(config.key, component)
    return component
end

WowVision.components.ComponentRegistry = ComponentRegistry
