local module = WowVision.base.windows:createModule("merchant")
local L = module.L
module:setLabel(L["Merchant"])
local gen = module:hasUI()

gen:Element("merchant", function(props)
    local frame = MerchantFrame
    local selectedTab = frame.selectedTab
    return {
        "Panel",
        label = L["Merchant"],
        wrap = true,
        children = {
            { "merchant/Tabs", frame = MerchantFrame, selectedTab = selectedTab },
            { "merchant/Items", frame = MerchantFrame, buyback = selectedTab == 2 },
            { "ProxyButton", frame = MerchantPrevPageButton, label = L["Previous Page"] },
            { "ProxyButton", frame = MerchantNextPageButton, label = L["Next Page"] },
            { "merchant/Repair", frame = MerchantFrame, buyback = selectedTab == 2 },
        },
    }
end)

gen:Element("merchant/Tabs", function(props)
    local selectedTab = props.selectedTab
    return {
        "List",
        label = L["Tabs"],
        direction = "horizontal",
        children = {
            {
                "ProxyButton",
                frame = MerchantFrameTab1,
                selected = selectedTab == 1,
            },
            { "ProxyButton", frame = MerchantFrameTab2, selected = selectedTab == 2 },
        },
    }
end)

gen:Element("merchant/Items", function(props)
    local result = { "List", label = L["Items"], children = {} }
    local itemCount = MERCHANT_ITEMS_PER_PAGE
    if props.buyback then
        itemCount = GetNumBuybackItems()
    end
    for i = 1, itemCount do
        local item = _G["MerchantItem" .. i]
        if not item or not item.ItemButton or not item.ItemButton:IsShown() then
            break
        end
        tinsert(result.children, { "merchant/Item", frame = item, buyback = props.buyback })
    end
    return result
end)

gen:Element("merchant/Item", function(props)
    return { "ItemButton", frame = props.frame.ItemButton, itemType = "Merchant", buyback = props.buyback }
end)

gen:Element("merchant/Repair", function(props)
    if props.buyback or not CanMerchantRepair() then
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
    generated = true,
    rootElement = "merchant",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.Merchant,
})
