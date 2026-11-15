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
-- one held as a secure click of the slot's own item button (bags open as the fight began only), Space reads the
-- slot's tooltip.

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

-- The item buttons the open bags show now: the frames' Items (WoW: Forever, retail), else the named slots of the
-- classic frames (ContainerFrame<n>Item<i>).
local function shownItemButtons()
    local buttons = {}
    local function add(button)
        if button ~= nil and button:IsShown() then
            tinsert(buttons, button)
        end
    end
    if ContainerFrameUtil_EnumerateContainerFrames ~= nil then
        for _, frame in ContainerFrameUtil_EnumerateContainerFrames() do
            if frame ~= nil and frame:IsShown() then
                for _, button in ipairs(frame.Items or {}) do
                    add(button)
                end
            end
        end
        return buttons
    end
    for i = 1, NUM_CONTAINER_FRAMES or 13 do
        local frame = _G["ContainerFrame" .. i]
        if frame ~= nil and frame:IsShown() then
            for slot = 1, frame.size or 0 do
                add(_G[frame:GetName() .. "Item" .. slot])
            end
        end
    end
    return buttons
end

-- Entry index -> the item button the open bags show for that slot now.
local function slotButtons()
    local targets = {}
    local byLocation = {}
    for _, button in ipairs(shownItemButtons()) do
        local bag, slot = module.slotLocation(button)
        byLocation[bag .. ":" .. slot] = button
    end
    for i, entry in ipairs(slots) do
        targets[i] = byLocation[entry.bag .. ":" .. entry.slot]
    end
    return targets
end

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
        -- Both clicks are the secure side's while it walks the list (Enter a secure click of the slot's own button,
        -- Backspace the item action); reached here (back by Ctrl-Tab) they say they cannot.
        bindings = {
            { binding = "leftClick", type = "Click" },
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
    -- Enter in a fight: a secure click of the slot's own item button (picking up and placing are the button's click
    -- in the game's code; addon code calling the pickup is refused in combat on WoW: Forever). The bags lay their
    -- buttons out as they open, so the buttons are known only for bags open as the fight began.
    clickTargets = function()
        return slotButtons()
    end,
    onMirror = function(index, why)
        if why == "leftClick" then
            -- reached only where no secure click was armed
            WowVision:notify(L["To move items in a fight, open the bags before it"])
            return
        end
        if why == "tooltip" then
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
-- Measuring (log only, nothing changes): does every opening of the bags give each slot the same item button? If it
-- does, a pick button armed out of combat stays right for bags opened in the fight, and Enter could pick up there
-- too. Logged on every opening, in and out of combat, against the opening before.
local lastLayout = nil
local wasOpen = false
local nextLook = 0

local function measureLayout()
    local layout = slotButtons()
    local shown, changed, compared = 0, 0, 0
    for i in ipairs(slots) do
        local button = layout[i]
        if button ~= nil then
            shown = shown + 1
            if lastLayout ~= nil and lastLayout[i] ~= nil then
                compared = compared + 1
                if lastLayout[i] ~= button then
                    changed = changed + 1
                end
            end
        end
    end
    local when = InCombatLockdown() and "in combat" or "out of combat"
    if lastLayout == nil then
        WowVision.graph.combatKeys.log("bags layout " .. when .. ": " .. shown .. " slots shown, first opening")
    else
        WowVision.graph.combatKeys.log(
            "bags layout "
                .. when
                .. ": "
                .. shown
                .. " slots shown, "
                .. changed
                .. " of "
                .. compared
                .. " got another button than at the last opening"
        )
    end
    if shown > 0 then
        lastLayout = layout
    end
end

local layoutWatch = CreateFrame("Frame")
layoutWatch:SetScript("OnUpdate", function()
    local now = GetTime()
    if now < nextLook then
        return
    end
    nextLook = now + 0.25
    local open = #shownItemButtons() > 0
    if open and not wasOpen then
        -- the frames lay their buttons out as they show; read them a moment later
        C_Timer.After(0.3, measureLayout)
    end
    wasOpen = open
end)

local events = CreateFrame("Frame")
events:RegisterEvent("BAG_CONTAINER_UPDATE")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
    WowVision.graph.combatKeys.stageMirrors()
end)
