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
    local label = info.itemName
    if frame.Count:IsShown() then
        label = label .. " " .. frame.Count:GetText()
    end
    return label
end
