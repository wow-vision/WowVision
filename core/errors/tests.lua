local testRunner = WowVision.testing.testRunner
local utils = WowVision.errors.utils

testRunner:addSuite("errors.utils", {
    ["templateLiteral strips %s placeholders"] = function(t)
        t:assertEqual(utils.templateLiteral("You have gained %s."), "Youhavegained.")
    end,

    ["templateLiteral strips numeric format specifiers"] = function(t)
        t:assertEqual(utils.templateLiteral("Level %d of %d"), "Levelof")
    end,

    ["templateLiteral strips flagged specifiers"] = function(t)
        t:assertEqual(utils.templateLiteral("Score: %+.2f pts"), "Score:pts")
    end,

    ["templateLiteral returns empty for placeholder-only template"] = function(t)
        t:assertEqual(utils.templateLiteral("%s"), "")
    end,

    ["templateLiteral returns empty for whitespace-and-placeholder template"] = function(t)
        t:assertEqual(utils.templateLiteral("  %s  %d  "), "")
    end,

    ["templateLiteral returns empty for nil template"] = function(t)
        t:assertEqual(utils.templateLiteral(nil), "")
    end,

    ["prettifyTemplate replaces placeholders with ellipsis"] = function(t)
        t:assertEqual(utils.prettifyTemplate("You have gained %s."), "You have gained ….")
    end,

    ["prettifyTemplate preserves whitespace and literals"] = function(t)
        t:assertEqual(utils.prettifyTemplate("Level %d of %d"), "Level … of …")
    end,

    ["prettifyTemplate returns nil for nil template"] = function(t)
        t:assertNil(utils.prettifyTemplate(nil))
    end,

    ["normalizeMessage returns prettified template when literal is non-empty"] = function(t)
        local result = utils.normalizeMessage("You have gained %s.", "You have gained Xynayya.")
        t:assertEqual(result, "You have gained ….")
    end,

    ["normalizeMessage collapses name variants to one key"] = function(t)
        local tmpl = "%s has died."
        local a = utils.normalizeMessage(tmpl, "Alice has died.")
        local b = utils.normalizeMessage(tmpl, "Bob has died.")
        t:assertEqual(a, b)
    end,

    ["normalizeMessage returns raw message when template is nil"] = function(t)
        t:assertEqual(utils.normalizeMessage(nil, "Raw error."), "Raw error.")
    end,

    ["normalizeMessage returns raw message when template has no literal"] = function(t)
        t:assertEqual(utils.normalizeMessage("%s", "Actual message"), "Actual message")
    end,

    ["makeKey combines type and message"] = function(t)
        t:assertEqual(utils.makeKey(42, "hello"), "42:hello")
    end,

    ["makeKey handles nil messageType"] = function(t)
        t:assertEqual(utils.makeKey(nil, "hello"), "nil:hello")
    end,

    ["makeKey distinguishes by type"] = function(t)
        local a = utils.makeKey(1, "same message")
        local b = utils.makeKey(2, "same message")
        t:assertTrue(a ~= b)
    end,
})
