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

local junkStore = WowVision.junkStore

local settings = module:hasSettings()
settings:add({
    type = "Bool",
    key = "autoSellPoorItems",
    label = L["Automatically Sell Poor Items"],
    default = false,
})
-- Items the player marked as junk in the bags (see junk.lua). On by default:
-- an item is only sold because the player marked it.
settings:add({
    type = "Bool",
    key = "autoSellMarkedJunk",
    label = L["Automatically Sell Items Marked as Junk"],
    default = true,
})
settings:add({
    type = "Bool",
    key = "autoRepair",
    label = L["Automatically Repair If Possible"],
    default = false,
})

-- Vendor sell price for a bag item, in copper; nil when the item isn't
-- cached yet or has none (matches how the tooltip and merchant labels
-- read prices elsewhere in gameDB/items.lua).
local function getSellPrice(itemID)
    local getInfo = C_Item ~= nil and C_Item.GetItemInfo or GetItemInfo
    if getInfo == nil or itemID == nil then
        return nil
    end
    local ok, price = pcall(function()
        return select(11, getInfo(itemID))
    end)
    if ok and price ~= nil and price > 0 then
        return price
    end
    return nil
end

-- The bags the player carries: the backpack, the bag slots and, where the
-- game has one, the reagent bag. Never the bank.
local function carriedBags()
    local bags = {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS do
        tinsert(bags, bag)
    end
    return bags
end

-- One pass over the carried bags that sells the Poor quality (grey) items
-- (Automatically Sell Poor Items) and the items marked as junk
-- (Automatically Sell Items Marked as Junk), nothing else, and says what
-- went and for how much. UseContainerItem sells the slot directly, the same
-- action a manual right click performs while a merchant is open. What is
-- sold is decided slot by slot in junkStore.lua.
local function sellJunk(self)
    local sellPoor = self.settings.autoSellPoorItems
    local marks = self.settings.autoSellMarkedJunk and WowVision.base.windows.junk:getMarks() or nil
    if not sellPoor and marks == nil then
        return
    end
    local result = junkStore.sell({
        bags = carriedBags(),
        numSlots = C_Container.GetContainerNumSlots,
        getInfo = C_Container.GetContainerItemInfo,
        sellPrice = getSellPrice,
        sell = C_Container.UseContainerItem,
        marks = marks,
        sellPoor = sellPoor,
    })
    local text = junkStore.summary(result, L, C_CurrencyInfo.GetCoinText)
    if text ~= nil then
        WowVision:speak(text)
    end
    if result.error ~= nil then
        geterrorhandler()(result.error)
    end
end

-- Repairs everything using the player's own money. Silently skipped when
-- the vendor can't repair, nothing is damaged, or the player can't
-- afford it -- the same conditions that leave the Repair All button
-- doing nothing.
local function repairAll()
    if not CanMerchantRepair() then
        return
    end
    local cost, canRepair = GetRepairAllCost()
    if not canRepair or cost == nil or cost <= 0 or GetMoney() < cost then
        return
    end
    RepairAllItems()
    print(format(L["Repaired all items for %s."], C_CurrencyInfo.GetCoinText(cost)))
end

module:registerEvent("event", "MERCHANT_SHOW")

-- One pass per opening of the window and no more: only MERCHANT_SHOW starts
-- a sale (the bag updates the sale causes start nothing), and sellJunk looks
-- at each slot once. A failure is reported and never stops the rest, nor
-- the window.
function module:onEvent(event)
    if event ~= "MERCHANT_SHOW" or self.selling then
        return
    end
    self.selling = true
    local ok, err = pcall(sellJunk, self)
    if not ok then
        geterrorhandler()(err)
    end
    if self.settings.autoRepair then
        ok, err = pcall(repairAll)
        if not ok then
            geterrorhandler()(err)
        end
    end
    self.selling = false
end

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
            WowVision.cursor = WowVision.cursor or {}
            WowVision.cursor.pickupIsActionBar = false
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
    builder:pushContext("merchant", L["Merchant"])

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    builder:addItem(ControlId.forObject(MerchantFrameTab1), tabNode(MerchantFrameTab1, 1))
    builder:addItem(ControlId.forObject(MerchantFrameTab2), tabNode(MerchantFrameTab2, 2))
    builder:endRow()
    builder:popContext()

    builder:beginStop("items")
    builder:pushContext("items", L["Items"])
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
            builder:pushContext("repair", L["Repair"])
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
