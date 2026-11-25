-- Everything the loot browser asks of the game, of AtlasLoot and of WowVision, in one table, so the tests can replace
-- it.
local ns = WowVision.atlasLoot

local Game = {}
ns.Game = Game

-- The name of the WowVision window this addon opens.
Game.WINDOW = "atlasLoot"

local DEFAULTS = {
    classFilter = true, -- only what the player's class can use
    levelFilter = false, -- only what the player's level allows
    upgradesOnly = false, -- only what would be an upgrade over what the player wears
    measure = "auto", -- who judges the upgrades: auto (Gear Judge, else Pawn, else item level), judge, pawn or level
    sort = "default", -- how the loot is ordered (Loot.SORTS)
    openWithAl = true, -- AtlasLoot's own window opening (/al) opens this screen too
}
Game.defaults = DEFAULTS

-- An error here must never break a key, and must not repeat on every press either: each distinct message once.
local reported = {}
function Game.report(err)
    err = tostring(err)
    if reported[err] then
        return
    end
    reported[err] = true
    geterrorhandler()("AtlasLoot browser: " .. err)
end

function Game.guarded(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            Game.report(err)
        end
    end
end

function Game.speak(text)
    if text == nil or text == "" then
        return
    end
    local wowVision = rawget(_G, "WowVision")
    if wowVision ~= nil and wowVision.speak ~= nil then
        wowVision:speak(text)
    else
        print(text)
    end
end

-- ---------------------------------------------------------------- settings

-- The module's settings (module.lua), whose defaults are the ones above.
local function store()
    return ns.settings or {}
end

function Game.getSetting(key)
    local value = store()[key]
    if value == nil then
        return DEFAULTS[key]
    end
    return value
end

function Game.setSetting(key, value)
    store()[key] = value
end

-- --------------------------------------------------------------- AtlasLoot

-- AtlasLoot's global table, nil when no AtlasLoot is installed and enabled (both of the AtlasLoot addons that exist
-- for WoW: Forever call it AtlasLoot).
function Game.atlas()
    local atlas = rawget(_G, "AtlasLoot")
    if type(atlas) ~= "table" or type(atlas.ItemDB) ~= "table" or type(atlas.Loader) ~= "table" then
        return nil
    end
    return atlas
end

-- AtlasLoot's own window, once AtlasLoot has built it.
function Game.atlasFrame()
    return rawget(_G, "AtlasLoot_GUI-Frame")
end

-- ----------------------------------------------------------------- player

function Game.playerClass()
    if UnitClassBase ~= nil then
        local ok, token = pcall(UnitClassBase, "player")
        if ok and token ~= nil then
            return token
        end
    end
    local _, token = UnitClass("player")
    return token
end

function Game.playerLevel()
    return UnitLevel("player")
end

-- "Horde" or "Alliance"
function Game.faction()
    return (UnitFactionGroup("player"))
end

function Game.inCombat()
    return InCombatLockdown ~= nil and InCombatLockdown() == true
end

-- ------------------------------------------------------------------ items

local function itemApi()
    return rawget(_G, "C_Item")
end

-- What the game knows of an item at once, without asking the server: type, sub type, equip location (as the game's
-- words), and the number of the type and of the sub type (classID, subClassID).
local function instantFacts(id)
    local c = itemApi()
    local instant = c ~= nil and c.GetItemInfoInstant or rawget(_G, "GetItemInfoInstant")
    if instant == nil then
        return nil
    end
    local ok, _, itemType, subType, equipLoc, _, classID, subClassID = pcall(instant, id)
    if ok then
        return itemType, subType, equipLoc, classID, subClassID
    end
    return nil
end

-- What the game says of an item: name, link, quality, level, minLevel, type, subType, equipLoc, classID, subClassID, and
-- cached (the name has come). The type, the sub type and the slot are known at once; the rest comes a moment after the
-- first ask.
function Game.itemInfo(id)
    local c = itemApi()
    local info = { id = id }
    local getInfo = c ~= nil and c.GetItemInfo or rawget(_G, "GetItemInfo")
    if getInfo ~= nil then
        local ok, name, link, quality, level, minLevel, itemType, subType, _, equipLoc, _, _, classID, subClassID = pcall(getInfo, id)
        if ok and name ~= nil then
            info.name, info.link, info.quality, info.level, info.minLevel = name, link, quality, level, minLevel
            info.type, info.subType, info.equipLoc = itemType, subType, equipLoc
            info.classID, info.subClassID = classID, subClassID
            if classID == nil then
                -- a client whose GetItemInfo does not give the numbers: the instant answer does
                local _, _, _, instantClass, instantSub = instantFacts(id)
                info.classID, info.subClassID = instantClass, instantSub
            end
            info.cached = true
            return info
        end
    end
    local itemType, subType, equipLoc, classID, subClassID = instantFacts(id)
    info.type, info.subType, info.equipLoc, info.classID, info.subClassID = itemType, subType, equipLoc, classID, subClassID
    info.cached = false
    Game.requestItem(id)
    return info
