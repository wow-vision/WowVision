-- The price database of the modern auction house (Retail and WoW: Forever):
-- what a full scan adds up per item, how it is stored per day, and the lines
-- an item tooltip gets from it. Pure Lua so the headless tests run it.
--
-- Stored per realm and faction in WowVisionPriceDB:
--   { prices = { [itemId] = entry }, vendors = { [itemId] = copper }, lastScan = unixTime }
--   entry = { s = { [day] = "min:max:avg:auctions:units" } }
-- A day is one short string, not a table: a well-populated realm has tens of
-- thousands of items, each with a record per day, and the file is read at
-- every login. Prices are per unit, in copper. A later scan of the same day
-- replaces that day: each scan is a whole snapshot of the auction house.

local prices = {}
WowVision.modernAH = WowVision.modernAH or {}
WowVision.modernAH.prices = prices

local DAY_EPOCH = 1577836800 -- 2020-01-01 00:00:00 UTC

-- The most days of prices that are ever kept or counted, whatever the setting says.
prices.MAX_HISTORY_DAYS = 30

function prices.dayOf(unixTime)
    return math.floor((unixTime - DAY_EPOCH) / 86400)
end

-- Adds one auction of a scan to its results. An auction without a buyout has
-- no price to record. Returns whether it counted.
function prices.addAuction(results, itemId, count, buyout)
    if itemId == nil or count == nil or buyout == nil or count <= 0 or buyout <= 0 then
        return false
    end
    local unit = math.floor(buyout / count)
    local result = results[itemId]
    if result == nil then
        results[itemId] = { min = unit, max = unit, copper = buyout, units = count, auctions = 1 }
        return true
    end
    result.min = math.min(result.min, unit)
    result.max = math.max(result.max, unit)
    result.copper = result.copper + buyout
    result.units = result.units + count
    result.auctions = result.auctions + 1
    return true
end

-- Concatenation, not string.format("%d"): buyouts go past 32 bits.
local function encode(result)
    return result.min
        .. ":"
        .. result.max
        .. ":"
        .. math.floor(result.copper / result.units)
        .. ":"
        .. result.auctions
        .. ":"
        .. result.units
end

local function decode(text)
    local min, max, avg, auctions, units = text:match("^(%d+):(%d+):(%d+):(%d+):(%d+)$")
    if min == nil then
        return nil
    end
    return {
        min = tonumber(min),
        max = tonumber(max),
        avg = tonumber(avg),
        auctions = tonumber(auctions),
        units = tonumber(units),
    }
end

-- The last day that is too old to keep or count.
local function cutoffOf(day, historyDays)
    local days = math.floor(historyDays or prices.MAX_HISTORY_DAYS)
    return day - math.min(prices.MAX_HISTORY_DAYS, math.max(1, days))
end

-- Writes the results of a scan as the given day and drops every record that is
-- historyDays old or older, of the items this scan did not see as well.
-- Returns the number of items written.
function prices.store(db, results, day, historyDays)
    local written = 0
    for itemId, result in pairs(results) do
        local entry = db.prices[itemId]
        if entry == nil then
            entry = { s = {} }
            db.prices[itemId] = entry
        end
        entry.s[day] = encode(result)
        written = written + 1
    end
    local cutoff = cutoffOf(day, historyDays)
    for itemId, entry in pairs(db.prices) do
        for recorded in pairs(entry.s) do
            if recorded <= cutoff then
                entry.s[recorded] = nil
            end
        end
        if next(entry.s) == nil then
            db.prices[itemId] = nil
        end
    end
    return written
end

-- The prices of an item over every day still counted: the lowest and highest
-- price of those days, the average weighted by units, days (how many days a
-- scan saw the item), age (days since the latest of them), or nil.
function prices.summary(db, itemId, today, historyDays)
    local entry = db.prices[itemId]
    if entry == nil then
        return nil
    end
    local cutoff = cutoffOf(today, historyDays)
    local stats, copper
    for day, text in pairs(entry.s) do
        local record = day > cutoff and decode(text) or nil
        if record ~= nil then
            if stats == nil then
                stats = { min = record.min, max = record.max, auctions = 0, units = 0, days = 0, latest = day }
                copper = 0
            end
            stats.min = math.min(stats.min, record.min)
            stats.max = math.max(stats.max, record.max)
            stats.auctions = stats.auctions + record.auctions
            stats.units = stats.units + record.units
            stats.days = stats.days + 1
            stats.latest = math.max(stats.latest, day)
            copper = copper + record.avg * record.units
        end
    end
    if stats == nil then
        return nil
    end
    stats.avg = math.floor(copper / stats.units)
    stats.age = math.max(0, today - stats.latest)
    return stats
end

-- The tooltip lines in reading order, each a line of its own. stats: from
-- prices.summary, or nil. coin(copper) gives the spoken price. A price the
-- database does not know has no line.
function prices.tooltipLines(L, coin, stats, vendorSell, vendorBuy)
    local lines = {}
    -- First, so it follows the game's own sell price at the end of the tooltip:
    -- that one counts the whole stack, this one a single item.
    if vendorSell ~= nil and vendorSell > 0 then
        lines[#lines + 1] = L["Vendor price per item"] .. ": " .. coin(vendorSell)
    end
    if stats ~= nil then
        -- The price is what the player waits for: it comes last in each line.
        local over = " " .. stats.days .. " " .. (stats.days == 1 and L["day"] or L["days"])
        local age = ""
        if stats.age > 0 then
            age = " (" .. stats.age .. " " .. L["days ago"] .. ")"
        end
        lines[#lines + 1] = L["Auction minimum"] .. over .. age .. ": " .. coin(stats.min)
        lines[#lines + 1] = L["Auction average"] .. over .. ": " .. coin(stats.avg)
        lines[#lines + 1] = L["Auction maximum"] .. over .. ": " .. coin(stats.max)
    end
    if vendorBuy ~= nil and vendorBuy > 0 then
        lines[#lines + 1] = L["Vendor Buy"] .. ": " .. coin(vendorBuy)
    end
    return lines
end
