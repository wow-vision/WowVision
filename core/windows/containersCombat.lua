local module = WowVision.base.windows.containers
local L = module.L

local graph = WowVision.graph
local ControlId = graph.ControlId

-- The bags in combat (graph/combatKeys.lua, a mirrored list). Out of combat Backspace on a slot is a secure click of
-- its item button; in combat no secure click can be pointed at another button, so the secure side walks this list
-- itself and uses the focused slot with the game's own item action ("bag slot", the action the right click runs).
--
-- The list is by bag and slot, never by button: every held bag (open or not; the game's buttons are pooled and laid
-- out only for open bags), slot 1 first, one tab stop per bag, empty slots kept. A fight cannot change a bag's size,
-- so every position stays the same entry for the whole fight. In combat the bags window shows this list whatever the
-- shape setting; out of combat it is the window as ever.
--
-- The game's own open-bags keys open it in a fight (Open All Bags, Toggle Backpack): a secure click of the backpack
-- button opens the visible bags as a click by the player does (on WoW: Forever the combined bags, on the other clients
-- the backpack), so nothing of the game's bag frames is written by addon code. Enter picks the item up or places the
-- one held (the game's pickup call, not protected), Space reads the slot's tooltip.

-- Every held bag: backpack, bags, reagent bag where the client has one, keyring.
local function heldBags()
    local ids = {}
    for id = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        tinsert(ids, id)
    end
    local keyring = KEYRING_CONTAINER or (Enum ~= nil and Enum.BagIndex ~= nil and Enum.BagIndex.Keyring) or nil
    if keyring ~= nil then
        tinsert(ids, keyring)
    end
    return ids
end

-- The slots as staged for the fight: { bag, slot } in list order.
local slots = {}

local function slotId(bag, slot)
    return ControlId.structural("combatSlot:" .. bag .. ":" .. slot)
end

local function readSlots()
    local list = {}
    for _, bag in ipairs(heldBags()) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            tinsert(list, { bag = bag, slot = slot })
        end
    end
    return list
end

local pickup = C_Container.PickupContainerItem or PickupContainerItem

local function slotNode(bag, slot)
    return {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return module.slotLabel(bag, slot)
                end,
                kind = graph.kinds.label,
                live = "focus",
            },
        },
        tooltip = {
            type = "Game",
            mode = "immediate",
            populate = function(tooltip)
                tooltip:SetBagItem(bag, slot)
            end,
        },
        bindings = {
            {
                binding = "leftClick",
                type = "Function",
                func = function()
                    pickup(bag, slot)
                end,
            },
            -- Used by the secure side while it walks the list; reached here (back by Ctrl-Tab) it says it cannot.
            { binding = "rightClick", type = "Click" },
        },
        bagSlot = function()
            return bag, slot
        end,
    }
end

-- The bags window's render in combat: the staged list, one stop per bag.
function module.renderCombat(builder)
    builder:pushContext("bags", L["Bags"])
    local current = nil
    for _, entry in ipairs(slots) do
        if entry.bag ~= current then
            if current ~= nil then
                builder:popContext()
            end
            current = entry.bag
            builder:beginStop("combatBag:" .. entry.bag)
            builder:pushContext("combatBag:" .. entry.bag, C_Container.GetBagName(entry.bag) or KEYRING or "")
        end
        builder:addItem(slotId(entry.bag, entry.slot), slotNode(entry.bag, entry.slot))
    end
    if current ~= nil then
        builder:popContext()
    end
    builder:popContext()
    return #slots > 0
end

local function bagsInstance()
    local window = WowVision.UIHost.windowManager:getWindow("bags")
    return window ~= nil and window:getOpenInstance() or nil
end

-- The window opens a moment after the secure click; the focus lands once its screen is there.
local LAND_TRIES = 20
local LAND_STEP = 0.05

local function land(index, why, tries)
    local entry = slots[index]
    if entry == nil then
        return
    end
    local instance = bagsInstance()
    if instance == nil or instance.stack == nil then
        if (tries or 0) < LAND_TRIES then
            C_Timer.After(LAND_STEP, function()
                land(index, why, (tries or 0) + 1)
            end)
        else
            WowVision.graph.combatKeys.log("bags window did not open")
        end
        return
    end
    WowVision.graphHost:landMirror(instance.stack, slotId(entry.bag, entry.slot), why)
end

WowVision.graph.combatKeys.registerMirror({
    key = "bags",
    commands = { "OPENALLBAGS", "TOGGLEBACKPACK" },
    opener = function()
        return MainMenuBarBackpackButton
    end,
    entries = function()
        slots = readSlots()
        local list = {}
        for i, entry in ipairs(slots) do
            -- the keyring and other negative ids are no "bag slot" the item action reads
            list[i] = { value = entry.bag >= 0 and (entry.bag .. " " .. entry.slot) or "", group = entry.bag }
        end
        return list
    end,
    isOpen = function()
        return bagsInstance() ~= nil
    end,
    focusedIndex = function()
        local instance = bagsInstance()
        local host = WowVision.graphHost
        if instance == nil or host:focusedStack() ~= instance.stack then
            return nil
        end
        local node = host:focusedScreen().keyGraph:currentNode()
        if node == nil then
            return nil
        end
        if node.vtable.bagSlot == nil then
            return nil
        end
        local bag, slot = node.vtable.bagSlot()
        for i, entry in ipairs(slots) do
            if entry.bag == bag and entry.slot == slot then
                return i
            end
        end
        return nil
    end,
    onMirror = function(index, why)
        if why == "leftClick" or why == "tooltip" then
            WowVision.graphHost:combatKey(why)
            return
        end
        if why == "contextMenu" then
            -- its own menu would be walked by the host while the secure side walks the bags
            WowVision:notify(L["Not available in combat"])
            return
        end
        land(index, why)
    end,
    onClose = function()
        if CloseAllBags ~= nil then
            CloseAllBags()
        end
    end,
})

-- A bag swapped or bought changes the list: staged again out of combat.
local events = CreateFrame("Frame")
events:RegisterEvent("BAG_CONTAINER_UPDATE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
    WowVision.graph.combatKeys.stageMirrors()
end)
