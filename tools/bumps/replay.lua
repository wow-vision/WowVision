-- Replays logged walks through the room tracker (bumpLogic.newTracker) and says how often it knows the room inside,
-- how often it is unsure on stacked floors, and, where the log has it, whether its hall state agrees with the log's.
--
--   luajit tools/bumps/replay.lua <client> <walk log> [locale]      (from the repo root)
--
-- The walk log is a Lua file setting WowVisionDump.surroundings.trail, a list of lines
--   "<unix time> <x> <y> [flags] [|<subzone>]"
-- one per 2 yd walked: x and y as UnitPosition gives them; flags: i (IsIndoors), h (in a hall the game calls
-- outdoors, by the logging module's own judgement), s (swimming), g (ghost), a (falling), f<facing degrees>,
-- p<floor piece>, m<UI map id> (C_Map.GetBestMapForUnit; only when it or the subzone changed, or now and then);
-- the subzone (GetSubZoneText) after a bar, likewise only when it changed. The surroundings module's walk log
-- (local, not in this repository) writes this format. `locale`: the game's language of the walk (the subzone names
-- are compared with the data's in that language; default deDE).

local client, path, locale = arg[1], arg[2], arg[3] or "deDE"
assert(client and path, "usage: luajit tools/bumps/replay.lua <client> <walk log> [locale]")
local bumpLogic = dofile("tools/bumps/load.lua")(client)
dofile(path)
local trail = WowVisionDump.surroundings.trail

local GAP_TIME, GAP_DIST = 120, 30 -- seconds or yd between two points from which the walk starts afresh
local s = { inside = 0, known = 0, offFloor = 0, stacked = 0, unknown = 0, hallBoth = 0, hallLog = 0, hallOurs = 0,
    zoneless = 0 }
local zone, tracker = nil, bumpLogic.newTracker()
local px, py, pt, uiMap, subzone = nil, nil, nil, nil, nil
for _, line in ipairs(trail) do
    local t, x, y, rest = line:match("^(%d+) (%S+) (%S+)(.*)$")
    t, x, y = tonumber(t), tonumber(x), tonumber(y)
    local flags, tail = rest:match("^ ?([^|]*)|?(.*)$")
    local m = flags:match("m(%d+)")
    if m then
        uiMap = tonumber(m)
    end
    if tail ~= "" then
        subzone = tail
    end
    local indoors = flags:sub(1, 1) == "i"
    local logHall = flags:match("^i?h") ~= nil
    local found = nil
    for _, z in ipairs(bumpLogic.zones) do
        if bumpLogic.covers(z, x, y) then
            found = z
            break
        end
    end
    if found == nil then
        s.zoneless = s.zoneless + 1
        px = nil
    else
        if found ~= zone then
            if zone then
                bumpLogic.pack(zone)
            end
            zone = found
            bumpLogic.unpack(zone, locale)
            tracker:reset()
            px = nil
        end
        if px and (bumpLogic.dist(x, y, px, py) > GAP_DIST or t - pt > GAP_TIME) then
            tracker:reset()
            px = nil
        end
        tracker:update(zone, x, y, px, py, { indoors = indoors, uiMap = uiMap, subzone = subzone })
        if logHall and tracker.inHall then
            s.hallBoth = s.hallBoth + 1
        elseif logHall then
            s.hallLog = s.hallLog + 1
        elseif tracker.inHall then
            s.hallOurs = s.hallOurs + 1
        end
        if indoors or logHall then
            s.inside = s.inside + 1
            if tracker.room ~= nil and tracker.room ~= 0 then
                s.known = s.known + 1
                if not bumpLogic.onFloor(zone, tracker.room, x, y, bumpLogic.ROOM_SLACK) then
                    s.offFloor = s.offFloor + 1
                end
            elseif #bumpLogic.roomsAt(zone, x, y, bumpLogic.ROOM_MARGIN, indoors) > 1 then
                s.stacked = s.stacked + 1
            else
                s.unknown = s.unknown + 1
            end
        end
        px, py, pt = x, y, t
    end
end
local function pct(n)
    return 100 * n / math.max(1, s.inside)
end
print(string.format("%d trail points, %d outside the data's zones; inside (indoors or in a hall) %d",
    #trail, s.zoneless, s.inside))
print(string.format("room known %d (%.1f%%); of those more than %.0f yd off the room's floor %d",
    s.known, pct(s.known), bumpLogic.ROOM_SLACK, s.offFloor))
print(string.format("room unknown on stacked floors %d (%.1f%%), unknown elsewhere %d (%.1f%%)",
    s.stacked, pct(s.stacked), s.unknown, pct(s.unknown)))
print(string.format("halls: the log and the tracker %d, only the log %d, only the tracker %d",
    s.hallBoth, s.hallLog, s.hallOurs))
