local testRunner = WowVision.testing.testRunner
local bumpLogic = WowVision.bumpLogic

-- A small zone: a 200 x 200 yd grid around (0, 0). Building 1 (the bank) is not turned: world x = -vx, world y =
-- -vy; its room 1 spans world x 5..10, y -5..5, with a doorway from outside at world x 5; room 2 lies on the same
-- floor boxes (a floor over it) and joins room 1 by a doorway. Building 2 is named only by its place (Old Town) and
-- stands at y 45..55. A barrel stands outdoors at (0, 0), a crate in room 1 at (8, 0), a chair in room 2 at (8, 3).
-- A city wall covers the cell of (-20, -2), a canal edge (a water structure) the cell of (-30, -2).
local function makeZone(locale)
    local zone = {
        key = "test", map = 0, top = 100, left = 100, cell = 4, rows = 50, cols = 50,
        objects = "0 0 5 5 0 1 0 80 0 5 5 0 2 1 80 30 5 5 0 3 2",
        objectNames = { enUS = { "barrel", "crate", "chair" }, deDE = { "Fass", "", "Stuhl" } },
        interiors = "0 0 1 1 0 0 1 0 50 1 1 0 0 1",
        interiorNames = { enUS = { "bank", "building of Old Town" }, deDE = { "Bank", "" } },
        interiorWalls = { enUS = { [2] = "Old Town" }, deDE = { [2] = "Altstadt" } },
        rooms = "1 0 4 -10 -5 -5 5 4 -10.5 -5.5 -4.5 5.5 1 0 4 -10 -5 -5 5 0 2 0 4 -5 -5 5 5 0",
        doors = "0 1 1 -5 0 1 0 1 2 1 2 1 -7 4 0 1 1 1",
        structCells = "30 25 1 1 32 25 1 2",
        waterStructs = { 2 },
        structNames = { enUS = { "city wall", "canal" } },
        ofTemplate = { enUS = "%s of %s", deDE = "%s, %s" },
    }
    bumpLogic.unpack(zone, locale or "enUS")
    return zone
end

local WORDS = { wall = "wall", wallOf = "wall of %s" }

