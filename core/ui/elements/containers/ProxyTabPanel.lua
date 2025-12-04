--This is a virtual component
--Takes a frame prop that has a Tabs subtable, which is an array of Tab objects each with a .Text attribute
-- The frame must also work with PanelTemplates_GetSelectedTab (so most frames with tabs)
-- Do not pass the Tabs subframe as the frame prop or this won't work
local gen = WowVision.ui.generator
local L = LibStub("AceLocale-3.0"):GetLocale("WowVision")

gen:Element("ProxyTabPanel", function(props)
    local selectedTabIndex = PanelTemplates_GetSelectedTab(props.frame)

    local tabsList =
        { "List", displayType = "", label = props.label or L["Tabs"], direction = "horizontal", children = {} }
    for i, v in ipairs(props.frame.Tabs) do
        tinsert(tabsList.children, { "ProxyButton", frame = v, selected = i == selectedTabIndex })
    end

    local mainPanel = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        wrap = props.wrap or false,
        children = {
            tabsList,
        },
    }
    if props.tabs and props.tabs[selectedTabIndex] then
        tinsert(mainPanel.children, props.tabs[selectedTabIndex])
    end

    return mainPanel
end)
