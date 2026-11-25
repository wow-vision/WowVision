-- Headless only (tools/headless-tests.lua loads module.lua against a stand-in window module and hands over the
-- loader): the stop, the merchant category and the command, over the real graph builder and a stand-in game.
local testRunner = WowVision.testing.testRunner
local harness = WowVision._auctionHintsTestHarness
local hints = WowVision.auctionHints

local module, registered = harness.load({ LifeOnAzeroth_Data = true })

-- Another load of module.lua, without leaving its game calls behind for the module above.
local function loadOther(loaded)
    local saved = {}
    for key, value in pairs(hints.game) do
        saved[key] = value
    end
    local other, otherRegistered = harness.load(loaded)
    for key, value in pairs(saved) do
        hints.game[key] = value
    end
    return other, otherRegistered
end

-- bags[bag][slot] = { id, count, bound, favorite }; item 1 is for the auction house, item 2 is bound.
local ITEMS = {
    [1] = { name = "Ring", sellPrice = 500, bindType = 2 },
    [2] = { name = "Blade", sellPrice = 900, bindType = 1 },
}

local function withBags(test)
    local world = { bags = {}, combat = false, favorite = {}, said = {} }
    local saved = {}
    for key, value in pairs(hints.game) do
        saved[key] = value
    end
    local game = hints.game
    game.market = function()
        return { built = 100, houses = { ["1H"] = { latS = "1,1000,\n2,5000,\n" } } }
    end
    game.marketSettings = function()
        return nil
    end
    game.realmName = function()
        return "Spineshatter"
    end
    game.faction = function()
        return "Horde"
    end
    game.time = function()
        return 100
    end
    game.dateParts = function()
        return { month = 1, day = 1, hour = 0, min = 0 }
    end
    game.inCombat = function()
        return world.combat
    end
    game.carried = function()
        return { [0] = true, [1] = true }
    end
    game.numSlots = function(bag)
        return bag == 0 and 4 or 2
    end
    game.bagButtons = function()
        local buttons = {}
        for _, bag in ipairs({ 0, 1, 6 }) do
            for slot = 1, 4 do
                if world.bags[bag] ~= nil and world.bags[bag][slot] ~= nil then
                    tinsert(buttons, { bag = bag, slot = slot })
                end
            end
        end
        return buttons
    end
    game.slotInfo = function(bag, slot)
        local item = world.bags[bag] ~= nil and world.bags[bag][slot] or nil
        if item == nil then
            return nil
        end
        return { itemID = item.id, link = "item:" .. item.id, count = item.count or 1, bound = false }
    end
    game.itemInfo = function(linkOrID)
        local id = tonumber(linkOrID) or tonumber(linkOrID:match("item:(%d+)"))
        return ITEMS[id]
    end
    game.locationBound = function()
        return false
    end
    game.accountBoundUntilEquip = function()
        return false
    end
    game.durability = function()
        return nil, nil
    end
    game.coinText = function(copper)
        return math.floor(copper + 0.5) .. "c"
    end
    game.itemName = function(name)
        return name
    end
    game.isFavorite = function(link)
        return world.favorite[link] == true
    end
    local savedBase, savedSpeak = WowVision.base, WowVision.speak
    local containers = {}
    containers.slotLocation = function(button)
        return button.bag, button.slot
    end
    containers.itemClickLabels = function()
        return nil
    end
    containers.slotIsEmpty = function()
        return false
    end
    containers.getBagItemLabel = function(button)
        return "bag label " .. button.slot
    end
    containers.itemSlotNode = function(button, label)
        local vtable = WowVision.graph.nodes.text({ label = label })
        vtable.button = button
        return vtable
    end
    WowVision.base = { windows = { containers = containers } }
    WowVision.speak = function(_, text)
        tinsert(world.said, text)
    end
    local savedShow, savedCut, savedEnabled = module.settings.show, module.settings.countCut, module.enabled
    module.settings.show = true
    local ok, err = pcall(test, world)
    module.settings.show, module.settings.countCut, module.enabled = savedShow, savedCut, savedEnabled
    for key in pairs(game) do
        game[key] = nil
    end
    for key, value in pairs(saved) do
        game[key] = value
    end
    WowVision.base, WowVision.speak = savedBase, savedSpeak
    if not ok then
        error(err, 0)
    end
end

local function render()
    local builder = WowVision.graph.Builder:new()
    module.renderStop(builder)
    return builder:build()
end

