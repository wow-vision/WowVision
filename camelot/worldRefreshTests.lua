local testRunner = WowVision.testing.testRunner
local refresh = WowVision.worldRefresh

-- The game's texts, as the toast formats them: a line with a number and a unit, and the "at any time" line.
local GAME = {
    anytime = "The world may refresh at any time.",
    countdown = "The world will refresh in %d %s.",
    seconds = "Seconds",
    minutes = "Minutes",
}

testRunner:addSuite("WorldRefresh", {
    ["the countdown is said in the game's words, in minutes rounded up, in seconds below one minute"] = function(t)
        t:assertEqual(refresh.text(300, GAME), "The world will refresh in 5 Minutes.")
        t:assertEqual(refresh.text(241, GAME), "The world will refresh in 5 Minutes.", "rounded up, as the toast does")
        t:assertEqual(refresh.text(60, GAME), "The world will refresh in 1 Minutes.")
        t:assertEqual(refresh.text(59.2, GAME), "The world will refresh in 60 Seconds.")
        t:assertEqual(refresh.text(1, GAME), "The world will refresh in 1 Seconds.")
    end,

    ["once the time is up the game's at any time line is said"] = function(t)
        t:assertEqual(refresh.text(0, GAME), "The world may refresh at any time.")
        t:assertEqual(refresh.text(-3, GAME), "The world may refresh at any time.")
    end,

    ["without the game's texts WowVision's own are said"] = function(t)
        t:assertEqual(refresh.text(300, {}), "The world refreshes in 5 minutes")
        t:assertEqual(refresh.text(30, {}), "The world refreshes in 30 seconds")
        t:assertEqual(refresh.text(0, {}), "The world can refresh at any time")
        t:assertEqual(
            refresh.text(300, { countdown = "%d %s", minutes = nil }),
            "The world refreshes in 5 minutes",
            "a unit the game does not have"
        )
        t:assertEqual(
            refresh.text(300, { countdown = "%d %s %s %q", minutes = "Minutes" }),
            "The world refreshes in 5 minutes",
            "a line that does not take these two values"
        )
    end,

    ["a time the game will not say is the plain statement, with no reminders"] = function(t)
        t:assertEqual(refresh.text(nil, GAME), "The world is about to refresh")
        t:assertEqual(#refresh.plan(nil), 0)
    end,

    ["the start says the time and where the way to act is"] = function(t)
        t:assertEqual(
            refresh.announcement(300, GAME),
            "The world will refresh in 5 Minutes. To refresh now, open the WowVision menu and choose World Refresh"
        )
        t:assertEqual(
            refresh.announcement(300, {}),
            "The world refreshes in 5 minutes. To refresh now, open the WowVision menu and choose World Refresh",
            "WowVision's own line has no full stop: one is put between"
        )
    end,

    ["reminders: at one minute when that is a while off, and when the time is up"] = function(t)
        local steps = refresh.plan(300)
        t:assertEqual(#steps, 2)
        t:assertEqual(steps[1].delay, 240, "one minute before the end")
        t:assertFalse(steps[1].ended)
        t:assertEqual(steps[2].delay, 301, "just after the end")
        t:assertTrue(steps[2].ended)
        steps = refresh.plan(80)
        t:assertEqual(#steps, 1, "the start was said 20 seconds before the minute: no second line for it")
        t:assertEqual(steps[1].delay, 81)
        t:assertTrue(steps[1].ended)
        steps = refresh.plan(91)
        t:assertEqual(#steps, 2)
        t:assertEqual(steps[1].delay, 31)
        t:assertEqual(#refresh.plan(0), 0, "already up: the start said so")
    end,
})
