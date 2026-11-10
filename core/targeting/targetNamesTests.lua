local testRunner = WowVision.testing.testRunner
local targetNames = WowVision.targetNames

-- A stand-in for the game: units by token, each a table of what the calls
-- return. Missing fields read as nil, like the game for a fact it lacks.
local function fakeApi(units, options)
    options = options or {}
    local function u(unit)
        return units[unit] or {}
    end
    local api = {
        UnitExists = function(unit)
            return units[unit] ~= nil
        end,
        UnitIsGameObject = function(unit)
            return u(unit).object == true
        end,
        UnitGUID = function(unit)
            return u(unit).guid
        end,
        UnitIsPlayer = function(unit)
            return u(unit).player == true
        end,
        UnitPlayerControlled = function(unit)
            return u(unit).controlled == true
        end,
        UnitCanAttack = function(_, unit)
            return u(unit).attackable == true
        end,
        UnitName = function(unit)
            return u(unit).name, u(unit).realm
        end,
        UnitPVPName = function(unit)
            return u(unit).pvpName or u(unit).name
        end,
        UnitLevel = function(unit)
            return u(unit).level
        end,
        UnitRace = function(unit)
            return u(unit).race
        end,
        UnitClass = function(unit)
            return u(unit).class
        end,
        UnitSex = function(unit)
            return u(unit).sex
        end,
        UnitFactionGroup = function(unit)
            return u(unit).faction and "Alliance" or nil, u(unit).faction
        end,
        UnitGroupRolesAssigned = function(unit)
            return u(unit).role or "NONE"
        end,
        UnitIsPVP = function(unit)
            return u(unit).pvp == true
        end,
        UnitIsPVPFreeForAll = function(unit)
            return u(unit).ffa == true
        end,
        UnitIsAFK = function(unit)
            return u(unit).afk
        end,
        UnitIsDND = function(unit)
            return u(unit).dnd
        end,
        UnitIsDead = function(unit)
            return u(unit).dead == true
        end,
        UnitIsGhost = function(unit)
            return u(unit).ghost == true
        end,
        UnitIsCharmed = function(unit)
            return u(unit).charmed == true
        end,
        UnitAffectingCombat = function(unit)
            if unit == "player" then
                return options.combat == true
            end
            return u(unit).combat == true
        end,
        UnitClassification = function(unit)
            return u(unit).classification or "normal"
        end,
        UnitIsBossMob = function(unit)
            return u(unit).bossMob == true
        end,
        UnitCreatureType = function(unit)
            return u(unit).creatureType, u(unit).creatureTypeId
        end,
        UnitCreatureFamily = function(unit)
            return u(unit).family
        end,
        UnitReaction = function(unit)
            return u(unit).reaction
        end,
        UnitIsQuestBoss = function(unit)
            return u(unit).questBoss == true
        end,
        UnitIsTapDenied = function(unit)
            return u(unit).tapped == true
        end,
        UnitIsOwnerOrControllerOfUnit = function(_, unit)
            return u(unit).mine == true
        end,
        GetGuildInfo = function(unit)
            return u(unit).guild
        end,
        questRelated = function(unit)
            return u(unit).quest == true
        end,
        tooltipLines = function(unit)
            return u(unit).lines
        end,
        playerInCombat = function()
            return options.combat == true
        end,
    }
    for _, name in ipairs(options.missing or {}) do
        api[name] = nil
    end
    return api
end

-- The game's secrets, simulated: a table that joins into another secret and
-- that issecretvalue recognises. reveal reads what speech would hear.
local SecretMeta = {}
local function secret(value)
    return setmetatable({ secretValue = value }, SecretMeta)
end
local function reveal(value)
    if type(value) == "table" and value.secretValue ~= nil then
        return value.secretValue
    end
    return tostring(value)
end
SecretMeta.__concat = function(a, b)
    return secret(reveal(a) .. reveal(b))
end

local function withSecrets(fn)
    return function(t)
        local saved = issecretvalue
        issecretvalue = function(value)
            return type(value) == "table" and getmetatable(value) == SecretMeta
        end
        local ok, err = pcall(fn, t)
        issecretvalue = saved
        if not ok then
            error(err, 0)
        end
    end
end

-- One state's table with only the given parts on for a category.
local function only(category, parts)
    local saved = {}
    for _, entry in ipairs(targetNames.ORDER[category]) do
        saved[entry[1]] = false
    end
    for _, key in ipairs(parts) do
        saved[key] = true
    end
    return { [category] = saved }
