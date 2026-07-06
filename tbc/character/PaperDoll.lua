local char = WowVision.tbc.character
local L = char.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The TBC paper doll: equipment (named slot frames, live labels, drag,
-- immediate tooltips), the two stat columns each led by its category
-- dropdown, and the resistances.

-- Slot ID to localized name mapping for empty slots
local SLOT_NAMES = {
    [INVSLOT_AMMO] = L["Ammo"],
    [INVSLOT_HEAD] = L["Head"],
    [INVSLOT_NECK] = L["Neck"],
    [INVSLOT_SHOULDER] = L["Shoulders"],
    [INVSLOT_BACK] = L["Back"],
    [INVSLOT_CHEST] = L["Chest"],
    [INVSLOT_BODY] = L["Shirt"],
    [INVSLOT_TABARD] = L["Tabard"],
    [INVSLOT_WRIST] = L["Wrist"],
    [INVSLOT_HAND] = L["Hands"],
    [INVSLOT_WAIST] = L["Waist"],
    [INVSLOT_LEGS] = L["Legs"],
    [INVSLOT_FEET] = L["Feet"],
    [INVSLOT_FINGER1] = L["Finger"],
    [INVSLOT_FINGER2] = L["Finger"],
    [INVSLOT_TRINKET1] = L["Trinket"],
    [INVSLOT_TRINKET2] = L["Trinket"],
    [INVSLOT_MAINHAND] = L["Main Hand"],
    [INVSLOT_OFFHAND] = L["Off Hand"],
    [INVSLOT_RANGED] = L["Ranged"],
}

-- TBC equipment slot frame names in logical order
local EQUIPMENT_SLOTS = {
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

local RESISTANCE_FRAMES = {
    "MagicResFrame1", -- Fire
    "MagicResFrame2", -- Frost
    "MagicResFrame3", -- Nature
    "MagicResFrame4", -- Shadow
    "MagicResFrame5", -- Arcane
}

local function getEquipmentLabel(frame)
    local slotId = frame:GetID()
    local itemLink = GetInventoryItemLink("player", slotId)
    if itemLink then
        local itemName = GetItemInfo(itemLink)
        return itemName or itemLink
    end
    -- Fallback for slots where GetInventoryItemLink returns nil (e.g. ammo slot)
    local itemId = GetInventoryItemID("player", slotId)
    if itemId then
        local itemName = GetItemInfo(itemId)
        if itemName then
            return itemName
        end
    end
    return SLOT_NAMES[slotId] or L["Empty"]
end

local function statText(prefix, i)
    local label = _G[prefix .. i .. "Label"]
    local value = _G[prefix .. i .. "StatText"]
    if label == nil or value == nil then
        return nil
    end
    local labelText = label:GetText()
    if labelText == nil or labelText == "" then
        return nil
    end
    return labelText .. " " .. (value:GetText() or "")
end

local function statsColumn(builder, stopKey, prefix)
    builder:beginStop(stopKey)
    builder:pushContext(stopKey, L["Stats"])
    local dropdown = _G[prefix .. "Dropdown"]
    if dropdown ~= nil and dropdown:IsShown() then
        builder:addItem(ControlId.forObject(dropdown), nodes.proxyDropdown({ target = dropdown }))
    end
    for i = 1, 6 do
        local statFrame = _G[prefix .. i]
        if statFrame ~= nil and statFrame:IsShown() then
            local capturedPrefix, capturedIndex = prefix, i
            builder:addItem(
                ControlId.forObject(statFrame),
                nodes.proxyButton({
                    target = statFrame,
                    label = function()
                        return statText(capturedPrefix, capturedIndex)
                    end,
                })
            )
        end
    end
    builder:popContext()
end

function char.renderPaperDoll(builder)
    builder:beginStop("equipment")
    builder:pushContext("equipment", L["Equipment"])
    for _, slotName in ipairs(EQUIPMENT_SLOTS) do
        local slot = _G[slotName]
        if slot ~= nil and slot:IsShown() then
            local captured = slot
            local vtable = nodes.proxyButton({
                target = captured,
                label = function()
                    return getEquipmentLabel(captured)
                end,
            })
            if vtable ~= nil then
                tinsert(vtable.bindings, {
                    binding = "drag",
                    type = "Function",
                    func = function()
                        local script = captured:GetScript("OnDragStart")
                        if script ~= nil then
                            script(captured)
                        end
                    end,
                })
                builder:addItem(ControlId.forObject(captured), vtable)
            end
        end
    end
    builder:popContext()

    statsColumn(builder, "statsLeft", "PlayerStatFrameLeft")
    statsColumn(builder, "statsRight", "PlayerStatFrameRight")

    builder:beginStop("resistances")
    builder:pushContext("resistances", L["Resistances"])
    for _, frameName in ipairs(RESISTANCE_FRAMES) do
        local frame = _G[frameName]
        if frame ~= nil and frame:IsShown() then
            local captured = frame
            builder:addItem(
                ControlId.forObject(captured),
                nodes.proxyButton({
                    target = captured,
                    label = function()
                        return captured.tooltip
                    end,
                })
            )
        end
    end
    builder:popContext()
end
