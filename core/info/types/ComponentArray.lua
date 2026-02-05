local info = WowVision.info
local L = WowVision:getLocale()

local ComponentArrayField, parent = info:CreateFieldClass("ComponentArray")

function ComponentArrayField:setup(config)
    parent.setup(self, config)

    if not config.factory then
        error("ComponentArray field must have a 'factory' function.")
    end
    self.factory = config.factory

    if not config.getTypeKey then
        error("ComponentArray field must have a 'getTypeKey' function.")
    end
    self.getTypeKey = config.getTypeKey

    -- Available types for UI selector
    -- Can be array of strings: { "Static", "Tracked" }
    -- Or array of tables: { { key = "Static", label = "Static Buffer" }, ... }
    self.availableTypes = config.availableTypes or {}
end

function ComponentArrayField:getInfo()
    local result = parent.getInfo(self)
    result.factory = self.factory
    result.getTypeKey = self.getTypeKey
    result.availableTypes = self.availableTypes
    return result
end

function ComponentArrayField:getData(obj)
    local result = { _type = "array" }
    for _, item in ipairs(obj[self.key] or {}) do
        local config = item.info:getData(item)
        config.type = self.getTypeKey(item)
        tinsert(result, config)
    end
    return result
end

-- Runtime: return the instances array
function ComponentArrayField:get(obj)
    return obj[self.key] or {}
end

-- Set array - accepts instances or configs (configs are transformed via factory)
function ComponentArrayField:set(obj, value)
    if not value then
        obj[self.key] = {}
    else
        local instances = {}
        for _, item in ipairs(value) do
            if type(item) == "table" and item.class then
                -- Already an instance
                tinsert(instances, item)
            else
                -- Config, create instance via factory
                local instance = self.factory(item)
                tinsert(instances, instance)
            end
        end
        obj[self.key] = instances
    end
    self:onArrayChanged(obj)
end

-- Helper to persist array to db and emit change event
function ComponentArrayField:onArrayChanged(obj)
    local instances = obj[self.key] or {}
    if self.persist and obj.db then
        obj.db[self.key] = self:instancesToConfigs(instances)
    end
    self.events.valueChange:emit(obj, self.key, instances)
end

-- Convert instances array to config array for persistence
function ComponentArrayField:instancesToConfigs(instances)
    local result = { _type = "array" }
    for _, instance in ipairs(instances) do
        local config = instance.class.info:getDefaultDB(instance)
        config.type = self.getTypeKey(instance)
        tinsert(result, config)
    end
    return result
end

-- Default is empty array
function ComponentArrayField:getDefault(obj)
    return {}
end

-- Persist: convert instances → configs
function ComponentArrayField:getDefaultDB(obj)
    local instances = obj[self.key] or {}
    return self:instancesToConfigs(instances)
end

-- Restore: convert configs → instances
function ComponentArrayField:setDB(obj, db)
    obj.db = nil -- Temporarily disable to avoid re-persisting
    local configs = db[self.key] or {}
    local instances = {}
    for _, config in ipairs(configs) do
        local instance = self.factory(config)
        -- Call child's setDB to properly link instance to its DB entry
        -- This sets up instance.db and restores nested fields
        if instance.setDB then
            instance:setDB(config)
        else
            instance.db = config
        end
        tinsert(instances, instance)
    end
    obj[self.key] = instances
    obj.db = db
end

