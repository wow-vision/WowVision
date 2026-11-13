-- A WowNav route, followed the way Broesel's WowNav core follows it (DemoAddon/WowVisionNavigation/WowVisionNavigation.lua
-- of WoW_NavigationData, sections 4 to 4c, and ActionNavigation.lua): the start binding with the route state, the
-- target resolution (TargetResolver) with a check that a route exists, the route start with its cut at a transit and
-- the logical end point, the arrival rules (Guidance.Reached), the stagnation and blockage watch with the local
-- re-entry and the choke fallback, the manual new route with an edge penalty, and the transit continuation. Names and
-- order follow his functions, so each rule can be compared with its source; the reasons are in his comments there.
--
-- What WowVision does instead of his core: the sounds and the beacon (path.lua hands the current waypoint to
-- WowVision's Path), the speech (WowVision's texts, module.lua), the target list (catalog.lua) and the floor choice
-- (floorsUi.lua instead of /vn ebene). Left out with the user's decision: the Sku beacon, click/clack and final
-- approach tones, the blockage beep and its telemetry. The dock guidance (waiting, boarding, the noted counterpart
-- dock) is in dock.lua; a route to a dock ends at its waiting point (waitCheck), vehicles are never part of a route.
-- A walk-in target (portal, tram entrance; his TransitActivation) has no arrival: the prepoint and the capture
-- circle are said and the route stays until the map changes. Routes to docks and walk-in targets are on foot.
-- Changed because the game gives no height (UnitPosition z is 0 on Forever): the arrival after a transit is proven in
-- the plane (see ActionObserve).
--
-- Pure apart from env: the module (or a test) gives the game state through env (see wownavRoute.new). All searches run
-- inside N.Job, so a caller steps them in time slices.

local Route = {}
Route.__index = Route
WowVision.wownavRoute = Route

local sqrt, abs, atan2, max, min = math.sqrt, math.abs, math.atan2, math.max, math.min

-- His constants (WowVisionNavigation.lua section 4).
Route.ARRIVAL_TARGET_RADIUS = 1.5     -- yd: end point at the target position (logical target)
Route.UPDATE_INTERVAL = 0.25          -- s between two guidance updates
Route.BLOCKAGE_CHECK_INTERVAL = 0.5   -- s without noticeable movement despite an attempt to walk
Route.BLOCKAGE_MIN_MOVEMENT = 1.0     -- yd: below this it counts as stuck
Route.BLOCKAGE_MOVEMENT_TOLERANCE = 0.5 -- s: "tries to walk" survives short dropouts of the moving flag
Route.BLOCKAGE_ESCALATION_WAIT_TIME = 1.5 -- s of continuous sticking until escalation
Route.BLOCKAGE_EDGE_PENALTY = 1000.0  -- yd on the blocked link of a manual new route
Route.STAGNATION_WINDOW = 10.0        -- s observation window
Route.STAGNATION_MIN_APPROACH = 2.0   -- yd the distance has to drop within the window
Route.STAGNATION_MIN_TRAVEL = 5.0     -- yd of way covered in the window ("moves")
Route.FALLBACK_LOCK = 20.0            -- s during which the same waypoint does not fall back again
Route.ZUNKNOWN_SKIP_RADIUS = 1.5      -- yd: the first node under the player is skipped (his 2.25 = 1.5 squared)
-- The transit phases of his ActionNavigation (waiting, boarding/activating, travelling) each get one timeout of the
-- action; WowVision has no confirmation commands, so the three run as one span.
Route.ACTION_PHASES = 3
-- WowVision's own: a jump of the player farther than this between two observations is a teleport (a portal walked into)
Route.TELEPORT_JUMP = 50.0
-- WowVision's own: yd before a walk-in transit's source volume where it is announced once (its teleport comes at once)
Route.TRANSIT_AHEAD = 15.0
-- WowVision's own: yd above and below a walk-in transit's source volume within which the route is at its height
Route.TRANSIT_HEIGHT = 5.0
-- WowVision's own: yd around the player within which the nearest cell is the start when the player stands in none
-- (his N.START_RADIUS is 3; a step beside the network was "no network here")
Route.START_RADIUS = 30.0

-- Whether the network reaches the target of a resolution: exact, or approximate with its network ending within the
-- radius on land. On Forever the game gives no height for a live target (a quest marker, the current target, the
-- scanner), so a target on its network point resolves "approximate" only for want of one ("0.0 yards"): that end is
-- checked like an exact one. The last-stretch warning and the arrival text both ask this.
function Route.reachesTarget(result, radius)
    if result == nil or result.quality == "exact" then
        return true
    end
    return not result.normalizedWater and (result.delta3D or result.deltaXY or 0) <= radius
end

