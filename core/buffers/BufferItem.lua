local BufferItem = WowVision.Class("BufferItem")

function BufferItem:initialize()
    -- Base class, override in subclasses
end

function BufferItem:getFocusString()
    error("BufferItem:getFocusString must be implemented by subclass")
end

function BufferItem:getLabel()
    return self:getFocusString()
end

function BufferItem:serialize()
    return nil
end

function BufferItem:deserialize(data)
    -- Override in subclasses that support serialization
end

WowVision.buffers.BufferItem = BufferItem
