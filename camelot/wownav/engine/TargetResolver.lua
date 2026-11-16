-- WowNav engine by Broesel33 (github.com/Broesel33/WoW_NavigationData, DemoAddon/WowVisionNavigation/TargetResolver.lua at
-- cc6c179), carried in WowVision with his permission. Changes for WowVision: see camelot/wownav/engine/README.md.

-- Runtime attachment of targets to the network (schema 7, chapter 7 point 3). A target is bound to the attachment cell
-- above its position; a target outside every cell is bound to the nearest cell within 30 yd and marked as an
-- "approach". Stacked cells are separated into height bands; without a known height the player chooses (/vn ebene).
-- A target with certified levels (4.54, ``levels``) asks for its level the same way. A question is only asked when at least
-- two of its bands can be reached from the start, and its answer is evaluated over the very band it offered (R:Resolve).
WowVisionNavigationTargetResolver = {}
local R = WowVisionNavigationTargetResolver
local finite = WowVisionNavigationTargetCatalog.Finite

function R:Settings()
    local db = WowVisionNavigationDB or {}
    local net = WowVisionNavigationNavNetwork
    local radius = finite(db.targetRadius) and db.targetRadius > 0 and db.targetRadius or net.TARGET_RADIUS
    local tolerance = finite(db.targetTolerance) and db.targetTolerance >= 0 and db.targetTolerance
        or net.HEIGHT_TOLERANCE
    return radius, tolerance
end

