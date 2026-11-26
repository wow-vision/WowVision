local module = WowVision.base.scanner
local L = module.L

-- Scanner categories that need nothing but the game. Player: you yourself
-- first (name, zone, level, race, class, guild; Enter targets you), then
-- your corpse while you are a ghost (the map API reports it on the current
-- map) and the graveyards of the current map, so a corpse run has somewhere
-- to point. Group: the party or raid members (Enter routes to one).

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

-- The name of the map a unit is on; errors (a secret value) reach the pcall
-- in unitPlace.
local function bestMapName(unit, api)
    local map = api.C_Map
    if map == nil or map.GetBestMapForUnit == nil or map.GetMapInfo == nil then
        return nil
    end
    local mapId = map.GetBestMapForUnit(unit)
    local info = mapId ~= nil and map.GetMapInfo(mapId) or nil
    return info ~= nil and info.name or nil
end

-- The zone a unit is in, in the client's language; nil when the game does
-- not say. You: the zone you stand in. A raid member: the roster, which also
-- knows members far away. Otherwise the unit's map. api: the game reads
-- (tests pass fakes).
function module.unitPlace(unit, api)
    api = api or _G
    local place = nil
    if unit == "player" and api.GetRealZoneText ~= nil then
        local ok, zone = pcall(api.GetRealZoneText)
        place = ok and zone or nil
    end
    local raidIndex = tonumber(unit:match("^raid(%d+)$"))
    if not readable(place) and raidIndex ~= nil and api.GetRaidRosterInfo ~= nil then
        local ok, zone = pcall(function()
            return (select(7, api.GetRaidRosterInfo(raidIndex)))
        end)
        place = ok and zone or nil
    end
    if not readable(place) then
        local ok, name = pcall(bestMapName, unit, api)
        place = ok and name or nil
    end
    return readable(place) and place or nil
end

local ROLE_TEXTS = {
    TANK = L["Tank"],
    HEALER = L["Healer"],
    DAMAGER = L["Damage Dealer"],
}

-- The group role a unit was given (the role icon on the group frames):
-- Tank, Healer or Damage Dealer; nil for none or when the game does not
-- say. api: the game reads (tests pass fakes).
function module.unitRole(unit, api)
    api = api or _G
    if api.UnitGroupRolesAssigned == nil then
        return nil
    end
    local ok, role = pcall(api.UnitGroupRolesAssigned, unit)
    if not ok or not readable(role) then
        return nil
    end
    return ROLE_TEXTS[role]
end

-- A readable GUID of a unit, nil when the game does not give one.
local function unitGuid(unit)
    if UnitGUID == nil then
        return nil
    end
    local ok, guid = pcall(UnitGUID, unit)
    return ok and readable(guid) and guid or nil
end

-- Whether a unit token still stands for the member an entry was built for:
-- the game hands party1 to the next member when someone leaves. A GUID the
-- game does not give now cannot tell, so it counts as the same member.
local function sameMember(unit, guid)
    if guid == nil then
        return true
    end
    local now = unitGuid(unit)
    return now == nil or now == guid
end

-- A unit's entry: its name, then (withRole) its group role, where it is and
-- its description, read when spoken. guid: the member the entry was built
-- for; once the unit token stands for someone else the entry reads only the
-- name. What Enter does is up to the category (see the node's `unit` in
-- module.lua).
local function unitNode(key, unit, withRole, guid)
    return {
        key = key,
        label = UnitName(unit) or unit,
        nameDetail = function()
            if not sameMember(unit, guid) then
                return nil
            end
            local parts = {}
            local role = withRole and module.unitRole(unit) or nil
            if role ~= nil then
                tinsert(parts, role)
            end
            local place = module.unitPlace(unit)
            if place ~= nil then
                tinsert(parts, place)
            end
            local description = module.unitDescription(unit)
            if description ~= nil then
                tinsert(parts, description)
            end
            if #parts == 0 then
                return nil
            end
            return table.concat(parts, ", ")
        end,
    }
end

-- The party or raid members, each with its group role. `position` reads
-- where the game puts a member now (core/navigation/unitPosition.lua: on the
-- player's map only), each time the entry is spoken or routed to, so a
-- member who moves, or only now gets a position, is heard where they are;
-- one who left the group (the token went to someone else) has none. A
-- member with a position reads distance and direction; Enter opens the
-- navigation window aimed at it, and its unit as routeData lets a route
-- engine read the position again (WowNav: a new route). Enter on a member
-- without a position says so.
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
                local guid = unitGuid(unit)
                local node = unitNode("unit:" .. unit, unit, true, guid)
                node.position = function()
                    if not sameMember(unit, guid) then
                        return nil
                    end
                    return WowVision.unitPosition(unit)
                end
                node.x, node.y = node.position()
                node.routeData = { unit = unit }
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
        local me = unitNode("self", "player")
        me.unit = "player"
        local out = { me }
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
