local testRunner = WowVision.testing.testRunner
local unitAim = WowVision.unitAim

local atan2 = math.atan2 or function(y, x)
    return math.atan(y, x)
end

-- A camera camDistance yards behind the character, a unit distance yards
-- away at bearing degrees (positive = right), and a screen of trueFov
-- degrees. Returns what turnToUnit.lua reads: "behind", or "seen" and the
-- plate's offset, pinned to the edge like an offscreen plate.
local function look(bearing, distance, camDistance, trueFov)
    local b = math.rad(bearing)
    local side, ahead = distance * math.sin(b), camDistance + distance * math.cos(b)
    if ahead <= 0 then
        return "behind"
    end
    local offset = math.tan(atan2(side, ahead)) / math.tan(math.rad(trueFov / 2))
    return "seen", math.max(-1, math.min(1, offset))
end

-- The press as turnToUnit.lua runs it, the turns landing exactly. Returns
-- the bearing left and the turns used.
local function press(bearing, distance, camDistance, trueFov, assumedFov)
    local aim = unitAim.newAim()
    for _ = 1, 4 do
        local kind, offset = look(bearing, distance, camDistance, trueFov)
        local angle = kind == "seen" and unitAim.cameraAngle(offset, assumedFov) or nil
        if angle ~= nil and math.abs(angle) <= unitAim.AIMED and math.abs(offset) < unitAim.EDGE then
            return bearing, aim.turns
        end
        local turn = unitAim.nextTurn(aim, kind, angle, offset)
        -- turnByAngle does nothing within its tolerance
        if math.abs(turn) <= 3 then
            return bearing, aim.turns
        end
        bearing = bearing - turn
        while bearing > 180 do
            bearing = bearing - 360
        end
        while bearing <= -180 do
            bearing = bearing + 360
        end
    end
    return bearing, aim.turns
end

testRunner:addSuite("UnitAim", {
    ["the offset runs from the left edge to the right edge"] = function(t)
        t:assertEqual(unitAim.offset(0, 1000), -1)
        t:assertEqual(unitAim.offset(500, 1000), 0)
        t:assertEqual(unitAim.offset(1000, 1000), 1)
        t:assertEqual(unitAim.offset(1200, 1000), 1)
        t:assertEqual(unitAim.offset(10, 0), nil)
    end,

    ["the edge of the screen is half the field of view"] = function(t)
        t:assertTrue(math.abs(unitAim.cameraAngle(1, 90) - 45) < 0.001)
        t:assertTrue(math.abs(unitAim.cameraAngle(-1, 90) + 45) < 0.001)
    end,

    ["a far unit is faced in one turn"] = function(t)
        local left, turns = press(30, 200, 6, 90, 90)
        t:assertTrue(math.abs(left) < 3)
        t:assertEqual(turns, 1)
    end,

    ["a near unit is faced in two or three turns, never overshot by the first"] = function(t)
        local aim = unitAim.newAim()
        local kind, offset = look(40, 4, 6, 90)
        local first = unitAim.nextTurn(aim, kind, unitAim.cameraAngle(offset, 90), offset)
        t:assertTrue(first > 0 and first < 40)
        local left, turns = press(40, 4, 6, 90, 90)
        t:assertTrue(math.abs(left) < 3)
        t:assertTrue(turns <= 3)
    end,

    ["a wrong field of view is taken up by the gain"] = function(t)
        local left = press(35, 15, 6, 70, 90)
        t:assertTrue(math.abs(left) < 3)
        left = press(-35, 15, 6, 110, 90)
        t:assertTrue(math.abs(left) < 3)
    end,

    ["a unit to the left turns left"] = function(t)
        local aim = unitAim.newAim()
        local kind, offset = look(-30, 20, 6, 90)
        t:assertTrue(unitAim.nextTurn(aim, kind, unitAim.cameraAngle(offset, 90), offset) < 0)
    end,

    ["a unit behind or off screen is still found"] = function(t)
        for _, bearing in ipairs({ 170, -120, 75, -80 }) do
            local left = press(bearing, 10, 6, 90, 90)
            t:assertTrue(math.abs(left) < 4)
        end
    end,
})
