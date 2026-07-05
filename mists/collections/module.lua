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

local function render(builder, screen)
    if CollectionsJournal == nil or not CollectionsJournal:IsShown() then
        return
    end
    builder:pushContext("collections", L["Collections"])

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, CollectionsJournal.numTabs do
        local tab = _G["CollectionsJournalTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            tinsert(vtable.announcements, {
                text = function()
                    if CollectionsJournal.selectedTab == tabIndex then
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

    local tab = CollectionsJournal.selectedTab
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
