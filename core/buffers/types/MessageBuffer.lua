local MessageBuffer = WowVision.buffers:createType("Message")

function MessageBuffer:initialize(obj)
    WowVision.buffers.Buffer.initialize(self, obj)
    self.getDataString = obj.getDataString
    self.source = obj.source

    if self.source then
        -- Populate from existing messages
        for _, data in ipairs(self.source.messages) do
            local item = WowVision.buffers.MessageItem:new(data, self.getDataString)
            WowVision.ViewList.add(self, item)
        end

        -- Subscribe to future changes
        self.source.events.add:subscribe(self, function(subscriber, event, source, data)
            subscriber:onSourceAdd(source, data)
        end)
        self.source.events.remove:subscribe(self, function(subscriber, event, source, data, index)
            subscriber:onSourceRemove(source, data, index)
        end)
    end
end

function MessageBuffer:onSourceAdd(source, data)
    local item = WowVision.buffers.MessageItem:new(data, self.getDataString)
    WowVision.buffers.Buffer.add(self, item)
end

function MessageBuffer:onSourceRemove(source, data, index)
    local item = self.items[index]
    if item then
        WowVision.buffers.Buffer.remove(self, item)
    end
end

function MessageBuffer:unsubscribe()
    if self.source then
        self.source.events.add:unsubscribe(self)
        self.source.events.remove:unsubscribe(self)
    end
end
