-- Realm-scoped price database for auction items.
-- Owns the AHFullScanner instance that writes entries, exposes getPrice /
-- getMeanPrice / getVendorPrice for tooltip rendering, and caches vendor
-- buy prices from MERCHANT_SHOW. Auto-scan on AH open is opt-in via the
-- ahPrices.autoScan setting. Persists to WowVisionPriceDB keyed by
-- realm + faction.

local module = WowVision.base:createModule("ahPrices")
local L = module.L
module:setLabel(L["Auction Prices"])

local settings = module:hasSettings()
settings:add({ type = "Number", key = "historyDays", label = L["History Days"], default = 21 })
settings:add({ type = "Number", key = "meanDays", label = L["Mean Days"], default = 7 })
settings:add({ type = "Bool", key = "tooltipPrices", label = L["Tooltip Prices"], default = true })
settings:add({ type = "Bool", key = "autoScan", label = L["Auto Scan"], default = false })

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------

local DAY_EPOCH = 1577836800 -- 2020-01-01 00:00:00 UTC

local function today()
    return math.floor((time() - DAY_EPOCH) / 86400)
end

local function realmKey()
    local realm = GetNormalizedRealmName() or GetRealmName():gsub("%s+", "")
    local faction = UnitFactionGroup("player")
    return realm .. "-" .. faction
end

local function formatPrice(copper)
    if not copper or copper <= 0 then return nil end
    return C_CurrencyInfo.GetCoinText(copper)
end

local function extractItemId(link)
    if not link then return nil end
    local id = link:match("item:(%d+)")
    return id and tonumber(id) or nil
end

-----------------------------------------------------------------------
-- Database access
--
-- Per-realm shape: { prices = { [itemId] = entry }, vendors = { [itemId] = copper }, lastScan = unixTime }
--
-- Entry keys are short to keep WowVisionPriceDB.lua small; there can be
-- thousands of entries on a well-populated realm.
--   m = last-seen minimum buyout (per-unit copper)
--   d = day index when m was recorded (days since DAY_EPOCH)
--   h = { [day] = daily high per-unit copper }
--   l = { [day] = daily low per-unit copper }
--   a = { [day] = auction count sampled that day }
-----------------------------------------------------------------------

local db -- set in onEnable

local function ensureDB()
    if not WowVisionPriceDB then
        WowVisionPriceDB = {}
    end
    local key = realmKey()
    if not WowVisionPriceDB[key] then
        WowVisionPriceDB[key] = { prices = {}, vendors = {}, lastScan = 0 }
    end
    return WowVisionPriceDB[key]
end

local function pruneEntry(entry, maxAge)
    local cutoff = today() - maxAge
    for _, tbl in ipairs({ entry.h, entry.l, entry.a }) do
        if tbl then
            for day in pairs(tbl) do
                if day <= cutoff then
                    tbl[day] = nil
                end
            end
        end
    end
end

local function setPrice(itemId, minBuyout, auctionCount, maxAge)
    local d = today()
    local prices = db.prices
    local entry = prices[itemId]
    if not entry then
        entry = { m = minBuyout, d = d, h = {}, l = {}, a = {} }
        prices[itemId] = entry
    end

    entry.m = minBuyout
    entry.d = d

    local prevHigh = entry.h[d]
    entry.h[d] = prevHigh and math.max(prevHigh, minBuyout) or minBuyout

    local prevLow = entry.l[d]
    entry.l[d] = prevLow and math.min(prevLow, minBuyout) or minBuyout

    entry.a[d] = auctionCount

    pruneEntry(entry, maxAge)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

local api = {}

function api.getPrice(itemId)
    if not db then return nil end
    return db.prices[itemId]
end

function api.getVendorPrice(itemId)
    if not db then return nil end
    return db.vendors[itemId]
end

function api.getMeanPrice(itemId, days)
    if not db then return nil end
    local entry = db.prices[itemId]
    if not entry then return nil end
    days = days or 7
    local d = today()
    local total, count = 0, 0
    for i = 0, days - 1 do
        local dayKey = d - i
        local val = entry.l and entry.l[dayKey] or entry.h and entry.h[dayKey]
        if val then
            total = total + val
            count = count + 1
        end
    end
    if count == 0 then return nil end
    return math.floor(total / count)
end

function api.getPriceAge(itemId)
    if not db then return nil end
    local entry = db.prices[itemId]
    if not entry or not entry.d then return nil end
    return today() - entry.d
end

-----------------------------------------------------------------------
-- Full Scanner
-----------------------------------------------------------------------

local fullScanner = WowVision.tbcAH.AHFullScanner:new()

function api.startFullScan() fullScanner:start() end
function api.abortFullScan() fullScanner:abort() end
function api.isFullScanning() return fullScanner:isScanning() end
function api.canFullScan() return fullScanner:canScan() end
function api.getFullScanState() return fullScanner:getState() end
function api.getFullScanProgress() return fullScanner:getProgress() end
function api.getFullScanWaitElapsed() return fullScanner:getWaitElapsed() end
function api.getFullScanCooldownRemaining() return fullScanner:getCooldownRemaining() end

