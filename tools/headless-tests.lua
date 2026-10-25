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
loadAddonFile("core/minimap/logic.lua")
loadAddonFile("core/minimap/gatheringNames.lua")
loadAddonFile("core/minimap/tests.lua")
loadAddonFile("core/colors/names.lua")
loadAddonFile("core/colors/colors.lua")
loadAddonFile("core/colors/tests.lua")
loadAddonFile("core/windows/bars/lock.lua")
loadAddonFile("core/windows/bars/tests.lua")
loadAddonFile("core/targeting/softTargeting.lua")
loadAddonFile("core/targeting/softTargetingTests.lua")
loadAddonFile("core/ui modules/enemyCount.lua")
loadAddonFile("core/ui modules/enemyCountTests.lua")
loadAddonFile("core/db.lua")
loadAddonFile("core/dbTests.lua")
loadAddonFile("core/utils.lua")
loadAddonFile("core/utilsTests.lua")
loadAddonFile("core/secrets.lua")
loadAddonFile("core/secretsTests.lua")
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
WowVision.buffers.AuraBuffer.scanner = {
    fill = function(unit, index, filter)
        local aura = fakeIndexRead(unit, index, filter)
        scanLines = aura and fakeTooltips[aura.name] or {}
        return #scanLines
    end,
    line = function(index)
        return scanLines[index]
    end,
}
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
        t:assertEqual(buffer.items[1]:getFocusString(), "Moonfire, 12 seconds remaining, of 18 seconds, Magic")
        t:assertEqual(buffer.items[2]:getFocusString(), "Sunfire, 3 stacks")
        t:assertEqual(buffer.items[3]:getFocusString(), "Mark of the Wild, 59 minutes remaining, of 3600 seconds")
        t:assertEqual(buffer.items[4]:getFocusString(), "Focus Debuffs, no focus")

        -- The game's list changed: the rebuild keeps the position
        buffer:focusIndex(2)
        table.remove(fakeAuras.target.HARMFUL, 1)
        buffer:rebuild()
        t:assertEqual(#buffer.items, 3)
        t:assertEqual(buffer:getFocus():getFocusString(), "Mark of the Wild, 59 minutes remaining, of 3600 seconds")

        -- Under restriction the index read is refused; the tooltip speaks
        -- the name and the last line
        restrictedUnits.target = true
        buffer:rebuild()
        t:assertEqual(#buffer.items, 3)
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, Burns.")
        t:assertEqual(buffer.items[2]:getFocusString(), "Mark of the Wild, 59 minutes remaining, of 3600 seconds")
        restrictedUnits.target = nil
        buffer:rebuild()

        -- Only my auras narrows the filter; a source change rebuilds
        buffer.onlyMine = true
        t:assertEqual(buffer.items[1]:getFocusString(), "Sunfire, 3 stacks")
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
        t:assertEqual(again.items[1].items[1].items[1]:getFocusString(), "Sunfire, 3 stacks")

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
local fakeSpellNames = { [8921] = "Moonfire", [164812] = "Moonfire", [93402] = "Sunfire", [78674] = "Starsurge", [79577] = "Eclipse", [48518] = "Eclipse (Lunar)", [48517] = "Eclipse (Solar)" }
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
BuffIconCooldownViewer = { GetItemFrames = function()
    return { moonfireIcon, sunfireIcon }
end }
EssentialCooldownViewer = { GetItemFrames = function()
    return { moonfireEssential, starsurgeEssential }
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
loadAddonFile("core/graph/Builder.lua")
loadAddonFile("core/graph/ControlTypes.lua")
loadAddonFile("core/graph/nodes.lua")
loadAddonFile("core/graph/dropdownMenu.lua")
loadAddonFile("core/graph/scrollBox.lua")
loadAddonFile("core/graph/settings.lua")
loadAddonFile("core/graph/fieldControls.lua")
loadAddonFile("core/graph/tests.lua")
loadAddonFile("core/graph/controlTests.lua")

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
    "core/ui modules/graphBindings.lua",
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
    "core/scanner/module.lua",
    "core/scanner/ui.lua",
    "core/scanner/providers.lua",
    "core/navigation/maps/module.lua",
    "core/navigation/maps/ui.lua",
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
