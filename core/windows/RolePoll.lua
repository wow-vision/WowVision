local module = WowVision.base.windows.popups:createModule("rolePoll")
local L = module.L
module:setLabel(L["Role Poll"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Role check popups (party role poll and LFD role check) and the group
-- invitation that asks for a role (LFGInvitePopup: Retail and WoW: Forever
-- show it in place of the plain invitation popup when the inviting group
-- offers roles, e.g. a group from the group finder; it is shown with
-- StaticPopupSpecial_Show, so the popups window never sees it). Each one:
-- the title (the invitation line on the invite popup), the warning that
-- accepting leaves your queues when the game shows it, the three role
-- check buttons as a vertical list, then accept, decline, close. A role the
-- class cannot play has its check button hidden and is left out. The
-- invite popup's Accept stays disabled until a role is checked, and the
-- game declines the invitation itself when its timer runs out.

-- The first text region, without markup: the invite popup's line starts
-- with an atlas icon while a party sync (quest session) is active.
local function getPopupTitle(frame)
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" then
            return nodes.plainText(region:GetText()) or L["Role Poll"]
        end
    end
    return L["Role Poll"]
end

local ROLES = {
    { key = "Tank", labelKey = "Tank" },
    { key = "Healer", labelKey = "Healer" },
    { key = "DPS", labelKey = "Damage Dealer" },
}

local function makeRender(frameName)
    return function(builder, screen)
        local frame = _G[frameName]
        if frame == nil or not frame:IsShown() then
            return
        end
        builder:pushContext("rolePoll", getPopupTitle(frame))

        local warning = frame.QueueWarningText
        if warning ~= nil and warning:IsShown() and nodes.plainText(warning:GetText()) ~= nil then
            builder:beginStop("warning")
            builder:addItem(
                ControlId.structural("rolePoll:warning"),
                nodes.text({ label = nodes.fontText(warning) })
            )
        end

        builder:beginStop("roles")
        builder:pushContext("roles", L["Roles"])
        for _, role in ipairs(ROLES) do
            local roleButton = _G[frameName .. "RoleButton" .. role.key]
            local checkButton = roleButton ~= nil and roleButton.checkButton or nil
            if checkButton ~= nil and checkButton:IsShown() then
                builder:addItem(
                    ControlId.forObject(checkButton),
                    nodes.proxyCheckButton({ target = checkButton, label = L[role.labelKey] })
                )
            end
        end
        builder:popContext()

        for _, suffix in ipairs({ "AcceptButton", "DeclineButton", "CloseButton" }) do
            local button = _G[frameName .. suffix]
            if button ~= nil and button:IsShown() then
                builder:beginStop()
                local label = nil
                if suffix == "CloseButton" then
                    label = L["Close"]
                end
                builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button, label = label }))
            end
        end

        builder:popContext()
    end
end

module:registerWindow({
    type = "FrameWindow",
    name = "RolePoll",
    frameName = "RolePollPopup",
    conflictingAddons = { "Sku" },
    graphScreen = { render = makeRender("RolePollPopup") },
})

module:registerWindow({
    type = "FrameWindow",
    name = "LFDRoleCheckPopup",
    frameName = "LFDRoleCheckPopup",
    conflictingAddons = { "Sku" },
    graphScreen = { render = makeRender("LFDRoleCheckPopup") },
})

-- Closing WowVision's window leaves the invitation on screen, as the popups
-- window does with the plain invitation popup (Close All Windows and a
-- route start keep popups that wait for an answer). Hiding the frame here
-- would skip the game's StaticPopupSpecial_Hide: no decline, no timeout,
-- and the frame left in the game's list of shown dialogs. The window opens
-- again on the next check while the frame is shown.
local function keepInvitation()
    WowVision.UIHost.windowManager:closeWindow("LFGInvitePopup")
end

module:registerWindow({
    type = "FrameWindow",
    name = "LFGInvitePopup",
    frameName = "LFGInvitePopup",
    conflictingAddons = { "Sku" },
    graphScreen = { render = makeRender("LFGInvitePopup"), onRequestClose = keepInvitation },
})
