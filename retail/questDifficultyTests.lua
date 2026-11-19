local testRunner = WowVision.testing.testRunner

-- The game's side for one check: its rating of a quest (function or nil for
-- a client without it) and the colour it gives a rating.
local function withGame(rating, check)
    local savedInfo, savedColor = C_PlayerInfo, GetDifficultyColor
    C_PlayerInfo = rating ~= nil and { GetContentDifficultyQuestForPlayer = rating } or nil
    GetDifficultyColor = function(difficulty)
        return "color " .. tostring(difficulty), "highlight " .. tostring(difficulty)
    end
    local ok, err = pcall(check)
    C_PlayerInfo, GetDifficultyColor = savedInfo, savedColor
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("QuestDifficulty", {
    ["the colour is the one the game gives its rating of the quest"] = function(t)
        local asked
        withGame(function(questId)
            asked = questId
            return 1
        end, function()
            local color, extra = WowVision.quests.ratedDifficultyColor(42)
            t:assertEqual(asked, 42, "asked for the quest")
            t:assertEqual(color, "color 1")
            t:assertEqual(extra, nil, "the colour only, not its highlight")
        end)
    end,

    ["no rating from the game, no colour"] = function(t)
        withGame(function()
            return nil
        end, function()
            t:assertEqual(WowVision.quests.ratedDifficultyColor(42), nil)
        end)
    end,

    ["a client without the rating gives no colour"] = function(t)
        withGame(nil, function()
            t:assertEqual(WowVision.quests.ratedDifficultyColor(42), nil)
        end)
    end,
})
