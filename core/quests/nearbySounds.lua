local quests = WowVision.base.quests
local module = quests:createModule("nearby")
local L = module.L
module:setLabel(L["Nearby"])
local settings = module:hasSettings()

-- Nearby quest sounds: walking around, you hear the quests near you as
-- one-shot directional pings, from Questie's data. Three kinds, each its own
-- alert: a quest you can accept (its giver is close), a quest ready to hand
-- in (its finisher is close), and an open objective of a quest in your log.
-- The first two are Sku's quest notifications, with its sounds and timing
-- (nearbyEngine.lua has the rule); the objective sound is new.
--
-- The module's Enabled switch turns the whole feature off. Level floor and
-- repeatable quests follow the Quests module's Nearby settings, and holiday
-- quests only count while their event runs. Without Questie it stays silent.

local floor, min, max = math.floor, math.min, math.max
local Output = WowVision.alerts.Output

-- A beacon ping at a loudness level. The Beacon output is a continuous
-- guide with a distance scale of its own; here the engine hands over Sku's
-- level directly, and the volume turns the whole sound down one level per
-- 10 below 100, as Sku's beacon volume does.
local QuestBeacon = WowVision.alerts:createOutput("QuestBeacon")
QuestBeacon:addFields({
    { key = "beacon" },
    { key = "volume" },
})

function QuestBeacon:initialize(info)
    Output.initialize(self, info)
    self:addParameter({
        key = "beacon",
        type = "DataBrowse",
        label = L["Beacon Sound"],
        directory = function()
            return WowVision.audio:getPath("Beacon")
        end,
        default = function()
            return self.beacon
        end,
    })
    self:addParameter({
        key = "volume",
        type = "Number",
        label = L["Quest Sound Volume"],
        min = 10,
        max = 100,
        step = 10,
        default = function()
            return self.volume or 100
        end,
    })
end

function QuestBeacon:onFire(message)
    if self.db == nil or self.db.beacon == nil then
        return
    end
    local directory = WowVision.audio:getPath("Beacon")
    if directory == nil then
        return
    end
    local source = directory:getPath(self.db.beacon)
    if source == nil or source.getFile == nil then
        return
    end
    local level = floor(message.level + (100 - (self.db.volume or 100)) / 10)
    level = max(1, min(source.maxDistance, level))
    PlaySoundFile(source:getFile(message.angle, level), WowVision.audio.channel())
end

-- Sku's sound sets and volumes for the first two; the third is the probe
-- sound of Sku's Beacon 2, which nothing else here plays.
local function addQuestAlert(key, label, beacon, volume)
    local alert = module:addAlert({ key = key, label = label })
    alert:addOutput({
        type = "QuestBeacon",
        key = "beacon",
        label = L["Beacon Sound"],
        beacon = beacon,
        volume = volume,
    })
    -- Sku's chat line for the same ping, off to start with.
    alert:addOutput({
        type = "TTS",
        key = "tts",
        label = L["TTS Alert"],
        enabled = false,
        buildMessage = function(self, message)
            return message.text
        end,
    })
    settings:addRef(key .. "Alert", alert.parameters)
end

addQuestAlert("availableQuest", L["Available Quest Sound"], "WowVision/Notification_soft_100", 30)
addQuestAlert("turnInQuest", L["Turn-In Quest Sound"], "WowVision/steel_gong", 40)
addQuestAlert("questObjective", L["Quest Objective Sound"], "WowVision/probe_deep_1", 30)

local function addRange(key, label, default)
    settings:add({ key = key, type = "Number", label = label, default = default, min = 5, max = 200, step = 5 })
end
local function addOnce(key, label)
    settings:add({ key = key, type = "Bool", label = label, default = true })
end
addRange("availableRange", L["Available Quest Range"], 40)
addRange("turnInRange", L["Turn-In Quest Range"], 60)
addRange("objectiveRange", L["Quest Objective Range"], 50)
addOnce("availableOnce", L["Play Available Quests Once"])
addOnce("turnInOnce", L["Play Turn-In Quests Once"])
addOnce("objectiveOnce", L["Play Quest Objectives Once"])
settings:add({
    key = "stopDistance",
    type = "Number",
    label = L["Silence Distance"],
    default = 5,
    min = 1,
    max = 30,
    step = 1,
})

local engine = WowVision.quests.NearbyEngine.new()

