local testRunner = WowVision.testing.testRunner

-- Game reads for one test: everything missing unless given.
local function reads(overrides)
    local fake = {
        difficultyLevel = function()
            return nil
        end,
        colorWord = function()
            return nil
        end,
        tagName = function()
            return nil
        end,
        groupSize = function()
            return nil
        end,
        logEntry = function()
            return nil
        end,
        questText = function()
            return nil
        end,
        turnIn = function()
            return nil
        end,
        placeName = function()
            return nil
        end,
    }
    for key, value in pairs(overrides or {}) do
        fake[key] = value
    end
    return fake
end

local function joined(lines)
    return table.concat(lines, " | ")
end

testRunner:addSuite("QuestTooltip", {
    ["a nearby quest: title, level with colour, kind, giver with place, text"] = function(t)
        local lines = WowVision.quests.tooltipLines({
            questId = 7,
            name = "Kobold Camp Cleanup",
            level = 3,
            requiredLevel = 1,
            daily = true,
            starter = { name = "Marshal McBride", nearest = {} },
        }, "nearby", reads({
            colorWord = function(level)
                return level == 3 and "Green" or nil
            end,
            tagName = function()
                return "Elite"
            end,
            groupSize = function()
                return 3
            end,
            placeName = function()
                return "Northshire Abbey"
            end,
            questText = function()
                return { "Kill 10 Kobold Vermin." }
            end,
        }))
        t:assertEqual(
            joined(lines),
            "Kobold Camp Cleanup | Level 3, Green | Required Level 1 | Elite, Daily, 3 players"
                .. " | Quest Giver: Marshal McBride, Northshire Abbey | Kill 10 Kobold Vermin."
        )
    end,

    ["the game's scaled level wins over the data's"] = function(t)
        local lines = WowVision.quests.tooltipLines({ questId = 7, name = "Q", level = 3 }, "nearby", reads({
            difficultyLevel = function()
                return 12
            end,
            colorWord = function(level)
                return level == 12 and "Yellow" or "wrong"
            end,
        }))
        t:assertEqual(joined(lines), "Q | Level 12, Yellow")
    end,

    ["an item that starts a quest is named as the giver"] = function(t)
        local lines = WowVision.quests.tooltipLines({
            questId = 7,
            name = "Q",
            starter = { name = "Kobold", item = { name = "A Worn Note" } },
        }, "nearby", reads())
        t:assertEqual(joined(lines), "Q | Quest Giver: A Worn Note")
    end,

    ["a quest in progress reads its live progress and objectives"] = function(t)
        local stale = { questId = 9, title = "Wolves", level = 10, objectives = { { text = "Prowler slain: 1/10" } } }
        local lines = WowVision.quests.tooltipLines(stale, "inProgress", reads({
            logEntry = function()
                return {
                    questId = 9,
                    title = "Wolves",
                    level = 10,
                    objectives = {
                        { text = "Prowler slain: 4/10", finished = false },
                        { text = "Explore the hill", finished = true },
                    },
                }
            end,
            questText = function()
                return { "Prowler slain: 4/10" }
            end,
        }))
        t:assertEqual(
            joined(lines),
            "Wolves | Level 10 | Objectives: 1 of 2 | Prowler slain: 4/10 | Explore the hill, Complete"
        )
    end,

    ["a complete quest says so and where to turn it in"] = function(t)
        local lines = WowVision.quests.tooltipLines({
            questId = 9,
            title = "Wolves",
            complete = true,
            objectives = { { text = "Prowler slain: 10/10", finished = true } },
        }, "inProgress", reads({
            turnIn = function()
                return "Guard Thomas"
            end,
        }))
        t:assertEqual(joined(lines), "Wolves | Complete | Prowler slain: 10/10, Complete | Turn In: Guard Thomas")
    end,

    ["a failed quest says Failed"] = function(t)
        local lines = WowVision.quests.tooltipLines({ questId = 9, title = "Escort", failed = true }, "inProgress", reads())
        t:assertEqual(joined(lines), "Escort | Failed")
    end,
})