testRunner:addSuite("BumpLogic", {
    ["the object in the way is named, not one behind"] = function(t)
        local zone = makeZone()
        -- standing 1 yd west of the barrel (its box reaches 0.5 yd), pushing east
        local o = bumpLogic.objectAhead(zone, 0, -1, 0, 1, bumpLogic.REACH, 0)
        t:assertEqual(o and o.name, "barrel")
        t:assertNil(bumpLogic.objectAhead(zone, 0, -1, 0, -1, bumpLogic.REACH, 0))
        -- out of reach
        t:assertNil(bumpLogic.objectAhead(zone, 0, -3, 0, 1, bumpLogic.REACH, 0))
    end,

    ["an object touched counts whichever way the player pushes"] = function(t)
        local zone = makeZone()
        local o = bumpLogic.objectAhead(zone, 0, -0.6, 0, -1, bumpLogic.REACH, 0)
        t:assertEqual(o and o.name, "barrel")
    end,

    ["outdoors only outdoor objects, indoors only the room's"] = function(t)
        local zone = makeZone()
        t:assertNil(bumpLogic.objectAhead(zone, 7, 0, 1, 0, bumpLogic.REACH, 0))
        local o = bumpLogic.objectAhead(zone, 7, 0, 1, 0, bumpLogic.REACH, { [1] = true })
        t:assertEqual(o and o.name, "crate")
        t:assertNil(bumpLogic.objectAhead(zone, 7, 0, 1, 0, bumpLogic.REACH, { [2] = true }))
        o = bumpLogic.objectAhead(zone, 7, 3, 1, 0, bumpLogic.REACH, nil)
        t:assertEqual(o and o.name, "chair")
    end,

    ["names in the game's language, English where it has none"] = function(t)
        local zone = makeZone("deDE")
        t:assertEqual(bumpLogic.objectAhead(zone, 0, -1, 0, 1, bumpLogic.REACH, 0).name, "Fass")
        t:assertEqual(bumpLogic.objectAhead(zone, 7, 0, 1, 0, bumpLogic.REACH, nil).name, "crate")
        t:assertEqual(zone._index.interiors[1].name, "Bank")
        t:assertEqual(zone._index.interiors[2].name, "building of Old Town")
    end,

    ["a turned object's footprint follows its angle"] = function(t)
        local zone = {
            key = "turned", map = 0, top = 100, left = 100, cell = 4, rows = 50, cols = 50,
            -- a fence 6 yd long, 0.2 yd wide, its long axis along y (90 degrees)
            objects = "0 0 30 1 90 1 0", objectNames = { enUS = { "fence" } },
            interiors = "", interiorNames = {}, interiorWalls = {}, rooms = "", doors = "", structCells = "",
            structNames = { enUS = {} },
        }
        bumpLogic.unpack(zone, "enUS")
        -- 2.5 yd along the fence, 0.5 yd beside it: pushing toward it names it
        t:assertEqual(bumpLogic.objectAhead(zone, -0.5, 2.5, 1, 0, bumpLogic.REACH, 0).name, "fence")
        -- 4 yd along its axis is beyond its end
        t:assertNil(bumpLogic.objectAhead(zone, -0.5, 4.5, 1, 0, bumpLogic.REACH, 0))
    end,

    ["outside a building its wall is named"] = function(t)
        local zone = makeZone()
        t:assertEqual(bumpLogic.bumpText(zone, 3.5, 0, 1, 0, false, nil, WORDS), "wall of bank")
        -- a building named only by its place: "wall of Old Town", in German "Wand, Altstadt"
        t:assertEqual(bumpLogic.bumpText(zone, 0, 43.5, 0, 1, false, nil, WORDS), "wall of Old Town")
        local de = makeZone("deDE")
        t:assertEqual(bumpLogic.bumpText(de, 0, 43.5, 0, 1, false, nil, { wall = "Wand", wallOf = "Wand von %s" }),
            "Wand, Altstadt")
    end,

    ["a structure's wall is named, a water edge is not"] = function(t)
        local zone = makeZone()
        t:assertEqual(bumpLogic.bumpText(zone, -17.5, -2, -1, 0, false, nil, WORDS), "wall of city wall")
        t:assertNil(bumpLogic.bumpText(zone, -27.5, -2, -1, 0, false, nil, WORDS))
    end,

    ["indoors without an object it is a wall"] = function(t)
        local zone = makeZone()
        t:assertEqual(bumpLogic.bumpText(zone, 9.5, -4.5, 0, -1, true, { [1] = true }, WORDS), "wall")
        local text, key = bumpLogic.bumpText(zone, 7, 0, 1, 0, true, { [1] = true }, WORDS)
        t:assertEqual(text, "crate")
        t:assertEqual(key, bumpLogic.objectAhead(zone, 7, 0, 1, 0, bumpLogic.REACH, { [1] = true }))
    end,

    ["the room is the one walked into through a doorway"] = function(t)
        local zone = makeZone()
        -- rooms 1 and 2 share floor boxes: from nowhere the room is unknown, both are candidates
        local room, cands = bumpLogic.resolveRoom(zone, 8, 0, nil, nil, nil, true)
        t:assertNil(room)
        t:assertEqual(#cands, 2)
        -- through the doorway from outside into room 1
        t:assertEqual(bumpLogic.crossedDoor(zone, 0, 4, 0, 6, 0), 1)
        t:assertEqual((bumpLogic.resolveRoom(zone, 6, 0, 0, 4, 0, true)), 1)
        -- staying in it
        t:assertEqual((bumpLogic.resolveRoom(zone, 8, 0, 1, 6, 0, true)), 1)
        -- and out again
        t:assertEqual((bumpLogic.resolveRoom(zone, 4, 0, 1, 6, 0, true)), 0)
        -- a step past the doorway's side does not cross it
        t:assertNil(bumpLogic.crossedDoor(zone, 0, 4, 4, 6, 4))
    end,

    ["a bump is named once until the player moved freely"] = function(t)
        local state = bumpLogic.newBumpState()
        t:assertFalse(bumpLogic.step(state, true, 0, 0.2)) -- one look blocked is not yet a bump
        t:assertTrue(bumpLogic.step(state, true, 0, 0.2))
        t:assertTrue(bumpLogic.take(state, "barrel"))
        t:assertTrue(bumpLogic.step(state, true, 0, 0.2))
        t:assertFalse(bumpLogic.take(state, "barrel"))
        -- moving a little is not enough
        bumpLogic.step(state, false, 1, 0.2)
        bumpLogic.step(state, true, 0, 0.2)
        t:assertTrue(bumpLogic.step(state, true, 0, 0.2))
        t:assertFalse(bumpLogic.take(state, "barrel"))
        -- something else is said at once
        t:assertTrue(bumpLogic.take(state, "fence"))
        -- after a second of moving freely the same thing again
        for _ = 1, 5 do
            bumpLogic.step(state, false, 1, 0.2)
        end
        bumpLogic.step(state, true, 0, 0.2)
        bumpLogic.step(state, true, 0, 0.2)
        t:assertTrue(bumpLogic.take(state, "fence"))
        -- nothing found keeps the last thing
        t:assertFalse(bumpLogic.take(state, nil))
        t:assertFalse(bumpLogic.take(state, "fence"))
    end,

    ["the zone is found by map and position"] = function(t)
        local saved = bumpLogic.zones
        bumpLogic.zones = {}
        local zone = { key = "z", map = 0, top = 100, left = 100, cell = 4, rows = 50, cols = 50 }
        bumpLogic.addZone(zone)
        t:assertEqual(bumpLogic.findZone(0, 0, 0), zone)
        t:assertNil(bumpLogic.findZone(0, 0, 1))
        t:assertNil(bumpLogic.findZone(150, 0, 0))
        bumpLogic.zones = saved
    end,
})

-- The packed data itself (mapdata/bumps; the headless runner loads every client's, the game its own): every zone
-- reads back, its rooms and doorways point at what exists, and a player pushing at an object finds it.
testRunner:addSuite("BumpData", {
    ["every zone of the bump data reads back"] = function(t)
        for _, zone in ipairs(bumpLogic.zones) do
            local had = zone._index ~= nil
            local ix = bumpLogic.unpack(zone, "enUS")
            local objects, named = 0, 0
            local seen = {}
            for _, bucket in pairs(ix.objects) do
                for _, o in ipairs(bucket) do
                    if not seen[o] then
                        seen[o] = true
                        objects = objects + 1
                        named = named + (o.name and 1 or 0)
                        t:assertTrue(o.room == 0 or ix.rooms[o.room] ~= nil, zone.key .. ": object in a room that is missing")
                    end
                end
            end
            t:assertTrue(objects > 0, zone.key .. ": no objects")
            t:assertEqual(named, objects, zone.key .. ": objects without a name")
            for id, room in ipairs(ix.rooms) do
                t:assertTrue(ix.interiors[room.interior] ~= nil, zone.key .. ": room " .. id .. " of a missing building")
                t:assertEqual(#room.boxes % 4, 0, zone.key .. ": room " .. id .. " boxes")
            end
            for room, doors in pairs(ix.doorsOf) do
                t:assertTrue(room == 0 or ix.rooms[room] ~= nil, zone.key .. ": doorway of a missing room")
                for _, door in ipairs(doors) do
                    t:assertTrue(ix.interiors[door.interior] ~= nil, zone.key .. ": doorway of a missing building")
                end
            end
            -- pushing toward an object from beside it finds one (the first hundred outdoor ones)
            local tried = 0
            for o in pairs(seen) do
                if o.room == 0 and tried < 100 then
                    tried = tried + 1
                    local radius = math.sqrt(o.halfLength ^ 2 + o.halfWidth ^ 2)
                    local x = o.x - radius - 0.2
                    local qx, qy, d = bumpLogic.objectPoint(o, x, o.y)
                    t:assertTrue(bumpLogic.objectAhead(zone, x, o.y, (qx - x) / d, (qy - o.y) / d, d + 0.1, 0) ~= nil,
                        zone.key .. ": nothing found beside an object")
                end
            end
            if not had then
                bumpLogic.pack(zone)
            end
        end
    end,
})
