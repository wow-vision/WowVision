local quests = WowVision.quests
local L = WowVision:getLocale()

-- The native quest data source, for clients with the modern quest map
-- APIs (Retail, WoW: Forever, Mists when Questie is absent). It answers
-- the same questions as the Questie-backed adapter from what the game
-- itself draws on the world map:
--
--   available quests   C_QuestLine.GetAvailableQuestLines(map): the quest
--                      offer pins, already filtered by level and
--                      prerequisites server-side; asynchronous, requested
--                      per map and delivered by QUESTLINE_UPDATE
--   quests in progress the game's log, with the objective point from
--                      C_QuestLog.GetQuestsOnMap on the player's map,
--                      else the routed next waypoint toward the quest,
--                      else the point the world map draws on the quest's
--                      own map (another zone of the continent)
--
-- Places are one point per quest rather than spawn tables, so a target
-- here always has a single spawn, givers are unnamed ("Quest Giver" at a
-- place), and there is no NPC index: the scanner offers quest givers only.
-- Positions are map-percent like the Questie source, converted to world
-- coordinates through the map API (slightly offset from UnitPosition, as
-- every such conversion is).
local Native = WowVision.Class("NativeQuestAdapter")
quests.NativeAdapter = Native

function quests.nativeAvailable()
    return C_QuestLine ~= nil
        and C_QuestLine.GetAvailableQuestLines ~= nil
        and C_QuestLog ~= nil
        and C_QuestLog.GetQuestsOnMap ~= nil
end

function Native:initialize()
    self.backend = {
        placeName = function(mapId, x, y)
            return quests.places.placeName(mapId, x, y, nil, nil)
        end,
    }
    self._linesByMap = {}
    self._byQuest = {}
    self._requested = {}
    self._requestedAt = {}
    self._updated = {}
    self._pois = {}
    self._questMaps = nil
    self._worldCache = {}
end

function Native:isReady()
    return true
end

function Native:player()
    local x, y, _, continent = UnitPosition("player")
    return {
        x = x,
        y = y,
        continent = continent,
        mapId = C_Map.GetBestMapForUnit("player"),
        level = UnitLevel("player"),
    }
end

-- ---- positions ----

-- A spawn for normalized map coordinates, memoized per map.
function Native:_spawn(mapId, nx, ny)
    if mapId == nil or nx == nil or ny == nil then
        return nil
    end
    local byMap = self._worldCache[mapId]
    if byMap == nil then
        byMap = {}
        self._worldCache[mapId] = byMap
    end
    local key = math.floor(nx * 10000) * 10000 + math.floor(ny * 10000)
    local hit = byMap[key]
    if hit == false then
        return nil
    end
    if hit == nil then
        local continent, position = C_Map.GetWorldPosFromMapPos(mapId, CreateVector2D(nx, ny))
        if position == nil then
            byMap[key] = false
            return nil
        end
        local wx, wy = position:GetXY()
        hit = { mapId = mapId, x = nx * 100, y = ny * 100, wx = wx, wy = wy, continent = continent }
        byMap[key] = hit
    end
    -- Copies carry per-query distances.
    return { mapId = hit.mapId, x = hit.x, y = hit.y, wx = hit.wx, wy = hit.wy, continent = hit.continent }
end

local function stampDistance(spawn, ctx)
    if ctx == nil or ctx.x == nil or spawn.continent ~= ctx.continent then
        spawn.distance = nil
    else
        local dx, dy = ctx.x - spawn.wx, ctx.y - spawn.wy
        spawn.distance = math.sqrt(dx * dx + dy * dy)
    end
    return spawn
end

-- As the Adapter's rank: only a spawn on the player's continent is the
-- target's headline position (nearest); one on another continent has none.
local function singleTarget(kind, id, name, spawn, ctx)
    stampDistance(spawn, ctx)
    local nearest = spawn.distance ~= nil and spawn or nil
    return { kind = kind, id = id, name = name, spawns = { spawn }, nearest = nearest, distance = spawn.distance }
end

