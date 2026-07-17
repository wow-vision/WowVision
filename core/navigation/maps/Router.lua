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

local Router = {}
WowVision.Router = Router

local sqrt = math.sqrt

local function distanceBetween(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return sqrt(dx * dx + dy * dy)
end

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

-- ---------------------------------------------------------------------------
-- A*
-- ---------------------------------------------------------------------------

-- Route from world position (startX, startY) to the waypoint destId.
-- opts.entryCount: how many nearby waypoints seed the search (default 5).
-- opts.entryId: enter the graph through EXACTLY this waypoint (the user
-- picked their door into the network; 3D geometry makes closest-guessing
-- unreliable).
--
-- Returns { waypoints = orderedList, distance = graphYards } where distance
-- includes the leg from the player to the entry waypoint -- or nil and a
-- reason: "unknown destination", "no entry", "unreachable".
function Router.route(waypoints, startX, startY, destId, opts)
    opts = opts or {}
    local destination = waypoints[destId]
    if destination == nil then
        return nil, "unknown destination"
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
                return { waypoints = route, distance = current.g }
            end
            closed[current.id] = true

            local wp = waypoints[current.id]
            for linkId in pairs(wp.links or {}) do
                local neighbor = waypoints[linkId]
                -- Data may reference waypoints that were filtered out or
                -- never shipped; skip broken links rather than erroring.
                if neighbor ~= nil and not closed[linkId] then
                    local tentative = current.g + distanceBetween(wp.x, wp.y, neighbor.x, neighbor.y)
                    if tentative < (best[linkId] or math.huge) then
                        best[linkId] = tentative
                        cameFrom[linkId] = current.id
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
