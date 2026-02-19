local info = WowVision.info
local L = WowVision:getLocale()

local TrackingConfigField, parent = info:CreateFieldClass("TrackingConfig")

function TrackingConfigField:setup(config)
    parent.setup(self, config)
    self.requireUnique = config.requireUnique or false
end

-- Value is { type = "Health", units = { "player" }, ... }
-- Structure varies by object type (UnitType uses units array, others use params)
function TrackingConfigField:getDefault(obj)
    return { type = nil }
end

function TrackingConfigField:validate(value)
    if value == nil then
        return { type = nil }
    end
    if type(value) ~= "table" then
        return { type = nil }
    end
    -- If it's an Object instance (has a class), pass through directly
    if value.class then
        return value
    end
    -- Keep all fields from value, just ensure type exists
    local result = {}
    for k, v in pairs(value) do
        result[k] = v
    end
    if result.type == nil then
        result.type = nil
    end
    return result
end

function TrackingConfigField:getValueString(obj, value)
    if not value or not value.type then
        return L["None"]
    end
    local objectType = WowVision.objects.types:get(value.type)
    if objectType then
        -- For UnitType, show units; for others show type label
        if value.units and #value.units > 0 then
            return (objectType.label or value.type) .. " (" .. table.concat(value.units, ", ") .. ")"
        end
        return objectType.label or value.type
    end
    return value.type
end

-- Helper to persist and emit change event
function TrackingConfigField:onConfigChanged(obj)
    local value = obj[self.key]
    if self.persist and obj.db then
        obj.db[self.key] = WowVision.info.deepCopy(value)
    end
    self.events.valueChange:emit(obj, self.key, value)
end

-- Set the tracking config value
function TrackingConfigField:set(obj, value)
    local oldValue = obj[self.key]
    local newValue = self:validate(value)

    -- Check if value actually changed
    if WowVision.info.valuesEqual(oldValue, newValue) then
        return false
    end

    obj[self.key] = newValue
    self:onConfigChanged(obj)
    return true
end

-- Set just the type, resetting config to defaults
function TrackingConfigField:setType(obj, typeKey)
    local oldValue = obj[self.key]
    -- If type isn't changing, don't reset config
    if oldValue and oldValue.type == typeKey then
        return false
    end

    local value = { type = typeKey }
    if typeKey then
        local objectType = WowVision.objects.types:get(typeKey)
        if objectType then
            -- Get defaults from getTrackingGenerator
            local _, defaultConfig = objectType:getTrackingGenerator()
            for k, v in pairs(defaultConfig) do
                value[k] = v
            end
            value.type = typeKey
            -- Populate parameter field defaults for params not already at top level
            if objectType.parameters and value.params then
                for _, paramField in ipairs(objectType.parameters.fields) do
                    if value[paramField.key] == nil and value.params[paramField.key] == nil then
                        local default = paramField:getDefault(value.params)
                        if default ~= nil then
                            value.params[paramField.key] = default
                        end
                    end
                end
            end
        end
    end
    obj[self.key] = value
    self:onConfigChanged(obj)
    return true
end

-- Restore from DB
function TrackingConfigField:setDB(obj, db)
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

-- Build flat params table from a TrackingConfig for validation
local function buildParamsFromConfig(config)
    local params = {}
    if config.units and config.units[1] then
        params.unit = config.units[1]
    end
    if config.params then
        for k, v in pairs(config.params) do
            params[k] = v
        end
    end
    return params
end

-- Lazily register virtual elements on first use (UI must be loaded by then)
function TrackingConfigField:ensureVirtualElements()
    local gen = WowVision.ui.generator
    if gen:hasElement("TrackingConfigField/editor") then
        return
    end

    gen:Element("TrackingConfigField/editor", function(props)
        return props.field:buildEditor(props.obj)
    end)

    gen:Element("TrackingConfigField/typeSelector", function(props)
        return props.field:buildTypeSelector(props.obj)
    end)

    gen:Element("TrackingConfigField/paramsEditor", function(props)
        local trackingGen, _ = props.objectType:getTrackingGenerator(props.editCopy)

        tinsert(trackingGen.children, {
            "Button",
            key = "save",
            label = L["Save"],
            events = {
                click = function(event, saveButton)
                    local params = buildParamsFromConfig(props.editCopy)
                    local valid, unique = props.objectType:validParams(params)
                    if not valid then
                        WowVision:speak(L["Invalid parameters"])
                        return
                    end
                    if props.field.requireUnique and not unique then
                        WowVision:speak(L["Parameters must identify a single object"])
                        return
                    end
                    props.field:set(props.obj, props.editCopy)
                    saveButton.context:pop()
                end,
            },
        })

        return trackingGen
    end)
