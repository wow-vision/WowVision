local testRunner = WowVision.testing.testRunner
local graph = WowVision.graph
local ControlId = graph.ControlId
local Builder = graph.Builder
local KeyGraph = graph.KeyGraph
local announcer = graph.announcer

local function vt(label)
    return { announcements = { { text = label } } }
end

local function sid(key)
    return ControlId.structural(key)
end

-- A KeyGraph over a build function; the function receives a fresh builder each
-- rebuild and must return builder:build().
local function makeGraph(buildFn)
    local state = graph.newState()
    local kg = KeyGraph:new(function()
        return buildFn(Builder:new(state.expanded))
    end, state)
    return kg, state
end

-- Announcer hooks are global; set them for one test and always restore.
local function withAnnouncerHooks(hooks, fn)
    local saved = {
        partFilter = announcer.partFilter,
        positionText = announcer.positionText,
        expandedStateText = announcer.expandedStateText,
    }
    announcer.partFilter = hooks.partFilter
    announcer.positionText = hooks.positionText
    announcer.expandedStateText = hooks.expandedStateText
    local ok, err = pcall(fn)
    announcer.partFilter = saved.partFilter
    announcer.positionText = saved.positionText
    announcer.expandedStateText = saved.expandedStateText
    if not ok then
        error(err, 0)
    end
end

local function positionText(index, count)
    return index .. " of " .. count
end

--
-- Builder tests
--

