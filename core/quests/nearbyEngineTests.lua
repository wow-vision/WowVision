local testRunner = WowVision.testing.testRunner
local Engine = WowVision.quests.NearbyEngine

-- The player at the origin facing 0, as UnitPosition and GetPlayerFacing give it: facing 0 is north, which is
-- the first coordinate (x) growing; the second (y) grows to the west. So a point straight ahead is at (+x, 0), one
-- to the right at (0, -y).
local function player(overrides)
    local p = { x = 0, y = 0, continent = 1, facing = 0 }
    for k, v in pairs(overrides or {}) do
        p[k] = v
    end
    return p
end

local function opts(overrides)
    local o = {
        available = { range = 40, once = true },
        turnIn = { range = 60, once = true },
        objective = { range = 50, once = true },
        stopDistance = 5,
        gap = 0.3,
    }
    for k, v in pairs(overrides or {}) do
        o[k] = v
    end
    return o
end

-- A point straight ahead of a player at the origin, distance yards away.
local function ahead(key, kind, distance, questIds)
    return {
        key = key,
        kind = kind,
        questIds = questIds or { 1 },
        titles = { "Quest " .. key },
        spawns = { { x = distance, y = 0, continent = 1 } },
    }
end

local function engineWith(points)
    local engine = Engine.new()
    engine:setCatalog(points)
    return engine
end

-- Ticks until a ping comes or the time runs out; returns the ping and the time it came at.
local function pingWithin(engine, p, from, seconds, o)
    for step = 0, seconds * 10 do
        local now = from + step / 10
        local ping = engine:tick(p, now, o)
        if ping ~= nil then
            return ping, now
        end
    end
    return nil
end