-- His chokeFallback setting (WowVisionNavigationDB, written from WowVision's settings by the module): on unless false.
function Route.chokeFallback()
    return not (type(WowVisionNavigationDB) == "table" and WowVisionNavigationDB.chokeFallback == false)
end

local function distance(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    return sqrt(dx * dx + dy * dy)
end
Route.distance = distance

-- env: N (NavNetwork), G (Guidance), R (TargetResolver), C (TargetCatalog), and functions
--   position() -> x, y, nativeMap        swimming() -> bool       now() -> seconds
--   facing() -> radians or nil           moving() -> bool         speed() -> yd/s or nil (secret: nil)
function Route.new(env)
    local self = setmetatable({}, Route)
    self.env = env
    self.N, self.G, self.R, self.C = env.N, env.G, env.R, env.C
    self.A = env.A or _G.WowVisionNavigationTransitActivation
    self.penalties = {}       -- EdgePenalties[a][b] in yd, dropped at the end of the route
    self.anchor = { height = nil, preferred = nil, last = nil }   -- his HeightAnchor
    self:reset()
    return self
end

-- ---------------------------------------------------------------------------------------------------------------
-- 4a. Height and layer state of the route
-- ---------------------------------------------------------------------------------------------------------------

function Route:setHeightAnchor(height)
    self.anchor.height = height
    if height ~= nil then
        self.anchor.last = height
    end
end

-- The most recently steered waypoints: a stacked start cell attached to one of them wins.
function Route:setRouteState(previousId, waypointId)
    local set = {}
    for _, id in ipairs({ previousId or false, waypointId or false }) do
        if id and id < self.N.VIRT_BASE then
            set[id] = true
        end
    end
    if next(set) ~= nil then
        self.anchor.preferred = set
    end
end

function Route:estimatedHeight()
    if self.env.swimming() then
        return nil
    end
    return self.anchor.height
end

function Route:startOptions()
    return { swimming = self.env.swimming(), preferred = self.anchor.preferred, lastHeight = self.anchor.last,
        radius = Route.START_RADIUS }
end

-- Binds a position to the network. Returns id, binding | nil, reason ("ambiguous" | "no_attachment" | ...).
function Route:startBinding(x, y)
    local binding, reason = self.N.Bind(x, y, self:estimatedHeight(), self:startOptions())
    if not binding then
        return nil, reason
    end
    return self.N.BindingId(binding), binding
end

-- Route from a start attachment; when it finds no way, the other start attachments of the cell and of the cells next
-- to it are tried before "no network path" (his 4.41, from a game test on a slope). Runs inside a job.
-- Cost comparison (his K): with a position, a start that is a checked attachment of the start cell is compared with the
-- other checked attachments of that cell; endPool (optional) does the same for the target side. The pair with the lowest
-- approach + network + approach cost wins; usedStartId and result.targetBinding name it. Unchecked attachments and those of
-- neighbouring cells only serve as alternatives when no route exists.
-- Returns path, edges, result, usedStartId | nil, reason.
function Route:routeFromStart(startId, endId, footOnly, x, y, endPool)
    local N = self.N
    local options, startPool
    if x then
        options = self:startOptions()
        if not options.swimming then
            local primary = N.Bind(x, y, self:estimatedHeight(), options)
            if primary then
                local pool = N.CertifiedBindings(primary.zone, primary.cell, x, y, primary.cellDistance)
                for _, member in ipairs(pool) do
                    if member.id == startId then
                        startPool = pool
                        break
                    end
                end
            end
        end
    end
    local result, reason = N.RouteIds(startId, endId, self.penalties, footOnly, startPool, endPool)
    if result or not x then
        if result then
            return result.path, result.edges, result, result.startBinding and result.startBinding.id or startId
        end
        return nil, reason
    end
    local list = N.StartBindings(x, y, self:estimatedHeight(), options)
    for _, binding in ipairs(list or {}) do
        if binding.id ~= startId then
            local alternative = N.RouteIds(binding.id, endId, self.penalties, footOnly, nil, endPool)
            if alternative then
                return alternative.path, alternative.edges, alternative, binding.id
            end
        end
    end
    return nil, reason
end

-- ---------------------------------------------------------------------------------------------------------------
-- Arrival
-- ---------------------------------------------------------------------------------------------------------------

function Route:waypointIsReached(x, y, waypointId, previousId, afterId)
    -- a route to a dock: the last waypoint counts only inside the proven waiting circle (his WaypointIsReached with
    -- Navigation.waitTargetId; the normal arrival radius can be larger than that circle)
    if self.waitCheck and not afterId and not self.waitCheck(x, y) then
        return false
    end
    local reached, rule = self.G.Reached({
        x = x, y = y, px = self.previousX, py = self.previousY,
        z = self:estimatedHeight(), swimming = self.env.swimming(),
        waypointId = waypointId, previousId = previousId, nextId = afterId,
    })
    self.lastArrivalRule = reached and rule or nil
    return reached
end

-- ---------------------------------------------------------------------------------------------------------------
-- 4b. Stagnation, blockage, re-entry, choke fallback
-- ---------------------------------------------------------------------------------------------------------------

function Route:resetApproach()
    self.stagnationRefDistance = nil
    self.stagnationRefTime = nil
    self.stagnationTravel = 0
    self.stagnationLastX = nil
    self.stagnationLastY = nil
end

-- Local re-entry (his B14): the player stands in the attachment cell of a later waypoint of the route that is closer
-- than the current one; the route continues there, nothing is searched anew.
function Route:tryRouteReentry(x, y)
    if not self.active or not self.path or not self.pathIndex then
        return false
    end
    local current = self.pathIndex
    local best = self.G.Reenter(self.path, current, x, y, self:estimatedHeight(), { swimming = self.env.swimming() })
    if not best then
        return false
    end
    local remaining = {}
    for i = best, #self.path do
        remaining[#remaining + 1] = self.path[i]
    end
    self.path = remaining
    self.pathIndex = 1
    self.lastConfirmedNode = nil
    self.blockageCheckX = nil
    self.blockageStuckSince = nil
    self.blockageEscalated = false
    self:resetApproach()
    return true, best - current
end

local function edgeKey(a, b)
    if a > b then
        a, b = b, a
    end
    return tostring(a) .. "_" .. tostring(b)
end

-- Returns the reaction ("reentry" | "fallback") or nil.
function Route:handleBlockage(x, y)
    if not self.active or not self.path then
        return nil
    end
    local toId = self.path[self.pathIndex]
    local fromId = self.pathIndex > 1 and self.path[self.pathIndex - 1] or nil
    local key
    if fromId then
        key = edgeKey(fromId, toId)
        self.blockagesPerEdge[key] = (self.blockagesPerEdge[key] or 0) + 1
    end
    -- the certified re-entry first, whatever the kind of stuck (his 10.6bf)
    if self:tryRouteReentry(x, y) then
        if key then
            self.blockagesPerEdge[key] = nil
        end
        return "reentry"
    end
    -- choke fallback (his 10.6bq): one step back at a gate when the player drifted off the run-up segment; his
    -- setting chokeFallback (default on) switches it off
    if Route.chokeFallback() and self.pathIndex > 1 and fromId and toId and self.G.Choke(toId) then
        local _, lateral = self.G.SegmentProgress(x, y, fromId, toId)
        local limit = self.G.ArrivalRadius(fromId) or Route.ARRIVAL_TARGET_RADIUS
        local now = self.env.now()
        local last = self.fallbackTimePerIndex
        if lateral and lateral > limit and (now - (last[self.pathIndex] or -999)) >= Route.FALLBACK_LOCK then
            last[self.pathIndex] = now
            self.pathIndex = self.pathIndex - 1
            if key then
                self.blockagesPerEdge[key] = nil
            end
            self:resetApproach()
            return "fallback"
        end
    end
    -- no automatic new route, ever (his 10.6bi / 10.6dg, the user's decision)
    return nil
end

-- "Moves but does not get closer" (his 10.6ba). Returns the reaction of handleBlockage or nil.
function Route:checkApproach(x, y, dist, now)
    if self.stagnationLastX then
        local step = distance(self.stagnationLastX, self.stagnationLastY, x, y)
        -- real translation only: turning on the spot must not add up to travel (his 79d8973)
        local speed = self.env.speed()
        local translational
        if speed ~= nil then
            translational = speed > 0.1
        end
        if translational == true or translational == nil then
            self.stagnationTravel = (self.stagnationTravel or 0) + step
        end
    end
    self.stagnationLastX, self.stagnationLastY = x, y
    if not self.stagnationRefTime then
        self.stagnationRefDistance, self.stagnationRefTime = dist, now
        self.stagnationTravel = 0
        return nil
    end
    if dist <= self.stagnationRefDistance - Route.STAGNATION_MIN_APPROACH then
        self.stagnationRefDistance, self.stagnationRefTime = dist, now
        self.stagnationTravel = 0
        return nil
    end
    if (now - self.stagnationRefTime) < Route.STAGNATION_WINDOW then
        return nil
    end
    if (self.stagnationTravel or 0) < Route.STAGNATION_MIN_TRAVEL then
        -- hardly moved: that is the frozen case of checkBlockage; the window starts again
        self.stagnationRefTime = now
        return nil
    end
    self:resetApproach()
    return self:handleBlockage(x, y)
end

-- "Runs against a wall" (his CheckBlockage, without the beep). Returns the reaction of handleBlockage or nil.
function Route:checkBlockage(x, y, now)
    local facing = self.env.facing()
    local turning = false
    if facing and self.blockageLastFacing then
        local delta = ((facing - self.blockageLastFacing + math.pi) % (2 * math.pi)) - math.pi
        turning = abs(delta) > math.rad(0.5)
    end
    self.blockageLastFacing = facing
    if turning then
        self.lastMovementDetectedTime = nil
        self.blockageCheckX = nil
        self.blockageStuckSince = nil
        self.blockageEscalated = false
        return nil
    end
    if self.env.moving() then
        self.lastMovementDetectedTime = now
    end
    local triesToWalk = (now - (self.lastMovementDetectedTime or -999)) < Route.BLOCKAGE_MOVEMENT_TOLERANCE
    if not triesToWalk then
        self.blockageCheckX = nil
        self.blockageStuckSince = nil
        self.blockageEscalated = false
        return nil
    end
    if not self.blockageCheckX then
        self.blockageCheckX, self.blockageCheckY, self.blockageCheckTime = x, y, now
        return nil
    end
    if now - self.blockageCheckTime < Route.BLOCKAGE_CHECK_INTERVAL then
        return nil
    end
    local reaction
    if distance(self.blockageCheckX, self.blockageCheckY, x, y) < Route.BLOCKAGE_MIN_MOVEMENT then
        self.blockageStuckSince = self.blockageStuckSince or now
        if self.active and not self.blockageEscalated
            and (now - self.blockageStuckSince) >= Route.BLOCKAGE_ESCALATION_WAIT_TIME then
            self.blockageEscalated = true
            reaction = self:handleBlockage(x, y)
        end
    else
        self.blockageStuckSince = nil
        self.blockageEscalated = false
    end
    self.blockageCheckX, self.blockageCheckY, self.blockageCheckTime = x, y, now
    return reaction
end

-- ---------------------------------------------------------------------------------------------------------------
-- Route start and end
-- ---------------------------------------------------------------------------------------------------------------

-- His StopNavigation. keepPenalties: the manual new route carries the penalties over.
function Route:reset(keepPenalties)
    self.active = false
    self.path = nil
    self.pathIndex = nil
    self.pendingAction = nil
    self.logicalTarget = nil
    self.logicalPrepoint = nil
    self.logicalWarned = nil
    self.targetBindingId = nil
    self.targetName = nil
    self.result = nil         -- the target's resolution (his layerTargetResult)
    self.waitCheck = nil      -- function(x, y) for a route to a dock (his waitTargetId), set after begin
    self.activation = nil     -- the walk-in target of the route (his activationTarget), set after begin
    self.activationPrepointSaid = nil
    self.activationInside = nil
    self.transitAheadSaid = nil -- the walk-in transit ahead was announced
    self.source = nil         -- the target (his layerTargetSource)
    self.anchor.height = nil
    if not keepPenalties then
        self.penalties = {}
    end
    self.blockagesPerEdge = {}
    self.fallbackTimePerIndex = {}
    self.lastConfirmedNode = nil
    self.blockageCheckX = nil
    self.blockageStuckSince = nil
    self.blockageEscalated = false
    self.previousX, self.previousY, self.currentX, self.currentY = nil, nil, nil, nil
    self.nextUpdate = nil
    self:resetApproach()
end

-- His StartNavigationToNode, up to the route itself (runs inside a job). start: { id = node } for a fixed start (the
-- far end of a transit, a start chosen by the resolver), else the player's position is bound. Returns a plan for
-- Route:begin, or nil, reason key.
-- footOnly: no transit links (his routes to docks and walk-in targets, StartNavigationToNode).
function Route:planToNode(targetNodeId, start, footOnly)
    local N = self.N
    local startId, startX, startY
    if start and start.id then
        startId = start.id
    else
        local x, y = self.env.position()
        if not x then
            return nil, "position_unknown"
        end
        local id, reason = self:startBinding(x, y)
        if not id then
            return nil, reason == "ambiguous" and "floor_ambiguous" or "no_network_attachment"
        end
        startId, startX, startY = id, x, y
    end
    local path, edges, result = self:routeFromStart(startId, targetNodeId, footOnly, startX, startY)
    if not path then
        return nil, "no_route_found"
    end
    local pendingAction
    for _, edge in ipairs(edges or {}) do
        if edge.action then
            local action = edge.action
            if not action.fromNode or not action.toNode then
                return nil, "action_route_invalid"
            end
            pendingAction = action
            local truncated = {}
            for _, id in ipairs(path) do
                truncated[#truncated + 1] = id
                if id == action.fromNode then
                    break
                end
            end
            path = truncated
            break
        end
    end
    -- steering targets are the waypoints of the route, nothing else (his chapter 7 point 5)
    return { path = N.SteeringTargets(path), rawLength = #path, pendingAction = pendingAction,
        targetNodeId = targetNodeId, result = result }
end

-- An unchecked finish stays outside of graph and height proofs: the exact target position is the last point.
function Route:appendLogicalTarget(source, result)
    if not source or not result or self.pendingAction or self.logicalTarget or not self.path then
        return
    end
    -- a certified interaction (dock waiting point, activation area) ends at its own waypoint: the transit modules take
    -- over there; a logical end point behind it would end the route as "target reached" before they act
    if result.quality == "exact"
        and (source.interactionMode == "manual_wait" or source.activationMode == "walk_into_trigger") then
        return
    end
    -- his Weg B for the dyn layer (a dock of the dock model, its point on board, a dungeon entrance with its node): the
    -- route ends exactly on the fixed node of the row and the arrival is the normal one there; no unchecked end point
    -- behind it
    if source.dynNode and (result.targetNode == "target_node" or result.targetNode == "target_node_id") then
        return
    end
    if type(source.x) ~= "number" or type(source.y) ~= "number" then
        return
    end
    local physical = self.path[#self.path]
    local _, _, z = self.N.Position(physical)
    local id = self.N.NewVirtual({ x = source.x, y = source.y, z = source.z or z, type = "logical" })
    self.path[#self.path + 1] = id
    self.logicalTarget = id
    self.logicalPrepoint = physical
end

-- A route from a target picked as its start (the flight master in F10) begins at the target itself: its exact
-- position is the first waypoint, its network point the second. Like the logical end point, it stays outside of graph
-- and height proofs; its arrival radius is Route.ARRIVAL_START_RADIUS. Main thread, after Route:begin.
Route.ARRIVAL_START_RADIUS = 3.0     -- yd: the start point at the picked target's position

function Route:prependStart(x, y, z)
    if not self.path or type(x) ~= "number" or type(y) ~= "number" then
        return
    end
    local N = self.N
    local first = self.path[1]
    local fx, fy, fz = N.Position(first)
    -- the target stands on its network point: nothing to walk before it
    if distance(x, y, fx, fy) <= Route.ARRIVAL_START_RADIUS then
        return
    end
    local id = N.NewVirtual({ x = x, y = y, z = z or fz, type = "logical", radius = Route.ARRIVAL_START_RADIUS })
    table.insert(self.path, 1, id)
    self.pathIndex = 1
    self:setHeightAnchor(z or fz)
    N.KeepVirtual(self.path, self.targetBindingId)
end

-- WowVision's own: a start and a target on the same spot (the same row picked twice, or two within the target's arrival
-- radius on one floor) have nothing between them. Heights only count when both are known.
Route.SAME_SPOT_HEIGHT = 3.0          -- yd: his height tolerance of a floor

function Route.sameSpot(a, b)
    if type(a) ~= "table" or type(b) ~= "table" or type(a.x) ~= "number" or type(a.y) ~= "number"
        or type(b.x) ~= "number" or type(b.y) ~= "number" then
        return false
    end
    if distance(a.x, a.y, b.x, b.y) > Route.ARRIVAL_TARGET_RADIUS then
        return false
    end
    return type(a.z) ~= "number" or type(b.z) ~= "number" or abs(a.z - b.z) <= Route.SAME_SPOT_HEIGHT
end

-- Leaves only the logical end point (Route:appendLogicalTarget): nothing of the network is walked. A player standing
-- there arrives at the first update, with the arrival of any other route. A certified interaction or a transit has no
-- logical end point or a pending action, and keeps its route. Main thread, after Route:begin. True when it was cut.
function Route:dropToEnd()
    if not self.active or self.logicalTarget == nil or self.pendingAction ~= nil then
        return false
    end
    self.path = { self.logicalTarget }
    self.pathIndex = 1
    self.logicalPrepoint = nil
    self.N.KeepVirtual(self.path, self.targetBindingId)
    return true
end

-- A reversed route (Ctrl-Shift-R) goes on at the waypoint its predecessor led to: point = { id, x, y, z }, the id only
-- for a real network point (a virtual one's id may have been given away). The way back need not hold that waypoint
-- (other steering targets, one-way links), then its nearest one takes over. Main thread, after Route:begin.
function Route:resumeAt(point)
    local N = self.N
    local waypoints = {}
    for i, id in ipairs(self.path or {}) do
        local x, y, z = N.Position(id)
        waypoints[i] = { id = id, x = x, y = y, z = z }
    end
    local index = WowVision.Router.resumeIndex(waypoints, point)
    if index == nil then
        return nil
    end
    self.pathIndex = index
    self:setRouteState(self.path[index - 1], self.path[index])
    self:resetApproach()
    self:setHeightAnchor(waypoints[index].z)
    return index
end

-- Makes a plan the running route (main thread). source/result: the target and its resolution.
function Route:begin(plan, source, result, name)
    local N = self.N
    self.active = true
    self.path = plan.path
    self.pendingAction = plan.pendingAction
    self.transitAheadSaid = nil
    self.targetBindingId = plan.targetNodeId
    self.pathIndex = 1
    self.targetName = name
    self.source, self.result = source, result
    self.previousX, self.previousY, self.currentX, self.currentY = nil, nil, nil, nil
    self.nextUpdate = nil
    self:resetApproach()
    local _, _, startHeight = N.Position(self.path[1])
    self:setHeightAnchor(startHeight)
    self:setRouteState(nil, self.path[1])
    self:appendLogicalTarget(source, result)
    -- a live route's first node is often right under the player: skip it only when it is really reached in the plane
    if result and result.zUnknown and #self.path > 1 and self.path[1] ~= self.logicalPrepoint then
        local px, py = self.env.position()
        local sx, sy = N.Position(self.path[1])
        if px and sx and distance(px, py, sx, sy) <= Route.ZUNKNOWN_SKIP_RADIUS then
            self.pathIndex = 2
        end
    end
    N.KeepVirtual(self.path, plan.targetNodeId)
end

-- ---------------------------------------------------------------------------------------------------------------
-- Target resolution (his LayerTargetContext / LayerTargetStart / TargetSelection:Prepare), inside a job
-- ---------------------------------------------------------------------------------------------------------------

-- The routing context of the resolver: every candidate attachment of the target is checked for a route from the
-- start (and the start attachment that found it stays the start of this selection).
function Route:targetContext(startOverride, footOnly)
    local startId = startOverride
    local px, py
    if not startId then
        local x, y = self.env.position()
        if not x then
            return nil
        end
        startId = self:startBinding(x, y)
        px, py = x, y
    end
    if not startId then
        return nil
    end
    local context = { startNodeId = startId, footOnly = footOnly }
    -- endPool (optional): the checked attachments of the target cell; the third result is the target attachment of the
    -- cheapest pair
    context.route = function(endId, endPool)
        local path, _, result, used = self:routeFromStart(context.startNodeId, endId, footOnly, px, py, endPool)
        if not path then
            return nil
        end
        context.startNodeId = used
        return path, result.cost, result.targetBinding
    end
    return context
end

-- Resolves a target and plans its route (inside a job). target: the catalogue contract (TargetCatalog.Validate) plus
-- heightBand when a floor was chosen. Returns an outcome:
--   { kind = "start", plan, result, context }
--   { kind = "choose", result, reachable = { [band] = bool } }  (floors to choose from; his /vn ebene)
--   { kind = "fail", reason = key or text }
function Route:prepare(target, nav, startOverride)
    -- a waiting point and the point on board of the dock model are reached on foot (his LayerTargetStart). A walk-in
    -- target is not: portals and lifts are parts of a route (his chapter 02 rule 11), and the pre-point of a trigger may
    -- lie where only another action leads (the room of Stormwind's portal 702 is reached through portal 704); the route
    -- then ends at the pre-point of that action and the trigger's own activation follows after it
    local footOnly = target.interactionMode == "manual_wait" or target.boardingPoint == true
    local context = self:targetContext(startOverride, footOnly)
    if not context then
        local x, y = self.env.position()
        if not x then
            return { kind = "fail", reason = "position_unknown" }
        end
        local _, why = self:startBinding(x, y)
        return { kind = "fail", reason = why == "ambiguous" and "floor_ambiguous" or "no_network_attachment",
            ambiguousStart = why == "ambiguous" }
    end
    context.heightBand = target.heightBand
    local result = self.R:Resolve(nav, target, context)
    if result.quality == "ambiguous" and result.bands then
        -- which floor can be reached from here: the same check as his Prepare. A band of certified levels holds
        -- bindings; a band of cells holds cells, which are bound here first (his Prepare passes their missing id on,
        -- so every such band would read "no path").
        local reachable = {}
        for i, band in ipairs(result.bands) do
            -- since his 12.11.2026 the resolver itself marks the bands the start can reach (band.selectable)
            if band.selectable ~= nil then
                reachable[i] = band.selectable == true
            end
            for _, candidate in ipairs(reachable[i] ~= nil and {} or band.candidates) do
                local id = candidate.id
                if id == nil and candidate.zone ~= nil then
                    local binding = self.N.BindCell(candidate.zone, candidate.cell, target.x, target.y, candidate.distance)
                    id = binding and binding.id
                end
                if id ~= nil and context.route(id) then
                    reachable[i] = true
                    break
                end
            end
        end
        return { kind = "choose", result = result, reachable = reachable }
    end
    if result.endNodeId == nil then
        return { kind = "fail", reason = result.reason, result = result }
    end
    local plan, why = self:planToNode(result.endNodeId, { id = context.startNodeId }, footOnly)
    if not plan then
        return { kind = "fail", reason = why, result = result }
    end
    return { kind = "start", plan = plan, result = result, context = context }
end

-- A route straight to a waypoint of the network (an automatic waypoint of the list; his list entries with a nodeId
-- start a route to that node without the resolver). Inside a job; returns an outcome like Route:prepare.
function Route:prepareNode(nodeId, startOverride)
    if not self.N.Exists(nodeId) then
        return { kind = "fail", reason = "no_route_found" }
    end
    local plan, why = self:planToNode(nodeId, startOverride and { id = startOverride } or nil)
    if not plan then
        return { kind = "fail", reason = why, ambiguousStart = why == "floor_ambiguous" }
    end
    return { kind = "start", plan = plan, result = { quality = "exact" } }
end

-- ---------------------------------------------------------------------------------------------------------------
-- Manual new route (his PerformRecalculation): the blocked link gets a penalty, the target is resolved anew
-- ---------------------------------------------------------------------------------------------------------------

-- Puts the penalty on the current link (real waypoints only) and stops the route, keeping the penalties. Returns the
-- target to resolve again, or nil when there is no route.
function Route:penalizeCurrentLink()
    if not self.active or not self.path then
        return nil
    end
    local VIRT = self.N.VIRT_BASE
    local toId = self.path[self.pathIndex]
    local fromId = self.pathIndex > 1 and self.path[self.pathIndex - 1] or nil
    local a = fromId and fromId < VIRT and fromId or nil
    local b = toId and toId < VIRT and toId or nil
    if a and b and a ~= b then
        local p = self.penalties
        p[a] = p[a] or {}
        p[b] = p[b] or {}
        p[a][b] = (p[a][b] or 0) + Route.BLOCKAGE_EDGE_PENALTY
        p[b][a] = (p[b][a] or 0) + Route.BLOCKAGE_EDGE_PENALTY
    end
    local source = self.source
    self:reset(true)
    return source
end

-- ---------------------------------------------------------------------------------------------------------------
-- Manual stepping (his /vn prev and /vn next; WowVision's Ctrl-W / Ctrl-S)
-- ---------------------------------------------------------------------------------------------------------------

function Route:selectIndex(index)
    if not self.active or not self.path then
        return false
    end
    index = max(1, min(index, #self.path))
    if index == self.pathIndex then
        return false
    end
    self.pathIndex = index
    self:setRouteState(self.path[index - 1], self.path[index])
    self:resetApproach()
    return true
end

-- ---------------------------------------------------------------------------------------------------------------
-- Guidance update (his OnUpdate for a route, without the sounds)
-- ---------------------------------------------------------------------------------------------------------------

-- One update. Returns an event table or nil:
--   { kind = "advance" }                                   the next waypoint is current
--   { kind = "careful" }  + advance                         last physical waypoint before an unchecked last stretch
--   { kind = "reentry", skipped = n } / { kind = "fallback" }
--   { kind = "arrived", exact = bool, result }              target reached (his stop_target_position_reached / reached)
--   { kind = "transit", action }                            the route ends at a transit; the continuation waits
--   { kind = "transit", action, sourceEntered / teleported } a portal walked into before the route's end
--   { kind = "transitAhead", action }                       a portal ahead, once (the transit then has announced)
function Route:update(x, y)
    if not self.active or not self.path then
        return nil
    end
    local now = self.env.now()
    if self.nextUpdate and now < self.nextUpdate then
        return nil
    end
    self.nextUpdate = now + Route.UPDATE_INTERVAL
    local N, G = self.N, self.G

    -- a portal on the way teleports as soon as the player is in it, maybe before the route's last waypoint
    local walkIn = self:walkInTransit(x, y, self.currentX, self.currentY)
    if walkIn then
        if walkIn.kind == "transit" then
            self.active = false
        end
        return walkIn
    end

    -- the blockage watch runs on every update (his separate frame)
    local blockage = self:checkBlockage(x, y, now)
    if blockage then
        return { kind = blockage }
    end

    self.previousX, self.previousY = self.currentX, self.currentY
    self.currentX, self.currentY = x, y
    local waypointId = self.path[self.pathIndex]
    if not N.Exists(waypointId) then
        return { kind = "lost" }
    end
    local wx, wy = N.Position(waypointId)
    local dist = distance(x, y, wx, wy)
    if waypointId == self.logicalTarget then
        if dist <= G.EffectiveRadius(Route.ARRIVAL_TARGET_RADIUS) then
            local result = self.result
            self.active = false
            return { kind = "arrived", exact = false, result = result }
        end
        return nil
    end
    -- the height along the current link (his chapter 7 point 8)
    local previousId = self.pathIndex > 1 and self.path[self.pathIndex - 1] or nil
    local estimated = G.Height(previousId, waypointId, x, y)
    if estimated and not self.env.swimming() then
        self.anchor.height = estimated
        self.anchor.last = estimated
    end
    -- a walk-in target (his TransitActivation): the prepoint is said once; at the last waypoint there is no arrival,
    -- the capture circle is said once and the route stays until the map changes
    local activation = self.activation
    local lastActivation = activation ~= nil and self.pathIndex >= #self.path
    if activation ~= nil and not self.activationPrepointSaid and self.A:PrepointReached(activation, x, y) then
        self.activationPrepointSaid = true
        return { kind = "prepoint", unresolved = activation.actionSemanticStatus == "unresolved",
            dive = activation.facilityKind == "dive", target = activation }
    end
    if lastActivation then
        local observation
        if activation.actionSemanticStatus == "unresolved" then
            local _, _, map = self.env.position()
            observation = type(map) == "number" and { nativeMapId = map } or nil
        end
        local inside, mode = self.A:CaptureReached(activation, x, y, observation)
        if inside then
            if not self.activationInside then
                self.activationInside = true
                return { kind = "activation", unresolved = activation.actionSemanticStatus == "unresolved",
                    heightUnconfirmed = mode == "xy_only", dive = activation.facilityKind == "dive", target = activation }
            end
            return nil
        end
    end
    local afterId = self.path[self.pathIndex + 1]
    local beforeLogical = self.logicalTarget ~= nil and afterId == self.logicalTarget
    -- before an unchecked last stretch the last network point counts only within the target radius
    if not lastActivation and (not beforeLogical or dist <= G.EffectiveRadius(Route.ARRIVAL_TARGET_RADIUS))
        and self:waypointIsReached(x, y, waypointId, previousId, not beforeLogical and afterId or nil) then
        local careful = beforeLogical and not self.logicalWarned and self.result ~= nil
            and not Route.reachesTarget(self.result, G.EffectiveRadius(Route.ARRIVAL_TARGET_RADIUS))
        if careful then
            self.logicalWarned = true
        end
        self.lastConfirmedNode = waypointId
        if self.pathIndex >= #self.path then
            local result = self.result
            if self.pendingAction then
                local action = self.pendingAction
                self.active = false
                return { kind = "transit", action = action, announced = self.transitAheadSaid }
            end
            self.active = false
            return { kind = "arrived", exact = true, result = result }
        end
        self.pathIndex = self.pathIndex + 1
        self:setRouteState(waypointId, self.path[self.pathIndex])
        self:resetApproach()
        return { kind = "advance", careful = careful }
    end

    local reaction = self:checkApproach(x, y, dist, now)
    if reaction then
        return { kind = reaction }
    end
    return nil
end

-- ---------------------------------------------------------------------------------------------------------------
-- Transit continuation (his ActionNavigation + ActionArrival), proven in the plane
-- ---------------------------------------------------------------------------------------------------------------

local function inVolume2D(volume, x, y, widen)
    if type(volume) ~= "table" or type(volume.x) ~= "number" then
        return false
    end
    local dx, dy = x - volume.x, y - volume.y
    if volume.radius then
        local r = max(volume.radius, widen or 0)
        return dx * dx + dy * dy <= r * r
    end
    if volume.half_x and volume.half_y and volume.yaw_radians then
        local c, s = math.cos(volume.yaw_radians), math.sin(volume.yaw_radians)
        local lx, ly = c * dx + s * dy, -s * dx + c * dy
        return abs(lx) <= max(volume.half_x, widen or 0) and abs(ly) <= max(volume.half_y, widen or 0)
    end
    return false
end
Route.inVolume2D = inVolume2D

-- A portal walked into (activation walk_into_volume) teleports the moment the player is in its source volume, and the
-- route can cross that volume before its last waypoint (Darnassus to Rut'theran: waypoints 7.9 and 9.3 yd from the
-- centre of a 10 yd volume, the route's end 10.8 yd outside). His route waits for the transit only at its last
-- waypoint, so the teleport came first and the route was left behind. WowVision's own rule ends the walk at the
-- transit as soon as the player is in the source volume; a teleport between two observations shows as a jump into the
-- arrival volume, which proves the portal by itself.
local function walksInto(action)
    return type(action) == "table" and type(action.activation) == "table"
        and action.activation.mode == "walk_into_volume"
end

local function teleported(action, x, y, lastX, lastY)
    return lastX ~= nil and distance(x, y, lastX, lastY) > Route.TELEPORT_JUMP
        and (action.toNativeMap == nil or action.toNativeMap == action.fromNativeMap)
        and inVolume2D(action.arrivalVolume, x, y)
end

-- The source volume widened by Route.TRANSIT_AHEAD: where the transit is announced.
local function aheadReach(volume)
    if type(volume) ~= "table" then
        return 0
    end
    return max(volume.radius or 0, volume.half_x or 0, volume.half_y or 0) + Route.TRANSIT_AHEAD
end

-- The route works in the plane, so the player's height is that of the waypoint he walks to: he is at the portal only
-- when that waypoint is at the portal's height, within its volume and Route.TRANSIT_HEIGHT. Stormwind's Wizard's
-- Sanctum: its ramp passes 4.1 yd beside the centre of the portal at the top of the tower, 39 yd below it.
local function atVolumeHeight(route, volume)
    local id = route.path and route.path[route.pathIndex]
    if type(volume) ~= "table" or type(volume.z) ~= "number" or id == nil then
        return true
    end
    local _, _, z = route.N.Position(id)
    if type(z) ~= "number" then
        return true
    end
    return abs(z - volume.z) <= (volume.half_z or volume.radius or 0) + Route.TRANSIT_HEIGHT
end

-- A walk-in portal on its own map is a link of the network like any other: the player is through it once he is in its
-- arrival volume and nearer to its far waypoint (toNode) than to its near one (fromNode). Where the portal drops
-- straight down (Stormwind's Wizard's Sanctum: source and arrival 6.4 yd apart in the plane), the plane cannot tell
-- leaving the source from arriving, but the portal's two waypoints lie 14.3 yd apart.
local function pastLink(route, action, x, y)
    if not walksInto(action) or type(action.fromNode) ~= "number" or type(action.toNode) ~= "number" then
        return false
    end
    local fx, fy = route.N.Position(action.fromNode)
    local tx, ty = route.N.Position(action.toNode)
    if fx == nil or tx == nil then
        return false
    end
    return distance(x, y, tx, ty) < distance(x, y, fx, fy)
end

-- During a route with a portal on the way: the transit event when the player is in the portal (sourceEntered) or
-- came out at its far end (teleported); once, when he comes near it, the transitAhead event (the teleport leaves no
-- time for a text in the portal); else nil. lastX, lastY: the position of the previous update.
function Route:walkInTransit(x, y, lastX, lastY)
    local action = self.pendingAction
    if not walksInto(action) or not x then
        return nil
    end
    local level = atVolumeHeight(self, action.sourceVolume)
    if level and inVolume2D(action.sourceVolume, x, y) then
        return { kind = "transit", action = action, sourceEntered = true, announced = self.transitAheadSaid }
    end
    if teleported(action, x, y, lastX, lastY) then
        return { kind = "transit", action = action, teleported = true, announced = self.transitAheadSaid }
    end
    if level and not self.transitAheadSaid
        and inVolume2D(action.sourceVolume, x, y, aheadReach(action.sourceVolume)) then
        self.transitAheadSaid = true
        return { kind = "transitAhead", action = action }
    end
    return nil
end

-- The route reached a transit: the continuation waits for its arrival. target: what to route to afterwards (the
-- request); targetNodeId and result: the target's binding and resolution, which the continuation routes to again
-- (his pendingAction keeps the targetId: after a transit into another map, such as the tram, the target cannot be
-- resolved from the new map). event: the transit event, whose sourceEntered / teleported the observation starts from.
function Route:startAction(action, target, targetNodeId, result, event)
    local entered = event ~= nil and (event.sourceEntered or event.teleported) or false
    self.action = { action = action, target = target, targetNodeId = targetNodeId, result = result,
        startedAt = self.env.now(), sourceEntered = entered,
        sourceLeft = event ~= nil and event.teleported or false }
end

function Route:cancelAction()
    self.action = nil
end

-- The volume that proves the arrival of an action: its arrival volume; an action record without one (his DemoAddon,
-- 11/2026) has the position of its exit node, the start of the next leg, within the arrival radius of that node.
function Route:arrivalVolumeOf(action)
    if type(action.arrivalVolume) == "table" then
        return action.arrivalVolume
    end
    local N = self.N
    local toNode = action.toNode
    if type(toNode) ~= "number" then
        return nil
    end
    if not N.Exists(toNode) then
        N.LoadZone(action.toZoneId or math.floor(toNode / N.ZONE_BASE))
        if not N.Exists(toNode) then
            return nil
        end
    end
    local x, y = N.Position(toNode)
    if x == nil then
        return nil
    end
    return { x = x, y = y, radius = self.G.ArrivalRadius(toNode) or Route.ARRIVAL_TARGET_RADIUS }
end

-- His Actions:Observe without a height: the arrival volume in the plane, after the source volume was left (lift,
-- portal on the same map) or after the map changed (tram entrance, portal to another map); the nearer of the two
-- volumes counts, so a widened circle never proves an arrival at the source. widen: the minimum radius of both
-- volumes, WowVision's arrival distance (Alt-P, G.arrivalMin, the same minimum as Guidance.EffectiveRadius): the
-- radius that counted the transit's waypoint as reached also counts its source as entered. Returns "arrived",
-- "timeout" or nil.
function Route:observeAction(x, y, map, widen)
    local current = self.action
    if not current then
        return nil
    end
    local action = current.action
    local timing = action.timing
    local timeout = timing and timing.timeout_seconds
    if type(timeout) ~= "number" or timeout <= 0 then
        timeout = 30
    end
    -- an action that waits for a signal (the Wind Bridge, his no_time_limit) takes as long as it takes
    local limited = not (type(timing) == "table" and timing.no_time_limit == true)
    if limited and self.env.now() - current.startedAt > timeout * Route.ACTION_PHASES then
        self.action = nil
        return "timeout"
    end
    if not x then
        return nil
    end
    local fromMap = action.fromNativeMap
    local toMap = action.toNativeMap or fromMap
    if map == fromMap then
        if inVolume2D(action.sourceVolume, x, y, widen) then
            current.sourceEntered = true
        elseif current.sourceEntered then
            current.sourceLeft = true
        elseif walksInto(action) and teleported(action, x, y, current.lastX, current.lastY) then
            -- no observation inside the portal before its teleport: the jump to its far end proves it
            current.sourceEntered, current.sourceLeft = true, true
        end
    end
    current.lastX, current.lastY = x, y
    local arrival = self:arrivalVolumeOf(action)
    if map ~= toMap or not inVolume2D(arrival, x, y, widen) then
        return nil
    end
    local mode = action.arrival and action.arrival.mode
    if mode == "native_map_volume" then
        if fromMap == toMap then
            return nil
        end
    else
        local through = fromMap == toMap and pastLink(self, action, x, y)
        if fromMap == toMap and not current.sourceLeft and not through then
            return nil
        end
        local sv, av = action.sourceVolume, arrival
        if not through and type(sv) == "table" and type(sv.x) == "number" and fromMap == toMap
            and distance(x, y, sv.x, sv.y) <= distance(x, y, av.x, av.y) then
            return nil
        end
    end
    return "arrived"
end

-- After the arrival: the route goes on from the transit's far end, at its height (his ActionArrival). Returns the
-- request, the far end's node, the target's binding and its resolution.
function Route:actionArrival()
    local current = self.action
    self.action = nil
    if not current then
        return nil
    end
    local action = current.action
    if type(action.toNode) ~= "number" then
        return nil
    end
    local zone = self.N.LoadZone(action.toZoneId or math.floor(action.toNode / self.N.ZONE_BASE))
    if not zone or not self.N.Exists(action.toNode) then
        return nil
    end
    local _, _, z = self.N.Position(action.toNode)
    self:setHeightAnchor(z)
    return current.target, action.toNode, current.targetNodeId, current.result
end

-- The continuation's route (inside a job): from the far end of the transit to the target's binding (his
-- StartNavigationToNode with manualStartNode = action.toNode). Returns an outcome like Route:prepare.
function Route:continueTo(toNode, targetNodeId, result)
    if targetNodeId == nil or not self.N.Exists(targetNodeId) then
        return { kind = "fail", reason = "no_route_found" }
    end
    local plan, why = self:planToNode(targetNodeId, { id = toNode })
    if not plan then
        return { kind = "fail", reason = why, result = result }
    end
    return { kind = "start", plan = plan, result = result }
end
