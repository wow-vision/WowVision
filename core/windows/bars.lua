local module = WowVision.base.windows:createModule("bars")
local L = module.L
module:setLabel(L["Bars"])
local gen = module:hasUI()
local stanceButtons = {}
if StanceBarFrame and StanceBarFrame.StanceButtons then
    stanceButtons = StanceBarFrame.StanceButtons
else
    for i = 1, 10 do
        tinsert(stanceButtons, _G["StanceButton" .. i])
    end
end
local StanceBarFrame = StanceBarFrame or StanceBar

--Code borrowed from LibRangeCheck
local GetSpellInfo = GetSpellInfo
    or function(spellID)
        if not spellID then
            return nil
        end

        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name,
                nil,
                spellInfo.iconID,
                spellInfo.castTime,
                spellInfo.minRange,
                spellInfo.maxRange,
                spellInfo.spellID,
                spellInfo.originalIconID
        end
    end

local function getActionButtonLabel(button)
    local actionType, actionID, actionSubtype = GetActionInfo(button.action)
    if not actionType then
        return L["Empty"]
    end
    local name
    if actionType == "spell" then
        name = GetSpellInfo(actionID)
    elseif actionType == "item" then
        name = C_Item.GetItemInfo(actionID)
    elseif actionType == "macro" then
        name = GetMacroInfo(actionID)
    elseif actionType == "companion" then
        if actionSubtype == "CRITTER" then
            name = GetSpellInfo(actionID)
        end
        local mountID = C_MountJournal.GetMountFromSpell(actionID)
        if mountID then
            name = C_MountJournal.GetMountInfoByID(mountID)
        else
            name = "Unknown Mount"
        end
    elseif actionType == "equipmentset" then
        name = C_EquipmentSet.GetEquipmentSetInfo(actionID)
    elseif actionType == "flyout" then
        name = GetSpellInfo(actionID)
    else
        name = "Unknown Action Type"
    end
    if name == nil then
        name = "Unknown, id="
            .. (actionID or "none")
            .. ", action="
            .. (actionType or "none")
            .. ", subtype="
            .. (actionSubtype or "none")
    end
    local label = name
    local hotkey = button.HotKey:GetText()
    if hotkey then
        label = label .. " (" .. hotkey .. ")"
    end
    return label
end

gen:Element("bars/ActionButton", function(props)
    return {
        "ProxyButton",
        frame = props.frame,
        label = getActionButtonLabel(props.frame),
        ignoreRequiresFrameShown = true,
    }
end)

gen:Element("bars/MainActionBar", function(props)
    local result = { "List", direction = "horizontal", label = L["Action Bar"], children = {} }
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            tinsert(result.children, { "bars/ActionButton", frame = button })
        else
            print("Warning: ActionButton" .. i .. " doesn't exist.")
        end
    end

    return result
end)

gen:Element("bars/ActionBar", function(props)
    local result = { "List", direction = "horizontal", label = props.label, children = {} }
    local children = props.frame.actionButtons
    if not children then
        children = { props.frame:GetChildren() }
    end
    for _, v in ipairs(children) do
        tinsert(result.children, { "bars/ActionButton", frame = v })
    end
    return result
end)

gen:Element("bars/PetActionBar", function(props)
    if not PetHasActionBar() then
        return nil
    end
    local result = { "List", label = L["Pet Bar"], direction = "horizontal", children = {} }
    local children = { PetActionBarFrame:GetChildren() }
    for i = 1, NUM_PET_ACTION_SLOTS do
        local button = _G["PetActionButton" .. i]
        local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(i)
        local label = button.tooltipName or L["Empty"]
        if autoCastAllowed then
            if autoCastEnabled then
                label = label .. " " .. L["Auto Casting"]
            else
                label = label .. " " .. L["Not Auto Casting"]
            end
        end
        tinsert(result.children, {
            "ProxyButton",
            frame = button,
            label = label,
            ignoreRequiresFrameShown = true,
        })
    end
    return result
end)

gen:Element("bars/StanceBar", function(props)
    if not StanceBarFrame:IsShown() then
        return nil
    end
    local result = { "List", label = L["Stance Bar"], direction = "horizontal", children = {} }
    for i, v in ipairs(stanceButtons) do
        if v:IsShown() then
            local _, _, _, spellID = GetShapeshiftFormInfo(i)
            local label = GetSpellInfo(spellID)
            tinsert(result.children, { "ProxyButton", frame = v, label = label })
        end
    end
    return result
end)

gen:Element("bars", function(props)
    return {
        "List",
        label = L["Bars"],
        children = {
            { "bars/MainActionBar" },
            { "bars/PetActionBar" },
            { "bars/StanceBar" },
            { "bars/ActionBar", frame = MultiBarBottomLeft, label = L["Bottom Left Bar"] },
            { "bars/ActionBar", frame = MultiBarBottomRight, label = "Bottom Right Bar" },
            { "bars/ActionBar", frame = MultiBarRight, label = L["Right Bar"] },
            { "bars/ActionBar", frame = MultiBarLeft, label = L["Right Bar 2"] },
        },
    }
end)

module:registerWindow({
    type = "ManualWindow",
    name = "bars",
    innate = true,
    generated = true,
    rootElement = "bars",
    hookEscape = true,
})

module:registerBinding({
    type = "Script",
    key = "bars/openWindow",
    inputs = { "SHIFT-F4" },
    label = L["Action Bars"],
    script = "/run WowVision.UIHost:openWindow('bars')",
})
