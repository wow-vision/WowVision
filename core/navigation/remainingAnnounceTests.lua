local testRunner = WowVision.testing.testRunner
local remainingAnnounce = WowVision.remainingAnnounce

-- Walk a route of total waypoints from the start and collect the counts
-- spoken, one per waypoint reached (the last one says Arrived instead).
local function walk(mode, total)
    local spoken = {}
    for reached = 1, total do
        local remaining = total - reached
        if remainingAnnounce.shouldAnnounce(mode, remaining, total) then
            table.insert(spoken, remaining)
        end
    end
    return table.concat(spoken, " ")
end

testRunner:addSuite("RemainingAnnounce", {
    ["always speaks every waypoint but the last"] = function(t)
        t:assertEqual(walk("always", 5), "4 3 2 1")
        t:assertEqual(walk(nil, 3), "2 1", "no mode set: always")
        t:assertEqual(walk("unknown", 3), "2 1", "an unknown mode: always")
    end,

    ["never speaks nothing"] = function(t)
        t:assertEqual(walk("never", 20), "")
    end,

    ["the last ten speak from 10 to the end"] = function(t)
        t:assertEqual(walk("last10", 14), "10 9 8 7 6 5 4 3 2 1")
        t:assertEqual(walk("last10", 4), "3 2 1", "a short route speaks all")
    end,

    ["the last five speak from 5 to the end"] = function(t)
        t:assertEqual(walk("last5", 20), "5 4 3 2 1")
    end,

    ["the last one speaks only the waypoint before the last"] = function(t)
        t:assertEqual(walk("last1", 20), "1")
        t:assertEqual(walk("last1", 2), "1")
    end,

    ["the last ten percent round up"] = function(t)
        t:assertEqual(remainingAnnounce.tenPercent(55), 6)
        t:assertEqual(remainingAnnounce.tenPercent(50), 5)
        t:assertEqual(remainingAnnounce.tenPercent(30), 3)
        t:assertEqual(remainingAnnounce.tenPercent(5), 1)
        t:assertEqual(remainingAnnounce.tenPercent(0), 0)
        t:assertEqual(walk("lastTenPercent", 55), "6 5 4 3 2 1")
        t:assertEqual(walk("lastTenPercent", 30), "3 2 1")
        t:assertEqual(walk("lastTenPercent", 5), "1")
    end,

    ["every ten counts from the end and says the last one"] = function(t)
        t:assertEqual(walk("every10", 55), "50 40 30 20 10 1")
        t:assertEqual(walk("every10", 8), "1")
        t:assertEqual(walk("every10", 10), "1", "10 waypoints: 9 left at the first")
        t:assertEqual(walk("every10", 11), "10 1")
    end,

    ["nothing is spoken once none is left"] = function(t)
        t:assertFalse(remainingAnnounce.shouldAnnounce("always", 0, 5))
        t:assertFalse(remainingAnnounce.shouldAnnounce("always", nil, 5))
    end,

    ["every mode is listed"] = function(t)
        t:assertEqual(#remainingAnnounce.modes, 7)
        t:assertEqual(remainingAnnounce.modes[1], remainingAnnounce.DEFAULT)
    end,
})
