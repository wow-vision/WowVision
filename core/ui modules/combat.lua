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

enemyCountAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return tostring(message.count)
    end,
})

enemyCountAlert:addOutput({
    type = "Voice",
    key = "voice",
    label = L["Voice Alert"],
    getPath = function(self, message)
        return "Path", "numbers/" .. message.count .. ".mp3"
    end,
    enabled = false,
})

settings:addRef("combatStarted", combatStartedAlert.parameters)
settings:addRef("combatEnded", combatEndedAlert.parameters)
settings:addRef("enemyCount", enemyCountAlert.parameters)

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

local enemyCount = WowVision.enemyCount
local secrets = WowVision.secrets

-- A new number is said once it held this long: a plate that blinks out
-- and back is not spoken twice.
local SETTLE = 0.5

local PLATES = {}
for i = 1, 40 do
    PLATES[i] = "nameplate" .. i
end

local SOLO = { "player", "pet" }
local PARTY = { "player", "pet" }
for i = 1, 4 do
    tinsert(PARTY, "party" .. i)
    tinsert(PARTY, "partypet" .. i)
end
local RAID = { "player", "pet" }
for i = 1, 40 do
    tinsert(RAID, "raid" .. i)
    tinsert(RAID, "raidpet" .. i)
end

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
        if IsInRaid() then
            return RAID
        elseif IsInGroup() then
            return PARTY
        end
        return SOLO
    end,
    exists = UnitExists,
    reaction = function(unit)
        return UnitReaction("player", unit)
    end,
    isDead = UnitIsDead,
    inCombat = UnitAffectingCombat,
    classification = UnitClassification,
    threat = UnitThreatSituation,
    isSecret = secrets.isSecret,
}

local settler = enemyCount.Settler:new(SETTLE)
local recountQueued, settleQueued = false, false

local function recount(skip)
    if not enemyCountAlert.enabled then
        return
    end
    local count = enemyCount.count(api, module.settings.enemyCountMode, module.settings.enemyCountEliteOnly, skip)
    local say = settler:update(count, GetTime())
    if say ~= nil then
        enemyCountAlert:fire({ count = say })
    elseif settler.pending ~= nil and not settleQueued then
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

function module:onEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        combatStartedAlert:fire({})
        if enemyCountAlert.enabled and not self.plateHintGiven and not enemyPlatesShown() then
            self.plateHintGiven = true
            WowVision:speak(L["Turn on enemy nameplates to count enemies"])
        end
        queueRecount()
    elseif event == "PLAYER_REGEN_ENABLED" then
        combatEndedAlert:fire({})
        queueRecount()
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        -- The plate still exists during its own removal.
        recount(...)
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
        if settler.said ~= 0 or settler.pending ~= nil or UnitAffectingCombat("player") then
            recount()
        end
    end)
end
