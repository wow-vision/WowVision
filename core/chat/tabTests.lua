local testRunner = WowVision.testing.testRunner
local chatTabs = WowVision.chatTabs

testRunner:addSuite("ChatTabs", {
    ["a shown tab speaks; a hidden one only when set to always"] = function(t)
        t:assertEqual(chatTabs.shouldSpeak("shown", true), true)
        t:assertEqual(chatTabs.shouldSpeak("shown", false), false)
        t:assertEqual(chatTabs.shouldSpeak("always", false), true)
    end,

    ["a message is identified by its line ID"] = function(t)
        local args = { "hi", "Xynayya", n = 11 }
        args[11] = 4711
        t:assertEqual(chatTabs.lineKey(args, "anything"), "line:4711")
    end,

    ["a line without an event is identified by its text"] = function(t)
        t:assertEqual(chatTabs.lineKey(nil, "Disconnected"), "text:Disconnected")
    end,

    ["a secret line without an event has no identity"] = function(t)
        local previous = WowVision.secrets.isSecret
        WowVision.secrets.isSecret = function(value)
            return value == "SECRET"
        end
        local key = chatTabs.lineKey(nil, "SECRET")
        WowVision.secrets.isSecret = previous
        t:assertEqual(key, nil)
    end,

    ["the same message through two tabs is claimed once"] = function(t)
        local claims = chatTabs.newClaims()
        t:assertEqual(claims:claim("line:1", 10, "General"), true)
        t:assertEqual(claims:claim("line:1", 10, "Party"), false)
        t:assertEqual(claims:claim("line:2", 10, "Party"), true)
    end,

    ["two equal lines in one tab are both spoken"] = function(t)
        local claims = chatTabs.newClaims()
        t:assertEqual(claims:claim("text:You hit for 12.", 10, "Combat Log"), true)
        t:assertEqual(claims:claim("text:You hit for 12.", 10, "Combat Log"), true)
    end,

    ["claims expire with the moment"] = function(t)
        local claims = chatTabs.newClaims()
        claims:claim("text:Disconnected", 10, "General")
        t:assertEqual(claims:claim("text:Disconnected", 11, "Party"), true)
    end,

    ["a whisper tab is a temporary whisper window"] = function(t)
        t:assertEqual(chatTabs.isWhisperWindow({ isTemporary = true, chatType = "BN_WHISPER" }), true)
        t:assertEqual(chatTabs.isWhisperWindow({ isTemporary = true, chatType = "PET_BATTLE_COMBAT_LOG" }), false)
        t:assertEqual(chatTabs.isWhisperWindow({ chatType = "WHISPER" }), false)
    end,
})
