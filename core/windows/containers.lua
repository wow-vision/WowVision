local module = WowVision.base.windows:createModule("containers")
local L = module.L
module:setLabel(L["Containers"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Base class for all container types
local Container = WowVision.Class("Container")
Container:addFields({
    { key = "key", required = true },
    { key = "type", required = true },
})

function Container:initialize(info)
    self:applyFields(info)
end

-- Create component registry for containers
local containers = module:createComponentRegistry({
    key = "containers",
    path = "containers",
    type = "class",
    baseClass = Container,
    classNamePrefix = "Container",
})

function module:createContainerType(typeKey)
    return containers:createType({ key = typeKey })
end

function module:addContainer(info)
    return containers:createComponent(info)
end

-- An item slot node: live label (bag contents change constantly under
-- focus), real clicks for pickup, use, and split, and drag support.
-- clickLabels (optional) name what the clicks do, for the context menu.
-- isEmpty (optional) marks the slot as empty for the double arrow skip.
function module.itemSlotNode(itemButton, label, clickLabels, isEmpty)
    local vtable = nodes.proxyButton({ target = itemButton, label = label, clickLabels = clickLabels })
    if vtable == nil then
        return nil
    end
    vtable.announcements[1].live = "focus"
    vtable.isEmpty = isEmpty
    -- where the slot is, for a fight that begins on it (containersCombat.lua)
    vtable.bagSlot = function()
        return module.slotLocation(itemButton)
    end
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            WowVision.cursor = WowVision.cursor or {}
            WowVision.cursor.pickupIsActionBar = false
            nodes.runDrag(itemButton)
        end,
    })
    return vtable
end

local function shown(frame)
    return frame ~= nil and frame:IsShown()
end

-- Where an item button points: bag id and slot id. Retail bank buttons
-- carry a bank tab (a bag id) and a container slot, retail bag buttons
-- their own bag id (the combined frame mixes bags), classic buttons their
-- parent frame's.
function module.slotLocation(itemButton)
    if itemButton.GetBankTabID ~= nil and itemButton.GetContainerSlotID ~= nil then
        return itemButton:GetBankTabID(), itemButton:GetContainerSlotID()
    end
    if itemButton.GetBagID ~= nil then
        return itemButton:GetBagID(), itemButton:GetID()
    end
    return itemButton:GetParent():GetID(), itemButton:GetID()
end

-- What clicking an item slot does right now. The game decides a right click
-- by which window is open (the same order its own click handler and
-- UseContainerItem follow), so the label does too. nil means "nothing worth
-- naming" and leaves the bare click name.
function module.itemClickLabels(itemButton)
    return module.slotClickLabels(function()
        return module.slotLocation(itemButton)
    end)
end

-- The same by bag and slot: locate() returns them (the bags in combat, containersCombat.lua).
function module.slotClickLabels(locate)
    local function slotInfo()
        local bagID, slotID = locate()
        return bagID, slotID, C_Container.GetContainerItemInfo(bagID, slotID)
    end
    return {
        left = function()
            local _, _, info = slotInfo()
            if CursorHasItem() then
                return L["Place Item"]
            end
            if info == nil then
                return nil
            end
            return L["Pick Up"]
        end,
        right = function()
            local bagID, _, info = slotInfo()
            if info == nil then
                return nil
            end
            if shown(MerchantFrame) then
                if info.hasNoValue then
                    return nil
                end
                return L["Sell"]
            end
            -- Held bags: the backpack, the bag slots and (modern) the reagent
            -- bag; everything above is a bank bag or bank tab.
            local heldBags = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
            if bagID == BANK_CONTAINER or bagID > heldBags then
                return L["Move to Bags"]
            end
            if shown(BankFrame) then
                return L["Move to Bank"]
            end
            if shown(SendMailFrame) then
                return L["Attach to Mail"]
            end
            if shown(TradeFrame) then
                return L["Add to Trade"]
            end
            if shown(AuctionHouseFrame) then
                return L["Put up for Auction"]
            end
            if info.hasLoot then
                return L["Open"]
            end
            local link = info.hyperlink
            local isEquippable = C_Item ~= nil and C_Item.IsEquippableItem or IsEquippableItem
            if link ~= nil and isEquippable ~= nil and isEquippable(link) then
                return L["Equip"]
            end
            if info.isReadable then
                return L["Read"]
            end
            local getItemSpell = C_Item ~= nil and C_Item.GetItemSpell or GetItemSpell
            if link ~= nil and getItemSpell ~= nil and getItemSpell(link) ~= nil then
                return L["Use"]
            end
            return nil
        end,
    }
