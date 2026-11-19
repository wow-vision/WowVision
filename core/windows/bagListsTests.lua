local testRunner = WowVision.testing.testRunner
local bagLists = WowVision.bagLists

-- The lists of the bags' "Item Lists" stop (bagLists.lua). The slots are stand-ins.

local function button(bagID, slotID)
    return {
        GetBagID = function()
            return bagID
        end,
        GetID = function()
            return slotID
        end,
        name = bagID .. ":" .. slotID,
    }
end

local function names(list)
    local out = {}
    for _, itemButton in ipairs(list) do
        tinsert(out, itemButton.name)
    end
    return table.concat(out, ",")
end

-- Runs fn with an empty registry, then puts the real lists back.
local function withRegistry(fn)
    local lists, seeded, reported = bagLists.lists, bagLists.seeded, bagLists.reported
    bagLists.lists, bagLists.seeded, bagLists.reported = {}, {}, {}
    local handler = geterrorhandler
    local errors = {}
    geterrorhandler = function()
        return function(err)
            tinsert(errors, tostring(err))
        end
    end
    local ok, err = pcall(fn, errors)
    geterrorhandler = handler
    bagLists.lists, bagLists.seeded, bagLists.reported = lists, seeded, reported
    if not ok then
        error(err, 0)
    end
end

local function keys(entries)
    local out = {}
    for _, entry in ipairs(entries) do
        tinsert(out, entry.list.key)
    end
    return table.concat(out, ",")
end

testRunner:addSuite("Bag lists", {
    ["lists come in their order, then by key"] = function(t)
        withRegistry(function()
            local all = function(buttons)
                return buttons
            end
            bagLists.register({ key = "junk", order = 20, select = all })
            bagLists.register({ key = "new", order = 10, select = all })
            bagLists.register({ key = "b", select = all })
            bagLists.register({ key = "a", select = all })
            t:assertEqual(keys(bagLists.collect({ button(0, 1) })), "new,junk,a,b")
        end)
    end,

    ["registering a key again replaces its list"] = function(t)
        withRegistry(function()
            bagLists.register({ key = "x", order = 1, label = "first", select = function(b) return b end })
            bagLists.register({ key = "x", order = 1, label = "second", select = function(b) return b end })
            t:assertEqual(#bagLists.lists, 1)
            t:assertEqual(bagLists.lists[1].label, "second")
        end)
    end,

    ["a list with nothing in it is left out"] = function(t)
        withRegistry(function()
            bagLists.register({ key = "empty", order = 1, select = function() return {} end })
            bagLists.register({ key = "some", order = 2, select = function(buttons) return { buttons[1] } end })
            local collected = bagLists.collect({ button(0, 1), button(0, 2) })
            t:assertEqual(keys(collected), "some")
            t:assertEqual(names(collected[1].buttons), "0:1")
        end)
    end,

    ["a list that fails is left out and reported once"] = function(t)
        withRegistry(function(errors)
            bagLists.register({ key = "bad", order = 1, select = function() error("boom") end })
            bagLists.register({ key = "good", order = 2, select = function(b) return b end })
            t:assertEqual(keys(bagLists.collect({ button(0, 1) })), "good")
            t:assertEqual(keys(bagLists.collect({ button(0, 1) })), "good")
            t:assertEqual(#errors, 1)
        end)
    end,

    ["closing the bags resets every list and the open state"] = function(t)
        withRegistry(function()
            local resets = 0
            bagLists.register({ key = "a", select = function() return {} end, reset = function() resets = resets + 1 end })
            bagLists.register({ key = "b", select = function() return {} end })
            bagLists.register({ key = "c", select = function() return {} end, reset = function() error("boom") end })
            bagLists.seeded.a = true
            bagLists.reset()
            t:assertEqual(resets, 1)
            t:assertNil(bagLists.seeded.a)
        end)
    end,

    ["slots from several frames sort bag by bag, slot by slot"] = function(t)
        local slots = { button(1, 2), button(0, 5), button(1, 1), button(0, 3) }
        t:assertEqual(names(bagLists.sorted(slots)), "0:3,0:5,1:1,1:2")
        t:assertEqual(names(slots), "1:2,0:5,1:1,0:3", "the given list is not changed")
    end,

    ["a slot without a bag id reads as the backpack"] = function(t)
        local plain = { GetID = function() return 4 end, name = "plain" }
        t:assertEqual(names(bagLists.sorted({ button(1, 1), plain })), "plain,1:1")
    end,
})
