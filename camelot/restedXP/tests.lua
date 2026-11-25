-- Headless only (tools/headless-tests.lua loads the RestedXP files, then module.lua against a stand-in window module,
-- and hands over the loader): what is said, the guidance toward the arrow, and the module's keys, command, settings,
-- window and follower.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._restedXPTestHarness
local ns = WowVision.restedXP
local Text, Guidance, Game = ns.Text, ns.Guidance, ns.Game

local module, registered = harness.load({ RXPGuides = true })

local function binding(key)
    for _, info in ipairs(registered.bindings) do
        if info.key == key then
            return info
        end
    end
    return nil
end

-- Runs a test with functions of ns and Game replaced, then puts them back.
local function with(replacements, test)
    local saved = {}
    for target, fields in pairs(replacements) do
        saved[target] = {}
        for key, value in pairs(fields) do
            saved[target][key] = { target[key] }
            target[key] = value
        end
    end
    local ok, err = pcall(test)
    for target, fields in pairs(saved) do
        for key, value in pairs(fields) do
            target[key] = value[1]
        end
    end
    if not ok then
        error(err, 0)
    end
end

-- A stand-in for WowVision's maps: what was asked of it.
local function fakeMaps()
    local maps = { calls = {}, guiding = false }
    function maps:directTo(x, y, name)
        tinsert(self.calls, "direct " .. x .. " " .. y .. " " .. name)
        self.guiding = true
    end
    function maps:goToDestination(destination)
        tinsert(self.calls, "route " .. destination.x .. " " .. destination.y)
        self.guiding = true
        return self.routeFails ~= true
    end
    function maps:isGuiding()
        return self.guiding
    end
    function maps:cancelNavigation()
        self.guiding = false
        tinsert(self.calls, "cancel")
    end
    return maps
end

local function resetGuidance()
    Guidance.following, Guidance.lastPoint = nil, nil
end

