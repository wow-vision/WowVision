local components = {
    registryTypes = WowVision.Registry:new(),
    registries = WowVision.Registry:new(),
}

function components.createRegistry(config)
    local registry = WowVision.components.ComponentRegistry:new(config)
    if config.path then
        components.registries:register(config.path, registry)
    end
    return registry
end

function components.createType(path, config)
    local registry = components.registries:get(path)
    if not registry then
        error("components.createType: Unknown registry path '" .. path .. "'")
    end
    return registry:createType(config)
end

function components.createComponent(path, config)
    local registry = components.registries:get(path)
    if not registry then
        error("components.createComponent: Unknown registry path '" .. path .. "'")
    end
    return registry:createComponent(config)
end

WowVision.components = components
