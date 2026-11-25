local testRunner = WowVision.testing.testRunner
local hints = WowVision.auctionHints
local market = hints.market

local NOW = 1795140000

-- Items of the stand-in game: sell price per item, bind type (0 none, 1 when picked up, 2 when equipped, 3 when used).
local ITEMS = {
    [1] = { name = "Herb", sellPrice = 300, bindType = 0 },
    [2] = { name = "Ring", sellPrice = 500, bindType = 2 },
    [3] = { name = "Bound Blade", sellPrice = 1000, bindType = 1 },
    [4] = { name = "Potion", sellPrice = 1000, bindType = 3 },
    [5] = { name = "Account Cape", sellPrice = 100, bindType = 2, accountUntilEquip = true },
    [6] = { name = "Trinket", sellPrice = 0, bindType = 0 },
    [7] = { name = "Soulbound Trinket", sellPrice = 0, bindType = 1 },
    [8] = { name = "Quest Letter", sellPrice = 100, bindType = 4 },
}

-- Prices in copper per item: item 1 is exactly 10 percent above after a 5 percent cut at 348, just under at 347.
local PRICES = "1,348,300,5,5,\n2,1000,900,4,4,\n3,4000,1,1,1,\n4,1500,1,1,1,\n5,9000,1,1,1,\n6,700,1,1,1,\n7,800,1,1,1,\n8,900,1,1,1,\n"

-- A stand-in game: bags[bag][slot] = { id, count, bound, damaged, link, hidden, locationBound }.
local function withGame(test, options)
    options = options or {}
    local world = {
        bags = options.bags or {},
        countCut = true,
        data = { built = NOW - 3 * 3600, region = "eu", houses = { ["1H"] = { latS = PRICES } } },
        settings = nil,
        realm = "Spineshatter",
        faction = "Horde",
        reports = {},
        loaded = {},
    }
    local saved = {}
    for key, value in pairs(hints.game) do
        saved[key] = value
    end
    local game = hints.game
    game.countCut = function()
        return world.countCut
    end
    game.report = function(err)
        tinsert(world.reports, err)
    end
    game.market = function()
        return world.data
    end
    game.marketSettings = function()
        return world.settings
    end
    game.realmName = function()
        return world.realm
    end
    game.faction = function()
        return world.faction
    end
    game.dateParts = function()
        return { month = 11, day = 19, hour = 23, min = 5 }
    end
    game.slotInfo = function(bag, slot)
        local item = world.bags[bag] ~= nil and world.bags[bag][slot] or nil
        if item == nil then
            return nil
        end
        if item.hidden then
            return { unreadable = true }
        end
        local bound = item.bound
        if bound == nil and not item.unknownBound then
            bound = false
        end
        return { itemID = item.id, link = "item:" .. item.id, count = item.count or 1, bound = bound, hasNoValue = item.noValue }
    end
    game.itemInfo = function(linkOrID)
        local id = tonumber(linkOrID) or tonumber(linkOrID:match("item:(%d+)"))
        local item = ITEMS[id]
        if item == nil or world.loaded[id] == false then
            return nil
        end
        if world.noSellPrice == id then
            return { name = item.name, bindType = item.bindType }
        end
        return { name = item.name, sellPrice = item.sellPrice, bindType = item.bindType }
    end
    game.locationBound = function(bag, slot)
        return world.bags[bag][slot].locationBound
    end
    game.accountBoundUntilEquip = function(id)
        return ITEMS[id].accountUntilEquip == true
    end
    game.durability = function(bag, slot)
        local item = world.bags[bag][slot]
        if item.damaged then
            return 10, 20
        end
        return 20, 20
    end
    game.coinText = function(copper)
        return math.floor(copper + 0.5) .. "c"
    end
    game.itemName = function(name)
        return name
    end
    local ok, err = pcall(test, world)
    for key in pairs(game) do
        game[key] = nil
    end
    for key, value in pairs(saved) do
        game[key] = value
    end
    if not ok then
        error(err, 0)
    end
end

local function positions(...)
    local list = {}
    for _, p in ipairs({ ... }) do
        tinsert(list, { bag = p[1], slot = p[2], button = p[1] .. ":" .. p[2] })
    end
    return list
end

local function kindOf(bag, slot)
    local result, reason = hints.classify(bag, slot, market.snapshot())
    if result == nil then
        return reason
    end
    return result.kind, result.why
end

