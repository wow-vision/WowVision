local module = WowVision.base.windows:createModule("character")
local L = module.L
module:setLabel(L["Character"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The character panel: tabs pick paper doll (equipment and stats),
-- reputation (a Faux-pooled faction list plus the detail side panel), or
-- currency (a hybrid-scrolled token list). Reputation rows report GetID 0
-- but carry .index, which the scroll adapter prefers.

-- Slot ID to localized name mapping for empty slots
local SLOT_NAMES = {
    [INVSLOT_HEAD] = L["Head"],
    [INVSLOT_NECK] = L["Neck"],
    [INVSLOT_SHOULDER] = L["Shoulders"],
    [INVSLOT_BACK] = L["Back"],
    [INVSLOT_CHEST] = L["Chest"],
    [INVSLOT_BODY] = L["Shirt"],
    [INVSLOT_TABARD] = L["Tabard"],
    [INVSLOT_WRIST] = L["Wrist"],
    [INVSLOT_HAND] = L["Hands"],
    [INVSLOT_WAIST] = L["Waist"],
    [INVSLOT_LEGS] = L["Legs"],
    [INVSLOT_FEET] = L["Feet"],
    [INVSLOT_FINGER1] = L["Finger"],
    [INVSLOT_FINGER2] = L["Finger"],
    [INVSLOT_TRINKET1] = L["Trinket"],
    [INVSLOT_TRINKET2] = L["Trinket"],
    [INVSLOT_MAINHAND] = L["Main Hand"],
    [INVSLOT_OFFHAND] = L["Off Hand"],
    [INVSLOT_RANGED] = L["Ranged"],
}

local function getEquipmentLabel(frame)
    local slotId = frame:GetID()
    local itemLink = GetInventoryItemLink("player", slotId)
    if itemLink then
        local itemName = GetItemInfo(itemLink)
        -- GetItemInfo may return nil if item isn't cached yet, fallback to link
        return itemName or itemLink
    end
    -- Empty slot - return localized slot name
    return SLOT_NAMES[slotId] or L["Empty"]
end

local function draggableProxy(button, label)
    local vtable = nodes.proxyButton({ target = button, label = label })
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

local function renderPaperDoll(builder)
    builder:beginStop("equipment")
    builder:pushContext("equipment", L["Equipment"])
    for _, slot in ipairs({ PaperDollItemsFrame:GetChildren() }) do
        local captured = slot
        builder:addItem(
            ControlId.forObject(captured),
            draggableProxy(captured, function()
                return getEquipmentLabel(captured)
            end)
        )
    end
    builder:popContext()

    -- Stats: one stop, each category a labeled row -- up and down switch
    -- categories, left and right walk a category's stats.
    builder:beginStop("stats")
    builder:pushContext("stats", L["Stats"])
    for _, categoryKey in ipairs(PAPERDOLL_STATCATEGORY_DEFAULTORDER) do
        local category = PAPERDOLL_STATCATEGORIES[categoryKey]
        local categoryFrame = _G["CharacterStatsPaneCategory" .. category.id]
        if categoryFrame ~= nil then
            local label = categoryFrame.NameText:GetText()
            if label ~= nil and label ~= "" then
                builder:pushContext("statCategory:" .. category.id, label)
                builder:startRow()
                local children = { categoryFrame:GetChildren() }
                for i = 2, #children do
                    local stat = children[i]
                    if stat:IsShown() then
                        local captured = stat
                        builder:addItem(
                            ControlId.forObject(captured),
                            nodes.proxyButton({
                                target = captured,
                                label = function()
                                    return tostring(captured.Label:GetText())
                                        .. " "
                                        .. tostring(captured.Value:GetText())
                                end,
                            })
                        )
                    end
                end
                builder:endRow()
                builder:popContext()
            end
        end
    end
    builder:popContext()
end

------------------------------------------------------------
-- Reputation (tab 3). Mists uses the Cata ReputationFrame: ReputationBar[i]
-- is itself a clickable row Button shown via the ReputationListScrollFrame
-- FauxScrollFrame, with a ReputationDetailFrame side panel.
------------------------------------------------------------

local REPUTATION_ROWS = NUM_FACTIONS_DISPLAYED or 15

local function reputationButtons()
    local rows = {}
    for i = 1, REPUTATION_ROWS do
        local frame = _G["ReputationBar" .. i]
        if frame ~= nil then
            tinsert(rows, frame)
        end
    end
    return rows
end

local function factionLabel(index)
    local name, _, standingID, _, _, _, _, _, isHeader, _, hasRep = GetFactionInfo(index)
    if name == nil then
        return nil
    end
    local label = name
    if not isHeader or hasRep then
        local standing = _G["FACTION_STANDING_LABEL" .. (standingID or 0)]
        if standing ~= nil then
            label = label .. " - " .. standing
        end
    end
    return label
end

local function emitFaction(builder, index, helpers)
    local name, _, _, _, _, _, _, _, isHeader = GetFactionInfo(index)
    if name == nil then
        return
    end

    local announcements = {
        {
            text = function()
                return factionLabel(index)
            end,
            kind = kinds.label,
        },
    }

    local target = helpers.target
    if isHeader then
        tinsert(announcements, {
            text = function()
                local _, _, _, _, _, _, _, _, _, isCollapsed = GetFactionInfo(index)
                return isCollapsed and L["Collapsed"] or L["Expanded"]
            end,
            kind = kinds.value,
        })
        -- Headers toggle through their expand button, a named child of the row.
        target = function()
            local row = helpers.target()
            if row == nil then
                return nil
            end
            return _G[row:GetName() .. "ExpandOrCollapseButton"]
        end
    end

    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = target },
        },
        onFocus = helpers.onFocus,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    })
