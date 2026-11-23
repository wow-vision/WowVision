-- Headless only: the Social window's card keys. Every card on a page needs
-- its own key; the graph refuses a page with two of the same.
local testRunner = WowVision.testing.testRunner
local module = WowVision._socialUITestHarness

local function friend(battleTag, bnetAccountID, friendIndex)
    return {
        accountInfo = { battleTag = battleTag, bnetAccountID = bnetAccountID },
        friendIndex = friendIndex,
    }
end

testRunner:addSuite("SocialUICardKey", {
    ["a friend with a BattleTag goes by it"] = function(t)
        t:assertEqual(module.cardKey(friend("Anna#1234", 7, 1), 1), "card:friend:Anna#1234")
    end,
    ["two friends with an empty BattleTag get keys of their own"] = function(t)
        local first = module.cardKey(friend("", 7, 1), 1)
        local second = module.cardKey(friend("", 8, 2), 2)
        t:assertEqual(first, "card:friend:account:7")
        t:assertEqual(second, "card:friend:account:8")
    end,
    ["without a BattleTag or account id the friend index decides"] = function(t)
        t:assertEqual(module.cardKey(friend(nil, nil, 3), 5), "card:friend:account:3")
    end,
})
