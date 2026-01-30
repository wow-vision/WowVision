local module = WowVision.base:createModule("targeting")
local L = module.L
module:setLabel(L["Targeting"])
local gen = module:hasUI()
local settings = module:hasSettings()

-- Register event for caching target GUID (avoids UnitGUID call every frame)
module:registerEvent("event", "PLAYER_TARGET_CHANGED")

module.tooltips = {
    hardTarget = WowVision.Tooltip:new("hardTarget"),
}

local markerNames = {
    L["Star"],
    L["Circle"],
    L["Diamond"],
    L["Triangle"],
    L["Moon"],
    L["Square"],
    L["X"],
    L["Skull"],
}

local hardTargetChange = module:addAlert({
    key = "hardTargetChange",
    label = L["Target Change"],
})

local hardTargetSpeak = hardTargetChange:addOutput({
    key = "tts",
    type = "TTS",
    label = L["TTS Alert"],
    interrupt = true,
    buildMessage = function(self, message)
        local targetString = ""
        if self.db.announceRaidMarker then
            local index = GetRaidTargetIndex("target")
            if index and index >= 1 and index <= 8 then
                targetString = targetString .. markerNames[index] .. " "
            end
        end
        targetString = targetString .. module.tooltips.hardTarget:getText()
        return targetString
    end,
})

hardTargetSpeak:addParameter({
    key = "announceRaidMarker",
    type = "Bool",
    label = L["Announce Raid Target Marker on Hard Target"],
    default = true,
})

local function inCombatWith(unit)
    if IsInRaid() then
        for i = 1, 40 do
            local unitId = "raid" .. i
            if UnitExists(unitId) and UnitThreatSituation(unitId, unit) then
                return true
            end
            local petId = unitId .. "pet"
            if UnitExists(petId) and UnitThreatSituation(petId, unit) then
                return true
            end
        end
    elseif IsInGroup() then
        for i = 1, 5 do
            local unitId = "party" .. i
            if UnitExists(unitId) and UnitThreatSituation(unitId, unit) then
                return true
            end
            local petId = unitId .. "pet"
            if UnitExists(petId) and UnitThreatSituation(petId, unit) then
                return true
            end
        end
    else
        if UnitThreatSituation("player", unit) or UnitThreatSituation("playerpet", unit) then
            return true
        end
    end
    return false
end

hardTargetChange:addOutput({
    type = "Sound",
    key = "combatSound",
    label = L["Target in Combat Sound"],
    shouldFire = function(self, message)
        --local threat = UnitThreatSituation("player", "target")
        --if threat then
        --return threat >= 0
        --else
        --return nil
        --end
        return inCombatWith("target")
    end,
    getPath = function(self, message)
        return "Sound/WowVision/alerts/notification21.mp3"
    end,
})

local hardTargetHealth = module:addAlert({
    key = "hardTargetHealth",
    label = L["Health Monitor"],
})

hardTargetHealth:addOutput({
    key = "tts",
    type = "TTS",
    label = L["TTS Alert"],
    shouldFire = function(self, message)
        if message.healthInterval >= 100 or message.healthInterval <= 0 then
            return false
        end
        return true
    end,
    buildMessage = function(self, message)
        return message.healthInterval .. "%"
    end,
})

hardTargetHealth:addOutput({
    key = "voice",
    type = "Voice",
    label = L["Voice Alert"],
    shouldFire = function(self, message)
        if message.healthInterval >= 100 or message.healthInterval <= 0 then
            return false
        end
        return true
    end,
    getPath = function(self, message)
        return "Path", "numbers/" .. message.healthInterval .. ".mp3"
    end,
    enabled = false,
})

local hardTarget = settings:add({
    type = "Category",
    key = "hardTarget",
    label = L["Hard Target"],
})

hardTarget:addRef("targetChange", hardTargetChange.parameters)
hardTarget:addRef("healthMonitor", hardTargetHealth.parameters)

local softTargets = {}