end

-- An item slot holding nothing: the same read its label makes.
function module.slotIsEmpty(itemButton)
    return function()
        local bagID, slotID = module.slotLocation(itemButton)
        return C_Container.GetContainerItemInfo(bagID, slotID) == nil
    end
end

-- Bag shape: item slots read as the grid the frame draws (rows, with
-- up/down moving between them) or as one flat list per bag.
local settings = module:hasSettings()
settings:add({
    type = "Choice",
    key = "shape",
    label = L["Bag Shape"],
    default = "list",
    choices = {
        { label = L["Grid"], value = "grid" },
        { label = L["List"], value = "list" },
    },
})

-- Shown item buttons in visual order: rows top to bottom by screen
-- position, left to right within a row. Buttons the client has not laid
-- out yet trail as one final row in their given order.
function module.visualRows(buttons)
    local placed = {}
    local unplaced = {}
    for _, itemButton in ipairs(buttons) do
        if itemButton:IsShown() then
            if itemButton:GetTop() ~= nil then
                tinsert(placed, itemButton)
            else
                tinsert(unplaced, itemButton)
            end
        end
    end
    table.sort(placed, function(a, b)
        local at, bt = a:GetTop(), b:GetTop()
        if math.abs(at - bt) > 1 then
            return at > bt
        end
        return a:GetLeft() < b:GetLeft()
    end)
    local rows = {}
    local current = nil
    local currentTop = nil
    for _, itemButton in ipairs(placed) do
        local top = itemButton:GetTop()
        if current == nil or math.abs(top - currentTop) > 1 then
            current = {}
            currentTop = top
            tinsert(rows, current)
        end
        tinsert(current, itemButton)
    end
    if #unplaced > 0 then
        tinsert(rows, unplaced)
    end
    return rows
end

-- One item slot of a bag or the bank: the label (with "[Favorite]" and "[Junk]"
-- ahead of it when the player marked its item, see favorites.lua and junk.lua),
-- the clicks, and the Select Favorite and Select Junk keys and menu entries.
-- The bags' Item Lists stop (retail/containers/Bags.lua) lists slots again and
-- builds them with this too, so they read the same wherever they are.
--
-- A slot is built again on every rebuild of the window (every frame), so what
-- does not change is made once per item button and kept: where the button
-- points and how its label reads. Item buttons are the game's own frames and
-- stay for the session.
local slotParts = {}

local function partsOf(itemButton)
    local parts = slotParts[itemButton]
    if parts == nil then
        local function locate()
            return module.slotLocation(itemButton)
        end
        parts = {
            locate = locate,
            label = function()
                local windows = WowVision.base.windows
                local label = windows.junk:tagLabel(module.getBagItemLabel(itemButton), locate())
                return windows.favorites:tagLabel(label, locate())
            end,
        }
        slotParts[itemButton] = parts
    end
    return parts
end

local function slotNode(itemButton)
    local parts = partsOf(itemButton)
    local windows = WowVision.base.windows
    local node = module.itemSlotNode(
        itemButton,
        parts.label,
        module.itemClickLabels(itemButton),
        module.slotIsEmpty(itemButton)
    )
    node = windows.favorites:decorateSlot(node, parts.locate, itemButton)
    return windows.junk:decorateSlot(node, parts.locate, itemButton)
