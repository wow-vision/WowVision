local module = WowVision.base.windows:createModule("lfg")
local L = module.L
module:setLabel(L["Looking for Group"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC anniversary LFG tool: the listing tab (category or activity
-- selection, roles, comment, post) and the browse tab (filters, results
-- with data-first labels from the LFG list API, contact buttons).
--
-- WoW: Forever runs a newer build of the same Blizzard addon. Its client
-- folder replaces module.renderTabBar (side tabs instead of the bottom
-- ones), fills module.renderListingOptions (the controls only that build
-- has) and registers a third tab body with module.addTab
-- (camelot/lfg.lua).

module.tabs = {}

-- Register a tab body: render(builder) runs while that tab is selected.
function module.addTab(tabIndex, render)
    module.tabs[tabIndex] = render
end

-- Listing controls a client adds after the comment box; none here.
function module.renderListingOptions(builder) end

local function findCheckButton(parent)
    local children = { parent:GetChildren() }
    for _, child in ipairs(children) do
        if child:GetObjectType() == "CheckButton" then
            return child
        end
    end
end

local function findEditBox(parent)
    local children = { parent:GetChildren() }
    for _, child in ipairs(children) do
        if child:GetObjectType() == "EditBox" then
            return child
        end
    end
end

-- A list row's own table. Tree lists (the listing's activities, Forever's
-- browse results) hold tree nodes wrapping that table; flat lists (TBC's
-- browse results) hold the tables themselves. Browse rows are { resultID }
-- or, on WoW: Forever, the header { dividerType } of the collapsible solo
-- and group sections.
local function rowData(data)
    if type(data) == "table" and data.GetData ~= nil then
        return data:GetData()
    end
    return data
end

local function renderLockedView(builder)
    builder:beginStop("locked")
    builder:addItem(
        ControlId.structural("locked"),
        nodes.text({
            label = function()
                local text = ""
                for _, region in ipairs({ LFGListingFrameLockedView:GetRegions() }) do
                    if region:GetObjectType() == "FontString" and region:IsShown() then
                        local str = region:GetText()
                        if str ~= nil and str ~= "" then
                            if text ~= "" then
                                text = text .. " "
                            end
                            text = text .. str
                        end
                    end
                end
                return text
            end,
        })
    )
end

local function renderCategoryList(builder)
    builder:beginStop("categories")
    builder:pushContext("categories", L["Categories"])
    local emitted = 0
    for _, child in ipairs({ LFGListingFrameCategoryView:GetChildren() }) do
        if child:IsShown() and child:GetObjectType() == "Button" then
            builder:addItem(ControlId.forObject(child), nodes.proxyButton({ target = child }))
            emitted = emitted + 1
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("categoriesEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()
end

local function activityName(data)
    if data ~= nil and data.GetData ~= nil then
        local ok, inner = pcall(data.GetData, data)
        if ok and inner ~= nil and inner.name ~= nil then
            return inner.name
        end
    end
    if type(data) == "table" and data.name ~= nil then
        return data.name
    end
    return nil
end

-- An activity's suggested levels as the row shows them; nil for a group
-- and for an activity without levels.
local function activityLevels(row)
    if row == nil or row.activityID == nil then
        return nil
    end
    local minLevel, maxLevel = row.minLevel or 0, row.maxLevel or 0
    if minLevel == maxLevel or maxLevel == 0 then
        if minLevel == 0 then
            return nil
        end
        return format(LFD_LEVEL_FORMAT_SINGLE, minLevel)
    end
    return format(LFD_LEVEL_FORMAT_RANGE, minLevel, maxLevel)
end

-- The activity list is a tree: activities sit under activity groups
-- (dungeons, raids, ...). With several groups each folds; a group without
-- an activity at the player's level starts folded. A group's check box
-- selects its whole group; folding is its context menu's Expand/Collapse.
local function renderActivityList(builder)
    builder:beginStop("activities")
    nodes.scrollBoxList(builder, {
        scrollBox = LFGListingFrameActivityViewScrollBox,
        key = "activities",
        label = L["Activities"],
        id = function(data, index)
            local name = activityName(data)
            if name ~= nil then
                return ControlId.structural("activity:" .. name)
            end
            return ControlId.structural("activity:" .. index)
        end,
        button = function(rowFrame)
            return findCheckButton(rowFrame) or rowFrame
        end,
        row = function(data, index, helpers)
            local row = rowData(data)
            local isGroup = row ~= nil and row.activityGroupID ~= nil and row.activityID == nil
            local foldable = isGroup and row.showExpandCollapseButton and data.IsCollapsed ~= nil
            local expandButton = function()
                local check = helpers.target()
                local rowFrame = check ~= nil and check:GetParent() or nil
                return rowFrame ~= nil and rowFrame.ExpandOrCollapseButton or nil
            end
            return {
                controlType = graph.controlTypes.toggle,
                announcements = {
                    {
                        text = function()
                            return activityName(data)
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            return activityLevels(row)
                        end,
                        kind = kinds.value,
                    },
                    {
                        text = function()
                            local check = helpers.target()
                            if check ~= nil and check.GetChecked ~= nil then
                                return check:GetChecked() and L["Checked"] or L["Unchecked"]
                            end
                            return nil
                        end,
                        kind = kinds.value,
                        live = "focus",
                    },
                    {
                        text = function()
                            if foldable then
                                return data:IsCollapsed() and L["Collapsed"] or L["Expanded"]
                            end
                            return nil
                        end,
                        kind = kinds.value,
                        live = "focus",
                    },
                },
                bindings = {
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                },
                contextActions = foldable and function(add)
                    add({ label = L["Expand/Collapse"], click = { emulatedKey = "LeftButton", target = expandButton } })
                end or nil,
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
            }
        end,
    })
end

local function renderRoles(builder)
    builder:beginStop("roles")
    builder:pushContext("roles", L["Roles"])
    if LFGListingFrameSoloRoleButtons:IsShown() then
        local roles = {
            { frame = LFGListingFrameSoloRoleButtonsRoleButtonTank, label = L["Tank"] },
            { frame = LFGListingFrameSoloRoleButtonsRoleButtonHealer, label = L["Healer"] },
            { frame = LFGListingFrameSoloRoleButtonsRoleButtonDPS, label = L["Damage Dealer"] },
        }
        for _, role in ipairs(roles) do
            local check = findCheckButton(role.frame)
            if check ~= nil then
                builder:addItem(
                    ControlId.forObject(check),
                    nodes.proxyCheckButton({ target = check, label = role.label })
                )
            end
        end
    elseif LFGListingFrameGroupRoleButtons:IsShown() then
        builder:addItem(
            ControlId.forObject(LFGListingFrameGroupRoleButtonsRoleDropdown),
            module.dropdown({ target = LFGListingFrameGroupRoleButtonsRoleDropdown })
        )
        builder:addItem(
            ControlId.forObject(LFGListingFrameGroupRoleButtonsInitiateRolePoll),
            nodes.proxyButton({ target = LFGListingFrameGroupRoleButtonsInitiateRolePoll })
        )
    end

    local newPlayerFriendly = findCheckButton(LFGListingFrameNewPlayerFriendlyButton)
    if newPlayerFriendly ~= nil then
        builder:addItem(
            ControlId.forObject(newPlayerFriendly),
            nodes.proxyCheckButton({ target = newPlayerFriendly, label = L["New Player Friendly"] })
        )
    end
    builder:popContext()
end

-- The group finder's dropdowns. A pick in a game menu that addon code opened
-- counts as WowVision's (the game builds the whole menu in that call), and
-- C_LFGList.Search refuses such values: after a post, the game's own search
-- was blocked by the play style and voice chat picks. These dropdowns open
-- only on a real mouse press, so Enter cannot click them. TRIAL: Enter
-- hands the dropdown's own OpenMenu, bound to it by the game's
-- GenerateFlatClosure, to a next-frame timer, so the game's timer runs the
-- game's code; the taint timeline (core/taintWatch.lua) shows whether the
-- picks then stay clean.
function module.dropdown(config)
    local vtable = nodes.proxyDropdown(config)
    if vtable == nil then
        return nil
    end
    local target = config.target
    vtable.onActivate = function()
        C_Timer.After(0, GenerateFlatClosure(target.OpenMenu, target))
    end
    return vtable
end

-- The options menu (top right of a tab): its one check box, "Ignore
-- suggested level", shows activities outside the player's level in both
-- tabs. TBC has it on both tabs, WoW: Forever on the browse tab only.
-- The stop is named after that check box and says its state (the console
-- variable the box reads); Enter still opens the game's menu, where the
-- box itself is ticked.
local function renderOptionsButton(builder, button)
    if button == nil or not button:IsShown() then
        return
    end
    local vtable = module.dropdown({ target = button, label = LFG_LIST_IGNORE_SUGGESTED_LEVEL or L["Options"] })
    if vtable == nil then
        return
    end
    tinsert(vtable.announcements, {
        text = function()
            return GetCVarBool("disableSuggestedLevelActivityFilter") and L["Checked"] or L["Unchecked"]
        end,
        kind = kinds.value,
        live = "focus",
    })
    builder:beginStop("options")
    builder:addItem(ControlId.forObject(button), vtable)
end

local function renderListingTab(builder)
    if LFGListingFrameLockedView:IsShown() then
        renderLockedView(builder)
        return
    end

    renderOptionsButton(builder, LFGListingFrame.OptionsButton)

    if LFGListingFrameActivityView:IsShown() then
        renderActivityList(builder)
        if LFGListingFrameBackButton ~= nil and LFGListingFrameBackButton:IsShown() then
            builder:beginStop("back")
            builder:addItem(
                ControlId.forObject(LFGListingFrameBackButton),
                nodes.proxyButton({ target = LFGListingFrameBackButton })
            )
        end
    else
        renderCategoryList(builder)
    end

    renderRoles(builder)

    local commentBox = findEditBox(LFGListingComment)
    if commentBox ~= nil then
        builder:beginStop("comment")
        builder:addItem(
            ControlId.structural("comment"),
            nodes.proxyEditBox({ editBox = commentBox, label = L["Comment"] })
        )
    end

    module.renderListingOptions(builder)

    if LFGListingFramePostButton ~= nil and LFGListingFramePostButton:IsShown() then
        builder:beginStop("post")
        builder:addItem(
            ControlId.forObject(LFGListingFramePostButton),
            nodes.proxyButton({ target = LFGListingFramePostButton })
        )
    end
end

local function browseDividerLabel(dividerType)
    local types = LFGVanillaBrowseDividerType
    if types ~= nil and dividerType == types.CategorySolo then
        return LFG_LIST_CATEGORY_SOLO_PLAYERS
    elseif types ~= nil and dividerType == types.CategoryGroup then
        return LFG_LIST_CATEGORY_GROUPS
    end
    return GROUP
end

local function browseResultLabel(data)
    if data == nil or data.resultID == nil then
        return nil
    end
    local ok, info = pcall(C_LFGList.GetSearchResultInfo, data.resultID)
    if not ok or info == nil then
        return nil
    end
    local parts = {}
    if info.leaderName ~= nil and info.leaderName ~= "" then
        tinsert(parts, info.leaderName)
    end
    local actInfo
    if info.activityIDs ~= nil and info.activityIDs[1] ~= nil then
        local aOk, aResult = pcall(C_LFGList.GetActivityInfoTable, info.activityIDs[1])
        if aOk then
            actInfo = aResult
        end
    end
    if actInfo ~= nil and actInfo.shortName ~= nil then
        tinsert(parts, actInfo.shortName)
    end
    if info.numMembers ~= nil then
        local maxPlayers = actInfo ~= nil and actInfo.maxNumPlayers ~= nil and ("/" .. actInfo.maxNumPlayers) or ""
        tinsert(parts, info.numMembers .. maxPlayers .. " " .. L["Members"])
    end
    if info.comment ~= nil and info.comment ~= "" then
        tinsert(parts, info.comment)
    end
    if #parts > 0 then
        return table.concat(parts, " - ")
    end
    return GROUP or "Group"
end

local function renderBrowseTab(builder)
    if LFGBrowseFrameCategoryDropdown ~= nil and LFGBrowseFrameCategoryDropdown:IsShown() then
        builder:beginStop("categoryFilter")
        builder:addItem(
            ControlId.forObject(LFGBrowseFrameCategoryDropdown),
            module.dropdown({ target = LFGBrowseFrameCategoryDropdown })
        )
    end
    if LFGBrowseFrameActivityDropdown ~= nil and LFGBrowseFrameActivityDropdown:IsShown() then
        builder:beginStop("activityFilter")
        builder:addItem(
            ControlId.forObject(LFGBrowseFrameActivityDropdown),
            module.dropdown({ target = LFGBrowseFrameActivityDropdown })
        )
    end
    if LFGBrowseFrameRefreshButton ~= nil and LFGBrowseFrameRefreshButton:IsShown() then
        builder:beginStop("refresh")
        builder:addItem(
            ControlId.forObject(LFGBrowseFrameRefreshButton),
            nodes.proxyButton({ target = LFGBrowseFrameRefreshButton, label = L["Search"] })
        )
    end
    renderOptionsButton(builder, LFGBrowseFrame.OptionsButton)

    builder:beginStop("groups")
    nodes.scrollBoxList(builder, {
        scrollBox = LFGBrowseFrameScrollBox,
        key = "groups",
        label = L["Browse Groups"],
        id = function(data, index)
            local row = rowData(data)
            if row ~= nil and row.resultID ~= nil then
                return ControlId.structural("group:" .. row.resultID)
            elseif row ~= nil and row.dividerType ~= nil then
                return ControlId.structural("groupHeader:" .. row.dividerType)
            end
            return ControlId.structural("group:" .. index)
        end,
        row = function(data, index, helpers)
            local row = rowData(data)
            local state
            if row ~= nil and row.dividerType ~= nil then
                state = {
                    text = function()
                        return data.collapsed and L["Collapsed"] or L["Expanded"]
                    end,
                    kind = kinds.value,
                    live = "focus",
                }
            else
                state = {
                    text = function()
                        local selection = LFGBrowseFrame.selectionBehavior
                        if selection ~= nil and selection:IsElementDataSelected(data) then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                    live = "focus",
                }
            end
            return {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            if row ~= nil and row.dividerType ~= nil then
                                return browseDividerLabel(row.dividerType)
                            end
                            return browseResultLabel(row)
                        end,
                        kind = kinds.label,
                    },
                    state,
                },
                bindings = {
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                    { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
                },
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
                tooltipFrame = helpers.target,
            }
        end,
    })

    for _, button in ipairs({ LFGBrowseFrameSendMessageButton, LFGBrowseFrameGroupInviteButton }) do
        if button ~= nil and button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end
end

module.addTab(1, renderListingTab)
module.addTab(2, renderBrowseTab)

-- The bottom tabs LFGParentFrameTab1..2, as real clicks.
function module.renderTabBar(builder)
    for i = 1, 2 do
        local tab = _G["LFGParentFrameTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        if PanelTemplates_GetSelectedTab(LFGParentFrame) == tabIndex then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                })
                builder:addItem(ControlId.forObject(tab), vtable)
            end
        end
    end
end

local function render(builder, screen)
    if LFGParentFrame == nil or not LFGParentFrame:IsShown() then
        return
    end
    builder:pushContext("lfg", L["Looking for Group"])

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    module.renderTabBar(builder)
    builder:endRow()
    builder:popContext()

    local body = module.tabs[PanelTemplates_GetSelectedTab(LFGParentFrame) or 0]
    if body ~= nil then
        body(builder)
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "lfg",
    frameName = "LFGParentFrame",
    graphScreen = { render = render },
})

