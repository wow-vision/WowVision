local module = WowVision.base.windows.popups:createModule("rolePoll")
local L = module.L
module:setLabel(L["Role Poll"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Role check popups (party role poll and LFD role check): the three role
-- check buttons as a vertical list, then accept, decline, close.

local function getPopupTitle(frame)
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" then
            return region:GetText()
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
