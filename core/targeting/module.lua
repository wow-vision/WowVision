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

-- Forever and Retail hand the raid target index out as a secret in addon
-- code, always (GetRaidTargetIndex is SecretReturns): no comparison, table
-- lookup or curve evaluation is possible on it, so the marker cannot be
-- named. Concatenation carries the number into the spoken text, and speech
-- accepts the result: the player hears "3" and maps it to Diamond.
local secrets = WowVision.secrets

local function markerName(unit)
    local index = GetRaidTargetIndex(unit)
    if not index then
        return ""
    end
    if secrets.isSecret(index) then
        return "" .. index
    end
    return markerNames[index] or ""
end

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
            local marker = markerName("target")
            -- The marker text may be secret: no comparing it, only joining.
            if secrets.hasText(marker) then
                targetString = marker .. " "
            end
        end
        -- The configured parts (names.lua), or the full tooltip. Either may
        -- be secret: concatenation carries it through and speech accepts it.
        targetString = targetString .. module:targetText("target", module.tooltips.hardTarget)
        return targetString
    end,
})

hardTargetSpeak:addParameter({
    key = "announceRaidMarker",
    type = "Bool",
    label = L["Announce Raid Target Marker on Hard Target"],
    default = true,
})

-- Whether you, your pet or a group member is on the unit's threat list:
-- in a group too, where "party1" is never you (utils.groupUnits). A secret
-- threat status is not nil, so it still means "on the list".
local function inCombatWith(unit)
    for _, member in ipairs(WowVision.utils.groupUnits(IsInRaid(), IsInGroup())) do
        if UnitExists(member) and UnitThreatSituation(member, unit) ~= nil then
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

-- Crowd control on the current target (crowdControl.lua): fired with
-- { controlled = true } when crowd control lands on it or a controlled
-- target is chosen, { controlled = false } when it ends on the same target.
local targetCrowdControl = module:addAlert({
    key = "targetCrowdControl",
    label = L["Target Crowd Control"],
})
module.targetCrowdControl = targetCrowdControl

targetCrowdControl:addOutput({
    type = "Sound",
    key = "onSound",
    label = L["Controlled Sound"],
    shouldFire = function(self, message)
        return message.controlled == true
    end,
    path = "Sound/WowVision/alerts/cc-on.mp3",
})

targetCrowdControl:addOutput({
    type = "Sound",
    key = "offSound",
    label = L["Free Sound"],
    shouldFire = function(self, message)
        return message.controlled == false
    end,
    path = "Sound/WowVision/alerts/cc-off.mp3",
})

targetCrowdControl:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return message.controlled and L["Controlled"] or L["Free"]
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
hardTarget:addRef("crowdControl", targetCrowdControl.parameters)
-- Other files add to it too (range.lua).
module.hardTargetSettings = hardTarget

-- For a client that keeps target health secret in combat (see
-- retail/targeting.lua): the monitor leaves the menu and stops reading. Its
-- alert stays registered, so saved settings keep their place.
function module:removeTargetHealth()
    for i = #hardTarget.refs, 1, -1 do
        if hardTarget.refs[i].key == "healthMonitor" then
            table.remove(hardTarget.refs, i)
        end
    end
    self.targetHealthRemoved = true
end

local softTargets = {}

