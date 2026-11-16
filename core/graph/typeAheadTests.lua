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

    ["a typed umlaut finds that umlaut only; the base letter finds both"] = function(t)
        t:assertEqual(typeAhead.typed("Ü"), "ü")
        t:assertEqual(typeAhead.typed("ß"), "ß")
        t:assertEqual(typeAhead.typed("É"), "e", "other accents are no keys of their own")
        t:assertEqual(typeAhead.exactText("1. Übersicht"), "übersicht")
        local names = { "Ultra", "Übersicht", "Uhr" }
        local exact, folded = {}, {}
        for i, name in ipairs(names) do
            exact[i] = typeAhead.matcher("ü")(name)
            folded[i] = typeAhead.matcher("u")(name)
        end
        t:assertEqual(typeAhead.find(exact, 1, "ü", true), 2)
        t:assertEqual(typeAhead.find(exact, 2, "ü", true), 2, "the only Ü")
        t:assertEqual(typeAhead.find(folded, 1, "u", true), 2, "U still finds it")
        t:assertTrue(typeAhead.contains(typeAhead.matcher("mü")("Müller"), "mü"))
        t:assertFalse(typeAhead.contains(typeAhead.matcher("mü")("Mutter"), "mü"))
        t:assertTrue(typeAhead.contains(typeAhead.matcher("straß")("Straße"), "straß"))
    end,

    ["an umlaut repeated quickly keeps cycling, and adds to a text like any letter"] = function(t)
        local state = typeAhead.newState()
        typeAhead.feed(state, "Ü", 1)
        local text, cycle = typeAhead.feed(state, "ü", 1.1)
        t:assertEqual(text, "ü")
        t:assertTrue(cycle)
        state = typeAhead.newState()
        typeAhead.feed(state, "M", 1)
        text, cycle = typeAhead.feed(state, "ü", 1.1)
        t:assertEqual(text, "mü")
        t:assertFalse(cycle)
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

    ["a list of rows (key bindings): letters find a row by its name, home and end go to the first and last row"] = function(t)
        local graph = WowVision.graph
        local sid = graph.ControlId.structural
        local state = graph.newState()
        -- one row per binding: its keys, then Add; a binding without keys has Add alone
        local bindings = {
            { key = "next", label = "Next Item", inputs = { "TAB" } },
            { key = "scanner", label = "Scanner", inputs = { "F9", "CTRL-F9" } },
            { key = "soft", label = "Soft Target Enemy", inputs = {} },
            { key = "nav", label = "Navigation", inputs = { "F10" } },
        }
        local kg = graph.KeyGraph:new(function()
            local b = graph.Builder:new(state.expanded)
            b:pushContext("bindings", "Bindings")
            for _, binding in ipairs(bindings) do
                b:pushContext("binding:" .. binding.key, binding.label)
                b:startRow()
                for _, input in ipairs(binding.inputs) do
                    b:addLabel(sid(binding.key .. ":" .. input), input)
                end
                b:addLabel(sid(binding.key .. ":add"), "Add")
                b:endRow()
                b:popContext()
            end
            b:popContext()
            return b:build()
        end, state)

        kg:focus(sid("scanner:CTRL-F9"))
        local move = kg:moveToText("n", true, true)
        t:assertTrue(move.moved)
        t:assertEqual(move.to.id.key, "nav:F10", "the next binding named N, on its first key")
        move = kg:moveToText("n", true, true)
        t:assertEqual(move.to.id.key, "next:TAB", "wrapped around to Next Item")
        move = kg:moveToText("so", false, true)
        t:assertEqual(move.to.id.key, "soft:add", "a binding without keys lands on Add")
        move = kg:moveToText("a", true, true)
        t:assertFalse(move.found, "the button labels (Add) are not what a row is found by")
        -- without the list of rows, the letters stay in the row, as before
        kg:focus(sid("scanner:F9"))
        move = kg:moveToText("a", true, false)
        t:assertEqual(move.to.id.key, "scanner:add")

        kg:focus(sid("scanner:CTRL-F9"))
        move = kg:moveToRowEdge(false)
        t:assertTrue(move.moved)
        t:assertEqual(move.to.id.key, "nav:F10", "End: the last binding")
        move = kg:moveToRowEdge(true)
        t:assertEqual(move.to.id.key, "next:TAB", "Home: the first binding")
        move = kg:moveToRowEdge(true)
        t:assertFalse(move.moved, "already there")
        kg:focus(sid("soft:add"))
        t:assertEqual(kg:moveToRowEdge(false).to.id.key, "nav:F10")
    end,

    ["a filter text is found anywhere in a label"] = function(t)
        t:assertTrue(typeAhead.contains(typeAhead.matchText("Stormwind Harbor"), "wind"))
        t:assertTrue(typeAhead.contains(typeAhead.matchText("Übersicht"), typeAhead.fold("ÜB")))
        t:assertFalse(typeAhead.contains(typeAhead.matchText("Stormwind"), "hafen"))
        t:assertFalse(typeAhead.contains("anything", ""), "no text keeps nothing")
    end,

    ["a filtered column keeps the matches under a Filter line and leaves other stops alone"] = function(t)
        local graph = WowVision.graph
        local sid = graph.ControlId.structural
        local state = graph.newState()
        local filter
        local kg = graph.KeyGraph:new(function()
            local b = graph.Builder:new(state.expanded)
            b.listFilter = filter
            b:beginStop("list")
            b:addLabel(sid("elwynn"), "Elwynn Forest"):addLabel(sid("barrens"), "The Barrens")
            b:addLabel(sid("feralas"), "|cff00ff00Darkshore|r"):addLabel(sid("durotar"), "Mulgore")
            b:beginStop("refresh")
            b:addLabel(sid("refresh"), "Refresh")
            return b:build()
        end, state)
        kg:focus(sid("barrens"))
        filter = kg:filterScope(false)
        t:assertEqual(filter.stopKey, "list")

        filter.text = "ar"
        state.nextSuggestedMove = graph.LIST_FILTER_ID
        t:assertTrue(kg:rerender())
        t:assertEqual(filter.matches, 2)
        local header = kg:currentNode()
        t:assertEqual(header.id.key, graph.LIST_FILTER_ID.key, "focus lands on the Filter line")
        t:assertEqual(header.positionCount, 3, "the line and two matches")
        t:assertEqual(filter.firstId.key, "elwynn")
        t:assertEqual(kg:move("down").to.id.key, "barrens")
        t:assertEqual(kg:move("down").to.id.key, "feralas", "colour codes do not count")
        t:assertFalse(kg:move("down").moved, "the last match ends the list")
        t:assertNil(kg.current:nodeAt(sid("elwynn")), "no match, no node")
        t:assertTrue(kg.current:nodeAt(sid("refresh")) ~= nil, "another stop stays")

        filter.text = "zzz"
        state.nextSuggestedMove = graph.LIST_FILTER_ID
        t:assertTrue(kg:rerender(), "the Filter line keeps the list alive")
        t:assertEqual(filter.matches, 0)
        t:assertEqual(kg:currentNode().id.key, graph.LIST_FILTER_ID.key)

        filter = nil
        state.nextSuggestedMove = sid("elwynn")
        t:assertTrue(kg:rerender())
        t:assertEqual(kg:currentNode().id.key, "elwynn", "the whole list is back")
        t:assertTrue(kg.current:nodeAt(sid("durotar")) ~= nil)
    end,

    ["a filtered tree level keeps its own entries and takes a dropped group's children along"] = function(t)
        local graph = WowVision.graph
        local sid = graph.ControlId.structural
        local state = graph.newState()
        state.expanded["azeroth"] = true
        state.expanded["kalimdor"] = true
        local filter
        local group = { announcements = { { text = "" } } }
        local function header(label)
            return { announcements = { { text = label, kind = graph.kinds.label } }, onActivate = group.none }
        end
        local kg = graph.KeyGraph:new(function()
            local b = graph.Builder:new(state.expanded)
            b.listFilter = filter
            b:pushContext("root", "Root")
            b:beginGroup(sid("azeroth"), header("Azeroth"))
            b:addLabel(sid("elwynn"), "Elwynn"):addLabel(sid("duskwood"), "Duskwood")
            b:endGroup()
            b:beginGroup(sid("kalimdor"), header("Kalimdor"))
            b:addLabel(sid("durotar"), "Durotar")
            b:endGroup()
            b:popContext()
            return b:build()
        end, state)
        t:assertTrue(kg:rerender())
        kg:focus(sid("azeroth"))
        filter = kg:filterScope(false)
        t:assertTrue(filter.tree)
        filter.text = "ka"
        t:assertTrue(kg:rerender())
        t:assertNil(kg.current:nodeAt(sid("azeroth")))
        t:assertNil(kg.current:nodeAt(sid("elwynn")), "a dropped group's children go with it")
        t:assertTrue(kg.current:nodeAt(sid("durotar")) ~= nil, "a kept group keeps its children")

        filter = nil
        t:assertTrue(kg:rerender())
        kg:focus(sid("elwynn"))
        filter = kg:filterScope(false)
        filter.text = "du"
        t:assertTrue(kg:rerender())
        t:assertNil(kg.current:nodeAt(sid("elwynn")), "one level inside a group")
        t:assertTrue(kg.current:nodeAt(sid("duskwood")) ~= nil)
        t:assertTrue(kg.current:nodeAt(sid("durotar")) ~= nil, "another group's level is not filtered")
    end,

    ["a list of rows filters by the row's name; a lone row is searched, not filtered"] = function(t)
        local graph = WowVision.graph
        local sid = graph.ControlId.structural
        local state = graph.newState()
        local filter
        local kg = graph.KeyGraph:new(function()
            local b = graph.Builder:new(state.expanded)
            b.listFilter = filter
            for _, binding in ipairs({ { "scanner", "Scanner" }, { "nav", "Navigation" } }) do
                b:pushContext("binding:" .. binding[1], binding[2])
                b:startRow()
                b:addLabel(sid(binding[1] .. ":key"), "F9")
                b:addLabel(sid(binding[1] .. ":add"), "Add")
                b:endRow()
                b:popContext()
            end
            return b:build()
        end, state)
        t:assertTrue(kg:rerender())
        kg:focus(sid("scanner:key"))
        t:assertNil(kg:filterScope(false), "letters stay in the row, nothing to filter")
        filter = kg:filterScope(true)
        filter.text = "avi"
        t:assertTrue(kg:rerender())
        t:assertEqual(filter.matches, 1)
        t:assertNil(kg.current:nodeAt(sid("scanner:add")), "the whole row goes")
        t:assertTrue(kg.current:nodeAt(sid("nav:add")) ~= nil)
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
