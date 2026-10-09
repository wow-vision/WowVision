local module = WowVision.base.windows.legacy
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local talentTree = WowVision.talentTree
local spellSearch = WowVision.spellSearch

-- The tree page: three Legacy talent trees (professions, adventure,
-- progression) bought with Legacy points. The tree buttons pick the tree
-- and read the points spent in each; the points line reads what is left to
-- spend; then the talent search, the talents row by row as drawn (top to
-- bottom, left to right), and the apply, undo, and reset buttons. Buying
-- is staged as on the class talent tree: nothing is learned until Apply.
-- The talents themselves are the shared talent tree (retail/talentTree.lua).

-- The points spent in a tree, staged changes included as the tree's own
-- counter shows them; asked of every tree, not only the one shown.
local function pointsSpent(treeID)
    local configID = C_Traits.GetConfigIDByTreeID(treeID)
    if configID == nil then
        return nil
    end
    local currencies = C_Traits.GetTreeCurrencyInfo(configID, treeID, false)
    local currencyInfo = currencies ~= nil and currencies[1] or nil
    return currencyInfo ~= nil and currencyInfo.spentInTree or nil
end

-- The three tree buttons, each with the points spent in it: a click shows
-- that tree. They switch what the page below shows, so they read as a row,
-- like tabs.
local function renderTreeButtons(builder, panel)
    local entries = {}
    for _, button in ipairs(panel.treeButtons) do
        local captured = button
        local treeData = captured.treeData
        local vtable = nodes.proxyButton({
            target = captured,
            hover = false,
            label = function()
                local spent = pointsSpent(treeData.treeID)
                return nodes.joinLabel(treeData.name, spent ~= nil and talentTree.pointsText(spent))
            end,
        })
        if vtable ~= nil then
            tinsert(vtable.announcements, {
                text = function()
                    return captured:GetChecked() and L["selected"] or nil
                end,
                kind = kinds.selected,
            })
            tinsert(entries, { id = ControlId.structural("tree:" .. treeData.treeID), vtable = vtable })
        end
    end
    if #entries == 0 then
        return
    end
    builder:beginStop("trees")
    builder:pushContext("trees", L["Trees"])
    builder:startRow()
    for _, entry in ipairs(entries) do
        builder:addItem(entry.id, entry.vtable)
    end
    builder:endRow()
    builder:popContext()
end

-- The points left to spend (the summary's own line) with the season's cap
-- (its hover tooltip). The points spent read on the tree buttons.
local function renderPoints(builder, page)
    local summary = page.LegacyTreePointSummary
    builder:beginStop("points")
    builder:addItem(
        ControlId.structural("available"),
        nodes.text({
            label = function()
                local currencyInfo = LegacySystem.GetCurrencyInfo()
                local cap = nil
                if currencyInfo ~= nil and currencyInfo.maxQuantity ~= nil then
                    cap = LEGACY_POINTS_SEASONAL_CAP:format(currencyInfo.maxQuantity)
                end
                return nodes.joinLabel(nodes.shownText(summary.AvailablePointsLabel), cap)
            end,
        })
    )
end

function module.renderTree(builder, page)
    local panel = page.LegacyTreeTraitPanel
    renderTreeButtons(builder, page.LegacyTreeSelectionPanel)
    renderPoints(builder, page)
    builder:beginStop("search")
    builder:addItem(ControlId.structural("search"), spellSearch.node(panel.SearchBox))
    talentTree.renderTalents(builder, panel, { key = "talents" })
    -- Reset refunds the whole tree, staged until Apply like the rest.
    talentTree.renderCommitButtons(
        builder,
        panel,
        nodes.proxyButton({ target = panel.ResetButton, hover = false, label = L["Reset Tree"] })
    )
end
