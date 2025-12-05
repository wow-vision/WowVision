local module = WowVision.base.windows:createModule("taxi")
local L = module.L
module:setLabel(L["Taxi"])
local gen = module:hasUI()

local function Taxi_Mount(frame, props)
    local buttons = { TaxiFrame:GetChildren() }
    for i = 3, #buttons do
        local button = buttons[i]
        ExecuteFrameScript(button, "OnEnter")
        ExecuteFrameScript(button, "OnLeave")
    end
end

local function getTitle()
    if TaxiMerchant then
        return TaxiMerchant:GetText()
    end
    if TaxiFrame.TitleText then
        return TaxiFrame.TitleText:GetText()
    end
    return L["Taxi"]
end

gen:Element("taxi", function(props)
    local result = { "List", label = getTitle(), children = {}, hooks = {
        mount = Taxi_Mount,
    } }
    local buttons = { TaxiFrame:GetChildren() }
    for i = 3, #buttons do
        local button = buttons[i]
        if button:IsShown() and button:GetID() then
            tinsert(result.children, {
                "ProxyButton",
                frame = button,
                label = TaxiNodeName(button:GetID()) .. ", " .. C_CurrencyInfo.GetCoinText(
                    TaxiNodeCost(button:GetID())
                ),
            })
        end
    end
    return result
end)

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "taxi",
    generated = true,
    rootElement = "taxi",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.TaxiNode,
})
