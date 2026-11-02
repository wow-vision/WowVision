-- What the route to the target does (targetRoute.lua): pure Lua over a small game interface, so the headless suite
-- tests it. The target's position comes from the game for a group member (UnitPosition), and for a creature from the
-- route engine's catalogue: the nearest target with the creature's ID from its GUID (WowNav knows every NPC and mob of
-- its zones by that ID). Without a route engine the route data's nearest waypoint of the target's name stands in.
--
-- api: exists() -> bool; isPlayer() -> bool (the target is the player); name() -> the target's name;
-- player() -> px, py, map or nil; groupUnit() -> the target's party or raid unit or nil; unitPosition(unit) -> x, y or
-- nil; guid() -> the target's GUID or nil; engine: the active route engine or nil (engine:startAt(px, py, map) ->
-- start | nil, why ("ambiguous": the floor is not clear), engine:unitTarget(creatureId, px, py, map) -> a row of its
-- list | nil); waypointNamed(name, px, py) -> the route data's nearest waypoint of that name | nil (no engine);
-- hasRouteData() -> bool (no engine).
--
-- plan(api) returns one of
--   { say = text }                          nothing starts
--   { say = text, window = target }         the navigation window opens with the target preselected
--   { route = target, start = start }       the route starts (start: the engine's; nil with the route data)
-- target: { x, y, z, n, data, waypoint } (data: what the route engine gets; waypoint: the route data's own waypoint).
local targetFind = {}
WowVision.targetFind = targetFind

local L = WowVision:getLocale()

-- How far from the player a catalogue target or a waypoint of the target's name may lie to stand for the target: a
-- creature is targeted from about this far at most, a farther one of the same kind is another spawn.
targetFind.UNIT_RADIUS = 120

-- The creature ID in a creature's or vehicle's GUID ("Creature-0-1465-0-2105-448-000043F59F": 448), nil for any other.
function targetFind.creatureId(guid)
    if type(guid) ~= "string" then
        return nil
    end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind == "Creature" or kind == "Vehicle" then
        return tonumber(id)
    end
    return nil
end

-- Where the target stands, as a target of the plan; nil when nothing tells.
function targetFind.locate(api, px, py, map)
    local name = api.name()
    local unit = api.groupUnit()
    if unit ~= nil then
        local x, y = api.unitPosition(unit)
        if x ~= nil then
            -- the unit, so the route engine reads the position again on a new route (WowNav: a live target)
            return { x = x, y = y, n = name, data = { unit = unit } }
        end
    end
    local creature = targetFind.creatureId(api.guid())
    if creature == nil then
        return nil
    end
    if api.engine ~= nil then
        local row = api.engine:unitTarget(creature, px, py, map)
        if row == nil then
            return nil
        end
        return { x = row.x, y = row.y, z = row.z, n = row.n or name, data = row }
    end
    local wp = api.waypointNamed(name, px, py)
    if wp == nil then
        return nil
    end
    return { x = wp.x, y = wp.y, z = wp.z, n = wp.n, waypoint = wp }
end

function targetFind.plan(api)
    if not api.exists() then
        return { say = L["You have no target"] }
    end
    if api.isPlayer() then
        return { say = L["You are targeting yourself"] }
    end
    local px, py, map = api.player()
    if px == nil then
        return { say = L["Position unavailable"] }
    end
    local target = targetFind.locate(api, px, py, map)
    if target == nil then
        return { say = L["Your target's position is not known"] }
    end
    if api.engine ~= nil then
        local start, why = api.engine:startAt(px, py, map)
        if start ~= nil then
            return { route = target, start = start }
        end
        if why == "ambiguous" then
            return { say = L["Your floor is not clear here. Choose your start."], window = target }
        end
        return { say = L["No route to your target"] }
    end
    if not api.hasRouteData() then
        return { say = L["No route to your target"] }
    end
    return { route = target }
end
