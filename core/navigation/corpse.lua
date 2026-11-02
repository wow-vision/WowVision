-- The corpse run: a ghost -- spirit released, or logged in or reloaded as one -- gets a route to the corpse at once,
-- from the entry point the navigation window would preselect, while "Automatically Navigate to Corpse" is on
-- (Navigation menu, default on). The corpse is looked up on the zone's map, then on its parents up to the continent's
-- (corpseFind.lua), and only on the player's own continent. Right after a loading screen the game may not report it
-- yet, so it is asked again for a few seconds. The corpse has no height: WowNav takes the lowest floor where it lies
-- over several. The scanner's corpse entry (F9, Player) stays as it is.
local navigation = WowVision.base.navigation
local maps = navigation.maps
local corpseFind = WowVision.corpseFind
local L = navigation.L

local TRIES = 8       -- lookups after a trigger
local DELAY = 1.0     -- seconds before each

local CONTINENT = Enum ~= nil and Enum.UIMapType ~= nil and Enum.UIMapType.Continent or 2

local function mapInfo(map)
    return C_Map.GetMapInfo ~= nil and C_Map.GetMapInfo(map) or nil
end

local api = {
    bestMap = function()
        return C_Map.GetBestMapForUnit("player")
    end,
    corpseOn = function(map)
        if C_DeathInfo == nil or C_DeathInfo.GetCorpseMapPosition == nil then
            return nil
        end
        local ok, position = pcall(C_DeathInfo.GetCorpseMapPosition, map)
        return ok and position or nil
    end,
    parentOf = function(map)
        local info = mapInfo(map)
        return info ~= nil and info.parentMapID ~= nil and info.parentMapID ~= 0 and info.parentMapID or nil
    end,
    isContinent = function(map)
        local info = mapInfo(map)
        return info == nil or info.mapType == CONTINENT
    end,
    -- world coordinates in UnitPosition's convention, on the player's continent only (a corpse in an instance is
    -- not walked to from outside)
    toWorld = function(map, position)
        local continent, world = C_Map.GetWorldPosFromMapPos(map, position)
        if world == nil then
            return nil
        end
        local _, _, _, instance = UnitPosition("player")
        if continent ~= nil and instance ~= nil and continent ~= instance then
            return nil
        end
        return world:GetXY()
    end,
}

local generation = 0

local function active()
    return navigation:getEnabled() and navigation.settings.autoCorpse == true and UnitIsGhost("player")
end

-- A newer trigger replaces a running lookup; the route starts once the corpse is found.
local function startCorpseRun()
    generation = generation + 1
    local mine, tries = generation, 0
    local function attempt()
        if mine ~= generation or not active() then
            return
        end
        tries = tries + 1
        local x, y = corpseFind.find(api)
        if x == nil then
            if tries < TRIES then
                C_Timer.After(DELAY, attempt)
            end
            return
        end
        maps:goToDestination({
            id = "corpse", n = L["Corpse"], x = x, y = y, virtual = true,
            routeData = { lowestFloor = true },
        }, false)
    end
    C_Timer.After(DELAY, attempt)
end

local events = CreateFrame("Frame")
-- PLAYER_ALIVE: the spirit was released (or the player was resurrected: then he is no ghost and nothing happens);
-- PLAYER_ENTERING_WORLD: a login or reload, maybe as a ghost
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
    if active() then
        startCorpseRun()
    end
end)
