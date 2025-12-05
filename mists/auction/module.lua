local module = WowVision.base.windows:createModule("auction")
local L = module.L
module:setLabel(L["Auction House"])
local gen = module:hasUI()

--Some utility functions
local function getTimeLeftString(time)
    if time == 0 then
        return L["Short"]
    elseif time == 1 then
        return L["Medium"]
    elseif time == 2 then
        return L["Long"]
    else
        return L["Very Long"]
    end
end

local auctionHooks = {}

gen:Element("auction", function(props)
    local result = { "Panel", layout = true, shouldAnnounce = false, children = {} }
    if AuctionHouseFrame.BuyDialog:IsShown() then
        --This is a popup that overlays the entire screen
        tinsert(result.children, { "auction/BuyDialog", key = "BuyDialog" })
    else
        tinsert(result.children, { "auction/AuctionHouse", key = "AuctionHouse" })
    end
    return result
end)

gen:Element("auction/AuctionHouse", function(props)
    local result = {
        "Panel",
        label = AuctionHouseFrame:GetTitleText():GetText(),
        wrap = true,
        children = {
            { "auction/Tabs" },
        },
    }

    return result
end)

gen:Element("auction/Tabs", function(props)
    local frame = AuctionHouseFrame
    local result = {
        "ProxyTabPanel",
        frame = frame,
        wrap = true,
        tabs = {
            { "auction/BuyTab" },
            { "auction/SellTab" },
            { "auction/AuctionsTab" },
        },
    }

    return result
end)

gen:Element("auction/BuyTab", function(props)
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/CategoriesList" },
            { "auction/SearchBar" },
        },
    }
    if AuctionHouseFrame.BrowseResultsFrame:IsShown() then
        tinsert(result.children, { "auction/SearchResults" })
    end
    if AuctionHouseFrame.CommoditiesBuyFrame:IsShown() then
        tinsert(result.children, { "auction/BuyCommodity" })
    elseif AuctionHouseFrame.ItemBuyFrame:IsShown() then
        tinsert(result.children, { "auction/BuyItem" })
    end
    return result
end)

local function CategoriesList_getElement(self, button)
    return { "ProxyButton", frame = button }
end

gen:Element("auction/CategoriesList", function(props)
    return {
        "ProxyScrollBox",
        frame = AuctionHouseFrame.CategoriesList.ScrollBox,
        label = L["Categories"],
        getElement = CategoriesList_getElement,
    }
end)

gen:Element("auction/SearchBar", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            {
                "ProxyDropdownButton",
                frame = AuctionHouseFrame.SearchBar.FilterButton,
            },
            {
                "ProxyEditBox",
                frame = AuctionHouseFrame.SearchBar.SearchBox,
                label = L["Search"],
            },
            { "ProxyButton", frame = AuctionHouseFrame.SearchBar.SearchButton },
        },
    }
end)

module:registerDropdownMenu("MENU_AUCTION_HOUSE_SEARCH_FILTER", { [2] = { "auction/DropdownLevelRange" } })

gen:Element("auction/DropdownLevelRange", function(props)
    return {
        "List",
        layout = true,
        shouldAnnounce = false,
        children = {
            {
                "ProxyEditBox",
                frame = props.frame.MinLevel,
                autoInputOnFocus = false,
                hookEnter = true,
                label = L["Minimum"],
            },
            {
                "ProxyEditBox",
                frame = props.frame.MaxLevel,
                autoInputOnFocus = false,
                hookEnter = true,
                label = L["Maximum"],
            },
        },
    }
end)

local function BrowseResults_getNumEntries(self)
    return AuctionHouseFrame.BrowseResultsFrame:GetNumBrowseResults()
end

local function BrowseResults_getButtonData(self, button)
    local rowData = button:GetRowData()
    local data = {}
    button:GetScript("OnEnter")(button)
    data.name = GameTooltip:GetItem()
    button:GetScript("OnLeave")(button)

    data.price = C_CurrencyInfo.GetCoinText(rowData.minPrice)
    data.available = rowData.totalQuantity
    return data
end

