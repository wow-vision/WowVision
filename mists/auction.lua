local module = WowVision.base.windows:createModule("auction")
local L = module.L
module:setLabel(L["Auction House"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The auction house (the modern AuctionHouseFrame: every list is a
-- ScrollBox over C_AuctionHouse data). Buy: categories, search, browse
-- results, then the commodity or item purchase panes. Sell: the item or
-- commodity posting forms with comparables. Auctions: your auctions and
-- bids. The BuyDialog overlay replaces the whole body while shown. All row
-- clicks are real clicks on the real row buttons.

local function coin(amount)
    return C_CurrencyInfo.GetCoinText(amount or 0)
end

local function getTimeLeftString(timeLeft)
    if timeLeft == 0 then
        return L["Short"]
    elseif timeLeft == 1 then
        return L["Medium"]
    elseif timeLeft == 2 then
        return L["Long"]
    end
    return L["Very Long"]
end

-- Item names from item keys arrive async from the server; labels are live,
-- so they fill in when the data lands.
local function itemKeyName(itemKey)
    if itemKey == nil then
        return nil
    end
    local info = C_AuctionHouse.GetItemKeyInfo(itemKey)
    return info ~= nil and info.itemName or nil
end

local function itemKeyId(prefix, itemKey, fallbackIndex)
    if itemKey == nil then
        return ControlId.structural(prefix .. ":" .. fallbackIndex)
    end
    return ControlId.structural(
        prefix
            .. ":"
            .. tostring(itemKey.itemID)
            .. ":"
            .. tostring(itemKey.itemLevel or 0)
            .. ":"
            .. tostring(itemKey.itemSuffix or 0)
    )
end

-- AuctionHouseItemList ScrollBoxes use index-range data providers: the
-- provider elements are NUMBERS, and the real row data comes from the
-- list's registered getEntry -- the very same table the row buttons carry
-- as their rowData.
local function rowEntry(list, data)
    if type(data) == "number" and list ~= nil and list.getEntry ~= nil then
        local ok, entry = pcall(list.getEntry, data)
        if ok then
            return entry
        end
        return nil
    end
    return data
end

local function isSelectedEntry(list, entry)
    if list == nil or list.GetSelectedEntry == nil or entry == nil then
        return false
    end
    local ok, selected = pcall(list.GetSelectedEntry, list)
    return ok and selected == entry
end

-- The old screen's deliberate naming path: hover the materialized row and
-- read the item name off GameTooltip -- the full display name, suffixes
-- included. Falls back to nil when the row is not on screen yet (the live
-- label re-resolves once focus scrolls it in).
local function scrapeRowName(helpers)
    local row = helpers.target()
    if row == nil then
        return nil
    end
    local name
    pcall(function()
        local onEnter = row:GetScript("OnEnter")
        if onEnter ~= nil then
            onEnter(row)
            name = GameTooltip:GetItem()
            local onLeave = row:GetScript("OnLeave")
            if onLeave ~= nil then
                onLeave(row)
            end
        end
    end)
    return name
end

-- A table row: label composed from the resolved entry, real clicks,
-- selected state when the list tracks one. labelOf(entry, index, helpers).
local function tableRow(list, labelOf)
    return function(data, index, helpers)
        return {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        return labelOf(rowEntry(list, data), index, helpers)
                    end,
                    kind = kinds.label,
                },
                {
                    text = function()
                        if isSelectedEntry(list, rowEntry(list, data)) then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                },
            },
            bindings = {
                { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
            },
            onFocus = helpers.onFocus,
            onFocusTick = helpers.onFocusTick,
            onUnfocus = helpers.onUnfocus,
            tooltipFrame = helpers.target,
        }
    end
end

local function actionStop(builder, stopKey, button, label)
    if button == nil or not button:IsShown() then
        return
    end
    builder:beginStop(stopKey)
    builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button, label = label }))
end

local function liveText(builder, id, label)
    builder:addItem(id, nodes.text({ label = label }))
end

