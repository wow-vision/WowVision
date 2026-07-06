local module = WowVision.base.windows:createModule("auction")
local L = module.L
module:setLabel(L["Auction House"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- Tooltip type for auction items: populates GameTooltip via SetAuctionItem.
local AuctionItemTooltipType = WowVision.tooltips:createType("AuctionItem")

function AuctionItemTooltipType:initialize(tooltip)
    WowVision.TooltipType.initialize(self, tooltip)
end

function AuctionItemTooltipType:activate(widget, data)
    self.tooltip.activeFrame = GameTooltip
    self.listType = data.listType
    self.index = data.index
    self.link = data.link
end

function AuctionItemTooltipType:deactivate()
    self.listType = nil
    self.index = nil
    self.link = nil
end

function AuctionItemTooltipType:beforeRead()
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    if self.link then
        GameTooltip:SetHyperlink(self.link)
    else
        GameTooltip:SetAuctionItem(self.listType, self.index)
    end
end

function AuctionItemTooltipType:afterRead()
    GameTooltip:Hide()
end

-- Alert for item selection feedback
local selectAlert = module:addAlert({ key = "itemSelected", label = L["Item Selected"] })
selectAlert:addOutput({ type = "TTS", key = "tts", label = L["Item Selected"] })

-- Client-side filter: hide browse results below this stack size
local minStackSize = 0

-- Forward declaration: selectBrowseItem is defined further down but the session
-- closure captures the upvalue, so Lua reads the current value at call time.
local selectBrowseItem

local session = WowVision.tbcAH.ScanSession:new({
    selectItem = function(idx) selectBrowseItem(idx) end,
    isFullScanning = WowVision.ahPrices.isFullScanning,
    L = L,
})

hooksecurefunc("QueryAuctionItems", function(name, minLevel, maxLevel, page, usable, rarity, getAll, exactMatch, filterData)
    session:captureQuery({
        name = name,
        minLevel = minLevel,
        maxLevel = maxLevel,
        usable = usable,
        rarity = rarity,
        getAll = getAll,
        exactMatch = exactMatch,
        filterData = filterData,
    })
end)

-- Full AH scanner integration (price database)
local ahPrices = WowVision.ahPrices

local function formatCooldownTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    if mins > 0 and secs > 0 then
        return mins .. " min " .. secs .. " sec"
    elseif mins > 0 then
        return mins .. " min"
    else
        return secs .. " sec"
    end
end

local function fullScanScanningLabel()
    local state = ahPrices.getFullScanState()
    if state == "waiting" then
        return L["Scanning"] .. ", " .. math.floor(ahPrices.getFullScanWaitElapsed()) .. " sec"
    elseif state == "processing" then
        local p = ahPrices.getFullScanProgress()
        if p.total > 0 then
            return L["Scanning"] .. ", " .. math.floor(p.processed * 100 / p.total) .. "%"
        end
    end
    return L["Scanning"]
end

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

-- Normalize GetAuctionItemInfo into a flat table with only the fields we label with.
-- Scan results already come in this shape, so formatItemLabel accepts both.
local function readAuctionItem(listType, index)
    local name, _, count, _, _, _, _,
        minBid, _, buyoutPrice, bidAmount, highBidder,
        _, owner, _, saleStatus = GetAuctionItemInfo(listType, index)
    if not name then return nil end
    return {
        name = name,
        count = count,
        minBid = minBid,
        buyoutPrice = buyoutPrice,
        bidAmount = bidAmount,
        highBidder = highBidder,
        owner = owner,
        saleStatus = saleStatus,
        timeLeft = GetAuctionItemTimeLeft(listType, index),
    }
end

-- Build a display label for an auction item (browse/bid/owner/scan-result).
-- opts: { showSeller, showBidder, showSold }
local function formatItemLabel(item, opts)
    opts = opts or {}
    local label = item.name
    if item.count and item.count > 1 then
        label = label .. " x" .. item.count
    end
    if opts.showSold and item.saleStatus == 1 then
        label = "[" .. L["Sold"] .. "] " .. label
    end
    if opts.showSeller and item.owner then
        label = label .. ", " .. L["Seller"] .. ": " .. item.owner
    end
    if item.buyoutPrice and item.buyoutPrice > 0 then
        label = label .. ", " .. L["Buyout"] .. ": " .. formatMoney(item.buyoutPrice)
    end
    local currentBid = item.bidAmount and item.bidAmount > 0 and item.bidAmount or item.minBid
    local bidText = formatMoney(currentBid)
    if bidText then
        label = label .. ", " .. L["Current Bid"] .. ": " .. bidText
    end
    if opts.showBidder and item.highBidder then
        label = label .. ", " .. L["Bidder"] .. ": " .. item.highBidder
    end
    if item.timeLeft then
        label = label .. ", " .. L["Time Left"] .. ": " .. getTimeLeftString(item.timeLeft)
    end
    return label
end

------------------------------------------------------------
-- Shared graph helpers
------------------------------------------------------------

-- HookScript each frame at most once. We touch category/browse buttons repeatedly
-- during rebuilds; without this, we'd stack duplicate handlers every tick.
local hookedFrames = setmetatable({}, { __mode = "k" })
local function hookOnce(frame, script, handler)
    local key = hookedFrames[frame]
    if not key then
        key = {}
        hookedFrames[frame] = key
    end
    if key[script] then return end
    key[script] = true
    frame:HookScript(script, handler)
end

local function actionStop(builder, stopKey, button, label)
    if button == nil or not button:IsShown() then
        return
    end
    builder:beginStop(stopKey)
    builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button, label = label }))
