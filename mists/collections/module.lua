local module = WowVision.base.windows:createModule("collections")
local L = module.L
module:setLabel(L["Collections"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The collections journal: tabs, then the selected tab's body. Tab 1 is the
-- mount journal (module.renderMountJournal, in its file); other tabs are
-- not implemented yet.

-- Each tab's content frame, by tab id.
local TAB_FRAMES = {
    "MountJournal",
    "PetJournal",
    "ToyBox",
    "HeirloomsJournal",
    "WardrobeCollectionFrame",
    "WarbandSceneJournal",
}

-- The selected tab index. Mists keeps it on the journal. On Forever it is
-- read from which tab's content is shown: when the remembered tab is
-- hidden (tabs for empty collections hide while the "only show collected"
-- option is on), the journal shows the first valid tab but never records
-- it (Blizzard passes the journal instead of its tab container to the
-- side-tab override), so the container's selectedTab goes stale.
local function getSelectedTab()
    if CollectionsJournal.numTabs ~= nil then
        return CollectionsJournal.selectedTab
    end
    for index, frameName in ipairs(TAB_FRAMES) do
        local frame = _G[frameName]
        if frame ~= nil and frame:IsShown() then
            return index
        end
    end
    local container = CollectionsJournal.TabContainer
    return container ~= nil and container.selectedTab or nil
end

local function selectedAnnouncement(tabIndex)
    return {
        text = function()
            if getSelectedTab() == tabIndex then
                return L["selected"]
            end
            return nil
        end,
        kind = kinds.selected,
    }
end

-- Mists: bottom tabs, CollectionsJournalTab1..numTabs, real clicks.
local function renderBottomTabs(builder)
    for i = 1, CollectionsJournal.numTabs do
        local tab = _G["CollectionsJournalTab" .. i]
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            tinsert(vtable.announcements, selectedAnnouncement(i))
            builder:addItem(ControlId.forObject(tab), vtable)
        end
    end
end

-- WoW: Forever: icon-only side tabs in TabContainer.Tabs. They carry their
-- name as tooltip text, and they switch on mouse UP through a custom
-- handler, not OnClick, so a click would do nothing: activation runs the
-- tab's own OnMouseUp as a left-button release inside the tab.
local function renderSideTabs(builder)
    local container = CollectionsJournal.TabContainer
    if container == nil or container.Tabs == nil then
        return
    end
    for _, tab in ipairs(container.Tabs) do
        if tab:IsShown() then
            local captured = tab
            local tabIndex = tab:GetID()
            local vtable = nodes.proxyButton({
                target = captured,
                hover = false,
                label = function()
                    local data = CollectionsJournal.TABS_DATA ~= nil and CollectionsJournal.TABS_DATA[tabIndex] or nil
                    return captured.tooltipText or (data ~= nil and data.title) or nil
                end,
            })
            local function activate()
                local script = captured:GetScript("OnMouseUp")
                if script ~= nil then
                    script(captured, "LeftButton", true)
                end
            end
            vtable.bindings = {
                { binding = "leftClick", type = "Function", func = activate },
            }
            vtable.contextActions = nil
            tinsert(vtable.announcements, selectedAnnouncement(tabIndex))
            builder:addItem(ControlId.forObject(captured), vtable)
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
    if CollectionsJournal.numTabs ~= nil then
        renderBottomTabs(builder)
    else
        renderSideTabs(builder)
    end
    builder:endRow()
    builder:popContext()

    local tab = getSelectedTab()
    if tab == 1 and MountJournal ~= nil and MountJournal:IsShown() and MountJournal:IsVisible() then
        module.renderMountJournal(builder)
    else
        builder:beginStop("unimplemented")
        builder:addItem(ControlId.structural("unimplemented"), nodes.text({ label = "Not implemented yet" }))
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "collections",
    frameName = "CollectionsJournal",
    graphScreen = { render = render },
})
