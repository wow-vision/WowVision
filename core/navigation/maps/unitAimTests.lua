local testRunner = WowVision.testing.testRunner
local unitAim = WowVision.unitAim

-- A sweep to the right from the character's facing over a unit at
-- bearing: where it first changes between in front and behind (first
-- person: 90 degrees either side), as turnToUnit.lua sees it.
local function firstChange(bearing)
    local function inFront(yaw)
        return math.abs(WowVision.turnMath.wrap(bearing - yaw)) < 90
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
        t:assertEqual(WowVision.turnMath.wrap(0), 0)
        t:assertEqual(WowVision.turnMath.wrap(190), -170)
        t:assertEqual(WowVision.turnMath.wrap(-190), 170)
        t:assertEqual(WowVision.turnMath.wrap(180), 180)
        t:assertEqual(WowVision.turnMath.wrap(-180), 180)
        t:assertEqual(WowVision.turnMath.wrap(540), 180)
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
            t:assertTrue(math.abs(WowVision.turnMath.wrap(found - bearing)) <= 1)
        end
    end,

    ["behind the character the middle of both changes is the bearing"] = function(t)
        -- camera camDistance behind, unit distance away: in front while
        -- camDistance + distance * cos(bearing - yaw) > 0
        local function sweep(bearing, distance, camDistance)
            local function inFront(yaw)
                return camDistance + distance * math.cos(math.rad(bearing - yaw)) > 0
            end
            local changes = {}
            local last = inFront(0)
            for yaw = 1, 400 do
                local now = inFront(yaw)
                if now ~= last then
                    tinsert(changes, { at = yaw - 0.5, cameIn = now })
                    last = now
                    if #changes == 2 then
                        break
                    end
                end
            end
            return unitAim.closeBearing(changes[1], changes[2])
        end
        for _, bearing in ipairs({ 0, 40, -75, 150, -170 }) do
            local found, width = sweep(bearing, 3, 2)
            t:assertTrue(math.abs(WowVision.turnMath.wrap(found - bearing)) <= 1)
            t:assertTrue(width > 180 and width < 330)
        end
    end,

    ["a plate only on screen gives the bearing too"] = function(t)
        -- offscreen nameplates off: a plate within 45 degrees of the view
        for _, bearing in ipairs({ 0, 60, -120, 170 }) do
            local changes = {}
            local function onScreen(yaw)
                return math.abs(WowVision.turnMath.wrap(bearing - yaw)) < 45
            end
            local last = onScreen(0)
            for yaw = 1, 400 do
                local now = onScreen(yaw)
                if now ~= last then
                    tinsert(changes, { at = yaw - 0.5, cameIn = now })
                    last = now
                    if #changes == 2 then
                        break
                    end
                end
            end
            local found, width = unitAim.closeBearing(changes[1], changes[2])
            t:assertTrue(math.abs(WowVision.turnMath.wrap(found - bearing)) <= 1)
            t:assertTrue(math.abs(width - 90) <= 1)
        end
    end,

    ["the first change comes within half a turn"] = function(t)
        for bearing = -179, 180, 7 do
            local at = firstChange(bearing)
            t:assertTrue(at <= 180)
        end
    end,
})
