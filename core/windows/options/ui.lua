local module = WowVision.base.windows.options
local L = module.L
local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The game options window (SettingsPanel) on the graph framework: the pilot
-- for piloting ScrollBoxes. Category and setting rows come from the two
-- ScrollBox data providers; labels and values read from the row DATA (their
-- Setting objects), since offscreen row frames cannot be read at announce
-- time; secure clicks resolve the materialized row frame lazily. Value writes
-- go through setting:SetValue like the old screen did; checkbox and button
-- rows genuinely click the real child buttons.

-- ---- data readers (defensive: initializer shapes vary by client) ----

local function dataOf(elementData)
    if elementData == nil then
        return nil
    end
    return elementData.data or elementData
end

local function settingName(elementData)
    local ok, name = pcall(function()
        local d = dataOf(elementData)
        if d.name ~= nil then
            return d.name
        end
        if d.setting ~= nil and type(d.setting.GetName) == "function" then
            return d.setting:GetName()
        end
        return elementData.name
    end)
    if ok and name ~= nil then
        return tostring(name)
    end
    return nil
end

local function categoryName(elementData)
    local ok, name = pcall(function()
        local d = dataOf(elementData)
        if d.category ~= nil then
            if type(d.category.GetName) == "function" then
                return d.category:GetName()
            end
            if d.category.name ~= nil then
                return d.category.name
            end
        end
        if d.name ~= nil then
            return d.name
        end
        return elementData.name
    end)
    if ok and name ~= nil then
        return tostring(name)
    end
    return nil
end

local function settingObject(elementData)
    local d = dataOf(elementData)
    if d ~= nil and d.setting ~= nil then
        return d.setting
    end
    return nil
end

local function settingValue(setting)
    local ok, value = pcall(setting.GetValue, setting)
    if ok then
        return value
    end
    return nil
end

-- Normalized { value, label } entries from a dropdown initializer's options
-- (a list, or a function returning a container with GetData).
local function optionsList(elementData)
    local result = {}
    pcall(function()
        local d = dataOf(elementData)
        local options = d.options
        if type(options) == "function" then
            options = options()
        end
        if options == nil then
            return
        end
        local entries = options
        if type(options.GetData) == "function" then
            entries = options:GetData()
        end
        for _, entry in ipairs(entries or {}) do
            tinsert(result, {
                value = entry.value,
                label = entry.label or entry.text or tostring(entry.value),
            })
        end
    end)
    return result
end

-- ---- row node builders ----

local function textRow(builder, id, label)
    if label ~= nil and label ~= "" then
        builder:addItem(id, nodes.text({ label = label }))
    end
end

local function unimplementedRow(builder, id, template)
    builder:addItem(id, nodes.text({ label = "Setting type " .. tostring(template) .. " not implemented" }))
end

-- A checkbox backed by a Setting: value speaks from the setting, Enter
-- genuinely clicks the row's real Checkbox button.
local function checkboxNode(elementData, helpers, label, setting, childKey)
    local valueText = nil
    if setting ~= nil then
        valueText = function()
            local value = settingValue(setting)
            if value == nil then
                return nil
            end
            return value and L["Checked"] or L["Unchecked"]
        end
    end
    return {
        controlType = graph.controlTypes.toggle,
        announcements = {
            { text = label, kind = kinds.label },
            { text = valueText, kind = kinds.value, live = "focus" },
        },
        bindings = {
            {
                binding = "leftClick",
                type = "Click",
                emulatedKey = "LeftButton",
                target = function()
                    local rowFrame = helpers.target()
                    if rowFrame == nil then
                        return nil
                    end
                    return rowFrame[childKey or "Checkbox"] or rowFrame
                end,
            },
        },
        onFocus = helpers.onFocus,
    }
end

-- A button within a row, secure-clicked. Labels may read from the frame:
-- these are secondary nodes reached by moving within an already-scrolled row.
local function rowButtonNode(elementData, helpers, label, childKey)
    return {
        controlType = graph.controlTypes.button,
        announcements = { { text = label, kind = kinds.label } },
        bindings = {
            {
                binding = "leftClick",
                type = "Click",
                emulatedKey = "LeftButton",
                target = function()
                    local rowFrame = helpers.target()
                    if rowFrame == nil then
                        return nil
                    end
                    if childKey ~= nil then
                        return rowFrame[childKey] or rowFrame
                    end
                    return rowFrame
                end,
            },
        },
        onFocus = helpers.onFocus,
    }
end

local function frameChildText(helpers, childKey)
    return function()
        local rowFrame = helpers.target()
        local child = rowFrame ~= nil and rowFrame[childKey] or nil
        if child ~= nil and child.GetText ~= nil then
            return child:GetText()
        end
        return nil
    end
end

local function sliderNode(elementData, helpers, label, setting, options)
    options = options or {}
    local minValue = options.minValue
    local maxValue = options.maxValue
    local step = 1
    if minValue ~= nil and maxValue ~= nil and options.steps ~= nil and options.steps > 0 then
        step = (maxValue - minValue) / options.steps
    end
    local vtable = nodes.number({
        label = label,
        get = function()
            return settingValue(setting)
        end,
        set = function(value)
            if minValue ~= nil and value < minValue then
                value = minValue
            end
            if maxValue ~= nil and value > maxValue then
                value = maxValue
            end
            setting:SetValue(value)
        end,
        step = step,
    })
    vtable.onFocus = helpers.onFocus
    return vtable
