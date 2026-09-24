local module = WowVision.base.quests

-- /wv quests probe: one report of every quest and map point source the
-- client might offer, for finding out which of them actually return data
-- (written for WoW: Forever, where the native source comes back empty):
-- quest lines, task quests, the quest log's map points, super tracking,
-- then the map's own points (area POIs, flight points, dungeon entrances,
-- map links, vignettes) and every pin the open world map shows. Nothing here
-- changes game state: no RefreshAll on the world map, no quest watches, no
-- super tracking. The report opens in the copyable results window, a short
-- summary is spoken, and a copy goes to WowVisionDump.questProbe (on disk
-- after /reload, where SavedVariables work).
--
-- Quest lines are asynchronous, so the probe requests them, waits for
-- QUESTLINE_UPDATE (or WAIT_SECONDS), then reads everything in one pass.

local WAIT_SECONDS = 3
local MAX_ROWS = 8
local MAX_PER_SOURCE = 25
local MAX_LOG = 20

local function call(fn, ...)
    if fn == nil then
        return false, "missing"
    end
    return pcall(fn, ...)
end

local function namespaceFn(path)
    local node = _G
    for part in path:gmatch("[^%.]+") do
        if type(node) ~= "table" then
            return nil
        end
        node = node[part]
    end
    return node
end

local function pct(value)
    if type(value) ~= "number" then
        return tostring(value)
    end
    return string.format("%.1f", value * 100)
end

