local module = WowVision.base.scanner
local L = module.L

-- Scanner categories that need nothing but the game. Player: you yourself
-- first (name, level, race, class, guild; Enter targets you), then your
-- corpse while you are a ghost (the map API reports it on the current map)
-- and the graveyards of the current map, so a corpse run has somewhere to
-- point. Group: the party or raid members (Enter targets one).

local function mapPositionNode(key, label, mapId, position)
    if position == nil then
        return nil
    end
    local _, world = C_Map.GetWorldPosFromMapPos(mapId, position)
    if world == nil then
        return nil
    end
    local wx, wy = world:GetXY()
    return { key = key, label = label, x = wx, y = wy }
end

local function readable(value)
    return type(value) == "string" and value ~= "" and not (WowVision.isSecret ~= nil and WowVision.isSecret(value))
end

-- "Level 60, Human, Warrior, Guild: Name" for a unit, read when spoken (a
-- level up or a new guild shows without a Refresh). Parts the game does not
-- give are left out. api: the game reads (tests pass fakes).
function module.unitDescription(unit, api)
    api = api or _G
    local parts = {}
    local function read(name, ...)
        local fn = api[name]
        if fn == nil then
            return nil
        end
        local ok, a = pcall(fn, ...)
        return ok and a or nil
    end
    local level = read("UnitLevel", unit)
    if type(level) == "number" and level > 0 then
        tinsert(parts, L["Level"] .. " " .. level)
    end
    local race = read("UnitRace", unit)
    if readable(race) then
        tinsert(parts, race)
    end
    local class = read("UnitClass", unit)
    if readable(class) then
        tinsert(parts, class)
    end
    local guild = read("GetGuildInfo", unit)
    if readable(guild) then
        tinsert(parts, L["Guild"] .. ": " .. guild)
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ", ")
end

-- A unit's entry: its name, its description, Enter targets it (the game's
-- secure target action, see the node's `unit` in module.lua).
local function unitNode(key, unit)
    return {
        key = key,
        label = UnitName(unit) or unit,
        detail = function()
            return module.unitDescription(unit)
        end,
        unit = unit,
    }
end

-- The party or raid members. A member whose position the game gives (on
-- the map for everyone in the group) also reads distance and direction and
-- carries its unit as routeData, so Backspace routes to it and a route
-- engine can read the position again (WowNav: a new route).
module:registerProvider({
    key = "group",
    label = L["Group"],
    order = 6,
    build = function()
        local out = {}
        local raid = IsInRaid ~= nil and IsInRaid()
        local count = GetNumGroupMembers ~= nil and GetNumGroupMembers() or 0
        for i = 1, raid and count or math.min(count, 4) do
            local unit = raid and ("raid" .. i) or ("party" .. i)
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                local node = unitNode("unit:" .. unit, unit)
                local ok, x, y = pcall(UnitPosition, unit)
                if ok and type(x) == "number" and type(y) == "number"
                    and not (issecretvalue ~= nil and (issecretvalue(x) or issecretvalue(y))) then
                    node.x, node.y = x, y
                    node.routeData = { unit = unit }
                end
                tinsert(out, node)
            end
        end
        return out
    end,
})

module:registerProvider({
    key = "player",
    label = L["Player"],
    order = 5,
    build = function()
        local out = { unitNode("self", "player") }
        local mapId = C_Map.GetBestMapForUnit("player")
        if mapId == nil or not UnitIsDeadOrGhost("player") then
            return out
        end
        local corpse = C_DeathInfo ~= nil and C_DeathInfo.GetCorpseMapPosition ~= nil
                and C_DeathInfo.GetCorpseMapPosition(mapId)
            or nil
        local node = mapPositionNode("corpse", L["Corpse"], mapId, corpse)
        if node ~= nil then
            tinsert(out, node)
        end
        local graveyards = C_DeathInfo ~= nil and C_DeathInfo.GetGraveyardsForMap ~= nil
                and C_DeathInfo.GetGraveyardsForMap(mapId)
            or nil
        if graveyards ~= nil and #graveyards > 0 then
            local children = {}
            for _, graveyard in ipairs(graveyards) do
                local node = mapPositionNode(
                    "graveyard:" .. tostring(graveyard.graveyardID or graveyard.areaPoiID),
                    graveyard.name or L["Graveyards"],
                    mapId,
                    graveyard.position
                )
                if node ~= nil then
                    tinsert(children, node)
                end
            end
            tinsert(out, { key = "graveyards", label = L["Graveyards"], children = children })
        end
        return out
    end,
})
