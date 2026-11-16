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
-- The game's own open-bags keys open it in a fight (Open All Bags, Toggle Backpack): secure clicks of the game's own
-- bag buttons open every bag as the player's clicks do, so nothing of the game's bag frames is written by addon code.
-- Enter picks the item up or places the one held as a secure click of the slot's own item button (where the buttons
-- are known: bags open as the fight began, or a layout trusted out of combat), Space reads the slot's tooltip.

-- The slots as staged for the fight: { bag, slot } in list order.
local slots = {}

local function slotId(bag, slot)
    return ControlId.structural("combatSlot:" .. bag .. ":" .. slot)
end

local function readSlots()
    local list = {}
    for _, bag in ipairs(module.heldBagIds()) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            tinsert(list, { bag = bag, slot = slot })
        end
    end
    return list
end

-- Whether the bags lay their buttons out the same on every opening. Right after the interface loads they do not:
-- the second opening hands every slot another button (the window's button pool, ContainerFrame.lua UpdateItemSlots),
-- and from then on each opening gives the same (measured on WoW: Forever, 2026-11-15). So the layout is trusted once
-- an opening kept it, until the bags change.
local layoutTrusted = false

-- Entry index -> the item button the open bags show for that slot now.
local function slotButtons()
    local targets = {}
    local byLocation = {}
    for _, button in ipairs(module.shownItemButtons()) do
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

-- The window opens a moment after the secure click; the focus lands once its screen is there. One landing waits at a
-- time and the latest wins (keys pressed while it waits): it lands where the secure side is, read afresh when the
-- window was opened meanwhile.
local LAND_TRIES = 20
local LAND_STEP = 0.05
local waiting = nil

local function landNow(index, why)
    local entry = slots[index]
    local instance = bagsInstance()
    if entry == nil or instance == nil or instance.stack == nil then
        return false
    end
    WowVision.graphHost:landMirror(instance.stack, slotId(entry.bag, entry.slot), why)
    return true
end

local function retryLanding()
    if waiting == nil then
        return
    end
    if landNow(waiting.index, waiting.why) then
        waiting = nil
        return
    end
    waiting.tries = waiting.tries + 1
    if waiting.tries >= LAND_TRIES then
        waiting = nil
        WowVision.graph.combatKeys.log("bags window did not open")
        return
    end
    C_Timer.After(LAND_STEP, retryLanding)
end

local function land(index, why)
    if waiting ~= nil then
        -- a newer position while the window opens: the opening still reads it afresh
        waiting.index = index
        if waiting.why ~= "open" then
            waiting.why = why
        end
        return
    end
    if landNow(index, why) then
        return
    end
    waiting = { index = index, why = why, tries = 0 }
    C_Timer.After(LAND_STEP, retryLanding)
end

WowVision.graph.combatKeys.registerMirror({
    key = "bags",
    commands = { "OPENALLBAGS", "TOGGLEBACKPACK" },
    openers = function()
        return module.bagOpenButtons()
    end,
    trusted = function()
        return layoutTrusted
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
    -- B stays the game's in a fight while WowVision does not read the bags (the module off, Sku loaded)
    available = function()
        local window = WowVision.UIHost.windowManager:getWindow("bags")
        return window ~= nil and window:canOpen() and module:getEnabled()
    end,
    isOpen = function()
        return bagsInstance() ~= nil
    end,
    stack = function()
        local open = bagsInstance()
        return open ~= nil and open.stack or nil
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
    contextLabels = function(index)
        local entry = slots[index]
        local labels = entry ~= nil and module.slotClickLabels(function()
            return entry.bag, entry.slot
        end) or {}
        local function label(which, clickName)
            local ok, effect = pcall(labels[which] or function() end)
            return ok and effect ~= nil and (effect .. ", " .. clickName) or clickName
        end
        return { left = label("left", L["Left Click"]), right = label("right", L["Right Click"]) }
    end,
    onMirror = function(index, why)
        if why == "leftClick" then
            -- reached only where no secure click was armed
            WowVision:notify(L["To pick up items in a fight, open your bags once more out of combat"])
            return
        end
        if why == "tooltip" then
            WowVision.graphHost:combatKey(why)
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
    if lastLayout ~= nil and compared > 0 then
        layoutTrusted = changed == 0
    end
    -- The safety net: Enter in this fight clicks the buttons armed before it. Opened here, the layout may differ.
    if InCombatLockdown() then
        local wrong = 0
        for i in ipairs(slots) do
            local armed = WowVision.graph.combatKeys.pickTarget("bags", i)
            if layout[i] ~= nil and armed ~= nil and armed ~= layout[i] then
                wrong = wrong + 1
            end
        end
        if wrong > 0 then
            WowVision.graph.combatKeys.log("bags layout differs from the armed buttons in " .. wrong .. " slots")
            WowVision:notify(L["Bag layout changed, Enter may pick up the wrong item"])
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
    -- nothing to measure for while Menus in Combat is off
    if not WowVision.graph.combatKeys.enabled() then
        wasOpen = false
        return
    end
    local open = #module.shownItemButtons() > 0
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
    -- a bag of another size lays out anew
    layoutTrusted = false
    lastLayout = nil
    WowVision.graph.combatKeys.stageMirrors()
end)
