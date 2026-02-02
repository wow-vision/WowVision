local L = WowVision:getLocale()

local TrackedBuffer = WowVision.buffers:createType("Tracked")
TrackedBuffer.info:addFields({
    {
        key = "source",
        type = "TrackingConfig",
        label = L["Source"],
    },
})

function TrackedBuffer:initialize(obj)
    self.objectToItem = {} -- Maps Object -> ObjectItem for removal (must be before parent.initialize which calls onSetInfo)
    WowVision.buffers.Buffer.initialize(self, obj)

    -- Subscribe to source field changes to restart tracking
    local sourceField = self.class.info:getField("source")
    sourceField.events.valueChange:subscribe(self, function(subscriber, event, target, key, value)
        if target == self then
            subscriber:restartTracking()
        end
    end)
end

-- Deep copy a table
local function deepCopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = deepCopy(v)
    end
    return copy
end

function TrackedBuffer:restartTracking()
    -- Clean up existing tracker
    if self.tracker then
        self:cleanupTracker()
    end

    -- Validate source config before tracking
    if not self.source or not self.source.type then
        return
    end
    -- For UnitTypes, need valid units array
    if self.source.units then
        if #self.source.units == 0 or (self.source.units[1] == nil or self.source.units[1] == "") then
            return
        end
    end

    -- Deep copy config so tracker has stable reference
    local configCopy = deepCopy(self.source)
    self.tracker = WowVision.objects:track(configCopy)

    -- Populate from existing tracked objects
    for object, _ in pairs(self.tracker.items) do
        self:onTrackerAdd(self.tracker, object)
    end

    -- Subscribe to future changes
    self.tracker.events.add:subscribe(self, function(subscriber, event, tracker, object)
        subscriber:onTrackerAdd(tracker, object)
    end)
    self.tracker.events.remove:subscribe(self, function(subscriber, event, tracker, object)
        subscriber:onTrackerRemove(tracker, object)
    end)
    self.tracker.events.modify:subscribe(self, function(subscriber, event, tracker, object)
        subscriber:onTrackerModify(tracker, object)
    end)
end

function TrackedBuffer:onSetInfo()
    -- Use restartTracking to set up the tracker
    self:restartTracking()
end

function TrackedBuffer:cleanupTracker()
    if self.tracker then
        self.tracker.events.add:unsubscribe(self)
        self.tracker.events.remove:unsubscribe(self)
        self.tracker.events.modify:unsubscribe(self)
        self.tracker:untrack()
        self.tracker = nil
    end
    -- Clear existing items
    self.objectToItem = {}
    self.items = {}
end

function TrackedBuffer:onTrackerAdd(tracker, object)
    local item = WowVision.buffers.ObjectItem:new({ object = object })
    self.objectToItem[object] = item
    WowVision.buffers.Buffer.add(self, item)
end

function TrackedBuffer:onTrackerRemove(tracker, object)
    local item = self.objectToItem[object]
    if item then
        self.objectToItem[object] = nil
        WowVision.buffers.Buffer.remove(self, item)
    end
end

function TrackedBuffer:onTrackerModify(tracker, object)
    -- Object data changed, emit modify event if we have one
    local item = self.objectToItem[object]
    if item and self.events.modify then
        self.events.modify:emit(self, item)
    end
end

function TrackedBuffer:unsubscribe()
    self:cleanupTracker()
end

function TrackedBuffer:getTracker()
    return self.tracker
end
