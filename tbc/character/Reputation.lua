local char = WowVision.tbc.character
local L = char.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The TBC reputation tab: a Faux list whose row pool reports GetID 0, so
-- indices map through the pool table plus scroll offset. Faction rows are
-- StatusBars driven by OnMouseUp -- not clickable Buttons -- so activation
-- calls ReputationBar_OnClick directly, exactly as the old screen did.
-- Header rows click their overlay ReputationHeader button. Labels are
-- data-first from GetFactionInfo with normalized progress numbers.

local NUM_FACTIONS_DISPLAYED = 15

local reputationBarIndices = {}
local function reputationButtons()
    local rows = {}
    for i = 1, NUM_FACTIONS_DISPLAYED do
        local frame = _G["ReputationBar" .. i]
        if frame ~= nil then
            reputationBarIndices[frame] = i
            tinsert(rows, frame)
        end
    end
    return rows
end

local function reputationIndexOf(button)
    local offset = FauxScrollFrame_GetOffset(ReputationListScrollFrame) or 0
    return (reputationBarIndices[button] or 0) + offset
end

local function factionLabel(index)
    local name, _, standingID, barMin, barMax, barValue, _, _, isHeader, _, hasRep = GetFactionInfo(index)
    if name == nil then
        return nil
    end
    local label = name
    if not isHeader or hasRep then
        local standing = _G["FACTION_STANDING_LABEL" .. (standingID or 0)]
        if standing ~= nil then
            label = label .. " - " .. standing
        end
        if barMax ~= nil and barMin ~= nil and barValue ~= nil then
            label = label .. " " .. (barValue - barMin) .. " / " .. (barMax - barMin)
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

    if isHeader then
        tinsert(announcements, {
            text = function()
                local _, _, _, _, _, _, _, _, _, isCollapsed = GetFactionInfo(index)
                return isCollapsed and L["Collapsed"] or L["Expanded"]
            end,
            kind = kinds.value,
        })
        builder:addItem(helpers.id, {
            controlType = graph.controlTypes.button,
            announcements = announcements,
            bindings = {
                {
                    binding = "leftClick",
                    type = "Click",
                    emulatedKey = "LeftButton",
                    -- Headers click their overlay button, found by pool slot.
                    target = function()
                        local bar = helpers.target()
                        local slot = bar ~= nil and reputationBarIndices[bar] or nil
                        return slot ~= nil and _G["ReputationHeader" .. slot] or nil
                    end,
                },
            },
            onFocus = helpers.onFocus,
            onFocusTick = helpers.onFocusTick,
            onUnfocus = helpers.onUnfocus,
        })
        return
    end

    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = announcements,
        -- StatusBar rows respond to OnMouseUp, not clicks; call the handler.
        onActivate = function()
            local bar = helpers.target()
            if bar ~= nil then
                ReputationBar_OnClick(bar)
            end
        end,
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
    })
end

local function reputationEntryId(index)
    local name, _, _, _, _, _, _, _, isHeader = GetFactionInfo(index)
    if name ~= nil then
        return ControlId.structural((isHeader and "repHeader:" or "faction:") .. name)
    end
    return ControlId.structural("faction:" .. index)
end

function char.renderReputation(builder)
    builder:beginStop("factions")
    nodes.hybridScrollList(builder, {
        scrollFrame = ReputationListScrollFrame,
        key = "factions",
        label = L["Reputation"],
        count = GetNumFactions,
        rowHeight = REPUTATIONFRAME_FACTIONHEIGHT,
        buttons = reputationButtons,
        indexOf = reputationIndexOf,
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