end

local function syntheticStop(builder, stopKey, config)
    builder:beginStop(stopKey)
    builder:addItem(ControlId.structural(stopKey), nodes.button(config))
end

local function liveTextStop(builder, stopKey, label)
    builder:beginStop(stopKey)
    builder:addItem(ControlId.structural(stopKey), nodes.text({ label = label }))
end

-- A Blizzard MoneyFrame display (deposit, buyout price of the selection).
local function moneyFrameText(frame, label)
    return function()
        local amount = frame ~= nil and (frame.staticMoney or 0) or 0
        return (label or "") .. " " .. (formatMoney(amount) or "0")
    end
end

-- Money input: named Gold/Silver/Copper edit boxes as separate stops under a
-- labeled context (an edit box cannot share a stop with anything after it).
local function moneyInputStops(builder, keyPrefix, contextLabel, frame)
    if frame == nil or not frame:IsShown() then
        return
    end
    local goldBox = _G[frame:GetName() .. "Gold"]
    local silverBox = _G[frame:GetName() .. "Silver"]
    local copperBox = _G[frame:GetName() .. "Copper"]
    if goldBox == nil then
        return
    end
    builder:pushContext(keyPrefix, contextLabel)
    builder:beginStop(keyPrefix .. ":gold")
    builder:addItem(
        ControlId.structural(keyPrefix .. ":gold"),
        nodes.proxyEditBox({ editBox = goldBox, label = L["Gold"] })
    )
    if silverBox ~= nil then
        builder:beginStop(keyPrefix .. ":silver")
        builder:addItem(
            ControlId.structural(keyPrefix .. ":silver"),
            nodes.proxyEditBox({ editBox = silverBox, label = L["Silver"] })
        )
    end
    if copperBox ~= nil then
        builder:beginStop(keyPrefix .. ":copper")
        builder:addItem(
            ControlId.structural(keyPrefix .. ":copper"),
            nodes.proxyEditBox({ editBox = copperBox, label = L["Copper"] })
        )
    end
    builder:popContext()
end

------------------------------------------------------------
-- Sort headers: up/down pick the direction, Enter applies the sort.
------------------------------------------------------------

local function getCurrentSort(sortTable)
    local column, reversed = GetAuctionSort(sortTable, 1)
    -- Normalize bid-related columns to "bid" for matching
    if column == "totalbuyout" or column == "unitbid" or column == "unitprice" then
        column = "bid"
    end
    return column, reversed -- reversed: true=descending, false=ascending
end

