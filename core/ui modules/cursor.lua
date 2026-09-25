local module = WowVision.base.ui:createModule("cursor")
local L = module.L
module:setLabel(L["Cursor"])

local ITEM_QUALITY_RARE = LE_ITEM_QUALITY_RARE or (Enum.ItemQuality and Enum.ItemQuality.Rare) or 3
local ITEM_QUALITY_HEIRLOOM = LE_ITEM_QUALITY_HEIRLOOM or (Enum.ItemQuality and Enum.ItemQuality.Heirloom) or 7

-- Whether the cursor's current "item" content is an action bar reference
-- (nothing real to destroy) rather than a real item picked up from a bag,
-- trade, or merchant slot. Bar drag handlers set this true right before
-- picking up; every other item-pickup path sets it false right before its
-- own pickup, so it always reflects the most recent pickup's source.
WowVision.cursor = WowVision.cursor or {}
WowVision.cursor.pickupIsActionBar = false

module:registerBinding({
    type = "Function",
    key = "destroyCursorItem",
    label = L["Destroy Cursor Item"],
    inputs = { "ALT-CTRL-\\", "DELETE" },
    interruptSpeech = true,
    func = function()
        local cursorType, id, _ = GetCursorInfo()
        if cursorType == nil then
            return
        end
        -- Non-item cursor content (a spell, macro, mount, equipment set, or
        -- flyout picked up off an action bar) has nothing to destroy -- it
        -- is only a bar assignment. Clearing the cursor here is what
        -- finishes the removal Drag started: the slot was already emptied
        -- at pickup, and this drops the reference instead of placing it
        -- back somewhere.
        if cursorType ~= "item" then
            ClearCursor()
            return
        end
        -- An item-type action bar slot (e.g. a quest item or potion) holds
        -- only a reference, not the bag item itself -- clear it the same
        -- way as a spell, instead of offering to destroy the real item.
        if WowVision.cursor.pickupIsActionBar then
            ClearCursor()
            return
        end
        local itemName, _, itemQuality = C_Item.GetItemInfo(id)
        if not itemName then
            return
        end
        if itemQuality and itemQuality >= ITEM_QUALITY_RARE and itemQuality ~= ITEM_QUALITY_HEIRLOOM then
            StaticPopup_Show("DELETE_GOOD_ITEM", itemName)
        else
            StaticPopup_Show("DELETE_ITEM", itemName)
        end
    end,
})
