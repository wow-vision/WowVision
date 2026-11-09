-- What a target announcement says, built from the parts the player picked
-- (Menu, Targeting, Names). Kept free of frames so the headless tests run it;
-- names.lua wires it to the game and the settings.
--
-- A target falls into one category (classify); each category has an ordered
-- list of parts; each part reads the game through an api table and yields
-- tokens. The settings hold one table per combat state ("inCombat",
-- "outOfCombat"), with one table per category, with one boolean per part.
-- Which state applies is decided when the announcement is built.
--
-- Secrets (WoW: Forever and Retail hide unit identities in combat): a secret
-- string is never compared or measured, only joined, which speech accepts. A
-- secret boolean or number that has to be tested is skipped: the part says
-- nothing rather than guess. Category detection uses only reads the game
-- never makes secret (UnitIsPlayer, UnitPlayerControlled, UnitCanAttack).
--
-- api, the game calls the parts use (any may be nil: the part is then not
-- offered in the menu and says nothing):
--   UnitExists, UnitIsGameObject, UnitIsPlayer, UnitPlayerControlled,
--   UnitCanAttack, UnitName, UnitPVPName, UnitLevel, UnitRace, UnitClass,
--   UnitSex, UnitFactionGroup, UnitGroupRolesAssigned, UnitIsPVP,
--   UnitIsPVPFreeForAll, UnitIsAFK, UnitIsDND, UnitIsDead, UnitIsGhost,
--   UnitIsCharmed, UnitAffectingCombat, UnitClassification, UnitIsBossMob,
--   UnitCreatureType, UnitCreatureFamily, UnitReaction, UnitIsQuestBoss,
--   UnitIsTapDenied, UnitIsOwnerOrControllerOfUnit, UnitGUID, GetGuildInfo:
--   as in the game
--   questRelated(unit)    C_QuestLog.UnitIsRelatedToActiveQuest
--   tooltipLines(unit)    the unit tooltip's lines as { type, text, completed }
--                         (C_TooltipInfo.GetUnit), nil when unreadable
--   playerInCombat()      whether the player is in combat
local targetNames = {}
WowVision.targetNames = targetNames

local L = WowVision:getLocale()

local function secrets()
    return WowVision.secrets
end

local function isSecret(value)
    return secrets().isSecret(value)
end

local function hasText(text)
    return secrets().hasText(text)
end

-- Tooltip line types (Enum.TooltipDataLineType).
local LINE_NONE = 0
local LINE_UNIT_NAME = 2
local LINE_QUEST_OBJECTIVE = 8
local LINE_UNIT_OWNER = 16
local LINE_UNIT_LEVEL = 47

-- UnitCreatureType's id for totems.
local CREATURE_TYPE_TOTEM = 11

targetNames.STATES = {
    { key = "inCombat", label = L["In Combat"] },
    { key = "outOfCombat", label = L["Out of Combat"] },
}

targetNames.CATEGORIES = {
    { key = "player", label = L["Players"] },
    { key = "npc", label = L["NPCs"] },
    { key = "mob", label = L["Mobs"] },
    { key = "pet", label = L["Pets"] },
    { key = "totem", label = L["Totems"] },
}

-- ---------------------------------------------------------------------------
-- Reading the game
-- ---------------------------------------------------------------------------

-- One read context per announcement: the api, the unit, and a cache so a
-- call that several parts need (the classification, the tooltip lines) runs
-- once.
local Context = {}
Context.__index = Context

local function newContext(api, unit, category)
    return setmetatable({ api = api, unit = unit, category = category, cache = {} }, Context)
end

local function pack(...)
    return { n = select("#", ...), ... }
end

-- The results of api[name](...) as a packed list, empty when the call is
-- missing or fails.
local function callPacked(api, name, ...)
    local fn = api[name]
    if fn == nil then
        return { n = 0 }
    end
    local results = pack(pcall(fn, ...))
    if not results[1] then
        return { n = 0 }
    end
    return { n = results.n - 1, unpack(results, 2, results.n) }
end

local function call(api, name, ...)
    local results = callPacked(api, name, ...)
    return unpack(results, 1, results.n)
end

function Context:call(name, ...)
    return call(self.api, name, ...)
end

-- A call on the unit, cached by name.
function Context:read(name)
    local cached = self.cache[name]
    if cached == nil then
        cached = callPacked(self.api, name, self.unit)
        self.cache[name] = cached
    end
    return unpack(cached, 1, cached.n)
