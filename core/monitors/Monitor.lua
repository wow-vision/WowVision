local L = WowVision:getLocale()

local Monitor = WowVision.Class("Monitor"):include(WowVision.InfoClass)

Monitor.info:addFields({
    { key = "enabled", type = "Bool", default = true, persist = true, label = L["Enabled"] },
    { key = "label", type = "String", persist = true, label = L["Label"] },
    {
        key = "rules",
        type = "ComponentArray",
        persist = true,
        label = L["Rules"],
        factory = function(config)
            return WowVision.monitors.ruleRegistry:createTemporaryComponent(config)
        end,
        getTypeKey = function(instance)
            -- ClassRegistryType names classes as key + suffix, e.g., "AuraStateRule"
            -- The type key in the registry is just "AuraState"
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
    self.tracker = nil
    self:setInfo(config)

    -- Subscribe to tracking field changes to restart tracking
    for _, key in ipairs(self:getTrackingFields()) do
        local field = self.class.info:getField(key)
        if field then
            field.events.valueChange:subscribe(self, function(self, event, target, fieldKey, value)
                if target == self then
                    self:restartTracking()
                end
            end)
        end
    end
end

function Monitor:onSetInfo()
    self:restartTracking()
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

    self.tracker = self:createTracker()
    if not self.tracker then
        return
    end

    -- Populate from existing tracked objects
    for object, _ in pairs(self.tracker.items) do
        self.trackedObjects[object] = true
    end

    -- Subscribe to future changes
    self.tracker.events.add:subscribe(self, function(self, event, tracker, object)
        self.trackedObjects[object] = true
    end)
    self.tracker.events.remove:subscribe(self, function(self, event, tracker, object)
        self.trackedObjects[object] = nil
    end)
    self.tracker.events.modify:subscribe(self, function(self, event, tracker, object)
        -- Object data changed; update() will pick it up next frame
    end)

    -- Clear rule states since tracked objects changed
    for _, rule in ipairs(self.rules or {}) do
        if rule.clearObjectStates then
            rule:clearObjectStates()
        end
    end
end

function Monitor:cleanupTracker()
    if self.tracker then
        self.tracker.events.add:unsubscribe(self)
        self.tracker.events.remove:unsubscribe(self)
        self.tracker.events.modify:unsubscribe(self)
        self.tracker:untrack()
        self.tracker = nil
    end
    self.trackedObjects = {}
end

function Monitor:computeObjectState(object)
    return nil
end

function Monitor:update()
    if not self.enabled then
        return
    end
    if not self.tracker then
        return
    end
    self:updateRules()
end

function Monitor:updateRules()
    local rules = self.rules
    if not rules then
        return
    end

    -- For each object, compute state and pass to matching rules
    -- Track which rules matched at least one object this frame
    local rulesMatched = {}

    for object, _ in pairs(self.trackedObjects) do
        local state = self:computeObjectState(object)
        if state then
            for _, rule in ipairs(rules) do
                if rule.enabled and rule:matches(object) then
                    rulesMatched[rule] = true
                    if rule.setObjectState then
                        rule:setObjectState(object, state)
                    end
                end
            end
        end
    end

    -- For rules that didn't match any object this frame, check for removals
    for _, rule in ipairs(rules) do
        if rule.enabled and rule.objectStates then
            for object, _ in pairs(rule.objectStates) do
                if not self.trackedObjects[object] then
                    if rule.removeObject then
                        rule:removeObject(object)
                    end
                end
            end
        end
    end
end

function Monitor:getLabel()
    return self.label or self.class.name
end

function Monitor:getDefaultDBRecursive()
    local db = self.class.info:getData(self)
    -- Include rule defaults with their alerts
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
