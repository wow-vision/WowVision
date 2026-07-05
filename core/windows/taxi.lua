local module = WowVision.base.windows:createModule("taxi")
local L = module.L
module:setLabel(L["Taxi"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local function getTitle()
    if TaxiMerchant then
        return TaxiMerchant:GetText()
    end
    if TaxiFrame.TitleText then
        return TaxiFrame.TitleText:GetText()
    end
    return L["Taxi"]
end

local function nodeButtons()
    local buttons = {}
    local children = { TaxiFrame:GetChildren() }
    for i = 3, #children do
        local button = children[i]
        if button:IsShown() and button:GetID() then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function render(builder, screen)
    if TaxiFrame == nil or not TaxiFrame:IsShown() then
        return
    end

    -- Prime every node button's hover once per open, as the old screen did
    -- on mount, so node data is populated before reading.
    if not screen._taxiPrimed then
        screen._taxiPrimed = true
        for _, button in ipairs(nodeButtons()) do
            ExecuteFrameScript(button, "OnEnter")
            ExecuteFrameScript(button, "OnLeave")
        end
    end

    builder:pushContext("taxi", getTitle())
    builder:beginStop("destinations")
    for _, button in ipairs(nodeButtons()) do
        local captured = button
        builder:addItem(
            ControlId.forObject(captured),
            nodes.proxyButton({
                target = captured,
                label = function()
                    local id = captured:GetID()
                    return TaxiNodeName(id) .. ", " .. C_CurrencyInfo.GetCoinText(TaxiNodeCost(id))
                end,
            })
        )
    end
    builder:popContext()
end

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "taxi",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.TaxiNode,
    graphScreen = { render = render },
})
