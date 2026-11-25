-- Where each item of the bags belongs, and what is said about it. No game call here but through hints.game
-- (module.lua), no price but through hints.market, so the headless suite covers it (tests.lua).
--
-- ONE function, hints.classify, puts every occupied slot into exactly one of three places, and both lists are built
-- from its answers, so no item can be in two places or fall between them:
--   "auction"  the item would sell for at least 10 percent more at the auction house than to a vendor, and it can be
--              auctioned (nothing says it is bound, it is not damaged);
--   "vendor"   a vendor buys it and it is not "auction": bound items, items without an auction price, items under the
--              threshold, damaged ones;
--   "none"     neither.
--
-- The decisions:
--  * The auction price is Market's typical price per item, the vendor price the game's sell price per item.
--  * "auction" when what the auction house pays after its cut (unless that is switched off) reaches vendor * 110 / 100,
--    compared in whole coppers, so exactly 10 percent is in. An item no vendor buys is "auction" with any price.
--  * Any sign of binding keeps an item out: the slot's own flag must be exactly false, the item location check must not
--    say bound, the bind type must be none, on equip or on use, and not bound to the account until equipped. A damaged
--    item is out too (the auction house refuses it until repaired). Any doubt keeps it out.
--  * One line per item, however many stacks hold it.
local hints = WowVision.auctionHints
local L = WowVision:getLocale()

-- At least this many percent above the vendor price.
hints.PERCENT = 10
-- Prices older than this are called old.
hints.OLD_SECONDS = 24 * 3600

-- Item bind types that are not bound: none, bound when equipped, bound when used.
local NOT_BOUND = { [0] = true, [2] = true, [3] = true }

-- "{count}" and the like replaced by the values of the table; the order of the words differs between languages.
local function fill(template, values)
    return (template:gsub("{(%w+)}", function(name)
        local value = values[name]
        if value == nil then
            return nil
        end
        return tostring(value)
    end))
end
hints.fill = fill

-- The auction house's cut, in percent, taken off its price before the threshold is judged; 0 with the setting off.
function hints.cutFor(snapshot)
    if not hints.game.countCut() then
        return 0
    end
    return snapshot.cut or 5
end

-- Why a slot is not for the auction house, or nil when it is: "bound" or "damaged".
local function auctionBlock(info, item, bag, slot)
    local game = hints.game
    if info.bound ~= false then
        return "bound"
    end
    if game.locationBound(bag, slot) == true or not NOT_BOUND[item.bindType] then
        return "bound"
    end
    if game.accountBoundUntilEquip(info.itemID) == true then
        return "bound"
    end
    local current, maximum = game.durability(bag, slot)
    if current ~= nil and maximum ~= nil and current < maximum then
        return "damaged"
    end
    return nil
end

local function worthTheAuction(auction, vendor, cut)
    return auction * (100 - cut) >= vendor * (100 + hints.PERCENT)
end

-- Where the item of a slot belongs: nil and why it is not placed ("empty", "unreadable", "pending": the game has not
-- loaded the item), or { kind, why (why it is not for the auction house), bag, slot, itemID, name, quality, count,
-- vendorUnit, auctionUnit, cut, gain, percent }.
function hints.classify(bag, slot, snapshot)
    local game = hints.game
    local info = game.slotInfo(bag, slot)
    if info == nil then
        return nil, "empty"
    end
    if info.unreadable then
        return nil, "unreadable"
    end
    local item = game.itemInfo(info.link or info.itemID)
    if item == nil then
        return nil, "pending"
    end
    local vendor = item.sellPrice
    if type(vendor) ~= "number" then
        if info.hasNoValue then
            vendor = 0
        else
            return nil, "pending"
        end
    end
    local result = {
        bag = bag,
        slot = slot,
        itemID = info.itemID,
        name = item.name,
        quality = item.quality,
        count = info.count,
        vendorUnit = vendor,
    }
    local cut = hints.cutFor(snapshot)
    local why = auctionBlock(info, item, bag, slot)
    if why == nil then
        local auction = snapshot.price(info.itemID)
        result.auctionUnit = auction
        if auction == nil then
            why = "noprice"
        elseif not worthTheAuction(auction, vendor, cut) then
            why = "below"
        end
    end
    result.why = why
    if why == nil then
        result.kind = "auction"
        local net = result.auctionUnit * (100 - cut) / 100
        result.cut = cut
        result.gain = (net - vendor) * info.count
        -- percent above the vendor price, nil when a vendor pays nothing
        result.percent = vendor > 0 and (net - vendor) * 100 / vendor or nil
    elseif vendor > 0 then
        result.kind = "vendor"
    else
        result.kind = "none"
    end
    return result
