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

-- Route to a waypoint through the link graph and follow it with the beacon.
function module:navigateTo(waypointId, waypoints)
    local px, py = UnitPosition("player")
    if px == nil then
        WowVision:speak(L["Position unavailable"])
        return false
    end
    waypoints = waypoints or self:currentWaypoints()
    local route, reason = WowVision.Router.route(waypoints, px, py, waypointId)
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

-- /beacon            -> report current position (and active beacon bearing)
-- /beacon x y        -> drop a beacon at world coords (x, y) and start guiding
-- /beacon stop       -> clear the active beacon
function module:handleBeaconCommand(args)
    args = args and strtrim(args) or ""

    if args == "" then
        local px, py = UnitPosition("player")
        if not px then
            WowVision:speak("Position unavailable")
            return
        end
        WowVision:speak(string.format("Position x %.1f y %.1f", px, py))
        if self.path and self.path.beacon then
            local distance, relative = self.path.beacon:compute()
            if distance then
                WowVision:speak(string.format("Beacon %.0f yards, %.0f degrees", distance, relative))
            end
        end
        return
    end

    if args:lower() == "stop" then
        self:stopPath()
        WowVision:speak("Beacon stopped")
        return
    end

    local x, y = args:match("^(-?%d+%.?%d*)%s+(-?%d+%.?%d*)$")
    x, y = tonumber(x), tonumber(y)
    if not x or not y then
        WowVision:speak("Usage beacon x y")
        return
    end

    local path = self.Path:new()
    path:add({ x = x, y = y })
    path.events.complete:subscribe(self, function()
        self.path = nil
        WowVision:speak("Arrived")
    end)
    self:pathfind(path)
    WowVision:speak("Beacon set")
end

module:registerCommand({
    name = "beacon",
    scope = "Global",
    description = "Set a navigation beacon. Usage: /beacon x y, /beacon stop, or /beacon for current position.",
    func = function(args)
        module:handleBeaconCommand(args)
    end,
})

function module:onEnable()
    self:hasUpdate(function(self)
        self:updatePath()
    end)
end
