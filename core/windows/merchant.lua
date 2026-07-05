local module = WowVision.base.windows:createModule("merchant")
local L = module.L
module:setLabel(L["Merchant"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The merchant window: tabs, the item page, page buttons, and repair. The
-- merchant tab shows MERCHANT_ITEMS_PER_PAGE (10) item slots per page;
-- buyback shows up to 12 (GetNumBuybackItems). Item labels come from the
-- gameDB Merchant item type (name, count, price, stock, alternate costs) and
-- are live: page flips reuse the same buttons under focus.

local function merchantItemLabel(button, buyback)
    local itemType = WowVision.gameDB:get("Item"):get("Merchant")
    if itemType == nil or itemType.getLabel == nil then
        return nil
    end
    return itemType.getLabel(button, { buyback = buyback })
end

local function tabNode(tab, tabIndex)
    local vtable = nodes.proxyButton({ target = tab })
    tinsert(vtable.announcements, {
        text = function()
            if MerchantFrame.selectedTab == tabIndex then
                return L["selected"]
            end
            return nil
        end,
        kind = kinds.selected,
        live = "focus",
    })
    return vtable
end

local function itemNode(itemButton, buyback)
    local vtable = nodes.proxyButton({
        target = itemButton,
        label = function()
            return merchantItemLabel(itemButton, buyback)
        end,
    })
    -- Live: page flips rebind the same button frames under focus.
    vtable.announcements[1].live = "focus"
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local script = itemButton:GetScript("OnDragStart")
            if script ~= nil then
                script(itemButton)
            end
        end,
    })
    return vtable
end

local function render(builder, screen)
    local frame = MerchantFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    local buyback = frame.selectedTab == 2
    builder:pushContext(L["Merchant"])

    builder:beginStop("tabs")
    builder:pushContext(L["Tabs"])
    builder:startRow()
    builder:addItem(ControlId.forObject(MerchantFrameTab1), tabNode(MerchantFrameTab1, 1))
    builder:addItem(ControlId.forObject(MerchantFrameTab2), tabNode(MerchantFrameTab2, 2))
    builder:endRow()
    builder:popContext()

    builder:beginStop("items")
    builder:pushContext(L["Items"])
    local slotCount = MERCHANT_ITEMS_PER_PAGE
    if buyback then
        slotCount = GetNumBuybackItems()
    end
    local emitted = 0
    for i = 1, slotCount do
        local item = _G["MerchantItem" .. i]
        if item == nil or item.ItemButton == nil or not item.ItemButton:IsShown() then
            break
        end
        builder:addItem(ControlId.forObject(item.ItemButton), itemNode(item.ItemButton, buyback))
        emitted = emitted + 1
    end
    if emitted == 0 then
        -- An empty page is still a place to land (a fresh buyback tab).
        builder:addItem(ControlId.structural("itemsEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    if not buyback then
        if MerchantPrevPageButton ~= nil and MerchantPrevPageButton:IsShown() then
            builder:beginStop("prevPage")
            builder:addItem(
                ControlId.forObject(MerchantPrevPageButton),
                nodes.proxyButton({ target = MerchantPrevPageButton, label = L["Previous Page"] })
            )
        end
        if MerchantNextPageButton ~= nil and MerchantNextPageButton:IsShown() then
            builder:beginStop("nextPage")
            builder:addItem(
                ControlId.forObject(MerchantNextPageButton),
                nodes.proxyButton({ target = MerchantNextPageButton, label = L["Next Page"] })
            )
        end

        if CanMerchantRepair() then
            builder:beginStop("repair")
            builder:pushContext(L["Repair"])
            builder:startRow()
            if MerchantRepairAllButton ~= nil and MerchantRepairAllButton:IsShown() then
                builder:addItem(
                    ControlId.forObject(MerchantRepairAllButton),
                    nodes.proxyButton({ target = MerchantRepairAllButton, label = L["Repair All"] })
                )
            end
            if MerchantRepairItemButton ~= nil and MerchantRepairItemButton:IsShown() then
                builder:addItem(
                    ControlId.forObject(MerchantRepairItemButton),
                    nodes.proxyButton({ target = MerchantRepairItemButton, label = L["Repair Item"] })
                )
            end
            if MerchantGuildBankRepairButton ~= nil and MerchantGuildBankRepairButton:IsShown() then
                builder:addItem(
                    ControlId.forObject(MerchantGuildBankRepairButton),
                    nodes.proxyButton({ target = MerchantGuildBankRepairButton, label = L["Guild Bank Repair"] })
                )
            end
            builder:endRow()
            builder:popContext()
        end
    end

    builder:popContext()
end

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "merchant",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.Merchant,
    graphScreen = { render = render },
})
