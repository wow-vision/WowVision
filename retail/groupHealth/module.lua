local GroupHealth = WowVision.groupHealth

local module = WowVision.base:createModule("groupHealth")
local L = module.L
module:setLabel(L["Group Health Monitor"])
-- Off until the player turns it on (the module's own Enabled toggle, which
-- also switches its events and the snapshot key): it speaks on its own.
module.enabled = false
local settings = module:hasSettings()

-- The group health monitor: a hurt group member is spoken as their number,
-- the pitch telling how hurt (the lower the health, the higher). The idea
-- and the numbering come from Sku's health monitor: the player is 1, party
-- members 2 to 5, raid members by Sku's dial numbers (logic.lua), numbered
-- anew only out of combat so a number never moves during a fight.
--
-- Health is secret here (see logic.lua), so the addon never decides
-- whether someone is hurt: every announcement is prepared behind volume
-- gates (curves of ours) and the engine plays the one whose health range
-- matches. Health changes are not followed (they come by the hundreds a
-- second at times, far more than speech could say). What speaks:
-- - The repeat: every member below their role's Repeat Below, at the
--   role's interval, one member at a time and only while nothing else is
--   queued or playing. The announcements come at a fixed rate whatever the
--   fight does, and WowVision's own speech never waits behind more than
--   the one announcement playing.
-- - "<number> dead" once (whether a member is dead is not secret).
-- - The snapshot key: everyone once, in number order, a member at full
--   health as "<number> full".
-- All of it goes through the speech queue (retail/speech.lua) with the
-- monitor's own voice, rate and volume: pitch needs a real SAPI voice,
-- which an NVDA bridge voice is not.

local ROLE_KEYS = { TANK = "tank", HEALER = "healer", DAMAGER = "damager", NONE = "none" }

-- Repeat Below after Sku's thresholds per role; the interval is Sku's
-- default of 3 seconds.
local ROLE_DEFAULTS = {
    TANK = { repeatThreshold = 80, repeatInterval = 3 },
    HEALER = { repeatThreshold = 70, repeatInterval = 3 },
    DAMAGER = { repeatThreshold = 60, repeatInterval = 3 },
    NONE = { repeatThreshold = 60, repeatInterval = 3 },
}

-- Settings ----------------------------------------------------------------------

-- Saved by the voice's name: the pitch scales are tuned per voice, and
-- installing a voice moves the game's voice numbers.
local voiceField = settings:add({
    key = "voice",
    type = "TtsVoice",
    label = L["Voice"],
    default = 0,
})

