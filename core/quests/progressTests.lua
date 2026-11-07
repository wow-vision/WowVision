local testRunner = WowVision.testing.testRunner
local ProgressTracker = WowVision.quests.ProgressTracker

local function quest(questId, objectives, complete)
    return { questId = questId, objectives = objectives or {}, complete = complete == true }
end

local function kinds(results)
    local list = {}
    for _, result in ipairs(results) do
        table.insert(list, tostring(result.questId) .. ":" .. result.kind)
    end
    return table.concat(list, ",")
end

testRunner:addSuite("QuestProgress", {
    ["the first reading only remembers"] = function(t)
        local tracker = ProgressTracker:new()
        local results = tracker:update({ quest(1, { { text = "Kobold Candle: 3/8", finished = false } }) })
        t:assertEqual(#results, 0)
    end,

    ["a count going up in the text is progress"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Kobold Candle: 3/8", finished = false } }) })
        local results = tracker:update({ quest(1, { { text = "Kobold Candle: 4/8", finished = false } }) })
        t:assertEqual(kinds(results), "1:progress")
    end,

    ["the game's own numbers are used when present"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Kobolds slain", collected = 2, needed = 10, finished = false } }) })
        t:assertEqual(#tracker:update({ quest(1, { { text = "Kobolds slain", collected = 2, needed = 10 } }) }), 0)
        local results = tracker:update({ quest(1, { { text = "Kobolds slain", collected = 3, needed = 10 } }) })
        t:assertEqual(kinds(results), "1:progress")
    end,

    ["the last objective finishing is complete, not progress"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({
            quest(1, {
                { text = "Kobold Candle: 8/8", finished = true },
                { text = "Gold Dust: 9/10", finished = false },
            }),
        })
        local results = tracker:update({
            quest(1, {
                { text = "Kobold Candle: 8/8", finished = true },
                { text = "Gold Dust: 10/10", finished = true },
            }, true),
        })
        t:assertEqual(kinds(results), "1:complete")
    end,

    ["an objective without a count finishing is complete"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Explore the Fargodeep Mine", finished = false } }) })
        local results = tracker:update({ quest(1, { { text = "Explore the Fargodeep Mine", finished = true } }) })
        t:assertEqual(kinds(results), "1:complete")
    end,

    ["a changed text without a count is progress"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Deliver the letter", finished = false } }) })
        local results = tracker:update({ quest(1, { { text = "Deliver the letter (on its way)", finished = false } }) })
        t:assertEqual(kinds(results), "1:progress")
    end,

    ["a count going down stays silent"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Kobold Candle: 5/8", finished = false } }) })
        t:assertEqual(#tracker:update({ quest(1, { { text = "Kobold Candle: 4/8", finished = false } }) }), 0)
        -- and going up again from the lower count is progress
        t:assertEqual(kinds(tracker:update({ quest(1, { { text = "Kobold Candle: 5/8", finished = false } }) })), "1:progress")
    end,

    ["a newly accepted quest stays silent, even when already complete"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Kobold Candle: 3/8" } }) })
        local results = tracker:update({
            quest(1, { { text = "Kobold Candle: 3/8" } }),
            quest(2, { { text = "Linen Cloth: 6/6", finished = true } }, true),
        })
        t:assertEqual(#results, 0)
    end,

    ["a quest that left the log and came back is new again"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Kobold Candle: 3/8" } }) })
        tracker:update({})
        t:assertEqual(#tracker:update({ quest(1, { { text = "Kobold Candle: 5/8" } }) }), 0)
    end,

    ["an already complete quest staying complete is silent"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Kobold Candle: 8/8", finished = true } }, true) })
        t:assertEqual(#tracker:update({ quest(1, { { text = "Kobold Candle: 8/8", finished = true } }, true) }), 0)
    end,

    ["several quests report each"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({
            quest(1, { { text = "A: 1/3" } }),
            quest(2, { { text = "B: 0/1" } }),
            quest(3, { { text = "C: 2/5" } }),
        })
        local results = tracker:update({
            quest(1, { { text = "A: 2/3" } }),
            quest(2, { { text = "B: 1/1", finished = true } }, true),
            quest(3, { { text = "C: 2/5" } }),
        })
        t:assertEqual(kinds(results), "1:progress,2:complete")
    end,

    ["a count the game fills in after a later reading still sounds"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Boar slain: 0/8", collected = 0, needed = 8 } }) })
        -- the reading right after the kill still shows the old count
        t:assertEqual(#tracker:update({ quest(1, { { text = "Boar slain: 0/8", collected = 0, needed = 8 } }) }), 0)
        local results = tracker:update({ quest(1, { { text = "Boar slain: 1/8", collected = 1, needed = 8 } }) })
        t:assertEqual(kinds(results), "1:progress")
    end,

    ["objectives arriving after the accept stay silent, the first kill after them sounds"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({})
        tracker:update({ quest(1, {}) })
        t:assertTrue(tracker.loading)
        t:assertEqual(#tracker:update({ quest(1, { { text = "", collected = 0, needed = 8 } }) }), 0)
        t:assertTrue(tracker.loading)
        t:assertEqual(#tracker:update({ quest(1, { { text = "Boar slain: 0/8", collected = 0, needed = 8 } }) }), 0)
        t:assertFalse(tracker.loading)
        local results = tracker:update({ quest(1, { { text = "Boar slain: 1/8", collected = 1, needed = 8 } }) })
        t:assertEqual(kinds(results), "1:progress")
    end,

    ["an empty text turning into the real one is not progress"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "" } }) })
        t:assertEqual(#tracker:update({ quest(1, { { text = "Deliver the letter" } }) }), 0)
    end,

    ["a complete quest without objectives is not loading"] = function(t)
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, {}, true) })
        t:assertFalse(tracker.loading)
    end,

    ["a secret text keeps the last readable one"] = function(t)
        local previous = WowVision.isSecret
        WowVision.isSecret = function(value)
            return value == "SECRET"
        end
        local tracker = ProgressTracker:new()
        tracker:update({ quest(1, { { text = "Deliver the letter" } }) })
        t:assertEqual(#tracker:update({ quest(1, { { text = "SECRET" } }) }), 0)
        t:assertEqual(#tracker:update({ quest(1, { { text = "Deliver the letter" } }) }), 0)
        WowVision.isSecret = previous
    end,
})
