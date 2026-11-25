-- The chat voice on its own channel (retail/speech.lua): the module loads in a sandbox with a stand-in engine and
-- clock, and the chat alerts' text-to-speech output (core/alerts/outputs.lua) hands its lines to it.
local testRunner = WowVision.testing.testRunner

local function loadIn(path, env)
    if setfenv ~= nil then
        local chunk = assert(loadfile(path))
        setfenv(chunk, env)
        return chunk
    end
    return assert(loadfile(path, "t", env))
end

local SECRET = setmetatable({}, {
    __concat = function()
        return "(hidden)"
    end,
    __len = function()
        error("a hidden text was measured")
    end,
})

-- The speech module over a stand-in engine: spoken lists what reached the engine, stops counts its stops.
local function loadSpeech()
    local world = { now = 100, spoken = {}, stops = 0, noted = 0, bindings = {}, said = {} }
    local module = { L = setmetatable({}, { __index = function(_, key) return key end }) }
    function module:setLabel() end
    function module:setVital() end
    function module:registerBinding(info)
        tinsert(world.bindings, info)
    end
    local defaults = {}
    local onChange = {}
    function module:hasSettings()
        return {
            add = function(_, def)
                defaults[def.key] = def
                local subscribe = function(_, _, handler)
                    onChange[def.key] = handler
                end
                return { events = { valueChange = { subscribe = subscribe } } }
            end,
        }
    end
    local frame = {}
    function frame:SetScript(_, handler)
        world.onEvent = handler
    end
    function frame:RegisterEvent() end
    local env = setmetatable({
        WowVision = {
            base = {
                createModule = function()
                    return module
                end,
            },
            speak = function(_, text)
                tinsert(world.said, text)
            end,
            secrets = {
                isSecret = function(value)
                    return value == SECRET
                end,
            },
            speechInterrupt = {
                handOver = function(text)
                    return text
                end,
                noteStop = function()
                    world.noted = world.noted + 1
                end,
            },
            ttsCacheBust = {
                bust = function(text)
                    if text == SECRET then
                        return text
                    end
                    return text .. "~"
                end,
                bustForeign = function(text)
                    return text
                end,
            },
            speechSounds = { attach = function() end },
            speechTags = WowVision.speechTags,
        },
        C_VoiceChat = {
            SpeakText = function(voice, text, rate, volume, overlap)
                tinsert(world.spoken, { voice = voice, text = text, rate = rate, volume = volume, overlap = overlap })
            end,
            StopSpeakingText = function()
                world.stops = world.stops + 1
            end,
        },
        CreateFrame = function()
            return frame
        end,
        GetTime = function()
            return world.now
        end,
        tinsert = table.insert,
        tremove = table.remove,
    }, { __index = _G })
    loadIn("retail/speech.lua", env)("WowVision", {})
    local settings = {}
    for key, def in pairs(defaults) do
        settings[key] = def.default
    end
    settings.voiceID, settings.speechRate, settings.speechVolume = 0, 2, 80
    module.settings = settings
    module:createFrame()
    return module, world, defaults, onChange
end

local function started(world, id)
    world.onEvent(nil, "VOICE_CHAT_TTS_PLAYBACK_STARTED", 1, id)
end

local function finished(world, id)
    world.onEvent(nil, "VOICE_CHAT_TTS_PLAYBACK_FINISHED", 1, id)
end

