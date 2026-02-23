local L = LibStub("AceLocale-3.0"):GetLocale("WowVision")
local gen = WowVision.ui.generator
local itemsDB = WowVision.gameDB:get("Item")

gen:Element("ItemButton", function(props)
    local button = props.frame
        local itemType = itemsDB:get(props.itemType)
        local label = props.label or ""
        local tags = {}
        if itemType then
            if props.label == nil and itemType.getLabel then
                label = itemType.getLabel(button, props)
            end
            if itemType.getTags then
                tags = itemType.getTags(button, props)
            end
        end
                        tinsert(tags, "ItemButton")
    return { "ProxyButton", label = label, frame = button, tags = tags, draggable = true }
end)
