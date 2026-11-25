-- Headless only (tools/headless-tests.lua loads the meter's files, then module.lua against a stand-in window module,
-- and hands over the loader): the figures read from a stand-in game damage meter, said and listed, the keys, the
-- command and the screen.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._detailsMeterTestHarness
local ns = WowVision.detailsMeter
local Data, Game, Screen = ns.Data, ns.Game, ns.Screen

local module, registered = harness.load({ Details = true })

local function source(name, amount, perSecond, me)
    return { name = name, totalAmount = amount, amountPerSecond = perSecond, isLocalPlayer = me, sourceGUID = "guid-" .. name }
end

-- A meter with two kept fights (7 older, 9 newer), a current fight where the player is second, and two kinds.
local function withMeter(test)
    local world = { spoken = {}, now = 100, combat = false, resets = 0, window = nil }
    local saved = {}
    for key, value in pairs(Game) do
        saved[key] = value
    end
    Game.speak = function(text)
        tinsert(world.spoken, text)
    end
    Game.now = function()
        world.now = world.now + 10
        return world.now
    end
    Game.inCombat = function()
        return world.combat
    end
    Game.available = function()
        if world.off then
            return false, world.off
        end
        return true
    end
    Game.meterType = function(name)
        if name == "DamageDone" then
            return 0
        elseif name == "Interrupts" then
            return 5
        end
        return nil
    end
    Game.sessions = function()
        return { { sessionID = 7, name = "Boar", durationSeconds = 20 }, { sessionID = 9, name = "Wolf", durationSeconds = 80 } }
    end
    Game.session = function(segment, meterType)
        if segment.kind == "id" and segment.id == 7 then
            return { durationSeconds = 20, combatSources = {} }
        end
        if meterType == 5 then
            return { durationSeconds = 65, combatSources = { source("Me", 1, 0, true) } }
        end
        return { durationSeconds = 65, combatSources = { source("Bob", 30000, 500), source("Me", 15000, 250, true) } }
    end
    Game.sourceSpells = function()
        return nil
    end
    Game.globalString = function()
        return nil
    end
    Game.detailsWindow = function()
        return world.window
    end
    Game.hasDetails = function()
        return true
    end
    Game.after = function(_, fn)
        fn()
    end
    Game.resetAll = function()
        world.resets = world.resets + 1
        return true
    end
    Game.isOpen = function()
        return world.open == true
    end
    Game.open = function(config)
        world.open, world.config = true, config
        return true
    end
    Game.close = function()
        world.open = false
    end
    local savedSettings, savedData, savedSaved = ns.settings, module.data, ns.saved
    ns.settings = { follow = false }
    module.data = {}
    Data.clearCache()
    ns.pendingReset = nil
    local ok, err = pcall(test, world)
    ns.settings, module.data, ns.saved = savedSettings, savedData, savedSaved
    for key in pairs(Game) do
        Game[key] = nil
    end
    for key, value in pairs(saved) do
        Game[key] = value
    end
    Data.clearCache()
    if not ok then
        error(err, 0)
    end
end

local function binding(key)
    for _, info in ipairs(registered.bindings) do
        if info.key == key then
            return info
        end
    end
    return nil
end

