local testRunner = WowVision.testing.testRunner
local prices = WowVision.modernAH.prices
local ReplicateScanner = WowVision.modernAH.ReplicateScanner

local function newDB()
    return { prices = {}, vendors = {}, lastScan = 0 }
end

local L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

local function coin(copper)
    return copper .. "c"
end

-- A game stand-in: the snapshot, the clock and the frame the scanner listens on.
local function newGame(auctions)
    local game = { auctions = auctions or {}, clock = 1000, unix = 2000000000, requests = 0, registered = {} }
    game.frame = {
        scripts = {},
        SetScript = function(self, name, script)
            self.scripts[name] = script
        end,
        RegisterEvent = function(_, event)
            game.registered[event] = true
        end,
        UnregisterEvent = function(_, event)
            game.registered[event] = nil
        end,
        UnregisterAllEvents = function()
            game.registered = {}
        end,
    }
    game.env = {
        createFrame = function()
            return game.frame
        end,
        now = function()
            return game.clock
        end,
        wallClock = function()
            return game.unix
        end,
        api = {
            ReplicateItems = function()
                game.requests = game.requests + 1
            end,
            GetNumReplicateItems = function()
                return #game.auctions
            end,
            -- the snapshot counts from 0; item ID 17th, buyout 10th, count 3rd
            GetReplicateItemInfo = function(index)
                local auction = game.auctions[index + 1]
                if auction == nil then
                    return nil
                end
                return "name", 1, auction.count, 1, true, 1, "", 0, 0, auction.buyout, 0, false, nil, nil, nil, 0, auction.id, true
            end,
        },
    }
    function game:fire(event)
        self.frame.scripts.OnEvent(self.frame, event)
    end
    function game:frames(number)
        for _ = 1, number do
            if self.frame.scripts.OnUpdate ~= nil then
                self.frame.scripts.OnUpdate()
            end
        end
    end
    return game
end

local function newScanner(game)
    local scanner = ReplicateScanner:new(game.env)
    local heard = { failed = {} }
    local owner = {}
    scanner.events.scanRequested:subscribe(owner, function()
        heard.requested = true
    end)
    scanner.events.scanStarted:subscribe(owner, function(_, _, total)
        heard.started = total
    end)
    scanner.events.scanComplete:subscribe(owner, function(_, _, results)
        heard.results = results
    end)
    scanner.events.scanFailed:subscribe(owner, function(_, _, reason)
        tinsert(heard.failed, reason)
    end)
    return scanner, heard
end

