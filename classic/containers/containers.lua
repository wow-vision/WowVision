local module = WowVision.base.windows.containers
local L = module.L

-- Shared utility for getting bag item labels
function module.getBagItemLabel(frame)
    local bagID = frame:GetParent():GetID()
    local slotID = frame:GetID()
    local info = C_Container.GetContainerItemInfo(bagID, slotID)
    if not info then
        return L["Empty"]
    end
    local label = WowVision.items.formatName(info.itemName, info.quality)
    if frame.Count:IsShown() then
        label = label .. " " .. frame.Count:GetText()
    end
    return label
end

-- The same label by bag and slot, without the button (the bags in combat, containersCombat.lua): the count the
-- button would show is the stack count above one.
function module.slotLabel(bagID, slotID)
    local info = C_Container.GetContainerItemInfo(bagID, slotID)
    if not info then
        return L["Empty"]
    end
    local label = WowVision.items.formatName(info.itemName, info.quality)
    if info.stackCount ~= nil and info.stackCount > 1 then
        label = label .. " " .. info.stackCount
    end
    return label
end
