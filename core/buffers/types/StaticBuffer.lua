local L = WowVision:getLocale()

local StaticBuffer = WowVision.buffers:createType("Static")
StaticBuffer.info:addFields({
    {
        key = "objects",
        type = "Array",
        label = L["Objects"],
        elementField = { type = "Object" },
    },
})

function StaticBuffer:onSetInfo()
    -- Clear existing items
    self.items = {}

    -- Create objects from config
    if self.objects then
        for _, objectConfig in ipairs(self.objects) do
            if objectConfig.type then
                self:addObject(objectConfig.type, objectConfig.params)
            end
        end
    end
end

function StaticBuffer:addObject(typeKey, params)
    local obj = WowVision.objects:create(typeKey, params)
    if obj then
        self:add(WowVision.buffers.ObjectItem:new({ object = obj }))
    end
end
