local module = WowVision.base.windows:createModule("training")
local L = module.L
module:setLabel(L["Training"])
local gen = module:hasUI()

gen:Element("training", function(props)
    return {
        "Panel",
        label = ClassTrainerNameText:GetText(),
        wrap = true,
        children = {
            { "training/List", frame = ClassTrainerListScrollFrame },
            { "training/Details", frame = ClassTrainerDetailScrollFrame },
            { "ProxyButton", frame = ClassTrainerTrainButton },
        },
    }
end)

local function listFrame_getElementHeight(self)
    return CLASS_TRAINER_SKILL_HEIGHT
end

local function ListFrame_getNumEntries(self)
    return GetNumTrainerServices()
end

local function ListFrame_getButton(self, button)
    local id = button:GetID()
    local serviceName, serviceSubText, serviceType, isExpanded = GetTrainerServiceInfo(id)
    local label = serviceName
    if serviceSubText then
        label = label .. " " .. serviceSubText
    end
    local header = nil
    if serviceType == "used" then
        label = label .. " " .. L["Known"]
    elseif serviceType == "unavailable" then
        label = label .. " " .. L["Unavailable"]
    elseif serviceType == "header" then
        if isExpanded then
            header = "expanded"
        else
            header = "collapsed"
        end
    end
    return {
        "ProxyButton",
        frame = button,
        label = label,
        selected = id == GetTrainerSelectionIndex(),
        header = header,
    }
end

local function ListFrame_getButtons(self)
    local buttons = {}
    for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
        local button = _G["ClassTrainerSkill" .. i]
        if button then
            tinsert(buttons, button)
        end
    end
    return buttons
end

gen:Element("training/List", function(props)
    local frame = props.frame
    if frame:IsShown() then
        return {
            "ProxyScrollFrame",
            frame = frame,
            getNumEntries = ListFrame_getNumEntries,
            getElement = ListFrame_getButton,
            getElementHeight = listFrame_getElementHeight,
            getButtons = ListFrame_getButtons,
        }
    end
    local result = { "List", children = {} }
    for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
        local button = _G["ClassTrainerSkill" .. i]
        if button and button:IsShown() then
            local element = ListFrame_getButton(nil, button)
            tinsert(result.children, element)
        end
    end
    return result
end)

gen:Element("training/Details", function(props)
    local frame = props.frame
    if not frame or not frame:IsVisible() then
        return nil
    end
    if not ClassTrainerSkillIcon:IsShown() then
        return nil
    end
    local result = { "List", label = L["Details"], children = {} }
    tinsert(result.children, { "ProxyButton", frame = ClassTrainerSkillIcon, label = ClassTrainerSkillName:GetText() })
    if ClassTrainerSubSkillName:IsVisible() then
        tinsert(result.children, { "Text", text = ClassTrainerSubSkillName:GetText() })
    end
    if ClassTrainerSkillRequirements:IsVisible() then
        tinsert(result.children, { "Text", text = ClassTrainerSkillRequirements:GetText() })
    end
    if ClassTrainerCostLabel:IsVisible() then
        tinsert(result.children, {
            "Text",
            text = ClassTrainerCostLabel:GetText() .. " " .. C_CurrencyInfo.GetCoinText(
                ClassTrainerDetailMoneyFrame.staticMoney
            ),
        })
    end
    return result
end)

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "training",
    generated = true,
    rootElement = "training",
    conflictingAddons = { "sku" },
    interactionType = Enum.PlayerInteractionType.Trainer,
})
