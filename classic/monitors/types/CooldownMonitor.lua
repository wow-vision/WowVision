local L = WowVision:getLocale()

local stateOutputs = {
    { type = "Sound", key = "sound", label = L["Sound Alert"], enabled = false },
    { type = "TTS", key = "tts", label = L["TTS Alert"], enabled = false },
}

-- CooldownStateRule: extends StateRule with cooldown-specific fields
local CooldownStateRule = WowVision.monitors.ruleRegistry:createType({ key = "CooldownState", parent = "State" })

CooldownStateRule:addFields({
    { key = "spell", type = "Spell", persist = true, label = L["Spell"], sortPriority = 2 },
    -- State alerts
    {
        key = "ready",
        type = "Alert",
        persist = true,
        label = L["Ready"],
        sortPriority = 3,
        alert = { key = "ready", label = L["Ready"] },
        outputs = stateOutputs,
    },
    {
        key = "charging",
        type = "Alert",
        persist = true,
        label = L["Charging"],
        sortPriority = 3,
        alert = { key = "charging", label = L["Charging"] },
        outputs = stateOutputs,
    },
    {
        key = "on_cooldown",
        type = "Alert",
        persist = true,
        label = L["On Cooldown"],
        sortPriority = 3,
        alert = { key = "on_cooldown", label = L["On Cooldown"] },
        outputs = stateOutputs,
    },
    -- Charge event alerts (not states, fire independently)
    {
        key = "charge_gained",
        type = "Alert",
        persist = true,
        label = L["Charge Gained"],
        sortPriority = 4,
        alert = { key = "charge_gained", label = L["Charge Gained"] },
        outputs = stateOutputs,
    },
    {
        key = "charge_lost",
        type = "Alert",
        persist = true,
        label = L["Charge Lost"],
        sortPriority = 4,
        alert = { key = "charge_lost", label = L["Charge Lost"] },
        outputs = stateOutputs,
    },
})

function CooldownStateRule:initialize(config)
    self._lastCharges = nil
    WowVision.monitors.StateRule.initialize(self, config)
end

function CooldownStateRule:getTrackingFields()
    return { "spell" }
end

function CooldownStateRule:getStates()
    return {
        { key = "ready" },
        { key = "charging" },
        { key = "on_cooldown" },
    }
end

function CooldownStateRule:matches(object)
    if not self.spell then
        return false
    end
    local objSpellId = object:get("spellId")
    return objSpellId == self.spell
end

function CooldownStateRule:onObjectAdd(object)
    self._trackedObject = object
end

function CooldownStateRule:onObjectRemove(object)
    if self._trackedObject == object then
        self._trackedObject = nil
    end
end

function CooldownStateRule:reset()
    self._trackedObject = nil
    self._lastCharges = nil
    WowVision.monitors.StateRule.reset(self)
end

function CooldownStateRule:computeState(object)
    local isReady = object:get("isReady")
    local hasCharges = object:get("hasCharges")

    if hasCharges then
        local charges = object:get("charges")
        local maxCharges = object:get("maxCharges")
        if charges >= maxCharges then
            return "ready"
        elseif charges > 0 then
            return "charging"
        else
            return "on_cooldown"
        end
    else
        if isReady then
            return "ready"
        else
            return "on_cooldown"
        end
    end
end

function CooldownStateRule:update()
    local object = self._trackedObject
    if not object then
        return
    end

    -- Compute and transition state
    local state = self:computeState(object)
    if state ~= self:getCurrentState() then
        self:transitionTo(state)
    else
        self:updateResolved(state)
    end

    -- Check for charge changes (independent of state)
    local hasCharges = object:get("hasCharges")
    if hasCharges then
        local charges = object:get("charges")
        if self._lastCharges ~= nil and charges ~= self._lastCharges then
            if charges > self._lastCharges then
                local alert = self.charge_gained
                if alert then
                    alert:fire({ text = "charge gained", charges = charges, rule = self })
                end
            elseif charges < self._lastCharges then
                local alert = self.charge_lost
                if alert then
                    alert:fire({ text = "charge lost", charges = charges, rule = self })
                end
            end
        end
        self._lastCharges = charges
    end
end

function CooldownStateRule:getLabel()
    if self.label and self.label ~= "" then
        return self.label
    end
    if self.spell then
        local spellField = self.class:getField("spell")
        if spellField then
            local valueStr = spellField:getValueString(self, self.spell)
            if valueStr then
                return valueStr
            end
        end
    end
    return L["Cooldown State Rule"]
end

-- CooldownMonitor: player-only cooldown tracking
local CooldownMonitor = WowVision.monitors:createType("Cooldown")

CooldownMonitor:updateFields({
    {
        key = "rules",
        availableTypes = function()
            return { { key = "CooldownState", label = L["Cooldown State Rule"] } }
        end,
    },
})

function CooldownMonitor:createTracker()
    local spellIds = {}
    for _, rule in ipairs(self.rules or {}) do
        if rule.spell then
            tinsert(spellIds, rule.spell)
        end
    end
    if #spellIds == 0 then
        return nil
    end
    return WowVision.objects:track({
        type = "Cooldown",
        spellIds = spellIds,
        params = {},
    })
end

function CooldownMonitor:getLabel()
    return self.label or L["Cooldown Monitor"]
end
