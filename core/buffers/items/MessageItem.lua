local MessageItem = WowVision.Class("MessageItem", WowVision.buffers.BufferItem):include(WowVision.InfoClass)
MessageItem.info:addFields({
    { key = "data" },
    { key = "getDataString" },
})

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
