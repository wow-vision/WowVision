-- Full scan and tooltip prices for the modern auction house (Retail and WoW:
-- Forever): settings on the auction window's module, the Full Scan button on
-- the Buy tab, the lines at the end of item tooltips. Everything here waits
-- for the Full Scan setting, which is off until the player turns it on.

local module = WowVision.base.windows.auction
local L = module.L
local graph = WowVision.graph
local secrets = WowVision.secrets
local prices = WowVision.modernAH.prices

local settings = module:hasSettings()
settings:add({ type = "Bool", key = "fullScan", label = L["Full Scan"], default = false })
settings:add({
    type = "Number",
    key = "historyDays",
    label = L["History Days"],
    default = prices.MAX_HISTORY_DAYS,
    min = 1,
    max = prices.MAX_HISTORY_DAYS,
})
settings:add({ type = "Bool", key = "tooltipPrices", label = L["Tooltip Prices"], default = true })

local db -- set in onEnable

local function ensureDB()
    if WowVisionPriceDB == nil then
        WowVisionPriceDB = {}
    end
    local realm = GetNormalizedRealmName() or GetRealmName():gsub("%s+", "")
    local key = realm .. "-" .. UnitFactionGroup("player")
    if WowVisionPriceDB[key] == nil then
        WowVisionPriceDB[key] = { prices = {}, vendors = {}, lastScan = 0 }
    end
    return WowVisionPriceDB[key]
end

local function today()
    return prices.dayOf(time())
end

local function coin(copper)
    return C_CurrencyInfo.GetCoinText(copper)
end

local function itemIdOfLink(link)
    if link == nil or secrets.isSecret(link) then
        return nil
    end
    local id = link:match("item:(%d+)")
    return id ~= nil and tonumber(id) or nil
end

------------------------------------------------------------
-- The scan
------------------------------------------------------------

local scanner = WowVision.modernAH.ReplicateScanner:new({
    api = C_AuctionHouse,
    createFrame = CreateFrame,
    now = GetTime,
    wallClock = time,
})

local spokenStep = 0 -- the last quarter of the progress that was said

scanner.events.scanRequested:subscribe(module, function()
    db.lastScan = time()
    WowVision:notify(L["Scanning"])
end)

scanner.events.scanStarted:subscribe(module, function(_, _, total)
    spokenStep = 0
    WowVision:notify(L["Full scan started"] .. ", " .. total .. " " .. L["auctions"])
end)

scanner.events.scanProgress:subscribe(module, function(_, _, processed, total)
    local step = math.floor(processed * 4 / total)
    if step > spokenStep and step < 4 then
        spokenStep = step
        WowVision:notify(L["Scanning"] .. ", " .. (step * 25) .. "%")
    end
end)

scanner.events.scanComplete:subscribe(module, function(_, _, results)
    local count = prices.store(db, results, today(), module.settings.historyDays)
    WowVision:notify(L["Full scan complete"] .. ", " .. count .. " " .. L["items updated"])
end)

scanner.events.scanFailed:subscribe(module, function(_, _, reason)
    if reason == "aborted" then
        WowVision:notify(L["Full scan aborted"])
    elseif reason == "cooldown" then
        WowVision:notify(L["Cooldown active"])
    elseif reason == "ah_closed" then
        WowVision:notify(L["Auction not open"])
    else
        WowVision:notify(L["Full scan failed"])
    end
end)

local function cooldownText(seconds)
    local minutes = math.floor(seconds / 60)
    local rest = math.floor(seconds % 60)
    if minutes > 0 and rest > 0 then
        return minutes .. " min " .. rest .. " sec"
    elseif minutes > 0 then
        return minutes .. " min"
    end
    return rest .. " sec"
end

local function buttonLabel()
    local state = scanner:getState()
    if state == "waiting" then
        return L["Scanning"] .. ", " .. math.floor(scanner:getWaitElapsed()) .. " sec"
    elseif state == "processing" then
        local progress = scanner:getProgress()
        return L["Scanning"] .. ", " .. math.floor(progress.processed * 100 / progress.total) .. "%"
    end
    if scanner:canScan() then
        return L["Full Scan"]
    end
    return L["Full Scan"] .. ", " .. L["Cooldown active"]
end

