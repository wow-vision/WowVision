local module = WowVision.base.windows.containers
local L = module.L

-- Retail item slot labels. Item buttons are pooled and carry their own bag
-- id (the combined frame mixes bags; bank buttons carry a bank tab), so
-- the bag comes from the button, not its parent. Markers the game draws on
-- the slot read as words: stack count, quest item, new, and whether the
-- slot fails the current bag search. The quality colour follows the name.
function module.getBagItemLabel(itemButton)
    local bagID, slotID = module.slotLocation(itemButton)
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