testRunner:addSuite("AuctionHintsMarket", {
    ["the realm's kind comes from its name"] = function(t)
        t:assertEqual(market.ruleset("Spineshatter"), "Normal")
        t:assertEqual(market.ruleset("Firemaw PvP"), "PvP")
        t:assertEqual(market.ruleset("Mirage Raceway RP"), "Roleplay")
        t:assertEqual(market.ruleset("Zandalar RPPvP"), "Roleplay PvP")
        t:assertEqual(market.ruleset("Zandalar RP-PvP"), "Roleplay PvP")
        t:assertEqual(market.ruleset("A RP PvP realm"), "Roleplay PvP")
        t:assertNil(market.ruleset(""))
        t:assertNil(market.ruleset(nil))
    end,

    ["the player's own house is chosen, else the picked one, else the first"] = function(t)
        withGame(function(world)
            t:assertEqual(market.ownHouse(), "1H")
            world.faction = "Alliance"
            t:assertEqual(market.ownHouse(), "1A")
            world.faction = "Neutral"
            t:assertNil(market.ownHouse())
            world.faction = "Horde"
            local data = { houses = { ["1H"] = {}, ["2H"] = {}, ["0A"] = {} } }
            local key, own = market.chooseHouse(data)
            t:assertEqual(key, "1H")
            t:assertTrue(own)
            data.houses["1H"] = nil
            world.settings = { house = "2H" }
            key, own = market.chooseHouse(data)
            t:assertEqual(key, "2H")
            t:assertFalse(own)
            world.settings = { house = "auto" }
            t:assertEqual(market.chooseHouse(data), "0A")
            t:assertNil(market.chooseHouse({}))
        end)
    end,

    ["houses are named and cut as Market does"] = function(t)
        t:assertEqual(market.houseName("1H"), "Normal Horde")
        t:assertEqual(market.houseName("3B"), "Roleplay PvP Blackwater")
        t:assertNil(market.houseName("1"))
        t:assertEqual(market.cutOf("1H"), 5)
        t:assertEqual(market.cutOf("1B"), 15)
        t:assertEqual(market.cutOf(nil), 5)
    end,

    ["prices are read from the text lines or the parsed table, whole ids only"] = function(t)
        withGame(function(world)
            world.data.houses["1H"] = { latS = "11,50,1,\n1,40,1,\n100,0,1,\n12,7.5,1,\n" }
            local snapshot = market.snapshot()
            t:assertEqual(snapshot.price(11), 50)
            t:assertEqual(snapshot.price(1), 40)
            t:assertNil(snapshot.price(100))
            t:assertEqual(snapshot.price(12), 7.5)
            t:assertNil(snapshot.price(2))
            t:assertEqual(snapshot.built, NOW - 3 * 3600)
            t:assertTrue(snapshot.own)
            world.data.houses["1H"] = { lat = { [5] = { 60, 1 } } }
            snapshot = market.snapshot()
            t:assertEqual(snapshot.price(5), 60)
            t:assertNil(snapshot.price(1))
        end)
    end,

    ["without houses the region's prices are read, and without data there is a reason"] = function(t)
        withGame(function(world)
            world.data = { region = "eu", latest = 5, latS = { eu = "1,40,\n" } }
            local snapshot = market.snapshot()
            t:assertEqual(snapshot.price(1), 40)
            t:assertEqual(snapshot.built, 5)
            t:assertFalse(snapshot.own)
            world.data = { region = "us", latS = { eu = "1,40,\n" } }
            local none, why = market.snapshot()
            t:assertNil(none)
            t:assertEqual(why, "noprices")
            world.data = nil
            none, why = market.snapshot()
            t:assertEqual(why, "nomarket")
        end)
    end,
})

