local L = WowVision:getLocale()
local objects = WowVision.objects

local Cooldown = objects:createObjectType("Cooldown")
Cooldown:setLabel(L["Cooldown"])

Cooldown:addParameter({
    key = "spellId",
    type = "Spell",
    label = L["Spell ID"],
    required = true,
})

-- GCD detection
local GCD_SPELL = C_Spell and 61304 or 29515

local GetSpellCooldown = GetSpellCooldown
    or function(spellID)
        if not spellID then
            return 0, 0, true, 1
        end
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            return info.startTime, info.duration, info.isEnabled, info.modRate
        end
        return 0, 0, true, 1
    end

local GetSpellCharges = GetSpellCharges
    or function(spellID)
        if not spellID or not C_Spell or not C_Spell.GetSpellCharges then
            return nil
        end
        local info = C_Spell.GetSpellCharges(spellID)
        if info then
            return info.currentCharges, info.maxCharges, info.cooldownStartTime, info.cooldownDuration, info.chargeModRate
        end
        return nil
    end

local function isGCD(startTime, duration)
    if duration == 0 then
        return false
    end
    local gcdStart, gcdDuration = GetSpellCooldown(GCD_SPELL)
    if gcdDuration and gcdDuration > 0 then
        return math.abs(startTime - gcdStart) < 0.01 and math.abs(duration - gcdDuration) < 0.01
    end
    return false
end

local function getSpellName(spellID)
    if GetSpellInfo then
        return (GetSpellInfo(spellID))
    elseif C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        return info and info.name
    end
    return nil
end

local function getCooldownData(spellId)
    local startTime, duration, enabled = GetSpellCooldown(spellId)
    local onGCD = isGCD(startTime, duration)

    -- Bogus value check
    if duration > 604800 then
        duration = 0
        startTime = 0
    end

    local isReady = enabled and (duration == 0 or onGCD)
    local remaining = 0
    if not isReady and duration > 0 then
        remaining = (startTime + duration) - GetTime()
        if remaining < 0 then
            remaining = 0
            isReady = true
        end
    end

    local charges, maxCharges = GetSpellCharges(spellId)
    local hasCharges = maxCharges and maxCharges > 0

    return {
        spellId = spellId,
        name = getSpellName(spellId),
        startTime = isReady and 0 or startTime,
        duration = isReady and 0 or duration,
        remaining = remaining,
        isReady = isReady,
        charges = charges or 0,
        maxCharges = maxCharges or 0,
        hasCharges = hasCharges or false,
    }
end

-- Tracked spells: spellId → { trackers = {}, object = Object, data = {} }
Cooldown.spells = {}

Cooldown:addField({
    key = "spellId",
    type = "Number",
    label = L["Spell ID"],
    getCached = function(cache) return cache.spellId end,
    get = function(params) return params.spellId end,
})

Cooldown:addField({
    key = "name",
    type = "String",
    label = L["Name"],
    getCached = function(cache) return cache.name end,
    get = function(params) return getSpellName(params.spellId) end,
})

Cooldown:addField({
    key = "startTime",
    type = "Number",
    label = L["Start Time"],
    getCached = function(cache) return cache.startTime end,
    get = function(params) return getCooldownData(params.spellId).startTime end,
})

Cooldown:addField({
    key = "duration",
    type = "Number",
    label = L["Duration"],
    getCached = function(cache) return cache.duration end,
    get = function(params) return getCooldownData(params.spellId).duration end,
})

Cooldown:addField({
    key = "remaining",
    type = "Time",
    timeType = "duration",
    label = L["Remaining"],
    getCached = function(cache)
        if cache.isReady then return 0 end
        local remaining = (cache.startTime + cache.duration) - GetTime()
        if remaining < 0 then return 0 end
        return remaining
    end,
    get = function(params) return getCooldownData(params.spellId).remaining end,
})

Cooldown:addField({
    key = "isReady",
    type = "Bool",
    label = L["Is Ready"],
    getCached = function(cache) return cache.isReady end,
    get = function(params) return getCooldownData(params.spellId).isReady end,
})

Cooldown:addField({
    key = "charges",
    type = "Number",
    label = L["Charges"],
    getCached = function(cache) return cache.charges end,
    get = function(params)
        local charges = GetSpellCharges(params.spellId)
        return charges or 0
    end,
})

