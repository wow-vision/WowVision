-- The new items of the bags: what you looted, bought, were given or got from a quest since you last looked.
--
-- Two sources, both listed:
--
-- 1. The game's own flag. The game shows a glow on a new item and clears it the moment the item is hovered, and
--    WowVision hovers every slot it focuses, so an item would leave the list as soon as the cursor reached it.
--    The list therefore remembers each slot it has seen flagged, together with the item that was in it, until the
--    bags close; a slot that now holds another item, or none, drops out.
--
-- 2. What WowVision sees arrive. The game does not always flag everything (the reward of a quest went unflagged
--    on WoW: Forever), so WowVision also counts what the carried bags hold of each item after every
--    change of the bags, and an item of which they now hold more than before has arrived. Moving, sorting and
--    splitting items change no total, so they arrive nothing. An arrival is listed on every slot that holds that
--    item and is kept while the bags are closed, until they have been open and closed again.
local newItems = {}
WowVision.newItems = newItems

-- slot key ("bag:slot") -> the item ID that was flagged there
local seen = {}

-- item ID -> true for an item that arrived since the bags were last looked at
local arrived = {}

-- item ID -> how many of it the carried bags held after the last change
local baseline = nil

-- Until this time (seconds of the game's clock) a change of the bags is the game filling them in, not an arrival:
-- right after logging in, reloading or crossing a loading screen.
local graceUntil = 0

-- Whether the list has been drawn since the last reset: arrivals are kept for as long as the bags are closed.
local looked = false

local LOGIN_GRACE = 5
local ZONE_GRACE = 2

local function slotKey(bagID, slotID)
    return bagID .. ":" .. slotID
end

-- The ID of the item in a slot, or nil for an empty slot (or a client that cannot tell).
local function itemIdAt(bagID, slotID)
    local container = rawget(_G, "C_Container")
    if container == nil then
        return nil
    end
    if container.GetContainerItemID ~= nil then
        local ok, id = pcall(container.GetContainerItemID, bagID, slotID)
        if ok and type(id) == "number" then
            return id
        end
    end
    if container.GetContainerItemInfo ~= nil then
        local ok, info = pcall(container.GetContainerItemInfo, bagID, slotID)
        if ok and type(info) == "table" and type(info.itemID) == "number" then
            return info.itemID
        end
    end
    return nil
end

-- Whether the game flags this slot as holding a new item: its own list of new items, or the glow on the button.
function newItems.isFlagged(itemButton, bagID, slotID)
    local api = rawget(_G, "C_NewItems")
    if api ~= nil and api.IsNewItem ~= nil then
        local ok, isNew = pcall(api.IsNewItem, bagID, slotID)
        if ok and isNew == true then
            return true
        end
    end
    local glow = itemButton.NewItemTexture
    if glow ~= nil and glow.IsShown ~= nil then
        local ok, shown = pcall(glow.IsShown, glow)
        if ok and shown == true then
            return true
        end
    end
    return false
end

local function bagIdOf(itemButton)
    return itemButton.GetBagID ~= nil and itemButton:GetBagID() or 0
end

-- The slots to list, in the order given (bag by bag, slots ascending): the ones flagged now, the ones seen
-- flagged earlier that still hold the same item, and every slot that holds an item that arrived.
function newItems.list(buttons)
    looked = true
    local list = {}
    for _, itemButton in ipairs(buttons) do
        local bagID, slotID = bagIdOf(itemButton), itemButton:GetID()
        local key = slotKey(bagID, slotID)
        local itemID = itemIdAt(bagID, slotID)
        if itemID == nil then
            seen[key] = nil
        else
            if newItems.isFlagged(itemButton, bagID, slotID) then
                seen[key] = itemID
            end
            if seen[key] == itemID or arrived[itemID] == true then
                tinsert(list, itemButton)
            else
                seen[key] = nil
            end
        end
    end
    return list
end

-- How many of each item the carried bags hold: { [itemID] = count }, nil when the bags cannot be read.
local function carriedTotals()
    local container = rawget(_G, "C_Container")
    if container == nil or container.GetContainerNumSlots == nil or container.GetContainerItemInfo == nil then
        return nil
    end
    local lastBag = rawget(_G, "NUM_TOTAL_EQUIPPED_BAG_SLOTS") or rawget(_G, "NUM_BAG_SLOTS") or 4
    local totals = {}
    for bagID = 0, lastBag do
        local okSlots, slots = pcall(container.GetContainerNumSlots, bagID)
        if okSlots and type(slots) == "number" then
            for slotID = 1, slots do
                local ok, info = pcall(container.GetContainerItemInfo, bagID, slotID)
                if ok and type(info) == "table" and type(info.itemID) == "number" then
                    local count = type(info.stackCount) == "number" and info.stackCount or 1
                    totals[info.itemID] = (totals[info.itemID] or 0) + count
                end
            end
        end
    end
    return totals
end

-- The bags changed (or the game has just been entered): compare what they hold now with what they held. now is
-- the game's clock in seconds.
function newItems.update(now)
    local totals = carriedTotals()
    if totals == nil then
        return
    end
    if baseline == nil or now < graceUntil then
        baseline = totals
        return
    end
    for itemID, count in pairs(totals) do
        if count > (baseline[itemID] or 0) then
            arrived[itemID] = true
        end
    end
    -- An item that is gone is gone: when it comes back (bought back, looted again) that is a new arrival.
    for itemID in pairs(baseline) do
        if totals[itemID] == nil then
            arrived[itemID] = nil
        end
    end
    baseline = totals
end

local function clock()
    local now = rawget(_G, "GetTime")
    return now ~= nil and now() or 0
end

-- Forgets everything: what was flagged, what arrived and what the bags held.
function newItems.restart()
    seen = {}
    arrived = {}
    baseline = nil
    graceUntil = 0
    looked = false
end

-- The game's events for the bags (see watch): a login or a reload starts over, a loading screen only waits.
function newItems.onEvent(event, isInitialLogin, isReloadingUi)
    if event == "PLAYER_ENTERING_WORLD" then
        if isInitialLogin or isReloadingUi then
            newItems.restart()
            graceUntil = clock() + LOGIN_GRACE
        else
            graceUntil = clock() + ZONE_GRACE
        end
    elseif event ~= "BAG_UPDATE_DELAYED" then
        return
    end
    pcall(newItems.update, clock())
end

-- Starts listening to the game. Once; a client without frames (the tests) has nothing to listen with.
function newItems.watch()
    if newItems.frame ~= nil or rawget(_G, "CreateFrame") == nil then
        return false
    end
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:SetScript("OnEvent", function(_, event, ...)
        newItems.onEvent(event, ...)
    end)
    newItems.frame = frame
    return true
end

-- The items that arrived and are still waiting to be looked at, as item IDs in a stable order.
function newItems.arrivedIDs()
    local ids = {}
    for itemID in pairs(arrived) do
        tinsert(ids, itemID)
    end
    table.sort(ids)
    return ids
end

-- The bags closed: what was new has been looked at, if the list was drawn since. A list that was never drawn
-- keeps its arrivals: the bags are closed all the time while a quest reward waits.
function newItems.reset()
    if next(seen) ~= nil then
        seen = {}
    end
    if looked then
        looked = false
        arrived = {}
    end
end

-- A list of the bags' Item Lists stop (bagLists.lua), open when the bags open.
local L = WowVision:getLocale()
WowVision.bagLists.register({
    key = "new",
    label = L["New Items"],
    order = 10,
    expanded = true,
    select = newItems.list,
    reset = newItems.reset,
})

-- Listens to the game from the moment this file loads (the tests have no frames: nothing to listen with).
newItems.watch()
