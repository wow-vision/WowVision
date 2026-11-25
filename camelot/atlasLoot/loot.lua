-- Reads AtlasLoot's loot tables as plain lists, and decides what the filters show and what each line says. It never
-- touches AtlasLoot's window: the tables are AtlasLoot's own (AtlasLoot.ItemDB), read as its window reads them.
-- Everything the game must answer goes through `game` (ns.Game, replaced by the tests).
local ns = WowVision.atlasLoot
local L = ns.L

local Loot = {}
ns.Loot = Loot

-- AtlasLoot's marks inside an entry of a loot table (AtlasLoot's Constants.lua).
local IT_FILTERIGNORE, IT_HORDE, IT_ALLIANCE = 900, 901, 902

-- The text of a name as it is spoken: textures, colors and line breaks taken out.
function Loot.clean(text)
    if type(text) ~= "string" then
        return ""
    end
    text = text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", " ")
    text = text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    return text
end

local function call(object, method, ...)
    if type(object) ~= "table" or type(object[method]) ~= "function" then
        return false
    end
    return pcall(object[method], object, ...)
end

-- ------------------------------------------------------------- categories

-- AtlasLoot's loot modules, as its own window lists them: { id = addon name, name = spoken name }.
function Loot.modules(atlas)
    local list = {}
    local ok, data = call(atlas.Loader, "GetLootModuleList")
    if not ok or type(data) ~= "table" then
        return list
    end
    for _, group in ipairs({ data.module or {}, data.custom or {} }) do
        for _, entry in ipairs(group) do
            if entry.addonName ~= nil then
                local name = Loot.clean(entry.name)
                list[#list + 1] = { id = entry.addonName, name = name ~= "" and name or entry.addonName }
            end
        end
    end
    return list
end

-- Brings a module's tables in (they are loaded on demand). Returns "ready", data | "combat" | "disabled" | "missing".
function Loot.open(atlas, id)
    local data = atlas.ItemDB:Get(id)
    if data ~= nil then
        return "ready", data
    end
    local ok, result = call(atlas.Loader, "LoadModule", id)
    data = atlas.ItemDB:Get(id)
    if data ~= nil then
        return "ready", data
    end
    if ok and result == "InCombat" then
        return "combat"
    elseif ok and (result == "DISABLED") then
        return "disabled"
    end
    return "missing"
end

-- ---------------------------------------------------------------- versions

-- The game versions a module has tables for, in order (Classic, Burning Crusade...).
function Loot.versions(data)
    local out = {}
    local info = data.__atlaslootdata
    for version in pairs(type(info) == "table" and info.gameVersions or {}) do
        if version ~= 0 then
            out[#out + 1] = version
        end
    end
    table.sort(out)
    return out
end

-- The version the screen shows: the one asked for, else the one AtlasLoot's window is on, else the first there is.
function Loot.version(atlas, data, wanted)
    local versions = Loot.versions(data)
    for _, version in ipairs(versions) do
        if version == wanted then
            return wanted
        end
    end
    local gui = type(atlas.db) == "table" and atlas.db.GUI or nil
    local ok, version = call(data, "GetAviableGameVersion", gui ~= nil and gui.selectedGameVersion or nil)
    if ok and version ~= nil then
        return version
    end
    return versions[1] or 0
end

function Loot.versionName(atlas, version)
    if version == atlas.CLASSIC_VERSION_NUM then
        return L["Classic"]
    elseif version == atlas.BC_VERSION_NUM then
        return L["The Burning Crusade"]
    elseif version == atlas.WRATH_VERSION_NUM then
        return L["Wrath of the Lich King"]
    elseif atlas.FOREVER_VERSION_NUM ~= nil and version == atlas.FOREVER_VERSION_NUM then
        return L["WoW: Forever"]
    end
    return tostring(version)
end

-- --------------------------------------------------------------- instances

-- The dungeons, raids and other lists of a module for a game version, in AtlasLoot's groups:
-- { { name = group, list = { { key, name, levels = "10 to 18"? } } } }
function Loot.instances(atlas, id, data, version)
    local keys = atlas.ItemDB:GetModuleList(id)
    local _, types = call(data, "GetContentTypes")
    types = type(types) == "table" and types or {}
    local byType, order = {}, {}
    for _, key in ipairs(keys) do
        local content = data[key]
        if type(content) == "table" and (content.gameVersion == version or content.gameVersion == 0) then
            local okType, _, index = call(content, "GetContentType")
            if not okType or type(index) ~= "number" then
                index = 0
            end
            local named = content.name ~= nil or content.MapID ~= nil or content.AreaID ~= nil or content.FactionID ~= nil or content.AchievementID ~= nil
            local okName, name = call(content, "GetName", true)
            -- an instance AtlasLoot has no name for is listed by its key, not as "Unknown"
            name = (named and okName) and Loot.clean(name) or ""
            local range = content.LevelRange
            local levels
            if type(range) == "table" and range[2] ~= nil and range[3] ~= nil then
                levels = string.format(L["levels %d to %d"], range[2], range[3])
            end
            if byType[index] == nil then
                local group = types[index]
                byType[index] = {
                    name = type(group) == "table" and Loot.clean(group[1]) or L["Other"],
                    list = {},
                }
                order[#order + 1] = index
            end
            local list = byType[index].list
            list[#list + 1] = { key = key, name = name ~= "" and name or tostring(key), levels = levels }
        end
    end
    table.sort(order, function(a, b)
        if a == 0 or b == 0 then
            return b == 0 and a ~= 0
        end
        return a < b
    end)
    local groups = {}
    for _, index in ipairs(order) do
        groups[#groups + 1] = byType[index]
    end
    return groups
end

-- ------------------------------------------------------------------ bosses

-- The bosses of an instance, then its other lists (tier sets, keys, books...): { { index, name, extra, npcID } }.
function Loot.bosses(data, key)
    local out = {}
    local content = data[key]
    if type(content) ~= "table" or type(content.items) ~= "table" then
        return out
    end
    for index = 1, #content.items do
        local boss = content.items[index]
        if type(boss) == "table" then
            local ok, name = call(content, "GetNameForItemTable", index, true)
            name = ok and Loot.clean(name) or ""
            out[#out + 1] = {
                index = index,
                name = name ~= "" and name or string.format(L["List %d"], index),
                extra = boss.ExtraList == true,
                npcID = boss.npcID,
            }
        end
    end
    return out
end

-- The difficulties a boss has tables for: { { id, name } } (Normal, Heroic, 20 players...).
function Loot.difficulties(data, key, boss)
    local out = {}
    local ok, diffs = call(data, "GetDifficultys")
    local content = data[key]
    local bossData = type(content) == "table" and type(content.items) == "table" and content.items[boss] or nil
    if not ok or type(diffs) ~= "table" or type(bossData) ~= "table" then
        return out
    end
    for id = 1, #diffs do
        local table_ = bossData[id]
        if table_ ~= nil then
            local name = type(table_) == "table" and table_.diffName or diffs[id].name
            out[#out + 1] = { id = id, name = Loot.clean(name) }
        end
    end
    return out
end

-- The difficulty to show for what was asked: that one when the boss has it, else the nearest lower one, else the
-- first. (AtlasLoot's own GetDifficulty is not used: with a boss that has no table at all it never returns.)
function Loot.pickDifficulty(diffs, wanted)
    local best
    for _, diff in ipairs(diffs) do
        if diff.id == wanted then
            return wanted
        end
        if wanted ~= nil and diff.id < wanted then
            best = diff.id
        end
    end
    return best or (diffs[1] and diffs[1].id) or nil
end

-- A boss whose loot lives in another module: asks AtlasLoot to bring that module in and point the boss at it.
function Loot.resolve(atlas, id, key, boss)
    call(atlas.ItemDB, "CheckForLink", id, key, boss, true)
end

-- ------------------------------------------------------------------ entries

local function itemIdOf(ref)
    if type(ref) == "number" then
        return ref > 0 and ref or nil
    elseif type(ref) == "string" then
        local id = ref:match("^i(%d+)") or ref:match("^item:(%d+)")
        return id ~= nil and tonumber(id) or nil
    end
    return nil
end

local HEADER_PREFIXES = { "INV_", "ICON_", "ABILITY_", "ADDON_", "CLASS_", "SLOT_", "SPECIAL_" }

local function isHeaderRef(ref)
    if type(ref) ~= "string" then
        return false
    end
    for _, prefix in ipairs(HEADER_PREFIXES) do
        if ref:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

-- The two items of an entry for a player of that faction (AtlasLoot's marks: an entry hidden from one faction, or
-- another item for it), nil when the entry is not for them.
local function factionRefs(entry, faction)
    local horde, alliance = entry[IT_HORDE], entry[IT_ALLIANCE]
    if horde == nil and alliance == nil then
        return entry[2], entry[3]
    end
    local isHorde = faction == "Horde"
    if (alliance == false and not isHorde) or (horde == false and isHorde) then
        return nil
    end
    local used
    if isHorde then
        used = horde
    else
        used = alliance
    end
    if type(used) == "table" then
        return used[1], used[2]
    elseif used ~= nil and used ~= true then
        return used, entry[3]
    end
    return entry[2], entry[3]
end

local function headerName(ref, entry, game)
    local name = type(entry[4]) == "string" and Loot.clean(entry[4]) or ""
    if name == "" and type(ref) == "string" and ref:sub(1, 6) == "CLASS_" then
        name = game.className(ref:sub(7)) or ""
    end
    return name
end

-- The lines of one loot table, in AtlasLoot's order: { kind = "header", name } and
-- { kind = "item", id, pos, note?, npcID? }. tableType is AtlasLoot's description of the table's entries
-- (its first word: "Item" for a list of items, "Set" for a list of item sets).
function Loot.entries(items, tableType, game, npcID)
    local out = {}
    local formatType = type(tableType) == "table" and tableType[1] or "Item"
    local sorted = {}
    for _, entry in ipairs(items) do
        if type(entry) == "table" and type(entry[1]) == "number" and entry[999] == nil then
            sorted[#sorted + 1] = entry
        end
    end
    table.sort(sorted, function(a, b)
        return a[1] < b[1]
    end)
    local faction = game.faction()
    for _, entry in ipairs(sorted) do
        local first, second = factionRefs(entry, faction)
        if first ~= nil then
            if formatType == "Set" and type(first) == "number" then
                local name = game.setName(first)
                if name ~= nil and Loot.clean(name) ~= "" then
                    out[#out + 1] = { kind = "header", name = Loot.clean(name) }
                end
                for _, ref in ipairs(game.setItems(first) or {}) do
                    local id = itemIdOf(ref)
                    if id ~= nil then
                        out[#out + 1] = { kind = "item", id = id, pos = entry[1], npcID = npcID }
                    end
                end
            elseif isHeaderRef(first) then
                local name = headerName(first, entry, game)
                if name ~= "" then
                    out[#out + 1] = { kind = "header", name = name }
                end
            elseif formatType == "Item" then
                local note = type(entry[5]) == "string" and Loot.clean(entry[5]) or nil
                local id = itemIdOf(first)
                if id ~= nil then
                    out[#out + 1] = { kind = "item", id = id, pos = entry[1], note = note ~= "" and note or nil, npcID = npcID }
                end
                local other = itemIdOf(second)
                if other ~= nil then
                    out[#out + 1] = { kind = "item", id = other, pos = entry[1], npcID = npcID }
                end
            end
        end
    end
    return out
end

-- One boss's lines, for a difficulty: returns entries, nil | nil, "loading" | nil, "error", message.
function Loot.table(atlas, id, key, boss, diff, game, npcID)
    if diff == nil then
        -- no table at all for this boss (AtlasLoot's lookup would not return for it)
        return {}
    end
    call(atlas.ItemDB, "CheckForLink", id, key, boss)
    local ok, items, tableType = pcall(atlas.ItemDB.GetItemTable, atlas.ItemDB, id, key, boss, diff)
    if not ok then
        return nil, "error", items
    end
    if type(items) == "string" then
        -- the table lives in a module that is not loaded yet
        call(atlas.Loader, "LoadModule", items)
        return nil, "loading"
    end
    if type(items) ~= "table" then
        return {}
    end
    return Loot.entries(items, tableType, game, npcID)
end

-- ------------------------------------------------------------------ filters

-- Whether the class can use the item; asked once the game has the item's data, then kept until what the player wears
-- or his level changes (the armor he wears depends on the level).
local function usable(entry, game)
    local version = game.gearVersion()
    if entry.usableFinal and entry.usableVersion == version then
        return entry.usable
    end
    entry.usable = game.canUse(entry.id)
    entry.usableFinal = game.itemInfo(entry.id).cached == true
    entry.usableVersion = version
    return entry.usable
end

-- Whether the level allows the item; true while the game has not said what level it asks.
local function levelAllows(entry, game)
    local info = game.itemInfo(entry.id)
    return info.minLevel == nil or info.minLevel <= game.playerLevel()
end

-- ------------------------------------------------------------------- slots

-- The slot groups of the slot filter, in the order the player hears them. A group with no name of its own is spoken with
-- the game's word for its first equip location ("Head", "Back"...).
local SLOT_GROUPS = {
    { id = "head", locs = { "INVTYPE_HEAD" } },
    { id = "neck", locs = { "INVTYPE_NECK" } },
    { id = "shoulder", locs = { "INVTYPE_SHOULDER" } },
    { id = "cloak", locs = { "INVTYPE_CLOAK" } },
    { id = "chest", locs = { "INVTYPE_CHEST", "INVTYPE_ROBE" } },
    { id = "wrist", locs = { "INVTYPE_WRIST" } },
    { id = "hands", locs = { "INVTYPE_HAND" } },
    { id = "waist", locs = { "INVTYPE_WAIST" } },
    { id = "legs", locs = { "INVTYPE_LEGS" } },
    { id = "feet", locs = { "INVTYPE_FEET" } },
    { id = "finger", locs = { "INVTYPE_FINGER" } },
    { id = "trinket", locs = { "INVTYPE_TRINKET" } },
    {
        id = "weapons",
        locs = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND" },
        name = function()
            return L["Weapons"]
        end,
    },
    {
        id = "offhand",
        locs = { "INVTYPE_SHIELD", "INVTYPE_HOLDABLE" },
        name = function()
            return L["Shields and held in off hand"]
        end,
    },
    {
        id = "ranged",
        locs = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC" },
        name = function()
            return L["Ranged, thrown and relics"]
        end,
    },
    {
        id = "otherGear",
        name = function()
            return L["Other equipment"]
        end,
    },
    {
        id = "notGear",
        name = function()
            return L["Not equipment"]
        end,
    },
}

local SLOT_OF_LOC, SLOT_ORDER = {}, {}
for index, group in ipairs(SLOT_GROUPS) do
    SLOT_ORDER[group.id] = index
    for _, loc in ipairs(group.locs or {}) do
        SLOT_OF_LOC[loc] = group.id
    end
end

-- The slot group of an equip location: no equip location is not equipment, one the groups do not list is other equipment.
function Loot.slotGroup(equipLoc)
    if equipLoc == nil or equipLoc == "" then
        return "notGear"
    end
    return SLOT_OF_LOC[equipLoc] or "otherGear"
end

function Loot.slotLabel(id, game)
    for _, group in ipairs(SLOT_GROUPS) do
        if group.id == id then
            if group.name ~= nil then
                return group.name()
            end
            local loc = group.locs[1]
            return game.slotName(loc) or (loc:gsub("^INVTYPE_", ""):lower())
        end
    end
    return tostring(id)
end

-- The slot group of an item; nil while the game has said nothing about it (the filter then keeps it).
local function slotOf(entry, game)
    if entry.slot == nil then
        local info = game.itemInfo(entry.id)
        if info.equipLoc == nil then
            return nil
        end
        entry.slot = Loot.slotGroup(info.equipLoc)
    end
    return entry.slot
end

-- The choices of the slot filter: all slots, then the groups the lines have an item of (and the one picked, so it is
-- always there to be heard and changed).
function Loot.slotChoices(entries, current, game)
    local present = {}
    for _, entry in ipairs(entries) do
        if entry.kind == "item" then
            local slot = slotOf(entry, game)
            if slot ~= nil then
                present[slot] = true
            end
        end
    end
    if current ~= nil then
        present[current] = true
    end
    local out = { { value = "all", label = L["All slots"] } }
    for _, group in ipairs(SLOT_GROUPS) do
        if present[group.id] then
            out[#out + 1] = { value = group.id, label = Loot.slotLabel(group.id, game) }
        end
    end
    return out
end

-- ---------------------------------------------------------- kinds of items

-- The kind of an item is the game's own: its type (Armor, Weapon, Consumable...) and its sub type (Cloth, Leather, One-Handed
-- Swords...), numbered classID and subClassID. A kind is written "c4" for a whole type and "c4s2" for a sub type.
-- It is known at once (the game does not need to send the item); nil while it is not.
local function kindOf(entry, game)
    if entry.kindClass == nil then
        local info = game.itemInfo(entry.id)
        if info.classID == nil then
            return nil
        end
        entry.kindClass, entry.kindSub = info.classID, info.subClassID
    end
    return entry.kindClass, entry.kindSub
end

-- Whether an item of this type and sub type is of the kind asked for.
local function kindMatches(kind, classID, subClassID)
    local wantedClass, wantedSub = kind:match("^c(%d+)s(%d+)$")
    if wantedClass ~= nil then
        return tonumber(wantedClass) == classID and tonumber(wantedSub) == subClassID
    end
    wantedClass = kind:match("^c(%d+)$")
    return wantedClass ~= nil and tonumber(wantedClass) == classID
end

-- The names the game gave to the kinds seen so far, so the one picked can still be named when the list in front of the
-- player has no item of it.
local kindNames = {}

function Loot.kindLabel(kind)
    return kindNames[kind] or tostring(kind)
end

-- The choices of the kind filter: all kinds, then the types the lines have (armor first, then weapons, then the others by
-- number), each with its sub types, named in the game's words; and the one picked, so it can always be heard and changed.
function Loot.kindChoices(entries, current, game)
    local types = {}
    for _, entry in ipairs(entries) do
        if entry.kind == "item" then
            local classID, subClassID = kindOf(entry, game)
            if classID ~= nil then
                local info = game.itemInfo(entry.id)
                local group = types[classID]
                if group == nil then
                    group = { name = info.type or tostring(classID), subs = {} }
                    types[classID] = group
                end
                if subClassID ~= nil and group.subs[subClassID] == nil then
                    group.subs[subClassID] = info.subType or ""
                end
            end
        end
    end
    local order = {}
    for classID in pairs(types) do
        order[#order + 1] = classID
    end
    local function rank(classID)
        return classID == 4 and 0 or (classID == 2 and 1 or classID + 2)
    end
    table.sort(order, function(a, b)
        return rank(a) < rank(b)
    end)
    local out = { { value = "all", label = L["All types"] } }
    local function add(value, label)
        kindNames[value] = label
        out[#out + 1] = { value = value, label = label }
    end
    for _, classID in ipairs(order) do
        local group = types[classID]
        local subs = {}
        for subClassID in pairs(group.subs) do
            subs[#subs + 1] = subClassID
        end
        table.sort(subs)
        if #subs ~= 1 then
            add("c" .. classID, group.name)
        end
        for _, subClassID in ipairs(subs) do
            local name = group.subs[subClassID]
            add("c" .. classID .. "s" .. subClassID, (name ~= nil and name ~= "" and name ~= group.name) and (group.name .. ", " .. name) or group.name)
        end
    end
    if current ~= nil then
        local present = false
        for _, choice in ipairs(out) do
            present = present or choice.value == current
        end
        if not present then
            out[#out + 1] = { value = current, label = Loot.kindLabel(current) }
        end
    end
    return out
end

-- ---------------------------------------------------------------- upgrades

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

-- Languages that write 1,5 rather than 1.5: the speech engine reads the comma as a decimal mark and the point as the word
-- "point".
local DECIMAL_COMMA = { frFR = true, deDE = true, esES = true, itIT = true, ptBR = true, ruRU = true }

-- A percentage as it is spoken: one decimal at most, no ".0", never a minus sign.
function Loot.number(value, locale)
    local text = string.format("%.1f", math.abs(value))
    text = text:gsub("%.0$", "")
    if DECIMAL_COMMA[locale] then
        text = text:gsub("%.", ",")
    end
    return text
end

-- What the Gear Judge says of an item (its link): { how = "judge", percent = how much better the whole character gets, in
-- percent (nil when the Judge gives none: a character that wears nothing yet) } for an upgrade, false when it is none,
-- nil when the Judge cannot say yet. A tenth of a percent is the smallest upgrade that counts.
local function judgeSays(entry, info, game)
    local result, reason = game.judgeScore(info.link)
    if result == nil then
        if reason == "NOT_USABLE" or reason == "NOT_EQUIPPABLE" then
            return false
        end
        return nil
    end
    if result.equipped == true then
        return false
    end
    if finite(result.upgradePct) then
        if tonumber(string.format("%.1f", result.upgradePct)) > 0 then
            return { how = "judge", percent = result.upgradePct }
        end
        return false
    elseif finite(result.upgrade) and result.upgrade > 0 then
        return { how = "judge" }
    end
    return false
end

-- What wearing the item instead of what the player wears would be, as the judge of the upgrades says (game.upgradeMeasure):
-- { how = "judge", percent } when the Gear Judge calls it an upgrade, { how = "pawn", percent | big } when Pawn (with a
-- scale shown for the player) does, { how = "level", more } when its item level is above the lowest of what is worn where
-- it goes, { how = "empty" } when nothing is worn there; false when it is none of those (or is not gear, or is worn
-- already); nil while the game has not said enough. Trinkets are judged by item level when Pawn judges, as it does not
-- score them.
local function judgeUpgrade(entry, game, measure)
    local info = game.itemInfo(entry.id)
    if not info.cached then
        return nil
    end
    local worn = game.wornSlots(info.equipLoc)
    if worn == nil then
        return false
    end
    for _, slot in ipairs(worn) do
        if slot.id ~= nil and slot.id == entry.id then
            return false
        end
    end
    if measure == "judge" and info.link ~= nil then
        return judgeSays(entry, info, game)
    end
    if measure == "pawn" and info.equipLoc ~= "INVTYPE_TRINKET" and info.link ~= nil then
        local pawn = game.pawnUpgrade(info.link)
        if not pawn then
            return pawn
        end
        return { how = "pawn", percent = pawn.percent, big = pawn.big }
    end
    for _, slot in ipairs(worn) do
        if slot.empty then
            return { how = "empty" }
        end
    end
    local mine = game.itemLevelOf(info.link or entry.id) or info.level
    if mine == nil then
        return nil
    end
    local lowest
    for _, slot in ipairs(worn) do
        if slot.level == nil then
            return nil
        end
        if lowest == nil or slot.level < lowest then
            lowest = slot.level
        end
    end
    if mine > lowest then
        return { how = "level", more = mine - lowest }
    end
    return false
end

-- The judgement, kept (on the entry) until what the player wears changes or the screen is opened again; not kept while
-- the game has not answered.
function Loot.upgrade(entry, game)
    local version = game.gearVersion()
    local measure = game.upgradeMeasure()
    local kept = entry.upgradeKept
    if kept ~= nil and kept.version == version and kept.measure == measure then
        return kept.value
    end
    local value = judgeUpgrade(entry, game, measure)
    if value ~= nil then
        entry.upgradeKept = { version = version, measure = measure, value = value }
    end
    return value
end

-- The choices of the judge of upgrades (the "measure" setting), in the order the player hears them.
function Loot.measureChoices()
    return {
        { value = "auto", label = L["Automatic"] },
        { value = "judge", label = L["Gear Judge"] },
        { value = "pawn", label = L["Pawn"] },
        { value = "level", label = L["Item level"] },
    }
end

function Loot.upgradeText(upgrade, game)
    if upgrade.how == "judge" then
        if upgrade.percent == nil then
            return L["an upgrade, judged by Gear Judge"]
        end
        local locale = game ~= nil and game.locale() or "enUS"
        return string.format(L["upgrade of %s percent, judged by Gear Judge"], Loot.number(upgrade.percent, locale))
    elseif upgrade.how == "pawn" then
        if upgrade.big or upgrade.percent == nil then
            return L["big upgrade, judged by Pawn"]
        end
        return string.format(L["upgrade of %d percent, judged by Pawn"], math.floor(upgrade.percent * 100 + 0.5))
    elseif upgrade.how == "level" then
        return string.format(L["upgrade, item level %d higher than what you wear"], upgrade.more)
    end
    return L["upgrade, nothing worn in that slot"]
end

-- ------------------------------------------------------------------- filters

-- Whether the filters ({ classFilter, levelFilter, upgradesOnly, slot }) keep an item.
function Loot.keeps(entry, filters, game)
    if filters.classFilter and not usable(entry, game) then
        return false
    elseif filters.levelFilter and not levelAllows(entry, game) then
        return false
    elseif filters.upgradesOnly and Loot.upgrade(entry, game) == false then
        return false
    elseif filters.slot ~= nil then
        local slot = slotOf(entry, game)
        if slot ~= nil and slot ~= filters.slot then
            return false
        end
    end
    if filters.kind ~= nil then
        local classID, subClassID = kindOf(entry, game)
        if classID ~= nil and not kindMatches(filters.kind, classID, subClassID) then
            return false
        end
    end
    return true
end

-- The lines the filters keep, a header only when an item follows it, and how many items the filters hid.
function Loot.visible(entries, filters, game)
    local out, hidden, pending = {}, 0, nil
    for _, entry in ipairs(entries) do
        if entry.kind == "header" then
            pending = entry
        else
            if Loot.keeps(entry, filters, game) then
                if pending ~= nil then
                    out[#out + 1] = pending
                    pending = nil
                end
                out[#out + 1] = entry
            else
                hidden = hidden + 1
            end
        end
    end
    return out, hidden
end

function Loot.count(entries)
    local count = 0
    for _, entry in ipairs(entries) do
        if entry.kind == "item" then
            count = count + 1
        end
    end
    return count
end

-- -------------------------------------------------------------------- sort

-- The ways to order the loot, in the order the player hears them; "default" is AtlasLoot's own order.
local SORTS = {
    {
        value = "default",
        label = function()
            return L["AtlasLoot's order"]
        end,
    },
    {
        value = "level",
        label = function()
            return L["Item level, highest first"]
        end,
    },
    {
        value = "upgrade",
        label = function()
            return L["Biggest upgrade first"]
        end,
    },
    {
        value = "slot",
        label = function()
            return L["By slot"]
        end,
    },
    {
        value = "drop",
        label = function()
            return L["Drop chance, highest first"]
        end,
    },
}

function Loot.sortChoices()
    local out = {}
    for _, sort in ipairs(SORTS) do
        out[#out + 1] = { value = sort.value, label = sort.label() }
    end
    return out
end

-- How much of an upgrade a judgement is, to put the biggest first: a free slot, then Pawn's big ones and its percents,
-- then the item levels above; what is none (or not known yet) is last.
local function upgradeScore(upgrade)
    if type(upgrade) ~= "table" then
        return 0
    elseif upgrade.how == "empty" then
        return 3000000
    elseif upgrade.how == "judge" then
        return 1000000 + math.min((upgrade.percent or 0) * 100, 90000)
    elseif upgrade.how == "pawn" then
        return 1000000 + (upgrade.big and 100000 or (upgrade.percent or 0) * 100)
    end
    return 1000000 + math.min(upgrade.more or 0, 90000)
end

-- What an item is sorted by: two numbers, the smaller first (so what comes "highest first" is negated).
local function sortKeys(entry, sort, game)
    if sort == "level" then
        return -(game.itemInfo(entry.id).level or -1), 0
    elseif sort == "upgrade" then
        return -upgradeScore(Loot.upgrade(entry, game)), 0
    elseif sort == "slot" then
        local slot = slotOf(entry, game)
        return SLOT_ORDER[slot] or #SLOT_GROUPS + 1, -(game.itemInfo(entry.id).level or -1)
    elseif sort == "drop" then
        return -(tonumber(game.droprate(entry.npcID, entry.id)) or -1), 0
    end
    return 0, 0
end

-- The lines in the order asked for. Each run of items under one header is ordered on its own, so the headers stay
-- where AtlasLoot has them; items that are equal keep AtlasLoot's order.
-- Whether the way to sort puts the lines in an order of its own (not AtlasLoot's, and one that exists).
function Loot.isSorted(sort)
    for _, item in ipairs(SORTS) do
        if item.value == sort and sort ~= "default" then
            return true
        end
    end
    return false
end

function Loot.sort(lines, sort, game)
    if not Loot.isSorted(sort) then
        return lines
    end
    local out, run = {}, {}
    local function flush()
        local decorated = {}
        for index, entry in ipairs(run) do
            local first, second = sortKeys(entry, sort, game)
            decorated[index] = { entry = entry, first = first, second = second, index = index }
        end
        table.sort(decorated, function(a, b)
            if a.first ~= b.first then
                return a.first < b.first
            elseif a.second ~= b.second then
                return a.second < b.second
            end
            return a.index < b.index
        end)
        for _, item in ipairs(decorated) do
            out[#out + 1] = item.entry
        end
        run = {}
    end
    for _, entry in ipairs(lines) do
        if entry.kind == "header" then
            flush()
            out[#out + 1] = entry
        else
            run[#run + 1] = entry
        end
    end
    flush()
    return out
end

-- ------------------------------------------------------- a whole instance

-- The bosses a view of the whole instance reads: its bosses, not its other lists (tier sets, keys, books...), or all of
-- its lists when it has no boss at all.
function Loot.instanceBosses(data, key)
    local all, bosses = Loot.bosses(data, key), {}
    for _, boss in ipairs(all) do
        if not boss.extra then
            bosses[#bosses + 1] = boss
        end
    end
    if #bosses == 0 then
        return all
    end
    return bosses
end

-- The difficulties any of the bosses has a table for, in order: { { id, name } }.
function Loot.mergeDifficulties(data, key, bosses)
    local byId, ids = {}, {}
    for _, boss in ipairs(bosses) do
        for _, diff in ipairs(Loot.difficulties(data, key, boss.index)) do
            if byId[diff.id] == nil then
                byId[diff.id] = diff
                ids[#ids + 1] = diff.id
            end
        end
    end
    table.sort(ids)
    local out = {}
    for _, difficulty in ipairs(ids) do
        out[#out + 1] = byId[difficulty]
    end
    return out
end

-- ------------------------------------------------------------------ search

-- Accents and case taken out of a name, so "epee" finds "Épée" and "grosse" finds "Größe".
local FOLD = {}
for letter, chars in pairs({
    a = "àáâãäåÀÁÂÃÄÅ",
    c = "çÇ",
    e = "èéêëÈÉÊË",
    i = "ìíîïÌÍÎÏ",
    n = "ñÑ",
    o = "òóôõöÒÓÔÕÖ",
    u = "ùúûüÙÚÛÜ",
    y = "ýÿÝ",
}) do
    for char in chars:gmatch("[\195\197][\128-\191]") do
        FOLD[char] = letter
    end
end
FOLD["ß"], FOLD["æ"], FOLD["Æ"], FOLD["œ"], FOLD["Œ"] = "ss", "ae", "ae", "oe", "oe"

function Loot.fold(text)
    if type(text) ~= "string" then
        return ""
    end
    text = text:gsub("\226\128[\152\153]", "'")
    text = text:gsub("[\195\197][\128-\191]", FOLD)
    return (text:lower())
end

-- The words of a search, folded; a name has to hold every one of them.
function Loot.words(query)
    local out = {}
    for word in Loot.fold(query):gmatch("%S+") do
        out[#out + 1] = word
    end
    return out
end

-- A search needs at least two letters in all.
function Loot.searchable(words)
    return #table.concat(words) >= 2
end

-- How many bosses the index reads at a time, and how many times it asks again for a list that is not loaded yet.
local INDEX_TRIES = 40

local Index = {}
Index.__index = Index

-- An index of every item of a module for a game version, with where it drops: { entry, instance, boss, diffs,
-- bossDiffs }. It is read a few bosses at a time (Index:step), so the screen does not stop while it is built.
function Loot.index(atlas, moduleId, data, version)
    return setmetatable({
        atlas = atlas,
        moduleId = moduleId,
        data = data,
        version = version,
        records = {},
        jobs = nil,
        position = 1,
        retry = {},
        skipped = 0,
        cursor = 1,
        done = false,
    }, Index)
end

function Index:list()
    self.jobs = {}
    for _, group in ipairs(Loot.instances(self.atlas, self.moduleId, self.data, self.version)) do
        for _, instance in ipairs(group.list) do
            for _, boss in ipairs(Loot.bosses(self.data, instance.key)) do
                self.jobs[#self.jobs + 1] = { instance = instance, boss = boss, tries = 0, seen = {}, read = {} }
            end
        end
    end
end

-- Reads one boss: every difficulty's table once. False when a table lives in a module that is not loaded yet.
function Index:read(job, game)
    local key, boss = job.instance.key, job.boss
    Loot.resolve(self.atlas, self.moduleId, key, boss.index)
    local diffs = Loot.difficulties(self.data, key, boss.index)
    local complete = true
    for _, diff in ipairs(diffs) do
        if not job.read[diff.id] then
            local entries, problem, message = Loot.table(self.atlas, self.moduleId, key, boss.index, diff.id, game, boss.npcID)
            if problem == "loading" then
                complete = false
            else
                job.read[diff.id] = true
                if problem == "error" then
                    if game.report ~= nil then
                        game.report(message)
                    end
                else
                    for _, entry in ipairs(entries) do
                        if entry.kind == "item" then
                            local record = job.seen[entry.id]
                            if record == nil then
                                record = {
                                    entry = entry,
                                    instance = job.instance.name,
                                    instanceKey = key,
                                    boss = boss.name,
                                    bossIndex = boss.index,
                                    diffs = {},
                                    bossDiffs = #diffs,
                                }
                                job.seen[entry.id] = record
                                self.records[#self.records + 1] = record
                            end
                            if record.diffs[#record.diffs] ~= diff.name then
                                record.diffs[#record.diffs + 1] = diff.name
                            end
                        end
                    end
                end
            end
        end
    end
    return complete
end

-- Reads up to `budget` more bosses; true once the index is complete. The bosses whose list was not loaded get another
-- round after the others, a few times, then are left out (skipped).
function Index:step(game, budget)
    if self.done then
        return true
    end
    if self.jobs == nil then
        self:list()
    end
    while budget > 0 do
        local job = self.jobs[self.position]
        if job == nil then
            if #self.retry == 0 then
                self.done = true
                return true
            end
            self.jobs, self.position, self.retry = self.retry, 1, {}
            return false
        end
        self.position = self.position + 1
        budget = budget - 1
        if not self:read(job, game) then
            job.tries = job.tries + 1
            if job.tries >= INDEX_TRIES then
                self.skipped = self.skipped + 1
            else
                self.retry[#self.retry + 1] = job
            end
        end
    end
    return false
end

-- Asks the game for the names of up to `budget` more items (the ones it does not have), so it is never flooded.
function Index:request(game, budget)
    local records = self.records
    while budget > 0 and self.cursor <= #records do
        local id = records[self.cursor].entry.id
        self.cursor = self.cursor + 1
        if game.itemName(id) == nil then
            game.requestItem(id)
            budget = budget - 1
        end
    end
end

-- Where an indexed item drops: "Rhahk'Zor, The Deadmines", and the difficulties it is in when it is not in all of them.
function Loot.where(record)
    local text = record.boss .. ", " .. record.instance
    if record.bossDiffs > 1 and #record.diffs < record.bossDiffs then
        text = text .. ", " .. table.concat(record.diffs, ", ")
    end
    return text
end

-- How many items one search looks through before it stops (the rest is "more matches").
Loot.SEARCH_SCAN = 300

-- The items of an index whose name holds every word and that the filters keep:
-- { found = entries, recordOf = { [entry] = record }, passing = entries the other filters keep (for the slot choices),
-- hidden, more = the search stopped early, unknown = names the game has not sent }.
function Loot.find(index, words, filters, game)
    local result = { found = {}, recordOf = {}, passing = {}, hidden = 0, more = false, unknown = 0 }
    local others = { classFilter = filters.classFilter, levelFilter = filters.levelFilter, upgradesOnly = filters.upgradesOnly }
    local slotOnly = { slot = filters.slot, kind = filters.kind }
    for _, record in ipairs(index.records) do
        local entry = record.entry
        if entry.folded == nil then
            local name = game.itemName(entry.id)
            if name ~= nil then
                entry.folded = Loot.fold(name)
            elseif not game.itemFailed(entry.id) then
                result.unknown = result.unknown + 1
            end
        end
        local matches = entry.folded ~= nil
        for _, word in ipairs(words) do
            matches = matches and entry.folded:find(word, 1, true) ~= nil
        end
        if matches then
            if not Loot.keeps(entry, others, game) then
                result.hidden = result.hidden + 1
            else
                result.passing[#result.passing + 1] = entry
                if Loot.keeps(entry, slotOnly, game) then
                    result.found[#result.found + 1] = entry
                    result.recordOf[entry] = record
                else
                    result.hidden = result.hidden + 1
                end
            end
            if #result.found >= Loot.SEARCH_SCAN then
                result.more = true
                break
            end
        end
    end
    return result
end

-- ------------------------------------------------------------------- speech

-- What an item says: the name, the quality, the slot and type, the item level, the level it asks, the drop chance,
-- AtlasLoot's note, and what the filters did not already settle.
function Loot.describe(entry, filters, game, where)
    local info = game.itemInfo(entry.id)
    local parts = {}
    if info.name ~= nil then
        parts[#parts + 1] = info.name
    else
        parts[#parts + 1] = string.format(L["Item %d, loading"], entry.id)
    end
    if info.quality ~= nil and info.quality >= 2 then
        parts[#parts + 1] = game.qualityName(info.quality)
    end
    local slot, subType = game.slotName(info.equipLoc), info.subType
    if slot ~= nil and subType ~= nil and subType ~= "" and subType ~= slot then
        parts[#parts + 1] = slot .. ", " .. subType
    elseif slot ~= nil then
        parts[#parts + 1] = slot
    elseif subType ~= nil and subType ~= "" then
        parts[#parts + 1] = subType
    elseif info.type ~= nil and info.type ~= "" then
        parts[#parts + 1] = info.type
    end
    if info.level ~= nil and info.level > 1 and game.slotName(info.equipLoc) ~= nil then
        parts[#parts + 1] = string.format(L["item level %d"], info.level)
    end
    if info.minLevel ~= nil and info.minLevel > 1 then
        local text = string.format(L["requires level %d"], info.minLevel)
        if info.minLevel > game.playerLevel() then
            text = text .. ", " .. L["above your level"]
        end
        parts[#parts + 1] = text
    end
    local upgrade = Loot.upgrade(entry, game)
    if type(upgrade) == "table" then
        parts[#parts + 1] = Loot.upgradeText(upgrade, game)
    end
    local rate = game.droprate(entry.npcID, entry.id)
    if rate ~= nil then
        parts[#parts + 1] = string.format(L["%s percent drop chance"], tostring(rate))
    end
    if entry.note ~= nil then
        parts[#parts + 1] = entry.note
    end
    if where ~= nil then
        parts[#parts + 1] = string.format(L["from %s"], where)
    end
    if not filters.classFilter and entry.usable == false then
        parts[#parts + 1] = L["your class cannot use it"]
    end
    return table.concat(parts, ", ")
end
