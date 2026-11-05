-- Quest progress: what changed in the quest log between two looks at it.
-- Pure Lua (the headless runner covers it); the quests module feeds it the
-- game's own log (WowVision.quests.gameQuestLog) and speaks the changes.
--
-- progress.snapshot(entries)       -> { [questId] = { title, complete, failed, objectives } }
-- progress.changes(before, after)  -> list of changes, in log order:
--   { kind = "objective", questId, title, objectiveIndex, text }          count moved
--   { kind = "objectiveComplete", questId, title, objectiveIndex, text }  objective done
--   { kind = "questComplete", questId, title }                            quest ready to turn in
--
-- A quest missing from either side changes nothing: a new quest is taken
-- as it is (accepting one already done is not progress), a gone one was
-- turned in, abandoned, or is hidden under a collapsed header.
local progress = {}
WowVision.quests = WowVision.quests or {}
WowVision.quests.progress = progress

function progress.snapshot(entries)
    local snapshot = { order = {} }
    for _, entry in ipairs(entries or {}) do
        if entry.questId ~= nil and snapshot[entry.questId] == nil then
            local objectives = {}
            for i, objective in ipairs(entry.objectives or {}) do
                objectives[i] = { text = objective.text, finished = objective.finished == true }
            end
            snapshot[entry.questId] = {
                title = entry.title,
                complete = entry.complete == true,
                failed = entry.failed == true,
                objectives = objectives,
            }
            tinsert(snapshot.order, entry.questId)
        end
    end
    return snapshot
end

function progress.changes(before, after)
    local changes = {}
    if before == nil or after == nil then
        return changes
    end
    for _, questId in ipairs(after.order) do
        local old, new = before[questId], after[questId]
        if old ~= nil then
            for i, objective in ipairs(new.objectives) do
                local was = old.objectives[i]
                if was ~= nil and objective.text ~= nil then
                    if objective.finished and not was.finished then
                        tinsert(changes, {
                            kind = "objectiveComplete",
                            questId = questId,
                            title = new.title,
                            objectiveIndex = i,
                            text = objective.text,
                        })
                    elseif not objective.finished and objective.text ~= was.text then
                        tinsert(changes, {
                            kind = "objective",
                            questId = questId,
                            title = new.title,
                            objectiveIndex = i,
                            text = objective.text,
                        })
                    end
                end
            end
            if new.complete and not new.failed and not old.complete then
                tinsert(changes, { kind = "questComplete", questId = questId, title = new.title })
            end
        end
    end
    return changes
end

-- Carries quests the new look did not list but the player still has (the
-- classic log leaves out quests under a collapsed header) over from the old
-- one, refreshed by `reread(questId, old)` when it returns an entry, so
-- their progress is still compared and a header opened later stays quiet.
function progress.carryOver(before, after, stillOnQuest, reread)
    if before == nil then
        return after
    end
    for _, questId in ipairs(before.order) do
        if after[questId] == nil and stillOnQuest(questId) then
            local old = before[questId]
            local entry = reread ~= nil and reread(questId, old) or nil
            if entry ~= nil then
                entry.questId = questId
                after[questId] = progress.snapshot({ entry })[questId]
            else
                after[questId] = old
            end
            tinsert(after.order, questId)
        end
    end
    return after
end
