local module = WowVision.base.navigation:createModule("bumps")
local L = module.L
module:setLabel(L["Name What I Bump Into"])

-- Naming what the player bumps into: when the wall detection says they push against something (its
-- "blocked", held for a moment), the object in the way ("barrel", "fence", "mine cart"), or outdoors the
-- wall of the building or structure ahead ("wall of Stormwind Keep"), or indoors a wall. Once per bump;
-- the same thing again only after moving freely. The data (mapdata/bumps/<client>/, tools/bumps-pack.lua)
-- covers the zones the surroundings data has been exported for; elsewhere nothing is said. Nothing while
-- the wall detection is off. Toggle it via the alert's enable.

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
local FRESH = 0.5 -- seconds the wall detection's grading counts (it stops while disabled)
local JUMP = 100 -- yd between two looks from which the player was moved (a hearthstone, a portal)

local zone = nil
local room = nil -- the room the player is in as far as known
local lastCheck, lastTime = 0, nil
local lastX, lastY = nil, nil
local state = bumpLogic.newBumpState()

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
    zone, room = found, nil
    if found then
        bumpLogic.unpack(found, locale())
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

local function blocked(now)
    local walls = WowVision.base.navigation.walls
    return walls ~= nil and walls.severity == 1 and now - (walls.severityAt or 0) <= FRESH
end

local function forget()
    lastX, lastY, lastTime, room = nil, nil, nil, nil
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
    if zone == nil or px == nil then
        return
    end
    local moved = math.sqrt((x - px) ^ 2 + (y - py) ^ 2)
    if moved > JUMP then
        room = nil
        return
    end
    -- the room: outdoors 0 unless a doorway was just walked through (the game's word may follow a look later);
    -- indoors by doorways and floors (0 or nil there: unknown, the rooms whose floor is here count)
    local indoors = IsIndoors()
    local cands = nil
    if indoors then
        room, cands = bumpLogic.resolveRoom(zone, x, y, room, px, py, indoors)
    else
        local crossed = bumpLogic.crossedDoor(zone, room or 0, px, py, x, y)
        if crossed then
            room = crossed
        elseif room == nil or room == 0 or not bumpLogic.onFloor(zone, room, x, y, bumpLogic.ROOM_SLACK) then
            room = bumpLogic.hallAt(zone, x, y) or 0
        end
    end
    -- in a hall the game calls outdoors (Ironforge's, the Undercity's) as in a room
    local inside = indoors or (room ~= nil and room ~= 0 and zone._index.rooms[room].hall)
    if IsSwimming() or not bumpLogic.step(state, blocked(now), moved, dt) then
        return
    end
    local vx, vy = pushDirection()
    if vx == nil then
        return
    end
    -- indoors the objects of the room the player is in, else of the rooms whose floor is here, else of any room
    local rooms = nil
    if room and room ~= 0 then
        rooms = { [room] = true }
    elseif cands and #cands > 0 then
        rooms = {}
        for _, id in ipairs(cands) do
            rooms[id] = true
        end
    end
    local text, key = bumpLogic.bumpText(zone, x, y, vx, vy, inside, rooms, { wall = L["wall"], wallOf = L["wall of %s"] })
    if bumpLogic.take(state, key) then
        self:fireAlert("bump", { text = text })
    end
end)
