local testRunner = WowVision.testing.testRunner
local PetHealth = WowVision.petHealth

-- What a step curve with these points yields for an input: the value of the
-- last point at or below it.
local function through(points, input)
    local value = points[1][2]
    for _, point in ipairs(points) do
        if point[1] <= input then
            value = point[2]
        end
    end
    return value
end

testRunner:addSuite("PetHealth", {
    ["the curve rounds the percent up to the step"] = function(t)
        local points = PetHealth.curvePoints(5)
        t:assertEqual(through(points, 0.36), 40)
        t:assertEqual(through(points, 0.40), 40)
        t:assertEqual(through(points, 0.401), 45)
        t:assertEqual(through(points, 0.999), 100)
        t:assertEqual(through(points, 1), 100)
    end,

    ["no health reads 0 and any health left does not"] = function(t)
        for _, step in ipairs(PetHealth.STEPS) do
            local points = PetHealth.curvePoints(step)
            t:assertEqual(through(points, 0), 0)
            t:assertEqual(through(points, 0.001), step)
            t:assertEqual(through(points, 1), 100)
        end
    end,

    ["every step ends at 100 and keeps its points in order"] = function(t)
        for _, step in ipairs(PetHealth.STEPS) do
            local points = PetHealth.curvePoints(step)
            t:assertEqual(#points, 100 / step + 1)
            t:assertEqual(points[#points][2], 100)
            for index = 2, #points do
                t:assertTrue(points[index][1] > points[index - 1][1])
            end
        end
    end,

    ["the words are joined around the value"] = function(t)
        t:assertEqual(PetHealth.readout("Pet", 45, "percent"), "Pet 45 percent")
    end,

    ["nothing is due without a health event"] = function(t)
        local state = PetHealth.newState()
        t:assertFalse(PetHealth.due(state, 100, 3, true))
    end,

    ["a change is due once, then waits for the interval"] = function(t)
        local state = PetHealth.newState()
        PetHealth.onHealth(state, false)
        t:assertTrue(PetHealth.due(state, 100, 3, true))
        t:assertFalse(PetHealth.due(state, 101, 3, true))
        PetHealth.onHealth(state, false)
        t:assertFalse(PetHealth.due(state, 102.9, 3, true))
        t:assertTrue(PetHealth.due(state, 103, 3, true))
    end,

    ["a change said once is not said again without a new event"] = function(t)
        local state = PetHealth.newState()
        PetHealth.onHealth(state, false)
        t:assertTrue(PetHealth.due(state, 100, 3, true))
        t:assertFalse(PetHealth.due(state, 200, 3, true))
    end,

    ["a change waits while the speech is busy and is not lost"] = function(t)
        local state = PetHealth.newState()
        PetHealth.onHealth(state, false)
        t:assertFalse(PetHealth.due(state, 100, 3, false))
        t:assertTrue(PetHealth.due(state, 100.2, 3, true))
    end,

    ["the death is said once, and again after the pet lived"] = function(t)
        local state = PetHealth.newState()
        t:assertTrue(PetHealth.onHealth(state, true))
        t:assertFalse(PetHealth.onHealth(state, true))
        PetHealth.onHealth(state, false)
        t:assertTrue(PetHealth.onHealth(state, true))
    end,

    ["a dead pet has no health left to say"] = function(t)
        local state = PetHealth.newState()
        PetHealth.onHealth(state, false)
        PetHealth.onHealth(state, true)
        t:assertFalse(PetHealth.due(state, 100, 3, true))
        t:assertFalse(PetHealth.combatEnded(state, 100))
    end,

    ["the end of a fight says an unsaid change once"] = function(t)
        local state = PetHealth.newState()
        t:assertFalse(PetHealth.combatEnded(state, 100))
        PetHealth.onHealth(state, false)
        t:assertTrue(PetHealth.combatEnded(state, 100))
        t:assertFalse(PetHealth.combatEnded(state, 100))
        PetHealth.onHealth(state, false)
        t:assertFalse(PetHealth.due(state, 101, 3, true))
    end,
})
