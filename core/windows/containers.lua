local module = WowVision.base.windows:createModule("containers")
local L = module.L
module:setLabel(L["Containers"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

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

-- An item slot node: live label (bag contents change constantly under
-- focus), real clicks for pickup, use, and split, and drag support.
function module.itemSlotNode(itemButton, label)
    local vtable = nodes.proxyButton({ target = itemButton, label = label })
    vtable.announcements[1].live = "focus"
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local script = itemButton:GetScript("OnDragStart")
            if script ~= nil then
                script(itemButton)
            end
        end,
    })
    return vtable
end

local function render(builder, screen)
    builder:pushContext("bags", L["Bags"])
    containers:forEachComponent(function(container)
        if container.renderGraph ~= nil and (container.isOpen == nil or container:isOpen()) then
            local ok, err = pcall(container.renderGraph, container, builder)
            if not ok then
                geterrorhandler()(err)
            end
        end
    end)
    builder:popContext()
end

module:registerWindow({
    type = "CustomWindow",
    name = "bags",
    isOpen = function(self)
        for _, container in ipairs(containers:getComponents()) do
            if container.isOpen and container:isOpen() then
                return true
            end
        end
        return false
    end,
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
