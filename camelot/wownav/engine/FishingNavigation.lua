-- WowNav engine by Broesel33 (github.com/Broesel33/WoW_NavigationData, DemoAddon/WowVisionNavigation/FishingNavigation.lua
-- at 2661280), carried in WowVision with his permission. Changes for WowVision: see camelot/wownav/engine/README.md.

-- Fishing spots (dyn layer, kind "fishing_spot"). The data row holds only the standing point, the proven direction to the water
-- (fishingDirX/Y) and the preview distance (middle of the cast range). The water point is computed here: standing point +
-- direction * preview distance. It is orientation only: never a list entry and never a walking target (the navigation must not
-- send anybody into the water). Key I turns to it (WowVisionNavigationAlignmentTarget), and after the arrival a direction
-- tone sounds from it (core OnUpdate, FishingNavigation:BeaconTarget) until the player leaves the place. The tone is not
-- bound to "reaching" the water point: nobody walks there.
local Fishing = { reached = nil, generation = 0 }
WowVisionNavigationFishingNavigation = Fishing

local function finite(value)
    return (not issecretvalue or not issecretvalue(value)) and type(value) == "number" and value == value
        and math.abs(value) < math.huge
end

local function round(value)
    return math.floor(value + 0.5)
end

-- The row contract (kind fishing_spot): position, unit direction to the water, preview distance and the cast range.
local function validSpot(target)
    if type(target) ~= "table" or target.kind ~= "fishing_spot" or type(target.id) ~= "string" or target.id == ""
        or not finite(target.x) or not finite(target.y) or not finite(target.nativeMapId)
        or not finite(target.fishingDirX) or not finite(target.fishingDirY) then
        return false
    end
    local length = math.sqrt(target.fishingDirX * target.fishingDirX + target.fishingDirY * target.fishingDirY)
    if length < 0.99 or length > 1.01 then return false end
    if not finite(target.fishingPreviewDistance) or target.fishingPreviewDistance <= 0 then return false end
    return finite(target.fishingCastMin) and finite(target.fishingCastMax)
        and target.fishingCastMin > 0 and target.fishingCastMax >= target.fishingCastMin
end

local function waterPoint(target)
    return target.x + target.fishingDirX * target.fishingPreviewDistance,
        target.y + target.fishingDirY * target.fishingPreviewDistance
end

function Fishing:IsSpot(target)
    return validSpot(target)
end

-- The valid fishing spot with this ID from the dyn catalog of the active zones (the same lookup as for the docks), or nil.
function Fishing:Find(nav, id)
    if type(id) ~= "string" or type(_G.WowVisionNavigationTargetList) ~= "function" then return nil end
    for _, candidate in ipairs(WowVisionNavigationTargetList(nav, function(target) return target.id == id end, true)) do
        if candidate.id == id and validSpot(candidate) then return candidate end
    end
    return nil
end

function Fishing:Reset()
    self.reached = nil
    self.generation = self.generation + 1
end

function Fishing:ZoneLoaded()
    self:Reset()
end

-- Text keys of the sectors in which the water can lie, seen from the player: 1 = ahead, then counter-clockwise in 45-degree steps
-- (the numbering of the core's SectorFromAngle; world angle and GetPlayerFacing share one system). Listed statically, so that
-- every key is a literal of the code.
local SECTOR_KEYS = { "fishing_sector_1", "fishing_sector_2", "fishing_sector_3", "fishing_sector_4",
                      "fishing_sector_5", "fishing_sector_6", "fishing_sector_7", "fishing_sector_8" }

-- nil without a usable facing
local function sectorKey(x, y, targetX, targetY)
    if type(GetPlayerFacing) ~= "function" then return nil end
    local ok, facing = pcall(GetPlayerFacing)
    if not ok or not finite(facing) then return nil end
    local size = math.pi / 4
    local diff = (math.atan2(targetY - y, targetX - x) - facing) % (2 * math.pi)
    return SECTOR_KEYS[math.floor((diff + size / 2) / size) % 8 + 1]
end

-- Arrival at a fishing spot (the core calls it after it stopped the route). radius = the arrival radius of the core for a target
-- position. The place of the spot is the disc around its standing point with the larger of that radius and the maximum cast range
-- of the row (the spots of one water lie at least twice that range apart, so the places never overlap). The arrival fires 1.5 yd
-- before the point while the player still runs at about 7 yd/s: a place of only the arrival radius ended the context before
-- the announcement was spoken. Returns false if the row is not a valid fishing spot (the core then says the normal arrival text).
function Fishing:Arrival(target, nav, x, y, radius)
    if not validSpot(target) or type(nav) ~= "table" or not finite(x) or not finite(y)
        or not finite(radius) or radius <= 0 then
        return false
    end
    self:Reset()
    local waterX, waterY = waterPoint(target)
    self.reached = { id = target.id, zoneId = nav.zoneId, navFingerprint = nav.exportFingerprint,
                     originX = target.x, originY = target.y, radius = math.max(radius, target.fishingCastMax),
                     waterX = waterX, waterY = waterY }
    local name = WowVisionNavigationTargetName(target)
    local castMin, castMax = round(target.fishingCastMin), round(target.fishingCastMax)
    local sector = sectorKey(x, y, waterX, waterY)
    if sector then
        WowVisionNavigationPrint(WowVisionNavigationText("fishing_arrival", name, WowVisionNavigationText(sector),
            castMin, castMax))
    else
        WowVisionNavigationPrint(WowVisionNavigationText("fishing_arrival_no_facing", name, castMin, castMax))
    end
    return true
end

-- Key I: the water point of the spot that was reached, as long as the player is on the place (the disc of Arrival). Never offered as a target.
function Fishing:AlignmentTarget(x, y, nav)
    local context = self.reached
    if not context or not finite(x) or not finite(y) or type(nav) ~= "table"
        or context.zoneId ~= nav.zoneId or context.navFingerprint ~= nav.exportFingerprint then
        return nil
    end
    if (x - context.originX) ^ 2 + (y - context.originY) ^ 2 > context.radius ^ 2 then return nil end
    return "fishing-water:" .. context.id, context.waterX, context.waterY
end

-- The direction tone of the core. It ends when the player leaves the place (more than the place radius from the standing point),
-- when the zone context changes, and through the core's resets (a new target, /vn stop, ...). Unlike the dock
-- beacon it never ends because the point was "reached": it returns no name, so the core keeps sounding it.
function Fishing:BeaconTarget(x, y, nav)
    if not self.reached then return nil end
    local id, pointX, pointY = self:AlignmentTarget(x, y, nav)
    if not id then
        self:Reset()
        return nil
    end
    return id, pointX, pointY
end
