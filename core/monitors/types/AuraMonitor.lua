local L = WowVision:getLocale()

local stateOutputs = {
    { type = "Sound", key = "sound", label = L["Sound Alert"], enabled = false },
    { type = "TTS", key = "tts", label = L["TTS Alert"], enabled = false },
}

-- AuraStateRule: extends StateRule with aura-specific fields
local AuraStateRule = WowVision.monitors.ruleRegistry:createType({ key = "AuraState", parent = "State" })

AuraStateRule.info:addFields({
    { key = "spell", type = "Spell", persist = true, label = L["Spell"], sortPriority = 2 },
    { key = "playerOnly", type = "Bool", persist = true, default = true, label = L["Applied by Player"], sortPriority = 2 },
    { key = "pandemicThreshold", type = "Number", persist = true, default = 30, label = L["Pandemic Window (%)"], sortPriority = 2 },
    { key = "expiringThreshold", type = "Number", persist = true, default = 5, label = L["Expiry Threshold (seconds)"], sortPriority = 2 },
    {
        key = "applied",
        type = "Alert",
        persist = true,
        label = L["Applied"],
        sortPriority = 3,
        alert = { key = "applied", label = L["Applied"] },
        outputs = stateOutputs,
    },
    {
        key = "pandemic",
        type = "Alert",
        persist = true,
        label = L["Pandemic"],
        sortPriority = 3,
        alert = { key = "pandemic", label = L["Pandemic"] },
        outputs = stateOutputs,
    },
    {
        key = "expiring",
        type = "Alert",
        persist = true,
        label = L["Expiring"],
        sortPriority = 3,
        alert = { key = "expiring", label = L["Expiring"] },
        outputs = stateOutputs,
    },
    {
        key = "missing",
        type = "Alert",
        persist = true,
        label = L["Missing"],
        sortPriority = 3,
        alert = { key = "missing", label = L["Missing"] },
        outputs = stateOutputs,
    },
})

function AuraStateRule:initialize(config)
    self.trackedObjects = {} -- objects currently matching this rule
    WowVision.monitors.StateRule.initialize(self, config)
end

function AuraStateRule:getTrackingFields()
    return { "spell", "playerOnly" }
end

function AuraStateRule:getStates()
    return {
        { key = "applied" },
        { key = "pandemic", fallback = "applied" },
        { key = "expiring", fallback = "pandemic" },
    }
end

function AuraStateRule:matches(object)
    if not self.spell then
        return false
    end
    local objSpellId = object:get("spellId")
    if objSpellId ~= self.spell then
        return false
    end
    if self.playerOnly then
        local source = object:get("sourceUnit")
        if not source or not (UnitIsUnit(source, "player") or UnitIsUnit(source, "pet")) then
            return false
        end
    end
    return true
end

function AuraStateRule:onObjectAdd(object)
    self.trackedObjects[object] = true
    -- Store the initial duration for pandemic calculation
    -- WoW's duration field can change on aura updates
    local duration = object:get("duration")
    if duration and duration > 0 then
        self._baseDuration = duration
    end
end

function AuraStateRule:onObjectRemove(object)
    if self.trackedObjects[object] then
        self.trackedObjects[object] = nil
    end
end

function AuraStateRule:reset()
    self.trackedObjects = {}
    self._baseDuration = nil
    WowVision.monitors.StateRule.reset(self)
end

function AuraStateRule:computeState(object)
    local duration = self._baseDuration
    local remaining = object:get("remainingDuration")

    if not duration or duration == 0 then
        return "applied"
    end
    if not remaining then
        return "applied"
    end
    if (remaining / duration) * 100 <= (self.pandemicThreshold or 30) then
        if remaining <= (self.expiringThreshold or 5) then
            return "expiring"
        end
        return "pandemic"
    end
    return "applied"
end

function AuraStateRule:update()
    local bestState = nil
    local hasObjects = false

    for object, _ in pairs(self.trackedObjects) do
        hasObjects = true
        local state = self:computeState(object)
        if bestState == nil then
            bestState = state
        elseif state == "applied" then
            bestState = "applied"
        elseif state == "pandemic" and bestState == "expiring" then
            bestState = "pandemic"
        end
    end

    if hasObjects then
        if bestState ~= self:getCurrentState() then
            self:transitionTo(bestState)
        else
            self:updateResolved(bestState)
        end
    else
        if self:getCurrentState() ~= "missing" and (self:getCurrentState() ~= nil or self._announceRequested) then
            self:transitionTo("missing")
        else
            self:updateResolved("missing")
        end
        self._announceRequested = false
    end
end

function AuraStateRule:getLabel()
    if self.label and self.label ~= "" then
        return self.label
    end
    if self.spell then
        local spellField = self.class.info:getField("spell")
        if spellField then
            local valueStr = spellField:getValueString(self, self.spell)
            if valueStr then
                return valueStr
            end
        end
    end
    return L["Aura State Rule"]
end

-- AuraMonitor: extends Monitor with unit tracking for auras
local AuraMonitor = WowVision.monitors:createType("Aura")

AuraMonitor.info:addFields({
    { key = "unit", type = "String", default = "target", persist = true, label = L["Unit"], sortPriority = 2 },
    { key = "announceOnUnitChange", type = "Bool", default = false, persist = true, label = L["Announce on Target Change"], sortPriority = 2 },
})

AuraMonitor.info:updateFields({
    {
        key = "rules",
        availableTypes = function()
            return { { key = "AuraState", label = L["Aura State Rule"] } }
        end,
    },
})

function AuraMonitor:getTrackingFields()
    return { "unit" }
end

function AuraMonitor:createTracker()
    local unit = self.unit or "target"
    if not unit or unit == "" then
        return nil
    end
    return WowVision.objects:track({
        type = "Aura",
        units = { unit },
    })
end

function AuraMonitor:onUnitsChanged(unitId, guid)
    if self.announceOnUnitChange then
        for _, rule in ipairs(self.rules or {}) do
            if rule.reset then
                rule:reset()
            end
            rule._announceRequested = true
        end
    end
end

function AuraMonitor:getLabel()
    return self.label or (L["Aura Monitor"] .. " (" .. (self.unit or "target") .. ")")
end