end

local function dropdownNode(elementData, helpers, label, setting)
    local vtable = nodes.choice({
        label = label,
        get = function()
            return settingValue(setting)
        end,
        set = function(value)
            setting:SetValue(value)
        end,
        choices = function()
            return optionsList(elementData)
        end,
    })
    vtable.onFocus = helpers.onFocus
    return vtable
end

-- ---- category list ----

local function emitCategoryRow(builder, elementData, index, helpers)
    local template = elementData.frameTemplate
    if template == "SettingsCategoryListSpacerTemplate" then
        return
    end
    if template == "SettingsCategoryListHeaderTemplate" then
        textRow(builder, helpers.id, categoryName(elementData))
        return
    end
    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return categoryName(elementData)
                end,
                kind = kinds.label,
            },
        },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
        },
        onFocus = helpers.onFocus,
    })
end

-- ---- settings list: one emitter per row template ----

local settingEmitters = {}

settingEmitters["SettingsListSectionHeaderTemplate"] = function(builder, elementData, index, helpers)
    textRow(builder, helpers.id, settingName(elementData))
end

settingEmitters["SettingsListSearchCategoryTemplate"] = settingEmitters["SettingsListSectionHeaderTemplate"]

settingEmitters["SettingsCheckboxControlTemplate"] = function(builder, elementData, index, helpers)
    local label = function()
        return settingName(elementData)
    end
    builder:addItem(helpers.id, checkboxNode(elementData, helpers, label, settingObject(elementData)))
end

settingEmitters["SettingsCheckboxWithButtonControlTemplate"] = function(builder, elementData, index, helpers)
    local label = function()
        return settingName(elementData)
    end
    builder:startRow()
    builder:addItem(helpers.id, checkboxNode(elementData, helpers, label, settingObject(elementData)))
    builder:addItem(
        ControlId.structural("srow:" .. index .. ":button"),
        rowButtonNode(elementData, helpers, frameChildText(helpers, "Button"), "Button")
    )
    builder:endRow()
end

settingEmitters["SettingsSliderControlTemplate"] = function(builder, elementData, index, helpers)
    local setting = settingObject(elementData)
    if setting == nil then
        unimplementedRow(builder, helpers.id, elementData.frameTemplate)
        return
    end
    local d = dataOf(elementData)
    builder:addItem(
        helpers.id,
        sliderNode(elementData, helpers, function()
            return settingName(elementData)
        end, setting, d.options)
    )
end

settingEmitters["SettingsDropdownControlTemplate"] = function(builder, elementData, index, helpers)
    local setting = settingObject(elementData)
    if setting == nil then
        unimplementedRow(builder, helpers.id, elementData.frameTemplate)
        return
    end
    builder:addItem(
        helpers.id,
        dropdownNode(elementData, helpers, function()
            return settingName(elementData)
        end, setting)
    )
end

settingEmitters["AutoLootDropdownControlTemplate"] = settingEmitters["SettingsDropdownControlTemplate"]
settingEmitters["SettingsLanguageTemplate"] = settingEmitters["SettingsDropdownControlTemplate"]
settingEmitters["SettingsAudioLocaleTemplate"] = settingEmitters["SettingsDropdownControlTemplate"]

settingEmitters["SettingButtonControlTemplate"] = function(builder, elementData, index, helpers)
    local label = function()
        return settingName(elementData) or frameChildText(helpers, "Button")()
    end
    builder:addItem(helpers.id, rowButtonNode(elementData, helpers, label, "Button"))
end

settingEmitters["VoiceTestMicrophoneTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(
        helpers.id,
        rowButtonNode(elementData, helpers, function()
            return settingName(elementData)
        end, "ToggleTest")
    )
end

settingEmitters["VoicePushToTalkTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(
        helpers.id,
        rowButtonNode(elementData, helpers, function()
            return settingName(elementData)
        end, "PushToTalkKeybindButton")
    )
end

settingEmitters["SettingsLanguageRestartNeededTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(
        helpers.id,
        rowButtonNode(elementData, helpers, function()
            return settingName(elementData)
        end, "RestartNeeded")
    )
end

settingEmitters["SettingsCheckboxSliderControlTemplate"] = function(builder, elementData, index, helpers)
    local d = dataOf(elementData)
    local cbSetting = d.setting or d.cbSetting
    builder:startRow()
    builder:addItem(helpers.id, checkboxNode(elementData, helpers, d.cbLabel or settingName(elementData), cbSetting))
    if cbSetting ~= nil and settingValue(cbSetting) and d.sliderSetting ~= nil then
        builder:addItem(
            ControlId.structural("srow:" .. index .. ":slider"),
            sliderNode(elementData, helpers, d.sliderLabel, d.sliderSetting, d.sliderOptions)
        )
    end
    builder:endRow()
end