-- Groups cells into height bands (sorted by height). A band is { zMin, zMax, candidates, nearest }. The tolerance is the
-- total Z span of one band (the span is measured from the lowest cell of the band, so chains do not merge).
function R:HeightBands(candidates, tolerance)
    tolerance = tolerance or select(2, self:Settings())
    table.sort(candidates, function(a, b)
        if a.zMin ~= b.zMin then return a.zMin < b.zMin end
        if a.cell ~= b.cell then return a.cell < b.cell end
        return a.zone.id < b.zone.id
    end)
    local bands = {}
    for _, candidate in ipairs(candidates) do
        local band = bands[#bands]
        if not band or candidate.zMin - band.zMin > tolerance then
            band = { zMin = candidate.zMin, zMax = candidate.zMax, candidates = {}, nearest = math.huge }
            bands[#bands + 1] = band
        end
        band.zMax = math.max(band.zMax, candidate.zMax)
        band.nearest = math.min(band.nearest, candidate.distance)
        band.candidates[#band.candidates + 1] = candidate
    end
    return bands
end

local function FitsLand(candidate, z, tolerance)
    return z == nil or (candidate.zMin - tolerance <= z and z <= candidate.zMax + tolerance)
end

-- A water cell holds the surface height; everything below it is under water.
local function FitsWater(candidate, z, tolerance)
    return z == nil or z <= candidate.zMax + tolerance
end

local function Fits(candidate, z, tolerance)
    if candidate.kind == 2 then return FitsWater(candidate, z, tolerance) end
    return FitsLand(candidate, z, tolerance)
end

local function HeightDifference(candidate, z)
    if z == nil then return 0 end
    if z < candidate.zMin then return candidate.zMin - z end
    if z > candidate.zMax then return z - candidate.zMax end
    return 0
end

-- Concept 4.54: a target without a source height over several walkable levels carries the heights of the levels the build
-- certified (each one has a physical route). The player chooses the level (/vn ebene <number>); the chosen level is then
-- resolved like a target with a known height. Each band holds the attachment of its level, so the prompt can say which level
-- has no network path from the current start. With a start (context.route) the player is only asked when at least two levels
-- can be reached from it: with one the route goes to that level, with none there is no network path from here.
function R:ResolveLevels(nav, target, context)
    local levels = target.levels
    local function atLevel(h, index)
        local copy = {}
        for key, value in pairs(target) do copy[key] = value end
        copy.levels, copy.z, copy.zStatus = nil, h, "known"
        -- Weg B: the node of this level (a list as long as the levels; false: the level has none)
        if type(target.targetNode) == "table" then
            copy.targetNode = target.targetNode[index] or nil
        else
            copy.targetNode = nil
        end
        local plain = {}
        for key, value in pairs(context) do plain[key] = value end
        plain.heightBand, plain.band = nil, nil
        return self:Resolve(nav, copy, plain)
    end
    if context.heightBand then
        local h = levels[context.heightBand]
        if not h then return { quality = "unroutable", reason = WowVisionNavigationText("res_band_invalid") } end
        local result = atLevel(h, context.heightBand)
        result.level = context.heightBand
        return result
    end
    local bands, reachable, only = {}, 0, nil
    for i, h in ipairs(levels) do
        -- selectable: the level can be reached from the start (without a start, in a list, every level counts)
        local band = { zMin = h, zMax = h, candidates = {}, nearest = 0, level = i, selectable = true }
        if context.route then
            local result = atLevel(h, i)
            if result.binding then
                band.candidates[1] = result.binding
                band.nearest = result.cellDistance or 0
            end
            band.selectable = result.endNodeId ~= nil
            if band.selectable then
                reachable = reachable + 1
                if not only then result.level = i; only = result end
            end
        end
        bands[i] = band
    end
    if context.route and reachable == 0 then
        return { quality = "unroutable", noRouteFromStart = true, reason = WowVisionNavigationText("res_no_route_from_start") }
    end
    if context.route and reachable == 1 then return only end         -- one level to choose is no choice: no question
    return { quality = "ambiguous", bands = bands, levelUnknown = true, queryZ = nil, zConflict = false,
        reason = WowVisionNavigationText("res_level_unknown") }
end

-- Weg B (user decision 10.11.2026): every logical target of a zone built with it has a fixed node (NavNetwork.lua, "The node of a
-- logical target"). A catalog of such a zone carries navFingerprint. The resolver then binds the target to its node:
--   1. n of the row (targetNode) when the loaded zone has the catalog's fingerprint (a partial deploy cannot mislead it);
--   2. else the node at the target's coordinates (N.TargetNodeAt);
--   3. else, only in a zone of the catalog's fingerprint (a target that came with a target update after the build, "p"): the nearest
--      physical node within the target radius at the target's height, the last straight unchecked ("approximate");
--   4. a node without a route from the start (a source, a one-way end): the nearest nodes of 3. one by one.
-- A row without a node of its own (no n, none at its coordinates; user rule 11.11.2026: "logical targets without a node id are routed by the addon to the
-- nearest physical point, the rest is an unchecked straight"): the nearest nodes of 3. when one of them has a route, else the cells decide as for every other
-- target (the attachments of the cell above the target or of the nearest cell within the radius, of the own zone or of a neighbour where the row stands there).
-- A target of any other catalog (an older zone, live and dynamic targets) is bound over the cells as before.
R.fingerprintWarned = {}

local function CatalogZone(target)
    local net = WowVisionNavigationNavNetwork
    local own
    if target.zoneId then own = net.zones[target.zoneId] or net.LoadZone(target.zoneId) end
    if own and own.fingerprint == target.navFingerprint then return own, true end
    for _, id in ipairs(net.ZonesForPoint(target.x, target.y)) do
        local zone = net.LoadZone(id)
        if zone and zone.fingerprint == target.navFingerprint then return zone, true end
    end
    if own and not R.fingerprintWarned[own.id] then
        -- noted once per zone (the saved variables keep it for a bug report; nothing is said to the player)
        R.fingerprintWarned[own.id] = true
        if type(WowVisionNavigationDB) == "table" then
            WowVisionNavigationDB.targetNodeNote = "the catalog of zone " .. tostring(own.id) .. " belongs to another navdata; its node numbers are not used"
        end
    end
    return own, false
end

local function NodeResult(nav, target, binding, path, cost, radius, tolerance, how)
    local z = target.z
    local zone, i = binding.zone, binding.node
    local water = zone.area[i] == 2
    local underWater = water and z ~= nil and z < binding.z
    local deltaZ = (z ~= nil and not water) and math.abs(binding.z - z) or nil
    local deltaXY = binding.airDistance
    local exact = how ~= "nearest_node"
    return {
        endNodeId = binding.id, quality = exact and "exact" or "approximate", binding = binding, targetNode = how,
        cellDistance = 0, approach = not exact, deltaXY = deltaXY, deltaZ = deltaZ,
        delta3D = deltaZ and math.sqrt(deltaXY * deltaXY + deltaZ * deltaZ) or nil,
        zUnknown = z == nil, zOutOfTolerance = false, normalizedWater = underWater, queryZ = z,
        divingDepth = underWater and (binding.z - z) or nil,
        endpointSurface = water and "water" or "land", targetSurface = target.surface,
        path = path, cost = cost, graphRevision = nav.exportFingerprint, targetRevision = target.providerRevision,
        radius = radius, tolerance = tolerance,
    }
end

-- -> result, or nil when the target has no node (the cells decide, as before)
function R:ResolveTargetNode(nav, target, context, radius, tolerance)
    if type(target.navFingerprint) ~= "string" then return nil end
    local net = WowVisionNavigationNavNetwork
    local zone, matched = CatalogZone(target)
    local candidates = {}
    local own = false           -- the row has a node of its own (n or the node at its coordinates)
    if not target.approx then
        local direct
        if matched and type(target.targetNode) == "number" and target.targetNode >= 0 and target.targetNode < zone.n then
            direct = net.NodeTargetBinding(zone, target.targetNode + 1, target.x, target.y, "target_node_id")
        else
            local zones = zone and { zone } or {}
            if not zone then
                for _, id in ipairs(net.ZonesForPoint(target.x, target.y)) do
                    local loaded = net.LoadZone(id)
                    if loaded then zones[#zones + 1] = loaded end
                end
            end
            for _, candidate in ipairs(zones) do
                local i = net.TargetNodeAt(candidate, target.x, target.y, target.z, tolerance)
                if i then direct = net.NodeTargetBinding(candidate, i, target.x, target.y, "target_node"); break end
            end
        end
        if direct then candidates[1] = direct; own = true end
    end
    -- a dyn row (the dock model) has its own node or none: no "nearest node, roughly" for it; without a node the cells decide
    if matched and not target.dynNode then
        for _, binding in ipairs(net.NearestNodeBindings(zone, target.x, target.y, target.z, radius, tolerance)) do
            if not candidates[1] or binding.id ~= candidates[1].id then candidates[#candidates + 1] = binding end
        end
    end
    -- no node of its own and none at its height within the radius: the cells decide (user rule 11.11.2026), never "no target in the network"
    if #candidates == 0 then return nil end
    for _, binding in ipairs(candidates) do
        local how = binding.choice == "nearest_node" and "nearest_node" or binding.choice
        if not context.route then return NodeResult(nav, target, binding, nil, nil, radius, tolerance, how) end
        local path, cost = context.route(binding.id)
        if path then return NodeResult(nav, target, binding, path, cost, radius, tolerance, how) end
    end
    if matched and own then
        return { quality = "unroutable", noRouteFromStart = true, reason = WowVisionNavigationText("res_no_route_from_start"), targetNode = "none" }
    end
    return nil          -- no route to a node that is not the row's own (or of another navdata): the cells decide
end

-- The circle in which the route to a certified interaction has to END (taken from the row, no threshold of the resolver): the waiting
-- circle of a waiting point (manual_wait, waitingRadius), the capture circle of an activation area (walk_into_trigger,
-- activationCaptureRadius). nil: an ordinary target. Such a target is not resolved over the checked attachments of its cell (the
-- cheapest pair of start and target attachment): the waiting point lies exactly on a node, the arrival (Dock:WaitAreaReached, the capture
-- of the activation area) asks for the circle, and the activation proof asks for the node the target resolved to (target.nodeId).
-- A route that ended on another attachment of the cell, however much cheaper, would end beside the circle.
-- This function is the one place that says which targets end on their own node: a dyn target that carries a fixed physical node instead of a
-- circle (the planned dock model) is added here, and EndBindings then takes that node as the end.
function R.EndRadius(target)
    local C = WowVisionNavigationTargetCatalog
    if target.interactionMode == "manual_wait" and C.Finite(target.waitingRadius) and target.waitingRadius > 0 then
        return target.waitingRadius
    end
    if target.activationMode == "walk_into_trigger" and C.Finite(target.activationCaptureRadius) and target.activationCaptureRadius > 0 then
        return target.activationCaptureRadius
    end
    return nil
end

-- The end attachments of such a target: the field-mask choice first (the node target.nodeId names), then the others of the cell by
-- distance, but only those inside the circle of the row (the circle is measured from the target in the plane). Where the choice itself
-- lies outside (a navdata whose waiting point is not on its node) it stays the one end, as in the resolution without a route.
local function EndBindings(bindings, target, endRadius)
    local function inside(binding)
        return (binding.x - target.x) ^ 2 + (binding.y - target.y) ^ 2 <= endRadius ^ 2
    end
    local choice = bindings[1]
    if not choice then return {} end
    local list = { choice }
    if not inside(choice) then return list end
    for index = 2, #bindings do
        if inside(bindings[index]) then list[#list + 1] = bindings[index] end
    end
    return list
end

-- The height does not decide between the bands of a stage: an unknown height, the doubled tolerance (an approximation), or a known
-- height inside no band (the conflict of 4.41). A known height inside a band decides, also inside several overlapping bands (their
-- candidates all fit it; Ashenvale av480a, fishing spot 2803:-2656: z 208.8 in the bands 200.8-215.0 and 208.0-219.6 got a question).
local function PlayerDecides(bands, z, relaxed)
    if #bands < 2 then return false end
    if z == nil or relaxed then return true end
    for _, band in ipairs(bands) do
        if z >= band.zMin and z <= band.zMax then return false end
    end
    return true
end

function R:Resolve(nav, target, context)
    context = context or {}
    local valid, reason = WowVisionNavigationTargetCatalog.Validate(target)
    if not valid then return { quality = "unroutable", reason = reason } end
    if target.z == nil and type(target.levels) == "table" and #target.levels > 1 then
        return self:ResolveLevels(nav, target, context)
    end
    if target.expiresAt and type(GetTime) == "function" and target.expiresAt < GetTime() then
        return { quality = "stale", reason = WowVisionNavigationText("res_stale") }
    end
    if nav.nativeMapId == nil then return { quality = "unroutable", reason = WowVisionNavigationText("res_no_native_map") } end
    if nav.nativeMapId ~= target.nativeMapId then return { quality = "unroutable", reason = WowVisionNavigationText("res_other_map") } end
    local net = WowVisionNavigationNavNetwork
    local radius, tolerance = self:Settings()
    local byNode = self:ResolveTargetNode(nav, target, context, radius, tolerance)       -- Weg B: the fixed node of the target
    if byNode then return byNode end
    local endRadius = R.EndRadius(target)       -- a certified interaction ends in its own circle, not on the cheapest attachment of its cell
    local z = target.z
    local surface = target.surface
    local kinds = surface == "water" and { 2 } or (surface == "land" and { 1, 0 } or { 1, 0, 2 })
    local all = net.CellsWithin(target.x, target.y, radius, kinds)

    -- Stages: (1) cells that contain the point and fit the height, (2) cells within the radius that fit (the approach),
    -- (3) with a known height the same with twice the tolerance (provider heights are sometimes entity heights, not floor
    -- heights; the miss is an honest approximation). A stage only counts when a candidate of it can be routed, so an
    -- unreachable nearest cell never hides a valid farther one. Several height bands stay an explicit /vn ebene decision,
    -- but only where the player really has one (user rule 12.11.2026, Ashenvale av480a):
    --   * the question is the first stage whose bands the height does not decide (PlayerDecides) and in which a band can be
    --     routed; its bands are offered, and the answer (context.heightBand, with context.band the offered band itself) is
    --     evaluated over the candidates of that band only. Before, the index was applied to the bands of the first stage with
    --     candidates: one band there, so "/vn ebene 2" of a question of stage 2 said "height band invalid";
    --   * a band is selectable when one of its candidates can be routed from the start; with one selectable band there is no
    --     question, the route goes to it; with none the next stage is tried. Without a start (a list) every band counts.
    local function select(maxDistance, limit)
        local list = {}
        for _, candidate in ipairs(all) do
            if candidate.distance <= maxDistance and (z == nil or Fits(candidate, z, limit)) then
                list[#list + 1] = candidate
            end
        end
        return list
    end
    local stages = { { select(0, tolerance), false }, { select(radius, tolerance), false } }
    if z ~= nil then stages[3] = { select(radius, tolerance * 2), true } end
    local tested = false        -- context.route was asked (all start attachments were tried by it)

    -- The candidates of a stage or of one band, nearest first: -> candidate, binding, path, cost (nil: none can be routed).
    local function attempt(candidates)
        local list = {}
        for _, candidate in ipairs(candidates) do
            candidate.heightDifference = HeightDifference(candidate, z)
            list[#list + 1] = candidate
        end
        table.sort(list, function(a, b)
            if a.distance ~= b.distance then return a.distance < b.distance end
            if a.heightDifference ~= b.heightDifference then return a.heightDifference < b.heightDifference end
            if a.zone.id ~= b.zone.id then return a.zone.id < b.zone.id end
            return a.cell < b.cell
        end)
        for _, candidate in ipairs(list) do
            local bindings, pool
            if context.route then
                bindings = net.CellBindings(candidate.zone, candidate.cell, target.x, target.y, candidate.distance)
                if endRadius then
                    bindings = EndBindings(bindings, target, endRadius)         -- no pool: the route ends in the circle of the row
                else
                    pool = net.CertifiedBindings(candidate.zone, candidate.cell, target.x, target.y, candidate.distance)
                end
            else
                bindings = { net.BindCell(candidate.zone, candidate.cell, target.x, target.y, candidate.distance) }
            end
            -- the field-mask attachment first, with the other checked attachments of the cell in the cost comparison
            -- (the cheapest pair of start and target attachment wins); no route to it (a source, a dead end): the other
            -- attachments of the cell, one by one
            for index, binding in ipairs(bindings) do
                local path, cost, chosen
                if context.route then
                    tested = true
                    path, cost, chosen = context.route(binding.id, index == 1 and pool and #pool > 1 and pool or nil)
                end
                if not context.route or path then
                    if pool and chosen and chosen.id ~= binding.id then
                        for _, member in ipairs(pool) do
                            if member.id == chosen.id then binding = member; break end
                        end
                    end
                    return candidate, binding, path, cost
                end
            end
        end
        return nil
    end

    local function found(best, bestBinding, bestPath, bestCost, bands, zOutOfTolerance)
        local water = best.kind == 2
        local underWater = water and z ~= nil and z < best.zMin
        -- exact: the point lies in a cell and the height fits; an unknown height is only exact on water (2D cells)
        local exact = best.distance == 0 and not zOutOfTolerance and not underWater
            and ((z ~= nil and best.heightDifference <= tolerance) or (z == nil and water))
        local delta3D
        if z ~= nil and not water then
            delta3D = math.sqrt(best.distance * best.distance + best.heightDifference * best.heightDifference)
        end
        return {
            endNodeId = bestBinding.id, quality = exact and "exact" or "approximate",
            binding = bestBinding, cellDistance = best.distance, approach = best.distance > 0,
            deltaXY = best.distance, deltaZ = (z ~= nil and not water) and best.heightDifference or nil, delta3D = delta3D,
            zUnknown = z == nil, zOutOfTolerance = zOutOfTolerance, normalizedWater = underWater, queryZ = z,
            divingDepth = underWater and (best.zMax - z) or nil,
            endpointSurface = water and "water" or "land", targetSurface = surface,
            bands = bands, path = bestPath, cost = bestCost,
            graphRevision = nav.exportFingerprint, targetRevision = target.providerRevision,
            radius = radius, tolerance = tolerance,
        }
    end

    local function noRouteFromStart()
        return { quality = "unroutable", noRouteFromStart = true, reason = WowVisionNavigationText("res_no_route_from_start") }
    end

    -- The answer to a height question (/vn ebene <k>): band k of the question, evaluated over its own candidates only.
    if context.heightBand then
        local band = context.band           -- the band the question offered (TargetSelection keeps it with the question)
        if type(band) ~= "table" or band.level ~= nil or type(band.candidates) ~= "table" then
            -- a direct call without it: band k of the question this target gets with the same context
            local plain = {}
            for key, value in pairs(context) do plain[key] = value end
            plain.heightBand, plain.band = nil, nil
            local question = self:Resolve(nav, target, plain)
            if question.quality ~= "ambiguous" or not question.bands then return question end      -- no question (any more)
            band = question.bands[context.heightBand]
        end
        if not band then return { quality = "unroutable", reason = WowVisionNavigationText("res_band_invalid") } end
        local best, binding, path, cost = attempt(band.candidates)
        if best then
            local result = found(best, binding, path, cost, nil, band.relaxed == true)
            result.band = context.heightBand
            return result
        end
        if context.route then return noRouteFromStart() end
        return { quality = "unroutable", reason = WowVisionNavigationText("res_no_path") }
    end

    local question, undecided
    for stageIndex, stage in ipairs(stages) do
        local candidates, relaxed = stage[1], stage[2]
        if #candidates > 0 then
            local stageBands = self:HeightBands(candidates, tolerance)
            if PlayerDecides(stageBands, z, relaxed) then
                undecided = true
                for _, band in ipairs(stageBands) do band.stage, band.relaxed, band.selectable = stageIndex, relaxed, true end
                if not context.route then question = stageBands; break end       -- no start: every band can be chosen
                local reachable, only, onlyIndex = 0, nil, nil
                for index, band in ipairs(stageBands) do
                    local best, binding, path, cost = attempt(band.candidates)
                    band.selectable = best ~= nil
                    if best then
                        reachable = reachable + 1
                        if not only then only, onlyIndex = { best, binding, path, cost }, index end
                    end
                end
                if reachable == 1 then
                    -- one band to choose is no choice: the route goes to it
                    local result = found(only[1], only[2], only[3], only[4], stageBands, relaxed)
                    result.band = onlyIndex
                    return result
                end
                if reachable > 1 then question = stageBands; break end
                -- no band of this stage can be routed from the start: the next stage
            else
                local best, binding, path, cost = attempt(candidates)
                if best then return found(best, binding, path, cost, (#stageBands > 1) and stageBands or nil, relaxed) end
            end
        end
    end
    if question then
        return { quality = "ambiguous", bands = question, bandStage = question[1].stage, queryZ = z, zConflict = z ~= nil,
            reason = z == nil and WowVisionNavigationText("res_ambiguous") or WowVisionNavigationText("res_z_conflict") }
    end
    -- Since 4.41: when no candidate can be routed from the start (all start attachments were tried by context.route),
    -- there is no height question; the player hears that there is no network path from here.
    if context.route and (undecided or tested) then return noRouteFromStart() end
    if #all == 0 or (#stages[1][1] == 0 and #stages[2][1] == 0 and not (stages[3] and #stages[3][1] > 0)) then
        return { quality = "unroutable", reason = WowVisionNavigationText("res_no_point") }
    end
    return { quality = "unroutable", reason = WowVisionNavigationText("res_no_path") }
end