gen:Element("auction/SearchResults", function(props)
    return {
        "ProxyScrollTable",
        frame = AuctionHouseFrame.BrowseResultsFrame.ItemList.ScrollBox,
        label = L["Results"],
        getNumEntries = BrowseResults_getNumEntries,
        getButtonData = BrowseResults_getButtonData,
        headers = {
            {
                key = "name",
            },
            {
                key = "price",
                label = L["Price"],
            },
            {
                key = "available",
                label = L["Available"],
            },
        },
    }
end)

gen:Element("auction/BuyCommodity", function(props)
    local frame = AuctionHouseFrame.CommoditiesBuyFrame
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "ProxyButton", frame = frame.BackButton },
            { "auction/BuyCommodityAuctionsList", frame = frame.ItemList },
            { "auction/BuyCommodityBuyDisplay", frame = frame.BuyDisplay },
        },
    }
end)

local function BuyCommodityAuctionsList_getNumEntries(self)
    return AuctionHouseFrame.CommoditiesBuyFrame.ItemList:getNumEntries()
end

local function BuyCommodityAuctionsList_getButtonData(self, button)
    local rowData = button:GetRowData()
    local data = {}
    data.name = C_Item.GetItemInfo(rowData.itemID)
    data.unitPrice = C_CurrencyInfo.GetCoinText(rowData.unitPrice)
    data.available = rowData.quantity
    return data
end

local function BuyCommodityAuctionsList_getSelectedIndex(self)
    return -1
end

gen:Element("auction/BuyCommodityAuctionsList", function(props)
    return {
        "ProxyScrollTable",
        frame = props.frame.ScrollBox,
        label = L["Auctions"],
        getNumEntries = BuyCommodityAuctionsList_getNumEntries,
        getButtonData = BuyCommodityAuctionsList_getButtonData,
        getSelectedIndex = BuyCommodityAuctionsList_getSelectedIndex,
        headers = {
            {
                key = "name",
            },
            {
                key = "unitPrice",
                label = L["Unit Price"],
            },
            {
                key = "available",
                label = L["Available"],
            },
        },
    }
end)

gen:Element("auction/BuyCommodityBuyDisplay", function(props)
    local result = { "Panel", layout = true, shouldAnnounce = false, children = {} }
    if props.frame.QuantityInput:IsShown() then
        tinsert(result.children, {
            "ProxyEditBox",
            frame = props.frame.QuantityInput.InputBox,
            label = props.frame.QuantityInput.Label:GetText(),
        })
        tinsert(result.children, {
            "Text",
            label = props.frame.TotalPrice.Label:GetText(),
            text = C_CurrencyInfo.GetCoinText(props.frame.TotalPrice:GetAmount()),
        })
        tinsert(result.children, { "ProxyButton", frame = props.frame.BuyButton })
    end

    return result
end)

gen:Element("auction/BuyItem", function(props)
    local frame = AuctionHouseFrame.ItemBuyFrame
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "ProxyButton", frame = AuctionHouseFrame.ItemBuyFrame.BackButton },
        },
    }
    if frame.ItemList:IsShown() then
        tinsert(result.children, { "auction/BuyItemAuctionsList", frame = frame.ItemList })
    end
    if frame:HasAuctionSelected() then
        tinsert(result.children, { "auction/BuyoutFrame", frame = frame.BuyoutFrame })
        tinsert(result.children, { "auction/BidFrame", frame = frame.BidFrame })
    end
    return result
end)

local function BuyItemAuctionsList_getNumEntries(self)
    return AuctionHouseFrame.ItemBuyFrame.ItemList:getNumEntries()
end

local function BuyItemAuctionsList_getButtonData(self, button)
    local rowData = button:GetRowData()
    local data = {}
    button:GetScript("OnEnter")(button)
    data.name = GameTooltip:GetItem()
    button:GetScript("OnLeave")(button)
    if rowData.bidAmount then
        data.bidPrice = C_CurrencyInfo.GetCoinText(rowData.bidAmount)
    end
    if rowData.buyoutAmount then
        data.buyoutPrice = C_CurrencyInfo.GetCoinText(rowData.buyoutAmount)
    end
    if rowData.timeLeft then
        data.timeLeft = getTimeLeftString(rowData.timeLeft)
    end

    return data
end