end

local requested = {}
function Game.requestItem(id)
    if requested[id] then
        return
    end
    requested[id] = true
    local c = itemApi()
    if c ~= nil and c.RequestLoadItemDataByID ~= nil then
        pcall(c.RequestLoadItemDataByID, id)
    end
end

-- The name of an item when the game already has it, nil when it does not: it asks the server nothing (a search looks at
-- thousands of items, and asking for them all at once would flood it; Index:request asks a few at a time).
function Game.itemName(id)
    local c = itemApi()
    local isCached = c ~= nil and c.IsItemDataCachedByID or nil
    if isCached ~= nil then
        local ok, cached = pcall(isCached, id)
        if ok and cached == false then
            return nil
        end
    end
    local getInfo = c ~= nil and c.GetItemInfo or rawget(_G, "GetItemInfo")
    if getInfo == nil then
        return nil
    end
    local ok, name = pcall(getInfo, id)
    if ok and type(name) == "string" and name ~= "" then
        return name
    end
    return nil
end

-- The items the server answered it does not know (GET_ITEM_INFO_RECEIVED with success false): their name never comes.
local failed = {}

function Game.itemReceived(id, success)
    if id ~= nil and success == false then
        failed[id] = true
    end
end

function Game.itemFailed(id)
    return failed[id] == true
end

-- The armor types each class wears, and from which level (the classic rules: a hunter or a shaman wears cloth and
-- leather until level 40 and mail from it, a warrior or a paladin wears mail until level 40 and plate from it). The keys
-- of the inner tables are the game's armor sub class numbers: 1 cloth, 2 leather, 3 mail, 4 plate. AtlasLoot's own class
-- filter knows only the type a class ends with, so it shows a shaman mail from level 1 and no leather at all.
local ARMOR_FROM = {
    PRIEST = { [1] = 1 },
    MAGE = { [1] = 1 },
    WARLOCK = { [1] = 1 },
    ROGUE = { [1] = 1, [2] = 1 },
    DRUID = { [1] = 1, [2] = 1 },
    HUNTER = { [1] = 1, [2] = 1, [3] = 40 },
    SHAMAN = { [1] = 1, [2] = 1, [3] = 40 },
    WARRIOR = { [1] = 1, [2] = 1, [3] = 1, [4] = 40 },
    PALADIN = { [1] = 1, [2] = 1, [3] = 1, [4] = 40 },
    DEATHKNIGHT = { [1] = 1, [2] = 1, [3] = 1, [4] = 1 },
}

