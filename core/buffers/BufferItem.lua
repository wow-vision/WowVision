local BufferItem = WowVision.Class("BufferItem")

function BufferItem:initialize(object)
    self.object = object
end

function BufferItem:getFocusString()
    return self.object:getFocusString()
end

function BufferItem:getLabel()
    return self.object:getLabel()
end

function BufferItem:deserialize(data)
    self.object = WowVision.objects:deserialize(data)
end

function BufferItem:serialize()
    return self.object:serialize()
end

WowVision.buffers.BufferItem = BufferItem
