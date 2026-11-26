-- Headless only (tools/headless-tests.lua; not in modules.xml): a key for a WowVision window that is already open
-- brings that window to the front as it is, and the navigation window opened again for a target (F10 from the quest
-- log, the scanner's Enter) takes the target into the window that is open, keeping what was set in it. Drives the
-- real window manager and graph host; loads core/navigation/maps/ui.lua against a fake maps module.
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
        bank = { id = "bank", n = "Bank", x = 20, y = 0 },
    }, nil
end
function maps:entryPoints(waypoints)
    return { { waypoint = waypoints.inn, distance = 10 } }
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

-- Run fn(manager, host) with a real window manager and graph host in place, the navigation window and a plain list
-- window ("other") registered.
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
    WowVision.UIHost = {
        windowManager = manager,
        openWindow = function(_, name)
            return manager:openWindow(name)
        end,
        bringWindowToFront = function(_, name, toFirstScreen)
            return manager:bringToFront(name, toFirstScreen)
        end,
    }
    WowVision.speak = function(_, text)
        tinsert(host.spoken, text)
    end
    UnitPosition = function()
        return 0, 0, 0, 0
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

local function openNavigationTo(x, y, label)
    -- as module:openNavigationTo does it (core/navigation/maps/module.lua)
    maps.pendingTarget = { x = x, y = y, label = label }
    if WowVision.UIHost:openWindow("atlas") == nil then
        maps:aimOpenNavigation()
    end
end

testRunner:addSuite("WindowOpenAgain", {
    ["a window's key while it is open behind another brings it to the front as it is"] = function(t)
        withWindows(function(manager, host)
            local first = manager:openWindow("other")
            press(host, "down")
            t:assertEqual(focused(host), "Other B")
            manager:openWindow("atlas")
            t:assertEqual(host:focusedStack(), manager:getWindow("atlas"):getOpenInstance().stack)
            t:assertNil(manager:openWindow("other"), "no new window")
            t:assertEqual(#host.stacks, 2)
            t:assertEqual(host:focusedStack(), first.stack, "the open one is in front")
            t:assertEqual(focused(host), "Other B", "on the entry it was on")
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
            openNavigationTo(30, 40, "Kobold Camp")
            t:assertNil(maps.pendingTarget, "taken by the open window")
            t:assertEqual(#host.stacks, 2, "no second navigation window")
            t:assertEqual(host:focusedStack(), stack, "the navigation window is in front")
            t:assertEqual(screen._search, "inn", "the search is kept")
            t:assertEqual(screen._entryId, "inn", "the entry point is kept")
            t:assertEqual(focused(host), "Kobold Camp, 50 yards", "lands on the target")
        end)
    end,

    ["a second target replaces the first one at the head of the list"] = function(t)
        withWindows(function(manager, host)
            openNavigationTo(30, 40, "Kobold Camp")
            t:assertEqual(focused(host), "Kobold Camp, 50 yards")
            openNavigationTo(0, 5, "Mine")
            t:assertEqual(focused(host), "Mine, 5 yards")
            local names = {}
            for _, entry in ipairs(host:focusedScreen()._destinations) do
                tinsert(names, entry.waypoint.n)
            end
            t:assertEqual(table.concat(names, ","), "Mine,Inn,Bank", "the first target is gone")
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

    ["a target the window cannot take is dropped, never landing in a later open"] = function(t)
        withWindows(function(manager, host)
            maps.pendingTarget = { x = 30, y = 40, label = "Kobold Camp" }
            t:assertFalse(maps:aimOpenNavigation(), "the window is not open")
            t:assertNil(maps.pendingTarget)
            manager:openWindow("atlas")
            t:assertEqual(focused(host), "Inn, 10 yards", "a plain open lands on the entry point")
        end)
    end,
})
