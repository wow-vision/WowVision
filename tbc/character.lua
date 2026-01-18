local module = WowVision.base.windows:createModule("character")
local L = module.L
module:setLabel(L["Character"])
local gen = module:hasUI()

-- Slot ID to localized name mapping for empty slots
local SLOT_NAMES = {
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

gen:Element("character", {
    regenerateOn = {
        events = { "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED" },
        values = function(props)
            return { selectedTab = CharacterFrame.selectedTab }
        end,
    },
}, function(props)
    local result = { "Panel", label = L["Character"], wrap = true, children = {} }
    local tab = CharacterFrame.selectedTab
    if tab == 1 then
        tinsert(result.children, { "character/PaperDoll", frame = PaperDollFrame })
    else
        tinsert(result.children, { "Text", text = "Not yet implemented" })
    end
    tinsert(result.children, { "character/Tabs" })
    return result
end)

gen:Element("character/Tabs", {
    regenerateOn = {
        values = function(props)
            return { selectedTab = CharacterFrame.selectedTab }
        end,
    },
}, function(props)
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    -- TBC has 5 tabs
    for i = 1, 5 do
        local tab = _G["CharacterFrameTab" .. i]
        if tab and tab:IsShown() then
            tinsert(result.children, {
                "ProxyButton",
                key = "tab_" .. i,
                frame = tab,
                selected = CharacterFrame.selectedTab == i,
            })
        end
    end
    return result
end)

gen:Element("character/PaperDoll", {
    regenerateOn = {
        events = { "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED" },
    },
}, function(props)
    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "character/Equipment" },
            { "character/Stats" },
            { "character/Resistances" },
        },
    }
end)

local function getEquipmentLabel(frame)
    local slotId = frame:GetID()
    local itemLink = GetInventoryItemLink("player", slotId)
    if itemLink then
        local itemName = GetItemInfo(itemLink)
        return itemName or itemLink
    end
    return SLOT_NAMES[slotId] or L["Empty"]
end

gen:Element("character/Equipment", {
    regenerateOn = {
        events = { "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED" },
    },
}, function(props)
    local result = { "List", label = L["Equipment"], children = {} }
    for _, slotName in ipairs(EQUIPMENT_SLOTS) do
        local slot = _G[slotName]
        if slot and slot:IsShown() then
            local slotId = slot:GetID()
            tinsert(result.children, {
                "ProxyButton",
                key = "slot_" .. slotId,
                frame = slot,
                label = getEquipmentLabel(slot),
                tooltip = {
                    type = "Game",
                    mode = "immediate",
                },
            })
        end
    end
    return result
end)

gen:Element("character/Stats", {
    regenerateOn = {
        events = {
            "PLAYER_EQUIPMENT_CHANGED",
            "UNIT_INVENTORY_CHANGED",
            "COMBAT_RATING_UPDATE",
            "UNIT_STATS",
            "UNIT_AURA",
            "UNIT_DAMAGE",
            "UNIT_ATTACK_SPEED",
            "UNIT_ATTACK_POWER",
            "UNIT_RANGED_ATTACK_POWER",
            "PLAYER_DAMAGE_DONE_MODS",
            "UNIT_RESISTANCES",
        },
    },
}, function(props)
    return {
        "List",
        label = L["Stats"],
        children = {
            { "character/StatsColumn", key = "left", prefix = "PlayerStatFrameLeft" },
            { "character/StatsColumn", key = "right", prefix = "PlayerStatFrameRight" },
        },
    }
end)

local function getStatText(statFrame)
    if not statFrame or not statFrame:IsShown() then
        return nil
    end
    local label = _G[statFrame:GetName() .. "Label"]
    local statText = _G[statFrame:GetName() .. "StatText"]
    if not label or not statText then
        return nil
    end
    local labelText = label:GetText()
    local valueText = statText:GetText()
    if not labelText or labelText == "" then
        return nil
    end
    return labelText .. " " .. (valueText or "")
end

gen:Element("character/StatsColumn", function(props)
    local prefix = props.prefix
    local dropdownName = prefix .. "Dropdown"
    local dropdown = _G[dropdownName]

    local result = { "List", label = L["Stats"], children = {} }

    -- Add the dropdown to change stat category
    if dropdown and dropdown:IsShown() then
        tinsert(result.children, {
            "ProxyDropdownButton",
            key = "dropdown",
            frame = dropdown,
        })
    end

    -- Add the 6 stat frames for this column
    for i = 1, 6 do
        local statFrame = _G[prefix .. i]
        if statFrame and statFrame:IsShown() then
            local text = getStatText(statFrame)
            if text then
                tinsert(result.children, {
                    "ProxyButton",
                    key = "stat_" .. i,
                    frame = statFrame,
                    label = text,
                    tooltip = {
                        type = "Game",
                        mode = "immediate",
                    },
                })
            end
        end
    end

    if #result.children == 0 then
        return nil
    end

    return result
end)

-- Resistance frame names
-- MagicResFrame1-5, each has a .tooltip property with localized name and value
local RESISTANCE_FRAMES = {
    "MagicResFrame1", -- Fire
    "MagicResFrame2", -- Frost
    "MagicResFrame3", -- Nature
    "MagicResFrame4", -- Shadow
    "MagicResFrame5", -- Arcane
}

gen:Element("character/Resistances", {
    regenerateOn = {
        events = { "UNIT_RESISTANCES" },
    },
}, function(props)
    local result = { "List", label = L["Resistances"], children = {} }

    for i, frameName in ipairs(RESISTANCE_FRAMES) do
        local frame = _G[frameName]
        if frame and frame:IsShown() then
            local label = frame.tooltip or ""
            tinsert(result.children, {
                "ProxyButton",
                key = "resistance_" .. i,
                frame = frame,
                label = label,
                tooltip = {
                    type = "Game",
                    mode = "immediate",
                },
            })
        end
    end

    if #result.children == 0 then
        return nil
    end

    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "character",
    generated = true,
    rootElement = "character",
    frameName = "CharacterFrame",
    conflictingAddons = { "Sku" },
})
