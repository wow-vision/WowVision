local module = WowVision.base.ui:createModule("cursor")
local L = module.L
module:setLabel(L["Cursor"])

module:registerBinding({
    type = "Function",
    key = "destroyCursorItem",
    label = L["Destroy Cursor Item"],
    inputs = { "ALT-CTRL-\\", "DELETE" },
    interruptSpeech = true,
    func = function()
        local cursorType, id, _ = GetCursorInfo()
        if cursorType ~= "item" then
            return
        end
        local itemName, _, itemQuality = C_Item.GetItemInfo(id)
        if not itemName then
            return
        end
        if itemQuality >= LE_ITEM_QUALITY_RARE and itemQuality ~= LE_ITEM_QUALITY_HEIRLOOM then
            StaticPopup_Show("DELETE_GOOD_ITEM", itemName)
        else
            StaticPopup_Show("DELETE_ITEM", itemName)
        end
    end,
})
