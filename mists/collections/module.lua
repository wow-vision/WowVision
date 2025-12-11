local module = WowVision.base.windows:createModule("collections")
local L = module.L
module:setLabel(L["Collections"])
local gen = module:hasUI()

gen:Element("collections", {
    regenerateOn = {
        frameFields = { { "CollectionsJournal", "selectedTab" } },
    },
}, function(props)
    local result = {
        "Panel",
        label = L["Collections"],
        wrap = true,
        children = {
            { "collections/Tabs", frame = CollectionsJournal },
            {"Text",
        text = "Tab: " .. CollectionsJournal.selectedTab
        }
        },
    }
    return result
end)

gen:Element("collections/Tabs", function(props)
    local frame = props.frame
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    for i = 1, frame.numTabs do
        local tab = _G["CollectionsJournalTab" .. i]
        if tab then
            tinsert(result.children, {
                "ProxyButton",
                frame = tab,
                selected = frame.selectedTab == i,
            })
        end
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "collections",
    auto = true,
    generated = true,
    rootElement = "collections",
    frameName = "CollectionsJournal",
})
