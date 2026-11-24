local testRunner = WowVision.testing.testRunner
local gameDefaults = WowVision.gameDefaults

-- Locale stand-in: every string is its own key.
local L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

-- A game stand-in: console variables, bar toggles and, unless
-- options.noAudioAssist, Audio Assist. options.keys (key -> action) gives it
-- key bindings; options.refuseBind makes setting a key fail.
local function fakeGame(options)
    options = options or {}
    local game = {
        combat = options.combat or false,
        cvars = options.cvars or {},
        toggles = options.toggles,
        formats = options.formats or { Player = 1, Target = 3 },
        spec = options.spec or { Resource1Percent = 0, SayIfTargeted = 1 },
    }
    local api = {
        inCombat = function()
            return game.combat
        end,
        getCVar = function(name)
            return game.cvars[name]
        end,
        setCVar = function(name, value)
            if options.refuseCVar == name then
                error("refused")
            end
            game.cvars[name] = value
        end,
        actionBarToggles = function()
            return game.toggles
        end,
        setActionBarToggles = function(list)
            game.toggles = list
        end,
    }
    if options.keys ~= nil then
        game.keys = options.keys
        api.bindings = {
            keyOf = function(action)
                for key, held in pairs(game.keys) do
                    if held == action then
                        return key
                    end
                end
                return nil
            end,
            actionOf = function(key)
                return game.keys[key]
            end,
            nameOf = function(action)
                return "name of " .. action
            end,
            bind = function(key, action)
                if options.refuseBind then
                    error("refused")
                end
                game.keys[key] = action
                game.saved = (game.saved or 0) + 1
            end,
        }
    end
    if not options.noAudioAssist then
        api.audioAssist = {
            getFormat = function(unit)
                return game.formats[unit]
            end,
            setFormat = function(unit, _, value)
                game.formats[unit] = value
            end,
            getSpec = function(setting)
                return game.spec[setting]
            end,
            setSpec = function(setting, value)
                game.spec[setting] = value
            end,
        }
    end
    return game, api
end

local function allCVars(value)
    local cvars = {}
    for _, cvar in ipairs(gameDefaults.CVARS) do
        cvars[cvar.name] = value
    end
    for _, cvar in ipairs(gameDefaults.AUDIO_ASSIST_CVARS) do
        cvars[cvar.name] = value
    end
    return cvars
end

