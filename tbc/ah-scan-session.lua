-- Owns the multi-page scan workflow: scan -> browse results -> select -> view -> buy/back.
-- Replaces a bag of file-locals in auction.lua and the scanner/purchase/select frames
-- that poked at them. UI reads state via the query methods below.
--
-- States:
--   idle            - no scan done, no results
--   scanning        - AHScanner running
--   browsingResults - results available, user browsing the WV result list
--   selectingItem   - user picked a result; re-querying the AH page
--   viewingItem     - AH shows the real item; user can bid/buyout

local ScanSession = WowVision.Class("ScanSession")

local SCAN_TARGET_COUNT = 20

function ScanSession:initialize(config)
    config = config or {}
    self.selectItem = config.selectItem
    self.isFullScanning = config.isFullScanning or function() return false end
    self.L = config.L or setmetatable({}, { __index = function(_, k) return k end })

    self.state = "idle"
    self.scanner = WowVision.tbcAH.AHScanner:new()
    self.results = nil
    self.pendingItem = nil
    self.pendingIndex = nil
    self.lastQuery = {}
    self._pendingAppend = false

    self.purchaseFrame = CreateFrame("Frame")
    self.purchaseFrame:SetScript("OnEvent", function(_, event, ...)
        self:_onPurchaseEvent(event, ...)
    end)

    self.selectFrame = CreateFrame("Frame")
    self.selectFrame:SetScript("OnEvent", function()
        self:_onSelectFrameEvent()
    end)

    self:_subscribeToScanner()
end

function ScanSession:getState() return self.state end
function ScanSession:isScanning() return self.state == "scanning" end
function ScanSession:isSelectingItem() return self.state == "selectingItem" end
function ScanSession:isViewingItem()
    return self.state == "viewingItem" or self.state == "selectingItem"
end
function ScanSession:hasResults() return self.results ~= nil end
function ScanSession:getResults() return self.results end
function ScanSession:getScanProgress() return self.scanner:getProgress() end

function ScanSession:canLoadMore()
    if not self.results then return false end
    return self.results.lastPage ~= nil
        and self.results.totalPages ~= nil
        and (self.results.lastPage + 1) < self.results.totalPages
end

function ScanSession:startScan(options)
    options = options or {}
    self._pendingAppend = options.append or false
    if not options.append then
        self.pendingItem = nil
        self.pendingIndex = nil
    end
    self.scanner:start(self.lastQuery, {
        filter = options.filter,
        targetCount = options.targetCount or SCAN_TARGET_COUNT,
        startPage = options.startPage,
    })
end

function ScanSession:abort()
    if self:isScanning() then
        self.scanner:abort()
    end
end

-- Called from the QueryAuctionItems hook in auction.lua on every manual search.
function ScanSession:captureQuery(args)
    if self:isScanning() or self:isSelectingItem() or args.getAll
        or self.isFullScanning() then
        return
    end
    self.lastQuery = {
        name = args.name,
        minLevel = args.minLevel,
        maxLevel = args.maxLevel,
        usable = args.usable,
        rarity = args.rarity,
        exactMatch = args.exactMatch,
        filterData = args.filterData,
    }
    if not self:isViewingItem() then
        self.results = nil
        self.state = "idle"
    end
end

function ScanSession:selectResult(item)
    if self.state ~= "browsingResults" then return end
    self.pendingIndex = item.pageIndex
    self.pendingItem = item
    self.state = "selectingItem"
    self.selectFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    local q = (self.results and self.results.query) or self.lastQuery
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

function ScanSession:returnToResults()
    if not self:isViewingItem() then return end
    self.pendingItem = nil
    self.pendingIndex = nil
    self:_stopPurchaseTracking()
    self.selectFrame:UnregisterAllEvents()
    self.state = "browsingResults"
end

function ScanSession:removeResult(item)
    if not self.results or not item then return end
    for i, entry in ipairs(self.results) do
        if entry == item then
            tremove(self.results, i)
            return
        end
    end
end

