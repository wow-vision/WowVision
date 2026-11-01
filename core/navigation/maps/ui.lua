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

local function entryLabel(entry)
    local wp = entry.waypoint
    local parts = { wp.n or wp.id }
    tinsert(parts, string.format("%d %s", entry.distance, L["yards"]))
    local direction = module:directionTo(wp.x, wp.y)
    if direction ~= nil then
        tinsert(parts, direction)
    end
    return table.concat(parts, ", ")
end

-- Snapshot the network and the entry candidates once per open. A pending
-- target (the scanner's Enter, module:openNavigationTo) joins the snapshot
-- as a destination without links: the router ends the route with a straight
-- leg to it. It heads the destination list and takes the landing focus, so
-- the closest entry point and the target are both selected on open.
local TARGET_ID = "navigation:target"

local function ensureData(screen)
    if screen._waypoints ~= nil then
        return true
    end
    local px, py = UnitPosition("player")
    if px == nil then
        return false
    end
    local _, _, _, map = UnitPosition("player")
    screen._px, screen._py, screen._map = px, py, map
    -- With a route engine on (WowNav), its targets join the list and it finds the entry point itself: no entry choice.
    screen._waypoints, screen._engine = module:destinationWaypoints()
    -- an engine may say at once that no route can start here (WowNav: floor not clear, no network)
    if screen._engine ~= nil and screen._engine.listOpened ~= nil then
        screen._engine:listOpened()
    end
    if screen._engine ~= nil then
        screen._entries = {}
    else
        screen._entries = WowVision.Router.nearest(screen._waypoints, px, py, ENTRY_COUNT, WowVision.Router.hasLinks)
    end
    if screen._entries[1] ~= nil then
        screen._entryId = screen._entries[1].waypoint.id
    end
    screen._search = ""
    local target = module.pendingTarget
    module.pendingTarget = nil
    if target ~= nil then
        local wp = { id = TARGET_ID, n = target.label, x = target.x, y = target.y, virtual = true, onArrive = target.onArrive }
        screen._waypoints[TARGET_ID] = wp
        screen._target = wp
        screen._destIndex = 1
        if screen.state ~= nil then
            screen.state.nextSuggestedMove = ControlId.structural("destinations")
        end
    end
    return true
end

-- The destination list: every continent waypoint matching the search,
-- sorted by distance from where the window opened, with the route engine's
-- hits (its own search, nearest first). Cached until the search changes --
-- the full-continent sort runs once, not per tick. An engine that cut its
-- hits leaves a notice that the next spoken entry starts with.
local function destinations(screen)
    if screen._destinations ~= nil then
        return screen._destinations
    end
    local foldCase = WowVision.utils.foldCase
    local needle = screen._search ~= "" and foldCase(screen._search) or nil
    local found = {}
    local target = screen._target
    for _, wp in pairs(screen._waypoints) do
        -- an engine's row may bring its own search text (names in both languages, categories, zone), already folded
        if wp ~= target and wp.n ~= nil and (needle == nil or (wp.search or foldCase(wp.n)):find(needle, 1, true) ~= nil) then
            local dx = wp.x - screen._px
            local dy = wp.y - screen._py
            tinsert(found, { waypoint = wp, distance = math.sqrt(dx * dx + dy * dy) })
        end
    end
    if screen._engine ~= nil then
        local hits, info = screen._engine:search(screen._search, screen._px, screen._py, screen._map)
        for _, wp in ipairs(hits or {}) do
            local dx = wp.x - screen._px
            local dy = wp.y - screen._py
            tinsert(found, { waypoint = wp, distance = math.sqrt(dx * dx + dy * dy) })
        end
        if info ~= nil and info.capped then
            screen._notice = string.format(L["The nearest %d of %d results"], info.shown, info.total)
        end
    end
    table.sort(found, function(a, b)
        return a.distance < b.distance
    end)
    -- The target the window was opened for always heads the list.
    if target ~= nil then
        local dx = target.x - screen._px
        local dy = target.y - screen._py
        table.insert(found, 1, { waypoint = target, distance = math.sqrt(dx * dx + dy * dy) })
    end
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

    -- an engine's row may add a detail after the distance (WowNav: its categories and zone)
    local function labelOf(entry)
        local text = string.format("%s, %d %s", entry.waypoint.n, entry.distance, L["yards"])
        if entry.waypoint.detail ~= nil then
            text = text .. ", " .. entry.waypoint.detail
        end
        return text
    end

    -- the engine's notice of a cut list goes before the first entry said after the search
    local function withNotice(text)
        local notice = screen._notice
        screen._notice = nil
        return notice ~= nil and (notice .. ", " .. text) or text
    end

    local function speak()
        local list, index = clampedIndex()
        local entry = list[index]
        if entry ~= nil then
            WowVision:speak(withNotice(labelOf(entry)))
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
                    return entry ~= nil and withNotice(labelOf(entry)) or L["Empty"]
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
            local wp = entry.waypoint
            if screen._engine ~= nil and module:routeTo(wp.x, wp.y, wp.n, wp.onArrive, wp.z, wp) then
                return
            end
            local routed = module:navigateTo(wp.id, screen._waypoints, { entryId = screen._entryId, onArrive = wp.onArrive })
            -- A target too far from the network for a last leg still gets a
            -- straight beacon, as the scanner gave before.
            if not routed and wp.virtual then
                module:beaconTo(wp.x, wp.y, wp.n, wp.onArrive)
            end
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

-- The entry point stop: the closest waypoints, Enter selects one (only without a route engine).
local function renderEntries(builder, screen)
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
end

local function render(builder, screen)
    if not ensureData(screen) then
        return
    end
    builder:pushContext("navigation", L["Navigation"])

    if screen._engine == nil then
        renderEntries(builder, screen)
    end

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
