local L = WowVision:getLocale()
local secrets = WowVision.secrets

-- Spell cooldowns and procs under secrets (Retail, WoW: Forever).
--
-- In combat and in instances the cooldown APIs hand out secret numbers, but
-- the structures mark a few fields as never secret, and a probe in combat
-- (2026-10-30) confirmed them plain: a cooldown's isActive and isEnabled, a
-- charge set's isActive and maxCharges, and isOnGCD, which is only filled
-- while SPELL_UPDATE_COOLDOWN is being handled and is then true for every
-- spell bound to the global cooldown, nil for the rest. That is a state
-- machine with no arithmetic: Ready, Charging (recharging with a charge in
-- hand), On Cooldown. The client sends no event when a cooldown ends, so
-- rules on a cooldown poll the plain flag a few times a second.
--
-- The time left comes from the engine: C_Spell.GetSpellCooldownDuration
-- gives a duration object addons may hold, and its FormatRemainingDuration
-- through a numeric rule formatter with our own words ("49 seconds") returns
-- a string that is secret in combat but speakable. Nothing here compares or
-- measures a secret.
--
-- Procs are the spell activation overlay (the glow): its events carry a
-- plain spell id.
local monitors = WowVision.monitors

-- How often a rule on a cooldown asks the plain flag whether it ended.
local POLL_SECONDS = 0.1
-- The viewers whose spells the picker offers: the cooldown ones.
local SPELL_VIEWERS = { "EssentialCooldownViewer", "UtilityCooldownViewer" }

local stateOutputs = {
    { type = "Sound", key = "sound", label = L["Sound Alert"], enabled = false },
    { type = "TTS", key = "tts", label = L["TTS Alert"], enabled = false },
}

-- A plain boolean, or nil when the value is missing or secret.
local function plainBool(value)
    if value == nil or secrets.isSecret(value) then
        return nil
    end
    return value == true
end

local function spellNameOf(id)
    if id == nil or secrets.isSecret(id) or id == 0 then
        return nil
    end
    if C_Spell ~= nil and C_Spell.GetSpellName ~= nil then
        return C_Spell.GetSpellName(id)
    end
    return nil
end

local function cooldownOf(spellID)
    if C_Spell == nil or C_Spell.GetSpellCooldown == nil then
        return nil
    end
    local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
    if ok then
        return info
    end
    return nil
end

local function chargesOf(spellID)
    if C_Spell == nil or C_Spell.GetSpellCharges == nil then
        return nil
    end
    local ok, info = pcall(C_Spell.GetSpellCharges, spellID)
    if ok then
        return info
    end
    return nil
end

-- Whether a charge set is one (more than one charge): maxCharges is plain.
local function hasCharges(charges)
    if charges == nil or secrets.isSecret(charges.maxCharges) then
        return false
    end
    return (charges.maxCharges or 0) > 1
end

-- The formatter with our words, made once: below a minute "49 seconds",
-- above it "1 minutes 12 seconds". Its arguments are plain, so the game
-- takes them from addon code.
local ruleFormatter = nil
local ruleFormatterTried = false

local function getRuleFormatter()
    if ruleFormatterTried then
        return ruleFormatter
    end
    ruleFormatterTried = true
    if C_StringUtil == nil or C_StringUtil.CreateNumericRuleFormatter == nil then
        return nil
    end
    local up = Enum ~= nil and Enum.NumericRuleFormatRounding ~= nil and Enum.NumericRuleFormatRounding.Up or nil
    local ok, made = pcall(function()
        local formatter = C_StringUtil.CreateNumericRuleFormatter()
        formatter:AddBreakpoint({ threshold = 0, format = L["%d seconds"], step = 1, rounding = up })
        formatter:AddBreakpoint({
            threshold = 60,
            format = L["%d minutes %d seconds"],
            components = { { div = 60 }, { mod = 60, step = 1, rounding = up } },
        })
        return formatter
    end)
    if ok then
        ruleFormatter = made
    end
    return ruleFormatter
end

-- The time left on a duration the game hands us (a cooldown or a charge),
-- in our words, or nil. Secret in combat, speakable either way.
local function remainingText(getDuration, spellID)
    if getDuration == nil then
        return nil
    end
    local ok, duration = pcall(getDuration, spellID)
    if not ok or duration == nil then
        return nil
    end
    local formatter = getRuleFormatter()
    if formatter == nil then
        return nil
    end
    local okF, text = pcall(duration.FormatRemainingDuration, duration, formatter)
    if okF and secrets.hasText(text) then
        return text
    end
    return nil
