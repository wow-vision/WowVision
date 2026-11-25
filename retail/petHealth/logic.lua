-- The pet health module's game-independent half: the curve points that round
-- the pet's health up to a step, the spoken text, and when it speaks. No WoW
-- API in here, so the headless suite covers it (retail/petHealth/tests.lua).
--
-- Health is a SECRET value on Retail and WoW: Forever (see
-- retail/groupHealth/logic.lua): addon code cannot compare it, do arithmetic
-- on it or keep it to compare later. UnitHealthPercent(unit, true, curve)
-- runs the real health (0 to 1) through a curve WE build and hands back the
-- result, itself secret, which concatenation and speech accept. So the module
-- never knows how hurt the pet is: it decides WHEN to speak from plain facts
-- only (a health event came, the pet is dead, the speech is free).

local PetHealth = {}
WowVision.petHealth = PetHealth

-- The steps the percentage can be rounded to.
PetHealth.STEPS = { 1, 5, 10, 20, 25 }

-- Step curve points that turn a health fraction (0 to 1) into the percent
-- rounded UP to a multiple of `step`: 0 stays 0 and, with 5, anything above
-- 0.35 up to 0.40 reads 40. A step curve yields the value of the last point
-- at or below the input, so each point sits a millionth above its fraction:
-- exactly 40 percent still reads 40.
function PetHealth.curvePoints(step)
    local points = { { 0, 0 } }
    for value = step, 100, step do
        points[#points + 1] = { (value - step) / 100 + 0.000001, value }
    end
    return points
end

-- "Pet 45 percent". The value may be hidden: it is only joined into the words.
function PetHealth.readout(pet, value, percent)
    return pet .. " " .. value .. " " .. percent
end

function PetHealth.newState()
    return { changed = false, lastSaid = nil, deadSaid = false }
end

-- A health event of the pet (that it fired is plain; what the health is stays
-- hidden). dead: whether the pet is dead. True when its death is to be said
-- now, once.
function PetHealth.onHealth(state, dead)
    if dead then
        state.changed = false
        if state.deadSaid then
            return false
        end
        state.deadSaid = true
        return true
    end
    state.deadSaid = false
    state.changed = true
    return false
end

-- Whether the health is to be said now: only after a health event, no sooner
-- than `interval` seconds after the last time, and only while the speech has
-- nothing else to say. A change that has to wait is said later.
function PetHealth.due(state, now, interval, speechIdle)
    if not state.changed or not speechIdle then
        return false
    end
    if state.lastSaid ~= nil and now - state.lastSaid < interval then
        return false
    end
    state.changed = false
    state.lastSaid = now
    return true
end

-- The end of a fight: the last word on the health, once, when it changed
-- since it was said.
function PetHealth.combatEnded(state, now)
    if not state.changed then
        return false
    end
    state.changed = false
    state.lastSaid = now
    return true
end
