local module = WowVision.base.navigation:createModule("bumps")
local L = module.L
module:setLabel(L["Name What I Bump Into"])

-- Naming what the player bumps into: when the wall detection says they push against something (its
-- "blocked", held for a moment), the object in the way ("barrel", "fence", "mine cart"), or outdoors the
-- wall of the building or structure ahead ("wall of Stormwind Keep"), or indoors a wall. Once per bump;
-- the same thing again only after moving freely. The data (mapdata/bumps/<client>/, tools/bumps/pack.lua)
-- covers the zones the surroundings data has been exported for; elsewhere nothing is said. Nothing while
-- the wall detection is off. Toggle it via the alert's enable.
--
-- Which room the player is in comes from bumpLogic's tracker (doorways walked through, room floors, the
-- game's map in the halls). A module that knows better can hand its room over: module:setRoomSource.

local bumpLogic = WowVision.bumpLogic

-- Spoken with game voice 0, not the player's speech voice: with an NVDA SAPI voice there, the screen reader
-- cuts its speech off at the next key press, and the player is pressing movement keys.
local alert = module:addAlert({ key = "bump", label = L["Name What I Bump Into"] })
alert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    voice = 0,
    buildMessage = function(self, message)
        return message.text
    end,
})

local settings = module:hasSettings()
settings:addRef("bump", alert.parameters)

local CHECK_INTERVAL = 0.2
local FRESH = 0.5 -- seconds the wall detection's grading counts

local zone = nil
local tracker = bumpLogic.newTracker()
local lastCheck, lastTime = 0, nil
local lastX, lastY = nil, nil
local state = bumpLogic.newBumpState()
local restored = false
local roomSource = nil

