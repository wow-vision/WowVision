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
        self.buffer.events.remove:subscribe(self, function(self, event, source, message, index)
            if type(index) == "table" then
            end
            if index < self.index then
                self.index = self.index - 1
            end
            if index > #self.buffer.messages then
                self.index = -1
            end
        end)
        if #self.buffer.messages > 0 then
            self.index = #self.buffer.messages
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
    local message = self.buffer:getMessageString(self.index)
    if message then
        WowVision:speak(message)
    end
end

function MessageBufferView:onBindingPressed(binding)
    if binding.key == "home" and #self.buffer.messages > 0 and self.index > 1 then
        self.index = 1
        self:announceMessage()
        return true
    elseif binding.key == "end" and self.index > 0 and self.index < #self.buffer.messages then
        self.index = #self.buffer.messages
        self:announceMessage()
        return true
    elseif binding.key == "up" and self.index > 1 then
        self.index = self.index - 1
        self:announceMessage()
        return true
    elseif binding.key == "down" and self.index < #self.buffer.messages then
        self.index = self.index + 1
        self:announceMessage()
        return true
    end
    return false
end
