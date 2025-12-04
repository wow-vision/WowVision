local L = LibStub("AceLocale-3.0"):GetLocale("WowVision")
local gen = WowVision.ui.generator
local itemsDB = WowVision.gameDB:get("Item")

local function getButtonLabel(props)
    local button = props.frame
    local itemType = itemsDB:get(props.itemType)
    if itemType and itemType.getLabel then
        return itemType.getLabel(button, props)
    end
end

gen:Element("ItemButton", function(props)
    return { "ProxyButton", label = getButtonLabel(props), frame = props.frame }
end)