end
module.slotNode = slotNode

-- The text in the game's bag search box. The bag and bank boxes hold the
-- same text (the game copies one into the others as it is typed), and the
-- game clears it when the last of them hides.
function module.searchText()
    local box = BagItemSearchBox
    if box == nil or box.GetText == nil then
        return ""
    end
    return box:GetText() or ""
end

-- With a search typed, only the slots that hold a matching item, in the
-- order given. The game dims the others and leaves them where they are;
-- read out, that is a bag full of "Filtered" to step through, so they are
-- left out, and the empty slots with them. Returns the slots to read and
-- whether a search is on.
function module.searchMatches(buttons)
    if module.searchText() == "" then
        return buttons, false
    end
    local matches = {}
    for _, itemButton in ipairs(buttons) do
        if itemButton:IsShown() then
            local info = C_Container.GetContainerItemInfo(module.slotLocation(itemButton))
            if info ~= nil and not info.isFiltered then
                tinsert(matches, itemButton)
            end
        end
    end
    return matches, true
end

-- Emit a bag's item slots in the configured shape. Grid rows share the
-- "grid" row key, so up and down follow POSITION in the row rather than
-- the screen column: the combined bag fills from the bottom-right and a
-- short top row would otherwise strand its cells. The list reads the slots
-- in SLOT order (the order the buttons are given in: slot 1 first), the way
-- older addons do; screen order would start at the top-left cell, which is
-- the LAST slot, and read the bag backwards. Returns the visual row count.
-- While a bag search is typed, only the matching items are emitted, as a
-- list in slot order whatever the shape (what is left of a grid has holes);
-- a bag without a match says No results.
function module.renderSlots(builder, buttons)
    local all = buttons
    local searching
    buttons, searching = module.searchMatches(buttons)
    if searching and #buttons == 0 then
        local first = all[1]
        if first ~= nil then
            local bagID, slotID = module.slotLocation(first)
            builder:addItem(
                ControlId.structural("noMatch:" .. tostring(bagID) .. ":" .. tostring(slotID)),
                nodes.text({ label = L["No results"] })
            )
            return 1
        end
        return 0
    end
    local rows = module.visualRows(buttons)
    local grid = module.settings.shape == "grid" and not searching
    if not grid then
        for _, itemButton in ipairs(buttons) do
            if itemButton:IsShown() then
                builder:addItem(ControlId.forObject(itemButton), slotNode(itemButton))
            end
        end
        return #rows
    end
    for _, row in ipairs(rows) do
        builder:startRow("grid")
        for _, itemButton in ipairs(row) do
            builder:addItem(ControlId.forObject(itemButton), slotNode(itemButton))
        end
        builder:endRow()
    end
    return #rows
end

local function render(builder, screen)
    -- in combat the list the secure side walks (containersCombat.lua)
    if InCombatLockdown() and module.renderCombat ~= nil and module.renderCombat(builder) then
        return
    end
    builder:pushContext("bags", L["Bags"])
    containers:forEachComponent(function(container)
        if container.renderGraph ~= nil and (container.isOpen == nil or container:isOpen()) then
            local ok, err = pcall(container.renderGraph, container, builder)
            if not ok then
                geterrorhandler()(err)
            end
        end
    end)
    builder:popContext()
end

module:registerWindow({
    type = "CustomWindow",
    name = "bags",
    isOpen = function(self)
        for _, container in ipairs(containers:getComponents()) do
            if container.isOpen and container:isOpen() then
                return true
            end
        end
        return false
    end,
    conflictingAddons = { "Sku" },
    -- Background: bags auto-open alongside merchants, mailboxes, and the
    -- bank; the interaction window keeps focus and ctrl-tab reaches the bags.
    graphScreen = { render = render, background = true },
})
