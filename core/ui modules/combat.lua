local module = WowVision.base.ui:createModule("combat")
local L = module.L
module:setLabel(L["Combat"])
local settings = module:hasSettings()

local combatStartedAlert = module:addAlert({
    key = "combatStarted",
    label = L["Combat Started Alert"],
})

combatStartedAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["combat started"]
    end,
})

local combatEndedAlert = module:addAlert({
    key = "combatEnded",
    label = L["Combat Ended Alert"],
})

combatEndedAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["combat ended"]
    end,
})

-- The number of enemies in the fight, said whenever it changes. The rules
-- are in enemyCount.lua; this part feeds them the game's answers.
local enemyCountAlert = module:addAlert({
    key = "enemyCount",
    label = L["Enemy Count Alert"],
})

local enemyCountSpeech = enemyCountAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        if message.texts == nil then
            return message.count ~= nil and tostring(message.count) or nil
        end
        return WowVision.enemyCount.controlWords(message, {
            names = module.settings.enemyCountControlMode == "names",
            noText = L["controlled"],
            join = WowVision.secrets.join,
            isSecret = WowVision.secrets.isSecret,
        })
    end,
})

-- Numbers only: crowd control texts are the game's own and have no file.
enemyCountAlert:addOutput({
    type = "Voice",
    key = "voice",
    label = L["Voice Alert"],
    getPath = function(self, message)
        if message.count == nil then
            return nil
        end
        return "Path", "numbers/" .. message.count .. ".mp3"
    end,
    enabled = false,
})

-- With Announce Crowd Control on: a control ended on an enemy still in the
-- fight. Plays just before the new count.
local controlEndedAlert = module:addAlert({
    key = "enemyControlEnded",
    label = L["Crowd Control Ended Alert"],
})

controlEndedAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    path = "Sound/WowVision/alerts/off1.mp3",
})

settings:addRef("combatStarted", combatStartedAlert.parameters)
settings:addRef("combatEnded", combatEndedAlert.parameters)
settings:addRef("enemyCount", enemyCountAlert.parameters)
settings:addRef("enemyControlEnded", controlEndedAlert.parameters)

settings:add({
    key = "enemyCountMode",
    type = "Choice",
    label = L["Count Enemies"],
    default = "group",
    choices = {
        { label = L["Attacking You or Your Group"], value = "group" },
        { label = L["Attacking You"], value = "player" },
    },
})

settings:add({
    key = "enemyCountEliteOnly",
    type = "Bool",
    label = L["Count Elite Enemies Only"],
    default = false,
})

-- Experimental: crowd controlled enemies leave the number and are said
-- apart, with the crowd control's name or with one word for all.
settings:add({
    key = "enemyCountControlMode",
    type = "Choice",
    label = L["Announce Crowd Control"],
    default = "off",
    choices = {
        { label = L["Off"], value = "off" },
        { label = L["With Spell Names"], value = "names" },
        { label = L["Without Names"], value = "word" },
    },
})

local function controlOn()
    return module.settings.enemyCountControlMode ~= "off"
end

local enemyCount = WowVision.enemyCount
local secrets = WowVision.secrets

local CONTROL_FILTER = "HARMFUL|CROWD_CONTROL"
local CONTROL_INDEX = Constants and Constants.LossOfControlConsts
    and Constants.LossOfControlConsts.LOSS_OF_CONTROL_ACTIVE_INDEX or 1
local lossOfControl = C_LossOfControl or {}
local unitAuras = C_UnitAuras or {}

-- A new number is said once it held this long: a plate that blinks out
-- and back is not spoken twice, and a pack that comes in one after another
-- is said as one number. 0.3 s is the length of the window Sku's TBC count
-- waits for a burst of new enemies (tFlushWindow in SkuCore/aqCombat.lua).
-- Unlike Sku's window, which flushes 0.3 s after the first new enemy, this
-- hold starts again at every change, so a pack that trickles in is said
-- 0.3 s after its last member.
local SETTLE = 0.3

local PLATES = {}
for i = 1, 40 do
    PLATES[i] = "nameplate" .. i
end

local spells = C_Spell or {}

local function readable(value)
    return value ~= nil and not secrets.isSecret(value)
end

-- Blizzard's rule for the Crowd Control list on an enemy NPC's plate: the
-- spell is crowd control by the game's list, or the aura is flagged to show
-- for everyone. nil when the answer is secret (Forever in combat).
local function shownAsControl(aura)
    local okShow, showAll = pcall(function()
        return aura.nameplateShowAll
    end)
    if okShow and readable(showAll) and showAll == true then
        return true
    end
    if spells.IsSpellCrowdControl == nil then
        return nil
    end
    local ok, isControl = pcall(function()
        return spells.IsSpellCrowdControl(aura.spellId)
    end)
    if not ok or not readable(isControl) then
        return nil
    end
    return isControl == true