-- ---- the catalog: every point a ping can come from ----
--
-- Built in slices of a couple of milliseconds a frame (hundreds of quests
-- would hitch otherwise), then handed to the engine whole. A build starts
-- shortly after anything that can change it, and every 30 seconds, since
-- Questie's set of available quests changes without a word. The quest log
-- event comes many times a minute while questing, so builds start at least
-- REBUILD_GAP apart, and a finished build always counts: dropping one for a
-- change made while it ran could leave the catalog empty for as long as the
-- events keep coming.

local SLICE_MS = 2
local REBUILD_DELAY = 1
local REBUILD_GAP = 5
local REBUILD_EVERY = 30
local TICK_EVERY = 0.1
local PING_GAP = 0.3

-- The catalog being built: { jobs, cursor, points, order, ctx }.
local build = nil
local dirtyAt = nil
local lastBuildStart = nil
local lastTick = 0

-- Questie's data answers: an adapter whose backend knows holiday events.
local function activeAdapter()
    local adapter = quests.adapter
    if adapter == nil or adapter.backend == nil or adapter.backend.isDoable == nil then
        return nil
    end
    if not quests:isReady() then
        return nil
    end
    return adapter
end

-- Rebuild soon; never later than a rebuild already due.
local function markDirty(now)
    local at = (now or GetTime()) + REBUILD_DELAY
    if dirtyAt == nil or at < dirtyAt then
        dirtyAt = at
    end
end

-- A point of the catalog, merged by key: several quests at one giver are one
-- point, as Sku has it (one ping for the giver).
local function pointFor(job, key, kind)
    local point = job.points[key]
    if point == nil then
        point = { key = key, kind = kind, questIds = {}, titles = {}, spawns = {}, spawnSeen = {} }
        job.points[key] = point
        tinsert(job.order, point)
    end
    return point
end

local function addQuest(point, questId, title)
    for _, id in ipairs(point.questIds) do
        if id == questId then
            return
        end
    end
    tinsert(point.questIds, questId)
    tinsert(point.titles, title or "")
end

-- The spawns that count: on the player's continent, and not phased out.
local function addSpawns(point, spawns, continent)
    for _, spawn in ipairs(spawns or {}) do
        if spawn.phased ~= true and spawn.continent == continent then
            local spawnKey = spawn.wx .. ":" .. spawn.wy
            if not point.spawnSeen[spawnKey] then
                point.spawnSeen[spawnKey] = true
                tinsert(point.spawns, { x = spawn.wx, y = spawn.wy, continent = spawn.continent })
            end
        end
    end
end

local function eventInactive(backend, questId)
    return backend.eventInactive ~= nil and backend.eventInactive(questId)
end

-- A quest in the log that is complete: the place to hand it in.
local function turnInJob(adapter, backend, entry)
    return function(job)
        local questId = entry.questId
        if eventInactive(backend, questId) then
            -- a holiday quest may still be handed in once its event is over
            if backend.canTurnInOutsideEvent == nil or not backend.canTurnInOutsideEvent(questId) then
                return
            end
        end
        for _, target in ipairs(adapter:targets(questId, "finish", job.ctx)) do
            if target.distance ~= nil then
                local point = pointFor(job, "turnIn:" .. target.kind .. ":" .. target.id, "turnIn")
                addQuest(point, questId, entry.title)
                addSpawns(point, target.spawns, job.ctx.continent)
                return
            end
        end
    end
end

-- A quest in the log with open objectives: the places they send you, a
-- point per objective. An objective with no index is the trigger spot of a
-- reach-this-place quest.
local function objectiveJob(adapter, backend, entry)
    return function(job)
        local questId = entry.questId
        if eventInactive(backend, questId) then
            return
        end
        for _, target in ipairs(adapter:targets(questId, "objectives", job.ctx)) do
            local index = target.objectiveIndex
            local objective = index ~= nil and entry.objectives[index] or nil
            if index == nil or (objective ~= nil and not objective.finished) then
                local point = pointFor(job, "objective:" .. questId .. ":" .. tostring(index or "spot"), "objective")
                addQuest(point, questId, entry.title)
                addSpawns(point, target.spawns, job.ctx.continent)
            end
        end
    end
end

-- A quest the player could accept: where its giver stands.
local function availableJob(adapter, questId)
    return function(job)
        local entry = adapter:availableEntry(questId, job.opts, job.ctx)
        if entry == nil or entry.starter.item ~= nil then
            -- a quest started by a dropped item has no giver to walk to
            return
        end
        local starter = entry.starter
        local point = pointFor(job, "available:" .. starter.kind .. ":" .. starter.id, "available")
        addQuest(point, questId, entry.name)
        addSpawns(point, starter.spawns, job.ctx.continent)
    end
end

