local module = WowVision.base.windows:createModule("merchant")
local L = module.L
module:setLabel(L["Merchant"])
local gen = module:hasUI()

gen:Element("merchant", function(props)
    return {
        "Panel",
        label = L["Merchant"],
        wrap = true,
        children = {
            { "merchant/Tabs", frame = MerchantFrame },
            { "merchant/Items", frame = MerchantFrame },
            { "ProxyButton", frame = MerchantPrevPageButton, label = L["Previous Page"] },
            { "ProxyButton", frame = MerchantNextPageButton, label = L["Next Page"] },
            { "merchant/Repair", frame = MerchantFrame },
        },
    }
end)

gen:Element("merchant/Tabs", function(props)
    return {
        "List",
        label = L["Tabs"],
        direction = "horizontal",
        children = {
            {
                "ProxyButton",
                frame = MerchantFrameTab1,
                selected = MerchantFrame.selectedTab == 1,
            },
            { "ProxyButton", frame = MerchantFrameTab2, selected = MerchantFrame.selectedTab == 2 },
        },
    }
end)

gen:Element("merchant/Items", function(props)
    local result = { "List", label = L["Items"], children = {} }
    local itemCount = MERCHANT_ITEMS_PER_PAGE
    if props.frame.selectedTab == 2 then
        itemCount = 12
    end
    for i = 1, itemCount do
        local item = _G["MerchantItem" .. i]
        if not item or not item.ItemButton or not item.ItemButton:IsShown() then
            break
        end
        tinsert(result.children, { "merchant/Item", frame = item })
    end
    return result
end)

gen:Element("merchant/Item", function(props)
    return { "ItemButton", frame = props.frame.ItemButton, itemType = "Merchant" }
end)

gen:Element("merchant/Repair", function(props)
    if not CanMerchantRepair() then
        return nil
    end
    return {
        "List",
        direction = "horizontal",
        label = L["Repair"],
        children = {
            { "ProxyButton", frame = MerchantRepairAllButton, label = L["Repair All"] },
            { "ProxyButton", frame = MerchantRepairItemButton, label = L["Repair Item"] },
            { "ProxyButton", frame = MerchantGuildBankRepairButton, label = L["Guild Bank Repair"] },
        },
    }
end)

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "merchant",
    auto = true,
    generated = true,
    rootElement = "merchant",
    frameName = "MerchantFrame",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.Merchant,
})