testRunner:addSuite("AuctionHints", {
    ["an item at least 10 percent above after the cut goes to the auction house"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 1 } } }
            t:assertEqual(kindOf(0, 1), "auction")
            world.data.houses["1H"].latS = "1,347,1,\n"
            local kind, why = kindOf(0, 1)
            t:assertEqual(kind, "vendor")
            t:assertEqual(why, "below")
            world.countCut = false
            t:assertEqual(kindOf(0, 1), "auction")
            world.data.houses["1H"].latS = "1,330,1,\n"
            t:assertEqual(kindOf(0, 1), "auction")
            world.data.houses["1H"].latS = "1,329,1,\n"
            t:assertEqual(kindOf(0, 1), "vendor")
        end)
    end,

    ["anything that says bound, and damage, keeps an item out"] = function(t)
        withGame(function(world)
            world.bags = {
                [0] = {
                    { id = 3 },
                    { id = 2, bound = true },
                    { id = 2, locationBound = true },
                    { id = 5 },
                    { id = 8 },
                    { id = 2, damaged = true },
                    { id = 4 },
                    { id = 2 },
                },
            }
            for slot, expected in ipairs({ "bound", "bound", "bound", "bound", "bound", "damaged" }) do
                local kind, why = kindOf(0, slot)
                t:assertEqual(kind, "vendor")
                t:assertEqual(why, expected)
            end
            t:assertEqual(kindOf(0, 7), "auction")
            t:assertEqual(kindOf(0, 8), "auction")
        end)
    end,

    ["an item no vendor buys goes to the auction house with any price, else nowhere"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 6 }, { id = 7 } } }
            local result = hints.classify(0, 1, market.snapshot())
            t:assertEqual(result.kind, "auction")
            t:assertNil(result.percent)
            t:assertEqual(kindOf(0, 2), "none")
        end)
    end,

    ["a slot the game does not call unbound counts as bound"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 2, unknownBound = true } } }
            local kind, why = kindOf(0, 1)
            t:assertEqual(kind, "vendor")
            t:assertEqual(why, "bound")
        end)
    end,

    ["a missing sell price waits for the item, unless the slot has no value"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 1 }, { id = 1, noValue = true } } }
            world.noSellPrice = 1
            t:assertEqual(kindOf(0, 1), "pending")
            local result = hints.classify(0, 2, market.snapshot())
            t:assertEqual(result.vendorUnit, 0)
            t:assertEqual(result.kind, "auction")
        end)
    end,

    ["merchant lines come in the order of the bags whatever the order given"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 3 } }, [1] = { { id = 8 } } }
            local result = hints.scan(positions({ 1, 1 }, { 0, 1 }), market.snapshot())
            t:assertEqual(result.merchant[1].itemID, 3)
            t:assertEqual(result.merchant[2].itemID, 8)
        end)
    end,

    ["empty, hidden and unloaded slots are not placed"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { [2] = { id = 1, hidden = true }, [3] = { id = 1 } } }
            world.loaded[1] = false
            t:assertEqual(kindOf(0, 1), "empty")
            t:assertEqual(kindOf(0, 2), "unreadable")
            t:assertEqual(kindOf(0, 3), "pending")
        end)
    end,

    ["the lines add up the stacks of an item and order by gain, the merchant ones by bag"] = function(t)
        withGame(function(world)
            world.bags = {
                [1] = { { id = 2, count = 1 }, { id = 3 } },
                [0] = { { id = 1, count = 10 }, { id = 2, count = 2 }, { id = 3, count = 1 }, { id = 4 } },
            }
            local result = hints.scan(
                positions({ 1, 1 }, { 1, 2 }, { 0, 1 }, { 0, 2 }, { 0, 3 }, { 0, 4 }, { 0, 9 }),
                market.snapshot()
            )
            t:assertEqual(#result.auction, 3)
            -- ring: 3 at 950 net against 500 is 1350; potion: 1425 against 1000 is 425; herbs: 10 at 330.6 is 306
            t:assertEqual(result.auction[1].itemID, 2)
            t:assertEqual(result.auction[1].count, 3)
            t:assertEqual(result.auction[1].stacks, 2)
            t:assertEqual(result.auction[1].bag, 0)
            t:assertEqual(result.auction[1].slot, 2)
            t:assertEqual(result.auction[1].button, "0:2")
            t:assertEqual(result.auction[1].auctionTotal, 3000)
            t:assertEqual(result.auction[2].itemID, 4)
            t:assertEqual(result.auction[3].itemID, 1)
            t:assertEqual(#result.merchant, 1)
            t:assertEqual(result.merchant[1].itemID, 3)
            t:assertEqual(result.merchant[1].button, "0:3")
            t:assertEqual(result.counts.total, 6)
            t:assertEqual(result.counts.auction, 4)
            t:assertEqual(result.counts.vendor, 2)
            t:assertEqual(result.counts.bound, 2)
        end)
    end,

    ["a slot that fails is reported and counted as unreadable"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 1 } } }
            hints.game.itemInfo = function()
                error("boom")
            end
            local result = hints.scan(positions({ 0, 1 }), market.snapshot())
            t:assertEqual(result.counts.unreadable, 1)
            t:assertEqual(#world.reports, 1)
        end)
    end,

    ["without prices nothing is for the auction house and the summary says why"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 2 } } }
            world.data = nil
            local result = hints.compute(positions({ 0, 1 }))
            t:assertEqual(result.problem, "nomarket")
            t:assertEqual(#result.auction, 0)
            t:assertEqual(#result.merchant, 1)
            t:assertTrue(hints.summaryText(result, NOW):find("no prices available", 1, true) ~= nil)
        end)
    end,

    ["the summary gives the count, the gain after the cut and the age of the prices"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 2 }, { id = 4 } } }
            local text = hints.summaryText(hints.compute(positions({ 0, 1 }, { 0, 2 })), NOW)
            t:assertEqual(
                text,
                "For Sale at the Auction House: 2 items sell for at least 10 percent more at the auction house than to a vendor. "
                    .. "Estimated gain 875c, after the auction house's cut of 5 percent (the deposit comes back when an item sells). "
                    .. "Prices from Life on Azeroth Market, taken November 19 at 23:05, 3 hours ago."
            )
            world.countCut = false
            text = hints.summaryText(hints.compute(positions({ 0, 1 })), NOW)
            t:assertTrue(text:find("1 item sells", 1, true) ~= nil)
            t:assertTrue(text:find("auction house fees not deducted", 1, true) ~= nil)
        end)
    end,

    ["the summary of an empty result, unloaded items, old and borrowed prices"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 3 }, { id = 1 } } }
            world.loaded[1] = false
            world.faction = "Alliance"
            world.data.built = NOW - 2 * 86400
            local text = hints.summaryText(hints.compute(positions({ 0, 1 }, { 0, 2 })), NOW)
            t:assertTrue(text:find("no item in your bags sells", 1, true) ~= nil)
            t:assertTrue(text:find("cut of 5 percent", 1, true) ~= nil)
            t:assertTrue(text:find("1 item is not loaded yet", 1, true) ~= nil)
            t:assertTrue(text:find("Warning, these prices are old.", 1, true) ~= nil)
            t:assertTrue(text:find("2 days ago", 1, true) ~= nil)
            t:assertTrue(text:find("another auction house: Normal Horde", 1, true) ~= nil)
            world.data.built = nil
            text = hints.summaryText(hints.compute(positions({ 0, 1 })), NOW)
            t:assertTrue(text:find("date unknown", 1, true) ~= nil)
        end)
    end,

    ["how long ago is said in the largest unit"] = function(t)
        t:assertEqual(hints.agoText(0), "just now")
        t:assertEqual(hints.agoText(-10), "just now")
        t:assertEqual(hints.agoText(89), "just now")
        t:assertEqual(hints.agoText(90), "2 minutes ago")
        t:assertEqual(hints.agoText(3569), "59 minutes ago")
        t:assertEqual(hints.agoText(3600), "1 hour ago")
        t:assertEqual(hints.agoText(84599), "23 hours ago")
        t:assertEqual(hints.agoText(85000), "1 day ago")
        t:assertEqual(hints.agoText(86400), "1 day ago")
    end,

    ["a line says the quantity, the prices, the difference and the gain"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 2, count = 2 }, { id = 2, count = 1 }, { id = 6 }, { id = 4 } } }
            local result = hints.compute(positions({ 0, 1 }, { 0, 2 }, { 0, 3 }, { 0, 4 }))
            t:assertEqual(
                hints.lineText(result.auction[1]),
                "Ring, 3 in 2 stacks: vendor 500c each, auction house 1000c each, 3000c in all, 90 percent more after the cut, estimated gain 1350c"
            )
            local texts = {}
            for _, line in ipairs(result.auction) do
                texts[line.itemID] = hints.lineText(line)
            end
            t:assertEqual(texts[6], "Trinket: the vendor does not buy it, auction house 700c, estimated gain 665c")
            t:assertEqual(
                texts[4],
                "Potion: vendor 1000c, auction house 1500c, 43 percent more after the cut, estimated gain 425c"
            )
            world.countCut = false
            result = hints.compute(positions({ 0, 1 }, { 0, 4 }))
            t:assertEqual(
                hints.lineText(result.auction[1]),
                "Ring, 2: vendor 500c each, auction house 1000c each, 2000c in all, 100 percent more, estimated gain 1000c"
            )
            t:assertEqual(
                hints.lineText(result.auction[2]),
                "Potion: vendor 1000c, auction house 1500c, 50 percent more, estimated gain 500c"
            )
        end)
    end,

    ["the status adds where the slots went"] = function(t)
        withGame(function(world)
            world.bags = { [0] = { { id = 2 }, { id = 3 }, { id = 7 }, { id = 8 } } }
            local text = hints.statusText(hints.compute(positions({ 0, 1 }, { 0, 2 }, { 0, 3 }, { 0, 4 })), NOW)
            t:assertTrue(
                text:find(
                    "1 in the list. Slots in the list: 1. Slots to sell to a merchant: 2. Occupied slots in your bags: 4, kept out of the list: 3 bound",
                    1,
                    true
                ) ~= nil
            )
        end)
    end,

    ["one item is valued by the same rules"] = function(t)
        withGame(function(world)
            local snapshot = market.snapshot()
            local value = hints.valueOfItem(2, snapshot)
            t:assertEqual(value.how, "auction")
            t:assertEqual(value.unit, 950)
            value = hints.valueOfItem(3, snapshot)
            t:assertEqual(value.how, "vendor")
            t:assertEqual(value.unit, 1000)
            t:assertNil(value.auctionUnit)
            t:assertEqual(hints.valueOfItem(5, snapshot).how, "vendor")
            t:assertEqual(hints.valueOfItem(7, snapshot).how, "none")
            t:assertEqual(hints.valueOfItem(2, nil).how, "vendor")
            world.loaded[2] = false
            t:assertNil(hints.valueOfItem(2, snapshot))
        end)
    end,
})
