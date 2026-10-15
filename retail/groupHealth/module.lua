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
-- matches.
--
-- What speaks, below the role's "Speak Below" (a member at exactly full
-- health as "<number> full"):
-- - With "Only When Health Changed Enough" (the default), Sku's rule: a
--   health event speaks the member at once, heard only when their health
--   moved the role's minimum change and the role's minimum pitch steps
--   since their last announcement (checks.lua, readback.lua).
-- - Without it, Sku's rule with no minimum: every health event (as Sku
--   with a minimum change of 0).
-- - Both: "<number> dead" once, an optional repeat of every member below
--   the role's repeat threshold at the role's interval, and the snapshot
--   key (everyone once).
-- All but the rule's numbers go through one queue that starts an utterance
-- every `spacing` seconds, one entry per member and lane (an entry already
-- waiting keeps its place and reads the health when it plays); the rule's
-- numbers go out at once.
--
-- Speech uses a game voice of its own, straight to the engine beside the
-- speech queue (speech:speakAside): pitch needs a real SAPI voice, which an
-- NVDA bridge voice is not.

local ROLE_KEYS = { TANK = "tank", HEALER = "healer", DAMAGER = "damager", NONE = "none" }

-- Sku's values per role, except one pitch step for tanks (Sku: none):
-- their minimum change (5 percent) is smaller than a pitch step (6.7), and
-- without it one tank announcement in seven sounded at the pitch of the
-- one before (simulation, 2026-10-13).
local ROLE_DEFAULTS = {
    TANK = {
        startThreshold = 90,
        urgentThreshold = 50,
        repeatThreshold = 80,
        repeatInterval = 0,
        minChange = 5,
        minPitchSteps = 1,
    },
    HEALER = {
        startThreshold = 80,
        urgentThreshold = 40,
        repeatThreshold = 70,
        repeatInterval = 0,
        minChange = 10,
        minPitchSteps = 1,
    },
    DAMAGER = {
        startThreshold = 70,
        urgentThreshold = 35,
        repeatThreshold = 60,
        repeatInterval = 0,
        minChange = 20,
        minPitchSteps = 2,
    },
    NONE = {
        startThreshold = 70,
        urgentThreshold = 35,
        repeatThreshold = 60,
        repeatInterval = 0,
        minChange = 30,
        minPitchSteps = 3,
    },
}

-- Settings ----------------------------------------------------------------------

-- Saved by the voice's name: the pitch scales are tuned per voice, and
-- installing a voice moves the game's voice numbers.
settings:add({
    key = "voice",
    type = "TtsVoice",
    label = L["Voice"],
    default = 0,
})