-- Whether the class wears that armor type at that level: true or false, nil when this addon has no rule for the class
-- or the level is not known (AtlasLoot's answer then stands).
function Game.armorWearable(class, level, subClassID)
    local rules = ARMOR_FROM[class]
    if rules == nil or type(level) ~= "number" then
        return nil
    end
    local from = rules[subClassID]
    if from == nil then
        return false
    end
    return level >= from
end

-- AtlasLoot's names of a stat in the class filter's settings: the game's key with "_SHORT", with two exceptions.
local LINKED_EXCEPTIONS = {
    ITEM_MOD_SPELL_HEALING = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
    ITEM_MOD_SPELL_DAMAGE = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",
}

local function linkedStat(stat)
    if stat:sub(-6) == "_SHORT" then
        return stat
    end
    return LINKED_EXCEPTIONS[stat] or (stat .. "_SHORT")
end

-- AtlasLoot's class filter without the armor type: the class restriction written on the item, and the stats the player
-- told AtlasLoot the class does not want (its options, per class). Used for an armor piece whose type the player wears now
-- but AtlasLoot, who knows only the type the class ends with, turned down.
local function otherRulesAllow(atlas, class, id)
    local requirements = atlas.Data ~= nil and atlas.Data.Requirements or nil
    if requirements ~= nil and type(requirements.ClassCanUseItem) == "function" then
        local ok, result = pcall(requirements.ClassCanUseItem, class, id)
        if ok and result == false then
            return false
        end
    end
    local settings = type(atlas.db) == "table" and atlas.db.ClassFilter or nil
    local wanted = type(settings) == "table" and settings[class] or nil
    local c = itemApi()
    local getStats = c ~= nil and c.GetItemStats or rawget(_G, "GetItemStats")
    if type(wanted) == "table" and getStats ~= nil then
        local ok, stats = pcall(getStats, type(id) == "string" and id or ("item:" .. id))
        if ok and type(stats) == "table" then
            for stat in pairs(stats) do
                if type(stat) == "string" and (wanted[stat] == false or wanted[linkedStat(stat)] == false) then
                    return false
                end
            end
        end
    end
    return true
end

-- Whether the class can use the item now: AtlasLoot's own question (armor and weapon types, class restrictions, stats),
-- except that the armor type is the one the player wears at this level, not the one the class ends with.
function Game.canUse(id)
    local atlas = Game.atlas()
    local filter = atlas ~= nil and atlas.Data ~= nil and atlas.Data.ClassFilter or nil
    if filter == nil or type(filter.ClassCanUseItem) ~= "function" then
        return true
    end
    local class = Game.playerClass()
    local ok, result = pcall(filter.ClassCanUseItem, class, id)
    local atlasSays = not ok or result ~= false
    local _, _, _, classID, subClassID = instantFacts(id)
    if classID == 4 and type(subClassID) == "number" and subClassID >= 1 and subClassID <= 4 then
        local wearable = Game.armorWearable(class, Game.playerLevel(), subClassID)
        if wearable == false then
            return false
        elseif wearable == true and not atlasSays then
            return otherRulesAllow(atlas, class, id)
        end
    end
    return atlasSays
end

-- -------------------------------------------------------------- equipment

-- What the player wears decides what is an upgrade, and the answers are kept: each change of equipment (and each opening
-- of the screen) makes them be asked again.
local gear = 0

function Game.gearVersion()
    return gear
end

function Game.gearChanged()
    gear = gear + 1
end

local SLOTS = {
    INVTYPE_HEAD = { 1 },
    INVTYPE_NECK = { 2 },
    INVTYPE_SHOULDER = { 3 },
    INVTYPE_CHEST = { 5 },
    INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 },
    INVTYPE_WRIST = { 9 },
    INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16, 17 },
    INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 },
    INVTYPE_SHIELD = { 17 },
    INVTYPE_HOLDABLE = { 17 },
}
local RANGED = { INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true, INVTYPE_RELIC = true }

local function inventoryLink(slot)
    if GetInventoryItemLink == nil then
        return nil
    end
    local ok, link = pcall(GetInventoryItemLink, "player", slot)
    if ok and type(link) == "string" and link ~= "" then
        return link
    end
    return nil
end

-- The inventory slots an item of this equip location goes into, nil when it is not gear (a bag, ammo, a tabard). WowVision's
-- own answer when it has one (it also knows the ranged slot, and when a one-hand weapon goes to the off hand).
local function compareSlots(equipLoc)
    if equipLoc == nil or equipLoc == "" then
        return nil
    end
    local wowVision = rawget(_G, "WowVision")
    local items = wowVision ~= nil and wowVision.items or nil
    if items ~= nil and type(items.compareSlots) == "function" then
        local ok, slots = pcall(items.compareSlots, equipLoc)
        if ok then
            return slots
        end
    end
    if RANGED[equipLoc] then
        local getSlot = rawget(_G, "GetInventorySlotInfo")
        if getSlot ~= nil then
            local ok, slot = pcall(getSlot, "RANGEDSLOT")
            if ok and slot ~= nil then
                return { slot }
            end
        end
        return nil
    end
    return SLOTS[equipLoc]
end

-- The item level of an item (its id or its link) as the game counts it, nil when it does not say.
function Game.itemLevelOf(ref)
    local c = itemApi()
    local detailed = c ~= nil and c.GetDetailedItemLevelInfo or rawget(_G, "GetDetailedItemLevelInfo")
    if detailed ~= nil then
        local ok, level = pcall(detailed, ref)
        if ok and type(level) == "number" and level > 0 then
            return level
        end
    end
    -- a client without that function (or with no answer yet) still says the item's own level
    local plain = c ~= nil and c.GetItemInfo or rawget(_G, "GetItemInfo")
    if plain ~= nil then
        local ok, _, _, _, level = pcall(plain, ref)
        if ok and type(level) == "number" and level > 0 then
            return level
        end
    end
    return nil
