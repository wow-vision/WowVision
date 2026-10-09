local talentTree = {}
WowVision.talentTree = talentTree

local L = WowVision:getLocale()
local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- Talent trees built on the shared talent frame (TalentFrameBaseMixin),
-- the modern talent UI of retail and WoW: Forever. Used by Forever's class
-- talents (camelot/talents.lua); written against the shared frame only, so
-- a retail talent window can use it too, though none does yet and nothing
-- here is tested on retail.
-- Each talent reads its name, rank, and state; Enter buys a rank (a choice
-- node opens its options), Backspace refunds one. The talents read row by
-- row as drawn, each row a context; a tree holding several groups (the
-- class tree's three specializations) reads a stop per group. The pages
-- around the tree are the callers' own.

-- A count of points, singular for one: "1 Point", "5 Points".
function talentTree.pointsText(count)
    return count .. " " .. (count == 1 and L["Point"] or L["Points"])
end

local function isSelectionNode(nodeInfo)
    return nodeInfo.type == Enum.TraitNodeType.Selection or nodeInfo.type == Enum.TraitNodeType.SubTreeSelection
end

-- An entry's name: a sub tree's, or the talent's (its override name, else
-- its spell's).
local function entryName(talentFrame, entryID)
    local entryInfo = talentFrame:GetAndCacheEntryInfo(entryID)
    if entryInfo == nil then
        return ""
    end
    if entryInfo.subTreeID ~= nil then
        local subTreeInfo = talentFrame:GetAndCacheSubTreeInfo(entryInfo.subTreeID)
        if subTreeInfo ~= nil and subTreeInfo.name ~= nil then
            return subTreeInfo.name
        end
    end
    if entryInfo.definitionID ~= nil then
        local definitionInfo = talentFrame:GetAndCacheDefinitionInfo(entryInfo.definitionID)
        return TalentUtil.GetTalentNameFromInfo(definitionInfo)
    end
    return ""
end

-- A choice node with nothing chosen shows a question mark; it reads its
-- options instead. Any other talent reads its name (empty only for the
-- moment its spell is still loading).
local function talentName(button)
    local name = button:GetName()
    if (name ~= nil and name ~= "") or not isSelectionNode(button:GetNodeInfo()) then
        return name or ""
    end
    local options = {}
    for _, entryID in ipairs(button:GetNodeInfo().entryIDs) do
        tinsert(options, entryName(button:GetTalentFrame(), entryID))
    end
    return L["Choice"] .. ": " .. table.concat(options, ", ")
end

local function rankText(button)
    local nodeInfo = button:GetNodeInfo()
    if FlagsUtil.IsSet(nodeInfo.flags, Enum.TraitNodeFlag.HideMaxRank) then
        return L["rank"] .. " " .. nodeInfo.currentRank
    end
    return L["rank"] .. " " .. nodeInfo.currentRank .. "/" .. nodeInfo.maxRanks
end

-- The talents a locked talent waits for, as a sighted player follows the
-- arrows into it, read by the arrow's type as the game decides
-- availability: each unlearned required talent ("A, B"), and the
-- sufficient ones while none of them is learned ("C or D", any one will
-- do). Arrows that are only drawn require nothing.
local function requirementsText(talentFrame, nodeID)
    local edgeTypes = Enum.TraitEdgeType
    local required = {}
    local sufficient = {}
    local sufficientMet = false
    for edge in talentFrame.edgePool:EnumerateActive() do
        local edgeInfo = edge:GetEdgeInfo()
        local start = edge:GetStartButton()
        if edgeInfo ~= nil and edgeInfo.targetNode == nodeID and start ~= nil then
            if edgeInfo.type == edgeTypes.RequiredForAvailability then
                if not edgeInfo.isActive then
                    tinsert(required, talentName(start))
                end
            elseif edgeInfo.type == edgeTypes.SufficientForAvailability then
                if edgeInfo.isActive then
                    sufficientMet = true
                else
                    tinsert(sufficient, talentName(start))
                end
            end
        end
    end
    local parts = table.concat(required, ", ")
    if not sufficientMet and #sufficient > 0 then
        parts = nodes.joinLabel(parts, table.concat(sufficient, " " .. L["or"] .. " "))
    end
    if parts == "" then
        return nil
    end
    return L["Requires %s"]:format(parts)
end

local function stripColors(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- The points a locked talent still waits for, in the game's own words: the
-- largest unmet spend condition on its node, the line its tooltip shows
-- (the classic tiers: so many points in the specialization). Asked of the
-- game directly, so the talent frame's condition cache keeps its colors.
local function pointsRequirementText(button)
    local talentFrame = button:GetTalentFrame()
    local nodeInfo = button:GetNodeInfo()
    local configID = talentFrame:GetConfigID()
    if configID == nil or nodeInfo.conditionIDs == nil then
        return nil
    end
    -- Forever's frames name the tree for the condition text; retail's have
    -- no such method and its condition text needs no name.
    local treeName = nil
    if talentFrame.GetTraitTreeName ~= nil then
        treeName = talentFrame:GetTraitTreeName(talentFrame:GetTalentTreeID(), nodeInfo.groupIDs)
    end
    local best = nil
    for _, conditionID in ipairs(nodeInfo.conditionIDs) do
        local condInfo = C_Traits.GetConditionInfo(configID, conditionID, true, treeName)
        if
            condInfo ~= nil
            and condInfo.isGate
            and not condInfo.isMet
            and condInfo.tooltipText ~= nil
            and (best == nil or (condInfo.spentAmountRequired or 0) > (best.spentAmountRequired or 0))
        then
            best = condInfo
        end
    end
    return best ~= nil and stripColors(best.tooltipText) or nil
end

-- The state the button's border shows: available (buyable now), locked
-- (with the points and the talents it waits for), or invalid (a refund
-- broke what depends on it). Partly bought, maxed, and unaffordable read
-- through the rank alone. A row that already says its gate leaves the
-- points out.
local function stateText(button, rowGated)
    local states = TalentButtonUtil.BaseVisualState
    local state = button:GetVisualState()
    if state == states.Selectable then
        return L["Available"]
    elseif state == states.Gated or state == states.Locked then
        return nodes.joinLabel(
            L["Locked"],
            not rowGated and pointsRequirementText(button) or nil,
            requirementsText(button:GetTalentFrame(), button:GetNodeID())
        )
    elseif state == states.RefundInvalid or state == states.DisplayError then
        return L["Invalid"]
    end
    return nil
end

-- What the full search marked the talent with: a match of the searched
-- text, or, after the not-on-action-bar search, the game's name for that
-- search.
local function searchText(button)
    local matchType = button:GetSearchMatchType()
    if matchType == nil then
        return nil
    end
    if SpellSearchUtil.IsActionBarMatchType(matchType) then
        return TALENT_FRAME_SEARCH_NOT_ON_ACTIONBAR
    end
    return L["Search Match"]
end

local function talentLabel(button, rowGated)
    return nodes.joinLabel(talentName(button), rankText(button), stateText(button, rowGated), searchText(button))
end

-- A talent display's own tooltip (rank, description, next rank, cost, the
-- click instructions, and what blocks it), built into the reader's tooltip
-- the way the display builds it on hover: for a talent and for a choice
-- node's option alike.
local function displayTooltip(tooltip, display)
    display:AddTooltipTitle(tooltip)
    display:AddTooltipInfo(tooltip)
    display:AddTooltipDescription(tooltip)
    display:AddTooltipCost(tooltip)
    if display:ShouldShowTooltipInstructions() then
        display:AddTooltipInstructions(tooltip)
    end
    if display:ShouldShowTooltipErrors() then
        display:AddTooltipErrors(tooltip)
    end
    tooltip:Show()
end

-- A choice node's own tooltip is only its errors (its options carry the
-- rest), so it reads the chosen option.
local function talentTooltip(tooltip, button)
    local nodeInfo = button:GetNodeInfo()
    if not isSelectionNode(nodeInfo) then
        displayTooltip(tooltip, button)
        return
    end
    GameTooltip_SetTitle(tooltip, talentName(button))
    local entryID = button:GetSelectedEntryID()
    if entryID ~= nil then
        tooltip:AppendInfo("GetTraitEntry", entryID, nodeInfo.currentRank)
    end
    if button:ShouldShowTooltipErrors() then
        button:AddTooltipErrors(tooltip)
    end
    tooltip:Show()
