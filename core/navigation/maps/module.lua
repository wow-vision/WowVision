local module = WowVision.base.navigation:createModule("maps")
local L = module.L
module:setLabel(L["Maps"])
local settings = module:hasSettings()

module.datasets = WowVision.Registry:new()

-- All beacon feedback lives under one alert whose outputs are action-scoped:
-- Beacon.lua fires module:fireAlert("beacon", { action = ... }) and only the
-- output matching that action plays. Each output keeps its own enable + sound,
-- so every cue stays independently configurable under a single settings group.
local beaconAlert = module:addAlert({ key = "beacon", label = L["Beacon"] })
beaconAlert:addOutput({
    type = "Beacon",
    key = "beacon",
    action = "tick",
    label = L["Beacon Sound"],
    beacon = "WowVision/probe_mid_1",
})
beaconAlert:addOutput({
    type = "Sound",
    key = "aligned",
    action = "aligned",
    label = L["Beacon Aligned"],
    path = "Sound/WowVision/alerts/clack.mp3",
})
beaconAlert:addOutput({
    type = "Sound",
    key = "unaligned",
    action = "unaligned",
    label = L["Beacon Off Course"],
    path = "Sound/WowVision/alerts/click.mp3",
})
beaconAlert:addOutput({
    type = "Sound",
    key = "arrived",
    action = "arrived",
    label = L["Waypoint Reached"],
    path = "Sound/WowVision/alerts/success2.mp3",
})

settings:addRef("beacon", beaconAlert.parameters)

function module:newDataset(key)
    local data = WowVision.Dataset:new()
    self.datasets:register(key, data)
    return data
end

-- All waypoints on the player's continent from enabled atlas datasets,
-- merged into one id -> waypoint map for the router. World coordinates are
-- continent-wide, so routes can leave the current zone.
function module:currentWaypoints()
    local _, _, _, instanceId = UnitPosition("player")
    local merged = {}
    WowVision.atlas:forEachEnabledDataset(function(dataset)
        local bucket = dataset.waypointsByContinent[instanceId]
        if bucket ~= nil then
            for id, wp in pairs(bucket) do
                merged[id] = wp
            end
        end
    end)
    return merged
end

-- Route to the nearest waypoint whose name contains the fragment
-- (case-insensitive): the test path for routed navigation before the
-- destination picker exists.
function module:navigateToName(fragment)
    local px, py = UnitPosition("player")
    if px == nil then
        WowVision:speak(L["Position unavailable"])
        return false
    end
    local waypoints = self:currentWaypoints()
    local needle = fragment:lower()
    local matches = WowVision.Router.nearest(waypoints, px, py, 1, function(wp)
        return wp.n ~= nil and wp.n:lower():find(needle, 1, true) ~= nil
    end)
    if #matches == 0 then
        WowVision:speak(L["No route found"] .. " " .. fragment)
        return false
    end
    local target = matches[1].waypoint
    WowVision:speak(target.n)
    return self:navigateTo(target.id, waypoints)
end

-- Straight-line beacon to a world position (no routing).
function module:beaconTo(wx, wy, label)
    local px, py = UnitPosition("player")
    local path = self.Path:new()
    path:add({ x = wx, y = wy, n = label })
    path.events.complete:subscribe(self, function()
        self.path = nil
        WowVision:speak(L["Arrived"])
    end)
    self:pathfind(path)
    if px ~= nil then
        local dx, dy = wx - px, wy - py
        local distance = math.sqrt(dx * dx + dy * dy)
        WowVision:speak(string.format("%s %d %s", L["Beacon set"], distance, L["yards"]))
    else
        WowVision:speak(L["Beacon set"])
    end
end

-- Map-percentage coordinates ("50.5 30.4") on the current zone map, the
-- numbers quest guides use: converted to a world position, then a straight
-- beacon. GetWorldPosFromMapPos returns coordinates in UnitPosition's
-- convention, which is exactly what Beacon consumes.
function module:beaconToMapCoords(xPercent, yPercent)
    local mapId = C_Map.GetBestMapForUnit("player")
    if mapId == nil then
        WowVision:speak(L["Position unavailable"])
        return false
    end
    local _, worldPos = C_Map.GetWorldPosFromMapPos(mapId, CreateVector2D(xPercent / 100, yPercent / 100))
    if worldPos == nil then
        WowVision:speak(L["Position unavailable"])
        return false
    end
    local wx, wy = worldPos:GetXY()
    self:beaconTo(wx, wy, string.format("%.1f %.1f", xPercent, yPercent))
    return true
