local L = WowVision:getLocale()

local stateOutputs = {
    { type = "Sound", key = "sound", label = L["Sound Alert"], enabled = false },
    { type = "TTS", key = "tts", label = L["TTS Alert"], enabled = false },
}

-- AuraStateRule: extends StateRule with aura-specific fields
local AuraStateRule = WowVision.monitors.ruleRegistry:createType({ key = "AuraState", parent = "State" })

AuraStateRule.info:addFields({
    { key = "spell", type = "Spell", persist = true, label = L["Spell"] },
    { key = "pandemicThreshold", type = "Number", persist = true, default = 30, label = L["Pandemic Window (%)"] },
    { key = "expiringThreshold", type = "Number", persist = true, default = 5, label = L["Expiry Threshold (seconds)"] },
    {
        key = "applied",
        type = "Alert",
        persist = true,
        label = L["Applied"],
        alert = { key = "applied", label = L["Applied"] },
        outputs = stateOutputs,
    },
    {
        key = "pandemic",
        type = "Alert",
        persist = true,
        label = L["Pandemic"],
        alert = { key = "pandemic", label = L["Pandemic"] },
        outputs = stateOutputs,
    },
    {
        key = "expiring",
        type = "Alert",
        persist = true,
        label = L["Expiring"],
        alert = { key = "expiring", label = L["Expiring"] },
        outputs = stateOutputs,
    },
    {
        key = "missing",
        type = "Alert",
        persist = true,
        label = L["Missing"],
        alert = { key = "missing", label = L["Missing"] },
        outputs = stateOutputs,
    },
})

function AuraStateRule:getStates()
    return {
        { key = "applied" },
        { key = "pandemic", fallback = "applied" },
        { key = "expiring", fallback = "pandemic" },
    }
    -- "missing" is independent, not in the fallback chain
end

function AuraStateRule:matches(object)
    if not self.spell then
        return false
    end
    local objSpellId = object:get("spellId")
    return objSpellId == self.spell
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
    { key = "unit", type = "String", default = "target", persist = true, label = L["Unit"] },
})

-- Override the rules ComponentArray to filter available types
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

-- Override updateRules to handle per-rule thresholds
function AuraMonitor:updateRules()
    local rules = self.rules
    if not rules then
        return
    end

    for object, _ in pairs(self.trackedObjects) do
        local duration = object:get("duration")
        local remaining = object:get("remainingDuration")

        for _, rule in ipairs(rules) do
            if rule.enabled and rule:matches(object) then
                local state
                if not duration or duration == 0 then
                    state = "applied"
                elseif not remaining then
                    state = "applied"
                elseif remaining <= (rule.expiringThreshold or 5) then
                    state = "expiring"
                elseif duration > 0 and (remaining / duration) * 100 <= (rule.pandemicThreshold or 30) then
                    state = "pandemic"
                else
                    state = "applied"
                end
                if rule.setObjectState then
                    rule:setObjectState(object, state)
                end
            end
        end
    end

    -- Check for removed objects in each rule
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

function AuraMonitor:getLabel()
    return self.label or (L["Aura Monitor"] .. " (" .. (self.unit or "target") .. ")")
end
