local macros = WowVision.base.windows:createModule("macros")
local L = macros.L
macros:setLabel(L["Macros"])
local gen = macros:hasUI()

gen:Element("macros", function(props)
    if props.forcePopup or MacroPopupFrame:IsShown() then
        return { "macros/PopupPanel" }
    else
        return { "macros/MainPanel" }
    end
end)

local function MainPanel_Mount(self, props)
    --When the popup panel closes, the macro text field is focused which is not desired
    MacroFrameText:ClearFocus()
end

gen:Element("macros/MainPanel", function(props)
    return {
        "Panel",
        label = "Macros",
        wrap = true,
        hooks = {
            mount = MainPanel_Mount,
        },
        children = {
            { "macros/MacroTabs" },
            { "macros/MacroList" },
            {
                "ProxyButton",
                frame = MacroFrame.SelectedMacroButton,
                label = L["Drag to pick up macro"],
                draggable = true
            },
            { "ProxyButton", frame = MacroEditButton },
            { "ProxyEditBox", label = "Macro Text", frame = MacroFrameText },
            { "ProxyButton", frame = MacroCancelButton },
            { "ProxyButton", frame = MacroSaveButton },
            { "ProxyButton", frame = MacroDeleteButton },
            { "ProxyButton", frame = MacroNewButton },
        },
    }
end)

gen:Element("macros/MacroTab", function(props)
    local tab = props.tab
    return { "ProxyButton", frame = tab, selected = props.selected }
end)

gen:Element("macros/MacroTabs", function(props)
    local selectedTab = PanelTemplates_GetSelectedTab(MacroFrame)
    return {
        "List",
        direction = "horizontal",
        label = L["Tabs"],
        children = {
            { "macros/MacroTab", tab = MacroFrameTab1, selected = selectedTab == 1 },
            { "macros/MacroTab", tab = MacroFrameTab2, selected = selectedTab == 2 },
        },
    }
end)

function MacroButton_Click(event, source)
    MacroFrame:SelectMacro(source.key, true)
end

gen:Element("macros/MacroList", function(props)
    local tab = PanelTemplates_GetSelectedTab(MacroFrame)
    local macroCounts = { GetNumMacros() }
    local macroOffset = 120 * (tab - 1)
    local startIndex = 1
    local endIndex = startIndex + macroCounts[tab] - 1
    local selectedMacro = MacroFrame.MacroSelector:GetSelectedIndex()
    local result = { "List", label = "Macros", children = {} }
    for i = startIndex, endIndex do
        local name = GetMacroInfo(i + macroOffset)
        tinsert(result.children, {
            "Button",
            label = name,
            selected = selectedMacro == i,
            key = i,
            events = {
                click = MacroButton_Click,
            },
        })
    end
    return result
end)

local function PopupPanel_Mount(self, props)
    MacroPopupFrame.BorderBox.IconSelectorEditBox:ClearFocus()
end

gen:Element("macros/PopupPanel", function(props)
    local box = MacroPopupFrame.BorderBox
    return {
        "Panel",
        label = "create/edit",
        wrap = true,
        hooks = {
            mount = PopupPanel_Mount,
        },
        children = {
            {
                "ProxyEditBox",
                frame = box.IconSelectorEditBox,
                fixAutoFocus = true,
                label = MacroPopupFrame.editBoxHeaderText,
            },
            { "ProxyButton", frame = box.OkayButton },
            { "ProxyButton", frame = box.CancelButton },
        },
    }
end)

macros:registerWindow({
    type = "FrameWindow",
    name = "MacroFrame",
    generated = true,
    rootElement = "macros",
    frameName = "MacroFrame",
})