end

-- A boolean read: true only for a plain true; a secret answer counts as
-- unknown.
function Context:flag(name, ...)
    local value
    if select("#", ...) > 0 then
        value = self:call(name, ...)
    else
        value = self:read(name)
    end
    if value == nil or isSecret(value) then
        return false
    end
    return value == true
end

function Context:tooltipLines()
    if self.cache.tooltipLines == nil then
        local lines = self:call("tooltipLines", self.unit)
        self.cache.tooltipLines = type(lines) == "table" and lines or {}
    end
    return self.cache.tooltipLines
end

-- The classification, nil when unknown or secret.
function Context:classification()
    local value = self:read("UnitClassification")
    if value == nil or isSecret(value) then
        return nil
    end
    return value
end

local function token(key, text, group)
    if not hasText(text) then
        return nil
    end
    return { key = key, text = text, group = group }
end

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------

local function isTotem(ctx)
    local _, id = ctx:read("UnitCreatureType")
    return id ~= nil and not isSecret(id) and id == CREATURE_TYPE_TOTEM
end

-- The category of a unit, nil for no unit or a game object (a soft interact
-- target such as a mailbox or a herb): those keep the full tooltip.
function targetNames.classify(api, unit)
    local ctx = newContext(api, unit)
    if not ctx:flag("UnitExists") then
        return nil
    end
    if ctx:flag("UnitIsGameObject") then
        return nil
    end
    -- Clients without UnitIsGameObject: the GUID names the object kind.
    if api.UnitIsGameObject == nil then
        local guid = ctx:read("UnitGUID")
        if hasText(guid) and not isSecret(guid) and guid:find("^GameObject%-") then
            return nil
        end
    end
    if ctx:flag("UnitIsPlayer") then
        return "player"
    end
    if ctx:flag("UnitPlayerControlled") then
        if isTotem(ctx) then
            return "totem"
        end
        return "pet"
    end
    if ctx:flag("UnitCanAttack", "player", unit) then
        return "mob"
    end
    return "npc"
end

-- ---------------------------------------------------------------------------
-- Parts
-- ---------------------------------------------------------------------------

local function stripBrackets(text)
    if isSecret(text) then
        return text
    end
    return (text:gsub("^%s*<(.-)>%s*$", "%1"))
end

-- An NPC's subtitle ("<Innkeeper>"): the line between the name and the
-- level. With typed tooltip lines it is an untyped line right after the
-- UnitName line and before the UnitLevel line. Without types, or without a
-- UnitLevel line (WoW: Forever), the classic shape: line 2 is the subtitle
-- when line 3 carries the level and line 2 does not. Anything secret or
-- unclear says nothing.
local function npcTitle(ctx)
    local lines = ctx:tooltipLines()
    local first, second = lines[1], lines[2]
    if first == nil or second == nil or not hasText(second.text) then
        return nil
    end
    local typed = false
    for _, line in ipairs(lines) do
        if line.type ~= nil and line.type ~= LINE_NONE then
            typed = true
            break
        end
    end
    if typed then
        if first.type ~= LINE_UNIT_NAME or (second.type ~= nil and second.type ~= LINE_NONE) then
            return nil
        end
        for index = 3, #lines do
            if lines[index].type == LINE_UNIT_LEVEL then
                return stripBrackets(second.text)
            end
        end
        -- WoW: Forever types the name, quest, threat and owner lines but
        -- never the level line: the untyped rule below decides.
    end
    local third = lines[3]
    if third == nil or isSecret(second.text) or not hasText(third.text) or isSecret(third.text) then
        return nil
    end
    local level = ctx:read("UnitLevel")
    if level == nil or isSecret(level) then
        return nil
    end
    local marker = level == -1 and "%?%?" or ("%f[%d]" .. level .. "%f[%D]")
    if third.text:find(marker) and not second.text:find(marker) then
        return stripBrackets(second.text)
    end
    return nil
end

local function levelText(level)
    if level == nil then
        return nil
    end
    if isSecret(level) then
        return L["Level"] .. " " .. level
    end
    if level == -1 then
        return L["Skull Level"]
    end
    if level <= 0 then
        return nil
    end
    return L["Level"] .. " " .. level
end