-- Another module's room for this zone, used instead of the tracker's: `source(zone)` returns the room (an id of
-- the bump data's rooms, 0 outside, nil unknown), whether the player is in a hall the game calls outdoors, and
-- optionally a function(x, y, vx, vy) giving the text and key of the wall ahead outside (asked before the bump
-- data's buildings and structures); or false when it knows nothing here (the tracker's then). It must number the
-- rooms as the bump data does (zone.roomsId, the packed rooms' fingerprint, tells which). nil removes it.
function module:setRoomSource(source)
    roomSource = source
end

local function locale()
    local l = GetLocale()
    return l == "enGB" and "enUS" or l
end

local function setZone(found)
    if found == zone then
        return
    end
    if zone then
        bumpLogic.pack(zone)
    end
    zone = found
    tracker:reset()
    if found then
        bumpLogic.unpack(found, locale())
    end
end

-- The spot and room of the last look, kept over a reload or a logout (per character): a login upstairs in a
-- tavern starts in that room, not "unknown".
local function keepHere(x, y)
    if WowVisionDB == nil or zone == nil then
        return
    end
    local h = WowVisionDB.bumpsHere
    if type(h) ~= "table" then
        h = {}
        WowVisionDB.bumpsHere = h
    end
    h.zone, h.roomsId, h.x, h.y, h.room, h.hall = zone.key, zone.roomsId, x, y, tracker.room, tracker.inHall
end

local function restoreHere(x, y)
    restored = true
    local h = WowVisionDB and WowVisionDB.bumpsHere
    if type(h) == "table" and h.zone == zone.key and h.roomsId == zone.roomsId and type(h.x) == "number"
        and bumpLogic.dist(h.x, h.y, x, y) <= bumpLogic.HERE_SAME then
        tracker:set(h.room, h.hall)
    end
end

-- The bumps named, to check a walk afterwards: WowVisionDump.bumps (saved at a reload or logout), the last
-- RECORD_KEPT lines "<date time> <zone> <x> <y> room=<room held> inside=<true|false> rooms=<rooms whose objects
-- counted> <text>" (room nil: unknown; rooms empty: outdoor objects, or any room's).
local RECORD_KEPT = 200
local function record(x, y, inside, rooms, text)
    WowVisionDump = WowVisionDump or {}
    local list = WowVisionDump.bumps
    if type(list) ~= "table" then
        list = {}
        WowVisionDump.bumps = list
    end
    local ids = {}
    for id in pairs(rooms or {}) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    list[#list + 1] = string.format("%s %s %.1f %.1f room=%s inside=%s rooms=%s %s", date("%Y-%m-%d %H:%M:%S"),
        zone.key, x, y, tostring(tracker.room), tostring(inside and true or false), table.concat(ids, ","), text)
    while #list > RECORD_KEPT do
        table.remove(list, 1)
    end
end

-- The way the player pushes from the movement keys held and the facing, as a unit vector, or nil.
local function pushDirection()
    local facing = GetPlayerFacing()
    if facing == nil or WowVision.isSecret(facing) then
        return nil
    end
    local flags = WowVision.movement.flags
    local ahead = ((flags.moveForward or flags.autorun) and 1 or 0) - (flags.moveBackward and 1 or 0)
    local side = (flags.strafeLeft and 1 or 0) - (flags.strafeRight and 1 or 0)
    local vx = ahead * math.cos(facing) + side * math.cos(facing + math.pi / 2)
    local vy = ahead * math.sin(facing) + side * math.sin(facing + math.pi / 2)
    local len = math.sqrt(vx * vx + vy * vy)
    if len < 0.1 then
        return nil
    end
    return vx / len, vy / len
end

-- The wall detection's fresh "blocked", while it is switched on (it grades on while its alert is off).
local function blocked(now)
    local walls = WowVision.base.navigation.walls
    local stuck = walls and walls.alerts.stuck
    return stuck ~= nil and stuck.enabled and walls.severity == 1 and now - (walls.severityAt or 0) <= FRESH
end

local function forget()
    lastX, lastY, lastTime = nil, nil, nil
    tracker:reset()
    state = bumpLogic.newBumpState()
end

module:hasUpdate(function(self)
    local now = GetTime()
    if now - lastCheck < CHECK_INTERVAL then
        return
    end
    lastCheck = now
    if not alert.enabled or UnitOnTaxi("player") then
        forget()
        return
    end
    local x, y, _, map = UnitPosition("player")
    if x == nil or WowVision.isSecret(x) then
        forget()
        return
    end
    local found = zone
    if zone == nil or zone.map ~= map or not bumpLogic.covers(zone, x, y) then
        found = bumpLogic.findZone(x, y, map)
    end
    setZone(found)
    local px, py, dt = lastX, lastY, lastTime and now - lastTime
    lastX, lastY, lastTime = x, y, now
    if zone == nil then
        return
    end
    if not restored then
        restoreHere(x, y)
    end
    if px ~= nil and bumpLogic.dist(x, y, px, py) > bumpLogic.JUMP then
        -- moved by the game (a hearthstone, a portal, a graveyard): starts afresh
        tracker:reset()
        px, py = nil, nil
    end
    local game = { indoors = IsIndoors(), uiMap = C_Map.GetBestMapForUnit("player"), subzone = GetSubZoneText() }
    local given, givenHall, givenWall = false, nil, nil
    if roomSource then
        given, givenHall, givenWall = roomSource(zone)
    end
    if given ~= false then
        -- (with the room unknown, the rooms whose floor is here count)
        local cands = nil
        if given == nil then
            cands = bumpLogic.roomsAt(zone, x, y, bumpLogic.ROOM_MARGIN, game.indoors)
        end
        tracker:set(given, givenHall, cands)
    else
        tracker:update(zone, x, y, px, py, game)
    end
    keepHere(x, y)
    if px == nil then
        return
    end
    local moved = bumpLogic.dist(x, y, px, py)
    if IsSwimming() then
        state.ticks = 0
        return
    end
    if not bumpLogic.step(state, blocked(now), moved, dt) then
        return
    end
    local vx, vy = pushDirection()
    if vx == nil then
        return
    end
    local inside, rooms = tracker:inside(game), tracker:objectRooms()
    local text, key = bumpLogic.bumpText(zone, x, y, vx, vy, inside, rooms,
        { wall = L["wall"], wallOf = L["wall of %s"] }, givenWall)
    if bumpLogic.take(state, key) then
        record(x, y, inside, rooms, text)
        self:fireAlert("bump", { text = text })
    end
end)
