local module = WowVision.base.windows.containers
local L = module.L

function getBagItemLabel(frame)
    local bagID = frame:GetParent():GetID()
    local slotID = frame:GetID()
    local info = C_Container.GetContainerItemInfo(bagID, slotID)
    if not info then
        return L["Empty"]
    end
    local label = info.itemName
    if frame.Count:IsShown() then
        label = label .. " " .. frame.Count:GetText()
    end
    return label
end

local Bag = module:createContainerType("Bag")
Bag.info:addFields({
    { key = "id", required = true, once = true },
    { key = "button" },
    { key = "prefix" },
})

function Bag:getFrame()
    for i = 1, 14 do
        local frame = _G["ContainerFrame" .. i]
        if frame and frame:GetID() == self.id then
            return frame
        end
    end
    return nil
end

function Bag:isOpen()
    local frame = self:getFrame()
    if not frame then
        return false
    end
    return frame:IsShown()
end

function Bag:getGenerator()
    local frame = self:getFrame()
    local button = self.button
    if not frame:IsShown() then
        return nil
    end
    local id = self.id
    local bagName = C_Container.GetBagName(id)
    if bagName == nil then
        error("Nil bag name for bag with id " .. (id or "nil") .. " button " .. button:GetName())
    end
    local label
    if self.prefix then
        label = self.prefix .. ": " .. bagName
    else
        label = bagName
    end
    local result = { "List", label = label, children = {} }
    if button then
        tinsert(result.children, { "ProxyButton", frame = button, label = L["Bag Slot"] .. " " .. bagName })
    end
    for i = frame.size, 1, -1 do
        local button = _G[frame:GetName() .. "Item" .. i]
        tinsert(result.children, {
            "ProxyButton",
            frame = button,
            label = getBagItemLabel(button),
        })
    end
    return result
end

local Bank = module:createContainerType("Bank")

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
            tinsert(items.children, { "ProxyButton", frame = button, label = getBagItemLabel(button) })
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

module:addContainer({
    type = "Bag",
    id = 0,
    button = MainMenuBarBackpackButton,
})
module:addContainer({
    type = "Bag",
    id = 1,
    button = CharacterBag0Slot,
})
module:addContainer({
    type = "Bag",
    id = 2,
    button = CharacterBag1Slot,
})
module:addContainer({
    type = "Bag",
    id = 3,
    button = CharacterBag2Slot,
})
module:addContainer({
    type = "Bag",
    id = 4,
    button = CharacterBag3Slot,
})
module:addContainer({
    type = "Bank",
})
module:addContainer({
    type = "Bag",
    id = 5,
    button = BankSlotsFrame.Bag1,
    prefix = BANK,
})
module:addContainer({
    type = "Bag",
    id = 6,
    button = BankSlotsFrame.Bag2,
    prefix = BANK,
})
module:addContainer({
    type = "Bag",
    id = 7,
    button = BankSlotsFrame.Bag3,
    prefix = BANK,
})
module:addContainer({
    type = "Bag",
    id = 8,
    button = BankSlotsFrame.Bag4,
    prefix = BANK,
})
module:addContainer({
    type = "Bag",
    id = 9,
    button = BankSlotsFrame.Bag5,
    prefix = BANK,
})
module:addContainer({
    type = "Bag",
    id = 10,
    button = BankSlotsFrame.Bag6,
    prefix = BANK,
})
module:addContainer({
    type = "Bag",
    id = 11,
    button = BankSlotsFrame.Bag7,
    prefix = BANK,
})
