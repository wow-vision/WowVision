-- Ping Target: what is said on a press (pingTarget.announcement). The ping itself is the game's /ping in the
-- binding's secure macro, not testable here.

local testRunner = WowVision.testing.testRunner
local pingTarget = WowVision.pingTarget
local L = WowVision:getLocale()

local SECRET = {}

-- The game for one press: target = nil (none), or { friend, min, max, throws }; combat; secret marks answers hidden.
local function fakeApi(game)
    local target = game.target
    return {
        exists = function()
            if game.secretExists then
                return SECRET
            end
            return target ~= nil
        end,
        isFriend = function()
            return target ~= nil and target.friend == true
        end,
        inCombat = function()
            return game.combat == true
        end,
        getRange = function()
            if target.throws then
                error("blocked")
            end
            return target.min, target.max
        end,
        isSecret = function(value)
            return value == SECRET
        end,
        L = L,
    }
end

testRunner:addSuite("PingTarget", {
    ["without a target it says so"] = function(t)
        t:assertEqual(pingTarget.announcement(fakeApi({})), L["No target"])
    end,

    ["a target in range says the upper bound of its range"] = function(t)
        local text = pingTarget.announcement(fakeApi({ target = { min = 20, max = 25 } }))
        t:assertEqual(text, string.format(L["%d yards"], 25))
    end,

    ["a target beyond every check says more than the lower bound"] = function(t)
        local text = pingTarget.announcement(fakeApi({ target = { min = 40 } }))
        t:assertEqual(text, string.format(L["more than %d yards"], 40))
    end,

    ["no range known says nothing (the ping still sounds)"] = function(t)
        t:assertNil(pingTarget.announcement(fakeApi({ target = {} })))
    end,

    ["a friendly target in combat is not ranged"] = function(t)
        local api = fakeApi({ combat = true, target = { friend = true, min = 0, max = 5 } })
        local asked = false
        local getRange = api.getRange
        api.getRange = function(...)
            asked = true
            return getRange(...)
        end
        t:assertNil(pingTarget.announcement(api))
        t:assertFalse(asked)
    end,

    ["an enemy in combat is ranged"] = function(t)
        local text = pingTarget.announcement(fakeApi({ combat = true, target = { min = 5, max = 8 } }))
        t:assertEqual(text, string.format(L["%d yards"], 8))
    end,

    ["a range check that throws or answers secrets says nothing"] = function(t)
        t:assertNil(pingTarget.announcement(fakeApi({ target = { throws = true } })))
        t:assertNil(pingTarget.announcement(fakeApi({ target = { min = SECRET, max = SECRET } })))
    end,

    ["a hidden answer to whether there is a target says nothing"] = function(t)
        t:assertNil(pingTarget.announcement(fakeApi({ secretExists = true })))
    end,
})