gen:Element("auction/BuyItemAuctionsList", function(props)
    return {
        "ProxyScrollTable",
        frame = props.frame.ScrollBox,
        label = L["Auctions"],
        getNumEntries = BuyItemAuctionsList_getNumEntries,
        getButtonData = BuyItemAuctionsList_getButtonData,
        headers = {
            { key = "name" },
            { key = "bidPrice", label = L["Bid Price"] },
            { key = "buyoutPrice", label = L["Buyout Price"] },
            { key = "timeLeft", label = L["Time Left"] },
        },
    }
end)

gen:Element("auction/BuyoutFrame", function(props)
    return {
        "Panel",
        label = L["Buyout Frame"],
        children = {
            { "Text", text = C_CurrencyInfo.GetCoinText(props.frame:GetPrice()) },
            { "ProxyButton", frame = props.frame.BuyoutButton },
        },
    }
end)

gen:Element("auction/BidFrame", function(props)
    local result = { "Panel", label = L["Bid Frame"], children = {} }
    tinsert(result.children, {
        "ProxyEditBox",
        frame = props.frame.BidAmount.gold,
        label = L["Gold"],
    })
    tinsert(result.children, { "ProxyEditBox", frame = props.frame.BidAmount.silver, label = L["Silver"] })
    tinsert(result.children, {
        "ProxyEditBox",
        frame = props.frame.BidAmount.copper,
        label = L["Copper"],
    })
    tinsert(result.children, { "ProxyButton", frame = props.frame.BidButton })
    return result
end)

gen:Element("auction/BuyDialog", function(props)
    local frame = AuctionHouseFrame.BuyDialog
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        wrap = true,
        children = {
            { "Text", text = frame.ItemDisplay.ItemText:GetText() },
            { "Text", text = C_CurrencyInfo.GetCoinText(frame.PriceFrame:GetAmount()) },
            { "ProxyButton", frame = AuctionHouseFrame.BuyDialog.CancelButton, enabled = true },
            { "ProxyButton", frame = AuctionHouseFrame.BuyDialog.BuyNowButton, enabled = true },
        },
    }
end)

gen:Element("auction/SellTab", function(props)
    local result = { "Panel", layout = true, shouldAnnounce = false, children = {} }
    if AuctionHouseFrame.ItemSellFrame:IsShown() then
        tinsert(result.children, { "auction/SellItem" })
    elseif AuctionHouseFrame.CommoditiesSellFrame:IsShown() then
        tinsert(result.children, { "auction/SellCommodity" })
    end
    return result
end)

local function SellItem_Click()
    AuctionHouseFrame.ItemSellFrame:OnOverlayClick()
end

gen:Element("auction/SellTabItemPlacement", function(props)
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            {
                "Button",
                label = L["Place Item Here"],
                events = {
                    click = SellItem_Click,
                },
            },
        },
    }
    return result
end)

gen:Element("auction/SellItem", function(props)
    local frame = AuctionHouseFrame.ItemSellFrame
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/SellTabItemPlacement", frame = frame },
            {
                "ProxyEditBox",
                frame = frame.QuantityInput.InputBox,
                label = frame.QuantityInput.Label:GetText(),
            },
            { "ProxyButton", frame = frame.QuantityInput.MaxButton },
            { "ProxyDropdownButton", frame = frame.Duration.Dropdown },
            { "auction/SellItemItemList" },
            { "auction/SellItemPriceInput", frame = frame.PriceInput },
            {
                "Text",
                label = frame.Deposit.Label:GetText(),
                text = C_CurrencyInfo.GetCoinText(frame.Deposit.MoneyDisplayFrame:GetAmount()),
            },
            {
                "Text",
                label = frame.TotalPrice.Label:GetText(),
                text = C_CurrencyInfo.GetCoinText(frame.TotalPrice:GetAmount()),
            },
            { "ProxyButton", frame = frame.PostButton },
            { "ProxyCheckButton", frame = frame.BuyoutModeCheckButton },
            { "auction/SellItemPriceInput", frame = frame.SecondaryPriceInput },
        },
    }
    return result
end)

gen:Element("auction/SellItemPriceInput", function(props)
    if not props.frame:IsShown() then
        return nil
    end
    local moneyFrame = props.frame.MoneyInputFrame
    local result = {
        "Panel",
        label = props.frame.Label:GetText(),
        layout = true,
        children = {
            { "ProxyEditBox", frame = moneyFrame.GoldBox, label = L["Gold"] },
            { "ProxyEditBox", frame = moneyFrame.SilverBox, label = L["Silver"] },
            { "ProxyEditBox", frame = moneyFrame.CopperBox, label = L["Copper"] },
        },
    }
    return result
end)