end

local function cooldownRemaining(spellID)
    return remainingText(C_Spell ~= nil and C_Spell.GetSpellCooldownDuration or nil, spellID)
end

local function chargeRemaining(spellID)
    return remainingText(C_Spell ~= nil and C_Spell.GetSpellChargeDuration or nil, spellID)
end

-- ---------------------------------------------------------------------------
-- The spell fields: Spells whose quick picks are the cooldown manager's
-- Essential and Utility entries, where it has them. For a cooldown rule only
-- the entries the game says have a cooldown to alert on (its own alert
-- editor asks C_CooldownViewer.GetValidAlertTypes per entry, which is why
-- it offers no cooldown alert for Sunfire); a proc can be on any spell.
-- Typed entry takes any name or id.
-- ---------------------------------------------------------------------------
local classes = WowVision.classes
local spellType = classes.fieldTypes.Spell
classes.registerFieldType("CooldownSpell", {
    validate = spellType.validate,
    valueString = spellType.valueString,
})
classes.registerFieldType("ProcSpell", {
    validate = spellType.validate,
    valueString = spellType.valueString,
})

-- The alert events that mean an entry has a cooldown of its own.
local function cooldownEventTypes()
    local enum = Enum ~= nil and Enum.CooldownViewerAlertEventType or nil
    if enum ~= nil then
        return { enum.Available, enum.OnCooldown, enum.ChargeGained }
    end
    return { 1, 3, 4 }
end

-- Whether the game offers a cooldown alert for this entry; without the
-- API, every entry passes.
local function entryHasCooldown(frame)
    if C_CooldownViewer == nil or C_CooldownViewer.GetValidAlertTypes == nil or frame.GetCooldownInfo == nil then
        return true
    end
    local okInfo, info = pcall(frame.GetCooldownInfo, frame)
    local cooldownID = okInfo and info ~= nil and info.cooldownID or nil
    if cooldownID == nil or secrets.isSecret(cooldownID) then
        return false
    end
    local ok, types = pcall(C_CooldownViewer.GetValidAlertTypes, cooldownID)
    if not ok or type(types) ~= "table" then
        return false
    end
    for _, wanted in ipairs(cooldownEventTypes()) do
        for _, eventType in ipairs(types) do
            if eventType == wanted then
                return true
            end
        end
    end
    return false
end

-- The spells an entry stands for, each a pick of its own. An entry with
-- linked spells (Eclipse: Lunar and Solar) is one item that renames itself
-- after whichever linked spell last had a cooldown event or an aura, and
-- the base spell's own name follows the active override, so a pick of the
-- base would change its label as the player's state changes. The linked
-- spells have fixed names and cooldowns of their own, so they are offered
-- instead; an entry without any offers the spell it shows.
local function entrySpellIDs(frame, displaySpellID)
    local ids = {}
    local info = nil
    if frame.GetCooldownInfo ~= nil then
        local ok, got = pcall(frame.GetCooldownInfo, frame)
        if ok then
            info = got
        end
    end
    local linked = info ~= nil and info.linkedSpellIDs or nil
    if type(linked) == "table" and not secrets.isSecret(linked) then
        for _, id in ipairs(linked) do
            if id ~= nil and not secrets.isSecret(id) and id ~= 0 then
                tinsert(ids, id)
            end
        end
    end
    if #ids == 0 then
        local id = displaySpellID(frame)
        if id ~= nil then
            tinsert(ids, id)
        end
    end
    return ids
end

local function viewerSpells(accept)
    local seen = {}
    local list = {}
    local displaySpellID = monitors.CdmAuraMonitor ~= nil and monitors.CdmAuraMonitor.displaySpellID or nil
    if displaySpellID == nil then
        return list
    end
    for _, viewerName in ipairs(SPELL_VIEWERS) do
        local viewer = _G[viewerName]
        if viewer ~= nil and viewer.GetItemFrames ~= nil then
            local ok, frames = pcall(viewer.GetItemFrames, viewer)
            for _, frame in ipairs(ok and frames or {}) do
                if accept == nil or accept(frame) then
                    for _, id in ipairs(entrySpellIDs(frame, displaySpellID)) do
                        if not seen[id] then
                            local name = spellNameOf(id)
                            if name ~= nil then
                                seen[id] = true
                                tinsert(list, { spellID = id, name = name })
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b)
        return a.name < b.name
    end)
    return list
