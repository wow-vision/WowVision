local testRunner = WowVision.testing.testRunner
local utils = WowVision.utils

-- UTF-8 bytes, written as escapes so the file stays ASCII.
local A_UML, a_uml = "\195\132", "\195\164"
local O_UML, o_uml = "\195\150", "\195\182"
local U_UML, u_uml = "\195\156", "\195\188"
local E_ACUTE, e_acute = "\195\137", "\195\169"
local SHARP_S = "\195\159"
local TIMES = "\195\151"
local OE, oe = "\197\146", "\197\147"

testRunner:addSuite("GroupUnits", {
    ["alone: you and your pet"] = function(t)
        local units = utils.groupUnits(false, false)
        t:assertEqual(table.concat(units, ","), "player,pet")
    end,

    ["in a party you come first, then the four others and their pets"] = function(t)
        local units = utils.groupUnits(false, true)
        t:assertEqual(#units, 10)
        t:assertEqual(units[1], "player")
        t:assertEqual(units[3], "party1")
        t:assertEqual(units[4], "partypet1")
        t:assertEqual(units[10], "partypet4")
    end,

    ["in a raid the forty raid units and their pets follow you"] = function(t)
        local units = utils.groupUnits(true, true)
        t:assertEqual(#units, 82)
        t:assertEqual(units[3], "raid1")
        t:assertEqual(units[4], "raidpet1")
    end,
})

-- The game reads for utils.groupFighting: a party of you and party1 (with
-- partypet1) fighting "target", each read overridable.
local function fight(overrides)
    local exists = { player = true, party1 = true, partypet1 = true, target = true }
    local api = {
        IsInRaid = function()
            return false
        end,
        IsInGroup = function()
            return true
        end,
        UnitExists = function(unit)
            return exists[unit] == true
        end,
        UnitThreatSituation = function()
            return nil
        end,
        UnitIsUnit = function(a, b)
            return a == b
        end,
        UnitAffectingCombat = function()
            return false
        end,
        UnitCanAttack = function()
            return true
        end,
        UnitIsTapDenied = function()
            return false
        end,
    }
    for key, value in pairs(overrides or {}) do
        api[key] = value
    end
    api.exists = exists
    return api
end

testRunner:addSuite("GroupFighting", {
    ["a mob nobody fights is no fight"] = function(t)
        t:assertFalse(utils.groupFighting("target", fight()))
    end,

    ["you on its threat list is a fight"] = function(t)
        t:assertTrue(utils.groupFighting("target", fight({
            UnitThreatSituation = function(member)
                return member == "player" and 1 or nil
            end,
        })))
    end,

    ["a group member's pet on its threat list is a fight"] = function(t)
        t:assertTrue(utils.groupFighting("target", fight({
            UnitThreatSituation = function(member)
                return member == "partypet1" and 0 or nil
            end,
        })))
    end,

    ["it attacking a group member is a fight, before any threat is known"] = function(t)
        local api = fight({
            UnitIsUnit = function(a, b)
                return a == "targettarget" and b == "party1"
            end,
        })
        api.exists.targettarget = true
        t:assertTrue(utils.groupFighting("target", api))
    end,

    ["in a group: in combat and tapped by nobody else is the group's fight"] = function(t)
        t:assertTrue(utils.groupFighting("target", fight({
            UnitAffectingCombat = function(unit)
                return unit == "target"
            end,
        })))
    end,

    ["in combat but tapped by someone else is not ours"] = function(t)
        t:assertFalse(utils.groupFighting("target", fight({
            UnitAffectingCombat = function()
                return true
            end,
            UnitIsTapDenied = function()
                return true
            end,
        })))
    end,

    ["alone, a mob in combat with a stranger is not yours"] = function(t)
        t:assertFalse(utils.groupFighting("target", fight({
            IsInGroup = function()
                return false
            end,
            UnitAffectingCombat = function()
                return true
            end,
        })))
    end,

    ["a friendly unit in combat is not a fight to announce"] = function(t)
        t:assertFalse(utils.groupFighting("target", fight({
            UnitAffectingCombat = function()
                return true
            end,
            UnitCanAttack = function()
                return false
            end,
        })))
    end,

    ["targeting yourself is no fight, though your target's target is you"] = function(t)
        local api = fight({
            UnitIsUnit = function(a, b)
                return a == "targettarget" and b == "player"
            end,
            UnitCanAttack = function()
                return false
            end,
        })
        api.exists.targettarget = true
        t:assertFalse(utils.groupFighting("target", api))
    end,

    ["a group member who targets you is no fight"] = function(t)
        local api = fight({
            UnitIsUnit = function(a, b)
                return a == "targettarget" and b == "player"
            end,
            UnitThreatSituation = function()
                return 0
            end,
            UnitAffectingCombat = function()
                return true
            end,
            UnitCanAttack = function()
                return false
            end,
        })
        api.exists.targettarget = true
        t:assertFalse(utils.groupFighting("target", api))
    end,

    ["a read that fails counts as no"] = function(t)
        t:assertFalse(utils.groupFighting("target", fight({
            UnitAffectingCombat = function()
                error("hidden")
            end,
        })))
    end,

    ["no target, no fight"] = function(t)
        local api = fight()
        api.exists.target = nil
        t:assertFalse(utils.groupFighting("target", api))
    end,
})

-- A stand-in for C_CurrencyInfo.GetCoinText.
local function coins(copper)
    local parts = {}
    local gold, silver, copperLeft = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    if gold > 0 then
        tinsert(parts, gold .. " Gold")
    end
    if silver > 0 then
        tinsert(parts, silver .. " Silver")
    end
    if copperLeft > 0 or #parts == 0 then
        tinsert(parts, copperLeft .. " Copper")
    end
    return table.concat(parts, ", ")
end

local GOLD = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"
local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"
local COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

testRunner:addSuite("MoneyLineText", {
    ["coin textures become gold, silver and copper"] = function(t)
        local text = "Sell Price: 1 " .. GOLD .. " 23 " .. SILVER .. " 45 " .. COPPER
        t:assertEqual(utils.moneyLineText(text, "Sell Price", coins), "Sell Price: 1 Gold, 23 Silver, 45 Copper")
    end,

    ["a few coins stay copper"] = function(t)
        t:assertEqual(utils.moneyLineText("Sell Price: 7" .. COPPER, "Sell Price", coins), "Sell Price: 7 Copper")
    end,

    ["coin atlases count too"] = function(t)
        local text = "Repair 2|A:coin-gold:0:0|a 5|A:coin-silver:0:0|a"
        t:assertEqual(utils.moneyLineText(text, "Sell Price", coins), "Repair 2 Gold, 5 Silver")
    end,

    ["a bare number after the sell price label is copper"] = function(t)
        t:assertEqual(utils.moneyLineText("Verkaufspreis: 12345", "Verkaufspreis", coins), "Verkaufspreis: 1 Gold, 23 Silver, 45 Copper")
        t:assertEqual(utils.moneyLineText("Verkaufspreis 1.234", "Verkaufspreis", coins), "Verkaufspreis 12 Silver, 34 Copper")
    end,

    ["a color code around the label does not hide the number"] = function(t)
        t:assertEqual(utils.moneyLineText("|cffffffffSell Price:|r 250", "Sell Price", coins), "Sell Price: 2 Silver, 50 Copper")
    end,

    ["lines without money stay as they are"] = function(t)
        t:assertEqual(utils.moneyLineText("Durability 50 / 50", "Sell Price", coins), nil)
        t:assertEqual(utils.moneyLineText("Item Level 12", "Sell Price", coins), nil)
        t:assertEqual(utils.moneyLineText("|TInterface\\Icons\\Spell_Holy:0|t Holy", "Sell Price", coins), nil)
        t:assertEqual(utils.moneyLineText(nil, "Sell Price", coins), nil)
    end,
})

testRunner:addSuite("FoldCase", {
    ["ASCII lowers as before"] = function(t)
        t:assertEqual(utils.foldCase("The Deadmines;285"), "the deadmines;285")
        t:assertEqual(utils.foldCase(""), "")
    end,

    ["capital umlauts fold to their small forms"] = function(t)
        t:assertEqual(utils.foldCase(A_UML .. "ther"), a_uml .. "ther")
        t:assertEqual(utils.foldCase(O_UML .. "dland"), o_uml .. "dland")
        t:assertEqual(utils.foldCase(U_UML .. "BER"), u_uml .. "ber")
    end,

    ["French accented capitals and the ligature fold"] = function(t)
        t:assertEqual(utils.foldCase(E_ACUTE .. "cole"), e_acute .. "cole")
        t:assertEqual(utils.foldCase(OE .. "il"), oe .. "il")
    end,

    ["small forms, sharp s and the times sign are untouched"] = function(t)
        local text = a_uml .. o_uml .. u_uml .. SHARP_S .. TIMES
        t:assertEqual(utils.foldCase(text), text)
    end,

    ["a search typed in small letters finds a capitalised name"] = function(t)
        local name = utils.foldCase("zentralpunkt;" .. O_UML .. "dland;" .. U_UML .. "berwald")
        t:assertNotNil(name:find(utils.foldCase(o_uml .. "dland"), 1, true))
        t:assertNotNil(name:find(utils.foldCase(U_UML .. "BERWALD"), 1, true))
        t:assertNil(name:find(utils.foldCase("odland"), 1, true), "accents are kept")
    end,
})

-- utils.guardedCall with the game's error handler swapped for a recorder.
local function withRecorder(body)
    local reported = {}
    local saved = geterrorhandler
    geterrorhandler = function()
        return function(message)
            tinsert(reported, tostring(message))
        end
    end
    local ok, err = pcall(body)
    geterrorhandler = saved
    if not ok then
        error(err, 0)
    end
    return reported
end

testRunner:addSuite("GuardedCall", {
    ["a call that works returns its results"] = function(t)
        local ok, a, b = utils.guardedCall({}, function(x, y)
            return x + y, "done"
        end, 1, 2)
        t:assertTrue(ok)
        t:assertEqual(a, 3)
        t:assertEqual(b, "done")
    end,

    ["an error is caught and reported once per part and message"] = function(t)
        local part = {}
        local reported = withRecorder(function()
            for _ = 1, 5 do
                t:assertFalse(utils.guardedCall(part, error, "same", 0))
            end
        end)
        t:assertEqual(#reported, 1)
        t:assertEqual(reported[1], "same")
    end,

    ["two errors that take turns are each reported once"] = function(t)
        local part = {}
        local reported = withRecorder(function()
            for frame = 1, 6 do
                utils.guardedCall(part, error, frame % 2 == 0 and "x" or "y", 0)
            end
        end)
        t:assertEqual(table.concat(reported, ","), "y,x")
    end,

    ["the same message from another part is reported again"] = function(t)
        local reported = withRecorder(function()
            utils.guardedCall({}, error, "same", 0)
            utils.guardedCall({}, error, "same", 0)
        end)
        t:assertEqual(#reported, 2)
    end,
})

local TAP_SECRET = {}
local function tapSecret(value)
    return value == TAP_SECRET
end

testRunner:addSuite("GroupTapped", {
    ["in combat and tapped by nobody else is the group's fight"] = function(t)
        t:assertTrue(utils.groupTapped(true, false, tapSecret))
        t:assertTrue(utils.groupTapped(1, false, tapSecret), "1 means in combat")
    end,

    ["out of combat or tapped by others is not"] = function(t)
        t:assertFalse(utils.groupTapped(false, false, tapSecret))
        t:assertFalse(utils.groupTapped(true, true, tapSecret))
    end,

    ["a missing or secret answer counts as no"] = function(t)
        t:assertFalse(utils.groupTapped(true, nil, tapSecret))
        t:assertFalse(utils.groupTapped(nil, false, tapSecret))
        t:assertFalse(utils.groupTapped(TAP_SECRET, false, tapSecret))
        t:assertFalse(utils.groupTapped(true, TAP_SECRET, tapSecret))
    end,
})