-- Blocked-call records (/wv taint) and the taint timeline list the fields
-- of these tables that addon code wrote: the values the listing's post and
-- the browse search read. WowVision.taintWatch exists from the taint recorder on.
if WowVision.taintWatch ~= nil then
    local watch = WowVision.taintWatch.watch
    watch("LFGParentFrame", function()
        return LFGParentFrame
    end)
    watch("LFGListingFrame", function()
        return LFGListingFrame
    end)
    watch("LFGListingFrame.ActivityView", function()
        return LFGListingFrame ~= nil and LFGListingFrame.ActivityView or nil
    end)
    watch("LFGListingFrame.CategoryView", function()
        return LFGListingFrame ~= nil and LFGListingFrame.CategoryView or nil
    end)
    watch("ActivityView.PlayStyleDropdown", function()
        local view = LFGListingFrame ~= nil and LFGListingFrame.ActivityView or nil
        return view ~= nil and view.PlayStyleDropdown or nil
    end)
    watch("ActivityView.VoiceChatDropdown", function()
        local view = LFGListingFrame ~= nil and LFGListingFrame.ActivityView or nil
        return view ~= nil and view.VoiceChatDropdown or nil
    end)
    watch("LFGBrowseFrame", function()
        return LFGBrowseFrame
    end)
    watch("LFGBrowseFrame.CategoryDropdown", function()
        return LFGBrowseFrame ~= nil and LFGBrowseFrame.CategoryDropdown or nil
    end)
    watch("LFGBrowseFrame.ActivityDropdown", function()
        return LFGBrowseFrame ~= nil and LFGBrowseFrame.ActivityDropdown or nil
    end)
    watch("LFGBrowseFrame.ActivityDropdown.selectedValues", function()
        local dropdown = LFGBrowseFrame ~= nil and LFGBrowseFrame.ActivityDropdown or nil
        return dropdown ~= nil and dropdown.selectedValues or nil
    end)
end
