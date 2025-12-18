local MessageBufferView, parent = WowVision.ui:CreateElementType("MessageBufferView", "Widget")

-- Define InfoClass fields at class level
MessageBufferView.info:addFields({
    {
        key = "buffer",
        default = nil,
        compareMode = "direct",
        set = function(obj, key, value)
            obj:setBuffer(value)
        end,
    },
})

-- Override inherited defaults
MessageBufferView.info:updateFields({
    { key = "displayType", default = "List" },
})

function MessageBufferView:initialize()
    parent.initialize(self)
    self.index = -1
end

function MessageBufferView:setBuffer(buffer)
    if self.buffer then
        self.buffer.events.remove:unsubscribe(self)
    end
    self.buffer = buffer
    self.index = -1
end

function MessageBufferView:onFocus()
    if self.buffer then
        self.buffer.events.remove:subscribe(self, function(self, event, source, item)
            if self.index > #self.buffer.items then
                self.index = #self.buffer.items
            end
            if self.index < 1 and #self.buffer.items > 0 then
                self.index = 1
            end
        end)
        if #self.buffer.items > 0 then
            self.index = #self.buffer.items
        end
        self:announceMessage()
    end
end

function MessageBufferView:onUnfocus()
    if self.buffer then
        self.buffer.events.remove:unsubscribe(self)
    end
end

function MessageBufferView:announceMessage()
    local item = self.buffer.items[self.index]
    if item then
        WowVision:speak(item:getFocusString())
    end
end

function MessageBufferView:onBindingPressed(binding)
    if binding.key == "home" and #self.buffer.items > 0 and self.index > 1 then
        self.index = 1
        self:announceMessage()
        return true
    elseif binding.key == "end" and self.index > 0 and self.index < #self.buffer.items then
        self.index = #self.buffer.items
        self:announceMessage()
        return true
    elseif binding.key == "up" and self.index > 1 then
        self.index = self.index - 1
        self:announceMessage()
        return true
    elseif binding.key == "down" and self.index < #self.buffer.items then
        self.index = self.index + 1
        self:announceMessage()
        return true
    end
    return false
end
