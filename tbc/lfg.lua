local module = WowVision.base.windows:createModule("lfg")
local L = module.L
module:setLabel(L["Looking for Group"])
local gen = module:hasUI()

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

gen:Element("lfg", function(props)
    local result = { "Panel", label = L["Looking for Group"], wrap = true, children = {} }
    tinsert(result.children, { "lfg/Tabs" })
    local tab = PanelTemplates_GetSelectedTab(LFGParentFrame)
    if tab == 1 then
        if LFGListingFrameLockedView:IsShown() then
            tinsert(result.children, { "lfg/LockedView" })
        else
            if LFGListingFrameActivityView:IsShown() then
                tinsert(result.children, { "lfg/ActivityList" })
                tinsert(result.children, { "ProxyButton", frame = LFGListingFrameBackButton })
            else
                tinsert(result.children, { "lfg/CategoryList" })
            end
            tinsert(result.children, { "lfg/Roles" })
            tinsert(result.children, { "lfg/Comment" })
            tinsert(result.children, { "ProxyButton", frame = LFGListingFramePostButton })
        end
    elseif tab == 2 then
        tinsert(result.children, { "ProxyDropdownButton", frame = LFGBrowseFrameCategoryDropdown })
        tinsert(result.children, { "ProxyDropdownButton", frame = LFGBrowseFrameActivityDropdown })
        tinsert(result.children, { "ProxyButton", frame = LFGBrowseFrameRefreshButton, label = L["Search"] })
        tinsert(result.children, { "lfg/BrowseResults" })
        tinsert(result.children, { "ProxyButton", frame = LFGBrowseFrameSendMessageButton })
        tinsert(result.children, { "ProxyButton", frame = LFGBrowseFrameGroupInviteButton })
    end
    return result
end)

gen:Element("lfg/Tabs", function(props)
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    for i = 1, 2 do
        local tab = _G["LFGParentFrameTab" .. i]
        if tab and tab:IsShown() then
            tinsert(result.children, {
                "ProxyButton",
                key = "tab_" .. i,
                frame = tab,
                selected = PanelTemplates_GetSelectedTab(LFGParentFrame) == i,
            })
        end
    end
    return result
end)

gen:Element("lfg/LockedView", function(props)
    local text = ""
    local regions = { LFGListingFrameLockedView:GetRegions() }
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" and region:IsShown() then
            local str = region:GetText()
            if str and str ~= "" then
                if text ~= "" then
                    text = text .. " "
                end
                text = text .. str
            end
        end
    end
    return { "Text", text = text }
end)

gen:Element("lfg/Roles", function(props)
    local result = { "List", label = L["Roles"], children = {} }

    if LFGListingFrameSoloRoleButtons:IsShown() then
        local roles = {
            { frame = LFGListingFrameSoloRoleButtonsRoleButtonTank, label = L["Tank"] },
            { frame = LFGListingFrameSoloRoleButtonsRoleButtonHealer, label = L["Healer"] },
            { frame = LFGListingFrameSoloRoleButtonsRoleButtonDPS, label = L["Damage Dealer"] },
        }
        for _, role in ipairs(roles) do
            local check = findCheckButton(role.frame)
            if check then
                tinsert(result.children, { "ProxyCheckButton", frame = check, label = role.label })
            end
        end
    elseif LFGListingFrameGroupRoleButtons:IsShown() then
        tinsert(result.children, {
            "ProxyDropdownButton",
            frame = LFGListingFrameGroupRoleButtonsRoleDropdown,
        })
        tinsert(result.children, {
            "ProxyButton",
            frame = LFGListingFrameGroupRoleButtonsInitiateRolePoll,
        })
    end

    local newPlayerFriendly = findCheckButton(LFGListingFrameNewPlayerFriendlyButton)
    if newPlayerFriendly then
        tinsert(result.children, { "ProxyCheckButton", frame = newPlayerFriendly, label = L["New Player Friendly"] })
    end

    return result
end)


gen:Element("lfg/CategoryList", function(props)
    local result = { "List", label = L["Categories"], children = {} }
    local children = { LFGListingFrameCategoryView:GetChildren() }
    for _, child in ipairs(children) do
        if child:IsShown() and child:GetObjectType() == "Button" then
            tinsert(result.children, { "ProxyButton", frame = child })
        end
    end
    return result
end)

local function getActivityLabel(button)
    local node = button.GetElementData and button:GetElementData()
    if node and node.GetData then
        local data = node:GetData()
        if data and data.name then
            return data.name
        end
    end
    return ""
end

local function ActivityList_getElement(self, button)
    local check = findCheckButton(button)
    if check then
        return { "ProxyCheckButton", frame = check, label = getActivityLabel(button) }
    end
    return nil
end

gen:Element("lfg/ActivityList", function(props)
    return {
        "ProxyScrollBox",
        frame = LFGListingFrameActivityViewScrollBox,
        label = L["Activities"],
        getElement = ActivityList_getElement,
        ordered = false,
    }
end)

gen:Element("lfg/Comment", function(props)
    local editBox = findEditBox(LFGListingComment)
    if editBox then
        return { "ProxyEditBox", frame = editBox, label = L["Comment"] }
    end
    return nil
end)


local function getBrowseResultLabel(button)
    local elemData = button.GetElementData and button:GetElementData()
    if elemData and elemData.resultID then
        local ok, info = pcall(C_LFGList.GetSearchResultInfo, elemData.resultID)
        if ok and info then
            local parts = {}
            if info.leaderName and info.leaderName ~= "" then
                tinsert(parts, info.leaderName)
            end
            local actInfo
            if info.activityIDs and info.activityIDs[1] then
                local aOk, aResult = pcall(C_LFGList.GetActivityInfoTable, info.activityIDs[1])
                if aOk then actInfo = aResult end
            end
            if actInfo and actInfo.shortName then
                tinsert(parts, actInfo.shortName)
            end
            if info.numMembers then
                local maxPlayers = actInfo and actInfo.maxNumPlayers and ("/" .. actInfo.maxNumPlayers) or ""
                tinsert(parts, info.numMembers .. maxPlayers .. " " .. L["Members"])
            end
            if info.comment and info.comment ~= "" then
                tinsert(parts, info.comment)
            end
            if #parts > 0 then
                return table.concat(parts, " - ")
            end
        end
    end
    local parts = {}
    local regions = { button:GetRegions() }
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" and region:IsShown() then
            local text = region:GetText()
            if text and text ~= "" then
                tinsert(parts, text)
            end
        end
    end
    return table.concat(parts, " - ")
end

local function BrowseResults_getElement(self, button)
    return { "ProxyButton", frame = button, label = getBrowseResultLabel(button) }
end

gen:Element("lfg/BrowseResults", function(props)
    return {
        "ProxyScrollBox",
        frame = LFGBrowseFrameScrollBox,
        label = L["Browse Groups"],
        getElement = BrowseResults_getElement,
        ordered = false,
    }
end)

module:registerWindow({
    type = "FrameWindow",
    name = "lfg",
    generated = true,
    rootElement = "lfg",
    frameName = "LFGParentFrame",
})