testRunner:addSuite("GameDefaults", {
    ["in combat nothing is touched"] = function(t)
        local game, api = fakeGame({ combat = true, cvars = allCVars("0") })
        local report = gameDefaults.apply(api, L)
        t:assertTrue(report.refused)
        t:assertEqual(game.cvars.autoLootDefault, "0")
        t:assertNil(game.toggles)
    end,

    ["a fresh game gets every setting"] = function(t)
        local game, api = fakeGame({
            cvars = allCVars("0"),
            toggles = { true, false, false, true },
        })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(game.cvars.autoLootDefault, "1")
        t:assertEqual(game.cvars.nameplateShowOffscreen, "1")
        t:assertEqual(game.cvars.nameplateShowFriendlyNpcs, "1")
        t:assertEqual(game.cvars.CAAEnabled, "1")
        t:assertEqual(game.cvars.CAASayTargetName, "0")
        t:assertEqual(game.cvars.CAAPlayerHealthPercent, "2")
        t:assertEqual(game.cvars.CAATargetHealthPercent, "2")
        t:assertEqual(#game.toggles, 4)
        for _, shown in ipairs(game.toggles) do
            t:assertTrue(shown)
        end
        t:assertEqual(game.formats.Player, 4)
        t:assertEqual(game.formats.Target, 4)
        t:assertEqual(game.spec.Resource1Percent, 2)
        t:assertEqual(game.spec.SayIfTargeted, 2)
        t:assertEqual(#report.failed, 0)
    end,

    ["settings already right are not written again"] = function(t)
        local cvars = allCVars("0")
        for _, cvar in ipairs(gameDefaults.CVARS) do
            cvars[cvar.name] = cvar.value
        end
        for _, cvar in ipairs(gameDefaults.AUDIO_ASSIST_CVARS) do
            cvars[cvar.name] = cvar.value
        end
        local game, api = fakeGame({
            cvars = cvars,
            toggles = { true, true, true, true, true, true, true },
            formats = { Player = 4, Target = 4 },
            spec = { Resource1Percent = 2, SayIfTargeted = 2 },
        })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(#report.changed, 0)
        t:assertEqual(#game.toggles, 7)
        local lines = gameDefaults.reportLines(report, L)
        t:assertEqual(lines[1], "Game settings: nothing to change")
    end,

    ["without Audio Assist only the rest is set"] = function(t)
        local game, api = fakeGame({
            noAudioAssist = true,
            cvars = { autoLootDefault = "0", nameplateShowOffscreen = "0", nameplateShowFriendlyNpcs = "0" },
        })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(game.cvars.autoLootDefault, "1")
        t:assertEqual(game.cvars.nameplateShowOffscreen, "1")
        t:assertEqual(game.cvars.nameplateShowFriendlyNpcs, "1")
        t:assertNil(game.cvars.CAAEnabled)
        t:assertEqual(#report.failed, 0)
    end,

    ["interact key: a free G is given to Interact With Target"] = function(t)
        local game, api = fakeGame({ noAudioAssist = true, keys = {} })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(game.keys.G, "INTERACTTARGET")
        t:assertEqual(game.saved, 1)
        t:assertEqual(report.changed[#report.changed], "name of INTERACTTARGET set to G")
    end,

    ["interact key: G is taken from the game's default, Target Last Hostile, and the report says so"] = function(t)
        local game, api = fakeGame({ noAudioAssist = true, keys = { G = "TARGETLASTHOSTILE" } })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(game.keys.G, "INTERACTTARGET")
        t:assertEqual(
            report.changed[#report.changed],
            "name of INTERACTTARGET set to G, in place of name of TARGETLASTHOSTILE"
        )
    end,

    ["interact key: a G the player gave to something else is left alone and named"] = function(t)
        local game, api = fakeGame({ noAudioAssist = true, keys = { G = "MOVEFORWARD" } })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(game.keys.G, "MOVEFORWARD")
        t:assertNil(game.saved)
        t:assertEqual(report.failed[#report.failed], "name of INTERACTTARGET (G is used by name of MOVEFORWARD)")
    end,

    ["interact key: a key the player already has is kept, on either interact action"] = function(t)
        local game, api = fakeGame({ noAudioAssist = true, keys = { F = "INTERACTTARGET", G = "TARGETLASTHOSTILE" } })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(game.keys.G, "TARGETLASTHOSTILE", "G is not touched")
        t:assertNil(game.saved)
        t:assertEqual(report.unchanged[#report.unchanged], "name of INTERACTTARGET")
        game, api = fakeGame({ noAudioAssist = true, keys = { H = "INTERACTMOUSEOVER" } })
        report = gameDefaults.apply(api, L)
        t:assertNil(game.keys.G, "Interact With Mouseover is an interact key too")
        t:assertEqual(report.unchanged[#report.unchanged], "name of INTERACTTARGET")
    end,

    ["interact key: a refused key is reported, and a game without key functions is skipped"] = function(t)
        local game, api = fakeGame({ noAudioAssist = true, keys = {}, refuseBind = true })
        local report = gameDefaults.apply(api, L)
        t:assertNil(game.keys.G)
        t:assertEqual(report.failed[#report.failed], "name of INTERACTTARGET")
        game, api = fakeGame({ noAudioAssist = true })
        report = gameDefaults.apply(api, L)
        for _, name in ipairs(report.failed) do
            t:assertTrue(name ~= "name of INTERACTTARGET")
        end
        for _, name in ipairs(report.unchanged) do
            t:assertTrue(name ~= "name of INTERACTTARGET")
        end
    end,

    ["interact key: in combat no key is set"] = function(t)
        local game, api = fakeGame({ combat = true, keys = {} })
        gameDefaults.apply(api, L)
        t:assertNil(game.keys.G)
    end,

    ["login: no interact key is said once per session, with where the button is"] = function(t)
        local check = gameDefaults.interactCheck
        check.said = false
        local said = {}
        local options = {
            keyOf = function()
                return nil
            end,
            actionName = "Interact With Target",
            L = L,
            say = function(text)
                tinsert(said, text)
            end,
        }
        t:assertTrue(gameDefaults.checkInteractKey(options))
        t:assertEqual(#said, 1)
        t:assertEqual(
            said[1],
            "The game's action Interact With Target has no key, so you cannot talk to characters or loot from the "
                .. "keyboard. To set it to G: press Shift+F1, open UI, and choose Apply Recommended Game Settings. "
                .. "Or give it a key of your own in the game's key bindings."
        )
        t:assertFalse(gameDefaults.checkInteractKey(options), "the second time in a session")
        t:assertEqual(#said, 1)
        check.said = false
    end,

    ["login: nothing is said with a key, with the setting off, without custom scripts, or when the game cannot be asked"] = function(t)
        local check = gameDefaults.interactCheck
        check.said = false
        local function run(overrides)
            local options = {
                keyOf = function()
                    return nil
                end,
                L = L,
                say = function()
                    error("must not speak")
                end,
            }
            for key, value in pairs(overrides) do
                options[key] = value
            end
            return gameDefaults.checkInteractKey(options)
        end
        t:assertFalse(run({
            keyOf = function(action)
                return action == "INTERACTTARGET" and "G" or nil
            end,
        }))
        t:assertFalse(run({
            keyOf = function(action)
                return action == "INTERACTMOUSEOVER" and "H" or nil
            end,
        }), "Interact With Mouseover counts")
        t:assertFalse(run({ enabled = false }), "the setting is off")
        t:assertFalse(run({ scriptsAllowed = false }), "the keys are dead: that message comes first")
        t:assertFalse(run({
            keyOf = function()
                error("refused")
            end,
        }), "a refused question is no answer")
        t:assertFalse(run({ keyOf = false }), "no key functions")
        t:assertFalse(check.said, "still free to speak later")
    end,

    ["a refused setting is named, the others still go"] = function(t)
        local game, api = fakeGame({ cvars = allCVars("0"), refuseCVar = "CAAEnabled" })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(report.failed[1], "Audio Assist")
        t:assertEqual(game.cvars.autoLootDefault, "1")
        t:assertEqual(game.cvars.CAAPlayerHealthPercent, "2")
    end,
})
