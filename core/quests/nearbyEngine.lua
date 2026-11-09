-- Which nearby quest points ping now, for the Nearby quest sounds. The game layer (nearbySounds.lua) builds the
-- catalog of points from the quest data and feeds in the player's position every tenth of a second; this decides
-- what to play. The rule is Sku's quest notification beacon, reproduced as it is: a point pings once its interval
-- has run since it came into range, only while it is in front of the player, and with "once" it is done after one
-- ping until the player leaves the zone. Pure: no WoW API, so the headless tests run it.
local Engine = {}
Engine.__index = Engine
WowVision.quests.NearbyEngine = Engine

local floor, abs, sqrt, deg = math.floor, math.abs, math.sqrt, math.deg
local atan2 = math.atan2 or math.atan

-- The near list keeps a point's spawns within range + this; the list is rebuilt after the player moved REFRESH_MOVE.
-- The margin is wider than the move, so no spawn in range is ever missing from the list.
local NEAR_MARGIN = 50
local REFRESH_MOVE = 25
-- An objective with many spawns is done again once the player is this far past its range.
local REARM_MARGIN = 30
-- Sku's cut-off: from this level on a target is too far to the side to ping.
local MAX_LEVEL = 30

function Engine.new()
    return setmetatable({
        catalog = {},
        near = nil,
        refreshed = nil,
        state = {},
        lastPing = nil,
    }, Engine)
end

-- Sku's beacon level for a target: a distance bucket (5 yards a step) plus a step for every 3 degrees beyond 20 off
-- the facing. Nil when it is 30 or more (the target is behind, or far to the side, so it stays quiet).
function Engine.level(distance, angle)
    local level = floor((distance + 1) / 5)
    local off = abs(angle)
    if off > 20 then
        level = level + floor((off - 20) / 3)
    end
    if level < 0 then
        level = 0
    end
    if level >= MAX_LEVEL then
        return nil
    end
    return level
end

-- Seconds between pings: one a second up close, one in 5.5 seconds far away.
function Engine.interval(distance)
    local interval = distance / 15
    if interval < 1.0 then
        return 1.0
    elseif interval > 5.5 then
        return 5.5
    end
    return interval
end

-- Degrees to a point relative to where the player faces, in (-180, 180]: 0 ahead, positive to the right. The same
-- math as Beacon:compute in core/navigation/maps/Beacon.lua, which the sound files are authored for.
function Engine.relativeAngle(px, py, facing, x, y)
    local bearing = -deg(atan2(y - py, x - px))
    local facingDeg = deg(facing)
    if facingDeg > 180 then
        facingDeg = facingDeg - 360
    end
    local relative = bearing + facingDeg
    if relative > 180 then
        relative = relative - 360
    elseif relative <= -180 then
        relative = relative + 360
    end
    return relative
end

-- points: { { key, kind = "available" | "turnIn" | "objective", questIds = { id, ... }, titles = { ... },
-- spawns = { { x, y, continent }, ... } }, ... }. State by key stays: a swap of the catalog is no new walk.
function Engine:setCatalog(points)
    self.catalog = points or {}
    self.near = nil
end

-- A new zone: every point may ping again.
function Engine:resetMap()
    self.state = {}
end

function Engine:clear()
    self.catalog = {}
    self.near = nil
    self.refreshed = nil
    self.state = {}
    self.lastPing = nil
end

local function distanceTo(px, py, spawn)
    local dx, dy = spawn.x - px, spawn.y - py
    return sqrt(dx * dx + dy * dy)
end

-- Each point with a spawn on the player's continent in reach, holding only those spawns. O(all spawns), so it
-- runs when the player has moved, not every tick.
function Engine:refresh(player, opts)
    local near = {}
    local present = {}
    for _, point in ipairs(self.catalog) do
        local settings = opts[point.kind]
        local reach = (settings ~= nil and settings.range or 0) + NEAR_MARGIN
        local spawns = nil
        for _, spawn in ipairs(point.spawns) do
            if spawn.continent == player.continent and distanceTo(player.x, player.y, spawn) <= reach then
                spawns = spawns or {}
                spawns[#spawns + 1] = spawn
            end
        end
        if spawns ~= nil then
            near[#near + 1] = { point = point, spawns = spawns }
            present[point.key] = true
        end
    end
    -- An objective that left the near list is forgotten: it pings again on the way back.
    for key in pairs(self.state) do
        if not present[key] and key:sub(1, 10) == "objective:" then
            self.state[key] = nil
        end
    end
    self.near = near
    self.refreshed = { x = player.x, y = player.y, continent = player.continent }
end

local function needsRefresh(self, player)
    local last = self.refreshed
    if self.near == nil or last == nil or last.continent ~= player.continent then
        return true
    end
    local dx, dy = player.x - last.x, player.y - last.y
    return sqrt(dx * dx + dy * dy) >= REFRESH_MOVE
end

local function nearest(entry, player)
    local best, bestSpawn = nil, nil
    for _, spawn in ipairs(entry.spawns) do
        local distance = distanceTo(player.x, player.y, spawn)
        if best == nil or distance < best then
            best, bestSpawn = distance, spawn
        end
    end
    return best, bestSpawn
end

local function hasNewQuest(point, state)
    for _, questId in ipairs(point.questIds) do
        if not state.seen[questId] then
            return true
        end
    end
    return false
end

local function remember(point, state)
    state.seen = state.seen or {}
    for _, questId in ipairs(point.questIds) do
        state.seen[questId] = true
    end
end

-- player = { x, y, continent, facing }; now in seconds. opts = { available = { range, once }, turnIn = { ... },
-- objective = { ... }, stopDistance, gap }. Returns the one ping due, { point, angle, distance, level }, or nil.
function Engine:tick(player, now, opts)
    if needsRefresh(self, player) then
        self:refresh(player, opts)
    end
    local best = nil
    for _, entry in ipairs(self.near) do
        local point = entry.point
        local settings = opts[point.kind]
        local range = settings.range
        local state = self.state[point.key]
        if state == nil then
            state = {}
            self.state[point.key] = state
        end
        local distance, spawn = nearest(entry, player)
        -- Many spawns would give an objective a ping in every zone; once the player left the area it is fresh.
        if state.done and point.kind == "objective" and distance > range + REARM_MARGIN then
            state.done, state.since, state.seen = nil, nil, nil
        end
        if distance > range then
            state.since = nil
        else
            -- a giver with a new quest pings again
            if state.done and hasNewQuest(point, state) then
                state.done, state.since = nil, nil
            end
            if not state.done then
                if distance < opts.stopDistance then
                    state.done = true
                    state.since = nil
                    remember(point, state)
                else
                    state.since = state.since or now
                    local angle = Engine.relativeAngle(player.x, player.y, player.facing, spawn.x, spawn.y)
                    local level = Engine.level(distance, angle)
                    if level ~= nil and now - state.since >= Engine.interval(distance) then
                        if best == nil or distance < best.distance then
                            best = { point = point, angle = angle, distance = distance, level = level, state = state }
                        end
                    end
                end
            end
        end
    end
    if best == nil then
        return nil
    end
    if self.lastPing ~= nil and now - self.lastPing < opts.gap then
        return nil
    end
    self.lastPing = now
    best.state.since = now
    remember(best.point, best.state)
    if opts[best.point.kind].once then
        best.state.done = true
    end
    best.state = nil
    return { point = best.point, angle = best.angle, distance = best.distance, level = best.level }
end
