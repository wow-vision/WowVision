-- What the player bumps into, pure and headless-tested: the objects, buildings and structures of the bump data
-- (mapdata/bumps/<client>/, written by tools/bumps/pack.lua from the surroundings data, which is generated offline
-- from each client's own map files). A zone registers its data as text; it is read into tables only while the
-- player is in the zone (bumpLogic.unpack) and dropped on leaving.
--
-- Objects are footprints (a box around its centre, turned by an angle) with a name and the room they stand in
-- (0 outdoors). Room floors and outlines are boxes in their building's own frame, so they stay exact for turned
-- buildings; a doorway joins two rooms (0 outside). Positions carry no height, so where floors stack the room is
-- the one the player walked into through a doorway (bumpLogic.newTracker). The rules are the surroundings
-- module's (its rooms.lua and objects.lua), without its floor layers.

local bumpLogic = {}
WowVision.bumpLogic = bumpLogic

bumpLogic.zones = {}

bumpLogic.REACH = 1.5 -- yd from the player to an object that can be what they push against
bumpLogic.ANGLE = 0.34 -- cosine: the object lies at most 70 degrees off the way they push
bumpLogic.TOUCHING = 0.3 -- yd; this close an object counts whichever way the player pushes
bumpLogic.WALL_REACH = 2.5 -- yd ahead looked at for the building or structure whose wall it is
bumpLogic.WALL_STEP = 0.5 -- yd between the points looked at ahead
bumpLogic.ROOM_MARGIN = 0.5 -- yd around a room's floor boxes that count as on them
bumpLogic.ROOM_SLACK = 2.0 -- yd; where no floor lies right under the player, a floor this close counts
bumpLogic.DOOR_REACH = 3.0 -- yd from a doorway's plane (or centre, without its width) within which a crossing counts
bumpLogic.DOOR_SIDE = 1.0 -- yd past the edges of the opening that still count as through it
bumpLogic.DOOR_HOLD = 4.0 -- yd from a doorway of the room entered through a doorway within which that room holds
-- yd off its floor within which a room entered through a doorway is left only for a room joined to it by a doorway
-- (floor boxes are rough: on the Wizard's Sanctum's winding stairs the player stood 3 yd beyond theirs)
bumpLogic.ROOM_FAR = 6.0
bumpLogic.HALL_GAP = 15 -- yd walked in a hall with no hall floor near (a bridge, over lava) before it ends
bumpLogic.HERE_SAME = 1.5 -- yd from the spot kept over a reload that still count as the same
bumpLogic.JUMP = 100 -- yd between two looks from which the player was moved (a hearthstone, a portal)
-- Objects go into buckets per block of BLOCK by BLOCK cells, not per cell (the surroundings module's measure: a
-- table per cell held Elwynn's objects in 62730 buckets, 8.8 MB), and an object is a number in flat lists, not a
-- table of its own. Elwynn's whole index: 9.7 MB per cell with a table per object, 1.8 MB so (LuaJIT); a lookup
-- takes some microseconds.
bumpLogic.BLOCK = 8

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

local function dist(ax, ay, bx, by)
    return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end
bumpLogic.dist = dist

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

-- A name in the player's locale, English where the locale has none; nil for none at all.
local function localized(lists, locale, i)
    local own = lists and lists[locale]
    local name = own and own[i]
    if name == nil or name == "" then
        name = lists and lists.enUS and lists.enUS[i]
    end
    if name == "" then
        return nil
    end
    return name
end

-- The block bucket of cell (r, c).
local function blockOf(zone, r, c)
    local b = bumpLogic.BLOCK
    return math.floor(r / b) * (math.floor(zone.cols / b) + 1) + math.floor(c / b)
end

-- Reads the zone's data into its index (zone._index): objects in the buckets of the blocks their footprint's circle
-- touches, each with that box of cells; the buildings' frames, rooms and doorways; the structures' cells.
-- `locale`: the game's (GetLocale()).
function bumpLogic.unpack(zone, locale)
    if zone._index then
        return zone._index
    end
    local ix = {
        objects = {}, interiors = {}, rooms = {}, doorsOf = {}, neighbours = {}, struct = {}, waterStructs = {},
    }

    -- objects: per object i its centre, half length and width, the cosine and sine of its angle, name, room, and
    -- the box of cells its footprint's circle touches (rows r0..r1, columns c0..c1)
    local ox, oy, ohl, ohw, ocos, osin, oname, oroom = {}, {}, {}, {}, {}, {}, {}, {}
    local or0, or1, oc0, oc1 = {}, {}, {}, {}
    ix.ox, ix.oy, ix.ohl, ix.ohw, ix.ocos, ix.osin, ix.oname, ix.oroom = ox, oy, ohl, ohw, ocos, osin, oname, oroom
    ix.or0, ix.or1, ix.oc0, ix.oc1 = or0, or1, oc0, oc1
    local list = numbers(zone.objects)
    local n = 0
    for i = 1, #list - 6, 7 do
        local name = localized(zone.objectNames, locale, list[i + 5])
        if name then
            n = n + 1
            local x, y, hl, hw = list[i] / 10, list[i + 1] / 10, list[i + 2] / 10, list[i + 3] / 10
            local angle = math.rad(list[i + 4])
            ox[n], oy[n], ohl[n], ohw[n], ocos[n], osin[n] = x, y, hl, hw, math.cos(angle), math.sin(angle)
            oname[n], oroom[n] = name, list[i + 6]
            local radius = math.sqrt(hl * hl + hw * hw)
            local r0, c0 = bumpLogic.cellOf(zone, x + radius, y + radius)
            local r1, c1 = bumpLogic.cellOf(zone, x - radius, y - radius)
            or0[n], or1[n], oc0[n], oc1[n] = r0, r1, c0, c1
            local added = {}
            for r = r0, r1 do
                for c = c0, c1 do
                    local block = blockOf(zone, r, c)
                    if not added[block] then
                        added[block] = true
                        local bucket = ix.objects[block]
                        if bucket == nil then
                            bucket = {}
                            ix.objects[block] = bucket
                        end
                        bucket[#bucket + 1] = n
                    end
                end
            end
        end
    end

    list = numbers(zone.interiors)
    for i = 1, #list - 6, 7 do
        local n = #ix.interiors + 1
        ix.interiors[n] = {
            ox = list[i], oy = list[i + 1], scale = list[i + 2], m00 = list[i + 3], m01 = list[i + 4],
            m10 = list[i + 5], m11 = list[i + 6], name = localized(zone.interiorNames, locale, n),
            wall = localized(zone.interiorWalls, locale, n),
        }
    end

    -- rooms: interior, hall map (the UI map of a hall the game calls outdoors, 0 none), the box values, the outline
    list = numbers(zone.rooms)
    local i = 1
    while i <= #list do
        local id = #ix.rooms + 1
        local room = { interior = list[i], boxes = {} }
        if list[i + 1] ~= 0 then
            room.hallMap = list[i + 1]
            room.area = localized(zone.roomAreas, locale, id)
        end
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
        ix.rooms[id] = room
    end

    list = numbers(zone.doors)
    for k = 1, #list - 8, 9 do
        local door = {
            a = list[k], b = list[k + 1], interior = list[k + 2], x = list[k + 3], y = list[k + 4],
            nx = list[k + 5], ny = list[k + 6], side = list[k + 7], half = list[k + 8],
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
    for k in pairs(zone.structNames and zone.structNames.enUS or {}) do
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

-- The nearest point of object i's footprint to a position, and the distance.
local function objectPoint(ix, i, x, y)
    local ux, uy, hl, hw = ix.ocos[i], ix.osin[i], ix.ohl[i], ix.ohw[i]
    local dx, dy = x - ix.ox[i], y - ix.oy[i]
    local pu = math.max(-hl, math.min(hl, dx * ux + dy * uy))
    local pv = math.max(-hw, math.min(hw, -dx * uy + dy * ux))
    local qx, qy = ix.ox[i] + pu * ux - pv * uy, ix.oy[i] + pu * uy + pv * ux
    return qx, qy, dist(x, y, qx, qy)
end
bumpLogic.objectPoint = objectPoint

-- Object i as a table (for tests and tools): x, y, halfLength, halfWidth, angle (radians), name, room.
function bumpLogic.object(zone, i)
    local ix = zone._index
    return {
        x = ix.ox[i], y = ix.oy[i], halfLength = ix.ohl[i], halfWidth = ix.ohw[i],
        angle = math.atan2(ix.osin[i], ix.ocos[i]), name = ix.oname[i], room = ix.oroom[i],
    }
end

-- The object the player pushes against: moving (or trying to) along the unit vector (vx, vy), the nearest object
-- within `reach` yards that lies that way. `rooms`: 0 for the outdoor objects, a set of room ids for the objects of
-- those rooms, nil for any indoor object. Returns the object's number and its distance, or nil.
function bumpLogic.objectAhead(zone, x, y, vx, vy, reach, rooms)
    local ix = zone._index
    local or0, or1, oc0, oc1, oroom = ix.or0, ix.or1, ix.oc0, ix.oc1, ix.oroom
    local r0, c0 = bumpLogic.cellOf(zone, x, y)
    local n = math.ceil(reach / zone.cell)
    local best, bestD, seen = nil, reach, {}
    for r = r0 - n, r0 + n do
        for c = c0 - n, c0 + n do
            for _, i in ipairs(ix.objects[blockOf(zone, r, c)] or {}) do
                if not seen[i] and r >= or0[i] and r <= or1[i] and c >= oc0[i] and c <= oc1[i] then
                    seen[i] = true
                    local fits
                    if rooms == 0 then
                        fits = oroom[i] == 0
                    elseif rooms == nil then
                        fits = oroom[i] ~= 0
                    else
                        fits = rooms[oroom[i]] == true
                    end
                    if fits then
                        local qx, qy, d = objectPoint(ix, i, x, y)
                        local toward = ((qx - x) * vx + (qy - y) * vy) / d
                        if d <= bestD and (d < bumpLogic.TOUCHING or toward >= bumpLogic.ANGLE) then
                            best, bestD = i, d
                        end
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

-- A building-frame position in world yards (the inverse of toBuilding).
function bumpLogic.toWorld(frame, vx, vy)
    return frame.ox - frame.scale * (frame.m00 * vx + frame.m01 * vy),
        frame.oy - frame.scale * (frame.m10 * vx + frame.m11 * vy)
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
-- indoors; where none fits, all of them (the game's word only decides between floors on top of each other: in
-- Ironforge the Great Forge's floor lies over the throne room's stairs and the cavern below, and the game calls the
-- forge outdoors and the rest indoors). `ids` (optional): the room ids to look at instead of all, in that order.
function bumpLogic.roomsAt(zone, x, y, margin, indoors, ids)
    local ix = zone._index
    local found, inFrame = {}, {}
    local function look(id)
        local room = ix.rooms[id]
        local pos = inFrame[room.interior]
        if pos == nil then
            pos = { bumpLogic.toBuilding(ix.interiors[room.interior], x, y) }
            inFrame[room.interior] = pos
        end
        local b = room.boxes
        for i = 1, #b - 3, 4 do
            if inBox(b, i, pos[1], pos[2], margin) then
                found[#found + 1] = id
                return
            end
        end
    end
    if ids then
        for _, id in ipairs(ids) do
            look(id)
        end
    else
        for id in ipairs(ix.rooms) do
            look(id)
        end
    end
    if indoors == nil then
        return found
    end
    local fitting = {}
    for _, id in ipairs(found) do
        if (zone._index.rooms[id].hallMap ~= nil) ~= indoors then
            fitting[#fitting + 1] = id
        end
    end
    return #fitting > 0 and fitting or found
end

-- The first room whose outline (the box of its walls) holds the position, or nil: where the floor boxes leave gaps
-- (under counters, a raised platform).
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

-- Did the player walk through a doorway of room `current` (0 outside) between (px, py) and (x, y)? Returns the
-- room behind it (0 outside) or nil. A doorway into a room whose floor is not here is passed over: a doorway has no
-- height (the Trade Quarter's doorway into its shop lies 0.8 yd from the canal tunnel's 17 yd below it, and one step
-- crossed both). `fits` (optional): function(room) deciding that instead (the default: outside, or the room's floor
-- within ROOM_SLACK).
function bumpLogic.crossedDoor(zone, current, px, py, x, y, fits)
    if current == nil or px == nil then
        return nil
    end
    local ix = zone._index
    for _, door in ipairs(ix.doorsOf[current] or {}) do
        if door.side ~= 0 and (door.nx ~= 0 or door.ny ~= 0) then
            local interior = ix.interiors[door.interior]
            local ax, ay = bumpLogic.toBuilding(interior, px, py)
            local bx, by = bumpLogic.toBuilding(interior, x, y)
            -- across the whole opening (its width known), else within DOOR_REACH of its centre: the Ruins of
            -- Lordaeron's sewer openings are 12 to 15 yd wide
            local function near(u, v)
                if door.half > 0 then
                    local along = math.abs((u - door.x) * -door.ny + (v - door.y) * door.nx)
                    local off = math.abs((u - door.x) * door.nx + (v - door.y) * door.ny)
                    return along <= door.half + bumpLogic.DOOR_SIDE and off <= bumpLogic.DOOR_REACH
                end
                return dist(u, v, door.x, door.y) <= bumpLogic.DOOR_REACH
            end
            if near(ax, ay) or near(bx, by) then
                local mine = current == door.a and door.side or -door.side
                local before = ((ax - door.x) * door.nx + (ay - door.y) * door.ny) * mine
                local after = ((bx - door.x) * door.nx + (by - door.y) * door.ny) * mine
                local behind = current == door.a and door.b or door.a
                if before > 0 and after < 0 then
                    local ok
                    if fits then
                        ok = fits(behind)
                    else
                        ok = behind == 0 or bumpLogic.onFloor(zone, behind, x, y, bumpLogic.ROOM_SLACK)
                    end
                    if ok then
                        return behind
                    end
                end
            end
        end
    end
    return nil
end

-- The room the player is in after a step from (px, py) to (x, y) while in room `current` (0 outside, nil unknown),
-- the surroundings module's resolveRoom without its floor layers. `byDoor`: the current room was entered through a
-- doorway. Returns the room (nil: nothing decides, keep what is known) and the candidate rooms here.
function bumpLogic.resolveRoom(zone, x, y, current, byDoor, indoors)
    local ix = zone._index
    local cands = bumpLogic.roomsAt(zone, x, y, bumpLogic.ROOM_MARGIN, indoors)
    local real = current ~= nil and current ~= 0
    -- a room the game's word does not fit while a candidate does is left (no longer held)
    if real and (ix.rooms[current].hallMap ~= nil) == indoors and #cands > 0
        and (ix.rooms[cands[1]].hallMap ~= nil) ~= indoors then
        real, byDoor = false, false
    end
    if byDoor and real then
        -- entered through a doorway: it holds while its floor is near, or near one of its doorways
        if bumpLogic.onFloor(zone, current, x, y, bumpLogic.ROOM_SLACK) then
            return current, cands
        end
        for _, door in ipairs(ix.doorsOf[current] or {}) do
            local dx, dy = bumpLogic.toWorld(ix.interiors[door.interior], door.x, door.y)
            if dist(dx, dy, x, y) <= bumpLogic.DOOR_HOLD then
                return current, cands
            end
        end
        -- no step leads into a room without a doorway between: near its floor it holds unless a room joined to it
        -- is here (the square's doorless room around Stormwind's Wizard's Sanctum took the player off its stairs)
        if bumpLogic.onFloor(zone, current, x, y, bumpLogic.ROOM_FAR) then
            local joined = false
            local neighbours = ix.neighbours[current] or {}
            for _, id in ipairs(bumpLogic.roomsAt(zone, x, y, bumpLogic.ROOM_SLACK, indoors)) do
                joined = joined or neighbours[id] == true
            end
            if not joined then
                return current, cands
            end
        end
    end
    if #cands == 0 then
        cands = bumpLogic.roomsAt(zone, x, y, bumpLogic.ROOM_SLACK, indoors)
    end
    if real then
        -- a room without any doorway is no room one walks into from another (only a guess where nothing else is)
        local kept = {}
        for _, id in ipairs(cands) do
            if id == current or ix.doorsOf[id] ~= nil then
                kept[#kept + 1] = id
            end
        end
        cands = kept
    end
    if #cands == 0 then
        return nil, cands
    end
    if #cands == 1 then
        return cands[1], cands
    end
    if current == nil then
        return nil, cands
    end
    -- several: the current room where it is among them, else the one joined to it by a doorway (from outside: the
    -- one entrance room)
    local joined = nil
    local neighbours = ix.neighbours[current] or {}
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

-- The hall rooms of the game's UI map `uiMap` whose floor is here (within ROOM_SLACK) and whose area, where known,
-- is the game's `subzone`. Halls the game calls outdoors (Ironforge's, almost all of the Undercity) carry the UI map
-- one stands on in them; the map does not tell floors apart everywhere (on the Ruins of Lordaeron's rose walk it is
-- the Undercity's, as in the city 110 yd below), so a hall also needs the game's area not to name another place
-- (the Magic Quarter under the Ruins' courtyard, where the game says "Ruins of Lordaeron").
function bumpLogic.hallsAt(zone, x, y, uiMap, subzone)
    local out = {}
    if uiMap == nil then
        return out
    end
    for id, room in ipairs(zone._index.rooms) do
        if room.hallMap == uiMap and (room.area == nil or subzone == nil or subzone == "" or room.area == subzone)
            and bumpLogic.onFloor(zone, id, x, y, bumpLogic.ROOM_SLACK) then
            out[#out + 1] = id
        end
    end
    return out
end

-- The room tracker: where the player is (room: an id, 0 outside, nil unknown inside), from look to look. `game` at
-- each look: { indoors = IsIndoors(), uiMap = the player's best UI map, subzone = GetSubZoneText() }.
local Tracker = {}
Tracker.__index = Tracker

function bumpLogic.newTracker()
    return setmetatable({ room = nil, byDoor = false, inHall = false, hallGap = 0, cands = nil }, Tracker)
end

-- Starts afresh (a new zone, a jump, a flight).
function Tracker:reset()
    self.room, self.byDoor, self.inHall, self.hallGap, self.cands = nil, false, false, 0, nil
end

-- Sets the room known from elsewhere (a spot kept over a reload, another module's tracker). `cands` (optional): the
-- candidate rooms here while the room is unknown.
function Tracker:set(room, inHall, cands)
    self.room, self.byDoor, self.inHall, self.hallGap = room, room ~= nil and room ~= 0, inHall and true or false, 0
    self.cands = cands
end

-- One look at (x, y), the last at (px, py) (nil: none).
function Tracker:update(zone, x, y, px, py, game)
    local ix = zone._index
    self.cands = nil
    local moved = px and dist(x, y, px, py) or 0
    -- through a doorway of the room the player is in (or from outside into an entrance room)
    local from = self.room
    if from == nil and not game.indoors and not self.inHall then
        from = 0
    end
    local crossed = bumpLogic.crossedDoor(zone, from, px, py, x, y)
    -- a room only guessed (not entered through a doorway) does not hide a doorway in from outside: the game calls
    -- parts of the square around Stormwind's Wizard's Sanctum indoors, the only room there is one without doorways
    -- (the square's own), and walking into the tower kept that room and named the square's trees (walk 2026-11-07)
    if crossed == nil and not self.byDoor and from ~= 0 then
        crossed = bumpLogic.crossedDoor(zone, 0, px, py, x, y)
    end
    if crossed ~= nil then
        self.room, self.byDoor = crossed, crossed ~= 0
        if crossed == 0 then
            self.inHall = false
        elseif ix.rooms[crossed].hallMap then
            self.inHall, self.hallGap = true, 0
        end
        return
    end
    -- the halls: in them while a hall's floor of the game's map is near, until HALL_GAP yd without one
    local halls = bumpLogic.hallsAt(zone, x, y, game.uiMap, game.subzone)
    if self.inHall then
        if #halls > 0 then
            self.hallGap = 0
        else
            self.hallGap = self.hallGap + moved
            if self.hallGap > bumpLogic.HALL_GAP or game.uiMap == nil then
                self.inHall, self.room, self.byDoor = false, nil, false
            end
        end
    elseif not game.indoors and #halls > 0 and (self.room == nil or self.room == 0) then
        -- into the halls without a doorway (Ironforge's gate: the game's map becomes the halls')
        self.inHall, self.hallGap, self.byDoor = true, 0, false
        self.room = #halls == 1 and halls[1] or nil
        self.cands = halls
        return
    end
    if not game.indoors and not self.inHall then
        -- just through a doorway the game's word may follow a look later: the room holds while its floor is here
        local r = self.room
        if not (self.byDoor and r ~= nil and r ~= 0 and bumpLogic.onFloor(zone, r, x, y, bumpLogic.ROOM_MARGIN)) then
            self.room, self.byDoor = 0, false
        end
        return
    end
    local found, cands = bumpLogic.resolveRoom(zone, x, y, self.room, self.byDoor, game.indoors)
    self.cands = cands
    if found ~= nil and found ~= self.room then
        self.room, self.byDoor = found, false
    end
end

-- Whether the player counts as inside: the game says indoors, in a hall it calls outdoors, or in a room just
-- entered through a doorway.
function Tracker:inside(game)
    return game.indoors or self.inHall or (self.room ~= nil and self.room ~= 0)
end

-- The rooms whose objects count: the room known, else the candidate rooms here, else nil (any room's).
function Tracker:objectRooms()
    if self.room ~= nil and self.room ~= 0 then
        return { [self.room] = true }
    end
    if self.cands and #self.cands > 0 then
        local set = {}
        for _, id in ipairs(self.cands) do
            set[id] = true
        end
        return set
    end
    return nil
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

-- What to say for a bump along the unit vector (vx, vy): the object in the way, else inside "wall", outside the wall
-- of the building or structure ahead. `rooms` as for objectAhead (inside: Tracker:objectRooms; not `inside and rooms
-- or 0`, which with the room unknown gave the outdoor objects). `words`: the locale's "wall" and "wall of %s".
-- `wall` (optional): another module's text for the wall ahead outside, function(x, y, vx, vy) -> text, key or nil,
-- asked before the building or structure here. Returns the text and a key that is the same for the same thing, or nil.
function bumpLogic.bumpText(zone, x, y, vx, vy, inside, rooms, words, wall)
    local search = 0
    if inside then
        search = rooms
    end
    local o = bumpLogic.objectAhead(zone, x, y, vx, vy, bumpLogic.REACH, search)
    if o then
        return zone._index.oname[o], o
    end
    if inside then
        return words.wall, "wall"
    end
    if wall then
        local text, key = wall(x, y, vx, vy)
        if text then
            return text, key
        end
    end
    local owner, what = bumpLogic.wallOwner(zone, x, y, vx, vy, bumpLogic.WALL_REACH)
    if owner and what == "place" then
        return string.format(zone._index.ofTemplate or "%s of %s", words.wall, owner), owner
    elseif owner then
        return string.format(words.wallOf, owner), owner
    end
    return nil
end

-- Questions other modules ask (a route avoiding objects, for one). The zone of the position is read in when
-- needed; one zone so read is kept besides the one the bump module holds (zone.held), the one before is dropped.
-- `which`: nil every object, 0 the outdoor ones, a room id that room's. Objects come as tables (bumpLogic.object)
-- with their `distance` in yards. Their footprints are boxes around the model (a tree's holds its crown): enough
-- to tell that something stands in the way, not exact collision. Names are in bumpLogic.locale (the bump module
-- sets the game's), English by default.
bumpLogic.locale = "enUS"
local queried = nil

-- The zone of map `map` holding the position, read in (nil: no data there).
function bumpLogic.zoneAt(map, x, y)
    local zone = bumpLogic.findZone(x, y, map)
    if zone == nil then
        return nil
    end
    if zone ~= queried then
        if queried and not queried.held then
            bumpLogic.pack(queried)
        end
        queried = zone
    end
    bumpLogic.unpack(zone, bumpLogic.locale)
    return zone
end

local function fitsWhich(ix, i, which)
    return which == nil or ix.oroom[i] == which
end

-- The objects whose footprint lies within `radius` yards of the position, nearest first.
function bumpLogic.objectsNear(map, x, y, radius, which)
    local zone = bumpLogic.zoneAt(map, x, y)
    local out = {}
    if zone == nil then
        return out
    end
    local ix = zone._index
    local r0, c0 = bumpLogic.cellOf(zone, x, y)
    local n = math.ceil(radius / zone.cell)
    local seen = {}
    for r = r0 - n, r0 + n do
        for c = c0 - n, c0 + n do
            for _, i in ipairs(ix.objects[blockOf(zone, r, c)] or {}) do
                if not seen[i] and r >= ix.or0[i] and r <= ix.or1[i] and c >= ix.oc0[i] and c <= ix.oc1[i] then
                    seen[i] = true
                    if fitsWhich(ix, i, which) then
                        local _, _, d = objectPoint(ix, i, x, y)
                        if d <= radius then
                            local o = bumpLogic.object(zone, i)
                            o.distance = d
                            out[#out + 1] = o
                        end
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        return a.distance < b.distance
    end)
    return out
end

-- The distance from the segment (u1, v1)-(u2, v2) to the box -hl..hl by -hw..hw (the object's own frame), and
-- where along the segment (0..1) it comes closest (where it enters the box when it crosses it).
local function segmentToBox(u1, v1, u2, v2, hl, hw)
    -- crossing: the segment clipped to the box (Liang-Barsky)
    local du, dv = u2 - u1, v2 - v1
    local t0, t1 = 0, 1
    local crosses = true
    for _, e in ipairs({ { -du, u1 + hl }, { du, hl - u1 }, { -dv, v1 + hw }, { dv, hw - v1 } }) do
        local pe, qe = e[1], e[2]
        if pe == 0 then
            if qe < 0 then
                crosses = false
            end
        else
            local t = qe / pe
            if pe < 0 then
                t0 = math.max(t0, t)
            else
                t1 = math.min(t1, t)
            end
        end
    end
    if crosses and t0 <= t1 then
        return 0, t0
    end
    local len2 = du * du + dv * dv
    local best, bestT = math.huge, 0
    local function pointToBox(u, v)
        local eu = math.max(0, math.abs(u) - hl)
        local ev = math.max(0, math.abs(v) - hw)
        return math.sqrt(eu * eu + ev * ev)
    end
    for _, t in ipairs({ 0, 1 }) do
        local d = pointToBox(u1 + du * t, v1 + dv * t)
        if d < best then
            best, bestT = d, t
        end
    end
    -- the box's corners against the segment
    for _, corner in ipairs({ { -hl, -hw }, { hl, -hw }, { hl, hw }, { -hl, hw } }) do
        local t = len2 > 0 and math.max(0, math.min(1, ((corner[1] - u1) * du + (corner[2] - v1) * dv) / len2)) or 0
        local d = dist(u1 + du * t, v1 + dv * t, corner[1], corner[2])
        if d < best then
            best, bestT = d, t
        end
    end
    return best, bestT
end

-- The first object a straight path from (x1, y1) to (x2, y2) passes within `clearance` yards of (one it crosses:
-- 0), with its `distance` and `along` (yards from the start to where the path comes closest), or nil. The path lies
-- in one zone of the data (nil where its end is outside the start's zone: ask in pieces).
function bumpLogic.objectOnLine(map, x1, y1, x2, y2, clearance, which)
    local zone = bumpLogic.zoneAt(map, x1, y1)
    if zone == nil or not bumpLogic.covers(zone, x2, y2) then
        return nil
    end
    local ix = zone._index
    local ra, ca = bumpLogic.cellOf(zone, math.max(x1, x2), math.max(y1, y2))
    local rb, cb = bumpLogic.cellOf(zone, math.min(x1, x2), math.min(y1, y2))
    local n = math.ceil(clearance / zone.cell)
    local length = dist(x1, y1, x2, y2)
    local best, bestAlong, bestD, seen = nil, math.huge, nil, {}
    for r = ra - n, rb + n do
        for c = ca - n, cb + n do
            for _, i in ipairs(ix.objects[blockOf(zone, r, c)] or {}) do
                if not seen[i] and r >= ix.or0[i] and r <= ix.or1[i] and c >= ix.oc0[i] and c <= ix.oc1[i] then
                    seen[i] = true
                    if fitsWhich(ix, i, which) then
                        local cs, sn = ix.ocos[i], ix.osin[i]
                        local ax, ay = x1 - ix.ox[i], y1 - ix.oy[i]
                        local bx, by = x2 - ix.ox[i], y2 - ix.oy[i]
                        local d, t = segmentToBox(ax * cs + ay * sn, -ax * sn + ay * cs, bx * cs + by * sn,
                            -bx * sn + by * cs, ix.ohl[i], ix.ohw[i])
                        local along = t * length
                        if d <= clearance and (along < bestAlong or (along == bestAlong and d < bestD)) then
                            best, bestAlong, bestD = i, along, d
                        end
                    end
                end
            end
        end
    end
    if best == nil then
        return nil
    end
    local o = bumpLogic.object(zone, best)
    o.distance, o.along = bestD, bestAlong
    return o
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