-- Add element: accepts instance or config
function ComponentArrayField:addElement(obj, instanceOrConfig)
    local instance
    -- Check if it's already an instance (has a class)
    if type(instanceOrConfig) == "table" and instanceOrConfig.class then
        instance = instanceOrConfig
    else
        -- Config, create instance via factory
        instance = self.factory(instanceOrConfig)
    end

    local arr = obj[self.key]
    if not arr then
        arr = {}
        obj[self.key] = arr
    end
    tinsert(arr, instance)

    -- Persist
    if obj.db then
        local dbArr = obj.db[self.key]
        if not dbArr then
            dbArr = {}
            obj.db[self.key] = dbArr
        end
        local config = instance.class.info:getDefaultDB(instance)
        config.type = self.getTypeKey(instance)
        tinsert(dbArr, config)
        instance.db = dbArr[#dbArr]
    end

    self.events.valueChange:emit(obj, self.key, arr)
    return #arr
end

-- Remove element at index
function ComponentArrayField:removeElement(obj, index)
    local arr = obj[self.key]
    if arr and arr[index] then
        local removed = tremove(arr, index)
        if obj.db and obj.db[self.key] then
            tremove(obj.db[self.key], index)
        end
        self.events.valueChange:emit(obj, self.key, arr)
        return removed
    end
    return nil
end

-- Get array length
function ComponentArrayField:getLength(obj)
    local arr = obj[self.key]
    if arr then
        return #arr
    end
    return 0
end

-- Value string for display
function ComponentArrayField:getValueString(obj, value)
    if not value then
        return "0 items"
    end
    return #value .. " items"
end

-- UI Generation

-- Lazily register virtual elements on first use
function ComponentArrayField:ensureVirtualElements()
    local gen = WowVision.ui.generator
    if gen:hasElement("ComponentArrayField/list") then
        return
    end

    gen:Element("ComponentArrayField/list", function(props)
        return props.field:buildList(props.obj)
    end)

    gen:Element("ComponentArrayField/item", function(props)
        return props.field:buildItem(props.obj, props.index)
    end)

    gen:Element("ComponentArrayField/typeSelector", function(props)
        return props.field:buildTypeSelector(props.obj)
    end)
end

-- Get label for a type (handles both string and table formats)
function ComponentArrayField:getTypeLabel(typeEntry)
    if type(typeEntry) == "table" then
        return typeEntry.label or typeEntry.key
    end
    return typeEntry
end

-- Get key for a type (handles both string and table formats)
function ComponentArrayField:getTypeKeyFromEntry(typeEntry)
    if type(typeEntry) == "table" then
        return typeEntry.key
    end
    return typeEntry
end

-- Main list view
function ComponentArrayField:buildList(obj)
    local field = self
    local instances = self:get(obj)
    local children = {}

    -- List existing components
    for i, instance in ipairs(instances) do
        local itemLabel = instance:getLabel() or ("Item " .. i)
        tinsert(children, {
            "Button",
            key = "item_" .. i,
            label = itemLabel,
            events = {
                click = function(event, button)
                    button.context:addGenerated({
                        "ComponentArrayField/item",
                        field = field,
                        obj = obj,
                        index = i,
                    })
                end,
            },
        })
    end

    -- Add button → opens type selector
    tinsert(children, {
        "Button",
        key = "add",
        label = L["Add"],
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "ComponentArrayField/typeSelector",
                    field = field,
                    obj = obj,
                })
            end,
        },
    })

    return {
        "List",
        label = self:getLabel() or self.key,
        children = children,
    }
end

-- Get available types (handles both table and function)
function ComponentArrayField:getAvailableTypes()
    if type(self.availableTypes) == "function" then
        return self.availableTypes()
    end
    return self.availableTypes
end

-- Type selector for adding new component
function ComponentArrayField:buildTypeSelector(obj)
    local field = self
    local children = {}

    for _, typeEntry in ipairs(self:getAvailableTypes()) do
        local typeKey = self:getTypeKeyFromEntry(typeEntry)
        local typeLabel = self:getTypeLabel(typeEntry)
        tinsert(children, {
            "Button",
            key = typeKey,
            label = typeLabel,
            events = {
                click = function(event, button)
                    -- Create new instance with defaults
                    local newInstance = field.factory({
                        type = typeKey,
                        label = L["New"] .. " " .. typeLabel,
                    })
                    local index = field:addElement(obj, newInstance)

                    -- Pop selector, open editor for new item
                    button.context:pop()
                    button.context:addGenerated({
                        "ComponentArrayField/item",
                        field = field,
                        obj = obj,
                        index = index,
                    })
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

-- Individual component editor
function ComponentArrayField:buildItem(obj, index)
    local field = self
    local instances = self:get(obj)
    local instance = instances[index]

    if not instance then
        return { "List", label = L["Not Found"], children = {} }
    end

    -- Delegate to instance's own settings generator
    local settingsGen = instance:getSettingsGenerator()
    settingsGen.key = "settings"

    return {
        "List",
        label = instance:getLabel() or ("Item " .. index),
        children = {
            settingsGen,
            {
                "Button",
                key = "remove",
                label = L["Remove"],
                events = {
                    click = function(event, button)
                        field:removeElement(obj, index)
                        button.context:pop()
                    end,
                },
            },
        },
    }
end

-- Entry point: button that opens the list
function ComponentArrayField:getGenerator(obj)
    self:ensureVirtualElements()
    local field = self
    local instances = self:get(obj)
    local count = #instances

    return {
        "Button",
        label = (self:getLabel() or self.key) .. " (" .. count .. ")",
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "ComponentArrayField/list",
                    field = field,
                    obj = obj,
                })
            end,
        },
    }
end
