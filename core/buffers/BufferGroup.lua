local BufferGroup = WowVision.Class("BufferGroup")
BufferGroup:include(WowVision.ViewList)

function BufferGroup:initialize()
    self.label = ""
    self.enabled = true
    self:setupViewList()
    self.wrap = true
    self.allowRefocus = true
end

function BufferGroup:getLabel()
    return self.label
end

function BufferGroup:setLabel(label)
    self.label = label
end

function BufferGroup:getEnabled()
    return self.enabled
end

function BufferGroup:setEnabled(enabled)
    self.enabled = enabled
end

function BufferGroup:getFocusString()
    local result = self:getLabel()
    local focus = self:getFocus()
    if focus then
        result = result .. " " .. focus:getFocusString()
    end
    return result
end

function BufferGroup:deserialize(data)
    self:setLabel(data.label or "")
    self:setEnabled(data.enabled or true)
    self:clear()
    for _, v in ipairs(data.buffers) do
        local buffer = WowVision.buffers:create(v.type or "Static", v)
        buffer:deserialize(v)
        self:add(buffer)
    end
end

function BufferGroup:serialize()
    local data = {
        label = self:getLabel(),
        enabled = self:getEnabled(),
        buffers = {},
    }
    for _, v in ipairs(self.items) do
        tinsert(data.buffers, v:serialize())
    end
    return data
end

WowVision.buffers.BufferGroup = BufferGroup
WowVision.buffers.types:register("Group", BufferGroup)