-- Gold, silver, copper boxes as separate stops under a labeled context.
local function moneyInputStops(builder, keyPrefix, contextLabel, moneyFrame)
    builder:pushContext(keyPrefix, contextLabel)
    builder:beginStop(keyPrefix .. ":gold")
    builder:addItem(
        ControlId.structural(keyPrefix .. ":gold"),
        nodes.proxyEditBox({ editBox = moneyFrame.GoldBox or moneyFrame.gold, label = L["Gold"] })
    )
    builder:beginStop(keyPrefix .. ":silver")
    builder:addItem(
        ControlId.structural(keyPrefix .. ":silver"),
        nodes.proxyEditBox({ editBox = moneyFrame.SilverBox or moneyFrame.silver, label = L["Silver"] })
    )
    builder:beginStop(keyPrefix .. ":copper")
    builder:addItem(
        ControlId.structural(keyPrefix .. ":copper"),
        nodes.proxyEditBox({ editBox = moneyFrame.CopperBox or moneyFrame.copper, label = L["Copper"] })
    )
    builder:popContext()
end

------------------------------------------------------------
-- Buy tab
------------------------------------------------------------

local function renderCategories(builder)
    builder:beginStop("categories")
    nodes.scrollBoxList(builder, {
        scrollBox = AuctionHouseFrame.CategoriesList.ScrollBox,
        key = "categories",
        label = L["Categories"],
        id = function(data, index)
            if data ~= nil and data.name ~= nil then
                return ControlId.structural("cat:" .. tostring(data.type) .. ":" .. data.name)
            end
            return ControlId.structural("cat:" .. index)
        end,
        row = function(data, index, helpers)
            return {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return data ~= nil and data.name or nil
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            if data ~= nil and data.selected then
                                return L["selected"]
                            end
                            return nil
                        end,
                        kind = kinds.selected,
                    },
                },
                bindings = {
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                },
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
            }
        end,
    })
end

local function renderSearchBar(builder)
    local searchBar = AuctionHouseFrame.SearchBar
    if searchBar.FilterButton ~= nil and searchBar.FilterButton:IsShown() then
        builder:beginStop("filter")
        builder:addItem(
            ControlId.forObject(searchBar.FilterButton),
            nodes.proxyDropdown({ target = searchBar.FilterButton })
        )
    end
    builder:beginStop("searchBox")
    builder:addItem(
        ControlId.structural("searchBox"),
        nodes.proxyEditBox({ editBox = searchBar.SearchBox, label = L["Search"] })
    )
    actionStop(builder, "searchButton", searchBar.SearchButton)
end

local function renderBrowseResults(builder)
    local resultsFrame = AuctionHouseFrame.BrowseResultsFrame
    builder:beginStop("results")
    nodes.scrollBoxList(builder, {
        scrollBox = resultsFrame.ItemList.ScrollBox,
        key = "results",
        label = L["Results"],
        id = function(data, index)
            local entry = rowEntry(resultsFrame.ItemList, data)
            return itemKeyId("browse", entry ~= nil and entry.itemKey or nil, index)
        end,
        row = tableRow(resultsFrame.ItemList, function(entry, index, helpers)
            if entry == nil then
                return nil
            end
            local parts = {}
            tinsert(parts, scrapeRowName(helpers) or itemKeyName(entry.itemKey) or "")
            tinsert(parts, coin(entry.minPrice))
            tinsert(parts, L["Available"] .. " " .. tostring(entry.totalQuantity or 0))
            return table.concat(parts, ", ")
        end),
    })
end

local function renderCommoditiesBuy(builder)
    local frame = AuctionHouseFrame.CommoditiesBuyFrame
    actionStop(builder, "back", frame.BackButton)

    local itemList = frame.ItemList
    builder:beginStop("commodityAuctions")
    nodes.scrollBoxList(builder, {
        scrollBox = itemList.ScrollBox,
        key = "commodityAuctions",
        label = L["Auctions"],
        id = function(data, index)
            local entry = rowEntry(itemList, data)
            if entry ~= nil and entry.auctionID ~= nil then
                return ControlId.structural("cauction:" .. entry.auctionID)
            end
            return ControlId.structural("cauction:" .. index)
        end,
        row = tableRow(itemList, function(entry)
            if entry == nil then
                return nil
            end
            local name = entry.itemID ~= nil and C_Item.GetItemInfo(entry.itemID) or nil
            local parts = {}
            tinsert(parts, name or "")
            tinsert(parts, L["Unit Price"] .. " " .. coin(entry.unitPrice))
            tinsert(parts, L["Available"] .. " " .. tostring(entry.quantity or 0))
            return table.concat(parts, ", ")
        end),
    })

    local buyDisplay = frame.BuyDisplay
    if buyDisplay.QuantityInput ~= nil and buyDisplay.QuantityInput:IsShown() then
        builder:beginStop("quantity")
        builder:addItem(
            ControlId.structural("quantity"),
            nodes.proxyEditBox({
                editBox = buyDisplay.QuantityInput.InputBox,
                label = buyDisplay.QuantityInput.Label:GetText(),
            })
        )
        builder:beginStop("totalPrice")
        liveText(builder, ControlId.structural("totalPrice"), function()
            return (buyDisplay.TotalPrice.Label:GetText() or "") .. " " .. coin(buyDisplay.TotalPrice:GetAmount())
        end)
        actionStop(builder, "buy", buyDisplay.BuyButton)
    end
