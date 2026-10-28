-- WowNav engine by Broesel33 (github.com/Broesel33/WoW_NavigationData, DemoAddon/WowVisionNavigation/TargetResolver.lua at
-- 5b8b5f2), carried in WowVision with his permission. Changes for WowVision: see camelot/wownav/engine/README.md.

-- Runtime attachment of targets to the network (schema 7, chapter 7 point 3). A target is bound to the attachment cell
-- above its position; a target outside every cell is bound to the nearest cell within 30 yd and marked as an
-- "approach". Stacked cells are separated into height bands; without a known height the player chooses (/vn ebene).
-- A target with certified levels (4.54, ``levels``) asks for its level the same way.
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
-- has no network path from the current start.
function R:ResolveLevels(nav, target, context)
    local levels = target.levels
    local function atLevel(h)
        local copy = {}
        for key, value in pairs(target) do copy[key] = value end
        copy.levels, copy.z, copy.zStatus = nil, h, "known"
        local plain = {}
        for key, value in pairs(context) do plain[key] = value end
        plain.heightBand = nil
        return self:Resolve(nav, copy, plain)
    end
    if context.heightBand then
        local h = levels[context.heightBand]
        if not h then return { quality = "unroutable", reason = WowVisionNavigationText("res_band_invalid") } end
        local result = atLevel(h)
        result.level = context.heightBand
        return result
    end
    local bands = {}
    for i, h in ipairs(levels) do
        local band = { zMin = h, zMax = h, candidates = {}, nearest = 0, level = i }
        if context.route then
            local result = atLevel(h)
            if result.binding then
                band.candidates[1] = result.binding
                band.nearest = result.cellDistance or 0
            end
        end
        bands[i] = band
    end
    return { quality = "ambiguous", bands = bands, levelUnknown = true, queryZ = nil, zConflict = false,
        reason = WowVisionNavigationText("res_level_unknown") }
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
    local z = target.z
    local surface = target.surface
    local kinds = surface == "water" and { 2 } or (surface == "land" and { 1, 0 } or { 1, 0, 2 })
    local all = net.CellsWithin(target.x, target.y, radius, kinds)

    -- Stages: (1) cells that contain the point and fit the height, (2) cells within the radius that fit (the approach),
    -- (3) with a known height the same with twice the tolerance (provider heights are sometimes entity heights, not floor
    -- heights; the miss is an honest approximation). A stage only counts when a candidate of it can be routed, so an
    -- unreachable nearest cell never hides a valid farther one. Several height bands stay an explicit /vn ebene decision.
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
    local best, bestBinding, bestPath, bestCost, bands, zOutOfTolerance, ambiguous, tested
    for _, stage in ipairs(stages) do
        local candidates = stage[1]
        if #candidates > 0 then
            local stageBands = self:HeightBands(candidates, tolerance)
            local decided = true
            if #stageBands > 1 and not context.heightBand then
                -- unknown height, or no band contains the height: the player decides
                local containing = 0
                for _, band in ipairs(stageBands) do
                    if z ~= nil and z >= band.zMin and z <= band.zMax then containing = containing + 1 end
                end
                if z == nil or stage[2] or containing ~= 1 then
                    ambiguous = ambiguous or { bands = stageBands, relaxed = stage[2] }
                    decided = false
                end
            end
            if decided then
                if context.heightBand then
                    local band = stageBands[context.heightBand]
                    if not band then return { quality = "unroutable", reason = WowVisionNavigationText("res_band_invalid") } end
                    candidates = band.candidates
                end
                for _, candidate in ipairs(candidates) do candidate.heightDifference = HeightDifference(candidate, z) end
                table.sort(candidates, function(a, b)
                    if a.distance ~= b.distance then return a.distance < b.distance end
                    if a.heightDifference ~= b.heightDifference then return a.heightDifference < b.heightDifference end
                    if a.zone.id ~= b.zone.id then return a.zone.id < b.zone.id end
                    return a.cell < b.cell
                end)
                for _, candidate in ipairs(candidates) do
                    local bindings
                    if context.route then
                        bindings = net.CellBindings(candidate.zone, candidate.cell, target.x, target.y, candidate.distance)
                    else
                        bindings = { net.BindCell(candidate.zone, candidate.cell, target.x, target.y, candidate.distance) }
                    end
                    -- the field-mask attachment first; no route to it (a source, a dead end): the other attachments of the cell
                    for _, binding in ipairs(bindings) do
                        local path, cost
                        if context.route then tested = true; path, cost = context.route(binding.id) end
                        if not context.route or path then
                            best, bestBinding, bestPath, bestCost = candidate, binding, path, cost
                            bands, zOutOfTolerance = (#stageBands > 1) and stageBands or nil, stage[2]
                            break
                        end
                    end
                    if best then break end
                end
                if best then break end
            end
        end
    end
    if not best then
        -- Since 4.41: when no candidate can be routed from the start (all start attachments were tried by context.route),
        -- there is no height question; the player hears that there is no network path from here.
        if context.route and (ambiguous or tested) then
            local any = false
            if ambiguous then
                for _, band in ipairs(ambiguous.bands) do
                    for _, candidate in ipairs(band.candidates) do
                        local binding = net.BindCell(candidate.zone, candidate.cell, target.x, target.y, candidate.distance)
                        if binding and context.route(binding.id) then any = true; break end
                    end
                    if any then break end
                end
            end
            if not any then
                return { quality = "unroutable", noRouteFromStart = true,
                    reason = WowVisionNavigationText("res_no_route_from_start") }
            end
        end
        if ambiguous then
            return { quality = "ambiguous", bands = ambiguous.bands, queryZ = z, zConflict = z ~= nil,
                reason = z == nil and WowVisionNavigationText("res_ambiguous")
                    or WowVisionNavigationText("res_z_conflict") }
        end
        if #all == 0 or (#stages[1][1] == 0 and #stages[2][1] == 0 and not (stages[3] and #stages[3][1] > 0)) then
            return { quality = "unroutable", reason = WowVisionNavigationText("res_no_point") }
        end
        return { quality = "unroutable", reason = WowVisionNavigationText("res_no_path") }
    end

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