local function labelOf(node)
    local label = node.vtable.announcements[1].text
    if type(label) == "function" then
        label = label()
    end
    return label
end

local function nodesOf(rendered)
    return rendered ~= nil and rendered.order or {}
end

testRunner:addSuite("AuctionHintsModule", {
    ["without Life on Azeroth Market's data there is no module"] = function(t)
        local other, nothing = loadOther({})
        t:assertNil(other)
        t:assertEqual(#nothing.lists + #nothing.stops, 0)
        t:assertNil(loadOther(nil))
    end,

    ["either of Market's two addons brings the module, whatever the case"] = function(t)
        for _, name in ipairs({ "LifeOnAzeroth_Data", "lifeonazeroth_data", "LifeOnAzeroth_Market", "lifeonazeroth_market" }) do
            t:assertNotNil(loadOther({ [name] = true }))
        end
    end,

    ["it registers a merchant category after the others, a stop and a command"] = function(t)
        t:assertEqual(registered.key, "auctionHints")
        t:assertEqual(registered.lists[1].key, "merchant")
        t:assertEqual(registered.lists[1].order, 40)
        t:assertEqual(registered.stops[1].key, "auctionHints")
        t:assertNotNil(registered.commands.sell)
    end,

    ["showing is off until the player turns it on, the cut counted"] = function(t)
        local other = loadOther({ LifeOnAzeroth_Data = true })
        t:assertFalse(other.settings.show)
        t:assertTrue(other.settings.countCut)
    end,

    ["the stop reads the summary, then one line per item of the carried bags"] = function(t)
        withBags(function(world)
            world.bags = { [0] = { { id = 1 }, { id = 2 } }, [1] = { { id = 1, count = 2 } }, [6] = { { id = 1 } } }
            local graphRender = render()
            local nodes = nodesOf(graphRender)
            t:assertEqual(#nodes, 2)
            t:assertTrue(labelOf(nodes[1]):find("1 item sells", 1, true) ~= nil)
            t:assertTrue(labelOf(nodes[2]):find("Ring, 3 in 2 stacks", 1, true) ~= nil)
        end)
    end,

    ["a line whose stacks changed reads the bags' own label"] = function(t)
        withBags(function(world)
            world.bags = { [0] = { { id = 1, count = 3 } } }
            local nodes = nodesOf(render())
            world.bags[0][1].count = 2
            t:assertEqual(labelOf(nodes[2]), "bag label 1")
        end)
    end,

    ["nothing is drawn when off, disabled, in combat or without carried bags"] = function(t)
        withBags(function(world)
            world.bags = { [0] = { { id = 1 } } }
            module.settings.show = false
            t:assertEqual(#nodesOf(render()), 0)
            module.settings.show = true
            module.enabled = false
            t:assertEqual(#nodesOf(render()), 0)
            module.enabled = true
            world.combat = true
            t:assertEqual(#nodesOf(render()), 0)
            world.combat = false
            world.bags = { [6] = { { id = 1 } } }
            t:assertEqual(#nodesOf(render()), 0)
        end)
    end,

    ["the merchant category holds the first stack of each item a vendor buys, no favorites"] = function(t)
        withBags(function(world)
            world.bags = { [0] = { { id = 2 }, { id = 1 }, { id = 2 } } }
            local buttons = hints.game.bagButtons()
            local selected = module.merchantSlots(buttons)
            t:assertEqual(#selected, 1)
            t:assertEqual(selected[1].slot, 1)
            world.favorite["item:2"] = true
            t:assertEqual(#module.merchantSlots(buttons), 0)
            world.favorite = {}
            module.settings.show = false
            t:assertEqual(#module.merchantSlots(buttons), 0)
        end)
    end,

    ["the command reads the carried bags without a window, and refuses in combat"] = function(t)
        withBags(function(world)
            world.bags = { [0] = { { id = 1 } }, [1] = { [2] = { id = 2 } } }
            module.settings.show = false
            registered.commands.sell.func()
            t:assertTrue(world.said[1]:find("Occupied slots in your bags: 2", 1, true) ~= nil)
            world.combat = true
            registered.commands.sell.func()
            t:assertEqual(world.said[2], "The list is not available during combat.")
        end)
    end,

    ["the cut setting counts or leaves out the cut"] = function(t)
        withBags(function(world)
            world.bags = { [0] = { { id = 1 } } }
            module.settings.countCut = false
            t:assertTrue(labelOf(nodesOf(render())[1]):find("fees not deducted", 1, true) ~= nil)
        end)
    end,
})
