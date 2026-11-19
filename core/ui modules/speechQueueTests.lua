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
    function module:hasSettings()
        return {
            add = function()
                return { events = { valueChange = { subscribe = function() end } } }
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
    end
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