local CLASSIFICATION_TOKENS = {
    elite = { { "elite", L["Elite"] } },
    rare = { { "rare", L["Rare"] } },
    rareelite = { { "rare", L["Rare"] }, { "elite", L["Elite"] } },
    worldboss = { { "boss", L["World Boss"] } },
    minus = { { "minor", L["Minor"] } },
    trivial = { { "trivial", L["Trivial"] } },
}

-- One token of the classification: the given key ("elite", "rare", "boss").
local function classificationToken(ctx, key)
    local tokens = CLASSIFICATION_TOKENS[ctx:classification() or ""]
    for _, entry in ipairs(tokens or {}) do
        if entry[1] == key then
            return token(entry[1], entry[2], "level")
        end
    end
    return nil
end

local function reactionText(reaction)
    if reaction == nil or isSecret(reaction) then
        return nil
    end
    if reaction <= 3 then
        return L["Hostile"]
    elseif reaction == 4 then
        return L["Neutral"]
    end
    return L["Friendly"]
end

local ROLE_TEXTS = {
    TANK = L["Tank"],
    HEALER = L["Healer"],
    DAMAGER = L["Damage Dealer"],
}

local SEX_TEXTS = {
    [2] = L["Male"],
    [3] = L["Female"],
}

-- Each part: label (the checkbox), requires (the api calls it needs; it is
-- offered only when they exist), read(ctx) returning a token, a list of
-- tokens, or nil. A token's key deduplicates: two parts naming the same
-- fact (Classification and Elite) say it once.
local PARTS = {}
targetNames.PARTS = PARTS

PARTS.name = {
    label = L["Name"],
    requires = { "UnitName" },
    read = function(ctx)
        local name = ctx:read("UnitName")
        -- A player's title comes with the name (UnitPVPName: "Sergeant
        -- Broesel"), so the name speaks it when Title is on too.
        if ctx.category == "player" and ctx.enabled.title then
            local pvpName = ctx:read("UnitPVPName")
            if hasText(pvpName) then
                local result = token("name", pvpName)
                result.covers = { "title" }
                return result
            end
        end
        return token("name", name)
    end,
}

PARTS.title = {
    label = L["Title"],
    requires = { "tooltipLines" },
    playerRequires = { "UnitPVPName", "UnitName" },
    read = function(ctx)
        if ctx.category ~= "player" then
            return token("title", npcTitle(ctx))
        end
        -- Without the name: the title alone, cut out of the full name.
        local name = ctx:read("UnitName")
        local pvpName = ctx:read("UnitPVPName")
        if not hasText(name) or not hasText(pvpName) or isSecret(name) or isSecret(pvpName) then
            return nil
        end
        local first, last = pvpName:find(name, 1, true)
        if first == nil then
            return nil
        end
        local title = (pvpName:sub(1, first - 1) .. pvpName:sub(last + 1)):gsub("^[%s,]+", ""):gsub("[%s,]+$", "")
        return token("title", title)
    end,
}

PARTS.realm = {
    label = L["Realm"],
    requires = { "UnitName" },
    read = function(ctx)
        local _, realm = ctx:read("UnitName")
        if not hasText(realm) then
            return nil
        end
        return token("realm", L["Realm"] .. " " .. realm)
    end,
}

PARTS.guild = {
    label = L["Guild"],
    requires = { "GetGuildInfo" },
    read = function(ctx)
        local guild = ctx:read("GetGuildInfo")
        if not hasText(guild) then
            return nil
        end
        return token("guild", L["Guild"] .. " " .. guild)
    end,
}

PARTS.level = {
    label = L["Level"],
    requires = { "UnitLevel" },
    read = function(ctx)
        return token("level", levelText(ctx:read("UnitLevel")), "level")
    end,
}

PARTS.classification = {
    label = L["Classification"],
    requires = { "UnitClassification" },
    read = function(ctx)
        local list = {}
        for _, entry in ipairs(CLASSIFICATION_TOKENS[ctx:classification() or ""] or {}) do
            tinsert(list, token(entry[1], entry[2], "level"))
        end
        return list
    end,
}

PARTS.elite = {
    label = L["Elite"],
    requires = { "UnitClassification" },
    read = function(ctx)
        return classificationToken(ctx, "elite")
    end,
}

PARTS.rare = {
    label = L["Rare"],
    requires = { "UnitClassification" },
    read = function(ctx)
        return classificationToken(ctx, "rare")
    end,
}

