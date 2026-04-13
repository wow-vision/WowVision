-- Blizzard bug: deDE localization in Blizzard_AuctionUI tries to call
-- PriceDropdown:SetWidth() but PriceDropdown doesn't exist in TBC Anniversary.
-- Create a dummy to prevent the error.
if not PriceDropdown then
    PriceDropdown = CreateFrame("Frame")
end

local module = WowVision.base.windows:createModule("auction")
local L = module.L
module:setLabel(L["Auction House"])
local gen = module:hasUI()

-- Alert for item selection feedback
local selectAlert = module:addAlert({ key = "itemSelected", label = L["Item Selected"] })
selectAlert:addOutput({ type = "TTS", key = "tts", label = L["Item Selected"] })

-- Client-side filter: hide browse results below this stack size
local minStackSize = 0

-- AH Scanner integration
local scanner = WowVision.AHScanner:new()
local scanResults = nil       -- array of result items, with .query/.lastPage/.totalPages metadata
local scanInProgress = false
local scanIsLoadMore = false   -- true when "Load More" triggered the scan (append results)
local viewingScanItem = false
local pendingScanSelect = nil
local pendingScanItem = nil    -- the scan result item being purchased

-- Capture the last query args so we can replay them for scanning.
-- Also clear scan state when the user starts a genuinely new search.
local lastQueryArgs = {}
hooksecurefunc("QueryAuctionItems", function(name, minLevel, maxLevel, page, usable, rarity, getAll, exactMatch, filterData)
    if scanner:isScanning() or pendingScanSelect then
        return
    end
    lastQueryArgs = {
        name = name,
        minLevel = minLevel,
        maxLevel = maxLevel,
        usable = usable,
        rarity = rarity,
        exactMatch = exactMatch,
        filterData = filterData,
    }
    -- New manual search — discard old scan results
    if not viewingScanItem then
        scanResults = nil
    end
end)

scanner.events.scanStarted:subscribe(module, function(self, event, info)
    scanInProgress = true
    if not scanIsLoadMore then
        scanResults = nil
    end
    local pages = info and info.totalPages or "?"
    WowVision:speak(L["Scanning"] .. ", " .. pages .. " " .. L["Page"])
end)

scanner.events.pageScanned:subscribe(module, function(self, event, progress)
    if progress.page > 0 and progress.page % 5 == 0 then
        WowVision:speak(L["Page"] .. " " .. progress.page .. " / " .. progress.totalPages)
    end
end)

local function finalizeScanResults(results, progress)
    if scanIsLoadMore and scanResults then
        -- Append new results to existing
        for _, item in ipairs(results) do
            tinsert(scanResults, item)
        end
    else
        scanResults = results
    end
    scanResults.query = scanner:getQuery()
    scanResults.lastPage = progress.page
    scanResults.totalPages = progress.totalPages
    scanIsLoadMore = false
end

