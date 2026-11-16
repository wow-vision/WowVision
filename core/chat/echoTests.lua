local testRunner = WowVision.testing.testRunner
local echo = WowVision.chatEcho

local function fakeFrame()
    local frame = { lines = {}, activeDuringAdd = {} }
    function frame:AddMessage(text)
        tinsert(self.lines, text)
        tinsert(self.activeDuringAdd, echo.active)
    end
    return frame
end

testRunner:addSuite("ChatEcho", {
    ["a spoken line is written with the addon's name in front"] = function(t)
        local frame = fakeFrame()
        t:assertEqual(echo.send(frame, "Beacon set"), true)
        t:assertEqual(frame.lines[1], "WowVision: Beacon set")
    end,

    ["the chat hook can tell an echoed line, and only that one"] = function(t)
        local frame = fakeFrame()
        echo.send(frame, "Beacon set")
        t:assertEqual(frame.activeDuringAdd[1], true)
        t:assertEqual(echo.active, false)
    end,

    ["nothing to say or nowhere to write writes nothing"] = function(t)
        local frame = fakeFrame()
        t:assertEqual(echo.send(frame, ""), false)
        t:assertEqual(echo.send(frame, nil), false)
        t:assertEqual(echo.send(nil, "Beacon set"), false)
        t:assertEqual(#frame.lines, 0)
    end,

    ["a frame that fails is reported and leaves the echo closed"] = function(t)
        local reported = nil
        local saved = geterrorhandler
        geterrorhandler = function()
            return function(err)
                reported = err
            end
        end
        local result = echo.send({
            AddMessage = function()
                error("no chat here", 0)
            end,
        }, "Beacon set")
        geterrorhandler = saved
        t:assertEqual(result, false)
        t:assertEqual(reported, "no chat here")
        t:assertEqual(echo.active, false)
    end,

    ["a message is spoken and offered to the chat, reading out only spoken"] = function(t)
        local savedBase, savedSpeak = WowVision.base, WowVision.speak
        local spoken, written = {}, {}
        WowVision.speak = function(_, text)
            tinsert(spoken, text)
        end
        WowVision.base = {
            chat = {
                echoSpoken = function(_, text)
                    tinsert(written, text)
                end,
            },
        }
        WowVision:notify("Route started")
        WowVision:speak("Quests, button")
        WowVision.base, WowVision.speak = savedBase, savedSpeak
        t:assertEqual(#spoken, 2)
        t:assertEqual(spoken[1], "Route started")
        t:assertEqual(#written, 1)
        t:assertEqual(written[1], "Route started")
    end,

    ["the chat module decides, and is optional"] = function(t)
        local saved = WowVision.base
        local heard = nil
        WowVision.base = {
            chat = {
                echoSpoken = function(_, text)
                    heard = text
                end,
            },
        }
        echo.spoken("Beacon set")
        t:assertEqual(heard, "Beacon set")
        WowVision.base = {}
        echo.spoken("Beacon set")
        WowVision.base = saved
    end,
})
