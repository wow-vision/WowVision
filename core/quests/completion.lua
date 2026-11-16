-- Which quests turned complete (every objective done, ready to hand in), for the quest complete sound. The game sends
-- no message for that: its progress messages name a count or one objective, never the quest. So the quests module
-- reads each quest's complete flag from the log and hands the states in here. Pure: no WoW API, so the headless
-- tests run it.
local Completion = {}
Completion.__index = Completion
WowVision.quests.Completion = Completion

function Completion.new()
    return setmetatable({ states = nil }, Completion)
end

-- states: { [questId] = { complete = bool, title = string } }, the log as it is now. Returns the quests that turned
-- complete since the last reading, as { questId, title }, by quest id. Only a quest that was in the log before, not
-- complete, counts: a quest accepted already complete (its items already in the bags, a talk-to quest) is not news.
-- The first reading only sets the baseline.
function Completion:update(states)
    local before = self.states
    self.states = states
    local turned = {}
    if before == nil then
        return turned
    end
    for questId, state in pairs(states) do
        local previous = before[questId]
        if state.complete and previous ~= nil and not previous.complete then
            tinsert(turned, { questId = questId, title = state.title })
        end
    end
    table.sort(turned, function(a, b)
        return a.questId < b.questId
    end)
    return turned
end
