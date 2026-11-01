-- WowNav engine by Broesel33 (github.com/Broesel33/WoW_NavigationData, DemoAddon/WowVisionNavigation/Guidance.lua at
-- 5b8b5f2), carried in WowVision with his permission. Changes for WowVision: see camelot/wownav/engine/README.md.

-- Guidance (schema 7, concept chapter 7 points 5 to 8): arrival at a waypoint, gate line, angle bisector, height
-- state of the route and local re-entry. Pure functions on the NavNetwork; the player state (Navigation.path, index,
-- announcements) stays in the core.
WowVisionNavigationGuidance = WowVisionNavigationGuidance or {}
local G = WowVisionNavigationGuidance

local sqrt, abs = math.sqrt, math.abs

local function Net() return WowVisionNavigationNavNetwork end

-- Distance in the plane
function G.Distance(x, y, bx, by)
    local dx, dy = bx - x, by - y
    return sqrt(dx * dx + dy * dy)
end

-- Player setting /vn arrival (SavedVariables arrivalMin): minimum arrival radius in yd. Fine points of the data (about
-- 0.3 yd) can be too small to hit; the effective radius is max(radius of the data, setting). 0 = off, the data decide.
-- WowVision: the setting is the wownav module's own (same range and default), written to G.arrivalMin.
function G.MinArrivalRadius()
    local value = G.arrivalMin
    if type(value) == "number" and value > 0 then return value end
    return 0
end

function G.EffectiveRadius(radius)
    if radius == nil then return nil end
    return math.max(radius, G.MinArrivalRadius())
end

-- Arrival radius of a waypoint in yd (nil for points without a code, e.g. the end point at the target)
function G.ArrivalRadius(id)
    return G.EffectiveRadius(Net().Radius(id))
end

-- Gate half width in yd or nil. Drives the final approach, the fallback and the click tolerance.
function G.Choke(id)
    return Net().GateHalfWidth(id)
end

-- Unit direction from a to b in the plane
local function Direction(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local l = sqrt(dx * dx + dy * dy)
    if l < 1e-9 then return nil end
    return dx / l, dy / l
end

-- Gate line (S10 point 5): perpendicular to the incoming link through the waypoint, 2 x half width long. Passing
-- counts when the movement (px,py) -> (x,y) crosses the line in link direction.
function G.GatePassed(px, py, x, y, waypointId, previousId)
    local net = Net()
    local halfWidth = net.GateHalfWidth(waypointId)
    if not halfWidth or not previousId or not px then return false end
    local ax, ay = net.Position(previousId)
    local wx, wy = net.Position(waypointId)
    local ux, uy = Direction(ax, ay, wx, wy)
    if not ux then return false end
    local ahead0 = (px - wx) * ux + (py - wy) * uy      -- distance along the link direction, negative = before
    local ahead1 = (x - wx) * ux + (y - wy) * uy
    if not (ahead0 < 0 and ahead1 >= 0) then return false end
    local t = ahead0 / (ahead0 - ahead1)               -- crossing point on the movement
    local sx, sy = px + (x - px) * t, py + (y - py) * t
    local lateral = abs((sx - wx) * -uy + (sy - wy) * ux)
    return lateral <= halfWidth
end

-- Angle bisector (chapter 7 point 6): is the player on the side of the next waypoint? The normal of the bisector is
-- u + v (u = incoming, v = outgoing direction); for a U-turn (u + v = 0) there is no bisector and the rule lapses.
function G.BisectorCrossed(x, y, waypointId, previousId, nextId)
    local net = Net()
    local ax, ay = net.Position(previousId)
    local wx, wy = net.Position(waypointId)
    local cx, cy = net.Position(nextId)
    local ux, uy = Direction(ax, ay, wx, wy)
    local vx, vy = Direction(wx, wy, cx, cy)
    if not ux or not vx then return false end
    local nx, ny = ux + vx, uy + vy
    if sqrt(nx * nx + ny * ny) < 1e-6 then return false end
    return (x - wx) * nx + (y - wy) * ny > 0
end

-- Advance condition (chapter 7 point 6). p: x, y (position), px, py (position at the previous update, optional),
-- z (height estimate or nil), waypointId, previousId, nextId, swimming.
-- Returns reached (bool), rule ("radius" | "gate" | "bisector")
function G.Reached(p)
    local net = Net()
    local wx, wy = net.Position(p.waypointId)
    local radius = G.ArrivalRadius(p.waypointId)
    if radius and G.Distance(p.x, p.y, wx, wy) <= radius then return true, "radius" end
    if p.previousId and p.px and G.GatePassed(p.px, p.py, p.x, p.y, p.waypointId, p.previousId) then
        return true, "gate"
    end
    if p.previousId and p.nextId and net.Area(p.waypointId) == "OPEN"
        and G.BisectorCrossed(p.x, p.y, p.waypointId, p.previousId, p.nextId)
        and net.AttachmentAtPosition(p.x, p.y, p.z, p.nextId, { swimming = p.swimming }) then
        return true, "bisector"
    end
    return false
end

-- Progress and lateral offset on the incoming link (telemetry and fallback only): t = 0 at the previous, 1 at the
-- current waypoint; lateral = sideways distance to the segment.
function G.SegmentProgress(x, y, fromId, toId)
    local net = Net()
    if not fromId or not net.Exists(fromId) or not net.Exists(toId) then return nil, nil end
    local ax, ay = net.Position(fromId)
    local bx, by = net.Position(toId)
    local dx, dy = bx - ax, by - ay
    local l2 = dx * dx + dy * dy
    if l2 < 0.0001 then return 1.0, 0.0 end
    local t = ((x - ax) * dx + (y - ay) * dy) / l2
    local tc = math.max(0.0, math.min(1.0, t))
    local qx, qy = ax + tc * dx, ay + tc * dy
    return t, sqrt((x - qx) ^ 2 + (y - qy) ^ 2)
end

-- Height along the current segment (chapter 7 point 8): open links are single-layer, fine links use the height of
-- the end points. Both are the same linear interpolation between the end points.
function G.Height(previousId, waypointId, x, y)
    local net = Net()
    if not net.Exists(waypointId) then return nil end
    local _, _, wz = net.Position(waypointId)
    if not previousId or not net.Exists(previousId) then return wz end
    local ax, ay, az = net.Position(previousId)
    local wx, wy = net.Position(waypointId)
    local before = G.Distance(x, y, ax, ay)
    local after = G.Distance(x, y, wx, wy)
    local total = before + after
    if total <= 0 then return wz end
    return az + (wz - az) * (before / total)
end

-- Local re-entry (B14): the player stands in an attachment cell whose attachment is a later point of the existing
-- route (bit of the player's field set) and that point is closer than the current waypoint: continue there.
-- The closest candidate wins. Returns new index, distance | nil
function G.Reenter(path, index, x, y, z, opts)
    local net = Net()
    local current = path[index]
    if not current or not net.Exists(current) then return nil end
    local ax, ay = net.Position(current)
    local currentDistance = G.Distance(x, y, ax, ay)
    local best, bestDistance
    for i = index + 1, #path do
        local id = path[i]
        if net.Exists(id) then
            local px, py = net.Position(id)
            local d = G.Distance(x, y, px, py)
            if d < currentDistance and (not bestDistance or d < bestDistance)
                and net.AttachmentAtPosition(x, y, z, id, opts) then
                best, bestDistance = i, d
            end
        end
    end
    if best then return best, bestDistance end
    return nil
end
