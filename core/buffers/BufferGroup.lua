local L = WowVision:getLocale()

local BufferGroup, parent = WowVision.buffers:createType("Group")

BufferGroup.info:addFields({
    {
        key = "items",
        type = "ComponentArray",
        label = L["Buffers"],
        persist = true,
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
        availableTypes = {
            { key = "Static", label = L["Static Buffer"] },
            { key = "Tracked", label = L["Tracked Buffer"] },
        },
    },
})

function BufferGroup:initialize(config)
    parent.initialize(self, config)
    self.wrap = true
end

-- Convenience method to add a buffer
function BufferGroup:addBuffer(buffer)
    local field = self.class.info:getField("items")
    field:addElement(self, buffer)
end

-- Convenience method to remove a buffer by index
function BufferGroup:removeBuffer(index)
    local field = self.class.info:getField("items")
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

RootBufferGroup.info:updateField({
    key = "items",
    availableTypes = {
        { key = "Static", label = L["Static Buffer"] },
        { key = "Tracked", label = L["Tracked Buffer"] },
        { key = "Group", label = L["Buffer Group"] },
    },
})

WowVision.buffers.RootBufferGroup = RootBufferGroup