end

-- What one item of this id is worth outside any slot, by the same rules: { unit (copper per item), how ("auction",
-- "vendor" or "none"), vendorUnit, auctionUnit }, or nil when the game has not loaded the item. For other modules that
-- value items (snapshot: hints.market.snapshot(), nil for vendor prices only).
function hints.valueOfItem(itemID, snapshot)
    local item = hints.game.itemInfo(itemID)
    if item == nil or type(item.sellPrice) ~= "number" then
        return nil
    end
    local vendor = item.sellPrice
    local bound = not NOT_BOUND[item.bindType] or hints.game.accountBoundUntilEquip(itemID) == true
    local auction = nil
    if not bound and snapshot ~= nil then
        auction = snapshot.price(itemID)
    end
    if auction ~= nil then
        local cut = hints.cutFor(snapshot)
        if worthTheAuction(auction, vendor, cut) then
            return { unit = auction * (100 - cut) / 100, how = "auction", vendorUnit = vendor, auctionUnit = auction }
        end
    end
    return { unit = vendor, how = vendor > 0 and "vendor" or "none", vendorUnit = vendor, auctionUnit = auction }
end

local function before(a, b)
    if a.bag ~= b.bag then
        return a.bag < b.bag
    end
    return a.slot < b.slot
end

-- One line per item out of a list of slots: the stacks added up, the line acting on its first stack.
local function linesOf(slots)
    local byItem, lines = {}, {}
    for _, slot in ipairs(slots) do
        local line = byItem[slot.itemID]
        if line == nil then
            line = {
                itemID = slot.itemID,
                name = slot.name,
                quality = slot.quality,
                vendorUnit = slot.vendorUnit,
                auctionUnit = slot.auctionUnit,
                percent = slot.percent,
                cut = slot.cut,
                count = 0,
                gain = 0,
                piles = {},
            }
            byItem[slot.itemID] = line
            tinsert(lines, line)
        end
        line.count = line.count + slot.count
        line.gain = line.gain + (slot.gain or 0)
        tinsert(line.piles, { bag = slot.bag, slot = slot.slot, count = slot.count, button = slot.button })
    end
    for _, line in ipairs(lines) do
        table.sort(line.piles, before)
        local first = line.piles[1]
        line.bag, line.slot, line.button = first.bag, first.slot, first.button
        line.stacks = #line.piles
    end
    return lines
end

