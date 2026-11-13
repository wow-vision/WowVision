local module = WowVision.base.windows.popups:createModule("rolePoll")
local L = module.L
module:setLabel(L["Role Poll"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Role check popups (party role poll and LFD role check) and the group
-- invitation that asks for a role (LFGInvitePopup: Retail and WoW: Forever
-- show it in place of the plain invitation popup when the inviting group
-- offers roles, e.g. a group from the group finder). All three are special
-- popups (StaticPopupSpecial_Show): the game lists them among its shown
-- dialogs, and the popups window skips them (no `which`). Each one:
-- the title (the invitation line on the invite popup), the invite popup's
-- warning line when the game fills it (accepting leaves your queues, and/or
-- the party sync warning while a party sync is active), the three role
-- check buttons as a vertical list, then accept, decline, close. A role the
-- class cannot play has its check button hidden and is left out. The
-- invite popup's Accept stays disabled until a role is checked, and the
-- game declines the invitation itself when its timer runs out.

-- The title's font string: the named one where the frame has it
-- (LFGInvitePopupText, LFDRoleCheckPopup.Text), else the first text region
-- (RolePollPopup's title has no name). Looked up once per frame; the render
-- runs every tick.
local titleStrings = setmetatable({}, { __mode = "k" })

local function findTitleString(frame)
    local named = frame.Text or _G[frame:GetName() .. "Text"]
    if named ~= nil then
        return named
    end
    for i = 1, select("#", frame:GetRegions()) do
        local region = select(i, frame:GetRegions())
        if region:GetObjectType() == "FontString" then
            return region
        end
    end
    return false
end

-- The title without markup: the invite popup's line starts with an atlas
-- icon while a party sync (quest session) is active.
local function getPopupTitle(frame)
    local title = titleStrings[frame]
    if title == nil then
        title = findTitleString(frame)
        titleStrings[frame] = title
    end
    if title == false then
        return L["Role Poll"]
    end
    return nodes.plainText(title:GetText()) or L["Role Poll"]
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
        local warningText = warning ~= nil and warning:IsShown() and warning:GetText() or nil
        if warningText ~= nil and warningText ~= "" then
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

-- Closing WowVision's window leaves the invitation on screen, as the popups
-- window does with the plain invitation popup (Close All Windows and a
-- route start keep popups that wait for an answer). Hiding the frame here
-- would skip the game's StaticPopupSpecial_Hide: no decline, no timeout,
-- and the frame left in the game's list of shown dialogs. The window opens
-- again on the next check while the frame is shown.
local function keepInvitation()
    WowVision.UIHost.windowManager:closeWindow("LFGInvitePopup")
end

-- The three role popups share one render. Only the invitation keeps its
-- frame on a close request; the role checks close as any frame window does.
for _, def in ipairs({
    { window = "RolePoll", frame = "RolePollPopup" },
    { window = "LFDRoleCheckPopup", frame = "LFDRoleCheckPopup" },
    { window = "LFGInvitePopup", frame = "LFGInvitePopup", onRequestClose = keepInvitation },
}) do
    module:registerWindow({
        type = "FrameWindow",
        name = def.window,
        frameName = def.frame,
        conflictingAddons = { "Sku" },
        graphScreen = { render = makeRender(def.frame), onRequestClose = def.onRequestClose },
    })
end