end

-- Choice nodes whose options box WowVision opened, by talent frame: the
-- box stays up while its list is open and closes when the tree reads again.
local openedChoices = setmetatable({}, { __mode = "k" })

local function closeOpenedChoices(talentFrame)
    local button = openedChoices[talentFrame]
    if button == nil then
        return
    end
    openedChoices[talentFrame] = nil
    if talentFrame:AreSelectionsOpen(button) then
        button:ClearSelections()
    end
end

-- The options of a choice node: the game's own options box (the one the
-- mouse opens by hovering the node), its option buttons clicked for real,
-- so the game decides what a click does: left picks the option or buys a
-- rank of the chosen one, right unlearns it. The list stays open after a
-- pick, as the box does; Escape returns to the tree.
local function renderChoices(builder, talentFrame, nodeID)
    local button = talentFrame:GetTalentButtonByNodeID(nodeID)
    if button == nil or not button:IsShown() or not talentFrame:AreSelectionsOpen(button) then
        return
    end
    builder:pushContext("choices", talentName(button))
    for index, option in ipairs(talentFrame.SelectionChoiceFrame.selectionFrameArray) do
        local captured = option
        local vtable = nodes.proxyButton({
            target = captured,
            hover = false,
            label = function()
                return captured:GetName()
            end,
            clickLabels = { left = L["Learn"], right = L["Unlearn"] },
            tooltip = {
                type = "Game",
                mode = "immediate",
                populate = function(tooltip)
                    displayTooltip(tooltip, captured)
                end,
            },
        })
        if vtable ~= nil then
            tinsert(vtable.announcements, {
                text = function()
                    return captured.isCurrentSelection and L["Selected"] or nil
                end,
                kind = kinds.selected,
                live = "focus",
            })
            tinsert(vtable.announcements, {
                text = function()
                    return not captured:IsChoiceAvailable() and L["Locked"] or nil
                end,
                kind = kinds.value,
            })
            builder:addItem(ControlId.structural("choice:" .. (captured:GetEntryID() or index)), vtable)
        end
    end
    builder:popContext()
