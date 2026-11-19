local GroupHealth = WowVision.groupHealth
local module = WowVision.base.groupHealth
local L = module.L
local settings = module:hasSettings()
local secrets = WowVision.secrets
local isSecret = secrets.isSecret

-- Dispellable debuffs: a watched member who gets a debuff the player can
-- dispel is said as their number and the debuff's type, "Poison 3" (the
-- idea comes from Sku's debuff monitor). Who is watched has its own party
-- and raid switches here; Include Yourself, the raid groups, the numbers,
-- voice, rate and volume are the group health monitor's.
--
-- In combat every aura read is closed to addons. What still works
-- (measured on WoW: Forever 70938, 2026-11-18, on the player's own auras;
-- the same way core/crowdControl.lua and the Aura buffer read the target):
-- a tooltip of our own, filled with one aura by index and filter, is
-- allowed, and its line count stays plain. The game's RAID filter with
-- HARMFUL keeps exactly the debuffs the player can dispel (AuraUtil.lua:
-- "harmful auras the player can dispel"), so filling index after index
-- until a tooltip comes back empty counts them, in combat too.
--
-- The type is the right side of the tooltip's first line: the game's own
-- word ("Magic", "Poison"). In combat it is secret, and so are its colour
-- and its width (measured the same day): it can be spoken whole, never
-- shortened or looked at. Out of combat it is the same word, so a member
-- sounds the same in and out of a fight. The word said is the last
-- debuff's in the list, the newest as far as the order tells.
--
-- What speaks: a member's count going up (a new debuff), at once. The
-- repeat runs only from such an announcement and only while the member
-- still carries a debuff; it never says that someone carries nothing.

local FILTER = "HARMFUL|RAID"
-- More debuffs than any member carries; the count stops at the first empty fill.
local MAX_INDEX = 40
-- How often the repeat looks for a due member.
local REPEAT_CHECK = 0.1

-- Watch Raid starts off: a raid is many members to read and to hear.
local DEFAULTS = { enabled = false, watchParty = true, watchRaid = false, repeatInterval = 3, numberFirst = false }

local dispelField = settings:add({
    key = "dispellable",
    type = "Category",
    label = L["Dispellable Debuffs"],
    fields = {
        {
            key = "enabled",
            type = "Bool",
            label = L["Announce Dispellable Debuffs"],
            default = DEFAULTS.enabled,
        },
        {
            key = "watchParty",
            type = "Bool",
            label = L["Watch Party"],
            default = DEFAULTS.watchParty,
        },
        {
            key = "watchRaid",
            type = "Bool",
            label = L["Watch Raid"],
            default = DEFAULTS.watchRaid,
        },
        {
            key = "repeatInterval",
            type = "Number",
            label = L["Repeat Every (seconds, 0 is off)"],
            default = DEFAULTS.repeatInterval,
            min = 0,
            max = 60,
        },
        -- Off: the type first ("Poison 3"), as Sku says it.
        {
            key = "numberFirst",
            type = "Bool",
            label = L["Number First"],
            default = DEFAULTS.numberFirst,
        },
    },
})

-- A setting of the category, falling back to the default when a saved
-- category predates the key.
local function dispelSetting(key)
    local values = module.settings.dispellable
    local value = nil
    if values ~= nil then
        value = values[key]
    end
    if value == nil then
        value = DEFAULTS[key]
    end
    return value
end
module.dispelSetting = dispelSetting

-- The switches that decide who is watched rebuild the list at once, and
-- everyone on it is read, so a debuff already carried is said.
local WATCH_KEYS = { enabled = true, watchParty = true, watchRaid = true }
for _, subField in ipairs(dispelField:getSubFields()) do
    if WATCH_KEYS[subField.key] then
        module.decidesWhoIsWatched(subField)
    end
end

-- The tooltip --------------------------------------------------------------------

local TIP = "WowVisionDispelTooltip"
local tooltip

-- The reader: fills the tooltip with one debuff and returns its line count
-- (nil: refused or not plain), and the right side of the first line of the
-- last fill. Tests hand in a stand-in through module.dispelReader.
local function reader()
    if module.dispelReader ~= nil then
        return module.dispelReader
    end
    if CreateFrame == nil then
        return nil
    end
    if tooltip == nil then
        tooltip = CreateFrame("GameTooltip", TIP, UIParent, "GameTooltipTemplate")
        module.dispelReader = {
            fill = function(unit, index)
                tooltip:ClearLines()
                tooltip:SetOwner(UIParent, "ANCHOR_NONE")
                if not pcall(tooltip.SetUnitAura, tooltip, unit, index, FILTER) then
                    return nil
                end
                local lines = tooltip:NumLines()
                if isSecret(lines) then
                    return nil
                end
                return lines
            end,
            -- A right side the fill left unused is hidden and may still
            -- hold an earlier aura's text.
            word = function()
                local fontString = _G[TIP .. "TextRight1"]
                if fontString == nil then
                    return nil
                end
                local shown = fontString:IsShown()
                if not isSecret(shown) and not shown then
                    return nil
                end
                local text = fontString:GetText()
                if not secrets.hasText(text) then
                    return nil
                end
                return text
            end,
        }
    end
    return module.dispelReader
end

