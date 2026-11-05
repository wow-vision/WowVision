-- The Questie backend for the quest adapter: the ONE place that knows
-- Questie's internal module names and field shapes. Questie's stable public
-- surface is tiny (Questie.API: isReady, RegisterOnReady,
-- RegisterForQuestUpdates); the database itself is reached through its
-- module loader, so a Questie rename costs this file only.
--
-- Facts that shape this file: Questie compiles its tables into binary
-- strings at login and NILS the raw tables afterwards, so only the query
-- handles work, and only once Questie.API.isReady is true. Names come out
-- already localized. Spawns are map-percent coordinates keyed by area id;
-- -1 marks an unknown position.
local quests = WowVision.quests

local function importModule(name)
    if QuestieLoader == nil or QuestieLoader.ImportModule == nil then
        return nil
    end
    return QuestieLoader:ImportModule(name)
end

-- Nil when Questie is not loaded; the module then reports Questie missing.
function quests.questieBackend()
    if Questie == nil or Questie.API == nil then
        return nil
    end
    local QuestieDB = importModule("QuestieDB")
    local ZoneDB = importModule("ZoneDB")
    local AvailableQuests = importModule("AvailableQuests")
    local Phasing = importModule("Phasing")
    if QuestieDB == nil or ZoneDB == nil then
        return nil
    end

    local backend = {}

    -- Spawns carry an optional phase id (their third value). Questie hides
    -- spawns the character's story progress phases out (the Tillers' farm,
    -- Hyjal, the goblin and worgen starts); so do we, or a beacon lands on
    -- an NPC that does not exist for this character.
    function backend.spawnVisible(phase)
        if phase == nil or phase == 0 then
            return true
        end
        if Phasing == nil or Phasing.IsSpawnVisible == nil then
            return true
        end
        local ok, visible = pcall(Phasing.IsSpawnVisible, phase)
        return not ok or visible ~= false
    end

    function backend.isReady()
        return Questie.API.isReady == true and QuestieDB.QueryQuest ~= nil
    end

    function backend.onReady(fn)
        if Questie.API.RegisterOnReady ~= nil then
            Questie.API.RegisterOnReady(fn)
        elseif backend.isReady() then
            fn()
        end
    end

    function backend.onQuestUpdate(fn)
        if Questie.API.RegisterForQuestUpdates ~= nil then
            Questie.API.RegisterForQuestUpdates(fn)
        end
    end

    local function idList(value)
        if type(value) ~= "table" then
            return nil
        end
        return value
    end

    function backend.quest(id)
        local ok, q = pcall(QuestieDB.GetQuest, id)
        if not ok or q == nil then
            return nil
        end
        local objectives = {}
        for _, data in ipairs(q.ObjectiveData or {}) do
            tinsert(objectives, {
                type = data.Type,
                id = data.Id,
                text = data.Text,
                idList = data.IdList,
                rootId = data.RootId,
                itemId = data.ItemId,
            })
        end
        local starts = q.Starts or {}
        local finisher = q.Finisher or {}
        return {
            id = id,
            name = q.name,
            level = q.level or q.questLevel,
            requiredLevel = q.requiredLevel,
            repeatable = q.IsRepeatable == true,
            daily = type(q.questFlags) == "number" and bit.band(q.questFlags, 4096) ~= 0,
            starts = { npc = idList(starts.NPC), object = idList(starts.GameObject), item = idList(starts.Item) },
            finishers = { npc = idList(finisher.NPC), object = idList(finisher.GameObject) },
            objectives = objectives,
            objectivesText = q.objectivesText,
            triggerEnd = q.triggerEnd,
            zone = q.zoneOrSort,
            nextInChain = q.nextQuestInChain,
        }
    end

    -- The markers Questie draws for one objective of a quest in the log
    -- (index = quest log order): the fixed coordinates of an exploration or
    -- event objective (ObjectiveData[i].Coordinates), and the spawn list
    -- Questie built for the live objective (Objectives[i].spawnList, its
    -- creatures, objects and item sources). The adapter's last resort when
    -- the database names nothing to walk to and the game marks nothing
    -- either; nil when Questie has no marker.
    function backend.questMarkers(id, objectiveIndex)
        local ok, q = pcall(QuestieDB.GetQuest, id)
        if not ok or q == nil or objectiveIndex == nil then
            return nil
        end
        -- the same point often stands in several lists (an objective's
        -- coordinates and its spawn list, two creatures of one kill credit)
        local spawns, name, found, seen = {}, nil, false, {}
        local function add(byArea)
            if type(byArea) ~= "table" then
                return
            end
            for areaId, list in pairs(byArea) do
                if type(list) == "table" then
                    local into = spawns[areaId] or {}
                    spawns[areaId] = into
                    for _, pair in pairs(list) do
                        local key = type(pair) == "table"
                            and (tostring(areaId) .. ":" .. tostring(pair[1]) .. ":" .. tostring(pair[2]))
                        if key and not seen[key] then
                            seen[key] = true
                            tinsert(into, pair)
                            found = true
                        end
                    end
                end
            end
        end
        local data = type(q.ObjectiveData) == "table" and q.ObjectiveData[objectiveIndex] or nil
        if type(data) == "table" then
            add(data.Coordinates)
        end
        local live = type(q.Objectives) == "table" and q.Objectives[objectiveIndex] or nil
        if type(live) == "table" and type(live.spawnList) == "table" then
            for _, spawn in pairs(live.spawnList) do
                if type(spawn) == "table" then
                    add(spawn.Spawns)
                    name = name or spawn.Name
                end
            end
        end
        if not found then
            return nil
        end
        return { name = name, spawns = spawns }
    end
    -- Before Questie's markers, the game's own quest marker (native.lua).
    function backend.questPoint(id)
        if quests.gameQuestPoint == nil then
            return nil
        end
        return quests.gameQuestPoint(id)
    end
    function backend.npc(id)
        local ok, npc = pcall(QuestieDB.GetNPC, QuestieDB, id)
        if not ok or npc == nil then
            return nil
        end
        return { id = id, name = npc.name, subName = npc.subName, spawns = npc.spawns, zone = npc.zoneID }
    end

    function backend.object(id)
        local ok, object = pcall(QuestieDB.GetObject, QuestieDB, id)
        if not ok or object == nil then
            return nil
        end
        return { id = id, name = object.name, spawns = object.spawns, zone = object.zoneID }
    end

    function backend.item(id)
        local ok, item = pcall(QuestieDB.GetItem, QuestieDB, id)
        if not ok or item == nil then
            return nil
        end
        return {
            id = id,
            name = item.name,
            npcDrops = idList(item.npcDrops),
            objectDrops = idList(item.objectDrops),
            vendors = idList(item.vendors),
        }
    end

    function backend.isDoable(id)
        local ok, doable = pcall(QuestieDB.IsDoable, id)
        return ok and doable == true
    end

    function backend.availableQuestIds()
        return AvailableQuests ~= nil and AvailableQuests.__availableQuests or nil
    end

    function backend.allQuestIds()
        local ids = {}
        for id in pairs(QuestieDB.QuestPointers or {}) do
            tinsert(ids, id)
        end
        return ids
    end

    function backend.questZone(id)
        local ok, zone = pcall(QuestieDB.QueryQuestSingle, id, "zoneOrSort")
        if ok and type(zone) == "number" and zone > 0 then
            return zone
        end
        return nil
    end

    -- Spawns are usually keyed by a zone's area id, but some records key by
    -- a SUBZONE id (Questie's own icon drawing falls back to the parent
    -- zone's map for those, keeping the same percentages) and a few carry
    -- a uiMapID outright. Mirror that resolution here.
    local function zoneMapFor(areaId)
        local ok, mapId = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, areaId)
        if ok and mapId ~= nil then
            return mapId
        end
        return nil
    end

    function backend.parentArea(areaId)
        local ok, parent = pcall(ZoneDB.GetParentZoneId, ZoneDB, areaId)
        if ok then
            return parent
        end
        return nil
    end

    function backend.mapForArea(areaId)
        if areaId == nil then
            return nil
        end
        local mapId = zoneMapFor(areaId)
        if mapId ~= nil then
            return mapId
        end
        local parent = backend.parentArea(areaId)
        if parent ~= nil then
            mapId = zoneMapFor(parent)
            if mapId ~= nil then
                return mapId
            end
        end
        local info = C_Map.GetMapInfo(areaId)
        if info ~= nil then
            return areaId
        end
        return nil
    end

    function backend.worldPosition(mapId, x, y)
        local continent, position = C_Map.GetWorldPosFromMapPos(mapId, CreateVector2D(x / 100, y / 100))
        if position == nil then
            return nil
        end
        local wx, wy = position:GetXY()
        return continent, wx, wy
    end

    -- ---- the NPC index: zone, flags, and rank for every creature ----
    --
    -- Built once per session in the background (a few milliseconds per
    -- frame) after Questie is ready, so zone role lists never scan the
    -- database on demand. zoneID is Questie's "most common zone" for the
    -- creature: right for townsfolk and rares, approximate for wanderers.

    backend.flags = QuestieDB.npcFlags or {}
    backend.index = nil
    local indexFrame = CreateFrame("Frame")
    indexFrame:Hide()

    function backend.startIndex(onDone)
        if backend.index ~= nil then
            if backend.index.done and onDone ~= nil then
                onDone()
            end
            return
        end
        local ids = {}
        for id in pairs(QuestieDB.NPCPointers or {}) do
            tinsert(ids, id)
        end
        local index = { byArea = {}, flags = {}, rank = {}, ids = ids, cursor = 1, done = false }
        backend.index = index
        local keys = { "zoneID", "npcFlags", "rank" }
        indexFrame:SetScript("OnUpdate", function()
            local deadline = debugprofilestop() + 3
            while index.cursor <= #ids and debugprofilestop() < deadline do
                local id = ids[index.cursor]
                index.cursor = index.cursor + 1
                local ok, row = pcall(QuestieDB.QueryNPC, id, keys)
                if ok and row ~= nil then
                    local zone = row[1]
                    if type(zone) == "number" and zone > 0 then
                        local list = index.byArea[zone]
                        if list == nil then
                            list = {}
                            index.byArea[zone] = list
                        end
                        tinsert(list, id)
                    end
                    index.flags[id] = row[2] or 0
                    index.rank[id] = row[3] or 0
                end
            end
            if index.cursor > #ids then
                index.done = true
                indexFrame:Hide()
                indexFrame:SetScript("OnUpdate", nil)
                if onDone ~= nil then
                    onDone()
                end
            end
        end)
        indexFrame:Show()
    end

    function backend.indexReady()
        return backend.index ~= nil and backend.index.done
    end

    function backend.npcsInArea(areaId)
        if backend.index == nil or areaId == nil then
            return {}
        end
        return backend.index.byArea[areaId] or {}
    end

    function backend.npcMeta(id)
        if backend.index == nil then
            return 0, 0
        end
        return backend.index.flags[id] or 0, backend.index.rank[id] or 0
    end

    -- Questie's curated per-character lists (faction and class filtered):
    -- "Mailbox" and "Meeting Stones" are object ids, the rest NPC ids.
    function backend.townsfolk(key)
        local char = Questie.db and Questie.db.char or nil
        local list = char ~= nil and char.townsfolk ~= nil and char.townsfolk[key] or nil
        if type(list) ~= "table" then
            return {}
        end
        return list
    end

    -- Names for a spawn: the zone, the subzone when the spawn's own area id
    -- IS a subzone (exact, straight from the data), then the shared
    -- landmark and overlay hints (core/quests/places.lua).
    function backend.placeName(mapId, x, y, areaId)
        local zone, subzone = nil, nil
        if areaId ~= nil and C_Map.GetAreaInfo ~= nil then
            local parent = backend.parentArea(areaId)
            if parent ~= nil and zoneMapFor(areaId) == nil then
                subzone = C_Map.GetAreaInfo(areaId)
                zone = C_Map.GetAreaInfo(parent)
            else
                zone = C_Map.GetAreaInfo(areaId)
            end
        end
        return quests.places.placeName(mapId, x, y, zone, subzone)
    end

    function backend.player()
        local x, y, _, continent = UnitPosition("player")
        local mapId = C_Map.GetBestMapForUnit("player")
        local areaId = nil
        if mapId ~= nil then
            local ok, area = pcall(ZoneDB.GetAreaIdByUiMapId, ZoneDB, mapId)
            if ok then
                areaId = area
            end
        end
        return { x = x, y = y, continent = continent, mapId = mapId, areaId = areaId, level = UnitLevel("player") }
    end

    return backend
end
