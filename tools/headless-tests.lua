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
-- WoW's Lua 5.1 has math.atan2 (WowNav's fishing code uses it); Lua 5.3+ folded it into math.atan.
math.atan2 = math.atan2 or math.atan

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
loadAddonFile("core/navigation/visitedStore.lua")
loadAddonFile("core/navigation/visitedTests.lua")
loadAddonFile("core/navigation/corpseFind.lua")
loadAddonFile("core/navigation/corpseTests.lua")
loadAddonFile("core/navigation/targetFind.lua")
loadAddonFile("core/navigation/targetTests.lua")

-- WowNav routes: Broesel's engine (camelot/wownav/engine) on his real data, packed into mapdata/WowNavPacked by
-- tools/wownav-pack.lua (its data.xml); without the packed data only the parts that need no network run.
loadAddonFile("camelot/wownav/engine/NavNetwork.lua")
loadAddonFile("camelot/wownav/engine/Guidance.lua")
loadAddonFile("camelot/wownav/engine/TargetCatalog.lua")
loadAddonFile("camelot/wownav/engine/TargetResolver.lua")
loadAddonFile("camelot/wownav/engine/DockNavigation.lua")
loadAddonFile("camelot/wownav/engine/TransitActivation.lua")
loadAddonFile("camelot/wownav/engine/FishingNavigation.lua")
do
    local base = "mapdata/WowNavPacked/"
    local xml = io.open(base .. "data.xml", "r")
    if xml ~= nil then
        local text = xml:read("*a")
        xml:close()
        for name in text:gmatch('<Script file="([^"]+)"') do
            dofile(base .. name:gsub("\\", "/"))
        end
    end
end
loadAddonFile("camelot/wownav/text.lua")
loadAddonFile("camelot/wownav/textTests.lua")
loadAddonFile("camelot/wownav/catalog.lua")
loadAddonFile("camelot/wownav/route.lua")
loadAddonFile("camelot/wownav/dock.lua")
loadAddonFile("camelot/wownav/fishing.lua")
loadAddonFile("camelot/wownav/tests.lua")

-- Movement intent: stand-ins record the hooks and the event frame so the
-- suite can play the game's side.
do
    local hooks, eventFrame = {}, nil
    local game = { moving = false, falling = false, now = 0 }
    function GetTime()
        return game.now
    end
    function IsPlayerMoving()
        return game.moving
    end
    function IsFalling()
        return game.falling
    end
    local savedHook, savedCreateFrame = hooksecurefunc, CreateFrame
    hooksecurefunc = function(name, hook)
        hooks[name] = hooks[name] or {}
        tinsert(hooks[name], hook)
    end
    CreateFrame = function()
        eventFrame = { events = {} }
        function eventFrame:RegisterEvent(event)
            self.events[event] = true
        end
        function eventFrame:SetScript(_, script)
            self.onEvent = script
        end
        return eventFrame
    end
    loadAddonFile("core/movement.lua")
    hooksecurefunc, CreateFrame = savedHook, savedCreateFrame

    local movement = WowVision.movement
    local function call(name)
        for _, hook in ipairs(hooks[name]) do
            hook()
        end
    end
    local function event(name)
        if eventFrame.events[name] then
            eventFrame.onEvent(eventFrame, name)
        end
    end
    local function reset()
        for key in pairs(movement.flags) do
            movement.flags[key] = false
        end
        game.moving, game.falling = false, false
    end

    WowVision.testing.testRunner:addSuite("Movement", {
        ["autorun cancelled by a movement key does not invert the next toggle"] = function(t)
            reset()
            call("ToggleAutoRun")
            t:assertTrue(movement.flags.autorun)
            -- Forward cancels autorun in the game, without StopAutoRun.
            call("MoveForwardStart")
            call("MoveForwardStop")
            event("PLAYER_STOPPED_MOVING")
            t:assertFalse(movement.flags.autorun)
            call("ToggleAutoRun")
            t:assertTrue(movement.flags.autorun)
        end,

        ["turning follows the game's turning events"] = function(t)
            reset()
            movement.turning = false
            event("PLAYER_STARTED_TURNING")
            t:assertTrue(movement.turning)
            event("PLAYER_STOPPED_TURNING")
            t:assertFalse(movement.turning)
        end,

        ["follow ends with AUTOFOLLOW_END"] = function(t)
            reset()
            call("FollowUnit")
            t:assertTrue(movement.flags.following)
            event("AUTOFOLLOW_END")
            t:assertFalse(movement.flags.following)
        end,

        ["the game walking the player counts as moving, a fall does not"] = function(t)
            reset()
            t:assertFalse(movement:isMoving())
            -- The interact key walks the player with no key held.
            game.moving = true
            t:assertTrue(movement:isMoving())
            game.falling = true
            t:assertFalse(movement:isMoving())
            -- A held key still counts while falling, as before.
            call("MoveForwardStart")
            t:assertTrue(movement:isMoving())
            call("MoveForwardStop")
        end,

        ["a movement key or autorun notes the time of the command"] = function(t)
            reset()
            movement.lastCommandAt = 0
            game.now = 5
            call("MoveForwardStart")
            t:assertEqual(movement.lastCommandAt, 5)
            call("MoveForwardStop")
            game.now = 7
            call("ToggleAutoRun")
            t:assertEqual(movement.lastCommandAt, 7)
            -- Turning is no translation command.
            game.now = 9
            call("TurnLeftStart")
            t:assertEqual(movement.lastCommandAt, 7)
            call("TurnLeftStop")
        end,

        ["a stale key flag does not count while the game says standing"] = function(t)
            reset()
            -- The Stop function never ran: the flag stays on.
            call("MoveForwardStart")
            t:assertFalse(movement:isMoving())
            game.moving = true
            t:assertTrue(movement:isMoving())
            call("MoveForwardStop")
        end,
    })
end
loadAddonFile("core/navigation/camera.lua")
loadAddonFile("core/navigation/cameraTests.lua")
loadAddonFile("core/navigation/maps/turnMath.lua")
loadAddonFile("core/navigation/maps/turnTests.lua")
loadAddonFile("core/quests/Adapter.lua")
loadAddonFile("core/quests/tests.lua")
loadAddonFile("core/quests/completion.lua")
loadAddonFile("core/quests/completionTests.lua")
-- The quest scanner over a stand-in quest module: the snapshot it builds
-- from and the live log it reads while open (core/quests/scannerLiveTests.lua).
do
    local harness = { providers = {}, snapshot = {}, log = {} }
    local savedBase = WowVision.base
    local questModule = { L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    }) }
    -- the module's settings as the scanner reads them (Sort Quests by Proximity off: the log's order)
    questModule.settings = { sortByProximity = false }
    function questModule:inProgress()
        return harness.snapshot
    end
    function questModule:targets()
        return {}
    end
    function questModule:objectiveTargets()
        return {}
    end
    function questModule:markerTarget()
        return nil
    end
    function questModule:gameMarkerTarget()
        return nil
    end
    function questModule:hasSource()
        return true
    end
    function questModule:isReady()
        return true
    end
    WowVision.base = {
        quests = questModule,
        scanner = {
            registerProvider = function(_, provider)
                harness.providers[provider.key] = provider
            end,
        },
    }
    -- module.lua only parses headless; the stand-in log answers instead, put
    -- in place by each live test and taken out after it
    harness.gameQuestEntry = function(questId)
        return harness.log[questId]
    end
    loadAddonFile("core/quests/scanner.lua")
    WowVision.quests._scannerLiveHarness = harness
    loadAddonFile("core/quests/scannerLiveTests.lua")
    WowVision.base = savedBase