fullScanner.events.scanStarted:subscribe(module, function(self, event, totalAuctions)
    WowVision:speak(L["Full scan started"] .. ", " .. totalAuctions .. " " .. L["auctions"])
end)

fullScanner.events.scanComplete:subscribe(module, function(self, event, results)
    local maxAge = module.settings.historyDays or 21
    local count = 0
    for itemId, data in pairs(results) do
        setPrice(itemId, data.minBuyout, data.totalSeen, maxAge)
        count = count + 1
    end
    db.lastScan = time()
    WowVision:speak(L["Full scan complete"] .. ", " .. count .. " " .. L["items updated"])
end)

fullScanner.events.scanFailed:subscribe(module, function(self, event, reason)
    if reason == "aborted" then
        WowVision:speak(L["Full scan aborted"])
    elseif reason == "cooldown" then
        WowVision:speak(L["Cooldown active"])
    elseif reason == "ah_closed" then
        WowVision:speak(L["Auction not open"])
    else
        WowVision:speak(L["Full scan failed"])
    end
end)

-----------------------------------------------------------------------
-- Vendor price caching
-----------------------------------------------------------------------

local vendorFrame = CreateFrame("Frame")
vendorFrame:RegisterEvent("MERCHANT_SHOW")
vendorFrame:SetScript("OnEvent", function()
    if not db then return end
    local numItems = GetMerchantNumItems()
    for i = 1, numItems do
        local _, _, price, quantity, numAvailable = GetMerchantItemInfo(i)
        if numAvailable == -1 and price and price > 0 and quantity and quantity > 0 then
            local link = GetMerchantItemLink(i)
            local itemId = extractItemId(link)
            if itemId then
                db.vendors[itemId] = math.floor(price / quantity)
            end
        end
    end
end)

-----------------------------------------------------------------------
-- Tooltip hook
-----------------------------------------------------------------------

local function addPriceLines(tooltip)
    local _, link = tooltip:GetItem()
    local itemId = extractItemId(link)
    if not itemId then return end

    local entry = db.prices[itemId]
    if entry and entry.m then
        local priceText = formatPrice(entry.m)
        if priceText then
            local line = L["Auction Price"] .. ": " .. priceText
            local age = today() - (entry.d or 0)
            if age > 0 then
                line = line .. " (" .. age .. " " .. L["days ago"] .. ")"
            end
            tooltip:AddLine(line, 1, 1, 1)
        end

        local meanDays = module.settings.meanDays or 7
        local mean = api.getMeanPrice(itemId, meanDays)
        if mean then
            local meanText = formatPrice(mean)
            if meanText then
                tooltip:AddLine(meanDays .. "-" .. L["Day Mean"] .. ": " .. meanText, 1, 1, 1)
            end
        end
    end

    -- Vendor sell price from GetItemInfo
    local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(itemId)
    if sellPrice and sellPrice > 0 then
        local sellText = formatPrice(sellPrice)
        if sellText then
            tooltip:AddLine(L["Vendor Sell"] .. ": " .. sellText, 1, 1, 1)
        end
    end

    -- Vendor buy price from cache
    local vendorPrice = db.vendors[itemId]
    if vendorPrice then
        local buyText = formatPrice(vendorPrice)
        if buyText then
            tooltip:AddLine(L["Vendor Buy"] .. ": " .. buyText, 1, 1, 1)
        end
    end

    tooltip._wvPricesAdded = true
    tooltip:Show()
end

local function afterTooltipSet(tooltip)
    if not db or not module.settings.tooltipPrices then return end
    if tooltip._wvPricesAdded then return end
    if not tooltip:GetItem() then return end
    addPriceLines(tooltip)
end

-----------------------------------------------------------------------
-- AH open/close tracking
-----------------------------------------------------------------------

local ahOpen = false

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_SHOW" then
        ahOpen = true
        if module.settings.autoScan then
            local canScan = fullScanner:canScan()
            if canScan then
                fullScanner:start()
            end
        end
    elseif event == "AUCTION_HOUSE_CLOSED" then
        ahOpen = false
        if fullScanner:isScanning() then
            fullScanner:abort()
        end
    end
end)

-----------------------------------------------------------------------
-- Module lifecycle
-----------------------------------------------------------------------

function module:onEnable()
    db = ensureDB()
    fullScanner:setLastScanTime(db.lastScan)

    -- Hook all Set* methods that display item tooltips. hooksecurefunc runs
    -- AFTER the C function returns, so the tooltip is fully built (including
    -- reagent lines on recipes) before we append price lines.
    local itemSetMethods = {
        "SetHyperlink", "SetAuctionItem", "SetAuctionSellItem",
        "SetBagItem", "SetInventoryItem", "SetMerchantItem",
        "SetTradeSkillItem", "SetLootItem", "SetQuestItem",
        "SetQuestLogItem", "SetSendMailItem", "SetInboxItem",
        "SetTradePlayerItem", "SetTradeTargetItem",
        "SetGuildBankItem", "SetItemByID",
    }
    for _, method in ipairs(itemSetMethods) do
        if GameTooltip[method] then
            hooksecurefunc(GameTooltip, method, afterTooltipSet)
        end
    end

    GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
        tooltip._wvPricesAdded = nil
    end)
end

WowVision.ahPrices = api
