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