end
loadAddonFile("core/minimap/logic.lua")
loadAddonFile("core/minimap/gatheringNames.lua")
loadAddonFile("core/minimap/tests.lua")
loadAddonFile("retail/groupHealth/logic.lua")
loadAddonFile("retail/groupHealth/voices.lua")
loadAddonFile("retail/groupHealth/tests.lua")
loadAddonFile("core/colors/names.lua")
loadAddonFile("core/colors/colors.lua")
loadAddonFile("core/colors/tests.lua")
loadAddonFile("core/windows/bars/lock.lua")
loadAddonFile("core/windows/bars/tests.lua")
loadAddonFile("core/targeting/softTargeting.lua")
loadAddonFile("core/targeting/softTargetingTests.lua")
loadAddonFile("core/ui modules/enemyCount.lua")
loadAddonFile("core/ui modules/enemyCountTests.lua")
loadAddonFile("core/ui modules/gameDefaults.lua")
loadAddonFile("core/ui modules/gameDefaultsTests.lua")
loadAddonFile("core/db.lua")
loadAddonFile("core/dbTests.lua")
loadAddonFile("core/utils.lua")
loadAddonFile("core/utilsTests.lua")
loadAddonFile("core/scanner/nearest.lua")
loadAddonFile("core/scanner/nearestTests.lua")
loadAddonFile("core/secrets.lua")
loadAddonFile("core/secretsTests.lua")
loadAddonFile("camelot/petTraining.lua")
loadAddonFile("camelot/petTrainingTests.lua")
loadAddonFile("core/ui/input/heldKeys.lua")
loadAddonFile("core/ui/input/heldKeysTests.lua")
loadAddonFile("core/ui/input/padLogic.lua")
loadAddonFile("core/ui/input/padLogicTests.lua")
loadAddonFile("core/ttsCacheBust.lua")
loadAddonFile("core/ttsCacheBustTests.lua")
loadAddonFile("core/speechInterrupt.lua")
loadAddonFile("core/speechInterruptTests.lua")
loadAddonFile("core/speechSounds.lua")
loadAddonFile("core/speechSoundsTests.lua")
loadAddonFile("core/chat/links.lua")
loadAddonFile("core/chat/linkTests.lua")
loadAddonFile("core/chat/tabs.lua")
loadAddonFile("core/chat/tabTests.lua")
loadAddonFile("core/ClassTests.lua")
loadAddonFile("core/ttsVoiceTests.lua")
loadAddonFile("core/errors/utils.lua")
loadAddonFile("core/errors/tests.lua")

-- The component registry and the systems above it, all on the class library.
loadAddonFile("core/Registry.lua")
loadAddonFile("core/templates/templates.lua")
loadAddonFile("core/templates/tests.lua")
loadAddonFile("core/components/components.lua")
loadAddonFile("core/components/RegistryType.lua")
loadAddonFile("core/components/ClassRegistryType.lua")
loadAddonFile("core/components/ComponentRegistry.lua")
loadAddonFile("core/components/tests.lua")

-- Object types read the game on demand: their spoken lines run here with
-- stand-ins for the game functions they call.
loadAddonFile("core/templates/Template.lua")
loadAddonFile("core/objects/objects.lua")
loadAddonFile("core/objects/types/type.lua")
loadAddonFile("core/objects/types/PlayerXP.lua")
loadAddonFile("core/objects/types/PlayerMoney.lua")
loadAddonFile("core/objects/types/PlayerBags.lua")
loadAddonFile("core/objects/types/PlayerDurability.lua")
loadAddonFile("core/objects/types/PlayerMail.lua")
loadAddonFile("core/objects/types/Hearthstone.lua")
loadAddonFile("core/objects/types/GameClock.lua")
loadAddonFile("core/objects/types/tests.lua")

-- Alerts construct at every module load in game; a construction smoke here
-- catches recursion/typo failures the parse check cannot.
loadAddonFile("core/alerts/alerts.lua")
loadAddonFile("core/alerts/outputs.lua")
loadAddonFile("core/audio/channelTests.lua")
loadAddonFile("core/audio/beaconVolumeTests.lua")

-- The real Module, for what it does with the stores. Its frames, bindings
-- and profiler are the game's side: stand-ins, in place only while Module.lua
-- loads and while a module is built, since the tests run long after this.
do
    local function libStub()
        return {
            NewLocale = function()
                return {}
            end,
            GetLocale = function()
                return {}
            end,
        }
    end
    local function frame()
        return { SetScript = function() end }
    end
    local standIn = {
        new = function()
            return {
                getDefaultDB = function()
                    return {}
                end,
            }
        end,
    }
    local function withStandIns(body, ...)
        local savedLibStub, savedCreateFrame = LibStub, CreateFrame
        local savedInput, savedProfiler = WowVision.input, WowVision.Profiler
        LibStub, CreateFrame = libStub, frame
        WowVision.input, WowVision.Profiler = { BindingSet = standIn }, standIn
        body(...)
        LibStub, CreateFrame = savedLibStub, savedCreateFrame
        WowVision.input, WowVision.Profiler = savedInput, savedProfiler
    end
    withStandIns(loadAddonFile, "core/module/Module.lua")
    local Module = WowVision.Module
    local initialize = Module.initialize
    function Module:initialize(key)
        withStandIns(initialize, self, key)
    end
    loadAddonFile("core/module/alertScopeTests.lua")
end

-- The buffer family on the new class system: construction and db round trip.
loadAddonFile("core/ViewList.lua")
loadAddonFile("core/buffers/Buffer.lua")
loadAddonFile("core/buffers/BufferItem.lua")
loadAddonFile("core/buffers/items/ObjectItem.lua")
loadAddonFile("core/buffers/items/MessageItem.lua")
loadAddonFile("core/buffers/BufferGroup.lua")
loadAddonFile("core/buffers/types/StaticBuffer.lua")
loadAddonFile("core/buffers/types/TrackedBuffer.lua")
loadAddonFile("core/MessageStore.lua")
loadAddonFile("core/buffers/types/MessageBuffer.lua")
loadAddonFile("core/buffers/types/ChatTabBuffer.lua")
-- The aura buffer reads the game's aura list by index; a small fake one here.
local fakeAuras = {
    player = { HELPFUL = { { name = "Mark of the Wild", applications = 0, duration = 3600, dispelName = "Magic" } }, HARMFUL = {} },
    target = {
        HARMFUL = {
            { name = "Moonfire", applications = 0, duration = 18, dispelName = "Magic" },
            { name = "Sunfire", applications = 3, duration = 0, dispelName = "" },
        },
        HELPFUL = {},
    },
}
local fakeUnits = { player = true, target = true }
local fakeTooltips = {
    Moonfire = { "Moonfire", "Burns the target.", "12 seconds remaining" },
    Sunfire = { "Sunfire", "Burns." },
    ["Mark of the Wild"] = { "Mark of the Wild", "59 minutes remaining" },
}
C_UnitAuras = C_UnitAuras or {}
C_UnitAuras.GetAuraDataByIndex = function(unit, index, filter)
    local base = filter:match("^(%u+)")
    local list = fakeAuras[unit] and fakeAuras[unit][base]
    return list and list[index] or nil
end
UnitExists = function(unit)
    return fakeUnits[unit] == true
end
-- The game refuses the index read for restricted units; the tooltip still fills.
local restrictedUnits = {}
local fakeIndexRead = C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex = function(unit, index, filter)
    if restrictedUnits[unit] then
        error("GetAuraDataByIndex(): Auras cannot be accessed when secret while tainted by 'WowVision'")
    end
    return fakeIndexRead(unit, index, filter)
end
loadAddonFile("core/buffers/types/AuraBuffer.lua")
local scanLines = {}
local scanName = nil
local fakeDispelTypes = {}
WowVision.buffers.AuraBuffer.scanner = {
    fill = function(unit, index, filter)
        local aura = fakeIndexRead(unit, index, filter)
        scanLines = aura and fakeTooltips[aura.name] or {}
        scanName = aura and aura.name or nil
        return #scanLines
    end,
    line = function(index)
        return scanLines[index]
    end,
    right = function(index)
        return index == 1 and fakeDispelTypes[scanName] or nil
    end,
}
WowVision.testing.testRunner:addSuite("AuraBufferStacks", {
    ["under restriction the player's stacks come from Blizzard's buttons"] = function(t)
        local AuraBuffer = WowVision.buffers.AuraBuffer
        local countShown = true
        local count = {
            IsShown = function()
                return countShown
            end,
            GetText = function()
                return "3"
            end,
        }
        local button = {
            hasValidInfo = true,
            unit = "player",
            Count = count,
            buttonInfo = { auraType = "Buff", index = 1 },
        }
        local savedBuff = BuffFrame
        local function read(unit, filter)
            local item = AuraBuffer.AuraItem:new({ unit = unit, filter = filter, index = 1, harmful = false })
            return item:getFocusString()
        end
        BuffFrame = { auraFrames = { { hasValidInfo = false }, button } }
        restrictedUnits.player = true
        local body = function()
            t:assertEqual(read("player", "HELPFUL"), "Mark of the Wild, 3 stacks, 59 minutes remaining")

            -- A filter renumbers the positions: another aura's count must not be said
            t:assertEqual(read("player", "HELPFUL|PLAYER"), "Mark of the Wild, 59 minutes remaining")

            countShown = false
            t:assertEqual(read("player", "HELPFUL"), "Mark of the Wild, 59 minutes remaining")
            countShown = true

            -- Another aura's button, a weapon enchant, another unit: none of them count
            button.buttonInfo = { auraType = "Buff", index = 2 }
            t:assertEqual(read("player", "HELPFUL"), "Mark of the Wild, 59 minutes remaining")
            button.buttonInfo = { auraType = "TempEnchant", index = 1 }
            t:assertEqual(read("player", "HELPFUL"), "Mark of the Wild, 59 minutes remaining")
            button.buttonInfo = { auraType = "Buff", index = 1 }
            button.unit = "vehicle"
            t:assertEqual(read("player", "HELPFUL"), "Mark of the Wild, 59 minutes remaining")
            button.unit = "player"

            -- A button that throws costs the stacks, not the line
            button.Count = {}
            t:assertEqual(read("player", "HELPFUL"), "Mark of the Wild, 59 minutes remaining")

            BuffFrame = nil
            t:assertEqual(read("player", "HELPFUL"), "Mark of the Wild, 59 minutes remaining")
        end
        local ok, err = pcall(body)
        restrictedUnits.player = nil
        BuffFrame = savedBuff
        if not ok then
            error(err, 0)
        end
    end,
})

