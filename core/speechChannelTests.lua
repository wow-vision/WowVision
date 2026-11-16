local testRunner = WowVision.testing.testRunner
local channel = WowVision.speechChannel

testRunner:addSuite("Speech channel", {
    ["Spoken's mute on the Dialog channel is lifted through its API"] = function(t)
        local calls = {}
        local spoken = {}
        function spoken:MuteChannel(name, muted)
            tinsert(calls, { self, name, muted })
        end
        t:assertTrue(channel.lift(spoken))
        t:assertEqual(#calls, 1)
        t:assertEqual(calls[1][1], spoken)
        t:assertEqual(calls[1][2], "Dialog")
        t:assertEqual(calls[1][3], false)
    end,

    ["without Spoken, or with one that has no such call, nothing happens"] = function(t)
        t:assertFalse(channel.lift(nil))
        t:assertFalse(channel.lift({}))
        t:assertFalse(channel.lift("Spoken"))
    end,

    ["an error in Spoken does not reach the speech"] = function(t)
        local spoken = {
            MuteChannel = function()
                error("broken")
            end,
        }
        t:assertFalse(channel.lift(spoken))
    end,

    ["ready asks the Spoken that is loaded"] = function(t)
        local saved = _G.Spoken
        local lifted = 0
        _G.Spoken = {
            MuteChannel = function(_, name, muted)
                if name == "Dialog" and muted == false then
                    lifted = lifted + 1
                end
            end,
        }
        local ok, err = pcall(channel.ready)
        _G.Spoken = saved
        if not ok then
            error(err, 0)
        end
        t:assertEqual(lifted, 1)
        -- no Spoken: no error
        channel.ready()
    end,
})
