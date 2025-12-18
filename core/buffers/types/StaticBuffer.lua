local StaticBuffer = WowVision.buffers:createType("Static")

function StaticBuffer:addObject(typeKey, params)
    local obj = WowVision.objects:create(typeKey, params)
    if obj then
        self:add(WowVision.buffers.ObjectItem:new(obj))
    end
end

function StaticBuffer:deserialize(data)
    WowVision.buffers.Buffer.deserialize(self, data)
    for _, v in ipairs(data.items or {}) do
        local item = WowVision.buffers.ObjectItem:new()
        item:deserialize(v)
        self:add(item)
    end
end

function StaticBuffer:serialize()
    local data = WowVision.buffers.Buffer.serialize(self)
    data.items = {}
    for _, v in ipairs(self.items) do
        tinsert(data.items, v:serialize())
    end
    return data
end
