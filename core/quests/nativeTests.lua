local testRunner = WowVision.testing.testRunner
local Native = WowVision.quests.NativeAdapter

-- Headless only (tools/headless-tests.lua; not in modules.xml): each test
-- installs stand-ins for the game's map and quest log APIs over a tiny
-- world and removes them again, then asks the native source, and the
-- scanner's In Progress category built on it, where log quests are.
--
--   continent map 1 (instance 0): zones 10 (the player's) and 20
--   continent map 2 (instance 1): zone 30
--
-- World coordinates are the zone's offset plus the map fraction times
-- 1000; zone 20 lies 2000 yards east and north of zone 10.

local harness = WowVision.quests._nativeTestHarness

local MAPS = {
    [1] = { mapID = 1, name = "Continent", mapType = 2, parentMapID = 0 },
    [2] = { mapID = 2, name = "Far Continent", mapType = 2, parentMapID = 0 },
    [10] = { mapID = 10, name = "Home Zone", mapType = 3, parentMapID = 1, instance = 0, offset = 0 },
    [20] = { mapID = 20, name = "Next Zone", mapType = 3, parentMapID = 1, instance = 0, offset = 2000 },
    [30] = { mapID = 30, name = "Overseas Zone", mapType = 3, parentMapID = 2, instance = 1, offset = 0 },
}

local GLOBALS = {
    "C_Map",
    "C_QuestLog",
    "Enum",
    "CreateVector2D",
    "UnitPosition",
    "UnitLevel",
    "GetQuestUiMapID",
    "MapUtil",
}

-- world: { pois = { [mapId] = { QuestPOIMapInfo... } }, uiMaps = { [questId] = mapId },
-- log = { { questId, title } }, noUiMapApi = true to leave GetQuestUiMapID out }
local function withWorld(world, body)
    local saved = {}
    for _, name in ipairs(GLOBALS) do
        saved[name] = _G[name]
    end
    local savedLog = WowVision.quests.gameQuestLog
    world.calls = {}
    Enum = { UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3 } }
    -- Blizzard's two helpers the source calls, as the game has them
    MapUtil = {
        ShouldMapTypeShowQuests = function(mapType)
            return mapType ~= Enum.UIMapType.World and mapType ~= Enum.UIMapType.Continent
                and mapType ~= Enum.UIMapType.Cosmic
        end,
        GetMapParentInfo = function(mapId, mapType)
            local info = C_Map.GetMapInfo(mapId)
            while info do
                if info.mapType == mapType then
                    return info
                end
                info = C_Map.GetMapInfo(info.parentMapID)
            end
            return nil
        end,
    }
    CreateVector2D = function(x, y)
        return { x = x, y = y }
    end
    UnitPosition = function()
        return 100, 100, 0, 0
    end
    UnitLevel = function()
        return 10
    end
    C_Map = {
        GetBestMapForUnit = function()
            return 10
        end,
        GetMapInfo = function(mapId)
            return MAPS[mapId]
        end,
        GetMapChildrenInfo = function(mapId, mapType, allDescendants)
            local out = {}
            for id, info in pairs(MAPS) do
                if info.parentMapID == mapId and (mapType == nil or info.mapType == mapType) then
                    tinsert(out, info)
                end
            end
            table.sort(out, function(a, b)
                return a.mapID < b.mapID
            end)
            return out
        end,
        GetWorldPosFromMapPos = function(mapId, position)
            local info = MAPS[mapId]
            if info == nil or info.offset == nil then
                return nil, nil
            end
            local wx, wy = info.offset + position.x * 1000, info.offset + position.y * 1000
            return info.instance, {
                GetXY = function()
                    return wx, wy
                end,
            }
        end,
    }
    C_QuestLog = {
        GetQuestsOnMap = function(mapId)
            world.calls[mapId] = (world.calls[mapId] or 0) + 1
            return world.pois[mapId] or {}
        end,
        GetTitleForQuestID = function(questId)
            for _, entry in ipairs(world.log) do
                if entry.questId == questId then
                    return entry.title
                end
            end
            return nil
        end,
    }
    if not world.noUiMapApi then
        GetQuestUiMapID = function(questId)
            return world.uiMaps[questId] or 0
        end
    else
        GetQuestUiMapID = nil
    end
    WowVision.quests.gameQuestLog = function()
        local out = {}
        for _, entry in ipairs(world.log) do
            tinsert(out, {
                questId = entry.questId,
                title = entry.title,
                objectives = { { text = entry.title .. " objective", finished = false } },
            })
        end
        return out
    end
    local ok, err = pcall(body)
    for _, name in ipairs(GLOBALS) do
        _G[name] = saved[name]
    end
    WowVision.quests.gameQuestLog = savedLog
    if not ok then
        error(err, 0)
    end
