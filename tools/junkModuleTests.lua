-- The junk module (core/windows/junk.lua) and the merchant's sale (core/windows/merchant.lua) run against a small
-- stand-in for the game: bags that hold items, a speech recorder, and fake modules. Headless only: the files are
-- loaded afresh inside each test, since they build their modules as they load.
--
-- Run through tools/headless-tests.lua.

local testRunner = WowVision.testing.testRunner

local function loadFile(path)
    local chunk, err = loadfile(path)
    if chunk == nil then
        error(err)
    end
    return chunk("WowVision", {})
end

-- The game, as these two files see it. bag[bagID][slot] = container item info; selling removes the slot.
local function newGame()
    local game = {
        bags = {},
        sold = {},
        spoken = {},
        errors = {},
        calls = {},
        repaired = 0,
        money = 100000,
        sellError = nil,
        merchantEvents = 0,
    }
    function game.add(bag, slot, id, extra)
        game.bags[bag] = game.bags[bag] or { size = 16 }
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
        game.bags[bag][slot] = info
        return info
    end
    return game
end

-- Runs body(env) with the globals both files read replaced by the game's stand-ins, the two files loaded, and puts
-- everything back, whatever happens in the body.
local function withGame(game, body)
    local names = {
        "C_Container", "C_CurrencyInfo", "C_Item", "GetItemInfo", "geterrorhandler", "CanMerchantRepair",
        "GetRepairAllCost", "GetMoney", "RepairAllItems", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "NUM_BAG_SLOTS", "format",
        "print", "Enum",
    }
    local saved = {}
    for _, name in ipairs(names) do
        saved[name] = _G[name]
    end
    local savedBase, savedSpeak, savedHost = WowVision.base, WowVision.speak, WowVision.graphHost
    local savedPrint = print

    local prices = {}
    game.prices = prices
    C_Container = {
        GetContainerNumSlots = function(bag)
            tinsert(game.calls, "slots:" .. bag)
            local contents = game.bags[bag]
            return contents ~= nil and contents.size or 0
        end,
        GetContainerItemInfo = function(bag, slot)
            local contents = game.bags[bag]
            return contents ~= nil and contents[slot] or nil
        end,
        UseContainerItem = function(bag, slot)
            if game.sellError ~= nil and #game.sold >= (game.sellErrorAfter or 0) then
                error(game.sellError)
            end
            tinsert(game.sold, bag .. ":" .. slot)
            game.bags[bag][slot] = nil
        end,
    }
    C_CurrencyInfo = {
        GetCoinText = function(value)
            return value .. " copper"
        end,
    }
    C_Item = nil
    GetItemInfo = function(id)
        local price = prices[id]
        if price == nil then
            price = 10
        end
        return "name", "link", 1, 1, 1, "type", "subtype", 1, "loc", 0, price
    end
    geterrorhandler = function()
        return function(err)
            tinsert(game.errors, tostring(err))
        end
    end
    CanMerchantRepair = function()
        return game.canRepair == true
    end
    GetRepairAllCost = function()
        return 50, true
    end
    GetMoney = function()
        return game.money
    end
    RepairAllItems = function()
        game.repaired = game.repaired + 1
    end
    NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
    NUM_BAG_SLOTS = 4
    format = string.format
    print = function() end
    Enum = Enum or {}
    Enum.PlayerInteractionType = Enum.PlayerInteractionType or { Merchant = 5 }

    local parent = {}
    function parent:createModule(key)
        local module = {
            key = key,
            L = setmetatable({}, {
                __index = function(_, text)
                    return text
                end,
            }),
            enabled = true,
            registeredBindings = {},
            events = {},
            settings = {},
        }
        function module:setLabel(label)
            self.label = label
        end
        function module:registerBinding(info)
            tinsert(self.registeredBindings, info)
            return info
        end
        function module:getEnabled()
            return self.enabled
        end
        function module:hasSettings()
            return {
                add = function(_, def)
                    module.settings[def.key] = def.default
                end,
            }
        end
        function module:registerEvent(kind, name)
            tinsert(self.events, name)
        end
        function module:registerWindow(info)
            self.window = info
        end
        function module:createComponentRegistry()
            return {
                createType = function() end,
                createComponent = function() end,
                forEachComponent = function() end,
                getComponents = function()
                    return {}
                end,
            }
        end
        parent[key] = module
        return module
    end
    WowVision.base = { windows = parent }
    WowVision.speak = function(_, text)
        tinsert(game.spoken, text)
    end
    WowVision.graphHost = {
        focusedScreen = function()
            return game.screen
        end,
    }

    loadFile("core/windows/marks.lua")
    loadFile("core/windows/junk.lua")
    loadFile("core/windows/favorites.lua")
    loadFile("core/windows/merchant.lua")
    local env = { junk = parent.junk, favorites = parent.favorites, merchant = parent.merchant }
    env.junk.data = env.junk:getDefaultData()
    env.favorites.data = env.favorites:getDefaultData()

    local ok, err = pcall(body, env)

    for _, name in ipairs(names) do
        _G[name] = saved[name]
    end
    print = savedPrint
    WowVision.base, WowVision.speak, WowVision.graphHost = savedBase, savedSpeak, savedHost
    if not ok then
        error(err, 0)
    end
end

local function mark(env, id)
    env.junk.data.marks[tostring(id)] = "Item " .. id
end

local function open(env)
    env.merchant:onEvent("MERCHANT_SHOW")
end

