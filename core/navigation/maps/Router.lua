-- Routing over waypoint link graphs: A* from a world position to a
-- destination waypoint, following the links map data provides.
--
-- Pure Lua, no WoW APIs -- the headless suite exercises it with synthetic
-- graphs. Waypoints are the plain tables MapDataset stores:
--   { id = ..., x = ..., y = ..., links = { [otherId] = true, ... } }
-- Coordinates share Beacon's convention (whatever UnitPosition returns);
-- the router only ever measures euclidean distances between them.
--
-- Links are treated as DIRECTED edges exactly as stored; importers that
-- mean two-way connections must write both sides.
--
-- The player is rarely standing on a waypoint, so routes enter the graph
-- through a virtual start connected to the nearest few waypoints -- the
-- absolute nearest is not always the best door into the network.
--
-- The same holds at the other end: most creature and object spawns carry
-- no links. A destination without links is reached through a virtual last
-- leg from the nearby linked waypoints, walked in a straight line.

local Router = {}
WowVision.Router = Router

local sqrt = math.sqrt

-- Last-leg candidates: how many linked waypoints near an unlinked
-- destination may end the graph part, and how far from it they may be.
local EXIT_COUNT = 10
local MAX_EXIT_DISTANCE = 500
-- A straight leg crosses unknown terrain, so when choosing where to leave
-- the network each of its yards costs this many route yards: a 10 yard
-- shorter leg is worth up to 90 yards of extra route. Only the choice is
-- weighted; the reported distance stays real.
local LAST_LEG_WEIGHT = 10

