local macros = WowVision.base.windows:createModule("macros")
local L = macros.L
macros:setLabel(L["Macros"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The macro window: tabs, the macro list (synthetic buttons selecting via
-- MacroFrame:SelectMacro), the pickup button, the macro text edit box, and
-- the action buttons. The create/edit popup replaces the whole body while
-- shown: name edit box, Okay, Cancel.

local function headerText(region)
    if type(region) == "table" and region.GetText ~= nil then
        return region:GetText()
    end
    return region
end

local function renderPopup(builder)
    local box = MacroPopupFrame.BorderBox
    builder:pushContext("macroPopup", L["Macros"])

    builder:beginStop("name")
    builder:addItem(
        ControlId.structural("name"),
        nodes.proxyEditBox({
            editBox = box.IconSelectorEditBox,
            fixAutoFocus = true,
            label = function()
                return headerText(MacroPopupFrame.editBoxHeaderText)
            end,
        })
    )
    builder:beginStop("okay")
    builder:addItem(ControlId.forObject(box.OkayButton), nodes.proxyButton({ target = box.OkayButton }))
    builder:beginStop("cancel")
    builder:addItem(ControlId.forObject(box.CancelButton), nodes.proxyButton({ target = box.CancelButton }))

    builder:popContext()
end

local function renderMain(builder)
    builder:pushContext("macros", L["Macros"])

    local selectedTab = PanelTemplates_GetSelectedTab(MacroFrame)
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, 2 do
        local tab = _G["MacroFrameTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            tinsert(vtable.announcements, {
                text = function()
                    if PanelTemplates_GetSelectedTab(MacroFrame) == tabIndex then
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

    builder:beginStop("list")
    builder:pushContext("macroList", L["Macros"])
    local macroCounts = { GetNumMacros() }
    local macroOffset = 120 * (selectedTab - 1)
    local count = macroCounts[selectedTab] or 0
    for i = 1, count do
        local index = i
        local vtable = nodes.button({
            label = function()
                return (GetMacroInfo(index + macroOffset))
            end,
            onActivate = function()
                MacroFrame:SelectMacro(index, true)
            end,
        })
        tinsert(vtable.announcements, {
            text = function()
                if MacroFrame.MacroSelector:GetSelectedIndex() == index then
                    return L["selected"]
                end
                return nil
            end,
            kind = kinds.selected,
        })
        builder:addItem(ControlId.structural("macro:" .. i), vtable)
    end
    if count == 0 then
        builder:addItem(ControlId.structural("macroListEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    if MacroFrame.SelectedMacroButton ~= nil and MacroFrame.SelectedMacroButton:IsShown() then
        builder:beginStop("pickup")
        local pickup = nodes.proxyButton({
            target = MacroFrame.SelectedMacroButton,
            label = L["Drag to pick up macro"],
        })
        tinsert(pickup.bindings, {
            binding = "drag",
            type = "Function",
            func = function()
                local button = MacroFrame.SelectedMacroButton
                local script = button:GetScript("OnDragStart")
                if script ~= nil then
                    script(button)
                end
            end,
        })
        builder:addItem(ControlId.forObject(MacroFrame.SelectedMacroButton), pickup)
    end

    builder:beginStop("edit")
    builder:addItem(ControlId.forObject(MacroEditButton), nodes.proxyButton({ target = MacroEditButton }))

    builder:beginStop("text")
    builder:addItem(
        ControlId.structural("macroText"),
        nodes.proxyEditBox({ editBox = MacroFrameText, label = L["Macro Text"] })
    )

    for _, button in ipairs({ MacroCancelButton, MacroSaveButton, MacroDeleteButton, MacroNewButton }) do
        if button ~= nil and button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end

    builder:popContext()
end

local function render(builder, screen)
    if MacroFrame == nil or not MacroFrame:IsShown() then
        return
    end

    local popup = MacroPopupFrame ~= nil and MacroPopupFrame:IsShown()
    -- On mode flips, steal keyboard focus back from the box Blizzard
    -- auto-focuses (the old mount hooks).
    if screen._macroPopup ~= popup then
        screen._macroPopup = popup
        if popup then
            MacroPopupFrame.BorderBox.IconSelectorEditBox:ClearFocus()
        else
            MacroFrameText:ClearFocus()
        end
    end

    if popup then
        renderPopup(builder)
    else
        renderMain(builder)
    end
end

macros:registerWindow({
    type = "FrameWindow",
    name = "MacroFrame",
    frameName = "MacroFrame",
    graphScreen = { render = render },
})
