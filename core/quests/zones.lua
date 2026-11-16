-- The scanner's In Progress list, one level per quest log zone (the
-- headers of the quest log: Elwynn Forest, Westfall, a class or a
-- profession), each zone's quests nearest first.
--
--   WowVision.quests.zoneGroups(entries, makeNode, distanceOf)
--     -> { { key, label, detail, children = { node, ... } }, ... }
--
-- entries: the quest log (each with .zone, the header above it, or nil);
-- makeNode(entry) -> the quest's scanner node; distanceOf(node) -> yards to
-- the place the node points at, or nil. Zones keep the quest log's order;
-- within a zone the nearest quest comes first, quests without a place
-- follow in log order. Plain Lua (tests call it directly).
WowVision.quests = WowVision.quests or {}

local L = WowVision:getLocale()

function WowVision.quests.zoneKey(zone)
    return "zone:" .. tostring(zone or "")
end

function WowVision.quests.zoneGroups(entries, makeNode, distanceOf)
    local zones, byKey = {}, {}
    for _, entry in ipairs(entries or {}) do
        local key = WowVision.quests.zoneKey(entry.zone)
        local zone = byKey[key]
        if zone == nil then
            local label = entry.zone
            if type(label) ~= "string" or label == "" then
                label = L["Unknown"]
            end
            zone = { key = key, label = label, children = {} }
            byKey[key] = zone
            tinsert(zones, zone)
        end
        tinsert(zone.children, makeNode(entry))
    end
    for _, zone in ipairs(zones) do
        local ranked = {}
        for index, node in ipairs(zone.children) do
            local ok, distance = pcall(distanceOf, node)
            if not ok or type(distance) ~= "number" then
                distance = nil
            end
            ranked[index] = { node = node, index = index, distance = distance }
        end
        table.sort(ranked, function(a, b)
            if a.distance ~= nil and b.distance ~= nil and a.distance ~= b.distance then
                return a.distance < b.distance
            end
            if (a.distance == nil) ~= (b.distance == nil) then
                return a.distance ~= nil
            end
            return a.index < b.index
        end)
        for index, item in ipairs(ranked) do
            zone.children[index] = item.node
        end
        zone.detail = tostring(#zone.children) .. " " .. L["quests"]
    end
    return zones
end
