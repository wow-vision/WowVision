-- Headless only (tools/headless-tests.lua loads the loot browser's files, then module.lua against a stand-in window
-- module, and hands over the loader): the tables of a stand-in AtlasLoot read and filtered, the screen walked with the
-- real graph builder, and the module's key, command, events and hook.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._atlasLootTestHarness
local ns = WowVision.atlasLoot
local Loot, Screen, Game = ns.Loot, ns.Screen, ns.Game

local module, registered = harness.load({ AtlasLootClassic = true })

-- A stand-in AtlasLoot: one loot module with a dungeon of two bosses (one with a heroic table) and a set list, plus a
-- module in each load state.
local function fakeAtlas()
    local contentTypes = { { "Dungeons" }, { "Raids" } }
    local function content(def)
        function def:GetContentType()
            return contentTypes[self.type], self.type
        end
        function def:GetName()
            return self.name
        end
        function def:GetNameForItemTable(index)
            return self.items[index].name
        end
        return def
    end
    local data = {
        __atlaslootdata = { gameVersions = { [1] = true, [4] = true, [0] = true } },
        Mine = content({
            type = 1,
            gameVersion = 1,
            name = "|cffff0000The Mine|r",
            LevelRange = { 10, 15, 20 },
            items = {
                {
                    name = "Foreman",
                    npcID = 11,
                    [1] = {
                        { 2, 102 },
                        { 1, 101 },
                        { 3, "INV_Box", nil, "Forever" },
                        { 4, 103, [901] = 104 },
                    },
                    [2] = { diffName = "Heroic!", { 1, 105 } },
                },
                { name = "Overseer", npcID = 12, [1] = { { 1, 102 } } },
                { name = "Keys", ExtraList = true },
            },
        }),
        Keep = content({ type = 2, gameVersion = 1, name = "The Keep", items = {} }),
        Spire = content({ type = 1, gameVersion = 4, name = "The Spire", items = {} }),
    }
    function data:GetContentTypes()
        return contentTypes
    end
    function data:GetDifficultys()
        return { { name = "Normal" }, { name = "Heroic" } }
    end
    function data:GetAviableGameVersion()
        return 1
    end
    local loadedModules = { TestLoot = data }
    local atlas = {
        CLASSIC_VERSION_NUM = 1,
        BC_VERSION_NUM = 2,
        FOREVER_VERSION_NUM = 4,
        asked = {},
    }
    atlas.Loader = {
        GetLootModuleList = function()
            return {
                module = {
                    { addonName = "TestLoot", name = "|TInterface\\X:0|t Test Loot" },
                    { addonName = "TestOff", name = "Off" },
                },
                custom = { { addonName = "TestCombat", name = "Later" } },
            }
        end,
        LoadModule = function(_, id)
            tinsert(atlas.asked, id)
            if id == "TestOff" then
                return "DISABLED"
            elseif id == "TestCombat" then
                return "InCombat"
            end
            return nil
        end,
    }
    atlas.ItemDB = {
        Get = function(_, id)
            return loadedModules[id]
        end,
        GetModuleList = function()
            return { "Mine", "Keep", "Spire" }
        end,
        CheckForLink = function() end,
        GetItemTable = function(_, _, key, boss, diff)
            return data[key].items[boss][diff], { "Item" }
        end,
    }
    return atlas, data
end

local ITEMS = {
    [101] = { name = "Pick", quality = 2, level = 18, minLevel = 12, equipLoc = "INVTYPE_WEAPON", classID = 2, subClassID = 4 },
    [102] = { name = "Cloak", quality = 3, level = 25, minLevel = 30, equipLoc = "INVTYPE_CLOAK", classID = 4, subClassID = 1 },
    [103] = { name = "Alliance Boots", quality = 2, level = 20, minLevel = 10, equipLoc = "INVTYPE_FEET", classID = 4, subClassID = 2 },
    [104] = { name = "Horde Boots", quality = 2, level = 20, minLevel = 10, equipLoc = "INVTYPE_FEET", classID = 4, subClassID = 2 },
    [105] = { name = "Heroic Sash", quality = 3, level = 30, minLevel = 20, equipLoc = "INVTYPE_WAIST", classID = 4, subClassID = 1 },
}

