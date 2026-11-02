local module = WowVision.base.windows:createModule("Craft")
local L = module.L
module:setLabel(L["Craft"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC craft window (CraftFrame, Blizzard_CraftUI): the older twin of the
-- trade skill window, used by Enchanting and by the hunter's Beast Training.
-- The skill bar, the has-materials filter and the slot dropdown (Enchanting
-- only), the training points (Beast Training only), the craft list (Faux pool
-- over the craft API), the live details pane with reagents, and the
-- Enchant/Train and Close buttons. Laid out like tbc/tradeskill.lua.

local difficultyColors = {
    optimal = L["Orange"],
    medium = L["Yellow"],
    easy = L["Green"],
    trivial = L["Grey"],
}

local function craftButtons()
    local buttons = {}
    for i = 1, CRAFTS_DISPLAYED do
        local button = _G["Craft" .. i]
        if button ~= nil then
            tinsert(buttons, button)
        end
    end
    return buttons
end

-- Name, rank, how many the bags can make, difficulty, and for Beast Training
-- the training point cost -- what the row shows.
local function craftLabel(index)
    local craftName, craftSubSpellName, craftType, numAvailable, _, trainingPointCost = GetCraftInfo(index)
    if craftName == nil then
        return nil
    end
    local parts = { craftName }
    if craftSubSpellName ~= nil and craftSubSpellName ~= "" then
        tinsert(parts, craftSubSpellName)
    end
    if numAvailable ~= nil and numAvailable > 0 then
        tinsert(parts, tostring(numAvailable))
    end
    local difficulty = difficultyColors[craftType]
    if difficulty ~= nil then
        tinsert(parts, "(" .. difficulty .. ")")
    end
    if trainingPointCost ~= nil and trainingPointCost > 0 then
        tinsert(parts, format(TRAINER_LIST_TP, trainingPointCost))
    end
    return table.concat(parts, " ")
end

local function craftEntryId(index)
    local craftName, craftSubSpellName, craftType = GetCraftInfo(index)
    if craftName ~= nil then
        local prefix = craftType == "header" and "craftHeader:" or "craft:"
        return ControlId.structural(prefix .. craftName .. ":" .. tostring(craftSubSpellName or ""))
    end
    return ControlId.structural("entry:" .. index)
end

local function emitCraft(builder, index, helpers)
    local craftName, _, craftType = GetCraftInfo(index)
    if craftName == nil then
        return
    end

    local announcements = {
        {
            text = function()
                return craftLabel(index)
            end,
            kind = kinds.label,
        },
    }
    if craftType == "header" then
        tinsert(announcements, {
            text = function()
                local _, _, _, _, isExpanded = GetCraftInfo(index)
                return isExpanded and L["Expanded"] or L["Collapsed"]
            end,
            kind = kinds.value,
        })
    else
        tinsert(announcements, {
            text = function()
                if index == GetCraftSelectionIndex() then
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

-- A font string of the details pane, read while it holds text. Blizzard
-- parks " " (a single space) in empty strings.
local function regionText(region)
    local text = region:GetText()
    if text ~= nil and #text > 1 then
        return text
    end
    return nil
end

local function detailText(builder, id, region, scrollFrame)
    if region == nil or not region:IsShown() or regionText(region) == nil then
        return
    end
    local vtable = nodes.text({
        label = function()
            return regionText(region)
        end,
    })
    nodes.attachScrollFrame(vtable, scrollFrame, region)
    builder:addItem(id, vtable)
end

local function renderDetails(builder)
    local scrollFrame = CraftDetailScrollFrame
    if scrollFrame == nil or not scrollFrame:IsVisible() or GetNumCrafts() == 0 then
        return
    end

    builder:beginStop("details")
    builder:pushContext("details", L["Details"])

    local icon = nodes.proxyButton({
        target = CraftIcon,
        label = function()
            local name = CraftName:GetText()
            local count = CraftIconCount:GetText()
            if count ~= nil and count ~= "" then
                return (name or "") .. " " .. count
            end
            return name
        end,
    })
    if icon ~= nil then
        nodes.attachScrollFrame(icon, scrollFrame, CraftIcon)
        builder:addItem(ControlId.structural("craft"), icon)
    end

    detailText(builder, ControlId.structural("requirements"), CraftRequirements, scrollFrame)
    detailText(builder, ControlId.structural("cost"), CraftCost, scrollFrame)
    detailText(builder, ControlId.structural("cooldown"), CraftCooldown, scrollFrame)
    detailText(builder, ControlId.structural("description"), CraftDescription, scrollFrame)

    builder:pushContext("reagents", CraftReagentLabel ~= nil and CraftReagentLabel:GetText() or SPELL_REAGENTS or "")
    for i = 1, MAX_CRAFT_REAGENTS do
        local reagent = _G["CraftReagent" .. i]
        if reagent ~= nil and reagent:IsShown() then
            local nameText = _G["CraftReagent" .. i .. "Name"]
            local countText = _G["CraftReagent" .. i .. "Count"]
            local vtable = nodes.proxyButton({
                target = reagent,
                label = function()
                    local label = nameText ~= nil and nameText:GetText() or ""
                    if countText ~= nil and countText:IsShown() then
                        label = label .. " " .. (countText:GetText() or "")
                    end
                    return label
                end,
            })
            if vtable ~= nil then
                nodes.attachScrollFrame(vtable, scrollFrame, reagent)
                builder:addItem(ControlId.forObject(reagent), vtable)
            end
        end
    end
    builder:popContext()
    builder:popContext()
end

local function render(builder, screen)
    if CraftFrame == nil or not CraftFrame:IsShown() then
        return
    end
    builder:pushContext("craft", CraftFrameTitleText:GetText())

    if CraftRankFrame ~= nil and CraftRankFrame:IsShown() then
        builder:beginStop("rank")
        builder:addItem(
            ControlId.structural("rank"),
            nodes.text({
                label = function()
                    return nodes.joinLabel(CraftRankFrameSkillName:GetText(), CraftRankFrameSkillRank:GetText())
                end,
            })
        )
    end
    if CraftFramePointsText ~= nil and CraftFramePointsText:IsShown() then
        builder:beginStop("trainingPoints")
        builder:addItem(
            ControlId.structural("trainingPoints"),
            nodes.text({
                label = function()
                    return nodes.joinLabel(CraftFramePointsLabel:GetText(), CraftFramePointsText:GetText())
                end,
            })
        )
    end
    if CraftFrameAvailableFilterCheckButton ~= nil and CraftFrameAvailableFilterCheckButton:IsShown() then
        builder:beginStop("availableFilter")
        builder:addItem(
            ControlId.forObject(CraftFrameAvailableFilterCheckButton),
            nodes.proxyCheckButton({ target = CraftFrameAvailableFilterCheckButton })
        )
    end
    local dropdown = CraftFrame.Dropdown
    if dropdown ~= nil and dropdown:IsShown() then
        builder:beginStop("slotFilter")
        builder:addItem(ControlId.forObject(dropdown), nodes.proxyDropdown({ target = dropdown }))
    end

    builder:beginStop("crafts")
    nodes.hybridScrollList(builder, {
        scrollFrame = CraftListScrollFrame,
        key = "crafts",
        label = L["Recipes"],
        count = GetNumCrafts,
        rowHeight = CRAFT_SKILL_HEIGHT,
        buttons = craftButtons,
        id = craftEntryId,
        emit = emitCraft,
    })

    renderDetails(builder)

    for _, button in ipairs({ CraftCreateButton, CraftCancelButton }) do
        if button ~= nil and button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "Craft",
    frameName = "CraftFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
