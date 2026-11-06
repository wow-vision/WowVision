-- The memory of visited destinations (visited.lua): pure Lua without game functions, so the headless suite tests it.
-- points: { [key] = seconds when the destination was reached } (the module's per-character data); now: seconds of
-- the real clock (GetServerTime), so a reload or a logout does not stop the minutes; minutes: how long a destination
-- counts as visited (a respawn timer).
local store = {}
WowVision.visitedStore = store

-- The key of a destination: its own id (the route data's waypoint id, a WowNav row's catalogue key); one without an
-- id that lasts (the scanner's target, a virtual destination of the navigation window) by its map and its position
-- on a 2 yd grid.
function store.key(wp, map)
    if wp.id ~= nil and not wp.virtual then
        return tostring(wp.id)
    end
    return string.format("pos:%s:%d:%d", tostring(map), math.floor(wp.x / 2 + 0.5), math.floor(wp.y / 2 + 0.5))
end

function store.mark(points, key, now)
    points[key] = now
end

function store.isVisited(points, key, now, minutes)
    local at = points[key]
    return at ~= nil and now - at < minutes * 60
end

-- Drops what no longer counts as visited, so the saved data does not grow.
function store.prune(points, now, minutes)
    for key, at in pairs(points) do
        if now - at >= minutes * 60 then
            points[key] = nil
        end
    end
end

function store.forget(points)
    for key in pairs(points) do
        points[key] = nil
    end
end

-- The name that makes destinations "the same object": the route data names a spawn "Peacebloom;Elwynn Forest;3;..."
-- (name first, then role, zone, spawn number, map position), WowNav names it "Peacebloom". Case-folded with fold.
function store.baseName(name, fold)
    if type(name) ~= "string" then
        return nil
    end
    local base = name:match("^%s*([^;]-)%s*;") or name:match("^%s*(.-)%s*$")
    return fold ~= nil and fold(base) or base:lower()
end

-- The nearest of candidates ({ waypoint, distance }) that skip(waypoint) does not rule out, or nil.
function store.nearest(candidates, skip)
    local best
    for _, candidate in ipairs(candidates) do
        if not skip(candidate.waypoint) and (best == nil or candidate.distance < best.distance) then
            best = candidate
        end
    end
    return best
end

-- The `count` nearest of candidates that skip(waypoint) does not rule out, nearest first.
function store.nearestN(candidates, skip, count)
    local kept = {}
    for _, candidate in ipairs(candidates) do
        if not skip(candidate.waypoint) then
            tinsert(kept, candidate)
        end
    end
    table.sort(kept, function(a, b)
        return a.distance < b.distance
    end)
    for i = #kept, count + 1, -1 do
        kept[i] = nil
    end
    return kept
end