local function sortByDistance(list)
    table.sort(list, function(a, b)
        if a.distance == nil then
            return false
        end
        if b.distance == nil then
            return true
        end
        return a.distance < b.distance
    end)
    return list
end

local function cap(list, maxCount)
    if maxCount ~= nil then
        while #list > maxCount do
            tremove(list)
        end
    end
    return list
end

-- ---- quest lines: the available quests of a map ----

-- Ask the server once per map; QUESTLINE_UPDATE then refreshes the cache
-- (the module forwards it to onLinesUpdated).
function Native:requestLines(mapId)
    if mapId == nil or self._requested[mapId] then
        return
    end
    self._requested[mapId] = true
    self._requestedAt[mapId] = GetTime()
    pcall(C_QuestLine.RequestQuestLinesForMap, mapId)
end

function Native:onLinesUpdated(requestRequired)
    self._linesByMap = {}
    if requestRequired then
        self._requested = {}
    else
        for mapId in pairs(self._requested) do
            self._updated[mapId] = true
        end
    end
end

-- Seconds after a request before an unanswered map counts as empty (the
-- Forever server sometimes never answers).
local LINES_TIMEOUT = 5

function Native:linesReady(mapId)
    if mapId == nil then
        return false
    end
    if self._updated[mapId] == true or #self:_lines(mapId) > 0 then
        return true
    end
    if quests.seen:hasGivers() then
        return true
    end
    local requestedAt = self._requestedAt[mapId]
    return requestedAt ~= nil and GetTime() - requestedAt > LINES_TIMEOUT
end

function Native:_lines(mapId)
    local cached = self._linesByMap[mapId]
    if cached ~= nil then
        return cached
    end
    local ok, list = pcall(C_QuestLine.GetAvailableQuestLines, mapId)
    if not ok or type(list) ~= "table" then
        list = {}
    end
    self._linesByMap[mapId] = list
    for _, entry in ipairs(list) do
        entry.mapId = mapId
        self._byQuest[entry.questID] = entry
    end
    return list
end

local function positionKey(mapId, nx, ny)
    return tostring(mapId) .. ":" .. tostring(math.floor(nx * 1000)) .. ":" .. tostring(math.floor(ny * 1000))
end

function Native:_giverTarget(entry, ctx)
    local spawn = self:_spawn(entry.mapId, entry.x, entry.y)
    if spawn == nil then
        return nil
    end
    return singleTarget("giver", positionKey(entry.mapId, entry.x, entry.y), L["Quest Giver"], spawn, ctx)
end

local function call(fn, ...)
    if fn == nil then
        return nil
    end
    local ok, result = pcall(fn, ...)
    if ok then
        return result
    end
    return nil
end

-- Where the game itself marks a quest in the log, for any quest source:
-- its point on the player's map or a map above it (C_QuestLog.GetQuestsOnMap,
-- the zone first, then the continent), else the routed next step (the
-- portal or flight toward it), else the older QuestPOIGetIconInfo on the
-- player's map. Returns mapId, x, y in map percent (0 to 100), or nil.
function quests.gameQuestPoint(questId)
    if C_Map == nil or C_Map.GetBestMapForUnit == nil then
        return nil
    end
    local playerMap = call(C_Map.GetBestMapForUnit, "player")
    local mapId, visited = playerMap, {}
    for _ = 1, 8 do
        if mapId == nil or mapId <= 0 or visited[mapId] then
            break
        end
        visited[mapId] = true
        if C_QuestLog ~= nil and C_QuestLog.GetQuestsOnMap ~= nil then
            for _, info in ipairs(call(C_QuestLog.GetQuestsOnMap, mapId) or {}) do
                local x, y = info.x, info.y
                if info.questID == questId and x ~= nil and y ~= nil and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                    return mapId, x * 100, y * 100
                end
            end
        end
        local info = C_Map.GetMapInfo ~= nil and call(C_Map.GetMapInfo, mapId) or nil
        mapId = info ~= nil and info.parentMapID or nil
    end
    if C_QuestLog ~= nil and C_QuestLog.GetNextWaypointForMap ~= nil and playerMap ~= nil then
        local ok, x, y = pcall(C_QuestLog.GetNextWaypointForMap, questId, playerMap)
        if ok and x ~= nil and y ~= nil then
            return playerMap, x * 100, y * 100
        end
    end
    if C_QuestLog ~= nil and C_QuestLog.GetNextWaypoint ~= nil then
        local ok, wayMap, x, y = pcall(C_QuestLog.GetNextWaypoint, questId)
        if ok and wayMap ~= nil and x ~= nil and y ~= nil then
            return wayMap, x * 100, y * 100
        end
    end
    if QuestPOIGetIconInfo ~= nil and playerMap ~= nil then
        local ok, _, x, y = pcall(QuestPOIGetIconInfo, questId)
        if ok and x ~= nil and y ~= nil and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
            return playerMap, x * 100, y * 100
        end
    end
    return nil
