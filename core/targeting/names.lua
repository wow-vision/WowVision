local module = WowVision.base.targeting
local L = module.L
local targetNames = WowVision.targetNames
local secrets = WowVision.secrets

-- The configurable target announcement (Menu, Targeting, Names): which facts
-- the hard and soft target announcements speak, per combat state and per
-- kind of target. The rules live in targetNames.lua; this file hands them
-- the game and the settings. With the announcement switched off, and for
-- game objects, the full tooltip is spoken as before.

-- The unit tooltip's lines as the game builds them (C_TooltipInfo.GetUnit,
-- the source the minimap scan already reads on Forever): the line type
-- tells the name, level, owner and quest objective lines apart.
local function tooltipLines(unit)
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
    if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then
        return nil
    end
    local lines = {}
    for index, line in ipairs(data.lines) do
        lines[index] = { type = line.type, text = line.leftText, completed = line.completed }
    end
    return lines
end

local function questRelated(unit)
    return C_QuestLog.UnitIsRelatedToActiveQuest(unit)
end

-- Every call the parts may use; a missing one leaves its parts out of the
-- menu and the announcement.
local api = {
    UnitExists = UnitExists,
    UnitIsGameObject = UnitIsGameObject,
    UnitGUID = UnitGUID,
    UnitIsPlayer = UnitIsPlayer,
    UnitPlayerControlled = UnitPlayerControlled,
    UnitCanAttack = UnitCanAttack,
    UnitName = UnitName,
    UnitPVPName = UnitPVPName,
    UnitLevel = UnitLevel,
    UnitRace = UnitRace,
    UnitClass = UnitClass,
    UnitSex = UnitSex,
    UnitFactionGroup = UnitFactionGroup,
    UnitGroupRolesAssigned = UnitGroupRolesAssigned,
    UnitIsPVP = UnitIsPVP,
    UnitIsPVPFreeForAll = UnitIsPVPFreeForAll,
    UnitIsAFK = UnitIsAFK,
    UnitIsDND = UnitIsDND,
    UnitIsDead = UnitIsDead,
    UnitIsGhost = UnitIsGhost,
    UnitIsCharmed = UnitIsCharmed,
    UnitAffectingCombat = UnitAffectingCombat,
    UnitClassification = UnitClassification,
    UnitIsBossMob = UnitIsBossMob,
    UnitCreatureType = UnitCreatureType,
    UnitCreatureFamily = UnitCreatureFamily,
    UnitReaction = UnitReaction,
    UnitIsQuestBoss = UnitIsQuestBoss,
    UnitIsTapDenied = UnitIsTapDenied,
    UnitIsOwnerOrControllerOfUnit = UnitIsOwnerOrControllerOfUnit,
    GetGuildInfo = GetGuildInfo,
    questRelated = C_QuestLog ~= nil and C_QuestLog.UnitIsRelatedToActiveQuest ~= nil and questRelated or nil,
    tooltipLines = C_TooltipInfo ~= nil and C_TooltipInfo.GetUnit ~= nil and tooltipLines or nil,
    -- The player's own combat flag: set the moment combat starts, unlike
    -- InCombatLockdown, which follows the protected-action lockdown.
    playerInCombat = function()
        return UnitAffectingCombat("player")
    end,
}
module.targetNamesApi = api

local settings = module:hasSettings()
settings:add(targetNames.settingsDef(api))

-- The text a target announcement speaks for a unit: the configured parts
-- for the current combat state, else (announcement off, a game object, an
-- error) the full tooltip as before. The second result tells which.
function module:targetText(unit, tooltip)
    local ok, text = pcall(targetNames.describe, api, unit, self.settings.names)
    if not ok then
        geterrorhandler()(text)
        text = nil
    end
    if text ~= nil then
        return text, true
    end
    return tooltip:getText(), false
end

module:registerCommand({
    name = "targetinfo",
    scope = "WowVision",
    description = "Target announcement: what each part reads for your target, the tooltip lines, and the announcement",
    func = function()
        local lines = targetNames.report(api, "target", module.settings.names)
        for _, line in ipairs(lines) do
            print(line)
        end
        if WowVision.testing ~= nil and WowVision.testing.showResults ~= nil then
            WowVision.testing.showResults(table.concat(lines, "\n"))
        end
        if not UnitExists("target") then
            WowVision:speak(L["No target"])
            return
        end
        local text = targetNames.describe(api, "target", module.settings.names)
        if secrets.hasText(text) then
            WowVision:speak(text)
        end
    end,
})
