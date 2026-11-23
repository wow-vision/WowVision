local testRunner = WowVision.testing.testRunner
local check = WowVision.scriptsCheck

-- Runs the check with a game that answers `answer`, recording what is said.
local function run(answer)
    local said = {}
    local spoke = check.run(function()
        return answer
    end, function(text)
        tinsert(said, text)
    end)
    return spoke, said
end

testRunner:addSuite("ScriptsCheck", {
    ["scripts off: said once per session"] = function(t)
        check.said = false
        local spoke, said = run(false)
        t:assertTrue(spoke)
        t:assertEqual(#said, 1)
        t:assertEqual(said[1], check.message())
        spoke, said = run(false)
        t:assertFalse(spoke, "the second time in a session")
        t:assertEqual(#said, 0)
        check.said = false
    end,

    ["scripts on: nothing is said"] = function(t)
        check.said = false
        local spoke, said = run(true)
        t:assertFalse(spoke)
        t:assertEqual(#said, 0)
        t:assertFalse(check.said, "still free to speak if the setting is lost later")
    end,

    ["a client that cannot be asked: nothing is said"] = function(t)
        check.said = false
        t:assertEqual(check.allowed("not a function"), nil)
        t:assertEqual(check.allowed(function()
            error("refused")
        end), nil, "a refused question is no answer")
        t:assertEqual(check.allowed(function()
            return nil
        end), nil, "nil is no answer")
        local spoke = check.run(function()
            return nil
        end, function()
            error("must not speak")
        end)
        t:assertFalse(spoke)
        t:assertFalse(check.said)
    end,
})
