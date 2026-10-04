local testRunner = WowVision.testing.testRunner
local turnMath = WowVision.turnMath

-- The engine as measured: each frame the OnUpdate decides, then the camera
-- steps by speed times that frame's duration (scaled by a trim), except
-- in the frame that stops. Returns the degrees turned and the sweep.
local function simulate(angle, plannedFps, frameDurations)
    local frameTime = turnMath.frameTime(plannedFps)
    local speed, steps = turnMath.plan(angle, frameTime)
    local sweep = turnMath.newSweep(angle, speed, steps)
    local turned = 0
    for i = 1, 200 do
        local delta = frameDurations[i] or frameDurations[#frameDurations]
        local action, fraction = sweep:frame(delta)
        if action == "stop" then
            return turned, sweep, speed, steps
        end
        turned = turned + speed * delta * (fraction or 1)
    end
    error("the sweep never stopped")
end

local function steady(fps)
    return { 1 / fps }
end

testRunner:addSuite("TurnMath", {
    ["a steady 20 fps turn lands exactly without a trim"] = function(t)
        local turned, sweep = simulate(80, 20, steady(20))
        t:assertTrue(math.abs(turned - 80) < 0.01)
        t:assertNil(sweep.trim)
    end,

    ["a half turn at 100 fps lands exactly"] = function(t)
        local turned, _, speed, steps = simulate(180, 100, steady(100))
        t:assertTrue(math.abs(turned - 180) < 0.01)
        t:assertEqual(steps, 13)
        t:assertTrue(speed <= turnMath.SPEED_MAX)
    end,

    ["a hitch frame is trimmed instead of overshooting"] = function(t)
        local turned, sweep = simulate(120, 60, { 0.016, 0.018, 0.1, 0.016 })
        t:assertTrue(math.abs(turned - 120) < 0.5)
        t:assertNotNil(sweep.trim)
    end,

    ["a frame rate drop mid-turn still lands"] = function(t)
        -- Planned at 100 fps, the game then runs at 30: the steps grow, and
        -- a last bit under a twentieth of one is skipped.
        local turned, _, speed = simulate(150, 100, { 0.01, 0.033, 0.033, 0.033, 0.033 })
        t:assertTrue(math.abs(turned - 150) <= speed * 0.033 * turnMath.TRIM_MIN)
    end,

    ["a tiny remainder stops early by less than a twentieth of a step"] = function(t)
        -- 100 fps planned, frames a hair shorter: the last bit is under 5 percent.
        local turned, _, speed = simulate(90, 100, { 0.00999 })
        t:assertTrue(math.abs(turned - 90) <= speed * 0.01 * turnMath.TRIM_MIN)
    end,

    ["small turns are slow enough to land in one step"] = function(t)
        local speed, steps = turnMath.plan(4, turnMath.frameTime(100))
        t:assertEqual(steps, 1)
        t:assertTrue(math.abs(speed - 400) < 0.01)
        local turned = simulate(4, 100, steady(100))
        t:assertTrue(math.abs(turned - 4) < 0.01)
    end,

    ["the frame rate is clamped"] = function(t)
        t:assertEqual(turnMath.frameTime(5), 1 / 10)
        t:assertEqual(turnMath.frameTime(nil), 1 / 10)
        t:assertEqual(turnMath.frameTime(500), 1 / 240)
    end,

    ["relative bearing is positive to the right"] = function(t)
        t:assertTrue(math.abs(turnMath.relativeBearing(0, 0, 0, 1, 0)) < 1e-9)
        t:assertTrue(math.abs(turnMath.relativeBearing(0, 0, 0, 0, -1) - 90) < 1e-9)
        t:assertTrue(math.abs(turnMath.relativeBearing(0, 0, 0, 0, 1) + 90) < 1e-9)
    end,

    ["a turn just past 180 is measured as such"] = function(t)
        local turned = turnMath.turned(0, math.rad(-181), 1, 181)
        t:assertTrue(math.abs(turned - 181) < 1e-9)
        local left = turnMath.turned(0, math.rad(30), -1, 30)
        t:assertTrue(math.abs(left - 30) < 1e-9)
    end,

    ["the movement direction follows strafing"] = function(t)
        local flags = { strafeRight = true }
        local right = turnMath.moveDirection(0, flags)
        t:assertTrue(math.abs(right + math.pi / 2) < 1e-9)
        -- Strafing right moves toward a target on the right: the lead
        -- point is closer to it.
        local lx, ly = turnMath.leadPoint(0, 0, 0, -10, right, 2)
        t:assertTrue(math.abs(lx) < 1e-9 and math.abs(ly + 2) < 1e-9)
        t:assertNil(turnMath.moveDirection(0, {}))
        local back = turnMath.moveDirection(0, { moveBackward = true })
        t:assertTrue(math.abs(math.abs(back) - math.pi) < 1e-9)
    end,

    ["the lead never passes half the way to the target"] = function(t)
        local lx, ly = turnMath.leadPoint(0, 0, 4, 0, 0, 10)
        t:assertTrue(math.abs(lx - 2) < 1e-9 and math.abs(ly) < 1e-9)
    end,
})
