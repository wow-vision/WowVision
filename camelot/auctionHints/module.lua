-- Auction hints: which items of the bags are worth more at the auction house than to a vendor, with the prices of the
-- third-party addon Life on Azeroth Market. Optional (OptionalDeps in WowVision_Camelot.toc): without its data this
-- file stops here and no module is made. Two places in the bags, both off until the player turns Show Auction Hints on:
--   * a last stop, For Sale at the Auction House: a summary, then one line per item with the prices and the gain, each
--     line the bag slot of the item's first stack (the same clicks and context menu);
--   * a category of the Item Lists, For Sale to a Merchant: what a vendor buys and the stop leaves alone (the same
--     rules, so an item is never in both); a favorite is never offered there.
local loaded = WowVision.loadedAddons
if
    loaded == nil
    or not (
        loaded["LifeOnAzeroth_Data"]
        or loaded["lifeonazeroth_data"]
        or loaded["LifeOnAzeroth_Market"]
        or loaded["lifeonazeroth_market"]
    )
then
    return
end

local hints = WowVision.auctionHints

local module = WowVision.base.windows:createModule("auctionHints")
local L = module.L
module:setLabel(L["Auction Hints"])
local settings = module:hasSettings()
-- Off: it adds a stop to the bags.
settings:add({ type = "Bool", key = "show", label = L["Show Auction Hints"], default = false })
settings:add({ type = "Bool", key = "countCut", label = L["Count the Auction House Cut"], default = true })

-- The game ----------------------------------------------------------------------

local game = hints.game

local function usable(value)
    return value ~= nil and not WowVision.secrets.isSecret(value)
end

function game.countCut()
    return module.settings.countCut ~= false
end

-- Each distinct error once: the bags redraw often.
local reported = {}
function game.report(err)
    err = tostring(err)
    if not reported[err] then
        reported[err] = true
        geterrorhandler()(err)
    end
end

function game.market()
    return type(LOA_DATA) == "table" and LOA_DATA or nil
end

function game.marketSettings()
    return type(LifeOnAzeroth_MarketDB) == "table" and LifeOnAzeroth_MarketDB or nil
end

function game.realmName()
    return GetRealmName()
end

function game.faction()
    return (UnitFactionGroup("player"))
end

function game.time()
    return time()
end

function game.dateParts(moment)
    return date("*t", moment)
end

function game.inCombat()
    return InCombatLockdown()
end

