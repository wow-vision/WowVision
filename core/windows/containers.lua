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
function module.itemSlotNode(itemButton, label, clickLabels)
    local vtable = nodes.proxyButton({ target = itemButton, label = label, clickLabels = clickLabels })
    if vtable == nil then
        return nil
    end
    vtable.announcements[1].live = "focus"
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            WowVision.cursor = WowVision.cursor or {}
            WowVision.cursor.pickupIsActionBar = false
            local script = itemButton:GetScript("OnDragStart")
            if script ~= nil then
                script(itemButton)
            end
        end,
    })
    return vtable
end

local function shown(frame)
    return frame ~= nil and frame:IsShown()
end

-- What clicking an item slot does right now. The game decides a right click
-- by which window is open (the same order its own click handler and
-- UseContainerItem follow), so the label does too. nil means "nothing worth
-- naming" and leaves the bare click name.
function module.itemClickLabels(itemButton)
    local function slotInfo()
        local bagID = itemButton.GetBagID ~= nil and itemButton:GetBagID() or itemButton:GetParent():GetID()
        local slotID = itemButton:GetID()
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
            if bagID == BANK_CONTAINER or bagID > NUM_BAG_SLOTS then
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

-- Emit a bag's item slots in the configured shape. Grid rows share the
-- "grid" row key, so up and down follow POSITION in the row rather than
-- the screen column: the combined bag fills from the bottom-right and a
-- short top row would otherwise strand its cells. Returns the row count.
function module.renderSlots(builder, buttons)
    local rows = module.visualRows(buttons)
    local grid = module.settings.shape == "grid"
    for _, row in ipairs(rows) do
        if grid then
            builder:startRow("grid")
        end
        for _, itemButton in ipairs(row) do
            builder:addItem(
                ControlId.forObject(itemButton),
                module.itemSlotNode(itemButton, function()
                    return module.getBagItemLabel(itemButton)
                end, module.itemClickLabels(itemButton))
            )
        end
        if grid then
            builder:endRow()
        end
    end
    return #rows
end

local function render(builder, screen)
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
