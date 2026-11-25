-- Headless only (tools/headless-tests.lua loads names.lua and sources.lua, then module.lua against a stand-in
-- module, and hands it over): the walk over a stand-in Questie database, the names it adds through the database's
-- correction layer, and the module's setting, command and menu.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._nameSourcesTestHarness
local module = harness.module
local ns = WowVision.nameSources
local Names, Sources, Game = ns.Names, ns.Sources, ns.Game

local KEYS = { Npc = { name = 1, subName = 14 }, Object = { name = 1 }, Item = { name = 1 } }

-- entries[typeName][id] = { en =, loc =, subEn =, subLoc = }
local function fakeDatabase(entries)
    local db = { corrections = {}, calls = 0 }
    local function entity(typeName)
        local function rows()
            return entries[typeName] or {}
        end
        return {
            GetAllIds = function()
                local ids = {}
                for id in pairs(rows()) do
                    tinsert(ids, id)
                end
                table.sort(ids)
                return ids
            end,
            GetRaw = function(id, field)
                local entry = rows()[id]
                return entry and (field == "name" and entry.en or entry.subEn)
            end,
            Get = function(id, field)
                local entry = rows()[id]
                if entry == nil then
                    return nil
                end
                local added = db.corrections[typeName] and db.corrections[typeName][id]
                if added ~= nil and added[KEYS[typeName][field]] ~= nil then
                    return added[KEYS[typeName][field]]
                end
                if field == "name" then
                    return entry.loc or entry.en
                end
                return entry.subLoc or entry.subEn
            end,
            InvalidateCache = function() end,
        }
    end
    db.NpcDB, db.ObjectDB, db.ItemDB = entity("Npc"), entity("Object"), entity("Item")
    db.library = {
        Meta = { Npc = { keys = KEYS.Npc }, Object = { keys = KEYS.Object }, Item = { keys = KEYS.Item } },
        l10n = {
            SetCorrection = function(_, _, typeName, _, newRows)
                db.calls = db.calls + 1
                db.corrections[typeName] = newRows
            end,
        },
    }
    return db
end

local DATA = {
    Npc = {
        [1] = { en = "Cat", loc = "Chat" },
        [2] = { en = "Cat", loc = "Chat" },
        [3] = { en = "Cat" },
        [4] = { en = "Boar", subEn = "Cook" },
        [5] = { en = "Wolf", loc = "Loup", subEn = "Cook", subLoc = "Cuisinier" },
    },
    Object = { [10] = { en = "Mailbox" } },
}

local function withGame(test, options)
    options = options or {}
    local world = { spoken = {}, locale = options.locale or "frFR", forgotten = 0, timers = {} }
    local db = fakeDatabase(options.data or DATA)
    world.db = db
    local saved = {}
    for key, value in pairs(Game) do
        saved[key] = value
    end
    local globals = { NpcDB = NpcDB, ObjectDB = ObjectDB, ItemDB = ItemDB, LibQuestieDB = LibQuestieDB }
    if options.noDatabase then
        NpcDB, ObjectDB, ItemDB, LibQuestieDB = nil, nil, nil, nil
    else
        NpcDB, ObjectDB, ItemDB, LibQuestieDB = db.NpcDB, db.ObjectDB, db.ItemDB, db.library
    end
    Game.locale = function()
        return world.locale
    end
    Game.now = function()
        return 0
    end
    Game.inCombat = function()
        return false
    end
    Game.metadata = function()
        return "1"
    end
    Game.speak = function(text)
        tinsert(world.spoken, text)
    end
    Game.time = function()
        return 1
    end
    Game.sourceEnv = function(registered)
        return { locale = world.locale, registered = registered, questieTranslations = { Mailbox = { frFR = "Boîte aux lettres" } } }
    end
    Game.forgetWowVisionNames = function()
        world.forgotten = world.forgotten + 1
    end
    local data = {}
    local savedStore, savedComplete, savedEnabled = module.globalDB, module.settings.complete, module.enabled
    module.globalDB = { data = data }
    world.data = data
    ns.scan, ns.pending, ns.manual, ns.started = nil, nil, false, false
    ns.state.phase = "idle"
    local registered = ns.registered
    ns.registered = {}
    local ok, err = pcall(test, world)
    module.settings.complete = false
    module.globalDB, module.settings.complete, module.enabled = savedStore, savedComplete, savedEnabled
    ns.scan, ns.pending, ns.manual, ns.started = nil, nil, false, false
    ns.registered = registered
    NpcDB, ObjectDB, ItemDB, LibQuestieDB = globals.NpcDB, globals.ObjectDB, globals.ItemDB, globals.LibQuestieDB
    for key in pairs(Game) do
        Game[key] = nil
    end
    for key, value in pairs(saved) do
        Game[key] = value
    end
    if not ok then
        error(err, 0)
    end
end

local function finish()
    for _ = 1, 100 do
        if ns.pump() then
            return
        end
    end
end

