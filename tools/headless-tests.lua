-- Headless runner for the WoW-independent test suites (currently the graph
-- core). Runs under a plain Lua interpreter, no game client needed.
--
-- Usage, from the repo root:
--   lua tools/headless-tests.lua [suiteFilter] [-v]
--
-- Only files with no WoW API dependencies can be loaded here; in-game suites
-- still run through /wowvision test.

tinsert = table.insert
tremove = table.remove
unpack = unpack or table.unpack

-- WoW API stand-in: records the run script on the fake frame.
function ExecuteFrameScript(frame, script)
    if frame._scripts ~= nil then
        tinsert(frame._scripts, script)
    end
end

local namespace = {}
local function loadAddonFile(path)
    local chunk, err = loadfile(path)
    if chunk == nil then
        error(err)
    end
    return chunk("WowVision", namespace)
end

loadAddonFile("core/Class.lua")
loadAddonFile("core/fieldTypes.lua")

WowVision = {
    Class = namespace.Class, -- the new class library (core/Class.lua)
    NewClass = namespace.Class,
    classes = namespace.classes,
}

function WowVision:getLocale()
    -- Untranslated keys read back as themselves, like AceLocale's fallback.
    return setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })
end

loadAddonFile("core/testing/TestRunner.lua")

loadAddonFile("core/Event.lua")
loadAddonFile("core/navigation/maps/Router.lua")
loadAddonFile("core/navigation/maps/routerTests.lua")
loadAddonFile("core/navigation/atlas/MapDataset.lua")
loadAddonFile("core/navigation/atlas/datasetTests.lua")
loadAddonFile("core/navigation/stuckMath.lua")
loadAddonFile("core/navigation/stuckTests.lua")
loadAddonFile("core/ClassTests.lua")

-- The component registry and the systems above it, all on the class library.
loadAddonFile("core/Registry.lua")
loadAddonFile("core/components/components.lua")
loadAddonFile("core/components/RegistryType.lua")
loadAddonFile("core/components/ClassRegistryType.lua")
loadAddonFile("core/components/ComponentRegistry.lua")
loadAddonFile("core/components/tests.lua")

-- Alerts construct at every module load in game; a construction smoke here
-- catches recursion/typo failures the parse check cannot.
loadAddonFile("core/alerts/alerts.lua")
-- The buffer family on the new class system: construction and db round trip.
loadAddonFile("core/ViewList.lua")
loadAddonFile("core/buffers/Buffer.lua")
loadAddonFile("core/buffers/BufferItem.lua")
loadAddonFile("core/buffers/items/ObjectItem.lua")
loadAddonFile("core/buffers/items/MessageItem.lua")
loadAddonFile("core/buffers/BufferGroup.lua")
loadAddonFile("core/buffers/types/StaticBuffer.lua")
loadAddonFile("core/buffers/types/TrackedBuffer.lua")
WowVision.testing.testRunner:addSuite("BufferConstruction", {
    ["a static buffer constructs and persists through the root group"] = function(t)
        local db = { items = { _type = "array" } }
        local root = WowVision.buffers.RootBufferGroup:new(db)
        root:setDB(db)
        t:assertEqual(root.enabled, true)

        local group = WowVision.buffers:create("Group", { label = "My Group" })
        root:addBuffer(group)
        t:assertEqual(db.items[1].label, "My Group")
        t:assertEqual(db.items[1].type, "Group")

        local static = WowVision.buffers:create("Static", { label = "Things" })
        group:addBuffer(static)
        t:assertEqual(db.items[1].items[1].label, "Things")

        -- Field writes persist into the nested config
        static.label = "Renamed"
        t:assertEqual(db.items[1].items[1].label, "Renamed")

        -- Restore rebuilds the whole tree from configs
        local again = WowVision.buffers.RootBufferGroup:new(db)
        again:setDB(db)
        t:assertEqual(again.items[1].label, "My Group")
        t:assertEqual(again.items[1].items[1].label, "Renamed")
    end,
})

