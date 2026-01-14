local StaticBuffer = WowVision.buffers:createType("Static")

function StaticBuffer:addObject(typeKey, params)
    local obj = WowVision.objects:create(typeKey, params)
    if obj then
        self:add(WowVision.buffers.ObjectItem:new(obj))
    end
end
