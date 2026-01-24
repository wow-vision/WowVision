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
            { "QuestLog/QuestControl" },
        },
    }
end)

local function getNumEntries(self)
    return GetNumQuestLogEntries()
end

local function getQuestListButton(self, button)
    local buttonId = button:GetID()
    local offset = FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
    local questIndex = buttonId + offset
    local label = ""
    local questLogTitleText, level, questTag, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling =
        GetQuestLogTitle(questIndex)
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
        selected = questIndex == GetQuestLogSelection(),
        header = header,
    }
end

local function getQuestListButtonIndex(self, button)
    -- TBC uses FauxScrollFrame, so the button ID is relative to scroll offset
    local offset = FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
    return button:GetID() + offset
end

-- TBC quest buttons are hardcoded as QuestLogTitle1-6, not children of the scroll frame
local QUESTS_DISPLAYED = 6
local function getQuestListButtons(self)
    local buttons = {}
    for i = 1, QUESTS_DISPLAYED do
        local button = _G["QuestLogTitle" .. i]
        if button then
            tinsert(buttons, button)
        end
    end
    return buttons
end

gen:Element("QuestLog/QuestList", function(props)
    local frame = props.frame

    -- If scroll frame is shown, use ProxyFauxScrollFrame
    if frame and frame:IsShown() then
        return {
            "ProxyFauxScrollFrame",
            frame = frame,
            buttonHeight = QUESTLOG_QUEST_HEIGHT,
            updateFunction = QuestLog_Update,
            getNumEntries = getNumEntries,
            getElement = getQuestListButton,
            getElementIndex = getQuestListButtonIndex,
            getButtons = getQuestListButtons,
        }
    end

    -- Scroll frame is hidden (not enough quests to scroll), render buttons directly
    local children = {}
    for i = 1, QUESTS_DISPLAYED do
        local button = _G["QuestLogTitle" .. i]
        if button and button:IsShown() then
            local element = getQuestListButton(nil, button)
            if element then
                tinsert(children, element)
            end
        end
    end

    if #children == 0 then
        return nil
    end

    return {
        "List",
        label = L["Quests"],
        children = children,
    }
end)

gen:Element("QuestLog/QuestDetails", {
    regenerateOn = {
        events = { "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "UNIT_QUEST_LOG_CHANGED" },
        values = function(props)
            return { GetQuestLogSelection() }
        end,
    },
}, function(props)
    local frame = props.frame
    if not frame:IsShown() or not frame:IsVisible() then
        return nil
    end

    -- Get quest text using TBC frame names
    local title = QuestLogQuestTitle and QuestLogQuestTitle:GetText() or ""
    local objectivesHeader = QuestLogObjectivesText and QuestLogObjectivesText:GetText() or ""
    local description = QuestLogQuestDescription and QuestLogQuestDescription:GetText() or ""

    local result = {
        "List",
        label = L["Details"],
        children = {
            { "Text", key = "title", text = title },
            { "Text", key = "description", text = description },
            { "Text", key = "objectivesText", text = objectivesHeader },
            { "QuestLog/QuestObjectives" },
        },
    }
    return result
end)

gen:Element("QuestLog/QuestObjectives", {
    regenerateOn = {
        events = { "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE" },
    },
}, function(props)
    local result = { "List", label = L["Objectives"], children = {} }

    -- TBC uses QuestLogObjective1 through QuestLogObjective10
    local MAX_OBJECTIVES = 10
    for i = 1, MAX_OBJECTIVES do
        local objective = _G["QuestLogObjective" .. i]
        if objective and objective:IsShown() then
            local text = objective:GetText()
            if text and text ~= "" then
                tinsert(result.children, { "Text", key = "objective_" .. i, text = text })
            end
        end
    end

    if #result.children > 0 then
        return result
    end
    return nil
end)

gen:Element("QuestLog/QuestControl", function(props)
    -- TBC doesn't have a control panel frame, check if quest log is open
    if not QuestLogFrame or not QuestLogFrame:IsShown() then
        return nil
    end

    local children = {}

    -- Collapse/Expand all button
    if QuestLogCollapseAllButton and QuestLogCollapseAllButton:IsShown() then
        tinsert(children, { "ProxyButton", frame = QuestLogCollapseAllButton })
    end

    -- Abandon button
    if QuestLogFrameAbandonButton and QuestLogFrameAbandonButton:IsShown() then
        tinsert(children, { "ProxyButton", frame = QuestLogFrameAbandonButton })
    end

    -- Push/Share quest button
    if QuestFramePushQuestButton and QuestFramePushQuestButton:IsShown() then
        tinsert(children, { "ProxyButton", frame = QuestFramePushQuestButton })
    end

    if #children == 0 then
        return nil
    end

    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = children,
    }
end)

module:registerWindow({
    type = "FrameWindow",
    name = "QuestLog",
    generated = true,
    rootElement = "QuestLog",
    frameName = "QuestLogFrame",
    conflictingAddons = { "Sku" },
})
