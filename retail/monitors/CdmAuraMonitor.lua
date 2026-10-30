local L = WowVision:getLocale()
local secrets = WowVision.secrets

-- Auras tracked through Blizzard's cooldown manager (Retail, WoW: Forever).
--
-- In combat and in instances the aura APIs are closed to addons, and every
-- value of an aura that does come through is secret. The cooldown manager
-- (Blizzard_CooldownViewer) is Blizzard's own code, so it reads what we
-- cannot, and it leaves plain facts on its item frames (measured in game,
-- 2026-10-24): whether an item's aura is up (IsActive on buff items, the
-- cached aura data on cooldown items), on which unit ("player" or "target",
-- auraDataUnit), and whether it is in its pandemic window (PandemicIcon).
-- The time left is drawn by the engine as the countdown text on the item's
-- Cooldown widget, secret but speakable. This monitor polls those facts each
-- tick for the item frames whose spell a rule names, and never touches an
-- aura value itself. Only auras in the cooldown manager's Tracked Buffs and
-- Tracked Bars can be tracked (the game sorts each entry as a spell or an
-- aura; the Essential and Utility viewers hold spells, whose item frames
-- carry aura data only incidentally), and only on the player and the
-- target, the two units the viewers watch.
local monitors = WowVision.monitors

local VIEWERS = { "BuffIconCooldownViewer", "BuffBarCooldownViewer", "EssentialCooldownViewer", "UtilityCooldownViewer" }
-- The viewers that draw auras: Tracked Buffs and Tracked Bars.
local AURA_VIEWERS = { "BuffIconCooldownViewer", "BuffBarCooldownViewer" }
-- Below this many seconds the countdown text shows one decimal ("8.7"), the
-- finest the engine formats; Blizzard's own value is 0.
local DECIMAL_BELOW_SECONDS = 600
-- The viewers are looked over again this often, besides on their layout
-- changes, in case a hook was missed.
local RESCAN_SECONDS = 5
-- How long a rule keeps saying Pandemic once the marker goes while the aura
-- data stays. The viewer hides the marker the instant the aura's expiration
-- time passes (its OnUpdate compares the clock), but clears the aura data
-- only when the removal event arrives, a server round trip later; read
-- plainly, that gap is an Applied between Pandemic and Missing. A refresh
-- looks the same at first, and is told apart by the item re-reading a live
-- aura (SetAuraInstanceInfo, hooked below), which ends the hold at once,
-- unless the item's cooldown widget finished in the same breath: at expiry
-- the widget's OnCooldownDone (hooked too) fires a frame before the clock
-- comparison, marks the item dirty, and the refresh re-reads the aura the
-- game still lists (measured in game, 2026-10-24). That re-read is the
-- expiry itself, so it never ends the hold.
local PANDEMIC_HOLD_SECONDS = 1
-- A re-read ends the hold only once the marker has been gone this many
-- ticks: a frame rebuilt by the viewer has its aura before its marker.
local PANDEMIC_HOLD_MIN_TICKS = 2

local stateOutputs = {
    { type = "Sound", key = "sound", label = L["Sound Alert"], enabled = false },
    { type = "TTS", key = "tts", label = L["TTS Alert"], enabled = false },
}

local function spellNameOf(id)
    if id == nil or secrets.isSecret(id) or id == 0 then
        return nil
    end
    if C_Spell ~= nil and C_Spell.GetSpellName ~= nil then
        return C_Spell.GetSpellName(id)
    end
    return nil
end

local function cooldownInfoOf(frame)
    if frame.GetCooldownInfo == nil then
        return nil
    end
    local ok, info = pcall(frame.GetCooldownInfo, frame)
    if ok then
        return info
    end
    return nil
end

-- The ids an entry goes by, in the order the cooldown manager itself names
-- it (its GetSpellID): the linked spell, the tooltip override, the
-- override, then the base spell. Two entries can share a base spell and
-- differ only here (Eclipse (Lunar) and Eclipse (Solar) are both Eclipse).
local ID_KEYS = { "linkedSpellID", "overrideTooltipSpellID", "overrideSpellID", "spellID" }

-- The plain spell id the cooldown manager would show the entry under.
local function displaySpellID(frame)
    local info = cooldownInfoOf(frame)
    if info == nil then
        return nil
    end
    for _, key in ipairs(ID_KEYS) do
        local id = info[key]
        if id ~= nil and not secrets.isSecret(id) and id ~= 0 then
            return id
        end
    end
    return nil