end

local function auraList(unit, filter)
    if unitAuras.GetUnitAuras == nil then
        return nil
    end
    local ok, auras = pcall(unitAuras.GetUnitAuras, unit, filter)
    if not ok or type(auras) ~= "table" or secrets.isSecret(auras) then
        return nil
    end
    return auras
end

-- The crowd control auras on a plate by Blizzard's rule, the ones its Crowd
-- Control list shows. nil when the rule cannot be read (secret, or the
-- aura list refused).
local function ruleList(unit)
    local harmful = auraList(unit, "HARMFUL")
    if harmful == nil then
        return nil
    end
    local shown = {}
    for _, aura in ipairs(harmful) do
        local verdict = shownAsControl(aura)
        if verdict == nil then
            return nil
        elseif verdict then
            tinsert(shown, aura)
        end
    end
    return shown
end

local function firstName(auras)
    if auras == nil or auras[1] == nil then
        return nil
    end
    local ok, name = pcall(function()
        return auras[1].name
    end)
    return ok and name or nil
end

-- Where Blizzard's rule cannot be read, the game's CROWD_CONTROL filter
-- decides (looser: on TBC it takes a Frostbolt slow), first through the
-- shared tooltip read (core/crowdControl.lua), which Retail allows where
-- its restriction closes the aura list (measured on the target, not yet on
-- nameplate units), then through the filtered aura list (TBC, which lacks
-- the filter token the tooltip read checks for).
local crowdControl = WowVision.crowdControl

local plates = {}
local api = {
    plates = function()
        wipe(plates)
        for _, unit in ipairs(PLATES) do
            if UnitExists(unit) then
                tinsert(plates, unit)
            end
        end
        return plates
    end,
    group = function()
        return WowVision.utils.groupUnits(IsInRaid(), IsInGroup())
    end,
    exists = UnitExists,
    reaction = function(unit)
        return UnitReaction("player", unit)
    end,
    isDead = UnitIsDead,
    inCombat = UnitAffectingCombat,
    classification = UnitClassification,
    threat = UnitThreatSituation,
    -- Guarded like utils.groupFighting's reads: a missing or refused
    -- answer is nil, which the group rule counts as no.
    tapDenied = function(unit)
        if UnitIsTapDenied == nil then
            return nil
        end
        local ok, tapped = pcall(UnitIsTapDenied, unit)
        if not ok then
            return nil
        end
        return tapped
    end,
    isSecret = secrets.isSecret,
    -- The crowd control reads are guarded: each game version has a
    -- different part of them, and a refused read means "unknown".
    controlCount = function(unit)
        if lossOfControl.GetActiveLossOfControlDataCountByUnit == nil then
            return nil
        end
        local ok, count = pcall(lossOfControl.GetActiveLossOfControlDataCountByUnit, unit)
        return ok and count or nil
    end,
    controlAuras = function(unit)
        local auras = ruleList(unit)
        if auras ~= nil then
            return #auras
        end
        local controlled = crowdControl.controlled(unit)
        if controlled ~= nil then
            return controlled and 1 or 0
        end
        auras = auraList(unit, CONTROL_FILTER)
        return auras and #auras or nil
    end,
    -- The loss-of-control text where the game keeps one (players only: it
    -- has none for NPCs), else the name of the crowd control aura, the one
    -- text an enemy NPC's plate draws, read the same way as above.
    controlText = function(unit)
        if lossOfControl.GetActiveLossOfControlDataByUnit ~= nil then
            local ok, text = pcall(function()
                local data = lossOfControl.GetActiveLossOfControlDataByUnit(unit, CONTROL_INDEX)
                return data and data.displayText
            end)
            if ok and text ~= nil then
                return text
            end
        end
        local auras = ruleList(unit)
        if auras ~= nil then
            return firstName(auras)
        end
        if crowdControl.controlled(unit) ~= nil then
            return crowdControl.name(unit)
        end
        return firstName(auraList(unit, CONTROL_FILTER))
    end,
}

local settler = enemyCount.Settler:new(SETTLE)
local controlSettler = enemyCount.Settler:new(SETTLE, enemyCount.CONTROL_IDLE)
local tracker = enemyCount.ControlTracker:new()
local recountQueued, settleQueued = false, false

