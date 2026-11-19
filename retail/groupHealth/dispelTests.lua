-- Headless only: the dispellable debuff announcements (dispel.lua) against a
-- stand-in tooltip reader, a stand-in clock and a recording speak.
local testRunner = WowVision.testing.testRunner
local GroupHealth = WowVision.groupHealth
local module = WowVision.groupHealth._moduleTestHarness

-- The game as members `numbers` (unit -> number) and their debuffs
-- (unit -> list of type words); `test` gets the spoken texts, a function
-- that moves the clock on and the debuff table to change.
local function withDispel(numbers, test)
    local saved = {
        GetTime = GetTime,
        InCombatLockdown = InCombatLockdown,
        base = WowVision.base,
        speak = module.speak,
        reader = module.dispelReader,
        settings = module.settings.dispellable,
        silent = module.settings.silentOutOfCombat,
    }
    local now = 100
    local spoken = {}
    local debuffs = {}
    local refused = false
    local last = nil
    GetTime = function()
        return now
    end
    InCombatLockdown = function()
        return false
    end
    -- A base of our own: other suites leave theirs, or none, behind.
    WowVision.base = {
        speech = {
            idle = function()
                return true
            end,
        },
    }
    module.speak = function(_, text)
        tinsert(spoken, text)
    end
    module.dispelReader = {
        fill = function(unit, index)
            if refused then
                return nil
            end
            local list = debuffs[unit] or {}
            last = list[index]
            return last ~= nil and 3 or 0
        end,
        word = function()
            return last
        end,
    }
    module.settings.dispellable = { enabled = true, repeatInterval = 3, numberFirst = false }
    module.settings.silentOutOfCombat = false
    module.dispelMembers, module.dispelAliases = {}, {}
    for unit, number in pairs(numbers) do
        module.dispelMembers[unit] = { unit = unit, number = number }
    end
    module.dispelDirty, module.nextDispelRepeat, module.dispelUnavailableSaid = {}, nil, false
    local function advance(seconds)
        now = now + seconds
    end
    local function refuse()
        refused = true
    end
    local ok, err = pcall(test, spoken, advance, debuffs, refuse)
    GetTime, InCombatLockdown = saved.GetTime, saved.InCombatLockdown
    WowVision.base, module.speak, module.dispelReader = saved.base, saved.speak, saved.reader
    module.settings.dispellable, module.settings.silentOutOfCombat = saved.settings, saved.silent
    module.dispelMembers, module.dispelAliases, module.dispelDirty, module.nextDispelRepeat = {}, {}, {}, nil
    if not ok then
        error(err, 0)
    end
end

-- An aura event for the unit, then the next frame.
local function auraEvent(unit)
    module:onAura(unit)
    module:checkDispels()
end

