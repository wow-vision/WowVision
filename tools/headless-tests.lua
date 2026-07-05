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

local namespace = {}
local function loadAddonFile(path)
    local chunk, err = loadfile(path)
    if chunk == nil then
        error(err)
    end
    return chunk("WowVision", namespace)
end

loadAddonFile("libs/middleclass.lua")

WowVision = {
    Class = namespace.Class,
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

loadAddonFile("core/graph/ControlId.lua")
loadAddonFile("core/graph/types.lua")
loadAddonFile("core/graph/Announcer.lua")
loadAddonFile("core/graph/KeyGraph.lua")
loadAddonFile("core/graph/Builder.lua")
loadAddonFile("core/graph/ControlTypes.lua")
loadAddonFile("core/graph/nodes.lua")
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
