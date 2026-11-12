local testRunner = WowVision.testing.testRunner
local unitAim = WowVision.unitAim

-- A sweep to the right from the character's facing over a unit at
-- bearing: where it first changes between in front and behind (first
-- person: 90 degrees either side), as turnToUnit.lua sees it.
local function firstChange(bearing)
    local function inFront(yaw)
        return math.abs(unitAim.wrap(bearing - yaw)) < 90
    end
    local last = inFront(0)
    for yaw = 1, 360 do
        local now = inFront(yaw)
        if now ~= last then
            return yaw - 0.5, now
        end
    end
end

testRunner:addSuite("UnitAim", {
    ["wrap keeps degrees in -180 to 180"] = function(t)
        t:assertEqual(unitAim.wrap(0), 0)
        t:assertEqual(unitAim.wrap(190), -170)
        t:assertEqual(unitAim.wrap(-190), 170)
        t:assertEqual(unitAim.wrap(180), 180)
        t:assertEqual(unitAim.wrap(-180), 180)
        t:assertEqual(unitAim.wrap(540), 180)
    end,

    ["the first change gives the bearing, ahead or back of it"] = function(t)
        t:assertEqual(unitAim.firstPersonBearing(30, true), 120)
        t:assertEqual(unitAim.firstPersonBearing(30, false), -60)
        t:assertEqual(unitAim.firstPersonBearing(170, true), -100)
    end,

    ["a unit right, left, behind or ahead is found from the first change"] = function(t)
        for _, bearing in ipairs({ 90, -90, 179, -150, 45, 0, 2, -2 }) do
            local at, cameIn = firstChange(bearing)
            local found = unitAim.firstPersonBearing(at, cameIn)
            t:assertTrue(math.abs(unitAim.wrap(found - bearing)) <= 1)
        end
    end,

    ["the first change comes within half a turn"] = function(t)
        for bearing = -179, 180, 7 do
            local at = firstChange(bearing)
            t:assertTrue(at <= 180)
        end
    end,
})
