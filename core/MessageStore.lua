-- MessageStore: A simple store for messages with event-based notifications
-- Stores can be registered globally by key for lookup by buffers

local MessageStore = WowVision.Class("MessageStore"):include(WowVision.InfoClass)
MessageStore.info:addFields({
    { key = "messages", default = {} },
    { key = "maxMessages" },
    { key = "getDataString" },
})

function MessageStore:initialize(obj)
    obj = obj or {}
    self:setInfo(obj)
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

WowVision.MessageStore = MessageStore

-- Global registry for MessageStores
WowVision.messageStores = WowVision.Registry:new()

-- Helper to create and register a MessageStore
function WowVision.createMessageStore(key, config)
    local store = MessageStore:new(config)
    WowVision.messageStores:register(key, store)
    return store
end

-- Helper to get a MessageStore by key
function WowVision.getMessageStore(key)
    return WowVision.messageStores:get(key)
end
