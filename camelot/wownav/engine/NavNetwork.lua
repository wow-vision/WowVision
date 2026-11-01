-- WowNav engine by Broesel33 (github.com/Broesel33/WoW_NavigationData, DemoAddon/WowVisionNavigation/NavNetwork.lua at
-- 5b8b5f2), carried in WowVision with his permission. Changes for WowVision: see camelot/wownav/engine/README.md.

-- NavNetwork (schema 7, concept chapters 7, 7a and 8): loader/decoder, continent graph, attachment cells and the
-- A* search. Replaces the graph, funnel, guidance and zone-by-zone world travel of the old core.
--
-- Data format: tools/wegenetz/schema7_codec.py (same description). A zone is held in memory as WVN7[zoneId]
-- (header plus the fields x,y,z,c,s,lo,lt,lf,e,cx,cy,cz,ch,cc,cl,an,ar,aq). It is decoded only when a route needs it
-- (start zone, target zone, zone reached over a seam).
--
-- Node IDs are global: zoneId * 10^7 + local index. Virtual points (link-point attachments, start and target
-- bindings) carry IDs from VIRT_BASE on and are discarded after the route.
WowVisionNavigationNavNetwork = WowVisionNavigationNavNetwork or {}
local N = WowVisionNavigationNavNetwork

local VIRT_BASE = 1000000000000
local ZONE_BASE = 10000000
N.VIRT_BASE, N.ZONE_BASE = VIRT_BASE, ZONE_BASE

local floor, sqrt, abs, min, max = math.floor, math.sqrt, math.abs, math.min, math.max
local sbyte = string.byte

-- Base codes (chapter 5)
local BIT_BRANCH = 512
local BIT_EXIT = 8
local BIT_GATEWAY = 64
N.BITS = { CORNER = 1, GATE = 2, ROAD = 4, EXIT = 8, LAYER = 16, ACTION = 32,
    GATEWAY = 64, TARGET = 128, COVERAGE = 256, BRANCH = 512 }
N.AREAS = { [0] = "OPEN", [1] = "FINE", [2] = "WATER" }

-- Link flags (K6): road 1, water exit 2, fine 4, swimming 8
-- Costs (chapter 4.4)
N.FINE_FACTOR = 1.5
-- 4.56 (user decision 2026-10-25, variant "neutral"): every land link that the route walks costs (length + HOP_COST) x LinkFactor, in both passes: the
-- hop cost counts the waypoint the player has to steer to, and the factors of the pass (the road factor 1/r in pass (b), the fine factor) scale it like
-- the length. So the comfort level stays the one knob between roads and cross-country (comfort 0: no road preference, the hop cost is the same on every
-- link). Partial links to seam points, seams and actions carry none. The pass choice (b against a) still compares geometric lengths. Value 15 yd
-- (measured on the Elwynn - Westfall routes: chapter 14).
N.HOP_COST = 15
N.SWIM_FACTOR = 1.5     -- the build; at run time a swimming link costs SWIM_FACTOR x (1 + p/100) x length (4.49, comfort p)
-- Comfort level (4.34, /vn comfort <p>): p percent, 0 to 300, default 60 (user decision 2026-10-25; 50 before). r = 1 + p/100; the road factor of
-- pass (b) is 1/r and (b) wins when its length is at most r times that of (a). p = 0: no pass (b).
N.COMFORT_DEFAULT, N.COMFORT_MAX = 60, 300
function N.SetComfort(percent)
    if type(percent) ~= "number" or percent ~= percent or percent < 0 or percent > N.COMFORT_MAX then return false end
    local r = 1 + percent / 100
    N.comfort, N.ROAD_MAX_RATIO, N.ROAD_FACTOR = percent, r, 1 / r
    N.SWIM_COMFORT = r      -- 4.49: swimming (links, partial links, water seams) costs r times more than the build says
    return true
end
N.SetComfort(N.COMFORT_DEFAULT)

-- Attachment parameters (chapter 7)
N.HEIGHT_TOLERANCE = 3.0     -- yd: height band of the cell +- 3 yd
N.START_RADIUS = 3.0         -- yd: nearest cell when the position is in none
N.TARGET_RADIUS = 30.0       -- yd: approach to the nearest cell for a target outside every cell
local FIELDS = 4

-- ---------------------------------------------------------------------------
-- Character alphabet (K3): printable ASCII 0x21..0x7E without " and \
-- ---------------------------------------------------------------------------
local LOOK = {}
do
    local index = 0
    for byte = 33, 126 do
        if byte ~= 34 and byte ~= 92 then LOOK[byte] = index; index = index + 1 end
    end
end
local BASE = 92

local function Chars(text)
    local n, result, i = #text, {}, 1
    while i <= n do
        local j = min(n, i + 3999)
        local bytes = { sbyte(text, i, j) }
        for k = 1, #bytes do
            local value = LOOK[bytes[k]]
            if value == nil then error("invalid character in schema 7 field") end
            result[i + k - 1] = value
        end
        i = j + 1
    end
    return result
end

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
N.zones = {}          -- [zoneId] = decoded zone of the active zone state
N.decoded = {}        -- [zoneId] = decoded zone, kept until N.UnloadZone or N.KeepZones drops it: Reset only detaches it
N.generation = 0      -- counts the changes of N.zones (a decoded zone can change what a list may check)
N.activeMapId = nil   -- native map of the active continent (set by the core): zones of other maps never contain a point
N.index = {}          -- [zoneId] = index entry (name, maps, boxes, seams)
N.virt = {}           -- [virtual id] = point
N.virtNext = VIRT_BASE
N.continents = {}     -- [name] = { mapId = id, zones = { [zoneId] = entry } }
N.seamProblems = {}   -- seam records that were not used (data errors)
N.memory = {}         -- G21: kB after login and after decoding each zone
N.linkpoints = {}
N.actionCount = 0     -- loaded action edges: the straight-line heuristic is invalid once cheap teleports exist
N.onZoneLoaded = nil  -- optional callback(zone) after a zone was decoded (the core registers the action module)
N.onZoneUnloaded = nil -- optional callback(zone) after N.UnloadZone dropped a zone
N.ActionAllowed = nil -- optional function(action) -> bool; nil allows every action

-- Concept 4.54 (user decision 19.10.2026): routes are always on foot. Walking into a portal or an instance entrance and riding a lift
-- are part of the way; boarding a vehicle (tram, ship, zeppelin) is not: the player takes it himself, a route never contains it.
function N.WalkingAction(action)
    local mode = type(action.activation) == "table" and action.activation.mode or nil
    return mode ~= "board" or action.kind == "lift"
end

local function Memory() return collectgarbage("count") end

function N.Reset()
    N.zones = {}
    N.generation = N.generation + 1
    N.activeMapId = nil
    N.seamProblems = {}
    N.virt = {}
    N.virtNext = VIRT_BASE
    N.linkpoints = {}
    N.actionCount = 0
end

function N.DiscardVirtual()
    N.virt = {}
    N.virtNext = VIRT_BASE
    N.linkpoints = {}
end

-- Keeps only the listed virtual IDs (lists or single IDs), everything else is discarded.
function N.KeepVirtual(...)
    local keep = {}
    for i = 1, select("#", ...) do
        local item = select(i, ...)
        if type(item) == "table" then
            for _, id in ipairs(item) do if id >= VIRT_BASE then keep[id] = N.virt[id] end end
        elseif type(item) == "number" and item >= VIRT_BASE then
            keep[item] = N.virt[item]
        end
    end
    N.virt = keep
    N.linkpoints = {}
    for id, point in pairs(keep) do
        if point.type == "linkpoint" then
            N.linkpoints[point.zone.id .. ":" .. point.link .. ":" .. point.t] = id
        end
    end
end

-- ---------------------------------------------------------------------------
-- Index (maps/<continent>/index.lua) and raw data
-- ---------------------------------------------------------------------------
function N.LoadIndex(source)
    source = source or _G.WVN7Index
    N.continents = {}
    N.index = {}
    if type(source) ~= "table" then return false end
    for name, continent in pairs(source) do
        local entry = { name = name, mapId = continent.mapId, zones = {} }
        for id, zone in pairs(continent.zones or {}) do
            zone.zoneId = zone.zoneId or id
            zone.continent = name
            zone.mapId = continent.mapId
            entry.zones[id] = zone
            N.index[id] = zone
        end
        N.continents[name] = entry
    end
    return true
end

-- Packed zone files (tools/pack_runtime_data.py): WVN7Src / WVN7LogicalSrc / WVN7DynSrc[zoneId] hold the exporter's
-- source as text; it is compiled the first time the zone is needed and builds WVN7 / WVN7Logical / WVN7Dyn[zoneId] as an
-- unpacked file does at login. Unpacked files keep working unchanged.
local compile = loadstring or load

local function Unpacked(globalName, sourceName, zoneId)
    local tables = _G[globalName]
    if type(tables) == "table" and type(tables[zoneId]) == "table" then return tables[zoneId] end
    local sources = _G[sourceName]
    local source = type(sources) == "table" and sources[zoneId] or nil
    if type(source) ~= "string" then return nil end
    local chunk, err = compile(source, "=" .. sourceName .. "[" .. tostring(zoneId) .. "]")
    if not chunk then return nil, err end
    local ok, failure = pcall(chunk)
    if not ok then return nil, failure end
    tables = _G[globalName]
    return type(tables) == "table" and tables[zoneId] or nil
end

local function IsPacked(sourceName, zoneId)
    local sources = _G[sourceName]
    return type(sources) == "table" and type(sources[zoneId]) == "string"
end

function N.ZoneAvailable(zoneId)
    return (type(_G.WVN7) == "table" and type(_G.WVN7[zoneId]) == "table") or IsPacked("WVN7Src", zoneId)
end

-- What a decoded zone was built from: the packed source text, else the raw tables of an unpacked file. A decoded copy in
-- N.decoded is reused only while this is unchanged.
local function ZoneSource(zoneId)
    if IsPacked("WVN7Src", zoneId) then return _G.WVN7Src[zoneId] end
    return type(_G.WVN7) == "table" and type(_G.WVN7[zoneId]) == "table" and _G.WVN7[zoneId] or nil
