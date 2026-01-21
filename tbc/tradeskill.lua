local module = WowVision.base.windows:createModule("TradeSkill")
local L = module.L
module:setLabel(L["Trade Skill"])
local gen = module:hasUI()

gen:Element("TradeSkill", function(props)
    return {
        "Panel",
        label = TradeSkillFrameTitleText:GetText(),
        wrap = true,
        children = {
            { "ProxyEditBox", frame = TradeSearchInputBox, label = L["Search"] },
            { "ProxyCheckButton", frame = TradeSkillFrameAvailableFilterCheckButton },
            { "ProxyDropdownButton", frame = TradeSkillSubClassDropdown },
            { "ProxyDropdownButton", frame = TradeSkillInvSlotDropdown },
            { "TradeSkill/List", frame = TradeSkillListScrollFrame },
            { "TradeSkill/Details", frame = TradeSkillDetailScrollFrame },
            { "ProxyButton", frame = TradeSkillCreateButton },
            { "ProxyButton", frame = TradeSkillCreateAllButton },
        },
    }
end)

local function getReagentLabel(button)
    local label = button.Name:GetText()
    if button.Count:IsShown() then
        label = label .. " " .. button.Count:GetText()
    end
    return label
end

gen:Element("TradeSkill/Details", function(props)
    local reagents = { "List", label = TradeSkillReagentLabel:GetText(), children = {} }
    for i = 1, MAX_TRADE_SKILL_REAGENTS do
        local reagent = _G["TradeSkillReagent" .. i]
        if reagent and reagent:IsShown() then
            tinsert(reagents.children, {
                "ProxyButton",
                frame = reagent,
                label = getReagentLabel(reagent),
            })
        end
    end

    local result = {
        "List",
        children = {
            { "ProxyButton", frame = TradeSkillSkillIcon, label = TradeSkillSkillName:GetText() },
        },
    }
    if TradeSkillDescription:IsShown() and TradeSkillDescription:IsVisible() then
        local descriptionText = TradeSkillDescription:GetText()
        --The length check is required because for some reason the default value of the font string is " " (the string with a single space)
        if descriptionText and #descriptionText > 1 then
            tinsert(result.children, { "Text", text = descriptionText })
        end
    end
    if TradeSkillRequirementText:IsVisible() then
        local requirementText = TradeSkillRequirementText:GetText()
        if requirementText then
            tinsert(result.children, { "Text", text = REQUIRES_LABEL .. " " .. requirementText })
        end
    end
    tinsert(result.children, reagents)
    return result
end)

local function getTradeSkillButtons()
    local buttons = {}
    for i = 1, TRADE_SKILLS_DISPLAYED do
        local button = _G["TradeSkillSkill" .. i]
        if button then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function getTradeSkillNumEntries(self)
    return GetNumTradeSkills()
end

local difficultyColors = {
    optimal = L["Orange"],
    medium = L["Yellow"],
    easy = L["Green"],
    trivial = L["Grey"],
}

local function getTradeSkillButton(self, button)
    local id = button:GetID()
    local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(id)
    local header = nil
    local extra = nil
    local label = button:GetText()
    if skillType == "header" or skillType == "subheader" then
        if isExpanded then
            header = "expanded"
        else
            header = "collapsed"
        end
    else
        extra = difficultyColors[skillType]
    end
    if numAvailable > 0 then
        label = label .. " " .. numAvailable
    end
    if extra then
        label = label .. " (" .. extra .. ")"
    end
    return {
        "ProxyButton",
        frame = button,
        label = label,
        header = header,
        selected = id == GetTradeSkillSelectionIndex(),
    }
end

local function getTradeSkillButtonHeight(self)
    return TRADE_SKILL_HEIGHT
end

gen:Element("TradeSkill/List", function(props)
    local frame = props.frame
    if frame and frame:IsShown() then
        return {
            "ProxyScrollFrame",
            frame = frame,
            label = L["Recipes"],
            getNumEntries = getTradeSkillNumEntries,
            getElement = getTradeSkillButton,
            getElementHeight = getTradeSkillButtonHeight,
            getButtons = getTradeSkillButtons,
        }
    end

    -- Scroll frame not shown, render buttons directly
    local result = {
        "List",
        label = L["Recipes"],
        children = {},
    }
    local buttons = getTradeSkillButtons()
    for _, button in ipairs(buttons) do
        if button:IsShown() then
            tinsert(result.children, getTradeSkillButton(nil, button))
        end
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "TradeSkill",
    generated = true,
    rootElement = "TradeSkill",
    frameName = "TradeSkillFrame",
    conflictingAddons = { "Sku" },
})
