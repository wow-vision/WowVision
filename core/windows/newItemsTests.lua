local testRunner = WowVision.testing.testRunner
local newItems = WowVision.newItems

-- The new-items list of the bags (newItems.lua). The game's item data and the buttons are stand-ins.

local GLOBALS = { "C_Container", "C_NewItems" }

-- Runs fn(world) with a fake bag contents table: world.items["bag:slot"] = itemID, world.flagged["bag:slot"] = true.
local function inWorld(fn)
    local saved = {}
    for _, name in ipairs(GLOBALS) do
        saved[name] = _G[name]
    end
    local world = { items = {}, flagged = {} }
    C_Container = {
        GetContainerItemID = function(bagID, slotID)
            return world.items[bagID .. ":" .. slotID]
        end,
    }
    C_NewItems = {
        IsNewItem = function(bagID, slotID)
            return world.flagged[bagID .. ":" .. slotID] == true
        end,
    }
    newItems.reset()
    local ok, err = pcall(fn, world)
    newItems.reset()
    for _, name in ipairs(GLOBALS) do
        _G[name] = saved[name]
    end
    if not ok then
        error(err, 0)
    end
end

local function button(bagID, slotID, glow)
    local result = {
        GetBagID = function()
            return bagID
        end,
        GetID = function()
            return slotID
        end,
        name = bagID .. ":" .. slotID,
    }
    if glow ~= nil then
        result.NewItemTexture = {
            IsShown = function()
                return glow
            end,
        }
    end
    return result
end

local function names(list)
    local out = {}
    for _, itemButton in ipairs(list) do
        tinsert(out, itemButton.name)
    end
    return table.concat(out, ",")
end

testRunner:addSuite("New items", {
    ["only the slots the game flags as new are listed"] = function(t)
        inWorld(function(world)
            world.items["0:1"], world.items["0:2"], world.items["1:1"] = 100, 101, 102
            world.flagged["0:2"], world.flagged["1:1"] = true, true
            local slots = { button(0, 1), button(0, 2), button(1, 1) }
            t:assertEqual(names(newItems.list(slots)), "0:2,1:1")
        end)
    end,

    ["the glow on the button counts when the game's list does not"] = function(t)
        inWorld(function(world)
            world.items["0:1"], world.items["0:2"] = 100, 101
            local slots = { button(0, 1, false), button(0, 2, true) }
            t:assertEqual(names(newItems.list(slots)), "0:2")
        end)
    end,

    ["an item stays listed after the game clears its flag, as hovering does"] = function(t)
        inWorld(function(world)
            world.items["0:1"] = 100
            world.flagged["0:1"] = true
            local slots = { button(0, 1) }
            t:assertEqual(names(newItems.list(slots)), "0:1")
            world.flagged["0:1"] = nil -- the cursor reached it
            t:assertEqual(names(newItems.list(slots)), "0:1", "still listed")
        end)
    end,

    ["a slot that now holds another item, or none, drops out"] = function(t)
        inWorld(function(world)
            world.items["0:1"], world.items["0:2"] = 100, 101
            world.flagged["0:1"], world.flagged["0:2"] = true, true
            local slots = { button(0, 1), button(0, 2) }
            t:assertEqual(names(newItems.list(slots)), "0:1,0:2")
            world.flagged = {}
            world.items["0:1"] = 999 -- sold and replaced by something else
            world.items["0:2"] = nil -- sold
            t:assertEqual(names(newItems.list(slots)), "")
            world.items["0:1"] = 100 -- the old item back: it was forgotten, it is not new
            t:assertEqual(names(newItems.list(slots)), "")
        end)
    end,

    ["closing the bags forgets what was seen"] = function(t)
        inWorld(function(world)
            world.items["0:1"] = 100
            world.flagged["0:1"] = true
            local slots = { button(0, 1) }
            t:assertEqual(names(newItems.list(slots)), "0:1")
            world.flagged = {}
            newItems.reset()
            t:assertEqual(names(newItems.list(slots)), "")
        end)
    end,

    ["an empty slot is never new, even if the game still flags it"] = function(t)
        inWorld(function(world)
            world.flagged["0:1"] = true
            t:assertEqual(names(newItems.list({ button(0, 1) })), "")
        end)
    end,

    ["a client without the new-item list and without a glow lists nothing"] = function(t)
        inWorld(function(world)
            C_NewItems = nil
            world.items["0:1"] = 100
            t:assertEqual(names(newItems.list({ button(0, 1) })), "")
        end)
    end,

    ["a failing game call does not break the list"] = function(t)
        inWorld(function(world)
            world.items["0:1"], world.items["0:2"] = 100, 101
            world.flagged["0:2"] = true
            C_NewItems.IsNewItem = function(bagID, slotID)
                if slotID == 1 then
                    error("boom")
                end
                return true
            end
            t:assertEqual(names(newItems.list({ button(0, 1), button(0, 2) })), "0:2")
        end)
    end,

    ["the item ID falls back to the item info when the client has no direct call"] = function(t)
        inWorld(function(world)
            C_Container = {
                GetContainerItemInfo = function(bagID, slotID)
                    local id = world.items[bagID .. ":" .. slotID]
                    return id ~= nil and { itemID = id } or nil
                end,
            }
            world.items["0:1"] = 100
            world.flagged["0:1"] = true
            t:assertEqual(names(newItems.list({ button(0, 1) })), "0:1")
        end)
    end,

    ["the list is one of the bags' lists, open to start with"] = function(t)
        local list
        for _, candidate in ipairs(WowVision.bagLists.lists) do
            if candidate.key == "new" then
                list = candidate
            end
        end
        t:assertNotNil(list)
        t:assertTrue(list.expanded)
        t:assertEqual(list.select, newItems.list)
        t:assertEqual(list.reset, newItems.reset)
    end,

    ["an item button without a bag id reads as the backpack"] = function(t)
        inWorld(function(world)
            world.items["0:4"] = 100
            world.flagged["0:4"] = true
            local plain = { GetID = function() return 4 end, name = "plain" }
            t:assertEqual(names(newItems.list({ plain })), "plain")
        end)
    end,
})

