-- The lists of items the bags offer as categories of one stop, "Item Lists", ahead of the bags: the items the
-- game marks as new, the items the player marked as junk, and whatever else registers.
--
-- A list is { key, label, order, expanded, select, reset }: select(buttons) answers the slots of the list out of
-- all the bag slots given (bag by bag, slots ascending), and reset() is called when the bags close. A list with
-- nothing in it is not shown; expanded makes it start open each time the bags open.
local bagLists = { lists = {}, seeded = {}, reported = {} }
WowVision.bagLists = bagLists

local function bagIdOf(itemButton)
    return itemButton.GetBagID ~= nil and itemButton:GetBagID() or 0
end

function bagLists.register(list)
    for index, existing in ipairs(bagLists.lists) do
        if existing.key == list.key then
            bagLists.lists[index] = list
            return
        end
    end
    tinsert(bagLists.lists, list)
    table.sort(bagLists.lists, function(a, b)
        local aOrder, bOrder = a.order or 100, b.order or 100
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end
        return a.key < b.key
    end)
end

-- Slots gathered from several frames, bag by bag and slot by slot. A new table: the given list is not changed.
-- Each button is asked for its bag and slot once (this runs on every rebuild of the bags), not at every
-- comparison of the sort.
local SLOTS_PER_BAG = 100000

function bagLists.sorted(buttons)
    local sorted, place = {}, {}
    for index, itemButton in ipairs(buttons) do
        sorted[index] = itemButton
        place[itemButton] = bagIdOf(itemButton) * SLOTS_PER_BAG + itemButton:GetID()
    end
    table.sort(sorted, function(a, b)
        return place[a] < place[b]
    end)
    return sorted
end

-- { { list = list, buttons = { ... } }, ... }: the lists that have something now, in their order. One that fails
-- is left out and reported once.
function bagLists.collect(buttons)
    local collected = {}
    for _, list in ipairs(bagLists.lists) do
        local ok, selected = pcall(list.select, buttons)
        if not ok then
            if not bagLists.reported[list.key] then
                bagLists.reported[list.key] = true
                geterrorhandler()(selected)
            end
        elseif type(selected) == "table" and #selected > 0 then
            tinsert(collected, { list = list, buttons = selected })
        end
    end
    return collected
end

-- The bags closed.
function bagLists.reset()
    if next(bagLists.seeded) ~= nil then
        bagLists.seeded = {}
    end
    for _, list in ipairs(bagLists.lists) do
        if list.reset ~= nil then
            pcall(list.reset)
        end
    end
end