-- Monitors and rules on the new class system.
loadAddonFile("classic/monitors/Rule.lua")
loadAddonFile("classic/monitors/Monitor.lua")
loadAddonFile("classic/monitors/rules/StateRule.lua")
WowVision.testing.testRunner:addSuite("MonitorConstruction", {
    ["a monitor with a state rule round-trips its db"] = function(t)
        local StateRule = WowVision.monitors.ruleRegistry.types:get("State")
        t:assertNotNil(StateRule)
        local db = { monitors = { _type = "array" } }
        local container = { monitors = {} }
        local field = WowVision.classes.newField({
            key = "monitors",
            type = "ComponentArray",
            persist = true,
            factory = function(config)
                return WowVision.monitors.registry:createTemporaryComponent(config)
            end,
            getTypeKey = function(instance)
                return "Aura"
            end,
        })
        -- A plain Monitor stands in for the WoW-API-dependent types here.
        WowVision.monitors.registry.types:register("Aura", WowVision.monitors.Monitor)
        field:setDB(container, db)

        field:addElement(container, { type = "Aura", label = "Test Monitor" })
        t:assertEqual(db.monitors[1].label, "Test Monitor")

        local monitor = container.monitors[1]
        monitor.enabled = false
        t:assertEqual(db.monitors[1].enabled, false)

        local container2 = { monitors = {} }
        field:setDB(container2, db)
        t:assertEqual(container2.monitors[1].label, "Test Monitor")
        t:assertEqual(container2.monitors[1].enabled, false)
    end,
})

-- Module settings as fields: the per-module settings class contract
-- (Module.lua itself is WoW-bound, so the shape is replicated here).
WowVision.testing.testRunner:addSuite("ModuleSettings", {
    ["settings declare, read, persist, and restore"] = function(t)
        local mod = { key = "fake" }
        local settingsClass = WowVision.Class("Settings:fake")
        local settingsObj = settingsClass:new()
        mod.settings = settingsObj
        settingsClass:addFields({
            { key = "volume", type = "Number", default = 80, persist = true, setting = true },
            { key = "muted", type = "Bool", default = false, persist = true, setting = true },
        })
        t:assertEqual(mod.settings.volume, 80)

        local node = { volume = 40, muted = true }
        settingsObj:setDB({ char = node })
        t:assertEqual(mod.settings.volume, 40)
        t:assertEqual(mod.settings.muted, true)

        mod.settings.volume = 55
        t:assertEqual(node.volume, 55)
        t:assertEqual(WowVision.classes.instanceConfig(settingsObj).muted, true)
    end,
})

WowVision.testing.testRunner:addSuite("AlertConstruction", {
    ["an alert with an output constructs enabled"] = function(t)
        local alert = WowVision.alerts.Alert:new({ key = "smoke", label = "Smoke" })
        t:assertEqual(alert.enabled, true)
        t:assertEqual(alert.defaultEnabled, true)
        alert:setEnabled(false)
        t:assertEqual(alert.enabled, false)
        t:assertEqual(alert.defaultEnabled, true)
    end,
})

loadAddonFile("core/graph/ControlId.lua")
loadAddonFile("core/graph/types.lua")
loadAddonFile("core/graph/Announcer.lua")
loadAddonFile("core/graph/KeyGraph.lua")
loadAddonFile("core/graph/Builder.lua")
loadAddonFile("core/graph/ControlTypes.lua")
loadAddonFile("core/graph/nodes.lua")
loadAddonFile("core/graph/scrollBox.lua")
loadAddonFile("core/graph/settings.lua")
loadAddonFile("core/graph/fieldControls.lua")
loadAddonFile("core/graph/tests.lua")
loadAddonFile("core/graph/controlTests.lua")

