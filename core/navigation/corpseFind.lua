-- Where the corpse lies (corpse.lua): pure Lua over a small game interface, so the headless suite tests it. The game
-- reports the corpse on a map only when it lies on that map; a ghost released to a graveyard of the next zone does
-- not find it on his own zone's map. So the zone's map is asked first, then its parents up to the continent.
--
-- api: bestMap() -> the player's map id or nil; corpseOn(map) -> a map position or nil; parentOf(map) -> the parent
-- map id or nil; isContinent(map) -> bool (the search stops there); toWorld(map, position) -> world x, y or nil.
-- Returns world x, y and the map the corpse was found on, or nil.
local corpseFind = {}
WowVision.corpseFind = corpseFind

local MAX_LEVELS = 6

function corpseFind.find(api)
    local map = api.bestMap()
    for _ = 1, MAX_LEVELS do
        if map == nil then
            return nil
        end
        local position = api.corpseOn(map)
        if position ~= nil then
            local x, y = api.toWorld(map, position)
            if x ~= nil then
                return x, y, map
            end
        end
        if api.isContinent(map) then
            return nil
        end
        map = api.parentOf(map)
    end
    return nil
end

-- The floor of a target over several floors that a corpse run takes: the lowest one a route reaches, else the
-- lowest. floors: lowest first, each with reachable (false when no network path leads there).
function corpseFind.lowestFloor(floors)
    for _, floor in ipairs(floors) do
        if floor.reachable ~= false then
            return floor
        end
    end
    return floors[1]
end