-- The items that arrive: what the bags hold of each item is counted after every change of the bags, since the game
-- does not flag everything (the reward of a quest). The bags and the clock are stand-ins.

local ARRIVAL_GLOBALS = { "C_Container", "C_NewItems", "GetTime", "CreateFrame", "NUM_TOTAL_EQUIPPED_BAG_SLOTS" }

-- Runs fn(world) with bags that hold world.items["bag:slot"] = { itemID, stackCount } and a clock the test moves.
local function inBags(fn)
    local saved = {}
    for _, name in ipairs(ARRIVAL_GLOBALS) do
        saved[name] = _G[name]
    end
    local world = { items = {}, flagged = {}, now = 100 }
    function world.put(bagID, slotID, itemID, count)
        world.items[bagID .. ":" .. slotID] = { itemID = itemID, stackCount = count or 1 }
    end
    -- the game says the bags changed, a second later
    function world.changed()
        world.now = world.now + 1
        newItems.onEvent("BAG_UPDATE_DELAYED")
    end
    -- the game has been entered, and the bags have had time to fill in
    function world.login()
        newItems.onEvent("PLAYER_ENTERING_WORLD", true, false)
        world.now = world.now + 10
    end
    C_Container = {
        GetContainerNumSlots = function(bagID)
            local size = 0
            for key in pairs(world.items) do
                if tonumber(key:match("^(%d+):")) == bagID then
                    size = math.max(size, tonumber(key:match(":(%d+)$")))
                end
            end
            return size
        end,
        GetContainerItemInfo = function(bagID, slotID)
            return world.items[bagID .. ":" .. slotID]
        end,
        GetContainerItemID = function(bagID, slotID)
            local info = world.items[bagID .. ":" .. slotID]
            return info ~= nil and info.itemID or nil
        end,
    }
    C_NewItems = {
        IsNewItem = function(bagID, slotID)
            return world.flagged[bagID .. ":" .. slotID] == true
        end,
    }
    GetTime = function()
        return world.now
    end
    NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
    newItems.restart()
    local ok, err = pcall(fn, world)
    newItems.restart()
    for _, name in ipairs(ARRIVAL_GLOBALS) do
        _G[name] = saved[name]
    end
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("New items arrivals", {
    ["a quest reward the game does not flag is listed"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.login()
            world.put(0, 2, 6948)
            world.changed()
            t:assertEqual(names(newItems.list({ button(0, 1), button(0, 2) })), "0:2")
        end)
    end,

    ["what the bags held when the game was entered is not new, nor what fills in just after"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            newItems.onEvent("PLAYER_ENTERING_WORLD", true, false)
            world.put(0, 2, 2592)
            world.changed()
            world.put(0, 3, 4306)
            world.changed()
            world.now = world.now + 10
            world.changed()
            t:assertEqual(#newItems.arrivedIDs(), 0)
        end)
    end,

    ["a stack that grows is new, and so is every slot that holds the item"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589, 20)
            world.put(1, 4, 2589, 3)
            world.login()
            world.put(1, 4, 2589, 4)
            world.changed()
            t:assertEqual(names(newItems.list({ button(0, 1), button(1, 4) })), "0:1,1:4")
        end)
    end,

    ["moving, sorting, splitting and using part of a stack arrive nothing"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589, 10)
            world.put(0, 2, 2592)
            world.login()
            -- swapped
            world.items["0:1"], world.items["0:2"] = world.items["0:2"], world.items["0:1"]
            world.changed()
            -- moved to another bag
            world.items["1:3"] = world.items["0:2"]
            world.items["0:2"] = nil
            world.changed()
            -- split in two
            world.put(0, 1, 2592)
            world.put(0, 4, 2589, 4)
            world.put(1, 3, 2589, 6)
            world.changed()
            -- some of it used
            world.put(1, 3, 2589, 2)
            world.changed()
            t:assertEqual(#newItems.arrivedIDs(), 0)
        end)
    end,

    ["an arrival waits while the bags are closed, and goes once they were open and closed"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.login()
            world.put(0, 2, 6948)
            world.changed()
            -- the window asks whether the bags are open, and resets, all the time they are not
            newItems.reset()
            newItems.reset()
            t:assertEqual(#newItems.arrivedIDs(), 1, "still waiting")
            t:assertEqual(names(newItems.list({ button(0, 1), button(0, 2) })), "0:2")
            newItems.reset()
            t:assertEqual(names(newItems.list({ button(0, 1), button(0, 2) })), "", "looked at")
        end)
    end,

    ["an arrival while the bags are open is listed at once"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.login()
            t:assertEqual(names(newItems.list({ button(0, 1) })), "")
            world.put(0, 2, 6948)
            world.changed()
            t:assertEqual(names(newItems.list({ button(0, 1), button(0, 2) })), "0:2")
        end)
    end,

    ["an item that is gone and comes back is a new arrival again"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.login()
            world.put(0, 2, 6948)
            world.changed()
            world.items["0:2"] = nil -- handed in
            world.changed()
            t:assertEqual(#newItems.arrivedIDs(), 0)
            world.put(0, 2, 6948)
            world.changed()
            t:assertEqual(#newItems.arrivedIDs(), 1)
        end)
    end,

    ["a loading screen only waits, and keeps what had arrived"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.login()
            world.put(0, 2, 6948)
            world.changed()
            newItems.onEvent("PLAYER_ENTERING_WORLD", false, false)
            t:assertEqual(#newItems.arrivedIDs(), 1)
            world.put(0, 3, 2592)
            world.changed() -- while the game fills the bags in
            t:assertEqual(#newItems.arrivedIDs(), 1)
            world.now = world.now + 5
            world.put(0, 4, 4306)
            world.changed()
            t:assertEqual(#newItems.arrivedIDs(), 2)
        end)
    end,

    ["a reload starts over"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.login()
            world.put(0, 2, 6948)
            world.changed()
            newItems.onEvent("PLAYER_ENTERING_WORLD", false, true)
            t:assertEqual(#newItems.arrivedIDs(), 0)
        end)
    end,

    ["the game's own flag still counts next to the arrivals"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.put(0, 2, 2592)
            world.login()
            world.flagged["0:1"] = true
            world.put(0, 3, 6948)
            world.changed()
            t:assertEqual(names(newItems.list({ button(0, 1), button(0, 2), button(0, 3) })), "0:1,0:3")
        end)
    end,

    ["bags that cannot be read arrive nothing and break nothing"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.login()
            local read = C_Container.GetContainerItemInfo
            C_Container.GetContainerItemInfo = function()
                error("bags unavailable")
            end
            world.changed()
            C_Container.GetContainerItemInfo = read
            C_Container.GetContainerNumSlots = nil
            world.changed()
            t:assertEqual(#newItems.arrivedIDs(), 0)
        end)
    end,

    ["events that are not a change of the bags arrive nothing"] = function(t)
        inBags(function(world)
            world.put(0, 1, 2589)
            world.login()
            world.put(0, 2, 6948)
            world.now = world.now + 1
            newItems.onEvent("BAG_UPDATE")
            newItems.onEvent("MERCHANT_SHOW")
            t:assertEqual(#newItems.arrivedIDs(), 0)
            newItems.onEvent("BAG_UPDATE_DELAYED")
            t:assertEqual(#newItems.arrivedIDs(), 1)
        end)
    end,

    ["the item IDs that arrived come in a fixed order"] = function(t)
        inBags(function(world)
            world.login()
            world.put(0, 1, 30)
            world.put(0, 2, 10)
            world.put(0, 3, 20)
            world.changed()
            t:assertEqual(table.concat(newItems.arrivedIDs(), ","), "10,20,30")
        end)
    end,

    ["WowVision listens to the bags and to entering the world, once"] = function(t)
        inBags(function(world)
            local registered, handler = {}, nil
            CreateFrame = function()
                return {
                    RegisterEvent = function(_, event)
                        registered[event] = true
                    end,
                    SetScript = function(_, name, fn)
                        if name == "OnEvent" then
                            handler = fn
                        end
                    end,
                }
            end
            local savedFrame = newItems.frame
            newItems.frame = nil
            t:assertTrue(newItems.watch())
            t:assertTrue(registered.PLAYER_ENTERING_WORLD)
            t:assertTrue(registered.BAG_UPDATE_DELAYED)
            t:assertFalse(newItems.watch(), "once")
            world.put(0, 1, 2589)
            handler(nil, "PLAYER_ENTERING_WORLD", true, false)
            world.now = world.now + 10
            world.put(0, 2, 6948)
            handler(nil, "BAG_UPDATE_DELAYED")
            t:assertEqual(#newItems.arrivedIDs(), 1)
            newItems.frame = savedFrame
        end)
    end,
})
