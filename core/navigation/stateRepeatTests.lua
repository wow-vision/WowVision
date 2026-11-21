local testRunner = WowVision.testing.testRunner
local stateRepeat = WowVision.stateRepeat

-- Feed { time, value } steps and collect the values spoken. Only true speaks
-- (the water states); pass bothSpeak for states with a line either way.
local function run(tracker, steps, delay, bothSpeak)
    local spoken = {}
    for _, step in ipairs(steps) do
        local time, value = step[1], step[2]
        if stateRepeat.update(tracker, value, time, delay, bothSpeak or value == true) then
            table.insert(spoken, tostring(value))
        end
    end
    return table.concat(spoken, ",")
end

-- A shore: the state flips every frame (1/60 s) for `seconds`, then stays `last`.
local function flicker(from, seconds, last)
    local steps, value = {}, true
    local frames = math.floor(seconds * 60)
    for i = 0, frames do
        table.insert(steps, { from + i / 60, value })
        value = not value
    end
    table.insert(steps, { from + seconds + 0.1, last })
    return steps
end

testRunner:addSuite("StateRepeat", {
    ["the start state is not spoken"] = function(t)
        local tracker = stateRepeat.new(true)
        t:assertEqual(run(tracker, { { 0, true }, { 1, true } }, 5), "")
    end,

    ["a first change is spoken at once"] = function(t)
        local tracker = stateRepeat.new(false)
        t:assertEqual(run(tracker, { { 0, true } }, 5), "true")
    end,

    ["a shore flicker says one line per delay"] = function(t)
        local tracker = stateRepeat.new(false)
        -- 12 seconds of flipping every frame: lines at 0, about 5 and about 10.
        t:assertEqual(run(tracker, flicker(0, 12, false), 5), "true,true,true")
    end,

    ["without a delay every entry is spoken"] = function(t)
        local tracker = stateRepeat.new(false)
        local steps = { { 0, true }, { 0.1, false }, { 0.2, true }, { 0.3, false }, { 0.4, true } }
        t:assertEqual(run(tracker, steps, 0), "true,true,true")
    end,

    ["leaving and coming back inside the delay says nothing new"] = function(t)
        local tracker = stateRepeat.new(false)
        t:assertEqual(run(tracker, { { 0, true }, { 1, false }, { 2, true }, { 9, true } }, 5), "true")
    end,

    ["coming back after the delay is spoken at once"] = function(t)
        local tracker = stateRepeat.new(false)
        -- Out of the water at 1 (taken over silently at 5), back in at 8.
        local steps = { { 0, true }, { 1, false }, { 5, false }, { 8, true } }
        t:assertEqual(run(tracker, steps, 5), "true,true")
    end,

    ["a silent change does not start a delay"] = function(t)
        local tracker = stateRepeat.new(true)
        -- Out at 0 (silent), back in at 0.5: spoken, nothing was said before.
        t:assertEqual(run(tracker, { { 0, false }, { 0.5, true } }, 5), "true")
    end,

    ["the last line matches where the flicker ends"] = function(t)
        -- A doorway: both states speak. The flicker ends on the state not said last.
        local tracker = stateRepeat.new("outdoors")
        local steps = { { 0, "indoors" }, { 0.1, "outdoors" }, { 0.2, "indoors" }, { 0.3, "outdoors" } }
        t:assertEqual(run(tracker, steps, 5, true), "indoors")
        -- Still outdoors when the delay is over: now that is said.
        t:assertEqual(run(tracker, { { 4.9, "outdoors" }, { 5.1, "outdoors" }, { 6, "outdoors" } }, 5, true), "outdoors")
    end,

    ["a flicker ending where it began says nothing more"] = function(t)
        local tracker = stateRepeat.new("outdoors")
        local steps = { { 0, "indoors" }, { 0.1, "outdoors" }, { 0.2, "indoors" }, { 5.5, "indoors" } }
        t:assertEqual(run(tracker, steps, 5, true), "indoors")
    end,
})
