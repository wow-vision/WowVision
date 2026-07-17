local module = WowVision.base.navigation.maps
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The navigation window (F10): pick your entry point into the waypoint
-- network, search for a destination, route there.
--
-- Layout: the landing stop is the 20 closest waypoints -- WoW geometry is
-- fully 3D, so the closest match is often the road under the bridge, and
-- each candidate announces name, distance, and relative direction so the
-- player can tell them apart. Enter SELECTS the entry (the closest is
-- preselected). Tab reaches the destination search box; tab again the
-- destination list -- every continent waypoint matching the search, sorted
-- by distance, presented as ONE cursor node (chat-reader pattern: tens of
-- thousands of entries cannot be per-tick builder nodes). Enter on a
-- destination routes from the selected entry and closes the window.

local ENTRY_COUNT = 20

-- Relative direction words from the player to (x, y), using Beacon's
-- verified bearing math: 0 = dead ahead, positive = to the right.
local function directionTo(x, y)
    local px, py = UnitPosition("player")
    local facing = GetPlayerFacing()
    if px == nil or facing == nil then
        return nil
    end
    local bearing = -math.deg(math.atan2(y - py, x - px))
    local facingDeg = math.deg(facing)
    if facingDeg > 180 then
        facingDeg = facingDeg - 360
    end
    local relative = bearing + facingDeg
    if relative > 180 then
        relative = relative - 360
    elseif relative <= -180 then
        relative = relative + 360
    end

    local absolute = math.abs(relative)
    if absolute <= 30 then
        return L["ahead"]
    elseif absolute >= 150 then
        return L["behind"]
    end
    local side = relative > 0 and L["right"] or L["left"]
    if absolute < 75 then
        return L["ahead"] .. " " .. side
    elseif absolute > 105 then
        return L["behind"] .. " " .. side
    end
    return side
end

local function entryLabel(entry)
    local wp = entry.waypoint
    local parts = { wp.n or wp.id }
    tinsert(parts, string.format("%d %s", entry.distance, L["yards"]))
    local direction = directionTo(wp.x, wp.y)
    if direction ~= nil then
        tinsert(parts, direction)
    end
    return table.concat(parts, ", ")
end

-- Snapshot the network and the entry candidates once per open.
local function ensureData(screen)
    if screen._waypoints ~= nil then
        return true
    end
    local px, py = UnitPosition("player")
    if px == nil then
        return false
    end
    screen._px, screen._py = px, py
    screen._waypoints = module:currentWaypoints()
    screen._entries = WowVision.Router.nearest(screen._waypoints, px, py, ENTRY_COUNT, function(wp)
        return wp.links ~= nil and next(wp.links) ~= nil
    end)
    if screen._entries[1] ~= nil then
        screen._entryId = screen._entries[1].waypoint.id
    end
    screen._search = ""
    return true
end

-- The destination list: every continent waypoint matching the search,
-- sorted by distance from where the window opened. Cached until the search
-- changes -- the full-continent sort runs once, not per tick.
local function destinations(screen)
    if screen._destinations ~= nil then
        return screen._destinations
    end
    local needle = screen._search ~= "" and screen._search:lower() or nil
    local found = {}
    for _, wp in pairs(screen._waypoints) do
        if wp.n ~= nil and (needle == nil or wp.n:lower():find(needle, 1, true) ~= nil) then
            local dx = wp.x - screen._px
            local dy = wp.y - screen._py
            tinsert(found, { waypoint = wp, distance = math.sqrt(dx * dx + dy * dy) })
        end
    end
    table.sort(found, function(a, b)
        return a.distance < b.distance
    end)
    screen._destinations = found
    return found
end

local function destinationCursor(screen)
    local function clampedIndex()
        local list = destinations(screen)
        local count = #list
        local index = screen._destIndex or 1
        if index > count then
            index = count
        end
        if index < 1 then
            index = count > 0 and 1 or 0
        end
        screen._destIndex = index
        return list, index, count
    end

    local function labelOf(entry)
        return string.format("%s, %d %s", entry.waypoint.n, entry.distance, L["yards"])
    end

    local function speak()
        local list, index = clampedIndex()
        local entry = list[index]
        if entry ~= nil then
            WowVision:speak(labelOf(entry))
        end
    end

    local function moveTo(target)
        local list, index, count = clampedIndex()
        if count == 0 then
            return
        end
        if target < 1 then
            target = 1
        end
        if target > count then
            target = count
        end
        if target == index then
            return
        end
        screen._destIndex = target
        speak()
    end

    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    local list, index = clampedIndex()
                    local entry = list[index]
                    return entry ~= nil and labelOf(entry) or L["Empty"]
                end,
                kind = kinds.label,
                live = false,
            },
            {
                text = function()
                    local _, index, count = clampedIndex()
                    if count == 0 then
                        return nil
                    end
                    return index .. " / " .. count
                end,
                kind = kinds.position,
                live = false,
            },
        },
        onActivate = function()
            local list, index = clampedIndex()
            local entry = list[index]
            if entry == nil then
                return
            end
            WowVision.UIHost:closeWindow("atlas")
            module:navigateTo(entry.waypoint.id, screen._waypoints, { entryId = screen._entryId })
        end,
        bindings = {
            {
                binding = "up",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    moveTo((screen._destIndex or 1) - 1)
                end,
            },
            {
                binding = "down",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    moveTo((screen._destIndex or 1) + 1)
                end,
            },
            {
                binding = "home",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    moveTo(1)
                end,
            },
            {
                binding = "end",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    local list = destinations(screen)
                    moveTo(#list)
                end,
            },
        },
    }
end

local function render(builder, screen)
    if not ensureData(screen) then
        return
    end
    builder:pushContext("navigation", L["Navigation"])

    builder:beginStop("entries")
    builder:pushContext("entries", L["Entry Points"])
    if #screen._entries == 0 then
        builder:addItem(ControlId.structural("entriesEmpty"), nodes.text({ label = L["Empty"] }))
    end
    for _, entry in ipairs(screen._entries) do
        local captured = entry
        builder:addItem(ControlId.structural("entry:" .. entry.waypoint.id), {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        return entryLabel(captured)
                    end,
                    kind = kinds.label,
                },
                {
                    text = function()
                        if screen._entryId == captured.waypoint.id then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                },
            },
            onActivate = function()
                screen._entryId = captured.waypoint.id
            end,
        })
    end
    builder:popContext()

    builder:beginStop("search")
    builder:addItem(
        ControlId.structural("search"),
        nodes.textInput({
            label = L["Search"],
            get = function()
                return screen._search
            end,
            set = function(value)
                screen._search = value or ""
                screen._destinations = nil
                screen._destIndex = 1
            end,
        })
    )

    builder:beginStop("targets")
    builder:pushContext("targets", L["Destinations"], nil, false)
    builder:addItem(ControlId.structural("destinations"), destinationCursor(screen))
    builder:popContext()

    builder:popContext()
end

module:registerWindow({
    type = "ManualWindow",
    name = "atlas",
    graphScreen = { render = render, captureClose = true },
})

module:registerBinding({
    type = "Script",
    key = "maps/openNavigation",
    label = L["Navigation"],
    inputs = { "F10" },
    script = "/run WowVision.UIHost:openWindow('atlas')",
})
