local L = WowVision:getLocale()
local objects = WowVision.objects

local Cooldown = objects:createGlobalType("Cooldown")
Cooldown:setLabel(L["Cooldown"])

Cooldown:addParameter({
    key = "spellId",
    type = "Spell",
    label = L["Spell ID"],
    required = true,
})

Cooldown:addParameter({
    key = "onCooldown",
    type = "Bool",
    label = L["On Cooldown"],
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

-- Fields

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
    if params.onCooldown ~= nil then
        return true, false
    end
    return false, false
end

function Cooldown:getObjectParams(key, data)
    return { spellId = key, onCooldown = data and not data.isReady or false }
end

function Cooldown:getObjectKey(params)
    return params.spellId
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

-- Spell lifecycle

function Cooldown:ensureEvents()
    if self._eventsRegistered then
        return
    end
    self._frame = CreateFrame("Frame")
    self._frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self._frame:RegisterEvent("SPELL_UPDATE_USABLE")
    self._frame:RegisterEvent("UNIT_SPELLCAST_SENT")
    self._frame:RegisterEvent("UNIT_SPELL_HASTE")
    self._frame:SetScript("OnEvent", function(frame, event, ...)
        self:onEvent(event, ...)
    end)
    self._eventsRegistered = true
    self._pendingCasts = {}
end

function Cooldown:addSpell(spellId)
    if self.objects[spellId] then
        return
    end
    local data = getCooldownData(spellId)
    self:addObject(spellId, data)
    self:ensureEvents()
end

function Cooldown:removeSpell(spellId)
    self:removeObject(spellId)
    if self._pendingCasts then
        self._pendingCasts[spellId] = nil
    end
end

function Cooldown:track(info)
    -- Support single spellId or array of spellIds
    local spellIds = info.spellIds or {}
    if info.params and info.params.spellId then
        tinsert(spellIds, info.params.spellId)
    end

    -- Add spell objects first (so they exist when tracker subscribes)
    for _, spellId in ipairs(spellIds) do
        self:addSpell(spellId)
    end

    -- Ensure events are registered for cast discovery even with no initial spells
    self:ensureEvents()

    -- Create tracker (parent handles registration + replaying existing objects)
    local tracker = objects.GlobalType.track(self, info)
    tracker._trackedSpells = {}
    for _, spellId in ipairs(spellIds) do
        tracker._trackedSpells[spellId] = true
    end
    return tracker
end

function Cooldown:untrack(tracker)
    objects.GlobalType.untrack(self, tracker)
    -- Remove spells no longer needed by any tracker
    for spellId, _ in pairs(tracker._trackedSpells or {}) do
        local stillNeeded = false
        for otherTracker, _ in pairs(self.trackers) do
            if otherTracker._trackedSpells and otherTracker._trackedSpells[spellId] then
                stillNeeded = true
                break
            end
        end
        if not stillNeeded then
            self:removeSpell(spellId)
        end
    end
end

function Cooldown:onEvent(event, ...)
    if event == "UNIT_SPELLCAST_SENT" then
        local unit, target, castGUID, spellID = ...
        if unit == "player" and spellID and not self.objects[spellID] then
            self._pendingCasts[spellID] = true
        end
        return
    end

    -- SPELL_UPDATE_COOLDOWN / SPELL_UPDATE_USABLE
    -- Promote pending casts that have real cooldowns
    if self._pendingCasts then
        for spellId, _ in pairs(self._pendingCasts) do
            if not self.objects[spellId] then
                local startTime, duration = GetSpellCooldown(spellId)
                if duration and duration > 0 and not isGCD(startTime, duration) then
                    self:addSpell(spellId)
                end
            end
        end
        self._pendingCasts = {}
    end

    self:refreshAll()
end

function Cooldown:refreshAll()
    for spellId, ref in pairs(self.objects) do
        local newData = getCooldownData(spellId)
        local oldData = ref.data

        -- Detect meaningful state changes
        local changed = oldData.isReady ~= newData.isReady
            or oldData.charges ~= newData.charges
            or oldData.duration ~= newData.duration
            or oldData.startTime ~= newData.startTime

        -- Update dynamic param before modify so verify sees current state
        ref.object.params.onCooldown = not newData.isReady

        if changed then
            self:modifyObject(spellId, newData)
        else
            ref.data = newData
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
