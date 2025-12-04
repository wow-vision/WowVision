local Buffer = WowVision.Class("Buffer")
Buffer:include(WowVision.ViewList)

function Buffer:initialize(obj)
    self.key = obj.key
    self.label = obj.label
    self:setupViewList()
    self.allowRefocus = true
end

function Buffer:addObject(typeKey, params)
    local obj = WowVision.objects:create(typeKey, params)
    if obj then
        self:add(WowVision.base.buffers.BufferItem:new(obj))
    end
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

function Buffer:deserialize(data)
    self:setLabel(data.label or "")
    self:setEnabled(data.enabled or true)
    self:clear()
    for _, v in ipairs(data.items) do
        local item = WowVision.base.buffers.BufferItem:new()
        item:deserialize(v)
        self:add(item)
    end
end

function Buffer:serialize()
    local data = {
        label = self:getLabel(),
        enabled = self:getEnabled(),
        items = {},
    }
    for _, v in ipairs(self.items) do
        tinsert(data.items, v:serialize())
    end
end

function Buffer:getFocusString()
    local result = self:getLabel()
    local focus = self:getFocus()
    if focus then
        result = result .. " " .. focus:getFocusString()
    end
    return result
end

WowVision.base.buffers.Buffer = Buffer