end

-- The plain spell names an item frame stands for: its base spell and the
-- override and linked spells. The ids that relate to an active aura turn
-- secret while it is up, so names once seen plain are remembered for the
-- frame until it is given another entry (the viewer pools its frames).
local knownNames = setmetatable({}, { __mode = "k" })

local function frameSpellNames(frame)
    local info = cooldownInfoOf(frame)
    if info == nil then
        return {}
    end
    local cooldownID = info.cooldownID
    if secrets.isSecret(cooldownID) then
        cooldownID = nil
    end
    local known = knownNames[frame]
    if known == nil or cooldownID == nil or known.cooldownID ~= cooldownID then
        known = { cooldownID = cooldownID, names = {} }
        knownNames[frame] = known
    end
    local names = known.names
    for _, key in ipairs(ID_KEYS) do
        local name = spellNameOf(info[key])
        if name ~= nil then
            names[name] = true
        end
    end
    if type(info.linkedSpellIDs) == "table" and not secrets.isSecret(info.linkedSpellIDs) then
        for _, id in ipairs(info.linkedSpellIDs) do
            local name = spellNameOf(id)
            if name ~= nil then
                names[name] = true
            end
        end
    end
    return names
end

-- One entry's ids and flags in words, for /wv cdmlog spells.
local function describeEntry(frame, viewerTag)
    local info = cooldownInfoOf(frame)
    if info == nil then
        return viewerTag(frame) .. ", no cooldown info"
    end
    local parts = { viewerTag(frame) }
    for _, key in ipairs({ "cooldownID", "spellID", "overrideSpellID", "overrideTooltipSpellID", "linkedSpellID" }) do
        local id = info[key]
        if id ~= nil then
            if secrets.isSecret(id) then
                tinsert(parts, key .. " secret")
            else
                tinsert(parts, key .. " " .. tostring(id) .. " " .. (spellNameOf(id) or "unnamed"))
            end
        end
    end
    if type(info.linkedSpellIDs) == "table" and not secrets.isSecret(info.linkedSpellIDs) then
        for _, id in ipairs(info.linkedSpellIDs) do
            if secrets.isSecret(id) then
                tinsert(parts, "linked secret")
            else
                tinsert(parts, "linked " .. tostring(id) .. " " .. (spellNameOf(id) or "unnamed"))
            end
        end
    end
    for _, key in ipairs({ "hasAura", "selfAura", "charges", "isKnown", "category" }) do
        local value = info[key]
        if value ~= nil then
            tinsert(parts, key .. " " .. (secrets.isSecret(value) and "secret" or tostring(value)))
        end
    end
    if C_CooldownViewer ~= nil and C_CooldownViewer.GetValidAlertTypes ~= nil and info.cooldownID ~= nil and not secrets.isSecret(info.cooldownID) then
        local ok, types = pcall(C_CooldownViewer.GetValidAlertTypes, info.cooldownID)
        if ok and type(types) == "table" then
            local names = {}
            for _, eventType in ipairs(types) do
                tinsert(names, tostring(eventType))
            end
            tinsert(parts, "alert events " .. (#names > 0 and table.concat(names, " ") or "none"))
        end
    end
    if frame.GetSpellID ~= nil then
        local ok, id = pcall(frame.GetSpellID, frame)
        if ok then
            tinsert(parts, "GetSpellID " .. (secrets.isSecret(id) and "secret" or (tostring(id) .. " " .. (spellNameOf(id) or "unnamed"))))
        end
    end
    return table.concat(parts, ", ")
end

-- Whether a frame is drawn at all. A hidden viewer (one the player shows
-- only in combat, say) unregisters its events, so its items keep whatever
-- aura data they last read: stale, and no sighted player sees it either.
local function frameVisible(frame)
    if frame.IsVisible == nil then
        return true
    end
    local ok, visible = pcall(frame.IsVisible, frame)
    return ok and visible == true
end

-- Whether the frame shows its aura on the unit right now. A buff item (the
-- Buff Icon and Buff Bar viewers) says so with IsActive; a cooldown item
-- (Essential, Utility) is active whenever it has a cooldown, so there the
-- cached aura data stands for the aura. A frame that is not drawn shows
-- nothing.
local function auraShown(frame, unit)
    if frame.auraDataUnit ~= unit or frame.auraDataCached == nil then
        return false
    end
    if not frameVisible(frame) then
        return false
    end
    if frame.GetApplicationsText ~= nil and frame.IsActive ~= nil then
        local ok, active = pcall(frame.IsActive, frame)
        return ok and active == true
    end
    return true
end

local function inPandemic(frame)
    return frame.PandemicIcon ~= nil
end

-- The text of a font string, or nil (secret text comes through as is).
local function textOf(fontString)
    if fontString == nil or fontString.GetText == nil then
        return nil
    end
    local ok, text = pcall(fontString.GetText, fontString)
    if ok then
        return text
    end
    return nil
end

-- The time left as the engine draws it on the item: the countdown text of
-- its Cooldown widget while the numbers are shown, else the bar's duration
-- text (the Buff Bar viewer).
local function timerText(frame)
    local cooldown = frame.Cooldown
    if cooldown ~= nil and cooldown.GetCountdownFontString ~= nil then
        local okHidden, hidden = pcall(cooldown.GetHideCountdownNumbers, cooldown)
        if okHidden and not hidden then
            local ok, fontString = pcall(cooldown.GetCountdownFontString, cooldown)
            if ok then
                local text = textOf(fontString)
                if secrets.hasText(text) then
                    return text
                end
            end
        end
    end
    local bar = frame.Bar
    if bar ~= nil then
        return textOf(bar.Duration)
    end
    return nil
end

local function stacksText(frame)
    if frame.GetApplicationsFontString == nil then
        return nil
    end
    local ok, fontString = pcall(frame.GetApplicationsFontString, frame)
    if not ok then
        return nil
    end
    return textOf(fontString)
end

-- Every item frame of the given viewers.
local function viewerItemFrames(viewerNames)
    local frames = {}
    for _, name in ipairs(viewerNames) do
        local viewer = _G[name]
        if viewer ~= nil and viewer.GetItemFrames ~= nil then
            local ok, list = pcall(viewer.GetItemFrames, viewer)
            if ok and list ~= nil then
                for _, frame in ipairs(list) do
                    tinsert(frames, frame)
                end
            end
        end
    end
    return frames
end

-- The auras in the cooldown manager's Tracked Buffs and Tracked Bars, one
-- entry per spell as the cooldown manager names them, sorted by name: what
-- a rule can name.
local function cdmSpells()
    local seen = {}
    local list = {}
    for _, frame in ipairs(viewerItemFrames(AURA_VIEWERS)) do
        local id = displaySpellID(frame)
        if id ~= nil and not seen[id] then
            local name = spellNameOf(id)
            if name ~= nil then
                seen[id] = true
                tinsert(list, { spellID = id, name = name })
            end
        end
    end
    table.sort(list, function(a, b)
        return a.name < b.name
    end)
    return list
end

-- ---------------------------------------------------------------------------
-- The spell field: a Spell whose quick picks are the cooldown manager's own
-- spells rather than the cast history, since only those can be tracked.
-- Typed entry still takes any name or id.
-- ---------------------------------------------------------------------------
local classes = WowVision.classes
local spellType = classes.fieldTypes.Spell
classes.registerFieldType("CdmSpell", {
    validate = spellType.validate,
    valueString = spellType.valueString,
})

local graph = WowVision.graph
if graph ~= nil and graph.settings ~= nil and graph.settings.spellControl ~= nil then
    graph.settings.registerFieldControl("CdmSpell", function(field, owner)
        return graph.settings.spellControl(field, owner, cdmSpells, L["No tracked buffs or bars"])
    end)
end

-- When each item frame last re-read a live aura (the viewer calls
-- SetAuraInstanceInfo on every refresh of an item that has one), and when
-- its cooldown widget last finished.
local refreshedAt = setmetatable({}, { __mode = "k" })
local cooldownDoneAt = setmetatable({}, { __mode = "k" })
local hookedFrames = setmetatable({}, { __mode = "k" })

local function hookFrame(frame)
    if hookedFrames[frame] or hooksecurefunc == nil or frame.SetAuraInstanceInfo == nil then
        return
    end
    hookedFrames[frame] = true
    hooksecurefunc(frame, "SetAuraInstanceInfo", function(item)
        refreshedAt[item] = GetTime()
    end)
    local cooldown = frame.Cooldown
    if cooldown ~= nil and cooldown.HookScript ~= nil then
        pcall(cooldown.HookScript, cooldown, "OnCooldownDone", function()
            cooldownDoneAt[frame] = GetTime()
        end)
    end
end

-- A short trace of what each rule saw, for /wv cdmlog: a line whenever a
-- frame's plain facts change or the hold decides, oldest first. Plain words
-- so it reads aloud.
local TRACE_MAX = 80
local trace = {}

local function addTrace(line)
    tinsert(trace, line)
    if #trace > TRACE_MAX then
        tremove(trace, 1)
    end
end

local function clearTrace()
    for i = #trace, 1, -1 do
        trace[i] = nil
    end
end

local function isActiveItem(frame)
    if frame.IsActive == nil then
        return nil
    end
    local ok, active = pcall(frame.IsActive, frame)
    return ok and active == true
end

-- The plain facts of a frame as one number, for cheap change detection.
local function frameCode(frame, unit)
    local code = 0
    if frame.auraDataCached ~= nil then
        code = code + 1
    end
    if frame.auraDataUnit == unit then
        code = code + 2
    end
    if isActiveItem(frame) then
        code = code + 4
    end
    if frame.PandemicIcon ~= nil then
        code = code + 8
    end
    if not frameVisible(frame) then
        code = code + 16
    end
    return code
end

local function viewerTag(frame)
    if frame.GetViewerFrame == nil then
        return "item"
    end
    local ok, viewer = pcall(frame.GetViewerFrame, frame)
    local name = ok and viewer ~= nil and viewer.GetName ~= nil and viewer:GetName() or nil
    if name == nil then
        return "item"
    end
    return (name:gsub("CooldownViewer", "")):lower()
end

local function describeFrame(frame, unit, since)
    local text = viewerTag(frame)
    if not frameVisible(frame) then
        text = text .. " hidden"
    end
    if frame.auraDataCached ~= nil then
        text = text .. " data"
    end
    if frame.auraDataUnit ~= nil then
        text = text .. " " .. tostring(frame.auraDataUnit)
    end
    local active = isActiveItem(frame)
    if active == true then
        text = text .. " active"
    elseif active == false then
        text = text .. " inactive"
    end
    if frame.PandemicIcon ~= nil then
        text = text .. " pandemic"
    end
    local at = refreshedAt[frame]
    if at ~= nil and since ~= nil and at >= since then
        text = text .. " reread"
    end
    at = cooldownDoneAt[frame]
    if at ~= nil and since ~= nil and at >= since then
        text = text .. " cooldown done"
    end
    return text
end

-- ---------------------------------------------------------------------------
-- The rule: one spell of the cooldown manager, with alerts per state.
-- ---------------------------------------------------------------------------
local CdmAuraStateRule = monitors.ruleRegistry:createType({ key = "CdmAuraState", parent = "State" })

CdmAuraStateRule:addFields({
    { key = "spell", type = "CdmSpell", persist = true, label = L["Spell"], sortPriority = 2 },
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
        key = "missing",
        type = "Alert",
        persist = true,
        label = L["Missing"],
        sortPriority = 3,
        alert = { key = "missing", label = L["Missing"] },
        outputs = stateOutputs,
    },
})

-- Whether the game has a pandemic window at all. WoW: Forever has none (a
-- refreshed aura carries nothing over), so camelot/cdmAuras.lua clears this
-- and hides the Pandemic state there.
CdmAuraStateRule.hasPandemic = true

function CdmAuraStateRule:initialize(config)
    self._frames = {}
    monitors.StateRule.initialize(self, config)
end

function CdmAuraStateRule:getTrackingFields()
    return { "spell" }
end

function CdmAuraStateRule:getStates()
    if not self.class.hasPandemic then
        return { { key = "applied" } }
    end
    return {
        { key = "applied" },
        { key = "pandemic", fallback = "applied" },
    }
end

-- The rule's spell by name: the cooldown manager item for a cast spell
-- (Moonfire) stands for its debuff too, and both carry the same name.
function CdmAuraStateRule:spellName()
    if self._nameFor ~= self.spell then
        self._nameFor = self.spell
        self._name = spellNameOf(self.spell)
    end
    return self._name
end

function CdmAuraStateRule:matchesFrame(names)
    local name = self:spellName()
    return name ~= nil and names[name] == true
end

function CdmAuraStateRule:setFrames(frames)
    self._frames = frames
    for _, frame in ipairs(frames) do
        hookFrame(frame)
    end
end

-- Whether to keep saying Pandemic now that the marker has gone while the
-- aura data stays: yes until the hold runs out, unless a frame re-read its
-- aura since the tick before the marker went (a refresh, so Applied holds).
function CdmAuraStateRule:holdingPandemic()
    local now = GetTime()
    local note = "held"
    if self._holdSince == nil then
        self._holdSince = self._lastTick or now
        self._holdTicks = 0
        note = "hold starts"
    end
    self._holdTicks = self._holdTicks + 1
    local expired = false
    for _, frame in ipairs(self._frames) do
        local at = cooldownDoneAt[frame]
        if at ~= nil and at >= self._holdSince then
            expired = true
        end
    end
    if expired then
        note = note .. ", cooldown done"
    elseif self._holdTicks >= PANDEMIC_HOLD_MIN_TICKS then
        for _, frame in ipairs(self._frames) do
            local at = refreshedAt[frame]
            if at ~= nil and at >= self._holdSince then
                self._holdSince = nil
                return false, "hold ends, aura reread"
            end
        end
    end
    if now - self._holdSince >= PANDEMIC_HOLD_SECONDS then
        self._holdSince = nil
        return false, "hold ends, timed out"
    end
    return true, note
end

-- Spoken as "Moonfire Applied" rather than "applied".
function CdmAuraStateRule:stateMessage(stateKey)
    local field = self.class:getField(stateKey)
    local label = field ~= nil and field.label or stateKey
    return { text = (self:spellName() or self:getLabel()) .. " " .. label, state = stateKey, rule = self }
end

-- One tick: the state from the frames, then the transition.
function CdmAuraStateRule:updateFromViewers(unit)
    local shown, pandemic = false, false
    local codes, scale = 0, 1
    for _, frame in ipairs(self._frames) do
        codes = codes + frameCode(frame, unit) * scale
        scale = scale * 32
        if auraShown(frame, unit) then
            shown = true
            if self.class.hasPandemic and inPandemic(frame) then
                pandemic = true
            end
        end
    end
    local changed = codes ~= self._lastCodes
    self._lastCodes = codes
    local before = self:getCurrentState()
    local note = nil
    local state
    if shown then
        state = pandemic and "pandemic" or "applied"
        if state == "applied" and before == "pandemic" then
            local holding, why = self:holdingPandemic()
            note = why
            if holding then
                state = "pandemic"
            end
        elseif state == "pandemic" then
            self._holdSince = nil
        end
        if state ~= before then
            self:transitionTo(state)
        else
            self:updateResolved(state)
        end
    else
        state = "missing"
        self._holdSince = nil
        if before ~= "missing" and (before ~= nil or self._announceRequested) then
            self:transitionTo("missing")
        else
            self:updateResolved("missing")
        end
    end
    self._announceRequested = false
    if self._traceNext ~= nil then
        note = note and (note .. ", " .. self._traceNext) or self._traceNext
        self._traceNext = nil
    end
    if changed or note ~= nil then
        self:addTrace(unit, before, state, note)
    end
    self._lastTick = GetTime()
end

-- One trace line: the clock, the spell, each frame's facts, the states.
function CdmAuraStateRule:addTrace(unit, before, after, note)
    local parts = {}
    for _, frame in ipairs(self._frames) do
        tinsert(parts, describeFrame(frame, unit, self._lastTick))
    end
    local line = string.format("%.2f", GetTime()) .. " " .. (self:spellName() or self:getLabel()) .. ": " .. table.concat(parts, "; ")
    line = line .. ". " .. tostring(before) .. " to " .. tostring(after)
    if note ~= nil then
        line = line .. ", " .. note
    end
    addTrace(line)
end

-- The aura now, as the game draws it: "Moonfire, 8.7, 3 stacks, Pandemic",
-- or "Moonfire, Missing".
function CdmAuraStateRule:currentText(unit)
    local name = self:spellName() or self:getLabel()
    for _, frame in ipairs(self._frames) do
        if auraShown(frame, unit) then
            local text = name
            text = text .. secrets.whenText(timerText(frame), ", ", "")
            text = text .. secrets.whenText(stacksText(frame), ", ", " " .. L["stacks"])
            if self.class.hasPandemic and inPandemic(frame) then
                text = text .. ", " .. L["Pandemic"]
            end
            return text
        end
    end
    return name .. ", " .. L["Missing"]
end

function CdmAuraStateRule:reset()
    monitors.StateRule.reset(self)
    self._holdSince = nil
end

function CdmAuraStateRule:getLabel()
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
    return L["Cooldown Manager Aura Rule"]
end

-- ---------------------------------------------------------------------------
-- The monitor: the unit, the rules, and the look over the viewers.
-- ---------------------------------------------------------------------------
local CdmAuraMonitor = monitors:createType("CdmAura")
CdmAuraMonitor.label = L["Cooldown Manager Auras"]

local UNIT_CHOICES = {
    { value = "target", label = L["Target"] },
    { value = "player", label = L["Player"] },
}

CdmAuraMonitor:addFields({
    { key = "unit", type = "Choice", default = "target", persist = true, label = L["Unit"], sortPriority = 2, choices = UNIT_CHOICES },
    { key = "announceOnUnitChange", type = "Bool", default = false, persist = true, label = L["Announce on Target Change"], sortPriority = 2 },
    -- The countdown text on the tracked items gains a decimal ("8.7"); it
    -- changes what is drawn on screen, so off by default.
    { key = "decimalTimer", type = "Bool", default = false, persist = true, label = L["One Decimal Timer"], sortPriority = 2 },
})

CdmAuraMonitor:updateFields({
    {
        key = "rules",
        availableTypes = function()
            return { { key = "CdmAuraState", label = L["Cooldown Manager Aura Rule"] } }
        end,
    },
})

CdmAuraMonitor.frameSpellNames = frameSpellNames
CdmAuraMonitor.cdmSpells = cdmSpells
CdmAuraMonitor.displaySpellID = displaySpellID
CdmAuraMonitor.trace = trace
CdmAuraMonitor.auraShown = auraShown
CdmAuraMonitor.frameVisible = frameVisible
CdmAuraMonitor.inPandemic = inPandemic

-- The live monitors, for the viewer hooks, the target change and the key.
local live = setmetatable({}, { __mode = "k" })
local hookedViewers = {}
local eventFrame = nil

local function markAllDirty()
    for monitor in pairs(live) do
        monitor._trackingDirty = true
    end
end

-- The viewers rebuild their item frames on a layout change; take a look
-- again then. Each viewer is hooked once it exists.
local function hookViewers()
    if hooksecurefunc == nil then
        return
    end
    for _, name in ipairs(VIEWERS) do
        local viewer = _G[name]
        if viewer ~= nil and not hookedViewers[name] and viewer.RefreshLayout ~= nil then
            hookedViewers[name] = true
            hooksecurefunc(viewer, "RefreshLayout", markAllDirty)
        end
    end
end

local function ensureEvents()
    if eventFrame ~= nil or CreateFrame == nil then
        return
    end
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function(_, event)
        for monitor in pairs(live) do
            if event == "PLAYER_TARGET_CHANGED" then
                monitor:onTargetChanged()
            else
                monitor._trackingDirty = true
                monitor._skipTicks = 2
            end
        end
    end)