end

-- A talent: Enter buys a rank (a choice node opens its options instead),
-- Backspace refunds one, drag picks up an active ability. The button is
-- pooled and found by its node on every read and press. The context menu
-- adds the shift-click's link in chat.
local function talentNode(talentFrame, nodeID, rowGated)
    local function find()
        local button = talentFrame:GetTalentButtonByNodeID(nodeID)
        if button ~= nil and button:IsShown() and button:GetNodeInfo() ~= nil then
            return button
        end
        return nil
    end
    local button = find()
    if button == nil then
        return nil
    end
    local choice = isSelectionNode(button:GetNodeInfo())
    local vtable = nodes.proxyFoundButton({
        find = find,
        label = function(button)
            return talentLabel(button, rowGated)
        end,
        tooltip = talentTooltip,
        drag = true,
        -- A choice node's plain left click does nothing (it only links);
        -- its options open on hover, so Enter opens them here instead.
        leftClick = not choice,
        clickLabels = { left = L["Learn"], right = L["Unlearn"] },
    })
    if choice then
        vtable.controlType = graph.controlTypes.dropdown
        vtable.onActivate = function()
            local current = find()
            local host = WowVision.graphHost
            local stack = host:focusedStack()
            if current == nil or stack == nil then
                return
            end
            current:ShowSelections()
            if not talentFrame:AreSelectionsOpen(current) then
                return
            end
            openedChoices[talentFrame] = current
            host:push(stack, {
                key = "choices",
                render = function(builder)
                    renderChoices(builder, talentFrame, nodeID)
                end,
            })
        end
    end
    local clickActions = vtable.contextActions
    vtable.contextActions = function(add)
        clickActions(add)
        local current = find()
        if current == nil then
            return
        end
        local spellID = current:GetSpellID()
        if spellID ~= nil then
            add({
                label = L["Link %s in Chat"]:format(talentName(current)),
                onActivate = function()
                    WowVision.chatLinks.shiftClick({ kind = "link", text = C_Spell.GetSpellLink(spellID) })
                end,
            })
        end
    end
    return vtable
end

-- The rows a spend gate holds back ("spend 8 more points"), keyed by the
-- gate's first talent, as the gate drawn beside that talent says.
local function gateTexts(talentFrame)
    local texts = {}
    local treeInfo = talentFrame:GetTreeInfo()
    if treeInfo == nil or treeInfo.gates == nil then
        return texts
    end
    for _, gate in ipairs(treeInfo.gates) do
        local condInfo = talentFrame:GetAndCacheCondInfo(gate.conditionID)
        if condInfo ~= nil and not condInfo.isMet and condInfo.spentAmountRequired ~= nil then
            texts[gate.topLeftNodeID] = TALENT_FRAME_GATE_TOOLTIP_FORMAT:format(condInfo.spentAmountRequired)
        end
    end
    return texts
end

local function visibleButtons(talentFrame)
    local buttons = {}
    for button in talentFrame:EnumerateAllTalentButtons() do
        local nodeInfo = button:GetNodeInfo()
        if nodeInfo ~= nil and nodeInfo.isVisible and button:IsShown() then
            tinsert(buttons, button)
        end
    end
    return buttons
end

