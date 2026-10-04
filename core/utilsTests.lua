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