end

local function reputationEntryId(index)
    local name, _, _, _, _, _, _, _, isHeader = GetFactionInfo(index)
    if name ~= nil then
        return ControlId.structural((isHeader and "repHeader:" or "faction:") .. name)
    end
    return ControlId.structural("faction:" .. index)
end

local function renderReputation(builder)
    builder:beginStop("factions")
    nodes.hybridScrollList(builder, {
        scrollFrame = ReputationListScrollFrame,
        key = "factions",
        label = L["Reputation"],
        count = GetNumFactions,
        rowHeight = REPUTATIONFRAME_FACTIONHEIGHT,
        buttons = reputationButtons,
        id = reputationEntryId,
        emit = emitFaction,
    })

    local detail = ReputationDetailFrame
    if detail ~= nil and detail:IsShown() then
        builder:beginStop("repDetail")
        builder:pushContext(
            "repDetail",
            ReputationDetailFactionName ~= nil and ReputationDetailFactionName:GetText() or ""
        )
        builder:addItem(
            ControlId.structural("repDescription"),
            nodes.text({
                label = function()
                    return ReputationDetailFactionDescription ~= nil
                            and ReputationDetailFactionDescription:GetText()
                        or nil
                end,
            })
        )
        if ReputationDetailAtWarCheckbox ~= nil and ReputationDetailAtWarCheckbox:IsShown() then
            builder:addItem(
                ControlId.forObject(ReputationDetailAtWarCheckbox),
                nodes.proxyCheckButton({ target = ReputationDetailAtWarCheckbox, label = L["At War"] })
            )
        end
        if ReputationDetailInactiveCheckbox ~= nil and ReputationDetailInactiveCheckbox:IsShown() then
            builder:addItem(
                ControlId.forObject(ReputationDetailInactiveCheckbox),
                nodes.proxyCheckButton({
                    target = ReputationDetailInactiveCheckbox,
                    label = MOVE_TO_INACTIVE or "Move to Inactive",
                })
            )
        end
        if ReputationDetailMainScreenCheckbox ~= nil and ReputationDetailMainScreenCheckbox:IsShown() then
            builder:addItem(
                ControlId.forObject(ReputationDetailMainScreenCheckbox),
                nodes.proxyCheckButton({ target = ReputationDetailMainScreenCheckbox, label = L["Watched"] })
            )
        end
        if ReputationDetailCloseButton ~= nil then
            builder:addItem(
                ControlId.forObject(ReputationDetailCloseButton),
                nodes.proxyButton({ target = ReputationDetailCloseButton, label = CLOSE or L["Close"] })
            )
        end
        builder:popContext()
    end
end

------------------------------------------------------------
-- Currency (tab 4): TokenFrameContainer is a native HybridScrollFrame over
-- the currency list.
------------------------------------------------------------

local function emitCurrency(builder, index, helpers)
    local _, isHeader = GetCurrencyListInfo(index)

    local announcements = {
        {
            text = function()
                local name, header, _, _, _, count = GetCurrencyListInfo(index)
                if name == nil then
                    return nil
                end
                if header or count == nil then
                    return name
                end
                return name .. " " .. count
            end,
            kind = kinds.label,
        },
    }
    if isHeader then
        tinsert(announcements, {
            text = function()
                local _, _, isExpanded = GetCurrencyListInfo(index)
                return isExpanded and L["Expanded"] or L["Collapsed"]
            end,
            kind = kinds.value,
        })
    end

    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    })
end

local function renderCurrency(builder)
    builder:beginStop("currency")
    nodes.hybridScrollList(builder, {
        scrollFrame = TokenFrameContainer,
        key = "currency",
        label = CharacterFrameTab4 ~= nil and CharacterFrameTab4:GetText() or L["Currency"],
        count = GetCurrencyListSize,
        emit = emitCurrency,
    })
end

local function render(builder, screen)
    if CharacterFrame == nil or not CharacterFrame:IsShown() then
        return
    end
    builder:pushContext("character", L["Character"])

    local selectedTab = CharacterFrame.selectedTab
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, 4 do
        local tab = _G["CharacterFrameTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            tinsert(vtable.announcements, {
                text = function()
                    if CharacterFrame.selectedTab == tabIndex then
                        return L["selected"]
                    end
                    return nil
                end,
                kind = kinds.selected,
            })
            builder:addItem(ControlId.forObject(tab), vtable)
        end
    end
    builder:endRow()
    builder:popContext()

    if selectedTab == 1 then
        renderPaperDoll(builder)
    elseif selectedTab == 3 then
        renderReputation(builder)
    elseif selectedTab == 4 then
        renderCurrency(builder)
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "character",
    frameName = "CharacterFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