testRunner:addSuite("GroupHealthDispel", {
    ["logic: only a rise announces; a drop and zero stay silent"] = function(t)
        local state = GroupHealth.newDispelState()
        t:assertTrue(GroupHealth.dispelStep(state, 1, 10))
        t:assertFalse(GroupHealth.dispelStep(state, 1, 11))
        t:assertTrue(GroupHealth.dispelStep(state, 2, 12))
        t:assertFalse(GroupHealth.dispelStep(state, 1, 13))
        t:assertTrue(state.active)
        t:assertFalse(GroupHealth.dispelStep(state, 0, 14))
        t:assertFalse(state.active)
        t:assertFalse(GroupHealth.dispelStep(state, nil, 15))
    end,

    ["logic: the repeat runs only after a rise and only while a debuff stays"] = function(t)
        local state = GroupHealth.newDispelState()
        t:assertFalse(GroupHealth.dispelRepeatDue(state, 100, 3))
        GroupHealth.dispelStep(state, 1, 10)
        t:assertFalse(GroupHealth.dispelRepeatDue(state, 12, 3))
        t:assertTrue(GroupHealth.dispelRepeatDue(state, 13, 3))
        t:assertFalse(GroupHealth.dispelRepeatDue(state, 13, 0))
        GroupHealth.dispelStep(state, 0, 14)
        t:assertFalse(GroupHealth.dispelRepeatDue(state, 100, 3))
    end,

    ["logic: number and word in the chosen order, the number alone without a word"] = function(t)
        t:assertEqual(GroupHealth.dispelText(3, "Poison", false), "Poison 3")
        t:assertEqual(GroupHealth.dispelText(3, "Poison", true), "3 Poison")
        t:assertEqual(GroupHealth.dispelText(3, nil, false), "3")
    end,

    ["a new debuff is said as type and number"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs)
            debuffs.party1 = { "Poison" }
            auraEvent("party1")
            t:assertEqual(#spoken, 1)
            t:assertEqual(spoken[1], "Poison 2")
        end)
    end,

    ["the word said is the last debuff's"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs)
            debuffs.party1 = { "Poison" }
            auraEvent("party1")
            debuffs.party1 = { "Poison", "Curse" }
            auraEvent("party1")
            t:assertEqual(spoken[2], "Curse 2")
        end)
    end,

    ["the repeat says it again while it stays, then stops when it is gone"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs)
            debuffs.party1 = { "Poison" }
            auraEvent("party1")
            advance(1)
            module:checkDispels()
            t:assertEqual(#spoken, 1)
            advance(2.5)
            module:checkDispels()
            t:assertEqual(#spoken, 2)
            debuffs.party1 = {}
            auraEvent("party1")
            advance(10)
            module:checkDispels()
            t:assertEqual(#spoken, 2)
        end)
    end,

    ["the repeat finds a debuff gone without an aura event and stays silent"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs)
            debuffs.party1 = { "Poison" }
            auraEvent("party1")
            debuffs.party1 = {}
            advance(5)
            module:checkDispels()
            t:assertEqual(#spoken, 1)
            t:assertFalse(module.dispelMembers.party1.dispel.active)
        end)
    end,

    ["a debuff that drops but does not end is not said again on the drop"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs)
            module.settings.dispellable.repeatInterval = 0
            debuffs.party1 = { "Poison", "Curse" }
            auraEvent("party1")
            debuffs.party1 = { "Poison" }
            auraEvent("party1")
            t:assertEqual(#spoken, 1)
        end)
    end,

    ["nothing carried is never said"] = function(t)
        withDispel({ party1 = 2, player = 1 }, function(spoken, advance)
            auraEvent("party1")
            auraEvent("player")
            advance(30)
            module:checkDispels()
            t:assertEqual(#spoken, 0)
        end)
    end,

    ["switched off, nothing is read or said"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs)
            module.settings.dispellable.enabled = false
            debuffs.party1 = { "Poison" }
            auraEvent("party1")
            t:assertEqual(#spoken, 0)
        end)
    end,

    ["silent out of combat: said by the repeat once the monitor speaks again"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs)
            module.settings.silentOutOfCombat = true
            debuffs.party1 = { "Poison" }
            auraEvent("party1")
            t:assertEqual(#spoken, 0)
            InCombatLockdown = function()
                return true
            end
            advance(0.2)
            module:checkDispels()
            t:assertEqual(spoken[1], "Poison 2")
        end)
    end,

    ["held back while silent, it is said once speaking is allowed even without a repeat"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs)
            module.settings.silentOutOfCombat = true
            module.settings.dispellable.repeatInterval = 0
            debuffs.party1 = { "Curse" }
            auraEvent("party1")
            InCombatLockdown = function()
                return true
            end
            advance(0.2)
            module:checkDispels()
            advance(10)
            module:checkDispels()
            t:assertEqual(#spoken, 1)
            t:assertEqual(spoken[1], "Curse 2")
        end)
    end,

    ["a read refused on the repeat says unavailable too"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs, refuse)
            local notified = {}
            local savedNotify = WowVision.notify
            WowVision.notify = function(_, text)
                tinsert(notified, text)
            end
            debuffs.party1 = { "Poison" }
            auraEvent("party1")
            refuse()
            advance(5)
            module:checkDispels()
            WowVision.notify = savedNotify
            t:assertEqual(#notified, 1)
            t:assertEqual(#spoken, 1)
        end)
    end,

    ["a refused read says unavailable once, never a debuff"] = function(t)
        withDispel({ party1 = 2 }, function(spoken, advance, debuffs, refuse)
            local notified = {}
            local savedNotify = WowVision.notify
            WowVision.notify = function(_, text)
                tinsert(notified, text)
            end
            refuse()
            auraEvent("party1")
            auraEvent("party1")
            WowVision.notify = savedNotify
            t:assertEqual(#notified, 1)
            t:assertEqual(#spoken, 0)
        end)
    end,

    ["a secret unit in the event reads every member"] = function(t)
        withDispel({ party1 = 2, party2 = 3 }, function(spoken, advance, debuffs)
            debuffs.party2 = { "Magic" }
            module:onAura(nil)
            module:checkDispels()
            t:assertEqual(spoken[1], "Magic 3")
        end)
    end,
})