testRunner:addSuite("GraphBuilder", {
    ["menu items wire vertically"] = function(t)
        local b = Builder:new()
        b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B"):addLabel(sid("c"), "C")
        local render = b:build()
        t:assertEqual(render.nodes["a"].transitions.down.destination.key, "b")
        t:assertEqual(render.nodes["b"].transitions.up.destination.key, "a")
        t:assertEqual(render.nodes["b"].transitions.down.destination.key, "c")
        t:assertNil(render.nodes["a"].transitions.up)
        t:assertNil(render.nodes["c"].transitions.down)
    end,

    ["row items wire horizontally"] = function(t)
        local b = Builder:new()
        b:startRow():addLabel(sid("a"), "A"):addLabel(sid("b"), "B"):addLabel(sid("c"), "C"):endRow()
        local render = b:build()
        t:assertEqual(render.nodes["a"].transitions.right.destination.key, "b")
        t:assertEqual(render.nodes["c"].transitions.left.destination.key, "b")
        t:assertNil(render.nodes["a"].transitions.left)
        t:assertNil(render.nodes["a"].transitions.down)
    end,

    ["shared row keys preserve the column"] = function(t)
        local b = Builder:new()
        b:startRow("k"):addLabel(sid("a1"), "A1"):addLabel(sid("a2"), "A2"):endRow()
        b:startRow("k"):addLabel(sid("b1"), "B1"):addLabel(sid("b2"), "B2"):endRow()
        local render = b:build()
        t:assertEqual(render.nodes["a2"].transitions.down.destination.key, "b2")
        t:assertEqual(render.nodes["b2"].transitions.up.destination.key, "a2")
    end,

    ["unkeyed rows land on the first item"] = function(t)
        local b = Builder:new()
        b:startRow():addLabel(sid("a1"), "A1"):addLabel(sid("a2"), "A2"):endRow()
        b:startRow():addLabel(sid("b1"), "B1"):addLabel(sid("b2"), "B2"):endRow()
        local render = b:build()
        t:assertEqual(render.nodes["a2"].transitions.down.destination.key, "b1")
    end,

    ["arrows do not cross stops"] = function(t)
        local b = Builder:new()
        b:addLabel(sid("a"), "A")
        b:beginStop()
        b:addLabel(sid("b"), "B")
        local render = b:build()
        t:assertNil(render.nodes["a"].transitions.down)
        t:assertNil(render.nodes["b"].transitions.up)
    end,

    ["duplicate ids error"] = function(t)
        local b = Builder:new()
        b:addLabel(sid("a"), "A")
        t:assertError(function()
            b:addLabel(sid("a"), "A again")
        end)
    end,

    ["empty build returns nil"] = function(t)
        t:assertNil(Builder:new():build())
    end,

    ["default start is the first node and setStart wins"] = function(t)
        local b = Builder:new()
        b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B")
        t:assertEqual(b:build().startKey.key, "a")

        local b2 = Builder:new()
        b2:addLabel(sid("a"), "A"):addLabel(sid("b"), "B"):setStart(sid("b"))
        t:assertEqual(b2:build().startKey.key, "b")
    end,

    ["single-item rows stamp positions by parent and stop"] = function(t)
        local b = Builder:new()
        b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B"):addLabel(sid("c"), "C")
        local render = b:build()
        t:assertEqual(render.nodes["a"].positionIndex, 1)
        t:assertEqual(render.nodes["c"].positionIndex, 3)
        t:assertEqual(render.nodes["c"].positionCount, 3)
    end,

    ["a lone item gets no position"] = function(t)
        local b = Builder:new()
        b:addLabel(sid("a"), "A")
        local render = b:build()
        t:assertNil(render.nodes["a"].positionCount)
    end,

    ["multi-item rows stamp within the row"] = function(t)
        local b = Builder:new()
        b:startRow():addLabel(sid("a"), "A"):addLabel(sid("b"), "B"):endRow()
        b:addLabel(sid("c"), "C")
        local render = b:build()
        t:assertEqual(render.nodes["b"].positionIndex, 2)
        t:assertEqual(render.nodes["b"].positionCount, 2)
        -- The single-item row is alone at its (parent, stop) level.
        t:assertNil(render.nodes["c"].positionCount)
    end,

    ["pushContext builds the parent chain"] = function(t)
        local b = Builder:new()
        b:pushContext("categories", "Categories", "list")
        b:addLabel(sid("a"), "A")
        b:popContext()
        b:addLabel(sid("outside"), "Outside")
        local render = b:build()
        local parent = render.nodes["a"].parent
        t:assertNotNil(parent)
        t:assertEqual(parent.focusable, false)
        t:assertEqual(parent.vtable.announcements[1].text, "Categories")
        t:assertEqual(parent.vtable.announcements[2].text, "list")
        t:assertNil(render.nodes[parent.id.key], "context must not be navigable")
        t:assertNil(render.nodes["outside"].parent)
    end,

    ["context children in separate stops share one position group"] = function(t)
        local b = Builder:new()
        b:pushContext("menu", "Menu")
        b:beginStop():addLabel(sid("a"), "A")
        b:beginStop():addLabel(sid("b"), "B")
        b:beginStop():addLabel(sid("c"), "C")
        b:popContext()
        local render = b:build()
        t:assertEqual(render.nodes["a"].positionIndex, 1)
        t:assertEqual(render.nodes["c"].positionIndex, 3)
        t:assertEqual(render.nodes["c"].positionCount, 3)
        t:assertNil(render.nodes["a"].transitions.down, "single-node stops have no arrow edges")
    end,

    ["pushContext can suppress child positions"] = function(t)
        local b = Builder:new()
        b:pushContext("log", "Log", nil, false)
        b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B")
        b:popContext()
        local render = b:build()
        t:assertNil(render.nodes["a"].positionCount)
    end,

    ["collapsed groups suppress their children"] = function(t)
        local expansion = {}
        local b = Builder:new(expansion)
        b:beginGroup(sid("g"), vt("Group"))
        b:addLabel(sid("child"), "Child")
        b:endGroup()
        local render = b:build()
        t:assertNotNil(render.nodes["g"])
        t:assertNil(render.nodes["child"])
        t:assertEqual(render.nodes["g"].expanded, false)

        expansion["g"] = true
        local b2 = Builder:new(expansion)
        b2:beginGroup(sid("g"), vt("Group"))
        b2:addLabel(sid("child"), "Child")
        b2:endGroup()
        local render2 = b2:build()
        t:assertNotNil(render2.nodes["child"])
        t:assertEqual(render2.nodes["g"].expanded, true)
        t:assertEqual(render2.nodes["child"].parent, render2.nodes["g"])
    end,

    ["a collapsed ancestor suppresses nested groups"] = function(t)
        local expansion = { inner = true }
        local b = Builder:new(expansion)
        b:beginGroup(sid("outer"), vt("Outer"))
        b:beginGroup(sid("inner"), vt("Inner"))
        b:addLabel(sid("leaf"), "Leaf")
        b:endGroup()
        b:endGroup()
        local render = b:build()
        t:assertNil(render.nodes["inner"])
        t:assertNil(render.nodes["leaf"])
    end,

    ["raw edges wire and unknown targets drop"] = function(t)
        local b = Builder:new()
        b:addNode(sid("a"), vt("A")):addNode(sid("b"), vt("B"))
        b:connect(sid("a"), "right", sid("b"), "crossing")
        b:connect(sid("a"), "down", sid("missing"))
        local render = b:build()
        t:assertEqual(render.nodes["a"].transitions.right.destination.key, "b")
        t:assertEqual(render.nodes["a"].transitions.right.label, "crossing")
        t:assertNil(render.nodes["a"].transitions.down)
    end,
})