Cooldown:addField({
    key = "maxCharges",
    type = "Number",
    label = L["Max Charges"],
    getCached = function(cache) return cache.maxCharges end,
    get = function(params)
        local _, maxCharges = GetSpellCharges(params.spellId)
        return maxCharges or 0
    end,
})

Cooldown:addField({
    key = "hasCharges",
    type = "Bool",
    label = L["Has Charges"],
    getCached = function(cache) return cache.hasCharges end,
    get = function(params)
        local _, maxCharges = GetSpellCharges(params.spellId)
        return maxCharges and maxCharges > 0
    end,
})

function Cooldown:validParams(params)
    if params.spellId then
        return true, true
    end
    return false, false
end

function Cooldown:getCache(params)
    local entry = self.spells[params.spellId]
    if entry then
        return entry.data
    end
    return nil
end

function Cooldown:getLabel(params)
    if params.spellId then
        local name = getSpellName(params.spellId)
        if name then
            return name
        end
    end
    return self.label
end

function Cooldown:getFocusString(params)
    local name = self:get(params, "name") or L["Cooldown"]
    local isReady = self:get(params, "isReady")
    if isReady then
        return name .. ": " .. L["Ready"]
    end
    local remaining = self:get(params, "remaining")
    if remaining then
        return name .. ": " .. string.format("%.1f", remaining) .. "s"
    end
    return name
end

-- Spell tracking management (similar to UnitType unit management)

function Cooldown:addSpell(spellId)
    if self.spells[spellId] then
        return self.spells[spellId]
    end
    local entry = {
        spellId = spellId,
        trackers = {},
        object = objects.Object:new(self, { spellId = spellId }),
        data = getCooldownData(spellId),
    }
    self.spells[spellId] = entry

    -- Register events if this is the first spell
    if not self._eventsRegistered then
        self._frame = CreateFrame("Frame")
        self._frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        self._frame:RegisterEvent("SPELL_UPDATE_USABLE")
        self._frame:SetScript("OnEvent", function(frame, event)
            self:onEvent(event)
        end)
        self._eventsRegistered = true
    end

    return entry
end

function Cooldown:removeSpell(spellId)
    self.spells[spellId] = nil
    -- Unregister events if no more spells tracked
    if not next(self.spells) and self._frame then
        self._frame:UnregisterAllEvents()
        self._eventsRegistered = false
    end
end

function Cooldown:addTracker(spellId, tracker)
    local entry = self.spells[spellId]
    if not entry then
        return
    end
    entry.trackers[tracker] = true
    tracker:add(entry.object)
end

function Cooldown:removeTracker(spellId, tracker)
    local entry = self.spells[spellId]
    if not entry then
        return
    end
    entry.trackers[tracker] = nil
    tracker:remove(entry.object)
    if not next(entry.trackers) then
        self:removeSpell(spellId)
    end
end

function Cooldown:track(info)
    local tracker = objects.ObjectTracker:new(info)
    tracker.manager = self
    tracker._trackedSpells = {}

    -- Support single spellId or array of spellIds
    local spellIds = info.spellIds or {}
    if info.params and info.params.spellId then
        tinsert(spellIds, info.params.spellId)
    end

    for _, spellId in ipairs(spellIds) do
        local entry = self:addSpell(spellId)
        self:addTracker(spellId, tracker)
        tracker._trackedSpells[spellId] = true
    end
    return tracker
end

function Cooldown:untrack(tracker)
    for spellId, _ in pairs(tracker._trackedSpells or {}) do
        self:removeTracker(spellId, tracker)
    end
end

function Cooldown:onEvent(event)
    -- Events are supplementary — onUpdate is the main driver
    -- But we still refresh data on events for responsiveness
    self:refreshAll()
end

function Cooldown:refreshAll()
    for spellId, entry in pairs(self.spells) do
        local newData = getCooldownData(spellId)
        local oldData = entry.data

        -- Detect meaningful state changes
        local changed = oldData.isReady ~= newData.isReady
            or oldData.charges ~= newData.charges
            or oldData.duration ~= newData.duration
            or oldData.startTime ~= newData.startTime

        entry.data = newData

        if changed then
            for tracker, _ in pairs(entry.trackers) do
                tracker:modify(entry.object)
            end
        end
    end
end

function Cooldown:onUpdate()
    self:refreshAll()
end

Cooldown:registerTemplate({
    key = "default",
    name = "Default",
    format = "{name}: {remaining}",
})
