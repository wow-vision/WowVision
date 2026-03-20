local L = WowVision:getLocale()

local Monitor = WowVision.Class("Monitor"):include(WowVision.InfoClass)

Monitor.info:addFields({
    { key = "enabled", type = "Bool", default = true, persist = true, label = L["Enabled"], sortPriority = 1 },
    { key = "label", type = "String", persist = true, label = L["Label"], sortPriority = 1 },
    {
        key = "rules",
        type = "ComponentArray",
        persist = true,
        label = L["Rules"],
        sortPriority = 3,
        factory = function(config)
            return WowVision.monitors.ruleRegistry:createTemporaryComponent(config)
        end,
        getTypeKey = function(instance)
            local className = instance.class.name
            if className:sub(-4) == "Rule" then
                return className:sub(1, -5)
            end
            return className
        end,
        availableTypes = function()
            return {}
        end,
    },
})

function Monitor:initialize(config)
    self.trackedObjects = {}
    self.pendingEvents = {}
    self.tracker = nil
    self:setInfo(config)

    -- Subscribe to tracking field changes to flag tracking for restart
    for _, key in ipairs(self:getTrackingFields()) do
        local field = self.class.info:getField(key)
        if field then
            field.events.valueChange:subscribe(self, function(self, event, target, fieldKey, value)
                if target == self then
                    self._trackingDirty = true
                end
            end)
        end
    end
end

function Monitor:onSetInfo()
    -- Mark that tracking needs to be started/restarted on next update
    self._trackingDirty = true
end

function Monitor:getTrackingFields()
    return {}
end

function Monitor:createTracker()
    return nil
end

function Monitor:restartTracking()
    if self.tracker then
        self:cleanupTracker()
    end

    if not self.rules or #self.rules == 0 then
        return
    end

    self.tracker = self:createTracker()
    if not self.tracker then
        return
    end

    -- Populate from existing tracked objects and notify rules
    for object, _ in pairs(self.tracker.items) do
        self.trackedObjects[object] = true
        tinsert(self.pendingEvents, { type = "add", object = object })
    end

    -- Subscribe to future changes
    self.tracker.events.add:subscribe(self, function(self, event, tracker, object)
        self.trackedObjects[object] = true
        tinsert(self.pendingEvents, { type = "add", object = object })
    end)
    self.tracker.events.remove:subscribe(self, function(self, event, tracker, object)
        self.trackedObjects[object] = nil
        tinsert(self.pendingEvents, { type = "remove", object = object })
    end)
    self.tracker.events.unitsChanged:subscribe(self, function(self, event, tracker, unitId, guid)
        self:onUnitsChanged(unitId, guid)
    end)
end

function Monitor:onUnitsChanged(unitId, guid)
    -- Override in subclasses
end

function Monitor:cleanupTracker()
    if self.tracker then
        self.tracker.events.add:unsubscribe(self)
        self.tracker.events.remove:unsubscribe(self)
        self.tracker.events.unitsChanged:unsubscribe(self)
        self.tracker:untrack()
        self.tracker = nil
    end
    self.trackedObjects = {}
    self.pendingEvents = {}
    -- Reset all rules
    for _, rule in ipairs(self.rules or {}) do
        if rule.reset then
            rule:reset()
        end
    end
end

function Monitor:update()
    if not self.enabled then
        return
    end
    if self._trackingDirty then
        self._trackingDirty = false
        self:restartTracking()
    end
    if not self.tracker then
        return
    end

    local rules = self.rules
    if not rules then
        return
    end

    -- Pass buffered events to rules
    if #self.pendingEvents > 0 then
        for _, evt in ipairs(self.pendingEvents) do
            for _, rule in ipairs(rules) do
                if rule.enabled then
                    if evt.type == "add" and rule:matches(evt.object) then
                        rule:onObjectAdd(evt.object)
                    elseif evt.type == "remove" then
                        -- Don't filter removes through matches() — object data may
                        -- already be cleared. Let the rule decide if it was tracking it.
                        rule:onObjectRemove(evt.object)
                    end
                end
            end
        end
        self.pendingEvents = {}
    end

    -- Let each rule update (time-based state transitions)
    for _, rule in ipairs(rules) do
        if rule.enabled and rule.update then
            rule:update()
        end
    end
end

function Monitor:getLabel()
    return self.label or self.class.name
end

function Monitor:getDefaultDBRecursive()
    local db = self.class.info:getData(self)
    local rulesField = self.class.info:getField("rules")
    if rulesField and self.rules then
        db.rules = { _type = "array" }
        for _, rule in ipairs(self.rules) do
            tinsert(db.rules, rule:getDefaultDBRecursive())
        end
    end
    return db
end

function Monitor:setDB(db)
    self.db = db
    self.class.info:setDB(self, db)
    self._trackingDirty = true
end

function Monitor:getSettingsGenerator()
    return self.class.info:getGenerator(self)
end

-- Component registry for monitor types
local registry = WowVision.components.createRegistry({
    path = "monitors/monitor",
    type = "class",
    baseClass = Monitor,
    classNameSuffix = "Monitor",
})

WowVision.monitors.Monitor = Monitor
WowVision.monitors.registry = registry

function WowVision.monitors:createType(key)
    return registry:createType({ key = key })
end

function WowVision.monitors:create(typeKey, params)
    params = params or {}
    params.type = typeKey
    return registry:createTemporaryComponent(params)
end
