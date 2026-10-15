local testRunner = WowVision.testing.testRunner
local NewClass = WowVision.NewClass

-- The game's voice list for one test: C_VoiceChat swapped for a stub and
-- put back even when the test fails (in game the real one speaks).
local function withVoices(names, body)
    local voices = {}
    for i, name in ipairs(names) do
        tinsert(voices, { voiceID = i - 1, name = name })
    end
    local saved = C_VoiceChat
    C_VoiceChat = {
        GetTtsVoices = function()
            return voices
        end,
    }
    local ok, err = pcall(body)
    C_VoiceChat = saved
    if not ok then
        error(err, 0)
    end
end

local function voiceClass()
    local A = NewClass("A")
    A:addFields({ { key = "voice", type = "TtsVoice", persist = true } })
    return A
end

testRunner:addSuite("TtsVoice", {
    ["saves the name and reads the number"] = function(t)
        withVoices({ "Hedda", "Zira" }, function()
            local global = {}
            local a = voiceClass():new()
            a:setDB({ global = global })
            a.voice = 1
            t:assertEqual(global.voice, "Zira")
            t:assertEqual(a.voice, 1)
        end)
    end,

    ["keeps the voice when installed voices move the numbers"] = function(t)
        local global = { voice = "Zira" }
        withVoices({ "Katja", "Stefan", "Hedda", "Zira" }, function()
            local a = voiceClass():new()
            a:setDB({ global = global })
            t:assertEqual(a.voice, 3)
            t:assertEqual(global.voice, "Zira")
        end)
    end,

    ["an old stored number is pinned as the name it means now"] = function(t)
        local global = { voice = 1 }
        withVoices({ "Hedda", "Zira" }, function()
            local a = voiceClass():new()
            a:setDB({ global = global })
            t:assertEqual(a.voice, 1)
            t:assertEqual(global.voice, "Zira")
        end)
    end,

    ["a missing value is pinned as the default voice"] = function(t)
        local global = {}
        withVoices({ "Hedda", "Zira" }, function()
            local a = voiceClass():new()
            a:setDB({ global = global })
            t:assertEqual(a.voice, 0)
            t:assertEqual(global.voice, "Hedda")
        end)
    end,

    ["a voice that is gone reads as the default but stays stored"] = function(t)
        local global = { voice = "Katja" }
        withVoices({ "Hedda", "Zira" }, function()
            local a = voiceClass():new()
            a:setDB({ global = global })
            t:assertEqual(a.voice, 0)
            t:assertEqual(global.voice, "Katja")
        end)
        withVoices({ "Hedda", "Katja", "Zira" }, function()
            local a = voiceClass():new()
            a:setDB({ global = global })
            t:assertEqual(a.voice, 1)
        end)
    end,

    ["choices and value text come from the game's list"] = function(t)
        withVoices({ "Hedda", "Zira" }, function()
            local A = voiceClass()
            local field = A:getField("voice")
            local a = A:new()
            local choices = field:getChoices(a)
            t:assertEqual(#choices, 2)
            t:assertEqual(choices[2].label, "Zira")
            t:assertEqual(choices[2].value, 1)
            t:assertEqual(field:getValueString(a, 1), "Zira")
        end)
    end,

    ["a parameter in a field set keeps its voice by name"] = function(t)
        local db = { voice = 0 }
        withVoices({ "Hedda", "Zira" }, function()
            local set = WowVision.classes.newFieldSet({ key = "tts" })
            set:add({ key = "voice", type = "TtsVoice", default = 0 })
            set:setDB(db)
            t:assertEqual(db.voice, "Hedda")
            set:setFieldValue("voice", 1)
            t:assertEqual(db.voice, "Zira")
        end)
        withVoices({ "Katja", "Hedda", "Zira" }, function()
            local set = WowVision.classes.newFieldSet({ key = "tts" })
            set:add({ key = "voice", type = "TtsVoice", default = 0 })
            set:setDB(db)
            t:assertEqual(set:getFieldValue("voice"), 2)
        end)
    end,
})
