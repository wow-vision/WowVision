local L = WowVision:getLocale()

local ObjectItem = WowVision.Class("ObjectItem", WowVision.buffers.BufferItem):include(WowVision.InfoClass)
ObjectItem.info:addFields({
    {
        key = "object",
        type = "TrackingConfig",
        label = L["Object"],
    },
})

function ObjectItem:initialize(config)
    WowVision.buffers.BufferItem.initialize(self, config)
end

-- Create the Object instance from the TrackingConfig (no caching for now)
function ObjectItem:getObject()
    local config = self.object
    if not config or not config.type then
        return nil
    end
    -- Convert TrackingConfig to Object params
    local params = {}
    if config.units and config.units[1] then
        -- UnitType uses units array
        params.unit = config.units[1]
    end
    if config.params then
        for k, v in pairs(config.params) do
            params[k] = v
        end
    end
    return WowVision.objects:create(config.type, params)
end

function ObjectItem:getFocusString()
    local obj = self:getObject()
    if obj then
        return obj:getFocusString()
    end
    return L["No object configured"]
end

function ObjectItem:getLabel()
    local config = self.object
    if config and config.type then
        local objectType = WowVision.objects.types:get(config.type)
        if objectType then
            -- Use getDefinitionLabel for a descriptive label
            local params = {}
            if config.units and config.units[1] then
                params.unit = config.units[1]
            end
            if config.params then
                for k, v in pairs(config.params) do
                    params[k] = v
                end
            end
            return objectType:getDefinitionLabel(params)
        end
        return config.type
    end
    return L["Empty Object"]
end

-- For ComponentArray: returns UI for editing this item's settings
function ObjectItem:getSettingsGenerator()
    return self.class.info:getGenerator(self)
end

WowVision.buffers.ObjectItem = ObjectItem
