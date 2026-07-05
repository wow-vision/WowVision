local module = WowVision.base.windows:createModule("QuestLog")
local L = module.L
module:setLabel(L["Quest Log"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The quest log: the hybrid-scrolled quest list (headers collapse and expand
-- with real clicks; quests select on click, driving the details pane), the
-- details text with live objectives, and the abandon, share, and track
-- buttons. All list data comes from the quest log API.

local function questLabel(index)
    local title, _, _, isHeader, isCollapsed, isComplete, frequency = GetQuestLogTitle(index)
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
    local _, _, _, isHeader, isCollapsed, _, _, _, _, _, _, _, _, _, _, isHidden = GetQuestLogTitle(index)
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
            live = "focus",
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
            live = "focus",
        })
    end

    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    })
end

local function contentText(builder, id, region, scrollFrame, live)
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
        live = live,
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

    builder:beginStop()
    builder:pushContext(L["Details"])
    contentText(builder, ControlId.structural("title"), QuestInfoTitleHeader, scrollFrame)
    contentText(builder, ControlId.structural("description"), QuestInfoDescriptionText, scrollFrame)
    contentText(builder, ControlId.structural("objectivesText"), QuestInfoObjectivesText, scrollFrame)

    local objectives = QuestInfoObjectivesFrame
    if objectives ~= nil and objectives.Objectives ~= nil then
        for i, objective in ipairs(objectives.Objectives) do
            if objective:IsShown() then
                -- Live: objectives rewrite in place as progress happens.
                contentText(builder, ControlId.structural("objective:" .. i), objective, scrollFrame, "focus")
            end
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
    builder:pushContext(L["Quest Log"])

    builder:beginStop("quests")
    nodes.hybridScrollList(builder, {
        scrollFrame = QuestLogListScrollFrame,
        key = "quests",
        count = function()
            return (GetNumQuestLogEntries())
        end,
        id = questEntryId,
        emit = emitQuestEntry,
    })

    renderDetails(builder)

    actionButton(builder, QuestLogFrameAbandonButton)
    actionButton(builder, QuestFramePushQuestButton)
    actionButton(builder, QuestLogFrameTrackButton)

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "QuestLog",
    frameName = "QuestLogFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
