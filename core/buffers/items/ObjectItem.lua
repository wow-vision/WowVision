local ObjectItem = WowVision.Class("ObjectItem", WowVision.buffers.BufferItem):include(WowVision.InfoClass)
ObjectItem.info:addFields({
    { key = "object" },
})

function ObjectItem:getFocusString()
    return self.object:getFocusString()
end

function ObjectItem:getLabel()
    return self.object:getLabel()
end

function ObjectItem:getObject()
    return self.object
end

WowVision.buffers.ObjectItem = ObjectItem
