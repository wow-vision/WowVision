-- The WowNav targets of a continent for WowVision's destination list (F10, /beacon to), the way Broesel's WowNav core
-- keeps and searches them (DemoAddon/WowVisionNavigation/WowVisionNavigation.lua of WoW_NavigationData: the zone
-- loader's ActivatePackage, Navigation.SearchTargets and WowVisionNavigationResolveListed; his 071a572).
--
-- The logical catalogues (NPCs, mobs, objects; compact format 2) and the dyn catalogues (dungeon entrances, portals,
-- docks, tram stops, elevators, zone crossings) of every zone on the player's map form one catalogue (his concept 7a),
-- activated in his TargetCatalog (C:ActivateZones). A compact catalogue stays as it is: no table per target. A search
-- tests the text once per target class, takes the distance from the compact rows, keeps the nearest SEARCH_LIMIT (1000)
-- hits and builds the row of a hit only (C:Scan, C.Nearest, C:Materialize). A hit whose zones are all decoded is
-- resolved (and dropped when no network cell takes it); a hit in a zone no route has needed yet is offered unchecked
-- and resolved when it is chosen. The search text is everything the row says except the distance: the names in both
-- languages with the aliases, the categories and the zone.
--
-- What WowVision does instead of his core: the catalogues of a continent are decoded one zone per step in the
-- background (his core has them all as tables from the login; here they are packed text until then), the rows are
-- WowVision's list rows (name, categories and zone as the detail), and the automatic waypoints nearby come from
-- catalog.autoPoints and the boarding points of the docks from dock.lua (opts.extra). A row's detail starts with
-- his Describe of its resolution (inexact by how much, a floor to choose, water surface).

local text = WowVision.wownavText
local L = WowVision:getLocale()

local catalog = {}
WowVision.wownavCatalog = catalog

-- the localised name of a zone (WowNav's LocalizedZoneName: the client's name of the zone's own map)
local zoneNames = {}
local function zoneName(N, zoneId)
    local cached = zoneNames[zoneId]
    if cached ~= nil then
        return cached or nil
    end
    local name
    if C_Map ~= nil and C_Map.GetMapInfo ~= nil then
        local ok, info = pcall(C_Map.GetMapInfo, zoneId)
        if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
            name = info.name
        end
    end
    local entry = N.index[zoneId]
    name = name or (entry and entry.name)
    zoneNames[zoneId] = name or false
    return name
end

local function lower(s)
    return WowVision.utils ~= nil and WowVision.utils.foldCase ~= nil and WowVision.utils.foldCase(s) or s:lower()
end

-- The zones of the index on a native map.
function catalog.zonesOnMap(N, map)
    local zones = {}
    for id, entry in pairs(N.index) do
        if (entry.nativeMapId or entry.mapId) == map then
            zones[#zones + 1] = id
        end
    end
    table.sort(zones)
    return zones
end

function catalog.covers(N, map)
    return #catalog.zonesOnMap(N, map) > 0
end

-- ---- activation: the catalogue of the player's map (his ActivatePackage for a new continent)
local current = nil      -- { map, zones, next, nav, done, ok, reason }

-- Starts the activation of a map's catalogue; nothing happens while that map is already active or under way.
function catalog.start(N, map)
    if current ~= nil and current.map == map then
        return
    end
    if current ~= nil then
        for _, zoneId in ipairs(current.zones) do
            N.DropTargets(zoneId)      -- the catalogues of the map that is left go back to packed text
        end
    end
    local zones = catalog.zonesOnMap(N, map)
    local zoneSet = {}
    for _, id in ipairs(zones) do
        zoneSet[id] = true
    end
    -- his ContinentNavData: what TargetCatalog and TargetResolver read of the continent
    current = {
        map = map, zones = zones, next = 1, done = false,
        nav = {
            schema_version = 7, packageLayoutVersion = 3, targetSchemaVersion = 1, nativeMapId = map, zoneSet = zoneSet,
        },
    }
end

-- Decodes the catalogues of the next zone; after the last one the catalogue is activated. True while there is more.
function catalog.step(N, C)
    local c = current
    if c == nil or c.done then
        return false
    end
    if c.next <= #c.zones then
        local zoneId = c.zones[c.next]
        c.next = c.next + 1
        N.LogicalTargets(zoneId)
        N.DynTargets(zoneId)
        return true
    end
    local zones = {}
    for _, zoneId in ipairs(c.zones) do
        zones[#zones + 1] = { zoneId = zoneId, logical = N.LogicalTargets(zoneId), dynamic = N.DynTargets(zoneId) }
    end
    c.ok, c.reason = C:ActivateZones(c.nav, zones)
    c.done = true
    return false
end

-- The active catalogue of the map, finished first if the background has not got there yet. Returns nav or nil, reason.
function catalog.ensure(N, C, map)
    catalog.start(N, map)
    while catalog.step(N, C) do
    end
    if not current.ok then
        return nil, current.reason
    end
    return current.nav
end

function catalog.clear()
    current = nil
end

-- The nav of the activated catalogue (his NavData of the continent), or nil while it is not ready.
function catalog.activeNav()
    if current == nil or not current.ok then
        return nil
    end
    return current.nav
end

-- ---- the search (his Navigation.SearchTargets, mode "target")

-- his AutomaticListEntry: the generated points of the network are list entries only with showauto
local function automaticListEntry(target)
    if target.autoGenerated == true then
        return true
    end
    if type(target.id) == "string" and target.id:match("^node_") then
        return true
    end
    return type(target.nameEn) == "string" and target.nameEn:match("^Auto: ") ~= nil
        or type(target.nameDe) == "string" and target.nameDe:match("^Auto: ") ~= nil
end

-- his TargetSearchText: zoneId is the zone of the provider, for a stored row or a class of a compact catalogue
local function searchText(N, entry, zoneId, german)
    local parts = {
        text.targetName(entry, german) or "", entry.nameDe or "", entry.nameEn or "", text.categories(entry) or "",
    }
    for _, alias in ipairs(entry.searchAliases or {}) do
        parts[#parts + 1] = alias
    end
    zoneId = entry.zoneId or zoneId
    local zone = zoneId and N.index[zoneId]
    local name = zone and zoneName(N, zoneId) or entry.zoneName
    if name then
        parts[#parts + 1] = name
    end
    if zone and zone.name then
        parts[#parts + 1] = zone.name
    end
    return lower(table.concat(parts, " | "))
end

local function matches(N, entry, filter, zoneId, german)
    return filter == "" or searchText(N, entry, zoneId, german):find(filter, 1, true) ~= nil
end

-- his WowVisionNavigationResolveListed: the resolution of a list entry without a route context, kept until the
-- catalogue, the resolver settings or the map change (opening the list again must not resolve the hits anew)
local resolveCache = nil
function catalog.resolveListed(R, C, nav, target)
    local radius, tolerance = R:Settings()
    local store = resolveCache
    if not (store and store.map == nav.nativeMapId and store.revision == C.revision and store.radius == radius
        and store.tolerance == tolerance) then
        store = { map = nav.nativeMapId, revision = C.revision, radius = radius, tolerance = tolerance, results = {} }
        resolveCache = store
    end
    local key = target.expiresAt == nil and target.catalogKey or nil
    local result = key and store.results[key]
    if not result then
        result = R:Resolve(nav, target, {})
        if key then
            store.results[key] = result
        end
    end
    return result
end

-- One WowVision list row of a materialized target: what the list says and what a route request needs
-- (catalog.contract).
local function listRow(N, item, german)
    local zone = zoneName(N, item.zoneId)
    local categories = text.categories(item)
    local detail = categories and (categories .. ", " .. (zone or "")) or zone
    -- his Describe after the resolution (inexact, floor to choose, water), before the categories
    local described = text.describe(item.layerResolution):match("^%s*%((.*)%)%s*$")
    if described ~= nil then
        detail = detail ~= nil and (described .. ", " .. detail) or described
    end
    return {
        id = "wownav:" .. tostring(item.catalogKey), n = text.targetName(item, german), detail = detail,
        x = item.x, y = item.y, z = item.z, levels = item.levels, tid = item.id, kind = item.kind,
        creatureEntry = item.entry,
        nameEn = item.nameEn, zoneId = item.zoneId, surface = item.surface, resolution = item.layerResolution,
        layer = type(item.providerId) == "string" and item.providerId:find("^package_dyn_") and "dyn" or "logical",
        -- approx: a position that is itself an estimate (a compact row's p, a dyn row's approximate: Zephras Isle)
        interactionMode = item.interactionMode, activationMode = item.activationMode,
        approx = item.approx or item.approximate == true or nil,
        -- his Weg B: the fixed node of the target (a number, or a list as long as the levels) and the fingerprint of the
        -- navdata its numbers belong to; dynNode for a row of the dyn layer (the dock model)
        navFingerprint = item.navFingerprint, targetNode = item.targetNode, dynNode = item.dynNode,
        pointApprox = item.approx,      -- the compact row's p (his target.approx), not a dyn row's approximate
        -- the dock model (dock.lua): a landing, its point on board and the link between them
        facilityRole = item.facilityRole, facilityKind = item.facilityKind, dockId = item.dockId,
        boardingPointId = item.boardingPointId,
        -- the circle in which the route to a waiting point or an activation area has to end (R.EndRadius)
        waitingRadius = item.waitingRadius, activationCaptureRadius = item.activationCaptureRadius,
    }
end

-- The kinds of the catalogue a creature of the game is listed as (TargetCatalog's kinds).
local CREATURE_KINDS = { npc = true, mob = true, creature = true }

-- The search of the destination list. filterText "" lists the nearest targets. opts: { showAuto, german, R, extra,
-- limit, start, direct } (extra: rows that already are rows, each with .entry, the target its text is searched in,
-- and .distance: the boarding points of the docks, his Dock:BoardingTargets; limit: fewer rows than C.SEARCH_LIMIT;
-- start: only targets that resolve to a network point, the ones a route can start at; direct: no target is
-- resolved or dropped, his list for /vn direct, where no route leads to the point; entry: only the creatures with
-- this ID, the creature kinds of CREATURE_KINDS).
-- Returns the rows (nearest first, at most the limit, each with .distance) and info { total, limit, shown,
-- capped } (total = matches before the reachability check). Without the catalogue: {}, info with .reason.
function catalog.search(N, C, map, filterText, x, y, opts)
    opts = opts or {}
    local limit = opts.limit or C.SEARCH_LIMIT
    local info = { total = 0, limit = limit, shown = 0, capped = false }
    local nav, reason = catalog.ensure(N, C, map)
    if nav == nil then
        info.reason = reason
        return {}, info
    end
    local german = opts.german
    if german == nil then
        german = text.german()
    end
    local filter = lower((filterText or ""):match("^%s*(.-)%s*$"))
    local auto = opts.showAuto == true
    local R = opts.R or _G.WowVisionNavigationTargetResolver
    local wantedEntry = opts.entry
    local function accept(entry, zoneId)
        if wantedEntry ~= nil and (entry.entry ~= wantedEntry or not CREATURE_KINDS[entry.kind]) then
            return false
        end
        return (auto or not automaticListEntry(entry)) and matches(N, entry, filter, zoneId, german)
    end
    local n, rows, owners, d2 = C:Scan(nav.zoneSet, nav.nativeMapId, accept, x, y, nil)
    -- an entry that already is a row: the automatic waypoints nearby (his door nodes with showauto)
    if auto and x then
        N.activeMapId = map
        for _, point in ipairs(catalog.autoPoints(N, x, y)) do
            if filter == "" or point.search:find(filter, 1, true) ~= nil then
                n = n + 1
                rows[n], owners[n], d2[n] = point, false, point.distance * point.distance
            end
        end
    end
    for _, row in ipairs(opts.extra or {}) do
        if matches(N, row.entry, filter, row.zoneId, german) then
            n = n + 1
            rows[n], owners[n], d2[n] = row, false, (row.distance or 0) ^ 2
        end
    end
    info.total = n
    -- the candidates nearest first until the limit is reached; a hit that cannot be reached (checked zone) is skipped,
    -- so more candidates than the limit may be read
    local list, count, position, want = {}, 0, 0, limit * 2
    while true do
        local order = C.Nearest(d2, n, want)
        for j = position + 1, #order do
            position = j
            local i = order[j]
            local owner, row = owners[i], rows[i]
            if owner then
                local item = C:Materialize(owner, row)
                row = nil
                if auto or not automaticListEntry(item) then
                    -- a start needs its network point now; a destination may still have floors to choose or an
                    -- unchecked zone
                    local reachable = not opts.start
                    if not opts.direct and N.PointZoneLoaded(item.x, item.y) then
                        local result = catalog.resolveListed(R, C, nav, item)
                        item.layerResolution = result
                        reachable = result.endNodeId ~= nil or (not opts.start and result.bands ~= nil)
                    end
                    if reachable then
                        row = listRow(N, item, german)
                    end
                end
            end
            if row then
                count = count + 1
                list[count] = row
                row.distance = x and math.sqrt(d2[i]) or nil
                if count >= limit then
                    break
                end
            end
        end
        if count >= limit or #order >= n then
            break
        end
        want = want * 4
    end
    info.shown, info.capped = count, count >= limit and position < n
    return list, info
end

-- The row of a creature of the game (the route to the target): the nearest target of the catalogue with its ID that a
-- route can reach, within radius of the player (a farther one is another spawn); nil without one.
function catalog.creatureRow(N, C, map, creatureId, x, y, radius)
    local rows = catalog.search(N, C, map, "", x, y, { limit = 1, entry = creatureId, showAuto = false })
    local row = rows[1]
    if row == nil or row.distance == nil or row.distance > radius then
        return nil
    end
    return row
end

-- How far the catalogue's target may lie from the position another source gives for it (a quest database's spawn,
-- the game's own map pin) and still be the same one.
catalog.MATCH_RADIUS = 60

-- The catalogue's row for a target another source names (the scanner's quest NPCs and objects): match is
-- { kind, id, name }. First the same creature (an NPC's ID), else a target of the same name (either language), the
-- nearest to x, y within radius (catalog.MATCH_RADIUS) that a route can reach. Its row brings the height and the
-- resolution the bare position lacks. Nil without one.
function catalog.matchRow(N, C, map, match, x, y, radius)
    if type(match) ~= "table" or x == nil or y == nil then
        return nil
    end
    radius = radius or catalog.MATCH_RADIUS
    if match.kind == "npc" and match.id ~= nil then
        local row = catalog.creatureRow(N, C, map, match.id, x, y, radius)
        if row ~= nil then
            return row
        end
    end
    local name = type(match.name) == "string" and match.name:match("^%s*(.-)%s*$") or ""
    if name == "" then
        return nil
    end
    local wanted = lower(name)
    local rows = catalog.search(N, C, map, name, x, y, { limit = 10, showAuto = false })
    for _, row in ipairs(rows) do
        if row.distance ~= nil and row.distance <= radius
            and ((row.n ~= nil and lower(row.n) == wanted) or (row.nameEn ~= nil and lower(row.nameEn) == wanted)) then
            return row
        end
    end
    return nil
end

-- The automatic waypoints near a position (his NODE_SELECTION_RADIUS list): the network's own waypoints of the zones
-- there, nearest first, at most limit, as rows that route straight to the waypoint (nodeId). Real waypoints only
-- (no points on links), like his NodesWithin.
catalog.NODE_SELECTION_RADIUS = 60.0

-- A waypoint of the network as a list row: named by its height, routed to straight (nodeId).
local function nodeRow(N, p)
    local name = text.autoName(p.z)
    return {
        id = "wownav:node:" .. p.id, n = name, search = lower(name .. " " .. L["automatic"]),
        x = p.x, y = p.y, z = p.z, nodeId = p.id, distance = p.distance, water = p.water == true,
    }
end

function catalog.autoPoints(N, x, y, radius, limit)
    radius = radius or catalog.NODE_SELECTION_RADIUS
    local found = {}
    for _, zoneId in ipairs(N.ZonesForPoint(x, y)) do
        if N.LoadZone(zoneId) then
            for _, id in ipairs(N.NodesWithin(zoneId, x, y, radius)) do
                local nx, ny, nz = N.Position(id)
                local dx, dy = nx - x, ny - y
                found[#found + 1] = { id = id, x = nx, y = ny, z = nz, distance = math.sqrt(dx * dx + dy * dy) }
            end
        end
    end
    table.sort(found, function(a, b)
        return a.distance < b.distance
    end)
    local rows = {}
    for i = 1, math.min(#found, limit or #found) do
        rows[i] = nodeRow(N, found[i])
    end
    return rows
end

-- The entry points of the navigation window (F10), the same kind of list as the route data's: the nearest targets of
-- the catalogue that resolve to a network point here (the flight master in front of the player, a door, a portal),
-- and the network's own waypoints, nearest first, at most count (catalog.ENTRY_COUNT). With "Show Automatic
-- Waypoints" (his showauto) the waypoints mix in as far as the list reaches; without it only those within
-- catalog.ENTRY_NEAR join, and the rest of the list is targets: the nearest target can lie far away, and a waypoint
-- next to the player still gives a fine start. The player picks where the route starts; WowNav never binds the
-- position itself. While the player swims or dives, the network's nearest water point (a waypoint of a WATER area
-- with a checked exit; his swimming start takes these only) within his water exit reach (N.WATER_EXIT_RADIUS) is
-- always in the list, at its place by distance and marked water, so F10 can preselect it.
-- opts: { showAuto, swimming, german }
catalog.ENTRY_RADIUS = 300.0
catalog.ENTRY_COUNT = 50
catalog.ENTRY_NEAR = 10.0

-- The network's waypoints near a position, nearest first: { id, x, y, z, distance, water }.
local function nearNodes(N, x, y, radius)
    local found = {}
    for _, zoneId in ipairs(N.ZonesForPoint(x, y)) do
        if N.LoadZone(zoneId) then
            for _, id in ipairs(N.NodesWithin(zoneId, x, y, radius)) do
                local nx, ny, nz = N.Position(id)
                local dx, dy = nx - x, ny - y
                found[#found + 1] = { id = id, x = nx, y = ny, z = nz, distance = math.sqrt(dx * dx + dy * dy),
                    water = N.Area(id) == "WATER" and not N.NoExit(id) }
            end
        end
    end
    table.sort(found, function(a, b)
        return a.distance < b.distance
    end)
    return found
end

local function byDistance(a, b)
    return a.distance < b.distance
end

function catalog.entryPoints(N, C, map, x, y, count, opts)
    opts = opts or {}
    -- the player's zones decoded, so the targets nearby are resolved now
    local nodes = nearNodes(N, x, y, catalog.ENTRY_RADIUS)
    local rows = catalog.search(N, C, map, "", x, y, { limit = count, start = true, german = opts.german })
    local reach = opts.showAuto and math.huge or catalog.ENTRY_NEAR
    local added = 0
    for i = 1, math.min(#nodes, count) do
        if nodes[i].distance > reach then
            break
        end
        rows[#rows + 1] = nodeRow(N, nodes[i])
        added = added + 1
    end
    if added > 0 then
        table.sort(rows, byDistance)
        for i = #rows, count + 1, -1 do
            rows[i] = nil
        end
    end
    if opts.swimming then
        -- already listed (the setting is on and it is among the nearest): nothing to add
        for _, row in ipairs(rows) do
            if row.water then
                return rows
            end
        end
        for _, p in ipairs(nodes) do
            if p.distance > N.WATER_EXIT_RADIUS then
                break
            end
            if p.water then
                rows[#rows + 1] = nodeRow(N, p)
                table.sort(rows, byDistance)
                break
            end
        end
    end
    return rows
end

-- The network point a route starts at from an entry point: a waypoint's own, or a target's resolved anew (his
-- resolution without a route context; its point may be a link point, made for this route). Returns the id and its
-- height, or nil when the target has no single network point (floors to choose, none in reach).
function catalog.startNode(N, R, nav, start, map)
    if start.nodeId ~= nil then
        return start.nodeId, start.z
    end
    if nav == nil or R == nil or start.tid == nil then
        return nil
    end
    local result = R:Resolve(nav, catalog.contract(start, map), {})
    if result == nil or result.endNodeId == nil then
        return nil
    end
    local _, _, z = N.Position(result.endNodeId)
    return result.endNodeId, z
end

-- The target contract of a row for the resolver (TargetCatalog.Validate).
function catalog.contract(r, map)
    return {
        id = r.tid, kind = r.kind, nameEn = r.nameEn or r.n, nativeMapId = map, coordinateSpace = "world",
        x = r.x, y = r.y, z = r.z, zStatus = r.z == nil and "unknown" or "known", levels = r.levels,
        surface = r.surface, interactionMode = r.interactionMode, activationMode = r.activationMode,
        -- his Weg B: what the resolver binds the target to its fixed node with (TargetResolver:ResolveTargetNode)
        zoneId = r.zoneId, navFingerprint = r.navFingerprint, targetNode = r.targetNode, dynNode = r.dynNode,
        approx = r.pointApprox,
        waitingRadius = r.waitingRadius, activationCaptureRadius = r.activationCaptureRadius,
    }
end
