local module = WowVision.base.windows:createModule("auction")
local L = module.L
module:setLabel(L["Auction House"])
local gen = module:hasUI()

-- Alert for item selection feedback
local selectAlert = module:addAlert({ key = "itemSelected", label = L["Item Selected"] })
selectAlert:addOutput({ type = "TTS", key = "tts", label = L["Item Selected"] })

-- Button counts per tab (matching Blizzard's fixed button arrays)
local NUM_BROWSE_BUTTONS = 8
local NUM_BID_BUTTONS = 9
local NUM_AUCTION_BUTTONS = 9

-- Utility: time left enum to string (TBC returns 1-4)
local function getTimeLeftString(timeLeft)
    if timeLeft == 1 then
        return L["Short"]
    elseif timeLeft == 2 then
        return L["Medium"]
    elseif timeLeft == 3 then
        return L["Long"]
    else
        return L["Very Long"]
    end
end

-- Utility: copper value to readable text
local function formatMoney(copper)
    if not copper or copper == 0 then
        return nil
    end
    return C_CurrencyInfo.GetCoinText(copper)
end

------------------------------------------------------------
-- AuctionSortButton element type
------------------------------------------------------------

local function getCurrentSort(sortTable)
    local column, reversed = GetAuctionSort(sortTable, 1)
    -- Normalize bid-related columns to "bid" for matching
    if column == "totalbuyout" or column == "unitbid" or column == "unitprice" then
        column = "bid"
    end
    return column, reversed -- reversed: true=descending, false=ascending
end

local AuctionSortButton, widgetParent = WowVision.ui:CreateElementType("AuctionSortButton", "Widget")

AuctionSortButton.info:addFields({
    { key = "sortTable", default = nil },
    { key = "sortColumn", default = nil },
    { key = "frame", default = nil, compareMode = "direct" },
})

AuctionSortButton.info:updateFields({
    { key = "displayType", default = "Sort Column" },
})

function AuctionSortButton:initialize()
    widgetParent.initialize(self)
    self._pendingDescending = nil
end

function AuctionSortButton:setupUniqueBindings()
    self:addBinding({
        binding = "leftClick",
        type = "Function",
        interruptSpeech = true,
        func = function()
            self:click()
        end,
    })
end

function AuctionSortButton:getLabel()
    if self.frame and self.frame.GetText then
        local text = self.frame:GetText()
        if text and text ~= "" then
            return text
        end
    end
    return self.label
end

function AuctionSortButton:onFocus()
    widgetParent.onFocus(self)
    local currentColumn, reversed = getCurrentSort(self.sortTable)
    if currentColumn == self.sortColumn then
        self._pendingDescending = reversed
    else
        self._pendingDescending = false
    end
end

function AuctionSortButton:onUnfocus()
    widgetParent.onUnfocus(self)
    self._pendingDescending = nil
end

function AuctionSortButton:getExtras()
    local extras = {}
    local directionStr
    if self._pendingDescending then
        directionStr = self.L["Descending"]
    else
        directionStr = self.L["Ascending"]
    end
    tinsert(extras, directionStr)
    local currentColumn = getCurrentSort(self.sortTable)
    if currentColumn == self.sortColumn then
        tinsert(extras, self.L["Active"])
    end
    return extras
end

function AuctionSortButton:onBindingPressed(binding)
    if binding.key == "up" then
        self._pendingDescending = false
        WowVision:speak(self.L["Ascending"])
        return true
    elseif binding.key == "down" then
        self._pendingDescending = true
        WowVision:speak(self.L["Descending"])
        return true
    end
    return false
end

function AuctionSortButton:onClick()
    AuctionFrame_SetSort(self.sortTable, self.sortColumn, self._pendingDescending)
    if self.sortTable == "list" then
        AuctionFrameBrowse_Search()
    else
        SortAuctionApplySort(self.sortTable)
    end
end

------------------------------------------------------------
-- Root element
------------------------------------------------------------

gen:Element("auction", function(props)
    local children = {
        { "auction/Tabs" },
    }
    if AuctionFrameBrowse:IsShown() then
        tinsert(children, { "auction/BrowseTab" })
    elseif AuctionFrameBid:IsShown() then
        tinsert(children, { "auction/BidsTab" })
    elseif AuctionFrameAuctions:IsShown() then
        tinsert(children, { "auction/AuctionsTab" })
    end
    tinsert(children, { "money/MoneyFrame", frame = AuctionFrameMoneyFrame, label = L["Your Gold"] })
    return {
        "Panel",
        label = L["Auction House"],
        wrap = true,
        children = children,
    }
end)

gen:Element("auction/Tabs", function(props)
    local result = {
        "List",
        label = L["Tabs"],
        direction = "horizontal",
        children = {},
    }
    for i = 1, 3 do
        local tab = _G["AuctionFrameTab" .. i]
        if tab and tab:IsShown() then
            local selected = PanelTemplates_GetSelectedTab(AuctionFrame) == i
            tinsert(result.children, {
                "ProxyButton",
                key = "tab_" .. i,
                frame = tab,
                selected = selected,
            })
        end
    end
    if #result.children == 0 then
        return nil
    end
    return result
end)

------------------------------------------------------------
-- Reusable: money input (Gold / Silver / Copper EditBoxes)
------------------------------------------------------------

gen:Element("auction/MoneyInput", function(props)
    local frame = props.frame
    if not frame or not frame:IsShown() then
        return nil
    end
    local goldBox = _G[frame:GetName() .. "Gold"]
    local silverBox = _G[frame:GetName() .. "Silver"]
    local copperBox = _G[frame:GetName() .. "Copper"]
    if not goldBox then
        return nil
    end
    return {
        "Panel",
        label = props.label,
        layout = true,
        children = {
            { "ProxyEditBox", frame = goldBox, label = L["Gold"] },
            { "ProxyEditBox", frame = silverBox, label = L["Silver"] },
            { "ProxyEditBox", frame = copperBox, label = L["Copper"] },
        },
    }
end)

------------------------------------------------------------
-- BROWSE TAB
------------------------------------------------------------

gen:Element("auction/BrowseTab", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/Categories" },
            { "auction/SearchFilters" },
            { "auction/BrowseSortHeaders" },
            { "auction/BrowsePriceOptions" },
            { "auction/BrowseResults" },
            { "auction/BrowsePageControls" },
            { "auction/BrowseActions" },
        },
    }
