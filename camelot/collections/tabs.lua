local module = WowVision.base.windows.collections
local L = module.L

local graph = WowVision.graph
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The WoW: Forever journal's tab bar: icon-only side tabs in
-- CollectionsJournal.TabContainer.Tabs, named by their tooltip text.

-- Each tab's content frame and the game key binding that opens the journal
-- on it, by tab id.
local TABS = {
    { frame = "MountJournal", command = "TOGGLECOLLECTIONSMOUNTJOURNAL" },
    { frame = "PetJournal", command = "TOGGLECOLLECTIONSPETJOURNAL" },
    { frame = "ToyBox", command = "TOGGLECOLLECTIONSTOYBOX" },
    { frame = "HeirloomsJournal", command = "TOGGLECOLLECTIONSHEIRLOOM" },
    { frame = "WardrobeCollectionFrame", command = "TOGGLECOLLECTIONSWARDROBE" },
}

-- The selected tab is read from which tab's content is shown: when the
-- remembered tab is hidden (tabs for empty collections hide while "only
-- show collected" is on), the journal shows the first valid tab but never
-- records it (Blizzard hands the journal instead of its tab container to the
-- side-tab override), so TabContainer.selectedTab goes stale.
function module.getSelectedTab()
    for index, tab in ipairs(TABS) do
        local frame = _G[tab.frame]
        if frame ~= nil and frame:IsShown() then
            return index
        end
    end
    return CollectionsJournal.TabContainer.selectedTab
end

-- The side tabs switch on mouse UP through a custom handler, not OnClick, so
-- a secure click cannot reach them, and running that handler as the addon
-- would show the new tab's content tainted (the toy buttons then refuse to
-- use toys). Enter instead runs the game binding that opens the journal on
-- that tab, securely, as its own key would.
function module.renderTabBar(builder)
    for _, tab in ipairs(CollectionsJournal.TabContainer.Tabs) do
        local tabIndex = tab:GetID()
        local command = TABS[tabIndex] ~= nil and TABS[tabIndex].command or nil
        if tab:IsShown() and command ~= nil then
            local captured = tab
            builder:addItem(ControlId.forObject(captured), {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return captured.tooltipText
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            return module.getSelectedTab() == tabIndex and L["selected"] or nil
                        end,
                        kind = kinds.selected,
                    },
                },
                bindings = {
                    { binding = "leftClick", type = "Command", command = command },
                },
            })
        end
    end
end