scanner.events.scanComplete:subscribe(module, function(self, event, results, progress)
    scanInProgress = false
    finalizeScanResults(results, progress)
    WowVision:speak(L["Scan complete"] .. ", " .. #scanResults .. " " .. L["Results"] .. " in " .. progress.total .. " " .. L["scanned"])
end)

scanner.events.scanAborted:subscribe(module, function(self, event, results, progress)
    scanInProgress = false
    finalizeScanResults(results, progress)
    WowVision:speak(L["Scan aborted"] .. ", " .. #scanResults .. " " .. L["Results"])
end)

scanner.events.scanFailed:subscribe(module, function(self, event, reason)
    scanInProgress = false
    scanIsLoadMore = false
    WowVision:speak(L["Scan failed"])
end)

-- Full AH scanner integration (price database)
local fullScanner = WowVision.ahPrices and WowVision.ahPrices.fullScanner

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
    if not fullScanner then return "" end
    local state = fullScanner:getState()
    if state == "waiting" then
        return L["Scanning"] .. ", " .. math.floor(fullScanner:getWaitElapsed()) .. " sec"
    elseif state == "processing" then
        local p = fullScanner:getProgress()
        if p.total > 0 then
            return L["Scanning"] .. ", " .. math.floor(p.processed * 100 / p.total) .. "%"
        end
    end
    return L["Scanning"]
end

gen:Element("auction/FullScanButton", {
    regenerateOn = {
        values = function()
            if not fullScanner then return {} end
            return {
                scanning = fullScanner:isScanning(),
                canScan = select(1, fullScanner:canScan()),
            }
        end,
    },
}, function(props)
    if not fullScanner then return nil end

    if fullScanner:isScanning() then
        return {
            "Button",
            label = fullScanScanningLabel,
            events = {
                click = function()
                    fullScanner:abort()
                end,
            },
        }
    end

    local canScan = fullScanner:canScan()
    if canScan then
        return {
            "Button",
            label = L["Full Scan"],
            events = {
                click = function()
                    fullScanner:start()
                end,
            },
        }
    end

    -- Cooldown: click speaks remaining time
    return {
        "Button",
        label = L["Full Scan"] .. ", " .. L["Cooldown active"],
        events = {
            click = function()
                WowVision:speak(formatCooldownTime(fullScanner:getCooldownRemaining()))
            end,
        },
    }
end)

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
-- Shared factories for repeated scroll frame patterns
------------------------------------------------------------

-- Creates a gen:Element callback for ProxyFauxScrollFrame with List fallback.
-- config: { buttonPrefix, numButtons, listType, scrollFrameName, label,
--           updateFunctionName, getElement, emptyElement }
local function makeResultsElement(config)
    local cachedButtons
    local function getButtons()
        if not cachedButtons then
            cachedButtons = {}
            for i = 1, config.numButtons do
                local button = _G[config.buttonPrefix .. i]
                if button then
                    tinsert(cachedButtons, button)
                end
            end
        end
        return cachedButtons
    end
    local function getNumEntries()
        return GetNumAuctionItems(config.listType) or 0
    end
    local function getElementIndex(self, button)
        return button:GetID() + (FauxScrollFrame_GetOffset(_G[config.scrollFrameName]) or 0)
    end

    return function(props)
        if getNumEntries() == 0 then
            return config.emptyElement
        end
        local scrollFrame = _G[config.scrollFrameName]
        if scrollFrame and scrollFrame:IsShown() then
            return {
                "ProxyFauxScrollFrame",
                frame = scrollFrame,
                label = config.label,
                buttonHeight = AUCTIONS_BUTTON_HEIGHT or 37,
                updateFunction = _G[config.updateFunctionName],
                getNumEntries = getNumEntries,
                getElement = config.getElement,
                getElementIndex = getElementIndex,
                getButtons = getButtons,
            }
        end
        local children = {}
        for _, button in ipairs(getButtons()) do
            if button:IsShown() then
                local element = config.getElement(nil, button)
                if element then
                    tinsert(children, element)
                end
            end
        end
        if #children == 0 then
            return nil
        end
        return { "List", label = config.label, children = children }
    end
end

-- Builds a sort header element spec from a sortTable name and button definitions.
-- Called inside gen:Element callbacks (where Blizzard frames are available).
local function buildSortHeaders(sortTable, buttons)
    local children = {}
    for _, btn in ipairs(buttons) do
        if btn.frame and btn.frame:IsShown() then
            tinsert(children, { "AuctionSortButton", frame = btn.frame, sortTable = sortTable, sortColumn = btn.column })
        end
    end
    if #children == 0 then
        return nil
    end
    return { "List", label = L["Sort"], direction = "horizontal", children = children }
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

gen:Element("auction", {
    regenerateOn = {
        values = function(props)
            return { tab = PanelTemplates_GetSelectedTab(AuctionFrame) }
        end,
    },
}, function(props)
    local children = {}
    if AuctionFrameBrowse:IsShown() then
        tinsert(children, { "auction/BrowseTab" })
    elseif AuctionFrameBid:IsShown() then
        tinsert(children, { "auction/BidsTab" })
    elseif AuctionFrameAuctions:IsShown() then
        tinsert(children, { "auction/AuctionsTab" })
    end
    tinsert(children, { "auction/Tabs" })
    return {
        "Panel",
        label = L["Auction House"],
        wrap = true,
        children = children,
    }
end)

gen:Element("auction/Tabs", {
    regenerateOn = {
        values = function(props)
            return { tab = PanelTemplates_GetSelectedTab(AuctionFrame) }
        end,
    },
}, function(props)
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
        },
    }
end)

