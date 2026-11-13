local testRunner = WowVision.testing.testRunner
local secrets = WowVision.secrets

-- A stand-in for the game's secrets: a table carrying the hidden value, and
-- an issecretvalue that recognises it. Installed for one test at a time.
local function secret(value)
    return { secretValue = value }
end

local function withSecrets(fn)
    return function(t)
        local saved = issecretvalue
        issecretvalue = function(value)
            return type(value) == "table" and value.secretValue ~= nil
        end
        local ok, err = pcall(fn, t)
        issecretvalue = saved
        if not ok then
            error(err, 0)
        end
    end
end

testRunner:addSuite("Secrets", {
    ["plain values compare as usual"] = function(t)
        t:assertEqual(secrets.changed("a", "a"), false)
        t:assertEqual(secrets.changed("a", "b"), true)
        t:assertEqual(secrets.changed(nil, "b"), true)
        t:assertEqual(secrets.changed(nil, nil), false)
    end,

    ["a secret on either side reads as a change"] = withSecrets(function(t)
        t:assertEqual(secrets.changed(secret("x"), "x"), true)
        t:assertEqual(secrets.changed("x", secret("x")), true)
        t:assertEqual(secrets.changed(secret("x"), secret("x")), true)
    end),

    ["hasText: nil and empty say nothing, secrets say something"] = withSecrets(function(t)
        t:assertEqual(secrets.hasText(nil), false)
        t:assertEqual(secrets.hasText(""), false)
        t:assertEqual(secrets.hasText("Hogger"), true)
        t:assertEqual(secrets.hasText(secret("")), true)
    end),

    ["join concatenates with the separator"] = function(t)
        t:assertEqual(secrets.join({}, ", "), "")
        t:assertEqual(secrets.join({ "Star" }, ", "), "Star")
        t:assertEqual(secrets.join({ "Star", "Hogger", "1 of 3" }, ", "), "Star, Hogger, 1 of 3")
    end,
    ["readBool: a plain answer, or nil and why"] = withSecrets(function(t)
        local function answer(value)
            return function()
                return value
            end
        end
        t:assertEqual(secrets.readBool(answer(true)), true)
        t:assertEqual(secrets.readBool(answer(false)), false)
        t:assertEqual(secrets.readBool(answer(nil)), false)
        local value, why = secrets.readBool(answer(secret(true)))
        t:assertEqual(value, nil)
        t:assertEqual(why, "hidden")
        value, why = secrets.readBool(function()
            error("refused")
        end)
        t:assertEqual(value, nil)
        t:assertEqual(why, "refused")
        value, why = secrets.readBool(nil)
        t:assertEqual(value, nil)
        t:assertEqual(why, "missing")
    end),
})
