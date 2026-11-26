-- Headless only (tools/headless-tests.lua; not in modules.xml): a key for a WowVision window that is already open
-- brings that window to the front as it is, and the navigation window opened again for a target (F10 from the quest
-- log, the scanner's Enter) takes the target into the window that is open, keeping what was set in it. Drives the
-- real window manager and graph host; loads core/navigation/maps/ui.lua against a fake
-- maps module.
local testRunner = WowVision.testing.testRunner
local graph = WowVision.graph
local ControlId = graph.ControlId
local nodes = graph.nodes

local function newHost()
    local savedCreateFrame = CreateFrame
    CreateFrame = function()
        return { RegisterEvent = function() end, SetScript = function() end }
    end
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

-- ---- the fake maps module and the navigation window ----

local maps = {
    L = setmetatable({}, {
        __index = function(_, key)
            return key
        end,
    }),
}
function maps:registerWindow(window)
    self.window = window
end
function maps:registerBinding() end
function maps:destinationWaypoints()
    return {
        inn = { id = "inn", n = "Inn", x = 10, y = 0 },
        bank = { id = "bank", n = "Bank", x = 200, y = 0 },
    }, nil
end
-- the entry points: the waypoints within 50 yards, nearest first
function maps:entryPoints(waypoints, px, py)
    local entries = {}
    for _, wp in pairs(waypoints) do
        local distance = math.sqrt((wp.x - px) ^ 2 + (wp.y - py) ^ 2)
        if distance <= 50 then
            tinsert(entries, { waypoint = wp, distance = distance })
        end
    end
    table.sort(entries, function(a, b)
        return a.distance < b.distance
    end)
    return entries
end
function maps:preselectedEntry(entries)
    return entries[1], false
end
function maps:engineMatch()
    return nil
end
function maps:directionTo()
    return nil
end

do
    local savedBase = WowVision.base
    WowVision.base = { navigation = { maps = maps } }
    local chunk = assert(loadfile("core/navigation/maps/ui.lua"))
    chunk("WowVision", {})
    WowVision.base = savedBase
end

-- The UIHost's window calls, each handed to the window manager as core/UIHost.lua does (that file needs the game's
-- frames, the headless runner does not load it).
local function fakeUIHost(manager)
    return {
        windowManager = manager,
        openWindow = function(_, name)
            return manager:openWindow(name)
        end,
        closeWindow = function(_, name)
            return manager:closeWindow(name)
        end,
        bringWindowToFront = function(_, name, toFirstScreen)
            return manager:bringToFront(name, toFirstScreen)
        end,
        openWindowStack = function(_, name)
            return manager:openStack(name)
        end,
        isWindowInFront = function(_, name)
            return manager:isInFront(name)
        end,
    }
end
WowVision.testing.fakeUIHost = fakeUIHost

-- Where the player stands (UnitPosition); nil: no position.
local position = { 0, 0 }

-- Run fn(manager, host) with a real window manager and graph host in place, the UIHost's window calls on that
-- manager, the navigation window and a plain list window ("other") registered.
local function withWindows(fn)
    local saved = {
        base = WowVision.base,
        host = WowVision.graphHost,
        uiHost = WowVision.UIHost,
        speak = WowVision.speak,
        UnitPosition = UnitPosition,
    }
    local host = newHost()
    local manager = WowVision.WindowManager:new()
    WowVision.base = {
        speech = { uiStop = function() return false end },
        ui = { settings = { menuSounds = false } },
        navigation = { maps = maps },
    }
    WowVision.graphHost = host
    WowVision.UIHost = fakeUIHost(manager)
    WowVision.speak = function(_, text)
        tinsert(host.spoken, text)
    end
    position = { 0, 0 }
    UnitPosition = function()
        if position == nil then
            return nil
        end
        return position[1], position[2], 0, 0
    end
    local navConfig = { name = "atlas", graphScreen = maps.window.graphScreen }
    manager:RegisterWindow(manager:CreateWindow("ManualWindow", navConfig))
    manager:RegisterWindow(manager:CreateWindow("ManualWindow", {
        name = "other",
        graphScreen = {
            captureClose = true,
            render = function(builder)
                builder:beginStop("list")
                builder:addItem(ControlId.structural("a"), nodes.text({ label = "Other A" }))
                builder:addItem(ControlId.structural("b"), nodes.text({ label = "Other B" }))
            end,
        },
    }))
    maps.pendingTarget = nil
    local ok, err = pcall(fn, manager, host)
    WowVision.base, WowVision.graphHost, WowVision.UIHost = saved.base, saved.host, saved.uiHost
    WowVision.speak, UnitPosition = saved.speak, saved.UnitPosition
    maps.pendingTarget = nil
    if not ok then
        error(err, 0)
    end
end

local function focused(host)
    local screen = host:focusedScreen()
    screen.keyGraph:rerender()
    local node = screen.keyGraph:currentNode()
    return node ~= nil and graph.announcer.firstPartText(node) or nil
end

local function press(host, key)
    host:focusedScreen().keyGraph:rerender()
    host:_dispatchKey(key)
end

-- as module:openNavigationTo does it (core/navigation/maps/module.lua): the target, then the window
local function openNavigationTo(x, y, label)
    maps.pendingTarget = { x = x, y = y, label = label }
    return maps:showNavigation()
end

local function destinationNames(host)
    local names = {}
    for _, entry in ipairs(host:focusedScreen()._destinations) do
        tinsert(names, entry.waypoint.n)
    end
    return table.concat(names, ",")
end