end

-- What the player wears where an item of this equip location would go: nil when it is not gear, else one entry per slot,
-- { empty = true } or { id, level }.
function Game.wornSlots(equipLoc)
    local slots = compareSlots(equipLoc)
    if slots == nil then
        return nil
    end
    local out = {}
    for _, slot in ipairs(slots) do
        local link = inventoryLink(slot)
        if link == nil then
            out[#out + 1] = { empty = true }
        else
            local ok, id = pcall(function()
                return tonumber(link:match("item:(%d+)"))
            end)
            out[#out + 1] = { id = ok and id or nil, level = Game.itemLevelOf(link) }
        end
    end
    return out
end

-- Whether Pawn is there with at least one scale shown for the player: then it judges what is an upgrade.
local pawnAnswer = { version = -1 }
function Game.pawnReady()
    if pawnAnswer.version == gear then
        return pawnAnswer.ready
    end
    pawnAnswer.version = gear
    local ready = false
    local common = rawget(_G, "PawnCommon")
    if
        type(rawget(_G, "PawnGetItemData")) == "function"
        and type(rawget(_G, "PawnIsItemAnUpgrade")) == "function"
        and type(common) == "table"
        and type(common.Scales) == "table"
    then
        local visible = rawget(_G, "PawnIsScaleVisible")
        for name in pairs(common.Scales) do
            local ok, shown = true, true
            if type(visible) == "function" then
                ok, shown = pcall(visible, name)
            end
            if ok and shown then
                ready = true
                break
            end
        end
    end
    pawnAnswer.ready = ready
    return ready
end

-- Pawn's judgement of an item (its link): nil when Pawn has no data on it yet, false when it is no upgrade for any of the
-- player's scales, else { percent = the best upgrade as a fraction, big = true when Pawn calls it big }.
function Game.pawnUpgrade(link)
    local getItem, isUpgrade = rawget(_G, "PawnGetItemData"), rawget(_G, "PawnIsItemAnUpgrade")
    if type(getItem) ~= "function" or type(isUpgrade) ~= "function" then
        return nil
    end
    local ok, item = pcall(getItem, link)
    if not ok or type(item) ~= "table" then
        return nil
    end
    local ok2, upgrades = pcall(isUpgrade, item)
    if not ok2 then
        Game.report(upgrades)
        return false
    end
    if type(upgrades) ~= "table" or #upgrades == 0 then
        return false
    end
    local best
    for _, upgrade in ipairs(upgrades) do
        local percent = upgrade.PercentUpgrade
        if type(percent) ~= "number" then
            percent = math.huge
        end
        if best == nil or percent > best then
            best = percent
        end
    end
    if best >= (rawget(_G, "PawnBigUpgradeThreshold") or 100) then
        return { big = true }
    end
    return { percent = best }
end

-- Sharpie's Gear Judge's public interface (SGJ_API_Info.md of that addon); nil when it is not installed and enabled.
local function judgeApi()
    local api = rawget(_G, "SharpiesGearJudgeAPI")
    return type(api) == "table" and api or nil
end

-- Whether the Gear Judge is there and has finished loading: then it can judge what is an upgrade.
local judgeAnswer = { version = -1 }
function Game.judgeReady()
    if judgeAnswer.version == gear then
        return judgeAnswer.ready
    end
    judgeAnswer.version = gear
    local api = judgeApi()
    local ready = false
    if api ~= nil and type(api.ScoreItem) == "function" then
        ready = true
        if type(api.IsReady) == "function" then
            local ok, answer = pcall(api.IsReady)
            ready = not ok or answer ~= false
        end
    end
    judgeAnswer.ready = ready
    return ready
end

-- The Gear Judge's judgement of an item (its link): a table (upgradePct, upgrade, equipped, equippedLink...) or nil and
-- the Judge's reason (NOT_CACHED, NOT_READY, NOT_USABLE, NOT_EQUIPPABLE, BAD_LINK, ERROR; MISSING when it is not there).
function Game.judgeScore(link)
    local api = judgeApi()
    if api == nil or type(api.ScoreItem) ~= "function" then
        return nil, "MISSING"
    end
    local ok, result, reason = pcall(api.ScoreItem, link)
    if not ok then
        Game.report(result)
        return nil, "ERROR"
    end
    if type(result) ~= "table" then
        return nil, reason or "ERROR"
    end
    return result
end

-- Who judges the upgrades: what the player chose (the "measure" setting), or what there is. "judge" and "auto" take the
-- Gear Judge when it is ready, then Pawn when it is ready, then the item level; "pawn" takes Pawn, then the item level;
-- "level" the item level. Returns "judge", "pawn" or "level".
function Game.upgradeMeasure()
    local wanted = Game.getSetting("measure")
    if wanted == "level" then
        return "level"
    end
    if wanted ~= "pawn" and Game.judgeReady() then
        return "judge"
    end
    if Game.pawnReady() then
        return "pawn"
    end
    return "level"
end

-- The language of the game's client ("frFR"), for the way numbers are spoken.
function Game.locale()
    return GetLocale ~= nil and GetLocale() or "enUS"
end

-- How often the creature drops the item, in percent, when AtlasLoot knows.
function Game.droprate(npcID, itemId)
    local atlas = Game.atlas()
    local data = atlas ~= nil and atlas.Data ~= nil and atlas.Data.Droprate or nil
    if data == nil or type(data.GetData) ~= "function" or npcID == nil then
        return nil
    end
    local id = npcID
    if type(id) == "table" then
        id = id[1]
    end
    local ok, rate = pcall(data.GetData, data, id, itemId)
    if ok and rate ~= nil and rate ~= "" then
        return rate
    end
    return nil
end

-- The name of an AtlasLoot item set, and its items.
function Game.setName(setId)
    local atlas = Game.atlas()
    local data = atlas ~= nil and atlas.Data ~= nil and atlas.Data.ItemSet or nil
    if data == nil or type(data.GetSetName) ~= "function" then
        return nil
    end
    local ok, name = pcall(data.GetSetName, setId, true)
    if ok then
        return name
    end
    return nil
end

function Game.setItems(setId)
    local atlas = Game.atlas()
    local data = atlas ~= nil and atlas.Data ~= nil and atlas.Data.ItemSet or nil
    if data == nil or type(data.GetSetItems) ~= "function" then
        return nil
    end
    local ok, items = pcall(data.GetSetItems, setId)
    if ok and type(items) == "table" then
        return items
    end
    return nil
end

-- "Head", "Two-Hand"... the game's own word for an equipment slot, nil for a non-equipment.
function Game.slotName(equipLoc)
    if equipLoc == nil or equipLoc == "" then
        return nil
    end
    local word = rawget(_G, equipLoc)
    if type(word) == "string" and word ~= "" then
        return word
    end
    return nil
end

function Game.qualityName(quality)
    if quality == nil then
        return nil
    end
    local word = rawget(_G, "ITEM_QUALITY" .. quality .. "_DESC")
    if type(word) == "string" then
        return word
    end
    return nil
end

function Game.className(token)
    local names = rawget(_G, "LOCALIZED_CLASS_NAMES_MALE")
    if type(names) == "table" and names[token] ~= nil then
        return names[token]
    end
    return nil
end

-- --------------------------------------------------------------- WowVision

local function host()
    local wowVision = rawget(_G, "WowVision")
    return wowVision ~= nil and wowVision.UIHost or nil
end

function Game.isOpen()
    local current = host()
    local manager = current ~= nil and current.windowManager or nil
    if manager == nil then
        return false
    end
    for _, instance in ipairs(manager.openWindows) do
        if instance.name == Game.WINDOW then
            return true
        end
    end
    return false
end

-- Opens the frameless graph window. screen is the graphScreen config (render, captureClose...).
function Game.open(screen)
    local current = host()
    if current == nil then
        return false
    end
    current:openTemporaryWindow({ name = Game.WINDOW, graphScreen = screen })
    return true
end

function Game.close()
    local current = host()
    if current ~= nil then
        current:closeWindow(Game.WINDOW)
    end
end

-- SPACE's reading of the focused entry's tooltip (the key's own action), for Enter on an item.
function Game.speakTooltip()
    local current = host()
    local tooltip = current ~= nil and current.tooltip or nil
    if tooltip ~= nil and type(tooltip.speak) == "function" then
        pcall(tooltip.speak, tooltip)
        return true
    end
    return false
end

function Game.defer(fn)
    if C_Timer ~= nil and C_Timer.After ~= nil then
        C_Timer.After(0, fn)
    else
        fn()
    end
end
