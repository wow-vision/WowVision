-- core/audio/channels.lua: the channel list a version gets, the fallback
-- for a saved channel the version does not offer, the selected channel.
local testRunner = WowVision.testing.testRunner

-- Loads channels.lua with the given version consts and slider names in
-- place, puts everything back afterwards (also on failure) and returns the
-- WowVision.audio it built.
local SLIDER_NAMES = {
    MASTER_VOLUME = "Master Volume",
    FX_VOLUME = "Sound Effects",
    MUSIC_VOLUME = "Music",
    AMBIENCE_VOLUME = "Ambience",
    DIALOG_VOLUME = "Dialog",
    GAMEPLAY_SFX_VOLUME = "Gameplay Sound Effects",
}
local function loadChannels(consts)
    local saved = { audio = WowVision.audio, consts = WowVision.consts, globals = {} }
    for name, label in pairs(SLIDER_NAMES) do
        saved.globals[name] = _G[name]
        _G[name] = label
    end
    WowVision.audio = {}
    WowVision.consts = consts
    local ok, err = pcall(function()
        assert(loadfile("core/audio/channels.lua"))("WowVision", {})
    end)
    local audio = WowVision.audio
    WowVision.audio, WowVision.consts = saved.audio, saved.consts
    for name, value in pairs(saved.globals) do
        _G[name] = value
    end
    if not ok then
        error(err)
    end
    return audio
end

-- The channel functions read WowVision.audio when called: runs fn with the
-- built one in place, the real one back afterwards (also on failure).
local function withAudio(audio, fn)
    local real = WowVision.audio
    WowVision.audio = audio
    local ok, err = pcall(fn)
    WowVision.audio = real
    if not ok then
        error(err)
    end
end

-- consts as retail/setup.lua declares them (Retail and WoW: Forever)
local MAINLINE = {
    SOUND_CHANNELS = { { label = "Gameplay Sound Effects", value = "Gameplay SFX" } },
}

local function values(channels)
    local out = {}
    for _, channel in ipairs(channels) do
        tinsert(out, channel.value)
    end
    return table.concat(out, ",")
end

testRunner:addSuite("SoundChannels", {
    ["classic clients: the five sliders, Sound Effects by default"] = function(t)
        local audio = loadChannels({ UI_DELAY = 0 })
        t:assertEqual(values(audio.channels), "Master,SFX,Music,Ambience,Dialog")
        t:assertEqual(audio.channels[1].label, "Master Volume")
        t:assertEqual(audio.defaultChannel, "SFX")
    end,

    ["Retail and Forever: Gameplay SFX added, Sound Effects still the default"] = function(t)
        local audio = loadChannels(MAINLINE)
        t:assertEqual(values(audio.channels), "Master,SFX,Music,Ambience,Dialog,Gameplay SFX")
        t:assertEqual(audio.defaultChannel, "SFX")
    end,

    ["the selected channel, else the default"] = function(t)
        local audio = loadChannels(MAINLINE)
        withAudio(audio, function()
            t:assertEqual(audio.channel(), "SFX")
            audio.selectedChannel = "Music"
            t:assertEqual(audio.channel(), "Music")
        end)
    end,

    ["a saved channel the version does not offer reads as the default"] = function(t)
        local audio = loadChannels({ UI_DELAY = 0 })
        local Holder = WowVision.Class("SoundChannelTestHolder")
        Holder:addFields({
            {
                type = "Choice",
                key = "soundChannel",
                default = audio.defaultChannel,
                choices = audio.channels,
                validate = audio.validateChannel,
                persist = true,
            },
        })
        withAudio(audio, function()
            local stale = Holder:new()
            stale:setDB({ char = { soundChannel = "Talking Head" } })
            t:assertEqual(stale.soundChannel, "SFX")
            local kept = Holder:new()
            kept:setDB({ char = { soundChannel = "Music" } })
            t:assertEqual(kept.soundChannel, "Music")
        end)
    end,
})