end

-- Build the type selector list
function TrackingConfigField:buildTypeSelector(obj)
    local field = self
    local children = {}

    -- "None" option
    tinsert(children, {
        "Button",
        key = "none",
        label = L["None"],
        events = {
            click = function(event, button)
                field:setType(obj, nil)
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
                    field:setType(obj, typeKey)
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

-- Build just the type dropdown button
function TrackingConfigField:buildTypeButton(obj)
    self:ensureVirtualElements()
    local field = self
    local value = field:get(obj) or { type = nil }
    local typeLabel = value.type and (WowVision.objects.types:get(value.type).label or value.type) or L["None"]
    return {
        "Button",
        key = "type",
        label = L["Type"] .. ": " .. typeLabel,
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "TrackingConfigField/typeSelector",
                    field = field,
                    obj = obj,
                })
            end,
        },
    }
end

-- Build a button that pushes to the params editor, or nil if no params
function TrackingConfigField:buildParamsButton(obj)
    self:ensureVirtualElements()
    local field = self
    local value = field:get(obj) or { type = nil }
    if not value.type then
        return nil
    end
    local objectType = WowVision.objects.types:get(value.type)
    if not objectType then
        return nil
    end

    -- Check if there are any params to edit
    local checkCopy = WowVision.info.deepCopy(value)
    local checkGen, _ = objectType:getTrackingGenerator(checkCopy)
    if not checkGen.children or #checkGen.children == 0 then
        return nil
    end

    return {
        "Button",
        key = "params",
        label = L["Parameters"],
        events = {
            click = function(event, button)
                local editCopy = WowVision.info.deepCopy(value)
                button.context:addGenerated({
                    "TrackingConfigField/paramsEditor",
                    objectType = objectType,
                    editCopy = editCopy,
                    field = field,
                    obj = obj,
                })
            end,
        },
    }
end

-- Build the editor panel
function TrackingConfigField:buildEditor(obj)
    local field = self
    local children = {}

    tinsert(children, field:buildTypeButton(obj))

    local paramsButton = field:buildParamsButton(obj)
    if paramsButton then
        tinsert(children, paramsButton)
    end

    return {
        "List",
        label = field:getLabel() or field.key,
        children = children,
    }
end

-- Creates a proxy that redirects writes through the field
function TrackingConfigField:createConfigProxy(obj)
    local field = self
    local value = obj[field.key] or { type = nil }
    local nestedProxies = {}
    local PROXY_MARKER = {} -- Unique marker to identify our proxies

    local function createNestedProxy(tbl, key)
        local proxy = setmetatable({}, {
            __index = function(nt, nk)
                return tbl[nk]
            end,
            __newindex = function(nt, nk, nv)
                local oldValue = tbl[nk]
                if WowVision.info.valuesEqual(oldValue, nv) then
                    return
                end
                tbl[nk] = nv
                field:onConfigChanged(obj)
            end,
            __pairs = function(nt)
                return pairs(tbl)
            end,
        })
        rawset(proxy, PROXY_MARKER, true)
        return proxy
    end

    return setmetatable({}, {
        __index = function(t, k)
            local v = value[k]
            -- Return nested proxy for table values to capture nested writes
            if type(v) == "table" and not rawget(v, PROXY_MARKER) then
                if not nestedProxies[k] then
                    nestedProxies[k] = createNestedProxy(v, k)
                end
                return nestedProxies[k]
            end
            return v
        end,
        __newindex = function(t, k, v)
            -- If assigning a proxy, extract the underlying value
            if type(v) == "table" and rawget(v, PROXY_MARKER) then
                -- Don't store proxies, the value is already in place
                return
            end
            -- Check if value actually changed
            local oldValue = value[k]
            if WowVision.info.valuesEqual(oldValue, v) then
                return
            end
            value[k] = v
            nestedProxies[k] = nil -- Clear cached proxy if value replaced
            field:onConfigChanged(obj)
        end,
        -- Allow pairs() iteration
        __pairs = function(t)
            return pairs(value)
        end,
    })
end

-- Returns a button that opens the tracking config editor
function TrackingConfigField:getGenerator(obj)
    self:ensureVirtualElements()
    local field = self
    local value = self:get(obj)
    local label = self:getLabel() or self.key
    local valueStr = self:getValueString(obj, value)

    return {
        "Button",
        label = label .. ": " .. valueStr,
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "TrackingConfigField/editor",
                    field = field,
                    obj = obj,
                })
            end,
        },
    }
end
