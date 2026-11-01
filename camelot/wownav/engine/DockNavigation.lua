-- WowNav engine by Broesel33 (github.com/Broesel33/WoW_NavigationData, DemoAddon/WowVisionNavigation/DockNavigation.lua at
-- 5b8b5f2), carried in WowVision with his permission. Changes for WowVision: see camelot/wownav/engine/README.md.

-- Passive waiting-point mode with a fixed boarding orientation point. Audio and the XY arrival signal run only in the
-- core OnUpdate; there is no vehicle detection.
local Dock = { reached = nil, passive = nil, generation = 0 }
WowVisionNavigationDockNavigation = Dock
local function targetList(nav)
    return _G.WowVisionNavigationTargetList
        and WowVisionNavigationTargetList(nav, function(target) return target.type == "transit_facility" end, true)
        or {}
end

local function finite(value)
    return type(value) == "number" and value == value
        and math.abs(value) < math.huge
end

local function validTarget(target, nav)
    if not nav or nav.packageLayoutVersion ~= 3 or (not WowVisionNavigationTargetCatalog
        or not WowVisionNavigationTargetCatalog:CertifiedInteraction(nav,target or {})) then return false end
    if type(nav) ~= "table" or nav.waitpoint_schema ~= 1
        or type(nav.waitpointFingerprint) ~= "string"
        or nav.waitpointFingerprint == ""
        or type(nav.exportFingerprint) ~= "string"
        or nav.exportFingerprint == "" or type(target) ~= "table"
        or target.type ~= "transit_facility"
        or target.interactionMode ~= "manual_wait"
        or target.activationMode ~= nil
        or target.facilityRole ~= "waiting"
        or type(target.id) ~= "string" or type(target.waitpointProofId) ~= "string"
        or not finite(target.nativeMapId)
        or type(target.transportRouteId) ~= "string"
        or type(target.transportStopId) ~= "string"
        or not finite(target.waitingRadius) or target.waitingRadius <= 0
        or target.waitingRadius > 2 or not finite(target.x)
        or not finite(target.y) or not finite(target.z) then
        return false
    end
    if target.boardingHintStatus == "certified" then
        local dx, dy = target.boardingDirX, target.boardingDirY
        local length = finite(dx) and finite(dy)
            and math.sqrt(dx * dx + dy * dy) or 0
        if length < 0.99 or length > 1.01
            or not finite(target.boardingPreviewDistance)
            or target.boardingPreviewDistance <= 0 then return false end
    elseif target.boardingHintStatus ~= "unavailable" then
        return false
    end
    return true
end

function Dock:IsDock(target, nav)
    return validTarget(target, nav or _G.NavData)
end

function Dock:Reset(passiveRetained)
    self.reached = nil
    if not passiveRetained then self.passive = nil end
    self.generation = self.generation + 1
end

function Dock:Arrival(target, nav, x, y)
    if not validTarget(target, nav) then return false end
    if self.reached and self.reached.id == target.id
        and self.reached.navFingerprint == nav.exportFingerprint then return false end
    self:Reset(false)
    self.reached = { id = target.id, zoneId = nav.zoneId,
                      navFingerprint = nav.exportFingerprint,
                      waitpointFingerprint = nav.waitpointFingerprint,
                      lastX = finite(x) and x or nil, lastY = finite(y) and y or nil }
    local vehicle = WowVisionNavigationText(({tram = "vehicle_tram", boat = "vehicle_boat",
                     zeppelin = "vehicle_zeppelin", lift = "vehicle_lift"})[target.facilityKind]
        or "vehicle_other")
    local text = WowVisionNavigationText("dock_reached", WowVisionNavigationTargetName(target), vehicle)
    if target.boardingHintStatus == "certified" then
        text = text .. WowVisionNavigationText("dock_boarding_hint")
    end
    WowVisionNavigationPrint(text)
    return true
end

