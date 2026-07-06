local module = WowVision.base.windows:createModule("QuestLog")
local L = module.L
module:setLabel(L["Quest Log"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC quest log: a true FauxScrollFrame with a six-button pool
-- (QuestLogTitle1-6) whose ids are POOL-RELATIVE -- logical index is id
-- plus scroll offset -- then the details pane with live objectives and the
-- control buttons.

local QUESTS_DISPLAYED = 6

local function questButtons()
    local buttons = {}
    for i = 1, QUESTS_DISPLAYED do
        local button = _G["QuestLogTitle" .. i]
        if button ~= nil then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function questButtonIndex(button)
    local offset = FauxScrollFrame_GetOffset(QuestLogListScrollFrame) or 0
    return button:GetID() + offset
end

local function questLabel(index)
    local title, _, _, isHeader, _, isComplete, frequency = GetQuestLogTitle(index)
    if title == nil then
        return nil
    end
    if isHeader then
        return title
    end
    local label = ""
    if isComplete == 1 then
        label = "[" .. L["Complete"] .. "] "
    elseif isComplete == -1 then
        label = "[" .. L["Failed"] .. "] "
    end
    if frequency == LE_QUEST_FREQUENCY_DAILY then
        label = label .. "[" .. L["Daily"] .. "] "
    elseif frequency == LE_QUEST_FREQUENCY_WEEKLY then
        label = label .. "[" .. L["Weekly"] .. "] "
    end
    return label .. title
end

local function questEntryId(index)
    local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
    if isHeader then
        return ControlId.structural("header:" .. tostring(title))
    end
    if questID ~= nil and questID ~= 0 then
        return ControlId.structural("quest:" .. tostring(questID))
    end
    return ControlId.structural("entry:" .. index)
end

local function emitQuestEntry(builder, index, helpers)
    local _, _, _, isHeader, _, _, _, _, _, _, _, _, _, _, _, isHidden = GetQuestLogTitle(index)
    if isHidden then
        return
    end

    local announcements = {
        {
            text = function()
                return questLabel(index)
            end,
            kind = kinds.label,
        },
    }
    if isHeader then
        tinsert(announcements, {
            text = function()
                local _, _, _, _, collapsed = GetQuestLogTitle(index)
                return collapsed and L["Collapsed"] or L["Expanded"]
            end,
            kind = kinds.value,
        })
    else
        tinsert(announcements, {
            text = function()
                if index == GetQuestLogSelection() then
                    return L["selected"]
                end
                return nil
            end,
            kind = kinds.selected,
        })
    end

    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    })
end

local function contentText(builder, id, region, scrollFrame)
    if region == nil or not region:IsShown() then
        return
    end
    local text = region:GetText()
    if text == nil or text == "" then
        return
    end
    local vtable = nodes.text({
        label = function()
            return region:GetText()
        end,
    })
    nodes.attachScrollFrame(vtable, scrollFrame, region)
    builder:addItem(id, vtable)
end

local function renderDetails(builder)
    local child = QuestLogDetailScrollChildFrame
    if child == nil or not child:IsShown() or not child:IsVisible() then
        return
    end
    local scrollFrame = QuestLogDetailScrollFrame

    builder:beginStop("details")
    builder:pushContext("details", L["Details"])
    contentText(builder, ControlId.structural("title"), QuestLogQuestTitle, scrollFrame)
    contentText(builder, ControlId.structural("description"), QuestLogQuestDescription, scrollFrame)
    contentText(builder, ControlId.structural("objectivesText"), QuestLogObjectivesText, scrollFrame)

    for i = 1, 10 do
        local objective = _G["QuestLogObjective" .. i]
        if objective ~= nil and objective:IsShown() then
            contentText(builder, ControlId.structural("objective:" .. i), objective, scrollFrame)
        end
    end
    builder:popContext()
end

local function actionButton(builder, button)
    if button == nil or not button:IsShown() then
        return
    end
    builder:beginStop()
    builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
end

local function render(builder, screen)
    local frame = QuestLogFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("questLog", L["Quest Log"])

    builder:beginStop("quests")
    nodes.hybridScrollList(builder, {
        scrollFrame = QuestLogListScrollFrame,
        key = "quests",
        label = L["Quests"],
        count = function()
            return (GetNumQuestLogEntries())
        end,
        rowHeight = QUESTLOG_QUEST_HEIGHT,
        buttons = questButtons,
        indexOf = questButtonIndex,
        id = questEntryId,
        emit = emitQuestEntry,
    })

    renderDetails(builder)

    actionButton(builder, QuestLogCollapseAllButton)
    actionButton(builder, QuestLogFrameAbandonButton)
    actionButton(builder, QuestFramePushQuestButton)

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "QuestLog",
    frameName = "QuestLogFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