end

function CdmAuraMonitor:initialize(config)
    monitors.Monitor.initialize(self, config)
    self._skipTicks = 0
    self._nextRescan = 0
    live[self] = true
    ensureEvents()
end

function CdmAuraMonitor:getTrackingFields()
    return { "unit", "decimalTimer" }
end

-- The item frames a rule may match: those of the aura viewers.
function CdmAuraMonitor:itemFrames()
    return viewerItemFrames(AURA_VIEWERS)
end

function CdmAuraMonitor:applyTimer(frame)
    local cooldown = frame.Cooldown
    if cooldown ~= nil and cooldown.SetCountdownMillisecondsThreshold ~= nil then
        pcall(cooldown.SetCountdownMillisecondsThreshold, cooldown, self.decimalTimer and DECIMAL_BELOW_SECONDS or 0)
    end
end

-- Match the viewers' item frames to the rules by spell name.
function CdmAuraMonitor:rescan()
    hookViewers()
    local frames = self:itemFrames()
    local namesOf = {}
    for _, frame in ipairs(frames) do
        namesOf[frame] = frameSpellNames(frame)
    end
    for _, rule in ipairs(self.rules or {}) do
        if rule.matchesFrame ~= nil then
            local matched = {}
            for _, frame in ipairs(frames) do
                if rule:matchesFrame(namesOf[frame]) then
                    tinsert(matched, frame)
                    self:applyTimer(frame)
                end
            end
            rule:setFrames(matched)
        end
    end
