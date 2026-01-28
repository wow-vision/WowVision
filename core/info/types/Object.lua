local info = WowVision.info
local L = WowVision:getLocale()

local ObjectField, parent = info:CreateFieldClass("Object")

function ObjectField:setup(config)
    parent.setup(self, config)
end

-- Value is { type = "Health", params = { unit = "player" } }
function ObjectField:getDefault(obj)
    return { type = nil, params = {} }
end

function ObjectField:validate(value)
    if value == nil then
        return { type = nil, params = {} }
    end
    if type(value) ~= "table" then
        return { type = nil, params = {} }
    end
    return {
        type = value.type,
        params = value.params or {},
    }
end

function ObjectField:getValueString(obj, value)
    if not value or not value.type then
        return L["None"]
    end
    local objectType = WowVision.objects.types:get(value.type)
    if objectType then
        return objectType:getDefinitionLabel(value.params)
    end
    return value.type
end

-- Helper to persist and emit change event
function ObjectField:onObjectChanged(obj)
    local value = obj[self.key]
    if self.persist and obj.db then
        -- Deep copy for persistence
        local dbValue = nil
        if value then
            dbValue = {
                type = value.type,
                params = {},
            }
            if value.params then
                for k, v in pairs(value.params) do
                    dbValue.params[k] = v
                end
            end
        end
        obj.db[self.key] = dbValue
    end
    self.events.valueChange:emit(obj, self.key, value)
end

-- Set the object value
function ObjectField:set(obj, value)
    obj[self.key] = self:validate(value)
    self:onObjectChanged(obj)
end

-- Set just the type, resetting params to defaults
function ObjectField:setType(obj, typeKey)
    local value = obj[self.key] or { type = nil, params = {} }
    value.type = typeKey
    -- Reset params to defaults for new type
    value.params = {}
    if typeKey then
        local objectType = WowVision.objects.types:get(typeKey)
        if objectType and objectType.parameters then
            -- Get default values from parameter fields
            for _, field in ipairs(objectType.parameters.fields) do
                local default = field:getDefault({})
                if default ~= nil then
                    value.params[field.key] = default
                end
            end
        end
    end
    obj[self.key] = value
    self:onObjectChanged(obj)
end

-- Set a specific param value
function ObjectField:setParam(obj, paramKey, paramValue)
    local value = obj[self.key] or { type = nil, params = {} }
    value.params[paramKey] = paramValue
    obj[self.key] = value
    self:onObjectChanged(obj)
end

-- Restore from DB
function ObjectField:setDB(obj, db)
    obj.db = nil -- Temporarily disable to avoid re-persisting
    local dbValue = db[self.key]
    if dbValue then
        self:set(obj, dbValue)
    else
        self:set(obj, self:getDefault(obj))
    end
    obj.db = db
end

-- UI Generation

-- Lazily register virtual elements on first use (UI must be loaded by then)
function ObjectField:ensureVirtualElements()
    local gen = WowVision.ui.generator
    if gen:hasElement("ObjectField/editor") then
        return
    end

    gen:Element("ObjectField/editor", function(props)
        return props.objectField:buildEditor(props.obj)
    end)

    gen:Element("ObjectField/typeSelector", function(props)
        return props.objectField:buildTypeSelector(props.obj)
    end)
end

-- Build the type selector list
function ObjectField:buildTypeSelector(obj)
    local objectField = self
    local children = {}

    -- "None" option
    tinsert(children, {
        "Button",
        key = "none",
        label = L["None"],
        events = {
            click = function(event, button)
                objectField:setType(obj, nil)
                button.context:pop()
            end,
        },
    })

    -- Add all registered object types
    for _, objectType in ipairs(WowVision.objects.types.items) do
        local typeKey = objectType.key
        local typeLabel = objectType.label or typeKey
        tinsert(children, {
            "Button",
            key = typeKey,
            label = typeLabel,
            events = {
                click = function(event, button)
                    objectField:setType(obj, typeKey)
                    button.context:pop()
                end,
            },
        })
    end

    return {
        "List",
        label = L["Select Type"],
        children = children,
    }
end

-- Build the editor panel
function ObjectField:buildEditor(obj)
    local objectField = self
    local value = objectField:get(obj) or { type = nil, params = {} }
    local children = {}

    -- Type selector button (label is computed fresh each regeneration)
    local typeLabel = value.type and (WowVision.objects.types:get(value.type).label or value.type) or L["None"]
    tinsert(children, {
        "Button",
        key = "type",
        label = L["Type"] .. ": " .. typeLabel,
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "ObjectField/typeSelector",
                    objectField = objectField,
                    obj = obj,
                })
            end,
        },
    })

    -- Params editor (if type is selected)
    if value.type then
        local objectType = WowVision.objects.types:get(value.type)
        if objectType and objectType.parameters and #objectType.parameters.fields > 0 then
            local paramsProxy = objectField:createParamsProxy(obj)
            local paramsGen = objectType.parameters:getGenerator(paramsProxy)
            paramsGen.key = "params"
            paramsGen.label = L["Parameters"]
            tinsert(children, paramsGen)
        end
    end

    return {
        "List",
        label = objectField:getLabel() or objectField.key,
        children = children,
    }
end

-- Creates a proxy for params that redirects writes through setParam
function ObjectField:createParamsProxy(obj)
    local objectField = self
    return setmetatable({}, {
        __index = function(t, k)
            local value = obj[objectField.key] or { type = nil, params = {} }
            return value.params[k]
        end,
        __newindex = function(t, k, v)
            objectField:setParam(obj, k, v)
        end,
    })
end

-- Returns a button that opens the object editor
function ObjectField:getGenerator(obj)
    self:ensureVirtualElements()
    local objectField = self
    local value = self:get(obj)
    local label = self:getLabel() or self.key
    local valueStr = self:getValueString(obj, value)

    return {
        "Button",
        label = label .. ": " .. valueStr,
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "ObjectField/editor",
                    objectField = objectField,
                    obj = obj,
                })
            end,
        },
    }
end
