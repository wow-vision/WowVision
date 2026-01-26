local StaticBuffer = WowVision.buffers:createType("Static")
StaticBuffer.info:addFields({
    { key = "objects", default = {} },  -- Array of { type = "...", params = {...} }
})

function StaticBuffer:onSetInfo()
    -- Clear existing items
    self.items = {}

    -- Create objects from config
    for _, objectConfig in ipairs(self.objects) do
        self:addObject(objectConfig.type, objectConfig.params)
    end
end

function StaticBuffer:addObject(typeKey, params)
    local obj = WowVision.objects:create(typeKey, params)
    if obj then
        self:add(WowVision.buffers.ObjectItem:new({ object = obj }))
    end
end