testRunner:addSuite("QuestNearbyEngine", {
    ["level counts five yards a step and a step for every three degrees past twenty"] = function(t)
        t:assertEqual(Engine.level(0, 0), 0)
        t:assertEqual(Engine.level(4, 0), 1)
        t:assertEqual(Engine.level(24, 0), 5)
        t:assertEqual(Engine.level(24, 20), 5, "twenty degrees is still ahead")
        t:assertEqual(Engine.level(24, 29), 8)
        t:assertEqual(Engine.level(24, -29), 8, "left and right alike")
    end,

    ["a target too far to the side or behind has no level"] = function(t)
        t:assertNil(Engine.level(10, 180))
        t:assertNil(Engine.level(10, 110))
        t:assertEqual(Engine.level(10, 100), 2 + 26)
        -- narrower when far: 145 yards is level 29 before the angle
        t:assertEqual(Engine.level(144, 0), 29)
        t:assertNil(Engine.level(144, 24))
        t:assertNil(Engine.level(149, 0))
    end,

    ["the interval is distance over fifteen, one to five and a half seconds"] = function(t)
        t:assertEqual(Engine.interval(0), 1.0)
        t:assertEqual(Engine.interval(15), 1.0)
        t:assertEqual(Engine.interval(30), 2.0)
        t:assertEqual(Engine.interval(200), 5.5)
    end,

    ["relative angle is zero ahead and positive to the right"] = function(t)
        t:assertEqual(Engine.relativeAngle(0, 0, 0, 10, 0), 0)
        t:assertEqual(Engine.relativeAngle(0, 0, 0, 0, -10), 90, "east of a player facing north")
        t:assertEqual(Engine.relativeAngle(0, 0, 0, 0, 10), -90, "west of a player facing north")
        t:assertEqual(math.abs(Engine.relativeAngle(0, 0, 0, -10, 0)), 180)
        -- turning the player to the west (the facing grows counterclockwise) puts a target in the north on the right
        t:assertEqual(Engine.relativeAngle(0, 0, math.rad(90), 10, 0), 90)
        -- a facing past half a turn counts as a turn the other way
        t:assertEqual(math.floor(Engine.relativeAngle(0, 0, math.rad(270), 10, 0) + 0.5), -90)
    end,

    ["a point pings once its interval has run, then stays silent with once"] = function(t)
        local engine = engineWith({ ahead("a", "available", 30) })
        local o = opts()
        local p = player()
        t:assertNil(engine:tick(p, 0, o), "the clock starts when it came into range")
        t:assertNil(engine:tick(p, 1.9, o))
        local ping = engine:tick(p, 2.0, o)
        t:assertTrue(ping ~= nil)
        t:assertEqual(ping.point.key, "a")
        t:assertEqual(ping.distance, 30)
        t:assertEqual(ping.level, 6)
        t:assertEqual(ping.angle, 0)
        t:assertNil(pingWithin(engine, p, 2.1, 30, o), "done")
    end,

    ["without once the point pings again after its interval"] = function(t)
        local engine = engineWith({ ahead("a", "available", 30) })
        local o = opts({ available = { range = 40, once = false } })
        local p = player()
        engine:tick(p, 0, o)
        local _, first = pingWithin(engine, p, 0.1, 5, o)
        t:assertTrue(math.abs(first - 2.0) < 0.01)
        local ping, second = pingWithin(engine, p, first + 0.1, 5, o)
        t:assertTrue(ping ~= nil)
        t:assertTrue(math.abs(second - (first + 2.0)) < 0.11, "an interval after the last ping")
    end,

    ["a point out of range never pings"] = function(t)
        local engine = engineWith({ ahead("a", "available", 45) })
        t:assertNil(pingWithin(engine, player(), 0, 20, opts()))
    end,

    ["closer than the stop distance is done without a ping"] = function(t)
        local engine = engineWith({ ahead("a", "available", 3) })
        local o = opts()
        t:assertNil(pingWithin(engine, player(), 0, 10, o))
        -- and it stays done when the player steps back out to ping distance
        t:assertNil(pingWithin(engine, player({ x = -20 }), 10, 10, o))
    end,

    ["resetMap lets a done point ping again"] = function(t)
        local engine = engineWith({ ahead("a", "turnIn", 30) })
        local o = opts()
        local p = player()
        t:assertTrue(pingWithin(engine, p, 0, 5, o) ~= nil)
        t:assertNil(pingWithin(engine, p, 6, 5, o))
        engine:resetMap()
        t:assertTrue(pingWithin(engine, p, 12, 5, o) ~= nil)
    end,

    ["an objective is fresh again after the player left its range by thirty yards"] = function(t)
        local engine = engineWith({ ahead("o", "objective", 30) })
        local o = opts()
        t:assertTrue(pingWithin(engine, player(), 0, 5, o) ~= nil)
        t:assertNil(pingWithin(engine, player(), 6, 5, o))
        -- 70 away: past range 50 but not past 80
        engine:tick(player({ x = -40 }), 12, o)
        t:assertNil(pingWithin(engine, player(), 13, 5, o), "not far enough away yet")
        -- 90 away: past range + 30
        engine:tick(player({ x = -60 }), 19, o)
        t:assertTrue(pingWithin(engine, player(), 20, 5, o) ~= nil)
    end,

    ["a giver does not re-arm by the player walking away"] = function(t)
        local engine = engineWith({ ahead("g", "available", 30) })
        local o = opts()
        t:assertTrue(pingWithin(engine, player(), 0, 5, o) ~= nil)
        engine:tick(player({ x = -200 }), 6, o)
        t:assertNil(pingWithin(engine, player(), 7, 10, o))
    end,

    ["a new quest at a done giver pings again"] = function(t)
        local engine = engineWith({ ahead("g", "available", 30, { 1 }) })
        local o = opts()
        local p = player()
        t:assertTrue(pingWithin(engine, p, 0, 5, o) ~= nil)
        t:assertNil(pingWithin(engine, p, 6, 5, o))
        engine:setCatalog({ ahead("g", "available", 30, { 1 }) })
        t:assertNil(pingWithin(engine, p, 12, 5, o), "the same quest again is nothing new")
        engine:setCatalog({ ahead("g", "available", 30, { 1, 2 }) })
        t:assertTrue(pingWithin(engine, p, 18, 5, o) ~= nil)
    end,

    ["a point on another continent is ignored"] = function(t)
        local point = ahead("a", "available", 20)
        point.spawns[1].continent = 2
        local engine = engineWith({ point })
        t:assertNil(pingWithin(engine, player(), 0, 10, opts()))
        -- and it counts as soon as the player is over there
        t:assertTrue(pingWithin(engine, player({ continent = 2 }), 10, 5, opts()) ~= nil)
    end,

    ["only one point pings per tick, the nearest first"] = function(t)
        local engine = engineWith({ ahead("far", "available", 30), ahead("near", "turnIn", 20) })
        local o = opts()
        local p = player()
        engine:tick(p, 0, o)
        local ping = engine:tick(p, 2.0, o)
        t:assertEqual(ping.point.key, "near")
        t:assertNil(engine:tick(p, 2.1, o), "the gap holds the next one back")
        local second = engine:tick(p, 2.4, o)
        t:assertEqual(second.point.key, "far")
    end,

    ["a target turned away pings as soon as the player turns to it"] = function(t)
        local engine = engineWith({ ahead("a", "available", 30) })
        local o = opts()
        local away = player({ facing = math.pi })
        t:assertNil(pingWithin(engine, away, 0, 10, o), "behind the player")
        local ping = engine:tick(player(), 10.1, o)
        t:assertTrue(ping ~= nil, "its interval ran while it was out of view")
    end,

    ["a moved player sees the points of a new area"] = function(t)
        local far = ahead("far", "available", 500)
        local engine = engineWith({ far })
        local o = opts()
        t:assertNil(pingWithin(engine, player(), 0, 5, o))
        local ping = pingWithin(engine, player({ x = 480 }), 5, 5, o)
        t:assertTrue(ping ~= nil)
        t:assertEqual(ping.point.key, "far")
    end,

    ["clear forgets the catalog and every state"] = function(t)
        local engine = engineWith({ ahead("a", "available", 30) })
        local o = opts()
        t:assertTrue(pingWithin(engine, player(), 0, 5, o) ~= nil)
        engine:clear()
        t:assertNil(pingWithin(engine, player(), 6, 5, o))
        engine:setCatalog({ ahead("a", "available", 30) })
        t:assertTrue(pingWithin(engine, player(), 12, 5, o) ~= nil)
    end,
})
