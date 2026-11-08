local testRunner = WowVision.testing.testRunner
local Adapter = WowVision.quests.Adapter

-- A fake backend over a tiny world: area 1 maps to map 10 on continent 0,
-- area 2 maps to map 20 on continent 1 (another continent), area 3 has no
-- map (an instance). World coordinates are the percent coordinates times
-- ten, so distances are easy to reason about.
local function fakeBackend(overrides)
    local npcs = {
        [100] = { id = 100, name = "Marshal McBride", subName = "Quest Giver", spawns = { [1] = { { 10, 10 } } } },
        [101] = { id = 101, name = "Kobold Vermin", spawns = { [1] = { { 50, 50 }, { 60, 60 } }, [3] = { { 5, 5 } } } },
        [102] = { id = 102, name = "Far Trader", spawns = { [2] = { { 10, 10 } } } },
        [103] = { id = 103, name = "Deputy Willem", spawns = { [1] = { { 20, 10 } } } },
        [104] = { id = 104, name = "Unknown Spot", spawns = { [1] = { { -1, -1 } } } },
    }
    local objects = {
        [200] = { id = 200, name = "Wanted Poster", spawns = { [1] = { { 30, 30 } } } },
    }
    local items = {
        [300] = { id = 300, name = "Kobold Candle", npcDrops = { 101 }, vendors = { 102 } },
    }
    local quests = {
        [1] = {
            id = 1,
            name = "Kobold Camp Cleanup",
            level = 3,
            requiredLevel = 1,
            starts = { npc = { 100 } },
            finishers = { npc = { 100 } },
            objectives = { { type = "monster", id = 101, text = "Kobold Vermin slain" } },
            zone = 1,
        },
        [2] = {
            id = 2,
            name = "Candles",
            level = 4,
            requiredLevel = 2,
            starts = { object = { 200 } },
            finishers = { npc = { 103 } },
            objectives = { { type = "item", id = 300, text = "Kobold Candle" } },
            zone = 1,
        },
        [3] = {
            id = 3,
            name = "Overseas",
            level = 5,
            requiredLevel = 1,
            starts = { npc = { 102 } },
            finishers = { npc = { 102 } },
            objectives = {},
            zone = 2,
        },
        [4] = {
            id = 4,
            name = "Too Low",
            level = 1,
            requiredLevel = 1,
            starts = { npc = { 103 } },
            finishers = { npc = { 103 } },
            objectives = {},
            zone = 1,
        },
        [5] = {
            id = 5,
            name = "Daily Chore",
            level = 10,
            requiredLevel = 1,
            repeatable = true,
            starts = { npc = { 103 } },
            finishers = { npc = { 103 } },
            objectives = {},
            zone = 1,
        },
        [6] = {
            id = 6,
            name = "Scout the Ridge",
            level = 10,
            requiredLevel = 1,
            starts = { npc = { 103 } },
            finishers = { npc = { 103 } },
            objectives = {},
            triggerEnd = { "Ridge scouted", { [1] = { { 80, 80 } } } },
            zone = 1,
        },
    }
    local backend = {
        ready = true,
        available = nil,
        doable = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true },
        playerPos = { x = 100, y = 100, continent = 0, mapId = 10, areaId = 1, level = 8 },
        conversions = 0,
        log = {},
    }
    function backend.isReady()
        return backend.ready
    end
    function backend.quest(id)
        return quests[id]
    end
    function backend.npc(id)
        return npcs[id]
    end
    function backend.object(id)
        return objects[id]
    end
    function backend.item(id)
        return items[id]
    end
    function backend.isDoable(id)
        return backend.doable[id] == true
    end
    function backend.availableQuestIds()
        return backend.available
    end
    function backend.allQuestIds()
        local ids = {}
        for id in pairs(quests) do
            tinsert(ids, id)
        end
        table.sort(ids)
        return ids
    end
    function backend.questZone(id)
        return quests[id].zone
    end
    function backend.mapForArea(areaId)
        if areaId == 1 then
            return 10
        elseif areaId == 2 then
            return 20
        end
        return nil
    end
    function backend.worldPosition(mapId, x, y)
        backend.conversions = backend.conversions + 1
        local continent = mapId == 10 and 0 or 1
        return continent, x * 10, y * 10
    end
    function backend.player()
        return backend.playerPos
    end
    function backend.questLog()
        return backend.log
    end
    for k, v in pairs(overrides or {}) do
        backend[k] = v
    end
    return backend
end

local function names(list)
    local out = {}
    for _, entry in ipairs(list) do
        tinsert(out, entry.name)
    end
    return table.concat(out, ",")
end

