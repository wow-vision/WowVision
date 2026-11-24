local module = WowVision.base.windows.lfgForever
if module == nil then
    return
end

local L = module.L
local game = module.game
local labels = module.labels

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The WowVision screen of LFG Forever's window. It is the window itself, read: every control is the real one of LFG
-- Forever (Enter clicks it, as WowVision does with the game's own windows), so nothing here changes how LFG Forever
-- works. The tab stops, in order:
--
--   Tabs          the tabs of the right-hand column: Filters, Whispers, Player ratings
--   Search        the category and the activity menus, Search, and Role check when it shows
--   Results       the groups and players the last search found, one line each; Enter asks the group to take you
--                 (or invites the player, or removes your own listing), the context menu has the other actions
--                 and the right-click menu
--   then, for the tab that is open:
--     Filters:          the four sections of the filters (Groups, Players, Classes, Miscellaneous), each with its
--                       header (Enter folds or unfolds it) and its controls
--     Whispers:         the whisper log, with Remove, Where is this player and Invite in each line's context menu
--     Player ratings:   the recent party members, with the stars in each line's context menu
--   Options       LFG Forever's settings
--
-- The screen is drawn again every tick, so it always shows what LFG Forever shows.

local function structural(key)
    return ControlId.structural(key)
end

-- The text of a font string now, as speech; nil when there is none.
local function textOf(fontString)
    if fontString == nil or fontString.GetText == nil then
        return nil
    end
    return nodes.plainText(fontString:GetText())
end

-- One part of the screen, run so that an error in it (a control LFG Forever built differently than expected)
-- leaves the other parts working: reported once (utils.guardedCall), and the builder's open contexts and row closed
-- again.
local function part(builder, name, fn, ...)
    local depth = #builder.parents
    local ok = WowVision.utils.guardedCall("lfgForever:" .. name, fn, builder, ...)
    if ok then
        return
    end
    if builder.currentRow ~= nil and not pcall(builder.endRow, builder) then
        builder.currentRow = nil
    end
    while #builder.parents > depth do
        if not pcall(builder.popContext, builder) then
            builder.parents[#builder.parents] = nil
        end
    end
end

-- A tree node of the results wraps the row's own table.
local function rowData(data)
    if type(data) == "table" and data.GetData ~= nil then
        return data:GetData()
    end
    return data
end

local function addButton(builder, button, label)
    if button == nil or not game.shown(button) then
        return
    end
    builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button, label = label }))
end

-- ------------------------------------------------------------------ tabs

local TABS = {
    { key = "filters", idField = "filtersTabID", sectionField = "GroupSection" },
    { key = "whispers", idField = "whispersTabID", sectionField = "WhispersSection" },
    { key = "ratings", idField = "ratingsTabID", sectionField = "RatingsSection" },
}

-- The tab that is open: LFG Forever's tab system hides the content of the others, so the open one is the one whose
-- section is shown.
local function currentTab(filter)
    for _, tab in ipairs(TABS) do
        if game.shown(filter[tab.sectionField]) then
            return tab.key
        end
    end
    return "filters"
end
module.currentTab = currentTab

local function tabButton(filter, tab)
    local tabID = filter[tab.idField]
    if tabID == nil or filter.GetTabButton == nil then
        return nil
    end
    local ok, button = pcall(filter.GetTabButton, filter, tabID)
    if ok then
        return button
    end
    return nil
end

local function renderTabs(builder, filter)
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for _, tab in ipairs(TABS) do
        local button = tabButton(filter, tab)
        if button ~= nil and game.shown(button) then
            local key = tab.key
            builder:addItem(
                structural("tab:" .. key),
                nodes.proxyFoundButton({
                    find = function()
                        return tabButton(filter, tab)
                    end,
                    label = function(found)
                        return found.tabText or nodes.frameText(found)()
                    end,
                    selected = function()
                        return currentTab(filter) == key
                    end,
                    rightClick = false,
                })
            )
        end
    end
    builder:endRow()
    builder:popContext()
end

-- ---------------------------------------------------------------- search

-- A menu with the name of what it picks said first: "Category, Dungeons".
local function dropdownNode(target, name)
    local current = nodes.frameText(target)
    return nodes.proxyDropdown({
        target = target,
        label = function()
            local value = nodes.plainText(current())
            local label = type(name) == "function" and name() or name
            if value ~= nil and label ~= nil and value:lower() == label:lower() then
                value = nil
            end
            return nodes.joinLabel(label, value)
        end,
    })
