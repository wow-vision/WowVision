local module = WowVision.base.windows:createModule("QuestLog")
local L = module.L
module:setLabel(L["Quest Log"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The quest log on clients where it merged into the world map (Retail, and
-- WoW: Forever since patch 1.60.1): pressing L opens QuestMapFrame, a panel
-- beside the map rather than the old standalone QuestLogFrame.
--
-- The quest list (QuestMapFrame.QuestsFrame) is a plain ScrollFrame over a
-- manually laid out row pool, not a virtualized ScrollBox: every row for the
-- current (uncollapsed) list exists as a real, positioned child of the
-- scroll child at once, ordered by a `layoutIndex` field, and reused/hidden
-- rather than destroyed as the list changes. Three row shapes share the
-- pool:
--   zone header   .CollapseButton, text via GetText()
--   quest         .questID, .Checkbox, .Text (title, formatted "[lvl] Name")
--   objective     .Dash, .Text, .questID (the quest it belongs to)
-- Selecting a quest drives QuestMapFrame.DetailsFrame, which reuses the same
-- shared QuestInfoTitleHeader/QuestInfoDescriptionText/QuestInfoObjectivesText
-- globals the NPC quest dialog (core/windows/questWindow.lua) and the older
-- QuestLogFrame (tbc/mists) already read -- only the row pool above is new.

-- Sorted by actual screen position rather than layoutIndex: objective rows
-- don't carry a layoutIndex at all, which sorted them to the very top
-- (missing treated as 0, below every real header/quest index).
local function visibleRowsByLayout(scrollChild)
    local rows = {}
    for _, kid in ipairs({ scrollChild:GetChildren() }) do
        if kid:IsShown() then
            tinsert(rows, kid)
        end
    end
    table.sort(rows, function(a, b)
        local topA, topB = a:GetTop(), b:GetTop()
        if topA == nil or topB == nil then
            return false
        end
        return topA > topB
    end)
    return rows
end

-- Header rows carry their text directly (GetText works); quest and
-- objective rows carry it on a child FontString named Text instead.
local function rowText(kid)
    if kid.Text ~= nil and kid.Text.GetText ~= nil then
        local text = kid.Text:GetText()
        if text ~= nil then
            return text
        end
    end
    if kid.GetText ~= nil then
        local ok, text = pcall(kid.GetText, kid)
        if ok and text ~= nil then
            return text
        end
    end
    return nil
end

-- QuestDifficultyColors keys don't spell out the five classic quest-color
-- names, but GetQuestDifficultyColor(level) returns the exact same table
-- object as one of these entries (checked with rawequal), so the mapping is
-- reliable rather than guessed from RGB values.
local difficultyColorLabels = {
    trivial = "Grey",
    standard = "Green",
    difficult = "Yellow",
    verydifficult = "Orange",
    impossible = "Red",
}

local function questDifficultyWord(questID)
    if C_QuestLog == nil or C_QuestLog.GetQuestDifficultyLevel == nil then
        return nil
    end
    if GetQuestDifficultyColor == nil or QuestDifficultyColors == nil then
        return nil
    end
    local level = C_QuestLog.GetQuestDifficultyLevel(questID)
    if level == nil then
        return nil
    end
    local ok, color = pcall(GetQuestDifficultyColor, level)
    if not ok or color == nil then
        return nil
    end
    for key, labelKey in pairs(difficultyColorLabels) do
        if rawequal(color, QuestDifficultyColors[key]) then
            return L[labelKey]
        end
    end
    return nil
end

local function emitHeader(builder, kid)
    builder:addItem(ControlId.structural("header:" .. tostring(rowText(kid))), {
        controlType = graph.controlTypes.button,
        announcements = {
            { text = function() return rowText(kid) end, kind = kinds.label, live = "focus" },
        },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = kid },
        },
        tooltipFrame = kid,
    })
end

local function isTracked(questID)
    return questID ~= nil and C_QuestLog.GetQuestWatchType(questID) ~= nil
end

local function emitQuest(builder, kid)
    local questID = kid.questID
    builder:addItem(ControlId.structural("quest:" .. tostring(questID)), {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    local text = rowText(kid)
                    local color = questDifficultyWord(questID)
                    if text ~= nil and color ~= nil then
                        return text .. ", " .. color
                    end
                    return text
                end,
                kind = kinds.label,
                live = "focus",
            },
            {
                text = function()
                    if C_QuestLog.GetSelectedQuest ~= nil and C_QuestLog.GetSelectedQuest() == questID then
                        return L["selected"]
                    end
                    return nil
                end,
                kind = kinds.selected,
                live = "focus",
            },
            {
                text = function()
                    return isTracked(questID) and L["tracked"] or nil
                end,
                kind = kinds.value,
                live = "focus",
            },
        },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = kid },
        },
        tooltipFrame = kid,
    })
end

local function renderQuestList(builder, questsFrame)
    local scrollFrame = questsFrame.ScrollFrame
    local scrollChild = scrollFrame ~= nil and scrollFrame.GetScrollChild ~= nil and scrollFrame:GetScrollChild() or nil
    if scrollChild == nil then
        return
    end

    builder:pushContext("quests", L["Quests"])
    for _, kid in ipairs(visibleRowsByLayout(scrollChild)) do
        if kid.CollapseButton ~= nil then
            emitHeader(builder, kid)
        elseif kid.questID ~= nil and kid.Checkbox ~= nil then
            emitQuest(builder, kid)
        end
        -- Objective progress rows (.Dash) are skipped here: the same text
        -- already reads via the details panel's objectives, and repeating
        -- it in the list is just noise.
    end
    builder:popContext()
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

local function actionButton(builder, button, label)
    if button == nil or not button:IsShown() then
        return
    end
    builder:beginStop()
    builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button, label = label }))
end

local function renderDetails(builder, detailsFrame)
    if not detailsFrame:IsShown() then
        return
    end
    local scrollFrame = detailsFrame.ScrollFrame

    builder:beginStop()
    builder:pushContext("details", L["Details"])
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

    -- The log's reward preview is a single pre-formatted summary line (e.g.
    -- "You will receive: 250 XP, 40 copper") -- unlike the NPC turn-in
    -- dialog (core/windows/questWindow.lua), there are no reward-choice
    -- buttons here; picking a reward only happens at actual turn-in.
    local rewardsFrame = detailsFrame.RewardsFrameContainer ~= nil and detailsFrame.RewardsFrameContainer.RewardsFrame or nil
    if rewardsFrame ~= nil then
        contentText(builder, ControlId.structural("rewards"), rewardsFrame.Label, scrollFrame)
    end
    builder:popContext()

    actionButton(builder, detailsFrame.AbandonButton)
    -- Reads the game's own caption, which flips between Track and Untrack
    -- (spoken again after the click, like any focused part).
    actionButton(builder, detailsFrame.TrackButton)
    actionButton(builder, detailsFrame.ShareButton)
    actionButton(builder, detailsFrame.WaypointMapButton)
end

local function render(builder, screen)
    local frame = QuestMapFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    local questsFrame = frame.QuestsFrame
    if questsFrame == nil or not questsFrame:IsShown() then
        return
    end

    builder:pushContext("questLog", L["Quest Log"])

    builder:beginStop("quests")
    renderQuestList(builder, questsFrame)

    if frame.DetailsFrame ~= nil then
        renderDetails(builder, frame.DetailsFrame)
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "QuestLog",
    frameName = "QuestMapFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
