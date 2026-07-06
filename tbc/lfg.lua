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
                            local check = helpers.target()
                            if check ~= nil and check.GetChecked ~= nil then
                                return check:GetChecked() and L["Checked"] or L["Unchecked"]
                            end
                            return nil
                        end,
                        kind = kinds.value,
                    },
                },
                bindings = {
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                },
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
            nodes.proxyDropdown({ target = LFGListingFrameGroupRoleButtonsRoleDropdown })
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

local function renderListingTab(builder)
    if LFGListingFrameLockedView:IsShown() then
        renderLockedView(builder)
        return
    end

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

    if LFGListingFramePostButton ~= nil and LFGListingFramePostButton:IsShown() then
        builder:beginStop("post")
        builder:addItem(
            ControlId.forObject(LFGListingFramePostButton),
            nodes.proxyButton({ target = LFGListingFramePostButton })
        )
    end
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
            nodes.proxyDropdown({ target = LFGBrowseFrameCategoryDropdown })
        )
    end
    if LFGBrowseFrameActivityDropdown ~= nil and LFGBrowseFrameActivityDropdown:IsShown() then
        builder:beginStop("activityFilter")
        builder:addItem(
            ControlId.forObject(LFGBrowseFrameActivityDropdown),
            nodes.proxyDropdown({ target = LFGBrowseFrameActivityDropdown })
        )
    end
    if LFGBrowseFrameRefreshButton ~= nil and LFGBrowseFrameRefreshButton:IsShown() then
        builder:beginStop("refresh")
        builder:addItem(
            ControlId.forObject(LFGBrowseFrameRefreshButton),
            nodes.proxyButton({ target = LFGBrowseFrameRefreshButton, label = L["Search"] })
        )
    end

    builder:beginStop("groups")
    nodes.scrollBoxList(builder, {
        scrollBox = LFGBrowseFrameScrollBox,
        key = "groups",
        label = L["Browse Groups"],
        id = function(data, index)
            if data ~= nil and data.resultID ~= nil then
                return ControlId.structural("group:" .. data.resultID)
            end
            return ControlId.structural("group:" .. index)
        end,
        rowLabel = function(data)
            return browseResultLabel(data)
        end,
    })

    for _, button in ipairs({ LFGBrowseFrameSendMessageButton, LFGBrowseFrameGroupInviteButton }) do
        if button ~= nil and button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
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
    builder:endRow()
    builder:popContext()

    local tab = PanelTemplates_GetSelectedTab(LFGParentFrame)
    if tab == 1 then
        renderListingTab(builder)
    elseif tab == 2 then
        renderBrowseTab(builder)
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "lfg",
    frameName = "LFGParentFrame",
    graphScreen = { render = render },
})