end

local function renderItemBuy(builder)
    local frame = AuctionHouseFrame.ItemBuyFrame
    actionStop(builder, "back", frame.BackButton)

    if frame.ItemList ~= nil and frame.ItemList:IsShown() then
        builder:beginStop("itemAuctions")
        nodes.scrollBoxList(builder, {
            scrollBox = frame.ItemList.ScrollBox,
            key = "itemAuctions",
            label = L["Auctions"],
            id = function(data, index)
                local entry = rowEntry(frame.ItemList, data)
                if entry ~= nil and entry.auctionID ~= nil then
                    return ControlId.structural("auction:" .. entry.auctionID)
                end
                return ControlId.structural("auction:" .. index)
            end,
            row = tableRow(frame.ItemList, function(entry, index, helpers)
                if entry == nil then
                    return nil
                end
                local parts = {}
                local name = scrapeRowName(helpers)
                if name ~= nil then
                    tinsert(parts, name)
                end
                if entry.bidAmount ~= nil then
                    tinsert(parts, L["Bid Price"] .. " " .. coin(entry.bidAmount))
                end
                if entry.buyoutAmount ~= nil then
                    tinsert(parts, L["Buyout Price"] .. " " .. coin(entry.buyoutAmount))
                end
                if entry.timeLeft ~= nil then
                    tinsert(parts, L["Time Left"] .. " " .. getTimeLeftString(entry.timeLeft))
                end
                return table.concat(parts, ", ")
            end),
        })
    end

    if frame:HasAuctionSelected() then
        local buyout = frame.BuyoutFrame
        if buyout ~= nil and buyout:IsShown() then
            builder:beginStop("buyoutPrice")
            builder:pushContext("buyout", L["Buyout Frame"])
            liveText(builder, ControlId.structural("buyoutPrice"), function()
                return coin(buyout:GetPrice())
            end)
            builder:popContext()
            actionStop(builder, "buyout", buyout.BuyoutButton)
        end
        local bid = frame.BidFrame
        if bid ~= nil and bid:IsShown() then
            moneyInputStops(builder, "bid", L["Bid Frame"], bid.BidAmount)
            actionStop(builder, "bidButton", bid.BidButton)
        end
    end
end

-- Drilling into a result replaces the browse list with a purchase pane:
-- land focus on its Back button, and remember the result so Back returns
-- to it instead of leaving focus recovery to walk backward to the search
-- button.
local function trackBuyTransitions(screen)
    local mode = "browse"
    local back = nil
    if AuctionHouseFrame.CommoditiesBuyFrame:IsShown() then
        mode = "commodity"
        back = AuctionHouseFrame.CommoditiesBuyFrame.BackButton
    elseif AuctionHouseFrame.ItemBuyFrame:IsShown() then
        mode = "item"
        back = AuctionHouseFrame.ItemBuyFrame.BackButton
    end
    if screen._buyMode == mode then
        return
    end
    local previous = screen._buyMode
    screen._buyMode = mode
    if mode ~= "browse" and back ~= nil then
        if previous == "browse" then
            screen._browseReturn = screen.state.curKey
        end
        screen.state.nextSuggestedMove = ControlId.forObject(back)
    elseif mode == "browse" and previous ~= nil and screen._browseReturn ~= nil then
        screen.state.nextSuggestedMove = screen._browseReturn
        screen._browseReturn = nil
    end
end

local function renderBuyTab(builder, screen)
    trackBuyTransitions(screen)
    renderCategories(builder)
    renderSearchBar(builder)
    if AuctionHouseFrame.BrowseResultsFrame:IsShown() then
        renderBrowseResults(builder)
    end
    if AuctionHouseFrame.CommoditiesBuyFrame:IsShown() then
        renderCommoditiesBuy(builder)
    elseif AuctionHouseFrame.ItemBuyFrame:IsShown() then
        renderItemBuy(builder)
    end