testRunner:addSuite("QuestAdapter", {
    ["not ready yields empty answers"] = function(t)
        local backend = fakeBackend({ ready = false })
        local adapter = Adapter:new(backend)
        t:assertFalse(adapter:isReady())
        t:assertEqual(#adapter:nearbyQuests(), 0)
        t:assertEqual(#adapter:targets(1, "start"), 0)
        t:assertNil(adapter:quest(1))
    end,

    ["start targets resolve the giver with world position and distance"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local targets = adapter:targets(1, "start")
        t:assertEqual(#targets, 1)
        local giver = targets[1]
        t:assertEqual(giver.kind, "npc")
        t:assertEqual(giver.name, "Marshal McBride")
        t:assertEqual(giver.nearest.wx, 100)
        t:assertEqual(giver.nearest.wy, 100)
        t:assertEqual(giver.distance, 0)
    end,

    ["objective targets pick the nearest spawn and skip unmapped areas"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local targets = adapter:targets(1, "objectives")
        t:assertEqual(#targets, 1)
        local kobold = targets[1]
        t:assertEqual(kobold.objectiveIndex, 1)
        t:assertEqual(kobold.objectiveText, "Kobold Vermin slain")
        -- Area 3 has no map: two spawns survive, the nearest is 50,50.
        t:assertEqual(#kobold.spawns, 2)
        t:assertEqual(kobold.nearest.x, 50)
        t:assertTrue(math.abs(kobold.distance - math.sqrt(2) * 400) < 0.001)
    end,

    ["item objectives expand to drops and vendors, off-continent last"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local targets = adapter:targets(2, "objectives")
        t:assertEqual(#targets, 2)
        t:assertEqual(targets[1].name, "Kobold Vermin")
        t:assertEqual(targets[1].source, "drop")
        t:assertEqual(targets[1].item.name, "Kobold Candle")
        t:assertEqual(targets[2].name, "Far Trader")
        t:assertEqual(targets[2].source, "vendor")
        t:assertNil(targets[2].distance)
    end,

    ["finish targets and object starters resolve"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        t:assertEqual(adapter:targets(2, "finish")[1].name, "Deputy Willem")
        local starters = adapter:targets(2, "start")
        t:assertEqual(starters[1].kind, "object")
        t:assertEqual(starters[1].name, "Wanted Poster")
    end,

    ["trigger spots become a target"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local targets = adapter:targets(6, "objectives")
        t:assertEqual(#targets, 1)
        t:assertEqual(targets[1].kind, "spot")
        t:assertEqual(targets[1].name, "Ridge scouted")
        t:assertEqual(targets[1].nearest.wx, 800)
    end,

    ["phased-out spawns are kept but rank after visible ones"] = function(t)
        local backend = fakeBackend()
        backend.spawnVisible = function(phase)
            return phase ~= 7
        end
        -- Two spawns: the near one is in a phase this character cannot see.
        backend.npc = function(id)
            if id == 500 then
                return { id = 500, name = "Phased Farmer", spawns = { [1] = { { 10, 10, 7 }, { 30, 30 } } } }
            end
            return nil
        end
        local adapter = Adapter:new(backend)
        local target = adapter:_npcTarget(500, adapter:_playerContext())
        t:assertEqual(#target.spawns, 2)
        t:assertEqual(target.nearest.x, 30)
        t:assertFalse(target.nearest.phased)
        local ordered = { target.spawns[1], target.spawns[2] }
        table.sort(ordered, Adapter.spawnBefore)
        t:assertEqual(ordered[1].x, 30)
        t:assertTrue(ordered[2].phased)
    end,

    ["all spawns phased falls back to the nearest"] = function(t)
        local backend = fakeBackend()
        backend.spawnVisible = function()
            return false
        end
        backend.npc = function(id)
            return { id = id, name = "Ghost", spawns = { [1] = { { 50, 50, 7 }, { 10, 10, 8 } } } }
        end
        local adapter = Adapter:new(backend)
        local target = adapter:_npcTarget(600, adapter:_playerContext())
        t:assertEqual(target.nearest.x, 10)
        t:assertTrue(target.nearest.phased)
    end,

    ["unknown positions are dropped"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local ctx = adapter:_playerContext()
        local target = adapter:_npcTarget(104, ctx)
        t:assertEqual(#target.spawns, 0)
        t:assertNil(target.distance)
    end,

    ["nearby quests rank by giver distance and apply level and repeat filters"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local list = adapter:nearbyQuests({ levelRange = 5 })
        -- Quest 3 is on another continent, 4 is too low, 5 repeatable.
        t:assertEqual(names(list), "Kobold Camp Cleanup,Scout the Ridge,Candles")
        t:assertEqual(list[1].distance, 0)
        t:assertEqual(list[1].starter.name, "Marshal McBride")
        local withRepeatable = adapter:nearbyQuests({ levelRange = 5, includeRepeatable = true })
        t:assertEqual(#withRepeatable, 4)
        local noFloor = adapter:nearbyQuests({ includeRepeatable = true })
        t:assertEqual(#noFloor, 5)
        local capped = adapter:nearbyQuests({ levelRange = 5, maxCount = 1 })
        t:assertEqual(#capped, 1)
    end,

    ["nearby prefers the backend's available set when present"] = function(t)
        local backend = fakeBackend({ available = { [2] = true } })
        local adapter = Adapter:new(backend)
        t:assertEqual(names(adapter:nearbyQuests()), "Candles")
    end,

    ["nearby respects doable"] = function(t)
        local backend = fakeBackend()
        backend.doable[1] = false
        local adapter = Adapter:new(backend)
        t:assertEqual(names(adapter:nearbyQuests({ levelRange = 5 })), "Scout the Ridge,Candles")
    end,

    ["zone scan is cached per area and cleared by invalidate"] = function(t)
        local backend = fakeBackend()
        local scans = 0
        local inner = backend.allQuestIds
        backend.allQuestIds = function()
            scans = scans + 1
            return inner()
        end
        local adapter = Adapter:new(backend)
        adapter:nearbyQuests()
        adapter:nearbyQuests()
        t:assertEqual(scans, 1)
        adapter:invalidate()
        adapter:nearbyQuests()
        t:assertEqual(scans, 2)
    end,

    ["world conversions are memoized"] = function(t)
        local backend = fakeBackend()
        local adapter = Adapter:new(backend)
        adapter:targets(1, "objectives")
        local first = backend.conversions
        adapter:targets(1, "objectives")
        t:assertEqual(backend.conversions, first)
    end,

    ["in-progress joins live progress to database targets"] = function(t)
        local backend = fakeBackend()
        backend.log = {
            {
                questId = 1,
                title = "Kobold Camp Cleanup",
                level = 3,
                objectives = { { text = "Kobold Vermin slain: 3/8", type = "monster", finished = false, collected = 3, needed = 8 } },
            },
            {
                questId = 999,
                title = "Not In Database",
                level = 9,
                complete = true,
                objectives = { { text = "Done", type = "event", finished = true } },
            },
        }
        local adapter = Adapter:new(backend)
        local list = adapter:inProgress()
        t:assertEqual(#list, 2)
        local first = list[1]
        t:assertTrue(first.known)
        t:assertEqual(first.objectives[1].collected, 3)
        t:assertEqual(first.objectives[1].needed, 8)
        t:assertEqual(first.objectives[1].target.kind, "npc")
        t:assertEqual(first.objectives[1].target.name, "Kobold Vermin")
        local second = list[2]
        t:assertFalse(second.known)
        t:assertTrue(second.complete)
        t:assertNil(second.objectives[1].target)
    end,

    ["objective targets for one index"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local targets = adapter:objectiveTargets(2, 1)
        t:assertEqual(#targets, 2)
        t:assertEqual(#adapter:objectiveTargets(2, 5), 0)
    end,

    ["a Questie marker resolves to its nearest marker"] = function(t)
        local adapter = Adapter:new(fakeBackend({
            questMarkers = function(id, index)
                if id == 6 and index == 1 then
                    -- one marker on another continent, one in an instance, two here
                    return {
                        name = "Ridge Lookout",
                        spawns = { [1] = { { 80, 80 }, { 20, 20 } }, [2] = { { 10, 10 } }, [3] = { { 5, 5 } } },
                    }
                end
                return nil
            end,
        }))
        local marker = adapter:markerTarget(6, 1)
        t:assertEqual(marker.kind, "marker")
        t:assertEqual(marker.name, "Ridge Lookout")
        t:assertEqual(marker.objectiveIndex, 1)
        t:assertEqual(#marker.spawns, 3, "the instance marker has no map")
        t:assertEqual(marker.nearest.x, 20)
        t:assertNil(adapter:markerTarget(6, 2), "no marker for that objective")
    end,

    ["no Questie marker on this continent, or no marker source, gives nothing"] = function(t)
        local overseas = Adapter:new(fakeBackend({
            questMarkers = function()
                return { spawns = { [2] = { { 10, 10 } } } }
            end,
        }))
        t:assertNil(overseas:markerTarget(3, 1))
        t:assertNil(Adapter:new(fakeBackend()):markerTarget(1, 1))
        t:assertNil(Adapter:new(fakeBackend({ ready = false, questMarkers = function() return {} end })):markerTarget(1, 1))
    end,

    ["the game's quest marker resolves to one point"] = function(t)
        local adapter = Adapter:new(fakeBackend({
            questPoint = function(id)
                if id == 1 then
                    return 10, 40, 40
                elseif id == 3 then
                    return 20, 10, 10
                end
                return nil
            end,
        }))
        local marker = adapter:gameMarkerTarget(1)
        t:assertEqual(marker.kind, "gameMarker")
        t:assertEqual(marker.nearest.wx, 400)
        t:assertTrue(math.abs(marker.distance - math.sqrt(2) * 300) < 0.001)
        t:assertNil(adapter:gameMarkerTarget(3), "on another continent")
        t:assertNil(adapter:gameMarkerTarget(2), "the game marks nothing")
        t:assertNil(Adapter:new(fakeBackend()):gameMarkerTarget(1), "no such source")
    end,

    ["npcs by role bucket the zone index within the radius"] = function(t)
        local backend = fakeBackend()
        backend.flags = { VENDOR = 4, REPAIR = 16384, TRAINER = 16 }
        backend.npcsInArea = function(areaId)
            if areaId == 1 then
                return { 100, 101, 103, 102 }
            end
            return {}
        end
        local meta = {
            [100] = { 4 + 16384, 0 }, -- vendor and repair, at the player
            [101] = { 0, 4 }, -- rare, nearest spawn 566 yards out
            [103] = { 16, 0 }, -- trainer, 100 yards
            [102] = { 4, 0 }, -- vendor on another continent
        }
        backend.npcMeta = function(id)
            return meta[id][1], meta[id][2]
        end
        local adapter = Adapter:new(backend)
        local buckets = adapter:npcsByRole({ radius = 500 })
        t:assertEqual(names(buckets.vendor), "Marshal McBride")
        t:assertEqual(names(buckets.repair), "Marshal McBride")
        t:assertEqual(names(buckets.trainer), "Deputy Willem")
        t:assertEqual(#buckets.rare, 0)
        local wide = adapter:npcsByRole({ radius = 1000, maxCount = 1 })
        t:assertEqual(names(wide.rare), "Kobold Vermin")
        t:assertEqual(#wide.vendor, 1)
    end,

    ["place targets resolve explicit ids within the radius"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local list = adapter:placeTargets("object", { 200 }, { radius = 500 })
        t:assertEqual(names(list), "Wanted Poster")
        t:assertEqual(#adapter:placeTargets("object", { 200 }, { radius = 100 }), 0)
        t:assertEqual(names(adapter:placeTargets("npc", { 103, 100 }, {})), "Marshal McBride,Deputy Willem")
    end,

    ["the player context is the backend's player"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        local player = adapter:playerContext()
        t:assertEqual(player.x, 100)
        t:assertEqual(player.y, 100)
        t:assertEqual(player.continent, 0)
    end,

    ["nodes sort nearest first, unplaced ones last, ties in order"] = function(t)
        local function keys(list)
            local out = {}
            for _, node in ipairs(list) do
                tinsert(out, node.key)
            end
            return table.concat(out, ",")
        end
        local nodes = {
            { key = "a", x = 500, y = 100 }, -- 400 yards
            { key = "b" }, -- nothing to walk to
            { key = "c", x = 110, y = 100 }, -- 10 yards
            { key = "d", x = 100, y = 600 }, -- 500 yards
            { key = "e" },
            { key = "f", x = 100, y = 500 }, -- 400 yards, like a: a came first
        }
        local sorted = Adapter.sortByProximity(nodes, { x = 100, y = 100 })
        t:assertEqual(keys(sorted), "c,a,f,d,b,e")
        t:assertEqual(keys(nodes), "a,b,c,d,e,f", "the list given is not changed")
    end,

    ["without a player position the order stays"] = function(t)
        local nodes = { { key = "far", x = 900, y = 900 }, { key = "near", x = 1, y = 1 } }
        t:assertEqual(Adapter.sortByProximity(nodes, nil), nodes)
        t:assertEqual(Adapter.sortByProximity(nodes, {}), nodes)
        t:assertEqual(Adapter.sortByProximity(nodes, { x = 1 }), nodes)
    end,

    ["an empty list sorts to an empty list"] = function(t)
        t:assertEqual(#Adapter.sortByProximity({}, { x = 0, y = 0 }), 0)
    end,

    ["unknown phase errors"] = function(t)
        local adapter = Adapter:new(fakeBackend())
        t:assertError(function()
            adapter:targets(1, "somewhere")
        end)
    end,
})