local function sortHeaderNode(screen, sortTable, column, frame)
    local stateKey = sortTable .. ":" .. column
    screen._sortPending = screen._sortPending or {}
    local pending = screen._sortPending

    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    local text = frame.GetText ~= nil and frame:GetText() or nil
                    return text ~= nil and text ~= "" and text or column
                end,
                kind = kinds.label,
            },
            {
                text = function()
                    return pending[stateKey] and L["Descending"] or L["Ascending"]
                end,
                kind = kinds.value,
            },
            {
                text = function()
                    local currentColumn = getCurrentSort(sortTable)
                    if currentColumn == column then
                        return L["Active"]
                    end
                    return nil
                end,
                kind = kinds.selected,
            },
        },
        onFocus = function()
            local currentColumn, reversed = getCurrentSort(sortTable)
            if currentColumn == column then
                pending[stateKey] = reversed and true or false
            else
                pending[stateKey] = false
            end
        end,
        onActivate = function()
            AuctionFrame_SetSort(sortTable, column, pending[stateKey] and true or false)
            if sortTable == "list" then
                AuctionFrameBrowse_Search()
            else
                SortAuctionApplySort(sortTable)
            end
        end,
        bindings = {
            {
                binding = "up",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    pending[stateKey] = false
                    WowVision:speak(L["Ascending"])
                end,
            },
            {
                binding = "down",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    pending[stateKey] = true
                    WowVision:speak(L["Descending"])
                end,
            },
        },
    }
end

local function sortHeadersStop(builder, screen, stopKey, sortTable, buttons)
    local shown = {}
    for _, btn in ipairs(buttons) do
        if btn.frame ~= nil and btn.frame:IsShown() then
            tinsert(shown, btn)
        end
    end
    if #shown == 0 then
        return
    end
    builder:beginStop(stopKey)
    builder:pushContext(stopKey, L["Sort"])
    builder:startRow()
    for _, btn in ipairs(shown) do
        builder:addItem(
            ControlId.structural("sort:" .. sortTable .. ":" .. btn.column),
            sortHeaderNode(screen, sortTable, btn.column, btn.frame)
        )
    end
    builder:endRow()
    builder:popContext()
end

------------------------------------------------------------
-- Results lists (Faux pools with pool-relative ids)
------------------------------------------------------------

local function resultsList(builder, screen, config)
    local count = GetNumAuctionItems(config.listType) or 0
    builder:beginStop(config.stopKey)
    nodes.hybridScrollList(builder, {
        scrollFrame = _G[config.scrollFrameName],
        key = config.stopKey,
        label = config.label,
        count = function()
            return GetNumAuctionItems(config.listType) or 0
        end,
        rowHeight = AUCTIONS_BUTTON_HEIGHT or 37,
        buttons = function()
            local buttons = {}
            for i = 1, config.numButtons do
                local button = _G[config.buttonPrefix .. i]
                if button ~= nil then
                    tinsert(buttons, button)
                end
            end
            return buttons
        end,
        indexOf = function(button)
            return button:GetID() + (FauxScrollFrame_GetOffset(_G[config.scrollFrameName]) or 0)
        end,
        emit = function(innerBuilder, index, helpers)
            local capturedIndex = index
            local vtable = {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            local item = readAuctionItem(config.listType, capturedIndex)
                            return item ~= nil and formatItemLabel(item, config.labelOpts) or nil
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            if GetSelectedAuctionItem(config.listType) == capturedIndex then
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
                tooltip = { type = "AuctionItem", listType = config.listType, index = capturedIndex },
            }
            if config.onEmitRow ~= nil then
                config.onEmitRow(helpers)
            end
            innerBuilder:addItem(helpers.id, vtable)
        end,
    })
end

------------------------------------------------------------
-- BROWSE TAB
------------------------------------------------------------

-- Category filter buttons — hook each to auto-search on click
local function hookFilterButton(button)
    hookOnce(button, "OnClick", function()
        AuctionFrameBrowse_Search()
    end)
end

-- Browse rows announce the selection through the alert on click.
local function hookBrowseButton(button)
    hookOnce(button, "OnClick", function()
        local selected = GetSelectedAuctionItem("list")
        if selected and selected > 0 then
            local name = GetAuctionItemInfo("list", selected)
            if name then
                selectAlert:fire({ text = L["Selected"] .. ": " .. name })
            end
        end
    end)
