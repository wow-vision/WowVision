local MessageStore = WowVision.Class("MessageStore")

function MessageStore:initialize(obj)
    obj = obj or {}
    self.messages = obj.messages or {}
    self.maxMessages = obj.maxMessages
    self.events = {
        add = WowVision.Event:new("add"),
        remove = WowVision.Event:new("remove"),
    }
end

function MessageStore:add(data)
    if self.maxMessages and #self.messages >= self.maxMessages then
        self:removeIndex(1)
    end
    tinsert(self.messages, data)
    self.events.add:emit(self, data)
end

function MessageStore:removeIndex(index)
    if index < 1 or index > #self.messages then
        return
    end
    local data = table.remove(self.messages, index)
    self.events.remove:emit(self, data, index)
end

function MessageStore:get(index)
    return self.messages[index]
end

function MessageStore:count()
    return #self.messages
end

function MessageStore:clear()
    for i = #self.messages, 1, -1 do
        self:removeIndex(i)
    end
end

function MessageStore:serialize()
    return self.messages
end

function MessageStore:deserialize(data)
    self:clear()
    for _, msg in ipairs(data or {}) do
        self:add(msg)
    end
end

WowVision.buffers.MessageStore = MessageStore