end

-- The viewers refresh their items against the new target a tick after the
-- change (each item is forced inactive first); two ticks of quiet keep
-- that from reading as the aura dropping and coming back.
function CdmAuraMonitor:onTargetChanged()
    if self.unit ~= "target" then
        return
    end
    self._skipTicks = 2
    for _, rule in ipairs(self.rules or {}) do
        if self.announceOnUnitChange then
            if rule.reset then
                rule:reset()
            end
            rule._announceRequested = true
            rule._traceNext = "after target change, announcing"
        else
            rule._traceNext = "after target change"
        end
    end
end

function CdmAuraMonitor:update()
    if not self.enabled then
        return
    end
    local now = GetTime()
    if self._trackingDirty or now >= self._nextRescan then
        self._trackingDirty = false
        self._nextRescan = now + RESCAN_SECONDS
        self:rescan()
    end
    if self._skipTicks > 0 then
        self._skipTicks = self._skipTicks - 1
        return
    end
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled and rule.updateFromViewers ~= nil then
            rule:updateFromViewers(self.unit)
        end
    end
end

function CdmAuraMonitor:unitLabel()
    for _, choice in ipairs(UNIT_CHOICES) do
        if choice.value == self.unit then
            return choice.label
        end
    end
    return tostring(self.unit)
