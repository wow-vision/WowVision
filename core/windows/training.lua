local module = WowVision.base.windows:createModule("training")
local L = module.L
module:setLabel(L["Training"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The class trainer: the service list (a Faux-style static button pool over
-- GetTrainerServiceInfo), the selected service's details, and the train
-- button. Details are live: selecting a service rewrites them in place.

local function trainerButtons()
    local buttons = {}
    for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
        local button = _G["ClassTrainerSkill" .. i]
        if button ~= nil then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function serviceLabel(index)
    local serviceName, serviceSubText, serviceType = GetTrainerServiceInfo(index)
    if serviceName == nil then
        return nil
    end
    local label = serviceName
    if serviceSubText ~= nil and serviceSubText ~= "" then
        label = label .. " " .. serviceSubText
    end
    if serviceType == "used" then
        label = label .. " " .. L["Known"]
    elseif serviceType == "unavailable" then
        label = label .. " " .. L["Unavailable"]
    end
    return label
end

local function emitService(builder, index, helpers)
    local _, _, serviceType = GetTrainerServiceInfo(index)

    local announcements = {
        {
            text = function()
                return serviceLabel(index)
            end,
            kind = kinds.label,
            live = "focus",
        },
    }
    if serviceType == "header" then
        tinsert(announcements, {
            text = function()
                local _, _, _, isExpanded = GetTrainerServiceInfo(index)
                return isExpanded and L["Expanded"] or L["Collapsed"]
            end,
            kind = kinds.value,
            live = "focus",
        })
    else
        tinsert(announcements, {
            text = function()
                if index == GetTrainerSelectionIndex() then
                    return L["selected"]
                end
                return nil
            end,
            kind = kinds.selected,
            live = "focus",
        })
    end

    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    })
end

local function detailText(builder, id, label)
    builder:addItem(
        id,
        nodes.text({
            label = label,
            live = "focus",
        })
    )
end

local function renderDetails(builder)
    local frame = ClassTrainerDetailScrollFrame
    if frame == nil or not frame:IsVisible() then
        return
    end
    if ClassTrainerSkillIcon == nil or not ClassTrainerSkillIcon:IsShown() then
        return
    end

    builder:beginStop("details")
    builder:pushContext("details", L["Details"])
    builder:addItem(
        ControlId.structural("skill"),
        nodes.attachHover({
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        return ClassTrainerSkillName:GetText()
                    end,
                    kind = kinds.label,
                    live = "focus",
                },
            },
            bindings = {
                {
                    binding = "leftClick",
                    type = "Click",
                    emulatedKey = "LeftButton",
                    target = ClassTrainerSkillIcon,
                },
            },
        }, ClassTrainerSkillIcon)
    )
    if ClassTrainerSubSkillName ~= nil and ClassTrainerSubSkillName:IsVisible() then
        detailText(builder, ControlId.structural("subSkill"), function()
            return ClassTrainerSubSkillName:GetText()
        end)
    end
    if ClassTrainerSkillRequirements ~= nil and ClassTrainerSkillRequirements:IsVisible() then
        detailText(builder, ControlId.structural("requirements"), function()
            return ClassTrainerSkillRequirements:GetText()
        end)
    end
    if ClassTrainerCostLabel ~= nil and ClassTrainerCostLabel:IsVisible() then
        detailText(builder, ControlId.structural("cost"), function()
            return (ClassTrainerCostLabel:GetText() or "")
                .. " "
                .. C_CurrencyInfo.GetCoinText(ClassTrainerDetailMoneyFrame.staticMoney or 0)
        end)
    end
    builder:popContext()
end

local function render(builder, screen)
    if ClassTrainerFrame == nil or not ClassTrainerFrame:IsShown() then
        return
    end
    builder:pushContext("trainer", ClassTrainerNameText ~= nil and ClassTrainerNameText:GetText() or L["Training"])

    builder:beginStop("services")
    nodes.hybridScrollList(builder, {
        scrollFrame = ClassTrainerListScrollFrame,
        key = "services",
        label = L["Training"],
        count = function()
            return GetNumTrainerServices()
        end,
        rowHeight = CLASS_TRAINER_SKILL_HEIGHT,
        buttons = trainerButtons,
        emit = emitService,
    })

    renderDetails(builder)

    if ClassTrainerTrainButton ~= nil and ClassTrainerTrainButton:IsShown() then
        builder:beginStop("train")
        builder:addItem(
            ControlId.forObject(ClassTrainerTrainButton),
            nodes.proxyButton({ target = ClassTrainerTrainButton })
        )
    end

    builder:popContext()
end

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "training",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.Trainer,
    graphScreen = { render = render },
})