function Dock:ChoosePassive(target, nav, targetFingerprint)
    if type(target) ~= "table" or target.interactionMode ~= "manual_wait"
        or type(target.id) ~= "string"
        or type(target.transportRouteId) ~= "string"
        or type(targetFingerprint) ~= "string" or targetFingerprint == ""
        or not self.reached or not nav
        or self.reached.navFingerprint ~= nav.exportFingerprint then
        return false
    end
    local start
    for _, localTarget in ipairs(targetList(nav)) do
        if localTarget.id == self.reached.id then start = localTarget; break end
    end
    if not validTarget(start, nav)
        or start.transportRouteId ~= target.transportRouteId
        or start.id == target.id then return false end
    local targetZone = target.zoneId or nav.zoneId
    if type(targetZone) ~= "number" then return false end
    self.passive = { id = target.id, zoneId = targetZone,
                    navFingerprint = targetFingerprint,
                    transportRouteId = target.transportRouteId }
    self.reached = nil
    self.generation = self.generation + 1
    WowVisionNavigationPrint(WowVisionNavigationText("dock_passive_set", WowVisionNavigationTargetName(target)))
    return true
end

function Dock:ZoneLoaded(nav)
    self.reached = nil
    self.generation = self.generation + 1
    if self.passive and (not nav or nav.zoneId ~= self.passive.zoneId
        or nav.exportFingerprint ~= self.passive.navFingerprint) then
        -- Another zone may carry the order, but a loaded target zone with a different package discards it.
        if nav and nav.zoneId == self.passive.zoneId then self.passive = nil end
    elseif self.passive and nav then
        local found = false
        for _, target in ipairs(targetList(nav)) do
            if target.id == self.passive.id and validTarget(target, nav)
                and target.transportRouteId == self.passive.transportRouteId then
                found = true
                break
            end
        end
        if not found then self.passive = nil end
    end
end

local function playerMap()
    if type(UnitPosition) ~= "function" then return nil end
    local ok, _, _, _, map = pcall(UnitPosition, "player")
    if not ok or (issecretvalue and issecretvalue(map))
        or not finite(map) then return nil end
    return map
end

-- The foot finish and the direction mode must use the same proven area.
function Dock:WaitAreaReached(target, x, y, nav)
    if not finite(x) or not finite(y) or not validTarget(target, nav)
        or playerMap() ~= target.nativeMapId then return false end
    return (x - target.x) ^ 2 + (y - target.y) ^ 2 <= target.waitingRadius ^ 2
end

-- Name key of the boarding point: "Am Schiff" for a boat, "Am Zeppelin" for a zeppelin, otherwise "Am Fahrzeug".
local function BoardingNameKey(target)
    local kind = target.facilityKind
    if kind == "boat" or kind == "zeppelin" then return "boarding_" .. kind end
    return "boarding_vehicle"
end

