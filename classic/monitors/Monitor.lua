local L = WowVision:getLocale()

local Monitor = WowVision.Class("Monitor")

Monitor:addFields({
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
    self:applyFields(config)

    -- Subscribe to tracking field changes to flag tracking for restart
    for _, key in ipairs(self:getTrackingFields()) do
        local field = self.class:getField(key)
        if field then
            field.events.valueChange:subscribe(self, function(self, event, target, fieldKey, value)
                if target == self then
                    self._trackingDirty = true
                end
            end)
        end
    end

    -- Subscribe to rules array changes (add/remove)
    local rulesField = self.class:getField("rules")
    if rulesField then
        rulesField.events.valueChange:subscribe(self, function(self, event, target, fieldKey, value)
            if target == self then
                self:onRulesChanged(value)
            end
        end)
    end

    -- Subscribe to initial rules' trackingDirty events
    if self.rules and #self.rules > 0 then
        self:onRulesChanged(self.rules)
    end
end

function Monitor:onSetInfo()
    -- Mark that tracking needs to be started/restarted on next update
    self._trackingDirty = true
end

function Monitor:onRulesChanged(rules)
    -- Unsubscribe from old rules
    for _, rule in ipairs(self._subscribedRules or {}) do
        rule.events.trackingDirty:unsubscribe(self)
    end
    -- Subscribe to new rules
    for _, rule in ipairs(rules or {}) do
        rule.events.trackingDirty:subscribe(self, function(self, event, rule)
            self._trackingDirty = true
        end)
    end
    self._subscribedRules = rules
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

function Monitor:onSetDB()
    self:onRulesChanged(self.rules or {})
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
