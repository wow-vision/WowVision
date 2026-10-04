local module = WowVision.base:createModule("targeting")
local L = module.L
module:setLabel(L["Targeting"])
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
    path = "Sound/WowVision/alerts/notification21.mp3",
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

-- The soft targeting console variables go through one writer that reads each
-- write back and holds the secure ones (the on/off switches, Force, measured
-- on Forever) until combat ends. See softTargeting.lua.
local soft = WowVision.softTargeting
local getCVar = C_CVar ~= nil and C_CVar.GetCVar or GetCVar
local setCVar = C_CVar ~= nil and C_CVar.SetCVar or SetCVar
local writer = soft.Writer:new({
    getCVar = getCVar,
    setCVar = setCVar,
    isSecure = function(name)
        -- Unknown counts as secure: a write held until combat ends is safe,
        -- a blocked one raises ADDON_ACTION_BLOCKED.
        if C_CVar == nil or C_CVar.GetCVarInfo == nil then
            return true
        end
        local ok, _, _, _, _, _, isSecure = pcall(C_CVar.GetCVarInfo, name)
        return not ok or isSecure ~= false
    end,
    inCombat = InCombatLockdown,
})

local arcChoices = {
    { label = L["Directly in Front"], value = 0 },
    { label = L["15 Degrees in Front"], value = 1 },
    { label = L["180 Degrees in Front"], value = 2 },
}

-- Written only once the module runs: restoring settings at load fires the
-- same change events before the game is ready for them.
local function onSoftTargetSettingChange()
    if module.softTargetingReady then
        module:applySoftTargeting()
    end
end

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
    enabled.events.valueChange:subscribe(nil, function(event, obj, key, value)
        if value ~= true then
            info.guid = nil
        end
        if module.softTargetingReady then
            -- 3 = keyboard and gamepad
            writer:write(info.cvar, value == true and 3 or 0)
        end
    end)
    settings:addRef(info.key, alert.parameters)
    local arc = settings:add({
        key = info.key .. "Arc",
        type = "Choice",
        label = info.arcLabel,
        default = info.defaultArc,
        choices = arcChoices,
    })
    arc.events.valueChange:subscribe(nil, onSoftTargetSettingChange)
    local range = settings:add({
        key = info.key .. "Range",
        type = "Number",
        label = info.rangeLabel,
        default = info.defaultRange,
        min = info.minRange,
        max = info.maxRange,
    })
    range.events.valueChange:subscribe(nil, onSoftTargetSettingChange)
    module:registerBinding({
        inputs = { info.binding },
        type = "Function",
        key = "targeting/" .. info.key,
        label = info.label,
        interruptSpeech = true,
        func = function()
            local value = enabled:toggle()
            local text
            if value then
                text = info.label .. " " .. L["Enabled"]
            else
                text = info.label .. " " .. L["Disabled"]
            end
            -- The switch is secure: pressed in combat it lands when combat ends.
            if writer.pending[info.cvar] ~= nil then
                text = text .. ", " .. L["after combat"]
            end
            WowVision:speak(text)
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
        path = info.sound,
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
    arcLabel = L["Soft Target Enemy Arc"],
    rangeLabel = L["Soft Target Enemy Range"],
    defaultArc = 1,
    defaultRange = 60,
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
    arcLabel = L["Soft Target Friend Arc"],
    rangeLabel = L["Soft Target Friend Range"],
    defaultArc = 1,
    defaultRange = 60,
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
    arcLabel = L["Soft Target Interact Arc"],
    rangeLabel = L["Soft Target Interact Range"],
    defaultArc = 2,
    -- Kept short on purpose: a long interact reach picks up mobs behind
    -- walls and buildings. 20 is the game's own gamepad value.
    defaultRange = 15,
    minRange = 1,
    maxRange = 20,
})

local lockMode = settings:add({
    key = "softTargetLock",
    type = "Choice",
    label = L["Soft Targeting With a Hard Target"],
    default = "noAttackableHardTarget",
    choices = {
        { label = L["Only Without an Attackable Hard Target"], value = "noAttackableHardTarget" },
        { label = L["Only Without a Hard Target"], value = "noHardTarget" },
        { label = L["Always"], value = "always" },
    },
})
lockMode.events.valueChange:subscribe(nil, onSoftTargetSettingChange)

