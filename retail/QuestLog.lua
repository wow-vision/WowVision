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
--
-- Two views, as on screen: the details REPLACE the list, and the game's Back
-- button returns to it.
--   List: the quest list (a header per zone; each quest is a row of the quest,
--   its tracking checkbox and its objective lines), the search box, the
--   settings dropdown.
--   Details: the text in the game's order, the rewards, then a row of the
--   buttons with Back first (one shift-tab from the text).
-- Moving between the views moves focus with them: opening a quest lands on
-- its title, Back lands on the quest's row.

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

local function questScrollChild()
    local questsFrame = QuestMapFrame ~= nil and QuestMapFrame.QuestsFrame or nil
    local scrollFrame = questsFrame ~= nil and questsFrame.ScrollFrame or nil
    if scrollFrame == nil or scrollFrame.GetScrollChild == nil then
        return nil
    end
    return scrollFrame:GetScrollChild()
end

-- Rows are pooled and change hands when the list refreshes (a header
-- collapsing moves every row below it), so clicks find the row again.
local function findRow(matches)
    local scrollChild = questScrollChild()
    if scrollChild == nil then
        return nil
    end
    for _, kid in ipairs({ scrollChild:GetChildren() }) do
        if kid:IsShown() and matches(kid) then
            return kid
        end
    end
    return nil
end

local function isQuestRow(kid)
    return kid.questID ~= nil and kid.Checkbox ~= nil
end

local function isObjectiveRow(kid)
    return kid.questID ~= nil and kid.Dash ~= nil
end

local function findQuestRow(questID)
    return findRow(function(kid)
        return isQuestRow(kid) and kid.questID == questID
    end)
end

local function questRowId(questID)
    return ControlId.structural("quest:" .. tostring(questID))
end

local function headerStateText(kid)
    if kid.questLogIndex == nil then
        return nil
    end
    local info = C_QuestLog.GetInfo(kid.questLogIndex)
    if info == nil then
        return nil
    end
    return info.isCollapsed and L["Collapsed"] or L["Expanded"]
end

-- Enter is the game's own left click (collapse or expand), Backspace its
-- right click (the menu: Track All, Untrack All).
local function emitHeader(builder, kid)
    local title = rowText(kid)
    local function find()
        return findRow(function(row)
            return row.CollapseButton ~= nil and rowText(row) == title
        end)
    end
    local vtable = nodes.proxyFoundButton({ find = find, label = rowText })
    vtable.announcements[1].live = "focus"
    tinsert(vtable.announcements, {
        text = function()
            local row = find()
            return row ~= nil and headerStateText(row) or nil
        end,
        kind = kinds.value,
        live = "focus",
    })
    vtable.tooltipFrame = find
    builder:addItem(ControlId.structural("header:" .. tostring(title)), vtable)
end

local function isTracked(questID)
    return questID ~= nil and C_QuestLog.GetQuestWatchType(questID) ~= nil
end

local function questLabel(kid)
    local text = nodes.plainText(rowText(kid))
    if text == nil then
        return nil
    end
    if kid.TagText ~= nil and kid.TagText:IsShown() then
        text = text .. " " .. (kid.TagText:GetText() or "")
    end
    local color = questDifficultyWord(kid.questID)
    if color ~= nil then
        return text .. ", " .. color
    end
    return text
end

-- The checkbox is a plain frame reacting to mouse up, so there is no secure
-- click: Enter runs that script, which is what a click does. It only calls
-- the watch API and writes nothing to Blizzard frames.
local function toggleTracking(questID)
    local row = findQuestRow(questID)
    local script = row ~= nil and row.Checkbox:GetScript("OnMouseUp") or nil
    if script ~= nil then
        script(row.Checkbox, "LeftButton", true)
    end
end

