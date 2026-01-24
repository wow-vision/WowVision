local module = WowVision.base.windows.containers
local L = module.L

local Bank = WowVision.components.createType("containers", { key = "Bank" })

function Bank:getFrame()
    return BankFrame
end

function Bank:isOpen()
    return BankFrame:IsShown()
end

function Bank:getGenerator()
    local frame = self:getFrame()
    local items = { "List", label = BANK, children = {} }
    local slots = { "List", label = L["Bank Bag Slots"], children = {} }
    local result = { "Panel", layout = true, shouldAnnounce = false, children = { items, slots } }
    for i = 1, frame.size do
        local button = _G["BankFrameItem" .. i]
        if button then
            tinsert(items.children, { "ProxyButton", frame = button, label = module.getBagItemLabel(button) })
        end
    end
    for i = 1, NUM_BANKBAGSLOTS do
        local button = BankSlotsFrame["Bag" .. i]
        if button and button:IsShown() then
            local label = C_Container.GetBagName(i + 4) or L["Empty"]
            label = label .. " " .. button.tooltipText
            tinsert(slots.children, { "ProxyButton", frame = button, label = label })
        else
            break
        end
    end
    local buySlotFrame = BankFramePurchaseInfo
    if buySlotFrame:IsVisible() then
        tinsert(slots.children, { "Text", text = BANKSLOTPURCHASE_LABEL })
        tinsert(
            slots.children,
            { "Text", text = COSTS_LABEL .. " " .. C_CurrencyInfo.GetCoinText(BankFrame.nextSlotCost) }
        )
        tinsert(slots.children, { "ProxyButton", frame = BankFramePurchaseButton })
    end
    return result
end