end)

-- Category filter buttons
gen:Element("auction/Categories", function(props)
    local children = {}
    for i = 1, 15 do
        local button = _G["AuctionFilterButton" .. i]
        if button and button:IsShown() then
            tinsert(children, { "ProxyButton", frame = button })
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Categories"], children = children }
end)

-- Search filters
gen:Element("auction/SearchFilters", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "ProxyEditBox", frame = BrowseName, label = L["Search"] },
            {
                "Button",
                label = L["Filters"],
                displayType = "Dropdown",
                events = {
                    click = function(event, button)
                        button.context:addGenerated({
                            "List",
                            layout = true,
                            label = L["Filters"],
                            children = {
                                { "ProxyEditBox", frame = BrowseMinLevel, autoInputOnFocus = false, hookEnter = true, label = L["Minimum Level"] },
                                { "ProxyEditBox", frame = BrowseMaxLevel, autoInputOnFocus = false, hookEnter = true, label = L["Maximum Level"] },
                                { "ProxyDropdownButton", frame = BrowseDropDown or BrowseDropdown },
                                { "ProxyCheckButton", frame = IsUsableCheckButton },
                                { "ProxyCheckButton", frame = ShowOnPlayerCheckButton },
                            },
                        })
                    end,
                },
            },
            { "ProxyButton", frame = BrowseSearchButton },
            { "ProxyButton", frame = BrowseResetButton },
        },
    }
end)