end

function CdmAuraMonitor:getLabel()
    if self.label and self.label ~= "" then
        return self.label
    end
    return L["Cooldown Manager Auras"] .. " (" .. self:unitLabel() .. ")"
end

-- What the tracked auras read right now, each rule in turn.
function CdmAuraMonitor:currentTexts()
    local texts = {}
    for _, rule in ipairs(self.rules or {}) do
        if rule.enabled and rule.currentText ~= nil then
            tinsert(texts, rule:currentText(self.unit))
        end
    end
    return texts
end

-- The key: the tracked auras of every enabled monitor, as the game draws
-- them (time left, stacks, pandemic), target monitors first.
local module = WowVision.base ~= nil and WowVision.base.monitors or nil
if module ~= nil then
    if module.registerCommand ~= nil then
        module:registerCommand({
            name = "cdmlog",
            description = "Show what the Cooldown Manager Auras rules saw ('clear' resets; 'spells' lists the tracked buff and bar entries, 'cooldowns' the essential and utility ones)",
            func = function(args)
                if args == "clear" then
                    clearTrace()
                    print("Cooldown manager log cleared")
                    return
                end
                if args == "spells" or args == "cooldowns" then
                    local lines = {}
                    local viewers = args == "spells" and AURA_VIEWERS or { "EssentialCooldownViewer", "UtilityCooldownViewer" }
                    for _, frame in ipairs(viewerItemFrames(viewers)) do
                        tinsert(lines, describeEntry(frame, viewerTag))
                    end
                    if #lines == 0 then
                        print(args == "spells" and "No tracked buffs or bars" or "No essential or utility spells")
                        return
                    end
                    WowVision.testing.showResults(table.concat(lines, string.char(10)))
                    return
                end
                if #trace == 0 then
                    print("No cooldown manager log")
                    return
                end
                WowVision.testing.showResults(table.concat(trace, string.char(10)))
                WowVision:speak(trace[#trace])
            end,
        })
    end
    module:registerBinding({
        type = "Function",
        key = "monitors/speakCdmAuras",
        inputs = {},
        label = L["Speak Tracked Auras"],
        interruptSpeech = true,
        func = function()
            local parts = {}
            for _, monitor in ipairs(module.getMonitors()) do
                if monitor.enabled and monitor.class == CdmAuraMonitor then
                    for _, text in ipairs(monitor:currentTexts()) do
                        tinsert(parts, text)
                    end
                end
            end
            if #parts == 0 then
                WowVision:speak(L["No tracked auras"])
                return
            end
            WowVision:speak(secrets.join(parts, ". "))
        end,
    })
end

monitors.CdmAuraMonitor = CdmAuraMonitor
monitors.CdmAuraStateRule = CdmAuraStateRule
