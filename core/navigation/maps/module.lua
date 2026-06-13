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
