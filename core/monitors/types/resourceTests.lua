-- Headless tests for the Resource monitor (tools/headless-tests.lua loads
-- this with stand-ins for the game's resource functions).
local steps = WowVision.resourceSteps

WowVision.testing.testRunner:addSuite("ResourceSteps", {
    ["counted resources step on every count, bars down from 100"] = function(t)
        t:assertEqual(table.concat(steps.build(true, 5), ","), "0,1,2,3,4,5")
        t:assertEqual(table.concat(steps.build(false, nil, 40), ","), "20,60,100")
        t:assertEqual(table.concat(steps.build(false, nil, 30), ","), "10,40,70,100")
        t:assertEqual(table.concat(steps.build(false, nil, 50), ","), "50,100")
        t:assertEqual(#steps.build(false, nil, 10), 10)
    end,

    ["bars cross thresholds the way Blizzard announces them"] = function(t)
        local tens = steps.build(false, nil, 10)
        t:assertEqual(steps.crossed(false, 75, 65, tens), 70)
        t:assertEqual(steps.crossed(false, 75, 45, tens), 50)
        t:assertEqual(steps.crossed(false, 43, 57, tens), 50)
        t:assertEqual(steps.crossed(false, 75, 70, tens), 70)
        t:assertNil(steps.crossed(false, 65, 70, tens))
        t:assertEqual(steps.crossed(false, 69, 71, tens), 70)
        t:assertEqual(steps.crossed(false, 85, 100, tens), 100)
        t:assertEqual(steps.crossed(false, 95, 100, tens), 100)
        t:assertNil(steps.crossed(false, 100, 99, tens))
        t:assertEqual(steps.crossed(false, 100, 90, tens), 90)
        t:assertEqual(steps.crossed(false, 15, 0, tens), 10)
        t:assertNil(steps.crossed(false, 0, 5, tens))
        t:assertNil(steps.crossed(false, nil, 50, tens))
        t:assertEqual(steps.percent(1, 1000), 1)
        t:assertEqual(steps.percent(0, 1000), 0)
    end,

    ["counted resources fire the step of the new count"] = function(t)
        local values = steps.build(true, 5)
        t:assertEqual(steps.crossed(true, 2, 3, values), 3)
        t:assertEqual(steps.crossed(true, 1, 3, values), 3)
        t:assertEqual(steps.crossed(true, 5, 0, values), 0)
        t:assertNil(steps.crossed(true, 3, 3, values))
        t:assertNil(steps.crossed(true, 3, 7, values))
    end,

    ["speech follows Blizzard's six formats"] = function(t)
        t:assertEqual(steps.text("full", false, "Mana", 40), "Mana 40%")
        t:assertEqual(steps.text("noPercent", false, "Mana", 40), "Mana 40")
        t:assertEqual(steps.text("tenths", false, "Mana", 40), "Mana 4")
        t:assertEqual(steps.text("noName", false, "Mana", 40), "40%")
        t:assertEqual(steps.text("number", false, "Mana", 40), "40")
        t:assertEqual(steps.text("numberTenths", false, "Mana", 40), "4")
        t:assertEqual(steps.text("full", true, "combo points", 3), "combo points 3")
        t:assertEqual(steps.text("numberTenths", true, "combo points", 3), "3")
    end,

    ["the main resource readout and its percent curve"] = function(t)
        t:assertEqual(steps.readoutText("energy", false, 80), "energy 80%")
        t:assertEqual(steps.readoutText("combo points", true, 3), "combo points 3")
        -- evaluate the step curve the way the game does: last point at or below
        local points = steps.percentCurvePoints()
        local function at(x)
            local result = nil
            for _, point in ipairs(points) do
                if point[1] <= x then
                    result = point[2]
                end
            end
            return result
        end
        t:assertEqual(#points, 101)
        t:assertEqual(at(0), 0)
        t:assertEqual(at(0.001), 1)
        t:assertEqual(at(0.40), 40)
        t:assertEqual(at(0.401), 41)
        t:assertEqual(at(0.995), 100)
        t:assertEqual(at(1), 100)
    end,

    ["sounds take the series, notes when it is too short, a spend sound for 0"] = function(t)
        local five = steps.sounds(true, steps.build(true, 5), "glass")
        t:assertEqual(five[1], "Sound/WowVision/alerts/glass1.mp3")
        t:assertEqual(five[5], "Sound/WowVision/alerts/glass5.mp3")
        t:assertEqual(five[0], steps.SPEND_SOUND)
        local seven = steps.sounds(true, steps.build(true, 7), "glass")
        t:assertEqual(seven[1], "Sound/WowVision/notes/synth_19_f3.mp3")
        t:assertEqual(seven[7], "Sound/WowVision/notes/synth_37_c5.mp3")
        local fifths = steps.sounds(false, steps.build(false, nil, 20), "brass")
        t:assertEqual(fifths[20], "Sound/WowVision/alerts/brass1.mp3")
        t:assertEqual(fifths[100], "Sound/WowVision/alerts/brass5.mp3")
        t:assertNil(fifths[0])
        local tens = steps.sounds(false, steps.build(false, nil, 10), "glass")
        t:assertEqual(tens[10], "Sound/WowVision/notes/synth_19_f3.mp3")
        t:assertEqual(tens[100], "Sound/WowVision/notes/synth_46_a5.mp3")
    end,
})

-- The game's side: the player's resources, the clock, speech and sound.
local game = { power = {}, maximum = {}, now = 0, spoken = {}, played = {}, secret = false }

local function withGame(body)
    local saved = {
        UnitPower = UnitPower,
        UnitPowerMax = UnitPowerMax,
        GetTime = GetTime,
        C_VoiceChat = C_VoiceChat,
        issecretvalue = issecretvalue,
        play = WowVision.play,
        print = print,
    }
    game.power, game.maximum, game.now, game.spoken, game.played, game.secret = {}, {}, 0, {}, {}, false
    game.printed = {}
    UnitPower = function(_, id)
        if game.secret then
            return "SECRET"
        end
        return game.power[id] or 0
    end
    UnitPowerMax = function(_, id)
        return game.maximum[id] or 0
    end
    GetTime = function()
        return game.now
    end
    C_VoiceChat = {
        SpeakText = function(voice, text, rate, volume)
            -- without the cache-buster's no-break spaces
            tinsert(game.spoken, (text:gsub("\194\160", "")))
            game.lastRate, game.lastVolume = rate, volume
        end,
    }
    issecretvalue = function(value)
        return value == "SECRET"
    end
    WowVision.play = function(_, path)
        tinsert(game.played, path)
    end
    print = function(text)
        tinsert(game.printed, text)
    end
    local ok, err = pcall(body)
    UnitPower, UnitPowerMax, GetTime, C_VoiceChat = saved.UnitPower, saved.UnitPowerMax, saved.GetTime, saved.C_VoiceChat
    issecretvalue, WowVision.play, print = saved.issecretvalue, saved.play, saved.print
    if not ok then
        error(err, 0)
    end
end

local COMBO = 4
local MANA = 0

-- A monitors list bound to a store, like the module's.
local function boundList(db)
    local container = { monitors = {} }
    local field = WowVision.classes.newField({
        type = "ComponentArray",
        key = "monitors",
        persist = true,
        factory = function(config)
            return WowVision.monitors.registry:createTemporaryComponent(config)
        end,
        getTypeKey = function(instance)
            return (instance.class.name:gsub("Monitor$", ""))
        end,
    })
    field:setDB(container, { global = db })
    return container, field
end

WowVision.testing.testRunner:addSuite("ResourceMonitor", {
    ["combo points build their steps and play glass sounds per point"] = function(t)
        withGame(function()
            game.maximum[COMBO] = 5
            local db = { monitors = { _type = "array" } }
            local container, field = boundList(db)
            field:addElement(container, { type = "Resource", powerType = "combopoints", speechOn = false })
            local monitor = container.monitors[1]
            t:assertEqual(monitor:getLabel(), "Resource: combo points")
            monitor:update()
            t:assertEqual(#monitor.rules, 6)
            t:assertEqual(monitor.rules[1]:getLabel(), "0")
            t:assertEqual(#game.played, 0)
            t:assertEqual(#monitor.class:getField("rules"):getAvailableTypes(), 0)

            -- The resource list: only what the player has, plus the pick
            game.maximum[MANA] = 100
            local listed = {}
            for _, choice in ipairs(monitor.class:getField("powerType"):getChoices(monitor)) do
                tinsert(listed, choice.value)
            end
            t:assertEqual(table.concat(listed, ","), "mana,combopoints")
            game.maximum[MANA] = nil
            listed = {}
            for _, choice in ipairs(monitor.class:getField("powerType"):getChoices(nil)) do
                tinsert(listed, choice.value)
            end
            t:assertEqual(table.concat(listed, ","), "combopoints")

            -- What the game hides (mana on Retail and Forever) is left out
            game.maximum[MANA] = 100
            local savedSecrets = C_Secrets
            C_Secrets = {
                ShouldUnitPowerBeSecret = function(_, id)
                    return id == MANA
                end,
            }
            listed = {}
            for _, choice in ipairs(monitor.class:getField("powerType"):getChoices(nil)) do
                tinsert(listed, choice.value)
            end
            C_Secrets = savedSecrets
            game.maximum[MANA] = nil
            t:assertEqual(table.concat(listed, ","), "combopoints")

            -- The monitor's menu: its settings, then one alert button per
            -- step that opens the step's alert ("1": Enabled, Sound, TTS)
            local savedGraph = WowVision.graph
            local items, pushed, rendered = {}, nil, nil
            local stepItems = {}
            local screenBuilder = {
                pushContext = function() end,
                popContext = function() end,
                addItem = function(_, id, vtable)
                    tinsert(stepItems, vtable)
                end,
            }
            WowVision.graph = {
                ControlId = {
                    structural = function(key)
                        return key
                    end,
                    forObject = function(object)
                        return object
                    end,
                },
                nodes = {
                    button = function(vtable)
                        return vtable
                    end,
                },
                settings = {
                    controlFor = function(fieldDef)
                        return { label = fieldDef.key }
                    end,
                    pushScreen = function(key, render)
                        pushed = key
                        render(screenBuilder)
                    end,
                    renderInto = function(_, set)
                        rendered = set
                    end,
                },
            }
            local builder = {
                addItem = function(_, id, vtable)
                    tinsert(items, vtable)
                end,
            }
            monitor:renderGraphSettings(builder)
            local labels = {}
            for _, item in ipairs(items) do
                tinsert(labels, type(item.label) == "function" and item.label() or item.label)
            end
            local text = table.concat(labels, ",")
            t:assertNil(text:find("rules", 1, true), "no rule list")
            t:assertNil(text:find("builtFor", 1, true))
            t:assertEqual(labels[#labels], "Steps (6)")
            items[#items].onActivate()
            labels = {}
            for _, item in ipairs(stepItems) do
                tinsert(labels, item.label)
            end
            t:assertEqual(table.concat(labels, ","), "0,1,2,3,4,5")
            stepItems[2].onActivate()
            WowVision.graph = savedGraph
            t:assertNotNil(pushed)
            t:assertEqual(rendered, monitor.rules[2]:getAlert().parameters)
            t:assertEqual(rendered.label, "1")
            game.power[COMBO] = 1
            monitor:update()
            t:assertEqual(game.played[1], "Sound/WowVision/alerts/glass1.mp3")
            game.power[COMBO] = 3
            monitor:update()
            t:assertEqual(game.played[2], "Sound/WowVision/alerts/glass3.mp3")
            game.power[COMBO] = 0
            monitor:update()
            t:assertEqual(game.played[3], steps.SPEND_SOUND)
            t:assertEqual(#game.spoken, 0)

            -- Stored: a fresh list restores the steps and does not rebuild
            t:assertEqual(#db.monitors[1].rules, 6)
            local again = boundList(db)
            local restored = again.monitors[1]
            t:assertEqual(#restored.rules, 6)
            t:assertEqual(restored.builtFor, monitor.builtFor)
            restored.rules[3]:getAlert().outputs[1].enabled = false
            restored:update()
            t:assertEqual(#restored.rules, 6)
            game.power[COMBO] = 2
            restored:update()
            t:assertEqual(#game.played, 3, "the switched-off step stays quiet")

            -- A talent adds a point: the step is added, the others stay
            game.maximum[COMBO] = 6
            restored:update()
            t:assertEqual(#restored.rules, 7)
            t:assertFalse(restored.rules[3]:getAlert().outputs[1].enabled)
        end)
    end,

    ["mana speaks Blizzard's steps in the monitor's voice"] = function(t)
        withGame(function()
            game.maximum[MANA], game.power[MANA] = 1000, 1000
            local db = { monitors = { _type = "array" } }
            local container, field = boundList(db)
            field:addElement(container, { type = "Resource", powerType = "mana", stepSize = 10, soundOn = false, speechVolume = 60 })
            local monitor = container.monitors[1]
            monitor:update()
            t:assertEqual(#monitor.rules, 10)
            game.power[MANA] = 650
            monitor:update()
            t:assertEqual(game.spoken[1], "mana 70")
            t:assertEqual(game.lastVolume, 60)
            t:assertEqual(#game.played, 0)
            -- A step switched off in its own alert stays silent
            for _, rule in ipairs(monitor.rules) do
                if rule.value == 60 then
                    rule:getAlert().outputs[2].enabled = false
                end
            end
            game.power[MANA] = 550
            monitor:update()
            t:assertEqual(#game.spoken, 1)
            game.power[MANA] = 450
            monitor:update()
            t:assertEqual(game.spoken[2], "mana 50")

            -- A new step size builds the steps anew
            monitor.stepSize = 50
            monitor:update()
            t:assertEqual(#monitor.rules, 2)
            t:assertEqual(#db.monitors[1].rules, 2)
        end)
    end,

    ["a minimum time between messages holds the newest one back"] = function(t)
        withGame(function()
            game.maximum[MANA], game.power[MANA] = 100, 100
            local monitor = WowVision.monitors:create("Resource", { powerType = "mana", stepSize = 10, soundOn = false, speechGap = 2 })
            monitor:update()
            game.power[MANA] = 85
            monitor:update()
            game.now = 0.5
            game.power[MANA] = 75
            monitor:update()
            game.now = 1
            game.power[MANA] = 65
            monitor:update()
            t:assertEqual(#game.spoken, 1)
            game.now = 2.1
            monitor:update()
            t:assertEqual(#game.spoken, 2)
            t:assertEqual(game.spoken[2], "mana 70")
        end)
    end,

    ["a hidden resource stays silent and the chat notes each turn"] = function(t)
        withGame(function()
            game.maximum[COMBO] = 5
            local container, field = boundList({ monitors = { _type = "array" } })
            field:addElement(container, { type = "Resource", powerType = "combopoints" })
            local monitor = container.monitors[1]
            monitor:update()
            t:assertEqual(#game.printed, 0)
            game.secret = true
            monitor:update()
            monitor:update()
            t:assertEqual(#game.printed, 1)
            t:assertEqual(game.printed[1], "WowVision resource: combopoints hidden (current, world, out of combat)")
            t:assertEqual(#game.played, 0)
            game.secret = false
            game.power[COMBO] = 2
            monitor:update()
            t:assertEqual(game.printed[2], "WowVision resource: combopoints readable again")
            t:assertEqual(#game.played, 0, "the first read after hiding settles")
            game.power[COMBO] = 3
            monitor:update()
            t:assertEqual(#game.played, 1)
        end)
    end,
})
