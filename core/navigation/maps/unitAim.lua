-- Turn-to-unit math, kept free of game calls so it runs in the headless
-- tests. turnToUnit.lua reads the unit's nameplate and turns with it.
--
-- A nameplate sits on screen above its unit. With the camera straight
-- behind the character, the plate at the screen's centre line means the
-- character faces the unit exactly, near or far: the camera, the character
-- and the unit then stand on one vertical plane. Off centre, the plate's
-- offset gives the unit's angle as the CAMERA sees it, which is smaller
-- than the angle from the character (the camera stands behind it), the
-- more so the nearer the unit. So a turn by the camera's angle never
-- overshoots, and the change between two readings tells how much the
-- angle shrinks per degree turned (the gain). The second turn uses that
-- gain and lands; a third is rare. The gain also takes up any error in
-- the assumed field of view.
local unitAim = {}

local atan = math.atan

-- A plate this close to the screen edge may be pinned there (offscreen
-- nameplates), so its offset says only "at least this far".
unitAim.EDGE = 0.95
-- Turn when the plate is pinned to an edge: far enough to bring it onto
-- the screen in one or two turns, from wherever it is.
unitAim.EDGE_TURN = 90
unitAim.BEHIND_TURN = 180
-- A camera angle this small ends a press. Near units look smaller to the
-- camera, so this is about 3 degrees from the character at 10 yards.
unitAim.AIMED = 2
unitAim.GAIN_START = 1
unitAim.GAIN_MIN = 0.2
unitAim.GAIN_MAX = 1.5
-- A turn smaller than this teaches nothing about the gain (reading noise).
unitAim.LEARN_MIN = 3

-- The plate's horizontal offset from the screen centre, -1 (left edge) to
-- 1 (right edge). x and width in the same (screen) units.
function unitAim.offset(x, width)
    if width == nil or width <= 0 then
        return nil
    end
    local half = width / 2
    local offset = (x - half) / half
    return math.max(-1, math.min(1, offset))
end

-- The unit's angle as the camera sees it, in degrees, positive = right,
-- for a horizontal field of view of fov degrees.
function unitAim.cameraAngle(offset, fov)
    return math.deg(atan(offset * math.tan(math.rad(fov / 2))))
end

-- A new aim for one press.
function unitAim.newAim()
    return { gain = unitAim.GAIN_START, lastAngle = nil, lastTurn = nil, lastEdge = false, turns = 0 }
end

-- The next turn in degrees (positive = right) for a reading: kind is
-- "behind" (the plate is behind the camera) or "seen" with the camera
-- angle. Also returns the camera angle left to close (nil when unknown).
function unitAim.nextTurn(aim, kind, angle, offset)
    local turn
    if kind == "behind" then
        aim.lastAngle = nil
        turn = unitAim.BEHIND_TURN
    else
        local edge = math.abs(offset) >= unitAim.EDGE
        if aim.lastAngle ~= nil and not edge and not aim.lastEdge and math.abs(aim.lastTurn) >= unitAim.LEARN_MIN then
            local gain = (aim.lastAngle - angle) / aim.lastTurn
            aim.gain = math.max(unitAim.GAIN_MIN, math.min(unitAim.GAIN_MAX, gain))
        end
        turn = angle / aim.gain
        if edge then
            local sign = offset > 0 and 1 or -1
            turn = sign * math.max(math.abs(turn), unitAim.EDGE_TURN)
        end
        turn = math.max(-180, math.min(180, turn))
        aim.lastAngle = angle
        aim.lastEdge = edge
    end
    aim.lastTurn = turn
    aim.turns = aim.turns + 1
    return turn
end

-- The edge sweep, where the game will not tell where a plate is on screen
-- (WoW: Forever refuses to measure nameplates: "Can't measure restricted
-- regions"), but still tells whether it is behind the camera
-- (C_NamePlateManager.IsNamePlateUnitBehindCamera, not secret).
--
-- The camera orbits the character, so the unit changes between in front
-- of the camera and behind it at the same angle either side of its
-- bearing, whatever the camera's distance and the unit's: the middle of
-- the two changes is the bearing. They exist only for a unit farther
-- than the camera, so turnToUnit.lua pulls the camera in close (still
-- behind the character). A sweep to the right passes both. In game
-- (Forever, 2026-11-12) the game's own change event came in the very frame
-- the camera crossed, so no lag is taken out; a sweep back over the second
-- change could measure one: seen going right at t, going back at u, the
-- change itself is at the middle and the lag half the gap.
unitAim.LAG_MAX = 30

local function wrap(degrees)
    while degrees > 180 do
        degrees = degrees - 360
    end
    while degrees <= -180 do
        degrees = degrees + 360
    end
    return degrees
end

-- first and second: the two changes the sweep saw, in order, as
-- { at = degrees swept, front = true when the unit came in front }. back:
-- degrees swept where the sweep back saw the second change undone (nil:
-- no lag correction). Returns the bearing relative to where the sweep
-- started (positive = right), the width of the in-front stretch, and the
-- lag.
function unitAim.edgeBearing(first, second, back)
    local lag = 0
    if back ~= nil then
        lag = math.max(0, math.min(unitAim.LAG_MAX, (second.at - back) / 2))
    end
    local a, b = first.at - lag, second.at - lag
    local width
    if first.front then
        width = b - a
    else
        width = a + 360 - b
    end
    return wrap((a + b + (first.front and 0 or 360)) / 2), width, lag
end

WowVision.unitAim = unitAim