end

-- Select a browse item by its 1-based index in the auction list.
-- Scrolls Blizzard's FauxScrollFrame to make the item visible, then clicks it.
function selectBrowseItem(realIndex)
    local total = GetNumAuctionItems("list") or 0
    local maxOffset = math.max(0, total - NUM_BROWSE_BUTTONS)
    local targetOffset = math.min(math.max(0, realIndex - 1), maxOffset)
    FauxScrollFrame_SetOffset(BrowseScrollFrame, targetOffset)
    AuctionFrameBrowse_Update()
    local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame) or 0
    for i = 1, NUM_BROWSE_BUTTONS do
        local button = _G["BrowseButton" .. i]
        if button and button:GetID() + offset == realIndex then
            hookBrowseButton(button)
            button:Click()
            break
        end
    end
end

-- Build a filter closure from the current minStackSize setting.
local function buildStackFilter()
    if minStackSize <= 1 then return nil end
    local threshold = minStackSize
    return function(name, texture, count)
        return (count or 0) >= threshold
    end
end

local MAX_FILTERED_BROWSE = 10000 -- ~200 pages, safety cap against getAll data in list

-- Current-page browse results filtered by minStackSize, as synthetic rows.
local function renderFilteredBrowseList(builder)
    local numBatch = GetNumAuctionItems("list") or 0
    builder:beginStop("filteredResults")
    builder:pushContext("filteredResults", L["Results"])
    local emitted = 0
    if numBatch > 0 and numBatch <= MAX_FILTERED_BROWSE then
        for i = 1, numBatch do
            local item = readAuctionItem("list", i)
            if item and (item.count or 0) >= minStackSize then
                local realIndex = i
                builder:addItem(ControlId.structural("filtered:" .. realIndex), {
                    controlType = graph.controlTypes.button,
                    announcements = {
                        {
                            text = function()
                                local current = readAuctionItem("list", realIndex)
                                return current ~= nil and formatItemLabel(current, { showSeller = true }) or nil
                            end,
                            kind = kinds.label,
                        },
                    },
                    onActivate = function()
                        selectBrowseItem(realIndex)
                    end,
                    tooltip = { type = "AuctionItem", listType = "list", index = realIndex },
                })
                emitted = emitted + 1
            end
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("filteredEmpty"), nodes.text({ label = L["No Results"] }))
    end
    builder:popContext()
end

-- The session's scan results as synthetic rows.
local function renderScanResultsList(builder)
    local results = session:getResults()
    builder:beginStop("scanResults")
    builder:pushContext("scanResults", L["Scan Results"])
    if results == nil or #results == 0 then
        builder:addItem(ControlId.structural("scanEmpty"), nodes.text({ label = L["No Results"] }))
    else
        for i, item in ipairs(results) do
            local capturedItem = item
            builder:addItem(ControlId.structural("scan:" .. i), {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return formatItemLabel(capturedItem, { showSeller = true })
                        end,
                        kind = kinds.label,
                    },
                },
                onActivate = function()
                    session:selectResult(capturedItem)
                end,
                tooltip = capturedItem.link and { type = "AuctionItem", link = capturedItem.link } or nil,
            })
        end
    end
    builder:popContext()
end

local function renderBrowseResults(builder, screen)
    -- Show abort button during scan
    if session:isScanning() then
        syntheticStop(builder, "abortScan", {
            label = function()
                local progress = session:getScanProgress()
                return L["Abort Scan"] .. " (" .. progress.page .. "/" .. progress.totalPages .. ")"
            end,
            onActivate = function()
                session:abort()
            end,
        })
        return
    end

    -- Viewing a single item from scan results — hide the full browse list.
    -- Browse actions handle bid/buyout controls for the selected item.
    if session:isViewingItem() then
        return
    end

    if session:hasResults() then
        renderScanResultsList(builder)
        return
    end

    if minStackSize > 1 then
        renderFilteredBrowseList(builder)
        return
    end

    resultsList(builder, screen, {
        stopKey = "results",
        label = L["Results"],
        listType = "list",
        buttonPrefix = "BrowseButton",
        numButtons = NUM_BROWSE_BUTTONS,
        scrollFrameName = "BrowseScrollFrame",
        labelOpts = { showSeller = true },
        onEmitRow = function(helpers)
            local row = helpers.target()
            if row ~= nil then
                hookBrowseButton(row)
            end
        end,
    })
