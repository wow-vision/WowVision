local module = WowVision.base.windows:createModule("bars")
local L = module.L
module:setLabel(L["Bars"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

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

-- An action button node: live label (drag, page flips, and cooldown-driven
-- changes rewrite slots), real clicks, drag support.
function module.actionButtonNode(button, label)
    local vtable = nodes.proxyButton({
        target = button,
        label = label or function()
            return module.getActionButtonLabel(button)
        end,
    })
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local script = button:GetScript("OnDragStart")
            if script ~= nil then
                script(button)
            end
        end,
    })
    return vtable
end

-- One stop holds every visible bar; each bar is a labeled row, so left and
-- right walk along a bar and up and down switch bars.
local function render(builder, screen)
    builder:beginStop("bars")
    builder:pushContext("bars", L["Bars"])
    bars:forEachComponent(function(bar)
        if bar.renderGraph ~= nil and bar:isVisible() then
            local ok, err = pcall(bar.renderGraph, bar, builder)
            if not ok then
                geterrorhandler()(err)
            end
        end
    end)
    builder:popContext()
end

module:registerWindow({
    type = "ManualWindow",
    name = "bars",
    innate = true,
    graphScreen = { render = render, captureClose = true },
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