WowVision.testing.testRunner:addSuite("AuraBufferFilters", {
    ["each client is offered the filters it knows, negated its own way"] = function(t)
        local AuraBuffer = WowVision.buffers.AuraBuffer
        local function tokens(offered)
            local out = {}
            for _, filter in ipairs(offered) do
                tinsert(out, filter.token .. (filter.notToken and ("=" .. filter.notToken) or ""))
            end
            return table.concat(out, " ")
        end
        -- Retail and WoW: Forever: every filter, "!" negation
        local retail = {
            "HELPFUL", "HARMFUL", "PLAYER", "RAID", "CANCELABLE", "INCLUDE_NAME_PLATE_ONLY", "MAW",
            "EXTERNAL_DEFENSIVE", "CROWD_CONTROL", "RAID_IN_COMBAT", "RAID_PLAYER_DISPELLABLE",
            "BIG_DEFENSIVE", "IMPORTANT", "DISPELLABLE",
        }
        t:assertEqual(
            tokens(AuraBuffer.clientFilters(retail, "!")),
            "PLAYER=!PLAYER RAID=!RAID CANCELABLE=!CANCELABLE CROWD_CONTROL=!CROWD_CONTROL "
                .. "RAID_PLAYER_DISPELLABLE=!RAID_PLAYER_DISPELLABLE DISPELLABLE=!DISPELLABLE "
                .. "EXTERNAL_DEFENSIVE=!EXTERNAL_DEFENSIVE BIG_DEFENSIVE=!BIG_DEFENSIVE "
                .. "RAID_IN_COMBAT=!RAID_IN_COMBAT IMPORTANT=!IMPORTANT"
        )
        -- TBC Anniversary: three filters, only Cancelable has a negative
        local tbc = { "HELPFUL", "HARMFUL", "RAID", "INCLUDE_NAME_PLATE_ONLY", "PLAYER", "CANCELABLE", "NOT_CANCELABLE", "MAW" }
        t:assertEqual(tokens(AuraBuffer.clientFilters(tbc, nil)), "PLAYER RAID CANCELABLE=NOT_CANCELABLE")
        t:assertEqual(#AuraBuffer.clientFilters(nil, nil), 0, "no AuraUtil: no filters")
    end,

    ["the filter string joins the source with every Only and Not"] = function(t)
        local AuraBuffer = WowVision.buffers.AuraBuffer
        local offered = AuraBuffer.clientFilters({ "PLAYER", "CANCELABLE", "CROWD_CONTROL" }, "!")
        t:assertEqual(AuraBuffer.buildFilter("HARMFUL", offered, {}), "HARMFUL")
        t:assertEqual(
            AuraBuffer.buildFilter("HARMFUL", offered, { PLAYER = "not", CROWD_CONTROL = "only", CANCELABLE = "any" }),
            "HARMFUL|!PLAYER|CROWD_CONTROL"
        )
        -- Not where the client has no negative is left out
        local old = AuraBuffer.clientFilters({ "PLAYER", "CANCELABLE", "NOT_CANCELABLE" }, nil)
        t:assertEqual(
            AuraBuffer.buildFilter("HELPFUL", old, { PLAYER = "not", CANCELABLE = "not" }),
            "HELPFUL|NOT_CANCELABLE"
        )
    end,
})

WowVision.testing.testRunner:addSuite("BufferConstruction", {
    ["Always Start at Top lands a switched-to buffer on its first item"] = function(t)
        local spoken = {}
        local savedSpeak, savedStarts = WowVision.speak, WowVision.buffers.startsAtTop
        WowVision.speak = function(_, text)
            spoken[#spoken + 1] = text
        end
        local function filled(label, lines)
            local buffer = WowVision.buffers:create("Static", { label = label })
            for _, line in ipairs(lines) do
                buffer:add(WowVision.buffers.MessageItem:new({ data = line }))
            end
            return buffer
        end
        local root = WowVision.buffers.RootBufferGroup:new({})
        local first = WowVision.buffers:create("Group", { label = "One" })
        local second = WowVision.buffers:create("Group", { label = "Two" })
        root:addBuffer(first)
        root:addBuffer(second)
        local a = filled("A", { "a1", "a2", "a3" })
        local b = filled("B", { "b1", "b2", "b3" })
        local c = filled("C", { "c1", "c2" })
        first:addBuffer(a)
        first:addBuffer(b)
        second:addBuffer(c)
        root:getFocus()
        first:getFocus()

        -- Off: a buffer keeps its place
        WowVision.buffers.startsAtTop = function()
            return false
        end
        a:focusDirection(1)
        a:focusDirection(1)
        first:UIFocusDirection(1)
        first:UIFocusDirection(-1)
        local keptOff = a:getFocus():getFocusString()

        -- On: between buffers
        WowVision.buffers.startsAtTop = function()
            return true
        end
        b:focusIndex(2)
        first:UIFocusDirection(1)
        local onB = spoken[#spoken]
        local bIndex = b.index

        -- On: between groups, the group keeps its buffer
        c:focusIndex(2)
        root:UIFocusDirection(1)
        local onC = spoken[#spoken]
        local cIndex = c.index

        WowVision.speak, WowVision.buffers.startsAtTop = savedSpeak, savedStarts
        t:assertEqual(keptOff, "a2")
        t:assertEqual(onB, "B b1")
        t:assertEqual(bIndex, 1)
        t:assertEqual(onC, "Two C c1")
        t:assertEqual(cIndex, 1)
        t:assertEqual(first.index, 2, "the group stays on its buffer")
    end,

    ["a run opens with its first buffer key and closes once when Alt is let go"] = function(t)
        local buffers = WowVision.buffers
        buffers.endRun()
        local savedStarted, savedEnded = buffers.runStarted, buffers.runEnded
        local log = {}
        buffers.runStarted = function()
            log[#log + 1] = "open"
        end
        buffers.runEnded = function()
            log[#log + 1] = "close"
        end
        buffers.endRun() -- Alt or another modifier changing with no run: nothing
        buffers.takeNewRun()
        buffers.takeNewRun() -- Alt held: the run goes on
        buffers.endRun()
        buffers.endRun() -- another modifier changing after the close: nothing
        buffers.takeNewRun()
        buffers.endRun()
        buffers.runStarted, buffers.runEnded = savedStarted, savedEnded
        t:assertEqual(table.concat(log, ","), "open,close,open,close")
    end,

    ["Always Start at Top: Alt let go, the next Alt-Down lands on the first item again"] = function(t)
        local spoken = {}
        local savedSpeak = WowVision.speak
        WowVision.speak = function(_, text)
            spoken[#spoken + 1] = text
        end
        local buffers = WowVision.buffers
        local buffer = buffers:create("Static", { label = "A" })
        for _, line in ipairs({ "health", "mana", "xp" }) do
            buffer:add(buffers.MessageItem:new({ data = line }))
        end
        local function press(direction)
            buffer:UIMoveItem(direction, buffers.takeNewRun())
            return spoken[#spoken]
        end

        buffers.endRun()
        local first = press(1)
        buffers.endRun()
        local again = press(1)
        local held = press(1)
        local heldOn = press(1)
        buffers.endRun()
        local backward = press(-1)
        buffers.endRun()
        local restarted = press(1)

        -- A switch reads the first item: the run goes on from there.
        local group = buffers:create("Group", { label = "G" })
        group:addBuffer(buffer)
        buffers.endRun()
        group:UIFocusDirection(1)
        local afterSwitch = buffers.takeNewRun()

        WowVision.speak = savedSpeak
        t:assertEqual(first, "health")
        t:assertEqual(again, "health")
        t:assertEqual(held, "mana", "Alt held walks on")
        t:assertEqual(heldOn, "xp")
        t:assertEqual(backward, "mana", "a backward press moves on from where the buffer stands")
        t:assertEqual(restarted, "health")
        t:assertEqual(afterSwitch, false)
    end,

    ["Retail and Forever offer no tracked buffer, and saved ones still load"] = function(t)
        local groupTypes = WowVision.buffers.groupTypes
        local saved = {}
        for i, entry in ipairs(groupTypes) do
            saved[i] = entry
        end
        local function offered(key)
            for _, entry in ipairs(WowVision.buffers.BufferGroup:getField("items").availableTypes) do
                if entry.key == key then
                    return true
                end
            end
            return false
        end
        t:assertTrue(offered("Tracked"))
        loadAddonFile("retail/buffers.lua")
        local tracked, static = offered("Tracked"), offered("Static")
        for i = #groupTypes, 1, -1 do
            groupTypes[i] = nil
        end
        for i, entry in ipairs(saved) do
            groupTypes[i] = entry
        end
        t:assertEqual(tracked, false)
        t:assertTrue(static)
        t:assertNotNil(WowVision.buffers:create("Tracked", { label = "Saved" }))
    end,

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

    ["a chat tab buffer waits for its tab's store and follows the tab choice"] = function(t)
        local db = { items = { _type = "array" } }
        local root = WowVision.buffers.RootBufferGroup:new(db)
        root:setDB(db)
        local group = WowVision.buffers:create("Group", { label = "Chat" })
        root:addBuffer(group)
        local buffer = WowVision.buffers:create("ChatTab", { tab = "chat.test1" })
        group:addBuffer(buffer)
        t:assertEqual(db.items[1].items[1].type, "ChatTab")
        t:assertEqual(db.items[1].items[1].tab, "chat.test1")
        t:assertEqual(#buffer.items, 0)

        -- The store appears later (chat tabs open after the buffers restore)
        local store = WowVision.createMessageStore("chat.test1", { messages = { "older line", "old line" } })
        t:assertEqual(#buffer.items, 2)
        -- It opens on the newest line and follows new ones
        t:assertEqual(buffer:getFocus():getFocusString(), "old line")
        store:add("new line")
        t:assertEqual(#buffer.items, 3)
        t:assertEqual(buffer.items[3]:getFocusString(), "new line")
        t:assertEqual(buffer:getFocus():getFocusString(), "new line")
        -- Moved back into history, it stays there while lines arrive
        buffer:focusDirection(-1)
        t:assertEqual(buffer:getFocus():getFocusString(), "old line")
        store:add("newer line")
        t:assertEqual(buffer:getFocus():getFocusString(), "old line")
        -- Back at the end, it follows again
        buffer:focusDirection(1)
        buffer:focusDirection(1)
        t:assertEqual(buffer:getFocus():getFocusString(), "newer line")
        store:add("newest line")
        t:assertEqual(buffer:getFocus():getFocusString(), "newest line")

        -- Choosing another tab swaps the lines
        WowVision.createMessageStore("chat.test2", { messages = { "other tab" } })
        buffer.tab = "chat.test2"
        t:assertEqual(db.items[1].items[1].tab, "chat.test2")
        t:assertEqual(#buffer.items, 1)
        t:assertEqual(buffer.items[1]:getFocusString(), "other tab")
        store:add("ignored now")
        t:assertEqual(#buffer.items, 1)

        -- Restored from the saved config, it attaches to the existing store,
        -- on its newest line
        local again = WowVision.buffers.RootBufferGroup:new(db)
        again:setDB(db)
        t:assertEqual(#again.items[1].items[1].items, 1)
        t:assertEqual(again.items[1].items[1]:getFocus():getFocusString(), "other tab")
    end,

    ["an aura buffer lists its sources by index and speaks each aura afresh"] = function(t)
        local db = { items = { _type = "array" } }
        local root = WowVision.buffers.RootBufferGroup:new(db)
        root:setDB(db)
        local group = WowVision.buffers:create("Group", { label = "Combat" })
        root:addBuffer(group)
        local buffer = WowVision.buffers:create("Aura", { sources = { "target:HARMFUL", "player:HELPFUL", "focus:HARMFUL" } })
        group:addBuffer(buffer)
        t:assertEqual(db.items[1].items[1].type, "Aura")
        t:assertEqual(#db.items[1].items[1].sources, 3)
        t:assertEqual(buffer:getLabel(), "Auras")

        -- Two debuffs, one buff, then a missing unit says so; no headings
        t:assertEqual(#buffer.items, 4)
        t:assertEqual(buffer.items[1]:getFocusString(), "Moonfire, 12 seconds remaining, Magic, Burns the target.")
        t:assertEqual(buffer.items[2]:getFocusString(), "Sunfire, 3 stacks, Burns.")
        t:assertEqual(buffer.items[3]:getFocusString(), "Mark of the Wild, 59 minutes remaining")
        t:assertEqual(buffer.items[4]:getFocusString(), "Focus Debuffs, no focus")

        -- The game's list changed: the rebuild keeps the position
        buffer:focusIndex(2)
        table.remove(fakeAuras.target.HARMFUL, 1)
        buffer:rebuild()
        t:assertEqual(#buffer.items, 3)
        t:assertEqual(buffer:getFocus():getFocusString(), "Mark of the Wild, 59 minutes remaining")

        -- Under restriction the index read is refused; the tooltip speaks
        -- the name and the other lines in the game's order
        restrictedUnits.target = true
        buffer:rebuild()
        t:assertEqual(#buffer.items, 3)
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, Burns.")
        t:assertEqual(buffer.items[2]:getFocusString(), "Mark of the Wild, 59 minutes remaining")

        -- A debuff's dispel type comes from the first line's right side; a
        -- buff's is left out, as in the index read
        fakeDispelTypes.Sunfire = "Magic"
        fakeDispelTypes["Mark of the Wild"] = "Magic"
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, Magic, Burns.")
        t:assertEqual(buffer.items[2]:getFocusString(), "Mark of the Wild, 59 minutes remaining")
        fakeDispelTypes.Sunfire = ""
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, Burns.")
        fakeDispelTypes.Sunfire = nil
        fakeDispelTypes["Mark of the Wild"] = nil
        restrictedUnits.target = nil
        buffer:rebuild()

        -- The two settings: what follows the name, stacks and dispel type
        buffer.speakDescription = false
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, 3 stacks")
        t:assertEqual(buffer.items[2]:getFocusString(), "Mark of the Wild, 59 minutes remaining")
        buffer.speakRemaining = false
        t:assertEqual(buffer.items[2]:getFocusString(), "Mark of the Wild")
        buffer.speakDescription = true
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, 3 stacks, Burns.")
        buffer.speakRemaining = true
        -- Under restriction the last line cannot be told apart: all of them
        -- with the description, else only the last, none with both off
        restrictedUnits.target = true
        buffer:rebuild()
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, Burns.")
        buffer.speakDescription = false
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, Burns.")
        buffer.speakRemaining = false
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire")
        buffer.speakRemaining, buffer.speakDescription = true, true
        restrictedUnits.target = nil
        buffer:rebuild()

        -- Only my auras narrows the filter; a source change rebuilds
        buffer.onlyMine = true
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, 3 stacks, Burns.")
        buffer.sources = { "target:HARMFUL" }
        t:assertEqual(#buffer.items, 1)
        t:assertEqual(buffer:getLabel(), "Target Debuffs")

        -- A source with nothing to list says so
        table.remove(fakeAuras.target.HARMFUL, 1)
        buffer:rebuild()
        t:assertEqual(#buffer.items, 1)
        t:assertEqual(buffer.items[1]:getFocusString(), "Target Debuffs, none")
        tinsert(fakeAuras.target.HARMFUL, { name = "Sunfire", applications = 3, duration = 0, dispelName = "" })
        buffer:rebuild()

        -- Restored from the saved config with its sources
        local again = WowVision.buffers.RootBufferGroup:new(db)
        again:setDB(db)
        t:assertEqual(#again.items[1].items[1].sources, 1)
        t:assertEqual(again.items[1].items[1].items[1]:getFocusString(), "Sunfire, 3 stacks, Burns.")

        -- A new buffer starts on the player's debuffs and buffs
        local fresh = WowVision.buffers:create("Aura", {})
        group:addBuffer(fresh)
        t:assertEqual(#fresh.sources, 2)
        t:assertEqual(#db.items[1].items[2].sources, 2)
        fakeAuras.target.HARMFUL = { { name = "Moonfire", applications = 0, duration = 18, dispelName = "Magic" }, { name = "Sunfire", applications = 3, duration = 0, dispelName = "" } }
    end,
})

-- Monitors and rules on the new class system.
loadAddonFile("core/monitors/Rule.lua")
loadAddonFile("core/monitors/Monitor.lua")
loadAddonFile("core/monitors/rules/StateRule.lua")
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

-- The cooldown manager aura monitor reads Blizzard's item frames; fake ones here.
C_Spell = C_Spell or {}
local fakeSpellNames = { [8921] = "Moonfire", [164812] = "Moonfire", [93402] = "Sunfire", [78674] = "Starsurge", [79577] = "Eclipse", [48518] = "Eclipse (Lunar)", [48517] = "Eclipse (Solar)", [22812] = "Barkskin", [108853] = "Fire Blast" }
C_Spell.GetSpellName = C_Spell.GetSpellName or function(id)
    return fakeSpellNames[id]
end
C_Spell.GetSpellInfo = C_Spell.GetSpellInfo or function(id)
    local name = fakeSpellNames[id]
    return name ~= nil and { name = name, spellID = id } or nil
end
GetTime = GetTime or function()
    return 0
end
local function fakeItem(spellID, buffItem)
    local item = {
        info = { spellID = spellID, cooldownID = spellID },
        auraDataUnit = nil,
        auraDataCached = nil,
        PandemicIcon = nil,
        active = false,
        visible = true,
    }
    function item:GetCooldownInfo()
        return self.info
    end
    function item:IsVisible()
        return self.visible
    end
    function item:SetAuraInstanceInfo() end
    item.Cooldown = {}
    function item.Cooldown:HookScript(_, handler)
        self.onDone = handler
    end
    if buffItem then
        function item:IsActive()
            return self.active
        end
        function item:GetApplicationsText()
            return ""
        end
    end
    return item
end
local moonfireIcon = fakeItem(8921, true)
local moonfireEssential = fakeItem(8921, false)
local sunfireIcon = fakeItem(93402, true)
local starsurgeEssential = fakeItem(78674, false)
-- One entry with two linked spells, the item renaming itself between them
local eclipseEssential = fakeItem(79577, false)
eclipseEssential.info.cooldownID, eclipseEssential.info.linkedSpellIDs = 90, { 48518, 48517 }
BuffIconCooldownViewer = { GetItemFrames = function()
    return { moonfireIcon, sunfireIcon }
end }
EssentialCooldownViewer = { GetItemFrames = function()
    return { moonfireEssential, starsurgeEssential, eclipseEssential }
end }
-- Two bar entries sharing a base spell, told apart by their tooltip spell
local eclipseLunar = fakeItem(79577, true)
eclipseLunar.info.cooldownID, eclipseLunar.info.overrideTooltipSpellID = 1, 48518
local eclipseSolar = fakeItem(79577, true)
eclipseSolar.info.cooldownID, eclipseSolar.info.overrideTooltipSpellID = 2, 48517
BuffBarCooldownViewer = { GetItemFrames = function()
    return { eclipseLunar, eclipseSolar }
end }
-- The rule's Sound outputs browse the audio directory
WowVision.audio = WowVision.audio or { directory = "Sound/WowVision" }
-- The item frame hooks: a stand-in that wraps a table's method
if hooksecurefunc == nil then
    hooksecurefunc = function(target, name, hook)
        local original = target[name]
        target[name] = function(...)
            local result = original(...)
            hook(...)
            return result
        end
    end
end
loadAddonFile("retail/monitors/CdmAuraMonitor.lua")
WowVision.testing.testRunner:addSuite("CdmAuraMonitor", {
    ["frames match rules by spell name and read plain state"] = function(t)
        local CdmAuraMonitor = WowVision.monitors.CdmAuraMonitor
        t:assertEqual(CdmAuraMonitor.frameSpellNames(moonfireIcon).Moonfire, true)
        t:assertEqual(CdmAuraMonitor.frameSpellNames(moonfireIcon).Sunfire, nil)
        -- Only the aura viewers count: Starsurge sits in Essential alone.
        -- Entries are named as the cooldown manager names them, so the two
        -- Eclipses are distinct
        local spells = CdmAuraMonitor.cdmSpells()
        t:assertEqual(#spells, 4)
        t:assertEqual(spells[1].name, "Eclipse (Lunar)")
        t:assertEqual(spells[1].spellID, 48518)
        t:assertEqual(spells[2].name, "Eclipse (Solar)")
        t:assertEqual(spells[3].name, "Moonfire")
        t:assertEqual(spells[3].spellID, 8921)
        t:assertEqual(spells[4].name, "Sunfire")
        t:assertEqual(CdmAuraMonitor.frameSpellNames(eclipseLunar)["Eclipse (Lunar)"], true)
        t:assertEqual(CdmAuraMonitor.frameSpellNames(eclipseLunar)["Eclipse"], true)
        t:assertEqual(CdmAuraMonitor.frameSpellNames(eclipseLunar)["Eclipse (Solar)"], nil)
        -- A name once seen plain stays with the frame while its entry does
        -- (the id turns secret while the aura is up), and goes with it
        eclipseLunar.info.overrideTooltipSpellID = nil
        t:assertEqual(CdmAuraMonitor.frameSpellNames(eclipseLunar)["Eclipse (Lunar)"], true)
        eclipseLunar.info.cooldownID = 3
        t:assertEqual(CdmAuraMonitor.frameSpellNames(eclipseLunar)["Eclipse (Lunar)"], nil)
        eclipseLunar.info.cooldownID, eclipseLunar.info.overrideTooltipSpellID = 1, 48518
        t:assertEqual(WowVision.classes.fieldTypes.CdmSpell ~= nil, true)
        t:assertEqual(WowVision.monitors.CdmAuraStateRule:getField("spell").typeKey, "CdmSpell")
        -- No aura: nothing shown
        t:assertEqual(CdmAuraMonitor.auraShown(moonfireIcon, "target"), false)
        -- A buff item needs IsActive besides the cached data
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached = "target", {}
        t:assertEqual(CdmAuraMonitor.auraShown(moonfireIcon, "target"), false)
        moonfireIcon.active = true
        t:assertEqual(CdmAuraMonitor.auraShown(moonfireIcon, "target"), true)
        t:assertEqual(CdmAuraMonitor.auraShown(moonfireIcon, "player"), false)
        -- A cooldown item's cached data stands for the aura
        moonfireEssential.auraDataUnit, moonfireEssential.auraDataCached = "target", {}
        t:assertEqual(CdmAuraMonitor.auraShown(moonfireEssential, "target"), true)
        -- A hidden frame shows nothing, whatever it last read
        moonfireEssential.visible = false
        t:assertEqual(CdmAuraMonitor.auraShown(moonfireEssential, "target"), false)
        moonfireEssential.visible = true
        moonfireIcon.active, moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached = false, nil, nil
        moonfireEssential.auraDataUnit, moonfireEssential.auraDataCached = nil, nil
    end,

    ["a monitor walks its rule through applied, pandemic and missing"] = function(t)
        local monitor = WowVision.monitors:create("CdmAura", { unit = "target" })
        t:assertEqual(monitor:getLabel(), "Cooldown Manager Auras (Target)")
        local rulesField = monitor.class:getField("rules")
        rulesField:addElement(monitor, { type = "CdmAuraState", spell = 8921 })
        local rule = monitor.rules[1]
        t:assertEqual(rule:spellName(), "Moonfire")
        t:assertEqual(rule:getLabel(), "Moonfire (8921)")

        local fired = {}
        for _, state in ipairs({ "applied", "pandemic", "missing" }) do
            local alert = rule.class:getField(state):getAlert(rule)
            alert:setEnabled(true)
            for _, output in ipairs(alert.outputs) do
                if output.key == "tts" then
                    output:setEnabled(true)
                    output.onFire = function(_, message)
                        tinsert(fired, message.text)
                    end
                end
            end
        end

        -- The first tick finds the frames and settles silently
        monitor:update()
        t:assertEqual(#rule._frames, 1)
        t:assertEqual(#fired, 0)
        t:assertEqual(rule:currentText("target"), "Moonfire, Missing")

        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active = "target", {}, true
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Applied")
        moonfireIcon.PandemicIcon = {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Pandemic")
        t:assertEqual(rule:currentText("target"), "Moonfire, Pandemic")
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active, moonfireIcon.PandemicIcon = nil, nil, false, nil
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Missing")
        t:assertEqual(#fired, 3)

        -- Without a pandemic window (WoW: Forever) the marker means nothing
        rule.class.hasPandemic = false
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active, moonfireIcon.PandemicIcon = "target", {}, true, {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Applied")
        t:assertEqual(rule:currentText("target"), "Moonfire")
        t:assertEqual(#rule:getStates(), 1)
        rule.class.hasPandemic = true
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active, moonfireIcon.PandemicIcon = nil, nil, false, nil
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Missing")
        t:assertEqual(#fired, 5)

        -- A target change holds the rule for two ticks, then announces when asked
        monitor.announceOnUnitChange = true
        monitor:onTargetChanged()
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active = "target", {}, true
        monitor:update()
        monitor:update()
        t:assertEqual(#fired, 5)
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Applied")
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active = nil, nil, false
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Missing")
        monitor.announceOnUnitChange = false

        -- The pandemic marker goes at expiry before the aura data does: the
        -- rule holds Pandemic across the gap and goes straight to Missing
        local savedGetTime = GetTime
        local now = 100
        GetTime = function()
            return now
        end
        local count = #fired
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active, moonfireIcon.PandemicIcon = "target", {}, true, {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Pandemic")
        now = now + 0.1
        moonfireIcon.PandemicIcon = nil
        monitor:update()
        t:assertEqual(#fired, count + 1)
        t:assertEqual(rule:getCurrentState(), "pandemic")
        now = now + 0.3
        monitor:update()
        t:assertEqual(#fired, count + 1)
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active = nil, nil, false
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Missing")
        t:assertEqual(#fired, count + 2)

        -- A refresh in pandemic re-reads the aura, so Applied follows on
        -- the second tick without the marker
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active, moonfireIcon.PandemicIcon = "target", {}, true, {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Pandemic")
        now = now + 0.1
        moonfireIcon:SetAuraInstanceInfo({})
        moonfireIcon.PandemicIcon = nil
        monitor:update()
        t:assertEqual(rule:getCurrentState(), "pandemic")
        now = now + 0.02
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Applied")
        t:assertEqual(#fired, count + 4)

        -- A one-tick marker glitch after a re-read changes nothing
        moonfireIcon.PandemicIcon = {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Pandemic")
        now = now + 0.1
        moonfireIcon:SetAuraInstanceInfo({})
        moonfireIcon.PandemicIcon = nil
        monitor:update()
        moonfireIcon.PandemicIcon = {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Pandemic")
        t:assertEqual(#fired, count + 5)
        count = count + 1

        -- The trace recorded the hold
        local traceText = table.concat(WowVision.monitors.CdmAuraMonitor.trace, "|")
        t:assertTrue(traceText:find("hold starts", 1, true) ~= nil, "trace has the hold")
        t:assertTrue(traceText:find("aura reread", 1, true) ~= nil, "trace has the reread")

        -- At expiry the widget finishes first and the viewer's own refresh
        -- re-reads the aura the game still lists: that re-read is no refresh
        now = now + 0.1
        moonfireIcon.PandemicIcon = {}
        monitor:update()
        t:assertEqual(rule:getCurrentState(), "pandemic")
        now = now + 0.1
        moonfireIcon.Cooldown.onDone(moonfireIcon.Cooldown)
        moonfireIcon:SetAuraInstanceInfo({})
        moonfireIcon.PandemicIcon = nil
        monitor:update()
        now = now + 0.02
        monitor:update()
        now = now + 0.02
        monitor:update()
        t:assertEqual(rule:getCurrentState(), "pandemic")
        t:assertEqual(#fired, count + 4)
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active = nil, nil, false
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Missing")
        t:assertEqual(#fired, count + 5)
        count = count + 1
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active, moonfireIcon.PandemicIcon = "target", {}, true, {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Pandemic")
        t:assertEqual(#fired, count + 5)
        count = count + 1

        -- A target change: a hidden viewer's stale aura data does not keep
        -- the rule in Applied on the new target
        now = now + 0.1
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active, moonfireIcon.PandemicIcon = nil, nil, false, nil
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Missing")
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active = "target", {}, true
        moonfireEssential.auraDataUnit, moonfireEssential.auraDataCached = "target", {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Applied")
        count = #fired
        monitor:onTargetChanged()
        moonfireIcon.visible = false
        monitor:update()
        monitor:update()
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Missing")
        t:assertEqual(#fired, count + 1)
        local lastTrace = WowVision.monitors.CdmAuraMonitor.trace[#WowVision.monitors.CdmAuraMonitor.trace]
        t:assertTrue(lastTrace:find("hidden", 1, true) ~= nil, "trace marks the hidden frame")
        t:assertTrue(lastTrace:find("after target change", 1, true) ~= nil, "trace marks the target change")
        moonfireIcon.visible = true
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active = nil, nil, false
        moonfireEssential.auraDataUnit, moonfireEssential.auraDataCached = nil, nil
        monitor:update()
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active, moonfireIcon.PandemicIcon = "target", {}, true, {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Pandemic")
        count = #fired - 4

        -- Without a re-read the hold runs out and Applied follows
        now = now + 0.1
        moonfireIcon.PandemicIcon = {}
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Pandemic")
        now = now + 0.1
        moonfireIcon.PandemicIcon = nil
        monitor:update()
        t:assertEqual(rule:getCurrentState(), "pandemic")
        now = now + 1.1
        monitor:update()
        t:assertEqual(fired[#fired], "Moonfire Applied")
        t:assertEqual(#fired, count + 5)
        moonfireIcon.auraDataUnit, moonfireIcon.auraDataCached, moonfireIcon.active = nil, nil, false
        monitor:update()
        GetTime = savedGetTime
    end,
})

-- Spell Cooldowns monitor: the cooldown APIs as the game answers them,
-- with plain flags and a fake duration object
local fakeCooldowns = {}
local fakeCharges = {}
local fakeOverlays = {}
C_Spell.GetSpellCooldown = C_Spell.GetSpellCooldown or function(id)
    return fakeCooldowns[id] or { isActive = false, isEnabled = true, startTime = 0, duration = 0 }
end
C_Spell.GetSpellCharges = C_Spell.GetSpellCharges or function(id)
    return fakeCharges[id]
end
C_Spell.GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration or function(id)
    return {
        FormatRemainingDuration = function(_, formatter)
            return formatter.format(fakeCooldowns[id] and fakeCooldowns[id].remaining or 0)
        end,
    }
end
C_Spell.GetSpellChargeDuration = C_Spell.GetSpellChargeDuration or function(id)
    return {
        FormatRemainingDuration = function(_, formatter)
            return formatter.format(fakeCharges[id] and fakeCharges[id].remaining or 0)
        end,
    }
end
C_StringUtil = C_StringUtil or {}
C_StringUtil.CreateNumericRuleFormatter = C_StringUtil.CreateNumericRuleFormatter or function()
    local formatter = { breakpoints = {} }
    function formatter:AddBreakpoint(breakpoint)
        tinsert(self.breakpoints, breakpoint)
    end
    function formatter.format(seconds)
        if seconds >= 60 then
            return string.format(formatter.breakpoints[2].format, math.floor(seconds / 60), seconds % 60)
        end
        return string.format(formatter.breakpoints[1].format, seconds)
    end
    return formatter
end
Enum = Enum or {}
Enum.NumericRuleFormatRounding = Enum.NumericRuleFormatRounding or { Nearest = 0, Up = 1, Down = 2 }
C_SpellActivationOverlay = C_SpellActivationOverlay or {}
C_SpellActivationOverlay.IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed or function(id)
    return fakeOverlays[id] == true
end
-- The game says which entries have a cooldown to alert on: Starsurge yes,
-- Moonfire (an instant with only the global cooldown) no
Enum.CooldownViewerAlertEventType = Enum.CooldownViewerAlertEventType or { Available = 1, PandemicTime = 2, OnCooldown = 3, ChargeGained = 4, OnAuraApplied = 5, OnAuraRemoved = 6 }
C_CooldownViewer = C_CooldownViewer or {}
C_CooldownViewer.GetValidAlertTypes = C_CooldownViewer.GetValidAlertTypes or function(cooldownID)
    if cooldownID == 78674 or cooldownID == 90 then
        return { 1, 3 }
    end
    return {}
end
loadAddonFile("retail/monitors/SpellCooldownMonitor.lua")
WowVision.testing.testRunner:addSuite("SpellCooldownMonitor", {
    ["the pickers list the Essential and Utility spells, cooldowns only for cooldown rules"] = function(t)
        -- An entry's linked spells are picks of their own, the base is not
        local spells = WowVision.monitors.SpellCooldownMonitor.cooldownSpells()
        t:assertEqual(#spells, 3)
        t:assertEqual(spells[1].name, "Eclipse (Lunar)")
        t:assertEqual(spells[1].spellID, 48518)
        t:assertEqual(spells[2].name, "Eclipse (Solar)")
        t:assertEqual(spells[3].name, "Starsurge")
        local procs = WowVision.monitors.SpellCooldownMonitor.procSpells()
        t:assertEqual(#procs, 4)
        t:assertEqual(procs[1].name, "Eclipse (Lunar)")
        t:assertEqual(procs[3].name, "Moonfire")
        t:assertEqual(procs[4].name, "Starsurge")
        t:assertEqual(WowVision.classes.fieldTypes.CooldownSpell ~= nil, true)
        t:assertEqual(WowVision.classes.fieldTypes.ProcSpell ~= nil, true)
    end,
    ["a cooldown rule walks Ready, On Cooldown and back, ignoring the global cooldown"] = function(t)
        local savedGetTime = GetTime
        local now = 500
        GetTime = function()
            return now
        end
        local monitor = WowVision.monitors:create("SpellCooldown", {})
        t:assertEqual(monitor:getLabel(), "Spell Cooldowns")
        local rulesField = monitor.class:getField("rules")
        rulesField:addElement(monitor, { type = "SpellCooldownState", spell = 22812 })
        local rule = monitor.rules[1]
        t:assertEqual(rule:getLabel(), "Barkskin (22812)")

        local fired = {}
        for _, state in ipairs({ "ready", "charging", "on_cooldown" }) do
            local alert = rule.class:getField(state):getAlert(rule)
            alert:setEnabled(true)
            for _, output in ipairs(alert.outputs) do
                if output.key == "tts" then
                    output:setEnabled(true)
                    output.onFire = function(_, message)
                        tinsert(fired, message.text)
                    end
                end
            end
        end

        -- The first tick settles silently on Ready
        monitor:update()
        t:assertEqual(rule:getCurrentState(), "ready")
        t:assertEqual(#fired, 0)
        t:assertEqual(rule:currentText(), "Barkskin, Ready")

        -- The global cooldown alone is not a cooldown
        fakeCooldowns[22812] = { isActive = true, isEnabled = true, isOnGCD = true, remaining = 1 }
        monitor:onCooldownEvent("SPELL_UPDATE_COOLDOWN")
        t:assertEqual(rule:getCurrentState(), "ready")
        t:assertEqual(#fired, 0)
        fakeCooldowns[22812] = nil
        monitor:onCooldownEvent("SPELL_UPDATE_COOLDOWN")

        -- A real cooldown: the event says so, with the time left in our words
        fakeCooldowns[22812] = { isActive = true, isEnabled = true, remaining = 49 }
        monitor:onCooldownEvent("SPELL_UPDATE_COOLDOWN")
        t:assertEqual(fired[#fired], "Barkskin On Cooldown")
        t:assertEqual(rule:currentText(), "Barkskin, On Cooldown, 49 seconds")
        fakeCooldowns[22812].remaining = 75
        t:assertEqual(rule:currentText(), "Barkskin, On Cooldown, 1 minutes 15 seconds")

        -- No event marks the end: the poll finds the flag down, on its
        -- schedule rather than every tick
        monitor:update()
        fakeCooldowns[22812] = nil
        monitor:update()
        t:assertEqual(rule:getCurrentState(), "on_cooldown")
        now = now + 0.2
        monitor:update()
        t:assertEqual(fired[#fired], "Barkskin Ready")
        t:assertEqual(#fired, 2)

        -- Charges: recharging with one in hand is Charging, none left is On Cooldown
        rulesField:addElement(monitor, { type = "SpellCooldownState", spell = 108853 })
        local charged = monitor.rules[2]
        local chargedFired = {}
        for _, state in ipairs({ "ready", "charging", "on_cooldown" }) do
            local alert = charged.class:getField(state):getAlert(charged)
            alert:setEnabled(true)
            for _, output in ipairs(alert.outputs) do
                if output.key == "tts" then
                    output:setEnabled(true)
                    output.onFire = function(_, message)
                        tinsert(chargedFired, message.text)
                    end
                end
            end
        end
        monitor._trackingDirty = true
        monitor:update()
        t:assertEqual(charged:getCurrentState(), "ready")
        fakeCharges[108853] = { maxCharges = 2, currentCharges = 1, isActive = true, remaining = 8 }
        monitor:onCooldownEvent("SPELL_UPDATE_CHARGES")
        t:assertEqual(chargedFired[#chargedFired], "Fire Blast Charging")
        t:assertEqual(charged:currentText(), "Fire Blast, Charging, 1 charges, 8 seconds")
        fakeCooldowns[108853] = { isActive = true, isEnabled = true, remaining = 8 }
        fakeCharges[108853].currentCharges = 0
        monitor:onCooldownEvent("SPELL_UPDATE_COOLDOWN")
        t:assertEqual(chargedFired[#chargedFired], "Fire Blast On Cooldown")
        fakeCooldowns[108853] = nil
        monitor:onCooldownEvent("SPELL_UPDATE_COOLDOWN")
        t:assertEqual(chargedFired[#chargedFired], "Fire Blast Charging")
        fakeCharges[108853] = nil
        now = now + 0.2
        monitor:update()
        t:assertEqual(chargedFired[#chargedFired], "Fire Blast Ready")
        GetTime = savedGetTime
    end,
    ["a proc rule follows the glow"] = function(t)
        local monitor = WowVision.monitors:create("SpellCooldown", {})
        local rulesField = monitor.class:getField("rules")
        rulesField:addElement(monitor, { type = "SpellProc", spell = 78674 })
        local rule = monitor.rules[1]
        local fired = {}
        for _, state in ipairs({ "active", "inactive" }) do
            local alert = rule.class:getField(state):getAlert(rule)
            alert:setEnabled(true)
            for _, output in ipairs(alert.outputs) do
                if output.key == "tts" then
                    output:setEnabled(true)
                    output.onFire = function(_, message)
                        tinsert(fired, message.text)
                    end
                end
            end
        end
        monitor:update()
        t:assertEqual(rule:getCurrentState(), "inactive")
        t:assertEqual(#fired, 0)
        t:assertEqual(rule:currentText(), "Starsurge, No proc")
        monitor:onGlow(78674, true)
        t:assertEqual(fired[#fired], "Starsurge Proc")
        t:assertEqual(rule:currentText(), "Starsurge, Proc")
        monitor:onGlow(22812, false)
        t:assertEqual(rule:getCurrentState(), "active")
        monitor:onGlow(78674, false)
        t:assertEqual(fired[#fired], "Starsurge Proc Ended")
        t:assertEqual(#fired, 2)
        -- A glow that starts before the rule exists is found on settling
        fakeOverlays[78674] = true
        monitor._trackingDirty = true
        monitor:update()
        t:assertEqual(rule:getCurrentState(), "active")
        fakeOverlays[78674] = nil
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

    ["a TTS output with a game voice keeps that voice when voices are installed"] = function(t)
        local voices = { { voiceID = 0, name = "Hedda" }, { voiceID = 1, name = "Zira" } }
        local spoken = {}
        C_VoiceChat = {
            GetTtsVoices = function()
                return voices
            end,
            SpeakText = function(voice, text)
                tinsert(spoken, voice)
            end,
        }
        WowVision.base = { speech = { settings = { speechVolume = 100, speechRate = 0 } } }
        local alert = WowVision.alerts.Alert:new({ key = "walk", label = "Walk" })
        alert:addOutput({
            type = "TTS",
            key = "tts",
            label = "TTS",
            voice = 0,
            buildMessage = function(self, message)
                return message.text
            end,
        })
        -- A db saved before the Voice setting existed: pinned to voice 0's name.
        local db = alert:getDefaultDBRecursive()
        db.outputs.tts.voice = nil
        alert:setDB(db)
        t:assertEqual(db.outputs.tts.voice, "Hedda")
        alert:fire({ text = "Brunnen" })
        t:assertEqual(spoken[1], 0)
        -- Two voices installed ahead of Hedda: the same voice, a new number.
        voices = {
            { voiceID = 0, name = "Katja" },
            { voiceID = 1, name = "Stefan" },
            { voiceID = 2, name = "Hedda" },
            { voiceID = 3, name = "Zira" },
        }
        alert:setDB(db)
        alert:fire({ text = "Tor" })
        t:assertEqual(spoken[2], 2)
        C_VoiceChat = nil
        WowVision.base = nil
    end,
})

loadAddonFile("core/graph/ControlId.lua")
loadAddonFile("core/graph/types.lua")
loadAddonFile("core/graph/Announcer.lua")
loadAddonFile("core/graph/KeyGraph.lua")
loadAddonFile("core/graph/typeAhead.lua")
loadAddonFile("core/graph/typeAheadTests.lua")
loadAddonFile("core/graph/Builder.lua")
loadAddonFile("core/graph/ControlTypes.lua")
loadAddonFile("core/graph/nodes.lua")
loadAddonFile("core/graph/dropdownMenu.lua")
loadAddonFile("core/graph/dropdownTests.lua")
loadAddonFile("core/graph/scrollBox.lua")
loadAddonFile("core/graph/settings.lua")
loadAddonFile("core/graph/fieldControls.lua")
loadAddonFile("core/graph/tests.lua")
loadAddonFile("core/graph/controlTests.lua")
loadAddonFile("core/targeting/targetNames.lua")
loadAddonFile("core/targeting/targetNamesTests.lua")

-- Native quest source and the scanner's quest categories: the adapter and
-- the provider load against stand-ins for the quest module and the scanner;
-- the suite installs the game's map and quest log APIs per test and points
-- the stand-in module at its own source.
do
    local savedBase = WowVision.base
    local harness = { providers = {}, source = nil }
    local questModule = { L = WowVision:getLocale() }
    questModule.settings = { sortByProximity = false }
    function questModule:hasSource()
        return true
    end
    function questModule:isReady()
        return true
    end
    function questModule:inProgress()
        return harness.source:inProgress()
    end
    function questModule:targets(questId, phase)
        return harness.source:targets(questId, phase)
    end
    function questModule:objectiveTargets(questId, index)
        return harness.source:objectiveTargets(questId, index)
    end
    function questModule:quest(questId)
        return harness.source:quest(questId)
    end
    function questModule:placeName()
        return nil
    end
    -- the scanner's last resorts; like the real module, nil when the source
    -- has no such lookup (the native source has neither)
    function questModule:markerTarget(questId, index)
        if harness.source.markerTarget == nil then
            return nil
        end
        return harness.source:markerTarget(questId, index)
    end
    function questModule:gameMarkerTarget(questId)
        if harness.source.gameMarkerTarget == nil then
            return nil
        end
        return harness.source:gameMarkerTarget(questId)
    end
    WowVision.base = {
        quests = questModule,
        scanner = {
            registerProvider = function(_, provider)
                harness.providers[provider.key] = provider
            end,
        },
    }
    loadAddonFile("core/quests/Adapter.lua")
    loadAddonFile("core/quests/native.lua")
    loadAddonFile("core/quests/scanner.lua")
    WowVision.quests._nativeTestHarness = harness
    loadAddonFile("core/quests/nativeTests.lua")
    WowVision.base = savedBase
end

-- Files that need the game client to run but should at least parse cleanly.
local parseOnly = {
    "vanilla/speech.lua",
    "tbc/speech.lua",
    "mists/speech.lua",
    "retail/speech.lua",
    "core/graph/Screen.lua",
    "core/graph/Host.lua",
    "core/graph/liveWatch.lua",
    "core/graph/textEntry.lua",
    "core/graph/keyCapture.lua",
    "core/ui/input/actions.lua",
    "core/ui/input/activator.lua",
    "core/ui/input/pad.lua",
    "core/ui/input/tests.lua",
    "core/ui/Window.lua",
    "core/ui/WindowManager.lua",
    "core/windows/GameMenu.lua",
    "core/errors/module.lua",
    "core/quests/module.lua",
    "core/ui modules/graphBindings.lua",
    "core/ui modules/gameDefaultsMenu.lua",
    "core/buffers/module.lua",
    "core/windows/options/ui.lua",
    "core/windows/options/Module.lua",
    "mists/talents/talents.lua",
    "mists/talents/glyphs.lua",
    "core/windows/gossip.lua",
    "core/windows/questWindow.lua",
    "core/windows/popups.lua",
    "core/windows/colorPicker.lua",
    "camelot/character.lua",
    "camelot/spellbook.lua",
    "camelot/talents.lua",
    "camelot/legacy/legacy.lua",
    "camelot/legacy/rewardTrack.lua",
    "camelot/legacy/challenges.lua",
    "camelot/legacy/tree.lua",
    "core/graph/hybridScroll.lua",
    "mists/QuestLog.lua",
    "core/windows/merchant.lua",
    "core/windows/containers.lua",
    "classic/containers/Bag.lua",
    "classic/containers/Bank.lua",
    "retail/containers/containers.lua",
    "retail/containers/Bags.lua",
    "retail/containers/Bank.lua",
    "retail/channels.lua",
    "retail/socialUI.lua",
    "retail/communities.lua",
    "retail/guildControl.lua",
    "core/windows/guildInvite.lua",
    "retail/QuestLog.lua",
    "retail/cooldownManager.lua",
    "retail/talentTree.lua",
    "retail/spellSearch.lua",
    "core/windows/training.lua",
    "core/windows/ready.lua",
    "core/windows/taxi.lua",
    "core/windows/mail.lua",
    "classic/mail.lua",
    "classic/friends.lua",
    "classic/quests/questie.lua",
    "core/quests/module.lua",
    "core/quests/scanner.lua",
    "core/quests/places.lua",
    "core/quests/native.lua",
    "core/quests/probe.lua",
    "core/quests/seen.lua",
    "core/minimap/engine.lua",
    "core/minimap/module.lua",
    "core/minimap/scanner.lua",
    "core/minimap/tracking.lua",
    "retail/groupHealth/module.lua",
    "core/scanner/module.lua",
    "core/scanner/ui.lua",
    "core/scanner/providers.lua",
    "core/navigation/maps/module.lua",
    "core/navigation/maps/ui.lua",
    "core/navigation/visited.lua",
    "camelot/wownav/module.lua",
    "core/navigation/corpse.lua",
    "core/navigation/targetRoute.lua",
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
    "mists/collections/module.lua",
    "mists/collections/MountJournal.lua",
    "core/chat/module.lua",
    "core/chat/ui.lua",
    "core/ui/tooltip/types/HyperlinkTooltip.lua",
    "core/ui/tooltip/types/AuraTooltip.lua",
    "mists/auction.lua",
    "tbc/QuestLog.lua",
    "tbc/socketing.lua",
    "tbc/spellbook.lua",
    "tbc/talents.lua",
    "tbc/tradeskill.lua",
    "tbc/lfg.lua",
    "camelot/lfg.lua",
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
    "core/ui/input/binding.lua",
    "core/ui/input/bindings.lua",
    "core/ui/input/input.lua",
    "core/windows/bars/StanceBar.lua",
    "classic/containers/Bag.lua",
    "core/WowVision.lua",
    "core/module/Module.lua",
    "core/alerts/alerts.lua",
    "retail/targeting.lua",
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