settingEmitters["SettingsCheckboxDropdownControlTemplate"] = function(builder, elementData, index, helpers)
    local d = dataOf(elementData)
    local cbSetting = d.setting or d.cbSetting
    builder:startRow()
    builder:addItem(helpers.id, checkboxNode(elementData, helpers, d.cbLabel or settingName(elementData), cbSetting))
    local dropdownSetting = d.dropdownSetting or d.dropDownSetting
    if cbSetting ~= nil and settingValue(cbSetting) and dropdownSetting ~= nil then
        local vtable = dropdownNode(elementData, helpers, d.dropDownLabel or d.dropdownLabel, dropdownSetting)
        builder:addItem(ControlId.structural("srow:" .. index .. ":dropdown"), vtable)
    end
    builder:endRow()
end

-- Keybinding sections: the header expands/collapses via a real click; the
-- binding rows are subframes of the section, so they can only enumerate once
-- the section frame is materialized (focus the header first).
settingEmitters["SettingsKeybindingSectionTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(
        helpers.id,
        rowButtonNode(elementData, helpers, function()
            return settingName(elementData) or frameChildText(helpers, "Button")()
        end, "Button")
    )
    local rowFrame = helpers.target()
    if rowFrame == nil or rowFrame.Controls == nil then
        return
    end
    for controlIndex, control in ipairs(rowFrame.Controls) do
        if control:IsShown() and control.Label ~= nil and control.Buttons ~= nil then
            builder:pushContext(control.Label:GetText() or "")
            builder:startRow()
            for buttonIndex, bindingButton in ipairs(control.Buttons) do
                local captured = bindingButton
                builder:addItem(ControlId.structural("kb:" .. index .. ":" .. controlIndex .. ":" .. buttonIndex), {
                    controlType = graph.controlTypes.button,
                    announcements = {
                        {
                            text = function()
                                return captured.GetText ~= nil and captured:GetText() or nil
                            end,
                            kind = kinds.label,
                        },
                    },
                    bindings = {
                        {
                            binding = "leftClick",
                            type = "Click",
                            emulatedKey = "LeftButton",
                            target = function()
                                return captured
                            end,
                        },
                    },
                    onFocus = helpers.onFocus,
                })
            end
            builder:endRow()
            builder:popContext()
        end
    end
end

local function emitSettingRow(builder, elementData, index, helpers)
    local emitter = settingEmitters[elementData.frameTemplate]
    if emitter ~= nil then
        local ok, err = pcall(emitter, builder, elementData, index, helpers)
        if not ok then
            geterrorhandler()(err)
        end
        return
    end
    unimplementedRow(builder, helpers.id, elementData.frameTemplate)
end

-- ---- the window ----

local function render(builder, screen)
    local frame = SettingsPanel
    if frame == nil or not frame:IsShown() then
        return
    end

    builder:beginStop("tabs")
    builder:pushContext(L["Tabs"])
    builder:startRow()
    builder:addItem(ControlId.forObject(frame.GameTab), nodes.proxyButton({ target = frame.GameTab }))
    builder:addItem(ControlId.forObject(frame.AddOnsTab), nodes.proxyButton({ target = frame.AddOnsTab }))
    builder:endRow()
    builder:popContext()

    if frame.SearchBox ~= nil then
        builder:beginStop("search")
        builder:addItem(
            ControlId.structural("search"),
            nodes.textInput({
                label = L["Search"],
                get = function()
                    return frame.SearchBox:GetText()
                end,
                set = function(text)
                    frame.SearchBox:SetText(text or "")
                end,
            })
        )
    end

    if frame.CategoryList ~= nil and frame.CategoryList:IsShown() then
        builder:beginStop("categories")
        nodes.scrollBoxList(builder, {
            scrollBox = frame.CategoryList.ScrollBox,
            label = L["Categories"],
            emit = emitCategoryRow,
        })
    end

    local list = frame.GetSettingsList ~= nil and frame:GetSettingsList() or nil
    if list ~= nil and list:IsShown() then
        builder:beginStop("settings")
        local title = nil
        pcall(function()
            title = list.Header.Title:GetText()
        end)
        nodes.scrollBoxList(builder, {
            scrollBox = list.ScrollBox,
            label = title or L["Options"],
            emit = emitSettingRow,
        })
        if list.Header ~= nil and list.Header.DefaultsButton ~= nil then
            builder:addItem(
                ControlId.forObject(list.Header.DefaultsButton),
                nodes.proxyButton({ target = list.Header.DefaultsButton })
            )
        end
    end
end

local function onKeybindRebindSuccess()
    WowVision:speak("Rebinding successful")
end

function module:onEnable()
    if SettingsPanel ~= nil then
        WowVision.UIHost:hookFunc(SettingsPanel, "OnKeybindRebindSuccess", onKeybindRebindSuccess)
    end
end

function module:onDisable()
    if SettingsPanel ~= nil then
        WowVision.UIHost:unhookFunc(SettingsPanel, "OnKeybindRebindSuccess", onKeybindRebindSuccess)
    end
end

module:registerWindow({
    type = "FrameWindow",
    name = "options",
    frameName = "SettingsPanel",
    graphScreen = { render = render },
})