-- One row: the quest, its checkbox on the right arrow, then its objective
-- lines (present when the game's Show Objectives setting is on).
local function emitQuest(builder, kid, objectives)
    local questID = kid.questID
    local function find()
        return findQuestRow(questID)
    end
    local vtable = nodes.proxyFoundButton({
        find = find,
        label = questLabel,
        selected = function()
            return C_QuestLog.GetSelectedQuest ~= nil and C_QuestLog.GetSelectedQuest() == questID
        end,
    })
    vtable.announcements[1].live = "focus"
    tinsert(vtable.announcements, {
        text = function()
            return isTracked(questID) and L["tracked"] or nil
        end,
        kind = kinds.value,
        live = "focus",
    })
    vtable.tooltipFrame = find

    builder:startRow()
    builder:addItem(questRowId(questID), vtable)
    builder:addItem(
        ControlId.structural("track:" .. tostring(questID)),
        nodes.toggle({
            label = TRACK_QUEST,
            get = function()
                return isTracked(questID)
            end,
            set = function()
                toggleTracking(questID)
            end,
        })
    )
    for i, objective in ipairs(objectives) do
        builder:addItem(
            ControlId.structural("objective:" .. tostring(questID) .. ":" .. i),
            nodes.text({
                label = function()
                    return nodes.plainText(rowText(objective))
                end,
                live = "focus",
            })
        )
    end
    builder:endRow()
end

-- The list's shown rows in screen order, each quest holding the objective
-- rows drawn under it.
local function listEntries(scrollChild)
    local entries = {}
    local current = nil
    for _, kid in ipairs(visibleRowsByLayout(scrollChild)) do
        if kid.CollapseButton ~= nil then
            current = nil
            tinsert(entries, { header = kid })
        elseif isQuestRow(kid) then
            current = { quest = kid, objectives = {} }
            tinsert(entries, current)
        elseif isObjectiveRow(kid) and current ~= nil and current.quest.questID == kid.questID then
            tinsert(current.objectives, kid)
        end
    end
    return entries
end

-- The game's own message for an empty list: no search matches, or no quests.
local function emptyListText(scrollFrame)
    local region = scrollFrame.NoSearchResultsText
    if region == nil or not region:IsShown() then
        region = scrollFrame.EmptyText
    end
    if region ~= nil and region:IsShown() then
        return nodes.plainText(region:GetText())
    end
    return nil
end

local function renderQuestList(builder, questsFrame)
    local scrollFrame = questsFrame.ScrollFrame
    local scrollChild = questScrollChild()
    if scrollChild == nil then
        return
    end

    builder:beginStop("quests")
    -- The game's count ("Quests: 12/25") names the list.
    local count = QuestLogCount ~= nil and QuestLogCount:IsShown() and QuestLogQuestCount ~= nil
            and nodes.plainText(QuestLogQuestCount:GetText())
        or nil
    builder:pushContext("quests", count or L["Quests"])
    local entries = listEntries(scrollChild)
    for _, entry in ipairs(entries) do
        if entry.header ~= nil then
            emitHeader(builder, entry.header)
        else
            emitQuest(builder, entry.quest, entry.objectives)
        end
    end
    if #entries == 0 then
        builder:addItem(
            ControlId.structural("emptyList"),
            nodes.text({ label = emptyListText(scrollFrame) or L["Empty"] })
        )
    end
    builder:popContext()

    local searchBox = scrollFrame.SearchBox
    if searchBox ~= nil and searchBox:IsShown() then
        builder:beginStop("search")
        builder:addItem(ControlId.forObject(searchBox), nodes.proxyEditBox({ editBox = searchBox, label = L["Search"] }))
    end

    local settingsDropdown = scrollFrame.SettingsDropdown
    if settingsDropdown ~= nil and settingsDropdown:IsShown() then
        builder:beginStop("settings")
        builder:addItem(
            ControlId.forObject(settingsDropdown),
            nodes.proxyDropdown({ target = settingsDropdown, label = L["Settings"] })
        )
    end
end

local function contentText(builder, id, region, scrollFrame, live)
    if region == nil or not region:IsVisible() then
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
    if scrollFrame ~= nil then
        nodes.attachScrollFrame(vtable, scrollFrame, region)
    end
    builder:addItem(id, vtable)
end

local function coinText(amount)
    if amount == nil or amount <= 0 then
        return nil
    end
    return C_CurrencyInfo.GetCoinText(amount, " ")
end

local function renderDetailText(builder, detailsFrame)
    local scrollFrame = detailsFrame.ScrollFrame
    builder:beginStop("details")
    builder:pushContext("details", L["Details"])
    contentText(builder, ControlId.structural("title"), QuestInfoTitleHeader, scrollFrame)
    local backFrame = detailsFrame.BackFrame
    local notice = backFrame ~= nil and backFrame.AccountCompletedNotice or nil
    if notice ~= nil then
        contentText(builder, ControlId.structural("accountCompleted"), notice.Text)
    end
    contentText(builder, ControlId.structural("objectivesText"), QuestInfoObjectivesText, scrollFrame)
    -- Live: the timer counts down.
    contentText(builder, ControlId.structural("timer"), QuestInfoTimerText, scrollFrame, "focus")

    local objectives = QuestInfoObjectivesFrame
    if objectives ~= nil and objectives.Objectives ~= nil then
        for i, objective in ipairs(objectives.Objectives) do
            -- Live: objectives rewrite in place as progress happens.
            contentText(builder, ControlId.structural("objective:" .. i), objective, scrollFrame, "focus")
        end
    end

    contentText(builder, ControlId.structural("spellObjective"), QuestInfoSpellObjectiveLearnLabel, scrollFrame)
    if QuestInfoSpellObjectiveFrame ~= nil then
        contentText(builder, ControlId.structural("spellObjectiveName"), QuestInfoSpellObjectiveFrame.Name, scrollFrame)
    end

    if QuestInfoRequiredMoneyFrame ~= nil and QuestInfoRequiredMoneyFrame:IsVisible() then
        local cost = coinText(C_QuestLog.GetRequiredMoney())
        if cost ~= nil then
            builder:addItem(
                ControlId.structural("requiredMoney"),
                nodes.text({
                    label = function()
                        return (QuestInfoRequiredMoneyText:GetText() or "") .. " " .. cost
                    end,
                })
            )
        end
    end

    contentText(builder, ControlId.structural("groupSize"), QuestInfoGroupSize, scrollFrame)
    contentText(builder, ControlId.structural("descriptionHeader"), QuestInfoDescriptionHeader, scrollFrame)
    contentText(builder, ControlId.structural("description"), QuestInfoDescriptionText, scrollFrame)
    builder:popContext()
end

local function rewardLabel(rewards, element)
    if element == rewards.MoneyFrame then
        return coinText(GetQuestLogRewardMoney())
    end
    local name = element.Name ~= nil and nodes.plainText(element.Name:GetText()) or nil
    if element == rewards.XPFrame then
        return name ~= nil and ((XP or "XP") .. " " .. name) or nil
    end
    if name == nil then
        return element.ValueText ~= nil and nodes.plainText(element.ValueText:GetText()) or nil
    end
    if element.Count ~= nil and element.Count:IsShown() then
        local count = element.Count:GetText()
        if count ~= nil and count ~= "" then
            return name .. " x " .. count
        end
    end
    return name
end

-- An item or currency reward is a real button, with the game's tooltip
-- filled directly (no hover scripts, see proxyButton).
local function rewardButton(rewards, element)
    return nodes.proxyButton({
        target = element,
        hover = false,
        label = function()
            return rewardLabel(rewards, element)
        end,
        tooltip = {
            type = "Game",
            mode = "immediate",
            populate = function(tooltip)
                if element.objectType == "currency" then
                    tooltip:SetQuestLogCurrency(element.type, element:GetID())
                else
                    tooltip:SetQuestLogItem(element.type, element:GetID(), element.questID)
                end
            end,
        },
    })
end

-- The game keeps the shown rewards in order in activeRewardElements: section
-- headers (font strings) and every kind of reward frame (items, money, XP,
-- spells, titles, reputation), so one walk reads them all as drawn.
local function renderRewards(builder)
    local rewards = MapQuestInfoRewardsFrame
    if rewards == nil or not rewards:IsVisible() or rewards.activeRewardElements == nil then
        return
    end
    local items = {}
    for _, element in ipairs(rewards.activeRewardElements) do
        if element:IsShown() then
            local vtable = nil
            if element:GetObjectType() == "FontString" then
                local text = nodes.plainText(element:GetText())
                if text ~= nil then
                    vtable = nodes.text({ label = text })
                end
            elseif element.type ~= nil then
                vtable = rewardButton(rewards, element)
            else
                local label = rewardLabel(rewards, element)
                if label ~= nil then
                    vtable = nodes.text({ label = label })
                end
            end
            if vtable ~= nil then
                tinsert(items, { id = ControlId.forObject(element), vtable = vtable })
            end
        end
    end
    if #items == 0 then
        return
    end
    builder:beginStop("rewards")
    builder:pushContext("rewards", L["Rewards"])
    for _, item in ipairs(items) do
        builder:addItem(item.id, item.vtable)
    end
    builder:popContext()
end

local function renderActions(builder, detailsFrame)
    local buttons = {}
    local function add(button, label)
        if button ~= nil and button:IsShown() then
            tinsert(buttons, { button = button, label = label })
        end
    end
    local backFrame = detailsFrame.BackFrame
    add(backFrame ~= nil and backFrame.BackButton or nil)
    add(detailsFrame.AbandonButton)
    -- Reads the game's own caption, which flips between Track and Untrack
    -- (spoken again after the click, like any focused part).
    add(detailsFrame.TrackButton)
    add(detailsFrame.ShareButton)
    -- Only one of these two shows: they swap the map between the quest's
    -- final destination and its next waypoint.
    add(detailsFrame.DestinationMapButton, detailsFrame.DestinationMapButton.tooltipText)
    add(detailsFrame.WaypointMapButton, detailsFrame.WaypointMapButton.tooltipText)
    if #buttons == 0 then
        return
    end
    builder:beginStop("actions")
    builder:startRow()
    for _, entry in ipairs(buttons) do
        builder:addItem(ControlId.forObject(entry.button), nodes.proxyButton({ target = entry.button, label = entry.label }))
    end
    builder:endRow()
end

-- Moves focus across a change of view: the focused control vanished with
-- the old view, so without this it would land wherever repair finds.
local function followView(screen, showingDetails)
    local state = screen.state
    if state.questLogDetails == showingDetails then
        return
    end
    if state.questLogDetails ~= nil then
        if showingDetails then
            state.nextSuggestedMove = ControlId.structural("title")
        else
            state.nextSuggestedMove = questRowId(C_QuestLog.GetSelectedQuest())
        end
    end
    state.questLogDetails = showingDetails
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

    local detailsFrame = frame.DetailsFrame
    local showingDetails = detailsFrame ~= nil and detailsFrame:IsShown()
    followView(screen, showingDetails)

    builder:pushContext("questLog", L["Quest Log"])
    if showingDetails then
        renderDetailText(builder, detailsFrame)
        renderRewards(builder)
        renderActions(builder, detailsFrame)
    else
        renderQuestList(builder, questsFrame)
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