end

local function renderBrowsePageControls(builder)
    -- When viewing scan results, replace Blizzard pagination with "Load More"
    if session:hasResults() and not session:isViewingItem() and not session:isScanning() then
        if session:canLoadMore() then
            syntheticStop(builder, "loadMore", {
                label = L["Load More"],
                onActivate = function()
                    local results = session:getResults()
                    session:startScan({
                        append = true,
                        startPage = results.lastPage + 1,
                        filter = buildStackFilter(),
                    })
                end,
            })
        end
        return
    end

    -- Filtered browse without scan results yet: offer Scan instead of paging
    if minStackSize > 1 and not session:hasResults() and not session:isScanning() then
        local _, totalAuctions = GetNumAuctionItems("list")
        if (totalAuctions or 0) > 0 then
            syntheticStop(builder, "scan", {
                label = L["Scan"],
                onActivate = function()
                    session:startScan({ filter = buildStackFilter() })
                end,
            })
        end
        return
    end

    -- Normal Blizzard page controls
    if BrowsePrevPageButton:IsShown() and BrowsePrevPageButton:IsEnabled() then
        actionStop(builder, "prevPage", BrowsePrevPageButton, L["Previous Page"])
    end
    if BrowseNextPageButton:IsShown() and BrowseNextPageButton:IsEnabled() then
        actionStop(builder, "nextPage", BrowseNextPageButton, L["Next Page"])
    end
end

local function renderBrowseActions(builder)
    local selected = GetSelectedAuctionItem("list")
    if not selected or selected == 0 then
        -- If we came from scan results but nothing is selected (e.g. after
        -- buying), offer to go back to the list
        if session:isViewingItem() then
            syntheticStop(builder, "backToResults", {
                label = L["Scan Results"],
                onActivate = function()
                    session:returnToResults()
                end,
            })
        end
        return
    end

    if BrowseBuyoutPrice:IsShown() then
        liveTextStop(builder, "buyoutPrice", moneyFrameText(BrowseBuyoutPrice, L["Buyout Price"]))
        actionStop(builder, "buyoutButton", BrowseBuyoutButton)
    end
    moneyInputStops(builder, "browseBid", L["Bid Price"], BrowseBidPrice)
    actionStop(builder, "bidButton", BrowseBidButton)
    if session:isViewingItem() then
        syntheticStop(builder, "backToResults", {
            label = L["Scan Results"],
            onActivate = function()
                session:returnToResults()
            end,
        })
    end
end

