local module = WowVision.base.windows.legacy
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local talentTree = WowVision.talentTree

-- The challenges page: Forever's achievements, worth Legacy points. The
-- Legacy points first, then the search box, the filter menu (completed,
-- incomplete), and the category tree on the left; the selected category's
-- challenges on the right. A click on a challenge selects it and unfolds
-- its objectives, which follow it here, with the track checkbox while it is
-- not done. Rows are secure clicks on the real frames; labels come from the
-- achievement data, so a row reads before it scrolls into view.

-- Legacy points earned out of all there are (the bar's own text).
local function renderPoints(builder, page)
    local summary = page.LegacyChallengePointSummary
    builder:beginStop("points")
    builder:addItem(
        ControlId.structural("points"),
        nodes.text({
            label = function()
                return nodes.joinLabel(L["Points"], nodes.shownText(summary.PointsBar.Text))
            end,
        })
    )
end

local function rowNode(helpers, announcements, extra)
    local vtable = {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    }
    for key, value in pairs(extra or {}) do
        vtable[key] = value
    end
    return vtable
end

-- ---- categories ----

-- A category row: a click selects it (its challenges fill the right side);
-- a parent category also folds open or shut. New marks a category with
-- challenges not seen yet.
local function emitCategory(list)
    return function(builder, node, index, helpers)
        local data = node:GetData()
        local categoryInfo = data.categoryInfo
        if categoryInfo == nil then
            return
        end
        local announcements = {
            { text = categoryInfo.name, kind = kinds.label },
            {
                text = function()
                    return list:IsCategorySelected(data) and L["selected"] or nil
                end,
                kind = kinds.selected,
            },
            {
                text = function()
                    if LegacyChallengeViewedUtil.CategoryHasUnviewedChallenges(categoryInfo.id) then
                        return L["New"]
                    end
                    return nil
                end,
            },
        }
        if data.isParent then
            tinsert(announcements, 2, {
                text = function()
                    return node:IsCollapsed() and L["Collapsed"] or L["Expanded"]
                end,
                kind = kinds.value,
            })
        end
        builder:addItem(ControlId.structural("category:" .. categoryInfo.id), rowNode(helpers, announcements))
    end
end

local function renderCategories(builder, list)
    builder:beginStop("search")
    builder:addItem(ControlId.structural("search"), nodes.proxyEditBox({ editBox = list.SearchBox, label = L["Search"] }))

    builder:beginStop("filter")
    builder:addItem(
        ControlId.forObject(list.FilterDropdown),
        nodes.proxyDropdown({ target = list.FilterDropdown, label = L["Filter"] })
    )

    builder:beginStop("categories")
    if list.NoResultsText:IsShown() then
        builder:addItem(ControlId.structural("noResults"), nodes.text({ label = list.NoResultsText:GetText() }))
        return
    end
    nodes.scrollBoxList(builder, {
        scrollBox = list.ScrollBox,
        key = "categories",
        label = L["Categories"],
        emit = emitCategory(list),
    })
end

-- ---- challenges ----

-- The row's data as the card shows it: the Legacy points the challenge is
-- worth (not its achievement points), and done only when earned by this
-- character, as the card reads.
local function challengeInfo(data)
    local id, name, points, completed, month, day, year, description, _, _, rewardText, isGuild, wasEarnedByMe =
        GetAchievementInfo(data.category, data.index)
    local done = AchievementFrame_ShowAsComplete(completed, wasEarnedByMe)
    return {
        id = id,
        name = name,
        points = AchievementFrame_GetOverridePoints(points, id) or 0,
        description = description,
        rewardText = rewardText,
        completedDate = done and FormatShortDate(day, month, year) or nil,
        -- The card offers tracking under the same test.
        trackable = not completed or (not wasEarnedByMe and not isGuild),
    }
end

local function isTracked(id)
    return C_ContentTracking.IsTracking(Enum.ContentTrackingType.Achievement, id)
end

local function challengeLabel(data)
    local info = challengeInfo(data)
    return nodes.joinLabel(
        info.name,
        info.points > 0 and talentTree.pointsText(info.points),
        info.completedDate ~= nil and (L["Completed"] .. " " .. info.completedDate),
        isTracked(info.id) and L["Tracked"],
        info.description,
        info.rewardText
    )
end

-- An objective as the unfolded card shows it: its text, and a counted one's
-- count (the card draws those as a bar, often without text).
local function criteriaLabel(id, criteriaIndex)
    local text, _, completed, quantity, reqQuantity, _, flags, _, quantityString =
        GetAchievementCriteriaInfo(id, criteriaIndex)
    local counted = flags ~= nil
        and reqQuantity ~= nil
        and reqQuantity > 0
        and bit.band(flags, EVALUATION_TREE_FLAG_PROGRESS_BAR) == EVALUATION_TREE_FLAG_PROGRESS_BAR
    local count = nil
    if counted then
        if quantityString ~= nil and quantityString ~= "" then
            count = quantityString
        elseif quantity ~= nil then
            count = quantity .. "/" .. reqQuantity
        end
    end
    if count ~= nil and (text == nil or text == "") then
        text = L["Progress"]
    end
    return nodes.joinLabel(text, count, completed and L["Complete"])
end

-- The unfolded challenge's objectives, then its track checkbox while the
-- card shows one (not done, or tracked; never under the game rule that
-- turns tracking off). The checkbox lives on the row frame, so it scrolls
-- the row in like the row does.
local function emitDetails(builder, data, helpers)
    local id = data.id
    builder:pushContext("objectives:" .. id, L["Objectives"])
    for criteriaIndex = 1, GetAchievementNumCriteria(id) or 0 do
        builder:addItem(
            ControlId.structural("criteria:" .. id .. ":" .. criteriaIndex),
            nodes.text({
                label = function()
                    return criteriaLabel(id, criteriaIndex)
                end,
            })
        )
    end
    local trackingDisabled = C_GameRules.IsGameRuleActive(Enum.GameRule.TrackAchievementsDisabled)
    if not trackingDisabled and (challengeInfo(data).trackable or isTracked(id)) then
        local vtable = nodes.proxyFoundButton({
            find = function()
                local frame = helpers.target()
                return frame ~= nil and frame.Tracked or nil
            end,
            -- Replaced below: a found label reads nothing until the row
            -- frame has scrolled in.
            label = function()
                return L["Track"]
            end,
            rightClick = false,
        })
        vtable.controlType = graph.controlTypes.toggle
        vtable.announcements[1] = { text = L["Track"], kind = kinds.label }
        tinsert(vtable.announcements, {
            text = function()
                return isTracked(id) and L["Checked"] or L["Unchecked"]
            end,
            kind = kinds.value,
        })
        vtable.onFocus = helpers.onFocus
        vtable.onFocusTick = helpers.onFocusTick
        builder:addItem(ControlId.structural("track:" .. id), vtable)
    end
    builder:popContext()
end

-- The row's tooltip. The game has none (hovering a card only lights it),
-- and a card lists its objectives -- the zones, dungeons, or raids to do --
-- only while unfolded, so the tooltip carries them: the description, the
-- reward, then every objective as the unfolded card reads it.
local function challengeTooltip(data)
    return {
        type = "Game",
        mode = "immediate",
        populate = function(tooltip)
            local info = challengeInfo(data)
            GameTooltip_SetTitle(tooltip, info.name)
            if info.description ~= nil and info.description ~= "" then
                tooltip:AddLine(info.description, 1, 1, 1, true)
            end
            if info.rewardText ~= nil and info.rewardText ~= "" then
                tooltip:AddLine(info.rewardText, 1, 1, 1, true)
            end
            local numCriteria = GetAchievementNumCriteria(info.id) or 0
            if numCriteria > 0 then
                tooltip:AddLine(L["Objectives"])
                for criteriaIndex = 1, numCriteria do
                    tooltip:AddLine(criteriaLabel(info.id, criteriaIndex), 1, 1, 1, true)
                end
            end
            tooltip:Show()
        end,
    }
end

-- A challenge row: a click selects it and unfolds it (a second click folds
-- it again). The context menu links it in chat, as a shift-click does.
local function emitChallenge(builder, data, index, helpers)
    local id = data.id
    local selected = SelectionBehaviorMixin.IsElementDataIntrusiveSelected(data)
    builder:addItem(
        ControlId.structural("challenge:" .. id),
        rowNode(helpers, {
            {
                text = function()
                    return challengeLabel(data)
                end,
                kind = kinds.label,
            },
            {
                text = function()
                    return SelectionBehaviorMixin.IsElementDataIntrusiveSelected(data) and L["selected"] or nil
                end,
                kind = kinds.selected,
            },
        }, {
            tooltip = challengeTooltip(data),
            contextActions = function(add)
                add({
                    label = L["Link %s in Chat"]:format(challengeInfo(data).name),
                    onActivate = function()
                        WowVision.chatLinks.shiftClick({ kind = "link", text = GetAchievementLink(id) })
                    end,
                })
            end,
        })
    )
    if selected then
        emitDetails(builder, data, helpers)
    end
end

-- The list is named after the category it holds. Only a category with
-- challenges of its own fills it: opening or closing a parent category
-- folds the tree and leaves the list as it was, as on screen.
local function renderChallenges(builder, pane)
    builder:beginStop("challenges")
    nodes.scrollBoxList(builder, {
        scrollBox = pane.ScrollBox,
        key = "challenges",
        label = nodes.joinLabel(L["Challenges"], pane.info ~= nil and pane.info.name or nil),
        emit = emitChallenge,
    })
end

function module.renderChallenges(builder, page)
    renderPoints(builder, page)
    renderCategories(builder, page.CategoryList)
    renderChallenges(builder, page.DetailPane)
end