-- SoftTargetForce: the hard target follows the soft target.
local force = settings:add({
    key = "softTargetForce",
    type = "Choice",
    label = L["Make Soft Target the Hard Target"],
    default = 0,
    choices = {
        { label = L["Off"], value = 0 },
        { label = L["Enemies"], value = 1 },
        { label = L["Friends"], value = 2 },
    },
})
force.events.valueChange:subscribe(nil, onSoftTargetSettingChange)

module:registerEvent("event", "PLAYER_REGEN_ENABLED")
-- A target that dies stays locked: its death has to switch the lock too.
module:registerEvent("unit", "UNIT_HEALTH", "target")

-- Every soft targeting variable, so a reload brings the game back in line
-- with the settings. A switch that is off stays as the game has it: players
-- may have turned the interact key on in Blizzard's own options.
function module:applySoftTargeting()
    for _, info in ipairs(softTargets) do
        if info.alert:getEnabled() then
            writer:write(info.cvar, 3)
        end
        writer:write(info.cvar .. "Arc", self.settings[info.key .. "Arc"])
        writer:write(info.cvar .. "Range", self.settings[info.key .. "Range"])
    end
    writer:write("SoftTargetForce", self.settings.softTargetForce)
    self.lockWanted = nil
    self:updateSoftTargetLock()
end

-- Runs on every target change and death, in combat too: the lock variables
-- are not secure. Writes only when the wanted value changes.
function module:updateSoftTargetLock()
    local withLocked, matchLocked = soft.lockValues(
        self.settings.softTargetLock,
        UnitExists("target"),
        UnitCanAttack("player", "target"),
        UnitIsDead("target")
    )
    if withLocked == nil or withLocked == self.lockWanted then
        return
    end
    self.lockWanted = withLocked
    writer:write("SoftTargetWithLocked", withLocked)
    writer:write("SoftTargetMatchLocked", matchLocked)
end

function module:onEvent(event, a, b)
    -- Cache hard target GUID on event (avoids UnitGUID call every frame)
    if event == "PLAYER_TARGET_CHANGED" then
        self._cachedTargetGuid = UnitGUID("target")
        self:updateSoftTargetLock()
        return
    end
    if event == "UNIT_HEALTH" then
        self:updateSoftTargetLock()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        writer:flush()
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
    -- Retail keeps some units' health secret from addons: no math is
    -- possible on it, so the health monitor sits out for those targets.
    if
        WowVision.isSecret(targetHealth)
        or WowVision.isSecret(targetHealthMax)
        or targetHealthMax == nil
        or targetHealthMax == 0
    then
        self.targetHealthInterval = nil
        return
    end
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

function module:onFullEnable()
    self.softTargetingReady = true
    self:applySoftTargeting()
end

function module:onDisable()
    self.softTargetingReady = false
end

-- One line per soft targeting variable: its value, the game's default, and
-- whether a write is waiting for combat to end.
function module:softTargetingReport()
    local names = {}
    for _, info in ipairs(softTargets) do
        tinsert(names, info.cvar)
        tinsert(names, info.cvar .. "Arc")
        tinsert(names, info.cvar .. "Range")
    end
    tinsert(names, "SoftTargetForce")
    tinsert(names, "SoftTargetWithLocked")
    tinsert(names, "SoftTargetMatchLocked")

    local lines = {
        L["Soft Targeting With a Hard Target"]
            .. ": "
            .. tostring(lockMode:getValueString(self.settings, self.settings.softTargetLock)),
    }
    for _, name in ipairs(names) do
        local value = getCVar(name)
        local line
        if value == nil then
            line = name .. " " .. L["not available"]
        else
            line = name .. " " .. value
            if C_CVar ~= nil and C_CVar.GetCVarDefault ~= nil then
                line = line .. " (" .. L["default"] .. " " .. tostring(C_CVar.GetCVarDefault(name)) .. ")"
            end
            if writer.pending[name] ~= nil then
                line = line .. ", " .. L["after combat"] .. " " .. writer.pending[name]
            end
        end
        tinsert(lines, line)
    end
    return lines
end

module:registerCommand({
    name = "soft",
    scope = "WowVision",
    description = "Soft targeting: the lock mode and every soft targeting console variable, with waiting writes",
    func = function()
        local lines = module:softTargetingReport()
        for _, line in ipairs(lines) do
            print(line)
        end
        WowVision:speak(table.concat(lines, ". "))
    end,
})