-- A world over the fake AtlasLoot: the player a level 20 Horde who cannot use item 103, every item cached.
local function withAtlas(test)
    local world = { spoken = {}, open = false, config = nil, requested = {}, closed = 0 }
    local atlas, data = fakeAtlas()
    world.atlas, world.data = atlas, data
    world.level, world.faction, world.unusable = 20, "Horde", { [103] = true }
    local savedGame = {}
    for key, value in pairs(Game) do
        savedGame[key] = value
    end
    Game.atlas = function()
        return atlas
    end
    Game.atlasFrame = function()
        return world.frame
    end
    Game.speak = function(text)
        tinsert(world.spoken, text)
    end
    Game.itemInfo = function(id)
        local item = ITEMS[id]
        if item == nil then
            return { id = id, cached = false }
        end
        local info = { id = id, cached = true, link = "item:" .. id, type = "Armor", subType = "Cloth" }
        for key, value in pairs(item) do
            info[key] = value
        end
        return info
    end
    Game.requestItem = function(id)
        world.requested[id] = true
    end
    Game.canUse = function(id)
        return not world.unusable[id]
    end
    Game.playerLevel = function()
        return world.level
    end
    Game.faction = function()
        return world.faction
    end
    Game.playerClass = function()
        return "PRIEST"
    end
    Game.gearVersion = function()
        return 1
    end
    Game.upgradeMeasure = function()
        return "level"
    end
    Game.wornSlots = function()
        return { { slot = 1, id = 1, level = 20 } }
    end
    Game.itemLevelOf = function()
        return nil
    end
    Game.slotName = function(equipLoc)
        return equipLoc
    end
    Game.qualityName = function(quality)
        return "Q" .. quality
    end
    Game.droprate = function()
        return nil
    end
    Game.inCombat = function()
        return false
    end
    Game.isOpen = function()
        return world.open
    end
    Game.open = function(config)
        world.open, world.config = true, config
        return true
    end
    Game.close = function()
        world.open = false
        world.closed = world.closed + 1
    end
    Game.speakTooltip = function()
        return false
    end
    local savedSettings = ns.settings
    ns.settings = {
        classFilter = true,
        levelFilter = false,
        upgradesOnly = false,
        measure = "auto",
        sort = "default",
        openWithAl = true,
    }
    world.settings = ns.settings
    local state = Screen.state
    local savedState = {}
    for key, value in pairs(state) do
        savedState[key] = value
    end
    state.level, state.module, state.instance, state.boss, state.whole = "modules", nil, nil, nil, false
    state.diff, state.slot, state.kind, state.version, state.cache, state.index = nil, nil, nil, nil, {}, nil
    ns.openedByAl, ns.frameHooked = false, nil
    local ok, err = pcall(test, world)
    for key in pairs(state) do
        state[key] = nil
    end
    for key, value in pairs(savedState) do
        state[key] = value
    end
    ns.settings = savedSettings
    for key in pairs(Game) do
        Game[key] = nil
    end
    for key, value in pairs(savedGame) do
        Game[key] = value
    end
    ns.openedByAl, ns.frameHooked = false, nil
    if not ok then
        error(err, 0)
    end
end

local function labelOf(row)
    if type(row.label) == "function" then
        return row.label()
    end
    return row.label
end