local function SellItemItemList_getNumEntries(self)
    return AuctionHouseFrame.ItemSellFrame:GetItemSellList():getNumEntries()
end

local function SellItemItemList_getButtonData(self, button)
    local rowData = button:GetRowData()
    local data = {}
    button:GetScript("OnEnter")(button)
    data.name = GameTooltip:GetItem()
    button:GetScript("OnLeave")(button)

    if rowData.bidAmount then
        data.bidPrice = C_CurrencyInfo.GetCoinText(rowData.bidAmount)
    end
    if rowData.buyoutAmount then
        data.buyoutPrice = C_CurrencyInfo.GetCoinText(rowData.buyoutAmount)
    end

    return data
end

gen:Element("auction/SellItemItemList", function(props)
    local frame = AuctionHouseFrame.ItemSellFrame:GetItemSellList()
    if not frame then
        return nil
    end

    return {
        "ProxyScrollTable",
        frame = frame.ScrollBox,
        label = L["Auctions"],
        getNumEntries = SellItemItemList_getNumEntries,
        getButtonData = SellItemItemList_getButtonData,
        headers = {
            { key = "name" },
            { key = "bidPrice", label = L["Bid Price"] },
            { key = "buyoutPrice", label = L["Buyout Price"] },
        },
    }
end)

gen:Element("auction/SellCommodity", function(props)
    local frame = AuctionHouseFrame.CommoditiesSellFrame
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/SellTabItemPlacement", frame = frame },
            {
                "ProxyEditBox",
                frame = frame.QuantityInput.InputBox,
                label = frame.QuantityInput.Label:GetText(),
            },
            { "ProxyButton", frame = frame.QuantityInput.MaxButton },
            { "ProxyDropdownButton", frame = frame.Duration.Dropdown },
            { "auction/SellCommodityItemList" },
            { "auction/SellItemPriceInput", frame = frame.PriceInput },
            {
                "Text",
                label = frame.Deposit.Label:GetText(),
                text = C_CurrencyInfo.GetCoinText(frame.Deposit.MoneyDisplayFrame:GetAmount()),
            },
            {
                "Text",
                label = frame.TotalPrice.Label:GetText(),
                text = C_CurrencyInfo.GetCoinText(frame.TotalPrice:GetAmount()),
            },
            { "ProxyButton", frame = frame.PostButton },
        },
    }
    return result
end)

local function SellCommodityItemList_getNumEntries()
    return AuctionHouseFrame.CommoditiesSellFrame:GetCommoditiesSellList():getNumEntries()
end

local function SellCommodityItemList_getButtonData(self, button)
    local rowData = button:GetRowData()
    local data = {}
    data.name = C_Item.GetItemInfo(rowData.itemID)
    data.unitPrice = C_CurrencyInfo.GetCoinText(rowData.unitPrice)

    if rowData.owners and #rowData.owners > 0 then
        local owners = table.concat(rowData.owners, ", ")
        data.seller = owners
    end

    return data
end

gen:Element("auction/SellCommodityItemList", function(props)
    local frame = AuctionHouseFrame.CommoditiesSellFrame:GetCommoditiesSellList()
    if not frame then
        return nil
    end
    return {
        "ProxyScrollTable",
        frame = frame.ScrollBox,
        label = L["Auctions"],
        getNumEntries = SellCommodityItemList_getNumEntries,
        getButtonData = SellCommodityItemList_getButtonData,
        headers = {
            { key = "name" },
            { key = "unitPrice", label = L["Unit Price"] },
            { key = "seller", label = L["Seller"] },
        },
    }
end)

gen:Element("auction/AuctionsTab", function(props)
    local frame = AuctionHouseFrame.AuctionsFrame
    local result = {
        "ProxyTabPanel",
        frame = frame,
        tabs = {
            { "auction/AuctionsFrameAuctions", frame = frame },
            { "auction/AuctionsFrameBids", frame = frame },
        },
    }
    return result
end)

