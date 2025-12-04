local Event = WowVision.Class("Event")

function Event:initialize(name)
    self.name = name
    self.subscribers = {}
    self.handlers = {} --for handlers without an attached subscriber object
end

function Event:emit(...)
    for subscriber, handlers in pairs(self.subscribers) do
        --Keep a list of handlers to prevent infinite recursion (if another event subscribes as part of an event handler)
        local handlerList = {}
        for _, handler in ipairs(handlers) do
            tinsert(handlerList, handler)
        end
        for _, handler in ipairs(handlerList) do
            handler(subscriber, self.name, ...)
        end
    end

    local handlerList = {}
    for _, handler in ipairs(self.handlers) do
        tinsert(handlerList, handler)
    end

    for _, handler in ipairs(handlerList) do
        handler(self.name, ...)
    end
end

function Event:subscribe(subscriber, handler)
    if subscriber == nil then
        tinsert(self.handlers, handler)
        return
    end
    if self.subscribers[subscriber] == nil then
        self.subscribers[subscriber] = { handler }
        return
    end
    table.insert(self.subscribers[subscriber], handler)
end

function Event:unsubscribe(subscriber, handler)
    if subscriber == nil then
        for i, v in ipairs(self.handlers) do
            table.remove(self.handlers, i)
            return
        end
    end
    self.subscribers[subscriber] = nil
end

WowVision.Event = Event
