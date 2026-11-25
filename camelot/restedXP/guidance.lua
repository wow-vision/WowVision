-- Leading the player to the arrow's destination with WowVision's own navigation: a sound beacon (it ticks from the
-- direction of the destination, faster as you face it, with a click when you line up and the distance in the
-- sound) or a route through WowNav's network. Both are WowVision's: this only hands them the point RestedXP's
-- arrow shows, and follows the arrow when RestedXP moves it to the next one.
--
-- WowVision's maps use UnitPosition's coordinates; RestedXP's arrow keeps HereBeDragons' world coordinates, which
-- are the same two numbers the other way round (HereBeDragons reads UnitPosition as y, x).
local ns = WowVision.restedXP
local L = ns.L

local Guidance = {}
ns.Guidance = Guidance

-- Where the arrow's destination is, as a WowVision map destination (the shape the corpse run gives
-- maps:goToDestination: a point with no links, so the route ends with a straight leg; WowNav takes the lowest floor
-- where it lies over several).
function Guidance.destination(arrow)
    return {
        id = "restedxp",
        n = arrow.title or L["Destination"],
        x = arrow.wy,
        y = arrow.wx,
        virtual = true,
        routeData = { lowestFloor = true },
    }
end

-- How far, in yards, the arrow's destination has to move before it counts as another destination. By default only an
-- arrow that did not move at all (a centimetre) is the same destination. RestedXP's arrow can drift by a few yards (a
-- creature that walks, a point worked out from where the player stands) and a guidance that is redone, and a
-- destination that is said again, at every drift is noise for some players: for them there is an option, "Ignore
-- small moves of the arrow", and then a destination under `smallMove` yards from the one aimed at is the same.
Guidance.exact = 0.01
Guidance.smallMove = 10

-- Where the arrow's destination is, kept to compare with a later one; nil when the arrow has none.
function Guidance.point(arrow)
    if arrow == nil or arrow.none or arrow.wx == nil then
        return nil
    end
    return { x = arrow.wx, y = arrow.wy or 0, instance = arrow.instance }
end

-- Whether `now` is another destination than `before` (both from Guidance.point): in another instance, or further
-- than `tolerance` yards (Guidance.exact when none is given). With nothing before, it is another.
function Guidance.moved(before, now, tolerance)
    if before == nil then
        return true
    end
    if before.instance ~= now.instance then
        return true
    end
    local dx, dy = now.x - before.x, now.y - before.y
    return math.sqrt(dx * dx + dy * dy) > (tolerance or Guidance.exact)
end

-- What guides now: "beacon", "route", or nil. following is the same, kept while the arrow is followed.
-- lastPoint is where the guidance was last aimed (not where the arrow was last seen: small drifts add up against it).
Guidance.following = nil
Guidance.lastPoint = nil

-- Starts the guidance toward the arrow. mode is "beacon" (a straight sound beacon) or "route" (WowNav's route).
-- maps is WowVision's maps module. Returns true when it started, else false and a sentence saying why.
function Guidance.start(maps, arrow, mode)
    if maps == nil then
        return false, L["WowVision's navigation is not available."]
    end
    if arrow == nil or arrow.none or arrow.wx == nil then
        return false, L["No destination in the guide right now."]
    end
    if arrow.otherContinent then
        return false, L["The destination is on another continent."]
    end
    local destination = Guidance.destination(arrow)
    local ok, result
    if mode == "route" and maps.goToDestination ~= nil then
        ok, result = pcall(maps.goToDestination, maps, destination, false)
    elseif maps.directTo ~= nil then
        ok, result = pcall(maps.directTo, maps, destination.x, destination.y, destination.n)
    elseif maps.beaconTo ~= nil then
        ok, result = pcall(maps.beaconTo, maps, destination.x, destination.y, destination.n)
    else
        return false, L["WowVision's navigation is not available."]
    end
    if not ok then
        return false, tostring(result)
    end
    if mode == "route" and result == false then
        return false, L["No route found."]
    end
    Guidance.following = mode == "route" and "route" or "beacon"
    Guidance.lastPoint = Guidance.point(arrow)
    return true
end

-- Ends the guidance and the following. WowVision's own cancel (Shift+F12) is hooked to call this too.
function Guidance.stop(maps)
    Guidance.following = nil
    Guidance.lastPoint = nil
    if maps ~= nil and maps.isGuiding ~= nil and maps:isGuiding() and maps.cancelNavigation ~= nil then
        maps:cancelNavigation()
        return true
    end
    return false
end

-- Called every moment while the arrow is followed: when RestedXP's arrow has gone to another destination (see
-- Guidance.moved, with `tolerance`), guides there. Returns true when it did. Does nothing when no guidance was asked,
-- when the arrow has no destination (the guidance already running goes on), when it is on another continent, or when
-- it has not moved further than the tolerance from where the guidance was last aimed.
function Guidance.follow(maps, arrow, tolerance)
    local mode = Guidance.following
    if mode == nil then
        return false
    end
    local point = Guidance.point(arrow)
    if point == nil or arrow.otherContinent or not Guidance.moved(Guidance.lastPoint, point, tolerance) then
        return false
    end
    -- Asked once per destination: a start that fails is not tried again every moment.
    Guidance.lastPoint = point
    return (Guidance.start(maps, arrow, mode))
end
