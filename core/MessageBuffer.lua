local MessageBuffer = WowVision.Class("MessageBuffer")

function MessageBuffer:initialize(messages, maxMessages, getDataString)
    self.messages = messages
    self.maxMessages = maxMessages or nil
    self.getDataString = getDataString
    self.events = {
        add = WowVision.Event:new("add"),
        remove = WowVision.Event:new("remove"),
    }
end

function MessageBuffer:add(message)
    if self.maxMessages and #self.messages > self.maxMessages then
        self:remove(1)
    end
    tinsert(self.messages, message)
    self.events.add:emit(self, message)
end

function MessageBuffer:remove(index)
    if index < 1 or index > #self.messages then
        return
    end
    self.events.remove:emit(self, self.messages[index], index)
    table.remove(self.messages, index)
end

function MessageBuffer:getMessageString(index)
    if index < 1 or index > #self.messages then
        return nil
    end
    local data = self.messages[index]
    if type(data) == "table" then
        return self.getDataString(data)
    else
        return data
    end
end

WowVision.MessageBuffer = MessageBuffer