PARTS.boss = {
    label = L["Boss"],
    requires = { "UnitClassification" },
    read = function(ctx)
        local worldBoss = classificationToken(ctx, "boss")
        if worldBoss ~= nil then
            return worldBoss
        end
        if ctx:flag("UnitIsBossMob") then
            return token("boss", L["Boss"], "level")
        end
        return nil
    end,
}

PARTS.creatureType = {
    label = L["Creature Type"],
    requires = { "UnitCreatureType" },
    read = function(ctx)
        return token("creatureType", (ctx:read("UnitCreatureType")), "creature")
    end,
}

PARTS.creatureFamily = {
    label = L["Creature Family"],
    requires = { "UnitCreatureFamily" },
    read = function(ctx)
        return token("creatureFamily", (ctx:read("UnitCreatureFamily")), "creature")
    end,
}

PARTS.race = {
    label = L["Race"],
    requires = { "UnitRace" },
    read = function(ctx)
        return token("race", (ctx:read("UnitRace")), "raceClass")
    end,
}

PARTS.class = {
    label = L["Class"],
    requires = { "UnitClass" },
    read = function(ctx)
        return token("class", (ctx:read("UnitClass")), "raceClass")
    end,
}

PARTS.sex = {
    label = L["Gender"],
    requires = { "UnitSex" },
    read = function(ctx)
        local sex = ctx:read("UnitSex")
        if sex == nil or isSecret(sex) then
            return nil
        end
        return token("sex", SEX_TEXTS[sex])
    end,
}

PARTS.faction = {
    label = L["Faction"],
    requires = { "UnitFactionGroup" },
    read = function(ctx)
        local _, localized = ctx:read("UnitFactionGroup")
        return token("faction", localized)
    end,
}

PARTS.role = {
    label = L["Group Role"],
    requires = { "UnitGroupRolesAssigned" },
    read = function(ctx)
        local role = ctx:read("UnitGroupRolesAssigned")
        if role == nil or isSecret(role) then
            return nil
        end
        return token("role", ROLE_TEXTS[role])
    end,
}

PARTS.pvp = {
    label = L["PvP Status"],
    requires = { "UnitIsPVP" },
    read = function(ctx)
        if ctx:flag("UnitIsPVPFreeForAll") then
            return token("pvp", L["Free-for-All PvP"])
        end
        if ctx:flag("UnitIsPVP") then
            return token("pvp", L["PvP"])
        end
        return nil
    end,
}

PARTS.afk = {
    label = L["Away (AFK)"],
    requires = { "UnitIsAFK" },
    read = function(ctx)
        return ctx:flag("UnitIsAFK") and token("afk", L["AFK"]) or nil
    end,
}

PARTS.dnd = {
    label = L["Do Not Disturb (DND)"],
    requires = { "UnitIsDND" },
    read = function(ctx)
        return ctx:flag("UnitIsDND") and token("dnd", L["Do Not Disturb"]) or nil
    end,
}

PARTS.reaction = {
    label = L["Reaction"],
    requires = { "UnitReaction" },
    read = function(ctx)
        return token("reaction", reactionText(ctx:call("UnitReaction", ctx.unit, "player")))
    end,
}

PARTS.owner = {
    label = L["Owner"],
    requires = { "tooltipLines" },
    read = function(ctx)
        for _, line in ipairs(ctx:tooltipLines()) do
            if line.type == LINE_UNIT_OWNER and hasText(line.text) then
                return token("owner", line.text)
            end
        end
        if ctx:flag("UnitIsOwnerOrControllerOfUnit", "player", ctx.unit) then
            return token("owner", L["Yours"])
        end
        return nil
    end,
}

PARTS.questBoss = {
    label = L["Quest Boss"],
    requires = { "UnitIsQuestBoss" },
    read = function(ctx)
        return ctx:flag("UnitIsQuestBoss") and token("questBoss", L["Quest Boss"]) or nil
    end,
}

PARTS.quest = {
    label = L["Quest Target"],
    requires = { "questRelated" },
    read = function(ctx)
        return ctx:flag("questRelated") and token("quest", L["Quest Target"]) or nil
    end,
}

