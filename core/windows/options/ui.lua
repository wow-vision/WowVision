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

-- Row tooltips come from the initializer's own data (GetTooltip), read as
-- Text tooltips like the old screen: the panel's SettingsTooltip frame
-- populates asynchronously, so reading it live races the populate.
local function rowTooltip(elementData)
    local ok, tip = pcall(function()
        if elementData.GetTooltip ~= nil then
            local value = elementData:GetTooltip()
            if type(value) == "function" then
                value = value()
            end
            return value
        end
        local d = dataOf(elementData)
        return d ~= nil and d.tooltip or nil
    end)
    if ok and type(tip) == "string" and tip ~= "" then
        return { type = "Text", text = tip }
    end
    return nil
end

local function textTooltip(text)
    if type(text) == "string" and text ~= "" then
        return { type = "Text", text = text }
    end
    return nil
end

local function textOf(region)
    if region == nil then
        return nil
    end
    if region.GetText ~= nil then
        local text = region:GetText()
        if text ~= nil and text ~= "" then
            return text
        end
    end
    -- Buttons of these templates keep their text on a Text fontstring child.
    if region.Text ~= nil and region.Text.GetText ~= nil then
        return region.Text:GetText()
    end
    return nil
end

local function frameChildText(helpers, childKey)
    return function()
        local rowFrame = helpers.target()
        local child = rowFrame ~= nil and rowFrame[childKey] or nil
        return textOf(child)
    end
end

-- The clickable expander of a section row, whatever the client names it.
local function expanderOf(rowFrame)
    if rowFrame == nil then
        return nil
    end
    if rowFrame.Button ~= nil then
        return rowFrame.Button
    end
    if rowFrame.ExpandButton ~= nil then
        return rowFrame.ExpandButton
    end
    if rowFrame.GetObjectType ~= nil and rowFrame:GetObjectType() == "Button" then
        return rowFrame
    end
    return nil
end

-- Header rows: name from data when the shape matches, else read from the row
-- frame (headers sit adjacent to visible rows, so their frames are usually
-- materialized by the time they are announced), else just "Separator".
local function headerNode(helpers, dataName, frameChildKey)
    return nodes.text({
        label = function()
            local name = dataName()
            if name == nil or name == "" then
                name = frameChildText(helpers, frameChildKey)()
            end
            if name ~= nil and name ~= "" then
                return name .. ", " .. L["Separator"]
            end
            return L["Separator"]
        end,
    })
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
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
        tooltip = rowTooltip(elementData),
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
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
        tooltip = rowTooltip(elementData),
    }
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
    vtable.onUnfocus = helpers.onUnfocus
    vtable.tooltipFrame = helpers.target
    vtable.tooltip = rowTooltip(elementData)
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
    vtable.onUnfocus = helpers.onUnfocus
    vtable.tooltipFrame = helpers.target
    vtable.tooltip = rowTooltip(elementData)
    return vtable
end

-- ---- category list ----

local function emitCategoryRow(builder, elementData, index, helpers)
    local template = elementData.frameTemplate
    if template == "SettingsCategoryListSpacerTemplate" then
        return -- purely visual gap; nothing to hear
    end
    if template == "SettingsCategoryListHeaderTemplate" then
        builder:addItem(
            helpers.id,
            headerNode(helpers, function()
                return categoryName(elementData)
            end, "Label")
        )
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
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    })
end

-- ---- settings list: one emitter per row template ----

local settingEmitters = {}

settingEmitters["SettingsListSectionHeaderTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(
        helpers.id,
        headerNode(helpers, function()
            return settingName(elementData)
        end, "Title")
    )
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
    local cbNode = checkboxNode(elementData, helpers, d.cbLabel or settingName(elementData), cbSetting)
    cbNode.tooltip = textTooltip(d.cbTooltip) or cbNode.tooltip
    builder:addItem(helpers.id, cbNode)
    if cbSetting ~= nil and settingValue(cbSetting) and d.sliderSetting ~= nil then
        local slider = sliderNode(elementData, helpers, d.sliderLabel, d.sliderSetting, d.sliderOptions)
        slider.tooltip = textTooltip(d.sliderTooltip) or slider.tooltip
        builder:addItem(ControlId.structural("srow:" .. index .. ":slider"), slider)
    end
    builder:endRow()
end

settingEmitters["SettingsCheckboxDropdownControlTemplate"] = function(builder, elementData, index, helpers)
    local d = dataOf(elementData)
    local cbSetting = d.setting or d.cbSetting
    builder:startRow()
    local cbNode = checkboxNode(elementData, helpers, d.cbLabel or settingName(elementData), cbSetting)
    cbNode.tooltip = textTooltip(d.cbTooltip) or cbNode.tooltip
    builder:addItem(helpers.id, cbNode)
    local dropdownSetting = d.dropdownSetting or d.dropDownSetting
    if cbSetting ~= nil and settingValue(cbSetting) and dropdownSetting ~= nil then
        local vtable = dropdownNode(elementData, helpers, d.dropDownLabel or d.dropdownLabel, dropdownSetting)
        vtable.tooltip = textTooltip(d.tooltip or d.dropDownTooltip) or vtable.tooltip
        builder:addItem(ControlId.structural("srow:" .. index .. ":dropdown"), vtable)
    end
    builder:endRow()
end

-- Keybinding sections: the header expands/collapses via a real click; the
-- binding rows arrive as their own KeyBindingFrameBindingTemplate elements
-- once expanded.
settingEmitters["SettingsKeybindingSectionTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(helpers.id, {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    local name = settingName(elementData)
                    if name == nil then
                        name = textOf(expanderOf(helpers.target()))
                    end
                    return name
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
                    return expanderOf(helpers.target())
                end,
            },
        },
        onFocus = helpers.onFocus,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
    })
end

settingEmitters["SettingsExpandableSectionTemplate"] = settingEmitters["SettingsKeybindingSectionTemplate"]

-- One binding row: two slot buttons, each reading "action name, current key"
-- and starting Blizzard's rebind on Enter.
settingEmitters["KeyBindingFrameBindingTemplate"] = function(builder, elementData, index, helpers)
    builder:startRow()
    for slot = 1, 2 do
        local slotIndex = slot
        builder:addItem(ControlId.structural("srow:" .. index .. ":bind" .. slotIndex), {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        local rowFrame = helpers.target()
                        local name = settingName(elementData)
                        if
                            name == nil
                            and rowFrame ~= nil
                            and rowFrame.Label ~= nil
                            and rowFrame.Label.GetText ~= nil
                        then
                            name = rowFrame.Label:GetText()
                        end
                        local button = rowFrame ~= nil and rowFrame.Buttons ~= nil and rowFrame.Buttons[slotIndex]
                            or nil
                        local slotText = textOf(button)
                        if name ~= nil and slotText ~= nil then
                            return name .. ", " .. slotText
                        end
                        return name or slotText
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
                        local rowFrame = helpers.target()
                        return rowFrame ~= nil and rowFrame.Buttons ~= nil and rowFrame.Buttons[slotIndex] or nil
                    end,
                },
            },
            onFocus = helpers.onFocus,
            onUnfocus = helpers.onUnfocus,
            tooltipFrame = helpers.target,
        })
    end
    builder:endRow()
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
            key = "categories",
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
            key = "settings",
            label = title or L["Options"],
            emit = emitSettingRow,
        })
        if list.Header ~= nil and list.Header.DefaultsButton ~= nil then
            builder:beginStop("defaults")
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