-- The carried bags: the backpack, the bags and the reagent bag.
function game.carried()
    local carried = {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        carried[bag] = true
    end
    return carried
end

-- The item buttons of the shown bag frames, without the slots an account without an authenticator cannot use.
function game.bagButtons()
    local buttons = {}
    if ContainerFrameUtil_EnumerateContainerFrames == nil then
        return buttons
    end
    for _, frame in ContainerFrameUtil_EnumerateContainerFrames() do
        if frame ~= nil and frame:IsShown() then
            for _, itemButton in ipairs(frame.Items or {}) do
                if itemButton:IsShown() and not (itemButton.IsExtended ~= nil and itemButton:IsExtended()) then
                    tinsert(buttons, itemButton)
                end
            end
        end
    end
    return buttons
end

function game.numSlots(bag)
    return C_Container.GetContainerNumSlots(bag) or 0
end

-- nil for an empty slot, { unreadable = true } when the game hides what it holds, else { itemID, link, count, bound,
-- hasNoValue }; bound as the game gives it, anything but false counts as bound.
function game.slotInfo(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info == nil then
        return nil
    end
    local itemID, count, bound = info.itemID, info.stackCount, info.isBound
    if not usable(itemID) or not usable(count) or WowVision.secrets.isSecret(bound) or not usable(info.hyperlink) then
        return { unreadable = true }
    end
    return { itemID = itemID, link = info.hyperlink, count = count, bound = bound, hasNoValue = info.hasNoValue == true }
end

-- A second opinion on a bound item, through the slot's item location; nil when the game cannot say.
function game.locationBound(bag, slot)
    if ItemLocation == nil or C_Item == nil or C_Item.IsBound == nil then
        return nil
    end
    local ok, bound = pcall(function()
        return C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(bag, slot))
    end)
    if ok and usable(bound) then
        return bound == true
    end
    return nil
end

-- { name, quality, sellPrice, bindType } of an item, nil while the game has not loaded it.
function game.itemInfo(linkOrID)
    local get = (C_Item ~= nil and C_Item.GetItemInfo) or GetItemInfo
    local ok, name, _, quality, _, _, _, _, _, _, _, sellPrice, _, _, bindType = pcall(get, linkOrID)
    if not ok or not usable(name) then
        return nil
    end
    return {
        name = name,
        quality = usable(quality) and quality or nil,
        sellPrice = usable(sellPrice) and sellPrice or nil,
        bindType = usable(bindType) and bindType or nil,
    }
end

function game.accountBoundUntilEquip(itemID)
    if C_Item == nil or C_Item.IsItemBindToAccountUntilEquip == nil then
        return nil
    end
    local ok, bound = pcall(C_Item.IsItemBindToAccountUntilEquip, itemID)
    if ok and usable(bound) then
        return bound == true
    end
    return nil
end

function game.durability(bag, slot)
    if C_Container.GetContainerItemDurability == nil then
        return nil, nil
    end
    local ok, current, maximum = pcall(C_Container.GetContainerItemDurability, bag, slot)
    if ok and usable(current) and usable(maximum) then
        return current, maximum
    end
    return nil, nil
end

function game.coinText(copper)
    return C_CurrencyInfo.GetCoinText(math.floor(copper + 0.5))
end

function game.itemName(name, quality)
    if WowVision.items ~= nil and WowVision.items.formatName ~= nil then
        return WowVision.items.formatName(name, quality)
    end
    return name
end

function game.isFavorite(link)
    local favorites = WowVision.base.windows.favorites
    return favorites ~= nil and favorites:keeps(link) == true
end

-- The bags ----------------------------------------------------------------------

local function shown()
    return module:getEnabled() and module.settings.show == true and not game.inCombat()
end

-- The positions of the slots of the carried bags among these buttons.
local function positionsOf(buttons)
    local containers = WowVision.base.windows.containers
    local carried = game.carried()
    local positions = {}
    for _, itemButton in ipairs(buttons) do
        local bag, slot = containers.slotLocation(itemButton)
        if carried[bag] then
            tinsert(positions, { bag = bag, slot = slot, button = itemButton })
        end
    end
    return positions
end

-- A line of the stop: the bag slot of its first stack, read with a sentence of its own. While the stacks still hold
-- what they held, that sentence; once the bags changed under it (the screen is redrawn soon after), the bags' own label.
local function lineNode(line)
    local containers = WowVision.base.windows.containers
    local button = line.button
    local text = hints.lineText(line)
    local function label()
        for _, pile in ipairs(line.piles) do
            local info = game.slotInfo(pile.bag, pile.slot)
            if info == nil or info.itemID ~= line.itemID or info.count ~= pile.count then
                return containers.getBagItemLabel(button)
            end
        end
        return text
    end
    return containers.itemSlotNode(button, label, containers.itemClickLabels(button), containers.slotIsEmpty(button))
end

-- The last stop of the bags window.
function module.renderStop(builder)
    if not shown() then
        return
    end
    local positions = positionsOf(game.bagButtons())
    if #positions == 0 then
        return
    end
    local nodes = WowVision.graph.nodes
    local ControlId = WowVision.graph.ControlId
    local result = hints.compute(positions)
    builder:beginStop("auctionHints")
    builder:addItem(
        ControlId.structural("auctionHints:summary"),
        nodes.text({ label = hints.summaryText(result, game.time()), live = false })
    )
    if #result.auction > 0 then
        builder:pushContext("auctionHints:list", L["For Sale at the Auction House"])
        for _, line in ipairs(result.auction) do
            -- by item, so the focus stays on the line when its first stack changes
            builder:addItem(ControlId.structural("auctionHints:item:" .. line.itemID), lineNode(line))
        end
        builder:popContext()
    end
end

-- The merchant category: for each item a vendor buys and the stop leaves alone, its first stack; no favorites.
function module.merchantSlots(buttons)
    if not shown() then
        return {}
    end
    local positions = {}
    for _, position in ipairs(positionsOf(buttons)) do
        local info = game.slotInfo(position.bag, position.slot)
        if not (info ~= nil and info.link ~= nil and game.isFavorite(info.link)) then
            tinsert(positions, position)
        end
    end
    local selected = {}
    for _, line in ipairs(hints.compute(positions).merchant) do
        tinsert(selected, line.button)
    end
    return selected
end

WowVision.bagLists.register({
    key = "merchant",
    label = L["For Sale to a Merchant"],
    order = 40,
    select = module.merchantSlots,
})

WowVision.bagLists.registerStop({ key = "auctionHints", order = 10, render = module.renderStop })

-- The command -------------------------------------------------------------------

-- Every slot of the carried bags, read from the game: the command needs no open bag.
local function allPositions()
    local positions = {}
    local bags = {}
    for bag in pairs(game.carried()) do
        tinsert(bags, bag)
    end
    table.sort(bags)
    for _, bag in ipairs(bags) do
        for slot = 1, game.numSlots(bag) do
            tinsert(positions, { bag = bag, slot = slot })
        end
    end
    return positions
end

function module:sayStatus()
    if game.inCombat() then
        WowVision:speak(L["The list is not available during combat."])
        return
    end
    WowVision:speak(hints.statusText(hints.compute(allPositions()), game.time()))
end

module:registerCommand({
    name = "sell",
    description = L["Say what in your bags is worth selling at the auction house."],
    func = function()
        module:sayStatus()
    end,
})