end

local function cooldownSpells()
    return viewerSpells(entryHasCooldown)
end

local function procSpells()
    return viewerSpells(nil)
end

local graph = WowVision.graph
if graph ~= nil and graph.settings ~= nil and graph.settings.spellControl ~= nil then
    graph.settings.registerFieldControl("CooldownSpell", function(field, owner)
        return graph.settings.spellControl(field, owner, cooldownSpells, L["No spells with cooldowns"])
    end)
    graph.settings.registerFieldControl("ProcSpell", function(field, owner)
        return graph.settings.spellControl(field, owner, procSpells, L["No essential or utility spells"])
    end)
end

-- ---------------------------------------------------------------------------
-- The cooldown rule: one spell, with alerts per state.
-- ---------------------------------------------------------------------------
local SpellCooldownStateRule = monitors.ruleRegistry:createType({ key = "SpellCooldownState", parent = "State" })

SpellCooldownStateRule:addFields({
    { key = "spell", type = "CooldownSpell", persist = true, label = L["Spell"], sortPriority = 2 },
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
})

function SpellCooldownStateRule:initialize(config)
    monitors.StateRule.initialize(self, config)
    -- Whether the active cooldown is only the global one, as the last
    -- cooldown event said.
    self._gcdOnly = false
    self._name = nil
    self._nameFor = nil
end

function SpellCooldownStateRule:getTrackingFields()
    return { "spell" }
end

function SpellCooldownStateRule:getStates()
    return { { key = "ready" }, { key = "charging" }, { key = "on_cooldown" } }
end

function SpellCooldownStateRule:spellName()
    if self._nameFor ~= self.spell then
        self._nameFor = self.spell
        self._name = spellNameOf(self.spell)
    end
    return self._name
end

-- Spoken as "Barkskin Ready" rather than "ready".
function SpellCooldownStateRule:stateMessage(stateKey)
    local field = self.class:getField(stateKey)
    local label = field ~= nil and field.label or stateKey
    return { text = (self:spellName() or self:getLabel()) .. " " .. label, state = stateKey, rule = self }
end

-- Inside a cooldown event: note whether the cooldown the game reports is
-- the global one, the only time isOnGCD can be trusted.
function SpellCooldownStateRule:noteCooldownEvent()
    local cooldown = cooldownOf(self.spell)
    if cooldown == nil then
        self._gcdOnly = false
        return
    end
    self._gcdOnly = plainBool(cooldown.isActive) == true and plainBool(cooldown.isOnGCD) == true
end

-- The state from the plain flags: a real cooldown is On Cooldown; a charge
-- set recharging while a charge remains is Charging; anything else Ready.
function SpellCooldownStateRule:readState()
    if self.spell == nil then
        return nil
    end
    local cooldown = cooldownOf(self.spell)
    local active = cooldown ~= nil and plainBool(cooldown.isActive) == true
    if not active then
        self._gcdOnly = false
    end
    if active and not self._gcdOnly then
        return "on_cooldown"
    end
    local charges = chargesOf(self.spell)
    if hasCharges(charges) and plainBool(charges.isActive) == true then
        return "charging"
    end
    return "ready"
end

-- One evaluation: the state, then the transition. The first settles silently
-- (StateRule), later ones alert on change.
function SpellCooldownStateRule:evaluate()
    local state = self:readState()
    if state == nil then
        return
    end
    if state ~= self:getCurrentState() then
        self:transitionTo(state)
    else
        self:updateResolved(state)
    end
end

-- The spell now: "Barkskin, On Cooldown, 49 seconds", "Fire Blast,
-- Charging, 1 charges, 8 seconds", or "Barkskin, Ready".
function SpellCooldownStateRule:currentText()
    local name = self:spellName() or self:getLabel()
    local state = self:readState()
    if state == "on_cooldown" then
        return name .. ", " .. L["On Cooldown"] .. secrets.whenText(cooldownRemaining(self.spell), ", ", "")
    end
    if state == "charging" then
        local charges = chargesOf(self.spell)
        local text = name .. ", " .. L["Charging"]
        if charges ~= nil then
            text = text .. secrets.whenNonZero(charges.currentCharges, ", ", " " .. L["charges"])
        end
        return text .. secrets.whenText(chargeRemaining(self.spell), ", ", "")
    end
    return name .. ", " .. L["Ready"]
