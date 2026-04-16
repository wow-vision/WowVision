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
    self._state = "idle"
    self._totalAuctions = 0
    self._processed = 0
    self._results = {}
    self._hijackedFrames = {}
    self._scanStartTime = 0

    self._frame = CreateFrame("Frame")
    self._frame:SetScript("OnEvent", function(_, event)
        self:_onEvent(event)
    end)
end

function AHFullScanner:canScan()
    return self:getCooldownRemaining() <= 0, "cooldown"
end

function AHFullScanner:getCooldownRemaining()
    if self._scanStartTime <= 0 then return 0 end
    return math.max(0, COOLDOWN - (GetTime() - self._scanStartTime))
end

-- Seed cooldown from a persisted unix timestamp (e.g. after reload).
-- Converts wall-clock time() to session-relative GetTime().
function AHFullScanner:setLastScanTime(unixTime)
    if not unixTime or unixTime <= 0 then return end
    local elapsed = time() - unixTime
    if elapsed < COOLDOWN then
        self._scanStartTime = GetTime() - elapsed
    end
end

function AHFullScanner:getState()
    return self._state
end

function AHFullScanner:getWaitElapsed()
    if self._state ~= "waiting" or self._scanStartTime <= 0 then return 0 end
    return GetTime() - self._scanStartTime
end

function AHFullScanner:start()
    if self._state ~= "idle" then
        return
    end

    local canScan, reason = self:canScan()
    if not canScan then
        self.events.scanFailed:emit(reason)
        return
    end

    self._state = "waiting"
    self._processed = 0
    self._totalAuctions = 0
    self._results = {}
    self._scanStartTime = GetTime()

    self._frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
    self:_hijackEvent()
    self._frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")

    QueryAuctionItems("", nil, nil, 0, nil, nil, true, false, nil)
end

function AHFullScanner:abort()
    if self._state == "idle" then return end
    self:_cleanup()
    self.events.scanFailed:emit("aborted")
end

function AHFullScanner:isScanning()
    return self._state ~= "idle"
end

function AHFullScanner:getProgress()
    return {
        processed = self._processed,
        total = self._totalAuctions,
    }
end

function AHFullScanner:_hijackEvent()
    self._hijackedFrames = {}
    local frames = { GetFramesRegisteredForEvent("AUCTION_ITEM_LIST_UPDATE") }
    for _, frame in ipairs(frames) do
        if frame ~= self._frame then
            frame:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
            tinsert(self._hijackedFrames, frame)
        end
    end
end

function AHFullScanner:_restoreEvent()
    for _, frame in ipairs(self._hijackedFrames) do
        frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    end
    self._hijackedFrames = {}
end

function AHFullScanner:_cleanup()
    self._state = "idle"
    self._frame:UnregisterAllEvents()
    self._frame:SetScript("OnUpdate", nil)
    self:_restoreEvent()
end

function AHFullScanner:_onEvent(event)
    if event == "AUCTION_HOUSE_CLOSED" then
        if self._state ~= "idle" then
            self:_cleanup()
            self.events.scanFailed:emit("ah_closed")
        end
        return
    end

    if event == "AUCTION_ITEM_LIST_UPDATE" and self._state == "waiting" then
        local numBatch, totalAuctions = GetNumAuctionItems("list")
        -- A getAll response delivers all auctions in one batch, so numBatch
        -- is always larger than a single page.  Skip stale page data or
        -- cleared-list events that fire before the real response arrives.
        if numBatch <= (NUM_AUCTION_ITEMS_PER_PAGE or 50) then
            return
        end
        self._totalAuctions = totalAuctions or numBatch or 0
        self._state = "processing"
        self.events.scanStarted:emit(self._totalAuctions)
        self:_startBatchProcessing()
    end
end

function AHFullScanner:_startBatchProcessing()
    self._frame:SetScript("OnUpdate", function()
        self:_processBatch()
    end)
end

function AHFullScanner:_processBatch()
    if self._state ~= "processing" then
        self._frame:SetScript("OnUpdate", nil)
        return
    end

    local endIndex = math.min(self._processed + BATCH_SIZE, self._totalAuctions)
    for i = self._processed + 1, endIndex do
        local name, _, count, _, _, _, _,
            _, _, buyoutPrice, _, _,
            _, _, _, _, itemId = GetAuctionItemInfo("list", i)
        if name and itemId and buyoutPrice and buyoutPrice > 0 and count and count > 0 then
            local perUnit = math.floor(buyoutPrice / count)
            local entry = self._results[itemId]
            if entry then
                if perUnit < entry.minBuyout then
                    entry.minBuyout = perUnit
                end
                entry.totalSeen = entry.totalSeen + 1
            else
                self._results[itemId] = {
                    minBuyout = perUnit,
                    totalSeen = 1,
                }
            end
        end
    end

    self._processed = endIndex
    self.events.scanProgress:emit(self._processed, self._totalAuctions)

    if self._processed >= self._totalAuctions then
        local results = self._results
        self:_cleanup()
        self.events.scanComplete:emit(results)
    end
end

WowVision.AHFullScanner = AHFullScanner
