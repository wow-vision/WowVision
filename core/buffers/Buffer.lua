local Buffer = WowVision.Class("Buffer"):include(WowVision.InfoClass)
Buffer:include(WowVision.ViewList)
Buffer.info:addFields({
    { key = "key" },
    { key = "label", type = "String" },
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

local buffers = {
    Buffer = Buffer,
    types = WowVision.Registry:new(),
}

function buffers:createType(key)
    local class = WowVision.Class(key .. "Buffer", self.Buffer):include(WowVision.InfoClass)
    self.types:register(key, class)
    return class, self.Buffer
end

function buffers:create(typeKey, params)
    local bufferType = self.types:get(typeKey)
    if not bufferType then
        error("Unknown buffer type: " .. typeKey)
    end
    return bufferType:new(params)
end

WowVision.buffers = buffers