gen:Element("auction/AuctionsFrameAuctions", function(props)
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/AllAuctionsList", frame = props.frame.AllAuctionsList },
            { "ProxyButton", frame = props.frame.CancelAuctionButton },
        },
    }
    return result
end)

local function AllAuctionsList_getButtonData(self, button)
    local rowData = button:GetRowData()
    local data = {}
    if rowData.status == 1 then
        data.sold = true
    end
    button:GetScript("OnEnter")(button)
    data.name = GameTooltip:GetItem()
    button:GetScript("OnLeave")(button)
    if rowData.bidAmount then
        data.bidPrice = C_CurrencyInfo.GetCoinText(rowData.bidAmount)
    end
    if rowData.buyoutAmount then
        data.buyoutPrice = C_CurrencyInfo.GetCoinText(rowData.buyoutAmount)
    end
    if rowData.quantity then
        data.quantity = rowData.quantity
    end
    if rowData.timeLeftSeconds then
        data.timeLeft = SecondsToTime(rowData.timeLeftSeconds, false, true)
    end
    return data
end

local AllAuctionsList_selection = nil

local function AllAuctionsList_selectionCallback(data)
    AllAuctionsList_selection = data
end

--mark
local function AllAuctionsList_Mount(self, props)
    WowVision.UIHost:hookFunc(
        AuctionHouseFrame.AuctionsFrame.AllAuctionsList,
        "selectionCallback",
        AllAuctionsList_selectionCallback
    )
end

gen:Element("auction/AllAuctionsList", function(props)
    return {
        "ProxyScrollTable",
        frame = props.frame.ScrollBox,
        label = L["Auctions"],
        selectedElement = AllAuctionsList_selection,
        getButtonData = AllAuctionsList_getButtonData,
        headers = {
            { key = "sold", label = L["Sold"], flag = true },
            { key = "name" },
            { key = "quantity", label = L["Quantity"] },
            { key = "bidPrice", label = L["Bid Price"] },
            { key = "buyoutPrice", label = L["Buyout Price"] },
            { key = "timeLeft", label = L["Time Left"] },
        },
        hooks = {
            mount = AllAuctionsList_Mount,
        },
    }
end)

gen:Element("auction/AuctionsFrameBids", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/BidsList", frame = props.frame.BidsList },
            { "auction/BidFrame", frame = props.frame.BidFrame },
            { "auction/BuyoutFrame", frame = props.frame.BuyoutFrame },
        },
    }
end)

local BidsList_selection = nil

local function BidsList_selectionCallback(element)
    BidsList_selection = element
end

local function BidsList_Mount(self, props)
    WowVision.UIHost:hookFunc(AuctionHouseFrame.AuctionsFrame.BidsList, "selectionCallback", BidsList_selectionCallback)
end

local function BidsList_getButtonData(self, button)
    local rowData = button:GetRowData()
    local data = {}
    button:GetScript("OnEnter")(button)
    data.name = GameTooltip:GetItem()
    button:GetScript("OnLeave")(button)

    if rowData.bidAmount then
        data.bidAmount = C_CurrencyInfo.GetCoinText(rowData.bidAmount)
    end
    if rowData.minBid then
        data.minBid = C_CurrencyInfo.GetCoinText(rowData.minBid)
    end
    if rowData.timeLeft then
        data.timeLeft = getTimeLeftString(rowData.timeLeft)
    end
    return data
end

gen:Element("auction/BidsList", function(props)
    return {
        "ProxyScrollTable",
        frame = props.frame.ScrollBox,
        label = L["Bids"],
        getButtonData = BidsList_getButtonData,
        selectedElement = BidsList_selection,
        headers = {
            { key = "name" },
            { key = "bidder", label = L["Bidder"] },
            { key = "bidAmount", label = L["Bid Amount"] },
            { key = "minBid", label = L["Minimum Bid"] },
            { key = "timeLeft", label = L["Time Left"] },
        },
        hooks = {
            mount = BidsList_Mount,
        },
    }
end)

module:registerWindow({
    type = "EventWindow",
    name = "AuctionHouseFrame",
    generated = true,
    rootElement = "auction",
    openEvent = "AUCTION_HOUSE_SHOW",
    closeEvent = "AUCTION_HOUSE_CLOSED",
})
