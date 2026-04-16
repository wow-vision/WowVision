local AHFullScanner = WowVision.Class("AHFullScanner")

local BATCH_SIZE = 250
local COOLDOWN = 900 -- 15 minutes

function AHFullScanner:initialize()
    self.events = {
        scanStarted = WowVision.Event:new("fullScanStarted"),
        scanProgress = WowVision.Event:new("fullScanProgress"),
        scanComplete = WowVision.Event:new("fullScanComplete"),
        scanFailed = WowVision.Event:new("fullScanFailed"),
    }
    self.state = "idle"
    self.totalAuctions = 0
    self.processed = 0
    self.results = {}
    self.hijackedFrames = {}
    self.scanStartTime = 0

    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event)
        self:_onEvent(event)
    end)
end

function AHFullScanner:canScan()
    return self:getCooldownRemaining() <= 0, "cooldown"
end

function AHFullScanner:getCooldownRemaining()
    if self.scanStartTime <= 0 then return 0 end
    return math.max(0, COOLDOWN - (GetTime() - self.scanStartTime))
end

-- Seed cooldown from a persisted unix timestamp (e.g. after reload).
-- Converts wall-clock time() to session-relative GetTime().
function AHFullScanner:setLastScanTime(unixTime)
    if not unixTime or unixTime <= 0 then return end
    local elapsed = time() - unixTime
    if elapsed < COOLDOWN then
        self.scanStartTime = GetTime() - elapsed
    end
end

function AHFullScanner:getState()
    return self.state
end

function AHFullScanner:getWaitElapsed()
    if self.state ~= "waiting" or self.scanStartTime <= 0 then return 0 end
    return GetTime() - self.scanStartTime
end

function AHFullScanner:start()
    if self.state ~= "idle" then
        return
    end

    local canScan, reason = self:canScan()
    if not canScan then
        self.events.scanFailed:emit(reason)
        return
    end

    self.state = "waiting"
    self.processed = 0
    self.totalAuctions = 0
    self.results = {}
    self.scanStartTime = GetTime()

    self.frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
    self:_hijackEvent()
    self.frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")

    QueryAuctionItems("", nil, nil, 0, nil, nil, true, false, nil)
end

function AHFullScanner:abort()
    if self.state == "idle" then return end
    self:_cleanup()
    self.events.scanFailed:emit("aborted")
end

function AHFullScanner:isScanning()
    return self.state ~= "idle"
end

function AHFullScanner:getProgress()
    return {
        processed = self.processed,
        total = self.totalAuctions,
    }
end

-- A getAll query delivers thousands of rows in one AUCTION_ITEM_LIST_UPDATE.
-- If Blizzard_AuctionUI processes that event it iterates all rows to render
-- the browse tab, which freezes the client for several seconds. We steal the
-- event for the duration of the scan and restore the original listeners in
-- _restoreEvent once we've finished batching the data ourselves.
function AHFullScanner:_hijackEvent()
    self.hijackedFrames = {}
    local frames = { GetFramesRegisteredForEvent("AUCTION_ITEM_LIST_UPDATE") }
    for _, frame in ipairs(frames) do
        if frame ~= self.frame then
            frame:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
            tinsert(self.hijackedFrames, frame)
        end
    end
end

function AHFullScanner:_restoreEvent()
    for _, frame in ipairs(self.hijackedFrames) do
        frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    end
    self.hijackedFrames = {}
end

function AHFullScanner:_cleanup()
    self.state = "idle"
    self.frame:UnregisterAllEvents()
    self.frame:SetScript("OnUpdate", nil)
    self:_restoreEvent()
end

function AHFullScanner:_onEvent(event)
    if event == "AUCTION_HOUSE_CLOSED" then
        if self.state ~= "idle" then
            self:_cleanup()
            self.events.scanFailed:emit("ah_closed")
        end
        return
    end

    if event == "AUCTION_ITEM_LIST_UPDATE" and self.state == "waiting" then
        local numBatch, totalAuctions = GetNumAuctionItems("list")
        -- A getAll response delivers all auctions in one batch, so numBatch
        -- is always larger than a single page.  Skip stale page data or
        -- cleared-list events that fire before the real response arrives.
        if numBatch <= (NUM_AUCTION_ITEMS_PER_PAGE or 50) then
            return
        end
        self.totalAuctions = totalAuctions or numBatch or 0
        self.state = "processing"
        self.events.scanStarted:emit(self.totalAuctions)
        self:_startBatchProcessing()
    end
end

function AHFullScanner:_startBatchProcessing()
    self.frame:SetScript("OnUpdate", function()
        self:_processBatch()
    end)
end

function AHFullScanner:_processBatch()
    if self.state ~= "processing" then
        self.frame:SetScript("OnUpdate", nil)
        return
    end

    local endIndex = math.min(self.processed + BATCH_SIZE, self.totalAuctions)
    for i = self.processed + 1, endIndex do
        local name, _, count, _, _, _, _,
            _, _, buyoutPrice, _, _,
            _, _, _, _, itemId = GetAuctionItemInfo("list", i)
        if name and itemId and buyoutPrice and buyoutPrice > 0 and count and count > 0 then
            local perUnit = math.floor(buyoutPrice / count)
            local entry = self.results[itemId]
            if entry then
                if perUnit < entry.minBuyout then
                    entry.minBuyout = perUnit
                end
                entry.totalSeen = entry.totalSeen + 1
            else
                self.results[itemId] = {
                    minBuyout = perUnit,
                    totalSeen = 1,
                }
            end
        end
    end

    self.processed = endIndex
    self.events.scanProgress:emit(self.processed, self.totalAuctions)

    if self.processed >= self.totalAuctions then
        local results = self.results
        self:_cleanup()
        self.events.scanComplete:emit(results)
    end
end

WowVision.tbcAH = WowVision.tbcAH or {}
WowVision.tbcAH.AHFullScanner = AHFullScanner
