local TrackedBuffer = WowVision.buffers:createType("Tracked")
TrackedBuffer.info:addFields({
    { key = "source" },
})

function TrackedBuffer:initialize(obj)
    WowVision.buffers.Buffer.initialize(self, obj)
    self.objectToItem = {} -- Maps Object -> ObjectItem for removal

    if self.source then
        -- Populate from existing tracked objects
        for object, _ in pairs(self.source.items) do
            self:onSourceAdd(self.source, object)
        end

        -- Subscribe to future changes
        self.source.events.add:subscribe(self, function(subscriber, event, source, object)
            subscriber:onSourceAdd(source, object)
        end)
        self.source.events.remove:subscribe(self, function(subscriber, event, source, object)
            subscriber:onSourceRemove(source, object)
        end)
        self.source.events.modify:subscribe(self, function(subscriber, event, source, object)
            subscriber:onSourceModify(source, object)
        end)
    end
end

function TrackedBuffer:onSourceAdd(source, object)
    local item = WowVision.buffers.ObjectItem:new({ object = object })
    self.objectToItem[object] = item
    WowVision.buffers.Buffer.add(self, item)
end

function TrackedBuffer:onSourceRemove(source, object)
    local item = self.objectToItem[object]
    if item then
        self.objectToItem[object] = nil
        WowVision.buffers.Buffer.remove(self, item)
    end
end

function TrackedBuffer:onSourceModify(source, object)
    -- Object data changed, emit modify event if we have one
    local item = self.objectToItem[object]
    if item and self.events.modify then
        self.events.modify:emit(self, item)
    end
end

function TrackedBuffer:unsubscribe()
    if self.source then
        self.source.events.add:unsubscribe(self)
        self.source.events.remove:unsubscribe(self)
        self.source.events.modify:unsubscribe(self)
    end
end

function TrackedBuffer:getSource()
    return self.source
end
