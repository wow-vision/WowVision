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

function ComponentRegistry:createTemporaryComponent(config)
    local typeClass = self.types:get(config.type)
    if not typeClass then
        error("ComponentRegistry: Unknown type '" .. config.type .. "'")
    end

    local component = self.registryType:createComponent(typeClass, config)
    return component
end

function ComponentRegistry:createComponent(config)
    local component = self:createTemporaryComponent(config)
    self.components:register(config.key, component)
    return component
end

function ComponentRegistry:getComponents()
    local result = {}
    for _, component in ipairs(self.components.items) do
        tinsert(result, component)
    end
    return result
end

function ComponentRegistry:getComponentsOfType(typeName)
    local typeClass = self.types:get(typeName)
    if not typeClass then
        error("ComponentRegistry: Unknown type '" .. typeName .. "'")
    end

    local result = {}
    for _, component in ipairs(self.components.items) do
        if self.registryType:isComponentOfType(component, typeClass) then
            tinsert(result, component)
        end
    end
    return result
end

function ComponentRegistry:forEachComponent(callback)
    for i, component in ipairs(self.components.items) do
        callback(component, self.components.itemKeys[i])
    end
end

function ComponentRegistry:forEachComponentOfType(typeName, callback)
    local typeClass = self.types:get(typeName)
    if not typeClass then
        error("ComponentRegistry: Unknown type '" .. typeName .. "'")
    end

    for i, component in ipairs(self.components.items) do
        if self.registryType:isComponentOfType(component, typeClass) then
            callback(component, self.components.itemKeys[i])
        end
    end
end

WowVision.components.ComponentRegistry = ComponentRegistry