local function addSoftTarget(info)
    local alert = module:addAlert({
        key = info.key,
        label = info.label,
        enabled = false,
    })
    info.alert = alert
    local enabled = alert.parameters:get("enabled")
    if not enabled then
        error("Could not retrieve enabled parameter on " .. info.key .. " alert.")
    end
    enabled.events.valueChange:subscribe(nil, function(event, setting, value)
        if value == true then
            SetCVar(info.cvar, 3)
        else
            SetCVar(info.cvar, 0)
            info.guid = nil
        end
    end)
    settings:addRef(info.key, alert.parameters)
    module:registerBinding({
        inputs = { info.binding },
        type = "Function",
        key = "targeting/" .. info.key,
        label = info.label,
        interruptSpeech = true,
        func = function()
            local value = enabled:toggle()
            if value then
                WowVision:speak(info.label .. " " .. L["Enabled"])
            else
                WowVision:speak(info.label .. " " .. L["Disabled"])
            end
        end,
        conflictingAddons = { "Sku" },
    })
    module:registerEvent("event", info.event)
    local tooltip = WowVision.Tooltip:new(info.key)
    module.tooltips[info.key] = tooltip
    info.tooltip = tooltip
    tinsert(softTargets, info)

    alert:addOutput({
        key = "tts",
        type = "TTS",
        label = L["TTS Alert"],
        interrupt = true,
        buildMessage = function(self, message)
            local text = info.tooltip:getText()
            if text and #text > 1 then
                return text
            end
            return message.name
        end,
    })

    alert:addOutput({
        key = "sound",
        type = "Sound",
        label = L["Sound Alert"],
        getPath = function(self, message)
            return info.sound
        end,
    })
end

addSoftTarget({
    key = "softEnemy",
    label = L["Soft Target Enemy"],
    cvar = "SoftTargetEnemy",
    unit = "softenemy",
    event = "PLAYER_SOFT_ENEMY_CHANGED",
    sound = "Sound/WowVision/alerts/notification26.mp3",
    binding = "SHIFT-I",
    minRange = 1,
    maxRange = 60,
})

addSoftTarget({
    key = "softFriend",
    label = L["Soft Target Friend"],
    cvar = "SoftTargetFriend",
    unit = "softfriend",
    event = "PLAYER_SOFT_FRIEND_CHANGED",
    sound = "Sound/WowVision/alerts/notification27.mp3",
    binding = "SHIFT-P",
    minRange = 1,
    maxRange = 60,
})

addSoftTarget({
    key = "softInteract",
    label = L["Soft Target Interact"],
    cvar = "SoftTargetInteract",
    unit = "softinteract",
    event = "PLAYER_SOFT_INTERACT_CHANGED",
    sound = "Sound/WowVision/alerts/notification25.mp3",
    binding = "SHIFT-O",
    minRange = 1,
    maxRange = 15,
})

function module:onEvent(event, a, b)
    -- Cache hard target GUID on event (avoids UnitGUID call every frame)
    if event == "PLAYER_TARGET_CHANGED" then
        self._cachedTargetGuid = UnitGUID("target")
        return
    end

    for _, v in ipairs(softTargets) do
        if event == v.event then
            local newGuid
            if (a or b) and (a ~= b) then
                newGuid = b
            else
                newGuid = UnitGUID(v.unit)
            end
            module:updateSoftTarget(v, newGuid)
        end
    end
end

function module:updateHardTarget()
    -- Use cached GUID from PLAYER_TARGET_CHANGED event (avoids API call every frame)
    local target = self._cachedTargetGuid
    if target == nil then
        self.hardTarget = nil
        return
    end
    if target ~= self.hardTarget then
        self.hardTarget = target
        module.tooltips.hardTarget:set(nil, { type = "Unit", unit = "target" })
        hardTargetChange:fire({ target = target })
    end
    local targetHealth = UnitHealth("target")
    local targetHealthMax = UnitHealthMax("target")
    --Note 100/5 = 20, otherwise the calculation would be math.ceil((targetHealth / targetHealthMax) * 100 / 5)*5 which is a bit pointless
    --we only want the percent interval for the report, hence the math.ceil
    local targetHealthInterval = math.ceil((targetHealth / targetHealthMax) * 20) * 5
    if targetHealthInterval ~= self.targetHealthInterval then
        hardTargetHealth:fire({ target = target, healthInterval = targetHealthInterval })
        self.targetHealthInterval = targetHealthInterval
    end
end

function module:updateSoftTarget(target, newGuid)
    if not target.alert:getEnabled() then
        return
    end
    if newGuid ~= target.guid then
        if newGuid then
            target.tooltip:set(nil, { type = "Unit", unit = target.unit })
            target.alert:fire({ name = UnitName(target.unit) })
        else
            target.tooltip:reset()
        end
        target.guid = newGuid
    end
end

function module:onEnable()
    -- Initialize cached target GUID (in case target exists at startup)
    self._cachedTargetGuid = UnitGUID("target")
    self:hasUpdate(function(self)
        self:updateHardTarget()
    end)
end
