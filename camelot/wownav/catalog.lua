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
        nameEn = item.nameEn, zoneId = item.zoneId, surface = item.surface, resolution = item.layerResolution,
        layer = type(item.providerId) == "string" and item.providerId:find("^package_dyn_") and "dyn" or "logical",
        interactionMode = item.interactionMode, activationMode = item.activationMode, approx = item.approx,
    }
end

-- The search of the destination list. filterText "" lists the nearest targets. opts: { showAuto, german, R, extra }
-- (extra: rows that already are rows, each with .entry, the target its text is searched in, and .distance: the
-- boarding points of the docks, his Dock:BoardingTargets).
-- Returns the rows (nearest first, at most C.SEARCH_LIMIT, each with .distance) and info { total, limit, shown,
-- capped } (total = matches before the reachability check). Without the catalogue: {}, info with .reason.
function catalog.search(N, C, map, filterText, x, y, opts)
    opts = opts or {}
    local limit = C.SEARCH_LIMIT
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
    local function accept(entry, zoneId)
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
                    local reachable = true
                    if N.PointZoneLoaded(item.x, item.y) then
                        local result = catalog.resolveListed(R, C, nav, item)
                        item.layerResolution = result
                        reachable = result.endNodeId ~= nil or result.bands ~= nil
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

-- The automatic waypoints near a position (his NODE_SELECTION_RADIUS list): the network's own waypoints of the zones
-- there, nearest first, at most limit, as rows that route straight to the waypoint (nodeId). Real waypoints only
-- (no points on links), like his NodesWithin.
catalog.NODE_SELECTION_RADIUS = 60.0

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
        local p = found[i]
        local name = text.autoName(N.Bits(p.id), p.z)
        rows[i] = {
            id = "wownav:node:" .. p.id, n = name, search = lower(name .. " " .. L["automatic"]),
            x = p.x, y = p.y, z = p.z, nodeId = p.id, distance = p.distance,
        }
    end
    return rows
end

-- The target contract of a row for the resolver (TargetCatalog.Validate).
function catalog.contract(r, map)
    return {
        id = r.tid, kind = r.kind, nameEn = r.nameEn or r.n, nativeMapId = map, coordinateSpace = "world",
        x = r.x, y = r.y, z = r.z, zStatus = r.z == nil and "unknown" or "known", levels = r.levels,
        surface = r.surface, interactionMode = r.interactionMode, activationMode = r.activationMode,
    }
end