local function startBuild(adapter)
    local ctx = adapter:_playerContext()
    if ctx == nil or ctx.x == nil then
        return nil
    end
    local backend = adapter.backend
    local job = {
        jobs = {},
        cursor = 1,
        points = {},
        order = {},
        ctx = ctx,
        opts = {
            levelRange = quests.settings.levelRange,
            includeRepeatable = quests.settings.includeRepeatable,
        },
    }
    for _, entry in ipairs(WowVision.quests.gameQuestLog()) do
        if not entry.failed then
            if entry.complete then
                tinsert(job.jobs, turnInJob(adapter, backend, entry))
            else
                tinsert(job.jobs, objectiveJob(adapter, backend, entry))
            end
        end
    end
    -- The candidate list is read in a job of its own (a zone scan on first
    -- use), and adds one job per quest.
    tinsert(job.jobs, function(self)
        for _, questId in ipairs(adapter:_candidateIds(ctx.areaId)) do
            tinsert(self.jobs, availableJob(adapter, questId))
        end
    end)
    return job
end

-- Runs jobs until the slice is used up; hands the catalog over when done.
local function runBuild()
    local deadline = debugprofilestop() + SLICE_MS
    while build.cursor <= #build.jobs do
        local job = build.jobs[build.cursor]
        build.cursor = build.cursor + 1
        local ok, err = pcall(job, build)
        if not ok then
            geterrorhandler()(err)
        end
        if debugprofilestop() >= deadline then
            return
        end
    end
    local finished = build
    build = nil
    engine:setCatalog(finished.order)
end

-- ---- running ----

local function tickSettings()
    local s = module.settings
    return {
        available = { range = s.availableRange, once = s.availableOnce },
        turnIn = { range = s.turnInRange, once = s.turnInOnce },
        objective = { range = s.objectiveRange, once = s.objectiveOnce },
        stopDistance = s.stopDistance,
        gap = PING_GAP,
    }
end

local alertKeys = { available = "availableQuest", turnIn = "turnInQuest", objective = "questObjective" }

local function pingLabel(kind)
    if kind == "available" then
        return L["Quest available"]
    elseif kind == "turnIn" then
        return L["Quest to turn in"]
    end
    return L["Quest objective"]
end

local function tickEngine(now)
    if UnitOnTaxi("player") or UnitIsDeadOrGhost("player") or UnitAffectingCombat("player") then
        return
    end
    local x, y, _, continent = UnitPosition("player")
    local facing = GetPlayerFacing()
    if x == nil or y == nil or facing == nil then
        return
    end
    local ping = engine:tick({ x = x, y = y, continent = continent, facing = facing }, now, tickSettings())
    if ping == nil then
        return
    end
    local point = ping.point
    module:fireAlert(alertKeys[point.kind], {
        angle = ping.angle,
        level = ping.level,
        distance = ping.distance,
        text = pingLabel(point.kind)
            .. ": "
            .. table.concat(point.titles, ", ")
            .. ", "
            .. floor(ping.distance)
            .. " "
            .. L["yards"],
    })
end

local function update()
    local adapter = activeAdapter()
    if adapter == nil then
        return
    end
    local now = GetTime()
    if lastBuildStart == nil or now - lastBuildStart >= REBUILD_EVERY then
        markDirty(now)
    end
    local gapOver = lastBuildStart == nil or now - lastBuildStart >= REBUILD_GAP
    if build == nil and dirtyAt ~= nil and now >= dirtyAt and gapOver then
        dirtyAt = nil
        lastBuildStart = now
        build = startBuild(adapter)
        if build == nil then
            -- no position yet
            markDirty(now)
        end
    end
    if build ~= nil then
        runBuild()
    end
    if now - lastTick >= TICK_EVERY then
        lastTick = now
        tickEngine(now)
    end
end

local function onQuestsChanged()
    markDirty()
end

module:registerEvent("event", "QUEST_LOG_UPDATE")
module:registerEvent("event", "PLAYER_LEVEL_UP")
module:registerEvent("event", "ZONE_CHANGED_NEW_AREA")
module:registerEvent("event", "PLAYER_ENTERING_WORLD")

function module:onEvent(event)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        engine:resetMap()
    end
    markDirty()
end

function module:onEnable()
    quests.events.ready:subscribe(self, onQuestsChanged)
    quests.events.questUpdate:subscribe(self, onQuestsChanged)
    lastBuildStart = nil
    self:hasUpdate(function()
        update()
    end)
end

function module:onDisable()
    quests.events.ready:unsubscribe(self)
    quests.events.questUpdate:unsubscribe(self)
    engine:clear()
    build = nil
    dirtyAt = nil
end
