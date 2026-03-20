local L = WowVision:getLocale()

local stateOutputs = {
    { type = "Sound", key = "sound", label = L["Sound Alert"], enabled = false },
    { type = "TTS", key = "tts", label = L["TTS Alert"], enabled = false },
}

-- AuraStateRule: extends StateRule with aura-specific fields
local AuraStateRule = WowVision.monitors.ruleRegistry:createType({ key = "AuraState", parent = "State" })

AuraStateRule.info:addFields({
    { key = "spell", type = "Spell", persist = true, label = L["Spell"] },
    { key = "playerOnly", type = "Bool", persist = true, default = true, label = L["Player Only"] },
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

function AuraStateRule:initialize(config)
    self.trackedObjects = {} -- objects currently matching this rule
    WowVision.monitors.StateRule.initialize(self, config)
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
        local isFromPlayer = object:get("isFromPlayerOrPlayerPet")
        if not isFromPlayer then
            return false
        end
    end
    return true
end

function AuraStateRule:onObjectAdd(object)
    self.trackedObjects[object] = true
end

function AuraStateRule:onObjectRemove(object)
    if self.trackedObjects[object] then
        self.trackedObjects[object] = nil
    end
end

function AuraStateRule:reset()
    self.trackedObjects = {}
    WowVision.monitors.StateRule.reset(self)
end

function AuraStateRule:computeState(object)
    local duration = object:get("duration")
    local remaining = object:get("remainingDuration")

    if not duration or duration == 0 then
        return "applied"
    end
    if not remaining then
        return "applied"
    end
    if remaining <= (self.expiringThreshold or 5) then
        return "expiring"
    end
    if duration > 0 and (remaining / duration) * 100 <= (self.pandemicThreshold or 30) then
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
        end
    else
        if self:getCurrentState() ~= nil and self:getCurrentState() ~= "missing" then
            self:transitionTo("missing")
        end
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
    { key = "unit", type = "String", default = "target", persist = true, label = L["Unit"] },
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

function AuraMonitor:getLabel()
    return self.label or (L["Aura Monitor"] .. " (" .. (self.unit or "target") .. ")")
end
