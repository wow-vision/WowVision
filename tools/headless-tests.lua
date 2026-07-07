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

loadAddonFile("libs/middleclass.lua")
loadAddonFile("core/Class.lua")

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
loadAddonFile("core/ClassTests.lua")

-- The OLD info system and the component registry, running on the new class
-- library: exercises the InfoClass compatibility path the game relies on
-- during the conversion window.
loadAddonFile("core/Registry.lua")
loadAddonFile("core/info/Info.lua")
loadAddonFile("core/info/Field.lua")
loadAddonFile("core/info/types/Bool.lua")
loadAddonFile("core/info/types/String.lua")
loadAddonFile("core/info/types/Number.lua")
loadAddonFile("core/info/types/Choice.lua")
loadAddonFile("core/components/components.lua")
loadAddonFile("core/components/RegistryType.lua")
loadAddonFile("core/components/ClassRegistryType.lua")
loadAddonFile("core/components/ComponentRegistry.lua")
loadAddonFile("core/components/tests.lua")

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
    "core/module/Module.lua",
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
