-- The quest log's quest tooltip in a group (Retail and WoW: Forever).
--
-- The game's hover script (QuestMapLogTitleButton_OnEnter) adds the
-- player's objectives, then, when a group member is on the quest, calls
-- GameTooltip:SetQuestPartyProgress(questID, true, true). That is a Set call,
-- not an append: it clears the tooltip and fills it with the other members
-- only, so the player's progress is gone (for sighted players too).
--
-- restorePlayerProgress runs after the hover script. It reads the game's own
-- call back from the tooltip (its primary tooltip info; the info list is
-- reset whenever the tooltip is cleared, so it holds only what this hover
-- set) and, when that is the party progress call without the player, makes
-- the same call again with the player kept in (title still left out). The
-- quest, and the decision whether a group member is on it, come from the
-- game's call, so nothing is guessed and a client that stops leaving the
-- player out is left alone. SetQuestPartyProgress is one of the game's secure
-- tooltip delegates (TooltipDataHandler.lua): calling it adds no taint.
WowVision.questLogTooltip = {}

function WowVision.questLogTooltip.restorePlayerProgress(tooltip)
    local info = tooltip:GetPrimaryTooltipInfo()
    if info == nil or info.getterName ~= "GetQuestPartyProgress" or info.getterArgs == nil then
        return
    end
    local questID, ignoreActivePlayer = info.getterArgs[1], info.getterArgs[3]
    local isSecret = WowVision.secrets.isSecret
    if isSecret(questID) or isSecret(ignoreActivePlayer) or ignoreActivePlayer ~= true then
        return
    end
    tooltip:SetQuestPartyProgress(questID, true, false)
end