end

-- opts: levelRange, includeRepeatable, maxCount (see Adapter:nearbyQuests).
function Native:nearbyQuests(opts)
    opts = opts or {}
    local result = {}
    local ctx = self:player()
    if ctx.x == nil or ctx.mapId == nil then
        return result
    end
    self:requestLines(ctx.mapId)
    local showHidden = call(C_Minimap ~= nil and C_Minimap.IsTrackingHiddenQuests or nil) == true
    local playerLevel = ctx.level or 0
    for _, entry in ipairs(self:_lines(ctx.mapId)) do
        local onQuest = entry.inProgress or call(C_QuestLog.IsOnQuest, entry.questID) == true
        local hidden = entry.isHidden and not showHidden
        if not onQuest and not hidden then
            local level = call(C_QuestLog.GetQuestDifficultyLevel, entry.questID)
            local repeatable = call(C_QuestLog.IsRepeatableQuest, entry.questID) == true or entry.isDaily == true
            local floorOk = opts.levelRange == nil
                or level == nil
                or level <= 0
                or level >= playerLevel - opts.levelRange
            local repeatableOk = opts.includeRepeatable == true or not repeatable
            if floorOk and repeatableOk then
                local starter = self:_giverTarget(entry, ctx)
                if starter ~= nil and starter.distance ~= nil then
                    tinsert(result, {
                        questId = entry.questID,
                        name = entry.questName,
                        level = level,
                        repeatable = repeatable,
                        daily = entry.isDaily == true,
                        starter = starter,
                        distance = starter.distance,
                    })
                end
            end
        end
    end
    self:_addSeenGivers(result, ctx)
    return cap(sortByDistance(result), opts.maxCount)
end

-- Quest givers seen this session (see seen.lua), for maps where the
-- server sends no quest offers; where it does, those already cover them
-- and would only be listed twice.
function Native:_addSeenGivers(result, ctx)
    if #self:_lines(ctx.mapId) > 0 then
        return
    end
    for _, giver in ipairs(quests.seen:givers()) do
        local spawn = { mapId = giver.mapId, x = giver.x, y = giver.y, wx = giver.wx, wy = giver.wy, continent = giver.continent }
        local starter = singleTarget("seenGiver", giver.guid, giver.name, spawn, ctx)
        starter.subName = giver.subName
        starter.onArrive = giver.onArrive
        tinsert(result, {
            seenGiver = true,
            name = giver.name,
            status = giver.status,
            flag = giver.flag,
            indoors = giver.indoors,
            starter = starter,
            distance = starter.distance,
        })
    end
end

-- ---- quests in progress ----

-- The quest points the game draws on a map, by quest id, cached per map
-- until invalidate (the module forwards QUEST_POI_UPDATE and log changes).
function Native:_questsOnMap(mapId)
    if mapId == nil then
        return {}
    end
    local cached = self._pois[mapId]
    if cached ~= nil then
        return cached
    end
    local byQuest = {}
    for _, info in ipairs(call(C_QuestLog.GetQuestsOnMap, mapId) or {}) do
        byQuest[info.questID] = info
    end
    self._pois[mapId] = byQuest
    return byQuest
end

local function mapInfo(mapId)
    return mapId ~= nil and call(C_Map.GetMapInfo, mapId) or nil
end

