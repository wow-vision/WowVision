local module = WowVision.base.windows:createModule("TradeSkill")
local L = module.L
module:setLabel(L["Trade Skill"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC trade skill window: search, the has-materials filter, the
-- subclass and slot dropdowns, the recipe list (Faux pool over the trade
-- skill API), the live details pane with reagents, and the create buttons.

local difficultyColors = {
    optimal = L["Orange"],
    medium = L["Yellow"],
    easy = L["Green"],
    trivial = L["Grey"],
}

local function recipeButtons()
    local buttons = {}
    for i = 1, TRADE_SKILLS_DISPLAYED do
        local button = _G["TradeSkillSkill" .. i]
        if button ~= nil then
            tinsert(buttons, button)
        end
    end
    return buttons
end

local function recipeLabel(index)
    local skillName, skillType, numAvailable = GetTradeSkillInfo(index)
    if skillName == nil then
        return nil
    end
    local label = skillName
    if numAvailable ~= nil and numAvailable > 0 then
        label = label .. " " .. numAvailable
    end
    local difficulty = difficultyColors[skillType]
    if difficulty ~= nil then
        label = label .. " (" .. difficulty .. ")"
    end
    return label
end

local function recipeEntryId(index)
    local skillName, skillType = GetTradeSkillInfo(index)
    if skillName ~= nil then
        local prefix = (skillType == "header" or skillType == "subheader") and "tsHeader:" or "recipe:"
        return ControlId.structural(prefix .. skillName)
    end
    return ControlId.structural("entry:" .. index)
end

local function emitRecipe(builder, index, helpers)
    local skillName, skillType = GetTradeSkillInfo(index)
    if skillName == nil then
        return
    end
    local isHeader = skillType == "header" or skillType == "subheader"

    local announcements = {
        {
            text = function()
                return recipeLabel(index)
            end,
            kind = kinds.label,
        },
    }
    if isHeader then
        tinsert(announcements, {
            text = function()
                local _, _, _, isExpanded = GetTradeSkillInfo(index)
                return isExpanded and L["Expanded"] or L["Collapsed"]
            end,
            kind = kinds.value,
        })
    else
        tinsert(announcements, {
            text = function()
                if index == GetTradeSkillSelectionIndex() then
                    return L["selected"]
                end
                return nil
            end,
            kind = kinds.selected,
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

local function detailText(builder, id, label, scrollFrame, region)
    local vtable = nodes.text({ label = label })
    nodes.attachScrollFrame(vtable, scrollFrame, region)
    builder:addItem(id, vtable)
end

local function renderDetails(builder)
    local scrollFrame = TradeSkillDetailScrollFrame
    if scrollFrame == nil or not scrollFrame:IsVisible() then
        return
    end

    builder:beginStop("details")
    builder:pushContext("details", L["Details"])

    local icon = nodes.proxyButton({
        target = TradeSkillSkillIcon,
        label = function()
            return TradeSkillSkillName:GetText()
        end,
    })
    if icon ~= nil then
        nodes.attachScrollFrame(icon, scrollFrame, TradeSkillSkillIcon)
        builder:addItem(ControlId.structural("skill"), icon)
    end

    if TradeSkillDescription:IsShown() and TradeSkillDescription:IsVisible() then
        detailText(builder, ControlId.structural("description"), function()
            local text = TradeSkillDescription:GetText()
            --The default value of the font string is " " (a single space)
            if text ~= nil and #text > 1 then
                return text
            end
            return nil
        end, scrollFrame, TradeSkillDescription)
    end
    if TradeSkillRequirementText:IsVisible() then
        detailText(builder, ControlId.structural("requirement"), function()
            local text = TradeSkillRequirementText:GetText()
            if text ~= nil and text ~= "" then
                return REQUIRES_LABEL .. " " .. text
            end
            return nil
        end, scrollFrame, TradeSkillRequirementText)
    end

    builder:pushContext(
        "reagents",
        TradeSkillReagentLabel ~= nil and TradeSkillReagentLabel:GetText() or SPELL_REAGENTS or ""
    )
    for i = 1, MAX_TRADE_SKILL_REAGENTS do
        local reagent = _G["TradeSkillReagent" .. i]
        if reagent ~= nil and reagent:IsShown() then
            local captured = reagent
            local vtable = nodes.proxyButton({
                target = captured,
                label = function()
                    local label = captured.Name:GetText() or ""
                    if captured.Count:IsShown() then
                        label = label .. " " .. (captured.Count:GetText() or "")
                    end
                    return label
                end,
            })
            if vtable ~= nil then
                nodes.attachScrollFrame(vtable, scrollFrame, captured)
                builder:addItem(ControlId.forObject(captured), vtable)
            end
        end
    end
    builder:popContext()
    builder:popContext()
end

local function render(builder, screen)
    if TradeSkillFrame == nil or not TradeSkillFrame:IsShown() then
        return
    end
    builder:pushContext("tradeskill", TradeSkillFrameTitleText:GetText())

    if TradeSearchInputBox ~= nil then
        builder:beginStop("search")
        builder:addItem(
            ControlId.structural("search"),
            nodes.proxyEditBox({ editBox = TradeSearchInputBox, label = L["Search"] })
        )
    end
    if TradeSkillFrameAvailableFilterCheckButton ~= nil and TradeSkillFrameAvailableFilterCheckButton:IsShown() then
        builder:beginStop("availableFilter")
        builder:addItem(
            ControlId.forObject(TradeSkillFrameAvailableFilterCheckButton),
            nodes.proxyCheckButton({ target = TradeSkillFrameAvailableFilterCheckButton })
        )
    end
    if TradeSkillSubClassDropdown ~= nil and TradeSkillSubClassDropdown:IsShown() then
        builder:beginStop("subClass")
        builder:addItem(
            ControlId.forObject(TradeSkillSubClassDropdown),
            nodes.proxyDropdown({ target = TradeSkillSubClassDropdown })
        )
    end
    if TradeSkillInvSlotDropdown ~= nil and TradeSkillInvSlotDropdown:IsShown() then
        builder:beginStop("invSlot")
        builder:addItem(
            ControlId.forObject(TradeSkillInvSlotDropdown),
            nodes.proxyDropdown({ target = TradeSkillInvSlotDropdown })
        )
    end

    builder:beginStop("recipes")
    nodes.hybridScrollList(builder, {
        scrollFrame = TradeSkillListScrollFrame,
        key = "recipes",
        label = L["Recipes"],
        count = GetNumTradeSkills,
        rowHeight = TRADE_SKILL_HEIGHT,
        buttons = recipeButtons,
        id = recipeEntryId,
        emit = emitRecipe,
    })

    renderDetails(builder)

    if TradeSkillInputBox ~= nil and TradeSkillInputBox:IsShown() then
        builder:beginStop("quantity")
        builder:addItem(
            ControlId.structural("quantity"),
            nodes.proxyEditBox({ editBox = TradeSkillInputBox, label = L["Quantity"] })
        )
    end

    for _, button in ipairs({ TradeSkillCreateButton, TradeSkillCreateAllButton }) do
        if button ~= nil and button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "TradeSkill",
    frameName = "TradeSkillFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