-- Browse sort headers
gen:Element("auction/BrowseSortHeaders", function(props)
    local children = {}
    local buttons = {
        { frame = BrowseQualitySort, column = "quality" },
        { frame = BrowseLevelSort, column = "level" },
        { frame = BrowseDurationSort, column = "duration" },
        { frame = BrowseHighBidderSort, column = "seller" },
        { frame = BrowseCurrentBidSort, column = "bid" },
    }
    for _, btn in ipairs(buttons) do
        if btn.frame and btn.frame:IsShown() then
            tinsert(children, { "AuctionSortButton", frame = btn.frame, sortTable = "list", sortColumn = btn.column })
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Sort"], direction = "horizontal", children = children }
end)

-- Browse price options (shown when price options frame is open)
gen:Element("auction/BrowsePriceOptions", function(props)
    if not BrowsePriceOptionsFrame:IsShown() then
        return nil
    end
    return {
        "List",
        label = L["Price Options"],
        children = {
            { "ProxyCheckButton", frame = SortByBidPriceButton },
            { "ProxyCheckButton", frame = SortByBuyoutPriceButton },
            { "ProxyCheckButton", frame = SortByTotalPriceButton },
            { "ProxyCheckButton", frame = SortByUnitPriceButton },
        },
    }
end)

-- Browse result list helpers
local function getBrowseButtons()
    local buttons = {}
    for i = 1, NUM_BROWSE_BUTTONS do
        local button = _G["BrowseButton" .. i]
        if button then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function getBrowseNumEntries()
    local numBatch = GetNumAuctionItems("list")
    return numBatch or 0
end

local hookedBrowseButtons = {}
local function hookBrowseButton(button)
    if hookedBrowseButtons[button] then return end
    hookedBrowseButtons[button] = true
    button:HookScript("OnClick", function()
        local selected = GetSelectedAuctionItem("list")
        if selected and selected > 0 then
            local name = GetAuctionItemInfo("list", selected)
            if name then
                selectAlert:fire({ text = L["Selected"] .. ": " .. name })
            end
        end
    end)
end

local function getBrowseElement(self, button)
    local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame) or 0
    local index = button:GetID() + offset
    local name, _, count, quality, canUse, level, levelColHeader,
        minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
        bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =
        GetAuctionItemInfo("list", index)
    if not name then
        return nil
    end

    hookBrowseButton(button)

    local label = name
    if count and count > 1 then
        label = label .. " x" .. count
    end
    if owner then
        label = label .. ", " .. L["Seller"] .. ": " .. owner
    end

    local currentBid = bidAmount and bidAmount > 0 and bidAmount or minBid
    local bidText = formatMoney(currentBid)
    if bidText then
        label = label .. ", " .. L["Current Bid"] .. ": " .. bidText
    end

    if buyoutPrice and buyoutPrice > 0 then
        label = label .. ", " .. L["Buyout"] .. ": " .. formatMoney(buyoutPrice)
    end

    local timeLeft = GetAuctionItemTimeLeft("list", index)
    if timeLeft then
        label = label .. ", " .. L["Time Left"] .. ": " .. getTimeLeftString(timeLeft)
    end

    return { "ProxyButton", frame = button, label = label }
end

local function getBrowseElementIndex(self, button)
    local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame) or 0
    return button:GetID() + offset
end

gen:Element("auction/BrowseResults", function(props)
    local numBatch = GetNumAuctionItems("list")
    if not numBatch or numBatch == 0 then
        return nil
    end

    if BrowseScrollFrame:IsShown() then
        return {
            "ProxyFauxScrollFrame",
            frame = BrowseScrollFrame,
            label = L["Results"],
            buttonHeight = AUCTIONS_BUTTON_HEIGHT or 37,
            updateFunction = AuctionFrameBrowse_Update,
            getNumEntries = getBrowseNumEntries,
            getElement = getBrowseElement,
            getElementIndex = getBrowseElementIndex,
            getButtons = getBrowseButtons,
        }
    end

    -- Scroll frame not shown, render visible buttons directly
    local children = {}
    for i = 1, NUM_BROWSE_BUTTONS do
        local button = _G["BrowseButton" .. i]
        if button and button:IsShown() then
            local element = getBrowseElement(nil, button)
            if element then
                tinsert(children, element)
            end
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Results"], children = children }
end)

