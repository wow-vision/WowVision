-- Headless only (tools/headless-tests.lua loads gearJudge.lua against a stand-in loot module and hands over the
-- loader): the verdict on the items up for a roll, over a stand-in for the game and for Sharpie's Gear Judge.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._gearJudgeTestHarness

local module, registered = harness.load({ SharpiesGearJudge = true })

local function binding(key)
    for _, info in ipairs(registered.bindings) do
        if info.key == key then
            return info
        end
    end
    return nil
end

local RING = "|cff0070dd|Hitem:101::::|h[Gold Band]|h|r"
local OLD = "|cff1eff00|Hitem:55::::|h[Old Ring]|h|r"

-- A roll world: rolls (the game's roll windows), judge(link) returning what the Judge returns, names by link. `said`
-- collects what is spoken; timers holds the waiting retries.
local function withRolls(test)
    local world = { rolls = { { link = RING, name = "Gold Band" } }, requested = {}, timers = {}, locale = "enUS" }
    world.names = { [RING] = "Gold Band", [OLD] = "Old Ring" }
    world.result = { upgradePct = 4.25, equippedLink = OLD }
    world.api = {
        IsReady = function()
            return true
        end,
        ScoreItem = function(link)
            if world.result ~= nil then
                return world.result
            end
            return nil, world.reason
        end,
    }
    local said, errors = {}, {}
    local game = module.game
    local saved = {}
    for key, value in pairs(game) do
        saved[key] = value
    end
    local savedSpeak, savedNotify, savedErrorHandler = WowVision.speak, WowVision.notify, geterrorhandler
    game.api = function()
        return world.api
    end
    game.rolls = function()
        return world.rolls
    end
    game.itemName = function(link)
        return world.names[link]
    end
    game.requestItem = function(link)
        tinsert(world.requested, link)
    end
    game.after = function(seconds, func)
        tinsert(world.timers, { seconds = seconds, func = func })
    end
    game.locale = function()
        return world.locale
    end
    WowVision.speak = function(_, text)
        tinsert(said, text)
    end
    WowVision.notify = function(_, text)
        tinsert(said, text)
    end
    geterrorhandler = function()
        return function(err)
            tinsert(errors, tostring(err))
        end
    end
    local function runTimers()
        local waiting = world.timers
        world.timers = {}
        for _, timer in ipairs(waiting) do
            timer.func()
        end
    end
    local ok, err = pcall(test, world, said, runTimers, errors)
    for key, value in pairs(saved) do
        game[key] = value
    end
    WowVision.speak, WowVision.notify, geterrorhandler = savedSpeak, savedNotify, savedErrorHandler
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("GearJudge", {
    ["without Sharpie's Gear Judge there is no module and no key"] = function(t)
        local other, nothing = harness.load({})
        t:assertNil(other)
        t:assertEqual(#nothing.bindings, 0)
        local none = harness.load(nil)
        t:assertNil(none)
    end,

    ["the addon is found whatever the case of its folder name"] = function(t)
        local other = harness.load({ sharpiesgearjudge = true })
        t:assertNotNil(other)
    end,

    ["the keys are Alt+Ctrl+J for the first roll and none for all of them"] = function(t)
        t:assertEqual(binding("loot/gearJudge").inputs[1], "ALT-CTRL-J")
        t:assertEqual(#binding("loot/gearJudgeAll").inputs, 0)
    end,

    ["the key says the item and the upgrade it is"] = function(t)
        withRolls(function(world, said)
            binding("loot/gearJudge").func()
            t:assertEqual(said[1], "Gold Band, upgrade of 4.2 percent, instead of Old Ring")
        end)
    end,

    ["a downgrade is said without a minus sign and with a decimal comma where it is read"] = function(t)
        withRolls(function(world, said)
            world.locale = "frFR"
            world.result = { upgradePct = -12.55, equippedLink = OLD }
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, downgrade of 12,6 percent, instead of Old Ring")
        end)
    end,

    ["a whole percentage has no decimal and a rounded zero is no change"] = function(t)
        withRolls(function(world, said)
            world.result = { upgradePct = 3, equippedLink = OLD }
            module:sayFirst()
            world.result = { upgradePct = -0.04, equippedLink = OLD }
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, upgrade of 3 percent, instead of Old Ring")
            t:assertEqual(said[2], "Gold Band, no change, instead of Old Ring")
        end)
    end,

    ["without a percentage the points say which way it goes"] = function(t)
        withRolls(function(world, said)
            world.result = { upgrade = 12 }
            module:sayFirst()
            world.result = { upgrade = -1, upgradePct = 1 / 0 }
            module:sayFirst()
            world.result = { upgrade = 0 }
            module:sayFirst()
            world.result = {}
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, an upgrade, empty slot")
            t:assertEqual(said[2], "Gold Band, a downgrade, empty slot")
            t:assertEqual(said[3], "Gold Band, no change, empty slot")
            t:assertEqual(said[4], "Gold Band, Gear Judge gave no figure")
        end)
    end,

    ["an empty link for the replaced item means the slot is empty"] = function(t)
        withRolls(function(world, said)
            world.result = { upgradePct = 5, equippedLink = "" }
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, upgrade of 5 percent, empty slot")
        end)
    end,

    ["the key takes the first roll window, as the other roll keys do"] = function(t)
        withRolls(function(world, said)
            local other = "|Hitem:7::::|h[Silver Ring]|h"
            world.rolls = { { link = RING }, { link = other } }
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, upgrade of 4.2 percent, instead of Old Ring")
        end)
    end,

    ["an item already worn is said so"] = function(t)
        withRolls(function(world, said)
            world.result = { equipped = true, upgradePct = 0, equippedLink = RING }
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, you already wear it")
        end)
    end,

    ["the replaced item is named from its link when the game has not loaded it"] = function(t)
        withRolls(function(world, said)
            world.names = {}
            world.result = { upgradePct = 1, equippedLink = OLD }
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, upgrade of 1 percent, instead of Old Ring")
        end)
    end,

    ["the Judge's reasons are said in words"] = function(t)
        withRolls(function(world, said)
            local expected = {
                NOT_USABLE = "your class cannot use it",
                NOT_EQUIPPABLE = "it is not equipment",
                NOT_READY = "Gear Judge is not ready yet",
                BAD_LINK = "Gear Judge cannot read that item",
                ERROR = "Gear Judge reported an error",
                SOMETHING_NEW = "Gear Judge reported an error",
            }
            world.result = nil
            for reason, words in pairs(expected) do
                world.reason = reason
                module:sayFirst()
                t:assertEqual(said[#said], "Gold Band, " .. words)
            end
            t:assertEqual(#world.timers, 0)
        end)
    end,

    ["an old or broken Judge and one still loading are said so"] = function(t)
        withRolls(function(world, said, _, errors)
            world.api = {}
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, Gear Judge is too old: version 3.2.7 or later is needed.")
            world.api = nil
            module:sayFirst()
            t:assertEqual(said[2], said[1])
            world.api = {
                IsReady = function()
                    return false
                end,
                ScoreItem = function()
                    error("must not be asked")
                end,
            }
            module:sayFirst()
            t:assertEqual(said[3], "Gold Band, Gear Judge is not ready yet")
            t:assertEqual(#errors, 0)
            world.api = {
                ScoreItem = function()
                    error("boom")
                end,
            }
            module:sayFirst()
            t:assertEqual(said[4], "Gold Band, Gear Judge reported an error")
            t:assertEqual(#errors, 1)
        end)
    end,

    ["an item the game has not loaded is asked for and said when it comes"] = function(t)
        withRolls(function(world, said, runTimers)
            local result = world.result
            world.result, world.reason = nil, "NOT_CACHED"
            module:sayFirst()
            t:assertEqual(said[1], "The item is loading.")
            t:assertEqual(world.requested[1], RING)
            t:assertEqual(world.timers[1].seconds, module.RETRY_DELAY)
            runTimers()
            t:assertEqual(#said, 1)
            world.result = result
            runTimers()
            t:assertEqual(said[2], "Gold Band, upgrade of 4.2 percent, instead of Old Ring")
            t:assertEqual(#world.timers, 0)
            t:assertEqual(#world.requested, 1)
        end)
    end,

    ["after the last retry the reason is said"] = function(t)
        withRolls(function(world, said, runTimers)
            world.result, world.reason = nil, "NOT_CACHED"
            module:sayFirst()
            for _ = 1, module.RETRIES do
                runTimers()
            end
            t:assertEqual(said[2], "Gold Band, the item is not loaded yet")
            t:assertEqual(#world.timers, 0)
        end)
    end,

    ["a new press ends the retries of the one before"] = function(t)
        withRolls(function(world, said, runTimers)
            local result = world.result
            world.result, world.reason = nil, "NOT_CACHED"
            module:sayFirst()
            world.result = result
            module:sayFirst()
            runTimers()
            t:assertEqual(#said, 2)
        end)
    end,

    ["a roll without a link says the Judge cannot read it"] = function(t)
        withRolls(function(world, said)
            world.rolls = { { name = "Gold Band" } }
            module:sayFirst()
            t:assertEqual(said[1], "Gold Band, Gear Judge cannot read that item")
        end)
    end,

    ["without a roll the keys say there is no loot"] = function(t)
        withRolls(function(world, said)
            world.rolls = {}
            binding("loot/gearJudge").func()
            binding("loot/gearJudgeAll").func()
            t:assertEqual(said[1], "No loot.")
            t:assertEqual(said[2], "No loot.")
        end)
    end,

    ["the key for all rolls says each item, numbered"] = function(t)
        withRolls(function(world, said)
            local other = "|Hitem:7::::|h[Silver Ring]|h"
            world.rolls = { { link = RING }, { link = other } }
            world.names[other] = "Silver Ring"
            binding("loot/gearJudgeAll").func()
            t:assertEqual(
                said[1],
                "Item 1 of 2, Gold Band, upgrade of 4.2 percent, instead of Old Ring. "
                    .. "Item 2 of 2, Silver Ring, upgrade of 4.2 percent, instead of Old Ring"
            )
        end)
    end,

    ["the key for all rolls asks the game for the items it has not loaded"] = function(t)
        withRolls(function(world, said)
            world.result, world.reason = nil, "NOT_CACHED"
            module:sayAll()
            t:assertEqual(world.requested[1], RING)
            t:assertEqual(said[1], "Item 1 of 1, Gold Band, the item is not loaded yet")
        end)
    end,

    ["the game's roll windows are read first to last, skipping hidden ones and hidden values"] = function(t)
        local saved = { GroupLootFrame1, GroupLootFrame2, GroupLootFrame3, GetLootRollItemLink, issecretvalue }
        local secretLink = "secret"
        local function frame(visible, rollID, name)
            return {
                rollID = rollID,
                IsVisible = function()
                    return visible
                end,
                Name = {
                    GetText = function()
                        return name
                    end,
                },
            }
        end
        GroupLootFrame1 = frame(false, 1, "Hidden")
        GroupLootFrame2 = frame(true, 2, "Second")
        GroupLootFrame3 = frame(true, 3, "Third")
        GetLootRollItemLink = function(rollID)
            if rollID == 3 then
                return secretLink
            end
            return "link" .. rollID
        end
        issecretvalue = function(value)
            return value == secretLink or value == "Third"
        end
        local ok, err = pcall(function()
            local rolls = module.game.rolls()
            t:assertEqual(#rolls, 2)
            t:assertEqual(rolls[1].link, "link2")
            t:assertEqual(rolls[1].name, "Second")
            t:assertNil(rolls[2].link)
            t:assertNil(rolls[2].name)
        end)
        GroupLootFrame1, GroupLootFrame2, GroupLootFrame3, GetLootRollItemLink, issecretvalue =
            saved[1], saved[2], saved[3], saved[4], saved[5]
        if not ok then
            error(err, 0)
        end
    end,
})
