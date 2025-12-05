local module = WowVision.base.windows:createModule("containers")
local L = module.L
module:setLabel(L["Containers"])
local gen = module:hasUI()

module.containerTypes = WowVision.Registry:new()
module.containers = {}

local Container = WowVision.Class("Container")

function Container:initialize(info)
    self.type = info.type
    self:setInfo(info)
end

function module:createContainerType(typeKey)
    local class = WowVision.Class("Container" .. typeKey, Container):include(WowVision.InfoClass)
    self.containerTypes:register(typeKey, class)
    return class
end

function module:addContainer(info)
    local class = self.containerTypes:get(info.type)
    if not class then
        error("Container type " .. info.type .. " not found.")
    end
    local instance = class:new(info)
    tinsert(self.containers, instance)
end

gen:Element("bags", function(props)
    local result = { "Panel", label = L["Bags"], wrap = true, children = {} }
    for _, v in ipairs(module.containers) do
        tinsert(result.children, { "bags/Container", container = v })
    end
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
        for _, v in ipairs(module.containers) do
            if v.isOpen and v:isOpen() then
                return true
            end
        end
        return false
    end,
    conflictingAddons = { "Sku" },
})