-- Pagination
gen:Element("auction/BrowsePageControls", function(props)
    local children = {}
    if BrowsePrevPageButton:IsShown() and BrowsePrevPageButton:IsEnabled() then
        tinsert(children, { "ProxyButton", frame = BrowsePrevPageButton, label = L["Previous Page"] })
    end
    if BrowseNextPageButton:IsShown() and BrowseNextPageButton:IsEnabled() then
        tinsert(children, { "ProxyButton", frame = BrowseNextPageButton, label = L["Next Page"] })
    end
    if #children == 0 then
        return nil
    end
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = children,
    }
end)

-- Bid/buyout actions on selected browse item (only when an item is selected)
gen:Element("auction/BrowseActions", function(props)
    local selected = GetSelectedAuctionItem("list")
    if not selected or selected == 0 then
        return nil
    end
    local children = {
        { "auction/MoneyInput", frame = BrowseBidPrice, label = L["Bid Price"] },
    }
    if BrowseBuyoutPrice:IsShown() then
        tinsert(children, { "money/MoneyFrame", frame = BrowseBuyoutPrice, label = L["Buyout Price"] })
    end
    tinsert(children, { "ProxyButton", frame = BrowseBidButton })
    tinsert(children, { "ProxyButton", frame = BrowseBuyoutButton })
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = children,
    }
end)

------------------------------------------------------------
-- BIDS TAB
------------------------------------------------------------

gen:Element("auction/BidsTab", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/BidSortHeaders" },
            { "auction/BidResults" },
            { "auction/BidActions" },
        },
    }
end)

-- Bid sort headers
gen:Element("auction/BidSortHeaders", function(props)
    local children = {}
    local buttons = {
        { frame = BidQualitySort, column = "quality" },
        { frame = BidLevelSort, column = "level" },
        { frame = BidDurationSort, column = "duration" },
        { frame = BidBuyoutSort, column = "buyout" },
        { frame = BidStatusSort, column = "status" },
        { frame = BidBidSort, column = "bid" },
    }
    for _, btn in ipairs(buttons) do
        if btn.frame and btn.frame:IsShown() then
            tinsert(children, { "AuctionSortButton", frame = btn.frame, sortTable = "bidder", sortColumn = btn.column })
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Sort"], direction = "horizontal", children = children }
end)

-- Bid list helpers
local function getBidButtons()
    local buttons = {}
    for i = 1, NUM_BID_BUTTONS do
        local button = _G["BidButton" .. i]
        if button then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function getBidNumEntries()
    local numBatch = GetNumAuctionItems("bidder")
    return numBatch or 0
end

local function getBidElement(self, button)
    local offset = FauxScrollFrame_GetOffset(BidScrollFrame) or 0
    local index = button:GetID() + offset
    local name, _, count, quality, canUse, level, levelColHeader,
        minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
        bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =
        GetAuctionItemInfo("bidder", index)
    if not name then
        return nil
    end

    local label = name
    if count and count > 1 then
        label = label .. " x" .. count
    end

    local bidText = formatMoney(bidAmount and bidAmount > 0 and bidAmount or minBid)
    if bidText then
        label = label .. ", " .. L["Current Bid"] .. ": " .. bidText
    end

    if buyoutPrice and buyoutPrice > 0 then
        label = label .. ", " .. L["Buyout"] .. ": " .. formatMoney(buyoutPrice)
    end

    local timeLeft = GetAuctionItemTimeLeft("bidder", index)
    if timeLeft then
        label = label .. ", " .. L["Time Left"] .. ": " .. getTimeLeftString(timeLeft)
    end

    return { "ProxyButton", frame = button, label = label }
end

local function getBidElementIndex(self, button)
    local offset = FauxScrollFrame_GetOffset(BidScrollFrame) or 0
    return button:GetID() + offset
