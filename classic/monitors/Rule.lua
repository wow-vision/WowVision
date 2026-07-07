local L = WowVision:getLocale()

local Rule = WowVision.Class("Rule"):include(WowVision.InfoClass)

Rule.info:addFields({
    { key = "enabled", type = "Bool", default = true, persist = true, label = L["Enabled"], sortPriority = 1 },
    { key = "label", type = "String", persist = true, label = L["Label"], sortPriority = 1 },
})

function Rule:initialize(config)
    self.events = {
        trackingDirty = WowVision.Event:new("trackingDirty"),
    }
    self:setInfo(config)

    -- Subscribe to own tracking-relevant fields
    for _, key in ipairs(self:getTrackingFields()) do
        local field = self.class.info:getField(key)
        if field then
            field.events.valueChange:subscribe(self, function(self, event, target, fieldKey, value)
                if target == self then
                    self.events.trackingDirty:emit(self)
                end
            end)
        end
    end
end

-- Cascade DB to nested fields (Alert/Output linking)
function Rule:setDB(db)
    self.class.info:setDB(self, db)
end

function Rule:getTrackingFields()
    return {}
end

function Rule:matches(object)
    return false
end

-- Called when a matching object is added to the tracker
function Rule:onObjectAdd(object) end

-- Called when a matching object is removed from the tracker
function Rule:onObjectRemove(object) end

-- Called every frame to check time-based state changes
function Rule:update() end

-- Called when the tracker is restarted (target change, etc.)
function Rule:reset() end

function Rule:getLabel()
    return self.label or self.class.name
end

-- Component registry for rule types
local registry = WowVision.components.createRegistry({
    path = "monitors/rule",
    type = "class",
    baseClass = Rule,
    classNameSuffix = "Rule",
})

if not WowVision.monitors then
    WowVision.monitors = {}
end

WowVision.monitors.Rule = Rule
WowVision.monitors.ruleRegistry = registry
