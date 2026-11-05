local testRunner = WowVision.testing.testRunner
local progress = WowVision.quests.progress

local function quest(id, objectives, complete, extra)
    local entry = { questId = id, title = "Quest " .. id, complete = complete, objectives = {} }
    for i, objective in ipairs(objectives) do
        entry.objectives[i] = { text = objective[1], finished = objective[2] }
    end
    for key, value in pairs(extra or {}) do
        entry[key] = value
    end
    return entry
end

local function kinds(changes)
    local out = {}
    for _, change in ipairs(changes) do
        tinsert(out, change.kind .. ":" .. tostring(change.text or change.title))
    end
    return table.concat(out, " | ")
end

testRunner:addSuite("quests.progress", {
    ["the first look is quiet"] = function(t)
        local now = progress.snapshot({ quest(1, { { "Kobold slain: 3/8", false } }) })
        t:assertEqual(#progress.changes(nil, now), 0)
    end,

    ["a moving count is progress"] = function(t)
        local before = progress.snapshot({ quest(1, { { "Kobold slain: 3/8", false } }) })
        local after = progress.snapshot({ quest(1, { { "Kobold slain: 4/8", false } }) })
        t:assertEqual(kinds(progress.changes(before, after)), "objective:Kobold slain: 4/8")
    end,

    ["the last kill finishes the objective, then the quest"] = function(t)
        local before = progress.snapshot({
            quest(1, { { "Kobold slain: 7/8", false }, { "Candle: 2/2", true } }, false),
        })
        local after = progress.snapshot({
            quest(1, { { "Kobold slain: 8/8", true }, { "Candle: 2/2", true } }, true),
        })
        t:assertEqual(
            kinds(progress.changes(before, after)),
            "objectiveComplete:Kobold slain: 8/8 | questComplete:Quest 1"
        )
    end,

    ["nothing changed is quiet"] = function(t)
        local entries = { quest(1, { { "Kobold slain: 3/8", false } }) }
        t:assertEqual(#progress.changes(progress.snapshot(entries), progress.snapshot(entries)), 0)
    end,

    ["a new quest is quiet even when already complete"] = function(t)
        local before = progress.snapshot({})
        local after = progress.snapshot({ quest(2, { { "Candle: 2/2", true } }, true) })
        t:assertEqual(#progress.changes(before, after), 0)
    end,

    ["a failed quest is not complete"] = function(t)
        local before = progress.snapshot({ quest(1, {}, false) })
        local after = progress.snapshot({ quest(1, {}, true, { failed = true }) })
        t:assertEqual(#progress.changes(before, after), 0)
    end,

    ["losing an item after finishing is progress again"] = function(t)
        local before = progress.snapshot({ quest(1, { { "Candle: 2/2", true } }, true) })
        local after = progress.snapshot({ quest(1, { { "Candle: 1/2", false } }, false) })
        t:assertEqual(kinds(progress.changes(before, after)), "objective:Candle: 1/2")
    end,

    ["an unknown text is never compared"] = function(t)
        local before = progress.snapshot({ quest(1, { { "Kobold slain: 3/8", false } }) })
        local after = progress.snapshot({ quest(1, { { nil, false } }) })
        t:assertEqual(#progress.changes(before, after), 0)
    end,

    ["a quest under a collapsed header is carried and still compared"] = function(t)
        local before = progress.snapshot({ quest(1, { { "Kobold slain: 3/8", false } }) })
        local after = progress.carryOver(before, progress.snapshot({}), function()
            return true
        end, function(questId, old)
            return { title = old.title, complete = false, objectives = { { text = "Kobold slain: 4/8" } } }
        end)
        t:assertEqual(kinds(progress.changes(before, after)), "objective:Kobold slain: 4/8")
        -- Opening the header later lists the same state: quiet.
        local opened = progress.snapshot({ quest(1, { { "Kobold slain: 4/8", false } }) })
        t:assertEqual(#progress.changes(after, opened), 0)
    end,

    ["a turned-in quest is dropped"] = function(t)
        local before = progress.snapshot({ quest(1, { { "Kobold slain: 8/8", true } }, true) })
        local after = progress.carryOver(before, progress.snapshot({}), function()
            return false
        end)
        t:assertNil(after[1])
        t:assertEqual(#after.order, 0)
    end,
})
