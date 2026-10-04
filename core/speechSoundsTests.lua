local testRunner = WowVision.testing.testRunner
local sounds = WowVision.speechSounds

local LINE = "PlaySoundSeparatingChatLineBreaks"
local ACTIVITY = "PlayActivitySoundWhenNotFocused"

-- A game standing in for C_TTSSettings: both sounds on, like a fresh
-- client, every write counted; refuse makes writes fail.
local function fakeGame(refuse)
    local store = { values = { [LINE] = true, [ACTIVITY] = true }, writes = 0 }
    local game = {
        get = function(option)
            return store.values[option]
        end,
        set = function(option, enabled)
            if refuse then
                return false
            end
            store.values[option] = enabled
            store.writes = store.writes + 1
            return true
        end,
    }
    return store, game
end

-- module:hasSettings() on a real settings class: the facade's add rule
-- (persisted unless the def says persist = false) replicated, since
-- Module.lua itself is WoW-bound.
local function settingsFacade()
    local settingsClass = WowVision.Class("Settings:speechSoundsTest")
    local facade = { obj = settingsClass:new() }
    function facade:add(def)
        if def.persist == nil then
            def.persist = true
        end
        def.setting = true
        settingsClass:addFields({ def })
        return settingsClass:getField(def.key)
    end
    function facade:field(key)
        return settingsClass:getField(key)
    end
    return facade
end

local function untranslated()
    return setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    })
end

testRunner:addSuite("Speech sounds", {
    ["a fresh character gets the line-break sound turned off once"] = function(t)
        local state = { chatLineSoundOff = false }
        local store, game = fakeGame()
        t:assertTrue(sounds.silenceOnce(state, game))
        t:assertEqual(store.values[LINE], false)
        t:assertEqual(store.values[ACTIVITY], true, "the activity sound is left alone")
        t:assertEqual(store.writes, 1)
        t:assertTrue(state.chatLineSoundOff)
    end,

    ["a sound that is already off is not written and still counts as handled"] = function(t)
        local state = { chatLineSoundOff = false }
        local store, game = fakeGame()
        store.values[LINE] = false
        t:assertFalse(sounds.silenceOnce(state, game))
        t:assertEqual(store.writes, 0)
        t:assertTrue(state.chatLineSoundOff)
    end,

    ["a character that was handled keeps the sound the player chose"] = function(t)
        local state = { chatLineSoundOff = true }
        local store, game = fakeGame()
        t:assertFalse(sounds.silenceOnce(state, game))
        t:assertEqual(store.values[LINE], true)
        t:assertEqual(store.writes, 0)
    end,

    ["an unreadable setting is tried again next login"] = function(t)
        local state = { chatLineSoundOff = false }
        local store, game = fakeGame()
        store.values[LINE] = nil
        t:assertFalse(sounds.silenceOnce(state, game))
        t:assertEqual(store.writes, 0)
        t:assertFalse(state.chatLineSoundOff)
    end,

    ["a refused write is tried again next login"] = function(t)
        local state = { chatLineSoundOff = false }
        local store, game = fakeGame(true)
        t:assertFalse(sounds.silenceOnce(state, game))
        t:assertEqual(store.values[LINE], true)
        t:assertFalse(state.chatLineSoundOff)
    end,

    ["the toggles read and write the game setting and store nothing"] = function(t)
        local facade = settingsFacade()
        local store, game = fakeGame()
        sounds.addSettings(facade, untranslated(), game)
        local settings = facade.obj
        local line = facade:field("chatLineSound")
        t:assertEqual(line.typeKey, "Bool")
        t:assertEqual(line.label, "Sound Between Chat Lines")
        t:assertFalse(line.persist, "the game keeps the value")
        t:assertFalse(facade:field("unfocusedActivitySound").persist)
        t:assertEqual(settings.chatLineSound, true)
        store.values[LINE] = false
        t:assertEqual(settings.chatLineSound, false, "reads are live")
        settings.unfocusedActivitySound = false
        t:assertEqual(store.values[ACTIVITY], false)
        t:assertEqual(store.writes, 1)
    end,

    ["a database restore leaves the game setting alone"] = function(t)
        local facade = settingsFacade()
        local store, game = fakeGame()
        sounds.addSettings(facade, untranslated(), game)
        local charNode = { chatLineSound = false, chatLineSoundOff = true }
        local globalNode = {}
        facade.obj:setDB({ char = charNode, global = globalNode })
        t:assertEqual(store.writes, 0, "a stale stored copy is not written back")
        t:assertEqual(store.values[LINE], true)
        t:assertTrue(facade.obj.chatLineSoundOff, "the flag itself is restored")
        facade.obj.unfocusedActivitySound = false
        t:assertEqual(store.values[ACTIVITY], false)
        t:assertNil(charNode.unfocusedActivitySound, "nothing is stored")
        t:assertNil(globalNode.unfocusedActivitySound)
    end,

    ["the silenced flag is a hidden per-character setting"] = function(t)
        local facade = settingsFacade()
        local _, game = fakeGame()
        sounds.addSettings(facade, untranslated(), game)
        local flag = facade:field("chatLineSoundOff")
        t:assertNotNil(flag)
        t:assertEqual(flag.default, false)
        t:assertEqual(flag.global, false)
        t:assertEqual(flag.showInUI, false)
        t:assertTrue(flag.persist)
    end,

    ["attach silences from entering the world and keeps the module's own onEvent"] = function(t)
        local facade = settingsFacade()
        local store, game = fakeGame()
        local heard = {}
        local module = { registered = {}, settings = facade.obj }
        function module:registerEvent(eventType, event)
            table.insert(self.registered, eventType .. ":" .. event)
        end
        function module:onEvent(event)
            table.insert(heard, event)
        end
        sounds.attach(module, facade, untranslated(), game)
        t:assertEqual(module.registered[1], "event:PLAYER_ENTERING_WORLD")
        t:assertNotNil(facade:field("chatLineSound"))
        module:onEvent("PLAYER_LOGIN")
        t:assertEqual(store.values[LINE], true, "only entering the world silences")
        module:onEvent("PLAYER_ENTERING_WORLD")
        t:assertEqual(store.values[LINE], false)
        t:assertTrue(facade.obj.chatLineSoundOff)
        t:assertEqual(#heard, 2, "the module's own handler saw both events")
    end,

    ["the game accessors are harmless without the game API"] = function(t)
        t:assertNil(C_TTSSettings)
        t:assertNil(sounds.game.get(LINE))
        t:assertFalse(sounds.game.set(LINE, false))
    end,
})