end

local function renderSearch(builder, filter)
    builder:beginStop("search")
    builder:setStartStop("search")
    builder:pushContext("search", L["Search"])
    if game.shown(filter.CategoryDropdown) then
        builder:addItem(
            ControlId.forObject(filter.CategoryDropdown),
            dropdownNode(filter.CategoryDropdown, L["Category"])
        )
    end
    if game.shown(filter.ActivityDropdown) then
        builder:addItem(
            ControlId.forObject(filter.ActivityDropdown),
            dropdownNode(filter.ActivityDropdown, L["Activity"])
        )
    end
    addButton(builder, filter.SearchButton)
    addButton(builder, filter.RoleCheckButton)
    builder:popContext()
end

-- --------------------------------------------------------------- results

-- How many listings a header holds; nil when the tree will not say.
local function childCount(node)
    if type(node) ~= "table" or node.GetNodes == nil then
        return nil
    end
    local ok, children = pcall(node.GetNodes, node)
    if ok and type(children) == "table" then
        return #children
    end
    return nil
end

local function isCollapsed(node)
    if type(node) ~= "table" then
        return false
    end
    if node.IsCollapsed ~= nil then
        local ok, collapsed = pcall(node.IsCollapsed, node)
        if ok then
            return collapsed == true
        end
    end
    return node.collapsed == true
end

-- The row's button that does what Enter does: Ask to Join on a group, Invite on a player, Delist on your own
-- listing (LFG Forever's red x, shown when you are alone or lead the group). The three share one place on the row,
-- so only one of them shows.
local ACTION_KEYS = { "LFGFAskToJoin", "LFGFInvite", "LFGFDelist" }

local function actionButton(frame)
    if frame == nil then
        return nil, nil
    end
    for _, key in ipairs(ACTION_KEYS) do
        local button = frame[key]
        if button ~= nil and game.shown(button) then
            return button, key
        end
    end
    return nil, nil
end

-- What LFG Forever marks a drawn row with, as speech: the icon of a guild member or a friend, and the strip of a
-- player you rated. Both are on the row's frame only, so they are said once the row is drawn. isGroup is asked
-- only when there is a rating to word.
local function marks(frame, relationField, stripField, isGroup)
    if frame == nil then
        return nil
    end
    local relation = labels.relation(game.relation(frame[relationField]))
    local rating = game.stripRating(frame[stripField])
    local rated = nil
    if rating ~= nil then
        rated = labels.mark(rating, isGroup ~= nil and isGroup())
    end
    if relation == nil and rated == nil then
        return nil
    end
    return nodes.joinLabel(relation, rated)
end

local function dividerRow(data, row, helpers)
    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return labels.divider(row.dividerType, childCount(data))
                end,
                kind = kinds.label,
            },
            {
                text = function()
                    return isCollapsed(data) and L["Collapsed"] or L["Expanded"]
                end,
                kind = kinds.value,
                live = "focus",
            },
        },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    }
end

local function listingRow(data, row, helpers)
    local function primary()
        local frame = helpers.target()
        return actionButton(frame) or frame
    end
    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return labels.listing(row.resultID)
                end,
                kind = kinds.label,
            },
            -- what Enter does here, once the row is drawn; a group already asked says so
            {
                text = function()
                    local button, key = actionButton(helpers.target())
                    if button == nil then
                        return nil
                    end
                    if key == "LFGFInvite" then
                        return L["Invite"]
                    end
                    if key == "LFGFDelist" then
                        return L["Remove my listing"]
                    end
                    if button.Check ~= nil and game.shown(button.Check) then
                        return L["Ask to join"] .. ", " .. L["already asked"]
                    end
                    return L["Ask to join"]
                end,
                kind = kinds.value,
                live = "focus",
            },
            -- a guild member or a friend, and your rating (a group: the lowest among its members), as LFG Forever
            -- marks the drawn row
            {
                text = function()
                    return marks(helpers.target(), "LFGFRelation", "LFGFRatingStrip", function()
                        return not labels.isSolo(row.resultID)
                    end)
                end,
                kind = kinds.value,
                live = "focus",
            },
        },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = primary },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
        },
        contextActions = function(add)
            local frame = helpers.target()
            if frame ~= nil and game.shown(frame.LFGFAskToJoin) then
                add({
                    label = L["Ask to join"],
                    click = { emulatedKey = "LeftButton", target = frame.LFGFAskToJoin },
                })
            end
            if frame ~= nil and game.shown(frame.LFGFInvite) then
                add({ label = L["Invite"], click = { emulatedKey = "LeftButton", target = frame.LFGFInvite } })
            end
            if frame ~= nil and game.shown(frame.LFGFDelist) then
                add({
                    label = L["Remove my listing"],
                    click = { emulatedKey = "LeftButton", target = frame.LFGFDelist },
                })
            end
            add({ label = L["Right click menu"], click = { emulatedKey = "RightButton", target = helpers.target } })
        end,
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    }
end

