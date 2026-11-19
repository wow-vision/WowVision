local testRunner = WowVision.testing.testRunner
local restorePlayerProgress = WowVision.questLogTooltip.restorePlayerProgress

-- A tooltip that holds one primary tooltip info and records Set calls.
local function fakeTooltip(info)
    return {
        calls = {},
        GetPrimaryTooltipInfo = function()
            return info
        end,
        SetQuestPartyProgress = function(self, ...)
            tinsert(self.calls, { ... })
        end,
    }
end

local function partyInfo(questID, omitTitle, ignoreActivePlayer)
    return { getterName = "GetQuestPartyProgress", getterArgs = { questID, omitTitle, ignoreActivePlayer, n = 3 } }
end

testRunner:addSuite("QuestLogTooltip", {
    ["the game's party call without the player is made again with the player, no title"] = function(t)
        local tooltip = fakeTooltip(partyInfo(123, true, true))
        restorePlayerProgress(tooltip)
        t:assertEqual(#tooltip.calls, 1)
        t:assertEqual(tooltip.calls[1][1], 123, "the quest from the game's call")
        t:assertEqual(tooltip.calls[1][2], true, "title left out")
        t:assertEqual(tooltip.calls[1][3], false, "player kept in")
    end,

    ["a tooltip without the party call is left alone (solo, nobody else on the quest)"] = function(t)
        local tooltip = fakeTooltip(nil)
        restorePlayerProgress(tooltip)
        t:assertEqual(#tooltip.calls, 0)
        tooltip = fakeTooltip({ getterName = "GetHyperlink", getterArgs = { "quest:123" } })
        restorePlayerProgress(tooltip)
        t:assertEqual(#tooltip.calls, 0)
    end,

    ["a party call that already has the player is left alone"] = function(t)
        local tooltip = fakeTooltip(partyInfo(123, true, false))
        restorePlayerProgress(tooltip)
        t:assertEqual(#tooltip.calls, 0)
        tooltip = fakeTooltip(partyInfo(123))
        restorePlayerProgress(tooltip)
        t:assertEqual(#tooltip.calls, 0, "the tracker's call (defaults) includes the player")
    end,

    ["a secret quest is left alone"] = function(t)
        local savedIsSecretValue = issecretvalue
        issecretvalue = function(value)
            return value == "secret"
        end
        local tooltip = fakeTooltip(partyInfo("secret", true, true))
        local ok, err = pcall(restorePlayerProgress, tooltip)
        issecretvalue = savedIsSecretValue
        t:assertTrue(ok, err)
        t:assertEqual(#tooltip.calls, 0)
    end,
})
