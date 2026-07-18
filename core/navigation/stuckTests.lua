local testRunner = WowVision.testing.testRunner
local stuckMath = WowVision.stuckMath

testRunner:addSuite("StuckMath", {
    ["severity grades the movement shortfall"] = function(t)
        -- 7 yd/s over 0.15s: expected just over a yard.
        local speed, dt = 7, 0.15
        local expected = speed * dt
        t:assertEqual(stuckMath.severity(0, speed, dt), 1) -- dead stop
        t:assertEqual(stuckMath.severity(expected * 0.2, speed, dt), 1)
        t:assertEqual(stuckMath.severity(expected * 0.3, speed, dt), 2)
        t:assertEqual(stuckMath.severity(expected * 0.5, speed, dt), 3)
        t:assertEqual(stuckMath.severity(expected * 0.7, speed, dt), 4)
        t:assertEqual(stuckMath.severity(expected * 0.9, speed, dt), 5)
        t:assertNil(stuckMath.severity(expected, speed, dt)) -- full speed
        t:assertNil(stuckMath.severity(expected * 2, speed, dt)) -- faster than expected
    end,

    ["severity handles missing or zero inputs"] = function(t)
        t:assertNil(stuckMath.severity(1, nil, 0.15))
        t:assertNil(stuckMath.severity(1, 0, 0.15))
        t:assertNil(stuckMath.severity(1, 7, nil))
        t:assertNil(stuckMath.severity(1, 7, 0))
    end,

    ["speed scaling normalizes mounts and snares"] = function(t)
        -- Mounted at 14 yd/s, moving at running pace: half expected -> impeded.
        t:assertEqual(stuckMath.severity(7 * 0.15, 14, 0.15), 3)
        -- Snared to 3.5 yd/s, moving at that pace: fine.
        t:assertNil(stuckMath.severity(3.5 * 0.15, 3.5, 0.15))
    end,

    ["cadence fires every Nth impeded sample and resets when free"] = function(t)
        local cadence = stuckMath.newCadence(3)
        t:assertNil(cadence:sample(1))
        t:assertNil(cadence:sample(1))
        t:assertEqual(cadence:sample(1), 1)
        t:assertNil(cadence:sample(1)) -- rhythm restarts
        t:assertNil(cadence:sample(2))
        t:assertEqual(cadence:sample(2), 2)
        t:assertNil(cadence:sample(nil)) -- free movement resets
        t:assertNil(cadence:sample(3))
        t:assertNil(cadence:sample(3))
        t:assertEqual(cadence:sample(3), 3)
    end,
})
