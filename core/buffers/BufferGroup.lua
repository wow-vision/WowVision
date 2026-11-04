local L = WowVision:getLocale()

local BufferGroup, parent = WowVision.buffers:createType("Group")

-- What a group's Add offers. A version can take a type out of the list (see
-- retail/buffers.lua); the type stays registered, so saved buffers still load.
WowVision.buffers.groupTypes = {
    { key = "Static", label = L["Static Buffer"] },
    { key = "Tracked", label = L["Tracked Buffer"] },
    { key = "ChatTab", label = L["Chat Tab Buffer"] },
    { key = "Aura", label = L["Aura Buffer"] },
}

BufferGroup:addFields({
    {
        key = "items",
        type = "ComponentArray",
        label = L["Buffers"],
        persist = true,
        sortPriority = 3,
        factory = function(config)
            return WowVision.buffers:create(config.type, config)
        end,
        getTypeKey = function(instance)
            local className = instance.class.name
            if className:sub(-6) == "Buffer" then
                return className:sub(1, -7)
            end
            return className
        end,
        availableTypes = WowVision.buffers.groupTypes,
    },
})

function BufferGroup:initialize(config)
    parent.initialize(self, config)
    self.wrap = true
end

-- Convenience method to add a buffer
function BufferGroup:addBuffer(buffer)
    local field = self.class:getField("items")
    field:addElement(self, buffer)
end

-- Convenience method to remove a buffer by index
function BufferGroup:removeBuffer(index)
    local field = self.class:getField("items")
    field:removeElement(self, index)
end

-- Get the buffer type key for a buffer (used for display)
function BufferGroup:getBufferTypeKey(buffer)
    local className = buffer.class.name
    if className:sub(-6) == "Buffer" then
        return className:sub(1, -7)
    end
    return className
end

WowVision.buffers.BufferGroup = BufferGroup

-- Root group allows adding child groups (one level of nesting only)
local RootBufferGroup = WowVision.buffers.registry:createType({ key = "RootGroup", parent = "Group" })

RootBufferGroup:updateField({
    key = "items",
    availableTypes = {
        { key = "Group", label = L["Buffer Group"] },
    },
})

WowVision.buffers.RootBufferGroup = RootBufferGroup