-- The Filters push screen (min stack size plus Blizzard's filter widgets).
local function pushFiltersScreen()
    graph.settings.pushScreen("auctionFilters", function(builder)
        builder:pushContext("filters", L["Filters"])
        builder:beginStop("minStack")
        builder:addItem(
            ControlId.structural("minStack"),
            nodes.textInput({
                label = L["Min Stack Size"],
                get = function()
                    return minStackSize > 0 and minStackSize or nil
                end,
                set = function(value)
                    minStackSize = tonumber(value) or 0
                end,
            })
        )
        builder:beginStop("minLevel")
        builder:addItem(
            ControlId.structural("minLevel"),
            nodes.proxyEditBox({ editBox = BrowseMinLevel, label = L["Minimum Level"] })
        )
        builder:beginStop("maxLevel")
        builder:addItem(
            ControlId.structural("maxLevel"),
            nodes.proxyEditBox({ editBox = BrowseMaxLevel, label = L["Maximum Level"] })
        )
        local dropdown = BrowseDropDown or BrowseDropdown
        if dropdown ~= nil then
            builder:beginStop("rarity")
            builder:addItem(ControlId.forObject(dropdown), nodes.proxyDropdown({ target = dropdown }))
        end
        if IsUsableCheckButton ~= nil then
            builder:beginStop("usable")
            builder:addItem(
                ControlId.forObject(IsUsableCheckButton),
                nodes.proxyCheckButton({ target = IsUsableCheckButton })
            )
        end
        if ShowOnPlayerCheckButton ~= nil then
            builder:beginStop("showOnPlayer")
            builder:addItem(
                ControlId.forObject(ShowOnPlayerCheckButton),
                nodes.proxyCheckButton({ target = ShowOnPlayerCheckButton })
            )
        end
        builder:popContext()
    end)
end

local function renderBrowseTab(builder, screen)
    builder:beginStop("categories")
    builder:pushContext("categories", L["Categories"])
    local emitted = 0
    for i = 1, 15 do
        local button = _G["AuctionFilterButton" .. i]
        if button ~= nil and button:IsShown() then
            hookFilterButton(button)
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
            emitted = emitted + 1
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("categoriesEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    builder:beginStop("search")
    builder:addItem(ControlId.structural("search"), nodes.proxyEditBox({ editBox = BrowseName, label = L["Search"] }))

    renderBrowseResults(builder, screen)
    renderBrowsePageControls(builder)
    renderBrowseActions(builder)

    sortHeadersStop(builder, screen, "browseSort", "list", {
        { frame = BrowseQualitySort, column = "quality" },
        { frame = BrowseLevelSort, column = "level" },
        { frame = BrowseDurationSort, column = "duration" },
        { frame = BrowseHighBidderSort, column = "seller" },
        { frame = BrowseCurrentBidSort, column = "bid" },
    })

    if BrowsePriceOptionsFrame ~= nil and BrowsePriceOptionsFrame:IsShown() then
        builder:beginStop("priceOptions")
        builder:pushContext("priceOptions", L["Price Options"])
        for _, button in ipairs({
            SortByBidPriceButton,
            SortByBuyoutPriceButton,
            SortByTotalPriceButton,
            SortByUnitPriceButton,
        }) do
            if button ~= nil and button:IsShown() then
                builder:addItem(ControlId.forObject(button), nodes.proxyCheckButton({ target = button }))
            end
        end
        builder:popContext()
    end

    syntheticStop(builder, "filters", {
        label = L["Filters"],
        onActivate = pushFiltersScreen,
    })
    actionStop(builder, "searchButton", BrowseSearchButton)

    -- Full scan (price database): label and action follow the scanner state.
    syntheticStop(builder, "fullScan", {
        label = function()
            if ahPrices.isFullScanning() then
                return fullScanScanningLabel()
            end
            if ahPrices.canFullScan() then
                return L["Full Scan"]
            end
            return L["Full Scan"] .. ", " .. L["Cooldown active"]
        end,
        onActivate = function()
            if ahPrices.isFullScanning() then
                ahPrices.abortFullScan()
            elseif ahPrices.canFullScan() then
                ahPrices.startFullScan()
            else
                WowVision:speak(formatCooldownTime(ahPrices.getFullScanCooldownRemaining()))
            end
        end,
    })
    actionStop(builder, "resetButton", BrowseResetButton)
end

------------------------------------------------------------
-- BIDS TAB
------------------------------------------------------------

local function renderBidsTab(builder, screen)
    sortHeadersStop(builder, screen, "bidSort", "bidder", {
        { frame = BidQualitySort, column = "quality" },
        { frame = BidLevelSort, column = "level" },
        { frame = BidDurationSort, column = "duration" },
        { frame = BidBuyoutSort, column = "buyout" },
        { frame = BidStatusSort, column = "status" },
        { frame = BidBidSort, column = "bid" },
    })

    if (GetNumAuctionItems("bidder") or 0) == 0 then
        liveTextStop(builder, "noBids", L["No Bids"])
    else
        resultsList(builder, screen, {
            stopKey = "bids",
            label = L["Bids"],
            listType = "bidder",
            buttonPrefix = "BidButton",
            numButtons = NUM_BID_BUTTONS,
            scrollFrameName = "BidScrollFrame",
        })
    end

    local selected = GetSelectedAuctionItem("bidder")
    if selected ~= nil and selected ~= 0 then
        moneyInputStops(builder, "rebid", L["Bid Price"], BidBidPrice)
        actionStop(builder, "rebidButton", BidBidButton)
        actionStop(builder, "bidBuyoutButton", BidBuyoutButton)
    end
end

------------------------------------------------------------
-- AUCTIONS TAB
------------------------------------------------------------

local function renderCreateAuction(builder)
    builder:pushContext("createAuction", L["Create Auction"])
    local sellName = GetAuctionSellItemInfo()

    -- Stack size and number of stacks (Blizzard hides these in TBC Anniversary
    -- but the backend logic still populates them; force-show so they can
    -- receive focus)
    if sellName then
        AuctionsStackSizeEntry:Show()
        AuctionsStackSizeMaxButton:Show()
        AuctionsNumStacksEntry:Show()
        AuctionsNumStacksMaxButton:Show()
        builder:beginStop("stackSize")
        builder:addItem(
            ControlId.structural("stackSize"),
            nodes.proxyEditBox({ editBox = AuctionsStackSizeEntry, label = L["Stack Size"] })
        )
        actionStop(builder, "stackSizeMax", AuctionsStackSizeMaxButton)
        builder:beginStop("numStacks")
        builder:addItem(
            ControlId.structural("numStacks"),
            nodes.proxyEditBox({ editBox = AuctionsNumStacksEntry, label = L["Number of Stacks"] })
        )
        actionStop(builder, "numStacksMax", AuctionsNumStacksMaxButton)
    end

    moneyInputStops(builder, "buyout", L["Buyout Price"], BuyoutPrice)

    -- Starting price behind a push screen, as before.
    syntheticStop(builder, "startingBid", {
        label = L["Starting Bid"],
        onActivate = function()
            graph.settings.pushScreen("auctionStartingBid", function(innerBuilder)
                innerBuilder:pushContext("startingBid", L["Starting Bid"])
                moneyInputStops(innerBuilder, "startPrice", L["Starting Bid"], StartPrice)
                innerBuilder:popContext()
            end)
        end,
    })

    builder:beginStop("duration")
    builder:pushContext("duration", L["Duration"])
    local durations = {
        { frame = AuctionsShortAuctionButton, label = L["12 Hours"] },
        { frame = AuctionsMediumAuctionButton, label = L["24 Hours"] },
        { frame = AuctionsLongAuctionButton, label = L["48 Hours"] },
    }
    for _, duration in ipairs(durations) do
        if duration.frame ~= nil then
            builder:addItem(
                ControlId.forObject(duration.frame),
                nodes.proxyCheckButton({ target = duration.frame, label = duration.label })
            )
        end
    end
    builder:popContext()

    if sellName then
        liveTextStop(builder, "deposit", moneyFrameText(AuctionsDepositMoneyFrame, L["Deposit"]))
    end

    actionStop(builder, "createAuction", AuctionsCreateAuctionButton)
    builder:popContext()
end

local function renderAuctionsTab(builder, screen)
    builder:beginStop("sellItem")
    builder:addItem(
        ControlId.forObject(AuctionsItemButton),
        nodes.proxyButton({
            target = AuctionsItemButton,
            label = function()
                local sellName, _, sellCount = GetAuctionSellItemInfo()
                if sellName then
                    local stackSize = tonumber(AuctionsStackSizeEntry:GetText()) or sellCount
                    if stackSize and stackSize > 1 then
                        return sellName .. " x" .. stackSize
                    end
                    return sellName
                end
                return L["Place Item Here"]
            end,
        })
    )

    renderCreateAuction(builder)

    resultsList(builder, screen, {
        stopKey = "myAuctions",
        label = L["Auctions"],
        listType = "owner",
        buttonPrefix = "AuctionsButton",
        numButtons = NUM_AUCTION_BUTTONS,
        scrollFrameName = "AuctionsScrollFrame",
        labelOpts = { showBidder = true, showSold = true },
    })

    if AuctionsCancelAuctionButton:IsEnabled() then
        actionStop(builder, "cancelAuction", AuctionsCancelAuctionButton)
    end

    sortHeadersStop(builder, screen, "auctionsSort", "owner", {
        { frame = AuctionsQualitySort, column = "quality" },
        { frame = AuctionsDurationSort, column = "duration" },
        { frame = AuctionsHighBidderSort, column = "status" },
        { frame = AuctionsBidSort, column = "bid" },
    })
end

------------------------------------------------------------
-- Root render
------------------------------------------------------------

local function render(builder, screen)
    if AuctionFrame == nil or not AuctionFrame:IsShown() then
        return
    end
    builder:pushContext("auction", L["Auction House"])

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, 3 do
        local tab = _G["AuctionFrameTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        if PanelTemplates_GetSelectedTab(AuctionFrame) == tabIndex then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                })
                builder:addItem(ControlId.forObject(tab), vtable)
            end
        end
    end
    builder:endRow()
    builder:popContext()

    if AuctionFrameBrowse:IsShown() then
        renderBrowseTab(builder, screen)
    elseif AuctionFrameBid:IsShown() then
        renderBidsTab(builder, screen)
    elseif AuctionFrameAuctions:IsShown() then
        renderAuctionsTab(builder, screen)
    end

    builder:popContext()
end

------------------------------------------------------------
-- Enrich auction confirmation popups with item name + count.
-- Uses hooksecurefunc (post-hook) so we never replace the
-- original function.  We modify the text FontString on the
-- popup frame instance, not the shared StaticPopupDialogs
-- template, so other addons and non-auction popups are
-- unaffected.
------------------------------------------------------------

local AUCTION_POPUP_TYPES = {
    BID_AUCTION = true,
    BUYOUT_AUCTION = true,
    CANCEL_AUCTION = true,
}

local function getAuctionPopupItemSuffix(which)
    local name, count
    if which == "BID_AUCTION" or which == "BUYOUT_AUCTION" then
        for _, lt in ipairs({ "list", "bidder" }) do
            local selected = GetSelectedAuctionItem(lt)
            if selected and selected > 0 then
                name, _, count = GetAuctionItemInfo(lt, selected)
                if name then break end
            end
        end
    elseif which == "CANCEL_AUCTION" then
        local selected = GetSelectedAuctionItem("owner")
        if selected and selected > 0 then
            name, _, count = GetAuctionItemInfo("owner", selected)
        end
    end
    if not name then return nil end
    local suffix = " " .. name
    if count and count > 1 then
        suffix = suffix .. " x" .. count
    end
    return suffix
end

-- Return to scan results when the user cancels a bid/buyout confirmation popup.
-- Installed lazily inside StaticPopup_Show because Blizzard_AuctionUI is LoadOnDemand
-- and its dialog tables don't exist at addon load time.
local hookedPopupCancel = {}

hooksecurefunc("StaticPopup_Show", function(which)
    if not AUCTION_POPUP_TYPES[which] then return end

    -- Lazily hook OnCancel for bid/buyout popups (now that Blizzard_AuctionUI is loaded)
    if not hookedPopupCancel[which] and (which == "BUYOUT_AUCTION" or which == "BID_AUCTION") then
        local dialog = StaticPopupDialogs[which]
        if dialog and dialog.OnCancel then
            hookedPopupCancel[which] = true
            hooksecurefunc(dialog, "OnCancel", function()
                if session:isViewingItem() then
                    session:returnToResults()
                end
            end)
        end
    end

    local suffix = getAuctionPopupItemSuffix(which)
    if not suffix then return end
    for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
        local frame = _G["StaticPopup" .. i]
        if frame and frame.which == which and frame:IsShown() then
            local textObj = frame.text or (frame.GetTextFontString and frame:GetTextFontString())
            if textObj then
                local current = textObj:GetText() or ""
                textObj:SetText(current .. suffix)
            end
            break
        end
    end
end)

------------------------------------------------------------
-- Window registration
------------------------------------------------------------

module:registerWindow({
    type = "FrameWindow",
    name = "auction",
    frameName = "AuctionFrame",
    graphScreen = {
        render = render,
        captureClose = true,
        onRequestClose = function()
            AuctionFrame:Hide()
        end,
    },
})