end

------------------------------------------------------------
-- Sell tab
------------------------------------------------------------

local function renderPriceInput(builder, keyPrefix, priceInput)
    if priceInput == nil or not priceInput:IsShown() then
        return
    end
    moneyInputStops(builder, keyPrefix, priceInput.Label:GetText() or "", priceInput.MoneyInputFrame)
end

-- The posting form shared by item and commodity sells. config.itemSell adds
-- the buyout mode checkbox and the secondary price input.
local function renderSellForm(builder, frame, itemSell)
    builder:beginStop("placeItem")
    builder:addItem(ControlId.structural("placeItem"), {
        controlType = graph.controlTypes.button,
        announcements = { { text = L["Place Item Here"], kind = kinds.label } },
        onActivate = function()
            frame:OnOverlayClick()
        end,
        bindings = {
            {
                binding = "drag",
                type = "Function",
                func = function()
                    frame:OnOverlayClick()
                end,
            },
        },
    })

    builder:beginStop("sellQuantity")
    builder:addItem(
        ControlId.structural("sellQuantity"),
        nodes.proxyEditBox({
            editBox = frame.QuantityInput.InputBox,
            label = frame.QuantityInput.Label:GetText(),
        })
    )
    actionStop(builder, "maxQuantity", frame.QuantityInput.MaxButton)

    if frame.Duration ~= nil and frame.Duration.Dropdown ~= nil then
        builder:beginStop("duration")
        builder:addItem(
            ControlId.forObject(frame.Duration.Dropdown),
            nodes.proxyDropdown({ target = frame.Duration.Dropdown })
        )
    end

    renderPriceInput(builder, "price", frame.PriceInput)
    if itemSell then
        if frame.BuyoutModeCheckButton ~= nil and frame.BuyoutModeCheckButton:IsShown() then
            builder:beginStop("buyoutMode")
            builder:addItem(
                ControlId.forObject(frame.BuyoutModeCheckButton),
                nodes.proxyCheckButton({ target = frame.BuyoutModeCheckButton })
            )
        end
        renderPriceInput(builder, "secondaryPrice", frame.SecondaryPriceInput)
    end

    builder:beginStop("deposit")
    liveText(builder, ControlId.structural("deposit"), function()
        return (frame.Deposit.Label:GetText() or "") .. " " .. coin(frame.Deposit.MoneyDisplayFrame:GetAmount())
    end)
    builder:beginStop("sellTotal")
    liveText(builder, ControlId.structural("sellTotal"), function()
        return (frame.TotalPrice.Label:GetText() or "") .. " " .. coin(frame.TotalPrice:GetAmount())
    end)
    actionStop(builder, "post", frame.PostButton)
end

local function renderSellComparables(builder, list, labelOf)
    if list == nil or list.ScrollBox == nil then
        return
    end
    builder:beginStop("comparables")
    nodes.scrollBoxList(builder, {
        scrollBox = list.ScrollBox,
        key = "comparables",
        label = L["Auctions"],
        id = function(data, index)
            local entry = rowEntry(list, data)
            if entry ~= nil and entry.auctionID ~= nil then
                return ControlId.structural("comparable:" .. entry.auctionID)
            end
            return ControlId.structural("comparable:" .. index)
        end,
        row = tableRow(list, labelOf),
    })
end

local function renderItemSell(builder)
    local frame = AuctionHouseFrame.ItemSellFrame
    renderSellForm(builder, frame, true)
    renderSellComparables(builder, frame:GetItemSellList(), function(entry, index, helpers)
        if entry == nil then
            return nil
        end
        local parts = {}
        local name = scrapeRowName(helpers)
        if name ~= nil then
            tinsert(parts, name)
        end
        if entry.bidAmount ~= nil then
            tinsert(parts, L["Bid Price"] .. " " .. coin(entry.bidAmount))
        end
        if entry.buyoutAmount ~= nil then
            tinsert(parts, L["Buyout Price"] .. " " .. coin(entry.buyoutAmount))
        end
        return table.concat(parts, ", ")
    end)
end

