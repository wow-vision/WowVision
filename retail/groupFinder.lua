local module = WowVision.base.windows:createModule("groupFinder")
local L = module.L
module:setLabel(L["Looking for Group"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- Retail's group finder (PVEFrame, Blizzard_GroupFinder Mainline): the
-- bottom tabs, the Group Finder tab's buttons (Dungeon Finder, Raid Finder,
-- Premade Groups) and the Dungeon Finder itself (LFDQueueFrame): the type
-- dropdown (follower dungeons, specific dungeons, the random ones), the
-- roles, the dungeon list of the follower and specific types, the rewards
-- of a random type, the covers that replace the finder (party backfill,
-- deserter cooldown) and Find Group. Everything is the game's own controls,
-- clicked as they are. The other tabs and Raid Finder and Premade Groups
-- are not read yet. WoW: Forever never loads PVEFrame (its group finder is
-- tbc/lfg.lua with camelot/lfg.lua).

-- A frame's shown text, its own regions and its children's, joined: the
-- reward panel of a random dungeon, the cover frames.
local function frameTexts(frame)
    return function()
        local parts = {}
        local function collect(f, depth)
            for _, region in ipairs({ f:GetRegions() }) do
                if region:GetObjectType() == "FontString" and region:IsShown() then
                    local text = nodes.plainText(region:GetText())
                    if text ~= nil and text ~= "" then
                        tinsert(parts, text)
                    end
                end
            end
            if depth < 3 then
                for _, child in ipairs({ f:GetChildren() }) do
                    if child:IsShown() and child:GetObjectType() ~= "Button" then
                        collect(child, depth + 1)
                    end
                end
            end
        end
        collect(frame, 1)
        if #parts == 0 then
            return nil
        end
        return table.concat(parts, ", ")
    end
end

local function selectedWhen(isSelected)
    return {
        text = function()
            return isSelected() and L["selected"] or nil
        end,
        kind = kinds.selected,
    }
end

-- The bottom tabs (Group Finder, Player vs. Player, Mythic+ Dungeons and
-- whatever the client adds), as real clicks.
local function renderTabs(builder)
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, 8 do
        local tab = _G["PVEFrameTab" .. i]
        if tab ~= nil and tab:IsShown() then
            local tabIndex = i
            local vtable = nodes.proxyButton({ target = tab })
            if vtable ~= nil then
                tinsert(
                    vtable.announcements,
                    selectedWhen(function()
                        return PanelTemplates_GetSelectedTab(PVEFrame) == tabIndex
                    end)
                )
                builder:addItem(ControlId.forObject(tab), vtable)
            end
        end
    end
    builder:endRow()
    builder:popContext()
end

-- The Group Finder tab's buttons: Dungeon Finder, Raid Finder, Premade
-- Groups (and Scenarios where the client has them).
local function renderGroupButtons(builder)
    builder:beginStop("groupButtons")
    for i = 1, 4 do
        local button = GroupFinderFrame["groupButton" .. i]
        if button ~= nil and button:IsShown() then
            local captured = button
            local vtable = nodes.proxyButton({ target = button, label = nodes.fontText(button.name) })
            if vtable ~= nil then
                tinsert(
                    vtable.announcements,
                    selectedWhen(function()
                        return GroupFinderFrame.selectionIndex == captured:GetID()
                    end)
                )
                builder:addItem(ControlId.forObject(button), vtable)
            end
        end
    end
end

local ROLES = {
    { name = "LFDQueueFrameRoleButtonTank", label = L["Tank"] },
    { name = "LFDQueueFrameRoleButtonHealer", label = L["Healer"] },
    { name = "LFDQueueFrameRoleButtonDPS", label = L["Damage Dealer"] },
    { name = "LFDQueueFrameRoleButtonLeader", label = L["Leader"] },
}

local function renderRoles(builder)
    builder:beginStop("roles")
    builder:pushContext("roles", L["Roles"])
    builder:startRow()
    for _, role in ipairs(ROLES) do
        local button = _G[role.name]
        local check = button ~= nil and button.checkButton or nil
        if check ~= nil and button:IsShown() then
            local vtable = nodes.proxyCheckButton({ target = check, label = role.label, allowHidden = true })
            if vtable ~= nil then
                builder:addItem(ControlId.forObject(check), vtable)
            end
        end
    end
    builder:endRow()
    builder:popContext()
end

-- The dungeon type: "<label>: <current pick>".
local function renderTypeDropdown(builder)
    local dropdown = LFDQueueFrame.TypeDropdown
    if dropdown == nil or not dropdown:IsShown() then
        return
    end
    local caption = _G["LFDQueueFrameTypeDropdownName"]
    local current = nodes.frameText(dropdown)
    builder:beginStop("type")
    builder:addItem(
        ControlId.forObject(dropdown),
        nodes.proxyDropdown({
            target = dropdown,
            label = function()
                local pick = current()
                local name = caption ~= nil and nodes.plainText(caption:GetText()) or nil
                if name ~= nil and name ~= "" and pick ~= nil then
                    return name .. " " .. pick
                end
                return pick
            end,
        })
    )
end

-- One dungeon or header of the follower and specific lists, from its id:
-- the game's name and levels, whether it is locked, and its check state
-- (the lists the game itself checks the rows against).
local function dungeonLevels(dungeonID)
    local _, _, _, minLevel, maxLevel = GetLFGDungeonInfo(dungeonID)
    if minLevel == nil then
        return nil
    end
    if minLevel == maxLevel then
        return format(LFD_LEVEL_FORMAT_SINGLE, minLevel)
    end
    return format(LFD_LEVEL_FORMAT_RANGE, minLevel, maxLevel)
end

local function checkState(dungeonID)
    if LFGLockList ~= nil and LFGLockList[dungeonID] then
        return L["Locked"]
    end
    local _, queued = LFGDungeonList_EvaluateListState(LE_LFG_CATEGORY_LFD)
    local list = queued and LFGQueuedForList[LE_LFG_CATEGORY_LFD] or LFGEnabledList
    local state = list ~= nil and list[dungeonID] or nil
    if state == 1 then
        return L["Partially Checked"]
    end
    if state and state ~= 0 then
        return L["Checked"]
    end
    return L["Unchecked"]
end

local function renderDungeonList(builder, scrollBox, key)
    builder:beginStop(key)
    nodes.scrollBoxList(builder, {
        scrollBox = scrollBox,
        key = key,
        label = nodes.frameText(LFDQueueFrame.TypeDropdown),
        id = function(data, index)
            local dungeonID = type(data) == "table" and data.dungeonID or nil
            return ControlId.structural(key .. ":" .. tostring(dungeonID or index))
        end,
        button = function(rowFrame)
            return rowFrame.enableButton or rowFrame
        end,
        row = function(data, index, helpers)
            local dungeonID = type(data) == "table" and data.dungeonID or nil
            local isHeader = dungeonID ~= nil and LFGIsIDHeader(dungeonID)
            local rowFrame = function()
                local check = helpers.target()
                return check ~= nil and check:GetParent() or nil
            end
            local expandButton = function()
                local row = rowFrame()
                return row ~= nil and row.expandOrCollapseButton or nil
            end
            return {
                controlType = graph.controlTypes.toggle,
                announcements = {
                    {
                        text = function()
                            return dungeonID ~= nil and (GetLFGDungeonInfo(dungeonID)) or nil
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            if dungeonID == nil or isHeader then
                                return nil
                            end
                            return dungeonLevels(dungeonID)
                        end,
                        kind = kinds.value,
                    },
                    {
                        text = function()
                            return dungeonID ~= nil and checkState(dungeonID) or nil
                        end,
                        kind = kinds.value,
                        live = "focus",
                    },
                    {
                        text = function()
                            if not isHeader then
                                return nil
                            end
                            return LFGCollapseList ~= nil and LFGCollapseList[dungeonID] and L["Collapsed"]
                                or L["Expanded"]
                        end,
                        kind = kinds.value,
                        live = "focus",
                    },
                },
                bindings = {
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                },
                contextActions = isHeader and function(add)
                    add({ label = L["Expand/Collapse"], click = { emulatedKey = "LeftButton", target = expandButton } })
                end or nil,
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
                -- the row's hover shows why a locked dungeon cannot be queued
                tooltipFrame = rowFrame,
            }
        end,
    })
end

-- A cover over the finder (in a group that is still looking for members,
-- under the deserter cooldown): its text and its buttons.
local function renderCover(builder, cover, key)
    if cover == nil or not cover:IsShown() then
        return false
    end
    builder:beginStop(key)
    builder:addItem(ControlId.structural(key .. ":text"), nodes.text({ label = frameTexts(cover) }))
    for _, child in ipairs({ cover:GetChildren() }) do
        if child:IsShown() and child:GetObjectType() == "Button" then
            local vtable = nodes.proxyButton({ target = child })
            if vtable ~= nil then
                builder:addItem(ControlId.forObject(child), vtable)
            end
        end
    end
    return true
end

local function renderDungeonFinder(builder)
    local frame = LFDQueueFrame
    renderRoles(builder)
    renderTypeDropdown(builder)
    local covered = renderCover(builder, frame.PartyBackfill, "backfill")
    covered = renderCover(builder, frame.CooldownFrame, "cooldown") or covered
    if not covered then
        if frame.Follower ~= nil and frame.Follower:IsShown() then
            builder:beginStop("followerIntro")
            builder:addItem(ControlId.structural("followerIntro"), nodes.text({ label = frameTexts(frame.Follower) }))
            renderDungeonList(builder, frame.Follower.ScrollBox, "follower")
        elseif frame.Specific ~= nil and frame.Specific:IsShown() then
            renderDungeonList(builder, frame.Specific.ScrollBox, "specific")
        else
            local rewards = _G["LFDQueueFrameRandomScrollFrameChildFrame"]
            if rewards ~= nil and rewards:IsVisible() then
                builder:beginStop("rewards")
                builder:addItem(ControlId.structural("rewards"), nodes.text({ label = frameTexts(rewards) }))
            end
        end
    end
    local findGroup = _G["LFDQueueFrameFindGroupButton"]
    if findGroup ~= nil and findGroup:IsShown() then
        builder:beginStop("findGroup")
        local vtable = nodes.proxyButton({ target = findGroup })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(findGroup), vtable)
        end
    end
end

local function notSupported(builder, key)
    builder:beginStop(key)
    builder:addItem(ControlId.structural(key), nodes.text({ label = L["This tab is not supported yet"] }))
end

local function render(builder, screen)
    if PVEFrame == nil or not PVEFrame:IsShown() then
        return
    end
    builder:pushContext("groupFinder", L["Looking for Group"])
    renderTabs(builder)
    if GroupFinderFrame ~= nil and GroupFinderFrame:IsShown() then
        renderGroupButtons(builder)
        if LFDParentFrame ~= nil and LFDParentFrame:IsShown() and LFDQueueFrame ~= nil then
            renderDungeonFinder(builder)
        else
            notSupported(builder, "groupFrame")
        end
    else
        notSupported(builder, "tab")
    end
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "groupFinder",
    frameName = "PVEFrame",
    graphScreen = { render = render },
})
