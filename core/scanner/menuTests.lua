-- Headless only (tools/headless-tests.lua; not in modules.xml): the graph
-- host driven by key presses, with the game-facing pieces stubbed -- the
-- ends of a list read again, and the scanner as a menu (Scanner as Tree
-- off) next to the tree. Loads core/scanner/ui.lua against a fake scanner
-- module, so it needs core/graph/Screen.lua and Host.lua loaded first.
local testRunner = WowVision.testing.testRunner
local graph = WowVision.graph
local ControlId = graph.ControlId
local nodes = graph.nodes

local function fakeFrame()
    return {
        RegisterEvent = function() end,
        SetScript = function() end,
    }
end

local function newHost()
    local savedCreateFrame = CreateFrame
    CreateFrame = fakeFrame
    local host = graph.GraphHost:new()
    CreateFrame = savedCreateFrame
    host.spoken = {}
    host._speak = function(self, text)
        if text ~= nil and text ~= "" then
            tinsert(self.spoken, text)
        end
    end
    return host
end

-- Run fn(host) with WowVision.graphHost and the speech stub in place.
local function withHost(fn)
    local saved = { base = WowVision.base, host = WowVision.graphHost, speak = WowVision.speak }
    local host = newHost()
    WowVision.base = { speech = { uiStop = function() return false end } }
    WowVision.graphHost = host
    WowVision.speak = function(_, text)
        tinsert(host.spoken, text)
    end
    local ok, err = pcall(fn, host)
    WowVision.base, WowVision.graphHost, WowVision.speak = saved.base, saved.host, saved.speak
    if not ok then
        error(err, 0)
    end
end

local function focused(host)
    local screen = host:focusedScreen()
    screen.keyGraph:rerender()
    local node = screen.keyGraph:currentNode()
    return node ~= nil and graph.announcer.firstPartText(node) or nil, node
end

local function press(host, key)
    host:focusedScreen().keyGraph:rerender()
    host:_dispatchKey(key)
end

local function enter(host)
    host:focusedScreen().keyGraph:rerender()
    host:_activateFocused()
end

local function lastSpoken(host)
    return host.spoken[#host.spoken]
end

-- ---- the fake scanner module and its window ----

local scanner = {
    L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    }),
    settings = { asTree = false },
    builds = 0,
}
function scanner:registerWindow(window)
    self.window = window
end
function scanner:registerBinding() end
scanner.providers = {}
function scanner:registerProvider(provider)
    self.providers[provider.key] = provider
end
function scanner:buildTree()
    self.builds = self.builds + 1
    return {
        {
            key = "quests",
            label = "Quests",
            expanded = true,
            children = {
                {
                    key = "inProgress",
                    label = "In Progress",
                    children = function()
                        return {
                            {
                                key = "quest:5",
                                label = "Kobold Camp",
                                x = 10,
                                y = 20,
                                tooltip = { type = "Hyperlink", link = "quest:5:3" },
                                children = {
                                    { key = "spawn:1", label = "Spawn one", x = 1, y = 1 },
                                    { key = "spawn:2", label = "Spawn two", x = 2, y = 2 },
                                },
                            },
                        }
                    end,
                },
                { key = "nearby", label = "Nearby", children = {} },
                {
                    key = "later",
                    label = "Later",
                    children = function()
                        return {}
                    end,
                },
            },
        },
        { key = "npcs", label = "NPCs", children = { { key = "npc:1", label = "Marshal", x = 5, y = 5 } } },
        { key = "group", label = "Group", children = {} },
        {
            key = "player",
            label = "Player",
            children = {
                { key = "self", label = "Anna", nameDetail = "Elwynn Forest, Level 12", unit = "player" },
                { key = "unit:party1", label = "Bert", x = 3, y = 4, routeData = { unit = "party1" } },
            },
        },
    }
end