testRunner:addSuite("RestedXP", {
    ["without RestedXP there is no module and no key"] = function(t)
        local other, nothing = harness.loadOther({})
        t:assertNil(other)
        t:assertEqual(#nothing.bindings, 0)
        t:assertNotNil(harness.loadOther({ rxpguides = true }))
    end,

    ["the keys are on Shift, Alt and Ctrl+F2, four actions without a key"] = function(t)
        t:assertEqual(#registered.bindings, 10)
        t:assertEqual(binding("restedxp/menu").inputs[1], "SHIFT-F2")
        t:assertEqual(binding("restedxp/guides").inputs[1], "ALT-CTRL-F2")
        t:assertEqual(binding("restedxp/step").inputs[1], "ALT-F2")
        t:assertEqual(binding("restedxp/arrow").inputs[1], "CTRL-F2")
        t:assertEqual(binding("restedxp/beacon").inputs[1], "CTRL-SHIFT-F2")
        t:assertEqual(binding("restedxp/route").inputs[1], "ALT-SHIFT-F2")
        t:assertEqual(#binding("restedxp/skip").inputs, 0)
    end,

    ["the settings default to announcing steps and recalculating"] = function(t)
        t:assertTrue(module.settings.announceSteps)
        t:assertFalse(module.settings.announceDestination)
        t:assertTrue(module.settings.recalculate)
        t:assertFalse(module.settings.ignoreSmallMoves)
    end,

    ["the options page of RestedXP gets a window"] = function(t)
        local window = registered.windows["restedxp-settings"]
        t:assertEqual(window.type, "CustomWindow")
        local shown = false
        with({ [Game] = {
            optionsShown = function()
                return shown
            end,
        } }, function()
            t:assertFalse(window.isOpen())
            shown = true
            t:assertTrue(window.isOpen())
        end)
    end,

    ["the command's words reach the actions in three languages"] = function(t)
        local done = {}
        local function note(name)
            return function(mode)
                tinsert(done, name .. (mode and (" " .. mode) or ""))
            end
        end
        with({
            [ns] = {
                sayStep = note("step"),
                sayArrow = note("arrow"),
                toggleGuidance = note("guide"),
                stopGuidance = note("stop"),
            },
            [ns.Screens] = { toggleMain = note("menu") },
            [Game] = { speak = note("help") },
        }, function()
            local command = registered.commands.rxp
            for _, args in ipairs({ "step", "Étape", "flèche", "signal", "itineraire", "stopp", "", "menu", "what" }) do
                command.func(args)
            end
        end)
        t:assertEqual(
            table.concat(done, ","),
            "step,step,arrow,guide beacon,guide route,stop,menu,menu,help "
                .. "RestedXP: /wv rxp opens the menu, /wv rxp step says the step, /wv rxp arrow says where the arrow points, /wv rxp beacon starts a sound beacon, /wv rxp route a WowVision route, /wv rxp stop ends the guidance."
        )
    end,

    ["the follower looks at the arrow twice a second"] = function(t)
        local looks, now = 0, 10
        local savedTime = GetTime
        GetTime = function()
            return now
        end
        with({ [ns] = {
            follow = function()
                looks = looks + 1
            end,
        } }, function()
            module.nextFollow = nil
            module:followIfDue()
            now = 10.4
            module:followIfDue()
            now = 10.5
            module:followIfDue()
        end)
        GetTime = savedTime
        t:assertEqual(looks, 2)
    end,

    ["display text becomes speech"] = function(t)
        t:assertEqual(Text.plain("|cRXP_FRIENDLY_Innkeeper|r |TInterface\\x:0|t  Gryan::123 "), "Innkeeper Gryan")
        t:assertNil(Text.plain("  "))
        t:assertEqual(Text.yards(1.2), "1 yard")
        t:assertEqual(Text.yards(34.6), "35 yards")
    end,

    ["directions are said as clock positions with the side"] = function(t)
        t:assertEqual(Text.direction(0), "ahead of you")
        t:assertEqual(Text.direction(170), "behind you")
        t:assertEqual(Text.direction(60), "at 2 o'clock, to your right")
        t:assertEqual(Text.direction(-90), "at 9 o'clock, to your left")
        t:assertEqual(Text.relativeDegrees(math.rad(90), 0), -90)
    end,

    ["the arrow and a step are read"] = function(t)
        t:assertEqual(Text.arrow(nil), "No destination in the guide right now.")
        t:assertEqual(Text.arrow({ title = "Camp", degrees = 0, distance = 40 }), "Camp, ahead of you, 40 yards")
        t:assertEqual(Text.arrow({ title = "Camp", otherContinent = true }), "Camp, on another continent")
        t:assertEqual(Text.arrow({}), "Destination unknown.")
        t:assertEqual(Text.step("Title", { { text = "Kill 5", done = true }, { text = "Return" } }), "Title. Kill 5, done. Return")
    end,

    ["a beacon or a route leads to the arrow, its coordinates swapped"] = function(t)
        resetGuidance()
        local maps = fakeMaps()
        local arrow = { title = "Camp", wx = 1, wy = 2, instance = 0 }
        t:assertTrue(Guidance.start(maps, arrow, "beacon"))
        t:assertEqual(maps.calls[1], "direct 2 1 Camp")
        t:assertEqual(Guidance.following, "beacon")
        t:assertTrue(Guidance.start(maps, arrow, "route"))
        t:assertEqual(maps.calls[2], "route 2 1")
        t:assertTrue(Guidance.stop(maps))
        t:assertNil(Guidance.following)
        t:assertFalse(Guidance.stop(maps))
        resetGuidance()
    end,

    ["guidance explains why it cannot start"] = function(t)
        resetGuidance()
        local maps = fakeMaps()
        local _, why = Guidance.start(nil, { wx = 1 }, "beacon")
        t:assertEqual(why, "WowVision's navigation is not available.")
        _, why = Guidance.start(maps, { none = true }, "beacon")
        t:assertEqual(why, "No destination in the guide right now.")
        _, why = Guidance.start(maps, { wx = 1, wy = 1, otherContinent = true }, "beacon")
        t:assertEqual(why, "The destination is on another continent.")
        maps.routeFails = true
        _, why = Guidance.start(maps, { wx = 1, wy = 1 }, "route")
        t:assertEqual(why, "No route found.")
        t:assertNil(Guidance.following)
        resetGuidance()
    end,

    ["the follower guides again only when the arrow really moved"] = function(t)
        resetGuidance()
        local maps = fakeMaps()
        Guidance.start(maps, { wx = 0, wy = 0, instance = 0 }, "beacon")
        t:assertFalse(Guidance.follow(maps, { wx = 0, wy = 0, instance = 0 }))
        t:assertFalse(Guidance.follow(maps, { wx = 5, wy = 0, instance = 0 }, Guidance.smallMove))
        t:assertTrue(Guidance.follow(maps, { wx = 11, wy = 0, instance = 0 }, Guidance.smallMove))
        t:assertTrue(Guidance.follow(maps, { wx = 11, wy = 0, instance = 1 }, Guidance.smallMove))
        t:assertEqual(#maps.calls, 3)
        resetGuidance()
    end,

    ["settings are read from the module, with the defaults beneath"] = function(t)
        local saved = ns.settings
        ns.settings = module.settings
        local before = module.settings.recalculate
        Game.setSetting("recalculate", false)
        t:assertFalse(Game.getSetting("recalculate"))
        module.settings.recalculate = before
        ns.settings = nil
        t:assertTrue(Game.getSetting("announceSteps"))
        ns.settings = saved
    end,
})