end

-- Route to a waypoint through the link graph and follow it with the beacon.
-- opts passes through to the router (entryId for a user-chosen entry point).
function module:navigateTo(waypointId, waypoints, opts)
    local px, py = UnitPosition("player")
    if px == nil then
        WowVision:speak(L["Position unavailable"])
        return false
    end
    waypoints = waypoints or self:currentWaypoints()
    local route, reason = WowVision.Router.route(waypoints, px, py, waypointId, opts)
    if route == nil then
        WowVision:speak(L["No route found"] .. " " .. tostring(reason))
        return false
    end
    local path = self.Path:new()
    for _, wp in ipairs(route.waypoints) do
        path:add(wp)
    end
    path.events.complete:subscribe(self, function()
        self.path = nil
        local last = route.waypoints[#route.waypoints]
        WowVision:speak(L["Arrived"] .. (last.n ~= nil and (" " .. last.n) or ""))
    end)
    self:pathfind(path)
    WowVision:speak(string.format("%d %s, %d %s", #route.waypoints, L["waypoints"], route.distance, L["yards"]))
    return true
end

function module:pathfind(path)
    self.beacon = nil
    self.path = path
    path.events.arriveAtWaypoint:subscribe(self, function()
        module:fireAlert("beacon", { action = "arrived" })
    end)
    self.path:start()
end

function module:stopPath()
    self.path = nil
    self.beacon = nil
end

function module:updatePath()
    if self.path then
        self.path:update()
    end
end

-- /beacon            -> report current map position (and active beacon bearing)
-- /beacon x y        -> beacon to MAP coordinates on the current zone map
--                       ("50.5 30.4", the numbers quest guides use)
-- /beacon world x y  -> beacon to raw world coordinates
-- /beacon stop       -> clear the active beacon
function module:handleBeaconCommand(args)
    args = args and strtrim(args) or ""

    if args == "" then
        local px, py = UnitPosition("player")
        if not px then
            WowVision:speak(L["Position unavailable"])
            return
        end
        local mapId = C_Map.GetBestMapForUnit("player")
        local mapPos = mapId ~= nil and C_Map.GetPlayerMapPosition(mapId, "player") or nil
        if mapPos ~= nil then
            local mx, my = mapPos:GetXY()
            WowVision:speak(string.format("%.1f %.1f", mx * 100, my * 100))
        else
            WowVision:speak(string.format("Position x %.1f y %.1f", px, py))
        end
        if self.path and self.path.beacon then
            local distance, relative = self.path.beacon:compute()
            if distance then
                WowVision:speak(string.format("Beacon %.0f %s, %.0f degrees", distance, L["yards"], relative))
            end
        end
        return
    end

    local fragment = args:match("^[Tt]o%s+(.+)$")
    if fragment ~= nil then
        self:navigateToName(fragment)
        return
    end

    if args:lower() == "stop" then
        self:stopPath()
        WowVision:speak(L["Beacon stopped"])
        return
    end

    local worldX, worldY = args:match("^[Ww]orld%s+(-?%d+%.?%d*)%s+(-?%d+%.?%d*)$")
    worldX, worldY = tonumber(worldX), tonumber(worldY)
    if worldX ~= nil and worldY ~= nil then
        self:beaconTo(worldX, worldY)
        return
    end

    local x, y = args:match("^(-?%d+%.?%d*)%s+(-?%d+%.?%d*)$")
    x, y = tonumber(x), tonumber(y)
    if not x or not y then
        WowVision:speak("Usage beacon x y")
        return
    end
    self:beaconToMapCoords(x, y)
end

module:registerCommand({
    name = "beacon",
    scope = "Global",
    description = "Set a navigation beacon. Usage: /beacon x y (map coordinates), /beacon to name, /beacon world x y, /beacon stop, or /beacon for current position.",
    func = function(args)
        module:handleBeaconCommand(args)
    end,
})

function module:onEnable()
    self:hasUpdate(function(self)
        self:updatePath()
    end)
end