-- Talents grouped into the rows they are drawn in, top to bottom, each left
-- to right.
local function talentRows(buttons)
    local rows = {}
    local byY = {}
    for _, button in ipairs(buttons) do
        local posY = button:GetNodeInfo().posY
        local row = byY[posY]
        if row == nil then
            row = { posY = posY, buttons = {} }
            byY[posY] = row
            tinsert(rows, row)
        end
        tinsert(row.buttons, button)
    end
    table.sort(rows, function(a, b)
        return a.posY < b.posY
    end)
    for _, row in ipairs(rows) do
        table.sort(row.buttons, function(a, b)
            return a:GetNodeInfo().posX < b:GetNodeInfo().posX
        end)
    end
    return rows
end

-- A context per row (with its gate, if any) over the row's talents, so up
-- and down move between rows and left and right along one.
local function emitRows(builder, talentFrame, buttons, gates)
    for rowIndex, row in ipairs(talentRows(buttons)) do
        local gateText = nil
        for _, button in ipairs(row.buttons) do
            gateText = gateText or gates[button:GetNodeID()]
        end
        builder:pushContext("row:" .. row.posY, nodes.joinLabel(L["Row"] .. " " .. rowIndex, gateText))
        builder:startRow()
        for _, button in ipairs(row.buttons) do
            local nodeID = button:GetNodeID()
            builder:addItem(
                ControlId.structural("talent:" .. nodeID),
                talentNode(talentFrame, nodeID, gateText ~= nil)
            )
        end
        builder:endRow()
        builder:popContext()
    end
end

-- The tree's talents under a context (Talents unless the caller names it;
-- label = false leaves it out, for a page already named so). Without groups
-- they are one stop. With groups ({ { id, label } }, in reading order),
-- each group is a stop of its own under its label, holding the talents
-- whose node belongs to it; talents of no listed group follow in a stop of
-- their own.
-- config: { key, label?, groups? }
function talentTree.renderTalents(builder, talentFrame, config)
    closeOpenedChoices(talentFrame)
    local key = config.key
    local buttons = visibleButtons(talentFrame)
    local gates = gateTexts(talentFrame)
    local wrapped = config.label ~= false
    if wrapped then
        builder:pushContext(key, config.label or L["Talents"])
    end
    if #buttons == 0 then
        builder:beginStop(key)
        builder:addItem(ControlId.structural(key .. ":empty"), nodes.text({ label = L["Empty"] }))
    elseif config.groups == nil then
        builder:beginStop(key)
        emitRows(builder, talentFrame, buttons, gates)
    else
        local listed = {}
        for _, group in ipairs(config.groups) do
            listed[group.id] = {}
        end
        local others = {}
        for _, button in ipairs(buttons) do
            local bucket = others
            for _, groupID in ipairs(button:GetNodeInfo().groupIDs or {}) do
                if listed[groupID] ~= nil then
                    bucket = listed[groupID]
                    break
                end
            end
            tinsert(bucket, button)
        end
        for _, group in ipairs(config.groups) do
            if #listed[group.id] > 0 then
                builder:beginStop(key .. ":" .. group.id)
                builder:pushContext("group:" .. group.id, group.label)
                emitRows(builder, talentFrame, listed[group.id], gates)
                builder:popContext()
            end
        end
        if #others > 0 then
            builder:beginStop(key .. ":others")
            emitRows(builder, talentFrame, others, gates)
        end
    end
    if wrapped then
        builder:popContext()
    end
end

-- Apply (saying when changes wait for it, or why it cannot apply them),
-- then undo (shown while changes wait), then the caller's reset control.
-- One stop; none while all three are hidden (inspecting another player).
function talentTree.renderCommitButtons(builder, talentFrame, resetNode)
    local applyButton = talentFrame.ApplyButton
    local apply = nodes.proxyButton({ target = applyButton, hover = false })
    if apply ~= nil then
        tinsert(apply.announcements, {
            text = function()
                if not applyButton:IsEnabled() then
                    return applyButton.disabledTooltip
                end
                return talentFrame:HasAnyConfigChanges() and L["Unsaved Changes"] or nil
            end,
            kind = kinds.value,
        })
    end
    local undo = nodes.proxyButton({ target = talentFrame.UndoButton, hover = false, label = L["Undo Changes"] })
    if apply == nil and undo == nil and resetNode == nil then
        return
    end
    builder:beginStop("commit")
    builder:startRow()
    builder:addItem(ControlId.forObject(applyButton), apply)
    builder:addItem(ControlId.forObject(talentFrame.UndoButton), undo)
    builder:addItem(ControlId.forObject(talentFrame.ResetButton), resetNode)
    builder:endRow()
end
