-- Headless only (tools/headless-tests.lua; not in modules.xml): the graph host driven by key presses, with the
-- game-facing pieces stubbed -- letters and the list filter, the arrows changing menu levels, the window's letter
-- switch and closing every window at once.
local testRunner = WowVision.testing.testRunner
local graph = WowVision.graph
local nodes = graph.nodes
local sid = graph.ControlId.structural

local function withHost(fn)
    local saved = {
        base = WowVision.base,
        host = WowVision.graphHost,
        speak = WowVision.speak,
        createFrame = CreateFrame,
        getTime = GetTime,
        combat = InCombatLockdown,
    }
    CreateFrame = function()
        return { RegisterEvent = function() end, SetScript = function() end }
    end
    local host = graph.GraphHost:new()
    CreateFrame = saved.createFrame
    host.spoken = {}
    host._speak = function(self, text)
        if text ~= nil and text ~= "" then
            tinsert(self.spoken, text)
        end
    end
    local clock = { now = 100 }
    GetTime = function()
        return clock.now
    end
    InCombatLockdown = function()
        return false
    end
    WowVision.base = {
        speech = {
            uiStop = function()
                return false
            end,
        },
        ui = { settings = { letterNavigation = true, interruptSpeechOnWindowClose = false } },
    }
    WowVision.graphHost = host
    local ok, err = pcall(fn, host, clock)
    WowVision.base, WowVision.graphHost, WowVision.speak = saved.base, saved.host, saved.speak
    GetTime, InCombatLockdown = saved.getTime, saved.combat
    if not ok then
        error(err, 0)
    end
end

local function focusedKey(host)
    local screen = host:focusedScreen()
    screen.keyGraph:rerender()
    return screen.keyGraph:currentNode().id.key
end

local function press(host, key)
    host:focusedScreen().keyGraph:rerender()
    host:_dispatchKey(key)
end

local function type_(host, clock, letter, gap)
    clock.now = clock.now + (gap or 0.1)
    host:focusedScreen().keyGraph:rerender()
    host:_typeLetter(letter)
end

