-- The quest data adapter: answers "what quests are nearby", "what is in my
-- log and how far along", and "where do I go for this quest" over a BACKEND
-- that supplies the raw data. The backend is injected so the logic here is
-- plain Lua (headless-testable with a fake); in game the backend is Questie
-- (questie.lua), the only file that touches Questie's internals.
--
-- Backend contract -- every function is plain and may return nil:
--   isReady()                 -> bool; nothing below is called until true
--   quest(id)                 -> { id, name, level, requiredLevel, repeatable,
--                                  starts = { npc = ids?, object = ids?, item = ids? },
--                                  finishers = { npc = ids?, object = ids? },
--                                  objectives = { { type, id, text, idList?, rootId? }, ... }
--                                    (type: monster | object | item | reputation |
--                                     killcredit | spell; order = quest log order),
--                                  triggerEnd = { text, { [areaId] = { {x, y}, ... } } }?,
--                                  zone = areaId? }
--   npc(id)                   -> { id, name, subName?, spawns = { [areaId] = { {x, y}, ... } }?, zone? }
--   object(id)                -> { id, name, spawns?, zone? }
--   item(id)                  -> { id, name, npcDrops?, objectDrops?, vendors? }
--   isDoable(id)              -> bool: the player is eligible right now
--   eventInactive(id)         -> bool (optional): a holiday quest whose event is not running
--   canTurnInOutsideEvent(id) -> bool (optional): such a quest that may still be handed in
--   availableQuestIds()       -> set { [id] = true } the backend maintains, or nil
--   allQuestIds()             -> array of every quest id (fallback scan)
--   questZone(id)             -> areaId the quest belongs to (cheap single read)
--   mapForArea(areaId)        -> uiMapId, or nil for non-world areas
--   spawnVisible(phase)       -> false when a spawn's phase is hidden for this character (optional)
--   worldPosition(mapId, x, y)-> continent, wx, wy for map-percent x, y
--   player()                  -> { x, y, continent, mapId, areaId, level }
--   questMarkers(id, index)   -> { name?, spawns = { [areaId] = { {x, y}, ... } } } (optional):
--                                the map markers of one objective of a quest in the log
--   questPoint(id)            -> mapId, x, y (optional): the game's own marker for a
--                                quest in the log, in map percent
--   questLog()                -> { { questId, title, level, complete, failed,
--                                    objectives = { { text, type, finished, collected, needed }, ... } }, ... }
--
-- Coordinates follow the codebase convention: wx, wy are what
-- GetWorldPosFromMapPos yields and UnitPosition returns, so distances are
-- plain Euclidean and Beacon consumes them directly.
WowVision.quests = WowVision.quests or {}

local Adapter = WowVision.Class("QuestAdapter")
WowVision.quests.Adapter = Adapter

Adapter.phases = { start = "start", objectives = "objectives", finish = "finish" }

function Adapter:initialize(backend)
    self.backend = backend
    self._zoneScan = nil
    self._worldCache = {}
    -- Resolved (unranked) targets by id: spawn lists never change within a
    -- session, so a creature looked up once serves every later query.
    self._targets = { npc = {}, object = {} }
end

function Adapter:isReady()
    return self.backend ~= nil and self.backend.isReady() == true
end

-- ---- positions ----

-- Map-percent to world, memoized: the conversion is deterministic and the
-- same spawn resolves on every query.
function Adapter:_toWorld(mapId, x, y)
    local byMap = self._worldCache[mapId]
    if byMap == nil then
        byMap = {}
        self._worldCache[mapId] = byMap
    end
    local key = x * 1000 + y
    local hit = byMap[key]
    if hit ~= nil then
        if hit == false then
            return nil
        end
        return hit.continent, hit.wx, hit.wy
    end
    local continent, wx, wy = self.backend.worldPosition(mapId, x, y)
    if wx == nil or wy == nil then
        byMap[key] = false
        return nil
    end
    byMap[key] = { continent = continent, wx = wx, wy = wy }
    return continent, wx, wy
end

