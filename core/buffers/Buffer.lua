local L = WowVision:getLocale()

local Buffer = WowVision.Class("Buffer"):include(WowVision.InfoClass)
Buffer:include(WowVision.ViewList)
Buffer.info:addFields({
    {
        key = "enabled",
        type = "Bool",
        label = L["Enabled"],
        default = true,
        required = true,
        get = function(obj, key)
            return obj:getEnabled()
        end,
        set = function(obj, key, value)
            obj:setEnabled(value)
        end,
    },
    {
        key = "label",
        type = "String",
        label = L["Label"],
    },
})

function Buffer:initialize(obj)
    obj = obj or {}
    self:setupViewList()
    self.allowRefocus = true
    self.events = {
        add = WowVision.Event:new("add"),
        modify = WowVision.Event:new("modify"),
        remove = WowVision.Event:new("remove"),
    }
    self:setInfo(obj)
end

function Buffer:add(index, item)
    local result = WowVision.ViewList.add(self, index, item)
    if result then
        local addedItem = item or index
        self.events.add:emit(self, addedItem)
    end
    return result
end

function Buffer:remove(item)
    local result = WowVision.ViewList.remove(self, item)
    if result then
        self.events.remove:emit(self, item)
    end
    return result
end

function Buffer:getLabel()
    return self.label
end

function Buffer:setLabel(label)
    self.label = label or ""
end

function Buffer:getEnabled()
    return self.enabled
end

function Buffer:setEnabled(enabled)
    self.enabled = enabled
end

function Buffer:getFocusString()
    local result = self:getLabel()
    local focus = self:getFocus()
    if focus then
        result = result .. " " .. focus:getFocusString()
    end
    return result
end

function Buffer:getDefaultDB()
    return self.info:getDefaultDB(self)
end

function Buffer:setDB(db)
    self.info:setDB(self, db)
end

-- UI Generation

-- Lazily register virtual elements on first use
function Buffer:ensureVirtualElements()
    local gen = WowVision.ui.generator
    if gen:hasElement("Buffer/settings") then
        return
    end

    gen:Element("Buffer/settings", function(props)
        return props.buffer:buildSettings()
    end)
end

-- Build the settings UI
function Buffer:buildSettings()
    return self.class.info:getGenerator(self)
end

-- Returns UI generator for editing this buffer's settings
function Buffer:getSettingsGenerator()
    self:ensureVirtualElements()
    local buffer = self

    return {
        "Buffer/settings",
        buffer = buffer,
    }
end

-- Create component registry for buffer types
local registry = WowVision.components.createRegistry({
    path = "buffers/buffer",
    type = "class",
    baseClass = Buffer,
    classNameSuffix = "Buffer",
})

local buffers = {
    Buffer = Buffer,
    registry = registry,
}

-- Convenience method to create buffer types
function buffers:createType(key)
    local typeClass = registry:createType({ key = key })
    return typeClass, self.Buffer
end

-- Convenience method to create buffer instances
function buffers:create(typeKey, params)
    params = params or {}
    params.type = typeKey
    return registry:createComponent(params)
end

WowVision.buffers = buffers