testRunner:addSuite("JunkModule", {
    ["the Select Junk key is a dormant keymap, Shift+Enter by default"] = function(t)
        withGame(newGame(), function(env)
            local keymap = env.junk.registeredBindings[1]
            t:assertEqual(#env.junk.registeredBindings, 1)
            t:assertEqual(keymap.key, "junk/toggle")
            t:assertEqual(keymap.type, "Flexible")
            t:assertTrue(keymap.dorment, "held only while a node asks for it")
            t:assertEqual(keymap.inputs[1], "SHIFT-ENTER")
            t:assertEqual(#keymap.inputs, 1)
            t:assertEqual(keymap.label, "Select Junk")
            t:assertEqual(env.junk.label, "Junk")
        end)
    end,

    ["the module's data starts with no marks"] = function(t)
        withGame(newGame(), function(env)
            local data = env.junk:getDefaultData()
            t:assertNil(next(data.marks))
        end)
    end,

    ["marks are there only while the module is on and its data is loaded"] = function(t)
        withGame(newGame(), function(env)
            t:assertNotNil(env.junk:getMarks())
            env.junk.enabled = false
            t:assertNil(env.junk:getMarks())
            env.junk.enabled = true
            env.junk.data = nil
            t:assertNil(env.junk:getMarks())
            env.junk.data = {}
            t:assertNotNil(env.junk:getMarks(), "data saved before the marks existed")
            t:assertNotNil(env.junk.data.marks)
        end)
    end,

    ["Select Junk marks the item, says so, and a second press takes the mark off"] = function(t)
        local game = newGame()
        game.add(0, 3, 25, { itemName = "Worn Shortsword" })
        game.screen = { _liveKey = "node" }
        withGame(game, function(env)
            env.junk:toggleAt(0, 3)
            t:assertEqual(game.spoken[1], "Worn Shortsword: marked as junk")
            t:assertTrue(env.junk:isMarkedAt(0, 3))
            t:assertEqual(env.junk.data.marks["25"], "Worn Shortsword")
            t:assertNil(game.screen._liveKey, "the live watch is told: the label was just said")
            game.screen._liveKey = "node"
            env.junk:toggleAt(0, 3)
            t:assertEqual(game.spoken[2], "Worn Shortsword: no longer junk")
            t:assertFalse(env.junk:isMarkedAt(0, 3))
            t:assertNil(env.junk.data.marks["25"])
            t:assertNil(game.screen._liveKey)
        end)
    end,

    ["one mark covers every stack and copy of the item"] = function(t)
        local game = newGame()
        game.add(0, 1, 25)
        game.add(2, 7, 25)
        game.add(0, 2, 26)
        withGame(game, function(env)
            env.junk:toggleAt(0, 1)
            t:assertTrue(env.junk:isMarkedAt(2, 7))
            t:assertFalse(env.junk:isMarkedAt(0, 2))
        end)
    end,

    ["an item whose name the game has not given yet is said by the name in its link"] = function(t)
        local game = newGame()
        game.add(0, 1, 2589, {
            itemName = false,
            hyperlink = "|cffffffff|Hitem:2589::::::::60:::::::::|h[Linen Cloth]|h|r",
        })
        withGame(game, function(env)
            env.junk:toggleAt(0, 1)
            t:assertEqual(game.spoken[1], "Linen Cloth: marked as junk")
            t:assertEqual(env.junk.data.marks["2589"], "Linen Cloth", "and kept under that name")
        end)
    end,

    ["an empty slot is said to be empty and marks nothing"] = function(t)
        local game = newGame()
        withGame(game, function(env)
            env.junk:toggleAt(0, 5)
            t:assertEqual(game.spoken[1], "Empty")
            t:assertNil(next(env.junk.data.marks))
        end)
    end,

    ["an item no vendor buys is not marked, but its mark can be taken off"] = function(t)
        local game = newGame()
        game.add(0, 1, 6948, { itemName = "Hearthstone", hasNoValue = true })
        withGame(game, function(env)
            env.junk:toggleAt(0, 1)
            t:assertEqual(game.spoken[1], "Hearthstone cannot be sold to a vendor.")
            t:assertNil(next(env.junk.data.marks))
            -- marked earlier, when it still had a value
            env.junk.data.marks["6948"] = "Hearthstone"
            env.junk:toggleAt(0, 1)
            t:assertEqual(game.spoken[2], "Hearthstone: no longer junk")
            t:assertNil(next(env.junk.data.marks))
        end)
    end,

    ["an item with no usable link is not marked"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { hyperlink = "|Hbattlepet:1:2:3|h[Cat]|h" })
        withGame(game, function(env)
            env.junk:toggleAt(0, 1)
            t:assertEqual(game.spoken[1], "This item cannot be marked as junk.")
            t:assertNil(next(env.junk.data.marks))
        end)
    end,

    ["with the module off, the key does nothing"] = function(t)
        local game = newGame()
        game.add(0, 1, 25)
        withGame(game, function(env)
            env.junk.enabled = false
            env.junk:toggleAt(0, 1)
            t:assertEqual(#game.spoken, 0)
            t:assertNil(next(env.junk.data.marks))
        end)
    end,

    ["a marked item's label starts with [Junk]"] = function(t)
        local game = newGame()
        game.add(0, 1, 25)
        game.add(0, 2, 26)
        withGame(game, function(env)
            mark(env, 25)
            t:assertEqual(env.junk:tagLabel("Worn Shortsword, White", 0, 1), "[Junk] Worn Shortsword, White")
            t:assertEqual(env.junk:tagLabel("Cloth, White", 0, 2), "Cloth, White", "not marked: no tag")
            t:assertEqual(env.junk:tagLabel("Empty", 0, 9), "Empty", "an empty slot: no tag")
            t:assertNil(env.junk:tagLabel(nil, 0, 1))
        end)
    end,

    ["the tag goes when the mark does, and with the module off"] = function(t)
        local game = newGame()
        game.add(0, 1, 25)
        withGame(game, function(env)
            mark(env, 25)
            t:assertEqual(env.junk:tagLabel("x", 0, 1), "[Junk] x")
            env.junk.enabled = false
            t:assertEqual(env.junk:tagLabel("x", 0, 1), "x")
            env.junk.enabled = true
            env.junk.data.marks["25"] = nil
            t:assertEqual(env.junk:tagLabel("x", 0, 1), "x")
        end)
    end,

    ["a label survives a bag that cannot be read"] = function(t)
        local game = newGame()
        game.add(0, 1, 25)
        withGame(game, function(env)
            mark(env, 25)
            C_Container.GetContainerItemInfo = function()
                error("no bag")
            end
            t:assertEqual(env.junk:tagLabel("x", 0, 1), "x")
        end)
    end,

    ["a bag slot node gets the key and a menu entry that do the same"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { itemName = "Worn Shortsword" })
        withGame(game, function(env)
            local where = { 0, 1 }
            local baseEntries = 0
            local vtable = {
                bindings = { { binding = "leftClick" } },
                contextActions = function(add)
                    baseEntries = baseEntries + 1
                    add({ label = "Left Click" })
                end,
            }
            t:assertEqual(env.junk:decorateSlot(vtable, function()
                return where[1], where[2]
            end), vtable, "the same node comes back")
            t:assertEqual(#vtable.bindings, 2)
            local spec = vtable.bindings[2]
            t:assertEqual(spec.binding, "junk/toggle")
            t:assertEqual(spec.type, "Function")
            t:assertTrue(spec.interruptSpeech)

            local entries = {}
            vtable.contextActions(function(entry)
                tinsert(entries, entry)
            end)
            t:assertEqual(baseEntries, 1, "the clicks stay in the menu")
            t:assertEqual(entries[1].label, "Left Click")
            t:assertEqual(entries[2].label, "Mark as Junk")

            spec.func()
            t:assertTrue(env.junk:isMarkedAt(0, 1))
            entries = {}
            vtable.contextActions(function(entry)
                tinsert(entries, entry)
            end)
            t:assertEqual(entries[2].label, "Unmark as Junk")
            entries[2].onActivate()
            t:assertFalse(env.junk:isMarkedAt(0, 1))

            -- the button is reused for another slot: the key follows it
            game.add(1, 4, 99, { itemName = "Other" })
            where = { 1, 4 }
            spec.func()
            t:assertTrue(env.junk:isMarkedAt(1, 4))
            t:assertFalse(env.junk:isMarkedAt(0, 1))
        end)
    end,

    ["the marked slots among some buttons, in the order given"] = function(t)
        local game = newGame()
        game.add(0, 1, 25)
        game.add(0, 2, 26)
        game.add(1, 4, 27)
        game.add(2, 1, 25)
        withGame(game, function(env)
            mark(env, 25)
            mark(env, 27)
            local buttons = { { 1, 4 }, { 0, 2 }, { 2, 1 }, { 0, 1 }, { 3, 3 } }
            local function locate(button)
                return button[1], button[2]
            end
            local marked = env.junk:markedSlots(buttons, locate)
            local seen = {}
            for _, button in ipairs(marked) do
                tinsert(seen, button[1] .. ":" .. button[2])
            end
            t:assertEqual(table.concat(seen, " "), "1:4 2:1 0:1")
            -- a button that cannot say where it is
            local broken = { locate = true }
            marked = env.junk:markedSlots({ broken, buttons[1] }, function(button)
                if button == broken then
                    error("not a slot")
                end
                return button[1], button[2]
            end)
            t:assertEqual(#marked, 1)
            -- off: nothing is marked
            env.junk.enabled = false
            t:assertEqual(#env.junk:markedSlots(buttons, locate), 0)
        end)
    end,

    ["a node that is nil, or a module that is off, is passed through as it is"] = function(t)
        withGame(newGame(), function(env)
            t:assertNil(env.junk:decorateSlot(nil, function() end))
            env.junk.enabled = false
            local vtable = { bindings = {} }
            env.junk:decorateSlot(vtable, function() end)
            t:assertEqual(#vtable.bindings, 0)
            t:assertNil(vtable.contextActions)
        end)
    end,

    ["a node with no menu of its own still gets the entry"] = function(t)
        withGame(newGame(), function(env)
            local vtable = { bindings = {} }
            env.junk:decorateSlot(vtable, function()
                return 0, 1
            end)
            local entries = {}
            vtable.contextActions(function(entry)
                tinsert(entries, entry)
            end)
            t:assertEqual(#entries, 1)
            t:assertEqual(entries[1].label, "Mark as Junk")
        end)
    end,
})

testRunner:addSuite("JunkMerchant", {
    ["the merchant's settings: grey items off as before, marked items on"] = function(t)
        withGame(newGame(), function(env)
            t:assertFalse(env.merchant.settings.autoSellPoorItems)
            t:assertTrue(env.merchant.settings.autoSellMarkedJunk)
            t:assertFalse(env.merchant.settings.autoRepair)
            t:assertEqual(#env.merchant.events, 1)
            t:assertEqual(env.merchant.events[1], "MERCHANT_SHOW")
        end)
    end,

    ["opening a merchant sells the marked items and nothing else, and says what and how much"] = function(t)
        local game = newGame()
        game.add(0, 1, 100, { itemName = "Linen Cloth", stackCount = 5 })
        game.add(0, 2, 101, { itemName = "Healing Potion", quality = 2 })
        game.add(0, 3, 102, { itemName = "Worn Shortsword" })
        game.add(1, 1, 103, { itemName = "Grey Fang", quality = 0 })
        game.add(2, 6, 104, { itemName = "Epic Thing", quality = 4 })
        withGame(game, function(env)
            game.prices[100] = 3
            game.prices[102] = 25
            mark(env, 100)
            mark(env, 102)
            open(env)
            t:assertEqual(table.concat(game.sold, " "), "0:1 0:3")
            t:assertEqual(#game.spoken, 1)
            t:assertEqual(
                game.spoken[1],
                "Sold marked junk for 40 copper: Linen Cloth, Worn Shortsword."
            )
            -- everything unmarked is still in the bags
            t:assertNotNil(game.bags[0][2])
            t:assertNotNil(game.bags[1][1], "grey, but selling poor items is off")
            t:assertNotNil(game.bags[2][6])
            t:assertEqual(#game.errors, 0)
        end)
    end,

    ["the grey items go on their own setting, together with the marked ones in one pass"] = function(t)
        local game = newGame()
        game.add(0, 1, 100, { itemName = "Linen Cloth" })
        game.add(0, 2, 101, { quality = 0 })
        game.add(0, 3, 102, { quality = 0 })
        game.add(0, 4, 103)
        withGame(game, function(env)
            mark(env, 100)
            env.merchant.settings.autoSellPoorItems = true
            open(env)
            t:assertEqual(table.concat(game.sold, " "), "0:1 0:2 0:3")
            t:assertEqual(game.spoken[1], "Sold marked junk and 2 poor quality items for 30 copper: Linen Cloth.")
            t:assertNotNil(game.bags[0][4])
        end)
    end,

    ["grey items alone say what they said before"] = function(t)
        local game = newGame()
        game.add(0, 1, 101, { quality = 0, stackCount = 2 })
        game.add(0, 2, 103)
        withGame(game, function(env)
            env.merchant.settings.autoSellPoorItems = true
            open(env)
            t:assertEqual(table.concat(game.sold, " "), "0:1")
            t:assertEqual(game.spoken[1], "Sold 2 poor quality items for 20 copper.")
        end)
    end,

    ["with nothing marked and grey items off, the merchant opening sells and says nothing"] = function(t)
        local game = newGame()
        game.add(0, 1, 101, { quality = 0 })
        game.add(0, 2, 103, { quality = 4 })
        withGame(game, function(env)
            open(env)
            t:assertEqual(#game.sold, 0)
            t:assertEqual(#game.spoken, 0)
        end)
    end,

    ["the setting for marked items, and the module itself, can switch the sale off"] = function(t)
        local game = newGame()
        game.add(0, 1, 100)
        withGame(game, function(env)
            mark(env, 100)
            env.merchant.settings.autoSellMarkedJunk = false
            open(env)
            t:assertEqual(#game.sold, 0)
            env.merchant.settings.autoSellMarkedJunk = true
            env.junk.enabled = false
            open(env)
            t:assertEqual(#game.sold, 0)
            env.junk.enabled = true
            open(env)
            t:assertEqual(#game.sold, 1)
        end)
    end,

    ["an item with no vendor value is never sold, even marked"] = function(t)
        local game = newGame()
        game.add(0, 1, 6948, { itemName = "Hearthstone", hasNoValue = true })
        game.add(0, 2, 100, { isLocked = true })
        withGame(game, function(env)
            mark(env, 6948)
            mark(env, 100)
            open(env)
            t:assertEqual(#game.sold, 0)
            t:assertEqual(#game.spoken, 0)
        end)
    end,

    ["only the bags the player carries are looked at: not the bank, not what is worn"] = function(t)
        local game = newGame()
        game.add(-1, 1, 100, { itemName = "In the bank" })
        game.add(6, 1, 100, { itemName = "In a bank bag" })
        game.add(12, 1, 100, { itemName = "In the warband bank" })
        game.add(5, 1, 100, { itemName = "In the reagent bag" })
        game.add(0, 1, 100, { itemName = "In the backpack" })
        withGame(game, function(env)
            mark(env, 100)
            open(env)
            t:assertEqual(table.concat(game.sold, " "), "0:1 5:1")
            for _, call in ipairs(game.calls) do
                t:assertTrue(call == "slots:0" or call == "slots:1" or call == "slots:2" or call == "slots:3" or call == "slots:4" or call == "slots:5", call)
            end
            t:assertNotNil(game.bags[-1][1])
            t:assertNotNil(game.bags[6][1])
            t:assertNotNil(game.bags[12][1])
        end)
    end,

    ["a client with no reagent bag stops at the bag slots"] = function(t)
        local game = newGame()
        game.add(4, 1, 100)
        game.add(5, 1, 100)
        withGame(game, function(env)
            NUM_TOTAL_EQUIPPED_BAG_SLOTS = nil
            mark(env, 100)
            open(env)
            t:assertEqual(table.concat(game.sold, " "), "4:1")
        end)
    end,

    ["one opening is one pass: bag updates start nothing, a second opening finds nothing left"] = function(t)
        local game = newGame()
        game.add(0, 1, 100)
        game.add(0, 2, 100)
        withGame(game, function(env)
            mark(env, 100)
            env.merchant:onEvent("BAG_UPDATE")
            env.merchant:onEvent("MERCHANT_CLOSED")
            t:assertEqual(#game.sold, 0, "other events sell nothing")
            open(env)
            t:assertEqual(#game.sold, 2)
            t:assertEqual(#game.spoken, 1)
            -- the sale's own bag updates, and the window staying open, sell nothing more
            env.merchant:onEvent("BAG_UPDATE")
            t:assertEqual(#game.sold, 2)
            -- the next visit: nothing marked is left, so nothing is sold and nothing is said
            open(env)
            t:assertEqual(#game.sold, 2)
            t:assertEqual(#game.spoken, 1)
        end)
    end,

    ["a sale that fails is reported, keeps what was sold, and the repair still happens"] = function(t)
        local game = newGame()
        game.add(0, 1, 100)
        game.add(0, 2, 101)
        game.add(0, 3, 102)
        game.canRepair = true
        game.sellError = "sale refused"
        game.sellErrorAfter = 1
        withGame(game, function(env)
            mark(env, 100)
            mark(env, 101)
            mark(env, 102)
            env.merchant.settings.autoRepair = true
            open(env)
            t:assertEqual(#game.sold, 1)
            t:assertEqual(#game.errors, 1)
            t:assertTrue(game.errors[1]:find("sale refused") ~= nil)
            t:assertEqual(#game.spoken, 1, "what did sell is said")
            t:assertEqual(game.repaired, 1)
            -- and the next opening works again
            game.sellError = nil
            open(env)
            t:assertEqual(#game.sold, 3)
        end)
    end,

    ["an error anywhere in the sale does not stop the repair, and is reported"] = function(t)
        local game = newGame()
        game.canRepair = true
        withGame(game, function(env)
            mark(env, 100)
            C_Container.GetContainerNumSlots = function()
                error("bags unavailable")
            end
            env.merchant.settings.autoRepair = true
            env.merchant:onEvent("MERCHANT_SHOW")
            t:assertEqual(#game.errors, 1)
            t:assertTrue(game.errors[1]:find("bags unavailable") ~= nil)
            t:assertEqual(game.repaired, 1)
            C_Container.GetContainerNumSlots = function()
                return 0
            end
            env.merchant:onEvent("MERCHANT_SHOW")
            t:assertEqual(#game.errors, 1, "the guard against a second pass was released")
        end)
    end,
})

-- The bags window's item slots (core/windows/containers.lua) with fake item buttons.
local function slotButton(bag, slot)
    return {
        IsShown = function()
            return true
        end,
        GetTop = function() end,
        GetBagID = function()
            return bag
        end,
        GetID = function()
            return slot
        end,
    }
end

-- The Junk list junk.lua registered with the bags' Item Lists (core/windows/bagLists.lua).
local function junkList()
    for _, list in ipairs(WowVision.bagLists.lists) do
        if list.key == "junk" then
            return list
        end
    end
    error("the Junk list is not registered")
end

-- A builder that only writes down what it is asked for.
local function recordingBuilder()
    local builder = { events = {}, items = {} }
    function builder:beginGroup(_, vtable, _, defaultExpanded)
        tinsert(self.events, "group:" .. vtable.announcements[1].text .. (defaultExpanded and "[open]" or "[closed]"))
    end
    function builder:endGroup() end
    function builder:beginStop(key)
        tinsert(self.events, "stop:" .. key)
    end
    function builder:pushContext(key, label)
        tinsert(self.events, "push:" .. key .. "=" .. tostring(label))
    end
    function builder:popContext()
        tinsert(self.events, "pop")
    end
    function builder:addItem(_, vtable)
        tinsert(self.events, "item")
        tinsert(self.items, vtable)
    end
    function builder:startRow() end
    function builder:endRow() end
    return builder
end

local function renderedSlots(env, buttons)
    local builder = { items = {} }
    function builder:addItem(_, vtable)
        tinsert(self.items, vtable)
    end
    function builder:startRow() end
    function builder:endRow() end
    env.containers.renderSlots(builder, buttons)
    return builder.items
end

testRunner:addSuite("JunkWiring", {
    ["bag item slots read [Junk] ahead of a marked item, in the list and in the grid"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { itemName = "Worn Shortsword" })
        game.add(0, 2, 26, { itemName = "Linen Cloth" })
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            env.containers = WowVision.base.windows.containers
            env.containers.getBagItemLabel = function(button)
                local info = C_Container.GetContainerItemInfo(button:GetBagID(), button:GetID())
                return info == nil and "Empty" or info.itemName .. ", White"
            end
            local buttons = { slotButton(0, 1), slotButton(0, 2), slotButton(0, 3) }
            for _, shape in ipairs({ "list", "grid" }) do
                env.containers.settings.shape = shape
                mark(env, 25)
                local items = renderedSlots(env, buttons)
                t:assertEqual(#items, 3, shape)
                t:assertEqual(items[1].announcements[1].text(), "[Junk] Worn Shortsword, White", shape)
                t:assertEqual(items[2].announcements[1].text(), "Linen Cloth, White", shape)
                t:assertEqual(items[3].announcements[1].text(), "Empty", shape)
                env.junk.data.marks["25"] = nil
                t:assertEqual(items[1].announcements[1].text(), "Worn Shortsword, White", shape .. ": live")
            end
        end)
    end,

    ["every bag item slot has the Select Junk key, which works on the slot it stands on"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { itemName = "Worn Shortsword" })
        game.add(3, 5, 26, { itemName = "Linen Cloth" })
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            local containers = WowVision.base.windows.containers
            env.containers = containers
            containers.getBagItemLabel = function()
                return "x"
            end
            local items = renderedSlots(env, { slotButton(0, 1), slotButton(3, 5) })
            for _, vtable in ipairs(items) do
                local found = nil
                for _, spec in ipairs(vtable.bindings) do
                    if spec.binding == "junk/toggle" then
                        found = spec
                    end
                end
                t:assertNotNil(found, "the key is on the node")
                -- the nodes keep their clicks and drag
                t:assertEqual(vtable.bindings[1].binding, "leftClick")
            end
            items[2].bindings[#items[2].bindings].func()
            t:assertTrue(env.junk:isMarkedAt(3, 5))
            t:assertFalse(env.junk:isMarkedAt(0, 1))
            t:assertEqual(game.spoken[1], "Linen Cloth: marked as junk")
        end)
    end,

    ["the Junk list of the Item Lists holds every marked slot, in bag order, and reads like the bags"] = function(t)
        local game = newGame()
        game.add(2, 3, 30, { itemName = "Third" })
        game.add(0, 5, 10, { itemName = "First" })
        game.add(0, 2, 11, { itemName = "Not marked" })
        game.add(1, 1, 20, { itemName = "Second" })
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            local containers = WowVision.base.windows.containers
            containers.getBagItemLabel = function(button)
                local info = C_Container.GetContainerItemInfo(button:GetBagID(), button:GetID())
                return info.itemName
            end
            mark(env, 30)
            mark(env, 10)
            mark(env, 20)
            local list = junkList()
            t:assertEqual(list.label, "Junk")
            local buttons = { slotButton(2, 3), slotButton(0, 5), slotButton(0, 2), slotButton(1, 1), slotButton(4, 4) }
            local selected = list.select(WowVision.bagLists.sorted(buttons))
            t:assertEqual(#selected, 3)
            t:assertEqual(containers.slotNode(selected[1]).announcements[1].text(), "[Junk] First")
            t:assertEqual(containers.slotNode(selected[2]).announcements[1].text(), "[Junk] Second")
            t:assertEqual(containers.slotNode(selected[3]).announcements[1].text(), "[Junk] Third")
        end)
    end,

    ["with nothing marked the Junk list is empty, so the Item Lists leave it out"] = function(t)
        local game = newGame()
        game.add(0, 1, 25)
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            local containers = WowVision.base.windows.containers
            containers.getBagItemLabel = function()
                return "x"
            end
            t:assertEqual(#junkList().select({ slotButton(0, 1) }), 0)
        end)
    end,

    ["an item in the Junk list can be unmarked from there, and it leaves the list"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { itemName = "Worn Shortsword" })
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            local containers = WowVision.base.windows.containers
            containers.getBagItemLabel = function()
                return "Worn Shortsword, White"
            end
            mark(env, 25)
            local buttons = { slotButton(0, 1) }
            local list = junkList()
            local vtable = containers.slotNode(list.select(buttons)[1])
            vtable.bindings[#vtable.bindings].func()
            t:assertFalse(env.junk:isMarkedAt(0, 1))
            t:assertEqual(#list.select(buttons), 0)
        end)
    end,

    ["the retail bags show the Item Lists once, right after the first combined frame's bags"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { itemName = "Worn Shortsword" })
        game.add(0, 2, 26)
        game.add(5, 1, 27)
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            local containers = WowVision.base.windows.containers
            containers.getBagItemLabel = function()
                return "label"
            end
            local function combinedFrame(name, buttons)
                return {
                    Items = buttons,
                    IsShown = function()
                        return true
                    end,
                    IsCombinedBagContainer = function()
                        return true
                    end,
                    GetName = function()
                        return name
                    end,
                    GetID = function()
                        return 0
                    end,
                }
            end
            local frames = {
                combinedFrame("FrameA", { slotButton(0, 1), slotButton(0, 2) }),
                combinedFrame("FrameB", { slotButton(5, 1) }),
            }
            local savedComponents = WowVision.components
            local savedEnumerate = ContainerFrameUtil_EnumerateContainerFrames
            local savedCollect = WowVision.bagLists.collect
            local Bags = {}
            WowVision.components = {
                createType = function()
                    return Bags
                end,
            }
            ContainerFrameUtil_EnumerateContainerFrames = function()
                local index = 0
                return function()
                    index = index + 1
                    return frames[index] ~= nil and index or nil, frames[index]
                end
            end
            local function stopsOf(builder)
                local stops = {}
                for _, event in ipairs(builder.events) do
                    if event:sub(1, 5) == "stop:" then
                        tinsert(stops, event:sub(6))
                    end
                end
                return table.concat(stops, " ")
            end
            local ok, err = pcall(function()
                loadFile("retail/containers/Bags.lua")
                mark(env, 25)
                mark(env, 27)
                local builder = recordingBuilder()
                Bags:renderGraph(builder)
                t:assertEqual(
                    stopsOf(builder),
                    "frame:FrameA:grid frame:FrameA:bagSlots lists frame:FrameB:grid frame:FrameB:bagSlots"
                )
                t:assertEqual(#game.errors, 0)
                -- both marked items, from both frames, are in the one Junk category
                local groups = {}
                for _, event in ipairs(builder.events) do
                    if event:sub(1, 6) == "group:" then
                        tinsert(groups, event:sub(7))
                    end
                end
                t:assertEqual(table.concat(groups, ","), "Junk (2)[closed]")

                -- a failure of the stop is reported and the bags still render
                WowVision.bagLists.collect = function()
                    error("lists broke")
                end
                builder = recordingBuilder()
                Bags:renderGraph(builder)
                t:assertEqual(stopsOf(builder), "frame:FrameA:grid frame:FrameA:bagSlots frame:FrameB:grid frame:FrameB:bagSlots")
                t:assertEqual(#game.errors, 1)
                t:assertTrue(game.errors[1]:find("lists broke") ~= nil)
            end)
            WowVision.bagLists.collect = savedCollect
            WowVision.components = savedComponents
            ContainerFrameUtil_EnumerateContainerFrames = savedEnumerate
            if not ok then
                error(err, 0)
            end
        end)
    end,

    ["with the junk module off the Junk list is empty"] = function(t)
        local game = newGame()
        game.add(0, 1, 25)
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            local containers = WowVision.base.windows.containers
            mark(env, 25)
            env.junk.enabled = false
            t:assertEqual(#junkList().select({ slotButton(0, 1) }), 0)
        end)
    end,

    ["with the junk module off the bag slots are what they were"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { itemName = "Worn Shortsword" })
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            local containers = WowVision.base.windows.containers
            env.containers = containers
            containers.getBagItemLabel = function()
                return "Worn Shortsword, White"
            end
            mark(env, 25)
            env.junk.enabled = false
            local items = renderedSlots(env, { slotButton(0, 1) })
            t:assertEqual(items[1].announcements[1].text(), "Worn Shortsword, White")
            for _, spec in ipairs(items[1].bindings) do
                t:assertNotEqual(spec.binding, "junk/toggle")
            end
        end)
    end,
})

local function favorite(env, id)
    env.favorites.data.marks[tostring(id)] = "Item " .. id
end

local function favoritesList()
    for _, list in ipairs(WowVision.bagLists.lists) do
        if list.key == "favorites" then
            return list
        end
    end
    error("the Favorites list is not registered")
end

testRunner:addSuite("FavoritesModule", {
    ["the Select Favorite key is a dormant keymap, Shift+Backspace by default"] = function(t)
        withGame(newGame(), function(env)
            local keymap = env.favorites.registeredBindings[1]
            t:assertEqual(#env.favorites.registeredBindings, 1)
            t:assertEqual(keymap.key, "favorite/toggle")
            t:assertEqual(keymap.type, "Flexible")
            t:assertTrue(keymap.dorment, "held only while a node asks for it")
            t:assertEqual(keymap.inputs[1], "SHIFT-BACKSPACE")
            t:assertEqual(#keymap.inputs, 1)
            t:assertEqual(keymap.label, "Select Favorite")
            t:assertEqual(env.favorites.label, "Favorites")
        end)
    end,

    ["Select Favorite marks the item, says so, and a second press takes the mark off"] = function(t)
        local game = newGame()
        game.add(0, 3, 25, { itemName = "Worn Shortsword" })
        game.screen = { _liveKey = "node" }
        withGame(game, function(env)
            env.favorites:toggleAt(0, 3)
            t:assertEqual(game.spoken[1], "Worn Shortsword: marked as favorite")
            t:assertTrue(env.favorites:isMarkedAt(0, 3))
            t:assertEqual(env.favorites.data.marks["25"], "Worn Shortsword")
            t:assertFalse(env.junk:isMarkedAt(0, 3), "junk is a mark of its own")
            t:assertNil(game.screen._liveKey, "the live watch is told: the label was just said")
            env.favorites:toggleAt(0, 3)
            t:assertEqual(game.spoken[2], "Worn Shortsword: no longer a favorite")
            t:assertFalse(env.favorites:isMarkedAt(0, 3))
            t:assertNil(env.favorites.data.marks["25"])
        end)
    end,

    ["an item no vendor buys can be a favorite"] = function(t)
        local game = newGame()
        game.add(0, 1, 6948, { itemName = "Hearthstone", hasNoValue = true })
        withGame(game, function(env)
            env.favorites:toggleAt(0, 1)
            t:assertEqual(game.spoken[1], "Hearthstone: marked as favorite")
            t:assertTrue(env.favorites:isMarkedAt(0, 1))
        end)
    end,

    ["an empty slot and an item with no usable link mark nothing"] = function(t)
        local game = newGame()
        game.add(0, 2, 25, { hyperlink = "|Hbattlepet:1:2:3|h[Cat]|h" })
        withGame(game, function(env)
            env.favorites:toggleAt(0, 5)
            t:assertEqual(game.spoken[1], "Empty")
            env.favorites:toggleAt(0, 2)
            t:assertEqual(game.spoken[2], "This item cannot be marked as a favorite.")
            t:assertNil(next(env.favorites.data.marks))
        end)
    end,

    ["with the module off, the key does nothing and the slots are what they were"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { itemName = "Worn Shortsword" })
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            env.containers = WowVision.base.windows.containers
            env.containers.getBagItemLabel = function()
                return "Worn Shortsword, White"
            end
            favorite(env, 25)
            env.favorites.enabled = false
            env.favorites:toggleAt(0, 1)
            t:assertEqual(#game.spoken, 0)
            local items = renderedSlots(env, { slotButton(0, 1) })
            t:assertEqual(items[1].announcements[1].text(), "Worn Shortsword, White")
            for _, spec in ipairs(items[1].bindings) do
                t:assertNotEqual(spec.binding, "favorite/toggle")
            end
        end)
    end,

    ["bag slots read [Favorite] ahead of [Junk], and carry both keys and both menu entries"] = function(t)
        local game = newGame()
        game.add(0, 1, 25, { itemName = "Worn Shortsword" })
        game.add(0, 2, 26, { itemName = "Linen Cloth" })
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            env.containers = WowVision.base.windows.containers
            env.containers.getBagItemLabel = function(button)
                local info = C_Container.GetContainerItemInfo(button:GetBagID(), button:GetID())
                return info.itemName .. ", White"
            end
            favorite(env, 25)
            mark(env, 25)
            favorite(env, 26)
            local items = renderedSlots(env, { slotButton(0, 1), slotButton(0, 2) })
            t:assertEqual(items[1].announcements[1].text(), "[Favorite] [Junk] Worn Shortsword, White")
            t:assertEqual(items[2].announcements[1].text(), "[Favorite] Linen Cloth, White")
            local keys = {}
            for _, spec in ipairs(items[1].bindings) do
                keys[spec.binding] = spec
            end
            t:assertNotNil(keys["favorite/toggle"])
            t:assertNotNil(keys["junk/toggle"])
            keys["favorite/toggle"].func()
            t:assertFalse(env.favorites:isMarkedAt(0, 1))
            t:assertTrue(env.junk:isMarkedAt(0, 1), "the other mark stays")
            local labels = {}
            items[1].contextActions(function(entry)
                tinsert(labels, entry.label)
            end, {})
            t:assertEqual(table.concat(labels, ","), "Left Click,Right Click,Drag,Mark as Favorite,Unmark as Junk")
        end)
    end,

    ["the Favorites list of the Item Lists holds the marked slots in bag order, after Junk"] = function(t)
        local game = newGame()
        game.add(2, 3, 30, { itemName = "Third" })
        game.add(0, 5, 10, { itemName = "First" })
        game.add(0, 2, 11, { itemName = "Not marked" })
        withGame(game, function(env)
            loadFile("core/windows/containers.lua")
            local containers = WowVision.base.windows.containers
            containers.getBagItemLabel = function(button)
                return C_Container.GetContainerItemInfo(button:GetBagID(), button:GetID()).itemName
            end
            favorite(env, 30)
            favorite(env, 10)
            local list = favoritesList()
            t:assertEqual(list.label, "Favorites")
            t:assertTrue(list.order > junkList().order)
            local selected = list.select(WowVision.bagLists.sorted({ slotButton(2, 3), slotButton(0, 5), slotButton(0, 2) }))
            t:assertEqual(#selected, 2)
            t:assertEqual(containers.slotNode(selected[1]).announcements[1].text(), "[Favorite] First")
            t:assertEqual(containers.slotNode(selected[2]).announcements[1].text(), "[Favorite] Third")
            env.favorites.enabled = false
            t:assertEqual(#list.select({ slotButton(0, 5) }), 0, "switched off, the list is empty")
        end)
    end,

    ["a favorite is not sold at a merchant, even marked as junk, even grey"] = function(t)
        local game = newGame()
        game.add(0, 1, 100, { itemName = "Linen Cloth" })
        game.add(0, 2, 101, { itemName = "Worn Shortsword" })
        game.add(0, 3, 102, { itemName = "Grey Fang", quality = 0 })
        game.add(0, 4, 103, { itemName = "Grey Claw", quality = 0 })
        withGame(game, function(env)
            mark(env, 100)
            mark(env, 101)
            favorite(env, 100)
            favorite(env, 102)
            env.merchant.settings.autoSellPoorItems = true
            open(env)
            t:assertEqual(table.concat(game.sold, " "), "0:2 0:4")
            t:assertNotNil(game.bags[0][1], "marked as junk and as favorite: kept")
            t:assertNotNil(game.bags[0][3], "a grey favorite: kept")
            t:assertEqual(#game.errors, 0)
        end)
    end,

    ["switching the favorites off hides them without making the items sellable"] = function(t)
        local game = newGame()
        game.add(0, 1, 100, { itemName = "Linen Cloth" })
        withGame(game, function(env)
            mark(env, 100)
            favorite(env, 100)
            env.favorites.enabled = false
            open(env)
            t:assertEqual(#game.sold, 0)
        end)
    end,

    ["favorites alone sell nothing"] = function(t)
        local game = newGame()
        game.add(0, 1, 100, { itemName = "Linen Cloth", quality = 0 })
        withGame(game, function(env)
            favorite(env, 100)
            open(env)
            t:assertEqual(#game.sold, 0)
            t:assertEqual(#game.spoken, 0)
        end)
    end,
})

-- newItems.lua starts listening to the bags as it loads. It is loaded afresh here, with a stand-in for frames, and
-- what it replaced on WowVision is put back.
testRunner:addSuite("NewItemsWiring", {
    ["the new items start listening to the bags and to entering the world when the file loads"] = function(t)
        local savedNewItems, savedFrame = WowVision.newItems, CreateFrame
        local previous
        for _, list in ipairs(WowVision.bagLists.lists) do
            if list.key == "new" then
                previous = list
            end
        end
        local registered, scripts = {}, {}
        CreateFrame = function()
            return {
                RegisterEvent = function(_, event)
                    registered[event] = true
                end,
                SetScript = function(_, name, fn)
                    scripts[name] = fn
                end,
            }
        end
        local ok, err = pcall(loadFile, "core/windows/newItems.lua")
        CreateFrame = savedFrame
        WowVision.newItems = savedNewItems
        if previous ~= nil then
            WowVision.bagLists.register(previous)
        end
        if not ok then
            error(err, 0)
        end
        t:assertTrue(registered.PLAYER_ENTERING_WORLD)
        t:assertTrue(registered.BAG_UPDATE_DELAYED)
        t:assertEqual(type(scripts.OnEvent), "function")
    end,
})