local function renderResults(builder, list)
    local scrollBox = list ~= nil and list.ScrollBox or nil
    if scrollBox == nil then
        return
    end
    builder:beginStop("results")
    builder:pushContext("results", L["Search results"])
    if game.shown(list.SearchingSpinner) then
        builder:addItem(structural("results:searching"), nodes.text({ label = L["Searching"], live = "focus" }))
    end
    nodes.scrollBoxList(builder, {
        scrollBox = scrollBox,
        key = "results",
        id = function(data, index)
            local row = rowData(data)
            if type(row) == "table" and row.resultID ~= nil then
                return structural("result:" .. tostring(row.resultID))
            elseif type(row) == "table" and row.dividerType ~= nil then
                return structural("resultsHeader:" .. tostring(row.dividerType))
            end
            return structural("result:" .. tostring(index))
        end,
        row = function(data, index, helpers)
            local row = rowData(data)
            if type(row) == "table" and row.dividerType ~= nil then
                return dividerRow(data, row, helpers)
            end
            return listingRow(data, type(row) == "table" and row or {}, helpers)
        end,
    })
    builder:popContext()
end

-- --------------------------------------------------------------- filters

local function checkNode(check)
    return nodes.proxyCheckButton({ target = check, label = nodes.fontText(check.Text) })
end

local function addChecks(builder, checks)
    for _, check in ipairs(checks or {}) do
        if game.shown(check) then
            builder:addItem(ControlId.forObject(check), checkNode(check))
        end
    end
end

-- The header of a section: Enter folds or unfolds it, and it says which, and whether something in it is not at its
-- default while it is folded (LFG Forever shows a warning icon there).
local function addHeader(builder, section)
    local header = section.Header
    if header == nil or not game.shown(header) then
        return
    end
    local vtable = nodes.proxyButton({ target = header, label = nodes.fontText(section.Title) })
    if vtable == nil then
        return
    end
    table.insert(vtable.announcements, {
        text = function()
            return section.collapsed and L["Collapsed"] or L["Expanded"]
        end,
        kind = kinds.value,
        live = "focus",
    })
    table.insert(vtable.announcements, {
        text = function()
            if header.Warning ~= nil and game.shown(header.Warning) then
                return L["has changed filters"]
            end
            return nil
        end,
        kind = kinds.value,
    })
    builder:addItem(ControlId.forObject(header), vtable)
end

-- A folded section hides its controls, but IsShown of a child stays true, so the section's own state is tested.
local function isExpanded(section)
    return section.collapsed ~= true and section.Content ~= nil and game.shown(section.Content)
end

local function sectionTitle(section)
    return textOf(section.Title)
end

local function levelBoxes(builder, filter)
    local range = filter.LevelRange
    if range == nil or not game.shown(range) then
        return
    end
    local label = textOf(filter.LevelLabel) or ""
    for _, info in ipairs({
        { box = range.MinLevel, key = "%s, minimum" },
        { box = range.MaxLevel, key = "%s, maximum" },
    }) do
        if info.box ~= nil and game.shown(info.box) then
            builder:addItem(
                ControlId.forObject(info.box),
                nodes.proxyEditBox({ editBox = info.box, label = string.format(L[info.key], label) })
            )
        end
    end
end

local function labelledDropdown(builder, dropdown, labelFontString)
    if dropdown == nil or not game.shown(dropdown) then
        return
    end
    builder:addItem(
        ControlId.forObject(dropdown),
        dropdownNode(dropdown, function()
            return textOf(labelFontString)
        end)
    )