-- How many debuffs the player can dispel the unit carries, and the type
-- word of the last one; nil when the game does not tell.
function module:countDispellable(unit)
    local read = reader()
    if read == nil then
        return nil
    end
    local count, word = 0, nil
    for index = 1, MAX_INDEX do
        local lines = read.fill(unit, index)
        if lines == nil then
            return nil
        end
        if lines == 0 then
            break
        end
        count = index
        word = read.word()
    end
    return count, word
end

-- Members --------------------------------------------------------------------------

-- The dispel list: built like the monitor's (module.lua, collect), with
-- this feature's party and raid switches. Empty while switched off.
module.dispelMembers = {}
module.dispelAliases = {}

function module:rebuildDispel(inCombat)
    if not dispelSetting("enabled") then
        self.dispelMembers, self.dispelAliases = {}, {}
        self.dispelRaidMode = nil
        return
    end
    -- In a raid the members carry the monitor's raid numbers: with only
    -- Watch Party on, the player's own raid group by those numbers, so a
    -- number names the same person in both. Only when the monitor watches
    -- no raid either does the party keep its party numbers.
    local watchRaid = dispelSetting("watchRaid")
    local ownGroupOnly = not watchRaid and dispelSetting("watchParty") and self.settings.watchRaid
    local raid = IsInRaid() and (watchRaid or ownGroupOnly)
    if raid and inCombat and self.dispelRaidMode then
        self.rosterDirty = true
        return
    end
    self.dispelRaidMode = raid
    self.dispelMembers, self.dispelAliases = self:collect(self.dispelMembers, {
        includeSelf = self.settings.includeSelf,
        party = dispelSetting("watchParty"),
        raid = watchRaid or ownGroupOnly,
        ownGroupOnly = ownGroupOnly,
    })
    -- new members carry no dispel state yet: read them
    self:markAllDispel()
end

function module:dispelMemberFor(unit)
    return self.dispelMembers[unit] or self.dispelAliases[unit]
end

-- Announcing ----------------------------------------------------------------------

-- Said once per world entry when the game refuses the read, so silence
-- never passes for "nothing to dispel".
function module:dispelUnavailable()
    if not self.dispelUnavailableSaid then
        self.dispelUnavailableSaid = true
        WowVision:notify(L["Dispellable debuffs unavailable here"])
    end
end

function module:dispelState(member)
    if member.dispel == nil then
        member.dispel = GroupHealth.newDispelState()
    end
    return member.dispel
end

function module:sayDispel(member, word)
    self:speak(GroupHealth.dispelText(member.number, word, dispelSetting("numberFirst")))
end

-- Reads the member afresh and announces a new debuff.
function module:checkDispel(member)
    local count, word = self:countDispellable(member.unit)
    if count == nil then
        self:dispelUnavailable()
        return
    end
    local state = self:dispelState(member)
    local now = GetTime()
    if not GroupHealth.dispelStep(state, count, now) then
        return
    end
    if self:silenced() then
        -- Not said: the repeat says it once the monitor speaks again.
        state.lastSaid = nil
        return
    end
    self:sayDispel(member, word)
end

-- Members whose auras changed are read once per frame at most: the game
-- sends aura events in bursts.
module.dispelDirty = {}

function module:markDispel(member)
    self.dispelDirty[member] = true
end

function module:markAllDispel()
    for _, member in pairs(self.dispelMembers) do
        self.dispelDirty[member] = true
    end
end

function module:onAura(unit)
    if not dispelSetting("enabled") then
        return
    end
    if unit == nil or isSecret(unit) then
        self:markAllDispel()
        return
    end
    local member = self:dispelMemberFor(unit)
    if member ~= nil then
        self:markDispel(member)
    end
end

-- The once-per-frame work: the members marked since the last frame, then
-- the repeat, one member per check and only while nothing else is queued
-- or playing (like the health repeat), so it never holds back other speech.
function module:checkDispels()
    if not dispelSetting("enabled") then
        self.dispelDirty = {}
        return
    end
    if next(self.dispelDirty) ~= nil then
        local dirty = self.dispelDirty
        self.dispelDirty = {}
        for member in pairs(dirty) do
            -- a member dropped by a roster change since the mark is not read
            if self:dispelMemberFor(member.unit) == member then
                self:checkDispel(member)
            end
        end
    end
    local now = GetTime()
    if self.nextDispelRepeat ~= nil and now < self.nextDispelRepeat then
        return
    end
    self.nextDispelRepeat = now + REPEAT_CHECK
    if self:silenced() or not WowVision.base.speech:idle() then
        return
    end
    local interval = dispelSetting("repeatInterval")
    local due, dueSince
    for _, member in pairs(self.dispelMembers) do
        local state = member.dispel
        if state ~= nil and GroupHealth.dispelRepeatDue(state, now, interval) then
            local since = state.lastSaid or -math.huge
            if due == nil or since < dueSince or (since == dueSince and member.number < due.number) then
                due, dueSince = member, since
            end
        end
    end
    if due == nil then
        return
    end
    -- Read afresh: the debuff may be gone since the last aura event.
    local count, word = self:countDispellable(due.unit)
    local state = due.dispel
    if count == nil then
        state.lastSaid = now
        self:dispelUnavailable()
        return
    end
    GroupHealth.dispelStep(state, count, now)
    if state.active then
        state.lastSaid = now
        self:sayDispel(due, word)
    end
end
