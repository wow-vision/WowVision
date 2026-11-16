local testRunner = WowVision.testing.testRunner
local text = WowVision.wownavText

-- Creatures and objects named in the client's language from Questie's database (text.lua). The game and Questie
-- are stand-ins: GetLocale, QuestieLoader, and the two databases Questie publishes, NpcDB and ObjectDB, whose Get
-- answers in the client's language.

local function class(kind, entry, nameEn, nameDe, extra)
    local target = { kind = kind, entry = entry, nameEn = nameEn, nameDe = nameDe or nameEn }
    for key, value in pairs(extra or {}) do
        target[key] = value
    end
    return target
end

local function database(names, titles, asked)
    return {
        Get = function(id, field)
            if asked ~= nil then
                asked[#asked + 1] = field .. ":" .. tostring(id)
            end
            if field == "subName" then
                return titles ~= nil and titles[id] or nil
            end
            local value = names[id]
            if value == "error" then
                error("boom")
            end
            return value
        end,
    }
end

-- Runs fn with a French client and Questie answering, then puts the globals back.
local function inFrench(fn, options)
    options = options or {}
    local saved = { GetLocale, NpcDB, ObjectDB, QuestieLoader, text.localNamesEnabled, Questie }
    GetLocale = function()
        return options.locale or "frFR"
    end
    NpcDB = database({
        [10556] = "Péon fainéant",
        [3191] = "Pyall Pas-Silencieux",
        [6928] = "Aubergiste Grosk",
        [7000] = "error",
    }, { [3191] = "Cuisinier", [6928] = "Aubergiste" }, options.asked)
    ObjectDB = database({ [1618] = "Pacifique", [104555] = "Enclume" }, { [1618] = "Ne devrait pas apparaître" })
    QuestieLoader = nil
    Questie = nil
    text.clearLocalNames()
    local ok, err = pcall(fn)
    GetLocale, NpcDB, ObjectDB, QuestieLoader, text.localNamesEnabled, Questie = unpack(saved, 1, 6)
    text.clearLocalNames()
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("WowNav local names", {
    ["an NPC reads its name in the client's language"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon", "Fauler Peon")), "Péon fainéant")
        end)
    end,

    ["mobs and creatures use the creature database too"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("mob", 10556, "Lazy Peon")), "Péon fainéant")
            t:assertEqual(text.targetName(class("creature", 10556, "Lazy Peon")), "Péon fainéant")
        end)
    end,

    ["objects, herbs, ores and mailboxes use the object database"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("herb", 1618, "Peacebloom", "Friedensblume")), "Pacifique")
            t:assertEqual(text.targetName(class("mining", 1618, "Silverleaf")), "Pacifique")
            t:assertEqual(text.targetName(class("gameobject", 104555, "Anvil", "Amboss")), "Enclume")
            t:assertEqual(text.targetName(class("mailbox", 104555, "Mailbox")), "Enclume")
        end)
    end,

    ["a creature ID is not looked up among objects, nor the reverse"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 1618, "Not A Peacebloom")), "Not A Peacebloom")
            t:assertEqual(text.targetName(class("herb", 10556, "Not A Peon")), "Not A Peon")
        end)
    end,

    ["an ID Questie does not know keeps the catalogue's name"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 99999, "Mystery Man", "Raetselmann")), "Mystery Man")
        end)
    end,

    ["no ID, or a kind without a database, keeps the catalogue's name"] = function(t)
        local asked = {}
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", nil, "Nameless")), "Nameless")
            t:assertEqual(text.targetName(class("fishing_spot", 5, "Pool")), "Pool")
            t:assertEqual(#asked, 0)
        end, { asked = asked })
    end,

    ["a title in parentheses stays, in the client's language"] = function(t)
        inFrench(function()
            t:assertEqual(
                text.targetName(class("npc", 3191, "Pyall Silentstride (Cook)", "Pyall Leisetritt (Koch)")),
                "Pyall Pas-Silencieux (Cuisinier)"
            )
            t:assertEqual(
                text.targetName(class("npc", 6928, "Innkeeper Grosk (Innkeeper)")),
                "Aubergiste Grosk (Aubergiste)"
            )
        end)
    end,

    ["no title in the catalogue's name: none is added"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 3191, "Pyall Silentstride")), "Pyall Pas-Silencieux")
        end)
    end,

    ["a title Questie has no translation for is left out, not left in English"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon (Idler)")), "Péon fainéant")
        end)
    end,

    ["objects never take a title"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("herb", 1618, "Peacebloom (Herb)")), "Pacifique")
        end)
    end,

    ["what WowNav adds around a name is kept (the suffix for two alike targets)"] = function(t)
        inFrench(function()
            local row = class("npc", 10556, "Lazy Peon", "Fauler Peon", { nameSuffix = { key = "number", value = 2 } })
            t:assertEqual(text.targetName(row), "Péon fainéant (2)")
        end)
    end,

    ["names built from a template are left to WowNav"] = function(t)
        local asked = {}
        inFrench(function()
            local entrance = class("gameobject", 104555, "Ragefire Chasm", "Flammenschlund", {
                nameKey = "dungeon_entrance",
                nameParam = "Ragefire Chasm",
            })
            t:assertNotEqual(text.targetName(entrance), "Enclume")
            t:assertEqual(#asked, 0)
        end, { asked = asked })
    end,

    ["a name key WowNav has no template for keeps the catalogue's name"] = function(t)
        local asked = {}
        inFrench(function()
            local other = class("gameobject", 104555, "Strange Door", "Seltsame Tuer", { nameKey = "a_future_key" })
            t:assertEqual(text.targetName(other), "Strange Door")
            t:assertEqual(#asked, 0)
        end, { asked = asked })
    end,

    ["the shared class row is never changed"] = function(t)
        inFrench(function()
            local shared = class("npc", 10556, "Lazy Peon", "Fauler Peon")
            text.targetName(shared)
            t:assertEqual(shared.nameEn, "Lazy Peon")
            t:assertEqual(shared.nameDe, "Fauler Peon")
        end)
    end,

    ["an English or German client keeps the catalogue's names"] = function(t)
        local asked = {}
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon", "Fauler Peon")), "Lazy Peon")
        end, { locale = "enUS", asked = asked })
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon", "Fauler Peon")), "Fauler Peon")
        end, { locale = "deDE", asked = asked })
        t:assertEqual(#asked, 0)
    end,

    ["a caller that asks for German on purpose gets German"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon", "Fauler Peon"), true), "Fauler Peon")
        end)
    end,

    ["other languages use Questie's answer as well"] = function(t)
        inFrench(function()
            NpcDB = database({ [10556] = "Peón perezoso" })
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon", "Fauler Peon")), "Peón perezoso")
        end, { locale = "esES" })
    end,

    ["WowNav's global naming function reaches the localized name"] = function(t)
        inFrench(function()
            t:assertEqual(WowVisionNavigationTargetName(class("npc", 10556, "Lazy Peon")), "Péon fainéant")
        end)
    end,

    ["the setting switches it off"] = function(t)
        inFrench(function()
            text.localNamesEnabled = function()
                return false
            end
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon")), "Lazy Peon")
        end)
    end,

    ["Questie missing: the catalogue's name, and the localized one as soon as it is there"] = function(t)
        inFrench(function()
            local npcs = NpcDB
            NpcDB = nil
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon")), "Lazy Peon")
            NpcDB = npcs
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon")), "Péon fainéant")
        end)
    end,

    ["Questie set to another language than the game is not used, until it agrees"] = function(t)
        local asked = {}
        inFrench(function()
            local uiLocale = "enUS"
            QuestieLoader = {
                ImportModule = function(_, name)
                    t:assertEqual(name, "l10n")
                    return {
                        GetUILocale = function()
                            return uiLocale
                        end,
                    }
                end,
            }
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon")), "Lazy Peon", "Questie still says English")
            t:assertEqual(#asked, 0, "Questie was not asked")
            uiLocale = "frFR"
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon")), "Péon fainéant", "the refusal was not kept")
        end, { asked = asked })
    end,

    ["a name missed while Questie is still loading is asked again once it is ready"] = function(t)
        inFrench(function()
            local onReady = {}
            Questie = {
                API = {
                    isReady = false,
                    RegisterOnReady = function(fn)
                        onReady[#onReady + 1] = fn
                    end,
                },
            }
            local loaded = NpcDB
            NpcDB = database({})
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon")), "Lazy Peon", "not loaded yet")
            NpcDB = loaded
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon")), "Lazy Peon", "the miss is remembered")
            t:assertEqual(#onReady, 1, "hooked once")
            Questie.API.isReady = true
            onReady[1]()
            t:assertEqual(text.targetName(class("npc", 10556, "Lazy Peon")), "Péon fainéant", "asked again when ready")
            t:assertEqual(#onReady, 1, "not hooked again")
        end)
    end,

    ["a failing Questie lookup does not break naming"] = function(t)
        inFrench(function()
            t:assertEqual(text.targetName(class("npc", 7000, "Broken One")), "Broken One")
        end)
    end,

    ["each ID is asked of Questie once"] = function(t)
        local asked = {}
        inFrench(function()
            for _ = 1, 5 do
                text.targetName(class("npc", 10556, "Lazy Peon"))
                text.targetName(class("npc", 99999, "Mystery Man"))
            end
            t:assertEqual(#asked, 2)
        end, { asked = asked })
    end,
})