function ScanSession:_subscribeToScanner()
    self.scanner.events.scanStarted:subscribe(self, function(_, _, info)
        if not self._pendingAppend then
            self.results = nil
        end
        self.state = "scanning"
        local pages = info and info.totalPages or "?"
        WowVision:speak(self.L["Scanning"] .. ", " .. pages .. " " .. self.L["Page"])
    end)
    self.scanner.events.pageScanned:subscribe(self, function(_, _, progress)
        if progress.page > 0 and progress.page % 5 == 0 then
            WowVision:speak(self.L["Page"] .. " " .. progress.page .. " / " .. progress.totalPages)
        end
    end)
    self.scanner.events.scanComplete:subscribe(self, function(_, _, results, progress)
        self:_finalize(results, progress)
        self.state = "browsingResults"
        WowVision:speak(self.L["Scan complete"] .. ", " .. #self.results .. " " .. self.L["Results"] .. " in " .. progress.total .. " " .. self.L["scanned"])
    end)
    self.scanner.events.scanAborted:subscribe(self, function(_, _, results, progress)
        self:_finalize(results, progress)
        self.state = "browsingResults"
        WowVision:speak(self.L["Scan aborted"] .. ", " .. #self.results .. " " .. self.L["Results"])
    end)
    self.scanner.events.scanFailed:subscribe(self, function(_, _, reason)
        self._pendingAppend = false
        self.state = (self.results and #self.results > 0) and "browsingResults" or "idle"
        WowVision:speak(self.L["Scan failed"])
    end)
end

function ScanSession:_finalize(results, progress)
    if self._pendingAppend and self.results then
        for _, item in ipairs(results) do
            tinsert(self.results, item)
        end
    else
        self.results = results
    end
    self.results.query = self.scanner:getQuery()
    self.results.lastPage = progress.page
    self.results.totalPages = progress.totalPages
    self._pendingAppend = false
end

-- Verify the auction at the given index still matches the expected scan result.
-- The AH contents can shift between scan capture and re-query.
function ScanSession:_verifyItem(index, expectedItem)
    local name, _, count, _, _, _, _,
        minBid, _, buyoutPrice, _, _,
        _, owner = GetAuctionItemInfo("list", index)
    if not name then return false end
    if name ~= expectedItem.name then return false end
    if (count or 0) ~= (expectedItem.count or 0) then return false end
    if (buyoutPrice or 0) ~= (expectedItem.buyoutPrice or 0) then return false end
    if (minBid or 0) ~= (expectedItem.minBid or 0) then return false end
    if owner and expectedItem.owner and owner ~= expectedItem.owner then return false end
    return true
end

function ScanSession:_findItem(expectedItem)
    local numBatch = GetNumAuctionItems("list") or 0
    for i = 1, numBatch do
        if self:_verifyItem(i, expectedItem) then
            return i
        end
    end
    return nil
end

-- Re-query completed. Verify the target is still where we expect it, then hand
-- off to the UI to scroll + click. Delayed by one frame so BrowseButtons have
-- their IDs populated before selectItem tries to click them.
function ScanSession:_onSelectFrameEvent()
    if self.state ~= "selectingItem" then return end
    local expectedIndex = self.pendingIndex
    local expectedItem = self.pendingItem
    self.pendingIndex = nil
    self.selectFrame:UnregisterAllEvents()

    local actualIndex
    if self:_verifyItem(expectedIndex, expectedItem) then
        actualIndex = expectedIndex
    else
        actualIndex = self:_findItem(expectedItem)
    end

    if actualIndex then
        self.state = "viewingItem"
        self:_startPurchaseTracking()
        C_Timer.After(0, function()
            if self.selectItem then
                self.selectItem(actualIndex)
            end
        end)
    else
        self:removeResult(expectedItem)
        self.pendingItem = nil
        self.state = "browsingResults"
        WowVision:speak(self.L["Item not found"])
    end
end

function ScanSession:_startPurchaseTracking()
    self.purchaseFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    self.purchaseFrame:RegisterEvent("UI_ERROR_MESSAGE")
end

function ScanSession:_stopPurchaseTracking()
    self.purchaseFrame:UnregisterAllEvents()
end

function ScanSession:_onPurchaseEvent(event, ...)
    if self.state ~= "viewingItem" or not self.pendingItem then return end
    if event == "CHAT_MSG_SYSTEM" then
        local message = ...
        if message == ERR_AUCTION_BID_PLACED then
            self:removeResult(self.pendingItem)
            self:returnToResults()
            WowVision:speak(self.L["Item purchased"])
        end
    elseif event == "UI_ERROR_MESSAGE" then
        local _, message = ...
        if message == ERR_ITEM_NOT_FOUND then
            self:removeResult(self.pendingItem)
            self:returnToResults()
            WowVision:speak(self.L["Item not found"])
        end
    end
end

WowVision.tbcAH = WowVision.tbcAH or {}
WowVision.tbcAH.ScanSession = ScanSession