-- Fixed orientation point from the dock and the proven direction, no boarding proof.
function Dock:BoardingTarget(target, nav)
    if target and target.reachable and target.boardingHintStatus == "certified"
        and validTarget(target, nav) and playerMap() == target.nativeMapId then
        -- the search finds the boarding point by its German and by its English words
        local aliases = {"Einsteigrichtung", "Einsteigpunkt", "Orientierungspunkt", "Am Schiff", "Am Zeppelin",
                         "boarding direction", "boarding point", "orientation point", "On the ship", "On the zeppelin",
                         "Am Fahrzeug", "In der Bahn", "At the vehicle", "On the tram"}
        for _, alias in ipairs(target.searchAliases or {}) do aliases[#aliases + 1] = alias end
        return {
                id = "dock-boarding:" .. target.id, boardingTargetId = target.id,
                -- 4.53: the point is named after the vessel ("Am Schiff"), localized through Localization.lua (dyn.boarding_*)
                nameKey = BoardingNameKey(target),
                nameDe = "Einsteigpunkt: " .. target.nameDe,
                nameEn = "Boarding orientation point: " .. (target.nameEn or target.nameDe),
                category = { "orientation" }, reachable = true,
                searchAliases = aliases, nodeId = target.nodeId,
                x = target.x + target.boardingDirX * target.boardingPreviewDistance,
                y = target.y + target.boardingDirY * target.boardingPreviewDistance, z = target.z,
                arrivalRadius = math.min(0.35, target.boardingPreviewDistance * 0.25),
                navFingerprint = nav.exportFingerprint,
                waitpointFingerprint = nav.waitpointFingerprint,
        }
    end
end

function Dock:BoardingTargets(x, y, nav)
    local list = {}
    for _, target in ipairs(targetList(nav)) do
        local entry = self:BoardingTarget(target, nav)
        if entry then list[#list + 1] = entry end
    end
    return list
end

function Dock:DirectTargetValid(direct, nav)
    if not nav or direct.navFingerprint ~= nav.exportFingerprint
        or direct.waitpointFingerprint ~= nav.waitpointFingerprint then return false end
    for _, target in ipairs(targetList(nav)) do
        if target.id == direct.boardingTargetId then
            local current = self:BoardingTarget(target, nav)
            return current ~= nil and current.x == direct.x and current.y == direct.y
                and current.arrivalRadius == direct.arrivalRadius
        end
    end
    return false
end

-- The small capture disc may be passed between two real position updates. A map or proof change is discarded before
-- this purely geometric test.
function Dock:PointReached(context, px, py, x, y, radius)
    local ax, ay = context.lastX, context.lastY
    context.lastX, context.lastY = x, y
    if (x - px) ^ 2 + (y - py) ^ 2 <= radius ^ 2 then return true end
    if not finite(ax) or not finite(ay) then return false end
    local dx, dy = x - ax, y - ay
    local length2 = dx * dx + dy * dy
    if length2 < 0.0001 then return false end
    local t = math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / length2))
    return (ax + t * dx - px) ^ 2 + (ay + t * dy - py) ^ 2 <= radius ^ 2
end

function Dock:AlignmentTarget(x, y, nav)
    if not finite(x) or not finite(y)
        or type(nav) ~= "table" then return nil end
    local context = self.reached or self.passive
    if not context or context.zoneId ~= nav.zoneId
        or context.navFingerprint ~= nav.exportFingerprint
        or (context.waitpointFingerprint
            and context.waitpointFingerprint ~= nav.waitpointFingerprint) then return nil end
    local target
    for _, candidate in ipairs(targetList(nav)) do
        if candidate.id == context.id then target = candidate; break end
    end
    if not validTarget(target, nav) or playerMap() ~= target.nativeMapId then return nil end
    local dx, dy = x - target.x, y - target.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if self.passive then
        -- This is an explicit I request near the stop target. There is no automatic stop detection and no height anchor.
        if distance > 30 then return nil end
        return "dock-passive:" .. target.id, target.x, target.y
    end
    if distance > target.waitingRadius + (target.boardingPreviewDistance or 0)
        or target.boardingHintStatus ~= "certified" then
        return nil
    end
    local preview = target.boardingPreviewDistance
    return "dock-boarding:" .. target.id,
        target.x + target.boardingDirX * preview,
        target.y + target.boardingDirY * preview
end

-- The same resolver as for I, but only for the source dock that was reached. The passive counterpart dock never gets a
-- ride beacon. The short orientation point may still be reached after the waiting circle was left. This is free
-- orientation, not a certified foot route.
function Dock:BeaconTarget(x, y, nav)
    if not self.reached then return nil end
    local id, px, py = self:AlignmentTarget(x, y, nav)
    if not id or not finite(px) or not finite(py) then
        self:Reset(false)
        return nil
    end
    local target
    for _, candidate in ipairs(targetList(nav)) do
        if candidate.id == self.reached.id then target = candidate; break end
    end
    local radius = math.min(0.35, target.boardingPreviewDistance * 0.25)
    if self:PointReached(self.reached, px, py, x, y, radius) then
        self:Reset(false)
        return id, px, py, WowVisionNavigationTargetName(target)
    end
    return id, px, py
end
