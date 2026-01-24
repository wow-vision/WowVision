local module = WowVision.base.windows:createModule("containers")
local L = module.L
module:setLabel(L["Containers"])
local gen = module:hasUI()

-- Base class for all container types
local Container = WowVision.Class("Container"):include(WowVision.InfoClass)
Container.info:addFields({
    { key = "key", required = true },
    { key = "type", required = true },
})

function Container:initialize(info)
    self:setInfo(info)
end

-- Create component registry for containers
local containers = module:createComponentRegistry({
    key = "containers",
    path = "containers",
    type = "class",
    baseClass = Container,
    classNamePrefix = "Container",
})

function module:createContainerType(typeKey)
    return containers:createType({ key = typeKey })
end

function module:addContainer(info)
    return containers:createComponent(info)
end

gen:Element("bags", function(props)
    local result = { "Panel", label = L["Bags"], wrap = true, children = {} }
    containers:forEachComponent(function(container)
        tinsert(result.children, { "bags/Container", container = container })
    end)
    return result
end)

gen:Element("bags/Container", function(props)
    if props.container.isOpen == nil or props.container:isOpen() then
        return props.container:getGenerator()
    end
    return nil
end)

module:registerWindow({
    type = "CustomWindow",
    name = "bags",
    generated = true,
    rootElement = "bags",
    isOpen = function(self)
        for _, container in ipairs(containers:getComponents()) do
            if container.isOpen and container:isOpen() then
                return true
            end
        end
        return false
    end,
    conflictingAddons = { "Sku" },
})