end

local function point(questId, x, y, indicator)
    return { questID = questId, x = x, y = y, isMapIndicatorQuest = indicator == true }
end

-- The In Progress nodes of the scanner, by quest id, over a native source.
local function inProgressNodes(source)
    harness.source = source
    local out = {}
    for _, category in ipairs(harness.providers.quests.build({ maxEntries = 25, radius = 500 })) do
        if category.key == "inProgress" then
            -- one level per quest log zone, then the zone's quests
            for _, zone in ipairs(category.children()) do
                for _, node in ipairs(zone.children) do
                    out[node.key] = node
                end
            end
        end
    end
    return out
end

testRunner:addSuite("NativeQuestTargets", {
    ["a quest in another zone resolves through the map the quest log opens"] = function(t)
        local world = {
            pois = { [20] = { point(501, 0.5, 0.5) } },
            uiMaps = { [501] = 20 },
            log = { { questId = 501, title = "Next Door" } },
        }
        withWorld(world, function()
            local source = Native:new()
            local target = source:targets(501, "objectives")[1]
            t:assertNotNil(target, "target found")
            t:assertEqual(target.nearest.mapId, 20)
            t:assertEqual(target.nearest.wx, 2500)
            t:assertEqual(target.nearest.wy, 2500)
            t:assertNotNil(target.distance, "same continent, so a distance")
            local node = inProgressNodes(source)["quest:501"]
            t:assertEqual(node.x, 2500)
            t:assertEqual(node.y, 2500)
        end)
    end,

    ["without GetQuestUiMapID the continent's zones are searched once"] = function(t)
        local world = {
            noUiMapApi = true,
            pois = { [20] = { point(504, 0.25, 0.75) } },
            uiMaps = {},
            log = { { questId = 504, title = "Found By Index" } },
        }
        withWorld(world, function()
            local source = Native:new()
            local target = source:targets(504, "objectives")[1]
            t:assertNotNil(target, "target found")
            t:assertEqual(target.nearest.wx, 2250)
            t:assertEqual(target.nearest.wy, 2750)
            -- A second query reads the cached index, not the maps again.
            source:targets(504, "objectives")
            t:assertEqual(world.calls[20], 1)
            -- The overseas zone is not part of the player's continent.
            t:assertNil(world.calls[30])
        end)
    end,

    ["a map indicator entry is not a quest area"] = function(t)
        local world = {
            pois = { [20] = { point(502, 0.5, 0.5, true) } },
            uiMaps = { [502] = 20 },
            log = { { questId = 502, title = "Only An Arrow" } },
        }
        withWorld(world, function()
            local source = Native:new()
            t:assertEqual(#source:targets(502, "objectives"), 0)
            t:assertNil(inProgressNodes(source)["quest:502"].x)
        end)
    end,

    ["a quest on another continent gets no position in the scanner"] = function(t)
        local world = {
            pois = { [30] = { point(503, 0.5, 0.5) } },
            uiMaps = { [503] = 30 },
            log = { { questId = 503, title = "Overseas" } },
        }
        withWorld(world, function()
            local source = Native:new()
            local target = source:targets(503, "objectives")[1]
            t:assertNotNil(target, "the world map still shows it")
            t:assertNil(target.distance, "no distance across continents")
            t:assertNil(target.nearest, "no headline position across continents, as the Adapter's rank")
            local node = inProgressNodes(source)["quest:503"]
            t:assertNil(node.x)
            t:assertNil(node.y)
        end)
    end,

    ["the player's own map still comes first"] = function(t)
        local world = {
            pois = { [10] = { point(505, 0.2, 0.2) }, [20] = { point(505, 0.5, 0.5) } },
            uiMaps = { [505] = 20 },
            log = { { questId = 505, title = "Both" } },
        }
        withWorld(world, function()
            local source = Native:new()
            local target = source:targets(505, "objectives")[1]
            t:assertEqual(target.nearest.mapId, 10)
            t:assertEqual(target.nearest.wx, 200)
        end)
    end,

    ["invalidate drops every cached map"] = function(t)
        local world = {
            pois = { [20] = { point(501, 0.5, 0.5) } },
            uiMaps = { [501] = 20 },
            log = { { questId = 501, title = "Next Door" } },
        }
        withWorld(world, function()
            local source = Native:new()
            source:targets(501, "objectives")
            source:targets(501, "objectives")
            t:assertEqual(world.calls[20], 1)
            source:invalidate()
            world.pois[20] = { point(501, 0.1, 0.1) }
            local target = source:targets(501, "objectives")[1]
            t:assertEqual(world.calls[20], 2)
            t:assertEqual(target.nearest.wx, 2100)
        end)
    end,
})
