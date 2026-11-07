local testRunner = WowVision.testing.testRunner
local gameDefaults = WowVision.gameDefaults

-- Locale stand-in: every string is its own key.
local L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

-- A game stand-in: console variables, bindings, bar toggles and, unless
-- options.noAudioAssist, Audio Assist.
local function fakeGame(options)
    options = options or {}
    local game = {
        combat = options.combat or false,
        cvars = options.cvars or {},
        bindings = options.bindings or {},
        toggles = options.toggles,
        formats = options.formats or { Player = 1, Target = 3 },
        spec = options.spec or { Resource1Percent = 0, SayIfTargeted = 1 },
        saves = 0,
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
        bindingAction = function(key)
            return game.bindings[key] or ""
        end,
        setBinding = function(key, action)
            game.bindings[key] = action
            return true
        end,
        saveBindings = function()
            game.saves = game.saves + 1
        end,
        actionLabel = function(action)
            return action
        end,
        keyLabel = function(key)
            return key
        end,
        actionBarToggles = function()
            return game.toggles
        end,
        setActionBarToggles = function(list)
            game.toggles = list
        end,
    }
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
    local cvars = { autoLootDefault = value }
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
        t:assertEqual(game.saves, 0)
    end,

    ["a fresh game gets every setting"] = function(t)
        local game, api = fakeGame({
            cvars = allCVars("0"),
            bindings = { F = "ASSISTTARGET", B = "TOGGLEBACKPACK", ["SHIFT-B"] = "OPENALLBAGS" },
            toggles = { true, false, false, true },
        })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(game.cvars.autoLootDefault, "1")
        t:assertEqual(game.cvars.CAAEnabled, "1")
        t:assertEqual(game.cvars.CAASayTargetName, "0")
        t:assertEqual(game.cvars.CAAPlayerHealthPercent, "2")
        t:assertEqual(game.cvars.CAATargetHealthPercent, "2")
        t:assertEqual(game.bindings.F, "FOLLOWTARGET")
        t:assertEqual(game.bindings.NUMPAD0, "FOLLOWTARGET")
        t:assertEqual(game.bindings.R, "ASSISTTARGET")
        t:assertEqual(game.bindings.NUMPADDECIMAL, "ASSISTTARGET")
        t:assertEqual(game.bindings.B, "OPENALLBAGS")
        t:assertEqual(game.bindings["SHIFT-B"], "TOGGLEBACKPACK")
        t:assertEqual(game.bindings.G, "INTERACTTARGET")
        t:assertEqual(game.bindings.H, "TARGETLASTTARGET")
        t:assertEqual(game.saves, 1)
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

    ["a key names what it did before"] = function(t)
        local _, api = fakeGame({ bindings = { F = "ASSISTTARGET" } })
        local report = gameDefaults.apply(api, L)
        local found = false
        for _, line in ipairs(report.changed) do
            if line == "F: FOLLOWTARGET, before ASSISTTARGET" then
                found = true
            end
        end
        t:assertTrue(found)
    end,

    ["settings already right are not written again"] = function(t)
        local bindings = {}
        for _, binding in ipairs(gameDefaults.BINDINGS) do
            bindings[binding.key] = binding.action
        end
        local cvars = allCVars("0")
        cvars.autoLootDefault = "1"
        for _, cvar in ipairs(gameDefaults.AUDIO_ASSIST_CVARS) do
            cvars[cvar.name] = cvar.value
        end
        local game, api = fakeGame({
            cvars = cvars,
            bindings = bindings,
            toggles = { true, true, true, true, true, true, true },
            formats = { Player = 4, Target = 4 },
            spec = { Resource1Percent = 2, SayIfTargeted = 2 },
        })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(#report.changed, 0)
        t:assertEqual(game.saves, 0)
        local lines = gameDefaults.reportLines(report, L)
        t:assertEqual(lines[1], "Game settings: nothing to change")
    end,

    ["without Audio Assist only the rest is set"] = function(t)
        local game, api = fakeGame({ noAudioAssist = true, cvars = { autoLootDefault = "0" } })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(game.cvars.autoLootDefault, "1")
        t:assertNil(game.cvars.CAAEnabled)
        t:assertEqual(#report.failed, 0)
    end,

    ["a refused setting is named, the others still go"] = function(t)
        local game, api = fakeGame({ cvars = allCVars("0"), refuseCVar = "CAAEnabled" })
        local report = gameDefaults.apply(api, L)
        t:assertEqual(report.failed[1], "Audio Assist")
        t:assertEqual(game.cvars.autoLootDefault, "1")
        t:assertEqual(game.cvars.CAAPlayerHealthPercent, "2")
    end,
})
