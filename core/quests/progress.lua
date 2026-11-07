-- Quest progress: compares one reading of the quest log with the last and
-- says which quests moved forward. Plain Lua over gameQuestLog's shape
-- ({ questId, complete, objectives = { { text, finished, collected?, needed? } } }),
-- so it is headless-testable; the quests module feeds it on every quest
-- log change and plays a sound per result.
--
--   local tracker = WowVision.quests.ProgressTracker:new()
--   tracker:update(entries)  -> { { questId = 123, kind = "progress" | "complete" }, ... }
--   tracker.loading          true when the last reading had a quest whose
--                            objectives the game has not delivered yet
--
-- The first reading only remembers; so does the first reading of a quest
-- that was not in the log before (just accepted). A quest counts as moved
-- forward when an objective's count went up, an objective became finished,
-- or (for objectives that carry no count) its text changed. A quest that
-- moved forward and is now complete, while it was not before, reports
-- "complete" instead of "progress". Counts going down (an item sold or
-- destroyed) stay silent. Quests that left the log are forgotten.
WowVision.quests = WowVision.quests or {}

local ProgressTracker = {}
ProgressTracker.__index = ProgressTracker
WowVision.quests.ProgressTracker = ProgressTracker

function ProgressTracker:new()
    return setmetatable({ quests = nil }, self)
end

local function isSecret(value)
    return WowVision.isSecret ~= nil and WowVision.isSecret(value) == true
end

-- The count of an objective: the game's numbers when it gives them, else
-- the "3/8" in its text (Classic's leaderboard text, "Kobold Candle: 3/8").
local function countOf(objective)
    local collected = objective.collected
    if type(collected) == "number" then
        return collected
    end
    local text = objective.text
    if type(text) == "string" and not isSecret(text) then
        local have = text:match("(%d+)%s*/%s*%d+")
        if have ~= nil then
            return tonumber(have)
        end
    end
    return nil
end

-- A snapshot is "loading" while the game has not delivered the quest's
-- objectives yet: none at all on a quest that is not complete, or an
-- objective without text. Right after accepting, the client can list the
-- quest before its objective data arrives, and nothing may announce the
-- arrival; the module re-reads until it is there, so the first kill has
-- a count to compare with.
local function snapshot(entry)
    local objectives = {}
    local allFinished = true
    local loading = false
    for index, objective in ipairs(entry.objectives or {}) do
        local text = objective.text
        if isSecret(text) then
            text = nil
        elseif text == nil or text == "" then
            -- Not delivered yet: no text to compare with.
            text = nil
            loading = true
        end
        objectives[index] = {
            text = text,
            finished = objective.finished == true,
            count = countOf(objective),
        }
        if objective.finished ~= true then
            allFinished = false
        end
    end
    local complete = entry.complete == true or (#objectives > 0 and allFinished)
    if #objectives == 0 and not complete then
        loading = true
    end
    return { objectives = objectives, complete = complete, loading = loading }
end

-- Whether one objective moved forward from before to now.
local function advanced(before, now)
    if before == nil then
        -- An objective that was not there (the log read short): no claim.
        return false
    end
    if now.finished and not before.finished then
        return true
    end
    if before.count ~= nil and now.count ~= nil then
        return now.count > before.count
    end
    if before.text ~= nil and now.text ~= nil then
        return now.text ~= before.text
    end
    return false
end

function ProgressTracker:update(entries)
    local results = {}
    local current = {}
    local first = self.quests == nil
    self.loading = false
    for _, entry in ipairs(entries or {}) do
        local questId = entry.questId
        if questId ~= nil then
            local now = snapshot(entry)
            if now.loading then
                self.loading = true
            end
            local before = not first and self.quests[questId] or nil
            if before ~= nil then
                local moved = false
                for index, objective in ipairs(now.objectives) do
                    local old = before.objectives[index]
                    if advanced(old, objective) then
                        moved = true
                    end
                    -- An unreadable (secret) text keeps the last readable one.
                    if objective.text == nil and old ~= nil then
                        objective.text = old.text
                    end
                end
                if now.complete and not before.complete then
                    table.insert(results, { questId = questId, kind = "complete" })
                elseif moved then
                    table.insert(results, { questId = questId, kind = "progress" })
                end
            end
            current[questId] = now
        end
    end
    self.quests = current
    return results
end

-- Forget everything: the next reading only remembers again.
function ProgressTracker:reset()
    self.quests = nil
end