end

gen:Element("auction/BidResults", function(props)
    local numBatch = GetNumAuctionItems("bidder")
    if not numBatch or numBatch == 0 then
        return nil
    end

    if BidScrollFrame:IsShown() then
        return {
            "ProxyFauxScrollFrame",
            frame = BidScrollFrame,
            label = L["Bids"],
            buttonHeight = AUCTIONS_BUTTON_HEIGHT or 37,
            updateFunction = AuctionFrameBid_Update,
            getNumEntries = getBidNumEntries,
            getElement = getBidElement,
            getElementIndex = getBidElementIndex,
            getButtons = getBidButtons,
        }
    end

    local children = {}
    for i = 1, NUM_BID_BUTTONS do
        local button = _G["BidButton" .. i]
        if button and button:IsShown() then
            local element = getBidElement(nil, button)
            if element then
                tinsert(children, element)
            end
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Bids"], children = children }
end)

-- Bid actions (only when an item is selected)
gen:Element("auction/BidActions", function(props)
    local selected = GetSelectedAuctionItem("bidder")
    if not selected or selected == 0 then
        return nil
    end
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/MoneyInput", frame = BidBidPrice, label = L["Bid Price"] },
            { "ProxyButton", frame = BidBidButton },
            { "ProxyButton", frame = BidBuyoutButton },
        },
    }
end)

------------------------------------------------------------
-- AUCTIONS TAB
------------------------------------------------------------

gen:Element("auction/AuctionsTab", function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "auction/AuctionsSortHeaders" },
            { "auction/MyAuctionsList" },
            { "ProxyButton", frame = AuctionsCancelAuctionButton },
            { "auction/CreateAuction" },
        },
    }
end)

-- Auctions sort headers
gen:Element("auction/AuctionsSortHeaders", function(props)
    local children = {}
    local buttons = {
        { frame = AuctionsQualitySort, column = "quality" },
        { frame = AuctionsDurationSort, column = "duration" },
        { frame = AuctionsHighBidderSort, column = "status" },
        { frame = AuctionsBidSort, column = "bid" },
    }
    for _, btn in ipairs(buttons) do
        if btn.frame and btn.frame:IsShown() then
            tinsert(children, { "AuctionSortButton", frame = btn.frame, sortTable = "owner", sortColumn = btn.column })
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Sort"], direction = "horizontal", children = children }
end)

-- My auctions list helpers
local function getAuctionButtons()
    local buttons = {}
    for i = 1, NUM_AUCTION_BUTTONS do
        local button = _G["AuctionsButton" .. i]
        if button then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function getAuctionNumEntries()
    local numBatch = GetNumAuctionItems("owner")
    return numBatch or 0
end

local function getAuctionElement(self, button)
    local offset = FauxScrollFrame_GetOffset(AuctionsScrollFrame) or 0
    local index = button:GetID() + offset
    local name, _, count, quality, canUse, level, levelColHeader,
        minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
        bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =
        GetAuctionItemInfo("owner", index)
    if not name then
        return nil
    end

    local label = name
    if count and count > 1 then
        label = label .. " x" .. count
    end

    if saleStatus == 1 then
        label = "[" .. L["Sold"] .. "] " .. label
    end

    local bidText = formatMoney(bidAmount and bidAmount > 0 and bidAmount or minBid)
    if bidText then
        label = label .. ", " .. L["Current Bid"] .. ": " .. bidText
    end

    if buyoutPrice and buyoutPrice > 0 then
        label = label .. ", " .. L["Buyout"] .. ": " .. formatMoney(buyoutPrice)
    end

    if highBidder then
        label = label .. ", " .. L["Bidder"] .. ": " .. highBidder
    end

    local timeLeft = GetAuctionItemTimeLeft("owner", index)
    if timeLeft then
        label = label .. ", " .. L["Time Left"] .. ": " .. getTimeLeftString(timeLeft)
    end

    return { "ProxyButton", frame = button, label = label }
end

