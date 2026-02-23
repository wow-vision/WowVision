local module = WowVision.base.windows:createModule("bars")
local L = module.L
module:setLabel(L["Bars"])
local gen = module:hasUI()

-- Stance buttons compatibility
local stanceButtons = {}
if StanceBarFrame and StanceBarFrame.StanceButtons then
    stanceButtons = StanceBarFrame.StanceButtons
else
    for i = 1, 10 do
        tinsert(stanceButtons, _G["StanceButton" .. i])
    end
end
module.stanceButtons = stanceButtons
module.StanceBarFrame = StanceBarFrame or StanceBar

-- Code borrowed from LibRangeCheck
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
module.GetSpellInfo = GetSpellInfo

-- Shared utility for getting action button labels
function module.getActionButtonLabel(button)
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

-- Base class for all action bar types
local ActionBar = WowVision.Class("ActionBar"):include(WowVision.InfoClass)
ActionBar.info:addFields({
    { key = "key", required = true },
    { key = "type", required = true },
    { key = "label", required = true },
})

function ActionBar:initialize(info)
    self:setInfo(info)
end

function ActionBar:isVisible()
    return true
end

function ActionBar:getGenerator()
    error("ActionBar:getGenerator must be implemented by subclass")
end

module.ActionBar = ActionBar

-- Create component registry for action bars
local bars = module:createComponentRegistry({
    key = "bars",
    path = "bars",
    type = "class",
    baseClass = ActionBar,
    classNamePrefix = "ActionBar_",
})

-- Generator for individual action button
gen:Element("bars/ActionButton", function(props)
    return {
        "ProxyButton",
        frame = props.frame,
        label = module.getActionButtonLabel(props.frame),
        ignoreRequiresFrameShown = true,
        draggable = true
    }
end)

-- Generator for a bar component
gen:Element("bars/Bar", function(props)
    local bar = props.bar
    if not bar:isVisible() then
        return nil
    end
    return bar:getGenerator()
end)

-- Main bars generator
gen:Element("bars", function(props)
    local children = {}
    bars:forEachComponent(function(bar)
        tinsert(children, { "bars/Bar", bar = bar })
    end)
    return {
        "List",
        label = L["Bars"],
        children = children,
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
    type = "Function",
    key = "bars/openWindow",
    inputs = { "SHIFT-F4" },
    label = L["Action Bars"],
    interruptSpeech = true,
    func = function()
        WowVision.UIHost:openWindow("bars")
    end,
})
