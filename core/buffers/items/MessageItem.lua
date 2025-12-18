local MessageItem = WowVision.Class("MessageItem", WowVision.buffers.BufferItem)

function MessageItem:initialize(data, getDataString)
    self.data = data
    self.getDataString = getDataString
end

function MessageItem:getFocusString()
    if self.getDataString then
        return self.getDataString(self.data)
    end
    if type(self.data) == "string" then
        return self.data
    end
    return tostring(self.data)
end

function MessageItem:getLabel()
    return self:getFocusString()
end

function MessageItem:getData()
    return self.data
end

WowVision.buffers.MessageItem = MessageItem
