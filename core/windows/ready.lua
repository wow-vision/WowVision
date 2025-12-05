local module = WowVision.base.windows.popups:createModule("readycheck")
local L = module.L
module:setLabel(L["Ready Check"])
local gen = module:hasUI()

--Standard ready check popup
gen:Element("ReadyCheck", function(props)
    return {
        "Panel",
        label = L["Ready Check"],
        wrap = true,
        children = {
            { "Text", text = ReadyCheckFrameText:GetText() or "" },
            { "ProxyButton", frame = ReadyCheckFrameYesButton },
            { "ProxyButton", frame = ReadyCheckFrameNoButton },
        },
    }
end)

module:registerWindow({
    type = "FrameWindow",
    name = "ReadyCheck",
    generated = true,
    rootElement = "ReadyCheck",
    frameName = "ReadyCheckFrame",
    conflictingAddons = { "Sku" },
})

--LFD Dungeon Ready
gen:Element("DungeonReady", function(props)
    local info = { "List", children = {} }
    local frame = props.frame
    local result = {
        "Panel",
        label = LFGDungeonReadyDialogLabel:GetText(),
        wrap = true,
        children = {
            info,
            { "ProxyButton", frame = props.frame.enterButton },
            { "ProxyButton", frame = props.frame.leaveButton },
        },
    }

    --LFGDungeonReadyDialog
    local roleLabel, roleName = LFGDungeonReadyDialogYourRoleDescription, LFGDungeonReadyDialogRoleLabel
    if roleLabel:IsVisible() and roleName:IsVisible() then
        tinsert(info.children, { "Text", text = roleLabel:GetText() .. " " .. roleName:GetText() })
    end
    for _, v in ipairs({ props.frame.randomInProgress:GetRegions() }) do
        if v:GetObjectType() == "FontString" and v:IsVisible() then
            tinsert(info.children, { "Text", text = v:GetText() })
        end
    end
    for _, v in ipairs({ props.frame.instanceInfo:GetRegions() }) do
        if v:GetObjectType() == "FontString" and v:IsVisible() then
            tinsert(info.children, { "Text", text = v:GetText() })
        end
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "DungeonReady",
    generated = true,
    rootElement = "DungeonReady",
    frameName = "LFGDungeonReadyDialog",
    conflictingAddons = { "Sku" },
})