end

-- Catalog files of a zone (tables), compiled from the packed source on first use. Returns the table or nil, reason.
function N.LogicalTargets(zoneId)
    return Unpacked("WVN7Logical", "WVN7LogicalSrc", zoneId)
end

function N.DynTargets(zoneId)
    return Unpacked("WVN7Dyn", "WVN7DynSrc", zoneId)
end

-- Lets a packed catalog file go again (it is compiled anew when needed); an unpacked one stays.
function N.DropTargets(zoneId)
    if IsPacked("WVN7LogicalSrc", zoneId) and type(_G.WVN7Logical) == "table" then _G.WVN7Logical[zoneId] = nil end
    if IsPacked("WVN7DynSrc", zoneId) and type(_G.WVN7Dyn) == "table" then _G.WVN7Dyn[zoneId] = nil end
end

-- ---------------------------------------------------------------------------
-- Decoder
-- ---------------------------------------------------------------------------
local function PrefixSum(values, factor)
    local sum, result = 0, {}
    for i = 1, #values do
        sum = sum + values[i]
        result[i] = sum * factor
    end
    return result
end

local function CellKey(gx, gy)
    return (gx + 50000) * 100000 + (gy + 50000)
end

local CELL_SIZES = { [0] = 16, [1] = 8, [2] = 32 }