-- The quest objectives the tooltip lists for this unit ("Kobold Vermin
-- slain: 3/10"), finished ones left out.
PARTS.questProgress = {
    label = L["Quest Progress"],
    requires = { "tooltipLines" },
    read = function(ctx)
        local list = {}
        for index, line in ipairs(ctx:tooltipLines()) do
            if line.type == LINE_QUEST_OBJECTIVE and line.completed ~= true then
                tinsert(list, token("questProgress:" .. index, line.text))
            end
        end
        return list
    end,
}

PARTS.tapped = {
    label = L["Tapped by Others"],
    requires = { "UnitIsTapDenied" },
    read = function(ctx)
        return ctx:flag("UnitIsTapDenied") and token("tapped", L["Tapped by Others"]) or nil
    end,
}

PARTS.charmed = {
    label = L["Charmed"],
    requires = { "UnitIsCharmed" },
    read = function(ctx)
        return ctx:flag("UnitIsCharmed") and token("charmed", L["Charmed"]) or nil
    end,
}

PARTS.combat = {
    label = L["Target in Combat"],
    requires = { "UnitAffectingCombat" },
    read = function(ctx)
        return ctx:flag("UnitAffectingCombat") and token("combat", L["In Combat"]) or nil
    end,
}

PARTS.dead = {
    label = L["Dead"],
    playerLabel = L["Dead or Ghost"],
    requires = { "UnitIsDead" },
    read = function(ctx)
        if ctx.category == "player" and ctx:flag("UnitIsGhost") then
            return token("dead", L["Ghost"])
        end
        return ctx:flag("UnitIsDead") and token("dead", L["Dead"]) or nil
    end,
}

-- ---------------------------------------------------------------------------
-- Order and defaults per category: { part, inCombat default, outOfCombat
-- default }. The order is the spoken order; the grouping key of adjacent
-- tokens joins them with a space ("Level 30 Elite", "Human Warrior"),
-- everything else with a comma.
-- ---------------------------------------------------------------------------

targetNames.ORDER = {
    player = {
        { "name", true, true },
        { "title", false, true },
        { "realm", false, false },
        { "guild", false, true },
        { "level", false, true },
        { "race", false, true },
        { "class", true, true },
        { "sex", false, false },
        { "faction", false, false },
        { "role", false, false },
        { "pvp", false, false },
        { "afk", false, false },
        { "dnd", false, false },
        { "charmed", true, false },
        { "combat", false, false },
        { "dead", true, true },
    },
    npc = {
        { "name", true, true },
        { "title", false, true },
        { "level", false, true },
        { "classification", false, false },
        { "rare", false, true },
        { "elite", false, true },
        { "boss", false, true },
        { "creatureType", false, false },
        { "creatureFamily", false, false },
        { "reaction", false, false },
        { "questBoss", false, false },
        { "quest", false, true },
        { "questProgress", false, true },
        { "combat", false, false },
        { "dead", true, true },
    },
    mob = {
        { "name", true, true },
        { "title", false, true },
        { "level", true, true },
        { "classification", false, false },
        { "rare", true, true },
        { "elite", true, true },
        { "boss", true, true },
        { "creatureType", false, true },
        { "creatureFamily", false, false },
        { "reaction", false, true },
        { "questBoss", false, true },
        { "quest", false, true },
        { "questProgress", false, true },
        { "tapped", false, true },
        { "charmed", false, false },
        { "combat", false, false },
        { "dead", true, true },
    },
    pet = {
        { "name", true, true },
        { "owner", true, true },
        { "level", false, true },
        { "creatureType", false, false },
        { "creatureFamily", false, true },
        { "reaction", false, false },
        { "combat", false, false },
        { "dead", true, true },
    },
    totem = {
        { "name", true, true },
        { "owner", true, true },
        { "reaction", false, false },
    },
}

local STATE_INDEX = { inCombat = 2, outOfCombat = 3 }

function targetNames.stateKey(inCombat)
    return inCombat and "inCombat" or "outOfCombat"
end

function targetNames.defaultFor(stateKey, category, partKey)
    for _, entry in ipairs(targetNames.ORDER[category] or {}) do
        if entry[1] == partKey then
            return entry[STATE_INDEX[stateKey]] == true
        end
    end
    return false
end

-- Whether the game offers what a part needs. A player's title reads the
-- full name, every other title the tooltip.
function targetNames.available(api, partKey, category)
    local part = PARTS[partKey]
    if part == nil then
        return false
    end
    local requires = part.requires
    if category == "player" and part.playerRequires ~= nil then
        requires = part.playerRequires
    end
    for _, name in ipairs(requires) do
        if api[name] == nil then
            return false
        end
    end
    return true
end

-- The parts on for one category in one state: the saved choice, else the
-- default (a saved table that predates a part).
function targetNames.enabledParts(stateTable, stateKey, category)
    local saved = type(stateTable) == "table" and stateTable[category] or nil
    local enabled = {}
    for _, entry in ipairs(targetNames.ORDER[category] or {}) do
        -- No and-or here: a saved false must stay false.
        local value = nil
        if type(saved) == "table" then
            value = saved[entry[1]]
        end
        if value == nil then
            value = entry[STATE_INDEX[stateKey]]
        end
        enabled[entry[1]] = value == true
    end
    return enabled
end

-- Joins tokens: a comma between facts, a space inside a group.
local function join(tokens)
    local text = ""
    local previousGroup = nil
    for index, item in ipairs(tokens) do
        if index == 1 then
            text = item.text
        elseif item.group ~= nil and item.group == previousGroup then
            text = text .. " " .. item.text
        else
            text = text .. ", " .. item.text
        end
        previousGroup = item.group
    end
    return text
end

local function collect(list, result)
    if result == nil then
        return
    end
    if result.key ~= nil then
        tinsert(list, result)
        return
    end
    for _, item in ipairs(result) do
        if item ~= nil then
            tinsert(list, item)
        end
    end
end

-- The announcement for a unit with the given state's parts, or nil when
-- the unit has no category (none, or a game object). "" when every part is
-- off or has nothing to say.
function targetNames.compose(api, unit, stateKey, stateTable)
    local category = targetNames.classify(api, unit)
    if category == nil then
        return nil
    end
    local ctx = newContext(api, unit, category)
    ctx.enabled = targetNames.enabledParts(stateTable, stateKey, category)
    local tokens = {}
    local seenKeys, seenTexts = {}, {}
    for _, entry in ipairs(targetNames.ORDER[category]) do
        local partKey = entry[1]
        if ctx.enabled[partKey] and targetNames.available(api, partKey, category) then
            local found = {}
            collect(found, PARTS[partKey].read(ctx))
            for _, item in ipairs(found) do
                local duplicate = seenKeys[item.key]
                if not duplicate and not isSecret(item.text) then
                    duplicate = seenTexts[item.text]
                end
                if not duplicate then
                    tinsert(tokens, item)
                    seenKeys[item.key] = true
                    if not isSecret(item.text) then
                        seenTexts[item.text] = true
                    end
                    for _, covered in ipairs(item.covers or {}) do
                        seenKeys[covered] = true
                    end
                end
            end
        end
    end
    return join(tokens), category
end

-- The announcement for the player's current combat state, or nil when the
-- configured announcement is off or the unit has no category (the caller
-- then speaks the full tooltip as before).
function targetNames.describe(api, unit, names)
    if type(names) ~= "table" or names.enabled == false then
        return nil
    end
    local inCombat = api.playerInCombat ~= nil and api.playerInCombat()
    if isSecret(inCombat) then
        inCombat = false
    end
    local stateKey = targetNames.stateKey(inCombat == true)
    return targetNames.compose(api, unit, stateKey, names[stateKey])
end

-- A plain-text report for /wv targetinfo: the category, the combat state,
-- what every part of the category reads for the unit (on or off, offered or
-- not), the tooltip's lines with their types, and the announcement. Secret
-- values show as <secret>: they cannot be printed or measured.
local function plain(text)
    if text == nil then
        return "-"
    end
    if isSecret(text) then
        return "<secret>"
    end
    return tostring(text)
end

function targetNames.report(api, unit, names)
    local lines = {}
    local category = targetNames.classify(api, unit)
    tinsert(lines, "unit " .. tostring(unit) .. ", category " .. tostring(category))
    local inCombat = api.playerInCombat ~= nil and api.playerInCombat()
    local stateKey = targetNames.stateKey(inCombat == true and not isSecret(inCombat))
    tinsert(lines, "state " .. stateKey .. ", configured announcement " .. tostring(not (type(names) == "table" and names.enabled == false)))
    if category == nil then
        return lines
    end
    local stateTable = type(names) == "table" and names[stateKey] or nil
    local enabled = targetNames.enabledParts(stateTable, stateKey, category)
    local ctx = newContext(api, unit, category)
    -- Every part reads as if on, the title on too, to show what it would say.
    ctx.enabled = setmetatable({}, { __index = function() return true end })
    for _, entry in ipairs(targetNames.ORDER[category]) do
        local partKey = entry[1]
        local offered = targetNames.available(api, partKey, category)
        local spoken = {}
        if offered then
            local found = {}
            collect(found, PARTS[partKey].read(ctx))
            for _, item in ipairs(found) do
                tinsert(spoken, plain(item.text))
            end
        end
        tinsert(
            lines,
            partKey
                .. " ["
                .. (enabled[partKey] and "on" or "off")
                .. (offered and "" or ", not offered")
                .. "]: "
                .. (#spoken > 0 and table.concat(spoken, " / ") or "-")
        )
    end
    for index, line in ipairs(ctx:tooltipLines()) do
        tinsert(
            lines,
            "tooltip line " .. index .. " type " .. tostring(line.type) .. ": " .. plain(line.text)
                .. (line.completed and " (completed)" or "")
        )
    end
    local text = targetNames.compose(api, unit, stateKey, stateTable)
    tinsert(lines, "announcement: " .. plain(text))
    return lines
end

-- Every part of one state back to its default, in place: the tables keep
-- their identity, so the saved settings follow.
function targetNames.reset(stateTable, stateKey)
    for _, category in ipairs(targetNames.CATEGORIES) do
        local saved = stateTable[category.key]
        if type(saved) ~= "table" then
            saved = {}
            stateTable[category.key] = saved
        end
        for _, entry in ipairs(targetNames.ORDER[category.key]) do
            saved[entry[1]] = entry[STATE_INDEX[stateKey]] == true
        end
    end
end

-- ---------------------------------------------------------------------------
-- Settings: Names, with the master switch, then one sub-screen per combat
-- state, one per category, one checkbox per part the game offers.
-- ---------------------------------------------------------------------------

-- Nested categories live in plain tables: a missing one is created in place
-- so the checkboxes below it write into the saved settings.
local function nestedTable(obj, key)
    local value = obj[key]
    if type(value) ~= "table" then
        value = {}
        obj[key] = value
    end
    return value
end

-- The reset button on each combat state's screen: a field type with no
-- value, drawn as a button that puts that state's parts back to their
-- defaults.
targetNames.RESET_FIELD_TYPE = "TargetNamesReset"
WowVision.classes.registerFieldType(targetNames.RESET_FIELD_TYPE, {})

function targetNames.registerResetControl(graph)
    graph.settings.registerFieldControl(targetNames.RESET_FIELD_TYPE, function(field, owner)
        return graph.nodes.button({
            label = field:getLabel(),
            onActivate = function()
                targetNames.reset(owner, field.state)
                WowVision:speak(L["Defaults restored"])
            end,
        })
    end)
end

if WowVision.graph ~= nil and WowVision.graph.settings ~= nil then
    targetNames.registerResetControl(WowVision.graph)
end

function targetNames.settingsDef(api)
    local stateDefs = {}
    for _, state in ipairs(targetNames.STATES) do
        local categoryDefs = {}
        for _, category in ipairs(targetNames.CATEGORIES) do
            local partDefs = {}
            for _, entry in ipairs(targetNames.ORDER[category.key]) do
                local part = PARTS[entry[1]]
                local label = part.label
                if category.key == "player" and part.playerLabel ~= nil then
                    label = part.playerLabel
                end
                tinsert(partDefs, {
                    key = entry[1],
                    type = "Bool",
                    label = label,
                    default = entry[STATE_INDEX[state.key]] == true,
                    showInUI = targetNames.available(api, entry[1], category.key),
                })
            end
            tinsert(categoryDefs, {
                key = category.key,
                type = "Category",
                label = category.label,
                get = nestedTable,
                fields = partDefs,
            })
        end
        tinsert(categoryDefs, {
            key = "reset",
            type = targetNames.RESET_FIELD_TYPE,
            label = L["Reset to Defaults"],
            state = state.key,
        })
        tinsert(stateDefs, {
            key = state.key,
            type = "Category",
            label = state.label,
            get = nestedTable,
            fields = categoryDefs,
        })
    end
    local fields = {
        {
            key = "enabled",
            type = "Bool",
            label = L["Configured Target Announcement"],
            default = false,
        },
    }
    for _, def in ipairs(stateDefs) do
        tinsert(fields, def)
    end
    return {
        key = "names",
        type = "Category",
        label = L["Names"],
        fields = fields,
    }
end
