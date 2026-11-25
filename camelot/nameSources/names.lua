-- The logic, with no call into the game: it reads Questie's database through a "game" table handed in (so the tests give
-- it a stand-in) and works out which creatures, titles and world objects have no name in the game's language although
-- a name for the same English words is known somewhere.
--
-- Two kinds of knowledge feed it:
--   * the database itself: a creature called "Cat" that has a French name on one entry teaches the other entries called
--     "Cat" (a creature without a translation is much more often a copy of one that has one than a new word);
--   * outside sources (Sources.lua): dictionaries from other places, asked by the English name.
--
-- A walk over the database is slow, so it is done in small steps (Scan:step with a time budget) and its result is kept
-- in the saved variables by the glue (Main.lua).
local ns = WowVision.nameSources

local Names = {}
ns.Names = Names

Names.OWNER = "WowVisionNameSources"
Names.SLOT = "same-names"
Names.VERSION = 1
-- a name wins when this share of the entries called the same in English agree on it
Names.THRESHOLD = 0.6

-- the entity types and the fields read on each
local PHASES = {
    { type = "Npc", fields = { "name", "subName" } },
    { type = "Object", fields = { "name" } },
    { type = "Item", fields = { "name" } },
}
Names.PHASES = PHASES

local function isText(value)
    return type(value) == "string" and value ~= ""
end
Names.isText = isText

-- The text most entries agree on, or nil: counts is { [text] = number of entries }.
function Names.pick(counts)
    if type(counts) ~= "table" then
        return nil
    end
    local best, bestCount, total = nil, 0, 0
    for text, count in pairs(counts) do
        total = total + count
        -- a tie never reaches the threshold (two equal tops are at most half), so which one stays does not matter
        if count > bestCount then
            best, bestCount = text, count
        end
    end
    if best ~= nil and total > 0 and bestCount / total >= Names.THRESHOLD then
        return best
    end
    return nil
end

local function addVote(votes, english, translated)
    local counts = votes[english]
    if counts == nil then
        counts = {}
        votes[english] = counts
    end
    counts[translated] = (counts[translated] or 0) + 1
end

-- ----------------------------------------------------------------- the walk

local Scan = {}
Scan.__index = Scan

-- game: ids(type) -> ascending array of ids | nil; raw(type, id, field) -> the English base value;
-- get(type, id, field) -> the value in the game's language (the English one where nothing is translated);
-- now() -> milliseconds; release(type) drops the caches the walk filled.
function Names.newScan(game)
    local scan = setmetatable({}, Scan)
    scan.game = game
    scan.phase = 1
    scan.position = 1
    scan.ids = nil
    scan.processed = 0
    scan.total = 0
    scan.done = false
    scan.failed = nil
    scan.votes = { Npc = { name = {}, subName = {} }, Object = { name = {} } }
    scan.items = {}
    scan.untranslated = { Npc = {}, Object = {}, subName = {} }
    for _, phase in ipairs(PHASES) do
        local ids = game.ids(phase.type)
        if type(ids) == "table" then
            scan.total = scan.total + #ids
        end
    end
    return scan
end

-- Reads one entry: its English text and its text in the game's language, into the votes or the lists of what has no
-- translation.
function Scan:read(phase, id)
    local game = self.game
    local typeName = phase.type
    local english = game.raw(typeName, id, "name")
    if isText(english) then
        local localized = game.get(typeName, id, "name")
        local translated = isText(localized) and localized ~= english
        if typeName == "Item" then
            -- only the names of items are wanted, and only when every item of that name agrees
            if translated then
                local known = self.items[english]
                if known == nil then
                    self.items[english] = localized
                elseif known ~= localized then
                    self.items[english] = false
                end
            end
        elseif translated then
            addVote(self.votes[typeName].name, english, localized)
        else
            self.untranslated[typeName][id] = english
        end
    end
    if typeName == "Npc" then
        local title = game.raw(typeName, id, "subName")
        if isText(title) then
            local localizedTitle = game.get(typeName, id, "subName")
            if isText(localizedTitle) and localizedTitle ~= title then
                addVote(self.votes.Npc.subName, title, localizedTitle)
            else
                self.untranslated.subName[id] = title
            end
        end
    end
end

