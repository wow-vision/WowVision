local testRunner = WowVision.testing.testRunner

-- The enemy count says a lost number again (enemyCount.LostLine,
-- enemyCount.Announcer) by one fact of WowVision's speech queue: a stop
-- REPLACES the queue table and leaves the old one as it was, so a line still
-- in the old table after the swap was never sent. These tests load each
-- client's speech.lua in a sandbox and pin that fact: a change to how stop
-- clears the queue (wipe, or taking lines out) fails here instead of the
-- count quietly never repeating a number again.

-- The file as a chunk whose globals are env: setfenv where it exists (Lua
-- 5.1, LuaJIT, the game), loadfile's own env argument on later Lua.
local function loadIn(path, env)
    if setfenv ~= nil then
        local chunk = assert(loadfile(path))
        setfenv(chunk, env)
        return chunk
    end
    return assert(loadfile(path, "t", env))
end

local function loadSpeech(path)
    local module = { L = setmetatable({}, { __index = function(_, key) return key end }) }
    function module:setLabel() end
    function module:setVital() end
    -- The settings' change handlers by key: a test switches the Speech Queue on with them.
    local onChange = {}
    function module:hasSettings()
        return {
            add = function(_, def)
                local subscribe = function(_, _, handler)
                    onChange[def.key] = handler
                end
                return { events = { valueChange = { subscribe = subscribe } } }
            end,
        }
    end
    local stopped = 0
    local env = setmetatable({
        WowVision = {
            base = {
                createModule = function()
                    return module
                end,
            },
            speechInterrupt = { handOver = function(text) return text end },
            ttsCacheBust = {
                bust = function(text) return text end,
                bustForeign = function(text) return text end,
            },
            speechSounds = { attach = function() end },
            speechTags = WowVision.speechTags,
        },
        C_VoiceChat = {
            SpeakText = function() end,
            StopSpeakingText = function()
                stopped = stopped + 1
            end,
        },
        CreateFrame = function()
            return setmetatable({}, { __index = function() return function() end end })
        end,
        tinsert = table.insert,
        tremove = table.remove,
    }, { __index = _G })
    local chunk = loadIn(path, env)
    chunk("WowVision", {})
    return module, function()
        return stopped
    end, onChange
end

local suite = {}
for _, path in ipairs({ "tbc/speech.lua", "mists/speech.lua", "retail/speech.lua" }) do
    suite[path .. ": a stop replaces the queue table and leaves its lines in the old one"] = function(t)
        local speech, stopped = loadSpeech(path)
        local line = { text = "3" }
        local old = { { text = "other speech" }, line }
        speech.queue = old
        speech:stop()
        t:assertNotEqual(speech.queue, old)
        t:assertEqual(#speech.queue, 0)
        t:assertEqual(#old, 2)
        t:assertEqual(old[2], line)
        t:assertEqual(stopped(), 1)
    end
end
testRunner:addSuite("SpeechQueueStop", suite)

-- The tagged lines of core/speechTags.lua, through each client's real queue:
-- the environmental alerts drop their out-of-date lines with them.
local tagSuite = {}
for _, path in ipairs({ "tbc/speech.lua", "mists/speech.lua", "retail/speech.lua" }) do
    tagSuite[path .. ": a tagged line waits with its tag and only its owner drops it"] = function(t)
        local speech, _, onChange = loadSpeech(path)
        speech.settings = { voiceID = 0, speechRate = 0, speechVolume = 100 }
        onChange.speechQueue(nil, nil, nil, true)
        speech:speak("playing") -- sent at once: the queue holds the lines after it
        local water, tag = {}, nil
        speech:withTag({ owner = water }, function()
            speech:speak("swimming")
        end)
        speech:speak("other speech")
        t:assertEqual(#speech.queue, 2)
        tag = speech.queue[1].tag
        t:assertEqual(tag.owner, water)
        t:assertNil(speech.queue[2].tag)
        speech:dropQueued({})
        t:assertEqual(#speech.queue, 2)
        speech:dropQueued(water)
        t:assertEqual(#speech.queue, 1)
        t:assertEqual(speech.queue[1].text, "other speech")
    end
end
testRunner:addSuite("SpeechQueueTags", tagSuite)