end

function SpellCooldownStateRule:reset()
    monitors.StateRule.reset(self)
    self._gcdOnly = false
end

function SpellCooldownStateRule:getLabel()
    if self.label and self.label ~= "" then
        return self.label
    end
    if self.spell then
        local spellField = self.class:getField("spell")
        local valueStr = spellField ~= nil and spellField:getValueString(self, self.spell) or nil
        if valueStr then
            return valueStr
        end
    end
    return L["Spell Cooldown Rule"]
end

-- ---------------------------------------------------------------------------
-- The proc rule: the spell activation glow on one spell.
-- ---------------------------------------------------------------------------
local SpellProcRule = monitors.ruleRegistry:createType({ key = "SpellProc", parent = "State" })

SpellProcRule:addFields({
    { key = "spell", type = "ProcSpell", persist = true, label = L["Spell"], sortPriority = 2 },
    {
        key = "active",
        type = "Alert",
        persist = true,
        label = L["Proc"],
        sortPriority = 3,
        alert = { key = "active", label = L["Proc"] },
        outputs = stateOutputs,
    },
    {
        key = "inactive",
        type = "Alert",
        persist = true,
        label = L["Proc Ended"],
        sortPriority = 3,
        alert = { key = "inactive", label = L["Proc Ended"] },
        outputs = stateOutputs,
    },
})

function SpellProcRule:initialize(config)
    monitors.StateRule.initialize(self, config)
    self._name = nil
    self._nameFor = nil
end

function SpellProcRule:getTrackingFields()
    return { "spell" }
end

function SpellProcRule:getStates()
    return { { key = "active" }, { key = "inactive" } }
end

function SpellProcRule:spellName()
    if self._nameFor ~= self.spell then
        self._nameFor = self.spell
        self._name = spellNameOf(self.spell)
    end
    return self._name
end

function SpellProcRule:stateMessage(stateKey)
    local field = self.class:getField(stateKey)
    local label = field ~= nil and field.label or stateKey
    return { text = (self:spellName() or self:getLabel()) .. " " .. label, state = stateKey, rule = self }
end

-- A glow event names a spell id, which may be an override of ours: match
-- by name, which both resolve to plainly.
function SpellProcRule:matchesSpell(spellID)
    if spellID == nil or secrets.isSecret(spellID) then
        return false
    end
    if spellID == self.spell then
        return true
    end
    local name = self:spellName()
    return name ~= nil and spellNameOf(spellID) == name
end

function SpellProcRule:setActive(active)
    local state = active and "active" or "inactive"
    if state ~= self:getCurrentState() then
        self:transitionTo(state)
    else
        self:updateResolved(state)
    end
end

-- Where the rule starts: the glow as the game reports it now, plain or
-- absent.
function SpellProcRule:settle()
    if self.spell == nil then
        return
    end
    local overlayed = false
    if C_SpellActivationOverlay ~= nil and C_SpellActivationOverlay.IsSpellOverlayed ~= nil then
        local ok, value = pcall(C_SpellActivationOverlay.IsSpellOverlayed, self.spell)
        overlayed = ok and plainBool(value) == true
    end
    self:setActive(overlayed)
end

function SpellProcRule:currentText()
    local name = self:spellName() or self:getLabel()
    if self:getCurrentState() == "active" then
        return name .. ", " .. L["Proc"]
    end
    return name .. ", " .. L["No proc"]
end

function SpellProcRule:getLabel()
    if self.label and self.label ~= "" then
        return self.label
    end
    if self.spell then
        local spellField = self.class:getField("spell")
        local valueStr = spellField ~= nil and spellField:getValueString(self, self.spell) or nil
        if valueStr then
            return valueStr
        end
    end
    return L["Spell Proc Rule"]
end

-- ---------------------------------------------------------------------------
-- The monitor: the rules, the events and the poll.
-- ---------------------------------------------------------------------------
local SpellCooldownMonitor = monitors:createType("SpellCooldown")
SpellCooldownMonitor.label = L["Spell Cooldowns"]

SpellCooldownMonitor:updateFields({
    {
        key = "rules",
        availableTypes = function()
            return {
                { key = "SpellCooldownState", label = L["Spell Cooldown Rule"] },
                { key = "SpellProc", label = L["Spell Proc Rule"] },
            }
        end,
    },
})