--
-- KeyGraph tests
--

testRunner:addSuite("GraphKeyGraph", {
    ["computeOrder walks down-right"] = function(t)
        local b = Builder:new()
        b:addNode(sid("a"), vt("A")):addNode(sid("b"), vt("B"))
        b:addNode(sid("c"), vt("C")):addNode(sid("d"), vt("D"))
        b:connect(sid("a"), "right", sid("b"))
        b:connect(sid("a"), "down", sid("c"))
        b:connect(sid("c"), "right", sid("d"))
        local render = b:build()
        local order = KeyGraph.computeOrder(render)
        t:assertEqual(order[1].key, "a")
        t:assertEqual(order[2].key, "b")
        t:assertEqual(order[3].key, "c")
        t:assertEqual(order[4].key, "d")
    end,

    ["focus survives rebuild by structural key"] = function(t)
        local kg, state = makeGraph(function(b)
            b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B"):addLabel(sid("c"), "C")
            return b:build()
        end)
        kg:rerender()
        kg:move("down")
        t:assertEqual(state.curKey.key, "b")
        kg:rerender()
        t:assertEqual(state.curKey.key, "b")
    end,

    ["focus follows a moved object by reference"] = function(t)
        local objA, objB = {}, {}
        local swapped = false
        local kg, state = makeGraph(function(b)
            local first = swapped and objB or objA
            local second = swapped and objA or objB
            b:addLabel(ControlId.referenced(first, "slot1"), "First")
            b:addLabel(ControlId.referenced(second, "slot2"), "Second")
            return b:build()
        end)
        kg:rerender()
        t:assertEqual(state.curKey.key, "slot1")
        swapped = true
        kg:rerender()
        t:assertEqual(state.curKey.key, "slot2", "focus should follow objA")
    end,

    ["nearest survivor when the focused node vanishes"] = function(t)
        local keepC = true
        local kg, state = makeGraph(function(b)
            b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B")
            if keepC then
                b:addLabel(sid("c"), "C")
            end
            return b:build()
        end)
        kg:rerender()
        kg:moveToEdge("down")
        t:assertEqual(state.curKey.key, "c")
        keepC = false
        kg:rerender()
        t:assertEqual(state.curKey.key, "b")
    end,

    ["a vanished stop lands on the surviving stop's landing"] = function(t)
        local showB = true
        local kg, state = makeGraph(function(b)
            b:beginStop("a")
            b:addLabel(sid("a1"), "A1"):addLabel(sid("a2"), "A2")
            if showB then
                b:beginStop("b")
                b:addLabel(sid("b1"), "B1"):addLabel(sid("b2"), "B2")
            end
            return b:build()
        end)
        kg:rerender()
        kg:move("next")
        t:assertEqual(state.curKey.key, "b1")
        showB = false
        kg:rerender()
        -- The raw backward walk would land on a2; entering the surviving
        -- stop through its landing returns to its remembered position.
        t:assertEqual(state.curKey.key, "a1")
    end,

    ["a vanished node within a surviving stop lands on its neighbor"] = function(t)
        local showC = true
        local kg, state = makeGraph(function(b)
            b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B")
            if showC then
                b:addLabel(sid("c"), "C")
            end
            return b:build()
        end)
        kg:rerender()
        kg:moveToEdge("down")
        t:assertEqual(state.curKey.key, "c")
        showC = false
        kg:rerender()
        t:assertEqual(state.curKey.key, "b")
    end,

    ["first render lands on the selected member of the start stop"] = function(t)
        local kg, state = makeGraph(function(b)
            b:addLabel(sid("a"), "A")
            b:addItem(sid("b"), {
                announcements = { { text = "B" }, { text = "selected", kind = "selected" } },
            })
            b:addLabel(sid("c"), "C")
            return b:build()
        end)
        kg:rerender()
        t:assertEqual(state.curKey.key, "b")
    end,

    ["move at an edge stays put"] = function(t)
        local kg = makeGraph(function(b)
            b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B")
            return b:build()
        end)
        kg:rerender()
        local result = kg:move("up")
        t:assertFalse(result.moved)
        t:assertEqual(result.to, result.from)
    end,

    ["tab cycles stops and remembers positions"] = function(t)
        local kg, state = makeGraph(function(b)
            b:addLabel(sid("a1"), "A1"):addLabel(sid("a2"), "A2")
            b:beginStop()
            b:addLabel(sid("b1"), "B1"):addLabel(sid("b2"), "B2")
            return b:build()
        end)
        kg:rerender()
        t:assertEqual(state.curKey.key, "a1")
        kg:move("next")
        t:assertEqual(state.curKey.key, "b1")
        kg:move("down")
        t:assertEqual(state.curKey.key, "b2")
        kg:move("next") -- wraps back to stop 1's remembered position
        t:assertEqual(state.curKey.key, "a1")
        kg:move("next") -- returns to stop 2's remembered position
        t:assertEqual(state.curKey.key, "b2")
    end,

    ["tab cycles single-node stops with wrap"] = function(t)
        local kg, state = makeGraph(function(b)
            b:pushContext("menu", "Menu")
            b:beginStop():addLabel(sid("a"), "A")
            b:beginStop():addLabel(sid("b"), "B")
            b:beginStop():addLabel(sid("c"), "C")
            b:popContext()
            return b:build()
        end)
        kg:rerender()
        t:assertEqual(state.curKey.key, "a")
        kg:move("next")
        t:assertEqual(state.curKey.key, "b")
        kg:move("next")
        t:assertEqual(state.curKey.key, "c")
        kg:move("next")
        t:assertEqual(state.curKey.key, "a", "wraps to the first stop")
        kg:move("previous")
        t:assertEqual(state.curKey.key, "c", "wraps backward")
    end,

    ["explicit tab edges override stop cycling"] = function(t)
        local kg, state = makeGraph(function(b)
            b:addLabel(sid("a1"), "A1"):addLabel(sid("a2"), "A2")
            b:beginStop()
            b:addLabel(sid("b1"), "B1")
            b:connect(sid("a1"), "next", sid("a2"))
            return b:build()
        end)
        kg:rerender()
        kg:move("next")
        t:assertEqual(state.curKey.key, "a2")
    end,

    ["nextSuggestedMove is consumed"] = function(t)
        local kg, state = makeGraph(function(b)
            b:addLabel(sid("a"), "A"):addLabel(sid("b"), "B"):addLabel(sid("c"), "C")
            return b:build()
        end)
        kg:rerender()
        state.nextSuggestedMove = sid("c")
        kg:rerender()
        t:assertEqual(state.curKey.key, "c")
        t:assertNil(state.nextSuggestedMove)
    end,

    ["a nil render closes the graph"] = function(t)
        local kg = makeGraph(function()
            return nil
        end)
        t:assertFalse(kg:rerender())
        local result = kg:move("down")
        t:assertFalse(result.moved)
        t:assertNil(result.from)
    end,

    ["focusByReference moves focus"] = function(t)
        local obj = {}
        local kg, state = makeGraph(function(b)
            b:addLabel(sid("a"), "A")
            b:addLabel(ControlId.referenced(obj, "b"), "B")
            return b:build()
        end)
        kg:rerender()
        t:assertTrue(kg:focusByReference(obj))
        t:assertEqual(state.curKey.key, "b")
        t:assertFalse(kg:focusByReference(obj), "already focused: no change")
    end,

    ["tree expand, descend, ascend, collapse"] = function(t)
        local kg, state = makeGraph(function(b)
            b:beginGroup(sid("g"), vt("Group"))
            b:addLabel(sid("c1"), "C1"):addLabel(sid("c2"), "C2")
            b:endGroup()
            return b:build()
        end)
        kg:rerender()
        t:assertEqual(state.curKey.key, "g")

        local result = kg:treeRight()
        t:assertEqual(result.kind, "expanded")
        t:assertEqual(state.expanded["g"], true)
        t:assertEqual(state.curKey.key, "g")

        result = kg:treeRight()
        t:assertEqual(result.kind, "descended")
        t:assertEqual(state.curKey.key, "c1")

        result = kg:treeLeft()
        t:assertEqual(result.kind, "ascended")
        t:assertEqual(state.curKey.key, "g")

        result = kg:treeLeft()
        t:assertEqual(result.kind, "collapsed")
        t:assertNil(state.expanded["g"])
        t:assertEqual(state.curKey.key, "g")
    end,

    ["empty groups auto-recollapse"] = function(t)
        local kg, state = makeGraph(function(b)
            b:beginGroup(sid("g"), vt("Group"))
            b:endGroup()
            return b:build()
        end)
        kg:rerender()
        local result = kg:treeRight()
        t:assertEqual(result.kind, "emptyGroup")
        t:assertNil(state.expanded["g"])
    end,

    ["activate runs the focused control's handler"] = function(t)
        local clicked = false
        local kg = makeGraph(function(b)
            b:addItem(sid("a"), {
                announcements = { { text = "A" } },
                onActivate = function()
                    clicked = true
                end,
            })
            b:addLabel(sid("b"), "B")
            return b:build()
        end)
        kg:rerender()
        t:assertTrue(kg:activate())
        t:assertTrue(clicked)
        kg:move("down")
        t:assertFalse(kg:activate(), "labels have no activation")
    end,
})