-- Fires the counts and says a lost one again (enemyCount.Announcer).
local announcer = enemyCount.Announcer:new({
    fire = function(message)
        enemyCountAlert:fire(message)
    end,
    -- The alert's own checks (Alert:fire), for its speech output alone.
    fireSpeech = function(message)
        if enemyCountAlert.enabled and enemyCountSpeech.enabled and enemyCountSpeech:respondsTo(message.action) then
            enemyCountSpeech:fire(message)
        end
    end,
    queue = function()
        local speech = WowVision.base.speech
        return speech and speech.queue
    end,
    now = GetTime,
    enabled = function()
        return enemyCountAlert.enabled
    end,
    mode = function()
        return module.settings.enemyCountControlMode
    end,
})

local function sayCount(message)
    announcer:say(message)
end

-- Whether a count is on or about to be said, so the ticker keeps checking.
local function counting()
    if controlOn() then
        return controlSettler.said ~= enemyCount.CONTROL_IDLE or controlSettler.pending ~= nil
    end
    return settler.said ~= 0 or settler.pending ~= nil
end

-- One recount with Announce Crowd Control on; returns the settler in use.
local function recountControl(skip)
    local settings = module.settings
    local free, controlled = enemyCount.scan(api, settings.enemyCountMode, settings.enemyCountEliteOnly, skip)
    if controlSettler:update(enemyCount.controlKey(free, controlled), GetTime()) ~= nil then
        local message = tracker:change(free, controlled, api.controlText)
        if message == nil then
            -- A quiet change (a controlled enemy gone): the free count is
            -- the same, a lost number still stands.
            announcer:quietChange()
        else
            if message.ended then
                controlEndedAlert:fire({})
            end
            if message.count ~= nil or message.texts ~= nil then
                sayCount(message)
            end
        end
    end
    return controlSettler
end

local function recount(skip)
    if not enemyCountAlert.enabled then
        return
    end
    local active
    if controlOn() then
        active = recountControl(skip)
    else
        local count = enemyCount.count(api, module.settings.enemyCountMode, module.settings.enemyCountEliteOnly, skip)
        local say = settler:update(count, GetTime())
        if say ~= nil then
            sayCount({ count = say })
        end
        active = settler
    end
    if active.pending ~= nil and not settleQueued then
        settleQueued = true
        -- A little past the hold, so frame timing cannot land just short of it.
        C_Timer.After(SETTLE + 0.05, function()
            settleQueued = false
            recount()
        end)
    end
end

-- Threat and flag events come in bursts; one recount serves a burst.
local function queueRecount()
    if recountQueued then
        return
    end
    recountQueued = true
    C_Timer.After(0.1, function()
        recountQueued = false
        recount()
    end)
end

-- Enemy plates are off by default, and without them nothing is counted.
local function enemyPlatesShown()
    local getBool = C_CVar ~= nil and C_CVar.GetCVarBool or GetCVarBool
    local ok, shown = pcall(getBool, "nameplateShowEnemies")
    return not ok or shown ~= false
end

module:registerEvent("event", "PLAYER_REGEN_DISABLED")
module:registerEvent("event", "PLAYER_REGEN_ENABLED")
module:registerEvent("event", "NAME_PLATE_UNIT_ADDED")
module:registerEvent("event", "NAME_PLATE_UNIT_REMOVED")
module:registerEvent("event", "UNIT_THREAT_LIST_UPDATE")
module:registerEvent("event", "UNIT_FLAGS")
-- Crowd control comes and goes as an aura on the enemy's plate.
module:registerEvent("event", "UNIT_AURA")

function module:onEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        combatStartedAlert:fire({})
        if enemyCountAlert.enabled and not self.plateHintGiven and not enemyPlatesShown() then
            self.plateHintGiven = true
            WowVision:notify(L["Turn on enemy nameplates to count enemies"])
        end
        queueRecount()
    elseif event == "PLAYER_REGEN_ENABLED" then
        combatEndedAlert:fire({})
        queueRecount()
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        -- The plate still exists during its own removal.
        recount(unit)
        -- Its token may come back on another enemy.
        tracker:forget(unit)
    elseif event == "UNIT_AURA" then
        local unit = ...
        if controlOn() and type(unit) == "string" and unit:find("^nameplate") then
            queueRecount()
        end
    else
        queueRecount()
    end
end

function module:onEnable()
    -- Events miss an enemy that dies or leashes quietly; a recount a second
    -- while a fight is on catches it.
    local nextCheck = 0
    self:hasUpdate(function()
        local now = GetTime()
        if now < nextCheck then
            return
        end
        nextCheck = now + 1
        local function check()
            if counting() or UnitAffectingCombat("player") then
                recount()
            end
        end
        if controlOn() then
            announcer:tick(check, controlSettler, false)
        else
            announcer:tick(check, settler, true)
        end
    end)
end