-- Whether the world map draws quest points on a map: Blizzard's own rule
-- (not on world, continent or cosmic maps).
local function mapShowsQuests(mapId)
    local info = mapInfo(mapId)
    return info ~= nil and MapUtil.ShouldMapTypeShowQuests(info.mapType) == true
end

-- The continent map above a map (or the map itself), as Blizzard finds it.
local function continentOf(mapId)
    if mapId == nil then
        return nil
    end
    local info = call(MapUtil.GetMapParentInfo, mapId, Enum.UIMapType.Continent)
    return info ~= nil and info.mapID or nil
end

-- The map the quest log opens for a quest (QuestMapFrame does the same
-- through this legacy global), or nil; 0 means none.
local function questUiMap(questId)
    if GetQuestUiMapID == nil then
        return nil
    end
    local ok, mapId = pcall(GetQuestUiMapID, questId)
    if ok and type(mapId) == "number" and mapId ~= 0 then
        return mapId
    end
    return nil
end

-- Quest id to the zone maps of the player's continent whose world map
-- draws a point for it, built once per invalidate (and again on another
-- continent), for clients without GetQuestUiMapID or quests it has no map
-- for. Map indicator entries are skipped like Blizzard's QuestDataProvider
-- does: they mark the way to the quest, not its area.
function Native:_continentQuestMaps(ctx)
    local continent = continentOf(ctx.mapId)
    local index = self._questMaps
    if index ~= nil and index.continent == continent then
        return index.byQuest
    end
    index = { continent = continent, byQuest = {} }
    self._questMaps = index
    if continent == nil or C_Map.GetMapChildrenInfo == nil then
        return index.byQuest
    end
    local ok, zones = pcall(C_Map.GetMapChildrenInfo, continent, Enum.UIMapType.Zone, true)
    if not ok or type(zones) ~= "table" then
        return index.byQuest
    end
    for _, zone in ipairs(zones) do
        for questId, poi in pairs(self:_questsOnMap(zone.mapID)) do
            if not poi.isMapIndicatorQuest then
                local maps = index.byQuest[questId]
                if maps == nil then
                    maps = {}
                    index.byQuest[questId] = maps
                end
                tinsert(maps, zone.mapID)
            end
        end
    end
    return index.byQuest
end

-- The nearest point the world map draws for a quest on the given maps,
-- preferring points on the player's continent; nil when none has one.
function Native:_pointOnMaps(questId, maps, ctx)
    local best = nil
    for _, mapId in ipairs(maps) do
        local poi = mapShowsQuests(mapId) and self:_questsOnMap(mapId)[questId] or nil
        if poi ~= nil and not poi.isMapIndicatorQuest then
            local spawn = self:_spawn(mapId, poi.x, poi.y)
            if spawn ~= nil then
                stampDistance(spawn, ctx)
                if best == nil
                    or (spawn.distance ~= nil and (best.distance == nil or spawn.distance < best.distance))
                then
                    best = spawn
                end
            end
        end
    end
    return best
end

-- The quest's point on its own map, for a quest whose area lies outside
-- the player's map: the map the quest log opens for it, else the zones of
-- the continent that draw it. Only points the world map shows; no guessed
-- places such as a zone's centre.
function Native:_questMapSpawn(questId, ctx)
    local own = questUiMap(questId)
    if own ~= nil and own ~= ctx.mapId then
        local spawn = self:_pointOnMaps(questId, { own }, ctx)
        if spawn ~= nil then
            return spawn
        end
    end
    local maps = self:_continentQuestMaps(ctx)[questId]
    if maps == nil then
        return nil
    end
    return self:_pointOnMaps(questId, maps, ctx)
end

