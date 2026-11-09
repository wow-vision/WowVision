-- WowNav routes in WowVision (WoW: Forever). With the setting on, every route request of the navigation (the
-- scanner's Enter, the places list, /beacon to, the F10 window) goes to WowNav: Broesel's engine (engine/, his
-- NavNetwork, Guidance, TargetCatalog and TargetResolver) on his navigation data (the submodule
-- mapdata/WoW_NavigationData, packed by tools/wownav-pack.lua), followed with his rules (route.lua) and walked with
-- WowVision's beacon (path.lua). His catalogues of the whole continent are searched from the F10 list the way his list
-- searches them: the nearest 1000 hits (catalog.lua). Like his zone loader, the player's zone and the zones that share
-- a seam with it are decoded in the background, one per frame, so the first route there does not wait for them.
--
-- The start is never searched by WowNav (his N.Bind of the player's position) -- except for Ctrl-Shift-N, which starts
-- the route again from where the player stands when that is clear (engine:startHere): F10 lists the nearest targets that have
-- a network point (and the network's own waypoints with "Show Automatic Waypoints") as entry points, like the route
-- data's, and the route starts at the one the player picks (his start-point mode, /vn hier, for every route); while
-- swimming the nearest water point is preselected. A route searched again
-- (a new road preference, a new route around a blocked spot) starts at the route's last reached waypoint. The target's
-- floor is asked only when there is a choice: a target over several floors and nothing tells which one
-- (floorsUi.lua). The setting "Show Automatic Waypoints" (his showauto, default off) adds the network's own
-- waypoints near the player to F10, by height; Enter routes straight to one. A route that reaches a portal, the tram entrance or an elevator ends there; once
-- the player has come out at its far end, the route goes on from there by itself.
--
-- Docks of the tram, ships and zeppelins follow his dock guidance (dock.lua): a dock is walked to and waited at; at a
-- dock, the other dock of the line is noted instead of walked to, and near it the turn key faces it. At a fishing spot
-- (fishing.lua) a beacon sounds from the water and the turn key faces it, until the player leaves the place.
--
-- With the standalone WowVisionNavigation addon loaded as well, this stays off (both use the same globals).

local maps = WowVision.base.navigation.maps
local catalog = WowVision.wownavCatalog
local Route = WowVision.wownavRoute
local dock = WowVision.wownavDock
local fishing = WowVision.wownavFishing

local module = WowVision.base.navigation:createModule("wownav")
local L = module.L
module:setLabel(L["WowNav Routes"])

local settings = module:hasSettings()
settings:add({ key = "enabled", type = "Bool", label = L["Routes from WowNav"], default = true })
-- WowNav's comfort level: a road route may be up to this many percent longer than the shortest way (his default 60
-- since 2026-10-25).
settings:add({ key = "comfort", type = "Number", label = L["Road Preference (Percent Longer)"], default = 60, min = 0, max = 300 })
-- his /vn outposts (Z2, default on): routes go around the outposts and capitals of the opposing faction; without a way
-- around they lead through one and say so
settings:add({ key = "avoidOutposts", type = "Bool", label = L["Avoid Enemy Outposts"], default = true })
-- his /vn showauto (default off): the network's own waypoints near the player join the F10 list, by height
settings:add({ key = "showAuto", type = "Bool", label = L["Show Automatic Waypoints"], default = false })
-- his /vn radius and /vn toleranz: how far from the network a target may lie, and the height band of a floor
settings:add({
    key = "targetRadius", type = "Number", label = L["Target Radius Around the Network (Yards)"],
    default = 30, min = 1, max = 100,
})
settings:add({ key = "targetTolerance", type = "Number", label = L["Height Tolerance of a Floor (Yards)"], default = 3,
    min = 0, max = 20 })
-- creatures and objects named in the game language from Questie's database where it knows them (text.lua); the
-- catalogues themselves only have English and German
settings:add({ key = "localNames", type = "Bool", label = L["Names in Your Language"], default = true })
function WowVision.wownavText.localNamesEnabled()
    return module.settings.localNames ~= false
end
-- his /vn rueckfall: one step back at a gate when the player drifted sideways
settings:add({ key = "chokeFallback", type = "Bool", label = L["Step Back at Gates"], default = true })
-- his preload: the player's zone and its neighbours are decoded ahead
settings:add({ key = "preload", type = "Bool", label = L["Prepare Neighbouring Zones"], default = true })
-- his /vn ankunft (a waypoint counts as reached within at least this many yards) is WowVision's arrival distance:
-- the radius Alt-P picks (navigation/maps) is the minimum over the data's own radius of each waypoint

local BUDGET_MS = 8          -- search time per frame (his chapter 7 point 4 allows 30)
local SLOW_NOTICE = 1.0      -- seconds before "calculating route" is said
local RECALC_DELAY = 1.0     -- seconds after the last change of the road preference before the route is searched again

local job = nil              -- the pending search: { job, request, startedAt, noticed }
local passive = nil          -- the noted dock (his passive mode): { name, near }
local recalcAt = nil         -- when the running route is searched again with a changed road preference
local route = nil            -- the wownavRoute of the module
local routeMap = nil         -- the native map the running route lives on

function module:network()
    return _G.WowVisionNavigationNavNetwork, _G.WowVisionNavigationGuidance
end

local function standaloneLoaded()
    return C_AddOns ~= nil and C_AddOns.IsAddOnLoaded ~= nil and C_AddOns.IsAddOnLoaded("WowVisionNavigation")
end

-- His ActionAllowed: an action edge without conditions (ActionNavigation CanTraverse).
local function actionAllowed(action)
    local conditions = type(action) == "table" and action.conditions or nil
    return type(conditions) == "table" and conditions.status == "unconditional" and conditions.proof ~= nil
end

local function inWater()
    return (IsSwimming ~= nil and IsSwimming() == true) or (IsSubmerged ~= nil and IsSubmerged() == true)
end

local function playerSpeed()
    if GetUnitSpeed == nil then
        return nil
    end
    local ok, speed = pcall(GetUnitSpeed, "player")
    if not ok or (issecretvalue ~= nil and issecretvalue(speed)) or type(speed) ~= "number" then
        return nil
    end
    return speed
end

local function playerFacing()
    if GetPlayerFacing == nil then
        return nil
    end
    local facing = GetPlayerFacing()
    if issecretvalue ~= nil and issecretvalue(facing) then
        return nil
    end
    return facing
end

local indexed = false
local function ready(self)
    local N, G = self:network()
    if N == nil or G == nil or N.Job == nil or type(_G.WVN7Index) ~= "table" then
        return nil
    end
    if not indexed then
        N.LoadIndex()
        N.ActionAllowed = actionAllowed
        indexed = true
        route = Route.new({
            N = N, G = G, R = _G.WowVisionNavigationTargetResolver, C = _G.WowVisionNavigationTargetCatalog,
            position = function()
                local x, y, _, map = UnitPosition("player")
                return x, y, map
            end,
            swimming = inWater,
            now = GetTime,
            facing = playerFacing,
            moving = function()
                return IsPlayerMoving ~= nil and IsPlayerMoving() == true
            end,
            speed = playerSpeed,
        })
    end
    N.SetComfort(self.settings.comfort or 60)
    N.SetAvoidOutposts(self.settings.avoidOutposts ~= false)
    -- his settings live in WowVisionNavigationDB, where his resolver and route rules read them (R:Settings,
    -- Route.chokeFallback); while the standalone addon is loaded this module is off and the table is his
    WowVisionNavigationDB = type(WowVisionNavigationDB) == "table" and WowVisionNavigationDB or {}
    WowVisionNavigationDB.targetRadius = self.settings.targetRadius
    WowVisionNavigationDB.targetTolerance = self.settings.targetTolerance
    WowVisionNavigationDB.chokeFallback = self.settings.chokeFallback ~= false
    -- his /vn ankunft: WowVision's arrival distance (Alt-P), kept current by the subscriptions at the end
    G.arrivalMin = maps:arrivalDistance()
    return N
end

function module:route()
    return route
end

-- ---- the engine maps calls (core/navigation/maps/module.lua setRouteEngine)
local engine = {}

function engine:isActive()
    return module:getEnabled() and module.settings.enabled == true and not standaloneLoaded() and ready(module) ~= nil
end


function engine:routeTo(target)
    return module:routeTo(target)
end

-- F10's entry points: the nearest 50 targets with a network point and waypoints of the network, all of them nearby
-- with "Show Automatic Waypoints", else only those right beside the player (catalog.entryPoints); {} where WowNav has
-- no data. The count of the route data's list (maps.ENTRY_COUNT) is not WowNav's.
function engine:entryPoints(px, py, map, count, swimming)
    local N = ready(module)
    if N == nil or px == nil or not catalog.covers(N, map) then
        return {}
    end
    N.activeMapId = map
    return catalog.entryPoints(N, _G.WowVisionNavigationTargetCatalog, map, px, py, catalog.ENTRY_COUNT,
        { showAuto = module.settings.showAuto == true, swimming = swimming })
end

-- The start at the player's position, only when it is clear -- the one place WowNav binds the position itself (Ctrl-Shift-N,
-- the route to the target). Says nothing; returns the start, or nil and why ("ambiguous": the floor is not clear,
-- "none": no network here).
function engine:startAt(px, py, map)
    local N = ready(module)
    if N == nil or px == nil or not catalog.covers(N, map) then
        return nil, "none"
    end
    N.activeMapId = map
    local id, why = route:startBinding(px, py)
    if id == nil then
        return nil, why == "ambiguous" and "ambiguous" or "none"
    end
    local _, _, z = N.Position(id)
    return { nodeId = id, z = z }
end

-- Ctrl-Shift-N (his /vn new, asked for by the player): the start at the player's position (engine:startAt). Says why
-- not otherwise (floor not clear, no network) and returns nil.
function engine:startHere(px, py, map)
    local start, why = self:startAt(px, py, map)
    if start == nil then
        -- WowVision:speak, not say: this file's say is declared further down
        WowVision:speak(why == "ambiguous" and L["Your floor is not clear here"] or L["No WowNav network here"])
    end
    return start
end

-- The route to the target: the catalogue's nearest target with the creature's ID (catalog.creatureRow), as a row of
-- the list; nil where WowNav has no data or no such creature near the player.
function engine:unitTarget(creatureId, px, py, map)
    local N = ready(module)
    if N == nil or px == nil or not catalog.covers(N, map) then
        return nil
    end
    N.activeMapId = map
    return catalog.creatureRow(N, _G.WowVisionNavigationTargetCatalog, map, creatureId, px, py,
        WowVision.targetFind.UNIT_RADIUS)
end

-- A target another source names (the scanner's quest NPCs and objects: { kind, id, name } at x, y): the catalogue's
-- row of the same target near that position (catalog.matchRow), which brings its height; nil where WowNav has no data
-- or no such target.
function engine:matchTarget(match, x, y, map)
    local N = ready(module)
    if N == nil or x == nil or map == nil or not catalog.covers(N, map) then
        return nil
    end
    N.activeMapId = map
    return catalog.matchRow(N, _G.WowVisionNavigationTargetCatalog, map, match, x, y)
end

-- Shift-F12 (his /vn stop): ends the search, the route, a transit waiting for its far end, the dock guidance and the
-- water beacon of a fishing spot. True when any of them was running.
function engine:cancel()
    local Dock = _G.WowVisionNavigationDockNavigation
    local running = module:runningRequest() ~= nil or module.path ~= nil or module.dockPath ~= nil
        or (route ~= nil and route.action ~= nil) or (Dock ~= nil and (Dock.reached ~= nil or Dock.passive ~= nil))
        or fishing.reached()
    if running then
        module:stopRoute()
    end
    return running
end

-- Ctrl-Shift-R (maps:reverseRoute): the running route turned around. Nil when no WowNav route runs.
function engine:reverseRoute()
    return module:reverseRoute()
end

function engine:search(text, px, py, map, opts)
    return module:search(text, px, py, map, opts)
end

-- Auto Route (maps:routeToNearestWalk): of several targets, the one the shortest walk reaches.
function engine:routeToNearest(targets)
    return module:routeToNearest(targets)
end

maps:setRouteEngine(engine)

-- ---- speech
local function say(text)
    WowVision:speak(text)
end
-- what his dock module says (WowVisionNavigationPrint)
WowVision.wownavText.say = say

-- The saved trail of route requests and dock decisions (WowVisionDump.wownav, on disk after /reload or logout; the
-- newest last), so a walk test can be read without typing anything in the game.
local LOG_SIZE = 60
local function logLine(line)
    WowVisionDump = WowVisionDump or {}
    local trail = WowVisionDump.wownav
    if type(trail) ~= "table" then
        trail = {}
        WowVisionDump.wownav = trail
    end
    trail[#trail + 1] = date("%Y-%m-%d %H:%M:%S") .. " " .. line
    while #trail > LOG_SIZE do
        table.remove(trail, 1)
    end
end

local TRANSIT_WORDS = { portal = L["the portal"], tram = L["the tram"], lift = L["the elevator"], dive = L["a dive"],
    surface = L["surfacing"], wind_bridge = L["the Wind Bridge"] }
-- his KIND_TEXT (ActionNavigation.lua): the player dives and surfaces himself, and waits for the Wind Bridge; the
-- portal text does not fit
local TRANSIT_TEXTS = { dive = L["Dive here; the route goes on after it"],
    surface = L["Surface here; the route goes on after it"],
    wind_bridge = L["Wait here until you hear the Wind Bridge, then step into the wind current; the route goes on after it"] }
-- his MODE_TEXT: a transit without a text of its own by how it is activated (a portal that is clicked, no trigger)
local TRANSIT_MODE_TEXTS = {
    click = L["Target the portal with soft targeting and interact with it; the route goes on after it"] }

-- What a transit says (his ActionNavigation texts): by its kind, else by its activation mode, else the generic text;
-- a transit whose positions are estimates says so (his approximateSuffix).
local function transitText(action)
    local mode = type(action.activation) == "table" and action.activation.mode or nil
    local text = TRANSIT_TEXTS[action.kind] or (mode and TRANSIT_MODE_TEXTS[mode])
        or string.format(L["Use %s; the route goes on after it"], TRANSIT_WORDS[action.kind] or L["the transit"])
    -- his action_boarding: a vehicle (the elevator) is boarded only when it is safely there
    if mode == "board" then
        text = text .. ". " .. WowVisionNavigationText("action_boarding")
    end
    if action.approximate == true then
        text = text .. ". " .. WowVisionNavigationText("approximate_position")
    end
    return text
end

-- What a walk-in target says at its prepoint and in its activation area (his Navigation.ActivationText): the text of
-- its facility kind (dive, Wind Bridge), else of its action mode (click), else the generic one; approximate: said.
local ACTIVATION_TEXT_KEYS = {
    prepoint_reached = { generic = "prepoint_reached_go_through",
        kinds = { dive = "prepoint_reached_dive", click = "prepoint_reached_click",
            wind_bridge = "prepoint_reached_wind_bridge" } },
    activation_area = { generic = "activation_area_entered",
        kinds = { dive = "activation_area_dive", click = "activation_area_click",
            wind_bridge = "activation_area_wind_bridge" } },
}
local function activationText(target, base)
    local keys = ACTIVATION_TEXT_KEYS[base]
    local key = keys.generic
    target = target or {}
    for _, kind in ipairs({ target.facilityKind or false, target.actionMode or false }) do
        if keys.kinds[kind] ~= nil then
            key = keys.kinds[kind]
            break
        end
    end
    local text = WowVisionNavigationText(key)
    if target.approximate == true then
        text = text .. " " .. WowVisionNavigationText("approximate_position")
    end
    return text
end

-- The resolver's and the planner's reasons as WowVision texts.
local REASONS = {
    position_unknown = L["Position unavailable"],
    floor_ambiguous = L["Your floor is not clear here"],
    no_network_attachment = L["No WowNav network here"],
    no_route_found = L["No route found"],
    action_route_invalid = L["No route found"],
}
local function reasonText(reason)
    return REASONS[reason] or tostring(reason or L["No route found"])
end

-- ---- destinations: his search of the WowNav catalogue of the player's map (the nearest 1000 hits), with the
-- automatic waypoints nearby when they are shown. Returns the rows, nearest first, and the search info (capped).
-- opts.direct: F10's Direct (his /vn direct list): a point is set straight, so no hit is dropped as unreachable.
function module:search(text, px, py, map, opts)
    local N = ready(self)
    if N == nil or map == nil or not catalog.covers(N, map) then
        return {}, nil
    end
    local C = _G.WowVisionNavigationTargetCatalog
    -- the boarding points of the docks join the hits (his list with Dock:BoardingTargets)
    local extra = catalog.ensure(N, C, map) ~= nil and px ~= nil and dock.boardingRows(N, px, py) or nil
    local rows, info = catalog.search(N, C, map, text, px, py,
        { showAuto = self.settings.showAuto == true, extra = extra, direct = opts ~= nil and opts.direct == true })
    if info.reason ~= nil then
        say(string.format(L["WowNav catalogue not usable: %s"], tostring(info.reason)))
    end
    return rows, info
end

-- ---- floors: asked only when there is a choice
local floorChoice = nil

function module:floorChoice()
    return floorChoice
end

local function askFloor(floors, onChoose)
    floorChoice = { floors = floors, onChoose = onChoose }
    WowVision.UIHost:openWindow("wownavFloors")
end

function module:chooseFloor(floor)
    local choice = floorChoice
    floorChoice = nil
    WowVision.UIHost:closeWindow("wownavFloors")
    if choice ~= nil then
        choice.onChoose(floor)
    end
end

-- The floors of an ambiguous target (his bands or certified levels), with the ones that cannot be reached marked;
-- at the target's position (`x`, `y`: where the floor window looks up their names).
local function targetFloors(outcome, x, y)
    local floors = {}
    for i, band in ipairs(outcome.result.bands) do
        floors[#floors + 1] = { band = i, z = band.zMin, reachable = outcome.reachable[i] == true, x = x, y = y }
    end
    return floors
end

-- ---- the route request

-- How far an approximate target lies from the network (his Describe / desc_inexact).
local function approximateText(result)
    if result == nil or result.quality ~= "approximate" then
        return nil
    end
    if result.normalizedWater then
        return string.format(L["water surface, diving depth %d yards"], math.floor((result.divingDepth or 0) + 0.5))
    end
    local yards = result.delta3D or result.deltaXY or 0
    if yards < 1 then
        return nil
    end
    local text = string.format(L["approximate, %d yards"], math.floor(yards + 0.5))
    if result.zUnknown then
        text = text .. ", " .. L["height unknown"]
    end
    return text
end

local function routeLength(N, path, index, px, py)
    local sum, x, y = 0, px, py
    for i = index, #path do
        local wx, wy = N.Position(path[i])
        sum = sum + Route.distance(x, y, wx, wy)
        x, y = wx, wy
    end
    return sum
end

-- The player's zones and their seam neighbours, decoded ahead (his PreloadNeighbours): { key, pending, index, keep }.
local preload = nil

-- The zones a route touches stay decoded, with the player's own and the target's, and the zones prepared around the
-- player; all others are dropped.
local function keepRouteZones(N, path, px, py, map, targetNodeId)
    local keep = {}
    for zoneId in pairs(preload and preload.keep or {}) do
        keep[zoneId] = true
    end
    local ids = { targetNodeId }
    for _, id in ipairs(path) do
        ids[#ids + 1] = id
    end
    for _, id in ipairs(ids) do
        if id < N.VIRT_BASE then
            keep[math.floor(id / N.ZONE_BASE)] = true
        else
            local point = N.virt[id]
            if point and point.zone then
                keep[point.zone.id] = true
            end
        end
    end
    if px ~= nil then
        N.activeMapId = map
        for _, zoneId in ipairs(N.ZonesForPoint(px, py)) do
            keep[zoneId] = true
        end
    end
    N.KeepZones(keep)
end

local function startRoute(self, request, outcome)
    local N = self:network()
    local trimmed = false
    if request.dockTarget ~= nil and request.dockTarget.facilityKind == "tram" then
        -- a tram dock's route ends before a last drop (its waiting nodes lay in the track bed); a ship's pier slopes
        -- down to the dock (Menethil: 3.6 yd over 30 yd to the dock to Auberdine), cut there it ended 70 yd early and
        -- the boarding beacon had no point
        local cut = dock.trimDrop(N, outcome.plan.path)
        if cut ~= nil then
            outcome.plan.path = cut
            trimmed = true
        end
    end
    route:begin(outcome.plan, request.contract, outcome.result, request.label)
    -- a target picked as the start (not a waypoint) is the first waypoint itself; not after a transit, whose route
    -- goes on from the far end
    local start = request.start
    local fromStart = start ~= nil and route.path[1] == request.startOverride
    if fromStart and start.nodeId == nil then
        route:prependStart(start.x, start.y, start.z)
    end
    -- Ctrl-Shift-R: the way back was found; Ctrl-Shift-N goes there again. Once: a transit's continuation starts anew.
    local reversed = request.reversed
    request.reversed = nil
    if reversed ~= nil then
        maps.lastDestination = reversed.destination
    end
    -- start and target on the same spot: nothing to walk on the network
    local sameSpot = fromStart and Route.sameSpot(start, request.contract) and route:dropToEnd()
    if request.dockTarget ~= nil and not trimmed then
        route.waitCheck = dock.waitAreaCheck(N, request.dockTarget)
    end
    route.activation = request.activationTarget
    do
        local lastX, lastY, lastZ = N.Position(route.path[#route.path])
        logLine(string.format("route %s: %d waypoints, ends %.1f %.1f %.1f%s%s", tostring(request.label), #route.path,
            lastX or 0, lastY or 0, lastZ or 0, request.dockTarget and ", to a dock" or "",
            trimmed and ", cut before the drop" or ""))
    end
    local px, py, map = route.env.position()
    routeMap = map
    -- the target's zone too: after a transit the route goes on to the same binding
    keepRouteZones(N, route.path, px, py, map, route.targetBindingId)
    local path = WowVision.WowNavPath:new(self, route, request.label)
    self.path = path
    self.request = request
    maps:pathfind(path)

    local count = #route.path
    local yards = px ~= nil and routeLength(N, route.path, route.pathIndex, px, py) or 0
    -- standing on it: the arrival of the first update says all there is
    if sameSpot and yards <= route.G.EffectiveRadius(Route.ARRIVAL_TARGET_RADIUS) then
        return
    end
    local text = string.format("%d %s, %d %s", count, L["waypoints"], yards, L["yards"])
    local approx = approximateText(outcome.result)
    if approx ~= nil then
        text = text .. ", " .. approx
    end
    if route.pendingAction ~= nil then
        text = text .. ", " .. string.format(L["then %s"], TRANSIT_WORDS[route.pendingAction.kind] or L["the transit"])
    end
    -- his approx_target: a catalogue position that is itself only approximate
    if request.approx then
        text = text .. ". " .. WowVisionNavigationText("approx_target")
    end
    -- his Z2 warning: no way around an enemy outpost, or the target inside one
    local outpost = outcome.plan and outcome.plan.result and outcome.plan.result.outpost
    if outpost == "through" or outpost == "target" then
        text = text .. ". " .. WowVisionNavigationText("outpost_" .. outpost)
    end
    if reversed ~= nil then
        text = reversed.text .. ". " .. text
    end
    say(text)
end

-- The network point of the request's start (request.startOverride, catalog.startNode): a waypoint's own or a target's
-- resolved anew. False, said, when the entry point has none.
local function bindStart(self, request)
    local _, _, map = route.env.position()
    local id, z = catalog.startNode(self:network(), _G.WowVisionNavigationTargetResolver, catalog.activeNav(),
        request.start, map)
    if id == nil then
        say(L["No network point at the chosen start"])
        return false
    end
    request.startOverride, request.startZ = id, z
    return true
end

-- A job planning in time slices, as every search (stepJob runs it).
local function newJob(N, request, work)
    return { request = request, startedAt = GetTime(), job = work, frames = 0, misses = N.wholeMisses or 0,
        answers = N.knownMissAnswers or 0 }
end

-- Starts the search for a request. request: { contract or nodeId, label, onArrive, start }; start: the entry point the
-- route starts at (a row of catalog.entryPoints: a target or a waypoint). WowNav never binds the player's position for
-- a start (his N.Bind): the player picks it in F10, like with the route data.
local function search(self, request)
    local N = self:network()
    local _, _, map = route.env.position()
    if request.startOverride == nil and not bindStart(self, request) then
        return
    end
    -- the start point's height is the route's height from here (his manual start node: exact x, y and z)
    route.anchor.last = request.startZ
    -- the engine looks for zones on the player's map only (index boxes of other maps overlap)
    N.activeMapId = map
    local work
    if request.nodeId ~= nil then
        work = N.Job(route.prepareNode, route, request.nodeId, request.startOverride)
    else
        work = N.Job(route.prepare, route, request.contract, { nativeMapId = map }, request.startOverride)
    end
    job = newJob(N, request, work)
end

-- The contract of a target maps hands over as a position (scanner, places list, /beacon to, the route data's points).
local function positionContract(target, map)
    return {
        id = "wowvision:" .. tostring(target.label or "target"), kind = "live", nameEn = target.label or "?",
        nativeMapId = map, coordinateSpace = "world", x = target.x, y = target.y, z = target.z,
        zStatus = target.z == nil and "unknown" or "known",
    }
end

-- The request for one target maps hands over ({ x, y, z, label, onArrive, data, start, reversed }; data: a row of the
-- WowNav list; start: the entry point picked in F10, a row of catalog.entryPoints): { nodeId or contract, label,
-- onArrive, start, dockTarget, activationTarget, approx, lowestFloor, reversed }. Nil when there is nothing to walk
-- to, with why: "fail" and the text to say, or "passive", the dock the player waits at and its source (routeTo says
-- it; a nearest pick leaves the target out).
local function targetRequest(N, target, px, py, map)
    local start = type(target.start) == "table" and target.start or nil
    if type(target.data) == "table" and target.data.nodeId ~= nil then
        -- an automatic waypoint: straight to it, no target to resolve
        return { nodeId = target.data.nodeId, label = target.label, onArrive = target.onArrive, start = start,
            reversed = target.reversed }
    end
    -- a boarding point ("At the vehicle") picked as a route's destination is a place like any other: routed to on the
    -- network, never taken for its dock (it lies a few yards from the dock's waiting point); F10's Direct leads
    -- straight to it instead
    local boarding = type(target.data) == "table" and target.data.boardingTargetId ~= nil
    local dockTarget
    local dockRow = not boarding and dock.isDockRow(target.data) and target.data or nil
    if dockRow == nil and not boarding then
        -- a position (scanner, places list, /beacon to, the route data's own points) that is a dock is that dock; a
        -- target at the far end of a line while the player is in its station is a ride to that end's dock
        local wownavRow = type(target.data) == "table" and target.data.tid ~= nil
        dockRow = (not wownavRow and dock.rowAt(N, target.x, target.y)) or dock.rideFor(N, px, py, target.x, target.y)
        if dockRow ~= nil then
            logLine("taken as the dock " .. tostring(dockRow.n))
            target.data = dockRow
        end
    end
    if dockRow ~= nil then
        -- a dock: the other dock of the line is noted (nothing to walk), any other dock is walked to
        local outcome, value, why, source = dock.choose(N, dockRow, px, py)
        if why ~= nil then
            logLine(why)
        end
        if outcome == "fail" or outcome == "passive" then
            return nil, outcome, value, source
        end
        dockTarget = value
    end
    -- a portal or tram entrance as the target (his walk-in activation): checked against its proof, then walked into
    local activationTarget
    if dockTarget == nil and type(target.data) == "table" and target.data.activationMode == "walk_into_trigger" then
        local outcome, value = dock.activation(N, target.data)
        if outcome == "fail" then
            return nil, outcome, value
        end
        activationTarget = value
    end
    local contract
    if type(target.data) == "table" and target.data.unit ~= nil then
        -- a group member (his GroupMember): a live target that expires after 30 s, read again on a new route
        contract = module.unitContract(target.data.unit, map)
        if contract == nil then
            return nil, "fail", WowVisionNavigationText("no_live_coordinates")
        end
    elseif type(target.data) == "table" and target.data.tid ~= nil then
        contract = catalog.contract(target.data, map)
    else
        contract = positionContract(target, map)
    end
    return { contract = contract, label = target.label, onArrive = target.onArrive, dockTarget = dockTarget,
        activationTarget = activationTarget, approx = type(target.data) == "table" and target.data.approx == true,
        lowestFloor = type(target.data) == "table" and target.data.lowestFloor == true, start = start,
        reversed = target.reversed }
end

-- The network maps routes on here: N, the player's position and map; nil (logged) where WowNav has no data.
local function routable(self, label)
    local N = ready(self)
    if N == nil then
        return nil
    end
    local px, py, map = route.env.position()
    if px == nil or not catalog.covers(N, map) then
        logLine(string.format("not taken: no WowNav data here (%s)", tostring(label)))
        return nil
    end
    N.activeMapId = map
    if #N.ZonesForPoint(px, py) == 0 then
        return nil
    end
    return N, px, py, map
end

-- A route request from maps (see targetRequest). True when WowNav took it.
function module:routeTo(target)
    local px, py, map = route.env.position()
    local data = type(target.data) == "table" and target.data or nil
    logLine(string.format("request %s at %.1f %.1f from %s %s map %s: %s", tostring(target.label), target.x or 0,
        target.y or 0, px and string.format("%.1f", px) or "?", py and string.format("%.1f", py) or "?", tostring(map),
        data == nil and "a position" or (data.boardingTargetId and "a boarding point") or (data.nodeId and "a waypoint")
            or string.format("%s %s", tostring(data.tid), tostring(data.interactionMode or data.kind))))
    local N
    N, px, py, map = routable(self, target.label)
    if N == nil then
        return false
    end
    local request, why, value, source = targetRequest(N, target, px, py, map)
    if request == nil then
        if why == "passive" then
            self:stopRoute(nil, true)
            passive = { name = WowVisionNavigationTargetName(value), near = false }
            say(dock.passiveText(source, value))
        else
            say(value)
        end
        return true
    end
    -- every route starts at the entry point the player picked; none: nothing of the network near enough to list
    if request.start == nil then
        say(L["No WowNav network here"])
        return true
    end
    if bindStart(self, request) then
        self:stopRoute()
        search(self, request)
    end
    return true
end

-- How far the walk to a planned target is: the whole route on the network (a transit is ridden, not walked; the plan's
-- path itself stops at the first one) and the stretch from its end to the target.
local function walkLength(N, outcome)
    local whole = outcome.plan.result and outcome.plan.result.length or N.PathLength(outcome.plan.path)
    local off = outcome.result and (outcome.result.delta3D or outcome.result.deltaXY) or 0
    return whole + off
end

-- Auto Route (navigation/visited.lua): of several targets of the same name, requests as for routeTo with the same
-- start, the one the shortest walk reaches. One job plans a route to each, in time slices like every search, and the
-- shortest becomes the request (its onChosen runs first); a target whose floor is not clear is left out unless no
-- other has a route, and one with nothing to walk to (a dock the player waits at) is left out. True when WowNav took
-- it. The search line of the log says how long the planning took.
function module:routeToNearest(targets)
    local first = targets[1]
    if first == nil then
        return false
    end
    local N, px, py, map = routable(self, first.label)
    if N == nil then
        return false
    end
    local start = type(first.start) == "table" and first.start or nil
    if start == nil then
        say(L["No WowNav network here"])
        return true
    end
    local candidates = {}
    for _, target in ipairs(targets) do
        local candidate = targetRequest(N, target, px, py, map)
        if candidate ~= nil then
            candidate.onChosen = target.onChosen
            tinsert(candidates, candidate)
        end
    end
    if #candidates == 0 then
        say(L["No route found"])
        return true
    end
    logLine(string.format("nearest by walk of %d %s from %.1f %.1f map %s", #candidates, tostring(first.label), px, py,
        tostring(map)))
    local request = { label = first.label, start = start }
    if not bindStart(self, request) then
        return true
    end
    self:stopRoute()
    route.anchor.last = request.startZ
    local function plan()
        local best, bestLength, firstChoice, lastFail
        for _, candidate in ipairs(candidates) do
            local outcome
            if candidate.nodeId ~= nil then
                outcome = route:prepareNode(candidate.nodeId, request.startOverride)
            else
                outcome = route:prepare(candidate.contract, { nativeMapId = map }, request.startOverride)
            end
            if outcome.kind == "start" then
                local length = walkLength(N, outcome)
                if bestLength == nil or length < bestLength then
                    best, bestLength = { candidate = candidate, outcome = outcome }, length
                end
            elseif outcome.kind == "choose" then
                firstChoice = firstChoice or { candidate = candidate, outcome = outcome }
            else
                lastFail = outcome
            end
        end
        local pick = best or firstChoice
        if pick == nil then
            return lastFail or { kind = "fail", reason = "no_route_found" }
        end
        -- the request becomes the picked one's: the route, its arrival and a floor question are about it
        for key, value in pairs(pick.candidate) do
            if key ~= "onChosen" and key ~= "start" then
                request[key] = value
            end
        end
        if pick.candidate.onChosen ~= nil then
            pick.candidate.onChosen()
        end
        say(pick.candidate.label)
        return pick.outcome
    end
    job = newJob(N, request, N.Job(plan))
    return true
end

-- Ctrl-Shift-R: the running route turned around. The new route starts at the waypoint the beacon leads to now (the
-- next real network point when that one is virtual: a picked target before its network point) and leads back to
-- where the previous route started: the target or waypoint picked as its entry point in F10, else its start node.
-- Nil when no WowNav route runs; true when the request was made.
function module:reverseRoute()
    local request, path = self.request, self.path
    local N = self:network()
    if request == nil or path == nil or route == nil or not route.active or route.path == nil
        or request.startOverride == nil or N == nil then
        return nil
    end
    local from
    for i = route.pathIndex or 1, #route.path do
        local id = route.path[i]
        if N.virt[id] == nil then
            from = id
            break
        end
    end
    if from == nil then
        return nil
    end
    local _, _, fromZ = N.Position(from)
    local start = request.start
    local data, x, y, z
    if type(start) == "table" and (start.tid ~= nil or start.nodeId ~= nil) and start.x ~= nil then
        data, x, y, z = start, start.x, start.y, start.z
    else
        data = { nodeId = request.startOverride }
        x, y, z = N.Position(request.startOverride)
        data.x, data.y, data.z = x, y, z
    end
    local label = (type(start) == "table" and start.n) or L["the start of the previous route"]
    if data.n == nil then
        data.n = label
    end
    -- the search answers later: said and remembered when the route starts (startRoute), a failed one says why
    local reversed = { text = string.format(L["Route reversed, back to %s"], label), destination = data }
    if self:routeTo({ x = x, y = y, z = z, label = label, data = data, start = { nodeId = from, z = fromZ },
        reversed = reversed }) then
        return true
    end
    say(L["No route found"])
    return false
end

-- His TargetProviders:GroupMember: the unit's position now as a live target, valid for 30 s; nil without one.
function module.unitContract(unit, map)
    if UnitExists ~= nil and not UnitExists(unit) then
        return nil
    end
    local ok, x, y, _, unitMap = pcall(UnitPosition, unit)
    local finite = _G.WowVisionNavigationTargetCatalog.Finite
    if not ok or not finite(x) or not finite(y) or (unitMap ~= nil and unitMap ~= map) then
        return nil
    end
    local name = UnitName ~= nil and UnitName(unit) or unit
    local now = GetTime()
    return {
        id = "group:" .. unit, kind = "live", nameEn = name or unit, nativeMapId = map, coordinateSpace = "world",
        x = x, y = y, zStatus = "unknown", category = { "live" }, source = { provider = "wow_api", record = unit },
        updatedAt = now, expiresAt = now + 30, unit = unit,
    }
end

-- A request's target again: a group member's position is read anew (his WowVisionNavigationLayerTargetNew); nil
-- when the member is gone.
local function freshContract(request, map)
    if request.contract ~= nil and request.contract.unit ~= nil then
        return module.unitContract(request.contract.unit, map)
    end
    return request.contract
end

-- Ends the running route, the search and a waiting transit; with them the dock guidance (his StopNavigation resets
-- the dock module unless the wait context is kept: keepDock, for the noted dock and a boarding point) and the fishing
-- spot that was reached.
function module:stopRoute(keepPenalties, keepDock)
    job = nil
    fishing.reset()
    if not keepDock then
        local Dock = _G.WowVisionNavigationDockNavigation
        if Dock ~= nil then
            Dock:Reset(false)
        end
        passive = nil
    end
    if self.dockPath ~= nil then
        self.dockPath:finish()
        if maps.path == self.dockPath then
            maps:stopPath()
        end
        self.dockPath = nil
    end
    if route ~= nil then
        route:cancelAction()
        route:reset(keepPenalties)
    end
    if self.path ~= nil then
        self.path:finish()
        if maps.path == self.path then
            maps:stopPath()
        end
        self.path = nil
    end
    routeMap = nil
end

local function onOutcome(self, request, outcome)
    if outcome.kind == "start" then
        startRoute(self, request, outcome)
    elseif outcome.kind == "choose" then
        local contract = request.contract or {}
        local floors = targetFloors(outcome, contract.x, contract.y)
        if request.lowestFloor then
            -- a target without a height that is walked to on the ground (the corpse run): the lowest floor a route
            -- reaches, no question
            request.contract.heightBand = WowVision.corpseFind.lowestFloor(floors).band
            search(self, request)
            return
        end
        askFloor(floors, function(floor)
            request.contract.heightBand = floor.band
            search(self, request)
        end)
    else
        say(reasonText(outcome.reason))
    end
end

local function stepJob(self)
    local j = job
    if j == nil then
        return
    end
    local done, outcome, failure = j.job:Step(BUDGET_MS, debugprofilestop)
    j.frames = j.frames + 1
    if done then
        -- how long the search took, and the whole searches that missed (the floor check) and what they answered
        local N = self:network()
        logLine(string.format("search %s: %s after %.1f s in %d frames, %d whole misses, %d targets answered from them",
            tostring(j.request.label), type(outcome) == "table" and tostring(outcome.kind) or tostring(failure),
            GetTime() - j.startedAt, j.frames, (N.wholeMisses or 0) - j.misses, (N.knownMissAnswers or 0) - j.answers))
    end
    if not done then
        if not j.noticed and GetTime() - j.startedAt >= SLOW_NOTICE then
            j.noticed = true
            say(L["Calculating route"])
        end
        return
    end
    job = nil
    if type(outcome) ~= "table" then
        say(L["No route found"] .. (failure ~= nil and (" " .. tostring(failure)) or ""))
        return
    end
    onOutcome(self, j.request, outcome)
end

-- ---- what the route says while it is walked (path.lua)
function module:onRouteEvent(path, event)
    if path ~= self.path then
        return
    end
    local kind = event.kind
    if kind == "advance" then
        if event.careful then
            say(L["Last network point; the last stretch is unchecked, move carefully"])
        end
    elseif kind == "reentry" then
        say(L["Back on the route"])
    elseif kind == "fallback" then
        say(L["One waypoint back"])
    elseif kind == "arrived" and self.request ~= nil and self.request.dockTarget ~= nil then
        -- at the dock: his Arrival says what to wait for; the beacon leads to the boarding point
        local request = self.request
        path:finish()
        maps:stopPath()
        self.path = nil
        route:reset()
        local x, y = route.env.position()
        logLine(string.format("arrived at the dock %s at %.1f %.1f", tostring(request.label), x or 0, y or 0))
        local boarding = dock.arrived(self:network(), request.dockTarget, x, y)
        if boarding ~= nil then
            self.dockPath = boarding
            maps:pathfind(boarding)
        end
        if request.onArrive ~= nil then
            request.onArrive()
        end
    elseif kind == "arrived" then
        local request = self.request
        path:finish()
        maps:stopPath()
        self.path = nil
        local label = request and request.label
        local result = event.result
        local x, y = route.env.position()
        local N = self:network()
        local radius = route.G.EffectiveRadius(Route.ARRIVAL_TARGET_RADIUS)
        if request ~= nil and fishing.arrived(N, request.contract, x, y, radius) then
            -- at a fishing spot: his Arrival says where the water lies; the beacon sounds from it
            logLine(string.format("arrived at the fishing spot %s at %.1f %.1f", tostring(label), x or 0, y or 0))
            local water = fishing.waterPath(N)
            if water ~= nil then
                self.dockPath = water
                maps:pathfind(water)
            end
        elseif Route.reachesTarget(result, radius) then
            -- an approximate result whose network ends at the target is an arrival too (Route.reachesTarget)
            say(L["Arrived"] .. (label ~= nil and (" " .. label) or ""))
        elseif result.normalizedWater then
            -- his stop_water_net_ends / stop_net_ends: how far the network ends from the target
            say(WowVisionNavigationText("stop_water_net_ends", result.delta3D or result.deltaXY or 0,
                result.divingDepth or 0))
        else
            say(WowVisionNavigationText("stop_net_ends", result.delta3D or result.deltaXY or 0,
                result.zUnknown and WowVisionNavigationText("suffix_horizontal") or ""))
        end
        if request ~= nil and request.onArrive ~= nil then
            request.onArrive()
        end
        route:reset()
    elseif kind == "prepoint" then
        if event.unresolved then
            say(WowVisionNavigationText("prepoint_reached_unresolved"))
        else
            say(activationText(event.target, "prepoint_reached"))
        end
    elseif kind == "activation" then
        if event.unresolved then
            say(WowVisionNavigationText("activation_position_reached",
                event.heightUnconfirmed and WowVisionNavigationText("height_not_confirmed") or ""))
        else
            say(activationText(event.target, "activation_area"))
        end
    elseif kind == "transit" then
        local request = self.request
        path:finish()
        maps:stopPath()
        self.path = nil
        local text = transitText(event.action)
        -- said before the portal already (transitAhead), or through it (its teleport came between two updates):
        -- "The route goes on" follows at once
        if not event.teleported and not event.announced then
            say(text)
        end
        local targetNodeId, result = route.targetBindingId, route.result
        route:reset()
        route:startAction(event.action, request, targetNodeId, result, event)
        local action, sv, av = event.action, event.action.sourceVolume or {}, event.action.arrivalVolume or {}
        logLine(string.format("transit %s: waiting for its far end (%s), source %.1f %.1f r %s, arrival %.1f %.1f r %s",
            tostring(action.kind), tostring(action.arrival and action.arrival.mode), sv.x or 0, sv.y or 0,
            tostring(sv.radius or sv.half_x), av.x or 0, av.y or 0, tostring(av.radius or av.half_x)))
    elseif kind == "transitAhead" then
        -- a portal teleports the moment it is entered: what to do is said before it
        say(string.format(L["Ahead: walk into %s; the route goes on after it"],
            TRANSIT_WORDS[event.action.kind] or L["the transit"]))
    elseif kind == "lost" then
        self:stopRoute()
        say(L["Route ended"])
    end
end

-- The transit continuation: once the player came out at the far end, the route goes on from there.
-- The saved trail notes a jump of the player (a portal's teleport) while a transit waits: where he came out, how far
-- from the transit's arrival, and whether the source was entered first -- so a missed arrival can be read later.
local function traceAction(current, x, y, map)
    if x == nil then
        return
    end
    if current.traceX ~= nil and Route.distance(x, y, current.traceX, current.traceY) > 50 then
        local av = current.action.arrivalVolume
        logLine(string.format("transit: jumped to %.1f %.1f map %s, %.0f yd from its arrival, source %s", x, y,
            tostring(map), type(av) == "table" and type(av.x) == "number" and Route.distance(x, y, av.x, av.y) or -1,
            current.sourceEntered and "entered" or "never entered"))
    end
    current.traceX, current.traceY = x, y
end

local function checkAction(self)
    if route == nil or route.action == nil or job ~= nil then
        return
    end
    local x, y, map = route.env.position()
    local current = route.action
    local state = route:observeAction(x, y, map, route.G.MinArrivalRadius())
    traceAction(current, x, y, map)
    if state ~= nil then
        logLine(string.format("transit: %s at %.1f %.1f", state, x or 0, y or 0))
    end
    if state == "timeout" then
        say(L["The transit took too long; route ended"])
    elseif state == "arrived" then
        local request, toNode, targetNodeId, result = route:actionArrival()
        if request ~= nil then
            say(L["The route goes on"])
            local N = self:network()
            N.activeMapId = map
            job = newJob(N, request, N.Job(route.continueTo, route, toNode, targetNodeId, result))
        end
    end
end

-- A route ends when the player dies, or comes onto another map (his PLAYER_DEAD and continent change), and when
-- WowVision's navigation was stopped (Shift-F12).
local function checkRunning(self)
    if self.path == nil then
        return
    end
    if maps.path ~= self.path then
        self:stopRoute()
        return
    end
    local x, y, map = route.env.position()
    if x ~= nil and routeMap ~= nil and map ~= routeMap then
        -- after a walk-in target's capture circle the map change ends the route (his B5)
        local activation, inside = route.activation, route.activationInside
        self:stopRoute()
        if activation ~= nil then
            local key = inside and "reason_activation_map_changed" or "reason_map_changed_guidance_done"
            say(WowVisionNavigationText(key))
        else
            say(L["Route ended"])
        end
        return
    end
    -- his stop_outside_zones: a route that leaves every zone of the network ends
    local N = self:network()
    if x ~= nil and N ~= nil and #N.ZonesForPoint(x, y) == 0 then
        self:stopRoute()
        say(WowVisionNavigationText("stop_outside_zones"))
    end
end

-- The target of the route being searched or walked, nil without one.
function module:runningRequest()
    if job ~= nil then
        return job.request
    end
    if self.path ~= nil and route ~= nil and route.active then
        return self.request
    end
    return nil
end

-- Where a route searched again starts: the last waypoint of the running route the player has reached (the one he came
-- from; a blocked link lies after it), else its first; before the route is walked (still searched) the request's own
-- start. Never the position bound anew: like every start, it is a waypoint of the route the player picked.
local function restartPoint(self, request)
    local N = self:network()
    if route ~= nil and route.active and route.path ~= nil then
        for i = math.max((route.pathIndex or 1) - 1, 1), 1, -1 do
            local id = route.path[i]
            if id ~= nil and id < N.VIRT_BASE then
                local _, _, z = N.Position(id)
                return { nodeId = id, z = z }
            end
        end
    end
    return request.start
end

-- A changed road preference applies to the running route as well (his /vn komfort does the same): once the slider
-- has rested for RECALC_DELAY, the same target is searched again from the route's last reached waypoint.
local function checkRecalculation(self)
    if recalcAt == nil or GetTime() < recalcAt then
        return
    end
    recalcAt = nil
    local request = self:runningRequest()
    if request ~= nil then
        local _, _, map = route.env.position()
        local contract = freshContract(request, map)
        if contract == nil and request.nodeId == nil then
            self:stopRoute()
            say(WowVisionNavigationText("target_source_gone"))
            return
        end
        say(L["Searching the route again with the new road preference"])
        local start = restartPoint(self, request)
        self:stopRoute()
        search(self, { contract = contract, nodeId = request.nodeId, label = request.label,
            onArrive = request.onArrive, start = start })
    end
end

-- His /vn neu: the link the player is stuck on gets a penalty and the target is searched again from the route's last
-- reached waypoint (before the blocked link).
function module:newRoute()
    if route == nil or not route.active or self.path == nil then
        say(L["No active route"])
        return false
    end
    local request = self.request
    local start = restartPoint(self, request)
    route:penalizeCurrentLink()
    self:stopRoute(true)
    local _, _, map = route.env.position()
    local contract = freshContract(request, map)
    if contract == nil and request.nodeId == nil then
        say(WowVisionNavigationText("target_source_gone"))
        return false
    end
    say(L["Searching a new route"])
    search(self, { contract = contract, nodeId = request.nodeId, label = request.label,
        onArrive = request.onArrive, start = start })
    return true
end

-- The catalogue of the player's map is read in the background, one zone per step; then, like his zone loader
-- (ActivatePackage and PreloadNeighbours), the player's zones and the zones that share a seam with them are decoded,
-- one per step. Zones the player walks into later get their neighbours prepared the same way.
local PRELOAD_CHECK = 1.0      -- seconds between two looks at the player's zones
local preloadCheckAt = 0

local function stepPreload(N, px, py, map)
    local now = GetTime()
    if preload == nil or now >= preloadCheckAt then
        preloadCheckAt = now + PRELOAD_CHECK
        N.activeMapId = map
        local own = N.ZonesForPoint(px, py)
        table.sort(own)
        local key = map .. ":" .. table.concat(own, ",")
        if preload == nil or preload.key ~= key then
            local keep, pending = {}, {}
            local function add(zoneId)
                if not keep[zoneId] then
                    keep[zoneId] = true
                    if not N.decoded[zoneId] and N.ZoneAvailable(zoneId) then
                        pending[#pending + 1] = zoneId
                    end
                end
            end
            for _, zoneId in ipairs(own) do
                add(zoneId)
            end
            for _, zoneId in ipairs(own) do
                for _, neighbour in ipairs(N.NeighbourZones(zoneId)) do
                    if (N.index[neighbour] and (N.index[neighbour].nativeMapId or N.index[neighbour].mapId)) == map then
                        add(neighbour)
                    end
                end
            end
            preload = { key = key, pending = pending, index = 0, keep = keep }
        end
    end
    local zoneId = preload.pending[preload.index + 1]
    if zoneId ~= nil then
        preload.index = preload.index + 1
        if not N.decoded[zoneId] then
            N.LoadZone(zoneId)
        end
    end
end

local function stepCatalog(self)
    local N = ready(self)
    if N == nil then
        return
    end
    local px, py, map = route.env.position()
    if map == nil or not catalog.covers(N, map) then
        return
    end
    catalog.start(N, map)
    if catalog.step(N, _G.WowVisionNavigationTargetCatalog) then
        return
    end
    if px ~= nil and module.settings.preload ~= false then
        stepPreload(N, px, py, map)
    end
end

-- The noted dock (his passive mode): WowVision says once when it is near, so the turn key can face it.
local function checkPassive(self)
    if passive == nil or passive.near then
        return
    end
    local N = self:network()
    local x, y = route.env.position()
    local px, _, id = dock.alignment(N, x, y)
    if px ~= nil and type(id) == "string" and id:find("^dock%-passive:") then
        passive.near = true
        logLine("near the noted dock " .. tostring(passive.name))
        say(string.format(L["%s is near; I turns you toward it"], passive.name or ""))
    end
end

-- The turn key without a route (his I at a dock): at a reached dock the boarding point, near the noted dock that dock,
-- on a fishing spot that was reached its water.
-- Other users of maps.facingWithoutWaypoint (the surroundings) answer when the dock has nothing to face.
local turnHooked = false
local function hookTurn(self)
    if turnHooked then
        return
    end
    turnHooked = true
    local previous = maps.facingWithoutWaypoint
    maps.facingWithoutWaypoint = function()
        if engine:isActive() then
            local x, y = route.env.position()
            local px, py = dock.alignment(self:network(), x, y)
            if px == nil then
                px, py = fishing.alignment(self:network(), x, y)
            end
            if px ~= nil then
                return math.atan2(py - y, px - x)
            end
        end
        if previous ~= nil then
            return previous()
        end
        return nil
    end
end

local dockMap = nil
function module:onEnable()
    hookTurn(self)
    self:hasUpdate(function(self)
        if not engine:isActive() then
            return
        end
        stepJob(self)
        checkRunning(self)
        checkAction(self)
        checkRecalculation(self)
        checkPassive(self)
        local _, _, map = route.env.position()
        if map ~= nil and map ~= dockMap then
            -- his ZoneLoaded at a continent change: a reached dock is forgotten, a noted one is kept
            if dockMap ~= nil and _G.WowVisionNavigationDockNavigation ~= nil then
                _G.WowVisionNavigationDockNavigation:ZoneLoaded(nil)
            end
            if dockMap ~= nil then
                fishing.reset()
            end
            dockMap = map
        end
        if job == nil then
            stepCatalog(self)
        end
    end)
end

module:registerEvent("event", "PLAYER_DEAD")

function module:onEvent(event)
    if event == "PLAYER_DEAD" and (self.path ~= nil or job ~= nil or (route ~= nil and route.action ~= nil)) then
        self:stopRoute()
    end
end

-- His /vn status: what WowNav guides to now.
function module:status()
    local Dock = _G.WowVisionNavigationDockNavigation
    if job ~= nil then
        say(string.format(L["Searching the route to %s"], tostring(job.request.label or "")))
    elseif self.path ~= nil and route ~= nil and route.active then
        say(string.format(L["En route to %s, waypoint %d of %d"], tostring(self.request and self.request.label or ""),
            route.pathIndex or 0, #(route.path or {})))
    elseif route ~= nil and route.action ~= nil then
        say(string.format(L["Waiting for the far end of %s"],
            TRANSIT_WORDS[route.action.action.kind] or L["the transit"]))
    elseif passive ~= nil then
        say(string.format(L["Riding to the noted dock %s"], tostring(passive.name or "")))
    elseif Dock ~= nil and Dock.reached ~= nil then
        say(L["At a dock, waiting"])
    elseif fishing.reached() then
        say(L["At a fishing spot"])
    else
        say(L["No active route"])
    end
end

module:registerBinding({
    type = "Script",
    key = "wownav/status",
    label = L["WowNav Route Status"],
    inputs = {},
    script = "/run WowVision.base.navigation.wownav:status()",
})

module:registerBinding({
    type = "Script",
    key = "wownav/newRoute",
    label = L["New WowNav Route Around a Blocked Spot"],
    inputs = {},
    script = "/run WowVision.base.navigation.wownav:newRoute()",
})

module.settings.class:getField("comfort").events.valueChange:subscribe(module, function()
    if module:runningRequest() ~= nil then
        recalcAt = GetTime() + RECALC_DELAY
    end
end)

-- his /vn outposts: the running route is recalculated with the new choice
module.settings.class:getField("avoidOutposts").events.valueChange:subscribe(module, function(_, _, _, _, value)
    local N = module:network()
    if N ~= nil and N.SetAvoidOutposts ~= nil then
        N.SetAvoidOutposts(value ~= false)
    end
    if module:runningRequest() ~= nil then
        recalcAt = GetTime() + RECALC_DELAY
    end
end)

-- Alt-P or the settings changed the arrival distance: the running route uses it at once
for _, key in ipairs(maps.arrivalDistanceKeys) do
    maps.settings.class:getField(key).events.valueChange:subscribe(module, function()
        local _, G = module:network()
        if G ~= nil then
            G.arrivalMin = maps:arrivalDistance()
        end
    end)
end

-- With the setting turned on while the standalone addon runs, say why nothing changes.
module.settings.class:getField("enabled").events.valueChange:subscribe(module, function(_, _, _, _, value)
    if value == true and standaloneLoaded() then
        say(L["Turn off the WowVisionNavigation addon to use its routes here"])
    end
end)
