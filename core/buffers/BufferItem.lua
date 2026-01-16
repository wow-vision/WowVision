local BufferItem = WowVision.Class("BufferItem"):include(WowVision.InfoClass)

function BufferItem:initialize(info)
    -- Base class, override in subclasses
    self:setInfo(info)
end

function BufferItem:getFocusString()
    error("BufferItem:getFocusString must be implemented by subclass")
end

function BufferItem:getLabel()
    return self:getFocusString()
end

WowVision.buffers.BufferItem = BufferItem
