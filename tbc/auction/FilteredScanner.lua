-- Paginated scanner for a user-filtered browse query (name / level / rarity / ...).
-- Walks pages one at a time, optionally applies a client-side filter, and stops
-- at targetCount or the last page. Emits per-page progress events so the UI can
-- announce "Page 5 / 12" while scanning. Contrast with AHFullScanner, which
-- fires a single getAll query for the price database.

local AHFilteredScanner = WowVision.Class("AHFilteredScanner")

local NUM_AUCTION_ITEMS_PER_PAGE = NUM_AUCTION_ITEMS_PER_PAGE or 50
local QUERY_TIMEOUT = 10

-- Shared between the page-based scanner and ScanSession's re-query on select.
-- Takes a captured filter query (name/level/rarity/...) and a target page.
local function sendPageQuery(q, page)
    QueryAuctionItems(
        q.name or "",
        q.minLevel or 0,
        q.maxLevel or 0,
        page,
        q.usable or false,
        q.rarity or -1,
        false,
        q.exactMatch or false,
        q.filterData
    )
end

WowVision.tbcAH = WowVision.tbcAH or {}
WowVision.tbcAH.sendPageQuery = sendPageQuery

function AHFilteredScanner:initialize()
    self.events = {
        scanStarted = WowVision.Event:new("scanStarted"),
        pageScanned = WowVision.Event:new("pageScanned"),
        scanComplete = WowVision.Event:new("scanComplete"),
        scanAborted = WowVision.Event:new("scanAborted"),
        scanFailed = WowVision.Event:new("scanFailed"),
    }
    self.state = "idle"
    self.query = nil
    self.options = nil
    self.page = 0
    self.totalPages = 0
    self.results = {}
    self.totalScanned = 0
    self.waitStart = 0

    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event)
        self:_onEvent(event)
    end)
end

function AHFilteredScanner:start(query, options)
    if self.state ~= "idle" then
        self:abort()
    end

    self.query = query or {}
    self.options = options or {}
    self.page = self.options.startPage or 0
    self.totalPages = 0
    self.results = {}
    self.totalScanned = 0

    self.frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    self.frame:RegisterEvent("AUCTION_HOUSE_CLOSED")

    self:_sendQuery()
end

function AHFilteredScanner:abort()
    if self.state == "idle" then return end
    local results = self.results
    local progress = self:getProgress()
    self:_cleanup()
    self.events.scanAborted:emit(results, progress)
end

function AHFilteredScanner:isScanning()
    return self.state ~= "idle"
end

function AHFilteredScanner:getProgress()
    return {
        page = self.page,
        totalPages = self.totalPages,
        matched = #self.results,
        total = self.totalScanned,
    }
end

function AHFilteredScanner:getQuery()
    return self.query
end

function AHFilteredScanner:_cleanup()
    self.state = "idle"
    self.frame:UnregisterAllEvents()
    self.frame:SetScript("OnUpdate", nil)
end

function AHFilteredScanner:_sendQuery()
    if CanSendAuctionQuery() then
        self.state = "querying"
        sendPageQuery(self.query, self.page)
    else
        self.state = "waiting"
        self.waitStart = GetTime()
        self.frame:SetScript("OnUpdate", function()
            self:_onUpdate()
        end)
    end
end

function AHFilteredScanner:_onUpdate()
    if self.state ~= "waiting" then
        self.frame:SetScript("OnUpdate", nil)
        return
    end
    if CanSendAuctionQuery() then
        self.frame:SetScript("OnUpdate", nil)
        self:_sendQuery()
    elseif GetTime() - self.waitStart > QUERY_TIMEOUT then
        self.frame:SetScript("OnUpdate", nil)
        self:_cleanup()
        self.events.scanFailed:emit("timeout")
    end
end

function AHFilteredScanner:_onEvent(event)
    if event == "AUCTION_HOUSE_CLOSED" then
        if self.state ~= "idle" then
            self:abort()
        end
        return
    end

    if event == "AUCTION_ITEM_LIST_UPDATE" and self.state == "querying" then
        self.state = "processing"
        self:_processPage()
    end
end

function AHFilteredScanner:_processPage()
    local numBatch, totalAuctions = GetNumAuctionItems("list")
    numBatch = numBatch or 0
    totalAuctions = totalAuctions or 0
    self.totalPages = math.ceil(totalAuctions / NUM_AUCTION_ITEMS_PER_PAGE)

    -- Emit scanStarted on first page
    if self.page == (self.options.startPage or 0) then
        self.events.scanStarted:emit({
            totalPages = self.totalPages,
            totalAuctions = totalAuctions,
        })
    end

    local filter = self.options.filter
    for i = 1, numBatch do
        local name, texture, count, quality, canUse, level, levelColHeader,
            minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
            bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo =
            GetAuctionItemInfo("list", i)
        if name then
            self.totalScanned = self.totalScanned + 1
            if not filter or filter(name, texture, count, quality, canUse, level, levelColHeader,
                    minBid, minIncrement, buyoutPrice, bidAmount, highBidder,
                    bidderFullName, owner, ownerFullName, saleStatus, itemId, hasAllInfo) then
                tinsert(self.results, {
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
                    page = self.page,
                    pageIndex = i,
                })
            end
        end
    end

    self.events.pageScanned:emit(self:getProgress())

    -- Check if done
    local endPage = self.options.endPage
    local targetCount = self.options.targetCount
    local nextPage = self.page + 1
    local hitTarget = targetCount and #self.results >= targetCount
    if hitTarget or nextPage >= self.totalPages or (endPage and nextPage > endPage) then
        local results = self.results
        local progress = self:getProgress()
        self:_cleanup()
        self.events.scanComplete:emit(results, progress)
    else
        self.page = nextPage
        self:_sendQuery()
    end
end

WowVision.tbcAH = WowVision.tbcAH or {}
WowVision.tbcAH.AHFilteredScanner = AHFilteredScanner
