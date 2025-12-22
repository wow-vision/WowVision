local module = WowVision.base.windows:createModule("ItemText")
local L = module.L
module:setLabel(L["Item Text"])
local gen = module:hasUI()

gen:Element("ItemText", function(props)
    local itemName = ItemTextGetItem()
    if itemName == nil then
        return nil
    end
    local itemText = ItemTextGetText()
    if itemText == nil then
        return nil
    end
    return {
        "Panel",
        label = itemName,
        wrap = true,
        children = {
            { "ItemText/List", frame = props.frame, itemName = itemName },
            { "Text", text = itemText },
            { "ProxyButton", frame = ItemTextPrevPageButton, label = L["Previous Page"] },
            { "ProxyButton", frame = ItemTextNextPageButton, label = L["Next Page"] },
            { "ProxyButton", frame = ItemTextFrameCloseButton, label = L["Close"] },
        },
    }
end)

gen:Element("ItemText/List", function(props)
    local itemName = props.itemName
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "Text", text = itemName },
        },
    }
    local creatorName = ItemTextGetCreator()
    if creatorName ~= nil and creatorName ~= "" then
        tinsert(result.children, { "Text", text = creatorName })
    end
    local page = ItemTextGetPage()
    if page and page > 0 then
        tinsert(result.children, { "Text", text = L["Page"] .. " " .. page })
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "ItemText",
    generated = true,
    rootElement = "ItemText",
    frameName = "ItemTextFrame",
})