local function count(list)
    if type(list) ~= "table" then
        return tostring(list)
    end
    return tostring(#list)
end

local function flag(value)
    if value == nil then
        return "nil"
    end
    return value and "yes" or "no"
end

-- APIs the native source uses or could use, plus the legacy globals Questie
-- found missing on Forever.
local API_NAMES = {
    "C_QuestLine.RequestQuestLinesForMap",
    "C_QuestLine.GetAvailableQuestLines",
    "C_QuestLine.GetForceVisibleQuests",
    "C_QuestLine.GetQuestLineInfo",
    "C_QuestLog.GetQuestsOnMap",
    "C_QuestLog.IsOnMap",
    "C_QuestLog.GetDistanceSqToQuest",
    "C_QuestLog.GetNextWaypoint",
    "C_QuestLog.GetNextWaypointForMap",
    "C_QuestLog.GetNextWaypointText",
    "C_QuestLog.GetQuestAdditionalHighlights",
    "C_TaskQuest.GetQuestsOnMap",
    "C_TaskQuest.GetQuestLocation",
    "C_AreaPoiInfo.GetQuestHubsForMap",
    "C_AreaPoiInfo.GetAreaPOIForMap",
    "C_SuperTrack.GetSuperTrackedQuestID",
    "C_SuperTrack.GetHighestPrioritySuperTrackingType",
    "C_Navigation.GetDistance",
    "C_Navigation.GetTargetState",
    "C_Navigation.GetNextWaypointForMap",
    "C_Minimap.IsTrackingHiddenQuests",
    "C_Minimap.IsInsideQuestBlob",
    "C_QuestLog.UnitIsRelatedToActiveQuest",
    "C_TooltipInfo.GetUnit",
    "UnitIsQuestBoss",
    "MapUtil.ShouldMapTypeShowQuests",
    "QuestPOIGetIconInfo",
    "GetNumQuestLogEntries",
    "GetQuestLogTitle",
}

local function sectionClient(lines, mapId)
    local version, build, _, interface = GetBuildInfo()
    tinsert(lines, "== Client")
    tinsert(lines, string.format("version %s build %s interface %s", tostring(version), tostring(build), tostring(interface)))
    local info = mapId ~= nil and C_Map.GetMapInfo(mapId) or nil
    tinsert(
        lines,
        string.format(
            "player map %s %s, type %s, parent %s",
            tostring(mapId),
            info and info.name or "?",
            info and tostring(info.mapType) or "?",
            info and tostring(info.parentMapID) or "?"
        )
    )
    if info ~= nil and MapUtil ~= nil and MapUtil.ShouldMapTypeShowQuests ~= nil then
        local ok, show = call(MapUtil.ShouldMapTypeShowQuests, info.mapType)
        tinsert(lines, "map type shows quests: " .. (ok and flag(show) or tostring(show)))
    end
    local pos = mapId ~= nil and C_Map.GetPlayerMapPosition(mapId, "player") or nil
    local wx, wy, _, continent = UnitPosition("player")
    tinsert(
        lines,
        string.format(
            "position %s %s, world %s %s continent %s",
            pos and pct(pos.x) or "nil",
            pos and pct(pos.y) or "nil",
            tostring(wx),
            tostring(wy),
            tostring(continent)
        )
    )
    -- Only the native adapter fetches quest lines per map.
    local source = "none"
    if module.adapter ~= nil then
        source = module.adapter.requestLines ~= nil and "native" or "Questie"
    end
    tinsert(lines, "WowVision quest source: " .. source .. ", native available: " .. flag(WowVision.quests.nativeAvailable()))
end

local function sectionApis(lines)
    tinsert(lines, "== API presence")
    local missing = {}
    for _, name in ipairs(API_NAMES) do
        if namespaceFn(name) == nil then
            tinsert(missing, name)
        end
    end
    if #missing == 0 then
        tinsert(lines, "all " .. #API_NAMES .. " present")
    else
        tinsert(lines, #missing .. " of " .. #API_NAMES .. " missing: " .. table.concat(missing, ", "))
    end
end

local function describeLine(entry)
    return string.format(
        "  %s (%s) at %s %s, hidden %s, in progress %s, start map %s",
        tostring(entry.questName),
        tostring(entry.questID),
        pct(entry.x),
        pct(entry.y),
        flag(entry.isHidden),
        flag(entry.inProgress),
        tostring(entry.startMapID)
    )
end

local function sectionQuestLines(lines, mapIds, state)
    tinsert(lines, "== Available quest lines (quest offer pins)")
    tinsert(
        lines,
        string.format(
            "QUESTLINE_UPDATE fired %d times, last requestRequired %s, waited %.1f seconds",
            state.updates,
            tostring(state.lastRequestRequired),
            state.waited
        )
    )
    for _, mapId in ipairs(mapIds) do
        local before = state.before[mapId]
        local ok, list = call(C_QuestLine and C_QuestLine.GetAvailableQuestLines, mapId)
        tinsert(
            lines,
            string.format("map %s: before request %s, after %s", tostring(mapId), tostring(before), ok and count(list) or ("error " .. tostring(list)))
        )
        if ok and type(list) == "table" then
            for i = 1, math.min(#list, MAX_ROWS) do
                tinsert(lines, describeLine(list[i]))
            end
        end
        local okForce, forced = call(C_QuestLine and C_QuestLine.GetForceVisibleQuests, mapId)
        tinsert(lines, "map " .. tostring(mapId) .. " force visible quests: " .. (okForce and count(forced) or ("error " .. tostring(forced))))
        if okForce and type(forced) == "table" then
            for i = 1, math.min(#forced, MAX_ROWS) do
                local okInfo, info = call(C_QuestLine.GetQuestLineInfo, forced[i], mapId)
                if okInfo and info ~= nil then
                    tinsert(lines, describeLine(info))
                else
                    tinsert(lines, "  " .. tostring(forced[i]) .. " no quest line info")
                end
            end
        end
    end
end

local function sectionTasks(lines, mapIds)
    tinsert(lines, "== Task quests (bonus objectives, world quests)")
    for _, mapId in ipairs(mapIds) do
        local ok, list = call(C_TaskQuest and C_TaskQuest.GetQuestsOnMap, mapId)
        tinsert(lines, "map " .. tostring(mapId) .. ": " .. (ok and count(list) or ("error " .. tostring(list))))
        if ok and type(list) == "table" then
            for i = 1, math.min(#list, MAX_ROWS) do
                local info = list[i]
                local questId = info.questID or info.questId
                tinsert(
                    lines,
                    string.format(
                        "  %s %s at %s %s",
                        tostring(questId),
                        tostring(C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questId) or ""),
                        pct(info.x),
                        pct(info.y)
                    )
                )
            end
        end
        local okHubs, hubs = call(C_AreaPoiInfo and C_AreaPoiInfo.GetQuestHubsForMap, mapId)
        tinsert(lines, "map " .. tostring(mapId) .. " quest hubs " .. (okHubs and count(hubs) or tostring(hubs)))
    end
end

local function sectionQuestsOnMap(lines, mapIds)
    tinsert(lines, "== Quest log points drawn on the map (C_QuestLog.GetQuestsOnMap)")
    for _, mapId in ipairs(mapIds) do
        local ok, list = call(C_QuestLog.GetQuestsOnMap, mapId)
        tinsert(lines, "map " .. tostring(mapId) .. ": " .. (ok and count(list) or ("error " .. tostring(list))))
        if ok and type(list) == "table" then
            for i = 1, math.min(#list, MAX_ROWS) do
                local info = list[i]
                tinsert(
                    lines,
                    string.format(
                        "  %s at %s %s, type %s, indicator %s",
                        tostring(info.questID),
                        pct(info.x),
                        pct(info.y),
                        tostring(info.type),
                        flag(info.isMapIndicatorQuest)
                    )
                )
            end
        end
    end
end

local function sectionLog(lines, mapId)
    tinsert(lines, "== Quest log, per quest")
    local ok, total = call(C_QuestLog.GetNumQuestLogEntries)
    if not ok then
        tinsert(lines, "GetNumQuestLogEntries error " .. tostring(total))
        return
    end
    local shown = 0
    for index = 1, total or 0 do
        local okInfo, info = call(C_QuestLog.GetInfo, index)
        if okInfo and info ~= nil and not info.isHeader and shown < MAX_LOG then
            shown = shown + 1
            local questId = info.questID
            local okDone, done = call(C_QuestLog.IsComplete, questId)
            tinsert(lines, string.format("%s (%s), complete %s", tostring(info.title), tostring(questId), okDone and flag(done) or tostring(done)))
            local okOn, onMap, hasLocal = call(C_QuestLog.IsOnMap, questId)
            local okDist, distSq, onContinent = call(C_QuestLog.GetDistanceSqToQuest, questId)
            local distance = okDist and type(distSq) == "number" and string.format("%d yards", math.sqrt(distSq)) or tostring(distSq)
            tinsert(
                lines,
                string.format(
                    "  on map %s, local POI %s, distance %s, on continent %s, watched %s",
                    okOn and flag(onMap) or tostring(onMap),
                    okOn and flag(hasLocal) or "?",
                    distance,
                    okDist and flag(onContinent) or "?",
                    tostring(select(2, call(C_QuestLog.GetQuestWatchType, questId)))
                )
            )
            local okBlob, inside = call(C_Minimap and C_Minimap.IsInsideQuestBlob, questId)
            tinsert(lines, "  inside quest area: " .. (okBlob and flag(inside) or tostring(inside)))
            local okNext, nextMap, nx, ny = call(C_QuestLog.GetNextWaypoint, questId)
            local okForMap, fx, fy = call(C_QuestLog.GetNextWaypointForMap, questId, mapId)
            local okText, text = call(C_QuestLog.GetNextWaypointText, questId)
            tinsert(
                lines,
                string.format(
                    "  next waypoint %s, for this map %s, text %s",
                    okNext and string.format("map %s at %s %s", tostring(nextMap), pct(nx), pct(ny)) or tostring(nextMap),
                    okForMap and string.format("%s %s", pct(fx), pct(fy)) or tostring(fx),
                    okText and tostring(text) or tostring(text)
                )
            )
            if QuestPOIGetIconInfo ~= nil then
                local okIcon, completed, ix, iy, objective = call(QuestPOIGetIconInfo, questId)
                if okIcon then
                    tinsert(lines, string.format("  POI icon %s %s, objective %s, completed %s", pct(ix), pct(iy), tostring(objective), tostring(completed)))
                end
            end
        end
    end
    tinsert(lines, string.format("%d log entries, %d quests shown", total or 0, shown))
end

local function sectionTracking(lines, mapId)
    tinsert(lines, "== Super tracking and navigation")
    local _, questId = call(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
    local _, kind = call(C_SuperTrack and C_SuperTrack.GetHighestPrioritySuperTrackingType)
    tinsert(lines, "super tracked quest " .. tostring(questId) .. ", tracking type " .. tostring(kind))
    local _, distance = call(C_Navigation and C_Navigation.GetDistance)
    local _, navState = call(C_Navigation and C_Navigation.GetTargetState)
    local okNav, nx, ny, desc = call(C_Navigation and C_Navigation.GetNextWaypointForMap, mapId)
    tinsert(
        lines,
        string.format(
            "navigation distance %s, state %s, next waypoint %s",
            tostring(distance),
            tostring(navState),
            okNav and string.format("%s %s %s", pct(nx), pct(ny), tostring(desc)) or tostring(nx)
        )
    )
    local _, hidden = call(C_Minimap and C_Minimap.IsTrackingHiddenQuests)
    tinsert(lines, "minimap tracks hidden (low level) quests: " .. tostring(hidden))
end

local function pos(position)
    if position == nil then
        return "no position"
    end
    local ok, x, y = pcall(position.GetXY, position)
    if not ok or x == nil then
        return "bad position"
    end
    return string.format("%.1f %.1f", x * 100, y * 100)
end

local function addList(lines, title, ok, list, describe)
    if not ok then
        tinsert(lines, title .. ": ERROR " .. tostring(list))
        return
    end
    if type(list) ~= "table" then
        tinsert(lines, title .. ": " .. tostring(list))
        return
    end
    tinsert(lines, title .. ": " .. #list)
    for i = 1, math.min(#list, MAX_PER_SOURCE) do
        local okLine, line = pcall(describe, list[i])
        tinsert(lines, "  " .. (okLine and tostring(line) or ("ERR " .. tostring(line))))
    end
end

local function probeMap(lines, mapId)
    local info = C_Map.GetMapInfo(mapId)
    tinsert(lines, "")
    tinsert(
        lines,
        "== Map " .. mapId .. " " .. tostring(info and info.name) .. " type " .. tostring(info and info.mapType)
    )

    local ok, ids = call(C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap, mapId)
    addList(lines, "Area POIs", ok, ids, function(id)
        local poi = C_AreaPoiInfo.GetAreaPOIInfo(mapId, id)
        if poi == nil then
            return id .. " no info"
        end
        return string.format(
            "%s | %s | atlas %s | %s",
            tostring(poi.name),
            tostring(poi.description),
            tostring(poi.atlasName),
            pos(poi.position)
        )
    end)

    local okShow, show = call(C_TaxiMap and C_TaxiMap.ShouldMapShowTaxiNodes, mapId)
    tinsert(lines, "Map shows taxi nodes: " .. (okShow and tostring(show) or ("ERR " .. tostring(show))))
    ok, ids = call(C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap, mapId)
    addList(lines, "Flight points", ok, ids, function(node)
        return string.format(
            "%s | state %s | faction %s | undiscovered %s | %s",
            tostring(node.name),
            tostring(node.state),
            tostring(node.faction),
            tostring(node.isUndiscovered),
            pos(node.position)
        )
    end)

    ok, ids = call(C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap, mapId)
    addList(lines, "Dungeon entrances", ok, ids, function(entry)
        return string.format("%s | atlas %s | %s", tostring(entry.name), tostring(entry.atlasName), pos(entry.position))
    end)

    ok, ids = call(C_Map.GetMapLinksForMap, mapId)
    addList(lines, "Map links", ok, ids, function(link)
        return string.format("%s | to map %s | %s", tostring(link.name), tostring(link.linkedUiMapID), pos(link.position))
    end)

    ok, ids = call(C_DeathInfo and C_DeathInfo.GetGraveyardsForMap, mapId)
    addList(lines, "Graveyards", ok, ids, function(g)
        return string.format("%s | %s", tostring(g.name), pos(g.position))
    end)

    ok, ids = call(C_Map.GetMapChildrenInfo, mapId)
    addList(lines, "Child maps", ok, ids, function(child)
        return string.format("%s %s type %s", tostring(child.mapID), tostring(child.name), tostring(child.mapType))
    end)
end

local function probeVignettes(lines, mapId)
    local ok, guids = call(C_VignetteInfo and C_VignetteInfo.GetVignettes)
    addList(lines, "Vignettes (map " .. mapId .. ")", ok, guids, function(guid)
        local v = C_VignetteInfo.GetVignetteInfo(guid)
        if v == nil then
            return "no info"
        end
        local position = C_VignetteInfo.GetVignettePosition(guid, mapId)
        return string.format(
            "%s | atlas %s | type %s | onMinimap %s | onWorldMap %s | %s",
            tostring(v.name),
            tostring(v.atlasName),
            tostring(v.type),
            tostring(v.onMinimap),
            tostring(v.onWorldMap),
            pos(position)
        )
    end)
end

-- Every pin the open world map shows, grouped by template, with the first
-- few names found on the usual pin data fields.
local function pinName(pin)
    local candidates = {
        pin.name,
        pin.poiInfo and pin.poiInfo.name,
        pin.taxiNodeInfo and pin.taxiNodeInfo.name,
        pin.description,
        pin.questID and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(pin.questID),
        pin.unit and UnitName(pin.unit),
    }
    for i = 1, 6 do
        local value = candidates[i]
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    local keys = {}
    for key, value in pairs(pin) do
        local t = type(value)
        if type(key) == "string" and (t == "string" or t == "number" or t == "boolean") then
            tinsert(keys, key .. "=" .. tostring(value))
            if #keys >= 8 then
                break
            end
        end
    end
    return "unnamed {" .. table.concat(keys, ", ") .. "}"
end

local function probePins(lines)
    tinsert(lines, "")
    if WorldMapFrame == nil or not WorldMapFrame:IsShown() then
        tinsert(lines, "== World map pins: map closed (open it with M and run again)")
        return
    end
    tinsert(lines, "== World map pins, showing map " .. tostring(WorldMapFrame:GetMapID()))
    local templates = {}
    for template in pairs(WorldMapFrame.pinPools or {}) do
        tinsert(templates, template)
    end
    table.sort(templates)
    for _, template in ipairs(templates) do
        local pool = WorldMapFrame.pinPools[template]
        local names = {}
        local count = 0
        for pin in pool:EnumerateActive() do
            count = count + 1
            if #names < 8 then
                local ok, name = pcall(pinName, pin)
                local x, y = pin.normalizedX, pin.normalizedY
                local where = x and string.format(" @%.1f %.1f", x * 100, y * 100) or ""
                tinsert(names, (ok and name or "ERR") .. where)
            end
        end
        if count > 0 then
            tinsert(lines, template .. ": " .. count)
            for _, name in ipairs(names) do
                tinsert(lines, "  " .. name)
            end
        end
    end
end

local function sectionWowVision(lines)
    tinsert(lines, "== What WowVision's source makes of it")
    if not module:hasSource() then
        tinsert(lines, "no quest data source")
        return
    end
    local okNear, near = pcall(module.nearbyQuests, module, { maxCount = 50 })
    local okLog, log = pcall(module.inProgress, module)
    tinsert(lines, "nearby quests " .. (okNear and count(near) or tostring(near)) .. ", in progress " .. (okLog and count(log) or tostring(log)))
end

local function mapsToProbe(mapId)
    local list = { mapId }
    local info = mapId ~= nil and C_Map.GetMapInfo(mapId) or nil
    if info ~= nil and info.parentMapID ~= nil and info.parentMapID ~= 0 then
        tinsert(list, info.parentMapID)
    end
    return list
end

local probeFrame = nil

function module:runProbe()
    local mapId = C_Map.GetBestMapForUnit("player")
    local mapIds = mapsToProbe(mapId)
    local state = { updates = 0, before = {}, waited = 0, started = GetTime() }
    for _, id in ipairs(mapIds) do
        local ok, list = call(C_QuestLine and C_QuestLine.GetAvailableQuestLines, id)
        state.before[id] = ok and count(list) or "error"
    end

    local finished = false
    local function finish()
        if finished then
            return
        end
        finished = true
        probeFrame:UnregisterEvent("QUESTLINE_UPDATE")
        state.waited = GetTime() - state.started
        local lines = { "WowVision quest probe " .. date("%Y-%m-%d %H:%M:%S") }
        local sections = {
            function()
                sectionClient(lines, mapId)
            end,
            function()
                sectionApis(lines)
            end,
            function()
                sectionQuestLines(lines, mapIds, state)
            end,
            function()
                sectionTasks(lines, mapIds)
            end,
            function()
                sectionQuestsOnMap(lines, mapIds)
            end,
            function()
                sectionLog(lines, mapId)
            end,
            function()
                sectionTracking(lines, mapId)
            end,
            function()
                for _, id in ipairs(mapIds) do
                    probeMap(lines, id)
                end
            end,
            function()
                if mapId ~= nil then
                    probeVignettes(lines, mapId)
                end
            end,
            function()
                probePins(lines)
            end,
            function()
                sectionWowVision(lines)
            end,
        }
        -- One broken section must not hide the rest of the report.
        for _, section in ipairs(sections) do
            local ok, err = pcall(section)
            if not ok then
                tinsert(lines, "section error: " .. tostring(err))
            end
        end
        local text = table.concat(lines, "\n")
        WowVisionDump = WowVisionDump or {}
        WowVisionDump.questProbe = lines
        WowVision.testing.showResults(text)
        local okLines, available = call(C_QuestLine and C_QuestLine.GetAvailableQuestLines, mapId)
        local okPoints, points = call(C_QuestLog.GetQuestsOnMap, mapId)
        WowVision:speak(
            string.format(
                "Quest probe done. Quest lines %s, log points %s. Report is in the results window.",
                okLines and count(available) or "error",
                okPoints and count(points) or "error"
            )
        )
    end

    if probeFrame == nil then
        probeFrame = CreateFrame("Frame")
    end
    probeFrame:SetScript("OnEvent", function(_, _, requestRequired)
        state.updates = state.updates + 1
        state.lastRequestRequired = requestRequired
        if requestRequired then
            for _, id in ipairs(mapIds) do
                call(C_QuestLine.RequestQuestLinesForMap, id)
            end
        end
    end)
    probeFrame:RegisterEvent("QUESTLINE_UPDATE")
    for _, id in ipairs(mapIds) do
        call(C_QuestLine and C_QuestLine.RequestQuestLinesForMap, id)
    end
    WowVision:speak("Quest probe running, " .. WAIT_SECONDS .. " seconds")
    C_Timer.After(WAIT_SECONDS, finish)
end