end

local function renderGroupsSection(builder, filter)
    local section = filter.GroupSection
    if section == nil or not game.shown(section) then
        return
    end
    builder:beginStop("filters:groups")
    builder:pushContext("filters:groups", sectionTitle(section))
    addHeader(builder, section)
    if isExpanded(section) then
        addChecks(builder, filter.GroupFilterChecks)
        if filter.GroupClassDropdown ~= nil and game.shown(filter.GroupClassDropdown) then
            builder:addItem(
                ControlId.forObject(filter.GroupClassDropdown),
                nodes.proxyDropdown({ target = filter.GroupClassDropdown })
            )
        end
    end
    -- these four sit on the section's title row, folded or not
    addButton(builder, filter.ResetFiltersLink)
    addButton(builder, filter.SaveNewFilterLink)
    if filter.MyFiltersDropdown ~= nil and game.shown(filter.MyFiltersDropdown) then
        builder:addItem(
            ControlId.forObject(filter.MyFiltersDropdown),
            nodes.proxyDropdown({ target = filter.MyFiltersDropdown })
        )
    end
    builder:popContext()
end

local function renderRolesSection(builder, filter)
    local section = filter.RoleSection
    if section == nil or not game.shown(section) then
        return
    end
    builder:beginStop("filters:roles")
    builder:pushContext("filters:roles", sectionTitle(section))
    addHeader(builder, section)
    if isExpanded(section) then
        addChecks(builder, filter.PlayerRoleChecks)
        levelBoxes(builder, filter)
    end
    builder:popContext()
end

local function renderClassesSection(builder, filter)
    local section = filter.ClassSection
    if section == nil or not game.shown(section) then
        return
    end
    builder:beginStop("filters:classes")
    builder:pushContext("filters:classes", sectionTitle(section))
    addHeader(builder, section)
    if isExpanded(section) then
        addChecks(builder, filter.PlayerClassChecks)
        addButton(builder, filter.UnselectAllClasses)
        addButton(builder, filter.SelectAllClasses)
    end
    builder:popContext()
end

local function renderMiscellaneousSection(builder, filter)
    local section = filter.MiscellaneousSection
    if section == nil or not game.shown(section) then
        return
    end
    builder:beginStop("filters:misc")
    builder:pushContext("filters:misc", sectionTitle(section))
    addHeader(builder, section)
    if isExpanded(section) then
        labelledDropdown(builder, filter.PlaystyleDropdown, filter.PlaystyleLabel)
        labelledDropdown(builder, filter.LanguagesDropdown, filter.LanguagesLabel)
    end
    builder:popContext()
end

-- -------------------------------------------------------------- whispers

-- The links of a whisper line, found on the drawn row when the context menu opens (a link only shows when it
-- applies).
local function shownLink(helpers, field)
    local frame = helpers.target()
    local link = frame ~= nil and frame[field] or nil
    if link ~= nil and game.shown(link) then
        return link
    end
    return nil
end

local function whisperRow(data, index, helpers)
    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return labels.whisper(data)
                end,
                kind = kinds.label,
            },
            -- a guild member or a friend, and your rating of the sender, as LFG Forever marks the drawn row
            {
                text = function()
                    return marks(helpers.target(), "Relation", "RatingStrip")
                end,
                kind = kinds.value,
                live = "focus",
            },
        },
        -- Enter opens the line's menu (whisper back, invite, add friend...), as a right click does
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
        },
        contextActions = function(add)
            local invite = shownLink(helpers, "InviteLink")
            if invite ~= nil then
                add({ label = L["Invite"], click = { emulatedKey = "LeftButton", target = invite } })
            end
            local location = shownLink(helpers, "LocationLink")
            if location ~= nil then
                add({ label = L["Where is this player"], click = { emulatedKey = "LeftButton", target = location } })
            end
            local remove = shownLink(helpers, "RemoveLink")
            if remove ~= nil then
                add({ label = L["Remove"], click = { emulatedKey = "LeftButton", target = remove } })
            end
        end,
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    }
end

local function renderWhispers(builder, filter)
    local log = filter.WhisperLog
    if log == nil or log.ScrollBox == nil then
        return
    end
    builder:beginStop("whispers")
    builder:pushContext("whispers", filter.WhispersSection ~= nil and sectionTitle(filter.WhispersSection) or nil)
    nodes.scrollBoxList(builder, {
        scrollBox = log.ScrollBox,
        key = "whispers",
        row = whisperRow,
    })
    addButton(builder, filter.ClearChatLink)
    builder:popContext()
