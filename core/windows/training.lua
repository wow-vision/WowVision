local module = WowVision.base.windows:createModule("training")
local L = module.L
module:setLabel(L["Training"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The class trainer: the service list, the selected service's details, and
-- the train button. Details are live: selecting a service rewrites them in
-- place.
--
-- The service list frame changed from a Faux-style static button pool
-- (ClassTrainerListScrollFrame) to a ScrollBox (ClassTrainerFrame.ScrollBox)
-- at some point after the original migration -- each row's element data is
-- just { skillIndex, playerMoney, trainerType }, a thin pointer back into
-- the same GetTrainerServiceInfo(skillIndex) API the old code used, so the
-- announcement logic below is unchanged; only the scroll adapter is new.
--
-- GetTrainerServiceInfo's own return order also differs by client: Classic/
-- TBC/Mists return (name, rank, category, isExpanded); WoW: Forever (since
-- patch 1.60.1) returns (name, category, spellID, levelReq, rank) instead.
-- The two are told apart by the 3rd value's type -- a category string on the
-- old signature, a numeric spellID on the new one.
-- Tree-backed ScrollBoxes (WoW: Forever) hand emitters the tree node, not its
-- payload -- Find(index, true) returns the node so collapse state stays
-- readable; the actual { skillIndex, playerMoney, trainerType } table lives
-- behind node:GetData(). Flat providers (Classic/TBC/Mists) already return
-- the payload directly, so this is a no-op there.
local function servicePayload(data)
    if type(data) == "table" and data.GetData ~= nil then
        return data:GetData()
    end
    return data
end

local function getServiceInfo(index)
    local a, b, c, d, e = GetTrainerServiceInfo(index)
    if type(c) == "number" then
        return { name = a, category = b, spellID = c, levelReq = d, rank = e }
    end
    return { name = a, rank = b, category = c, isExpanded = d }
end

local function serviceLabel(index)
    local info = getServiceInfo(index)
    if info.name == nil then
        return nil
    end
    local label = info.name
    if info.rank ~= nil and info.rank ~= "" then
        label = label .. " " .. info.rank
    end
    if info.category == "used" then
        label = label .. ", " .. L["Known"]
    elseif info.category == "unavailable" then
        label = label .. ", " .. L["Unavailable"]
    end
    if info.category ~= "header" then
        local cost = GetTrainerServiceCost ~= nil and GetTrainerServiceCost(index) or nil
        if cost ~= nil and cost > 0 then
            label = label .. ", " .. C_CurrencyInfo.GetCoinText(cost)
        end
        if info.category == "unavailable" and info.levelReq ~= nil and info.levelReq > 0 then
            label = label .. ", " .. L["Level"] .. " " .. tostring(info.levelReq)
        end
    end
    return label
end

local function emitService(builder, data, position, helpers)
    local index = servicePayload(data).skillIndex
    local category = getServiceInfo(index).category

    local announcements = {
        {
            text = function()
                return serviceLabel(index)
            end,
            kind = kinds.label,
            live = "focus",
        },
    }
    if category == "header" then
        tinsert(announcements, {
            text = function()
                return getServiceInfo(index).isExpanded and L["Expanded"] or L["Collapsed"]
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
    if ClassTrainerFrame.ScrollBox ~= nil then
        nodes.scrollBoxList(builder, {
            scrollBox = ClassTrainerFrame.ScrollBox,
            key = "services",
            label = L["Training"],
            id = function(data)
                return ControlId.structural("services:" .. tostring(servicePayload(data).skillIndex))
            end,
            emit = emitService,
        })
    elseif ClassTrainerListScrollFrame ~= nil then
        -- Older clients still on the Faux-style static button pool.
        nodes.hybridScrollList(builder, {
            scrollFrame = ClassTrainerListScrollFrame,
            key = "services",
            label = L["Training"],
            count = function()
                return GetNumTrainerServices()
            end,
            rowHeight = CLASS_TRAINER_SKILL_HEIGHT,
            buttons = function()
                local buttons = {}
                for i = 1, CLASS_TRAINER_SKILLS_DISPLAYED do
                    local button = _G["ClassTrainerSkill" .. i]
                    if button ~= nil then
                        tinsert(buttons, button)
                    end
                end
                return buttons
            end,
            emit = function(emitBuilder, index, helpers)
                emitService(emitBuilder, { skillIndex = index }, index, helpers)
            end,
        })
    else
        builder:pushContext("services", L["Training"])
        builder:addItem(ControlId.structural("services:unsupported"), nodes.text({ label = L["Unavailable"] }))
        builder:popContext()
    end

    renderDetails(builder)

    local trainButton = ClassTrainerFrame.TrainButton or ClassTrainerTrainButton
    if trainButton ~= nil and trainButton:IsShown() then
        builder:beginStop("train")
        builder:addItem(ControlId.forObject(trainButton), nodes.proxyButton({ target = trainButton }))
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
