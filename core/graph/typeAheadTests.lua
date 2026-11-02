local testRunner = WowVision.testing.testRunner
local typeAhead = WowVision.graph.typeAhead

local function texts(list)
    local out = {}
    for i, label in ipairs(list) do
        out[i] = typeAhead.matchText(label)
    end
    return out
end

testRunner:addSuite("TypeAhead", {
    ["labels are matched without escape codes, accents, case or leading punctuation"] = function(t)
        t:assertEqual(typeAhead.matchText("|cffff0000Rot|r Option"), "rot option")
        t:assertEqual(typeAhead.matchText("|TInterface\\Icons\\Spell:0|t Feuerball"), "feuerball")
        t:assertEqual(typeAhead.matchText("1. Übersicht"), "ubersicht")
        t:assertEqual(typeAhead.matchText("  (Écran) "), "ecran) ")
        t:assertEqual(typeAhead.matchText("Straße"), "strasse")
        t:assertEqual(typeAhead.matchText("123"), "")
        t:assertEqual(typeAhead.matchText(nil), "")
    end,

    ["a letter goes to the next entry starting with it, wrapping around"] = function(t)
        local labels = texts({ "Alerts", "Buffers", "Bindings", "Chat", "Buttons" })
        t:assertEqual(typeAhead.find(labels, 1, "b", true), 2)
        t:assertEqual(typeAhead.find(labels, 2, "b", true), 3)
        t:assertEqual(typeAhead.find(labels, 3, "b", true), 5)
        t:assertEqual(typeAhead.find(labels, 5, "b", true), 2, "after the last match: the first again")
        t:assertEqual(typeAhead.find(labels, 4, "c", true), 4, "the only match is the current entry")
        t:assertNil(typeAhead.find(labels, 1, "z", true), "nothing starts with z")
        t:assertNil(typeAhead.find({}, 0, "a", true))
    end,

    ["an umlaut key and its base letter find the same entries"] = function(t)
        local labels = texts({ "Allgemein", "Übersicht", "Ultra" })
        t:assertEqual(typeAhead.find(labels, 1, typeAhead.fold("Ü"), true), 2)
        t:assertEqual(typeAhead.find(labels, 2, "u", true), 3)
    end,

    ["letters typed quickly are one search text, the current entry still counting"] = function(t)
        local state = typeAhead.newState()
        local text, cycle = typeAhead.feed(state, "G", 10)
        t:assertEqual(text, "g")
        t:assertTrue(cycle)
        text, cycle = typeAhead.feed(state, "o", 10.2)
        t:assertEqual(text, "go")
        t:assertFalse(cycle)
        local labels = texts({ "Gnome", "Goldshire", "Grand" })
        t:assertEqual(typeAhead.find(labels, 2, "go", false), 2, "staying on Goldshire")
        text = typeAhead.feed(state, "l", 10.4)
        t:assertEqual(text, "gol")
        -- after a pause a letter starts anew
        text, cycle = typeAhead.feed(state, "g", 11.5)
        t:assertEqual(text, "g")
        t:assertTrue(cycle)
    end,

    ["the key graph moves within the focused list only"] = function(t)
        local graph = WowVision.graph
        local sid = graph.ControlId.structural
        local state = graph.newState()
        local kg = graph.KeyGraph:new(function()
            local b = graph.Builder:new(state.expanded)
            b:beginStop("search"):addLabel(sid("search"), "Bindings search")
            b:beginStop("list")
            b:addLabel(sid("alerts"), "Alerts"):addLabel(sid("buffers"), "Buffers"):addLabel(sid("chat"), "Chat")
            b:addLabel(sid("bars"), "|cff00ff00Bars|r")
            return b:build()
        end, state)
        kg:focus(sid("alerts"))
        local move = kg:moveToText("b", true)
        t:assertTrue(move.moved)
        t:assertEqual(move.to.id.key, "buffers", "not the search box of the other stop")
        move = kg:moveToText("b", true)
        t:assertEqual(move.to.id.key, "bars", "colour codes do not count")
        move = kg:moveToText("b", true)
        t:assertEqual(move.to.id.key, "buffers", "wrapped around")
        move = kg:moveToText("z", true)
        t:assertFalse(move.found)
        t:assertFalse(move.moved)
        t:assertEqual(kg:currentNode().id.key, "buffers", "focus stays")
        move = kg:moveToText("bu", false)
        t:assertTrue(move.found)
        t:assertFalse(move.moved, "the focused entry still matches a growing text")
    end,

    ["the same letter typed quickly keeps cycling"] = function(t)
        local state = typeAhead.newState()
        typeAhead.feed(state, "b", 1)
        local text, cycle = typeAhead.feed(state, "b", 1.1)
        t:assertEqual(text, "b")
        t:assertTrue(cycle)
        text, cycle = typeAhead.feed(state, "B", 1.2)
        t:assertEqual(text, "b")
        t:assertTrue(cycle)
    end,
})
