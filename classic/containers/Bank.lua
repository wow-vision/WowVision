local module = WowVision.base.windows.containers
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local Bank = WowVision.components.createType("containers", { key = "Bank" })

function Bank:getFrame()
    return BankFrame
end

function Bank:isOpen()
    return BankFrame:IsShown()
end

-- The main bank: its item slots as one stop, then the bank bag slots (and
-- the next-slot purchase when available) as another.
function Bank:renderGraph(builder)
    local frame = self:getFrame()

    builder:beginStop("bank")
    builder:pushContext("bank", BANK)
    for i = 1, frame.size do
        local button = _G["BankFrameItem" .. i]
        if button ~= nil then
            builder:addItem(
                ControlId.forObject(button),
                module.itemSlotNode(button, function()
                    return module.getBagItemLabel(button)
                end)
            )
        end
    end
    builder:popContext()

    builder:beginStop("bankSlots")
    builder:pushContext("bankSlots", L["Bank Bag Slots"])
    for i = 1, NUM_BANKBAGSLOTS do
        local button = BankSlotsFrame["Bag" .. i]
        if button ~= nil and button:IsShown() then
            local slotIndex = i
            -- Structural id: these frames also back the opened bank bags'
            -- own slot buttons.
            builder:addItem(
                ControlId.structural("bankSlot:" .. i),
                module.itemSlotNode(button, function()
                    local label = C_Container.GetBagName(slotIndex + 4) or L["Empty"]
                    return label .. " " .. (button.tooltipText or "")
                end)
            )
        else
            break
        end
    end

    if BankFramePurchaseInfo ~= nil and BankFramePurchaseInfo:IsVisible() then
        builder:addItem(ControlId.structural("purchaseLabel"), nodes.text({ label = BANKSLOTPURCHASE_LABEL }))
        builder:addItem(
            ControlId.structural("purchaseCost"),
            nodes.text({
                label = function()
                    return COSTS_LABEL .. " " .. C_CurrencyInfo.GetCoinText(BankFrame.nextSlotCost or 0)
                end,
            })
        )
        builder:addItem(
            ControlId.forObject(BankFramePurchaseButton),
            nodes.proxyButton({ target = BankFramePurchaseButton })
        )
    end
    builder:popContext()
end
