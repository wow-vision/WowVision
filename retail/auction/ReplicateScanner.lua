-- The whole auction house in one request on the modern API: ReplicateItems
-- asks the server for a snapshot, REPLICATE_ITEM_LIST_UPDATE says it is here,
-- and the snapshot is read in batches over several frames so the client does
-- not freeze. Same states and events as the TBC AHFullScanner.
--
-- The game is passed in (env) so the headless tests can stand in for it.

local prices = WowVision.modernAH.prices

local ReplicateScanner = WowVision.Class("ReplicateScanner")

local BATCH_SIZE = 500
local COOLDOWN = 900 -- the server allows one snapshot per 15 minutes
local WAIT_TIMEOUT = 180 -- no snapshot by then: it is not coming

function ReplicateScanner:initialize(env)
    self.api = env.api
    self.now = env.now
    self.wallClock = env.wallClock
    self.events = {
        scanRequested = WowVision.Event:new("replicateScanRequested"),
        scanStarted = WowVision.Event:new("replicateScanStarted"),
        scanProgress = WowVision.Event:new("replicateScanProgress"),
        scanComplete = WowVision.Event:new("replicateScanComplete"),
        scanFailed = WowVision.Event:new("replicateScanFailed"),
    }
    self.state = "idle"
    self.totalAuctions = 0
    self.processed = 0
    self.results = {}
    self.scanStartTime = 0

    self.frame = env.createFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event)
        self:_onEvent(event)
    end)
end

function ReplicateScanner:canScan()
    return self:getCooldownRemaining() <= 0, "cooldown"
end

function ReplicateScanner:getCooldownRemaining()
    if self.scanStartTime <= 0 then
        return 0
    end
    return math.max(0, COOLDOWN - (self.now() - self.scanStartTime))
end

-- Seeds the cooldown from the saved request time, so it survives a reload.
function ReplicateScanner:setLastScanTime(unixTime)
    if unixTime == nil or unixTime <= 0 then
        return
    end
    local elapsed = self.wallClock() - unixTime
    if elapsed < COOLDOWN then
        self.scanStartTime = self.now() - elapsed
    end
end

function ReplicateScanner:getState()
    return self.state
end

function ReplicateScanner:isScanning()
    return self.state ~= "idle"
end

function ReplicateScanner:getWaitElapsed()
    if self.state ~= "waiting" then
        return 0
    end
    return self.now() - self.scanStartTime
end

function ReplicateScanner:getProgress()
    return { processed = self.processed, total = self.totalAuctions }
end

function ReplicateScanner:start()
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
    self.scanStartTime = self.now()
    self.frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
    self.frame:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    self.frame:SetScript("OnUpdate", function()
        self:_onUpdate()
    end)
    self.api.ReplicateItems()
    -- The server's cooldown runs from this request, whatever becomes of the scan.
    self.events.scanRequested:emit()
end

function ReplicateScanner:abort()
    if self.state == "idle" then
        return
    end
    self:_cleanup()
    self.events.scanFailed:emit("aborted")
end

function ReplicateScanner:_cleanup()
    self.state = "idle"
    self.frame:UnregisterAllEvents()
    self.frame:SetScript("OnUpdate", nil)
end

function ReplicateScanner:_onEvent(event)
    if event == "AUCTION_HOUSE_CLOSED" then
        if self.state ~= "idle" then
            self:_cleanup()
            self.events.scanFailed:emit("ah_closed")
        end
        return
    end
    if event == "REPLICATE_ITEM_LIST_UPDATE" and self.state == "waiting" then
        local total = self.api.GetNumReplicateItems()
        if total == nil or total <= 0 then
            return -- not the snapshot yet; the timeout ends the wait
        end
        self.frame:UnregisterEvent("REPLICATE_ITEM_LIST_UPDATE")
        self.totalAuctions = total
        self.state = "processing"
        self.events.scanStarted:emit(total)
    end
end

function ReplicateScanner:_onUpdate()
    if self.state == "waiting" then
        if self.now() - self.scanStartTime >= WAIT_TIMEOUT then
            self:_cleanup()
            self.events.scanFailed:emit("timeout")
        end
    elseif self.state == "processing" then
        self:_processBatch()
    end
end

function ReplicateScanner:_processBatch()
    local last = math.min(self.processed + BATCH_SIZE, self.totalAuctions)
    -- The snapshot counts from 0. The item ID, count and buyout are there even
    -- before the client knows the item's name (hasAllInfo false).
    for index = self.processed, last - 1 do
        local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemId = self.api.GetReplicateItemInfo(index)
        prices.addAuction(self.results, itemId, count, buyout)
    end
    self.processed = last
    self.events.scanProgress:emit(self.processed, self.totalAuctions)
    if self.processed >= self.totalAuctions then
        local results = self.results
        self:_cleanup()
        self.events.scanComplete:emit(results)
    end
end

WowVision.modernAH.ReplicateScanner = ReplicateScanner