-- Goes on for about budget milliseconds (at least one entry). True when the walk is over.
function Scan:step(budget)
    if self.done then
        return true
    end
    local game = self.game
    local started = game.now()
    while not self.done do
        local phase = PHASES[self.phase]
        if phase == nil then
            self.done = true
            break
        end
        if self.ids == nil then
            self.ids = game.ids(phase.type) or {}
            self.position = 1
        end
        local id = self.ids[self.position]
        if id == nil then
            if game.release ~= nil then
                game.release(phase.type)
            end
            self.phase = self.phase + 1
            self.ids = nil
        else
            local ok, err = pcall(self.read, self, phase, id)
            if not ok then
                self.errors = (self.errors or 0) + 1
                self.lastError = tostring(err)
                if self.errors > 200 then
                    self.failed = self.lastError
                    self.done = true
                    break
                end
            end
            self.position = self.position + 1
            self.processed = self.processed + 1
            if game.now() - started >= budget then
                break
            end
        end
    end
    return self.done
end

function Scan:progress()
    if self.total <= 0 then
        return 1
    end
    local share = self.processed / self.total
    if share > 1 then
        share = 1
    end
    return share
end

-- ----------------------------------------------------------------- the rows

-- The names to add. sources: nil or a table with lookup(kind, english) -> text, sourceKey (Sources.lua), where kind is
-- "Npc", "Title" or "Object". Returns rows = { Npc = { [id] = { name =, subName = } }, Object = { [id] = { name = } } }
-- and stats = { npcNames, npcTitles, objects, bySource = { [key] = number } }.
function Names.compute(scan, sources)
    local rows = { Npc = {}, Object = {} }
    local stats = { npcNames = 0, npcTitles = 0, objects = 0, bySource = {} }
    local function count(key)
        stats.bySource[key] = (stats.bySource[key] or 0) + 1
    end
    local function outside(kind, english)
        if sources == nil then
            return nil
        end
        local text, key = sources.lookup(kind, english)
        if isText(text) and text ~= english then
            return text, key or "outside"
        end
        return nil
    end

    for id, english in pairs(scan.untranslated.Npc) do
        local name, key = Names.pick(scan.votes.Npc.name[english]), "same-name"
        if name == nil then
            name, key = outside("Npc", english)
        end
        if name ~= nil then
            rows.Npc[id] = { name = name }
            stats.npcNames = stats.npcNames + 1
            count(key)
        end
    end
    for id, english in pairs(scan.untranslated.subName) do
        local title, key = Names.pick(scan.votes.Npc.subName[english]), "same-name"
        if title == nil then
            title, key = outside("Title", english)
        end
        if title ~= nil then
            local row = rows.Npc[id]
            if row == nil then
                row = {}
                rows.Npc[id] = row
            end
            row.subName = title
            stats.npcTitles = stats.npcTitles + 1
            count(key)
        end
    end
    for id, english in pairs(scan.untranslated.Object) do
        local name, key = Names.pick(scan.votes.Object.name[english]), "same-name"
        if name == nil then
            name, key = outside("Object", english)
        end
        if name == nil then
            local item = scan.items[english]
            if isText(item) then
                name, key = item, "item"
            end
        end
        if name ~= nil then
            rows.Object[id] = { name = name }
            stats.objects = stats.objects + 1
            count(key)
        end
    end
    return rows, stats
end

-- The rows in the shape the database takes: { [id] = { [fieldIndex] = text } } per type. keys: { Npc = { name =,
-- subName = }, Object = { name = } } (the field indexes the database gives).
function Names.corrections(rows, keys)
    local out = { Npc = {}, Object = {} }
    local npcKeys = keys and keys.Npc or {}
    for id, row in pairs(rows.Npc or {}) do
        local converted = {}
        if isText(row.name) and npcKeys.name ~= nil then
            converted[npcKeys.name] = row.name
        end
        if isText(row.subName) and npcKeys.subName ~= nil then
            converted[npcKeys.subName] = row.subName
        end
        if next(converted) ~= nil then
            out.Npc[id] = converted
        end
    end
    local objectKeys = keys and keys.Object or {}
    for id, row in pairs(rows.Object or {}) do
        if isText(row.name) and objectKeys.name ~= nil then
            out.Object[id] = { [objectKeys.name] = row.name }
        end
    end
    return out
end

-- How many rows of each kind (for a cache that came back from the saved variables).
function Names.countRows(rows)
    local npcNames, npcTitles, objects = 0, 0, 0
    for _, row in pairs(rows and rows.Npc or {}) do
        if row.name ~= nil then
            npcNames = npcNames + 1
        end
        if row.subName ~= nil then
            npcTitles = npcTitles + 1
        end
    end
    for _ in pairs(rows and rows.Object or {}) do
        objects = objects + 1
    end
    return npcNames, npcTitles, objects
end

-- A cache is good for this game when its version, language and stamp all agree and it has its rows.
function Names.cacheMatches(cache, locale, stamp)
    return type(cache) == "table"
        and cache.version == Names.VERSION
        and cache.locale == locale
        and cache.stamp == stamp
        and type(cache.rows) == "table"
end