local function renderCommoditySell(builder)
    local frame = AuctionHouseFrame.CommoditiesSellFrame
    renderSellForm(builder, frame, false)
    renderSellComparables(builder, frame:GetCommoditiesSellList(), function(entry)
        if entry == nil then
            return nil
        end
        local parts = {}
        local name = entry.itemID ~= nil and C_Item.GetItemInfo(entry.itemID) or nil
        tinsert(parts, name or "")
        tinsert(parts, L["Unit Price"] .. " " .. coin(entry.unitPrice))
        if entry.owners ~= nil and #entry.owners > 0 then
            tinsert(parts, L["Seller"] .. " " .. table.concat(entry.owners, ", "))
        end
        return table.concat(parts, ", ")
    end)
end

local function renderSellTab(builder)
    if AuctionHouseFrame.ItemSellFrame:IsShown() then
        renderItemSell(builder)
    elseif AuctionHouseFrame.CommoditiesSellFrame:IsShown() then
        renderCommoditySell(builder)
    end
end

------------------------------------------------------------
-- Auctions tab (your auctions and bids)
------------------------------------------------------------

local function renderAuctionsSubTabs(builder, auctionsFrame)
    builder:beginStop("subTabs")
    builder:pushContext("subTabs", L["Tabs"])
    builder:startRow()
    for _, tab in ipairs(auctionsFrame.Tabs or {}) do
        if tab:IsShown() then
            local captured = tab
            local vtable = nodes.proxyButton({ target = captured })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        if PanelTemplates_GetSelectedTab(auctionsFrame) == captured:GetID() then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                })
                builder:addItem(ControlId.forObject(captured), vtable)
            end
        end
    end
    builder:endRow()
    builder:popContext()
end

local function renderAuctionsTab(builder)
    local auctionsFrame = AuctionHouseFrame.AuctionsFrame
    renderAuctionsSubTabs(builder, auctionsFrame)

    if auctionsFrame.AllAuctionsList ~= nil and auctionsFrame.AllAuctionsList:IsShown() then
        builder:beginStop("myAuctions")
        nodes.scrollBoxList(builder, {
            scrollBox = auctionsFrame.AllAuctionsList.ScrollBox,
            key = "myAuctions",
            label = L["Auctions"],
            id = function(data, index)
                local entry = rowEntry(auctionsFrame.AllAuctionsList, data)
                if entry ~= nil and entry.auctionID ~= nil then
                    return ControlId.structural("mine:" .. entry.auctionID)
                end
                return ControlId.structural("mine:" .. index)
            end,
            row = tableRow(auctionsFrame.AllAuctionsList, function(entry, index, helpers)
                if entry == nil then
                    return nil
                end
                local parts = {}
                if entry.status == 1 then
                    tinsert(parts, L["Sold"])
                end
                tinsert(parts, scrapeRowName(helpers) or itemKeyName(entry.itemKey) or "")
                if entry.quantity ~= nil and entry.quantity > 1 then
                    tinsert(parts, "x" .. entry.quantity)
                end
                if entry.bidAmount ~= nil then
                    tinsert(parts, L["Bid Price"] .. " " .. coin(entry.bidAmount))
                end
                if entry.buyoutAmount ~= nil then
                    tinsert(parts, L["Buyout Price"] .. " " .. coin(entry.buyoutAmount))
                end
                if entry.timeLeftSeconds ~= nil then
                    tinsert(parts, L["Time Left"] .. " " .. SecondsToTime(entry.timeLeftSeconds, false, true))
                end
                return table.concat(parts, ", ")
            end),
        })
        actionStop(builder, "cancelAuction", auctionsFrame.CancelAuctionButton)
    end

    if auctionsFrame.BidsList ~= nil and auctionsFrame.BidsList:IsShown() then
        builder:beginStop("myBids")
        nodes.scrollBoxList(builder, {
            scrollBox = auctionsFrame.BidsList.ScrollBox,
            key = "myBids",
            label = L["Bids"],
            id = function(data, index)
                local entry = rowEntry(auctionsFrame.BidsList, data)
                if entry ~= nil and entry.auctionID ~= nil then
                    return ControlId.structural("bid:" .. entry.auctionID)
                end
                return ControlId.structural("bid:" .. index)
            end,
            row = tableRow(auctionsFrame.BidsList, function(entry, index, helpers)
                if entry == nil then
                    return nil
                end
                local parts = {}
                tinsert(parts, scrapeRowName(helpers) or itemKeyName(entry.itemKey) or "")
                if entry.bidder ~= nil then
                    tinsert(parts, L["Bidder"] .. " " .. tostring(entry.bidder))
                end
                if entry.bidAmount ~= nil then
                    tinsert(parts, L["Bid Amount"] .. " " .. coin(entry.bidAmount))
                end
                if entry.minBid ~= nil then
                    tinsert(parts, L["Minimum Bid"] .. " " .. coin(entry.minBid))
                end
                if entry.timeLeft ~= nil then
                    tinsert(parts, L["Time Left"] .. " " .. getTimeLeftString(entry.timeLeft))
                end
                return table.concat(parts, ", ")
            end),
        })
        if auctionsFrame.BidFrame ~= nil and auctionsFrame.BidFrame:IsShown() then
            moneyInputStops(builder, "rebid", L["Bid Frame"], auctionsFrame.BidFrame.BidAmount)
            actionStop(builder, "rebidButton", auctionsFrame.BidFrame.BidButton)
        end
        if auctionsFrame.BuyoutFrame ~= nil and auctionsFrame.BuyoutFrame:IsShown() then
            builder:beginStop("bidBuyoutPrice")
            builder:pushContext("bidBuyout", L["Buyout Frame"])
            liveText(builder, ControlId.structural("bidBuyoutPrice"), function()
                return coin(auctionsFrame.BuyoutFrame:GetPrice())
            end)
            builder:popContext()
            actionStop(builder, "bidBuyout", auctionsFrame.BuyoutFrame.BuyoutButton)
        end
    end
