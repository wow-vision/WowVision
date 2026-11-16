local testRunner = WowVision.testing.testRunner
local Completion = WowVision.quests.Completion

local function ids(list)
    local out = {}
    for _, quest in ipairs(list) do
        tinsert(out, tostring(quest.questId))
    end
    return table.concat(out, ",")
end

testRunner:addSuite("QuestCompletion", {
    ["the first reading is the baseline, even with complete quests"] = function(t)
        local watcher = Completion.new()
        t:assertEqual(#watcher:update({ [1] = { complete = true }, [2] = { complete = false } }), 0)
    end,

    ["a quest in the log turning complete is reported once, with its title"] = function(t)
        local watcher = Completion.new()
        watcher:update({ [1] = { complete = false, title = "A Threat Within" } })
        local turned = watcher:update({ [1] = { complete = true, title = "A Threat Within" } })
        t:assertEqual(ids(turned), "1")
        t:assertEqual(turned[1].title, "A Threat Within")
        t:assertEqual(#watcher:update({ [1] = { complete = true, title = "A Threat Within" } }), 0, "not again")
    end,

    ["a quest accepted already complete is not news"] = function(t)
        local watcher = Completion.new()
        watcher:update({ [1] = { complete = false } })
        t:assertEqual(#watcher:update({ [1] = { complete = false }, [2] = { complete = true } }), 0)
    end,

    ["a quest that falls back and completes again is reported again"] = function(t)
        local watcher = Completion.new()
        watcher:update({ [1] = { complete = true } })
        watcher:update({ [1] = { complete = false } })
        t:assertEqual(ids(watcher:update({ [1] = { complete = true } })), "1")
    end,

    ["several at once come by quest id; a quest that left the log is no news"] = function(t)
        local watcher = Completion.new()
        watcher:update({ [9] = { complete = false }, [3] = { complete = false }, [5] = { complete = false } })
        t:assertEqual(ids(watcher:update({ [9] = { complete = true }, [3] = { complete = true } })), "3,9")
    end,
})
