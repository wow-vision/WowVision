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
--                      else the routed next waypoint toward the quest
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
    self._pois = nil
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

local function singleTarget(kind, id, name, spawn, ctx)
    stampDistance(spawn, ctx)
    return { kind = kind, id = id, name = name, spawns = { spawn }, nearest = spawn, distance = spawn.distance }
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

-- The quest points the game draws on a map, by quest id. Cached until
-- invalidate (the module forwards QUEST_POI_UPDATE and log changes).
function Native:_questsOnMap(mapId)
    if self._pois ~= nil and self._pois.mapId == mapId then
        return self._pois.byQuest
    end
    local byQuest = {}
    local list = mapId ~= nil and call(C_QuestLog.GetQuestsOnMap, mapId) or nil
    for _, info in ipairs(list or {}) do
        byQuest[info.questID] = info
    end
    self._pois = { mapId = mapId, byQuest = byQuest }
    return byQuest
end

-- Where a quest in the log sends you now: its point on the player's map,
-- else the routed next step toward it on this map, else the point on
-- whatever map holds it. Named by the game's own travel text when it has
-- one ("Travel to Westfall"), else the quest title.
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
    return lines
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
    self._pois = nil
    self._worldCache = {}
end
