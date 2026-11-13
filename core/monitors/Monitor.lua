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
                    self:markTrackingDirty(true)
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

-- Ask for a tracking restart on the next update. resetRules: what is
-- tracked changed (the unit, a rule's spell), so the rules start over and
-- announce the state they find. Without it (a rule added, copied or
-- removed) the rules settle on what they find in silence: the game state
-- did not change, only the list of rules did.
function Monitor:markTrackingDirty(resetRules)
    self._trackingDirty = true
    if resetRules then
        self._resetRulesOnRestart = true
    end
end

function Monitor:onRulesChanged(rules)
    -- Unsubscribe from old rules
    for _, rule in ipairs(self._subscribedRules or {}) do
        rule.events.trackingDirty:unsubscribe(self)
    end
    -- Subscribe to new rules
    for _, rule in ipairs(rules or {}) do
        rule.events.trackingDirty:subscribe(self, function(self, event, rule)
            self:markTrackingDirty(true)
        end)
    end
    self._subscribedRules = rules
    self:markTrackingDirty(false)
end

function Monitor:getTrackingFields()
    return {}
end

function Monitor:createTracker()
    return nil
end

function Monitor:restartTracking()
    local resetRules = self._resetRulesOnRestart
    self._resetRulesOnRestart = nil
    if self.tracker then
        self:cleanupTracker(not resetRules)
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

-- quiet: the rules settle on what the new tracker finds without announcing.
function Monitor:cleanupTracker(quiet)
    if self.tracker then
        self.tracker.events.add:unsubscribe(self)
        self.tracker.events.remove:unsubscribe(self)
        self.tracker.events.unitsChanged:unsubscribe(self)
        self.tracker:untrack()
        self.tracker = nil
    end
    self.trackedObjects = {}
    self.pendingEvents = {}
    -- Start all rules over: announcing, or in silence when quiet
    for _, rule in ipairs(self.rules or {}) do
        if quiet and rule.forget then
            rule:forget()
        elseif rule.reset then
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

-- What a target monitor says when the target changes, for its
-- announceOnUnitChange field: "changes" speaks only what differs from the
-- old target, "always" speaks the new target's state, "never" settles on
-- the new target in silence (later changes on it speak as usual).
WowVision.monitors.TARGET_CHANGE_CHOICES = {
    { value = "changes", label = L["Only Changes"] },
    { value = "always", label = L["Always"] },
    { value = "never", label = L["Never"] },
}

-- The field was a Bool before: a saved false reads as "changes" and a saved
-- true as "always", so old settings keep their meaning without a migration
-- (restore runs through this validate too).
function WowVision.monitors.targetChangeValue(field, value)
    if value == true or value == "always" then
        return "always"
    elseif value == "never" then
        return "never"
    end
    return "changes"
end

-- Point a monitor's rules at a new target per its announceOnUnitChange.
-- Returns the mode it acted on.
function Monitor:rulesOnTargetChange()
    local mode = self.announceOnUnitChange
    for _, rule in ipairs(self.rules or {}) do
        if mode == "always" then
            if rule.reset then
                rule:reset()
            end
            rule._announceRequested = true
        elseif mode == "never" and rule.forget then
            rule:forget()
        end
    end
    return mode
end

function WowVision.monitors:createType(key)
    return registry:createType({ key = key })
end

function WowVision.monitors:create(typeKey, params)
    params = params or {}
    params.type = typeKey
    return registry:createTemporaryComponent(params)
end
