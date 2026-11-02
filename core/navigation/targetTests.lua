local testRunner = WowVision.testing.testRunner
local targetFind = WowVision.targetFind

local L = WowVision:getLocale()

local GUARD = "Creature-0-1465-0-2105-4262-000043F59F"

-- A game with a target. o: { exists, isPlayer, name, player (false: no position), unit, positions (by unit), guid,
-- engine: { start, why, rows (by creature ID) } or nil, waypoints (by name), routeData }
local function api(o)
    local engine = nil
    if o.engine ~= nil then
        engine = {
            asked = {},
            startAt = function(self, px, py, map)
                return o.engine.start, o.engine.why
            end,
            unitTarget = function(self, creatureId, px, py, map)
                self.asked[#self.asked + 1] = creatureId
                return (o.engine.rows or {})[creatureId]
            end,
        }
    end
    return {
        exists = function()
            return o.exists ~= false
        end,
        isPlayer = function()
            return o.isPlayer == true
        end,
        name = function()
            return o.name or "Darnassus Sentinel"
        end,
        player = function()
            if o.player == false then
                return nil
            end
            return 9950, 2500, 1
        end,
        groupUnit = function()
            return o.unit
        end,
        unitPosition = function(unit)
            local p = (o.positions or {})[unit]
            if p == nil then
                return nil
            end
            return p[1], p[2]
        end,
        guid = function()
            return o.guid
        end,
        engine = engine,
        waypointNamed = function(name, px, py)
            return (o.waypoints or {})[name]
        end,
        hasRouteData = function()
            return o.routeData == true
        end,
    }
end

local ROW = { x = 9960, y = 2510, z = 1310, n = "Darnassus Sentinel", tid = "creature_4262" }

testRunner:addSuite("RouteToTarget", {
    ["the creature ID of a creature's or a vehicle's GUID, nothing for any other"] = function(t)
        t:assertEqual(targetFind.creatureId(GUARD), 4262)
        t:assertEqual(targetFind.creatureId("Vehicle-0-1465-0-2105-28670-000043F59F"), 28670)
        t:assertNil(targetFind.creatureId("Player-1465-0A1B2C3D"))
        t:assertNil(targetFind.creatureId("Pet-0-1465-0-2105-416-0100000001"))
        t:assertNil(targetFind.creatureId(nil))
    end,

    ["no target, yourself, or no position: said, nothing starts"] = function(t)
        local plan = targetFind.plan(api({ exists = false, engine = { start = {} } }))
        t:assertEqual(plan.say, L["You have no target"])
        t:assertNil(plan.route)
        t:assertEqual(targetFind.plan(api({ isPlayer = true })).say, L["You are targeting yourself"])
        t:assertEqual(targetFind.plan(api({ player = false, guid = GUARD })).say, L["Position unavailable"])
    end,

    ["a creature from the engine's catalogue: the route starts where the floor is clear"] = function(t)
        local a = api({ guid = GUARD, engine = { start = { nodeId = 7 }, rows = { [4262] = ROW } } })
        local plan = targetFind.plan(a)
        t:assertNil(plan.say)
        t:assertEqual(plan.start.nodeId, 7)
        t:assertEqual(plan.route.x, 9960)
        t:assertEqual(plan.route.z, 1310)
        t:assertEqual(plan.route.data, ROW, "the engine gets its own row")
        t:assertEqual(a.engine.asked[1], 4262)
    end,

    ["the floor at the player is not clear: said, and the window opens with the target"] = function(t)
        local plan = targetFind.plan(api({ guid = GUARD, engine = { why = "ambiguous", rows = { [4262] = ROW } } }))
        t:assertEqual(plan.say, L["Your floor is not clear here. Choose your start."])
        t:assertEqual(plan.window.data, ROW)
        t:assertNil(plan.route)
    end,

    ["no network at the player, or the creature unknown: said, nothing starts"] = function(t)
        local plan = targetFind.plan(api({ guid = GUARD, engine = { why = "none", rows = { [4262] = ROW } } }))
        t:assertEqual(plan.say, L["No route to your target"])
        t:assertNil(plan.route)
        t:assertNil(plan.window)
        plan = targetFind.plan(api({ guid = GUARD, engine = { start = { nodeId = 7 } } }))
        t:assertEqual(plan.say, L["Your target's position is not known"])
        t:assertNil(plan.route)
    end,

    ["a group member: the game's position, with the unit for a new route"] = function(t)
        local plan = targetFind.plan(api({ name = "Lyra", unit = "party2", positions = { party2 = { 9900, 2400 } },
            guid = "Player-1465-0A1B2C3D", engine = { start = { nodeId = 7 } } }))
        t:assertEqual(plan.route.x, 9900)
        t:assertEqual(plan.route.n, "Lyra")
        t:assertEqual(plan.route.data.unit, "party2")
    end,

    ["a player outside the group has no position"] = function(t)
        local plan = targetFind.plan(api({ name = "Lyra", guid = "Player-1465-0A1B2C3D", engine = { start = {} } }))
        t:assertEqual(plan.say, L["Your target's position is not known"])
    end,

    ["the route data: the nearest waypoint of the target's name, else nothing"] = function(t)
        local wp = { id = 12, n = "Darnassus Sentinel", x = 9955, y = 2505 }
        local plan = targetFind.plan(api({ guid = GUARD, routeData = true, waypoints = { ["Darnassus Sentinel"] = wp } }))
        t:assertEqual(plan.route.waypoint, wp)
        t:assertNil(plan.start)
        plan = targetFind.plan(api({ guid = GUARD, routeData = true }))
        t:assertEqual(plan.say, L["Your target's position is not known"])
        plan = targetFind.plan(api({ name = "Lyra", unit = "party1", positions = { party1 = { 1, 2 } } }))
        t:assertEqual(plan.say, L["No route to your target"], "no route data and no engine")
    end,
})