local function lastSpoken(host)
    return host.spoken[#host.spoken]
end

local function list(names, stops)
    return function(builder)
        for _, name in ipairs(names) do
            builder:addLabel(sid(name), name)
        end
        if stops then
            builder:beginStop("other")
            builder:addLabel(sid("refresh"), "Refresh")
        end
    end
end

-- A menu of three levels, as the WowVision menu is.
local function openMenu(host)
    local stack
    local function level(depth)
        return function(builder)
            builder:addItem(sid("deeper" .. depth), nodes.button({
                label = "Deeper " .. depth,
                opensLevel = true,
                onActivate = function()
                    host:push(stack, { key = "level" .. (depth + 1), render = level(depth + 1) })
                end,
            }))
            builder:addItem(sid("action" .. depth), nodes.button({
                label = "Action " .. depth,
                onActivate = function()
                    host.acted = depth
                end,
            }))
        end
    end
    stack = host:open({ key = "menu", render = level(1) })
    return stack
end

testRunner:addSuite("MenuNavigation", {
    ["two different letters typed quickly filter the list, the same letter keeps jumping"] = function(t)
        withHost(function(host, clock)
            host:open({ key = "list", render = list({ "Alpha", "Beta", "Banana", "Cabin" }, true) })
            type_(host, clock, "b")
            t:assertEqual(focusedKey(host), "Beta", "one letter jumps")
            type_(host, clock, "b")
            t:assertEqual(focusedKey(host), "Banana", "the same letter cycles")
            t:assertNil(host:focusedScreen().listFilter)

            type_(host, clock, "a", 1)
            t:assertEqual(focusedKey(host), "Alpha", "after a pause a letter jumps again")
            type_(host, clock, "b", 0.2)
            local screen = host:focusedScreen()
            t:assertEqual(screen.listFilter.text, "ab", "typed quickly: a filter")
            t:assertEqual(focusedKey(host), graph.LIST_FILTER_ID.key)
            t:assertEqual(lastSpoken(host):sub(1, 10), "Filter: ab", "the Filter line is read")
            press(host, "down")
            t:assertEqual(focusedKey(host), "Cabin", "the only entry containing it")

            type_(host, clock, "i", 5)
            t:assertEqual(screen.listFilter.text, "abi", "once filtering, a letter adds however slowly it comes")
            t:assertEqual(focusedKey(host), graph.LIST_FILTER_ID.key)

            type_(host, clock, "x", 0.1)
            t:assertTrue(lastSpoken(host):find("No results", 1, true) ~= nil, "nothing left says so")
        end)
    end,

    ["umlauts jump and filter, one press counting once however it arrives"] = function(t)
        withHost(function(host, clock)
            host:open({ key = "list", render = list({ "Alpha", "Mutter", "Müller", "Übersicht", "Ultra" }) })
            local screen = host:focusedScreen()
            screen.keyGraph:rerender()
            host:onLetter("ü")
            t:assertEqual(focusedKey(host), "Übersicht", "an umlaut goes to its own entry")
            host:onLetter("Ü")
            t:assertEqual(focusedKey(host), "Übersicht", "the second report of the same press does nothing")
            t:assertNil(host:focusedScreen().listFilter)

            clock.now = clock.now + 2
            host:onLetter("m")
            clock.now = clock.now + 0.1
            host:onLetter("ü")
            t:assertEqual(screen.listFilter.text, "mü")
            t:assertEqual(lastSpoken(host):sub(1, 11), "Filter: mü", "said as typed")
            t:assertEqual(screen.listFilter.matches, 1, "Mutter stays out")
            press(host, "down")
            t:assertEqual(focusedKey(host), "Müller")
        end)
    end,

    ["a list behind one node filters all its entries, not the one it shows"] = function(t)
        withHost(function(host, clock)
            local names = { "Goldshire", "Stormwind", "Goldtooth", "Westfall" }
            local rows, index, read = nil, 1, 0
            local function shown()
                return rows or names
            end
            local cursor = {
                labels = function()
                    return names
                end,
                index = function()
                    return index
                end,
                go = function(i)
                    index = i
                    read = read + 1
                end,
                show = function(matches, text)
                    if matches == nil then
                        local entry = shown()[index]
                        rows, index = nil, 1
                        for i, name in ipairs(names) do
                            if name == entry then
                                index = i
                            end
                        end
                        return
                    end
                    rows = { "Filter: " .. text }
                    for _, i in ipairs(matches) do
                        tinsert(rows, names[i])
                    end
                    index = 1
                end,
            }
            host:open({
                key = "cursor",
                render = function(builder)
                    builder:addItem(sid("cursor"), {
                        controlType = graph.controlTypes.button,
                        listCursor = cursor,
                        announcements = {
                            {
                                kind = graph.kinds.label,
                                text = function()
                                    return shown()[index]
                                end,
                            },
                        },
                        onActivate = function()
                            host.picked = shown()[index]
                        end,
                    })
                end,
            })
            local screen = host:focusedScreen()

            type_(host, clock, "w")
            t:assertEqual(index, 4, "one letter jumps inside the list")
            t:assertEqual(read, 1)
            type_(host, clock, "w")
            t:assertEqual(index, 4, "the only match is read again")
            t:assertEqual(read, 2)

            type_(host, clock, "z", 2)
            t:assertEqual(lastSpoken(host), "No results", "nothing starts with it")

            type_(host, clock, "g", 2)
            t:assertEqual(index, 1)
            type_(host, clock, "o")
            t:assertEqual(screen.listFilter.matches, 2, "both Gold entries, wherever the cursor stood")
            t:assertEqual(lastSpoken(host):sub(1, 10), "Filter: go")
            t:assertEqual(focusedKey(host), "cursor", "the node stays")
            type_(host, clock, "l", 3)
            t:assertEqual(shown()[1], "Filter: gol")
            t:assertEqual(#shown(), 3)

            host:_activateFocused()
            t:assertNil(host.picked, "the Filter line is no entry")
            t:assertTrue(screen.listFilter ~= nil, "and Enter on it keeps the filter")

            index = 3
            press(host, "left")
            t:assertNil(screen.listFilter)
            t:assertEqual(shown()[index], "Goldtooth", "the whole list again, on the same entry")
            t:assertEqual(index, 3)
        end)
    end,

    ["a list behind one node without show only jumps, a growing text included"] = function(t)
        withHost(function(host, clock)
            local names, index = { "Alpha", "Beta", "Berlin" }, 1
            host:open({
                key = "cursor",
                render = function(builder)
                    builder:addItem(sid("cursor"), {
                        listCursor = {
                            labels = function()
                                return names
                            end,
                            index = function()
                                return index
                            end,
                            go = function(i)
                                index = i
                            end,
                        },
                        announcements = { { text = "line" } },
                    })
                end,
            })
            type_(host, clock, "b")
            t:assertEqual(index, 2)
            type_(host, clock, "e")
            t:assertEqual(index, 2, "still fits")
            type_(host, clock, "r")
            t:assertEqual(index, 3)
            t:assertNil(host:focusedScreen().listFilter)
        end)
    end,

    ["tab leaves the filter behind"] = function(t)
        withHost(function(host, clock)
            host:open({ key = "list", render = list({ "Alpha", "Beta" }, true) })
            type_(host, clock, "a")
            type_(host, clock, "l")
            t:assertTrue(host:focusedScreen().listFilter ~= nil)
            press(host, "next")
            t:assertNil(host:focusedScreen().listFilter)
            t:assertEqual(focusedKey(host), "refresh")
        end)
    end,

    ["backspace and left take the filter away, focus stays on the entry"] = function(t)
        withHost(function(host, clock)
            host:open({ key = "list", render = list({ "Alpha", "Beta", "Banana" }) })
            local screen = host:focusedScreen()
            type_(host, clock, "a")
            type_(host, clock, "n")
            press(host, "down")
            t:assertEqual(focusedKey(host), "Banana")
            press(host, "left")
            t:assertNil(screen.listFilter)
            t:assertEqual(focusedKey(host), "Banana", "left stays on the entry")
            t:assertEqual(lastSpoken(host):sub(1, 14), "Filter removed")

            type_(host, clock, "b", 2)
            type_(host, clock, "e")
            t:assertEqual(focusedKey(host), graph.LIST_FILTER_ID.key)
            local specs = host:_nodeBindingSpecs(screen.keyGraph:currentNode())
            t:assertEqual(specs[1].binding, "rightClick", "while filtered Backspace belongs to the filter")
            specs[1].func()
            t:assertNil(screen.listFilter)
            t:assertEqual(focusedKey(host), "Alpha", "from the Filter line: the first entry")
            t:assertEqual(#host:_nodeBindingSpecs(screen.keyGraph:currentNode()), 0, "and Backspace is free again")
        end)
    end,

    ["enter on a match and going a level deeper end the filter"] = function(t)
        withHost(function(host, clock)
            local stack = openMenu(host)
            local first = stack.screens[1]
            type_(host, clock, "a")
            type_(host, clock, "c")
            press(host, "down")
            t:assertEqual(focusedKey(host), "action1")
            host:_activateFocused()
            t:assertEqual(host.acted, 1)
            t:assertNil(first.listFilter, "the pick ends it")

            type_(host, clock, "d", 2)
            type_(host, clock, "e")
            press(host, "down")
            t:assertEqual(focusedKey(host), "deeper1")
            press(host, "right")
            t:assertEqual(#stack.screens, 2, "right opens the level")
            t:assertNil(first.listFilter, "and the filter ends")
        end)
    end,

    ["right opens the next level and left goes back, never out of the menu"] = function(t)
        withHost(function(host)
            local stack = openMenu(host)
            press(host, "left")
            t:assertEqual(#stack.screens, 1, "the first level stays")
            t:assertEqual(#host.stacks, 1, "the menu stays open")

            press(host, "down")
            press(host, "right")
            t:assertEqual(#stack.screens, 1, "right on an action does nothing")
            t:assertNil(host.acted, "and does not run it")
            press(host, "up")

            press(host, "right")
            t:assertEqual(#stack.screens, 2)
            press(host, "right")
            t:assertEqual(#stack.screens, 3)
            press(host, "left")
            t:assertEqual(#stack.screens, 2)
            t:assertEqual(focusedKey(host), "deeper2")
            press(host, "left")
            press(host, "left")
            t:assertEqual(#stack.screens, 1)
            t:assertEqual(#host.stacks, 1, "still open")
        end)
    end,

    ["left keeps a question and the first level of a context menu, and walks a row first"] = function(t)
        withHost(function(host)
            local stack = host:open({ key = "root", render = list({ "One" }) })
            host:push(stack, { key = "confirm", noLevelBack = true, render = list({ "Yes", "No" }) })
            press(host, "left")
            t:assertEqual(#stack.screens, 2, "a yes/no question stays")
            host:pop(stack)

            host:push(stack, { key = "context", _contextMenu = true, render = list({ "Sub" }) })
            press(host, "left")
            t:assertEqual(#stack.screens, 2, "the context menu stays open")
            host:push(stack, { key = "context2", _contextMenu = true, render = list({ "Inner" }) })
            press(host, "left")
            t:assertEqual(#stack.screens, 2, "its submenu goes back")
            host:pop(stack)

            host:push(stack, {
                key = "rows",
                render = function(builder)
                    builder:startRow()
                    builder:addLabel(sid("cell1"), "Cell 1")
                    builder:addLabel(sid("cell2"), "Cell 2")
                    builder:endRow()
                end,
            })
            press(host, "right")
            t:assertEqual(focusedKey(host), "cell2")
            press(host, "left")
            t:assertEqual(focusedKey(host), "cell1")
            press(host, "left")
            t:assertEqual(#stack.screens, 2, "a row's end is not a level")
        end)
    end,

    ["a window takes letters only with its own switch on; menus keep theirs"] = function(t)
        withHost(function(host)
            local on = false
            local window = host:open({
                key = "window",
                render = list({ "One" }),
                windowLetters = function()
                    return on
                end,
            })
            t:assertFalse(host:_wantsLetters(), "off by default")
            on = true
            t:assertTrue(host:_wantsLetters())
            WowVision.base.ui.settings.letterNavigation = false
            t:assertTrue(host:_wantsLetters(), "a window's switch does not depend on the setting for menus")
            on = false
            host:close(window)

            host:open({ key = "menu", letterNavigation = true, render = list({ "One" }) })
            t:assertFalse(host:_wantsLetters(), "the setting for menus off")
            WowVision.base.ui.settings.letterNavigation = true
            t:assertTrue(host:_wantsLetters())
        end)
    end,

    ["closing all closes every stack and the game's windows; in combat the game's stay"] = function(t)
        withHost(function(host)
            local savedClose = CloseAllWindows
            local gameCloses, gameResult = 0, false
            CloseAllWindows = function()
                gameCloses = gameCloses + 1
                return gameResult
            end
            local manager = WowVision.WindowManager:new()
            local requested = 0

            host:open({ key = "plain", render = list({ "One" }) })
            host:open({
                key = "framed",
                render = list({ "Two" }),
                onRequestClose = function()
                    requested = requested + 1
                end,
            })
            t:assertTrue(manager:closeAll(), "something was open")
            t:assertEqual(requested, 1, "a window bound to a frame is asked to close")
            t:assertEqual(#host.stacks, 1, "a plain stack closes at once; the other waits for its frame")
            t:assertEqual(gameCloses, 1)
            t:assertTrue(manager.quietCloseUntil > GetTime(), "closing does not cut off what is said next")
            host.stacks = {}

            t:assertFalse(manager:closeAll(), "nothing open, nothing to say")
            gameResult = true
            t:assertTrue(manager:closeAll(), "a window of the game was open")

            InCombatLockdown = function()
                return true
            end
            gameCloses = 0
            manager:closeAll()
            t:assertEqual(gameCloses, 0, "the game's protected windows cannot close in combat")
            CloseAllWindows = savedClose
        end)
    end,
})
