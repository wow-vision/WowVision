local L = WowVision:getLocale()

local ObjectItem = WowVision.Class("ObjectItem", WowVision.buffers.BufferItem):include(WowVision.InfoClass)
ObjectItem.info:addFields({
    {
        key = "object",
        type = "TrackingConfig",
        label = L["Object"],
        persist = true,
        requireUnique = true,
    },
    {
        key = "template",
        type = "Template",
        label = L["Template"],
        persist = true,
        getTemplates = function(obj)
            if obj.object and obj.object.type then
                local objectType = WowVision.objects.types:get(obj.object.type)
                if objectType then return objectType.templates end
            end
        end,
    },
})

function ObjectItem:initialize(config)
    WowVision.buffers.BufferItem.initialize(self, config)
end

-- Check if self.object is an Object instance (from TrackedBuffer) or TrackingConfig (from StaticBuffer)
function ObjectItem:isObjectInstance()
    return self.object and self.object.class ~= nil
end

-- Get the Object instance
-- If self.object is already an Object (from TrackedBuffer), return it directly
-- If self.object is a TrackingConfig (from StaticBuffer), create an Object from it
function ObjectItem:getObject()
    local obj = self.object
    if not obj then
        return nil
    end

    -- If it's already an Object instance (has a class), return it directly
    if obj.class then
        return obj
    end

    -- Otherwise it's a TrackingConfig, create Object from it
    if not obj.type then
        return nil
    end
    -- Convert TrackingConfig to Object params
    local params = {}
    if obj.units and obj.units[1] then
        -- UnitType uses units array
        params.unit = obj.units[1]
    end
    if obj.params then
        for k, v in pairs(obj.params) do
            params[k] = v
        end
    end
    return WowVision.objects:create(obj.type, params)
end

function ObjectItem:getFocusString()
    local obj = self:getObject()
    if not obj then
        return L["No object configured"]
    end

    local templateValue = self.template
    if templateValue then
        local objectType = obj.type
        if templateValue.format then
            -- Custom format string (parsed + cached by ObjectType)
            return objectType:renderTemplate(templateValue.format, obj.params)
        elseif templateValue.key then
            -- Registered template by key
            local template = objectType.templates:get(templateValue.key)
            if template then
                local context = objectType:buildContext(obj.params, template.fields)
                return template:render(context)
            end
        end
    end

    -- Fallback to default
    return obj:getFocusString()
end

function ObjectItem:getLabel()
    local obj = self.object
    if not obj then
        return L["Empty Object"]
    end

    -- If it's an Object instance, use its getLabel method
    if obj.class then
        return obj:getLabel()
    end

    -- Otherwise it's a TrackingConfig
    if obj.type then
        local objectType = WowVision.objects.types:get(obj.type)
        if objectType then
            -- Use getDefinitionLabel for a descriptive label
            local params = {}
            if obj.units and obj.units[1] then
                params.unit = obj.units[1]
            end
            if obj.params then
                for k, v in pairs(obj.params) do
                    params[k] = v
                end
            end
            return objectType:getDefinitionLabel(params)
        end
        return obj.type
    end
    return L["Empty Object"]
end

-- For ComponentArray: returns UI for editing this item's settings
function ObjectItem:getSettingsGenerator()
    local objectField = self.class.info:getField("object")
    local templateField = self.class.info:getField("template")
    local children = {}

    -- Type dropdown
    tinsert(children, objectField:buildTypeButton(self))

    -- Parameters button (only if type has params)
    local paramsButton = objectField:buildParamsButton(self)
    if paramsButton then
        tinsert(children, paramsButton)
    end

    -- Template selector
    tinsert(children, templateField:getGenerator(self))

    return { "List", label = self:getLabel(), children = children }
end

WowVision.buffers.ObjectItem = ObjectItem
