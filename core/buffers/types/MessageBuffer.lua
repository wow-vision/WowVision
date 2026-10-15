local MessageBuffer = WowVision.buffers:createType("Message")
MessageBuffer:addFields({
    { key = "source" },
    { key = "sourceKey" },
})

function MessageBuffer:initialize(obj)
    WowVision.buffers.Buffer.initialize(self, obj)

    if self.source then
        self:attach(self.source)
    elseif self.sourceKey then
        self:attachKey(self.sourceKey)
    end
end

-- Look the source up by key; a store that does not exist yet (a buffer
-- restored at load, its store created on the first tick) is waited for.
function MessageBuffer:attachKey(key)
    local store = WowVision.getMessageStore(key)
    if store then
        self:attach(store)
        return
    end
    WowVision.messageStoreAdded:subscribe(self, function(subscriber, event, addedKey, addedStore)
        if addedKey == subscriber.sourceKey then
            WowVision.messageStoreAdded:unsubscribe(subscriber)
            subscriber:attach(addedStore)
        end
    end)
end

function MessageBuffer:attach(store)
    self.source = store

    -- Populate from existing messages
    for _, data in ipairs(store.messages) do
        local item = WowVision.buffers.MessageItem:new({ data = data, getDataString = store.getDataString })
        WowVision.ViewList.add(self, item)
    end

    -- Subscribe to future changes
    store.events.add:subscribe(self, function(subscriber, event, source, data)
        subscriber:onSourceAdd(source, data)
    end)
    store.events.remove:subscribe(self, function(subscriber, event, source, data, index)
        subscriber:onSourceRemove(source, data, index)
    end)
end

-- Point the buffer at another store: drop the old items and subscriptions.
function MessageBuffer:setSourceKey(key)
    self:unsubscribe()
    self.source = nil
    self:clear()
    self.index = -1
    self.sourceKey = key
    if key then
        self:attachKey(key)
    end
end

function MessageBuffer:onSourceAdd(source, data)
    local item = WowVision.buffers.MessageItem:new({ data = data, getDataString = self.source.getDataString })
    WowVision.buffers.Buffer.add(self, item)
end

function MessageBuffer:onSourceRemove(source, data, index)
    local item = self.items[index]
    if item then
        WowVision.buffers.Buffer.remove(self, item)
    end
end

function MessageBuffer:unsubscribe()
    WowVision.messageStoreAdded:unsubscribe(self)
    if self.source then
        self.source.events.add:unsubscribe(self)
        self.source.events.remove:unsubscribe(self)
    end
end

WowVision.buffers.MessageBuffer = MessageBuffer