testRunner:addSuite("SpeechAside", {
    ["the channel is off by default, protection on, rate and pitch unchanged"] = function(t)
        local _, _, defaults = loadSpeech()
        t:assertFalse(defaults.chatChannel.default)
        t:assertTrue(defaults.chatProtect.default)
        t:assertEqual(defaults.chatRateOffset.default, 0)
        t:assertEqual(defaults.chatPitch.default, 0)
    end,

    ["a line is taken only with the channel on and a voice of its own"] = function(t)
        local speech, world = loadSpeech()
        t:assertFalse(speech:speakAside("hello", 1))
        speech.settings.chatChannel = true
        t:assertFalse(speech:speakAside("hello", nil))
        t:assertFalse(speech:speakAside("hello", 0))
        t:assertEqual(#world.spoken, 0)
        t:assertTrue(speech:speakAside("hello", 1))
        local line = world.spoken[1]
        t:assertEqual(line.voice, 1)
        t:assertEqual(line.text, "hello~")
        t:assertEqual(line.rate, 2)
        t:assertEqual(line.volume, 80)
        t:assertFalse(line.overlap)
    end,

    ["the rate difference is added and kept in the engine's range, the volume too"] = function(t)
        local speech, world = loadSpeech()
        speech.settings.chatChannel = true
        speech.settings.chatRateOffset = 3
        speech.settings.speechVolume = 120
        speech:speakAside("a", 1)
        speech.settings.chatRateOffset = 20
        speech:speakAside("a", 1)
        speech.settings.chatRateOffset = -20
        speech.settings.speechVolume = -5
        speech:speakAside("a", 1)
        t:assertEqual(world.spoken[1].rate, 5)
        t:assertEqual(world.spoken[1].volume, 100)
        t:assertEqual(world.spoken[2].rate, 10)
        t:assertEqual(world.spoken[3].rate, -10)
        t:assertEqual(world.spoken[3].volume, 0)
    end,

    ["a pitch wraps the escaped words in a tag, never a hidden text"] = function(t)
        local speech, world = loadSpeech()
        speech.settings.chatChannel = true
        speech.settings.chatPitch = -3
        speech:speakAside("a <b> & c", 1)
        t:assertEqual(world.spoken[1].text, '<pitch absmiddle="-3">a &lt;b&gt; &amp; c</pitch>~')
        speech:speakAside(SECRET, 1)
        t:assertEqual(world.spoken[2].text, SECRET)
    end,

    ["how long a line plays comes from its length and rate"] = function(t)
        local speech = loadSpeech()
        t:assertEqual(speech.asideSeconds(string.rep("a", 24), 0), 3)
        t:assertEqual(speech.asideSeconds(string.rep("a", 36), 10), 2)
        t:assertTrue(speech.asideSeconds(string.rep("a", 24), -10) > 6.9)
        t:assertEqual(speech.asideSeconds(SECRET, 0), 8)
    end,

    ["lines add up while they wait, and the busy time ends"] = function(t)
        local speech, world = loadSpeech()
        speech.settings.chatChannel = true
        speech.settings.speechRate = 0
        t:assertFalse(speech:asideBusy())
        speech:speakAside(string.rep("a", 12), 1)
        speech:speakAside(string.rep("a", 24), 1)
        t:assertEqual(speech.asideUntil, 105)
        world.now = 104.9
        t:assertTrue(speech:asideBusy())
        world.now = 105
        t:assertFalse(speech:asideBusy())
        speech:speakAside(string.rep("a", 12), 1)
        t:assertEqual(speech.asideUntil, 107)
    end,

    ["a stop leaves a chat line playing and still marks the next line"] = function(t)
        local speech, world = loadSpeech()
        speech.settings.chatChannel = true
        speech:speakAside("hello there", 1)
        speech.queue = { { text = "x" } }
        speech.speaking = true
        speech:uiStop()
        t:assertEqual(world.stops, 0)
        t:assertEqual(world.noted, 1)
        t:assertEqual(#speech.queue, 0)
        t:assertFalse(speech.speaking)
        world.now = 200
        speech:stop()
        t:assertEqual(world.stops, 1)
        t:assertEqual(world.noted, 1)
    end,

    ["with protection off a stop cuts the chat line"] = function(t)
        local speech, world = loadSpeech()
        speech.settings.chatChannel = true
        speech.settings.chatProtect = false
        speech:speakAside("hello there", 1)
        speech:stop()
        t:assertEqual(world.stops, 1)
        t:assertFalse(speech:asideBusy())
    end,

    ["Stop Chat Voice cuts it and says so"] = function(t)
        local speech, world = loadSpeech()
        local binding = world.bindings[1]
        t:assertEqual(binding.key, "speech/stopChat")
        t:assertEqual(binding.inputs[1], "ALT-SHIFT-C")
        speech.settings.chatChannel = true
        speech:speakAside("hello there", 1)
        binding.func()
        t:assertEqual(world.stops, 1)
        t:assertFalse(speech:asideBusy())
        t:assertEqual(world.said[1], "Chat voice stopped.")
    end,

    ["a chat line starting beside nothing of ours does not hold the queue"] = function(t)
        local speech, world = loadSpeech()
        speech.settings.chatChannel = true
        speech:speakAside("hello there", 1)
        started(world, 7)
        t:assertFalse(speech.speaking)
        -- our own line, sent after: its start marks it, its end frees the queue, the chat line's end does not
        speech.speaking = true
        started(world, 8)
        t:assertTrue(speech.speaking)
        finished(world, 7)
        t:assertTrue(speech.speaking)
        finished(world, 8)
        t:assertFalse(speech.speaking)
    end,

    ["without a chat line a start marks the engine as speaking, as before"] = function(t)
        local speech, world = loadSpeech()
        started(world, 3)
        t:assertTrue(speech.speaking)
        finished(world, 3)
        t:assertFalse(speech.speaking)
    end,

    ["the chat alerts hand their own voice to the channel, and speak the usual way when not taken"] = function(t)
        local savedBase, savedSpeak = WowVision.base, WowVision.speak
        local savedVoiceChat = C_VoiceChat
        local taken, queued = {}, {}
        local take = true
        C_VoiceChat = {
            GetTtsVoices = function()
                return { { voiceID = 0, name = "Hedda" }, { voiceID = 1, name = "Zira" } }
            end,
        }
        WowVision.base = {
            speech = {
                settings = { voiceID = 0 },
                speakAside = function(_, text, voice)
                    if take then
                        tinsert(taken, { text, voice })
                    end
                    return take
                end,
            },
        }
        WowVision.speak = function(_, text)
            tinsert(queued, text)
        end
        local ok, err = pcall(function()
            local alert = WowVision.alerts.Alert:new({ key = "aside", label = "Aside" })
            alert:addOutput({
                type = "TTS",
                key = "tts",
                label = "TTS",
                aside = true,
                buildMessage = function(_, message)
                    return message.message
                end,
            })
            local db = alert:getDefaultDBRecursive()
            alert:setDB(db)
            alert:fire({ message = "follows" })
            t:assertEqual(#taken, 0)
            t:assertEqual(queued[1], "follows")
            local output = alert.outputs and alert.outputs[1] or nil
            t:assertNotNil(output)
            output.parameters:getField("voice"):set(output.parameters, 1)
            alert:fire({ message = "own" })
            t:assertEqual(taken[1][1], "own")
            t:assertEqual(taken[1][2], 1)
            t:assertEqual(#queued, 1)
            take = false
            alert:fire({ message = "refused" })
            t:assertEqual(queued[2], "refused")
            take = true
            local other = WowVision.alerts.Alert:new({ key = "notchat", label = "Not chat" })
            other:addOutput({
                type = "TTS",
                key = "tts",
                label = "TTS",
                buildMessage = function(_, message)
                    return message.message
                end,
            })
            other:setDB(other:getDefaultDBRecursive())
            other.outputs[1].parameters:getField("voice"):set(other.outputs[1].parameters, 1)
            other:fire({ message = "not chat" })
            t:assertEqual(#taken, 1)
            t:assertEqual(queued[3], "not chat")
        end)
        WowVision.base, WowVision.speak, C_VoiceChat = savedBase, savedSpeak, savedVoiceChat
        if not ok then
            error(err, 0)
        end
    end,
})
