local testRunner = WowVision.testing.testRunner
local store = WowVision.junkStore

local function item(id, extra)
    local info = {
        itemID = id,
        itemName = "Item " .. id,
        hyperlink = "|cffffffff|Hitem:" .. id .. "::::::::60:::::::::|h[Item " .. id .. "]|h|r",
        quality = 1,
        stackCount = 1,
        hasNoValue = false,
        isLocked = false,
    }
    for key, value in pairs(extra or {}) do
        info[key] = value
    end
    return info
end

-- The player's bags as the sale pass sees them: bags[bag][slot] = item info. Returns the options for
-- store.sell and the list of slots it sold.
local function world(bags, config)
    config = config or {}
    local sold = {}
    local looked = {}
    local opts = {
        bags = config.bagIDs or { 0, 1, 2, 3, 4, 5 },
        numSlots = function(bag)
            return bags[bag] ~= nil and (bags[bag].size or #bags[bag]) or 0
        end,
        getInfo = function(bag, slot)
            tinsert(looked, bag .. ":" .. slot)
            return bags[bag] ~= nil and bags[bag][slot] or nil
        end,
        sellPrice = function(itemID)
            if config.prices ~= nil then
                return config.prices[itemID]
            end
            return 10
        end,
        sell = function(bag, slot)
            if config.sellError ~= nil and #sold >= (config.sellErrorAfter or 0) then
                error(config.sellError)
            end
            tinsert(sold, bag .. ":" .. slot)
        end,
        marks = config.marks,
        sellPoor = config.sellPoor,
    }
    return opts, sold, looked
end

local function coin(value)
    return value .. "c"
end

testRunner:addSuite("JunkStore", {
    ["an item's key is its number, and its suffix when it has a random variant"] = function(t)
        t:assertEqual(store.keyFromLink("|cffffffff|Hitem:6948::::::::60:::::::::|h[Hearthstone]|h|r"), "6948")
        t:assertEqual(store.keyFromLink("|cff9d9d9d|Hitem:2589:0:0:0:0:0:0:0:60:0:0:0|h[Linen Cloth]|h|r"), "2589")
        t:assertEqual(store.keyFromLink("item:25"), "25", "a bare item string")
        -- Footpad's Gloves of the Monkey: suffix -26, a unique number of its own
        local monkey = "|cff1eff00|Hitem:15324:0:0:0:0:0:-26:1234567:60:0:0:0|h[Gloves of the Monkey]|h|r"
        t:assertEqual(store.keyFromLink(monkey), "15324:-26")
        local eagle = "|cff1eff00|Hitem:15324:0:0:0:0:0:-4:7654321:60:0:0:0|h[Gloves of the Eagle]|h|r"
        t:assertEqual(store.keyFromLink(eagle), "15324:-4")
        t:assertNotEqual(store.keyFromLink(monkey), store.keyFromLink(eagle), "variants stay apart")
    end,

    ["enchants, gems, level and the unique number do not change the key"] = function(t)
        local plain = "|cffffffff|Hitem:1234:0:0:0:0:0:0:0:60:0:0:0|h[Sword]|h|r"
        local dressed = "|cffffffff|Hitem:1234:2564:3000:3001:0:0:0:99887766:42:261:0:0|h[Sword]|h|r"
        t:assertEqual(store.keyFromLink(plain), store.keyFromLink(dressed))
        local sameVariantAnotherDrop = "|cff1eff00|Hitem:15324:0:0:0:0:0:-26:1:60:0:0:0|h[x]|h|r"
        local oneMore = "|cff1eff00|Hitem:15324:0:0:0:0:0:-26:2:61:0:0:0|h[x]|h|r"
        t:assertEqual(store.keyFromLink(sameVariantAnotherDrop), store.keyFromLink(oneMore))
    end,

    ["what is no item link has no key"] = function(t)
        t:assertNil(store.keyFromLink(nil))
        t:assertNil(store.keyFromLink(123))
        t:assertNil(store.keyFromLink(""))
        t:assertNil(store.keyFromLink("|cff71d5ff|Hspell:1234|h[Fireball]|h|r"))
        t:assertNil(store.keyFromLink("|Hbattlepet:1:2:3|h[Cat]|h"))
        t:assertNil(store.keyFromLink("item:"))
        t:assertNil(store.keyFromLink("item:0:1"))
        t:assertNil(store.keyFromLink("item:abc"))
    end,

    ["the name in a link, when there is one"] = function(t)
        t:assertEqual(store.nameFromLink("|cffffffff|Hitem:2589::::::::60|h[Linen Cloth]|h|r"), "Linen Cloth")
        t:assertEqual(store.nameFromLink("|Hitem:1|h[Gloves [of the] Monkey]|h"), "Gloves [of the] Monkey")
        t:assertNil(store.nameFromLink("item:25"))
        t:assertNil(store.nameFromLink(nil))
    end,

    ["toggling marks an unmarked item and unmarks a marked one"] = function(t)
        local marks = {}
        t:assertFalse(store.isMarked(marks, "25"))
        t:assertTrue(store.toggle(marks, "25", "Worn Shortsword"), "now marked")
        t:assertTrue(store.isMarked(marks, "25"))
        t:assertEqual(marks["25"], "Worn Shortsword", "the name is kept to be read back")
        t:assertFalse(store.toggle(marks, "25", "Worn Shortsword"), "now unmarked")
        t:assertFalse(store.isMarked(marks, "25"))
        t:assertNil(marks["25"])
        store.toggle(marks, "26")
        t:assertTrue(store.isMarked(marks, "26"), "marked even without a name")
    end,

    ["a mark of one item never marks another, and no key or no marks mark nothing"] = function(t)
        local marks = { ["25"] = "Worn Shortsword" }
        t:assertFalse(store.isMarked(marks, "26"))
        t:assertFalse(store.isMarked(marks, "25:-26"), "a variant is not the plain item")
        t:assertFalse(store.isMarked(marks, nil))
        t:assertFalse(store.isMarked(nil, "25"))
    end,

    ["count and clear"] = function(t)
        local marks = { ["1"] = "a", ["2"] = "b", ["3:-1"] = "c" }
        t:assertEqual(store.count(marks), 3)
        store.clear(marks)
        t:assertEqual(store.count(marks), 0)
        t:assertNil(next(marks))
    end,
})

testRunner:addSuite("JunkSale", {
    ["only marked items are sold when poor items are off"] = function(t)
        local bags = {
            [0] = { item(1), item(2), item(3, { quality = 0 }), item(4) },
            [1] = { item(5), item(6, { quality = 0 }) },
        }
        local opts, sold = world(bags, { marks = { ["2"] = "Item 2", ["5"] = "Item 5" } })
        local result = store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:2 1:1")
        t:assertEqual(result.units, 2)
        t:assertEqual(result.markedUnits, 2)
        t:assertEqual(result.poorUnits, 0)
        t:assertEqual(result.value, 20)
    end,

    ["an unmarked item is never sold, whatever it is: epic, expensive, last in the bag"] = function(t)
        local bags = {
            [0] = {
                item(1, { quality = 4 }),
                item(2, { quality = 1, stackCount = 20 }),
                item(3, { quality = 2 }),
                item(4, { quality = 0 }),
            },
        }
        -- Poor items off, one unrelated mark: nothing in the bag is marked.
        local opts, sold = world(bags, { marks = { ["999"] = "Other" }, sellPoor = false })
        local result = store.sell(opts)
        t:assertEqual(#sold, 0)
        t:assertEqual(result.units, 0)
        -- No marks at all (the setting is off or the module is): nothing, with poor items off too.
        opts, sold = world(bags, { marks = nil, sellPoor = false })
        store.sell(opts)
        t:assertEqual(#sold, 0)
        -- Poor items on: the grey one goes, and only that one.
        opts, sold = world(bags, { marks = {}, sellPoor = true })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:4")
    end,

    ["grey items go with their setting, marked ones with theirs, and each slot is sold once"] = function(t)
        local bags = {
            [0] = { item(1, { quality = 0 }), item(2), item(3, { quality = 0 }), item(4) },
        }
        local marks = { ["3"] = "Item 3 (grey and marked)", ["2"] = "Item 2" }
        local opts, sold = world(bags, { marks = marks, sellPoor = true })
        local result = store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:1 0:2 0:3")
        t:assertEqual(result.poorUnits, 1, "the grey unmarked one")
        t:assertEqual(result.markedUnits, 2, "the marked ones, the grey one among them")
        t:assertEqual(result.units, 3)

        -- Marked items off: the grey ones still go, the marked ones stay.
        opts, sold = world(bags, { marks = nil, sellPoor = true })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:1 0:3")
    end,

    ["a variant that is not the marked one stays"] = function(t)
        local monkey = item(15324, { hyperlink = "|Hitem:15324:0:0:0:0:0:-26:111:60|h[Gloves of the Monkey]|h" })
        local eagle = item(15324, { hyperlink = "|Hitem:15324:0:0:0:0:0:-4:222:60|h[Gloves of the Eagle]|h" })
        local plain = item(15324, { hyperlink = "|Hitem:15324:0:0:0:0:0:0:0:60|h[Gloves]|h" })
        local bags = { [0] = { monkey, eagle, plain } }
        local opts, sold = world(bags, { marks = { ["15324:-26"] = "Gloves of the Monkey" } })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:1")
        -- A mark of the plain item leaves both variants.
        opts, sold = world(bags, { marks = { ["15324"] = "Gloves" } })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:3")
    end,

    ["an item with another number but the same name is not the marked item"] = function(t)
        local bags = { [0] = { item(10, { itemName = "Linen Cloth" }), item(11, { itemName = "Linen Cloth" }) } }
        local opts, sold = world(bags, { marks = { ["10"] = "Linen Cloth" } })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:1")
    end,

    ["locked slots, and items no vendor buys, are left alone even when marked"] = function(t)
        local bags = {
            [0] = {
                item(1, { isLocked = true }),
                item(2, { hasNoValue = true }),
                item(3, { quality = 0, isLocked = true }),
                item(4, { quality = 0, hasNoValue = true }),
                item(5),
            },
        }
        local marks = { ["1"] = "a", ["2"] = "b", ["3"] = "c", ["4"] = "d", ["5"] = "e" }
        local opts, sold = world(bags, { marks = marks, sellPoor = true })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:5")
    end,

    ["a marked item needs proof that a vendor buys it: the flag or a price"] = function(t)
        local bags = { [0] = { item(1) } }
        bags[0][1].hasNoValue = nil
        local marks = { ["1"] = "a" }
        -- No flag from the game and no price known: not sold.
        local opts, sold = world(bags, { marks = marks, prices = {} })
        store.sell(opts)
        t:assertEqual(#sold, 0)
        -- A price: sold.
        opts, sold = world(bags, { marks = marks, prices = { [1] = 7 } })
        store.sell(opts)
        t:assertEqual(#sold, 1)
    end,

    ["only the listed bags are looked at: never the bank, never another bag"] = function(t)
        local bags = {
            [-1] = { item(1) },
            [0] = { item(2) },
            [6] = { item(3) },
            [12] = { item(4) },
        }
        local marks = { ["1"] = "a", ["2"] = "b", ["3"] = "c", ["4"] = "d" }
        local opts, sold, looked = world(bags, { marks = marks, bagIDs = { 0 } })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:1")
        t:assertEqual(table.concat(looked, " "), "0:1")
    end,

    ["a stack is sold whole, and counts its items and their worth"] = function(t)
        local bags = { [0] = { item(1, { stackCount = 5 }), item(2, { stackCount = 3, quality = 0 }) } }
        local opts, sold = world(bags, { marks = { ["1"] = "a" }, sellPoor = true, prices = { [1] = 100, [2] = 4 } })
        local result = store.sell(opts)
        t:assertEqual(#sold, 2)
        t:assertEqual(result.units, 8)
        t:assertEqual(result.markedUnits, 5)
        t:assertEqual(result.poorUnits, 3)
        t:assertEqual(result.value, 512)
    end,

    ["a price that is not known counts for nothing, and the item is still sold"] = function(t)
        local bags = { [0] = { item(1, { hasNoValue = false }) } }
        local opts = world(bags, { marks = { ["1"] = "a" }, prices = {} })
        local result = store.sell(opts)
        t:assertEqual(result.units, 1)
        t:assertEqual(result.value, 0)
    end,

    ["names: each marked item sold once, in the order of the bags"] = function(t)
        local bags = {
            [0] = { item(1, { itemName = "Linen Cloth", stackCount = 5 }), item(2, { itemName = "Worn Shortsword" }) },
            [1] = { item(1, { itemName = "Linen Cloth", stackCount = 2 }), item(3, { itemName = "Grey", quality = 0 }) },
        }
        local opts = world(bags, { marks = { ["1"] = "Linen Cloth", ["2"] = "Worn Shortsword" }, sellPoor = true })
        local result = store.sell(opts)
        t:assertEqual(table.concat(result.markedNames, "|"), "Linen Cloth|Worn Shortsword")
        t:assertEqual(result.markedUnits, 8)
        t:assertEqual(result.poorUnits, 1)
    end,

    ["a name the game does not give comes from the mark, then from the key"] = function(t)
        local bags = {
            [0] = {
                item(1, { itemName = false, hyperlink = "item:1" }),
                item(2, { itemName = false, hyperlink = "item:2" }),
            },
        }
        local opts = world(bags, { marks = { ["1"] = "Remembered", ["2"] = true } })
        local result = store.sell(opts)
        t:assertEqual(table.concat(result.markedNames, "|"), "Remembered|2")
    end,

    ["a name the game does not give yet is read from the item's link"] = function(t)
        local bags = {
            [0] = { item(1, { itemName = false, hyperlink = "|cffffffff|Hitem:1::::::::60|h[Linen Cloth]|h|r" }) },
        }
        local opts = world(bags, { marks = { ["1"] = "Remembered" } })
        local result = store.sell(opts)
        t:assertEqual(table.concat(result.markedNames, "|"), "Linen Cloth")
    end,

    ["empty slots and missing bags are skipped"] = function(t)
        local bags = { [0] = { size = 4, [2] = item(1) } }
        local opts, sold = world(bags, { marks = { ["1"] = "a" } })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:2")
    end,

    ["a failing sale call ends the pass, keeps what was sold, and reports the error"] = function(t)
        local bags = { [0] = { item(1), item(2), item(3) } }
        local marks = { ["1"] = "a", ["2"] = "b", ["3"] = "c" }
        local opts, sold = world(bags, { marks = marks, sellError = "boom", sellErrorAfter = 1 })
        local result = store.sell(opts)
        t:assertEqual(#sold, 1)
        t:assertEqual(result.units, 1)
        t:assertTrue(tostring(result.error):find("boom") ~= nil)
    end,

    ["an item the game cannot describe does not stop the pass"] = function(t)
        local bags = { [0] = { item(1), item(2) } }
        -- the game refusing to hand over any field of the first one (a secret value)
        bags[0][1] = setmetatable({}, { __index = function() error("secret") end })
        local opts, sold = world(bags, { marks = { ["2"] = "b" } })
        store.sell(opts)
        t:assertEqual(table.concat(sold, " "), "0:2")
    end,

    ["the pass looks at each slot once"] = function(t)
        local bags = { [0] = { item(1), item(2), item(3) } }
        local opts, sold, looked = world(bags, { marks = { ["1"] = "a", ["2"] = "b" } })
        store.sell(opts)
        t:assertEqual(#looked, 3)
        t:assertEqual(#sold, 2)
    end,
})

testRunner:addSuite("JunkSummary", {
    ["nothing sold, nothing said"] = function(t)
        t:assertNil(store.summary({ units = 0, value = 0, poorUnits = 0, markedUnits = 0, markedNames = {} }, {}, coin))
    end,

    ["grey items only: the count and the total"] = function(t)
        local L = { ["Sold %d poor quality items for %s."] = "Sold %d poor items for %s." }
        local result = { units = 4, value = 120, poorUnits = 4, markedUnits = 0, markedNames = {} }
        t:assertEqual(store.summary(result, L, coin), "Sold 4 poor items for 120c.")
    end,

    ["marked items only: the total and the names"] = function(t)
        local L = { ["Sold marked junk for %s: %s."] = "Marked sold for %s: %s." }
        local result = { units = 7, value = 35, poorUnits = 0, markedUnits = 7, markedNames = { "Linen Cloth", "Sword" } }
        t:assertEqual(store.summary(result, L, coin), "Marked sold for 35c: Linen Cloth, Sword.")
        -- one item: nothing reads "1 items"
        result = { units = 1, value = 3, poorUnits = 0, markedUnits = 1, markedNames = { "Sword" } }
        t:assertEqual(store.summary(result, L, coin), "Marked sold for 3c: Sword.")
    end,

    ["both kinds: how many grey ones, the total, and the names of the marked ones"] = function(t)
        local L = { ["Sold marked junk and %d poor quality items for %s: %s."] = "Marked and %d grey for %s: %s." }
        local result = { units = 9, value = 90, poorUnits = 4, markedUnits = 5, markedNames = { "Sword" } }
        t:assertEqual(store.summary(result, L, coin), "Marked and 4 grey for 90c: Sword.")
    end,

    ["a long list of names says five and how many more"] = function(t)
        local L = {
            ["Sold marked junk for %s: %s."] = "for %s: %s.",
            ["%s and %d more"] = "%s and %d more",
        }
        local names = { "A", "B", "C", "D", "E", "F", "G" }
        local result = { units = 7, value = 7, poorUnits = 0, markedUnits = 7, markedNames = names }
        t:assertEqual(store.summary(result, L, coin), "for 7c: A, B, C, D, E and 2 more.")
        names = { "A", "B", "C", "D", "E" }
        result.markedNames = names
        t:assertEqual(store.summary(result, L, coin), "for 7c: A, B, C, D, E.")
    end,
})
