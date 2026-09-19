local testRunner = WowVision.testing.testRunner
local utils = WowVision.errors.utils

testRunner:addSuite("errors.utils", {
    ["templateLiteral strips placeholders and whitespace"] = function(t)
        t:assertEqual(utils.templateLiteral("You have gained %s."), "Youhavegained.")
        t:assertEqual(utils.templateLiteral("Level %d of %d"), "Levelof")
        t:assertEqual(utils.templateLiteral("Score: %+.2f pts"), "Score:pts")
        t:assertEqual(utils.templateLiteral("%1$s slain: %2$d/%3$d"), "slain:/")
    end,

    ["templateLiteral is empty for wordless or missing templates"] = function(t)
        t:assertEqual(utils.templateLiteral("%s"), "")
        t:assertEqual(utils.templateLiteral("  %s  %d  "), "")
        t:assertEqual(utils.templateLiteral(nil), "")
    end,

    ["prettifyTemplate turns placeholders into ellipses"] = function(t)
        t:assertEqual(utils.prettifyTemplate("Level %d of %d"), "Level … of …")
        t:assertNil(utils.prettifyTemplate(nil))
    end,

    ["identify keys a worded error by its global name"] = function(t)
        local key, label = utils.identify("ERR_OUT_OF_RANGE", "Out of range.", "Out of range.")
        t:assertEqual(key, "ERR_OUT_OF_RANGE")
        t:assertEqual(label, "Out of range.")
    end,

    ["identify collapses placeholder variants to one entry"] = function(t)
        local keyA, labelA = utils.identify("ERR_PLAYER_DIED_S", "%s has died.", "Alice has died.")
        local keyB = utils.identify("ERR_PLAYER_DIED_S", "%s has died.", "Bob has died.")
        t:assertEqual(keyA, keyB)
        t:assertEqual(labelA, "… has died.")
    end,

    ["identify keeps wordless templates apart by text"] = function(t)
        local keyA, labelA = utils.identify("ERR_GENERIC_S", "%s", "First")
        local keyB = utils.identify("ERR_GENERIC_S", "%s", "Second")
        t:assertTrue(keyA ~= keyB)
        t:assertEqual(labelA, "First")
    end,

    ["identify keys untyped messages by text"] = function(t)
        local key, label = utils.identify(nil, nil, "Server shutdown in 5 minutes.")
        t:assertEqual(key, "text:Server shutdown in 5 minutes.")
        t:assertEqual(label, "Server shutdown in 5 minutes.")
    end,

    ["throttle suppresses repeats inside the delay"] = function(t)
        local throttle = utils.newThrottle()
        t:assertTrue(throttle:allow("a", 10, 2))
        t:assertFalse(throttle:allow("a", 11, 2))
        t:assertTrue(throttle:allow("b", 11, 2))
        t:assertTrue(throttle:allow("a", 12, 2))
    end,

    ["suppressed repeats do not extend the window"] = function(t)
        local throttle = utils.newThrottle()
        t:assertTrue(throttle:allow("a", 0, 2))
        t:assertFalse(throttle:allow("a", 1.5, 2))
        t:assertTrue(throttle:allow("a", 2.1, 2))
    end,

    ["throttle with no delay allows everything"] = function(t)
        local throttle = utils.newThrottle()
        t:assertTrue(throttle:allow("a", 1, 0))
        t:assertTrue(throttle:allow("a", 1, 0))
    end,

    ["frame dedupe passes each message once per frame"] = function(t)
        local dedupe = utils.newFrameDedupe()
        t:assertTrue(dedupe:first("Out of range.", 5))
        t:assertFalse(dedupe:first("Out of range.", 5))
        t:assertTrue(dedupe:first("Not enough mana.", 5))
        t:assertTrue(dedupe:first("Out of range.", 6))
    end,
})