settings:add({
    key = "rate",
    type = "Number",
    label = L["Speech Rate"],
    -- Short numbers: five hurt members fit in little time.
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
    key = "spacing",
    type = "Number",
    label = L["Time Between Numbers (seconds)"],
    -- Sku's 0.2. Paces the queue (changes without the rule, deaths, the
    -- repeat, the snapshot); the rule's numbers go out at once.
    default = 0.2,
    min = 0.05,
    max = 2,
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
-- Sku's rule, the way a healer reacts to a health bar: not on every small
-- change. The key predates the rule (it was a ten percent step) and stays,
-- so the saved choice carries over.
local ruleSetting = settings:add({
    key = "onlyOnSteps",
    type = "Bool",
    label = L["Only When Health Changed Enough"],
    default = true,
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
                key = "startThreshold",
                type = "Number",
                label = L["Speak Below (percent)"],
                default = defaults.startThreshold,
                min = 0,
                max = 100,
            },
            {
                key = "minChange",
                type = "Number",
                label = L["Minimum Change (percent)"],
                default = defaults.minChange,
                min = 2,
                max = 50,
            },
            {
                key = "minPitchSteps",
                type = "Number",
                label = L["Minimum Pitch Steps"],
                default = defaults.minPitchSteps,
                min = 0,
                max = 7,
            },
            {
                key = "urgentThreshold",
                type = "Number",
                label = L["Urgent Below (percent)"],
                default = defaults.urgentThreshold,
                min = 0,
                max = 100,
            },
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
function module:roleSetting(role, key)
    local values = self.settings[ROLE_KEYS[role]]
    local value = values ~= nil and values[key] or nil
    if value == nil then
        value = ROLE_DEFAULTS[role][key]
    end
    return value
end

local function roleSetting(role, key)
    return module:roleSetting(role, key)
end

-- A role's minimum change in whole percent, never below the setting's floor.
local function minChange(role)
    return math.max(2, math.floor(roleSetting(role, "minChange") + 0.5))
end

local function raidGroupWatched(group)
    local groups = module.settings.raidGroups
    return groups == nil or groups["group" .. group] ~= false
end

-- Curves ------------------------------------------------------------------------

local isSecret = WowVision.secrets.isSecret

-- One curve object per point list, reused. Each readback plan brings its
-- digit curves and gates (readback.lua caps the plans); past CURVES_MAX the
-- cache starts afresh and the old curves are left to the garbage collector.
local CURVES_MAX = 2048
local curves, curveCount = {}, 0

local function curveFor(points)
    local key = GroupHealth.pointsKey(points)
    local curve = curves[key]
    if curve == nil then
        curve = C_CurveUtil.CreateCurve()
        curve:SetType(Enum.LuaCurveType.Step)
        for _, point in ipairs(points) do
            curve:AddPoint(point[1], point[2])
        end
        if curveCount >= CURVES_MAX then
            curves, curveCount = {}, 0
        end
        curves[key] = curve
        curveCount = curveCount + 1
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
        cached = { profile = profile, pitch = GroupHealth.pitchPoints(profile), levels = GroupHealth.pitchLevels(profile) }
        if name ~= nil then
            profileCache[voice] = cached
        end
    end
    return cached.profile, cached.pitch, cached.levels
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
-- their reference, repeat timing and death. Unit tokens move when someone leaves,
-- so the person is found by GUID; without one, the member starts afresh
-- (one silent check finds their reference).
local function newMember(unit, number, role, old)
    local member = {
        unit = unit,
        guid = plainGuid(unit),
        number = number,
        role = role,
        dead = false,
    }
    if old ~= nil then
        member.reference = old.reference
        member.lastRepeat = old.lastRepeat
        member.dead = old.dead
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
    -- Whoever is new gets one silent check: their reference.
    local checks = self:ruleChecks()
    if checks ~= nil then
        checks:readNew()
    end
end

function module:memberFor(unit)
    return self.members[unit] or self.aliases[unit]
end

-- The queue ---------------------------------------------------------------------

module.queue = {}
module.queued = {}

local function entryKey(member, lane)
    return member.unit .. ":" .. lane
end

function module:clearQueue()
    self.queue = {}
    self.queued = {}
end

-- `force` entries play even when a roster update dropped the member: the
-- snapshot finishes what it started.
function module:enqueue(member, lane, force)
    local key = entryKey(member, lane)
    if self.queued[key] then
        return
    end
    self.queued[key] = true
    tinsert(self.queue, { member = member, lane = lane, key = key, force = force, queuedAt = GetTime() })
    self:pump()
end

function module:pump()
    if self.pumping then
        return
    end
    local entry = tremove(self.queue, 1)
    if entry == nil then
        return
    end
    self.queued[entry.key] = nil
    -- A member dropped by a roster update is skipped.
    if entry.force or self:memberFor(entry.member.unit) == entry.member then
        self:trace(entry.member, "play", entry)
        self:announce(entry.member, entry.lane)
    end
    self.pumping = true
    C_Timer.After(self.settings.spacing or 0.2, function()
        self.pumping = false
        self:pump()
    end)
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
    if data.utterances == nil then
        -- Earlier builds counted per character: carry this one's count over.
        data.utterances = self.data ~= nil and self.data.utterances or 0
    end
    data.utterances = data.utterances + 1
    return data.utterances
end

-- `tag` ({ member, lane }) comes back when a stop of all speech cuts it.
-- `direct`: straight to the engine, in the caller's slot (a number carried
-- by a check).
function module:speak(text, tag, direct)
    local speech = WowVision.base.speech
    local voice, rate, volume = self.settings.voice or 0, self.settings.rate, self.settings.volume
    local checks = self:ruleChecks()
    if direct or checks == nil then
        speech:speakAside(voice, text, rate, volume)
        return
    end
    -- Beside the checks our own speech takes a slot of their line, so its
    -- start is never taken for a sample's (readback.lua).
    checks.readback:speakOwn(function()
        speech:speakAside(voice, text, rate, volume)
    end, tag)
end

function module:unavailable()
    if not self.unavailableSaid then
        self.unavailableSaid = true
        WowVision:speak(L["Group health monitor unavailable here"])
    end
end

-- The health range [low, high) a lane speaks in; a high above 1 includes
-- full health. "change" is a health change (with the rule, a number carried
-- by a check).
function module:laneRange(member, lane)
    local role = member.role
    if lane == "change" then
        return 0, GroupHealth.fraction(roleSetting(role, "startThreshold"))
    elseif lane == "repeat" then
        return 0, GroupHealth.fraction(roleSetting(role, "repeatThreshold"))
    elseif lane == "snapshot" and self.settings.announceFull then
        -- At full health the snapshot says "<number> full" instead.
        return 0, 1
    end
    return 0, 2
end

-- `quiet` (optional) keeps the number silent inside that band, Sku's rule
-- (gatePoints); `direct` speaks straight to the engine (a number carried by
-- a check). Returns how many utterances went out.
function module:announce(member, lane, quiet, direct)
    local number = tostring(member.number)
    local tag = { member = member, lane = lane }
    if lane == "dead" then
        self:speak(WowVision.ttsCacheBust.bust(number .. " " .. L["dead"]), tag, direct)
        return 1
    end
    -- A member who died while this waited gets no number.
    if plainTrue(UnitIsDeadOrGhost, member.unit) then
        return 0
    end
    local profile, pitchPoints = self:profile()
    local pitch = through(member.unit, pitchPoints)
    local low, high = self:laneRange(member, lane)
    local lowRange, highRange = GroupHealth.copyRanges(low, high, profile)
    local lowPoints = GroupHealth.gatePoints(lowRange[1], lowRange[2], quiet)
    local highPoints = GroupHealth.gatePoints(highRange[1], highRange[2], quiet)
    local fullGate = quiet ~= nil and GroupHealth.gatePoints(1, 2, quiet) or fullPoints
    local wantFull = (lane == "change" or lane == "snapshot") and self.settings.announceFull
    -- A carried number whose gates keep every health silent is not sent:
    -- fewer utterances at once in the engine.
    local sendNumber = quiet == nil or not (GroupHealth.isSilent(lowPoints) and GroupHealth.isSilent(highPoints))
    if quiet ~= nil and wantFull and GroupHealth.isSilent(fullGate) then
        wantFull = false
    end
    local lowVolume = through(member.unit, lowPoints)
    local highVolume = through(member.unit, highPoints)
    if pitch == nil or lowVolume == nil or highVolume == nil then
        self:unavailable()
        return 0
    end
    -- Every announcement has the same two parts (logic.lua): the LOW copy
    -- (rising, the urgent part of the scale) and the HIGH copy last
    -- (falling, the healthy part). The volume gates pick the copy; the
    -- sentence shape never changes, so the voice's melody adds the same to
    -- every number of a copy.
    -- "<number> full" ends the same utterance, silent unless the member
    -- is at exactly full health (when both copies before it are silent, so
    -- it is heard after their length): one utterance instead of two, as
    -- the engine prepares one after another.
    local fullPart = ""
    if wantFull then
        local full = through(member.unit, fullGate)
        if full ~= nil then
            local bottom = profile.scale[#profile.scale]
            fullPart = GroupHealth.segment(full, bottom, number .. " " .. L["full"])
            sendNumber = true
        end
    end
    if not sendNumber then
        return 0
    end
    local pad = GroupHealth.uniquePad(self:nextCount())
    self:speak(GroupHealth.segment(lowVolume, pitch, number .. pad)
        .. GroupHealth.segment(highVolume, pitch, number) .. fullPart, tag, direct)
    return 1
end

-- Sku's rule (checks.lua) ----------------------------------------------------------

-- A stop of all speech cut a death of ours: it is said again, worth more
-- than the silence asked for. The snapshot and the repeat are not: a stop
-- during them means stop.
local RESPEAK = { dead = true }

-- The checks while the setting is on, made on first use; nil while off.
function module:ruleChecks()
    if not self.settings.onlyOnSteps then
        return nil
    end
    if self.checks == nil then
        self.checks = GroupHealth.Checks:new({
            members = function()
                return self.members
            end,
            memberFor = function(unit)
                return self:memberFor(unit)
            end,
            threshold = function(member)
                return minChange(member.role)
            end,
            urgent = function(member)
                return roleSetting(member.role, "urgentThreshold")
            end,
            speakBelow = function(member)
                return GroupHealth.fraction(roleSetting(member.role, "startThreshold"))
            end,
            pitchQuiet = function(member)
                local _, _, levels = self:profile()
                return GroupHealth.pitchQuiet(levels, member.reference, roleSetting(member.role, "minPitchSteps"))
            end,
            carry = function(member, quiet)
                return self:announce(member, "change", quiet, true)
            end,
            now = debugprofilestop,
            frameMs = function()
                local fps = GetFramerate()
                return fps ~= nil and fps > 0 and 1000 / fps or nil
            end,
            startOwner = function(id)
                return WowVision.base.speech:startOwner(id)
            end,
            after = C_Timer.After,
            speak = function(text)
                -- Silent, at the rate the fixed values were measured at.
                WowVision.base.speech:speakAside(self.settings.voice or 0, text, GroupHealth.readbackConstants.RATE, 0)
            end,
            through = through,
            nextCount = function()
                return self:nextCount()
            end,
            onOwnCut = function(tag)
                local member = tag ~= nil and tag.member or nil
                if member ~= nil and RESPEAK[tag.lane] and self:memberFor(member.unit) == member and member.dead then
                    self:trace(member, "respeak")
                    self:enqueue(member, tag.lane)
                end
            end,
            onError = function(err)
                geterrorhandler()(err)
            end,
            onFailing = function()
                print("WowVision: " .. L["Group health readings failing"])
                WowVision:speak(L["Group health readings failing"])
            end,
            trace = function(member, what, detail, extra)
                self:trace(member, what, detail, extra)
            end,
        })
    end
    return self.checks
end

-- Switching the rule off and on starts it afresh: nothing of the old
-- checks may answer for members read since.
ruleSetting.events.valueChange:subscribe(module, function()
    module.checks = nil
    if module.enabled then
        module:rebuild()
    end
end)

-- WowVision's own stops (keys, Ctrl, interrupting alerts) leave out the
-- stop while only our silent samples play.
WowVision.base.speech:addSilentJudge(GroupHealth.isOwnSilent)

-- Anyone stopping all speech cuts the samples and our speech with them:
-- the readback drops the cut samples, reads those members again and hands
-- back the cut speech.
hooksecurefunc(C_VoiceChat, "StopSpeakingText", function()
    if module.checks ~= nil then
        module.checks.readback:onStop()
    end
end)

-- Health events -------------------------------------------------------------------

function module:silenced()
    return self.settings.silentOutOfCombat and not InCombatLockdown()
end

function module:onHealth(unit)
    local member = self:memberFor(unit)
    if member == nil then
        return
    end
    self:trace(member, "event", unit)
    unit = member.unit
    -- Dead or offline members get no numbers; a death is said once.
    if plainTrue(UnitIsDeadOrGhost, unit) then
        if not member.dead then
            member.dead = true
            -- Dead is a reference of 0: the resurrection is a change,
            -- heard whatever health it brings.
            member.reference = 0
            if self.settings.announceDeaths and not self:silenced() then
                self:enqueue(member, "dead")
            end
        end
        return
    end
    member.dead = false
    if plainFalse(UnitIsConnected, unit) or self:silenced() then
        return
    end
    local checks = self:ruleChecks()
    if checks ~= nil then
        checks:onEvent(unit)
    else
        self:enqueue(member, "change")
    end
end

-- The repeat: each role at its own interval, every member below the role's
-- repeat threshold (the gate decides).
local REPEAT_CHECK = 0.25

function module:checkRepeats()
    local now = GetTime()
    if self.nextRepeatCheck ~= nil and now < self.nextRepeatCheck then
        return
    end
    self.nextRepeatCheck = now + REPEAT_CHECK
    if self:silenced() then
        return
    end
    for _, member in pairs(self.members) do
        local interval = roleSetting(member.role, "repeatInterval")
        if interval ~= nil and interval > 0 and not member.dead then
            if member.lastRepeat == nil or now - member.lastRepeat >= interval then
                member.lastRepeat = now
                self:enqueue(member, "repeat")
            end
        end
    end
end

-- Everyone once, in number order, ungated.
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
    self:clearQueue()
    for _, member in ipairs(list) do
        if plainTrue(UnitIsDeadOrGhost, member.unit) then
            self:enqueue(member, "dead", true)
        else
            self:enqueue(member, "snapshot", true)
        end
    end
end

-- Diagnostics (log.lua replaces this while its log is on).
function module:trace(member, what, detail, extra) end

-- Wiring ------------------------------------------------------------------------

module:registerEvent("event", "UNIT_HEALTH")
module:registerEvent("event", "GROUP_ROSTER_UPDATE")
module:registerEvent("event", "PLAYER_ROLES_ASSIGNED")
module:registerEvent("event", "PLAYER_REGEN_ENABLED")
module:registerEvent("event", "PLAYER_ENTERING_WORLD")
-- The readback times its silent samples by these.
module:registerEvent("event", "VOICE_CHAT_TTS_PLAYBACK_STARTED")
module:registerEvent("event", "VOICE_CHAT_TTS_PLAYBACK_FINISHED")
module:registerEvent("event", "VOICE_CHAT_TTS_PLAYBACK_FAILED")

function module:onEvent(event, ...)
    if event == "VOICE_CHAT_TTS_PLAYBACK_STARTED" then
        if self.checks ~= nil then
            self.checks.readback:onStarted(...)
        end
    elseif event == "VOICE_CHAT_TTS_PLAYBACK_FINISHED" then
        if self.checks ~= nil then
            self.checks.readback:onFinished(..., false)
        end
    elseif event == "VOICE_CHAT_TTS_PLAYBACK_FAILED" then
        if self.checks ~= nil then
            self.checks.readback:onFinished(..., true)
        end
    elseif event == "UNIT_HEALTH" then
        self:onHealth(...)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.rosterDirty then
            self:rebuild()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self.unavailableSaid = false
        self:rebuild()
    else
        self:rebuild()
    end
end

function module:onEnable()
    self:hasUpdate(function(self)
        self:checkRepeats()
    end)
    self:rebuild()
end

function module:onDisable()
    self:clearQueue()
    self.members = {}
    self.aliases = {}
    self.checks = nil
end

module:registerBinding({
    type = "Function",
    key = "groupHealth/snapshot",
    label = L["Speak Group Health"],
    -- A letter key: the game names keys by the character the keyboard
    -- layout produces, so only letters (and function keys) exist on every
    -- layout. "Ö" never fired, and "#" is a different key on English and
    -- French layouts. H for health.
    inputs = { "ALT-H" },
    func = function()
        module:snapshot()
    end,
})