local function said(world)
    return world.spoken[#world.spoken]
end

testRunner:addSuite("DetailsMeter", {
    ["without Details there is no module and no key"] = function(t)
        local other, nothing = harness.loadOther({})
        t:assertNil(other)
        t:assertEqual(#nothing.bindings, 0)
        t:assertNotNil(harness.loadOther({ details = true }))
    end,

    ["four keys, a command and the follow setting"] = function(t)
        t:assertEqual(#registered.bindings, 4)
        t:assertEqual(binding("details/open").inputs[1], "SHIFT-F6")
        t:assertEqual(binding("details/say").inputs[1], "ALT-CTRL-D")
        t:assertEqual(binding("details/measure-next").inputs[1], "ALT-CTRL-M")
        t:assertEqual(binding("details/fight-next").inputs[1], "ALT-CTRL-C")
        t:assertNotNil(registered.commands.meter)
        t:assertTrue(module.settings.follow)
    end,

    ["your line gives your figure, your rank and the best"] = function(t)
        withMeter(function(world)
            binding("details/say").func()
            t:assertTrue(said(world):find("15000 damage", 1, true) ~= nil)
            -- the rank word comes from the locale; the runner's locale reads keys back
            t:assertTrue(said(world):find("ordinal 2 of 2", 1, true) ~= nil)
            t:assertTrue(said(world):find("Bob", 1, true) ~= nil)
        end)
    end,

    ["a meter that is off or missing says so"] = function(t)
        withMeter(function(world)
            world.off = "disabled"
            ns.sayMine()
            t:assertEqual(said(world), "The game's damage meter is turned off.")
            world.off = "missing"
            ns.sayMine()
            t:assertEqual(said(world), "The game's damage meter is not available.")
        end)
    end,

    ["the fights come current, all together, then the kept ones newest first"] = function(t)
        withMeter(function()
            local choices = Data.segmentChoices()
            t:assertEqual(choices[1].value, "current")
            t:assertEqual(choices[2].value, "overall")
            t:assertEqual(choices[3].value, "id:9")
            t:assertEqual(choices[4].value, "id:7")
            t:assertEqual(Data.lastKept().value, "id:9")
        end)
    end,

    ["the keys step through the measures and the fights"] = function(t)
        withMeter(function(world)
            binding("details/measure-next").func()
            t:assertEqual(module.data.attribute, "Interrupts")
            t:assertTrue(said(world):find("1 interrupt", 1, true) ~= nil)
            binding("details/fight-next").func()
            t:assertEqual(module.data.segment, "overall")
            t:assertFalse(ns.settings.follow)
        end)
    end,

    ["Details' window is followed unless the player turned that off"] = function(t)
        withMeter(function(world)
            ns.settings.follow = true
            world.window = { segment = { kind = "id", id = 9 }, attributeValue = 5 }
            local selection = Data.selection()
            t:assertTrue(selection.followed)
            t:assertEqual(selection.segment.id, 9)
            t:assertEqual(selection.attribute, "Interrupts")
            ns.settings.follow = false
            t:assertFalse(Data.selection().followed)
        end)
    end,

    ["an empty fight has nothing to read"] = function(t)
        withMeter(function(world)
            module.data.segment = "id:7"
            ns.sayMine()
            t:assertTrue(said(world):find("You are not in this list", 1, true) ~= nil)
        end)
    end,

    ["the command asks before it erases, and erases only when told yes"] = function(t)
        withMeter(function(world)
            registered.commands.meter.func("reset yes")
            t:assertEqual(world.resets, 0)
            registered.commands.meter.func("reset")
            registered.commands.meter.func("reset no")
            registered.commands.meter.func("reset yes")
            t:assertEqual(world.resets, 0)
            registered.commands.meter.func("reset")
            registered.commands.meter.func("reset yes")
            t:assertEqual(world.resets, 1)
            world.combat = true
            registered.commands.meter.func("reset")
            t:assertEqual(said(world), "Erasing is not possible during a fight. Try again after it.")
        end)
    end,

    ["Shift+F6 opens the screen, drawn by the real graph engine, and closes it"] = function(t)
        withMeter(function(world)
            binding("details/open").func()
            t:assertTrue(world.open)
            local builder = WowVision.graph.Builder:new()
            world.config.render(builder, {})
            local rendered = builder:build()
            local stops = {}
            for _, node in ipairs(rendered.order) do
                stops[node.stopKey] = true
            end
            local count = 0
            for _ in pairs(stops) do
                count = count + 1
            end
            t:assertTrue(count >= 3)
            binding("details/open").func()
            t:assertFalse(world.open)
        end)
    end,

    ["the module's screen adds the meter's buttons"] = function(t)
        withMeter(function()
            local builder = WowVision.graph.Builder:new()
            module:getGraphMenuItems(builder)
            local rendered = builder:build()
            t:assertTrue(#rendered.order >= 4)
        end)
    end,
})
