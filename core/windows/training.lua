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

-- The service the Train button buys: the trainer frame's own selection, not
-- GetTrainerSelectionIndex, which can still name a row while the frame has
-- none and Train is off. WoW: Forever keeps it as a display index (0 is the
-- profession step button) and maps it to the skill index; Classic/TBC/Mists
-- keep the skill index itself.
local function selectedSkillIndex()
    local selected = ClassTrainerFrame ~= nil and ClassTrainerFrame.selectedService or nil
    if selected == nil then
        return nil
    end
    local map = ClassTrainerFrame.displayIndexToSkillIndex
    if map ~= nil then
        return map[selected]
    end
    return selected
end

local function getServiceInfo(index)
    local a, b, c, d, e = GetTrainerServiceInfo(index)
    if type(c) == "number" then
        return { name = a, category = b, spellID = c, levelReq = d, rank = e }
    end
    return { name = a, rank = b, category = c, isExpanded = d }
end

-- The "Requires" line Blizzard prints under each row: level, profession rank
-- (Cooking (50)) and abilities, built from the same globals the row uses so
-- it reads in the client's language.
local function serviceRequirements(index, info)
    local parts = {}
    local levelReq = info.levelReq
    if levelReq == nil and GetTrainerServiceLevelReq ~= nil then
        levelReq = GetTrainerServiceLevelReq(index)
    end
    if levelReq ~= nil and levelReq > 1 then
        tinsert(parts, format(TRAINER_REQ_LEVEL, levelReq))
    end
    if GetTrainerServiceSkillReq ~= nil then
        local skill, rank = GetTrainerServiceSkillReq(index)
        if skill ~= nil and skill ~= "" then
            tinsert(parts, format(TRAINER_REQ_SKILL_RANK, skill, rank))
        end
    end
    if GetTrainerServiceNumAbilityReq ~= nil then
        for i = 1, GetTrainerServiceNumAbilityReq(index) or 0 do
            local ability = GetTrainerServiceAbilityReq(index, i)
            if ability ~= nil and ability ~= "" then
                tinsert(parts, ability)
            end
        end
    end
    if #parts == 0 then
        return nil
    end
    return REQUIRES_LABEL .. " " .. table.concat(parts, PLAYER_LIST_DELIMITER)
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
        if info.category ~= "used" then
            local requirements = serviceRequirements(index, info)
            if requirements ~= nil then
                label = label .. ", " .. requirements
            end
        end
    end
    return label
end

local function serviceAnnouncements(index)
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
                if index == selectedSkillIndex() then
                    return L["selected"]
                end
                return nil
            end,
            kind = kinds.selected,
            live = "focus",
        })
    end
    return announcements
end

local function emitService(builder, data, position, helpers)
    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = serviceAnnouncements(servicePayload(data).skillIndex),
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

    -- WoW: Forever lifts the profession's next rank (Apprentice Cooking for
    -- someone who has not learned it yet) out of the service list into its
    -- own button above it; the list never contains that service.
    local stepButton = ClassTrainerFrame.skillStepButton
    local stepIndex = GetTrainerServiceStepIndex ~= nil and GetTrainerServiceStepIndex() or nil
    if stepButton ~= nil and stepButton:IsShown() and stepIndex ~= nil then
        builder:beginStop("step")
        builder:addItem(
            ControlId.structural("step"),
            nodes.attachHover({
                controlType = graph.controlTypes.button,
                announcements = serviceAnnouncements(stepIndex),
                bindings = {
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = stepButton },
                },
            }, stepButton)
        )
    end

    -- The service filter (Available, Unavailable, Already Known), a dropdown
    -- of checkboxes on every client. The game hides unavailable services by
    -- default on WoW: Forever, so without this a low level character hears
    -- one service and nothing of what comes later.
    local filter = ClassTrainerFrame.FilterDropdown
    if filter ~= nil and filter:IsShown() then
        builder:beginStop("filter")
        builder:addItem(
            ControlId.forObject(filter),
            nodes.proxyDropdown({ target = filter, label = L["Filter"] })
        )
    end

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

-- WoW: Forever turns Train on only while it draws the selected row, so on
-- opening the window the first learnable service can be selected (or the
-- frame can have no selection at all) while Train stays off until that row
-- is clicked. One frame after the window opens, and after each purchase,
-- this finishes the game's own selection: a learnable selected row gets the
-- game's row click; no selection, or one that is no longer learnable after
-- a purchase, goes to the game's own nearest learnable service. Then Train
-- works straight away, and pressing it again and again learns them all.
-- Classic/TBC/Mists select in their own window code and are left alone.
local purchasePending = false
local hookedTrainButton = nil

local function selectedRow(frame)
    local selected = frame.selectedService
    if selected == 0 then
        return frame.skillStepButton
    end
    return frame.ScrollBox:FindFrameByPredicate(function(row, elementData)
        elementData = servicePayload(elementData)
        return elementData ~= nil and elementData.displayIndex == selected
    end)
end

local function finishSelection(afterPurchase)
    local frame = ClassTrainerFrame
    if frame == nil or not frame:IsShown() or frame.ScrollBox == nil then
        return
    end
    local trainButton = frame.TrainButton
    if trainButton == nil or trainButton:IsEnabled() then
        return
    end
    local row = frame.selectedService ~= nil and selectedRow(frame) or nil
    if row ~= nil and row.isAvailable then
        row:Click("LeftButton")
    elseif (frame.selectedService == nil or afterPurchase) and ClassTrainer_SelectNearestLearnableSkill ~= nil then
        ClassTrainer_SelectNearestLearnableSkill()
    end
end

module:registerEvent("event", "TRAINER_SHOW")
module:registerEvent("event", "TRAINER_UPDATE")

function module:onEvent(event)
    if event == "TRAINER_SHOW" then
        purchasePending = false
        C_Timer.After(0, function()
            local trainButton = ClassTrainerFrame ~= nil and ClassTrainerFrame.TrainButton or nil
            if trainButton ~= nil and hookedTrainButton ~= trainButton then
                hookedTrainButton = trainButton
                trainButton:HookScript("OnClick", function()
                    purchasePending = true
                end)
            end
            finishSelection(false)
        end)
    elseif event == "TRAINER_UPDATE" then
        local afterPurchase = purchasePending
        purchasePending = false
        C_Timer.After(0, function()
            finishSelection(afterPurchase)
        end)
    end
end

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "training",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.Trainer,
    graphScreen = { render = render },
})
