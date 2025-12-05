local module = WowVision.base.windows.popups:createModule("rolePoll")
local L = module.L
module:setLabel(L["Role Poll"])
local gen = module:hasUI()

local function getPopupTitle(frame)
    local regions = { frame:GetRegions() }
    for _, v in ipairs(regions) do
        if v:GetObjectType() == "FontString" then
            return v:GetText()
        end
    end
    return "Unknown"
end

gen:Element("RolePoll", function(props)
    local frame = props.frame
    local frameName = frame:GetName()
    local result = {
        "Panel",
        label = getPopupTitle(props.frame),
        wrap = true,
        children = {
            {
                "List",
                children = {
                    { "rolePoll/RoleButton", frame = frame, roleName = "Tank", label = L["Tank"] },
                    { "rolePoll/RoleButton", frame = frame, roleName = "Healer", label = L["Healer"] },
                    { "rolePoll/RoleButton", frame = frame, roleName = "DPS", label = L["Damage Dealer"] },
                },
            },
        },
    }
    local acceptButton = _G[frameName .. "AcceptButton"]
    if acceptButton then
        tinsert(result.children, { "ProxyButton", frame = acceptButton })
    end
    local declineButton = _G[frameName .. "DeclineButton"]
    if declineButton then
        tinsert(result.children, { "ProxyButton", frame = declineButton })
    end
    local closeButton = _G[frameName .. "CloseButton"]
    if closeButton then
        tinsert(result.children, { "ProxyButton", frame = closeButton, label = L["Close"] })
    end
    return result
end)

gen:Element("rolePoll/RoleButton", function(props)
    local frame = _G[props.frame:GetName() .. "RoleButton" .. props.roleName]
    if frame then
        frame = frame.checkButton
    end
    if not frame or not frame:IsShown() then
        return nil
    end
    return { "ProxyCheckButton", frame = frame, label = props.label }
end)

module:registerWindow({
    type = "FrameWindow",
    name = "RolePoll",
    generated = true,
    rootElement = "RolePoll",
    frameName = "RolePollPopup",
    conflictingAddons = { "Sku" },
})

module:registerWindow({
    type = "FrameWindow",
    name = "LFDRoleCheckPopup",
    generated = true,
    rootElement = "RolePoll",
    frameName = "LFDRoleCheckPopup",
    conflictingAddons = { "Sku" },
})