settings:add({
    key = "rate",
    type = "Number",
    label = L["Speech Rate"],
    -- Short numbers: five hurt members fit in little time. The voice
    -- profiles were measured at this rate.
    default = 7,
    min = -10,
    max = 10,
})
settings:add({
    key = "volume",
    type = "Number",
    label = L["Speech Volume"],
    default = 100,
    min = 0,
    max = 100,
})
settings:add({
    key = "includeSelf",
    type = "Bool",
    label = L["Include Yourself"],
    default = true,
})
settings:add({
    key = "watchParty",
    type = "Bool",
    label = L["Watch Party"],
    default = true,
})
settings:add({
    key = "watchRaid",
    type = "Bool",
    label = L["Watch Raid"],
    default = true,
})
settings:add({
    key = "announceFull",
    type = "Bool",
    label = L["Announce Full Health"],
    default = true,
})
settings:add({
    key = "announceDeaths",
    type = "Bool",
    label = L["Announce Deaths"],
    default = true,
})
settings:add({
    key = "silentOutOfCombat",
    type = "Bool",
    label = L["Silent Out of Combat"],
    default = false,
})
-- Off: every member takes a turn at the role's interval, and silence
-- means healthy (Sku's continuous monitor). On: a turn only after a health
-- event for the member since their last turn, so a member hit once is said
-- once and then stays quiet, and silence means nothing changed (closer to
-- Sku's pitch monitor, which speaks on changes). The interval still caps
-- the rate: heal and damage ticks cost at most one turn per interval.
settings:add({
    key = "repeatOnlyAfterChange",
    type = "Bool",
    label = L["Repeat Only After a Change"],
    default = false,
})

local raidGroupFields = {}
for group = 1, GroupHealth.MAX_RAID_GROUPS do
    tinsert(raidGroupFields, {
        key = "group" .. group,
        type = "Bool",
        label = string.format(L["Group %d"], group),
        default = true,
    })
end
settings:add({
    key = "raidGroups",
    type = "Category",
    label = L["Raid Groups"],
    fields = raidGroupFields,
})

local ROLE_LABELS = {
    TANK = L["Tanks"],
    HEALER = L["Healers"],
    DAMAGER = L["Damage Dealers"],
    NONE = L["No Role"],
}

for _, role in ipairs(GroupHealth.ROLES) do
    local defaults = ROLE_DEFAULTS[role]
    settings:add({
        key = ROLE_KEYS[role],
        type = "Category",
        label = ROLE_LABELS[role],
        fields = {
            {
                key = "repeatThreshold",
                type = "Number",
                label = L["Repeat Below (percent)"],
                default = defaults.repeatThreshold,
                min = 0,
                max = 100,
            },
            {
                key = "repeatInterval",
                type = "Number",
                label = L["Repeat Every (seconds, 0 is off)"],
                default = defaults.repeatInterval,
                min = 0,
                max = 300,
            },
        },
    })
end

-- A role's setting, falling back to the default when a saved category
-- predates the key.
local function roleSetting(role, key)
    local values = module.settings[ROLE_KEYS[role]]
    local value = values ~= nil and values[key] or nil
    if value == nil then
        value = ROLE_DEFAULTS[role][key]
    end
    return value
end

local function raidGroupWatched(group)
    local groups = module.settings.raidGroups
    return groups == nil or groups["group" .. group] ~= false
end

-- Curves ------------------------------------------------------------------------

local isSecret = WowVision.secrets.isSecret

-- One curve object per point list, reused: the pitch scale, the full gate
-- and two gates per role threshold.
local curves = {}

local function curveFor(points)
    local key = GroupHealth.pointsKey(points)
    local curve = curves[key]
    if curve == nil then
        curve = C_CurveUtil.CreateCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        for _, point in ipairs(points) do
            curve:AddPoint(point[1], point[2])
        end
        curves[key] = curve
    end
    return curve
end

-- The member's health through a curve; nil when the game refuses the unit
-- (party and raid units are restricted for addons in PvP).
local function through(unit, points)
    local ok, value = pcall(UnitHealthPercent, unit, true, curveFor(points))
    if not ok then
        return nil
    end
    return value
end

local function voiceName(voiceID)
    for _, voice in ipairs(C_VoiceChat.GetTtsVoices() or {}) do
        if voice.voiceID == voiceID then
            return voice.name
        end
    end
    return nil
end

-- The voice profile of the chosen voice (voices.lua), looked up by its name.
-- The game lists its voices only once in the world: a voice not found yet
-- is looked up again next time instead of keeping the fallback.
local profileCache = {}

function module:profile()
    local voice = self.settings.voice or 0
    local cached = profileCache[voice]
    if cached == nil then
        local name = voiceName(voice)
        local profile = GroupHealth.voices:forVoice(name)
        cached = { profile = profile, pitch = GroupHealth.pitchPoints(profile) }
        if name ~= nil then
            profileCache[voice] = cached
        end
    end
    return cached.profile, cached.pitch
end

local fullPoints = GroupHealth.fullPoints()

-- Members -----------------------------------------------------------------------

module.members = {}
module.aliases = {}
module.rosterDirty = false

local VALID_ROLES = { TANK = true, HEALER = true, DAMAGER = true }

local function roleOf(unit, rosterRole)
    local ok, role = pcall(UnitGroupRolesAssigned, unit)
    if not ok or isSecret(role) or not VALID_ROLES[role] then
        role = "NONE"
    end
    if role == "NONE" and rosterRole == "MAINTANK" and not isSecret(rosterRole) then
        role = "TANK"
    end
    return role
end

-- A comparison the game may refuse or answer secretly counts as "no".
local function sameUnit(a, b)
    local ok, same = pcall(UnitIsUnit, a, b)
    return ok and not isSecret(same) and same == true
end

local function plainTrue(func, unit)
    local ok, value = pcall(func, unit)
    return ok and not isSecret(value) and value == true
end

local function plainFalse(func, unit)
    local ok, value = pcall(func, unit)
    return ok and not isSecret(value) and value == false
end

-- Who the unit is, where the game says so (identities are secret in some
-- places): nil otherwise.
local function plainGuid(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if ok and guid ~= nil and not isSecret(guid) then
        return guid
    end
    return nil
end

-- A member; `old` is the same person before the roster update, who keeps
-- their repeat timing, death and pending change. Unit tokens move when
-- someone leaves, so the person is found by GUID. Someone already dead when
-- first seen is not announced: their death is old news (the snapshot says
-- it). A new member counts as changed, so Repeat Only After a Change says
-- them once.
local function newMember(unit, number, role, old)
    local member = {
        unit = unit,
        guid = plainGuid(unit),
        number = number,
        role = role,
        dead = plainTrue(UnitIsDeadOrGhost, unit),
        changed = true,
    }
    if old ~= nil then
        member.lastRepeat = old.lastRepeat
        member.dead = old.dead
        member.changed = old.changed
    end
    return member
end

function module:buildRaid(members, aliases, previous)
    local roster = {}
    local rosterRoles = {}
    for index = 1, MAX_RAID_MEMBERS or 40 do
        local ok, _, _, subgroup, _, _, _, _, _, _, rosterRole = pcall(GetRaidRosterInfo, index)
        if ok and subgroup ~= nil and not isSecret(subgroup) then
            roster[index] = subgroup
            rosterRoles[index] = rosterRole
        end
    end
    local numbers = GroupHealth.raidNumbers(roster, MAX_RAID_MEMBERS or 40)
    for index, number in pairs(numbers) do
        local unit = "raid" .. index
        local isSelf = sameUnit(unit, "player")
        if raidGroupWatched(roster[index]) and (self.settings.includeSelf or not isSelf) then
            members[unit] = newMember(unit, number, roleOf(unit, rosterRoles[index]), previous(unit))
            -- Events may name the same person by another token.
            if isSelf then
                aliases.player = members[unit]
            end
            for party = 1, 4 do
                if sameUnit(unit, "party" .. party) then
                    aliases["party" .. party] = members[unit]
                end
            end
        end
    end
end

function module:buildParty(members, previous)
    if self.settings.includeSelf then
        members.player = newMember("player", 1, roleOf("player"), previous("player"))
    end
    if IsInGroup() and self.settings.watchParty then
        for party = 1, 4 do
            local unit = "party" .. party
            if UnitExists(unit) then
                members[unit] = newMember(unit, party + 1, roleOf(unit), previous(unit))
            end
        end
    end
end

function module:collect()
    local byGuid = {}
    for _, member in pairs(self.members) do
        if member.guid ~= nil then
            byGuid[member.guid] = member
        end
    end
    local function previous(unit)
        local guid = plainGuid(unit)
        return guid ~= nil and byGuid[guid] or nil
    end
    local members, aliases = {}, {}
    if IsInRaid() and self.settings.watchRaid then
        self:buildRaid(members, aliases, previous)
    else
        self:buildParty(members, previous)
    end
    return members, aliases
end

-- Raid numbers change only out of combat; a party's follow its tokens.
function module:rebuild()
    local raid = IsInRaid() and self.settings.watchRaid
    if raid and InCombatLockdown() and self.raidMode then
        self.rosterDirty = true
        return
    end
    self.rosterDirty = false
    self.raidMode = raid
    self.members, self.aliases = self:collect()
end

function module:memberFor(unit)
    return self.members[unit] or self.aliases[unit]
end

-- Speaking ----------------------------------------------------------------------

-- The utterance counter behind the paddings (logic.lua). In the account
-- store: the engine's audio cache outlives a /reload and a change of
-- character, so no two utterances of any character may share a count.
function module:nextCount()
    local data = self.globalDB ~= nil and self.globalDB.data or nil
    if data == nil then
        self.fallbackCount = (self.fallbackCount or math.floor(GetTime() * 1000)) + 1
        return self.fallbackCount
    end
    data.utterances = (data.utterances or 0) + 1
    return data.utterances
end

-- Through the speech queue, with the monitor's own voice, rate and volume.
-- The queue adds its cache-buster and the bridge hand-over by
-- concatenation, which a secret text allows.
function module:speak(text)
    WowVision.base.speech:speak(text, self.settings.voice or 0, self.settings.rate, self.settings.volume)
end

function module:unavailable()
    if not self.unavailableSaid then
        self.unavailableSaid = true
        WowVision:notify(L["Group health monitor unavailable here"])
    end
end

-- The health range [low, high) a lane speaks in; a high above 1 includes
-- full health.
function module:laneRange(member, lane)
    if lane == "repeat" then
        return 0, GroupHealth.fraction(roleSetting(member.role, "repeatThreshold"))
    elseif lane == "snapshot" and self.settings.announceFull then
        -- At full health the snapshot says "<number> full" instead.
        return 0, 1
    end
    return 0, 2
end

-- Speaks the member on a lane ("repeat", "snapshot" or "dead"): the number
-- behind the lane's gates, so the engine plays it only in the lane's
-- health range. Returns whether anything was sent.
function module:announce(member, lane)
    local number = tostring(member.number)
    if lane == "dead" then
        self:speak(number .. " " .. L["dead"])
        return true
    end
    if plainTrue(UnitIsDeadOrGhost, member.unit) then
        return false
    end
    local profile, pitchPoints = self:profile()
    local pitch = through(member.unit, pitchPoints)
    local low, high = self:laneRange(member, lane)
    local lowRange, highRange = GroupHealth.copyRanges(low, high, profile)
    local lowVolume = through(member.unit, GroupHealth.bandPoints(lowRange[1], lowRange[2]))
    local highVolume = through(member.unit, GroupHealth.bandPoints(highRange[1], highRange[2]))
    -- What is silent is spoken at the fastest rate (logic.lua, ratePoints):
    -- it takes a third of the time and nobody hears it. The rate, like the
    -- volume, is decided by the curve inside the secret.
    local rate = self.settings.rate
    local lowRate = through(member.unit, GroupHealth.ratePoints(lowRange[1], lowRange[2], rate))
    local highRate = through(member.unit, GroupHealth.ratePoints(highRange[1], highRange[2], rate))
    if pitch == nil or lowVolume == nil or highVolume == nil or lowRate == nil or highRate == nil then
        self:unavailable()
        return false
    end
    -- Every announcement has the same two parts (logic.lua): the LOW copy
    -- (rising, the urgent part of the scale) and the HIGH copy last
    -- (falling, the healthy part). The volume gates pick the copy; the
    -- sentence shape never changes, so the voice's melody adds the same to
    -- every number of a copy.
    -- The snapshot's "<number> full" ends the same utterance, silent unless
    -- the member is at exactly full health (when both copies before it are
    -- silent, so it is heard after their length).
    local fullPart = ""
    if lane == "snapshot" and self.settings.announceFull then
        local full = through(member.unit, fullPoints)
        local fullRate = through(member.unit, GroupHealth.ratePoints(1, 2, rate))
        if full ~= nil and fullRate ~= nil then
            fullPart = GroupHealth.segment(full, profile.scale[#profile.scale], number .. " " .. L["full"], fullRate)
        end
    end
    local pad = GroupHealth.uniquePad(self:nextCount())
    local lowPart = GroupHealth.segment(lowVolume, pitch, number .. pad, lowRate)
    local highPart = GroupHealth.segment(highVolume, pitch, number, highRate)
    self:speak(lowPart .. highPart .. fullPart)
    return true
end

-- Health events: deaths, and the mark for Repeat Only After a Change -----------------------

function module:silenced()
    return self.settings.silentOutOfCombat and not InCombatLockdown()
end

function module:onHealth(unit)
    local member = self:memberFor(unit)
    if member == nil then
        return
    end
    -- That the event fired is plain (every addon gets it, the bar moves
    -- for everyone); what the health is stays secret.
    member.changed = true
    if plainTrue(UnitIsDeadOrGhost, member.unit) then
        if not member.dead then
            member.dead = true
            if self.settings.announceDeaths and not self:silenced() then
                self:announce(member, "dead")
            end
        end
        return
    end
    member.dead = false
end

-- The repeat ----------------------------------------------------------------------

-- How often the repeat looks for a due member: fine enough that the next
-- one follows the last closely, as each goes out only once the queue is
-- empty again.
local REPEAT_CHECK = 0.1

-- One member per turn, the most overdue, and only while nothing is queued
-- or playing: a silent announcement (a member above the threshold) takes
-- as long as a spoken one, so letting them pile up would hold back
-- everything else WowVision says. Dead and offline members take their
-- turn silently, so they neither speak nor hold the others back.
function module:checkRepeats()
    local now = GetTime()
    if self.nextRepeatCheck ~= nil and now < self.nextRepeatCheck then
        return
    end
    self.nextRepeatCheck = now + REPEAT_CHECK
    if self:silenced() or not WowVision.base.speech:idle() then
        return
    end
    local onlyAfterChange = self.settings.repeatOnlyAfterChange
    local member = GroupHealth.mostOverdue(self.members, now, function(m)
        if onlyAfterChange and not m.changed then
            return nil
        end
        return roleSetting(m.role, "repeatInterval")
    end)
    if member == nil then
        return
    end
    member.lastRepeat = now
    member.changed = false
    if not member.dead and not plainFalse(UnitIsConnected, member.unit) then
        self:announce(member, "repeat")
    end
end

-- Everyone once, in number order, ungated; the repeat starts afresh after it.
function module:snapshot()
    local list = {}
    for _, member in pairs(self.members) do
        tinsert(list, member)
    end
    if #list == 0 then
        WowVision:speak(L["Nobody to watch"])
        return
    end
    table.sort(list, function(a, b)
        return a.number < b.number
    end)
    local now = GetTime()
    for _, member in ipairs(list) do
        member.lastRepeat = now
        member.changed = false
        if plainTrue(UnitIsDeadOrGhost, member.unit) then
            self:announce(member, "dead")
        else
            self:announce(member, "snapshot")
        end
    end
end

-- Wiring ------------------------------------------------------------------------

module:registerEvent("event", "UNIT_HEALTH")
module:registerEvent("event", "GROUP_ROSTER_UPDATE")
module:registerEvent("event", "PLAYER_ROLES_ASSIGNED")
module:registerEvent("event", "PLAYER_REGEN_ENABLED")
module:registerEvent("event", "PLAYER_ENTERING_WORLD")

function module:onEvent(event, ...)
    if event == "UNIT_HEALTH" then
        self:onHealth(...)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.rosterDirty then
            self:rebuild()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self.unavailableSaid = false
        self:rebuild()
        -- The game lists its voices only in the world, so the voice name is
        -- knowable now: warn here if the chosen voice is the NVDA bridge.
        self:warnBridgeVoice()
    else
        self:rebuild()
    end
end

-- The NVDA bridge voice (SAPI2SR) cannot play the pitch scale: NVDA ignores
-- the pitch our markup carries, which a real SAPI voice honours (confirmed
-- on NVDA 2026.3 with both Eloquence and eSpeak). Warn once when the monitor
-- is enabled, enters the world, or has its voice set to the bridge, so the
-- player knows to pick a Windows voice for the pitch. Said once; switching
-- back to a bridge voice after a Windows one warns again.
function module:warnBridgeVoice()
    local name = voiceName(self.settings.voice or 0)
    local bridge = name ~= nil and name:lower():find("sapi2sr", 1, true) ~= nil
    if not bridge then
        self.bridgeWarned = false
        return
    end
    if self.bridgeWarned then
        return
    end
    self.bridgeWarned = true
    WowVision:speak(L["This screen reader voice does not play the health pitch. For the pitch, choose a Windows voice such as Microsoft Zira in the Voice setting."])
end

function module:onEnable()
    self:hasUpdate(function(self)
        self:checkRepeats()
    end)
    self:rebuild()
    self:warnBridgeVoice()
end

function module:onDisable()
    self.members = {}
    self.aliases = {}
end

-- Choosing the bridge voice while already enabled warns too.
voiceField.events.valueChange:subscribe(module, function(subscriber)
    subscriber:warnBridgeVoice()
end)

module:registerBinding({
    type = "Function",
    key = "groupHealth/snapshot",
    label = L["Speak Group Health"],
    -- A letter key: the game names keys by the character the keyboard
    -- layout produces, so only letters (and function keys) exist on every
    -- layout. "Ö" never fired, and "#" is a different key on English and
    -- French layouts. H for health.
    inputs = { "ALT-H" },
    -- With controller support: right trigger + right stick press.
    padInputs = { "CTRL-PADRSTICK" },
    func = function()
        module:snapshot()
    end,
})
