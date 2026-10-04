-- The game's own sounds around text-to-speech, as toggles on the speech
-- module.
--
-- The client plays two sounds around the text it speaks: one separating
-- chat line breaks (between two messages) and an activity sound when a
-- message is spoken while the chat window is hidden. Both are game
-- settings (C_TTSSettings; the /tts playline and /tts playactivity
-- commands toggle them) that default to on, so every fresh character hears
-- the line-break sound between WowVision's announcements.
--
-- The speech module shows one toggle per sound. A toggle IS the game
-- setting: it reads and writes C_TTSSettings and stores nothing of its own,
-- so the /tts commands and the Speech settings screen always agree. On a
-- character's first login with WowVision the line-break sound is turned
-- off once, the way the action bars are unlocked once; after that the
-- player's choice stands.
--
-- Timing: the client loads a character's text-to-speech settings around
-- PLAYER_ENTERING_WORLD (Blizzard's own TextToSpeechFrame waits for that
-- event before reading them). A write at login is accepted and then lost
-- to that load, so the speech modules silence from PLAYER_ENTERING_WORLD,
-- not from onFullEnable.
--
-- Kept free of frames and game globals so it runs in the headless tests;
-- the game is reached only through the accessor pair passed in.
local sounds = {}

-- The two toggles: WowVision setting key and label, Enum.TtsBoolSetting name.
sounds.options = {
    {
        key = "chatLineSound",
        label = "Sound Between Chat Lines",
        option = "PlaySoundSeparatingChatLineBreaks",
    },
    {
        key = "unfocusedActivitySound",
        label = "Activity Sound When Unfocused",
        option = "PlayActivitySoundWhenNotFocused",
    },
}

-- Declares the toggles on a speech module's settings facade, reading and
-- writing the game through game.get(optionName) and
-- game.set(optionName, enabled), plus the hidden per-character flag that
-- records the one-time silencing.
function sounds.addSettings(settings, L, game)
    for _, def in ipairs(sounds.options) do
        settings:add({
            type = "Bool",
            key = def.key,
            label = L[def.label],
            -- No value of its own, the game keeps it. Not persisting also
            -- keeps the database restore from writing a stale copy back
            -- into the game.
            persist = false,
            get = function(obj, key)
                return game.get(def.option)
            end,
            set = function(obj, key, value)
                game.set(def.option, value)
            end,
        })
    end
    settings:add({
        type = "Bool",
        key = "chatLineSoundOff",
        default = false,
        global = false,
        showInUI = false,
    })
end

-- Turns the line-break sound off on a character's first login.
-- state.chatLineSoundOff records that this character was handled.
-- Returns true when the sound was on and is now off.
function sounds.silenceOnce(state, game)
    if state.chatLineSoundOff then
        return false
    end
    local option = sounds.options[1].option
    local enabled = game.get(option)
    if enabled == nil then
        -- Unreadable (no API, an error): try again next login.
        return false
    end
    local changed = false
    if enabled then
        if not game.set(option, false) then
            -- Refused: try again next login.
            return false
        end
        changed = true
    end
    state.chatLineSoundOff = true
    return changed
end

-- Everything a version's speech module needs, in one call: the toggles on
-- its settings and the one-time silencing from PLAYER_ENTERING_WORLD (see
-- Timing above). The module's own onEvent, if it has one, still runs.
-- game defaults to the real C_TTSSettings side.
function sounds.attach(module, settings, L, game)
    game = game or sounds.game
    sounds.addSettings(settings, L, game)
    module:registerEvent("event", "PLAYER_ENTERING_WORLD")
    local previous = module.onEvent
    function module:onEvent(event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            sounds.silenceOnce(self.settings, game)
        end
        return previous(self, event, ...)
    end
end

-- The game side: C_TTSSettings with the option looked up by name, since
-- Enum is a game global. get returns nil and set returns false when the
-- client has no such setting.
local function gameOption(optionName)
    if C_TTSSettings == nil or Enum == nil or Enum.TtsBoolSetting == nil then
        return nil
    end
    return Enum.TtsBoolSetting[optionName]
end

sounds.game = {
    get = function(optionName)
        local option = gameOption(optionName)
        if option == nil then
            return nil
        end
        local ok, enabled = pcall(C_TTSSettings.GetSetting, option)
        if ok then
            return enabled
        end
        return nil
    end,
    set = function(optionName, enabled)
        local option = gameOption(optionName)
        if option == nil then
            return false
        end
        return (pcall(C_TTSSettings.SetSetting, option, enabled))
    end,
}

WowVision.speechSounds = sounds
