-- The items the game flags as new in the bags: what you looted or bought since you last looked.
--
-- The game shows a glow on a new item and clears it the moment the item is hovered, and WowVision hovers every
-- slot it focuses, so an item would leave the "New Items" list as soon as the cursor reached it. The list
-- therefore remembers each slot it has seen flagged, together with the item that was in it, until the bags
-- close (reset); a slot that now holds another item, or none, drops out.
local newItems = {}
WowVision.newItems = newItems

-- slot key ("bag:slot") -> the item ID that was flagged there
local seen = {}

local function slotKey(bagID, slotID)
    return bagID .. ":" .. slotID
end

-- The ID of the item in a slot, or nil for an empty slot (or a client that cannot tell).
local function itemIdAt(bagID, slotID)
    local container = rawget(_G, "C_Container")
    if container == nil then
        return nil
    end
    if container.GetContainerItemID ~= nil then
        local ok, id = pcall(container.GetContainerItemID, bagID, slotID)
        if ok and type(id) == "number" then
            return id
        end
    end
    if container.GetContainerItemInfo ~= nil then
        local ok, info = pcall(container.GetContainerItemInfo, bagID, slotID)
        if ok and type(info) == "table" and type(info.itemID) == "number" then
            return info.itemID
        end
    end
    return nil
end

-- Whether the game flags this slot as holding a new item: its own list of new items, or the glow on the button.
function newItems.isFlagged(itemButton, bagID, slotID)
    local api = rawget(_G, "C_NewItems")
    if api ~= nil and api.IsNewItem ~= nil then
        local ok, isNew = pcall(api.IsNewItem, bagID, slotID)
        if ok and isNew == true then
            return true
        end
    end
    local glow = itemButton.NewItemTexture
    if glow ~= nil and glow.IsShown ~= nil then
        local ok, shown = pcall(glow.IsShown, glow)
        if ok and shown == true then
            return true
        end
    end
    return false
end

local function bagIdOf(itemButton)
    return itemButton.GetBagID ~= nil and itemButton:GetBagID() or 0
end

-- The slots to list, in the order given (bag by bag, slots ascending): the ones flagged now and the ones seen
-- flagged earlier that still hold the same item.
function newItems.list(buttons)
    local list = {}
    for _, itemButton in ipairs(buttons) do
        local bagID, slotID = bagIdOf(itemButton), itemButton:GetID()
        local key = slotKey(bagID, slotID)
        local itemID = itemIdAt(bagID, slotID)
        if itemID == nil then
            seen[key] = nil
        else
            if newItems.isFlagged(itemButton, bagID, slotID) then
                seen[key] = itemID
            end
            if seen[key] == itemID then
                tinsert(list, itemButton)
            else
                seen[key] = nil
            end
        end
    end
    return list
end

-- The bags closed: what was new has been looked at.
function newItems.reset()
    if next(seen) ~= nil then
        seen = {}
    end
end

-- A list of the bags' Item Lists stop (bagLists.lua), open when the bags open.
local L = WowVision:getLocale()
WowVision.bagLists.register({
    key = "new",
    label = L["New Items"],
    order = 10,
    expanded = true,
    select = newItems.list,
    reset = newItems.reset,
})
