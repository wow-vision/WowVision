local testRunner = WowVision.testing.testRunner
local corpseFind = WowVision.corpseFind

-- A map tree: zone 1426 (Dun Morogh) and 1432 (Loch Modan) under continent 1415 (Eastern Kingdoms).
local function api(corpseMap, best)
    local parents = { [1426] = 1415, [1432] = 1415, [1415] = 947 }
    return {
        bestMap = function()
            return best
        end,
        corpseOn = function(map)
            if map == corpseMap then
                return { x = 0.5, y = 0.25 }
            end
            return nil
        end,
        parentOf = function(map)
            return parents[map]
        end,
        isContinent = function(map)
            return map == 1415
        end,
        toWorld = function(map, position)
            return map * 10 + position.x, position.y
        end,
    }
end

testRunner:addSuite("CorpseRun", {
    ["the corpse on the zone's own map"] = function(t)
        local x, y, map = corpseFind.find(api(1426, 1426))
        t:assertEqual(map, 1426)
        t:assertEqual(x, 14260.5)
        t:assertEqual(y, 0.25)
    end,

    ["a corpse in the next zone is found on the continent's map"] = function(t)
        local _, _, map = corpseFind.find(api(1415, 1432))
        t:assertEqual(map, 1415)
    end,

    ["no corpse on the continent: nothing, and the search stops there"] = function(t)
        t:assertNil(corpseFind.find(api(947, 1432)), "the world map above the continent is not asked")
        t:assertNil(corpseFind.find(api(1426, nil)), "no map for the player")
    end,

    ["the lowest floor a route reaches, else the lowest"] = function(t)
        local floors = { { band = 1, reachable = false }, { band = 2, reachable = true }, { band = 3, reachable = true } }
        t:assertEqual(corpseFind.lowestFloor(floors).band, 2)
        t:assertEqual(corpseFind.lowestFloor({ { band = 1, reachable = false }, { band = 2, reachable = false } }).band, 1)
        t:assertEqual(corpseFind.lowestFloor({ { band = 4 } }).band, 4)
    end,
})