end

-- --------------------------------------------------------------- ratings

local function ratingOf(frame)
    local stars = frame ~= nil and frame.Stars or nil
    if stars == nil then
        return nil
    end
    return game.readable(stars.rating)
end

local function allyRow(data, index, helpers)
    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return labels.ally(data)
                end,
                kind = kinds.label,
            },
            -- the stars are on the drawn row, so they are said once it is there
            {
                text = function()
                    local frame = helpers.target()
                    if frame == nil or frame.Stars == nil then
                        return nil
                    end
                    return labels.rating(ratingOf(frame))
                end,
                kind = kinds.value,
                live = "focus",
            },
            -- a guild member or a friend, as LFG Forever marks the drawn row
            {
                text = function()
                    return marks(helpers.target(), "Relation", nil)
                end,
                kind = kinds.value,
                live = "focus",
            },
        },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
        },
        contextActions = function(add)
            for count = 1, 3 do
                local label = count == 1 and L["Rate 1 star"] or string.format(L["Rate %d stars"], count)
                add({
                    label = label,
                    click = {
                        emulatedKey = "LeftButton",
                        target = function()
                            local frame = helpers.target()
                            local stars = frame ~= nil and frame.Stars or nil
                            return stars ~= nil and stars.Buttons ~= nil and stars.Buttons[count] or nil
                        end,
                    },
                })
            end
            add({ label = L["Right click menu"], click = { emulatedKey = "RightButton", target = helpers.target } })
        end,
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    }
end

local function renderRatings(builder, filter)
    local ratings = filter.PlayerRatings
    if ratings == nil or ratings.ScrollBox == nil then
        return
    end
    builder:beginStop("ratings")
    builder:pushContext("ratings", filter.RatingsSection ~= nil and sectionTitle(filter.RatingsSection) or nil)
    nodes.scrollBoxList(builder, {
        scrollBox = ratings.ScrollBox,
        key = "ratings",
        row = allyRow,
    })
    addButton(builder, filter.ClearPlayerRatingLink)
    builder:popContext()
end

-- --------------------------------------------------------------- options

local function renderOptions(builder, filter)
    if filter.SettingsGear == nil or not game.shown(filter.SettingsGear) then
        return
    end
    builder:beginStop("options")
    -- one control: no "1 of 1"
    builder:pushContext("options", L["Settings"], nil, false)
    addButton(builder, filter.SettingsGear, L["Settings"])
    builder:popContext()
end

-- ---------------------------------------------------------------- screen

function module.render(builder)
    local frame, filter, list = game.panels()
    if not game.shown(frame) then
        return
    end
    if filter == nil then
        -- the window is on screen but has no filter panel: LFG Forever changed what this reads
        module.sayOnce("panels", L["LFG Forever's window has changed and cannot be read"])
        return
    end
    builder:pushContext("lfg", L["LFG Forever"])
    part(builder, "tabs", renderTabs, filter)
    part(builder, "search", renderSearch, filter)
    part(builder, "results", renderResults, list)
    local tab = currentTab(filter)
    if tab == "filters" then
        part(builder, "groups filters", renderGroupsSection, filter)
        part(builder, "player filters", renderRolesSection, filter)
        part(builder, "class filters", renderClassesSection, filter)
        part(builder, "other filters", renderMiscellaneousSection, filter)
    elseif tab == "whispers" then
        part(builder, "whispers", renderWhispers, filter)
    else
        part(builder, "ratings", renderRatings, filter)
    end
    part(builder, "options", renderOptions, filter)
    builder:popContext()
end

-- WowVision opens its screen whenever LFG Forever's window is shown (/lfg, LFG Forever's own key, its minimap
-- button) and closes it when that is hidden, like the windows it registers for the game's own frames.
module:registerWindow({
    type = "FrameWindow",
    name = game.WINDOW,
    frameName = game.FRAME,
    conflictingAddons = { "Sku" },
    graphScreen = {
        render = module.render,
        -- Escape: the window is LFG Forever's own, closed the way its close button does (a plain Hide)
        onRequestClose = function()
            game.hide()
        end,
    },
})