-- Files that need the game client to run but should at least parse cleanly.
local parseOnly = {
    "core/graph/Screen.lua",
    "core/graph/Host.lua",
    "core/graph/liveWatch.lua",
    "core/graph/textEntry.lua",
    "core/graph/keyCapture.lua",
    "core/ui/input/actions.lua",
    "core/ui/input/activator.lua",
    "core/ui/input/tests.lua",
    "core/ui/Window.lua",
    "core/ui/WindowManager.lua",
    "core/windows/GameMenu.lua",
    "core/errors.lua",
    "core/ui modules/graphBindings.lua",
    "core/buffers/module.lua",
    "core/windows/options/ui.lua",
    "core/windows/options/Module.lua",
    "mists/talents/talents.lua",
    "mists/talents/glyphs.lua",
    "core/windows/gossip.lua",
    "core/windows/questWindow.lua",
    "core/windows/popups.lua",
    "core/graph/hybridScroll.lua",
    "mists/QuestLog.lua",
    "core/windows/merchant.lua",
    "core/windows/containers.lua",
    "classic/containers/Bag.lua",
    "classic/containers/Bank.lua",
    "core/windows/training.lua",
    "core/windows/ready.lua",
    "core/windows/taxi.lua",
    "core/windows/mail.lua",
    "classic/mail.lua",
    "core/windows/Macros.lua",
    "core/windows/itemText.lua",
    "core/windows/RolePoll.lua",
    "core/windows/trade.lua",
    "core/windows/bars/bars.lua",
    "core/windows/bars/GenericActionBar.lua",
    "core/windows/bars/MainActionBar.lua",
    "core/windows/bars/StanceBar.lua",
    "core/windows/bars/PetActionBar.lua",
    "mists/spellbook/module.lua",
    "mists/spellbook/spellbook.lua",
    "mists/spellbook/professions.lua",
    "mists/character.lua",
    "mists/TradeSkill.lua",
    "mists/reforging.lua",
    "mists/socketing.lua",
    "mists/itemUpgrade.lua",
    "mists/QuestChoice.lua",
    "core/graph/dropdownMenu.lua",
    "mists/collections/module.lua",
    "mists/collections/MountJournal.lua",
    "core/chat/ui.lua",
    "mists/auction.lua",
    "tbc/QuestLog.lua",
    "tbc/socketing.lua",
    "tbc/spellbook.lua",
    "tbc/talents.lua",
    "tbc/tradeskill.lua",
    "tbc/lfg.lua",
    "tbc/character/character.lua",
    "tbc/character/PaperDoll.lua",
    "tbc/character/Pet.lua",
    "tbc/character/PVP.lua",
    "tbc/character/Reputation.lua",
    "tbc/character/Skills.lua",
    "tbc/auction/module.lua",
    "core/navigation/maps/ui.lua",
    "core/movement.lua",
    "core/navigation/walls.lua",
    "core/navigation/falling.lua",
    "core/navigation/maps/turnTo.lua",
    "core/navigation/maps/module.lua",
    "core/navigation/maps/Beacon.lua",
    "core/navigation/maps/Path.lua",
    "core/graph/contextMenu.lua",
    "core/commands/SlashCommand.lua",
    "core/data.lua",
    "core/MessageStore.lua",
    "core/navigation/atlas/MapDataset.lua",
    "core/templates/Template.lua",
    "core/ui/input/binding.lua",
    "core/ui/input/bindings.lua",
    "core/ui/input/input.lua",
    "core/windows/bars/StanceBar.lua",
    "classic/containers/Bag.lua",
    "core/WowVision.lua",
    "core/module/Module.lua",
    "core/alerts/alerts.lua",
    "core/alerts/outputs.lua",
}
for _, path in ipairs(parseOnly) do
    local chunk, err = loadfile(path)
    if chunk == nil then
        print("PARSE FAIL: " .. err)
        os.exit(1)
    end
end

local filter = nil
local verbose = false
for _, argument in ipairs({ ... }) do
    if argument == "-v" or argument == "--verbose" then
        verbose = true
    else
        filter = argument
    end
end

local runner = WowVision.testing.testRunner
print(runner:run(filter, verbose))
if runner.failed > 0 then
    os.exit(1)
end