-- Where a quest in the log sends you now: its point on the player's map,
-- else the routed next step toward it on this map, else the point on
-- whatever map holds it, else its point on its own map in another zone.
-- Named by the game's own travel text when it has one ("Travel to
-- Westfall"), else the quest title.
function Native:_questTarget(questId, ctx)
    local spawn = nil
    local poi = self:_questsOnMap(ctx.mapId)[questId]
    if poi ~= nil then
        spawn = self:_spawn(ctx.mapId, poi.x, poi.y)
    end
    if spawn == nil and C_QuestLog.GetNextWaypointForMap ~= nil and ctx.mapId ~= nil then
        local ok, x, y = pcall(C_QuestLog.GetNextWaypointForMap, questId, ctx.mapId)
        if ok and x ~= nil and y ~= nil then
            spawn = self:_spawn(ctx.mapId, x, y)
        end
    end
    if spawn == nil and C_QuestLog.GetNextWaypoint ~= nil then
        local ok, mapId, x, y = pcall(C_QuestLog.GetNextWaypoint, questId)
        if ok and mapId ~= nil and x ~= nil and y ~= nil then
            spawn = self:_spawn(mapId, x, y)
        end
    end
    if spawn == nil then
        spawn = self:_questMapSpawn(questId, ctx)
    end
    if spawn == nil then
        return nil
    end
    local name = call(C_QuestLog.GetNextWaypointText, questId)
    if name == nil or name == "" then
        name = call(C_QuestLog.GetTitleForQuestID, questId) or tostring(questId)
    end
    return singleTarget("quest", questId, name, spawn, ctx)
end

function Native:targets(questId, phase)
    local ctx = self:player()
    local target = nil
    if phase == "start" then
        local entry = self._byQuest[questId]
        if entry == nil and ctx.mapId ~= nil then
            self:_lines(ctx.mapId)
            entry = self._byQuest[questId]
        end
        if entry ~= nil then
            target = self:_giverTarget(entry, ctx)
        end
    else
        target = self:_questTarget(questId, ctx)
    end
    if target == nil then
        return {}
    end
    return { target }
end

function Native:objectiveTargets(questId, objectiveIndex)
    -- The game keeps one point per quest, not per objective.
    return self:targets(questId, "objectives")
end

function Native:inProgress()
    local result = {}
    for _, entry in ipairs(quests.gameQuestLog() or {}) do
        local objectives = {}
        for index, live in ipairs(entry.objectives or {}) do
            tinsert(objectives, {
                index = index,
                text = live.text,
                type = live.type,
                finished = live.finished == true,
                collected = live.collected,
                needed = live.needed,
            })
        end
        tinsert(result, {
            questId = entry.questId,
            title = entry.title,
            level = entry.level,
            zone = entry.zone,
            complete = entry.complete == true,
            failed = entry.failed == true,
            known = true,
            objectives = objectives,
        })
    end
    return result
end

function Native:quest(questId)
    local name = call(C_QuestLog.GetTitleForQuestID, questId)
    local entry = self._byQuest[questId]
    if name == nil and entry ~= nil then
        name = entry.questName
    end
    if name == nil then
        return nil
    end
    local objectivesText = {}
    for _, objective in ipairs(call(C_QuestLog.GetQuestObjectives, questId) or {}) do
        if objective.text ~= nil and objective.text ~= "" then
            tinsert(objectivesText, objective.text)
        end
    end
    return { id = questId, name = name, objectivesText = objectivesText }
end

