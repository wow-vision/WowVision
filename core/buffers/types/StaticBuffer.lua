local L = WowVision:getLocale()

local StaticBuffer = WowVision.buffers:createType("Static")
StaticBuffer.info:addFields({
    {
        key = "items",
        type = "ComponentArray",
        label = L["Objects"],
        persist = true,
        factory = function(config)
            -- If config.object exists, use it directly (loading from DB)
            -- Otherwise, map top-level type to object.type (adding new item)
            if not config.object then
                config = { object = { type = config.type } }
            end
            return WowVision.buffers.ObjectItem:new(config)
        end,
        getTypeKey = function(instance)
            -- ObjectItem wraps an object, return the object's type
            local objConfig = instance.object
            if objConfig and objConfig.type then
                return objConfig.type
            end
            return "Unknown"
        end,
        availableTypes = function()
            local types = {}
            for _, objType in ipairs(WowVision.objects.types.items) do
                tinsert(types, { key = objType.key, label = objType.label or objType.key })
            end
            return types
        end,
    },
})
