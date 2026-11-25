-- What the fishing session is worth, and so the gold per hour, from Life on Azeroth Market's prices and the vendor's
-- prices instead of the ones Forever Fishing's own display uses (it only knows Auctionator and TSM, and without them it
-- values everything at the vendor's price). The rules are WowVision_AuctionHints' (Hints.valueOfItem, reached through
-- its WowVisionAuctionHints.values): for each item the auction house's price after its cut when that beats the vendor's
-- by 10 percent and the item is not bound, else the vendor's price. Without that addon the vendor's price alone.
--
-- game: sessionRecords() -> { { id =, count = }, ... } or nil (no session); sessionSeconds(); values(ids) -> results, meta
-- (results[id] = { unit, how = "auction" | "vendor" | "none" } or false when the item is not loaded; meta = { problem,
-- sentences }); coinText(copper).
local ns = WowVision.foreverFishing
local L = ns.L

local Value = {}
ns.Value = Value

-- Under this many seconds of fishing a rate would be a wild number: it is not given.
Value.MIN_SECONDS = 60

-- The worth of the session so far: { total (copper), perHour (copper or nil while it is too early), seconds, catches,
-- counts = { auction, vendor, none, pending }, meta }; nil when there is no session to value or the game cannot say.
function Value.estimate(game)
    if type(game.sessionRecords) ~= "function" or type(game.values) ~= "function" then
        return nil
    end
    local records = game.sessionRecords()
    if type(records) ~= "table" then
        return nil
    end
    local ids = {}
    for _, record in ipairs(records) do
        ids[#ids + 1] = record.id
    end
    local results, meta = game.values(ids)
    if type(results) ~= "table" then
        return nil
    end
    local counts = { auction = 0, vendor = 0, none = 0, pending = 0 }
    local total, catches = 0, 0
    for _, record in ipairs(records) do
        local count = record.count
        local worth = results[record.id]
        catches = catches + count
        if type(worth) == "table" and type(worth.unit) == "number" and counts[worth.how] ~= nil then
            total = total + worth.unit * count
            counts[worth.how] = counts[worth.how] + count
        else
            counts.pending = counts.pending + count
        end
    end
    local seconds = type(game.sessionSeconds) == "function" and game.sessionSeconds() or 0
    local perHour = nil
    if type(seconds) == "number" and seconds >= Value.MIN_SECONDS then
        perHour = total * 3600 / seconds
    end
    return { total = total, perHour = perHour, seconds = seconds, catches = catches, counts = counts, meta = meta or {} }
end

-- An amount of copper said whole: gold and silver, with the copper only while it is under one gold, as Forever
-- Fishing writes its own.
function Value.amountText(game, copper)
    copper = math.floor(math.max(0, copper) + 0.5)
    if copper >= 10000 then
        copper = math.floor(copper / 100 + 0.5) * 100
    end
    if type(game.coinText) == "function" then
        return game.coinText(copper)
    end
    return tostring(copper)
end

local function catchesText(count)
    return string.format(count == 1 and L["%d catch"] or L["%d catches"], count)
end

-- The lines the screen and the key add: gold per hour, then what the session holds and where the prices come from.
-- Each is { key =, text = }; none when there is nothing to say (the caller then keeps Forever Fishing's own text).
function Value.lines(game, estimate)
    local lines = {}
    if estimate == nil then
        return lines
    end
    local marketKnown = estimate.meta.problem == nil
    if estimate.perHour ~= nil then
        local key = marketKnown and "Gold per hour, from Life on Azeroth Market and vendor prices: %s"
            or "Gold per hour, at vendor prices only, without Life on Azeroth Market prices: %s"
        lines[#lines + 1] = { key = "gold", text = string.format(L[key], Value.amountText(game, estimate.perHour)) }
    else
        lines[#lines + 1] = { key = "gold", text = L["Gold per hour will be estimated after a minute of fishing."] }
    end
    if estimate.catches == 0 then
        lines[#lines + 1] = { key = "session", text = L["Nothing caught yet this session."] }
    else
        local parts = {}
        local counts = estimate.counts
        if counts.auction > 0 then
            parts[#parts + 1] = string.format(L["%d at the auction house price"], counts.auction)
        end
        if counts.vendor > 0 then
            parts[#parts + 1] = string.format(L["%d at the vendor price"], counts.vendor)
        end
        if counts.none > 0 then
            parts[#parts + 1] = string.format(L["%d worth nothing"], counts.none)
        end
        if counts.pending > 0 then
            parts[#parts + 1] = string.format(L["%d with no price yet"], counts.pending)
        end
        local text = string.format(L["This session: %s, worth %s."], catchesText(estimate.catches), Value.amountText(game, estimate.total))
        text = text .. " " .. table.concat(parts, ", ") .. "."
        lines[#lines + 1] = { key = "session", text = text }
    end
    if marketKnown and type(estimate.meta.sentences) == "table" and #estimate.meta.sentences > 0 then
        lines[#lines + 1] = { key = "market", text = table.concat(estimate.meta.sentences, " ") }
    end
    return lines
end
