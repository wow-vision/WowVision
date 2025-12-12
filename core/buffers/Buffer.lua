local Buffer = WowVision.Class("Buffer")
Buffer:include(WowVision.ViewList)

function Buffer:initialize(obj)
    obj = obj or {}
    self.key = obj.key
    self.label = obj.label
    self:setupViewList()
    self.allowRefocus = true
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

function Buffer:deserialize(data)
    self:setLabel(data.label or "")
    self:setEnabled(data.enabled or true)
    self:clear()
end

function Buffer:serialize()
    return {
        label = self:getLabel(),
        enabled = self:getEnabled(),
    }
end

local buffers = {
    Buffer = Buffer,
    types = WowVision.Registry:new(),
}

function buffers:createType(key)
    local class = WowVision.Class(key .. "Buffer", self.Buffer)
    self.types:register(key, class)
    return class
end

function buffers:create(typeKey, params)
    local bufferType = self.types:get(typeKey)
    if not bufferType then
        error("Unknown buffer type: " .. typeKey)
    end
    return bufferType:new(params)
end

WowVision.buffers = buffers