do
    local savedBase = WowVision.base
    WowVision.base = { scanner = scanner }
    local chunk = assert(loadfile("core/scanner/ui.lua"))
    chunk("WowVision", {})
    chunk = assert(loadfile("core/scanner/providers.lua"))
    chunk("WowVision", {})
    WowVision.base = savedBase
end

local function openScanner(host, asTree)
    scanner.settings.asTree = asTree
    scanner._expanded = nil
    scanner.builds = 0
    local config = {}
    for key, value in pairs(scanner.window.graphScreen) do
        config[key] = value
    end
    config.key = "scanner"
    return host:open(config)
end

local function list(n)
    return {
        captureClose = true,
        render = function(builder)
            builder:beginStop("list")
            for i = 1, n do
                local label = string.char(64 + i)
                builder:addItem(ControlId.structural(label), nodes.text({ label = label }))
            end
        end,
    }
end

testRunner:addSuite("ListEnds", {
    ["up and down past a list's end read the entry again, or stay silent with the setting off"] = function(t)
        withHost(function(host)
            host:open(list(3))
            press(host, "down")
            press(host, "down")
            t:assertEqual((focused(host)), "C")
            local count = #host.spoken
            press(host, "down")
            t:assertEqual((focused(host)), "C")
            t:assertEqual(#host.spoken, count + 1, "the last entry is read again")
            t:assertEqual(host.spoken[#host.spoken], "C")
        end)
        withHost(function(host)
            host:open(list(3))
            press(host, "up")
            t:assertEqual((focused(host)), "A")
            t:assertEqual(#host.spoken, 1, "the first entry is read again")
        end)
        withHost(function(host)
            WowVision.base.ui = { settings = { edgeSound = false } }
            host:open(list(3))
            press(host, "up")
            t:assertEqual((focused(host)), "A")
            t:assertEqual(#host.spoken, 0, "off: silent")
        end)
    end,

    ["left and right at a list's end stay silent"] = function(t)
        withHost(function(host)
            host:open(list(2))
            press(host, "left")
            press(host, "right")
            t:assertEqual(#host.spoken, 0)
        end)
    end,

    ["a node's own onRight and onLeft run"] = function(t)
        withHost(function(host)
            local calls = {}
            host:open({
                render = function(builder)
                    builder:beginStop("list")
                    local vtable = nodes.text({ label = "A" })
                    vtable.onRight = function()
                        tinsert(calls, "right")
                    end
                    vtable.onLeft = function()
                        tinsert(calls, "left")
                    end
                    builder:addItem(ControlId.structural("a"), vtable)
                end,
            })
            press(host, "right")
            press(host, "left")
            t:assertEqual(table.concat(calls, ","), "right,left")
        end)
    end,
})

testRunner:addSuite("ScannerMenu", {
    ["the root lists the categories, Enter opens one level"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            t:assertEqual((focused(host)), "Quests")
            enter(host)
            t:assertEqual(#stack.screens, 2)
            t:assertEqual((focused(host)), "In Progress")
            press(host, "down")
            t:assertEqual((focused(host)), "Nearby")
            t:assertEqual(lastSpoken(host), "Nearby, Button, Empty")
            press(host, "down")
            press(host, "down")
            t:assertEqual(lastSpoken(host), "Later, Button") -- the end reads again
        end)
    end,

    ["a category entry is a button, not a collapsed group"] = function(t)
        withHost(function(host)
            openScanner(host, false)
            local _, node = focused(host)
            t:assertEqual(node.vtable.controlType, graph.controlTypes.button)
            t:assertFalse(node.expandable == true)
        end)
    end,

    ["Escape and Left go back to the entry that was opened"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            press(host, "down")
            t:assertEqual((focused(host)), "NPCs")
            enter(host)
            t:assertEqual((focused(host)), "Marshal")
            host:_close(host:focusedScreen())
            t:assertEqual(#stack.screens, 1)
            t:assertEqual((focused(host)), "NPCs")
            press(host, "right")
            t:assertEqual(#stack.screens, 2)
            press(host, "left")
            t:assertEqual(#stack.screens, 1)
            t:assertEqual((focused(host)), "NPCs")
        end)
    end,

    ["Left on the top level does not close the scanner"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            press(host, "left")
            t:assertEqual(#stack.screens, 1)
            t:assertEqual(#host.stacks, 1)
        end)
    end,

    ["Enter goes deeper as long as there are entries below, like the tree"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            enter(host) -- Quests
            enter(host) -- In Progress
            t:assertEqual((focused(host)), "Kobold Camp")
            enter(host) -- a place with spawns: Enter lists them
            t:assertEqual(#stack.screens, 4)
            t:assertEqual((focused(host)), "Spawn one")
            press(host, "left")
            press(host, "right") -- Right does the same
            t:assertEqual(#stack.screens, 4)
        end)
    end,

    ["Enter on the last level opens the navigation window"] = function(t)
        withHost(function(host)
            local aimed, closed = nil, nil
            WowVision.base.navigation = {
                maps = {
                    openNavigationTo = function(_, x, y, label)
                        aimed = label .. " " .. x .. "," .. y
                    end,
                },
            }
            local savedUIHost = WowVision.UIHost
            WowVision.UIHost = {
                closeWindow = function(_, name)
                    closed = name
                end,
            }
            local ok, err = pcall(function()
                openScanner(host, false)
                press(host, "down")
                enter(host) -- NPCs
                enter(host) -- Marshal: no entries below
            end)
            WowVision.UIHost = savedUIHost
            assert(ok, err)
            t:assertEqual(aimed, "Marshal 5,5")
            t:assertEqual(closed, "scanner")
        end)
    end,

    ["a quest carries its tooltip to the focused entry"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            scanner:openMenuPath(stack, { "quests", "inProgress", "quest:5" })
            local _, node = focused(host)
            t:assertEqual(node.vtable.tooltip.type, "Hyperlink")
            t:assertEqual(node.vtable.tooltip.link, "quest:5:3")
        end)
    end,

    ["an empty category stays in place, reads Empty and does not open"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            press(host, "down")
            press(host, "down")
            t:assertEqual((focused(host)), "Group")
            enter(host)
            t:assertEqual(#stack.screens, 1)
            t:assertEqual(lastSpoken(host), "Empty")
            press(host, "right")
            t:assertEqual(#stack.screens, 1)
            t:assertEqual(lastSpoken(host), "Empty")
        end)
    end,

    ["an entry built when opened does not open when it turns out empty"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            enter(host) -- Quests
            press(host, "down")
            press(host, "down")
            t:assertEqual((focused(host)), "Later")
            enter(host)
            t:assertEqual(#stack.screens, 2)
            t:assertEqual(lastSpoken(host), "Empty")
        end)
    end,

    ["in the tree an empty category is no group and Enter says Empty"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, true)
            press(host, "down") -- In Progress
            press(host, "down") -- Nearby
            local label, node = focused(host)
            t:assertEqual(label, "Nearby")
            t:assertFalse(node.expandable == true)
            enter(host)
            t:assertEqual(lastSpoken(host), "Empty")
            t:assertEqual(#stack.screens, 1)
        end)
    end,

    ["your own entry targets on Enter, a group member with a place routes"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            scanner:openMenuPath(stack, { "player", "self" })
            local label, node = focused(host)
            t:assertEqual(label, "Anna")
            t:assertEqual(node.vtable.bindings[1].binding, "leftClick")
            t:assertEqual(node.vtable.bindings[1].type, "Target")
            t:assertEqual(node.vtable.bindings[1].unit, "player")
            t:assertEqual(node.vtable.onActivate, nil)
            t:assertEqual(node.vtable.onSecondary, nil)
            press(host, "down")
            label, node = focused(host)
            t:assertEqual(label, "Bert")
            t:assertEqual(node.vtable.bindings, nil)
            t:assertTrue(node.vtable.onActivate ~= nil)
            t:assertEqual(node.vtable.onSecondary, nil)
        end)
    end,

    ["the place and description read right after the name, before the role"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            scanner:openMenuPath(stack, { "player", "self" })
            local _, node = focused(host)
            local parts = graph.announcer.effectiveAnnouncements(node)
            t:assertEqual(parts[1].text, "Anna")
            t:assertEqual(parts[2].text, "Elwynn Forest, Level 12")
            t:assertEqual(parts[3].kind, graph.kinds.role)
        end)
    end,

    ["the quest log path opens every level and lands on the quest"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            scanner:openMenuPath(stack, { "quests", "inProgress", "quest:5" })
            t:assertEqual(#stack.screens, 3)
            t:assertEqual((focused(host)), "Kobold Camp")
            host:_close(host:focusedScreen())
            t:assertEqual((focused(host)), "In Progress")
            host:_close(host:focusedScreen())
            t:assertEqual((focused(host)), "Quests")
        end)
    end,

    ["Refresh on a deeper level rebuilds the tree and keeps the level"] = function(t)
        withHost(function(host)
            openScanner(host, false)
            enter(host) -- Quests
            t:assertEqual(scanner.builds, 1)
            press(host, "next") -- the Refresh stop
            t:assertEqual((focused(host)), "Refresh")
            enter(host)
            press(host, "previous")
            t:assertEqual((focused(host)), "In Progress")
            t:assertEqual(scanner.builds, 2)
        end)
    end,

    ["the menu takes letters, the tree does not"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, false)
            focused(host)
            t:assertTrue(stack.config.letterNavigation)
            host:close(stack)
            stack = openScanner(host, true)
            focused(host)
            t:assertFalse(stack.config.letterNavigation)
        end)
    end,

    ["with Scanner as Tree on, Enter opens the group in place"] = function(t)
        withHost(function(host)
            local stack = openScanner(host, true)
            press(host, "down")
            t:assertEqual((focused(host)), "In Progress") -- Quests starts expanded
            enter(host)
            t:assertEqual(#stack.screens, 1)
            press(host, "down")
            t:assertEqual((focused(host)), "Kobold Camp")
        end)
    end,
})

-- ---- the Player and Group categories (core/scanner/providers.lua) ----

local function gameReads(overrides)
    local api = {
        UnitLevel = function()
            return 60
        end,
        UnitRace = function()
            return "Human"
        end,
        UnitClass = function()
            return "Warrior"
        end,
        GetGuildInfo = function()
            return "Order of Light"
        end,
    }
    for key, value in pairs(overrides or {}) do
        api[key] = value
    end
    return api
end

-- Run fn with the game's unit globals faked for the providers' builds.
local function withGame(globals, fn)
    local saved = {}
    for key, value in pairs(globals) do
        saved[key] = _G[key]
        _G[key] = value
    end
    local ok, err = pcall(fn)
    for key in pairs(globals) do
        _G[key] = saved[key]
    end
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("ScannerUnits", {
    ["you are described by level, race, class and guild"] = function(t)
        t:assertEqual(
            scanner.unitDescription("player", gameReads()),
            "Level 60, Human, Warrior, Guild: Order of Light"
        )
    end,

    ["what the game does not give is left out"] = function(t)
        local text = scanner.unitDescription("player", gameReads({
            GetGuildInfo = function()
                return nil
            end,
            UnitRace = function()
                error("no race here")
            end,
        }))
        t:assertEqual(text, "Level 60, Warrior")
    end,

    ["you are in the zone you stand in"] = function(t)
        t:assertEqual(scanner.unitPlace("player", {
            GetRealZoneText = function()
                return "Elwynn Forest"
            end,
        }), "Elwynn Forest")
    end,

    ["a party member is on the map the game names"] = function(t)
        t:assertEqual(scanner.unitPlace("party1", {
            C_Map = {
                GetBestMapForUnit = function(unit)
                    return unit == "party1" and 37 or nil
                end,
                GetMapInfo = function(id)
                    return id == 37 and { name = "Westfall" } or nil
                end,
            },
        }), "Westfall")
    end,

    ["a raid member's zone comes from the roster, the map is the fallback"] = function(t)
        local map = {
            GetBestMapForUnit = function()
                return 37
            end,
            GetMapInfo = function()
                return { name = "Westfall" }
            end,
        }
        local function roster(zone)
            return function(index)
                if index == 3 then
                    return "Bert", 0, 1, 60, "Warrior", "WARRIOR", zone
                end
            end
        end
        t:assertEqual(scanner.unitPlace("raid3", { GetRaidRosterInfo = roster("Duskwood"), C_Map = map }), "Duskwood")
        t:assertEqual(scanner.unitPlace("raid3", { GetRaidRosterInfo = roster(nil), C_Map = map }), "Westfall")
    end,

    ["a place the game does not give is no place"] = function(t)
        t:assertEqual(scanner.unitPlace("party1", {}), nil)
        t:assertEqual(scanner.unitPlace("party1", {
            C_Map = {
                GetBestMapForUnit = function()
                    error("no map")
                end,
                GetMapInfo = function() end,
            },
        }), nil)
    end,

    ["Player lists you first; alive, you alone"] = function(t)
        withGame({
            UnitName = function()
                return "Anna"
            end,
            GetRealZoneText = function()
                return "Elwynn Forest"
            end,
            C_Map = {
                GetBestMapForUnit = function()
                    return 1
                end,
            },
            UnitIsGhost = function()
                return false
            end,
            UnitIsDeadOrGhost = function()
                return false
            end,
            C_DeathInfo = {},
        }, function()
            local out = scanner.providers.player.build({})
            t:assertEqual(out[1].label, "Anna")
            t:assertEqual(out[1].unit, "player")
            t:assertEqual(out[1].nameDetail(), "Elwynn Forest")
            t:assertNil(out[2], "alive: nothing to point at")
        end)
    end,

    ["Group lists every member, a place only where the game gives one"] = function(t)
        withGame({
            IsInRaid = function()
                return false
            end,
            GetNumGroupMembers = function()
                return 3
            end,
            UnitExists = function(unit)
                return unit == "party1" or unit == "party2"
            end,
            UnitIsUnit = function()
                return false
            end,
            UnitName = function(unit)
                return unit == "party1" and "Bert" or "Cleo"
            end,
            UnitPosition = function(unit)
                if unit == "party1" then
                    return 10, 20
                end
                return nil
            end,
            UnitLevel = function()
                return 60
            end,
            C_Map = {
                GetBestMapForUnit = function()
                    return 37
                end,
                GetMapInfo = function()
                    return { name = "Westfall" }
                end,
            },
        }, function()
            local out = scanner.providers.group.build({})
            t:assertEqual(#out, 2)
            t:assertEqual(out[1].label, "Bert")
            t:assertEqual(out[1].nameDetail(), "Westfall, Level 60")
            -- Enter routes (the position), it never targets (no unit)
            t:assertEqual(out[1].unit, nil)
            t:assertEqual(out[1].x, 10)
            t:assertEqual(out[1].routeData.unit, "party1")
            t:assertEqual(out[2].label, "Cleo")
            t:assertEqual(out[2].unit, nil)
            t:assertEqual(out[2].x, nil)
            t:assertTrue(out[2].onActivate ~= nil)
        end)
    end,

    ["Group is there with no group at all"] = function(t)
        withGame({
            IsInRaid = function()
                return false
            end,
            GetNumGroupMembers = function()
                return 0
            end,
        }, function()
            t:assertEqual(#scanner.providers.group.build({}), 0)
            t:assertEqual(scanner.providers.group.optional, nil)
        end)
    end,
})
