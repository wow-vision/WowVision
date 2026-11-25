-- Headless only (tools/headless-tests.lua loads the files, then module.lua against a stand-in window module, and hands
-- over the loader): a stand-in Forever Fishing, what is said about its window, the session's worth, the screen, the
-- keys and the menu entry.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._foreverFishingTestHarness
local ns = WowVision.foreverFishing
local Game, Value, Fishing, Screen = ns.Game, ns.Value, ns.Fishing, ns.Screen

local module, registered = harness.load({ ForeverFishing = true })

local function withFishing(test)
    local world = { spoken = {}, open = false, toggled = 0, combat = false, screen = nil }
    local saved = {}
    for key, value in pairs(Game) do
        saved[key] = value
    end
    Game.speak = function(text)
        tinsert(world.spoken, text)
    end
    Game.available = function()
        return true
    end
    Game.isOpen = function()
        return world.open
    end
    Game.inCombat = function()
        return world.combat
    end
    Game.toggleUI = function()
        world.open = not world.open
        world.toggled = world.toggled + 1
    end
    Game.toggleGear = function()
        world.gear = not world.gear
    end
    Game.texts = function()
        return { hint = "Press K", others = {} }
    end
    Game.inputKey = function()
        return "K"
    end
    Game.rod = function()
        return "bags"
    end
    Game.gearOn = function()
        return false
    end
    Game.autoEquip = function()
        return true
    end
    Game.autoRestore = function()
        return true
    end
    Game.localized = function()
        return nil
    end
    Game.sessionRecords = function()
        return world.records
    end
    Game.sessionSeconds = function()
        return world.seconds or 0
    end
    Game.coinText = function(copper)
        return copper .. "c"
    end
    Game.isScreenOpen = function()
        return world.screen ~= nil
    end
    Game.openScreen = function(config)
        world.screen = config
        return true
    end
    Game.closeScreen = function()
        world.screen = nil
    end
    local savedMessages, savedName, savedHints = module.settings.messages, Screen.keyName, WowVision.auctionHints
    Screen.keyName = function()
        return "Shift+F7"
    end
    ns.announcedOpen = false
    local ok, err = pcall(test, world)
    module.settings.messages, Screen.keyName, WowVision.auctionHints = savedMessages, savedName, savedHints
    ns.announcedOpen = false
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

