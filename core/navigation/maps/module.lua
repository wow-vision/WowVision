local module = WowVision.base.navigation:createModule("maps")
local L = module.L
module:setLabel(L["Maps"])

module.datasets = WowVision.Registry:new()

-- Active beacon sound. Hardcoded for now; this will become a user setting once
-- beacon selection UI exists.
local BEACON_PATH = "Beacon/WowVision/probe_mid_1"

function module:getBeaconSource()
    if self._beaconSource == nil then
        self._beaconSource = WowVision.audio:getPath(BEACON_PATH) or false
    end
    if self._beaconSource == false then
        return nil
    end
    return self._beaconSource
end

function module:newDataset(key)
    local data = WowVision.Dataset:new()
    self.datasets:register(key, data)
    return data
end

function module:pathfind(path)
    self.beacon = nil
    self.path = path
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

    if not self:getBeaconSource() then
        WowVision:speak("Beacon sound not available")
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
