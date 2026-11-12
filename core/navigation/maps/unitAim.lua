-- Turn-to-unit math, kept free of game calls so it runs in the headless
-- tests. turnToUnit.lua sweeps the camera and turns with it.
--
-- In first person a unit changes between in front of the camera and
-- behind it exactly 90 degrees either side of its bearing, at any distance
-- (WoW: Forever, 2026-11-12: the two changes lay 180 degrees apart). So the
-- first change a sweep meets gives the bearing.
local unitAim = {}

unitAim.FIRST_PERSON_HALF = 90

-- degrees into (-180, 180]
function unitAim.wrap(degrees)
    local wrapped = (degrees + 180) % 360 - 180
    if wrapped == -180 then
        return 180
    end
    return wrapped
end

-- The unit's bearing (positive = right, as the turn) from the first change
-- of a sweep to the right: at, the degrees swept at the change; cameIn,
-- true when the unit came in front there (it lies ahead of the change),
-- false when it went behind (it lies back).
function unitAim.firstPersonBearing(at, cameIn)
    if cameIn then
        return unitAim.wrap(at + unitAim.FIRST_PERSON_HALF)
    end
    return unitAim.wrap(at - unitAim.FIRST_PERSON_HALF)
end

-- With the camera behind the character instead (for a unit so close that
-- its plate leaves the first-person view), the two changes lie the same
-- angle either side of the bearing, wider the nearer the unit, so a sweep
-- needs both: the bearing is the middle of the in-front stretch. first and
-- second: { at = degrees swept, cameIn = came in front }, in sweep order.
-- Returns the bearing and the stretch's width (half a circle or more).
function unitAim.closeBearing(first, second)
    if first.cameIn then
        return unitAim.wrap((first.at + second.at) / 2), second.at - first.at
    end
    return unitAim.wrap((first.at + second.at + 360) / 2), first.at + 360 - second.at
end

WowVision.unitAim = unitAim
