-- The route to the target (a key of its own, unbound by default): where the current target stands (targetFind.lua),
-- then a route there from the nearest point of the network. With a route engine (WowNav) the route starts at the
-- player's position when the floor there is clear, as Ctrl-Shift-N does; when it is not, that is said and the
-- navigation window (F10) opens with the target preselected, as for the scanner's Enter, to pick the start. The route
-- data start at the entry point F10 would preselect. No position, or no route: that is said and nothing starts (no
-- straight beacon).
local navigation = WowVision.base.navigation
local maps = navigation.maps
local targetFind = WowVision.targetFind
local L = navigation.L

local function usable(value)
    return value ~= nil and not WowVision.isSecret(value)
end

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function unitPosition(unit)
    local ok, x, y = pcall(UnitPosition, unit)
    if ok and usable(x) and usable(y) and finite(x) and finite(y) then
        return x, y
    end
    return nil
end

-- The party or raid unit that is the target, nil when the target is in no group of the player's.
local function groupUnit()
    local raid = IsInRaid ~= nil and IsInRaid()
    local count = GetNumGroupMembers ~= nil and GetNumGroupMembers() or 0
    for i = 1, raid and count or math.min(count, 4) do
        local unit = raid and ("raid" .. i) or ("party" .. i)
        if UnitExists(unit) and UnitIsUnit(unit, "target") and not UnitIsUnit(unit, "player") then
            return unit
        end
    end
    return nil
end

local function gameApi()
    local engine = maps:activeRouteEngine()
    return {
        exists = function()
            return UnitExists("target") == true
        end,
        isPlayer = function()
            return UnitIsUnit("target", "player") == true
        end,
        name = function()
            local name = UnitName("target")
            return usable(name) and name or L["Target"]
        end,
        player = function()
            local px, py, _, map = UnitPosition("player")
            if px == nil then
                return nil
            end
            return px, py, map
        end,
        groupUnit = groupUnit,
        unitPosition = unitPosition,
        guid = function()
            local guid = UnitGUID("target")
            return usable(guid) and guid or nil
        end,
        engine = engine,
        waypointNamed = function(name, px, py)
            local fold = WowVision.utils.foldCase
            local wanted = fold(name)
            local found = WowVision.Router.nearest(maps:currentWaypoints(), px, py, 1, function(wp)
                return wp.n ~= nil and fold(wp.n) == wanted
            end)[1]
            if found == nil or found.distance > targetFind.UNIT_RADIUS then
                return nil
            end
            return found.waypoint
        end,
        hasRouteData = function()
            return next(maps:currentWaypoints()) ~= nil
        end,
    }
end

local TARGET_ID = "routeToTarget"

-- The plan carried out: said, the window opened, or the route started.
function maps:routeToTarget()
    local api = gameApi()
    local plan = targetFind.plan(api)
    if plan.say ~= nil then
        WowVision:notify(plan.say)
    end
    local target = plan.window or plan.route
    if target == nil then
        return false
    end
    if plan.window ~= nil then
        maps:openNavigationTo(target.x, target.y, target.n, nil, target.data)
        return false
    end
    -- the destination of Ctrl-Shift-N and the visited waypoints, as if picked in F10
    local wp = target.waypoint
        or { id = TARGET_ID, n = target.n, x = target.x, y = target.y, z = target.z, virtual = true, routeData = target.data }
    maps.lastDestination = wp
    local onArrive = maps:arrivalFor(wp)
    WowVision:notify(target.n)
    if api.engine ~= nil then
        if maps:routeTo(target.x, target.y, target.n, onArrive, target.z, target.data, plan.start) then
            return true
        end
        WowVision:notify(L["No route to your target"])
        return false
    end
    local px, py, map = api.player()
    local waypoints = maps:currentWaypoints()
    if wp.virtual then
        waypoints[wp.id] = wp
    end
    local entry = maps:preselectedEntry(maps:entryPoints(waypoints, px, py, map, nil))
    return maps:navigateTo(wp.id, waypoints, { entryId = entry and entry.waypoint.id, onArrive = onArrive })
end

maps:registerBinding({
    type = "Script",
    key = "maps/routeToTarget",
    label = L["Route to Your Target"],
    inputs = {},
    script = "/run WowVision.base.navigation.maps:routeToTarget()",
})
