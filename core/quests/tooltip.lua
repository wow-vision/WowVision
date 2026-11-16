-- The scanner's quest tooltip (Shift+Down on a quest in Nearby or In
-- Progress): what a sighted player sees at a glance on a quest, as lines.
-- The game's own quest link tooltip says too little on its own (no colour,
-- often no level), so the lines are built here and the link's lines that
-- add something follow them.
--
--   WowVision.quests.tooltipLines(entry, kind, api?) -> { "line", ... }
--
-- entry: a Nearby entry ({ questId, name, level, requiredLevel, daily,
-- repeatable, starter }) or an In Progress entry ({ questId, title, level,
-- complete, failed, objectives }); kind: "nearby" | "inProgress".
-- api: the game reads (tests pass fakes); WowVision.quests.tooltipApi by
-- default. Every read may be missing on a client and returns nil then.
WowVision.quests = WowVision.quests or {}

local L = WowVision:getLocale()

local function nonEmpty(text)
    return type(text) == "string" and text ~= "" and not (WowVision.isSecret ~= nil and WowVision.isSecret(text))
end

local function call(fn, ...)
    if fn == nil then
        return nil
    end
    local ok, a, b = pcall(fn, ...)
    if not ok then
        return nil
    end
    return a, b
end

-- The quest colour by level, the five classic words. GetQuestDifficultyColor
-- returns one of the QuestDifficultyColors tables itself, so the word comes
-- from that identity, never from guessing at RGB values.
local DIFFICULTY_WORDS = {
    trivial = "Grey",
    standard = "Green",
    difficult = "Yellow",
    verydifficult = "Orange",
    impossible = "Red",
}

function WowVision.quests.difficultyColorWord(level)
    if type(level) ~= "number" or level <= 0 or GetQuestDifficultyColor == nil or QuestDifficultyColors == nil then
        return nil
    end
    local color = call(GetQuestDifficultyColor, level)
    if color == nil then
        return nil
    end
    for key, word in pairs(DIFFICULTY_WORDS) do
        if rawequal(color, QuestDifficultyColors[key]) then
            return L[word]
        end
    end
    return nil
end

local api = {}
WowVision.quests.tooltipApi = api

-- The level the game rates the quest at (scaled quests on modern clients),
-- else nil and the entry's own level counts.
function api.difficultyLevel(questId)
    if C_QuestLog == nil then
        return nil
    end
    local level = call(C_QuestLog.GetQuestDifficultyLevel, questId)
    if type(level) == "number" and level > 0 then
        return level
    end
    return nil
end

function api.colorWord(level)
    return WowVision.quests.difficultyColorWord(level)
end

-- The game's tag: Elite, Group, Dungeon, Raid, PvP ... (already localized).
function api.tagName(questId)
    if C_QuestLog ~= nil and C_QuestLog.GetQuestTagInfo ~= nil then
        local info = call(C_QuestLog.GetQuestTagInfo, questId)
        if type(info) == "table" and nonEmpty(info.tagName) then
            return info.tagName
        end
    end
    if GetQuestTagInfo ~= nil then
        local _, name = call(GetQuestTagInfo, questId)
        if nonEmpty(name) then
            return name
        end
    end
    return nil
end

function api.groupSize(questId)
    if C_QuestLog ~= nil and C_QuestLog.GetSuggestedGroupSize ~= nil then
        local size = call(C_QuestLog.GetSuggestedGroupSize, questId)
        if type(size) == "number" and size > 1 then
            return size
        end
    end
    return nil
end

-- The quest as the log has it right now (progress changes while the
-- scanner is open), or nil when it is not in the log.
function api.logEntry(questId)
    local log = WowVision.quests.gameQuestLog ~= nil and call(WowVision.quests.gameQuestLog) or nil
    for _, entry in ipairs(log or {}) do
        if entry.questId == questId then
            return entry
        end
    end
    return nil
end

local function questsModule()
    return WowVision.base ~= nil and WowVision.base.quests or nil
end

-- The quest data's own text (what to do), one string per line.
function api.questText(questId)
    local quests = questsModule()
    if quests == nil then
        return nil
    end
    local quest = call(quests.quest, quests, questId)
    return quest ~= nil and quest.objectivesText or nil
end

function api.turnIn(questId)
    local quests = questsModule()
    if quests == nil then
        return nil
    end
    local targets = call(quests.targets, quests, questId, "finish")
    local first = targets ~= nil and targets[1] or nil
    return first ~= nil and first.name or nil
end

function api.placeName(target)
    local quests = questsModule()
    if quests == nil or target == nil or target.nearest == nil then
        return nil
    end
    return call(quests.placeName, quests, target.nearest)
end

local function add(lines, text)
    if nonEmpty(text) then
        for _, existing in ipairs(lines) do
            if existing == text then
                return
            end
        end
        table.insert(lines, text)
    end
end

function WowVision.quests.tooltipLines(entry, kind, reads)
    reads = reads or api
    local lines = {}
    local questId = entry.questId
    local live = kind == "inProgress" and reads.logEntry(questId) or nil
    if live ~= nil then
        entry = live
    end

    add(lines, entry.title or entry.name)

    -- Level and colour: "Level 12, Yellow"
    local level = reads.difficultyLevel(questId) or entry.level
    if type(level) == "number" and level > 0 then
        local text = L["Level"] .. " " .. tostring(level)
        local color = reads.colorWord(level)
        if color ~= nil then
            text = text .. ", " .. color
        end
        add(lines, text)
    end
    if type(entry.requiredLevel) == "number" and entry.requiredLevel > 0 and entry.requiredLevel ~= level then
        add(lines, L["Required Level"] .. " " .. tostring(entry.requiredLevel))
    end

    -- What kind of quest: "Elite, Daily, 3 players"
    local kindParts = {}
    local tag = reads.tagName(questId)
    if nonEmpty(tag) then
        table.insert(kindParts, tag)
    end
    if entry.daily then
        table.insert(kindParts, L["Daily"])
    elseif entry.repeatable then
        table.insert(kindParts, L["Repeatable"])
    end
    local size = reads.groupSize(questId)
    if size ~= nil then
        table.insert(kindParts, string.format(L["%d players"], size))
    end
    if #kindParts > 0 then
        add(lines, table.concat(kindParts, ", "))
    end

    if kind == "inProgress" then
        local objectives = entry.objectives or {}
        if entry.failed then
            add(lines, L["Failed"])
        elseif entry.complete then
            add(lines, L["Complete"])
        elseif #objectives > 0 then
            local done = 0
            for _, objective in ipairs(objectives) do
                if objective.finished then
                    done = done + 1
                end
            end
            add(lines, L["Objectives"] .. ": " .. done .. " " .. L["of"] .. " " .. #objectives)
        end
        for _, objective in ipairs(objectives) do
            local text = objective.text
            if nonEmpty(text) and objective.finished then
                text = text .. ", " .. L["Complete"]
            end
            add(lines, text)
        end
        if entry.complete then
            local turnIn = reads.turnIn(questId)
            if nonEmpty(turnIn) then
                add(lines, L["Turn In"] .. ": " .. turnIn)
            end
        end
    else
        local starter = entry.starter
        if starter ~= nil then
            local giver = starter.item ~= nil and starter.item.name or starter.name
            if nonEmpty(giver) then
                local text = L["Quest Giver"] .. ": " .. giver
                local place = reads.placeName(starter)
                if nonEmpty(place) then
                    text = text .. ", " .. place
                end
                add(lines, text)
            end
        end
    end

    for _, line in ipairs(reads.questText(questId) or {}) do
        add(lines, line)
    end
    return lines
end