-- Category filter buttons — hook each to auto-search on click
local hookedFilterButtons = {}
local function hookFilterButton(button)
    if hookedFilterButtons[button] then return end
    hookedFilterButtons[button] = true
    button:HookScript("OnClick", function()
        AuctionFrameBrowse_Search()
    end)
end

gen:Element("auction/Categories", function(props)
    local children = {}
    for i = 1, 15 do
        local button = _G["AuctionFilterButton" .. i]
        if button and button:IsShown() then
            hookFilterButton(button)
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
            { "auction/BrowseResults" },
            { "auction/BrowsePageControls" },
            { "auction/BrowseActions" },
            { "auction/BrowseSortHeaders" },
            { "auction/BrowsePriceOptions" },
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
                                {
                                    "EditBox",
                                    label = L["Min Stack Size"],
                                    type = "number",
                                    autoInputOnFocus = false,
                                    value = minStackSize > 0 and minStackSize or nil,
                                    events = {
                                        valueChange = function(event, widget, value)
                                            minStackSize = tonumber(value) or 0
                                        end,
                                    },
                                },
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
            { "auction/FullScanButton" },
            { "ProxyButton", frame = BrowseResetButton },
        },
    }
end)

-- Browse sort headers
gen:Element("auction/BrowseSortHeaders", function(props)
    return buildSortHeaders("list", {
        { frame = BrowseQualitySort, column = "quality" },
        { frame = BrowseLevelSort, column = "level" },
        { frame = BrowseDurationSort, column = "duration" },
        { frame = BrowseHighBidderSort, column = "seller" },
        { frame = BrowseCurrentBidSort, column = "bid" },
    })
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

-- Browse result item element builder
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

    if buyoutPrice and buyoutPrice > 0 then
        label = label .. ", " .. L["Buyout"] .. ": " .. formatMoney(buyoutPrice)
    end

    local currentBid = bidAmount and bidAmount > 0 and bidAmount or minBid
    local bidText = formatMoney(currentBid)
    if bidText then
        label = label .. ", " .. L["Current Bid"] .. ": " .. bidText
    end

    local timeLeft = GetAuctionItemTimeLeft("list", index)
    if timeLeft then
        label = label .. ", " .. L["Time Left"] .. ": " .. getTimeLeftString(timeLeft)
    end

    return { "ProxyButton", frame = button, label = label }
end

-- Select a browse item by its 1-based index in the auction list.
-- Scrolls Blizzard's FauxScrollFrame to make the item visible, then clicks it.
local function selectBrowseItem(realIndex)
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

-- Build a flat List of browse results filtered by minStackSize.
local function buildFilteredBrowseList()
    local numBatch = GetNumAuctionItems("list") or 0
    if numBatch == 0 then return nil end
    local children = {}
    for i = 1, numBatch do
        local name, _, count, quality, canUse, level, levelColHeader,
            minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
            bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =
            GetAuctionItemInfo("list", i)
        if name and (count or 0) >= minStackSize then
            local label = name
            if count and count > 1 then
                label = label .. " x" .. count
            end
            if owner then
                label = label .. ", " .. L["Seller"] .. ": " .. owner
            end
            if buyoutPrice and buyoutPrice > 0 then
                label = label .. ", " .. L["Buyout"] .. ": " .. formatMoney(buyoutPrice)
            end
            local currentBid = bidAmount and bidAmount > 0 and bidAmount or minBid
            local bidText = formatMoney(currentBid)
            if bidText then
                label = label .. ", " .. L["Current Bid"] .. ": " .. bidText
            end
            local timeLeft = GetAuctionItemTimeLeft("list", i)
            if timeLeft then
                label = label .. ", " .. L["Time Left"] .. ": " .. getTimeLeftString(timeLeft)
            end
            local realIndex = i
            tinsert(children, {
                "Button",
                label = label,
                events = {
                    click = function()
                        selectBrowseItem(realIndex)
                    end,
                },
            })
        end
    end
    if #children == 0 then
        return { "Text", text = L["No Results"] }
    end
    return { "List", label = L["Results"], children = children }
end

local browseResultsCallback = makeResultsElement({
    buttonPrefix = "BrowseButton",
    numButtons = NUM_BROWSE_BUTTONS,
    listType = "list",
    scrollFrameName = "BrowseScrollFrame",
    label = L["Results"],
    updateFunctionName = "AuctionFrameBrowse_Update",
    getElement = getBrowseElement,
})

-- Build a label string for a scan result entry (same format as browse items).
local function buildScanResultLabel(item)
    local label = item.name
    if item.count and item.count > 1 then
        label = label .. " x" .. item.count
    end
    if item.owner then
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
    if item.timeLeft then
        label = label .. ", " .. L["Time Left"] .. ": " .. getTimeLeftString(item.timeLeft)
    end
    return label
end

-- Remove a purchased/gone item from the scan results list.
local function removeScanItem(item)
    if not scanResults or not item then return end
    for i, entry in ipairs(scanResults) do
        if entry == item then
            tremove(scanResults, i)
            return
        end
    end
end

-- Purchase tracking: auto-return to scan results after buy or item-not-found.
local purchaseFrame = CreateFrame("Frame")

local function stopPurchaseTracking()
    purchaseFrame:UnregisterAllEvents()
end

local function returnToScanResults()
    viewingScanItem = false
    pendingScanItem = nil
    stopPurchaseTracking()
end

purchaseFrame:SetScript("OnEvent", function(_, event, ...)
    if not viewingScanItem or not pendingScanItem then return end
    if event == "CHAT_MSG_SYSTEM" then
        local message = ...
        if message == ERR_AUCTION_BID_PLACED then
            removeScanItem(pendingScanItem)
            returnToScanResults()
            WowVision:speak(L["Item purchased"])
        end
    elseif event == "UI_ERROR_MESSAGE" then
        local _, message = ...
        if message == ERR_ITEM_NOT_FOUND then
            removeScanItem(pendingScanItem)
            returnToScanResults()
            WowVision:speak(L["Item not found"])
        end
    end
end)

local function startPurchaseTracking()
    purchaseFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    purchaseFrame:RegisterEvent("UI_ERROR_MESSAGE")
end

-- Verify that the auction at the given index matches the expected scan result.
-- Compares name, stack count, buyout price, min bid, and owner.
local function verifyAuctionItem(index, expectedItem)
    local name, _, count, quality, canUse, level, levelColHeader,
        minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
        bidderFullName, owner = GetAuctionItemInfo("list", index)
    if not name then return false end
    if name ~= expectedItem.name then return false end
    if (count or 0) ~= (expectedItem.count or 0) then return false end
    if (buyoutPrice or 0) ~= (expectedItem.buyoutPrice or 0) then return false end
    if (minBid or 0) ~= (expectedItem.minBid or 0) then return false end
    if owner and expectedItem.owner and owner ~= expectedItem.owner then return false end
    return true
end

-- Search all items on the current page for one matching the expected scan result.
-- Returns the 1-based page index if found, nil otherwise.
local function findMatchingAuctionItem(expectedItem)
    local numBatch = GetNumAuctionItems("list") or 0
    for i = 1, numBatch do
        if verifyAuctionItem(i, expectedItem) then
            return i
        end
    end
    return nil
end

-- Navigate to a scan result's page and select it, then show bid/buyout.
-- scanResults is preserved so the user can return to the list.
-- We delay the selection by one frame so Blizzard's AuctionFrameBrowse_Update()
-- finishes first — otherwise BrowseButtons are still hidden when we try to Click().
-- After re-querying, we verify the item at the expected index still matches.
-- If it shifted, we search the full page. If gone entirely, we notify the user.
local scanSelectFrame = CreateFrame("Frame")
scanSelectFrame:SetScript("OnEvent", function()
    if pendingScanSelect then
        local expectedIndex = pendingScanSelect
        local expectedItem = pendingScanItem
        pendingScanSelect = nil
        scanSelectFrame:UnregisterAllEvents()

        -- Verify the item at the expected index still matches
        local actualIndex
        if verifyAuctionItem(expectedIndex, expectedItem) then
            actualIndex = expectedIndex
        else
            -- Item shifted — search the full page
            actualIndex = findMatchingAuctionItem(expectedItem)
        end

        if actualIndex then
            viewingScanItem = true
            startPurchaseTracking()
            C_Timer.After(0, function()
                selectBrowseItem(actualIndex)
            end)
        else
            -- Item no longer on this page — remove from results and notify
            removeScanItem(expectedItem)
            pendingScanItem = nil
            WowVision:speak(L["Item not found"])
        end
    end
end)

local function selectScanResult(item)
    pendingScanSelect = item.pageIndex
    pendingScanItem = item
    scanSelectFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    local q = scanResults and scanResults.query or lastQueryArgs
    QueryAuctionItems(
        q.name or "",
        q.minLevel or 0,
        q.maxLevel or 0,
        item.page,
        q.usable or false,
        q.rarity or -1,
        false,
        q.exactMatch or false,
        q.filterData
    )
end

local SCAN_TARGET_COUNT = 20

-- Start a scan using the last captured query args.
-- startPage: optional page to resume from (for "Load More").
local function startScan(startPage)
    local filter
    if minStackSize > 1 then
        local threshold = minStackSize
        filter = function(name, texture, count)
            return (count or 0) >= threshold
        end
    end
    scanner:start(lastQueryArgs, {
        filter = filter,
        targetCount = SCAN_TARGET_COUNT,
        startPage = startPage,
    })
end

-- Build a List element from scan results.
local function buildScanResultsList()
    if not scanResults or #scanResults == 0 then
        return { "Text", text = L["No Results"] }
    end
    local children = {}
    for _, item in ipairs(scanResults) do
        local capturedItem = item
        tinsert(children, {
            "Button",
            label = buildScanResultLabel(item),
            events = {
                click = function()
                    selectScanResult(capturedItem)
                end,
            },
        })
    end
    return { "List", label = L["Scan Results"], children = children }
end

gen:Element("auction/BrowseResults", {
    regenerateOn = {
        events = { "AUCTION_ITEM_LIST_UPDATE" },
        values = function()
            return {
                minStack = minStackSize,
                scanning = scanInProgress,
                scanCount = scanResults and #scanResults or 0,
                viewingItem = viewingScanItem,
            }
        end,
    },
}, function(props)
    -- Show abort button during scan
    if scanInProgress then
        local progress = scanner:getProgress()
        return {
            "Button",
            label = L["Abort Scan"] .. " (" .. progress.page .. "/" .. progress.totalPages .. ")",
            events = {
                click = function()
                    scanner:abort()
                end,
            },
        }
    end

    -- Viewing a single item from scan results — hide the full browse list.
    -- BrowseActions handles bid/buyout controls for the selected item.
    if viewingScanItem and scanResults then
        return nil
    end

    -- Show scan results list if we have them
    if scanResults then
        return buildScanResultsList()
    end

    -- Filtered browse: show current page filtered results
    -- Scan button is handled by BrowsePageControls (replaces Next Page).
    if minStackSize > 1 then
        return buildFilteredBrowseList()
    end

    return browseResultsCallback(props)
end)

-- Pagination: show "Scan" or "Load More" when filters are active, otherwise Blizzard page buttons.
gen:Element("auction/BrowsePageControls", function(props)
    -- When viewing scan results, replace Blizzard pagination with "Load More"
    if scanResults and not viewingScanItem and not scanInProgress then
        local hasMore = scanResults.lastPage and scanResults.totalPages
            and (scanResults.lastPage + 1) < scanResults.totalPages
        if hasMore then
            return {
                "Button",
                label = L["Load More"],
                events = {
                    click = function()
                        scanIsLoadMore = true
                        startScan(scanResults.lastPage + 1)
                    end,
                },
            }
        end
        return nil
    end

    -- Filtered browse without scan results yet: offer Scan button instead of page controls
    if minStackSize > 1 and not scanResults and not scanInProgress then
        local _, totalAuctions = GetNumAuctionItems("list")
        if (totalAuctions or 0) > 0 then
            return {
                "Button",
                label = L["Scan"],
                events = {
                    click = function()
                        startScan()
                    end,
                },
            }
        end
    end

    -- Normal Blizzard page controls
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
        -- If we came from scan results but nothing is selected (e.g. after buying),
        -- offer to go back to the list
        if viewingScanItem and scanResults then
            return {
                "Button",
                label = L["Scan Results"],
                events = {
                    click = function()
                        returnToScanResults()
                    end,
                },
            }
        end
        return nil
    end
    local children = {}
    if BrowseBuyoutPrice:IsShown() then
        tinsert(children, { "money/MoneyFrame", frame = BrowseBuyoutPrice, label = L["Buyout Price"] })
        tinsert(children, { "ProxyButton", frame = BrowseBuyoutButton })
    end
    tinsert(children, { "auction/MoneyInput", frame = BrowseBidPrice, label = L["Bid Price"] })
    tinsert(children, { "ProxyButton", frame = BrowseBidButton })
    if viewingScanItem and scanResults then
        tinsert(children, {
            "Button",
            label = L["Scan Results"],
            events = {
                click = function()
                    returnToScanResults()
                end,
            },
        })
    end
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
    return buildSortHeaders("bidder", {
        { frame = BidQualitySort, column = "quality" },
        { frame = BidLevelSort, column = "level" },
        { frame = BidDurationSort, column = "duration" },
        { frame = BidBuyoutSort, column = "buyout" },
        { frame = BidStatusSort, column = "status" },
        { frame = BidBidSort, column = "bid" },
    })
end)

-- Bid result item element builder
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

    if buyoutPrice and buyoutPrice > 0 then
        label = label .. ", " .. L["Buyout"] .. ": " .. formatMoney(buyoutPrice)
    end

    local bidText = formatMoney(bidAmount and bidAmount > 0 and bidAmount or minBid)
    if bidText then
        label = label .. ", " .. L["Current Bid"] .. ": " .. bidText
    end

    local timeLeft = GetAuctionItemTimeLeft("bidder", index)
    if timeLeft then
        label = label .. ", " .. L["Time Left"] .. ": " .. getTimeLeftString(timeLeft)
    end

    return { "ProxyButton", frame = button, label = label }
end

gen:Element("auction/BidResults", {
    regenerateOn = {
        events = { "AUCTION_BIDDER_LIST_UPDATE" },
    },
}, makeResultsElement({
    buttonPrefix = "BidButton",
    numButtons = NUM_BID_BUTTONS,
    listType = "bidder",
    scrollFrameName = "BidScrollFrame",
    label = L["Bids"],
    updateFunctionName = "AuctionFrameBid_Update",
    getElement = getBidElement,
    emptyElement = { "Text", text = L["No Bids"] },
}))

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
    local itemLabel = L["Place Item Here"]
    local sellName, sellTexture, sellCount = GetAuctionSellItemInfo()
    if sellName then
        local stackSize = tonumber(AuctionsStackSizeEntry:GetText()) or sellCount
        itemLabel = sellName
        if stackSize and stackSize > 1 then
            itemLabel = itemLabel .. " x" .. stackSize
        end
    end
    local children = {
        { "ProxyButton", frame = AuctionsItemButton, label = itemLabel },
        { "auction/CreateAuction" },
        { "auction/MyAuctionsList" },
    }
    if AuctionsCancelAuctionButton:IsEnabled() then
        tinsert(children, { "ProxyButton", frame = AuctionsCancelAuctionButton })
    end
    tinsert(children, { "auction/AuctionsSortHeaders" })
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = children,
    }