local function getAuctionElementIndex(self, button)
    local offset = FauxScrollFrame_GetOffset(AuctionsScrollFrame) or 0
    return button:GetID() + offset
end

gen:Element("auction/MyAuctionsList", function(props)
    local numBatch = GetNumAuctionItems("owner")
    if not numBatch or numBatch == 0 then
        return nil
    end

    if AuctionsScrollFrame:IsShown() then
        return {
            "ProxyFauxScrollFrame",
            frame = AuctionsScrollFrame,
            label = L["Auctions"],
            buttonHeight = AUCTIONS_BUTTON_HEIGHT or 37,
            updateFunction = AuctionFrameAuctions_Update,
            getNumEntries = getAuctionNumEntries,
            getElement = getAuctionElement,
            getElementIndex = getAuctionElementIndex,
            getButtons = getAuctionButtons,
        }
    end

    local children = {}
    for i = 1, NUM_AUCTION_BUTTONS do
        local button = _G["AuctionsButton" .. i]
        if button and button:IsShown() then
            local element = getAuctionElement(nil, button)
            if element then
                tinsert(children, element)
            end
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Auctions"], children = children }
end)

-- Create auction form
gen:Element("auction/CreateAuction", function(props)
    local children = {}

    -- Item placement button (shows item name + stack size being sold)
    local itemLabel = L["Place Item Here"]
    local sellName, sellTexture, sellCount = GetAuctionSellItemInfo()
    if sellName then
        local stackSize = tonumber(AuctionsStackSizeEntry:GetText()) or sellCount
        itemLabel = sellName
        if stackSize and stackSize > 1 then
            itemLabel = itemLabel .. " x" .. stackSize
        end
    end
    tinsert(children, { "ProxyButton", frame = AuctionsItemButton, label = itemLabel })

    -- Stack size and number of stacks (Blizzard hides these in TBC Anniversary
    -- but the backend logic still populates them; force-show so they can receive focus)
    if sellName then
        AuctionsStackSizeEntry:Show()
        AuctionsStackSizeMaxButton:Show()
        AuctionsNumStacksEntry:Show()
        AuctionsNumStacksMaxButton:Show()
        tinsert(children, { "ProxyEditBox", frame = AuctionsStackSizeEntry, label = L["Stack Size"] })
        tinsert(children, { "ProxyButton", frame = AuctionsStackSizeMaxButton })
        tinsert(children, { "ProxyEditBox", frame = AuctionsNumStacksEntry, label = L["Number of Stacks"] })
        tinsert(children, { "ProxyButton", frame = AuctionsNumStacksMaxButton })
    end

    -- Starting price
    tinsert(children, { "auction/MoneyInput", frame = StartPrice, label = L["Starting Price"] })

    -- Duration radio buttons
    tinsert(children, {
        "List",
        label = L["Duration"],
        children = {
            { "ProxyCheckButton", frame = AuctionsShortAuctionButton, label = L["12 Hours"] },
            { "ProxyCheckButton", frame = AuctionsMediumAuctionButton, label = L["24 Hours"] },
            { "ProxyCheckButton", frame = AuctionsLongAuctionButton, label = L["48 Hours"] },
        },
    })

    -- Buyout price
    tinsert(children, { "auction/MoneyInput", frame = BuyoutPrice, label = L["Buyout Price"] })

    -- Deposit (shown when an item is placed)
    if sellName then
        tinsert(children, { "money/MoneyFrame", frame = AuctionsDepositMoneyFrame, label = L["Deposit"] })
    end

    -- Create auction button
    tinsert(children, { "ProxyButton", frame = AuctionsCreateAuctionButton })

    return {
        "Panel",
        label = L["Create Auction"],
        layout = true,
        children = children,
    }
end)

------------------------------------------------------------
-- Window registration
------------------------------------------------------------

module:registerWindow({
    type = "FrameWindow",
    name = "auction",
    generated = true,
    rootElement = "auction",
    frameName = "AuctionFrame",
    hookEscape = true,
})
