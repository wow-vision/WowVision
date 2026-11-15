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

-- The held bags: backpack, bags 1 to 4, and the keyring where the client has one (the bags in combat,
-- core/windows/containersCombat.lua).
function module.heldBagIds()
    local ids = { 0, 1, 2, 3, 4 }
    if KEYRING_CONTAINER ~= nil then
        tinsert(ids, KEYRING_CONTAINER)
    end
    return ids
end

-- The item buttons the open bag frames show now: the named slots of the numbered frames.
function module.shownItemButtons()
    local buttons = {}
    for i = 1, NUM_CONTAINER_FRAMES do
        local frame = _G["ContainerFrame" .. i]
        if frame ~= nil and frame:IsShown() then
            for slot = 1, frame.size or 0 do
                local button = _G[frame:GetName() .. "Item" .. slot]
                if button ~= nil and button:IsShown() then
                    tinsert(buttons, button)
                end
            end
        end
    end
    return buttons
end

-- The bar buttons whose clicks open every bag, as Open All Bags does: the backpack's and each bag slot's.
local BAG_OPEN_BUTTONS = {
    "MainMenuBarBackpackButton",
    "CharacterBag0Slot",
    "CharacterBag1Slot",
    "CharacterBag2Slot",
    "CharacterBag3Slot",
}

function module.bagOpenButtons()
    local buttons = {}
    for bag, name in ipairs(BAG_OPEN_BUTTONS) do
        local button = _G[name]
        if button ~= nil and (C_Container.GetContainerNumSlots(bag - 1) or 0) > 0 then
            tinsert(buttons, button)
        end
    end
    return buttons
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