local function distanceBetween(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return sqrt(dx * dx + dy * dy)
end

-- Whether a waypoint is part of the link network, so a route can enter or
-- leave there. Most creature and object spawns are not.
function Router.hasLinks(wp)
    return wp.links ~= nil and next(wp.links) ~= nil
end

local hasLinks = Router.hasLinks

-- ---------------------------------------------------------------------------
-- Binary min-heap on .f, for the A* open set
-- ---------------------------------------------------------------------------

local function heapPush(heap, entry)
    tinsert(heap, entry)
    local index = #heap
    while index > 1 do
        local parent = math.floor(index / 2)
        if heap[parent].f <= heap[index].f then
            break
        end
        heap[parent], heap[index] = heap[index], heap[parent]
        index = parent
    end
end

local function heapPop(heap)
    local size = #heap
    if size == 0 then
        return nil
    end
    local top = heap[1]
    heap[1] = heap[size]
    heap[size] = nil
    size = size - 1
    local index = 1
    while true do
        local left = index * 2
        local right = left + 1
        local smallest = index
        if left <= size and heap[left].f < heap[smallest].f then
            smallest = left
        end
        if right <= size and heap[right].f < heap[smallest].f then
            smallest = right
        end
        if smallest == index then
            break
        end
        heap[index], heap[smallest] = heap[smallest], heap[index]
        index = smallest
    end
    return top
end

-- ---------------------------------------------------------------------------
-- Nearest waypoints to a position
-- ---------------------------------------------------------------------------

-- The `count` nearest waypoints to (x, y), optionally filtered, as a sorted
-- list of { waypoint = wp, distance = yards }.
function Router.nearest(waypoints, x, y, count, filter)
    local found = {}
    for _, wp in pairs(waypoints) do
        if filter == nil or filter(wp) then
            tinsert(found, { waypoint = wp, distance = distanceBetween(x, y, wp.x, wp.y) })
        end
    end
    table.sort(found, function(a, b)
        return a.distance < b.distance
    end)
    if count ~= nil then
        for i = #found, count + 1, -1 do
            found[i] = nil
        end
    end
    return found
end

-- The entry point preselected among `entries` (nearest first, as from
-- Router.nearest): the nearest; while swimming the nearest one marked water
-- (wp.water), without moving it to the front -- dry land may be nearer.
-- Returns the entry (nil for an empty list) and true when swimming found no
-- water entry, so the nearest is preselected instead.
function Router.preselectEntry(entries, swimming)
    if swimming then
        for _, entry in ipairs(entries) do
            if entry.waypoint.water == true then
                return entry, false
            end
        end
        return entries[1], true
    end
    return entries[1], false
end

-- ---------------------------------------------------------------------------
-- The nearest of several destinations by the walk
-- ---------------------------------------------------------------------------

-- Of the waypoints in `targets`, the one the shortest walk from (startX,
-- startY) reaches (Auto Route, navigation/visited.lua). One search outward
-- over the links (Dijkstra) that stops at the first target it settles, so
-- it costs about one route however many targets there are. Targets without
-- links are reached over a straight last leg, weighted as in Router.route,
-- so the pick agrees with Router.route. opts: entryId, entryCount,
-- exitCount, maxExitDistance as for Router.route.
-- Returns the target waypoint and its route, shaped as Router.route's (no
-- second search needed), or nil and a reason: "no entry", "unreachable".
function Router.nearestByWalk(waypoints, startX, startY, targets, opts)
    opts = opts or {}
    local exitCount = opts.exitCount or EXIT_COUNT
    local maxExit = opts.maxExitDistance or MAX_EXIT_DISTANCE

    -- A target is reached when the search settles it: over the links (its
    -- own, or another waypoint's link into it), or over a straight last leg.
    -- Targets without links of their own get their nearest linked waypoints
    -- as exits, found in one pass over the network for all of them (a box
    -- around the targets skips the rest).
    local targetById = {}
    local open = {}
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, target in ipairs(targets) do
        if waypoints[target.id] == target then
            targetById[target.id] = target
        end
        if not hasLinks(target) then
            tinsert(open, { waypoint = target, exits = {} })
            minX, maxX = math.min(minX, target.x), math.max(maxX, target.x)
            minY, maxY = math.min(minY, target.y), math.max(maxY, target.y)
        end
    end
    local exits = {} -- id -> { { target, leg }, ... }
    if #open > 0 then
        minX, minY, maxX, maxY = minX - maxExit, minY - maxExit, maxX + maxExit, maxY + maxExit
        for id, wp in pairs(waypoints) do
            if wp.x >= minX and wp.x <= maxX and wp.y >= minY and wp.y <= maxY and hasLinks(wp) then
                for _, entry in ipairs(open) do
                    local leg = distanceBetween(wp.x, wp.y, entry.waypoint.x, entry.waypoint.y)
                    if leg <= maxExit then
                        tinsert(entry.exits, { id = id, leg = leg })
                    end
                end
            end
        end
        for _, entry in ipairs(open) do
            table.sort(entry.exits, function(a, b)
                return a.leg < b.leg
            end)
            for i = 1, math.min(#entry.exits, exitCount) do
                local exit = entry.exits[i]
                exits[exit.id] = exits[exit.id] or {}
                tinsert(exits[exit.id], { target = entry.waypoint, leg = exit.leg })
            end
        end
    end

    local entries
    if opts.entryId ~= nil then
        local entry = waypoints[opts.entryId]
        if entry == nil then
            return nil, "no entry"
        end
        entries = { { waypoint = entry, distance = distanceBetween(startX, startY, entry.x, entry.y) } }
    else
        entries = Router.nearest(waypoints, startX, startY, opts.entryCount or 5)
    end
    if #entries == 0 then
        return nil, "no entry"
    end

    -- Dijkstra with lazy deletion; a target reached over its last leg is a
    -- heap entry of its own (.target, with the exit it leaves from), settled
    -- like any waypoint.
    local best = {}
    local cameFrom = {} -- id -> previous id on the best path
    local closed = {}
    local heap = {}
    for _, entry in ipairs(entries) do
        local wp = entry.waypoint
        if entry.distance < (best[wp.id] or math.huge) then
            best[wp.id] = entry.distance
            heapPush(heap, { id = wp.id, g = entry.distance, f = entry.distance })
        end
    end
    -- The settled target's route, entry first, as Router.route returns it.
    local function routeTo(lastId, target, g, lastLeg)
        local route = { target }
        local id = lastId
        while id ~= nil do
            tinsert(route, 1, waypoints[id])
            id = cameFrom[id]
        end
        if lastLeg ~= nil then
            g = g - lastLeg * (LAST_LEG_WEIGHT - 1)
        end
        return target, { waypoints = route, distance = g, lastLeg = lastLeg }
    end
    while true do
        local current = heapPop(heap)
        if current == nil then
            return nil, "unreachable"
        end
        if current.target ~= nil then
            return routeTo(current.from, current.target, current.g, current.leg)
        end
        if not closed[current.id] and current.g <= (best[current.id] or math.huge) then
            local target = targetById[current.id]
            if target ~= nil then
                return routeTo(cameFrom[current.id], target, current.g, nil)
            end
            closed[current.id] = true
            for _, exit in ipairs(exits[current.id] or {}) do
                local g = current.g + exit.leg * LAST_LEG_WEIGHT
                heapPush(heap, { target = exit.target, from = current.id, leg = exit.leg, g = g, f = g })
            end
            local wp = waypoints[current.id]
            for linkId in pairs(wp.links or {}) do
                local neighbor = waypoints[linkId]
                if neighbor ~= nil and not closed[linkId] then
                    local tentative = current.g + distanceBetween(wp.x, wp.y, neighbor.x, neighbor.y)
                    if tentative < (best[linkId] or math.huge) then
                        best[linkId] = tentative
                        cameFrom[linkId] = current.id
                        heapPush(heap, { id = linkId, g = tentative, f = tentative })
                    end
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- A*
-- ---------------------------------------------------------------------------

-- Route from world position (startX, startY) to the waypoint destId.
-- opts.entryCount: how many nearby waypoints seed the search (default 5).
-- opts.entryId: enter the graph through EXACTLY this waypoint (the user
-- picked their door into the network; 3D geometry makes closest-guessing
-- unreliable).
-- opts.exitCount / opts.maxExitDistance: last-leg candidates for a
-- destination without links (defaults EXIT_COUNT / MAX_EXIT_DISTANCE).
--
-- Returns { waypoints = orderedList, distance = graphYards, lastLeg = yards }
-- where distance includes the leg from the player to the entry waypoint and
-- lastLeg is set only when the route ends with a straight leg off the
-- network -- or nil and a reason: "unknown destination", "no entry",
-- "unreachable".
function Router.route(waypoints, startX, startY, destId, opts)
    opts = opts or {}
    local destination = waypoints[destId]
    if destination == nil then
        return nil, "unknown destination"
    end

    -- id -> straight yards to the destination, for the linked waypoints
    -- that may end the graph part when the destination has no links.
    local exits = {}
    if not hasLinks(destination) then
        local maxExit = opts.maxExitDistance or MAX_EXIT_DISTANCE
        local candidates = Router.nearest(waypoints, destination.x, destination.y, opts.exitCount or EXIT_COUNT, hasLinks)
        for _, candidate in ipairs(candidates) do
            if candidate.distance <= maxExit then
                exits[candidate.waypoint.id] = candidate.distance
            end
        end
    end

    local entries
    if opts.entryId ~= nil then
        local entry = waypoints[opts.entryId]
        if entry == nil then
            return nil, "no entry"
        end
        entries = { { waypoint = entry, distance = distanceBetween(startX, startY, entry.x, entry.y) } }
    else
        entries = Router.nearest(waypoints, startX, startY, opts.entryCount or 5)
    end
    if #entries == 0 then
        return nil, "no entry"
    end

    -- Standard A* with lazy deletion: stale heap entries are skipped when
    -- their recorded cost no longer matches the best known.
    local best = {} -- id -> lowest g found
    local cameFrom = {} -- id -> previous id on the best path
    local closed = {}
    local heap = {}
    local lastLeg = nil -- straight yards of the best known way into destId

    for _, entry in ipairs(entries) do
        local wp = entry.waypoint
        if entry.distance < (best[wp.id] or math.huge) then
            best[wp.id] = entry.distance
            cameFrom[wp.id] = nil
            heapPush(heap, {
                id = wp.id,
                g = entry.distance,
                f = entry.distance + distanceBetween(wp.x, wp.y, destination.x, destination.y),
            })
        end
    end

    while true do
        local current = heapPop(heap)
        if current == nil then
            return nil, "unreachable"
        end
        if not closed[current.id] and current.g <= (best[current.id] or math.huge) then
            if current.id == destId then
                -- Reconstruct entry-first
                local route = {}
                local id = destId
                while id ~= nil do
                    tinsert(route, 1, waypoints[id])
                    id = cameFrom[id]
                end
                local distance = current.g
                if lastLeg ~= nil then
                    distance = distance - lastLeg * (LAST_LEG_WEIGHT - 1)
                end
                return { waypoints = route, distance = distance, lastLeg = lastLeg }
            end
            closed[current.id] = true

            local wp = waypoints[current.id]

            -- Virtual last leg: straight from this exit to the destination
            local leg = exits[current.id]
            if leg ~= nil then
                local tentative = current.g + leg * LAST_LEG_WEIGHT
                if tentative < (best[destId] or math.huge) then
                    best[destId] = tentative
                    cameFrom[destId] = current.id
                    lastLeg = leg
                    heapPush(heap, { id = destId, g = tentative, f = tentative })
                end
            end

            for linkId in pairs(wp.links or {}) do
                local neighbor = waypoints[linkId]
                -- Data may reference waypoints that were filtered out or
                -- never shipped; skip broken links rather than erroring.
                if neighbor ~= nil and not closed[linkId] then
                    local tentative = current.g + distanceBetween(wp.x, wp.y, neighbor.x, neighbor.y)
                    if tentative < (best[linkId] or math.huge) then
                        best[linkId] = tentative
                        cameFrom[linkId] = current.id
                        if linkId == destId then
                            lastLeg = nil
                        end
                        heapPush(heap, {
                            id = linkId,
                            g = tentative,
                            f = tentative + distanceBetween(neighbor.x, neighbor.y, destination.x, destination.y),
                        })
                    end
                end
            end
        end
    end
end
