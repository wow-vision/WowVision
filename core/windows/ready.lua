local module = WowVision.base.windows.popups:createModule("readycheck")
local L = module.L
module:setLabel(L["Ready Check"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

--Standard ready check popup
local function renderReadyCheck(builder, screen)
    if ReadyCheckFrame == nil or not ReadyCheckFrame:IsShown() then
        return
    end
    builder:pushContext("readyCheck", L["Ready Check"])

    builder:beginStop()
    builder:addItem(
        ControlId.structural("text"),
        nodes.text({
            label = function()
                return ReadyCheckFrameText:GetText()
            end,
        })
    )
    builder:beginStop()
    builder:addItem(ControlId.forObject(ReadyCheckFrameYesButton), nodes.proxyButton({ target = ReadyCheckFrameYesButton }))
    builder:beginStop()
    builder:addItem(ControlId.forObject(ReadyCheckFrameNoButton), nodes.proxyButton({ target = ReadyCheckFrameNoButton }))

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "ReadyCheck",
    frameName = "ReadyCheckFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderReadyCheck },
})

--LFD Dungeon Ready
local function regionTexts(builder, keyPrefix, holder)
    if holder == nil then
        return
    end
    for i, region in ipairs({ holder:GetRegions() }) do
        if region:GetObjectType() == "FontString" and region:IsVisible() then
            local captured = region
            builder:addItem(
                ControlId.structural(keyPrefix .. ":" .. i),
                nodes.text({
                    label = function()
                        return captured:GetText()
                    end,
                })
            )
        end
    end
end

local function renderDungeonReady(builder, screen)
    local frame = LFGDungeonReadyDialog
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext(
        "dungeonReady",
        LFGDungeonReadyDialogLabel ~= nil and LFGDungeonReadyDialogLabel:GetText() or L["Ready Check"]
    )

    builder:beginStop()
    local roleLabel, roleName = LFGDungeonReadyDialogYourRoleDescription, LFGDungeonReadyDialogRoleLabel
    if roleLabel ~= nil and roleLabel:IsVisible() and roleName ~= nil and roleName:IsVisible() then
        builder:addItem(
            ControlId.structural("role"),
            nodes.text({
                label = function()
                    return (roleLabel:GetText() or "") .. " " .. (roleName:GetText() or "")
                end,
            })
        )
    end
    regionTexts(builder, "progress", frame.randomInProgress)
    regionTexts(builder, "instance", frame.instanceInfo)

    if frame.enterButton ~= nil and frame.enterButton:IsShown() then
        builder:beginStop()
        builder:addItem(ControlId.forObject(frame.enterButton), nodes.proxyButton({ target = frame.enterButton }))
    end
    if frame.leaveButton ~= nil and frame.leaveButton:IsShown() then
        builder:beginStop()
        builder:addItem(ControlId.forObject(frame.leaveButton), nodes.proxyButton({ target = frame.leaveButton }))
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "DungeonReady",
    frameName = "LFGDungeonReadyDialog",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderDungeonReady },
})