-- positions: { { bag, slot, button }, ... }. Answers { auction = lines, biggest gain first; merchant = lines, in bag
-- order; counts = { total, auction, vendor, none, bound, damaged, noprice, below, pending, unreadable } }.
function hints.scan(positions, snapshot)
    local counts = {
        total = 0,
        auction = 0,
        vendor = 0,
        none = 0,
        bound = 0,
        damaged = 0,
        noprice = 0,
        below = 0,
        pending = 0,
        unreadable = 0,
    }
    local auctionSlots, merchantSlots = {}, {}
    for _, position in ipairs(positions) do
        local ok, result, reason = pcall(hints.classify, position.bag, position.slot, snapshot)
        if not ok then
            hints.game.report(result)
            result, reason = nil, "unreadable"
        end
        if reason ~= "empty" then
            counts.total = counts.total + 1
        end
        if result == nil then
            if counts[reason] ~= nil then
                counts[reason] = counts[reason] + 1
            end
        else
            counts[result.kind] = counts[result.kind] + 1
            if result.why ~= nil then
                counts[result.why] = counts[result.why] + 1
            end
            result.button = position.button
            if result.kind == "auction" then
                tinsert(auctionSlots, result)
            elseif result.kind == "vendor" then
                tinsert(merchantSlots, result)
            end
        end
    end
    local auction = linesOf(auctionSlots)
    for _, line in ipairs(auction) do
        line.auctionTotal = line.auctionUnit * line.count
    end
    table.sort(auction, function(a, b)
        if a.gain ~= b.gain then
            return a.gain > b.gain
        end
        return before(a, b)
    end)
    local merchant = linesOf(merchantSlots)
    table.sort(merchant, before)
    return { auction = auction, merchant = merchant, counts = counts }
end

-- What the places hold now: hints.scan's answer, plus snapshot (the prices read) and cut, or problem ("nomarket" or
-- "noprices": nothing is for the auction house then).
function hints.compute(positions)
    local snapshot, problem = hints.market.snapshot()
    if snapshot == nil then
        local result = hints.scan(positions, {
            price = function()
                return nil
            end,
        })
        result.problem = problem
        return result
    end
    local result = hints.scan(positions, snapshot)
    result.snapshot = snapshot
    result.cut = hints.cutFor(snapshot)
    return result
end

-- The words ---------------------------------------------------------------------

local MONTHS = {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
}

function hints.dateText(moment)
    local parts = hints.game.dateParts(moment)
    return fill(L["{month} {day} at {hour}:{minute}"], {
        month = L[MONTHS[parts.month]],
        day = parts.day,
        hour = parts.hour,
        minute = string.format("%02d", parts.min),
    })
end

-- How long ago, in the largest unit that fits; a moment to come is "just now".
function hints.agoText(seconds)
    if seconds < 90 then
        return L["just now"]
    end
    local count, unit
    if seconds < 3570 then
        count, unit = math.floor(seconds / 60 + 0.5), "minute"
    elseif seconds < 84600 then
        count, unit = math.floor(seconds / 3600 + 0.5), "hour"
    else
        count, unit = math.floor(seconds / 86400 + 0.5), "day"
    end
    return fill(L["{count} " .. unit .. (count == 1 and "" or "s") .. " ago"], { count = count })
end

-- How old the prices are, and where they come from, as sentences.
function hints.priceSentences(snapshot, now)
    local sentences = {}
    if snapshot.built == nil then
        tinsert(sentences, L["Prices from Life on Azeroth Market, date unknown."])
    else
        local age = now - snapshot.built
        if age > hints.OLD_SECONDS then
            tinsert(sentences, L["Warning, these prices are old."])
        end
        tinsert(
            sentences,
            fill(L["Prices from Life on Azeroth Market, taken {date}, {ago}."], {
                date = hints.dateText(snapshot.built),
                ago = hints.agoText(age),
            })
        )
    end
    if snapshot.house ~= nil and not snapshot.own then
        tinsert(sentences, fill(L["These are the prices of another auction house: {house}."], { house = snapshot.houseName }))
    end
    return sentences
end

-- "Linen Cloth", "Linen Cloth, 20" or "Linen Cloth, 20 in 3 stacks".
local function headText(line)
    local name = hints.game.itemName(line.name, line.quality)
    if line.stacks > 1 then
        return fill(L["{name}, {count} in {stacks} stacks"], { name = name, count = line.count, stacks = line.stacks })
    elseif line.count > 1 then
        return name .. ", " .. line.count
    end
    return name
end