end)

-- Auctions sort headers
gen:Element("auction/AuctionsSortHeaders", function(props)
    return buildSortHeaders("owner", {
        { frame = AuctionsQualitySort, column = "quality" },
        { frame = AuctionsDurationSort, column = "duration" },
        { frame = AuctionsHighBidderSort, column = "status" },
        { frame = AuctionsBidSort, column = "bid" },
    })
end)

-- My auction item element builder
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

    if buyoutPrice and buyoutPrice > 0 then
        label = label .. ", " .. L["Buyout"] .. ": " .. formatMoney(buyoutPrice)
    end

    local bidText = formatMoney(bidAmount and bidAmount > 0 and bidAmount or minBid)
    if bidText then
        label = label .. ", " .. L["Current Bid"] .. ": " .. bidText
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

gen:Element("auction/MyAuctionsList", {
    regenerateOn = {
        events = { "AUCTION_OWNED_LIST_UPDATE" },
    },
}, makeResultsElement({
    buttonPrefix = "AuctionsButton",
    numButtons = NUM_AUCTION_BUTTONS,
    listType = "owner",
    scrollFrameName = "AuctionsScrollFrame",
    label = L["Auctions"],
    updateFunctionName = "AuctionFrameAuctions_Update",
    getElement = getAuctionElement,
}))

