local windows = WowVision.base.windows
local L = windows.L

local graph = WowVision.graph
local ControlId = graph.ControlId

-- The equipment in combat (graph/combatKeys.lua, a mirrored list), on the game's own Character Info key. The game
-- refuses addon code that shows its character panel in combat (CheckProtectedFunctionsAllowed in
-- UIParentPanelManager.lua), so in a fight that key opens this WowVision list of the equipment slots instead, in the
-- order the character windows read them (tbc/character/PaperDoll.lua, camelot/character.lua).
--
-- Backspace uses the slot's item with the game's item action ("<slot>", UseInventoryItem: an on-use trinket). Enter is
-- a secure click of the slot's own button (CharacterHeadSlot and the others: fixed frames of the game that always
-- stand for the same slot): it picks the item up, or puts on the one held, as the game allows in combat (weapons).
-- Space reads the tooltip. The list closes when the fight ends; out of combat the key opens the character panel.

local SLOT_BUTTONS = {
    "CharacterHeadSlot",
    "CharacterNeckSlot",
    "CharacterShoulderSlot",
    "CharacterBackSlot",
    "CharacterChestSlot",
    "CharacterShirtSlot",
    "CharacterTabardSlot",
    "CharacterWristSlot",
    "CharacterHandsSlot",
    "CharacterWaistSlot",
    "CharacterLegsSlot",
    "CharacterFeetSlot",
    "CharacterFinger0Slot",
    "CharacterFinger1Slot",
    "CharacterTrinket0Slot",
    "CharacterTrinket1Slot",
    "CharacterMainHandSlot",
    "CharacterSecondaryHandSlot",
    "CharacterRangedSlot",
    "CharacterAmmoSlot",
}

-- The slots as staged: { button, id, name }.
local slots = {}

local function readSlots()
    local list = {}
    for _, buttonName in ipairs(SLOT_BUTTONS) do
        local button = _G[buttonName]
        if button ~= nil then
            -- the game's own slot name: CharacterHeadSlot -> HEADSLOT
            local global = buttonName:gsub("^Character", ""):upper()
            tinsert(list, { button = button, id = button:GetID(), name = _G[global] or global })
        end
    end
    return list
end

local function slotLabel(entry)
    local link = GetInventoryItemLink("player", entry.id)
    local item = link ~= nil and (WowVision.items.getLinkLabel(link) or link) or L["Empty"]
    return entry.name .. ", " .. item
end

local function slotId(entry)
    return ControlId.structural("combatEquipment:" .. entry.id)
end

local function render(builder)
    builder:pushContext("combatEquipment", L["Equipment"])
    for _, entry in ipairs(slots) do
        local captured = entry
        builder:addItem(slotId(captured), {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        return slotLabel(captured)
                    end,
                    kind = graph.kinds.label,
                    live = "focus",
                },
            },
            tooltip = {
                type = "Game",
                mode = "immediate",
                populate = function(tooltip)
                    tooltip:SetInventoryItem("player", captured.id)
                end,
            },
            -- the secure side's while it walks the list; reached here (back by Ctrl-Tab) they say they cannot
            bindings = {
                { binding = "leftClick", type = "Click" },
                { binding = "rightClick", type = "Click" },
            },
        })
    end
    builder:popContext()
end

windows:registerWindow({
    type = "ManualWindow",
    name = "combatEquipment",
    graphScreen = { render = render },
})

local function instance()
    local window = WowVision.UIHost.windowManager:getWindow("combatEquipment")
    return window ~= nil and window:getOpenInstance() or nil
end

WowVision.graph.combatKeys.registerMirror({
    key = "equipment",
    commands = { "TOGGLECHARACTER0" },
    -- nothing of the game opens: the list is WowVision's own
    openers = function()
        return {}
    end,
    -- the slot buttons never change: Enter always clicks the right one
    trusted = function()
        return true
    end,
    fixedTargets = true,
    entries = function()
        slots = readSlots()
        local list = {}
        for i, entry in ipairs(slots) do
            -- the ammo slot (0) is no slot the item action uses
            list[i] = { value = entry.id > 0 and tostring(entry.id) or "", group = 1 }
        end
        return list
    end,
    isOpen = function()
        return instance() ~= nil
    end,
    focusedIndex = function()
        return nil
    end,
    clickTargets = function()
        local targets = {}
        for i, entry in ipairs(slots) do
            targets[i] = entry.button
        end
        return targets
    end,
    contextLabels = function(index)
        local entry = slots[index]
        local link = entry ~= nil and GetInventoryItemLink("player", entry.id) or nil
        local left, right = L["Left Click"], L["Right Click"]
        if link ~= nil then
            left = L["Pick Up"] .. ", " .. left
            local getItemSpell = C_Item ~= nil and C_Item.GetItemSpell or GetItemSpell
            if getItemSpell ~= nil and getItemSpell(link) ~= nil then
                right = L["Use"] .. ", " .. right
            end
        end
        return { left = left, right = right }
    end,
    onMirror = function(index, why)
        if why == "tooltip" then
            WowVision.graphHost:combatKey(why)
            return
        end
        if why == "leftClick" then
            WowVision:notify(L["Not available in combat"])
            return
        end
        local entry = slots[index]
        if entry == nil then
            return
        end
        local open = instance()
        if open == nil then
            open = WowVision.UIHost:openWindow("combatEquipment")
        end
        if open ~= nil and open.stack ~= nil then
            WowVision.graphHost:landMirror(open.stack, slotId(entry), why)
        end
    end,
    onClose = function()
        WowVision.UIHost.windowManager:closeWindow("combatEquipment")
    end,
})

-- Out of combat the Character Info key opens the character panel: the list closes with the fight.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function()
    if instance() ~= nil then
        WowVision.UIHost.windowManager:closeWindow("combatEquipment")
    end
end)