--
-- Announcer tests
--

testRunner:addSuite("GraphAnnouncer", {
    ["entering a context reads the path with positions"] = function(t)
        withAnnouncerHooks({ positionText = positionText }, function()
            local kg = makeGraph(function(b)
                b:pushContext("categories", "Categories", "list")
                b:addLabel(sid("combat"), "Combat")
                b:addLabel(sid("general"), "General")
                b:addLabel(sid("audio"), "Audio")
                b:popContext()
                return b:build()
            end)
            kg:rerender()
            local line = announcer.composeFull(kg:currentNode())
            t:assertEqual(line, "Categories, list, Combat, 1 of 3")
        end)
    end,

    ["sibling moves read only the leaf"] = function(t)
        withAnnouncerHooks({ positionText = positionText }, function()
            local kg = makeGraph(function(b)
                b:pushContext("categories", "Categories", "list")
                b:addLabel(sid("combat"), "Combat")
                b:addLabel(sid("general"), "General")
                b:addLabel(sid("audio"), "Audio")
                b:popContext()
                return b:build()
            end)
            kg:rerender()
            local result = kg:move("down")
            local line = announcer.compose(result.from, result.to)
            t:assertEqual(line, "General, 2 of 3")
        end)
    end,

    ["descending into a group reads only the child"] = function(t)
        local kg = makeGraph(function(b)
            b:beginGroup(sid("g"), vt("Section"))
            b:addLabel(sid("c1"), "Child one")
            b:endGroup()
            return b:build()
        end)
        kg:rerender()
        kg:treeRight()
        local result = kg:treeRight()
        t:assertEqual(result.kind, "descended")
        local line = announcer.compose(result.move.from, result.move.to)
        t:assertEqual(line, "Child one")
    end,

    ["ascending reads only the target"] = function(t)
        local kg = makeGraph(function(b)
            b:beginGroup(sid("g"), vt("Section"))
            b:addLabel(sid("c1"), "Child one")
            b:endGroup()
            return b:build()
        end)
        kg:rerender()
        kg:treeRight()
        kg:treeRight()
        local result = kg:treeLeft()
        t:assertEqual(result.kind, "ascended")
        local line = announcer.compose(result.move.from, result.move.to)
        t:assertEqual(line, "Section")
    end,

    ["a row context announces the bar role"] = function(t)
        local kg = makeGraph(function(b)
            b:beginStop("tabs")
            b:pushContext("tabs", "Tabs")
            b:startRow()
            b:addLabel(sid("a"), "Buy"):addLabel(sid("b"), "Sell")
            b:endRow()
            b:popContext()
            return b:build()
        end)
        kg:rerender()
        local line = announcer.composeFull(kg:currentNode())
        t:assertTrue(line:find("Bar") ~= nil, "row context carries the Bar role: " .. line)
    end,

    ["a vertical context announces the list role"] = function(t)
        local kg = makeGraph(function(b)
            b:beginStop("quests")
            b:pushContext("quests", "Quests")
            b:addLabel(sid("a"), "First"):addLabel(sid("b"), "Second")
            b:popContext()
            return b:build()
        end)
        kg:rerender()
        local line = announcer.composeFull(kg:currentNode())
        t:assertTrue(line:find("List") ~= nil, "vertical context carries the List role: " .. line)
    end,

    ["a vertical context of bars is a list, not a bar"] = function(t)
        local kg = makeGraph(function(b)
            b:beginStop("s")
            b:pushContext("mixed", "Mixed")
            b:startRow()
            b:addLabel(sid("a1"), "A1"):addLabel(sid("a2"), "A2")
            b:endRow()
            b:startRow()
            b:addLabel(sid("b1"), "B1"):addLabel(sid("b2"), "B2")
            b:endRow()
            b:popContext()
            return b:build()
        end)
        kg:rerender()
        local line = announcer.composeFull(kg:currentNode())
        t:assertTrue(line:find("List") ~= nil, "multi-row context carries List: " .. line)
        t:assertTrue(line:find("Bar") == nil, "multi-row context is not a Bar: " .. line)
    end,

    ["declared roles beat arrangement roles"] = function(t)
        local kg = makeGraph(function(b)
            b:beginStop("s")
            b:pushContext("own", "Own", "Custom")
            b:addLabel(sid("a"), "First"):addLabel(sid("b"), "Second")
            b:popContext()
            return b:build()
        end)
        kg:rerender()
        local line = announcer.composeFull(kg:currentNode())
        t:assertTrue(line:find("Custom") ~= nil, "declared role announced: " .. line)
        t:assertTrue(line:find("List") == nil, "no arrangement role added: " .. line)
    end,

    ["keyed contexts with equal labels announce separately"] = function(t)
        local kg = makeGraph(function(b)
            b:beginStop("one")
            b:pushContext("bag:5", "Embersilk Bag")
            b:addLabel(sid("i1"), "Slot one")
            b:popContext()
            b:beginStop("two")
            b:pushContext("bag:6", "Embersilk Bag")
            b:addLabel(sid("i2"), "Slot two")
            b:popContext()
            return b:build()
        end)
        kg:rerender()
        local move = kg:move("next")
        local line = announcer.compose(move.from, move.to)
        t:assertEqual(line, "Embersilk Bag, List, Slot two", "the second bag's context level announces")
    end,

    ["arrangement roles recurse through nested contexts"] = function(t)
        local kg = makeGraph(function(b)
            b:beginStop("s")
            b:pushContext("stats", "Stats")
            b:pushContext("attributes", "Attributes")
            b:startRow()
            b:addLabel(sid("str"), "Strength"):addLabel(sid("agi"), "Agility")
            b:endRow()
            b:popContext()
            b:pushContext("melee", "Melee")
            b:startRow()
            b:addLabel(sid("ap"), "Attack Power"):addLabel(sid("crit"), "Crit")
            b:endRow()
            b:popContext()
            b:popContext()
            return b:build()
        end)
        kg:rerender()
        local line = announcer.composeFull(kg:currentNode())
        t:assertEqual(line, "Stats, List, Attributes, Bar, Strength")
    end,

    ["duplicate level labels dedupe"] = function(t)
        local kg = makeGraph(function(b)
            b:pushContext("options", "Options")
            b:addLabel(sid("options"), "Options")
            b:popContext()
            return b:build()
        end)
        kg:rerender()
        t:assertEqual(announcer.composeFull(kg:currentNode()), "Options")
    end,

    ["control types add role words in speak order"] = function(t)
        local buttonType = {
            key = "testButton",
            order = graph.standardOrder,
            common = function()
                return { { text = "button", kind = graph.kinds.role } }
            end,
        }
        local node = {
            id = sid("n"),
            transitions = {},
            vtable = {
                controlType = buttonType,
                announcements = {
                    { text = "on", kind = graph.kinds.value },
                    { text = "OK", kind = graph.kinds.label },
                },
            },
        }
        t:assertEqual(announcer.leafText(node), "OK, button, on")
    end,

    ["node parts override the type's common part"] = function(t)
        local buttonType = {
            key = "testButton",
            order = graph.standardOrder,
            common = function()
                return { { text = "button", kind = graph.kinds.role } }
            end,
        }
        local node = {
            id = sid("n"),
            transitions = {},
            vtable = {
                controlType = buttonType,
                announcements = {
                    { text = "OK", kind = graph.kinds.label },
                    { text = "menu button", kind = graph.kinds.role },
                },
            },
        }
        t:assertEqual(announcer.leafText(node), "OK, menu button")
    end,

    ["partFilter drops parts and auto positions"] = function(t)
        withAnnouncerHooks({
            positionText = positionText,
            partFilter = function(controlType, part)
                return part.kind ~= graph.kinds.role and part.kind ~= graph.kinds.position
            end,
        }, function()
            local buttonType = {
                key = "testButton",
                order = graph.standardOrder,
                common = function()
                    return { { text = "button", kind = graph.kinds.role } }
                end,
            }
            local node = {
                id = sid("n"),
                transitions = {},
                positionIndex = 2,
                positionCount = 5,
                vtable = {
                    controlType = buttonType,
                    announcements = { { text = "OK", kind = graph.kinds.label } },
                },
            }
            t:assertEqual(announcer.leafText(node), "OK")
        end)
    end,

    ["group headers speak their expansion state"] = function(t)
        withAnnouncerHooks({
            expandedStateText = function(expanded)
                return expanded and "expanded" or "collapsed"
            end,
        }, function()
            local kg = makeGraph(function(b)
                b:beginGroup(sid("g"), vt("Section"))
                b:addLabel(sid("c1"), "Child one")
                b:endGroup()
                return b:build()
            end)
            kg:rerender()
            t:assertEqual(announcer.leafText(kg:currentNode()), "Section, collapsed")
            kg:treeRight()
            t:assertEqual(announcer.leafText(kg:currentNode()), "Section, expanded")
        end)
    end,
})