-- Create auction form
gen:Element("auction/CreateAuction", function(props)
    local children = {}
    local sellName, sellTexture, sellCount = GetAuctionSellItemInfo()

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

    -- Buyout price
    tinsert(children, { "auction/MoneyInput", frame = BuyoutPrice, label = L["Buyout Price"] })

    -- Starting price (behind expandable dropdown)
    local startGold = _G[StartPrice:GetName() .. "Gold"]
    local startSilver = _G[StartPrice:GetName() .. "Silver"]
    local startCopper = _G[StartPrice:GetName() .. "Copper"]
    tinsert(children, {
        "Button",
        label = L["Starting Bid"],
        displayType = "Dropdown",
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "Panel",
                    label = L["Starting Bid"],
                    layout = true,
                    children = {
                        { "ProxyEditBox", frame = startGold, autoInputOnFocus = false, hookEnter = true, label = L["Gold"] },
                        { "ProxyEditBox", frame = startSilver, autoInputOnFocus = false, hookEnter = true, label = L["Silver"] },
                        { "ProxyEditBox", frame = startCopper, autoInputOnFocus = false, hookEnter = true, label = L["Copper"] },
                    },
                })
            end,
        },
    })

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
        shouldAnnounce = false,
        children = children,
    }
end)

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
                if viewingScanItem and pendingScanItem then
                    returnToScanResults()
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
    generated = true,
    rootElement = "auction",
    frameName = "AuctionFrame",
    hookEscape = true,
    onClose = function()
        AuctionFrame:Hide()
    end,
})
