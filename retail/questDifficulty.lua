-- The quest colour as this client's quest log shows it. The log does not
-- work the colour out from the quest's level: it asks the game how hard the
-- quest is for this player and colours by the answer (QuestMapFrame.lua and
-- QuestUtilsOverrides.lua: GetDifficultyColor of
-- C_PlayerInfo.GetContentDifficultyQuestForPlayer). GetQuestDifficultyColor
-- by level is still there, but its bands are not the log's: on WoW: Forever
-- a level 21 quest at level 27 is grey by the formula and green in the log.
-- So the colour word is read the way the log reads it
-- (WowVision.quests.difficultyColorWord in core/quests/tooltip.lua).
WowVision.quests = WowVision.quests or {}

-- One of the QuestDifficultyColors tables, or nil when the game gives no
-- rating (the colour by level counts then).
function WowVision.quests.ratedDifficultyColor(questId)
    if C_PlayerInfo == nil or C_PlayerInfo.GetContentDifficultyQuestForPlayer == nil or GetDifficultyColor == nil then
        return nil
    end
    local difficulty = C_PlayerInfo.GetContentDifficultyQuestForPlayer(questId)
    if difficulty == nil then
        return nil
    end
    return (GetDifficultyColor(difficulty))
end