SpellCooldownMonitor.cooldownSpells = cooldownSpells
SpellCooldownMonitor.procSpells = procSpells
SpellCooldownMonitor.cooldownRemaining = cooldownRemaining

local live = setmetatable({}, { __mode = "k" })
local eventFrame = nil

local function ensureEvents()
    if eventFrame ~= nil or CreateFrame == nil then
        return
    end
    eventFrame = CreateFrame("Frame")
    for _, event in ipairs({ "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES", "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", "PLAYER_ENTERING_WORLD" }) do
        pcall(eventFrame.RegisterEvent, eventFrame, event)
    end
    eventFrame:SetScript("OnEvent", function(_, event, spellID)
        for monitor in pairs(live) do
            if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
                monitor:onCooldownEvent(event)
            elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
                monitor:onGlow(spellID, true)
            elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
                monitor:onGlow(spellID, false)
            else
                monitor._trackingDirty = true
            end
        end
    end)
end

function SpellCooldownMonitor:initialize(config)
    monitors.Monitor.initialize(self, config)
    self._nextPoll = 0
    live[self] = true
    ensureEvents()
end

function SpellCooldownMonitor:getTrackingFields()
    return {}
end

-- A cooldown changed somewhere: the GCD flag is readable now, so each rule
-- notes it, then evaluates.
function SpellCooldownMonitor:onCooldownEvent(event)
    if not self.enabled then
        return
    end
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled and rule.noteCooldownEvent ~= nil then
            if event == "SPELL_UPDATE_COOLDOWN" then
                rule:noteCooldownEvent()
            end
            rule:evaluate()
        end
    end
end

function SpellCooldownMonitor:onGlow(spellID, shown)
    if not self.enabled then
        return
    end
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled and rule.matchesSpell ~= nil and rule:matchesSpell(spellID) then
            rule:setActive(shown)
        end
    end
end

-- Rules or spells changed: every rule starts over from what the game says,
-- silently, as on its first tick.
function SpellCooldownMonitor:settle()
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled then
            if rule.forget then
                rule:forget()
            end
            rule._gcdOnly = false
            if rule.settle ~= nil then
                rule:settle()
            elseif rule.evaluate ~= nil then
                rule:evaluate()
            end
        end
    end
end

-- Each tick: settle when dirty; otherwise poll the cooldown rules a few
-- times a second, since the end of a cooldown sends no event.
function SpellCooldownMonitor:update()
    if not self.enabled then
        return
    end
    if self._trackingDirty then
        self._trackingDirty = false
        self:settle()
        return
    end
    local now = GetTime()
    if now < self._nextPoll then
        return
    end
    self._nextPoll = now + POLL_SECONDS
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled and rule.evaluate ~= nil then
            local state = rule:getCurrentState()
            if state == "on_cooldown" or state == "charging" or state == nil then
                rule:evaluate()
            end
        end
    end
end

function SpellCooldownMonitor:getLabel()
    if self.label and self.label ~= "" then
        return self.label
    end
    return L["Spell Cooldowns"]
end

-- What the tracked spells read right now, each rule in turn.
function SpellCooldownMonitor:currentTexts()
    local texts = {}
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled and rule.currentText ~= nil then
            tinsert(texts, rule:currentText())
        end
    end
    return texts
end

-- The key: the tracked spells of every enabled Spell Cooldowns monitor.
local module = WowVision.base ~= nil and WowVision.base.monitors or nil
if module ~= nil then
    module:registerBinding({
        type = "Function",
        key = "monitors/speakCooldowns",
        inputs = {},
        label = L["Speak Tracked Cooldowns"],
        interruptSpeech = true,
        func = function()
            local parts = {}
            for _, monitor in ipairs(module.getMonitors()) do
                if monitor.enabled and monitor.class == SpellCooldownMonitor then
                    for _, text in ipairs(monitor:currentTexts()) do
                        tinsert(parts, text)
                    end
                end
            end
            if #parts == 0 then
                WowVision:speak(L["No tracked cooldowns"])
                return
            end
            WowVision:speak(secrets.join(parts, ". "))
        end,
    })
end

monitors.SpellCooldownMonitor = SpellCooldownMonitor
monitors.SpellCooldownStateRule = SpellCooldownStateRule
monitors.SpellProcRule = SpellProcRule
