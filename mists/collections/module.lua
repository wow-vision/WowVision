local module = WowVision.base.windows:createModule("collections")
local L = module.L
module:setLabel(L["Collections"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The collections journal: the tab bar, then the selected tab's body. Each
-- implemented tab registers itself with module.addTab (the mount journal in
-- its file); a selected tab without one reads "not implemented yet".
--
-- The tab bar and the selected tab below are Mists' bottom tabs. Clients with
-- a different journal replace module.renderTabBar and module.getSelectedTab
-- from their own folder (WoW: Forever: camelot/collections/tabs.lua).

module.tabs = {}

-- Register a tab body. config: { frame = content frame name, render =
-- function(builder) }. The body renders only while its frame is visible.
function module.addTab(tabIndex, config)
    module.tabs[tabIndex] = config
end

function module.getSelectedTab()
    return CollectionsJournal.selectedTab
end

-- Bottom tabs CollectionsJournalTab1..numTabs, as real clicks.
function module.renderTabBar(builder)
    for i = 1, CollectionsJournal.numTabs do
        local tab = _G["CollectionsJournalTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            tinsert(vtable.announcements, {
                text = function()
                    if module.getSelectedTab() == tabIndex then
                        return L["selected"]
                    end
                    return nil
                end,
                kind = kinds.selected,
            })
            builder:addItem(ControlId.forObject(tab), vtable)
        end
    end
end

local function render(builder, screen)
    if CollectionsJournal == nil or not CollectionsJournal:IsShown() then
        return
    end
    builder:pushContext("collections", L["Collections"])

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    module.renderTabBar(builder)
    builder:endRow()
    builder:popContext()

    local tab = module.tabs[module.getSelectedTab() or 0]
    local content = tab ~= nil and _G[tab.frame] or nil
    if content ~= nil and content:IsVisible() then
        tab.render(builder)
    else
        builder:beginStop("unimplemented")
        builder:addItem(ControlId.structural("unimplemented"), nodes.text({ label = L["Not implemented yet"] }))
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "collections",
    frameName = "CollectionsJournal",
    graphScreen = { render = render },
})