local function Decode(raw)
    local n = raw.nodeCount
    local zone = { id = raw.zoneId, base = raw.zoneId * ZONE_BASE, mapId = raw.mapId, n = n,
        fingerprint = raw.fingerprint, raw = raw }
    zone.x, zone.y, zone.z = PrefixSum(raw.x, 0.1), PrefixSum(raw.y, 0.1), PrefixSum(raw.z, 0.1)
    if #zone.x ~= n or #zone.y ~= n or #zone.z ~= n then error("coordinate fields have the wrong length") end
    local dictionary = {}
    for i, code in ipairs(raw.codes) do
        dictionary[i - 1] = {
            bits = code % 1024,
            area = floor(code / 1024) % 4,
            radius = (raw.radii[floor(code / 4096) % 256 + 1] or 0) * 0.1,
            noExit = floor(code / 1048576) % 2 == 1,     -- 4.27: water component without a checked exit
        }
    end
    local codes = Chars(raw.c)
    if #codes ~= n then error("code field has the wrong length") end
    zone.bits, zone.area, zone.radius, zone.noExit = {}, {}, {}, {}
    for i = 1, n do
        local entry = dictionary[codes[i]]
        if not entry then error("code outside the dictionary") end
        zone.bits[i], zone.area[i], zone.radius[i], zone.noExit[i] = entry.bits, entry.area, entry.radius, entry.noExit
    end
    zone.layer = Chars(raw.s)
    -- Links (CSR, K6/K7)
    local counts, offsets, flags = Chars(raw.lo), raw.lt, Chars(raw.lf)
    local linkCount = raw.linkCount
    if #counts ~= n or #offsets ~= linkCount or #flags ~= linkCount then error("link fields have the wrong length") end
    zone.lu, zone.lv, zone.lflag, zone.ldir, zone.llen = {}, {}, {}, {}, {}
    zone.adj = {}
    for i = 1, n do zone.adj[i] = {} end
    local k = 0
    for u = 0, n - 1 do
        for _ = 1, counts[u + 1] do
            k = k + 1
            local v = u + offsets[k]
            local code = flags[k]
            local direction, flag = floor(code / 16), code % 16
            if v <= u or v >= n or direction > 2 then error("invalid link") end
            zone.lu[k], zone.lv[k], zone.lflag[k], zone.ldir[k] = u, v, flag, direction
            local dx, dy, dz = zone.x[v + 1] - zone.x[u + 1], zone.y[v + 1] - zone.y[u + 1],
                zone.z[v + 1] - zone.z[u + 1]
            zone.llen[k] = sqrt(dx * dx + dy * dy + dz * dz)
            if direction == 0 or direction == 1 then       -- u -> v
                local a = zone.adj[u + 1]
                a[#a + 1] = v; a[#a + 1] = k
            end
            if direction == 0 or direction == 2 then       -- v -> u
                local a = zone.adj[v + 1]
                a[#a + 1] = u; a[#a + 1] = k
            end
        end
    end
    if k ~= linkCount then error("link count does not match the header") end
    -- Extras (K9): gates (half widths), branch pairs, actions
    zone.gate, zone.branch, zone.actions = {}, {}, {}
    local extras = raw.e or {}
    if extras.gates then
        local id = 0
        for i = 1, #extras.gates, 2 do
            id = id + extras.gates[i]
            zone.gate[id] = extras.gates[i + 1] * 0.1
        end
    end
    if extras.branches then
        local id = 0
        for i = 1, #extras.branches, 3 do
            id = id + extras.branches[i]
            zone.branch[id] = { id + extras.branches[i + 1], id + extras.branches[i + 2] }
        end
    end
    -- Seams (S12): the seam IDs that end at a GATEWAY waypoint (the seam itself is in the continent index)
    zone.seamIds = {}
    if extras.seams then
        local id = 0
        for i = 1, #extras.seams, 2 do
            id = id + extras.seams[i]
            local list = zone.seamIds[id] or {}
            list[#list + 1] = extras.seams[i + 1]
            zone.seamIds[id] = list
        end
    end
    -- Interaction proofs (transit facilities at AKTION waypoints): the certificate records the target modules compare
    -- a facility target with (see TargetCatalog:CertifiedInteraction)
    zone.captures = extras.captures or {}
    -- Actions (B3 to B6): directed AKTION links with their data record (same fields as the old action edges);
    -- from is a zone-local node, to a global node ID
    zone.actionsFrom = {}
    for _, record in ipairs(extras.actions or {}) do
        -- (N.WalkingAction decides at route time whether an action may be part of a route)
        local action = {}
        for key, value in pairs(record) do action[key] = value end
        action.fromNode = zone.base + record.from
        action.toNode = record.to
        action.toZoneId = record.toZone
        action.toNativeMap = record.toMapId
        action.fromNativeMap = raw.mapId
        local list = zone.actionsFrom[record.from] or {}
        list[#list + 1] = action
        zone.actionsFrom[record.from] = list
        zone.actions[#zone.actions + 1] = action
    end
    -- Z2: the ranges of the hostile outposts (gap, length - 1 pairs per faction, schema7_codec.py); the table of the player's opponents is built on demand
    zone.factionRanges, zone.hasFactions = {}, false
    for _, faction in ipairs({ "horde", "alliance" }) do
        local list = raw.factions and raw.factions[faction]
        if list then
            local ranges, expected = {}, 0
            for i = 1, #list, 2 do
                local first = expected + list[i]
                local last = first + list[i + 1]
                if last >= n then error("faction range outside the network") end
                ranges[#ranges + 1] = { first, last }
                expected = last + 1
            end
            zone.factionRanges[faction], zone.hasFactions = ranges, true
        end
    end
    zone.seam = {}
    -- Attachment cells (K10)
    local cx, cy, cz, ch = raw.cx, raw.cy, raw.cz, raw.ch
    local classes, layers, attachmentCounts = Chars(raw.cc), Chars(raw.cl), Chars(raw.an)
    local references, masks = raw.ar, Chars(raw.aq)
    local m = raw.cellCount
    if #cx ~= m or #cy ~= m or #cz ~= m or #ch ~= m or #classes ~= m or #layers ~= m
        or #attachmentCounts ~= m or #masks ~= 3 * #references then
        error("cell fields have the wrong length")
    end
    zone.cells = m
    zone.cellX, zone.cellY, zone.cellSize, zone.cellKind = {}, {}, {}, {}
    zone.cellZMin, zone.cellZMax, zone.cellLayer, zone.cellStart, zone.cellCount = {}, {}, {}, {}, {}
    zone.attLink = {}     -- attachment: link index or nil
    zone.attNode = {}     -- attachment: local node (node attachment)
    zone.attT = {}        -- attachment: link-point fraction 1..255
    zone.attMask = {}     -- attachment: 16-bit field mask
    zone.cellMap = { {}, {}, {} }
    local ox, oy, mz, previous, a = 0, 0, 0, 0, 0
    for i = 1, m do
        ox, oy, mz = ox + cx[i], oy + cy[i], mz + cz[i]
        local kind = classes[i]
        local size = CELL_SIZES[kind]
        if not size then error("invalid cell class") end
        zone.cellX[i], zone.cellY[i], zone.cellSize[i], zone.cellKind[i] = ox * 8, oy * 8, size, kind
        zone.cellZMin[i], zone.cellZMax[i] = (mz - ch[i]) * 0.1, (mz + ch[i]) * 0.1
        zone.cellLayer[i] = layers[i]
        zone.cellStart[i], zone.cellCount[i] = a + 1, attachmentCounts[i]
        for _ = 1, attachmentCounts[i] do
            a = a + 1
            previous = previous + references[a]
            if previous >= 0 then
                if previous >= n then error("cell attachment outside the network") end
                zone.attNode[a] = previous
            else
                local encoded = -previous
                local link, t = floor(encoded / 256), encoded % 256
                if t < 1 or link >= linkCount then error("invalid link-point attachment") end
                zone.attLink[a], zone.attT[a] = link + 1, t
            end
            zone.attMask[a] = (masks[3 * a - 2] * BASE + masks[3 * a - 1]) * BASE + masks[3 * a]
        end
        if attachmentCounts[i] > 0 then
            local key = CellKey(floor((ox * 8) / size + 0.5), floor((oy * 8) / size + 0.5))
            local map = zone.cellMap[kind + 1]
            local list = map[key]
            if not list then list = {}; map[key] = list end
            list[#list + 1] = i
        end
    end
    if a ~= #references then error("attachment count does not match the references") end
    return zone
end

-- A seam record of the index ends at a GATEWAY waypoint of this zone whose seam IDs (extras) contain the record's ID.
-- 4.37 (one-sided seam): an end can also reference an existing waypoint (aref/bref = "node": no GATEWAY code, no seam
-- ID) or a link point (aref/bref = "link": link az/al/at, bz/bl/bt, link index 0-based, t in 1/256). Anything else is a
-- data error: the end is not used and the problem is listed in N.seamProblems (fail closed).
local function SeamEndOf(seam, side)
    local ref = seam[side .. "ref"]
    if ref == "link" then
        return { zoneId = seam[side .. "z"], link = seam[side .. "l"], t = seam[side .. "t"], ref = ref, pos = seam[side .. "p"] }
    end
    local gid = seam[side]
    return { zoneId = gid and floor(gid / ZONE_BASE) or nil, gid = gid, ref = ref, pos = seam[side .. "p"] }
end

-- Zones that share a seam with the zone (from the continent index, no decoding needed), sorted.
function N.NeighbourZones(zoneId)
    local found = {}
    for _, entry in pairs(N.index) do
        for _, seam in ipairs(type(entry.seams) == "table" and entry.seams or {}) do
            local a, b = SeamEndOf(seam, "a").zoneId, SeamEndOf(seam, "b").zoneId
            if a == zoneId and b and b ~= zoneId then found[b] = true end
            if b == zoneId and a and a ~= zoneId then found[a] = true end
        end
    end
    local list = {}
    for id in pairs(found) do list[#list + 1] = id end
    table.sort(list)
    return list
end

local function SeamEndProblem(zone, seam, e)
    if e.ref == "link" then
        local k = type(e.link) == "number" and e.link + 1 or nil
        if not k or not zone.lu[k] then return "link point: the link does not exist" end
        if type(e.t) ~= "number" or e.t < 1 or e.t > 255 or e.t ~= floor(e.t) then return "link point: t outside 1 to 255" end
        if e.pos then
            local u, v, f = zone.lu[k] + 1, zone.lv[k] + 1, e.t / 256
            local x, y, z = zone.x[u] + (zone.x[v] - zone.x[u]) * f, zone.y[u] + (zone.y[v] - zone.y[u]) * f,
                zone.z[u] + (zone.z[v] - zone.z[u]) * f
            local d = sqrt((x - e.pos[1]) ^ 2 + (y - e.pos[2]) ^ 2 + (z - e.pos[3]) ^ 2)
            if d > zone.llen[k] / 256 + 0.1 + 1e-6 then return "link point: the position differs from the seam position" end
        end
        return nil
    end
    local localId = e.gid - zone.base
    if localId < 0 or localId >= zone.n then return "outside the zone" end
    if e.ref == "node" then
        if e.pos then
            local i = localId + 1
            if max(abs(zone.x[i] - e.pos[1]), abs(zone.y[i] - e.pos[2]), abs(zone.z[i] - e.pos[3])) > 0.06 + 1e-6 then
                return "waypoint: the position differs from the seam position"
            end
        end
        return nil
    end
    if floor((zone.bits[localId + 1] or 0) / BIT_GATEWAY) % 2 ~= 1 then return "no GATEWAY waypoint" end
    if seam.id ~= nil then
        local ids, found = zone.seamIds[localId], false
        for _, id in ipairs(ids or {}) do found = found or id == seam.id end
        if not found then return "seam ID not in the waypoint extras" end
    end
    return nil
end

local function Seams(zone)
    zone.seam = {}
    zone.seamLinkEnds = {}   -- [local waypoint] = { {seamId, k, t}, ... } for the end waypoints of links that carry a seam point
    zone.seamLinkOk = {}     -- [seam ID] = { k, t, partner = global waypoint across the seam, cost }
    zone.seamBad = {}        -- [seam ID] = true when this zone's end of the seam failed the check (the seam is not crossed)
    local seen = {}
    for _, entry in pairs(N.index) do
        if type(entry.seams) == "table" then
            for _, seam in ipairs(entry.seams) do
                local ea, eb = SeamEndOf(seam, "a"), SeamEndOf(seam, "b")
                local key = seam.id ~= nil and ("id:" .. tostring(seam.id))
                    or (min(seam.a or 0, seam.b or 0) .. ":" .. max(seam.a or 0, seam.b or 0))
                if not seen[key] then
                    seen[key] = true
                    for _, pair in ipairs({ { ea, eb }, { eb, ea } }) do
                        local mine, other = pair[1], pair[2]
                        if mine.zoneId == zone.id then
                            local problem = SeamEndProblem(zone, seam, mine)
                            if not problem and mine.ref == "link" and other.ref == "link" then
                                problem = "both ends are link points"
                            end
                            if not problem and mine.ref == "link" and seam.id == nil then problem = "link point without a seam ID" end
                            if problem then
                                if seam.id ~= nil then zone.seamBad[seam.id] = true end
                                local at = mine.gid and zone.base + (mine.gid - zone.base) or ("link " .. tostring(mine.link))
                                N.seamProblems[#N.seamProblems + 1] = string.format("seam %s, %s: %s", tostring(seam.id), tostring(at), problem)
                            elseif mine.ref == "link" then
                                local k = mine.link + 1
                                zone.seamLinkOk[seam.id] = { k = k, t = mine.t, partner = other.gid, cost = seam.cost, partnerZone = other.zoneId, water = seam.water }
                                for _, localEnd in ipairs({ zone.lu[k], zone.lv[k] }) do
                                    local list = zone.seamLinkEnds[localEnd] or {}
                                    list[#list + 1] = { seamId = seam.id, k = k, t = mine.t }
                                    zone.seamLinkEnds[localEnd] = list
                                end
                            else
                                local localId = mine.gid - zone.base
                                zone.seam[localId] = zone.seam[localId] or {}
                                if other.ref == "link" then
                                    table.insert(zone.seam[localId], { false, seam.cost, link = true, zoneId = other.zoneId, seamId = seam.id, water = seam.water })
                                else
                                    table.insert(zone.seam[localId], { other.gid, seam.cost, seamId = seam.id, water = seam.water })
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


-- Decodes a zone on demand. Returns the zone, or nil and a reason.
function N.LoadZone(zoneId)
    local existing = N.zones[zoneId]
    if existing then return existing end
    local before = Memory()
    local source = ZoneSource(zoneId)
    if source == nil then return nil, "zone data not loaded" end
    local zone = N.decoded[zoneId]
    if not zone or zone.source ~= source then     -- the decoded copy belongs to exactly this source
        local raw, why = Unpacked("WVN7", "WVN7Src", zoneId)
        if type(raw) ~= "table" then return nil, why and tostring(why) or "zone data not loaded" end
        local ok, decoded = pcall(Decode, raw)
        if not ok then return nil, tostring(decoded) end
        if type(source) == "string" then
            -- the text stays; the raw tables are rebuilt from it if the zone is decoded again after N.UnloadZone
            _G.WVN7[zoneId] = nil
            decoded.raw = nil
        end
        decoded.source = source
        zone, N.decoded[zoneId] = decoded, decoded
    end
    N.zones[zoneId] = zone
    N.generation = N.generation + 1
    N.actionCount = N.actionCount + #zone.actions
    for _, other in pairs(N.zones) do Seams(other) end
    if N.onZoneLoaded then N.onZoneLoaded(zone) end
    N.memory.zones = N.memory.zones or {}
    N.memory.zones[zoneId] = { before = before, after = Memory() }
    return zone
end

-- Drops a decoded zone, attached or only kept in N.decoded (it is decoded again on demand, from the packed source if there
-- is one). Virtual points on its links go with it. The other zones need no update: their seams point at waypoint IDs, and
-- the search decodes a zone behind a seam when it gets there. Never call this while a route job of that zone is running.
-- N.onZoneUnloaded(zone) (optional) lets the core drop what it derived from the zone (resolutions, lists).
function N.UnloadZone(zoneId)
    local zone = N.zones[zoneId] or N.decoded[zoneId]
    if not zone then return false end
    N.decoded[zoneId] = nil
    if N.zones[zoneId] then
        N.zones[zoneId] = nil
        N.generation = N.generation + 1
        N.actionCount = N.actionCount - #zone.actions
        for id, point in pairs(N.virt) do
            if point.zone == zone then N.virt[id] = nil end
        end
        for key, id in pairs(N.linkpoints) do
            if not N.virt[id] then N.linkpoints[key] = nil end
        end
    end
    if N.memory.zones then N.memory.zones[zoneId] = nil end
    if N.onZoneUnloaded then N.onZoneUnloaded(zone) end
    return true
end

-- Keeps the decoded zones in the set (zoneId -> true), attached or not, and drops all others. Returns the number dropped.
function N.KeepZones(keep)
    local drop, seen = {}, {}
    for _, zones in ipairs({ N.zones, N.decoded }) do
        for id in pairs(zones) do
            if not keep[id] and not seen[id] then seen[id] = true; drop[#drop + 1] = id end
        end
    end
    table.sort(drop)
    for _, id in ipairs(drop) do N.UnloadZone(id) end
    return #drop
end

-- ---------------------------------------------------------------------------
-- Point access
-- ---------------------------------------------------------------------------
local function ZoneOf(id)
    return N.zones[floor(id / ZONE_BASE)]
end

function N.Exists(id)
    if id == nil then return false end
    if id >= VIRT_BASE then return N.virt[id] ~= nil end
    local zone = ZoneOf(id)
    if not zone then return false end
    local localId = id - zone.base
    return localId >= 0 and localId < zone.n
end

function N.Position(id)
    if id >= VIRT_BASE then
        local v = N.virt[id]
        if not v then return 0, 0, 0 end
        return v.x, v.y, v.z
    end
    local zone = ZoneOf(id)
    if not zone then return 0, 0, 0 end
    local i = id - zone.base + 1
    return zone.x[i], zone.y[i], zone.z[i]
end

-- Base-code bit field; virtual points carry no code.
function N.Bits(id)
    if id == nil or id >= VIRT_BASE then return 0 end
    local zone = ZoneOf(id)
    return zone and zone.bits[id - zone.base + 1] or 0
end

function N.Area(id)
    if id == nil or id >= VIRT_BASE then return nil end
    local zone = ZoneOf(id)
    local value = zone and zone.area[id - zone.base + 1]
    return value and N.AREAS[value] or nil
end

function N.Layer(id)
    if id == nil or id >= VIRT_BASE then return nil end
    local zone = ZoneOf(id)
    return zone and zone.layer[id - zone.base + 1] or nil
end

-- Arrival radius in yd. A link point takes the smaller radius of its two ends (derived from the data).
-- Seam IDs that end at a waypoint (list) or nil.
function N.SeamIds(id)
    local zone = id and id < VIRT_BASE and ZoneOf(id)
    local list = zone and zone.seamIds[id - zone.base]
    if not list then return nil end
    local copy = {}
    for i, value in ipairs(list) do copy[i] = value end
    return copy
end

-- True for a water waypoint of a water component without a checked exit (4.27).
function N.NoExit(id)
    if id == nil or id >= VIRT_BASE then return false end
    local zone = ZoneOf(id)
    return zone ~= nil and zone.noExit[id - zone.base + 1] == true
end

function N.Radius(id)
    if id == nil then return nil end
    if id >= VIRT_BASE then
        local v = N.virt[id]
        return v and v.radius or nil
    end
    local zone = ZoneOf(id)
    return zone and zone.radius[id - zone.base + 1] or nil
end

-- Half width of the gate in yd or nil (not a GATE waypoint).
function N.GateHalfWidth(id)
    if id == nil or id >= VIRT_BASE then return nil end
    local zone = ZoneOf(id)
    return zone and zone.gate[id - zone.base] or nil
end

-- Global IDs of the neighbours that belong to the two halves of the same split link (code BRANCH).
function N.BranchPair(id)
    if id == nil or id >= VIRT_BASE then return nil end
    local zone = ZoneOf(id)
    local pair = zone and zone.branch[id - zone.base]
    if not pair then return nil end
    return zone.base + pair[1], zone.base + pair[2]
end

-- Neighbours for announcements/diagnostics: { {id, linkIndex, flags}, ... } (allowed direction only)
function N.Neighbors(id)
    local zone = ZoneOf(id)
    if not zone then return {} end
    local adj, result = zone.adj[id - zone.base + 1], {}
    for j = 1, #adj, 2 do
        result[#result + 1] = { zone.base + adj[j], adj[j + 1], zone.lflag[adj[j + 1]] }
    end
    return result
end

function N.NodeCount()
    local sum = 0
    for _, zone in pairs(N.zones) do sum = sum + zone.n end
    return sum
end

-- Waypoint IDs of a zone within a radius (linear search, lists/diagnostics only)
function N.NodesWithin(zoneId, x, y, radius)
    local zone = N.zones[zoneId]
    local result = {}
    if not zone then return result end
    local r2 = radius * radius
    for i = 1, zone.n do
        local dx, dy = zone.x[i] - x, zone.y[i] - y
        if dx * dx + dy * dy <= r2 then result[#result + 1] = zone.base + i - 1 end
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Virtual points
-- ---------------------------------------------------------------------------
local function NewVirtual(data)
    N.virtNext = N.virtNext + 1
    N.virt[N.virtNext] = data
    return N.virtNext
end
N.NewVirtual = NewVirtual

-- Link-point attachment (K10): point on link k (1-based) at t/256 from u to v.
function N.LinkpointNode(zone, k, t)
    local key = zone.id .. ":" .. k .. ":" .. t
    local existing = N.linkpoints[key]
    if existing and N.virt[existing] then return existing end
    local u, v = zone.lu[k] + 1, zone.lv[k] + 1
    local f = t / 256
    local id = NewVirtual({
        type = "linkpoint", zone = zone, link = k, t = t, radius = min(zone.radius[u], zone.radius[v]),
        water = zone.lflag[k] >= 8,
        x = zone.x[u] + (zone.x[v] - zone.x[u]) * f,
        y = zone.y[u] + (zone.y[v] - zone.y[u]) * f,
        z = zone.z[u] + (zone.z[v] - zone.z[u]) * f,
    })
    N.linkpoints[key] = id
    return id
end

local function LinkpointPosition(zone, k, t)
    local u, v = zone.lu[k] + 1, zone.lv[k] + 1
    local f = t / 256
    return zone.x[u] + (zone.x[v] - zone.x[u]) * f, zone.y[u] + (zone.y[v] - zone.y[u]) * f,
        zone.z[u] + (zone.z[v] - zone.z[u]) * f
end

function N.AttachmentPosition(zone, a)
    if zone.attLink[a] then return LinkpointPosition(zone, zone.attLink[a], zone.attT[a]) end
    local i = zone.attNode[a] + 1
    return zone.x[i], zone.y[i], zone.z[i]
end

-- ---------------------------------------------------------------------------
-- Cells and attachment choice
-- ---------------------------------------------------------------------------
local POWER = {}
for i = 0, 16 do POWER[i] = 2 ^ i end

local function BitSet(mask, bit)
    return floor(mask / POWER[bit]) % 2 == 1
end

local function Distance3(ax, ay, az, bx, by, bz)
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return sqrt(dx * dx + dy * dy + dz * dz)
end

-- Zones that can contain a point (index boxes); they are loaded on demand. The world boxes of different native maps overlap
-- (a continent and an island), so only zones of the active native map count.
function N.ZonesForPoint(x, y)
    local candidates = {}
    for id, entry in pairs(N.index) do
        local sameMap = N.activeMapId == nil or entry.nativeMapId == nil or entry.nativeMapId == N.activeMapId
        for _, box in pairs(sameMap and entry.worldBoxes or {}) do
            if x >= box.xmin and x <= box.xmax and y >= box.ymin and y <= box.ymax then
                candidates[#candidates + 1] = id
                break
            end
        end
    end
    table.sort(candidates)
    return candidates
end

local function RectDistance(zone, i, x, y)
    local size = zone.cellSize[i]
    local x0, y0 = zone.cellX[i], zone.cellY[i]
    local dx = max(x0 - x, 0, x - (x0 + size))
    local dy = max(y0 - y, 0, y - (y0 + size))
    return sqrt(dx * dx + dy * dy)
end

local function FitsHeight(zone, i, z)
    if z == nil then return true end
    return zone.cellZMin[i] - N.HEIGHT_TOLERANCE <= z and z <= zone.cellZMax[i] + N.HEIGHT_TOLERANCE
end

local function CellCandidates(zone, kind, x, y, z)
    local size = CELL_SIZES[kind]
    local list = zone.cellMap[kind + 1][CellKey(floor(x / size), floor(y / size))]
    local result = {}
    for _, i in ipairs(list or {}) do
        if FitsHeight(zone, i, z) then result[#result + 1] = i end
    end
    return result
end

-- Looks up the cell for (x, y, z). z == nil means height unknown. Swimming: 32-yd water cells only.
--   opts.swimming, opts.radius (default START_RADIUS), opts.preferred (set of node IDs of the route state),
--   opts.candidates (output on "ambiguous")
-- Returns { zone, cell, distance, kind } | nil, reason ("ambiguous" | "no_attachment")
function N.FindCell(x, y, z, opts)
    opts = opts or {}
    local zones = opts.zones
    if not zones then
        zones = {}
        for _, id in ipairs(N.ZonesForPoint(x, y)) do
            local zone = N.LoadZone(id)
            if zone then zones[#zones + 1] = zone end
        end
        if #zones == 0 then
            for _, zone in pairs(N.zones) do zones[#zones + 1] = zone end
        end
    end
    local order = opts.swimming and { 2 } or { 1, 0 }
    local hits = {}
    for _, kind in ipairs(order) do
        for _, zone in ipairs(zones) do
            for _, i in ipairs(CellCandidates(zone, kind, x, y, z)) do
                hits[#hits + 1] = { zone = zone, cell = i, distance = 0, kind = kind }
            end
        end
        if #hits > 0 then break end
    end
    if #hits > 0 then
        if #hits == 1 then return hits[1] end
        -- height known: nearest middle. Height unknown: the route state decides, otherwise ambiguous.
        if z ~= nil then
            local best, bestDistance
            for _, hit in ipairs(hits) do
                local middle = (hit.zone.cellZMin[hit.cell] + hit.zone.cellZMax[hit.cell]) / 2
                if not best or abs(middle - z) < bestDistance then best, bestDistance = hit, abs(middle - z) end
            end
            return best
        end
        -- Route state: a cell attached to a waypoint of the running route wins.
        if opts.preferred then
            for _, hit in ipairs(hits) do
                local zone = hit.zone
                for a = zone.cellStart[hit.cell], zone.cellStart[hit.cell] + zone.cellCount[hit.cell] - 1 do
                    local node = zone.attNode[a] and zone.base + zone.attNode[a]
                    if node and opts.preferred[node] then return hit end
                end
            end
        end
        -- Last known height (since 4.41): without any current height the band nearest to it decides, before the player is asked.
        if opts.lastHeight then
            local best, bestGap, bestMiddle
            for _, hit in ipairs(hits) do
                local lo, hi = hit.zone.cellZMin[hit.cell], hit.zone.cellZMax[hit.cell]
                local gap = max(lo - opts.lastHeight, 0, opts.lastHeight - hi)
                local middle = abs((lo + hi) / 2 - opts.lastHeight)
                if not best or gap < bestGap or (gap == bestGap and middle < bestMiddle) then
                    best, bestGap, bestMiddle = hit, gap, middle
                end
            end
            return best
        end
        -- Bands that are at most 2 yd apart belong to the same layer (chapter 4.1): not ambiguous
        table.sort(hits, function(p, q)
            return (p.zone.cellZMin[p.cell] + p.zone.cellZMax[p.cell]) < (q.zone.cellZMin[q.cell] + q.zone.cellZMax[q.cell])
        end)
        local first = hits[1]
        local ambiguous = false
        for i = 2, #hits do
            local hit = hits[i]
            if hit.zone.cellZMin[hit.cell] - first.zone.cellZMax[first.cell] > 2.0 then ambiguous = true; break end
        end
        if not ambiguous then return first end
        opts.candidates = hits
        return nil, "ambiguous"
    end
    -- no cell: nearest cell within the radius
    local radius = opts.radius or N.START_RADIUS
    local best
    for _, kind in ipairs(order) do
        local size = CELL_SIZES[kind]
        local reach = floor(radius / size) + 1
        for _, zone in ipairs(zones) do
            local gx, gy = floor(x / size), floor(y / size)
            for dx = -reach, reach do
                for dy = -reach, reach do
                    for _, i in ipairs(zone.cellMap[kind + 1][CellKey(gx + dx, gy + dy)] or {}) do
                        if FitsHeight(zone, i, z) then
                            local distance = RectDistance(zone, i, x, y)
                            if distance <= radius and (not best or distance < best.distance) then
                                best = { zone = zone, cell = i, distance = distance, kind = kind }
                            end
                        end
                    end
                end
            end
        end
    end
    if best then return best end
    return nil, "no_attachment"
end

-- True when every zone that can contain the point is decoded already. Lists must not decode zones: resolving a target decodes all
-- candidate zones of its point (CellsWithin), and the boxes of neighbouring zones overlap, so one decoded zone would pull in the next
-- one, whose targets pull in the following, until the first opening of the list has decoded the whole continent (4.54: 15 zones,
-- +350 MB, seconds of stall). A target with an unloaded candidate is offered without a check and resolved when it is selected.
function N.PointZoneLoaded(x, y)
    local candidates = N.ZonesForPoint(x, y)
    if #candidates == 0 then return next(N.zones) ~= nil end
    for _, id in ipairs(candidates) do
        if not N.zones[id] then return false end
    end
    return true
end

-- All attachment cells with a distance of at most radius to (x, y): { {zone, cell, kind, distance, zMin, zMax} }
-- (distance 0 = the point lies in the cell). kinds: list of cell classes (0 open, 1 fine, 2 water).
function N.CellsWithin(x, y, radius, kinds)
    local result = {}
    local zones = {}
    for _, id in ipairs(N.ZonesForPoint(x, y)) do
        local zone = N.LoadZone(id)
        if zone then zones[#zones + 1] = zone end
    end
    if #zones == 0 then
        for _, zone in pairs(N.zones) do zones[#zones + 1] = zone end
    end
    for _, kind in ipairs(kinds or { 1, 0, 2 }) do
        local size = CELL_SIZES[kind]
        local reach = floor(radius / size) + 1
        local gx, gy = floor(x / size), floor(y / size)
        for _, zone in ipairs(zones) do
            for dx = -reach, reach do
                for dy = -reach, reach do
                    for _, i in ipairs(zone.cellMap[kind + 1][CellKey(gx + dx, gy + dy)] or {}) do
                        local distance = RectDistance(zone, i, x, y)
                        if distance <= radius then
                            result[#result + 1] = { zone = zone, cell = i, kind = kind, distance = distance,
                                zMin = zone.cellZMin[i], zMax = zone.cellZMax[i], layer = zone.cellLayer[i] }
                        end
                    end
                end
            end
        end
    end
    return result
end

-- Attachment choice by field mask (chapter 7, since 4.24): attachments whose bit is set for the field of the point,
-- the nearest of them; else a bit set in one of the 8 neighbouring fields; else the nearest attachment of the cell.
-- accept(a) (optional) restricts the attachments that may be chosen (swimming start: water attachments).
function N.ChooseAttachment(zone, cell, x, y, accept)
    local size = zone.cellSize[cell]
    local fx = min(FIELDS - 1, max(0, floor((x - zone.cellX[cell]) / (size / FIELDS))))
    local fy = min(FIELDS - 1, max(0, floor((y - zone.cellY[cell]) / (size / FIELDS))))
    local first, count = zone.cellStart[cell], zone.cellCount[cell]
    local own, neighbours, all = {}, {}, {}
    local ownBit = FIELDS * fy + fx
    for a = first, first + count - 1 do
        if not accept or accept(a) then
            all[#all + 1] = a
            local mask = zone.attMask[a]
            if BitSet(mask, ownBit) then
                own[#own + 1] = a
            else
                local near = false
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        if (dx ~= 0 or dy ~= 0) and fx + dx >= 0 and fx + dx < FIELDS
                            and fy + dy >= 0 and fy + dy < FIELDS
                            and BitSet(mask, FIELDS * (fy + dy) + fx + dx) then
                            near = true
                        end
                    end
                end
                if near then neighbours[#neighbours + 1] = a end
            end
        end
    end
    local pool = #own > 0 and own or (#neighbours > 0 and neighbours or all)
    local best, distance
    for _, a in ipairs(pool) do
        local ax, ay = N.AttachmentPosition(zone, a)
        local d = sqrt((ax - x) ^ 2 + (ay - y) ^ 2)
        if not best or d < distance then best, distance = a, d end
    end
    return best, (#own > 0 and "own_field") or (#neighbours > 0 and "neighbour_field" or "nearest")
end

-- Binding of one given attachment of a cell.
local function BindingOfAttachment(zone, cell, attachment, choice, x, y, cellDistance)
    local ax, ay, az = N.AttachmentPosition(zone, attachment)
    local binding = { zone = zone, cell = cell, attachment = attachment, choice = choice,
        x = ax, y = ay, z = az, cellDistance = cellDistance or 0, approach = (cellDistance or 0) > 0,
        airDistance = sqrt((ax - x) ^ 2 + (ay - y) ^ 2) }
    if zone.attLink[attachment] then
        binding.type = "link"
        binding.link, binding.t = zone.attLink[attachment], zone.attT[attachment]
        binding.id = N.LinkpointNode(zone, binding.link, binding.t)
    else
        binding.type = "node"
        binding.id = zone.base + zone.attNode[attachment]
    end
    return binding
end

-- Builds the binding of one specific cell (used by the target resolver for every candidate band).
function N.BindCell(zone, cell, x, y, cellDistance, accept)
    local attachment, choice = N.ChooseAttachment(zone, cell, x, y, accept)
    if not attachment then return nil, "no_attachment" end
    return BindingOfAttachment(zone, cell, attachment, choice, x, y, cellDistance)
end

-- All attachments of one cell as bindings, the field-mask choice first, then the others by distance (4.44: a target end
-- binding that no route reaches, e.g. a source, is replaced by another attachment of the cell). noExit water nodes are left out.
function N.CellBindings(zone, cell, x, y, cellDistance)
    local first = N.BindCell(zone, cell, x, y, cellDistance)
    if not first then return {} end
    local list, seen = { first }, { [first.id] = true }
    local others = {}
    for a = zone.cellStart[cell], zone.cellStart[cell] + zone.cellCount[cell] - 1 do
        local binding = BindingOfAttachment(zone, cell, a, "alternative", x, y, cellDistance)
        if not seen[binding.id] and not (binding.type == "node" and N.NoExit(binding.id)) then others[#others + 1] = binding end
    end
    table.sort(others, function(p, q)
        if p.airDistance ~= q.airDistance then return p.airDistance < q.airDistance end
        return p.id < q.id
    end)
    for _, binding in ipairs(others) do
        if not seen[binding.id] then seen[binding.id] = true; list[#list + 1] = binding end
    end
    return list
end

-- Start while swimming or diving (opts.swimming): only water points are start attachments, i.e. nodes of a WATER area and
-- points on swimming links, never a land attachment on the lake floor or on the shore above. Without a water point in reach
-- the nearest water exit (code EXIT) is the start.
N.WATER_EXIT_RADIUS = 100.0     -- yd: reach of the water exit fallback
N.WATER_EXIT_ALTERNATIVES = 3   -- water exits offered as the last start alternatives

local function WaterFilter(zone)
    return function(a)
        local link = zone.attLink[a]
        if link then return zone.lflag[link] >= 8 end        -- link flag 8: swimming
        return zone.area[zone.attNode[a] + 1] == 2
    end
end

-- A node as a start binding (a water exit is no cell attachment).
local function NodeBinding(zone, i, x, y, cell)
    local nx, ny, nz = zone.x[i], zone.y[i], zone.z[i]
    return { zone = zone, cell = cell, choice = "water_exit", type = "node", id = zone.base + i - 1, x = nx, y = ny, z = nz,
        cellDistance = 0, approach = true, airDistance = sqrt((nx - x) ^ 2 + (ny - y) ^ 2) }
end

-- Water exits (code EXIT) of the zone within WATER_EXIT_RADIUS, nearest first.
local function WaterExits(zone, cell, x, y, limit)
    local found = {}
    for i = 1, zone.n do
        if floor(zone.bits[i] / BIT_EXIT) % 2 == 1 then
            local binding = NodeBinding(zone, i, x, y, cell)
            if binding.airDistance <= N.WATER_EXIT_RADIUS then found[#found + 1] = binding end
        end
    end
    table.sort(found, function(p, q)
        if p.airDistance ~= q.airDistance then return p.airDistance < q.airDistance end
        return p.id < q.id
    end)
    while #found > limit do found[#found] = nil end
    return found
end

-- Binding of a swimming start: water attachment of the cell, else of a water cell next to it, else the nearest water exit.
function N.BindWater(hit, x, y)
    local zone = hit.zone
    local binding = N.BindCell(zone, hit.cell, x, y, hit.distance, WaterFilter(zone))
    if binding then return binding end
    local cells = N.CellsWithin(x, y, zone.cellSize[hit.cell], { 2 })
    table.sort(cells, function(p, q)
        if p.distance ~= q.distance then return p.distance < q.distance end
        if p.zone.id ~= q.zone.id then return p.zone.id < q.zone.id end
        return p.cell < q.cell
    end)
    for _, near in ipairs(cells) do
        binding = N.BindCell(near.zone, near.cell, x, y, near.distance, WaterFilter(near.zone))
        if binding then return binding end
    end
    local exits = WaterExits(zone, hit.cell, x, y, 1)
    if exits[1] then return exits[1] end
    return nil, "no_attachment"
end

-- All start attachments for a position, best first (chapter 7, since 4.41): the binding of N.Bind, then the other
-- attachments of its cell (nearest first), then the attachments of the cells next to it (same layer first, then by
-- distance; with a known height the band nearest to it first). Water nodes without a checked exit (noExit) are never
-- offered as an alternative. Used when the route from the first attachment finds no way.
-- Returns { binding, ... } | nil, reason
function N.StartBindings(x, y, z, opts)
    opts = opts or {}
    local primary, reason = N.Bind(x, y, z, opts)
    if not primary then return nil, reason end
    local list, seen = { primary }, { [primary.id] = true }
    local function addCell(zone, cell, cellDistance)
        local found = {}
        local accept = opts.swimming and WaterFilter(zone) or nil
        for a = zone.cellStart[cell], zone.cellStart[cell] + zone.cellCount[cell] - 1 do
            local binding = (not accept or accept(a))
                and BindingOfAttachment(zone, cell, a, "alternative", x, y, cellDistance) or nil
            if binding and not seen[binding.id] and not (binding.type == "node" and N.NoExit(binding.id)) then
                found[#found + 1] = binding
            end
        end
        table.sort(found, function(p, q)
            if p.airDistance ~= q.airDistance then return p.airDistance < q.airDistance end
            return p.id < q.id
        end)
        for _, binding in ipairs(found) do
            if not seen[binding.id] then
                seen[binding.id] = true
                list[#list + 1] = binding
            end
        end
    end
    addCell(primary.zone, primary.cell, primary.cellDistance)
    local kind = primary.zone.cellKind and primary.zone.cellKind[primary.cell]
    local size = primary.zone.cellSize[primary.cell]
    local layer = primary.zone.cellLayer[primary.cell]
    local neighbours = {}
    for _, cell in ipairs(N.CellsWithin(x, y, size, kind and { kind } or nil)) do
        if not (cell.zone == primary.zone and cell.cell == primary.cell) then
            local middle = (cell.zMin + cell.zMax) / 2
            cell.heightGap = z and abs(middle - z) or 0
            cell.sameLayer = cell.layer == layer
            neighbours[#neighbours + 1] = cell
        end
    end
    table.sort(neighbours, function(p, q)
        if p.sameLayer ~= q.sameLayer then return p.sameLayer end
        if p.distance ~= q.distance then return p.distance < q.distance end
        if p.heightGap ~= q.heightGap then return p.heightGap < q.heightGap end
        if p.zone.id ~= q.zone.id then return p.zone.id < q.zone.id end
        return p.cell < q.cell
    end)
    for _, cell in ipairs(neighbours) do addCell(cell.zone, cell.cell, cell.distance) end
    if opts.swimming then
        for _, binding in ipairs(WaterExits(primary.zone, primary.cell, x, y, N.WATER_EXIT_ALTERNATIVES)) do
            if not seen[binding.id] then seen[binding.id] = true; list[#list + 1] = binding end
        end
    end
    return list
end

-- Binds a point to the network: find the cell, choose the attachment.
-- Returns binding { zone, cell, attachment, type, id (global node or link-point node), x, y, z of the attachment,
-- airDistance, cellDistance, approach } | nil, reason
function N.Bind(x, y, z, opts)
    opts = opts or {}
    local hit, reason = N.FindCell(x, y, z, opts)
    if not hit then return nil, reason end
    if opts.swimming then return N.BindWater(hit, x, y) end
    return N.BindCell(hit.zone, hit.cell, x, y, hit.distance)
end

-- Height bands of all cells above a point (diagnostics, level choice)
function N.HeightBands(x, y, opts)
    opts = opts or {}
    local bands = {}
    local order = opts.swimming and { 2 } or { 1, 0 }
    for _, id in ipairs(N.ZonesForPoint(x, y)) do
        local zone = N.LoadZone(id)
        if zone then
            for _, kind in ipairs(order) do
                for _, i in ipairs(CellCandidates(zone, kind, x, y, nil)) do
                    bands[#bands + 1] = { zone = zone, cell = i, zMin = zone.cellZMin[i], zMax = zone.cellZMax[i],
                        layer = zone.cellLayer[i] }
                end
                if #bands > 0 then break end
            end
        end
    end
    table.sort(bands, function(a, b) return a.zMin < b.zMin end)
    return bands
end

-- A binding as an ID, so that callers (list, resolver, core) can keep working with "node IDs".
function N.BindingId(binding)
    return binding.id
end

-- Inverse: real node ID or link-point ID -> binding
function N.BindingFromId(id)
    if id == nil then return nil end
    if id >= VIRT_BASE then
        local v = N.virt[id]
        if not v then return nil end
        if v.type == "linkpoint" then
            return { type = "link", zone = v.zone, link = v.link, t = v.t, id = id, x = v.x, y = v.y, z = v.z }
        end
        return nil
    end
    -- A route can end in a zone that is not decoded (after an action into another map the loaded zones are those of the new
    -- map only): decode the zone of the ID on demand, like a seam or an action does while the search runs.
    local zone = ZoneOf(id) or N.LoadZone(floor(id / ZONE_BASE))
    if not zone then return nil end
    local i = id - zone.base + 1
    if i < 1 or i > zone.n then return nil end
    return { type = "node", id = id, zone = zone, x = zone.x[i], y = zone.y[i], z = zone.z[i] }
end

-- Route between two IDs (bindings, link points or real nodes). Result as N.Route.
function N.RouteIds(startId, targetId, penalties, footOnly)
    local start, target = N.BindingFromId(startId), N.BindingFromId(targetId)
    if not start or not target then return nil, "invalid_point" end
    return N.Route(start, target, penalties, footOnly)
end

-- ---------------------------------------------------------------------------
-- A* (chapter 7, point 4)
-- ---------------------------------------------------------------------------
-- Binary min-heap with parallel fields
local function HeapNew() return { n = 0, f = {}, id = {}, g = {} } end

local function HeapPush(h, f, id, g)
    local i = h.n + 1
    h.n = i
    local hf, hi, hg = h.f, h.id, h.g
    while i > 1 do
        local p = floor(i / 2)
        if hf[p] <= f then break end
        hf[i], hi[i], hg[i] = hf[p], hi[p], hg[p]
        i = p
    end
    hf[i], hi[i], hg[i] = f, id, g
end

local function HeapPop(h)
    local n = h.n
    if n == 0 then return nil end
    local hf, hi, hg = h.f, h.id, h.g
    local f0, id0, g0 = hf[1], hi[1], hg[1]
    local f, id, g = hf[n], hi[n], hg[n]
    hf[n], hi[n], hg[n] = nil, nil, nil
    n = n - 1
    h.n = n
    if n > 0 then
        local i = 1
        while true do
            local child = i * 2
            if child > n then break end
            if child < n and hf[child + 1] < hf[child] then child = child + 1 end
            if hf[child] >= f then break end
            hf[i], hi[i], hg[i] = hf[child], hi[child], hg[child]
            i = child
        end
        hf[i], hi[i], hg[i] = f, id, g
    end
    return f0, id0, g0
end

local function LinkFactor(flag, road)
    local factor = 1.0
    if flag >= 8 then factor = N.SWIM_FACTOR * N.SWIM_COMFORT       -- swimming (8): 1.5 x (1 + p/100), 4.49
    elseif flag % 8 >= 4 then factor = N.FINE_FACTOR end             -- fine (4)
    if road and flag % 2 == 1 then factor = factor * N.ROAD_FACTOR end
    return factor
end

-- Start/target options of a binding: { {id, cost}, ... }. A node attachment has one option, a link point two
-- (depending on the link direction).
local function Options(binding, road, asStart)
    local options = {}
    if binding.type == "node" then
        options[1] = { id = binding.id, cost = 0 }
        return options
    end
    local zone, k, t = binding.zone, binding.link, binding.t
    local length = zone.llen[k] * LinkFactor(zone.lflag[k], road)
    local direction = zone.ldir[k]
    local u, v = zone.base + zone.lu[k], zone.base + zone.lv[k]
    if asStart then
        -- from the link point to u (v -> u) needs the reverse direction, to v (u -> v) the forward direction
        if direction == 0 or direction == 2 then options[#options + 1] = { id = u, cost = length * t / 256 } end
        if direction == 0 or direction == 1 then options[#options + 1] = { id = v, cost = length * (256 - t) / 256 } end
    else
        if direction == 0 or direction == 1 then options[#options + 1] = { id = u, cost = length * t / 256 } end
        if direction == 0 or direction == 2 then options[#options + 1] = { id = v, cost = length * (256 - t) / 256 } end
    end
    return options
end

-- ---------------------------------------------------------------------------
-- Z2: outposts and capitals of the opposing faction. A route avoids their waypoints (a detour), never fails because of them: when no
-- route exists without one, the route leads through (N.Route). An outpost that holds the start or the target of the route is open.
-- ---------------------------------------------------------------------------
N.avoidOutposts = true                      -- /vn outposts on|off
local OPPONENT = { horde = "alliance", alliance = "horde" }

function N.SetAvoidOutposts(enabled)
    N.avoidOutposts = enabled ~= false
end

-- group: "Alliance" | "Horde" (UnitFactionGroup("player")); anything else means no faction and no avoidance
function N.SetPlayerFaction(group)
    local faction = type(group) == "string" and group:lower() or nil
    N.playerFaction = OPPONENT[faction] and faction or nil
end

function N.PlayerFaction()
    if N.playerFaction then return N.playerFaction end
    if type(_G.UnitFactionGroup) == "function" then
        local ok, group = pcall(_G.UnitFactionGroup, "player")
        if ok then N.SetPlayerFaction(group) end
    end
    return N.playerFaction
end

-- zone.hostile[local index + 1] = group key (the global ID of one waypoint of the connected hostile waypoints) for the opponents of faction
local function HostileTable(zone, faction)
    if zone.hostileFor ~= faction then
        zone.hostileFor, zone.hostile = faction, nil
        local ranges = zone.factionRanges[OPPONENT[faction]]
        if ranges then
            local parent = {}
            for _, range in ipairs(ranges) do
                for i = range[1] + 1, range[2] + 1 do parent[i] = i end
            end
            local function find(i)
                while parent[i] ~= i do
                    parent[i] = parent[parent[i]]
                    i = parent[i]
                end
                return i
            end
            for k = 1, #zone.lu do
                local u, v = zone.lu[k] + 1, zone.lv[k] + 1
                if parent[u] and parent[v] then
                    local ru, rv = find(u), find(v)
                    if ru ~= rv then parent[ru] = rv end
                end
            end
            local hostile = {}
            for i in pairs(parent) do hostile[i] = zone.base + find(i) - 1 end
            zone.hostile = hostile
        end
    end
    return zone.hostile
end

-- The group key of a hostile waypoint (global ID) for the player of `faction`, else nil.
local function HostileGroup(id, faction)
    if id >= VIRT_BASE then return nil end
    local zone = N.zones[floor(id / ZONE_BASE)]
    if not zone or not zone.hasFactions then return nil end
    local hostile = HostileTable(zone, faction)
    return hostile and hostile[id - zone.base + 1] or nil
end

local function BindingEnds(binding)
    if binding.type == "node" then return { binding.id } end
    local zone, k = binding.zone, binding.link
    return { zone.base + zone.lu[k], zone.base + zone.lv[k] }
end

-- nil without avoidance (off, no faction known); else { faction, open = {group key = true}, targetInside = bool }
local function AvoidanceFor(startBinding, targetBinding)
    if not N.avoidOutposts then return nil end
    local faction = N.PlayerFaction()
    if not faction then return nil end
    local avoid = { faction = faction, open = {}, targetInside = false }
    for _, binding in ipairs({ startBinding, targetBinding }) do
        for _, id in ipairs(BindingEnds(binding)) do
            local group = HostileGroup(id, faction)
            if group then
                avoid.open[group] = true
                if binding == targetBinding then avoid.targetInside = true end
            end
        end
    end
    return avoid
end

local function Blocked(avoid, id)
    local group = HostileGroup(id, avoid.faction)
    return group ~= nil and not avoid.open[group]
end

-- Time slicing (chapter 7 point 4, "at most 30 ms per frame"): set while a route job's coroutine runs.
local slicing = nil
local SLICE_CHECK = 64     -- expansions between clock reads
-- WowVision: the waypoints reached by the plain searches of the running job that found no target (N.Route), one list
-- per foot-only switch. Such a set holds everything reachable from each of its waypoints, so it also bounds every
-- start whose options all lie in it.
local reachCache = nil
-- counters for WowVision's trail: whole searches that missed (kept as sets) and targets answered from those sets
N.wholeMisses, N.knownMissAnswers = 0, 0

-- true when a search from startBinding can be told without searching that it cannot reach targetBinding
local function KnownUnreachable(sets, startBinding, targetBinding)
    local starts, targets = Options(startBinding, false, true), Options(targetBinding, false, false)
    for _, reached in ipairs(sets) do
        local inside = true
        for _, option in ipairs(starts) do
            if reached[option.id] == nil then inside = false; break end
        end
        if inside then
            local hit = false
            for _, option in ipairs(targets) do
                if reached[option.id] ~= nil then hit = true; break end
            end
            if not hit then return true end
        end
    end
    return false
end

-- One pass. road = with road factor. Returns { path = {global IDs}, edges = {link refs}, length = geometric length
-- of the links walked, cost }
local function Pass(startBinding, targetBinding, road, penalties, footOnly, avoid)
    local starts = Options(startBinding, road, true)
    local targets = Options(targetBinding, road, false)
    local targetMap = {}
    for _, option in ipairs(targets) do
        local list = targetMap[option.id] or {}
        list[#list + 1] = option
        targetMap[option.id] = list
    end
    local hmin = road and N.ROAD_FACTOR or 1.0
    local tx, ty, tz = targetBinding.x, targetBinding.y, targetBinding.z
    local g, previous = {}, {}
    local heap = HeapNew()
    local useStraightLine = N.actionCount == 0   -- cheap teleports make the straight line inadmissible
    local function estimate(id)
        if not useStraightLine then return 0 end
        local x, y, z = N.Position(id)
        return Distance3(x, y, z, tx, ty, tz) * hmin
    end
    for _, option in ipairs(starts) do
        if option.cost < (g[option.id] or math.huge) then
            g[option.id] = option.cost
            previous[option.id] = false
            HeapPush(heap, option.cost + estimate(option.id), option.id, option.cost)
        end
    end
    local bestSum, bestEnd = math.huge, nil
    local expansions = 0
    local function relax(vid, new, from)
        if new < (g[vid] or math.huge) then
            g[vid] = new
            previous[vid] = from
            HeapPush(heap, new + estimate(vid), vid, new)
        end
    end
    -- 4.37: the virtual link point of a seam end on a link (created on demand, the virtual points are discarded per start)
    local function SeamPoint(zoneId, seamId)
        local other = N.zones[zoneId] or N.LoadZone(zoneId)
        local ok = other and other.seamLinkOk[seamId]
        if not ok then return nil end
        local point = N.LinkpointNode(other, ok.k, ok.t)
        local virtual = N.virt[point]
        if not virtual.seamNodes then
            virtual.seamNodes = {}
            for id, entry in pairs(other.seamLinkOk) do
                if entry.k == ok.k and entry.t == ok.t then
                    entry.seamId = id
                    virtual.seamNodes[#virtual.seamNodes + 1] = { gid = entry.partner, cost = entry.cost, seamId = id, water = entry.water }
                end
            end
        end
        return point
    end
    while true do
        local f, id, cost = HeapPop(heap)
        if not f then break end
        if f >= bestSum then break end
        if cost <= (g[id] or math.huge) then
            expansions = expansions + 1
            -- time slice (N.RouteJob): only inside a job's coroutine, never in a plain N.Route call
            if slicing and expansions % SLICE_CHECK == 0 and slicing.clock() >= slicing.deadline then
                coroutine.yield()
            end
            local atTarget = targetMap[id]
            if atTarget then
                for _, option in ipairs(atTarget) do
                    if cost + option.cost < bestSum then bestSum, bestEnd = cost + option.cost, id end
                end
            end
            local zone = ZoneOf(id)
            if zone then
                local localId = id - zone.base
                local adj = zone.adj[localId + 1]
                for j = 1, #adj, 2 do
                    local v, k = adj[j], adj[j + 1]
                    local new = cost + (zone.llen[k] + N.HOP_COST) * LinkFactor(zone.lflag[k], road)
                    local vid = zone.base + v
                    if penalties then
                        local row = penalties[id]
                        if row and row[vid] then new = new + row[vid] end
                    end
                    if new < (g[vid] or math.huge) and not (avoid and Blocked(avoid, vid)) then
                        g[vid] = new
                        previous[vid] = { id, zone, k }
                        HeapPush(heap, new + estimate(vid), vid, new)
                    end
                end
                local actions = (not footOnly) and zone.actionsFrom[localId] or nil
                if actions then
                    for _, action in ipairs(actions) do
                        local allowed = N.WalkingAction(action) and (not N.ActionAllowed or N.ActionAllowed(action))
                        local otherZone = floor(action.toNode / ZONE_BASE)
                        if allowed and not N.zones[otherZone] then N.LoadZone(otherZone) end
                        if allowed and N.zones[otherZone] and not (avoid and Blocked(avoid, action.toNode)) then
                            local new = cost + action.cost
                            if new < (g[action.toNode] or math.huge) then
                                g[action.toNode] = new
                                previous[action.toNode] = { id, false, false, action }
                                HeapPush(heap, new + estimate(action.toNode), action.toNode, new)
                            end
                        end
                    end
                end
                local seamLinks = zone.seamLinkEnds[localId]
                if seamLinks then
                    for _, entry in ipairs(seamLinks) do
                        local k, t = entry.k, entry.t
                        local direction = zone.ldir[k]
                        local length = zone.llen[k] * LinkFactor(zone.lflag[k], road)
                        local atU = zone.lu[k] == localId
                        if (atU and (direction == 0 or direction == 1)) or (not atU and (direction == 0 or direction == 2)) then
                            local point = SeamPoint(zone.id, entry.seamId)
                            if point then
                                relax(point, cost + length * (atU and t or 256 - t) / 256, { id, zone, k, false, true })
                            end
                        end
                    end
                end
                local seams = zone.seam[localId]
                if seams then
                    for _, seam in ipairs(seams) do
                        if seam.link then
                            local point = SeamPoint(seam.zoneId, seam.seamId)
                            if point then relax(point, cost + seam[2] * (seam.water and N.SWIM_COMFORT or 1), { id, false, false }) end
                        else
                            local otherZone = floor(seam[1] / ZONE_BASE)
                            if not N.zones[otherZone] then N.LoadZone(otherZone) end
                            if N.zones[otherZone] and not (seam.seamId and N.zones[otherZone].seamBad[seam.seamId])
                                and not (avoid and Blocked(avoid, seam[1])) then
                                local new = cost + seam[2] * (seam.water and N.SWIM_COMFORT or 1)
                                if new < (g[seam[1]] or math.huge) then
                                    g[seam[1]] = new
                                    previous[seam[1]] = { id, false, false }
                                    HeapPush(heap, new + estimate(seam[1]), seam[1], new)
                                end
                            end
                        end
                    end
                end
            end
            local virtual = id >= VIRT_BASE and N.virt[id] or nil
            if virtual and virtual.seamNodes then
                -- a seam end on a link: across the seam, and (if the point was reached over the seam) along the link
                for _, partner in ipairs(virtual.seamNodes) do
                    local otherZone = floor(partner.gid / ZONE_BASE)
                    if not N.zones[otherZone] then N.LoadZone(otherZone) end
                    local oz = N.zones[otherZone]
                    if oz and not oz.seamBad[partner.seamId] and not (avoid and Blocked(avoid, partner.gid)) then relax(partner.gid, cost + partner.cost * (partner.water and N.SWIM_COMFORT or 1), { id, false, false }) end
                end
                local came = previous[id]
                if not (came and came[5]) then
                    local zoneOfLink, k, t = virtual.zone, virtual.link, virtual.t
                    local direction = zoneOfLink.ldir[k]
                    local length = zoneOfLink.llen[k] * LinkFactor(zoneOfLink.lflag[k], road)
                    if direction == 0 or direction == 2 then      -- point -> u needs the direction v -> u
                        relax(zoneOfLink.base + zoneOfLink.lu[k], cost + length * t / 256, { id, zoneOfLink, k, false, true })
                    end
                    if direction == 0 or direction == 1 then      -- point -> v
                        relax(zoneOfLink.base + zoneOfLink.lv[k], cost + length * (256 - t) / 256, { id, zoneOfLink, k, false, true })
                    end
                end
            end
        end
    end
    if not bestEnd then return nil, expansions, g end
    local path, edges, length = { bestEnd }, {}, 0
    local id = bestEnd
    while previous[id] do
        local step = previous[id]
        local zone, k = step[2], step[3]
        table.insert(path, 1, step[1])
        if step[4] then
            table.insert(edges, 1, { action = step[4] })
            length = length + 0
        elseif k and step[5] then
            -- part of a link up to or from a seam point (4.37)
            table.insert(edges, 1, { zone = zone, link = k, flag = zone.lflag[k], partial = true })
            local ax, ay, az = N.Position(step[1])
            local bx, by, bz = N.Position(id)
            length = length + Distance3(ax, ay, az, bx, by, bz)
        elseif k then
            table.insert(edges, 1, { zone = zone, link = k, flag = zone.lflag[k] })
            length = length + zone.llen[k]
        else
            table.insert(edges, 1, { seam = true })
            -- a seam link counts with the geometric distance of its two ends (its cost may carry the swimming factor)
            local ax, ay, az = N.Position(step[1])
            local bx, by, bz = N.Position(id)
            length = length + Distance3(ax, ay, az, bx, by, bz)
        end
        id = step[1]
    end
    return { path = path, edges = edges, length = length, cost = bestSum, expansions = expansions }
end

-- Two passes: (a) comfort costs, (b) with the road factor 1/r; (b) wins when its geometric length is at most r x that
-- of (a) (r = 1 + comfort/100, default 1.5; comfort 0 has no pass (b)). Start and target are bindings from N.Bind.
function N.Route(startBinding, targetBinding, penalties, footOnly)
    -- WowVision: inside a job, a plain search that ran out without its target knows every waypoint it reaches; a later
    -- target outside that set, from a start inside it, has no route: the same answer without the whole search again
    -- (the floor check routes every candidate of a band, each a search of the whole continent)
    local sets
    if reachCache then
        local key = footOnly and "foot" or "all"
        sets = reachCache[key] or {}
        reachCache[key] = sets
        if KnownUnreachable(sets, startBinding, targetBinding) then
            N.knownMissAnswers = N.knownMissAnswers + 1
            return nil, "no_route"
        end
    end
    local avoid = AvoidanceFor(startBinding, targetBinding)
    local exhausted
    local function passes(avoidance)
        local a, _, reached = Pass(startBinding, targetBinding, false, penalties, footOnly, avoidance)
        if not a then
            if not avoidance then exhausted = reached end
            return nil
        end
        return a, N.comfort > 0 and Pass(startBinding, targetBinding, true, penalties, footOnly, avoidance) or nil
    end
    local a, b = passes(avoid)
    if not a and avoid then a, b = passes(nil) end     -- Z2: no route without a hostile outpost: through it, never no route
    if not a then
        if sets and exhausted then
            sets[#sets + 1] = exhausted
            N.wholeMisses = N.wholeMisses + 1
        end
        return nil, "no_route"
    end
    local chosen, pass = a, "a"
    if b and b.length <= N.ROAD_MAX_RATIO * a.length then chosen, pass = b, "b" end
    local path = {}
    -- virtual link-point attachments at the start and end (steering targets, chapter 7 point 2)
    if startBinding.type == "link" then path[#path + 1] = startBinding.id end
    for _, id in ipairs(chosen.path) do path[#path + 1] = id end
    if targetBinding.type == "link" then path[#path + 1] = targetBinding.id end
    local outpost
    if avoid then
        for _, id in ipairs(path) do
            if Blocked(avoid, id) then outpost = "through"; break end
        end
        if not outpost and avoid.targetInside then outpost = "target" end
    end
    return { path = path, edges = chosen.edges, length = chosen.length, cost = chosen.cost, pass = pass,
        lengthA = a.length, lengthB = b and b.length or nil, expansions = chosen.expansions, outpost = outpost }
end

-- Any work that searches routes, in time slices (WowVision): fn runs inside a coroutine, and every N.Route /
-- N.RouteIds it calls yields when the budget of the frame is used up. The caller steps it once per frame:
--   local job = N.Job(fn, ...)
--   local done, a, b = job:Step(budget, clock)   -- clock() in the budget's unit (debugprofilestop: ms)
-- done is true once fn has returned; a and b are then its first two results (or nil, error text). While a job is
-- pending, do not drop zones or virtual points it may use (N.UnloadZone, N.KeepVirtual, N.DiscardVirtual, N.Reset).
function N.Job(fn, ...)
    local args, count = { ... }, select("#", ...)
    local job = { done = false, reach = {} }
    job.thread = coroutine.create(function()
        return fn(unpack(args, 1, count))
    end)
    function job:Step(budget, clock)
        if self.done then return true, self.result, self.reason end
        slicing, reachCache = { clock = clock, deadline = clock() + budget }, self.reach
        local ok, result, reason = coroutine.resume(self.thread)
        slicing, reachCache = nil, nil
        if not ok then
            self.done, self.result, self.reason = true, nil, tostring(result)
        elseif coroutine.status(self.thread) == "dead" then
            self.done, self.result, self.reason = true, result, reason
        end
        return self.done, self.result, self.reason
    end
    return job
end

-- N.Route in time slices (see N.Job).
function N.RouteJob(startBinding, targetBinding, penalties, footOnly)
    return N.Job(N.Route, startBinding, targetBinding, penalties, footOnly)
end

-- Steering targets of a route: the waypoints, except a pure BRANCH point that the route walks through over the
-- two halves of the same split link (chapter 7 point 5).
function N.SteeringTargets(path)
    local result = {}
    local n = #path
    for i = 1, n do
        local id = path[i]
        local skip = false
        if i > 1 and i < n and N.Bits(id) == BIT_BRANCH then
            local a, b = N.BranchPair(id)
            local before, after = path[i - 1], path[i + 1]
            if a and ((before == a and after == b) or (before == b and after == a)) then skip = true end
        end
        if not skip then result[#result + 1] = id end
    end
    return result
end

-- Geometric (3D) length of a waypoint sequence
function N.PathLength(path)
    local sum = 0
    for i = 2, #path do
        local ax, ay, az = N.Position(path[i - 1])
        local bx, by, bz = N.Position(path[i])
        sum = sum + Distance3(ax, ay, az, bx, by, bz)
    end
    return sum
end

-- "Still inside the attachment cell whose attachment is the next waypoint" (chapter 7 point 6): true when a cell above
-- (x, y) has an attachment to targetId (node or link point) whose bit is set for the field of the player. With
-- unknown height all stacked cells count.
function N.AttachmentAtPosition(x, y, z, targetId, opts)
    opts = opts or {}
    local virtual = targetId >= VIRT_BASE and N.virt[targetId] or nil
    if targetId >= VIRT_BASE and (not virtual or virtual.type ~= "linkpoint") then return false end
    local kinds = opts.swimming and { 2 } or { 1, 0 }
    for _, zoneId in ipairs(N.ZonesForPoint(x, y)) do
        local zone = N.zones[zoneId]
        if zone then
            for _, kind in ipairs(kinds) do
                for _, cell in ipairs(CellCandidates(zone, kind, x, y, z)) do
                    local size = zone.cellSize[cell]
                    local fx = min(FIELDS - 1, max(0, floor((x - zone.cellX[cell]) / (size / FIELDS))))
                    local fy = min(FIELDS - 1, max(0, floor((y - zone.cellY[cell]) / (size / FIELDS))))
                    local bit = FIELDS * fy + fx
                    for a = zone.cellStart[cell], zone.cellStart[cell] + zone.cellCount[cell] - 1 do
                        local matches
                        if virtual then
                            matches = virtual.zone == zone and zone.attLink[a] == virtual.link and zone.attT[a] == virtual.t
                        else
                            matches = zone.attNode[a] ~= nil and zone.base + zone.attNode[a] == targetId
                        end
                        if matches and BitSet(zone.attMask[a], bit) then return true, zone, cell end
                    end
                end
            end
        end
    end
    return false
end

-- All node attachments (global IDs) of the cell above (x, y) whose bit is set for the field of the player.
function N.AttachmentsAtPosition(x, y, z, opts)
    opts = opts or {}
    local hit = N.FindCell(x, y, z, { swimming = opts.swimming, radius = 0 })
    local result = {}
    if not hit then return result end
    local zone, cell = hit.zone, hit.cell
    local size = zone.cellSize[cell]
    local fx = min(FIELDS - 1, max(0, floor((x - zone.cellX[cell]) / (size / FIELDS))))
    local fy = min(FIELDS - 1, max(0, floor((y - zone.cellY[cell]) / (size / FIELDS))))
    local bit = FIELDS * fy + fx
    for a = zone.cellStart[cell], zone.cellStart[cell] + zone.cellCount[cell] - 1 do
        if zone.attNode[a] and BitSet(zone.attMask[a], bit) then
            result[#result + 1] = zone.base + zone.attNode[a]
        end
    end
    return result, zone, cell
end

-- G21 (report): memory in kB
function N.MemoryReport()
    return { current = Memory(), zones = N.memory.zones, login = N.memory.login }
end
