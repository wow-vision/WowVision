-- Beacon.fileLevel (core/alerts/outputs.lua): the beacon file level for a
-- distance at a Beacon Volume.
local testRunner = WowVision.testing.testRunner
local Beacon = WowVision.alerts.outputTypes:get("Beacon")
local LEVELS = 30

testRunner:addSuite("BeaconVolume", {
    ["at 100 the level is the distance bucket, 1 to 30"] = function(t)
        t:assertEqual(Beacon.fileLevel(0, 100, LEVELS), 1)
        t:assertEqual(Beacon.fileLevel(7, 100, LEVELS), 2)
        t:assertEqual(Beacon.fileLevel(60, 100, LEVELS), 10)
        t:assertEqual(Beacon.fileLevel(500, 100, LEVELS), 30)
    end,

    ["the volume rounds to the nearest level"] = function(t)
        -- the nearest target: the loudest file the volume leaves
        t:assertEqual(Beacon.fileLevel(0, 96, LEVELS), 1)
        t:assertEqual(Beacon.fileLevel(0, 95, LEVELS), 2)
        t:assertEqual(Beacon.fileLevel(0, 55, LEVELS), 6)
        t:assertEqual(Beacon.fileLevel(0, 10, LEVELS), 10)
    end,

    ["far stays farther than near at every volume"] = function(t)
        for volume = 10, 100, 10 do
            local previous = 0
            for distance = 0, 200, 6 do
                local level = Beacon.fileLevel(distance, volume, LEVELS)
                t:assertTrue(level >= previous, "volume " .. volume .. " distance " .. distance)
                t:assertTrue(level >= 1 and level <= LEVELS, "volume " .. volume .. " in range")
                previous = level
            end
            -- the far end keeps its own step: 120 and 175 yards differ
            t:assertTrue(
                Beacon.fileLevel(120, volume, LEVELS) < Beacon.fileLevel(175, volume, LEVELS),
                "volume " .. volume .. " far cue"
            )
            t:assertEqual(Beacon.fileLevel(500, volume, LEVELS), LEVELS)
        end
    end,
})
