local L = WowVision:getLocale()

local MapDataset = WowVision.Class("MapDataset")

MapDataset:addFields({
    { key = "key", type = "String", required = true, once = true, label = L["Key"] },
    { key = "label", type = "String", persist = true, label = L["Label"] },
    { key = "gameVersion", type = "String", label = L["Game Version"] },
    { key = "enabled", type = "Bool", default = true, persist = true, label = L["Enabled"] },
})

function MapDataset:initialize(config)
    self.waypoints = {}                 -- id -> waypoint table
    self.waypointsByMap = {}            -- mapId -> { [id] = waypoint }
    self.waypointsByContinent = {}      -- continentId -> { [id] = waypoint }
    self.pendingReverse = {}            -- missing target id -> { sourceId, ... }
    self.events = {
        waypointsAdded = WowVision.Event:new("waypointsAdded"),
    }
    self:applyFields(config)
end

-- Bulk-add waypoints. Each waypoint is a plain table:
-- { id = "uuid", x = 100.5, y = 200.5, mapId = 1453, cId = 0, n = "Name", r = "role",
--   t = 2, links = { [id1] = true, [id2] = 1 } }
--
-- LINK VALUES: `true` means BIDIRECTIONAL -- the data ships each two-way
-- link once and the reverse edge is materialized here at load. `1` means
-- genuinely one-way (cliff jumps, transport exits): no reverse is added.
-- The router treats every key as an outgoing edge, so after this pass the
-- runtime graph is simply directed.
--
-- Data arrives in per-map chunks and links cross chunk boundaries, so
-- reverses whose target has not loaded yet wait in a pending queue keyed by
-- the missing id, applied the moment that waypoint arrives.
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

        -- Materialize reverse edges for this waypoint's bidirectional links
        if wp.links then
            for targetId, kind in pairs(wp.links) do
                if kind == true then
                    local target = self.waypoints[targetId]
                    if target then
                        if not target.links then
                            target.links = {}
                        end
                        if target.links[wp.id] == nil then
                            target.links[wp.id] = 1
                        end
                    else
                        local pending = self.pendingReverse[targetId]
                        if not pending then
                            pending = {}
                            self.pendingReverse[targetId] = pending
                        end
                        tinsert(pending, wp.id)
                    end
                end
            end
        end

        -- Apply reverses queued by earlier chunks that link to this waypoint
        local pending = self.pendingReverse[wp.id]
        if pending then
            self.pendingReverse[wp.id] = nil
            if not wp.links then
                wp.links = {}
            end
            for _, sourceId in ipairs(pending) do
                if wp.links[sourceId] == nil then
                    wp.links[sourceId] = 1
                end
            end
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
