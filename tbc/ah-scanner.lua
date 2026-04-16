local AHScanner = WowVision.Class("AHScanner")

local NUM_AUCTION_ITEMS_PER_PAGE = NUM_AUCTION_ITEMS_PER_PAGE or 50
local QUERY_TIMEOUT = 10

function AHScanner:initialize()
    self.events = {
        scanStarted = WowVision.Event:new("scanStarted"),
        pageScanned = WowVision.Event:new("pageScanned"),
        scanComplete = WowVision.Event:new("scanComplete"),
        scanAborted = WowVision.Event:new("scanAborted"),
        scanFailed = WowVision.Event:new("scanFailed"),
    }
    self._state = "idle"
    self._query = nil
    self._options = nil
    self._page = 0
    self._totalPages = 0
    self._results = {}
    self._totalScanned = 0
    self._waitStart = 0

    self._frame = CreateFrame("Frame")
    self._frame:SetScript("OnEvent", function(_, event)
        self:_onEvent(event)
    end)
end

function AHScanner:start(query, options)
    if self._state ~= "idle" then
        self:abort()
    end

    self._query = query or {}
    self._options = options or {}
    self._page = self._options.startPage or 0
    self._totalPages = 0
    self._results = {}
    self._totalScanned = 0

    self._frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    self._frame:RegisterEvent("AUCTION_HOUSE_CLOSED")

    self:_sendQuery()
end

function AHScanner:abort()
    if self._state == "idle" then return end
    local results = self._results
    local progress = self:getProgress()
    self:_cleanup()
    self.events.scanAborted:emit(results, progress)
end

function AHScanner:isScanning()
    return self._state ~= "idle"
end

function AHScanner:getProgress()
    return {
        page = self._page,
        totalPages = self._totalPages,
        matched = #self._results,
        total = self._totalScanned,
    }
end

function AHScanner:getQuery()
    return self._query
end

function AHScanner:_cleanup()
    self._state = "idle"
    self._frame:UnregisterAllEvents()
    self._frame:SetScript("OnUpdate", nil)
end

function AHScanner:_sendQuery()
    if CanSendAuctionQuery() then
        self._state = "querying"
        local q = self._query
        QueryAuctionItems(
            q.name or "",
            q.minLevel or 0,
            q.maxLevel or 0,
            self._page,
            q.usable or false,
            q.rarity or -1,
            false, -- getAll: always false to avoid throttle
            q.exactMatch or false,
            q.filterData
        )
    else
        self._state = "waiting"
        self._waitStart = GetTime()
        self._frame:SetScript("OnUpdate", function()
            self:_onUpdate()
        end)
    end
end

function AHScanner:_onUpdate()
    if self._state ~= "waiting" then
        self._frame:SetScript("OnUpdate", nil)
        return
    end
    if CanSendAuctionQuery() then
        self._frame:SetScript("OnUpdate", nil)
        self:_sendQuery()
    elseif GetTime() - self._waitStart > QUERY_TIMEOUT then
        self._frame:SetScript("OnUpdate", nil)
        self:_cleanup()
        self.events.scanFailed:emit("timeout")
    end
end

function AHScanner:_onEvent(event)
    if event == "AUCTION_HOUSE_CLOSED" then
        if self._state ~= "idle" then
            self:abort()
        end
        return
    end

    if event == "AUCTION_ITEM_LIST_UPDATE" and self._state == "querying" then
        self._state = "processing"
        self:_processPage()
    end
end

function AHScanner:_processPage()
    local numBatch, totalAuctions = GetNumAuctionItems("list")
    numBatch = numBatch or 0
    totalAuctions = totalAuctions or 0
    self._totalPages = math.ceil(totalAuctions / NUM_AUCTION_ITEMS_PER_PAGE)

    -- Emit scanStarted on first page
    if self._page == (self._options.startPage or 0) then
        self.events.scanStarted:emit({
            totalPages = self._totalPages,
            totalAuctions = totalAuctions,
        })
    end

    local filter = self._options.filter
    for i = 1, numBatch do
        local name, texture, count, quality, canUse, level, levelColHeader,
            minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
            bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =
            GetAuctionItemInfo("list", i)
        if name then
            self._totalScanned = self._totalScanned + 1
            if not filter or filter(name, texture, count, quality, canUse, level, levelColHeader,
                    minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
                    bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo) then
                tinsert(self._results, {
                    name = name,
                    texture = texture,
                    count = count,
                    quality = quality,
                    canUse = canUse,
                    level = level,
                    minBid = minBid,
                    buyoutPrice = buyoutPrice,
                    bidAmount = bidAmount,
                    owner = owner,
                    timeLeft = GetAuctionItemTimeLeft("list", i),
                    itemId = itemId,
                    link = GetAuctionItemLink("list", i),
                    page = self._page,
                    pageIndex = i,
                })
            end
        end
    end

    self.events.pageScanned:emit(self:getProgress())

    -- Check if done
    local endPage = self._options.endPage
    local targetCount = self._options.targetCount
    local nextPage = self._page + 1
    local hitTarget = targetCount and #self._results >= targetCount
    if hitTarget or nextPage >= self._totalPages or (endPage and nextPage > endPage) then
        local results = self._results
        local progress = self:getProgress()
        self:_cleanup()
        self.events.scanComplete:emit(results, progress)
    else
        self._page = nextPage
        self:_sendQuery()
    end
end

WowVision.AHScanner = AHScanner