testRunner:addSuite("Modern auction prices", {
    ["per unit: the buyout of a stack is divided by its count, rounded down"] = function(t)
        local results = {}
        t:assertTrue(prices.addAuction(results, 7, 20, 1005))
        t:assertEqual(results[7].min, 50)
        t:assertEqual(results[7].max, 50)
    end,

    ["an auction without a buyout or count is not a price"] = function(t)
        local results = {}
        t:assertFalse(prices.addAuction(results, 7, 5, 0))
        t:assertFalse(prices.addAuction(results, 7, 0, 100))
        t:assertFalse(prices.addAuction(results, nil, 5, 100))
        t:assertFalse(prices.addAuction(results, 7, nil, 100))
        t:assertNil(results[7])
    end,

    ["min, max and the average weighted by units"] = function(t)
        local results, db = {}, newDB()
        prices.addAuction(results, 7, 1, 100) -- 100 each
        prices.addAuction(results, 7, 9, 450) -- 50 each
        prices.addAuction(results, 7, 10, 3000) -- 300 each
        prices.store(db, results, 2000, 21)
        local stats = prices.summary(db, 7, 2000, 21)
        t:assertEqual(stats.min, 50)
        t:assertEqual(stats.max, 300)
        t:assertEqual(stats.avg, 177) -- 3550 copper over 20 units
        t:assertEqual(stats.auctions, 3)
        t:assertEqual(stats.units, 20)
        t:assertEqual(stats.age, 0)
        t:assertEqual(stats.days, 1)
    end,

    ["over several days: the lowest, the highest, the average by units, and the number of days"] = function(t)
        local db = newDB()
        local function scan(day, count, buyout)
            local results = {}
            prices.addAuction(results, 7, count, buyout)
            prices.store(db, results, day, 30)
        end
        scan(2000, 1, 100) -- 100 each, 1 unit
        scan(2005, 9, 450) -- 50 each, 9 units
        scan(2007, 10, 3000) -- 300 each, 10 units
        local stats = prices.summary(db, 7, 2009, 30)
        t:assertEqual(stats.min, 50)
        t:assertEqual(stats.max, 300)
        t:assertEqual(stats.avg, 177)
        t:assertEqual(stats.days, 3)
        t:assertEqual(stats.age, 2, "from the latest of the days")
    end,

    ["days past the history do not count, even before the next scan prunes them"] = function(t)
        local db = newDB()
        local function scan(day, buyout)
            local results = {}
            prices.addAuction(results, 7, 1, buyout)
            prices.store(db, results, day, 30)
        end
        scan(2000, 9)
        scan(2010, 100)
        local stats = prices.summary(db, 7, 2030, 30)
        t:assertEqual(stats.days, 1, "day 2000 is 30 days old on day 2030")
        t:assertEqual(stats.min, 100)
        t:assertNil(prices.summary(db, 7, 2040, 30), "nothing left to count")
        t:assertEqual(prices.summary(db, 7, 2010, 3).days, 1, "a shorter history counts fewer days")
    end,

    ["30 days is the limit, whatever the setting says"] = function(t)
        local db = newDB()
        local function scan(id, day)
            local results = {}
            prices.addAuction(results, id, 1, 100)
            prices.store(db, results, day, 400)
        end
        scan(7, 2000)
        scan(8, 2001)
        scan(9, 2030)
        t:assertNil(db.prices[7], "30 days old")
        t:assertNotNil(db.prices[8], "29 days old")
        t:assertEqual(prices.summary(db, 8, 2030, 400).days, 1)
    end,

    ["prices past 32 bits survive the database"] = function(t)
        local results, db = {}, newDB()
        prices.addAuction(results, 7, 1, 90000000000)
        prices.store(db, results, 2000, 21)
        t:assertEqual(prices.summary(db, 7, 2000, 21).max, 90000000000)
    end,

    ["a later scan of the same day replaces the day, another day is kept"] = function(t)
        local db = newDB()
        local function scan(day, buyout)
            local results = {}
            prices.addAuction(results, 7, 1, buyout)
            prices.store(db, results, day, 21)
        end
        scan(2000, 100)
        scan(2000, 40)
        t:assertEqual(prices.summary(db, 7, 2000, 21).max, 40, "the newer snapshot of the day")
        t:assertEqual(prices.summary(db, 7, 2000, 21).days, 1)
        scan(2001, 70)
        t:assertEqual(prices.summary(db, 7, 2001, 21).max, 70)
        t:assertEqual(prices.summary(db, 7, 2001, 21).min, 40, "the day before stays")
        t:assertEqual(prices.summary(db, 7, 2001, 21).days, 2)
    end,

    ["the age counts from the latest scan that saw the item"] = function(t)
        local results, db = {}, newDB()
        prices.addAuction(results, 7, 1, 100)
        prices.store(db, results, 2000, 21)
        prices.store(db, {}, 2003, 21)
        t:assertEqual(prices.summary(db, 7, 2003, 21).age, 3)
        t:assertNil(prices.summary(db, 8, 2003, 21))
    end,

    ["pruning: a day historyDays old goes, an item with no day left goes"] = function(t)
        local db = newDB()
        local function scan(id, day)
            local results = {}
            prices.addAuction(results, id, 1, 100)
            prices.store(db, results, day, 3)
        end
        scan(7, 2000)
        scan(8, 2001)
        scan(8, 2002)
        prices.store(db, {}, 2003, 3)
        t:assertNil(db.prices[7], "day 2000 is 3 days old on day 2003, and it was the only one")
        t:assertNotNil(db.prices[8].s[2001])
        t:assertNotNil(db.prices[8].s[2002])
    end,

    ["a history of 0 days still keeps the scan just made"] = function(t)
        local results, db = {}, newDB()
        prices.addAuction(results, 7, 1, 100)
        prices.store(db, results, 2000, 0)
        t:assertNotNil(prices.summary(db, 7, 2000, 0))
    end,

    ["tooltip: the sell price per item first, then the auction prices and what a vendor charges"] = function(t)
        local lines = prices.tooltipLines(L, coin, { min = 1, avg = 2, max = 3, age = 0, days = 7 }, 4, 5)
        t:assertEqual(#lines, 5)
        t:assertEqual(lines[1], "Vendor price per item: 4c")
        t:assertEqual(lines[2], "Auction minimum 7 days: 1c")
        t:assertEqual(lines[3], "Auction average 7 days: 2c")
        t:assertEqual(lines[4], "Auction maximum 7 days: 3c")
        t:assertEqual(lines[5], "Vendor Buy: 5c")
    end,

    ["tooltip: the age is said once it is not today; unknown prices have no line"] = function(t)
        local lines = prices.tooltipLines(L, coin, { min = 1, avg = 2, max = 3, age = 2, days = 1 })
        t:assertEqual(lines[1], "Auction minimum 1 day (2 days ago): 1c")
        t:assertEqual(lines[3], "Auction maximum 1 day: 3c")
        t:assertEqual(#lines, 3)
        t:assertEqual(#prices.tooltipLines(L, coin, nil, 0, nil), 0)
    end,
})

testRunner:addSuite("Modern auction full scan", {
    ["reads the snapshot from index 0 to its end, over several frames"] = function(t)
        local auctions = {}
        for i = 1, 1200 do
            auctions[i] = { id = i, count = 2, buyout = 200 }
        end
        local game = newGame(auctions)
        local scanner, heard = newScanner(game)
        scanner:start()
        t:assertEqual(game.requests, 1)
        t:assertTrue(heard.requested, "the request is reported at once")
        t:assertEqual(scanner:getState(), "waiting")
        game:fire("REPLICATE_ITEM_LIST_UPDATE")
        t:assertEqual(heard.started, 1200)
        game:frames(1)
        t:assertEqual(scanner:getProgress().processed, 500, "one batch per frame")
        t:assertNil(heard.results)
        game:frames(2)
        t:assertEqual(scanner:getState(), "idle")
        t:assertNotNil(heard.results[1], "the first auction of the snapshot")
        t:assertNotNil(heard.results[1200], "the last one")
        t:assertEqual(heard.results[1200].min, 100)
    end,

    ["an update before the snapshot is here keeps waiting"] = function(t)
        local game = newGame({})
        local scanner, heard = newScanner(game)
        scanner:start()
        game:fire("REPLICATE_ITEM_LIST_UPDATE")
        t:assertEqual(scanner:getState(), "waiting")
        t:assertNil(heard.started)
    end,

    ["no snapshot within the time limit fails the scan"] = function(t)
        local game = newGame({})
        local scanner, heard = newScanner(game)
        scanner:start()
        game.clock = game.clock + 179
        game:frames(1)
        t:assertEqual(scanner:getState(), "waiting")
        game.clock = game.clock + 1
        game:frames(1)
        t:assertEqual(scanner:getState(), "idle")
        t:assertEqual(heard.failed[1], "timeout")
    end,

    ["closing the auction house ends the scan and listens to nothing more"] = function(t)
        local game = newGame({ { id = 1, count = 1, buyout = 1 } })
        local scanner, heard = newScanner(game)
        scanner:start()
        game:fire("AUCTION_HOUSE_CLOSED")
        t:assertEqual(scanner:getState(), "idle")
        t:assertEqual(heard.failed[1], "ah_closed")
        t:assertNil(next(game.registered))
        t:assertNil(game.frame.scripts.OnUpdate)
    end,

    ["the cooldown stops a second request and ends after 15 minutes"] = function(t)
        local game = newGame({ { id = 1, count = 1, buyout = 1 } })
        local scanner, heard = newScanner(game)
        scanner:start()
        game:fire("REPLICATE_ITEM_LIST_UPDATE")
        game:frames(1)
        scanner:start()
        t:assertEqual(game.requests, 1)
        t:assertEqual(heard.failed[1], "cooldown")
        game.clock = game.clock + 900
        t:assertTrue(scanner:canScan())
    end,

    ["the saved request time carries the cooldown over a reload"] = function(t)
        local game = newGame({})
        local scanner = newScanner(game)
        scanner:setLastScanTime(game.unix - 100)
        t:assertFalse(scanner:canScan())
        t:assertEqual(math.floor(scanner:getCooldownRemaining()), 800)
        local later = newScanner(newGame({}))
        later:setLastScanTime(later.wallClock() - 900)
        t:assertTrue(later:canScan())
    end,
})
