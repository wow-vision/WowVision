local L = WowVision:getLocale()

local Rule = WowVision.Class("Rule"):include(WowVision.InfoClass)

Rule.info:addFields({
    { key = "enabled", type = "Bool", default = true, persist = true, label = L["Enabled"] },
    { key = "label", type = "String", persist = true, label = L["Label"] },
})

function Rule:initialize(config)
    self:setInfo(config)
end

function Rule:matches(object)
    return false
end

function Rule:getLabel()
    return self.label or self.class.name
end

function Rule:getSettingsGenerator()
    return self.class.info:getGenerator(self)
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
