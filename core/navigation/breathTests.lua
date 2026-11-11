local testRunner = WowVision.testing.testRunner
local breathSteps = WowVision.breathSteps

-- Feed a list of percents (as milliseconds of a 60 second bar) and collect
-- what would be spoken.
local function run(state, percents, stepSize)
    local spoken = {}
    for _, percent in ipairs(percents) do
        local step = breathSteps.update(state, percent * 600, stepSize)
        if step then
            table.insert(spoken, step)
        end
    end
    return spoken
end

testRunner:addSuite("BreathSteps", {
    ["percent clamps to the bar"] = function(t)
        t:assertEqual(breathSteps.percent(60000, 60000), 100)
        t:assertEqual(breathSteps.percent(30000, 60000), 50)
        t:assertEqual(breathSteps.percent(-150, 60000), 0)
        t:assertEqual(breathSteps.percent(70000, 60000), 100)
        t:assertNil(breathSteps.percent(nil, 60000))
        t:assertNil(breathSteps.percent(100, 0))
    end,

    ["a full dive speaks every step down once"] = function(t)
        local state = breathSteps.new(60000, 60000, 10)
        local spoken = run(state, { 99, 95, 90, 89, 85, 80, 50, 49, 11, 9, 0 }, 10)
        -- A jump (49 to 11) speaks the step it lands in, not every one passed.
        t:assertEqual(table.concat(spoken, " "), "90 80 50 20 10 0")
    end,

    ["a refill re-arms the steps silently"] = function(t)
        local state = breathSteps.new(60000, 60000, 10)
        local spoken = run(state, { 85, 55 }, 10)
        t:assertEqual(table.concat(spoken, " "), "90 60")
        -- Surfaced: the bar fills again, nothing is said.
        spoken = run(state, { 60, 70, 75 }, 10)
        t:assertEqual(#spoken, 0)
        -- Dived again: the steps count from the new level.
        spoken = run(state, { 69, 65, 59 }, 10)
        t:assertEqual(table.concat(spoken, " "), "70 60")
    end,

    ["a bar picked up half empty starts quiet"] = function(t)
        local state = breathSteps.new(33000, 60000, 10)
        t:assertEqual(state.level, 60)
        local spoken = run(state, { 55, 51, 50, 49 }, 10)
        t:assertEqual(table.concat(spoken, " "), "50")
    end,

    ["the step size is honoured"] = function(t)
        local state = breathSteps.new(60000, 60000, 25)
        local spoken = run(state, { 90, 80, 75, 60, 50, 30, 24 }, 25)
        t:assertEqual(table.concat(spoken, " "), "75 50 25")
    end,
})
