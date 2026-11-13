-- Turn-to-unit math, kept free of game calls so it runs in the headless
-- tests. turnToUnit.lua sweeps the camera and turns with it.
--
-- In first person a unit changes between in front of the camera and
-- behind it exactly 90 degrees either side of its bearing, at any distance
-- (WoW: Forever, 2026-11-12: the two changes lay 180 degrees apart, and
-- turns from one change landed within about 2 degrees). That holds with the
-- camera level, as first person starts. So the first change a sweep meets
-- gives the bearing.
local unitAim = {}
local wrap = WowVision.turnMath.wrap

unitAim.FIRST_PERSON_HALF = 90

-- The unit's bearing (positive = right, as the turn) from the first change
-- of a sweep to the right: at, the degrees swept at the change; cameIn,
-- true when the unit came in front there (it lies ahead of the change),
-- false when it went behind (it lies back).
function unitAim.firstPersonBearing(at, cameIn)
    if cameIn then
        return wrap(at + unitAim.FIRST_PERSON_HALF)
    end
    return wrap(at - unitAim.FIRST_PERSON_HALF)
end

-- With the camera behind the character instead, a unit's in-front stretch
-- lies symmetric about its bearing, whatever its width: half a circle or
-- more by the behind-camera answer (wider the nearer the unit), or about
-- the screen's width where only an on-screen unit has a plate. So the
-- bearing is the middle of two changes. first and second: { at = degrees
-- swept, cameIn = came in front }, in sweep order. Returns the bearing and
-- the stretch's width.
function unitAim.closeBearing(first, second)
    if first.cameIn then
        return wrap((first.at + second.at) / 2), second.at - first.at
    end
    return wrap((first.at + second.at + 360) / 2), first.at + 360 - second.at
end

WowVision.unitAim = unitAim