testRunner:addSuite("NameSources", {
    ["the name most entries agree on wins, and no name without enough agreement"] = function(t)
        t:assertEqual(Names.pick({ Chat = 2, Matou = 1 }), "Chat")
        t:assertNil(Names.pick({ Chat = 1, Matou = 1 }))
        t:assertNil(Names.pick(nil))
    end,

    ["completing is off until the player turns it on"] = function(t)
        t:assertFalse(harness.defaults.complete)
        withGame(function(world)
            module.enabled = true
            ns.start(false)
            t:assertEqual(ns.state.phase, "off")
            t:assertEqual(world.db.calls, 0)
        end)
    end,

    ["the saved switch does nothing before the world is entered"] = function(t)
        withGame(function(world)
            module.enabled = true
            module.settings.complete = true
            t:assertNil(ns.scan)
            t:assertEqual(world.db.calls, 0)
        end)
    end,

    ["turning it on walks the database and adds the missing names"] = function(t)
        withGame(function(world)
            ns.started = true
            module.enabled = true
            module.settings.complete = true
            t:assertEqual(ns.state.phase, "scanning")
            finish()
            t:assertEqual(ns.state.phase, "ready")
            t:assertEqual(NpcDB.Get(3, "name"), "Chat")
            t:assertEqual(NpcDB.Get(4, "subName"), "Cuisinier")
            t:assertEqual(ObjectDB.Get(10, "name"), "Boîte aux lettres")
            t:assertEqual(NpcDB.Get(4, "name"), "Boar")
            t:assertTrue(world.forgotten > 0)
            t:assertNotNil(world.data.cache)
        end)
    end,

    ["turning it off takes the names back"] = function(t)
        withGame(function()
            ns.started = true
            module.enabled = true
            module.settings.complete = true
            finish()
            module.settings.complete = false
            t:assertEqual(ns.state.phase, "off")
            t:assertEqual(NpcDB.Get(3, "name"), "Cat")
        end)
    end,

    ["an unchanged database reuses the saved result"] = function(t)
        withGame(function(world)
            ns.started = true
            module.enabled = true
            module.settings.complete = true
            finish()
            ns.scan = nil
            ns.start(false)
            t:assertNil(ns.scan)
            t:assertEqual(ns.state.phase, "ready")
            t:assertEqual(ns.recalculate(), true)
            t:assertNotNil(ns.scan)
        end)
    end,

    ["nothing is done in English or without Questie's database"] = function(t)
        withGame(function()
            ns.started = true
            module.enabled = true
            module.settings.complete = true
            t:assertEqual(ns.state.phase, "english")
            t:assertEqual(ns.statusText(false), "Not needed: the game is in English.")
        end, { locale = "enUS" })
        withGame(function()
            ns.started = true
            module.enabled = true
            module.settings.complete = true
            t:assertEqual(ns.state.phase, "noLibrary")
        end, { noDatabase = true })
    end,

    ["a source another addon adds is asked"] = function(t)
        withGame(function()
            t:assertTrue(ns.addSource("mine", function(kind, english)
                if kind == "Npc" and english == "Boar" then
                    return "Sanglier"
                end
            end))
            t:assertFalse(ns.addSource("bad", "x"))
            ns.started = true
            module.enabled = true
            module.settings.complete = true
            finish()
            t:assertEqual(NpcDB.Get(4, "name"), "Sanglier")
        end)
    end,

    ["it starts a few seconds after entering the world, once"] = function(t)
        withGame(function()
            local delays = {}
            local savedTimer = C_Timer
            C_Timer = {
                After = function(seconds, fn)
                    tinsert(delays, seconds)
                    fn()
                end,
            }
            module.enabled = true
            module:onEvent("PLAYER_ENTERING_WORLD")
            module:onEvent("PLAYER_ENTERING_WORLD")
            C_Timer = savedTimer
            t:assertEqual(#delays, 1)
            t:assertEqual(delays[1], module.START_AFTER)
        end)
    end,

    ["the update walks a scan"] = function(t)
        withGame(function()
            ns.started = true
            module.enabled = true
            module:onEnable()
            module.settings.complete = true
            module.update(module)
            t:assertEqual(ns.state.phase, "ready")
        end)
    end,

    ["the command and the menu say the state"] = function(t)
        withGame(function(world)
            ns.started = true
            module.enabled = true
            harness.commands.names.func("on")
            t:assertTrue(module.settings.complete)
            t:assertEqual(world.spoken[1], "Name sources are on.")
            finish()
            harness.commands.names.func("")
            t:assertTrue(world.spoken[#world.spoken]:find("1 creature names, 1 titles and 1 world objects", 1, true) ~= nil)
            harness.commands.names.func("test Mailbox")
            t:assertTrue(world.spoken[#world.spoken]:find("Boîte aux lettres", 1, true) ~= nil)
            harness.commands.names.func("off")
            t:assertFalse(module.settings.complete)
            local builder = WowVision.graph.Builder:new()
            module:getGraphMenuItems(builder)
            local rendered = builder:build()
            t:assertEqual(#rendered.order, 2)
        end)
    end,
})