testRunner:addSuite("WindowOpenAgain", {
    ["a window's key while it is open behind another brings it to the front as it is"] = function(t)
        withWindows(function(manager, host)
            local first = manager:openWindow("other")
            press(host, "down")
            t:assertEqual(focused(host), "Other B")
            manager:openWindow("atlas")
            t:assertEqual(host:focusedStack(), manager:openStack("atlas"))
            t:assertNil(manager:openWindow("other"), "no new window")
            t:assertEqual(#host.stacks, 2)
            t:assertEqual(host:focusedStack(), first.stack, "the open one is in front")
            t:assertEqual(focused(host), "Other B", "on the entry it was on")
            t:assertTrue(manager:isInFront("other"))
            t:assertFalse(manager:isInFront("atlas"))
        end)
    end,

    ["a window whose screen the host closed by itself opens afresh on its key"] = function(t)
        withWindows(function(manager, host)
            local first = manager:openWindow("other")
            host:close(first.stack) -- as the host does with a screen that has nothing to show
            t:assertNil(manager:openStack("other"), "no longer counted as open")
            local again = manager:openWindow("other")
            t:assertTrue(again ~= nil, "opened again")
            t:assertEqual(#host.stacks, 1)
            t:assertEqual(focused(host), "Other A")
        end)
    end,

    ["in a fight, while the bags are walked, the window stays behind"] = function(t)
        withWindows(function(manager, host)
            local savedWalking, savedLockdown = graph.combatKeys.walking, InCombatLockdown
            graph.combatKeys.walking = function()
                return "bags"
            end
            InCombatLockdown = function()
                return true
            end
            local ok, err = pcall(function()
                local first = manager:openWindow("other")
                manager:openWindow("atlas")
                host.focusedIndex = 2
                manager:openWindow("other")
                t:assertTrue(host:focusedStack() ~= first.stack, "the focus stays")
            end)
            graph.combatKeys.walking, InCombatLockdown = savedWalking, savedLockdown
            assert(ok, err)
        end)
    end,

    ["the navigation window opened again for a target keeps its search and lands on the target"] = function(t)
        withWindows(function(manager, host)
            manager:openWindow("atlas")
            local stack = host:focusedStack()
            local screen = stack.screens[1]
            screen.keyGraph:rerender()
            screen._search = "inn"
            screen._destinations = nil
            manager:openWindow("other") -- the quest log in front
            t:assertTrue(openNavigationTo(30, 40, "Kobold Camp"))
            t:assertNil(maps.pendingTarget, "taken by the open window")
            t:assertEqual(#host.stacks, 2, "no second navigation window")
            t:assertEqual(host:focusedStack(), stack, "the navigation window is in front")
            t:assertEqual(screen._search, "inn", "the search is kept")
            t:assertEqual(screen._entryId, "inn", "the entry point is kept")
            t:assertEqual(focused(host), "Kobold Camp, 50 yards", "lands on the target")
            t:assertEqual(destinationNames(host), "Kobold Camp,Inn", "the search still filters the rest")
        end)
    end,

    ["a second target replaces the first one at the head of the list"] = function(t)
        withWindows(function(manager, host)
            openNavigationTo(30, 40, "Kobold Camp")
            t:assertEqual(focused(host), "Kobold Camp, 50 yards")
            openNavigationTo(0, 5, "Mine")
            t:assertEqual(focused(host), "Mine, 5 yards")
            t:assertEqual(destinationNames(host), "Mine,Inn,Bank", "the first target is gone")
        end)
    end,

    ["opened again after a walk it reads distances and entry points from where the player is now"] = function(t)
        withWindows(function(manager, host)
            manager:openWindow("atlas")
            local screen = host:focusedScreen()
            screen.keyGraph:rerender()
            t:assertEqual(screen._entryId, "inn")
            position = { 200, 30 }
            openNavigationTo(200, 0, "Kobold Camp")
            t:assertEqual(focused(host), "Kobold Camp, 30 yards", "measured from here")
            t:assertEqual(screen._entryId, "bank", "the inn is no longer near: the nearest entry instead")
            position = nil
            openNavigationTo(210, 30, "Mine")
            t:assertEqual(focused(host), "Mine, 10 yards", "no position now: the last reading stays")
        end)
    end,

    ["a screen on top of the navigation window closes for the target"] = function(t)
        withWindows(function(manager, host)
            manager:openWindow("atlas")
            local stack = host:focusedStack()
            stack.screens[1].keyGraph:rerender()
            host:push(stack, {
                key = "menu",
                render = function(builder)
                    builder:addItem(ControlId.structural("x"), nodes.text({ label = "Menu entry" }))
                end,
            })
            openNavigationTo(30, 40, "Kobold Camp")
            t:assertEqual(#stack.screens, 1)
            t:assertEqual(focused(host), "Kobold Camp, 50 yards")
        end)
    end,

    ["a target is never left over for a later open"] = function(t)
        withWindows(function(manager, host)
            manager:openWindow("atlas") -- open, not read yet
            openNavigationTo(30, 40, "Kobold Camp")
            t:assertNil(maps.pendingTarget, "taken at once")
            manager:closeWindow("atlas")
            manager:openWindow("atlas")
            t:assertEqual(focused(host), "Inn, 10 yards", "a plain open lands on the entry point")
            manager:closeWindow("atlas")
            manager:getWindow("atlas")._hasConflictingAddon = true
            t:assertFalse(openNavigationTo(30, 40, "Kobold Camp"), "the window cannot open")
            t:assertNil(maps.pendingTarget)
        end)
    end,
})