-- The sentence of one line of the auction house stop.
function hints.lineText(line)
    local coin = hints.game.coinText
    local values = {
        vendor = coin(line.vendorUnit),
        auction = coin(line.auctionUnit),
        total = coin(line.auctionTotal),
        percent = line.percent ~= nil and math.floor(line.percent + 0.5) or nil,
        gain = coin(line.gain),
    }
    local several = line.count > 1
    local body
    if line.vendorUnit == 0 then
        if several then
            body = L[": the vendor does not buy it, auction house {auction} each, {total} in all, estimated gain {gain}"]
        else
            body = L[": the vendor does not buy it, auction house {auction}, estimated gain {gain}"]
        end
    elseif several then
        if line.cut > 0 then
            body = L[": vendor {vendor} each, auction house {auction} each, {total} in all, {percent} percent more after the cut, estimated gain {gain}"]
        else
            body = L[": vendor {vendor} each, auction house {auction} each, {total} in all, {percent} percent more, estimated gain {gain}"]
        end
    elseif line.cut > 0 then
        body = L[": vendor {vendor}, auction house {auction}, {percent} percent more after the cut, estimated gain {gain}"]
    else
        body = L[": vendor {vendor}, auction house {auction}, {percent} percent more, estimated gain {gain}"]
    end
    return headText(line) .. fill(body, values)
end

-- The summary said first: how many items, the total gain, what could not be checked, and how old the prices are.
function hints.summaryText(result, now)
    local title = L["For Sale at the Auction House"]
    if result.problem ~= nil then
        return fill(L["{title}: no prices available. Life on Azeroth Market is not installed, or its companion app has not made a price list yet."], { title = title })
    end
    local count = #result.auction
    local values = { title = title, count = count, percent = hints.PERCENT }
    local sentences = {}
    if count == 0 then
        tinsert(sentences, fill(L["{title}: no item in your bags sells for at least {percent} percent more at the auction house than to a vendor."], values))
        if result.cut > 0 then
            tinsert(sentences, fill(L["Prices counted after the auction house's cut of {cut} percent."], { cut = result.cut }))
        end
    else
        local key = count == 1
                and "{title}: {count} item sells for at least {percent} percent more at the auction house than to a vendor."
            or "{title}: {count} items sell for at least {percent} percent more at the auction house than to a vendor."
        tinsert(sentences, fill(L[key], values))
        local gain = 0
        for _, line in ipairs(result.auction) do
            gain = gain + line.gain
        end
        local coins = hints.game.coinText(gain)
        if result.cut > 0 then
            tinsert(sentences, fill(L["Estimated gain {gain}, after the auction house's cut of {cut} percent (the deposit comes back when an item sells)."], { gain = coins, cut = result.cut }))
        else
            tinsert(sentences, fill(L["Estimated gain {gain}, auction house fees not deducted."], { gain = coins }))
        end
    end
    local pending = result.counts.pending
    if pending > 0 then
        local key = pending == 1 and "{count} item is not loaded yet, its vendor price is unknown."
            or "{count} items are not loaded yet, their vendor prices are unknown."
        tinsert(sentences, fill(L[key], { count = pending }))
    end
    for _, sentence in ipairs(hints.priceSentences(result.snapshot, now)) do
        tinsert(sentences, sentence)
    end
    return table.concat(sentences, " ")
end

-- The command: the summary, then where the slots of the bags went and why the others are not in the list.
function hints.statusText(result, now)
    local counts = result.counts
    return hints.summaryText(result, now)
        .. " "
        .. fill(
            L["{lines} in the list. Slots in the list: {slots}. Slots to sell to a merchant: {merchant}. Occupied slots in your bags: {total}, kept out of the list: {bound} bound, {noprice} without an auction house price, {below} under {percent} percent, {damaged} damaged; {pending} not loaded."],
            {
                lines = #result.auction,
                slots = counts.auction,
                merchant = counts.vendor,
                total = counts.total,
                bound = counts.bound,
                noprice = counts.noprice,
                below = counts.below,
                percent = hints.PERCENT,
                damaged = counts.damaged,
                pending = counts.pending,
            }
        )
end