-- The soft targeting console variables go through one writer that reads each
-- write back and holds the secure ones (the on/off switches, Force, measured
-- on Forever) until combat ends. See softTargeting.lua.
local soft = WowVision.softTargeting
local getCVar = C_CVar ~= nil and C_CVar.GetCVar or GetCVar
local setCVar = C_CVar ~= nil and C_CVar.SetCVar or SetCVar
local getCVarDefault = C_CVar ~= nil and C_CVar.GetCVarDefault or GetCVarDefault
local writer = soft.Writer:new({
    getCVar = getCVar,
    setCVar = setCVar,
    getDefault = function(name)
        local ok, default = pcall(getCVarDefault, name)
        return ok and default or nil
    end,
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

-- Arcs and ranges default to the widest and the longest: the game's own values
-- are made for players who can see what is in front of them. They are written
-- only for a soft target type that is on, so a player who never uses one keeps
-- the game's values. Game Default, and a range of 0, go back to the game's own.
local GAME_DEFAULT = soft.GAME_DEFAULT
local WIDEST_ARC = 2

local arcChoices = {
    { label = L["Game Default"], value = GAME_DEFAULT },
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

-- Whether a setting's value means "the game's own": it writes nothing, and
-- choosing it restores the game's default.
local function isGameDefault(name, value)
    return value == nil or value == GAME_DEFAULT or (value == 0 and name:find("Range$") ~= nil)
end

-- A change event for the setting behind one variable.
local function onVariableSettingChange(name)
    return function(event, obj, key, value)
        if module.softTargetingReady and isGameDefault(name, value) then
            writer:restore(name)
        end
        onSoftTargetSettingChange()
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
            if value == true then
                module:applySoftTargeting()
            end
        end
    end)
    settings:addRef(info.key, alert.parameters)
    local arc = alert.parameters:add({
        key = "arc",
        type = "Choice",
        label = info.arcLabel,
        default = WIDEST_ARC,
        choices = arcChoices,
    })
    arc.events.valueChange:subscribe(nil, onVariableSettingChange(info.cvar .. "Arc"))
    -- 0 = the game's own range.
    local range = alert.parameters:add({
        key = "range",
        type = "Number",
        label = info.rangeLabel,
        default = info.maxRange,
        min = 0,
        max = info.maxRange,
    })
    range.events.valueChange:subscribe(nil, onVariableSettingChange(info.cvar .. "Range"))
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
            local text, configured = module:targetText(info.unit, info.tooltip)
            if configured then
                return text
            end
            if secrets.isSecret(text) or (text and #text > 1) then
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
    -- A long interact reach picks up mobs behind walls and buildings; 20
    -- is the game's own gamepad value.
    maxRange = 20,
})

local lockMode = settings:add({
    key = "softTargetLock",
    type = "Choice",
    label = L["Soft Targeting With a Hard Target"],
    default = GAME_DEFAULT,
    choices = {
        { label = L["Game Default"], value = GAME_DEFAULT },
        { label = L["Only Without an Attackable Hard Target"], value = "noAttackableHardTarget" },
        { label = L["Only Without a Hard Target"], value = "noHardTarget" },
        { label = L["Always"], value = "always" },
    },
})
lockMode.events.valueChange:subscribe(nil, function(event, obj, key, value)
    if module.softTargetingReady and value == GAME_DEFAULT then
        writer:restore("SoftTargetWithLocked")
        writer:restore("SoftTargetMatchLocked")
    end
    onSoftTargetSettingChange()
end)

-- SoftTargetForce: the hard target follows the soft target.
local force = settings:add({
    key = "softTargetForce",
    type = "Choice",
    label = L["Make Soft Target the Hard Target"],
    default = GAME_DEFAULT,
    choices = {
        { label = L["Game Default"], value = GAME_DEFAULT },
        { label = L["Off"], value = 0 },
        { label = L["Enemies"], value = 1 },
        { label = L["Friends"], value = 2 },
    },
})
force.events.valueChange:subscribe(nil, onVariableSettingChange("SoftTargetForce"))

module:registerEvent("event", "PLAYER_REGEN_ENABLED")
-- A target that dies stays locked: its death has to switch the lock too.
module:registerEvent("unit", "UNIT_HEALTH", "target")

-- Writes a value unless the setting is at its "game default", which leaves
-- the variable as the game has it.
local function writeUnlessDefault(name, value)
    if not isGameDefault(name, value) then
        writer:write(name, value)
    end
end

-- Every soft targeting variable, so a reload brings the game back in line
-- with the settings. A switch that is off stays as the game has it: players
-- may have turned the interact key on in Blizzard's own options.
function module:applySoftTargeting()
    for _, info in ipairs(softTargets) do
        if info.alert:getEnabled() then
            writer:write(info.cvar, 3)
            writeUnlessDefault(info.cvar .. "Arc", info.alert.parameters:getFieldValue("arc"))
            writeUnlessDefault(info.cvar .. "Range", info.alert.parameters:getFieldValue("range"))
        end
    end
    writeUnlessDefault("SoftTargetForce", self.settings.softTargetForce)
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
        self._targetDirty = true
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

    -- The payload GUIDs can be secret (hidden identities on Forever and
    -- Retail): then they cannot be compared, and the event itself is the
    -- change.
    for _, v in ipairs(softTargets) do
        if event == v.event then
            local newGuid
            if (a or b) and secrets.changed(a, b) then
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
    if not target then
        self.hardTarget = nil
        self._targetDirty = false
        return
    end
    -- A secret GUID cannot be compared with the last one, and this runs
    -- every tick: while the identity is hidden, only the target change
    -- event counts as a change.
    local changed
    if secrets.isSecret(target) then
        changed = self._targetDirty == true
    else
        changed = secrets.changed(target, self.hardTarget)
    end
    self._targetDirty = false
    if changed then
        self.hardTarget = target
        -- A new target's health is announced on its own, not compared with
        -- the last target's.
        self.targetHealthInterval = nil
        module.tooltips.hardTarget:set(nil, { type = "Unit", unit = "target" })
        hardTargetChange:fire({ target = target })
    end
    if self.targetHealthRemoved then
        return
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
    if secrets.changed(newGuid, target.guid) then
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