end

------------------------------------------------------------
-- Buy dialog overlay and the root
------------------------------------------------------------

local function renderBuyDialog(builder)
    local dialog = AuctionHouseFrame.BuyDialog
    builder:pushContext("buyDialog", L["Auction House"])
    builder:beginStop("dialogItem")
    liveText(builder, ControlId.structural("dialogItem"), function()
        return dialog.ItemDisplay.ItemText:GetText()
    end)
    builder:beginStop("dialogPrice")
    liveText(builder, ControlId.structural("dialogPrice"), function()
        return coin(dialog.PriceFrame:GetAmount())
    end)
    actionStop(builder, "buyNow", dialog.BuyNowButton)
    actionStop(builder, "cancelBuy", dialog.CancelButton)
    builder:popContext()
end

local function render(builder, screen)
    if AuctionHouseFrame == nil or not AuctionHouseFrame:IsShown() then
        return
    end

    -- The buy dialog overlays the whole window.
    if AuctionHouseFrame.BuyDialog:IsShown() then
        renderBuyDialog(builder)
        return
    end

    builder:pushContext("auction", AuctionHouseFrame:GetTitleText():GetText())

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i, tab in ipairs(AuctionHouseFrame.Tabs or {}) do
        if tab:IsShown() then
            local captured = tab
            local tabIndex = i
            local vtable = nodes.proxyButton({ target = captured })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        if AuctionHouseFrame.selectedTab == tabIndex then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                })
                builder:addItem(ControlId.forObject(captured), vtable)
            end
        end
    end
    builder:endRow()
    builder:popContext()

    if AuctionHouseFrame.BuyTab ~= nil and AuctionHouseFrame.selectedTab == 1 then
        renderBuyTab(builder, screen)
    elseif AuctionHouseFrame.selectedTab == 2 then
        renderSellTab(builder)
    elseif AuctionHouseFrame.selectedTab == 3 then
        renderAuctionsTab(builder)
    end

    builder:popContext()
end

-- The search filter menu's level-range row holds two edit boxes.
module:registerDropdownMenu("MENU_AUCTION_HOUSE_SEARCH_FILTER", {
    [2] = function(builder, itemFrame, index)
        if itemFrame.MinLevel ~= nil then
            builder:addItem(
                ControlId.structural("minLevel"),
                nodes.proxyEditBox({ editBox = itemFrame.MinLevel, label = L["Minimum"], autoInput = false })
            )
        end
        if itemFrame.MaxLevel ~= nil then
            builder:addItem(
                ControlId.structural("maxLevel"),
                nodes.proxyEditBox({ editBox = itemFrame.MaxLevel, label = L["Maximum"], autoInput = false })
            )
        end
    end,
})

module:registerWindow({
    type = "EventWindow",
    name = "AuctionHouseFrame",
    openEvent = "AUCTION_HOUSE_SHOW",
    closeEvent = "AUCTION_HOUSE_CLOSED",
    graphScreen = { render = render },
})