local function activate()
    if scanner:isScanning() then
        scanner:abort()
    elseif scanner:canScan() then
        scanner:start()
    else
        WowVision:speak(cooldownText(scanner:getCooldownRemaining()))
    end
end

-- mists/auction.lua calls this at the end of the Buy tab.
function module.renderFullScan(builder)
    if not module.settings.fullScan then
        return
    end
    builder:beginStop("fullScan")
    builder:addItem(
        graph.ControlId.structural("fullScan"),
        graph.nodes.button({ label = buttonLabel, onActivate = activate })
    )
end

------------------------------------------------------------
-- What vendors charge
------------------------------------------------------------

local vendorFrame = CreateFrame("Frame")
vendorFrame:RegisterEvent("MERCHANT_SHOW")
vendorFrame:SetScript("OnEvent", function()
    if db == nil or not module.settings.fullScan then
        return
    end
    for index = 1, GetMerchantNumItems() do
        local info = C_MerchantFrame.GetItemInfo(index)
        if
            info ~= nil
            and info.numAvailable == -1
            and not info.hasExtendedCost
            and info.price ~= nil
            and info.price > 0
            and info.stackCount ~= nil
            and info.stackCount > 0
        then
            local itemId = itemIdOfLink(GetMerchantItemLink(index))
            if itemId ~= nil then
                db.vendors[itemId] = math.floor(info.price / info.stackCount)
            end
        end
    end
end)

------------------------------------------------------------
-- Tooltips: the price lines come last, after everything the game wrote
------------------------------------------------------------

local function appendPrices(tooltip, itemId)
    if db == nil or itemId == nil or not module.settings.fullScan or not module.settings.tooltipPrices then
        return false
    end
    if tooltip:IsForbidden() then
        return false
    end
    local stats = prices.summary(db, itemId, today(), module.settings.historyDays)
    local vendorSell = select(11, C_Item.GetItemInfo(itemId))
    local lines = prices.tooltipLines(L, coin, stats, vendorSell, db.vendors[itemId])
    for _, line in ipairs(lines) do
        tooltip:AddLine(line, 1, 1, 1)
    end
    if #lines > 0 then
        tooltip:Show()
    end
    return true
end

local function itemIdOfTooltip(tooltip, data)
    if data ~= nil and data.id ~= nil and not secrets.isSecret(data.id) then
        return data.id
    end
    local _, link = tooltip:GetItem()
    return itemIdOfLink(link)
end

-- Clients that expose the processor without running their tooltips through it
-- have no GetPrimaryTooltipData: those get the setter hooks.
local function usesTooltipData()
    return type(GameTooltip.GetPrimaryTooltipData) == "function"
        and TooltipDataProcessor ~= nil
        and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
        and Enum ~= nil
        and Enum.TooltipDataType ~= nil
end

local ITEM_SETTERS = {
    "SetHyperlink",
    "SetAuctionItem",
    "SetAuctionSellItem",
    "SetBagItem",
    "SetInventoryItem",
    "SetMerchantItem",
    "SetTradeSkillItem",
    "SetLootItem",
    "SetQuestItem",
    "SetQuestLogItem",
    "SetSendMailItem",
    "SetInboxItem",
    "SetTradePlayerItem",
    "SetTradeTargetItem",
    "SetGuildBankItem",
    "SetItemByID",
}

local function hookSetters()
    local function afterSet(tooltip)
        if not tooltip._wvPricesAdded and appendPrices(tooltip, itemIdOfTooltip(tooltip)) then
            tooltip._wvPricesAdded = true
        end
    end
    for _, method in ipairs(ITEM_SETTERS) do
        if GameTooltip[method] ~= nil then
            hooksecurefunc(GameTooltip, method, afterSet)
        end
    end
    GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
        tooltip._wvPricesAdded = nil
    end)
end

local tooltipsHooked = false

function module:onEnable()
    db = ensureDB()
    scanner:setLastScanTime(db.lastScan)
    if tooltipsHooked then
        return
    end
    tooltipsHooked = true
    if usesTooltipData() then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip == GameTooltip or tooltip == ItemRefTooltip then
                appendPrices(tooltip, itemIdOfTooltip(tooltip, data))
            end
        end)
    else
        hookSetters()
    end
end
