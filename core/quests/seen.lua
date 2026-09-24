local quests = WowVision.quests

-- NPCs other modules saw in the world this session, for clients whose
-- server sends no quest offers or NPC data (WoW: Forever). The minimap
-- scanner (core/minimap) is the one source today. The native source lists
-- seen quest givers under Nearby; the scanner's NPC categories list seen
-- NPCs of each role next to the database ones.
--
-- A source: {
--   hasGivers = function() -> bool,
--   givers = function() -> list of { guid, name, subName?, mapId, x, y,
--       wx, wy, continent, status?, flag?, indoors?, onArrive? },
--   npcs = function(role, radius) -> list of quest system targets,
-- }

local Seen = { sources = {} }
quests.seen = Seen

function Seen:register(source)
    tinsert(self.sources, source)
end

local function collect(sources, method, ...)
    local out = {}
    for _, source in ipairs(sources) do
        if source[method] ~= nil then
            local ok, list = pcall(source[method], ...)
            if ok and type(list) == "table" then
                for _, entry in ipairs(list) do
                    tinsert(out, entry)
                end
            end
        end
    end
    return out
end

function Seen:hasGivers()
    for _, source in ipairs(self.sources) do
        local ok, has = pcall(source.hasGivers)
        if ok and has then
            return true
        end
    end
    return false
end

function Seen:givers()
    return collect(self.sources, "givers")
end

function Seen:npcs(role, radius)
    return collect(self.sources, "npcs", role, radius)
end
