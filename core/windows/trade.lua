local module = WowVision.base.windows:createModule("trade")
local L = module.L
module:setLabel(L["Trade"])
local gen = module:hasUI()

gen:Element("trade", function(props)
    return {
        "Panel",
        label = L["Trade"],
        wrap = true,
        children = {
            { "trade/PlayerItems" },
            { "trade/TargetItems" },
            { "ProxyButton", frame = TradeFrameTradeButton },
            { "ProxyButton", frame = TradeFrameCancelButton },
        },
    }
end)

gen:Element("trade/Item", function(props)
    local itemType = props.itemType
    local button
    if itemType == "TradePlayer" then
        button = _G["TradePlayerItem" .. props.id .. "ItemButton"]
    elseif itemType == "TradeTarget" then
        button = _G["TradeRecipientItem" .. props.id .. "ItemButton"]
    else
        error("Unknown trade item type: " .. (itemType or "unknown"))
    end
    if not button then
        return nil
    end
    return { "ItemButton", frame = button, itemType = itemType, id = props.id }
end)

gen:Element("trade/PlayerItems", function(props)
    local result = { "List", label = TradeFramePlayerNameText:GetText() or "", children = {} }
    for i = 1, 6 do
        tinsert(result.children, { "trade/Item", itemType = "TradePlayer", id = i })
    end
    return result
end)

gen:Element("trade/TargetItems", function(props)
    local result = { "List", label = TradeFrameRecipientNameText:GetText() or "", children = {} }
    for i = 1, 6 do
        tinsert(result.children, { "trade/Item", itemType = "TradeTarget", id = i })
    end
    return result
end)

module:registerWindow({
    name = "trade",
    auto = true,
    generated = true,
    rootElement = "trade",
    frameName = "TradeFrame",
    conflictingAddons = { "Sku" },
})
