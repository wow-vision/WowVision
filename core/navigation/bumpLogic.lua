-- What the player bumps into, pure and headless-tested: the objects, buildings and structures of the bump data
-- (mapdata/bumps/<client>/, written by tools/bumps-pack.lua from the surroundings data, which is generated offline
-- from each client's own map files). A zone registers its data as text; it is read into tables only while the
-- player is in the zone (bumpLogic.unpack) and dropped on leaving.
--
-- Objects are footprints (a box around its centre, turned by an angle) with a name and the room they stand in
-- (0 outdoors). Room floors and outlines are boxes in their building's own frame, so they stay exact for turned
-- buildings; a doorway joins two rooms (0 outside). Positions carry no height, so where floors stack the room is
-- the one the player walked into through a doorway.

local bumpLogic = {}
WowVision.bumpLogic = bumpLogic

bumpLogic.zones = {}

bumpLogic.REACH = 1.5 -- yd from the player to an object that can be what they push against
bumpLogic.ANGLE = 0.34 -- cosine: the object lies at most 70 degrees off the way they push
bumpLogic.TOUCHING = 0.3 -- yd; this close an object counts whichever way the player pushes
bumpLogic.WALL_REACH = 2.5 -- yd ahead looked at for the building or structure whose wall it is
bumpLogic.WALL_STEP = 0.5 -- yd between the points looked at ahead
bumpLogic.ROOM_SLACK = 0.5 -- yd around a room's floor boxes that still count as in it
bumpLogic.DOOR_REACH = 3.0 -- yd from a doorway's plane (or centre, without its width) within which a crossing counts
bumpLogic.DOOR_SIDE = 1.0 -- yd past the edges of the opening that still count as through it

function bumpLogic.addZone(zone)
    bumpLogic.zones[#bumpLogic.zones + 1] = zone
end

local function numbers(text)
    local out, n = {}, 0
    for v in (text or ""):gmatch("%S+") do
        n = n + 1
        out[n] = tonumber(v)
    end
    return out
end

function bumpLogic.cellOf(zone, x, y)
    return math.floor((zone.top - x) / zone.cell), math.floor((zone.left - y) / zone.cell)
end

function bumpLogic.covers(zone, x, y)
    local r, c = bumpLogic.cellOf(zone, x, y)
    return r >= 0 and r < zone.rows and c >= 0 and c < zone.cols
end

-- The registered zone of map `map` that covers the position, or nil.
function bumpLogic.findZone(x, y, map)
    for _, zone in ipairs(bumpLogic.zones) do
        if zone.map == map and bumpLogic.covers(zone, x, y) then
            return zone
        end
    end
    return nil
end

-- A name list in the player's locale, English where the locale has none.
local function localized(lists, locale, i)
    local own = lists[locale]
    local name = own and own[i]
    if name == nil or name == "" then
        name = lists.enUS and lists.enUS[i]
    end
    if name == "" then
        return nil
    end
    return name
end

-- Reads the zone's data into its index (zone._index): objects in buckets per grid cell their footprint touches,
-- the buildings' frames, rooms and doorways, the structures' cells. `locale`: the game's (GetLocale()).
function bumpLogic.unpack(zone, locale)
    if zone._index then
        return zone._index
    end
    local ix = { objects = {}, interiors = {}, rooms = {}, doorsOf = {}, neighbours = {}, struct = {}, waterStructs = {} }

    local list = numbers(zone.objects)
    for i = 1, #list - 6, 7 do
        local o = {
            x = list[i] / 10, y = list[i + 1] / 10, halfLength = list[i + 2] / 10, halfWidth = list[i + 3] / 10,
            angle = math.rad(list[i + 4]), name = localized(zone.objectNames, locale, list[i + 5]), room = list[i + 6],
        }
        local radius = math.sqrt(o.halfLength ^ 2 + o.halfWidth ^ 2)
        local r0, c0 = bumpLogic.cellOf(zone, o.x + radius, o.y + radius)
        local r1, c1 = bumpLogic.cellOf(zone, o.x - radius, o.y - radius)
        for r = r0, r1 do
            for c = math.max(0, c0), math.min(zone.cols - 1, c1) do
                local key = r * zone.cols + c
                local bucket = ix.objects[key]
                if bucket == nil then
                    bucket = {}
                    ix.objects[key] = bucket
                end
                bucket[#bucket + 1] = o
            end
        end
    end

    list = numbers(zone.interiors)
    for i = 1, #list - 6, 7 do
        local n = #ix.interiors + 1
        ix.interiors[n] = {
            ox = list[i], oy = list[i + 1], scale = list[i + 2], m00 = list[i + 3], m01 = list[i + 4], m10 = list[i + 5],
            m11 = list[i + 6], name = localized(zone.interiorNames, locale, n),
            wall = localized(zone.interiorWalls, locale, n),
        }
    end

    list = numbers(zone.rooms)
    local i = 1
    while i <= #list do
        local room = { interior = list[i], hall = list[i + 1] == 1, boxes = {} }
        local nBoxes = list[i + 2]
        for k = 1, nBoxes do
            room.boxes[k] = list[i + 2 + k]
        end
        i = i + 3 + nBoxes
        local nOutline = list[i]
        if nOutline > 0 then
            room.outline = { list[i + 1], list[i + 2], list[i + 3], list[i + 4] }
        end
        i = i + 1 + nOutline
        ix.rooms[#ix.rooms + 1] = room
    end

    list = numbers(zone.doors)
    for k = 1, #list - 8, 9 do
        local door = {
            a = list[k], b = list[k + 1], interior = list[k + 2], x = list[k + 3], y = list[k + 4], nx = list[k + 5],
            ny = list[k + 6], side = list[k + 7], half = list[k + 8],
        }
        for _, pair in ipairs({ { door.a, door.b }, { door.b, door.a } }) do
            local room, other = pair[1], pair[2]
            ix.neighbours[room] = ix.neighbours[room] or {}
            ix.neighbours[room][other] = true
            ix.doorsOf[room] = ix.doorsOf[room] or {}
            table.insert(ix.doorsOf[room], door)
        end
    end

    -- structure cells as runs along a row: row, column, count (< 0: the columns go down), structure
    list = numbers(zone.structCells)
    for k = 1, #list - 3, 4 do
        local r, c, n, struct = list[k], list[k + 1], list[k + 2], list[k + 3]
        local step = n > 0 and 1 or -1
        for j = 0, math.abs(n) - 1 do
            ix.struct[r * zone.cols + c + j * step] = struct
        end
    end
    for _, struct in ipairs(zone.waterStructs or {}) do
        ix.waterStructs[struct] = true
    end
    ix.structNames = {}
    for k in pairs(zone.structNames.enUS or {}) do
        ix.structNames[k] = localized(zone.structNames, locale, k)
    end
    ix.ofTemplate = zone.ofTemplate and (zone.ofTemplate[locale] or zone.ofTemplate.enUS) or nil

    zone._index = ix
    return ix
end

-- Drops the zone's tables again (the text stays registered).
function bumpLogic.pack(zone)
    zone._index = nil
end

-- The nearest point of an object's footprint to a position, and the distance.
function bumpLogic.objectPoint(o, x, y)
    local ux, uy = math.cos(o.angle), math.sin(o.angle)
    local dx, dy = x - o.x, y - o.y
    local pu = math.max(-o.halfLength, math.min(o.halfLength, dx * ux + dy * uy))
    local pv = math.max(-o.halfWidth, math.min(o.halfWidth, -dx * uy + dy * ux))
    local qx, qy = o.x + pu * ux - pv * uy, o.y + pu * uy + pv * ux
    local ex, ey = x - qx, y - qy
    return qx, qy, math.sqrt(ex * ex + ey * ey)
end

-- The object the player pushes against: moving (or trying to) along the unit vector (vx, vy), the nearest named
-- object within `reach` yards that lies that way. `rooms`: 0 for the outdoor objects, a set of room ids for the
-- objects of those rooms, nil for any indoor object. Returns the object and its distance, or nil.
function bumpLogic.objectAhead(zone, x, y, vx, vy, reach, rooms)
    local ix = zone._index
    local r0, c0 = bumpLogic.cellOf(zone, x, y)
    local n = math.ceil(reach / zone.cell)
    local best, bestD, seen = nil, reach, {}
    for r = r0 - n, r0 + n do
        for c = math.max(0, c0 - n), math.min(zone.cols - 1, c0 + n) do
            for _, o in ipairs(ix.objects[r * zone.cols + c] or {}) do
                local fits
                if rooms == 0 then
                    fits = o.room == 0
                elseif rooms == nil then
                    fits = o.room ~= 0
                else
                    fits = rooms[o.room] == true
                end
                if fits and o.name and not seen[o] then
                    seen[o] = true
                    local qx, qy, d = bumpLogic.objectPoint(o, x, y)
                    if d <= bestD and (d < bumpLogic.TOUCHING or ((qx - x) * vx + (qy - y) * vy) / d >= bumpLogic.ANGLE) then
                        best, bestD = o, d
                    end
                end
            end
        end
    end
    return best, best and bestD
end

-- A world position in a building's frame {ox, oy, scale, m00, m01, m10, m11}: world x = ox - scale * (m00 vx +
-- m01 vy), world y = oy - scale * (m10 vx + m11 vy).
function bumpLogic.toBuilding(frame, x, y)
    local a, b, c, d = frame.m00, frame.m01, frame.m10, frame.m11
    local r0, r1 = (frame.ox - x) / frame.scale, (frame.oy - y) / frame.scale
    local det = a * d - b * c
    return (d * r0 - b * r1) / det, (-c * r0 + a * r1) / det
end

local function inBox(b, i, vx, vy, margin)
    return vx >= b[i] - margin and vx <= b[i + 2] + margin and vy >= b[i + 1] - margin and vy <= b[i + 3] + margin
end

-- Is the position on the room's floor boxes (widened by `margin` yards)?
function bumpLogic.onFloor(zone, id, x, y, margin)
    local ix = zone._index
    local room = ix.rooms[id]
    local vx, vy = bumpLogic.toBuilding(ix.interiors[room.interior], x, y)
    local b = room.boxes
    for i = 1, #b - 3, 4 do
        if inBox(b, i, vx, vy, margin) then
            return true
        end
    end
    return false
end

-- The rooms whose floor boxes hold the position (within `margin` yards). `indoors` (the game's IsIndoors(), or
-- nil): a hall the game calls outdoors fits only while it says outdoors, any other room only while it says
-- indoors; where none fits, all of them (the game's word only decides between floors on top of each other).
function bumpLogic.roomsAt(zone, x, y, margin, indoors)
    local found = {}
    for id in ipairs(zone._index.rooms) do
        if bumpLogic.onFloor(zone, id, x, y, margin) then
            found[#found + 1] = id
        end
    end
    if indoors == nil then
        return found
    end
    local fitting = {}
    for _, id in ipairs(found) do
        if zone._index.rooms[id].hall ~= indoors then
            fitting[#fitting + 1] = id
        end
    end
    return #fitting > 0 and fitting or found
end

-- The one hall (a room the game calls outdoors) whose floor holds the position, or nil (none, or several).
function bumpLogic.hallAt(zone, x, y)
    local found = nil
    for _, id in ipairs(bumpLogic.roomsAt(zone, x, y, 0)) do
        if zone._index.rooms[id].hall then
            if found then
                return nil
            end
            found = id
        end
    end
    return found
end

-- The first room whose outline (the box of its walls) holds the position, or nil.
function bumpLogic.roomOutlineAt(zone, x, y)
    local ix = zone._index
    for id, room in ipairs(ix.rooms) do
        local o = room.outline
        if o then
            local vx, vy = bumpLogic.toBuilding(ix.interiors[room.interior], x, y)
            if inBox(o, 1, vx, vy, 0) then
                return id
            end
        end
    end
    return nil
end

-- Did the player walk through a doorway of room `current` between (px, py) and (x, y)? Returns the room behind it
-- (0 outside) or nil.
function bumpLogic.crossedDoor(zone, current, px, py, x, y)
    if current == nil or px == nil then
        return nil
    end
    local ix = zone._index
    for _, door in ipairs(ix.doorsOf[current] or {}) do
        if door.side ~= 0 and (door.nx ~= 0 or door.ny ~= 0) then
            local interior = ix.interiors[door.interior]
            local ax, ay = bumpLogic.toBuilding(interior, px, py)
            local bx, by = bumpLogic.toBuilding(interior, x, y)
            local function near(u, v)
                if door.half > 0 then
                    local along = math.abs((u - door.x) * -door.ny + (v - door.y) * door.nx)
                    local off = math.abs((u - door.x) * door.nx + (v - door.y) * door.ny)
                    return along <= door.half + bumpLogic.DOOR_SIDE and off <= bumpLogic.DOOR_REACH
                end
                local dx, dy = u - door.x, v - door.y
                return dx * dx + dy * dy <= bumpLogic.DOOR_REACH * bumpLogic.DOOR_REACH
            end
            if near(ax, ay) or near(bx, by) then
                local mine = current == door.a and door.side or -door.side
                local before = ((ax - door.x) * door.nx + (ay - door.y) * door.ny) * mine
                local after = ((bx - door.x) * door.nx + (by - door.y) * door.ny) * mine
                if before > 0 and after < 0 then
                    return current == door.a and door.b or door.a
                end
            end
        end
    end
    return nil
end

-- The room the player is in, as far as known, after a step from (px, py) to (x, y) while in room `current` (0
-- outside, nil unknown): through a doorway the room behind it (0 outside); else the room the floor boxes give where
-- they give one, the current room where it is among them, or the one room among them joined to it by a doorway (from
-- outside: the one entrance room). nil: unknown. The candidate rooms come as the second value.
function bumpLogic.resolveRoom(zone, x, y, current, px, py, indoors)
    local crossed = bumpLogic.crossedDoor(zone, current, px, py, x, y)
    if crossed then
        return crossed, {}
    end
    local cands = bumpLogic.roomsAt(zone, x, y, bumpLogic.ROOM_SLACK, indoors)
    if #cands == 1 then
        return cands[1], cands
    end
    if current == nil then
        return nil, cands
    end
    local joined = nil
    local neighbours = zone._index.neighbours[current] or {}
    for _, id in ipairs(cands) do
        if id == current then
            return current, cands
        end
        if neighbours[id] then
            if joined ~= nil then
                return nil, cands
            end
            joined = id
        end
    end
    return joined, cands
end

-- Whose wall the player pushes against from outside: the building whose room floor or outline lies just ahead
-- (within `reach` yards along the vector), or a structure (a gate, a city wall, a bridge) whose floor lies there.
-- Returns the name, and "place" for a building named only by the place it stands in (its wall is said as "wall,
-- <place>" in the zone's words), or nil.
function bumpLogic.wallOwner(zone, x, y, vx, vy, reach)
    local ix = zone._index
    for k = bumpLogic.WALL_STEP, reach, bumpLogic.WALL_STEP do
        local px, py = x + vx * k, y + vy * k
        local id = bumpLogic.roomsAt(zone, px, py, 0)[1] or bumpLogic.roomOutlineAt(zone, px, py)
        if id then
            local interior = ix.interiors[ix.rooms[id].interior]
            if interior.wall then
                return interior.wall, "place"
            end
            return interior.name
        end
        local r, c = bumpLogic.cellOf(zone, px, py)
        local struct = c >= 0 and c < zone.cols and ix.struct[r * zone.cols + c]
        if struct and not ix.waterStructs[struct] then
            return ix.structNames[struct]
        end
    end
    return nil
end

-- What to say for a bump along the unit vector (vx, vy): the object in the way, else indoors "wall", outdoors
-- the wall of the building or structure ahead. `rooms` as for objectAhead (indoors: the room known, else the
-- candidate rooms, else nil). `words`: the locale's "wall" and "wall of %s". Returns the text and a key that is
-- the same for the same thing, or nil.
function bumpLogic.bumpText(zone, x, y, vx, vy, indoors, rooms, words)
    local o = bumpLogic.objectAhead(zone, x, y, vx, vy, bumpLogic.REACH, indoors and rooms or 0)
    if o then
        return o.name, o
    end
    if indoors then
        return words.wall, "wall"
    end
    local owner, what = bumpLogic.wallOwner(zone, x, y, vx, vy, bumpLogic.WALL_REACH)
    if owner and what == "place" then
        return string.format(zone._index.ofTemplate or "%s of %s", words.wall, owner), owner
    elseif owner then
        return string.format(words.wallOf, owner), owner
    end
    return nil
end

-- When a bump is named: the wall detection's "blocked" held for BUMP_TICKS looks in a row, once per bump; the same
-- thing again only after moving freely for FREE seconds.
bumpLogic.BUMP_TICKS = 2
bumpLogic.FREE = 1.0
bumpLogic.MOVING = 0.2 -- yd moved in one look that counts as moving freely

function bumpLogic.newBumpState()
    return { ticks = 0, key = nil, free = 0 }
end

-- One look: `blocked` (the wall detection's fresh "blocked"), `moved` yards since the last look, `dt` seconds.
-- True when the thing ahead should be looked up now.
function bumpLogic.step(state, blocked, moved, dt)
    if not blocked then
        state.ticks = 0
        if moved > bumpLogic.MOVING then
            state.free = state.free + dt
            if state.free >= bumpLogic.FREE then
                state.key = nil
            end
        end
        return false
    end
    state.ticks = state.ticks + 1
    state.free = 0
    return state.ticks >= bumpLogic.BUMP_TICKS
end

-- After a lookup: whether the text is new (said), and remembers its key.
function bumpLogic.take(state, key)
    local new = key ~= nil and key ~= state.key
    state.key = key or state.key
    return new
end
