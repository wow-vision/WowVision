local testRunner = WowVision.testing.testRunner

-- Headless only (tools/headless-tests.lua; not in modules.xml): the
-- scanner's In Progress lines are built once, but what they say about
-- progress follows the game's log while the tree stays open. The harness
-- hands in a snapshot (what the tree was built from) and a log the test
-- changes afterwards.

local harness = WowVision.quests._scannerLiveHarness

local function snapshotEntry()
    return {
        questId = 7,
        title = "Kobold Camp Cleanup",
        known = true,
        objectives = {
            { index = 1, text = "Kobold Vermin slain: 2/8", finished = false },
            { index = 2, text = "Candles: 0/4", finished = false },
        },
    }
end

local function logEntry(kills, candles)
    return {
        questId = 7,
        title = "Kobold Camp Cleanup",
        complete = kills >= 8 and candles >= 4,
        failed = false,
        objectives = {
            { text = "Kobold Vermin slain: " .. kills .. "/8", finished = kills >= 8 },
            { text = "Candles: " .. candles .. "/4", finished = candles >= 4 },
        },
    }
end

local function speak(value)
    if type(value) == "function" then
        return value()
    end
    return value
end

-- A test that reads the stand-in log: WowVision.quests.gameQuestEntry
-- answers from it only while the test runs, then the real one is back.
local function withLog(test)
    return function(t)
        local saved = WowVision.quests.gameQuestEntry
        WowVision.quests.gameQuestEntry = harness.gameQuestEntry
        local ok, err = pcall(test, t)
        WowVision.quests.gameQuestEntry = saved
        if not ok then
            error(err, 0)
        end
    end
end

-- The In Progress category's quest node, built from the snapshot.
local function questNode()
    harness.snapshot = { snapshotEntry() }
    harness.log = { [7] = logEntry(2, 0) }
    local tree = harness.providers.quests.build({ maxEntries = 10, radius = 500 })
    local inProgress = tree[2]
    return inProgress.children()[1]
end

testRunner:addSuite("QuestScannerLive", {
    ["the quest's progress follows the log after the tree was built"] = withLog(function(t)
        local node = questNode()
        t:assertEqual(speak(node.detail), "0 of 2")
        harness.log[7] = logEntry(8, 1)
        t:assertEqual(speak(node.detail), "1 of 2")
        harness.log[7] = logEntry(8, 4)
        t:assertEqual(speak(node.detail), "Complete")
    end),

    ["an objective's text and state follow the log"] = withLog(function(t)
        local objectives = questNode().children()
        t:assertEqual(speak(objectives[1].label), "Kobold Vermin slain: 2/8")
        t:assertNil(speak(objectives[1].detail))
        harness.log[7] = logEntry(8, 0)
        t:assertEqual(speak(objectives[1].label), "Kobold Vermin slain: 8/8")
        t:assertEqual(speak(objectives[1].detail), "Complete")
        t:assertEqual(speak(objectives[2].label), "Candles: 0/4")
    end),

    ["a quest gone from the log keeps what the tree was built with"] = withLog(function(t)
        local node = questNode()
        harness.log[7] = nil
        t:assertEqual(speak(node.detail), "0 of 2")
    end),
})