-- Every spawn of a spawn list as a world position. Spawns in non-world
-- areas (instances the map API cannot place) and unknown positions (-1)
-- are dropped. Spawns the backend reports phased out for this character
-- (spawnVisible on the spawn's phase, its third value) are KEPT but
-- flagged `phased`: the phase rules are the backend's best guess from
-- quest flags, and an NPC that moves around must stay findable when the
-- guess is wrong. Ranking prefers unphased spawns.
function Adapter:_resolveSpawns(spawnsByArea)
    local result = {}
    if spawnsByArea == nil then
        return result
    end
    local spawnVisible = self.backend.spawnVisible
    for areaId, list in pairs(spawnsByArea) do
        local mapId = self.backend.mapForArea(areaId)
        if mapId ~= nil then
            for _, pair in ipairs(list) do
                local x, y, phase = pair[1], pair[2], pair[3]
                if x ~= nil and y ~= nil and x >= 0 and y >= 0 then
                    local continent, wx, wy = self:_toWorld(mapId, x, y)
                    if wx ~= nil then
                        local visible = spawnVisible == nil or spawnVisible(phase) ~= false
                        tinsert(result, {
                            areaId = areaId,
                            mapId = mapId,
                            x = x,
                            y = y,
                            wx = wx,
                            wy = wy,
                            continent = continent,
                            phased = not visible,
                        })
                    end
                end
            end
        end
    end
    return result
end

local function distanceBetween(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

-- Spawn order: unphased before phased, then nearest first; spawns with no
-- distance (another continent) last.
local function spawnBefore(a, b)
    if (a.phased == true) ~= (b.phased == true) then
        return b.phased == true
    end
    if a.distance == nil then
        return false
    end
    if b.distance == nil then
        return true
    end
    return a.distance < b.distance
end
Adapter.spawnBefore = spawnBefore

-- Stamp each same-continent spawn with its distance from the player and
-- pick the best as the target's headline position: the nearest unphased
-- spawn, else the nearest phased one.
local function rank(target, ctx)
    target.nearest = nil
    target.distance = nil
    if ctx == nil or ctx.x == nil then
        return target
    end
    for _, spawn in ipairs(target.spawns) do
        if spawn.continent == ctx.continent then
            spawn.distance = distanceBetween(ctx.x, ctx.y, spawn.wx, spawn.wy)
            if target.nearest == nil or spawnBefore(spawn, target.nearest) then
                target.distance = spawn.distance
                target.nearest = spawn
            end
        else
            spawn.distance = nil
        end
    end
    return target
end

function Adapter:_playerContext()
    return self.backend.player() or {}
end

-- Where the player stands now ({ x, y, continent, ... } as the backend's
-- player() gives it), for callers that rank their own nodes.
function Adapter:playerContext()
    return self:_playerContext()
end

-- Nodes nearest first. A node is anything with world coordinates x and y (a
-- scanner node); player is { x, y }. A node with no position (nothing known
-- to walk to, or another continent) goes after every node that has one, and
-- nodes at the same distance, or without a position, keep the order they
-- came in. Without a player position the list is returned as it is.
function Adapter.sortByProximity(nodes, player)
    if player == nil or player.x == nil or player.y == nil then
        return nodes
    end
    local ranked = {}
    for index, node in ipairs(nodes) do
        local distance = nil
        if node.x ~= nil and node.y ~= nil then
            distance = distanceBetween(player.x, player.y, node.x, node.y)
        end
        ranked[index] = { node = node, index = index, distance = distance }
    end
    table.sort(ranked, function(a, b)
        if a.distance ~= nil and b.distance ~= nil and a.distance ~= b.distance then
            return a.distance < b.distance
        end
        if (a.distance == nil) ~= (b.distance == nil) then
            return a.distance ~= nil
        end
        return a.index < b.index
    end)
    local sorted = {}
    for index, entry in ipairs(ranked) do
        sorted[index] = entry.node
    end
    return sorted
end

-- ---- targets: the places a quest sends you ----

local function copyTarget(source)
    local copy = {}
    for k, v in pairs(source) do
        copy[k] = v
    end
    -- Spawns carry per-query distances; give each copy its own list.
    local spawns = {}
    for i, spawn in ipairs(source.spawns) do
        local s = {}
        for k, v in pairs(spawn) do
            s[k] = v
        end
        spawns[i] = s
    end
    copy.spawns = spawns
    return copy
end

function Adapter:_npcTarget(id, ctx)
    local memo = self._targets.npc[id]
    if memo == nil then
        local npc = self.backend.npc(id)
        if npc == nil then
            self._targets.npc[id] = false
            return nil
        end
        memo = {
            kind = "npc",
            id = id,
            name = npc.name,
            subName = npc.subName,
            spawns = self:_resolveSpawns(npc.spawns),
        }
        self._targets.npc[id] = memo
    elseif memo == false then
        return nil
    end
    return rank(copyTarget(memo), ctx)
end

function Adapter:_objectTarget(id, ctx)
    local memo = self._targets.object[id]
    if memo == nil then
        local object = self.backend.object(id)
        if object == nil then
            self._targets.object[id] = false
            return nil
        end
        memo = { kind = "object", id = id, name = object.name, spawns = self:_resolveSpawns(object.spawns) }
        self._targets.object[id] = memo
    elseif memo == false then
        return nil
    end
    return rank(copyTarget(memo), ctx)
end

-- An item is reached through whatever yields it: the creatures and objects
-- it drops from, and the vendors selling it. Each source target carries the
-- item it is for.
function Adapter:_itemTargets(id, ctx, out)
    local item = self.backend.item(id)
    if item == nil then
        return
    end
    local via = { id = id, name = item.name }
    for _, npcId in ipairs(item.npcDrops or {}) do
        local target = self:_npcTarget(npcId, ctx)
        if target ~= nil then
            target.item = via
            target.source = "drop"
            tinsert(out, target)
        end
    end
    for _, objectId in ipairs(item.objectDrops or {}) do
        local target = self:_objectTarget(objectId, ctx)
        if target ~= nil then
            target.item = via
            target.source = "contains"
            tinsert(out, target)
        end
    end
    for _, npcId in ipairs(item.vendors or {}) do
        local target = self:_npcTarget(npcId, ctx)
        if target ~= nil then
            target.item = via
            target.source = "vendor"
            tinsert(out, target)
        end
    end
end

function Adapter:_spotTarget(quest, ctx)
    local trigger = quest.triggerEnd
    if trigger == nil then
        return nil
    end
    local target = {
        kind = "spot",
        id = quest.id,
        name = trigger[1] or quest.name,
        spawns = self:_resolveSpawns(trigger[2]),
    }
    return rank(target, ctx)
end

local function addAll(out, ids, resolve)
    for _, id in ipairs(ids or {}) do
        local target = resolve(id)
        if target ~= nil then
            tinsert(out, target)
        end
    end
end

-- Targets for one objective of a quest (index = quest log order).
function Adapter:_objectiveTargets(objective, index, ctx, out)
    local first = #out + 1
    if objective.type == "monster" then
        addAll(out, { objective.id }, function(id)
            return self:_npcTarget(id, ctx)
        end)
    elseif objective.type == "object" then
        addAll(out, { objective.id }, function(id)
            return self:_objectTarget(id, ctx)
        end)
    elseif objective.type == "item" then
        self:_itemTargets(objective.id, ctx, out)
    elseif objective.type == "killcredit" then
        local ids = {}
        for _, id in ipairs(objective.idList or {}) do
            tinsert(ids, id)
        end
        if objective.rootId ~= nil then
            tinsert(ids, objective.rootId)
        end
        addAll(out, ids, function(id)
            return self:_npcTarget(id, ctx)
        end)
    elseif objective.type == "spell" and objective.itemId ~= nil then
        self:_itemTargets(objective.itemId, ctx, out)
    end
    for i = first, #out do
        out[i].objectiveIndex = index
        out[i].objectiveText = objective.text
    end
end

local function sortByDistance(list)
    table.sort(list, function(a, b)
        if a.distance == nil then
            return false
        end
        if b.distance == nil then
            return true
        end
        return a.distance < b.distance
    end)
    return list
end

-- The places a quest phase sends you, nearest first (targets with no
-- spawn on the player's continent sort last, distance nil).
-- phase: "start" (givers), "objectives" (per objective, plus the trigger
-- spot for reach-this-place quests), "finish" (turn-in).
function Adapter:targets(questId, phase, ctx)
    local out = {}
    if not self:isReady() then
        return out
    end
    local quest = self.backend.quest(questId)
    if quest == nil then
        return out
    end
    ctx = ctx or self:_playerContext()
    if phase == Adapter.phases.start then
        local starts = quest.starts or {}
        addAll(out, starts.npc, function(id)
            return self:_npcTarget(id, ctx)
        end)
        addAll(out, starts.object, function(id)
            return self:_objectTarget(id, ctx)
        end)
        for _, itemId in ipairs(starts.item or {}) do
            self:_itemTargets(itemId, ctx, out)
        end
    elseif phase == Adapter.phases.finish then
        local finishers = quest.finishers or {}
        addAll(out, finishers.npc, function(id)
            return self:_npcTarget(id, ctx)
        end)
        addAll(out, finishers.object, function(id)
            return self:_objectTarget(id, ctx)
        end)
    elseif phase == Adapter.phases.objectives then
        for index, objective in ipairs(quest.objectives or {}) do
            self:_objectiveTargets(objective, index, ctx, out)
        end
        local spot = self:_spotTarget(quest, ctx)
        if spot ~= nil then
            tinsert(out, spot)
        end
    else
        error("Unknown quest phase: " .. tostring(phase))
    end
    return sortByDistance(out)
end

-- Targets for a single objective of a quest, nearest first.
function Adapter:objectiveTargets(questId, objectiveIndex, ctx)
    local out = {}
    if not self:isReady() then
        return out
    end
    local quest = self.backend.quest(questId)
    local objective = quest ~= nil and quest.objectives ~= nil and quest.objectives[objectiveIndex] or nil
    if objective == nil then
        return out
    end
    ctx = ctx or self:_playerContext()
    self:_objectiveTargets(objective, objectiveIndex, ctx, out)
    return sortByDistance(out)
end

-- The last resort for an objective with nothing to walk to, after the game's
-- own marker: the markers Questie draws for it (the optional
-- backend.questMarkers), as one target
-- named after what the markers show. Nil when no marker lies on the
-- player's continent.
function Adapter:markerTarget(questId, objectiveIndex, ctx)
    if not self:isReady() or self.backend.questMarkers == nil then
        return nil
    end
    local markers = self.backend.questMarkers(questId, objectiveIndex)
    if markers == nil then
        return nil
    end
    local target = rank({
        kind = "marker",
        id = questId,
        name = markers.name,
        objectiveIndex = objectiveIndex,
        spawns = self:_resolveSpawns(markers.spawns),
    }, ctx or self:_playerContext())
    if target.nearest == nil then
        return nil
    end
    return target
end

-- The first safety net for a quest with nothing to walk to, before Questie's
-- markers: the game's own marker for the quest (the optional
-- backend.questPoint), one point for the quest as a whole. Nil without one
-- on the player's continent.
function Adapter:gameMarkerTarget(questId, ctx)
    if not self:isReady() or self.backend.questPoint == nil then
        return nil
    end
    local mapId, x, y = self.backend.questPoint(questId)
    if mapId == nil or x == nil or y == nil then
        return nil
    end
    local continent, wx, wy = self:_toWorld(mapId, x, y)
    if wx == nil then
        return nil
    end
    local target = rank({
        kind = "gameMarker",
        id = questId,
        spawns = { { mapId = mapId, x = x, y = y, wx = wx, wy = wy, continent = continent } },
    }, ctx or self:_playerContext())
    if target.nearest == nil then
        return nil
    end
    return target
end

-- ---- quests ----

function Adapter:quest(questId)
    if not self:isReady() then
        return nil
    end
    return self.backend.quest(questId)
end

-- What an objective is about, for reading: the target's kind and name.
function Adapter:_describeObjective(objective)
    if objective == nil then
        return nil
    end
    local target = { kind = objective.type, id = objective.id, text = objective.text }
    if objective.type == "monster" then
        local npc = self.backend.npc(objective.id)
        target.kind = "npc"
        target.name = npc ~= nil and npc.name or nil
    elseif objective.type == "object" then
        local object = self.backend.object(objective.id)
        target.name = object ~= nil and object.name or nil
    elseif objective.type == "item" then
        local item = self.backend.item(objective.id)
        target.name = item ~= nil and item.name or nil
    elseif objective.type == "killcredit" then
        target.kind = "npc"
        local npc = objective.rootId ~= nil and self.backend.npc(objective.rootId) or nil
        target.name = npc ~= nil and npc.name or objective.text
    end
    return target
end

-- The quest log with each objective's live progress joined to the
-- database's description of what it targets (same index order). Quests the
-- database does not know still list, with objectives from the game alone.
function Adapter:inProgress()
    local result = {}
    local entries = self.backend.questLog() or {}
    local ready = self:isReady()
    for _, entry in ipairs(entries) do
        local quest = ready and self.backend.quest(entry.questId) or nil
        local objectives = {}
        for index, live in ipairs(entry.objectives or {}) do
            local objective = {
                index = index,
                text = live.text,
                type = live.type,
                finished = live.finished == true,
                collected = live.collected,
                needed = live.needed,
            }
            if quest ~= nil and quest.objectives ~= nil then
                objective.target = self:_describeObjective(quest.objectives[index])
            end
            tinsert(objectives, objective)
        end
        tinsert(result, {
            questId = entry.questId,
            title = entry.title,
            level = entry.level,
            zone = entry.zone,
            complete = entry.complete == true,
            failed = entry.failed == true,
            known = quest ~= nil,
            objectives = objectives,
        })
    end
    return result
end

-- ---- nearby: available quests ranked by distance to their giver ----

-- Candidate ids: the backend's own maintained set when it has one, else
-- the quests filed under the player's zone (scanned once per zone).
function Adapter:_candidateIds(areaId)
    local set = self.backend.availableQuestIds()
    if set ~= nil and next(set) ~= nil then
        local ids = {}
        for id in pairs(set) do
            tinsert(ids, id)
        end
        return ids
    end
    if areaId == nil then
        return {}
    end
    if self._zoneScan == nil or self._zoneScan.areaId ~= areaId then
        local ids = {}
        for _, id in ipairs(self.backend.allQuestIds() or {}) do
            if self.backend.questZone(id) == areaId then
                tinsert(ids, id)
            end
        end
        self._zoneScan = { areaId = areaId, ids = ids }
    end
    return self._zoneScan.ids
end

-- One candidate quest as a nearby entry (see nearbyQuests), or nil when it is
-- not offered to the player: a holiday quest out of season, not doable, below
-- the level floor, repeatable when those are off, or with no reachable giver.
function Adapter:availableEntry(questId, opts, ctx)
    if self.backend.eventInactive ~= nil and self.backend.eventInactive(questId) then
        return nil
    end
    if not self.backend.isDoable(questId) then
        return nil
    end
    local quest = self.backend.quest(questId)
    if quest == nil then
        return nil
    end
    local playerLevel = ctx.level or 0
    local requiredOk = (quest.requiredLevel or 0) <= playerLevel
    local floorOk = opts.levelRange == nil
        or quest.level == nil
        or quest.level < 0
        or quest.level >= playerLevel - opts.levelRange
    local repeatableOk = opts.includeRepeatable == true or quest.repeatable ~= true
    if not (requiredOk and floorOk and repeatableOk) then
        return nil
    end
    local starter = self:targets(questId, Adapter.phases.start, ctx)[1]
    if starter == nil or starter.distance == nil then
        return nil
    end
    return {
        questId = questId,
        name = quest.name,
        level = quest.level,
        requiredLevel = quest.requiredLevel,
        repeatable = quest.repeatable == true,
        daily = quest.daily == true,
        starter = starter,
        distance = starter.distance,
    }
end

-- opts: levelRange (hide quests more than this many levels below the
-- player; nil = no floor), includeRepeatable (default false; dailies are
-- repeatable), maxCount.
-- Each entry: { questId, name, level, requiredLevel, starter = target,
-- distance } with the starter the nearest giver on the player's continent;
-- quests with no reachable giver are omitted.
function Adapter:nearbyQuests(opts)
    opts = opts or {}
    local result = {}
    if not self:isReady() then
        return result
    end
    local ctx = self:_playerContext()
    if ctx.x == nil then
        return result
    end
    for _, questId in ipairs(self:_candidateIds(ctx.areaId)) do
        local entry = self:availableEntry(questId, opts, ctx)
        if entry ~= nil then
            tinsert(result, entry)
        end
    end
    sortByDistance(result)
    if opts.maxCount ~= nil then
        while #result > opts.maxCount do
            tremove(result)
        end
    end
    return result
end

-- ---- places: NPCs and objects by what they are ----

-- Flags are powers of two; avoid depending on a bit library.
local function hasFlag(flags, flag)
    if flags == nil or flag == nil or flag <= 0 then
        return false
    end
    return math.floor(flags / flag) % 2 == 1
end

-- The NPC roles the scanner offers, in display order, each keyed to the
-- backend's flag name. rank 2 and 4 are rare (CMaNGOS creature ranks).
Adapter.roles = {
    { key = "vendor", flag = "VENDOR" },
    { key = "repair", flag = "REPAIR" },
    { key = "trainer", flag = "TRAINER" },
    { key = "flightMaster", flag = "FLIGHT_MASTER" },
    { key = "innkeeper", flag = "INNKEEPER" },
    { key = "banker", flag = "BANKER" },
    { key = "auctioneer", flag = "AUCTIONEER" },
    { key = "stableMaster", flag = "STABLEMASTER" },
    { key = "battlemaster", flag = "BATTLEMASTER" },
    { key = "spiritHealer", flag = "SPIRIT_HEALER" },
}

local function isRare(rankValue)
    return rankValue == 2 or rankValue == 4
end

local function within(target, opts)
    if target.distance == nil then
        return false
    end
    return opts.radius == nil or target.distance <= opts.radius
end

local function cap(list, opts)
    if opts.maxCount ~= nil then
        while #list > opts.maxCount do
            tremove(list)
        end
    end
    return list
end

-- Resolve ids of one kind ("npc" or "object") to targets on the player's
-- continent within opts.radius, nearest first, at most opts.maxCount.
function Adapter:placeTargets(kind, ids, opts, ctx)
    opts = opts or {}
    local out = {}
    if not self:isReady() or ids == nil then
        return out
    end
    ctx = ctx or self:_playerContext()
    for _, id in ipairs(ids) do
        local target
        if kind == "npc" then
            target = self:_npcTarget(id, ctx)
        else
            target = self:_objectTarget(id, ctx)
        end
        if target ~= nil and within(target, opts) then
            tinsert(out, target)
        end
    end
    return cap(sortByDistance(out), opts)
end

-- The NPCs of the player's zone bucketed by role (Adapter.roles keys) plus
-- "rare", each nearest first within opts.radius, at most opts.maxCount.
-- Needs the backend's NPC index (npcsInArea/npcMeta); empty until built.
function Adapter:npcsByRole(opts, ctx)
    opts = opts or {}
    local buckets = {}
    for _, role in ipairs(Adapter.roles) do
        buckets[role.key] = {}
    end
    buckets.rare = {}
    if not self:isReady() or self.backend.npcsInArea == nil then
        return buckets
    end
    ctx = ctx or self:_playerContext()
    local flagValues = self.backend.flags or {}
    for _, id in ipairs(self.backend.npcsInArea(ctx.areaId) or {}) do
        local flags, rankValue = self.backend.npcMeta(id)
        local wanted = {}
        for _, role in ipairs(Adapter.roles) do
            if hasFlag(flags, flagValues[role.flag]) then
                tinsert(wanted, role.key)
            end
        end
        if isRare(rankValue) then
            tinsert(wanted, "rare")
        end
        if #wanted > 0 then
            local target = self:_npcTarget(id, ctx)
            if target ~= nil and within(target, opts) then
                for _, key in ipairs(wanted) do
                    tinsert(buckets[key], target)
                end
            end
        end
    end
    for key, list in pairs(buckets) do
        buckets[key] = cap(sortByDistance(list), opts)
    end
    return buckets
end

-- Forget cached zone scans, positions, and resolved targets (a map change,
-- a DB reload).
function Adapter:invalidate()
    self._zoneScan = nil
    self._worldCache = {}
    self._targets = { npc = {}, object = {} }
end
