local L = WowVision:getLocale()

local MapDataset = WowVision.Class("MapDataset"):include(WowVision.InfoClass)

MapDataset.info:addFields({
    { key = "key", type = "String", required = true, once = true, label = L["Key"] },
    { key = "label", type = "String", persist = true, label = L["Label"] },
    { key = "gameVersion", type = "String", label = L["Game Version"] },
    { key = "enabled", type = "Bool", default = true, persist = true, label = L["Enabled"] },
})

function MapDataset:initialize(config)
    self.waypoints = {}                 -- id -> waypoint table
    self.waypointsByMap = {}            -- mapId -> { [id] = waypoint }
    self.waypointsByContinent = {}      -- continentId -> { [id] = waypoint }
    self.events = {
        waypointsAdded = WowVision.Event:new("waypointsAdded"),
    }
    self:setInfo(config)
end

-- Bulk-add waypoints. Each waypoint is a plain table:
-- { id = "uuid", x = 100.5, y = 200.5, mapId = 1453, cId = 0, n = "Name", r = "role",
--   t = 2, links = { [id1] = true, [id2] = true } }
function MapDataset:addWaypoints(waypoints)
    for i = 1, #waypoints do
        local wp = waypoints[i]
        self.waypoints[wp.id] = wp
        if wp.mapId then
            local bucket = self.waypointsByMap[wp.mapId]
            if not bucket then
                bucket = {}
                self.waypointsByMap[wp.mapId] = bucket
            end
            bucket[wp.id] = wp
        end
        if wp.cId then
            local bucket = self.waypointsByContinent[wp.cId]
            if not bucket then
                bucket = {}
                self.waypointsByContinent[wp.cId] = bucket
            end
            bucket[wp.id] = wp
        end
    end
    self.events.waypointsAdded:emit(self, #waypoints)
end

function MapDataset:getWaypoint(id)
    return self.waypoints[id]
end

function MapDataset:getWaypointsByMap(mapId)
    return self.waypointsByMap[mapId] or {}
end

function MapDataset:getWaypointsByContinent(continentId)
    return self.waypointsByContinent[continentId] or {}
end

function MapDataset:getWaypointCount()
    local count = 0
    for _ in pairs(self.waypoints) do
        count = count + 1
    end
    return count
end

WowVision.MapDataset = MapDataset