local function said(world)
    return world.spoken[#world.spoken] or ""
end

testRunner:addSuite("ForeverFishing", {
    ["without Forever Fishing there is no module and no key"] = function(t)
        local other, nothing = harness.loadOther({})
        t:assertNil(other)
        t:assertEqual(#nothing.bindings, 0)
        t:assertNil(nothing.rootEntry)
        t:assertNotNil(harness.loadOther({ foreverfishing = true }))
    end,

    ["Shift+F7, a command, a menu entry and messages on"] = function(t)
        t:assertEqual(registered.bindings[1].inputs[1], "SHIFT-F7")
        t:assertNotNil(registered.commands.fishing)
        t:assertNotNil(registered.rootEntry)
        t:assertTrue(module.settings.messages)
    end,

    ["the menu entry starts fishing as /fish does, and does not close an open window"] = function(t)
        withFishing(function(world)
            local builder = WowVision.graph.Builder:new()
            registered.rootEntry(builder)
            local rendered = builder:build()
            rendered.order[1].vtable.onActivate()
            t:assertEqual(world.toggled, 1)
            t:assertEqual(said(world), "Start fishing")
            ns.startFishing()
            t:assertEqual(world.toggled, 1)
            t:assertTrue(said(world):find("Shift+F7", 1, true) ~= nil)
        end)
    end,

    ["an opening is said once, a hide of the parent is not a closing"] = function(t)
        withFishing(function(world)
            world.open = true
            ns.onShown()
            ns.onShown()
            t:assertEqual(#world.spoken, 1)
            ns.onHidden()
            t:assertEqual(#world.spoken, 1)
            world.open = false
            ns.onHidden()
            t:assertEqual(said(world), "Fishing window closed.")
            ns.onHidden()
            t:assertEqual(#world.spoken, 2)
        end)
    end,

    ["with messages off nothing is said by itself"] = function(t)
        withFishing(function(world)
            module.settings.messages = false
            world.open = true
            ns.onShown()
            ns.onNotice("Gear equipped", "gear")
            ns.onWarning("Too far")
            t:assertEqual(#world.spoken, 0)
        end)
    end,

    ["the window's gear results and warnings are said"] = function(t)
        withFishing(function(world)
            ns.onNotice("Gear equipped", "gear")
            ns.onNotice("Cooking", "chef")
            ns.onWarning("Too far")
            t:assertEqual(world.spoken[1], "Gear equipped")
            t:assertEqual(world.spoken[2], "Too far")
            t:assertEqual(#world.spoken, 2)
        end)
    end,

    ["the command turns the messages off and on"] = function(t)
        withFishing(function(world)
            registered.commands.fishing.func("messages off")
            t:assertFalse(module.settings.messages)
            registered.commands.fishing.func("messages on")
            t:assertTrue(module.settings.messages)
            t:assertEqual(said(world), "Fishing messages are on.")
        end)
    end,

    ["without the auction hints the session is valued at vendor prices"] = function(t)
        withFishing(function(world)
            WowVision.auctionHints = nil
            local savedItem = C_Item
            C_Item = {
                GetItemInfo = function(id)
                    if id == 2 then
                        return nil
                    end
                    return "Fish", nil, nil, nil, nil, nil, nil, nil, nil, nil, 50
                end,
            }
            world.records = { { id = 1, count = 4 }, { id = 2, count = 1 } }
            world.seconds = 120
            local estimate = Value.estimate(Game)
            C_Item = savedItem
            t:assertEqual(estimate.total, 200)
            t:assertEqual(estimate.perHour, 6000)
            t:assertEqual(estimate.counts.pending, 1)
            t:assertEqual(estimate.meta.problem, "noaddon")
        end)
    end,

    ["with the auction hints, their prices and sentences are used"] = function(t)
        withFishing(function(world)
            WowVision.auctionHints = {
                game = { itemInfo = function() end },
                market = {
                    snapshot = function()
                        return {}
                    end,
                },
                valueOfItem = function(id)
                    return { unit = id * 1000, how = "auction" }
                end,
                priceSentences = function()
                    return { "Fresh prices." }
                end,
            }
            world.records = { { id = 3, count = 2 } }
            world.seconds = 3600
            local savedTime = time
            time = function()
                return 0
            end
            local estimate = Value.estimate(Game)
            time = savedTime
            t:assertEqual(estimate.total, 6000)
            local lines = Value.lines(Game, estimate)
            t:assertTrue(lines[1].text:find("Life on Azeroth Market and vendor prices: 6000c", 1, true) ~= nil)
            t:assertEqual(lines[3].text, "Fresh prices.")
        end)
    end,

    ["no rate before a minute of fishing"] = function(t)
        withFishing(function(world)
            WowVision.auctionHints = nil
            world.records = {}
            world.seconds = 30
            local lines = Value.lines(Game, Value.estimate(Game))
            t:assertEqual(lines[1].text, "Gold per hour will be estimated after a minute of fishing.")
            t:assertEqual(lines[2].text, "Nothing caught yet this session.")
        end)
    end,

    ["Shift+F7 opens the screen, drawn by the real graph engine"] = function(t)
        withFishing(function(world)
            world.open = true
            registered.bindings[1].func()
            t:assertNotNil(world.screen)
            local builder = WowVision.graph.Builder:new()
            world.screen.render(builder, {})
            local rendered = builder:build()
            t:assertTrue(#rendered.order >= 3)
            registered.bindings[1].func()
            t:assertNil(world.screen)
        end)
    end,
})
