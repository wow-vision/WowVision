local module = WowVision.base.windows:createModule("QuestLog")
local L = module.L
module:setLabel(L["Quest Log"])
local gen = module:hasUI()

gen:Element("QuestLog", function(props)
    return {
        "Panel",
        label = L["Quest Log"],
        wrap = true,
        children = {
            { "QuestLog/QuestList", frame = QuestLogListScrollFrame },
            { "QuestLog/QuestDetails", frame = QuestLogDetailScrollChildFrame },
            { "QuestLog/QuestControl", frame = QuestLogControlPanel },
        },
    }
end)

local function getNumEntries(self)
    return GetNumQuestLogEntries()
end

local function getQuestListButton(self, button)
    local id = button:GetID()
    local label = ""
    local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling =
        GetQuestLogTitle(id)
    if isHidden then
        return nil
    end
    if isComplete == 1 then
        label = label .. "[" .. L["Complete"] .. "] "
    elseif isComplete == -1 then
        label = label .. "[" .. L["Failed"] .. "] "
    end
    if frequency == LE_QUEST_FREQUENCY_DAILY then
        label = label .. "[" .. L["Daily"] .. "] "
    elseif frequency == LE_QUEST_FREQUENCY_WEEKLY then
        label = label .. "[" .. L["Weekly"] .. "] "
    end
    label = label .. " " .. button:GetText()
    local header = nil
    if isHeader then
        if isCollapsed then
            header = "collapsed"
        else
            header = "expanded"
        end
    end
    return {
        "ProxyButton",
        frame = button,
        label = label,
        selected = id == GetQuestLogSelection(),
        header = header,
    }
end

local function getQuestListButtonIndex(self, button)
    return button:GetID()
end

gen:Element("QuestLog/QuestList", function(props)
    return {
        "ProxyScrollFrame",
        frame = props.frame,
        getNumEntries = getNumEntries,
        getElement = getQuestListButton,
        getElementIndex = getQuestListButtonIndex,
    }
end)

gen:Element("QuestLog/QuestDetails", function(props)
    local frame = props.frame
    if not frame:IsShown() or not frame:IsVisible() then
        return nil
    end
    local result = {
        "List",
        label = L["Details"],
        children = {
            { "Text", text = QuestInfoTitleHeader:GetText() },
            { "Text", text = QuestInfoDescriptionText:GetText() },
            { "Text", text = QuestInfoObjectivesText:GetText() },
            { "QuestLog/QuestObjectives", frame = QuestInfoObjectivesFrame },
        },
    }
    return result
end)

gen:Element("QuestLog/QuestObjectives", function(props)
    local frame = props.frame
    local result = { "List", label = L["Objectives"], children = {} }
    for i = 1, #frame.Objectives do
        local objective = frame.Objectives[i]
        if objective:IsShown() then
            tinsert(result.children, { "Text", text = objective:GetText() })
        end
    end

    if #result.children > 0 then
        return result
    end
    return nil
end)

gen:Element("QuestLog/QuestControl", function(props)
    local frame = props.frame
    if frame == nil or not frame:IsShown() or not frame:IsVisible() then
        return nil
    end
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "ProxyButton", frame = QuestLogFrameAbandonButton },
            { "ProxyButton", frame = QuestFramePushQuestButton },
            { "ProxyButton", frame = QuestLogFrameTrackButton },
        },
    }
end)

module:registerWindow({
    name = "QuestLog",
    auto = true,
    generated = true,
    rootElement = "QuestLog",
    frameName = "QuestLogFrame",
    conflictingAddons = { "Sku" },
})