local function rowsOf(model)
    local out = {}
    for _, row in ipairs(model.rows) do
        out[#out + 1] = labelOf(row)
    end
    return table.concat(out, " | ")
end

local function rowByKey(model, key)
    for _, row in ipairs(model.rows) do
        if row.key == key then
            return row
        end
    end
    return nil
end

-- The screen as the real graph builder draws it.
local function drawn()
    local builder = WowVision.graph.Builder:new()
    Screen.render(builder, {})
    return builder:build()
end

testRunner:addSuite("AtlasLoot", {
    ["without AtlasLoot there is no module and no key"] = function(t)
        local other, nothing = harness.loadOther({})
        t:assertNil(other)
        t:assertEqual(#nothing.bindings, 0)
        t:assertNotNil(harness.loadOther({ AtlasLootContinued = true }))
        t:assertNotNil(harness.loadOther({ atlaslootclassic = true }))
    end,

    ["it registers Alt+L, a command and its settings"] = function(t)
        t:assertEqual(registered.bindings[1].key, "atlasLoot/open")
        t:assertEqual(registered.bindings[1].inputs[1], "ALT-L")
        t:assertNotNil(registered.commands.atlasloot)
        t:assertTrue(module.settings.classFilter)
        t:assertFalse(module.settings.levelFilter)
        t:assertEqual(module.settings.measure, "auto")
        t:assertEqual(module.settings.sort, "default")
        t:assertTrue(module.settings.openWithAl)
    end,

    ["names are spoken without textures and colours"] = function(t)
        t:assertEqual(Loot.clean("|TInterface\\X:0|t |cff00ff00Loot|r  of|nthings "), "Loot of things")
        t:assertEqual(Loot.clean(nil), "")
    end,

    ["modules are listed and brought in as they can be"] = function(t)
        withAtlas(function(world)
            local modules = Loot.modules(world.atlas)
            t:assertEqual(#modules, 3)
            t:assertEqual(modules[1].name, "Test Loot")
            t:assertEqual(modules[3].id, "TestCombat")
            local status, data = Loot.open(world.atlas, "TestLoot")
            t:assertEqual(status, "ready")
            t:assertTrue(data == world.data)
            t:assertEqual(Loot.open(world.atlas, "TestOff"), "disabled")
            t:assertEqual(Loot.open(world.atlas, "TestCombat"), "combat")
            t:assertEqual(Loot.open(world.atlas, "Nothing"), "missing")
        end)
    end,

    ["game versions come in order, the wanted one when there is one"] = function(t)
        withAtlas(function(world)
            local versions = Loot.versions(world.data)
            t:assertEqual(#versions, 2)
            t:assertEqual(versions[1], 1)
            t:assertEqual(Loot.version(world.atlas, world.data, 4), 4)
            t:assertEqual(Loot.version(world.atlas, world.data, 3), 1)
            t:assertEqual(Loot.versionName(world.atlas, 4), "WoW: Forever")
            t:assertEqual(Loot.versionName(world.atlas, 2), "The Burning Crusade")
        end)
    end,

    ["instances are grouped for the version, with their levels"] = function(t)
        withAtlas(function(world)
            local groups = Loot.instances(world.atlas, "TestLoot", world.data, 1)
            t:assertEqual(#groups, 2)
            t:assertEqual(groups[1].name, "Dungeons")
            t:assertEqual(groups[1].list[1].name, "The Mine")
            t:assertEqual(groups[1].list[1].levels, "levels 15 to 20")
            t:assertEqual(groups[2].list[1].name, "The Keep")
            t:assertEqual(#Loot.instances(world.atlas, "TestLoot", world.data, 4), 1)
        end)
    end,

    ["bosses, their difficulties and the nearest one asked for"] = function(t)
        withAtlas(function(world)
            local bosses = Loot.bosses(world.data, "Mine")
            t:assertEqual(#bosses, 3)
            t:assertTrue(bosses[3].extra)
            local diffs = Loot.difficulties(world.data, "Mine", 1)
            t:assertEqual(#diffs, 2)
            t:assertEqual(diffs[2].name, "Heroic!")
            t:assertEqual(Loot.pickDifficulty(diffs, 2), 2)
            t:assertEqual(Loot.pickDifficulty(diffs, nil), 1)
            t:assertEqual(Loot.pickDifficulty({ { id = 1 }, { id = 3 } }, 2), 1)
            t:assertNil(Loot.pickDifficulty({}, 1))
        end)
    end,

    ["a table is read in AtlasLoot's order, with headers and the faction's item"] = function(t)
        withAtlas(function(world)
            local entries = Loot.table(world.atlas, "TestLoot", "Mine", 1, 1, Game, 11)
            local seen = {}
            for _, entry in ipairs(entries) do
                seen[#seen + 1] = entry.kind == "header" and entry.name or entry.id
            end
            t:assertEqual(table.concat(seen, ","), "101,102,Forever,104")
            world.faction = "Alliance"
            entries = Loot.table(world.atlas, "TestLoot", "Mine", 1, 1, Game, 11)
            t:assertEqual(entries[4].id, 103)
            t:assertEqual(#Loot.table(world.atlas, "TestLoot", "Mine", 3, nil, Game), 0)
        end)
    end,

    ["the filters hide what the class cannot use, what the level does not allow and other slots"] = function(t)
        withAtlas(function(world)
            local entries = Loot.table(world.atlas, "TestLoot", "Mine", 1, 1, Game, 11)
            world.faction = "Alliance"
            entries = Loot.table(world.atlas, "TestLoot", "Mine", 1, 1, Game, 11)
            local visible, hidden = Loot.visible(entries, { classFilter = true }, Game)
            t:assertEqual(hidden, 1)
            t:assertEqual(Loot.count(visible), 2)
            -- a header with nothing left under it goes
            t:assertEqual(#visible, 2)
            visible, hidden = Loot.visible(entries, { levelFilter = true }, Game)
            t:assertEqual(hidden, 1)
            visible = Loot.visible(entries, { slot = "feet" }, Game)
            t:assertEqual(Loot.count(visible), 1)
        end)
    end,

    ["only upgrades keeps what is above what is worn"] = function(t)
        withAtlas(function(world)
            local entries = Loot.table(world.atlas, "TestLoot", "Mine", 1, 1, Game, 11)
            local visible = Loot.visible(entries, { upgradesOnly = true }, Game)
            t:assertEqual(Loot.count(visible), 1)
            t:assertEqual(visible[1].id, 102)
        end)
    end,

    ["percentages are spoken with a decimal comma where it is read"] = function(t)
        t:assertEqual(Loot.number(-4.25, "frFR"), "4,2")
        t:assertEqual(Loot.number(3, "enUS"), "3")
    end,

    ["the screen goes down from the categories to a boss's loot and back"] = function(t)
        withAtlas(function(world)
            local model = Screen.model(world.atlas)
            t:assertEqual(rowsOf(model), "Test Loot | Off | Later")
            rowByKey(model, "module:TestLoot").activate()
            model = Screen.model(world.atlas)
            t:assertNotNil(rowByKey(model, "version"))
            t:assertNotNil(rowByKey(model, "search"))
            rowByKey(model, "instance:Mine").activate()
            model = Screen.model(world.atlas)
            t:assertNotNil(rowByKey(model, "whole"))
            rowByKey(model, "boss:1").activate()
            model = Screen.model(world.atlas)
            t:assertEqual(model.hidden, 0)
            t:assertTrue(rowsOf(model):find("Pick", 1, true) ~= nil)
            t:assertTrue(world.requested[101])
            Screen.back()
            Screen.back()
            Screen.back()
            t:assertEqual(Screen.state.level, "modules")
            world.open = true
            Screen.back()
            t:assertEqual(world.closed, 1)
        end)
    end,

    ["a module that cannot be read says why"] = function(t)
        withAtlas(function(world)
            rowByKey(Screen.model(world.atlas), "module:TestOff").activate()
            t:assertEqual(world.spoken[1], "That AtlasLoot module is disabled.")
            t:assertEqual(Screen.state.level, "modules")
        end)
    end,

    ["the loot level says how many items the filters hid"] = function(t)
        withAtlas(function(world)
            world.faction = "Alliance"
            rowByKey(Screen.model(world.atlas), "module:TestLoot").activate()
            rowByKey(Screen.model(world.atlas), "instance:Mine").activate()
            rowByKey(Screen.model(world.atlas), "boss:1").activate()
            local model = Screen.model(world.atlas)
            t:assertEqual(model.hidden, 1)
            t:assertEqual(model.shown, 2)
            t:assertTrue(Screen.summary(model):find("Hidden by the filters: 1", 1, true) ~= nil)
        end)
    end,

    ["the screen draws through the real graph builder, the filters on the loot level only"] = function(t)
        withAtlas(function(world)
            local rendered = drawn()
            local stops = {}
            for _, node in ipairs(rendered.order) do
                stops[node.stopKey] = true
            end
            t:assertTrue(stops.list and stops.navigation)
            t:assertNil(stops.filters)
            rowByKey(Screen.model(world.atlas), "module:TestLoot").activate()
            rowByKey(Screen.model(world.atlas), "instance:Mine").activate()
            rowByKey(Screen.model(world.atlas), "boss:1").activate()
            rendered = drawn()
            stops = {}
            for _, node in ipairs(rendered.order) do
                stops[node.stopKey] = true
            end
            t:assertTrue(stops.filters)
        end)
    end,

    ["the key opens the screen and closes it, and says when AtlasLoot is missing"] = function(t)
        withAtlas(function(world)
            registered.bindings[1].func()
            t:assertTrue(world.open)
            t:assertTrue(world.config.captureClose)
            registered.commands.atlasloot.func()
            t:assertFalse(world.open)
            Game.atlas = function()
                return nil
            end
            ns.toggle()
            t:assertFalse(world.open)
            t:assertEqual(world.spoken[1], "AtlasLoot is not installed or not enabled.")
        end)
    end,

    ["AtlasLoot's window opens the screen and closing the screen closes it"] = function(t)
        withAtlas(function(world)
            local scripts, hidden = {}, 0
            world.frame = {
                HookScript = function(_, name, fn)
                    scripts[name] = fn
                end,
                IsShown = function()
                    return true
                end,
                Hide = function()
                    hidden = hidden + 1
                end,
            }
            module:onEvent("ADDON_LOADED")
            t:assertNotNil(scripts.OnShow)
            scripts.OnShow()
            t:assertTrue(world.open)
            t:assertTrue(ns.openedByAl)
            Screen.close()
            t:assertEqual(hidden, 1)
            scripts.OnShow()
            scripts.OnHide()
            t:assertFalse(world.open)
            world.settings.openWithAl = false
            local savedSetting = module.settings.openWithAl
            module.settings.openWithAl = false
            scripts.OnShow()
            module.settings.openWithAl = savedSetting
            t:assertFalse(world.open)
        end)
    end,

    ["gear and level changes, and item answers, reach the browser"] = function(t)
        withAtlas(function()
            local changed, received = 0, {}
            Game.gearChanged = function()
                changed = changed + 1
            end
            Game.itemReceived = function(id, success)
                received[#received + 1] = tostring(id) .. tostring(success)
            end
            module:onEvent("PLAYER_EQUIPMENT_CHANGED")
            module:onEvent("PLAYER_LEVEL_UP")
            module:onEvent("GET_ITEM_INFO_RECEIVED", 5, false)
            t:assertEqual(changed, 2)
            t:assertEqual(received[1], "5false")
        end)
    end,
})