end

local WARRIOR = {
    player = true,
    name = "Broesel",
    pvpName = "Sergeant Broesel",
    realm = "Everlook",
    guild = "Die Waechter",
    level = 60,
    race = "Human",
    class = "Warrior",
    sex = 2,
    faction = "Alliance",
    role = "TANK",
    pvp = true,
    afk = true,
}

local HOGGER = {
    attackable = true,
    name = "Hogger",
    level = 11,
    classification = "elite",
    creatureType = "Humanoid",
    creatureTypeId = 7,
    family = nil,
    reaction = 2,
    questBoss = true,
    quest = true,
    tapped = true,
    lines = {
        { type = 2, text = "Hogger" },
        { type = 47, text = "Level 11 Elite Humanoid" },
        { type = 8, text = "Hogger slain: 0/1" },
        { type = 8, text = "Done already: 1/1", completed = true },
    },
}

local INNKEEPER = {
    name = "Innkeeper Farley",
    level = 30,
    reaction = 5,
    lines = {
        { type = 2, text = "Innkeeper Farley" },
        { type = 0, text = "<Innkeeper>" },
        { type = 47, text = "Level 30 Humanoid" },
    },
}

testRunner:addSuite("TargetNames", {
    -- Categories ----------------------------------------------------------------

    ["classify sorts players, NPCs, mobs, pets and totems"] = function(t)
        local api = fakeApi({
            target = WARRIOR,
            npc = INNKEEPER,
            mob = HOGGER,
            pet = { controlled = true, name = "Wolf", creatureTypeId = 1 },
            totem = { controlled = true, name = "Searing Totem", creatureTypeId = 11 },
        })
        t:assertEqual(targetNames.classify(api, "target"), "player")
        t:assertEqual(targetNames.classify(api, "npc"), "npc")
        t:assertEqual(targetNames.classify(api, "mob"), "mob")
        t:assertEqual(targetNames.classify(api, "pet"), "pet")
        t:assertEqual(targetNames.classify(api, "totem"), "totem")
    end,

    ["no unit and game objects have no category: the tooltip stays"] = function(t)
        local api = fakeApi({ softinteract = { object = true, name = "Mailbox" } })
        t:assertNil(targetNames.classify(api, "target"))
        t:assertNil(targetNames.classify(api, "softinteract"))
        t:assertNil(targetNames.compose(api, "softinteract", "outOfCombat", nil))
    end,

    ["without UnitIsGameObject the GUID tells objects apart"] = function(t)
        local api = fakeApi({
            softinteract = { guid = "GameObject-0-1-2-3-4-5" },
            softfriend = { guid = "Creature-0-1-2-3-4-5", name = "Guard" },
        }, { missing = { "UnitIsGameObject" } })
        t:assertNil(targetNames.classify(api, "softinteract"))
        t:assertEqual(targetNames.classify(api, "softfriend"), "npc")
    end,

    -- Combat state --------------------------------------------------------------

    ["in combat the in-combat parts are used"] = function(t)
        local names = {
            inCombat = only("mob", { "name", "level" }),
            outOfCombat = only("mob", { "name", "creatureType" }),
        }
        local text = targetNames.describe(fakeApi({ target = HOGGER }, { combat = true }), "target", names)
        t:assertEqual(text, "Hogger, Level 11")
    end,

    ["out of combat the out-of-combat parts are used"] = function(t)
        local names = {
            inCombat = only("mob", { "name", "level" }),
            outOfCombat = only("mob", { "name", "creatureType" }),
        }
        local text = targetNames.describe(fakeApi({ target = HOGGER }, { combat = false }), "target", names)
        t:assertEqual(text, "Hogger, Humanoid")
    end,

    ["the combat state is read when the announcement is built"] = function(t)
        local options = { combat = false }
        local api = fakeApi({ target = HOGGER }, options)
        local names = {
            inCombat = only("mob", { "name" }),
            outOfCombat = only("mob", { "level" }),
        }
        t:assertEqual(targetNames.describe(api, "target", names), "Level 11")
        options.combat = true
        t:assertEqual(targetNames.describe(api, "target", names), "Hogger")
    end,

    -- Composition ---------------------------------------------------------------

    ["the default player announcement out of combat"] = function(t)
        local text = targetNames.compose(fakeApi({ target = WARRIOR }), "target", "outOfCombat", nil)
        t:assertEqual(text, "Sergeant Broesel, Guild Die Waechter, Level 60, Human Warrior")
    end,

    ["the default player announcement in combat"] = function(t)
        local text = targetNames.compose(fakeApi({ target = WARRIOR }), "target", "inCombat", nil)
        t:assertEqual(text, "Broesel, Warrior")
    end,

    ["every player part in order"] = function(t)
        local parts = {}
        for _, entry in ipairs(targetNames.ORDER.player) do
            tinsert(parts, entry[1])
        end
        local unit = {}
        for k, v in pairs(WARRIOR) do
            unit[k] = v
        end
        unit.dnd, unit.charmed, unit.combat, unit.ffa = true, true, true, true
        local text = targetNames.compose(fakeApi({ target = unit }), "target", "outOfCombat", only("player", parts))
        t:assertEqual(
            text,
            "Sergeant Broesel, Realm Everlook, Guild Die Waechter, Level 60, Human Warrior, Male, Alliance, Tank,"
                .. " Free-for-All PvP, AFK, Do Not Disturb, Charmed, In Combat"
        )
    end,

    ["a player's title alone is cut out of the full name"] = function(t)
        local text = targetNames.compose(fakeApi({ target = WARRIOR }), "target", "outOfCombat", only("player", { "title" }))
        t:assertEqual(text, "Sergeant")
    end,

    ["a player without a title says the name once"] = function(t)
        local unit = { player = true, name = "Broesel" }
        local text =
            targetNames.compose(fakeApi({ target = unit }), "target", "outOfCombat", only("player", { "name", "title" }))
        t:assertEqual(text, "Broesel")
    end,

    ["a dead player and a ghost"] = function(t)
        local api = fakeApi({ a = { player = true, name = "A", dead = true }, b = { player = true, name = "B", ghost = true, dead = true } })
        t:assertEqual(targetNames.compose(api, "a", "inCombat", only("player", { "name", "dead" })), "A, Dead")
        t:assertEqual(targetNames.compose(api, "b", "inCombat", only("player", { "name", "dead" })), "B, Ghost")
    end,

    ["every mob part in order"] = function(t)
        local parts = {}
        for _, entry in ipairs(targetNames.ORDER.mob) do
            tinsert(parts, entry[1])
        end
        local text = targetNames.compose(fakeApi({ target = HOGGER }), "target", "outOfCombat", only("mob", parts))
        t:assertEqual(
            text,
            "Hogger, Level 11 Elite, Humanoid, Hostile, Quest Boss, Quest Target, Hogger slain: 0/1, Tapped by Others"
        )
    end,

    ["the default mob announcement in combat"] = function(t)
        local mob = { attackable = true, name = "Defias Thug", level = 10, classification = "rareelite", dead = true }
        local text = targetNames.compose(fakeApi({ target = mob }), "target", "inCombat", nil)
        t:assertEqual(text, "Defias Thug, Level 10 Rare Elite, Dead")
    end,

    ["an NPC's title comes from the line between name and level"] = function(t)
        local text = targetNames.compose(fakeApi({ target = INNKEEPER }), "target", "outOfCombat", nil)
        t:assertEqual(text, "Innkeeper Farley, Innkeeper, Level 30")
    end,

    ["untyped tooltip lines: the title only when the next line has the level"] = function(t)
        local untyped = {
            name = "Farley",
            level = 30,
            lines = { { text = "Farley" }, { text = "<Innkeeper>" }, { text = "Level 30 Humanoid" } },
        }
        local noTitle = {
            name = "Wolf",
            level = 5,
            lines = { { text = "Wolf" }, { text = "Level 5 Beast" } },
        }
        local api = fakeApi({ a = untyped, b = noTitle })
        t:assertEqual(targetNames.compose(api, "a", "outOfCombat", only("npc", { "title" })), "Innkeeper")
        t:assertEqual(targetNames.compose(api, "b", "outOfCombat", only("npc", { "title" })), "")
    end,

    ["WoW: Forever lines: only the name typed, the title found by the level"] = function(t)
        -- As a WoW: Forever capture shows them: no UnitLevel line type.
        local innkeeper = {
            name = "Donaal Downbreeze",
            level = 10,
            reaction = 5,
            lines = {
                { type = 2, text = "Donaal Downbreeze" },
                { type = 0, text = "Gastwirt" },
                { type = 0, text = "Stufe 10" },
                { type = 0, text = "PvP" },
            },
        }
        local questMob = {
            attackable = true,
            name = "Kobold",
            level = 2,
            lines = {
                { type = 2, text = "Kobold" },
                { type = 0, text = "Stufe 2" },
                { type = 0, text = "Humanoid" },
                { type = 17, text = "Kobolde" },
                { type = 8, text = "Kobold getötet: 2/8" },
            },
        }
        local api = fakeApi({ a = innkeeper, b = questMob })
        t:assertEqual(targetNames.compose(api, "a", "outOfCombat", only("npc", { "title" })), "Gastwirt")
        t:assertEqual(targetNames.compose(api, "b", "outOfCombat", only("mob", { "title" })), "")
    end,

    ["a skull level"] = function(t)
        local boss = { attackable = true, name = "Onyxia", level = -1, classification = "worldboss" }
        local text = targetNames.compose(fakeApi({ target = boss }), "target", "inCombat", nil)
        t:assertEqual(text, "Onyxia, Skull Level World Boss")
    end,

    ["pets name their owner, from the tooltip or as yours"] = function(t)
        local api = fakeApi({
            a = { controlled = true, name = "Wolf", lines = { { type = 2, text = "Wolf" }, { type = 16, text = "Broesel's Pet" } } },
            b = { controlled = true, name = "Imp", mine = true },
        })
        t:assertEqual(targetNames.compose(api, "a", "inCombat", nil), "Wolf, Broesel's Pet")
        t:assertEqual(targetNames.compose(api, "b", "inCombat", nil), "Imp, Yours")
    end,

    ["switched-off parts are left out"] = function(t)
        local text = targetNames.compose(fakeApi({ target = WARRIOR }), "target", "outOfCombat", only("player", { "class" }))
        t:assertEqual(text, "Warrior")
        t:assertEqual(targetNames.compose(fakeApi({ target = WARRIOR }), "target", "outOfCombat", only("player", {})), "")
    end,

    -- Missing and invalid values ------------------------------------------------

    ["facts the unit lacks are skipped: nil, empty, unknown codes"] = function(t)
        local unit = { player = true, name = "Broesel", guild = "", race = nil, class = "Mage", sex = 1, role = "NONE", level = 0 }
        local text = targetNames.compose(
            fakeApi({ target = unit }),
            "target",
            "outOfCombat",
            only("player", { "name", "guild", "level", "race", "class", "sex", "role", "realm", "pvp", "afk" })
        )
        t:assertEqual(text, "Broesel, Mage")
    end,

    ["a call the client lacks: the part is not offered and says nothing"] = function(t)
        local api = fakeApi({ target = WARRIOR }, { missing = { "UnitRace", "GetGuildInfo" } })
        t:assertFalse(targetNames.available(api, "race", "player"))
        t:assertTrue(targetNames.available(api, "class", "player"))
        local text = targetNames.compose(api, "target", "outOfCombat", only("player", { "name", "race", "guild", "class" }))
        t:assertEqual(text, "Broesel, Warrior")
    end,

    ["a call that errors says nothing"] = function(t)
        local api = fakeApi({ target = WARRIOR })
        api.UnitRace = function()
            error("boom")
        end
        local text = targetNames.compose(api, "target", "outOfCombat", only("player", { "name", "race", "class" }))
        t:assertEqual(text, "Broesel, Warrior")
    end,

    ["the menu offers only parts the client has"] = function(t)
        local api = fakeApi({}, { missing = { "tooltipLines" } })
        local def = targetNames.settingsDef(api)
        local outOfCombat = def.fields[3]
        t:assertEqual(outOfCombat.key, "outOfCombat")
        local npc = outOfCombat.fields[2]
        t:assertEqual(npc.key, "npc")
        local shown = {}
        for _, field in ipairs(npc.fields) do
            shown[field.key] = field.showInUI
        end
        t:assertFalse(shown.title)
        t:assertFalse(shown.questProgress)
        t:assertTrue(shown.name)
        -- A player's title reads the full name, not the tooltip.
        t:assertTrue(outOfCombat.fields[1].fields[2].showInUI)
    end,

    -- Duplicates ----------------------------------------------------------------

    ["Classification and Elite say Elite once"] = function(t)
        local text = targetNames.compose(
            fakeApi({ target = HOGGER }),
            "target",
            "inCombat",
            only("mob", { "name", "classification", "elite", "rare" })
        )
        t:assertEqual(text, "Hogger, Elite")
    end,

    ["a rare elite through Classification, Rare and Elite"] = function(t)
        local mob = { attackable = true, name = "Rare", classification = "rareelite", level = 20 }
        local text =
            targetNames.compose(fakeApi({ target = mob }), "target", "inCombat", only("mob", { "level", "rare", "elite", "classification" }))
        t:assertEqual(text, "Level 20 Rare Elite")
    end,

    ["the same text from two parts is said once"] = function(t)
        local beast = { attackable = true, name = "Wolf", creatureType = "Beast", family = "Beast" }
        local text = targetNames.compose(
            fakeApi({ target = beast }),
            "target",
            "inCombat",
            only("mob", { "name", "creatureType", "creatureFamily" })
        )
        t:assertEqual(text, "Wolf, Beast")
    end,

    ["a boss mob is Boss once, a world boss World Boss"] = function(t)
        local api = fakeApi({
            a = { attackable = true, name = "Van Cleef", bossMob = true },
            b = { attackable = true, name = "Kazzak", classification = "worldboss", bossMob = true },
        })
        t:assertEqual(targetNames.compose(api, "a", "inCombat", only("mob", { "name", "boss", "classification" })), "Van Cleef, Boss")
        t:assertEqual(targetNames.compose(api, "b", "inCombat", only("mob", { "name", "boss", "classification" })), "Kazzak, World Boss")
    end,

    -- Secrets -------------------------------------------------------------------

    ["a secret name is joined, never compared"] = withSecrets(function(t)
        local mob = { attackable = true, name = secret("Hogger"), level = 11, classification = "elite" }
        local text = targetNames.compose(fakeApi({ target = mob }), "target", "inCombat", nil)
        t:assertEqual(reveal(text), "Hogger, Level 11 Elite")
    end),

    ["a secret answer to a yes-or-no question is skipped"] = withSecrets(function(t)
        local unit = { player = true, name = "Broesel", afk = secret(true), dnd = secret(false) }
        local text =
            targetNames.compose(fakeApi({ target = unit }), "target", "outOfCombat", only("player", { "name", "afk", "dnd" }))
        t:assertEqual(text, "Broesel")
    end),

    ["two secret texts are both said: no comparison is possible"] = withSecrets(function(t)
        local beast = { attackable = true, name = secret("Wolf"), creatureType = secret("Beast"), family = secret("Beast") }
        local text = targetNames.compose(
            fakeApi({ target = beast }),
            "target",
            "inCombat",
            only("mob", { "name", "creatureType", "creatureFamily" })
        )
        t:assertEqual(reveal(text), "Wolf, Beast Beast")
    end),

    ["a secret level is still said"] = withSecrets(function(t)
        local mob = { attackable = true, name = "Hogger", level = secret(11) }
        local text = targetNames.compose(fakeApi({ target = mob }), "target", "inCombat", only("mob", { "name", "level" }))
        t:assertEqual(reveal(text), "Hogger, Level 11")
    end),

    -- Settings: defaults, saving, migration, reset, menu -------------------------

    ["defaults differ between the combat states"] = function(t)
        t:assertTrue(targetNames.defaultFor("outOfCombat", "player", "guild"))
        t:assertFalse(targetNames.defaultFor("inCombat", "player", "guild"))
        t:assertTrue(targetNames.defaultFor("inCombat", "mob", "elite"))
        t:assertFalse(targetNames.defaultFor("inCombat", "npc", "level"))
        local enabled = targetNames.enabledParts(nil, "inCombat", "npc")
        t:assertTrue(enabled.name)
        t:assertFalse(enabled.title)
    end,

    ["the configured announcement switched off falls back to the tooltip"] = function(t)
        local api = fakeApi({ target = HOGGER })
        t:assertNil(targetNames.describe(api, "target", { enabled = false }))
        -- Settings from before this feature: no Names table yet.
        t:assertNil(targetNames.describe(api, "target", nil))
    end,

    ["settings save to the store and come back after a reload"] = function(t)
        local api = fakeApi({ target = HOGGER }, { combat = true })
        local Settings = WowVision.Class("TargetNamesTestSettings")
        local def = targetNames.settingsDef(api)
        def.persist = true
        Settings:addFields({ def })
        local first = Settings:new()
        local store = first:getDefaultDB("global")
        first:setDB({ global = store })
        t:assertFalse(store.names.enabled)
        t:assertTrue(store.names.inCombat.mob.level)
        t:assertFalse(store.names.inCombat.player.guild)
        t:assertTrue(store.names.outOfCombat.player.guild)

        -- A checkbox write lands in the saved table (by reference).
        first.names.enabled = true
        first.names.inCombat.mob.level = false
        t:assertFalse(store.names.inCombat.mob.level)

        local second = Settings:new()
        second:setDB({ global = store })
        t:assertFalse(second.names.inCombat.mob.level)
        t:assertEqual(targetNames.describe(api, "target", second.names), "Hogger, Elite")
    end,

    ["saved settings from before Names gain the defaults, nothing is lost"] = function(t)
        local api = fakeApi({})
        local Settings = WowVision.Class("TargetNamesMigrationSettings")
        local def = targetNames.settingsDef(api)
        def.persist = true
        Settings:addFields({ def, { key = "softTargetLock", type = "String", default = "gameDefault", persist = true } })
        local defaults = Settings:new():getDefaultDB("global")

        local old = { softTargetLock = "always" }
        local reconciled = WowVision.dbManager:reconcile(defaults, old)
        t:assertEqual(reconciled.softTargetLock, "always")
        t:assertFalse(reconciled.names.enabled)
        t:assertTrue(reconciled.names.outOfCombat.npc.title)

        -- A partly saved Names table keeps every choice and gains the rest.
        local partial = { names = { enabled = false, inCombat = { mob = { name = false, unknownPart = true } } } }
        reconciled = WowVision.dbManager:reconcile(defaults, partial)
        t:assertFalse(reconciled.names.enabled)
        t:assertFalse(reconciled.names.inCombat.mob.name)
        t:assertTrue(reconciled.names.inCombat.mob.unknownPart)
        t:assertTrue(reconciled.names.inCombat.mob.level)
        t:assertTrue(reconciled.names.inCombat.player.name)
        t:assertTrue(reconciled.names.outOfCombat.player.guild)
    end,

    ["a part added after the settings were saved reads its default"] = function(t)
        local saved = { mob = { name = true } }
        local enabled = targetNames.enabledParts(saved, "outOfCombat", "mob")
        t:assertTrue(enabled.name)
        t:assertTrue(enabled.level)
        t:assertFalse(enabled.charmed)
    end,

    ["reset puts one state back to its defaults in place"] = function(t)
        local state = only("mob", { "creatureFamily" })
        local mobTable = state.mob
        targetNames.reset(state, "inCombat")
        t:assertTrue(state.mob == mobTable)
        t:assertTrue(state.mob.name)
        t:assertFalse(state.mob.creatureFamily)
        t:assertTrue(state.player.class)
        t:assertFalse(state.player.guild)
    end,

    ["the menu: Names, a combat state, a category, a checkbox, reset"] = function(t)
        local graph = WowVision.graph
        local api = fakeApi({}, { missing = { "tooltipLines" } })
        local Settings = WowVision.Class("TargetNamesMenuSettings")
        local def = targetNames.settingsDef(api)
        def.persist = true
        Settings:addFields({ def })
        local obj = Settings:new()
        local store = obj:getDefaultDB("global")
        obj:setDB({ global = store })

        local pushed
        local savedHost, savedSpeak = WowVision.graphHost, WowVision.speak
        local spoken
        WowVision.graphHost = {
            focusedStack = function()
                return {}
            end,
            push = function(_, _, screen)
                pushed = screen
            end,
        }
        WowVision.speak = function(_, text)
            spoken = text
        end
        local ok, err = pcall(function()
            local function open(vtable)
                pushed = nil
                vtable.onActivate()
                local builder = graph.Builder:new()
                pushed.render(builder)
                return builder:build().nodes
            end
            local namesField = Settings:getField("names")
            local top = open(graph.settings.controlFor(namesField, obj))
            t:assertNotNil(top["field:enabled"])
            local combat = open(top["field:inCombat"].vtable)
            t:assertNotNil(combat["field:reset"])
            local mobs = open(combat["field:mob"].vtable)
            local level = mobs["field:level"].vtable
            t:assertEqual(level.stateText(), "Checked")
            level.onActivate()
            t:assertFalse(store.names.inCombat.mob.level)
            t:assertEqual(level.stateText(), "Unchecked")
            -- Unoffered parts have no checkbox.
            t:assertNil(mobs["field:questProgress"])

            combat["field:reset"].vtable.onActivate()
            t:assertTrue(store.names.inCombat.mob.level)
            t:assertEqual(spoken, "Defaults restored")
        end)
        WowVision.graphHost, WowVision.speak = savedHost, savedSpeak
        if not ok then
            error(err, 0)
        end
    end,
})
