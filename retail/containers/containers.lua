local module = WowVision.base.windows.containers
local L = module.L

-- Retail item slot labels. Item buttons are pooled and carry their own bag
-- id (the combined frame mixes bags; bank buttons carry a bank tab), so
-- the bag comes from the button, not its parent. Markers the game draws on
-- the slot read as words: stack count, quest item, new, and whether the
-- slot fails the current bag search. The quality colour follows the name.
function module.getBagItemLabel(itemButton)
    return module.slotLabel(module.slotLocation(itemButton))
end

-- The same label by bag and slot, without the button (the bags in combat, containersCombat.lua).
function module.slotLabel(bagID, slotID)
    local info = C_Container.GetContainerItemInfo(bagID, slotID)
    if info == nil then
        return L["Empty"]
    end
    local parts = { info.itemName ~= nil and WowVision.items.formatName(info.itemName, info.quality) or L["Loading"] }
    local count = info.stackCount
    if count ~= nil and not WowVision.isSecret(count) and count > 1 then
        tinsert(parts, tostring(count))
    end
    local questInfo = C_Container.GetContainerItemQuestInfo ~= nil
            and C_Container.GetContainerItemQuestInfo(bagID, slotID)
        or nil
    if questInfo ~= nil and (questInfo.isQuestItem or (questInfo.questID ~= nil and questInfo.questID ~= 0)) then
        tinsert(parts, L["Quest Item"])
    end
    if C_NewItems ~= nil and C_NewItems.IsNewItem ~= nil and C_NewItems.IsNewItem(bagID, slotID) then
        tinsert(parts, L["New"])
    end
    if info.isLocked then
        tinsert(parts, L["Locked"])
    end
    if info.isFiltered then
        tinsert(parts, L["Filtered"])
    end
    return table.concat(parts, ", ")
end

-- The held bags and the bar buttons that stand for them (the bags window, Bags.lua, and the bags in combat,
-- core/windows/containersCombat.lua).
module.KEYRING_ID = KEYRING_CONTAINER or (Enum.BagIndex ~= nil and Enum.BagIndex.Keyring) or nil

module.BAG_SLOT_BUTTONS = {
    [0] = "MainMenuBarBackpackButton",
    [1] = "CharacterBag0Slot",
    [2] = "CharacterBag1Slot",
    [3] = "CharacterBag2Slot",
    [4] = "CharacterBag3Slot",
    [5] = "CharacterReagentBag0Slot",
}

-- Every held bag, in bar order: backpack, bags, reagent bag, keyring.
module.HELD_BAG_IDS = { 0, 1, 2, 3, 4, 5 }
if module.KEYRING_ID ~= nil then
    tinsert(module.HELD_BAG_IDS, module.KEYRING_ID)
end

function module.heldBagIds()
    return module.HELD_BAG_IDS
end

-- The item buttons the open bag frames show now (pooled: each frame's Items).
function module.shownItemButtons()
    local buttons = {}
    if ContainerFrameUtil_EnumerateContainerFrames == nil then
        return buttons
    end
    for _, frame in ContainerFrameUtil_EnumerateContainerFrames() do
        if frame ~= nil and frame:IsShown() then
            for _, button in ipairs(frame.Items or {}) do
                if button:IsShown() then
                    tinsert(buttons, button)
                end
            end
        end
    end
    return buttons
end

-- The bar buttons whose clicks open every bag, as Open All Bags does: the backpack button alone with combined bags
-- (it opens the one window), else each held bag's own button.
function module.bagOpenButtons()
    local manager = ContainerFrameSettingsManager
    local combined = manager ~= nil and manager:IsUsingCombinedBags()
    local buttons = {}
    for bag = 0, 5 do
        local button = _G[module.BAG_SLOT_BUTTONS[bag]]
        if button ~= nil and (C_Container.GetContainerNumSlots(bag) or 0) > 0 then
            tinsert(buttons, button)
        end
        if combined then
            break
        end
    end
    return buttons
end

-- An amount of money as words ("12 Gold 5 Silver"), nil for a secret or
-- missing amount. Shared by the bags and the bank.
function module.coinText(amount)
    if amount == nil or WowVision.isSecret(amount) then
        return nil
    end
    return C_CurrencyInfo.GetCoinText(amount, " ")
end

-- The money line of the bag and bank controls: "Money, <amount>", or just
-- "Money" while the amount cannot be read.
function module.moneyLabel(amount)
    local text = module.coinText(amount)
    if text == nil then
        return L["Money"]
    end
    return L["Money"] .. ", " .. text
end