-- Plain lines describing the raw state, for /wv quests raw [mapId]: the
-- map (the given one, else the player's best map) with its name, type
-- and parent, then the quest line count for it and each parent up the
-- chain (requesting any not yet requested, so a second run reads them).
function Native:debugLines(mapId)
    local ctx = self:player()
    mapId = mapId or ctx.mapId
    local lines = {}
    tinsert(lines, "Player map " .. tostring(ctx.mapId) .. ", continent " .. tostring(ctx.continent) .. ", position " .. tostring(ctx.x) .. " " .. tostring(ctx.y))
    local chain = {}
    local current = mapId
    while current ~= nil and #chain < 6 do
        tinsert(chain, current)
        local info = C_Map.GetMapInfo(current)
        current = info ~= nil and info.parentMapID or nil
        if current == 0 then
            current = nil
        end
    end
    for _, id in ipairs(chain) do
        local info = C_Map.GetMapInfo(id)
        self:requestLines(id)
        local list = self:_lines(id)
        tinsert(lines, string.format(
            "Map %s %s, type %s, parent %s, requested %s, updated %s, quest lines %d",
            tostring(id),
            tostring(info ~= nil and info.name or "?"),
            tostring(info ~= nil and info.mapType or "?"),
            tostring(info ~= nil and info.parentMapID or "?"),
            tostring(self._requested[id] == true),
            tostring(self._updated[id] == true),
            #list
        ))
        for i, entry in ipairs(list) do
            if i > 8 then
                tinsert(lines, "and more")
                break
            end
            local spawn = self:_spawn(entry.mapId, entry.x, entry.y)
            if spawn ~= nil then
                stampDistance(spawn, ctx)
            end
            tinsert(lines, string.format(
                "  %s, id %s, in progress %s, hidden %s, local story %s, start map %s, continent %s, distance %s",
                tostring(entry.questName),
                tostring(entry.questID),
                tostring(entry.inProgress),
                tostring(entry.isHidden),
                tostring(entry.isLocalStory),
                tostring(entry.startMapID),
                tostring(spawn ~= nil and spawn.continent or "none"),
                tostring(spawn ~= nil and spawn.distance or "none")
            ))
        end
    end
    local pois = self:_questsOnMap(ctx.mapId)
    local count = 0
    for _ in pairs(pois) do
        count = count + 1
    end
    tinsert(lines, "Quest points on player map " .. tostring(count))
    self:_debugLogLines(lines, ctx)
    return lines
end

local function mapLabel(mapId)
    local info = mapInfo(mapId)
    return tostring(mapId) .. " " .. tostring(info ~= nil and info.name or "?")
end

-- Per log quest: the map the quest log opens for it, whether the game
-- draws a point for it there and on the player's map, and where WowVision
-- sends you (map, continent, distance), so a check in game shows whether
-- points come back for maps the player is not on.
function Native:_debugLogLines(lines, ctx)
    local continent = continentOf(ctx.mapId)
    local index = self:_continentQuestMaps(ctx)
    local indexed = 0
    for _ in pairs(index) do
        indexed = indexed + 1
    end
    tinsert(lines, string.format(
        "Continent map %s, GetQuestUiMapID %s, quests with a point in its zones %d",
        continent ~= nil and mapLabel(continent) or "none",
        GetQuestUiMapID ~= nil and "present" or "missing",
        indexed
    ))
    for _, entry in ipairs(quests.gameQuestLog() or {}) do
        local questId = entry.questId
        local own = questUiMap(questId)
        local ownPoint = "no map"
        if own ~= nil then
            local poi = self:_questsOnMap(own)[questId]
            if poi == nil then
                ownPoint = "no point"
            elseif poi.isMapIndicatorQuest then
                ownPoint = "indicator only"
            else
                ownPoint = "point " .. string.format("%.1f %.1f", (poi.x or 0) * 100, (poi.y or 0) * 100)
            end
        end
        local maps = {}
        for _, mapId in ipairs(index[questId] or {}) do
            tinsert(maps, tostring(mapId))
        end
        local target = self:_questTarget(questId, ctx)
        local spawn = target ~= nil and (target.nearest or target.spawns[1]) or nil
        tinsert(lines, string.format(
            "  %s, id %s: quest map %s, %s; point on player map %s; zones with a point %s; target %s",
            tostring(entry.title),
            tostring(questId),
            own ~= nil and mapLabel(own) or "none",
            ownPoint,
            tostring(self:_questsOnMap(ctx.mapId)[questId] ~= nil),
            #maps > 0 and table.concat(maps, " ") or "none",
            spawn ~= nil and string.format(
                "map %s, continent %s, distance %s",
                tostring(spawn.mapId),
                tostring(spawn.continent),
                spawn.distance ~= nil and string.format("%d", spawn.distance) or "none"
            ) or "none"
        ))
    end
end

-- No NPC data: roles and explicit places are empty here.
function Native:npcsByRole()
    return {}
end

function Native:placeTargets()
    return {}
end

-- Forget the map's quest points and positions (a map change, a log
-- change); the quest lines refresh on their own event.
function Native:invalidate()
    self._pois = {}
    self._questMaps = nil
    self._worldCache = {}
end
