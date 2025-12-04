local module = WowVision.base.windows.options
local L = module.L
local gen = module:hasUI()

local function Options_OnKeybindRebindSuccess(frame)
    WowVision:speak("Rebinding successful")
end

local function Options_Mount(self, props)
    WowVision.UIHost:hookFunc(SettingsPanel, "OnKeybindRebindSuccess", Options_OnKeybindRebindSuccess)
end

gen:Element("options", function(props)
    local frame = SettingsPanel
    local children = { frame:GetChildren() }
    local result = {
        "Panel",
        label = children[2].Text:GetText(),
        wrap = true,
        hooks = {
            mount = Options_Mount,
        },
        children = {
            { "options/TopTabs", frame = frame },
            { "options/Search", frame = frame.SearchBox },
            { "options/CategoryList", frame = frame.CategoryList },
            { "options/SettingsList", frame = frame.Container },
        },
    }
    return result
end)

gen:Element("options/TopTabs", function(props)
    return {
        "List",
        direction = "horizontal",
        label = L["Tabs"],
        children = {
            { "ProxyButton", frame = props.frame.GameTab },
            { "ProxyButton", frame = props.frame.AddOnsTab },
        },
    }
end)

gen:Element("options/Search", function(props)
    local result = {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "ProxyEditBox", frame = props.frame, label = L["Search"] },
        },
    }

    if props.frame:GetText() ~= "" then
        --This check is necessary because the clear button is shown the moment the search edit box is focused and hidden the moment it is unfocused
        --This causes the current implementation of the reconciliation algorithm to get the virtual focus stuck in the search box if tabbing
        tinsert(result.children, {
            "ProxyButton",
            frame = props.frame.clearButton,
            label = L["Clear"],
        })
    end
    return result
end)

local function CategoryList_getElement(self, button)
    if not button:IsShown() then
        return { "Text", displayType = "Separator" }
    end
    local data = button:GetElementData()
    if data.frameTemplate == "SettingsCategoryListSpacerTemplate" then
        return { "Text", displayType = "Separator" }
    elseif data.frameTemplate == "SettingsCategoryListHeaderTemplate" then
        return { "Text", displayType = "Separator", text = button.Label:GetText() }
    end

    return { "ProxyButton", frame = button, label = button.Label:GetText() }
end

gen:Element("options/CategoryList", function(props)
    if not props.frame:IsShown() then
        return nil
    end
    return {
        "ProxyScrollBox",
        label = L["Categories"],
        frame = props.frame.ScrollBox,
        getElement = CategoryList_getElement,
        ordered = false,
    }
end)

local function SettingsList_getElement(self, button)
    currentSetting = button
    local data = button:GetElementData()
    local template = "settings/frames/" .. data.frameTemplate
    if gen:hasElement(template) then
        return { template, frame = button, data = data }
    end
    WowVision.missingSetting = button
    return { "Text", text = "Setting type " .. template .. " not implemented" }
end

gen:Element("options/SettingsList", function(props)
    local frame = SettingsPanel:GetSettingsList()
    if not frame:IsShown() then
        return nil
    end
    local sb = {
        "ProxyScrollBox",
        frame = frame.ScrollBox,
        label = frame.Header.Title:GetText(),
        ordered = false,
        getElement = SettingsList_getElement,
    }

    return {
        "Panel",
        layout = true,
        shouldAnnounce = false,
        children = {
            sb,
            { "ProxyButton", frame = frame.Header.DefaultsButton },
        },
    }
end)

local function getTooltip(frame)
    local tooltip = frame:GetData():GetTooltip()
    if not tooltip or type(tooltip) == "string" then
        return tooltip
    end
    if type(tooltip) == "function" then
        return tooltip()
    end
    error("Unknown tooltip type")
end

gen:Element("settings/frames/SettingsCheckboxControlTemplate", function(props)
    return {
        "ProxyCheckButton",
        frame = props.frame.Checkbox,
        label = props.frame.Text:GetText(),
        tooltip = getTooltip(props.frame),
        useGameTooltip = false,
    }
end)

gen:Element("settings/frames/SettingsListSectionHeaderTemplate", function(props)
    return { "Text", displayType = "Separator", text = props.frame.Title:GetText() }
end)

gen:Element("settings/frames/SettingsListSearchCategoryTemplate", function(props)
    return { "Text", displayType = "Separator", text = props.frame.Title:GetText() }
end)

gen:Element("settings/frames/SettingsCheckboxWithButtonControlTemplate", function(props)
    return {
        "List",
        layout = true,
        shouldAnnounce = false,
        children = {
            { "settings/frames/SettingsCheckboxControlTemplate", frame = props.frame, data = props.data },
            { "ProxyButton", frame = props.frame.Button },
        },
    }
end)

gen:Element("settings/frames/SettingsDropdownControlTemplate", function(props)
    return {
        "ProxyDropdownButton",
        frame = props.frame.Control.Dropdown,
        label = props.frame.Text:GetText(),
        tooltip = getTooltip(props.frame),
        useGameTooltip = false,
        textIsValue = true,
    }
end)

gen:Element("settings/frames/SettingsSliderControlTemplate", function(props)
    local slider = props.frame.SliderWithSteppers
    if not slider then
        return { "Text", text = "Missing slider" }
    end
    local label = props.frame.Text:GetText()
    local options = props.data.data.options
    if options.minValue then
        label = label .. " " .. L["Minimum"] .. " " .. options.minValue
    end
    if options.maxValue then
        label = label .. " " .. L["Maximum"] .. " " .. options.maxValue
    end

    return {
        "EditBox",
        label = label,
        type = "decimal",
        autoInputOnFocus = false,
        tooltip = getTooltip(props.frame),
        bind = {
            props.frame:GetSetting(),
            getType = "function",
            getName = "GetValue",
            setType = "function",
            setName = "SetValue",
        },
    }
end)

gen:Element("settings/frames/KeyBindingFrameBindingTemplate", function(props)
    if not props.frame:IsShown() then
        return nil
    end
    if not props.frame.Label then
        return nil --Not a real control,
    end
    local result = {
        "List",
        direction = "horizontal",
        label = props.frame.Label:GetText(),
        layout = true,
        children = {},
    }
    for _, v in ipairs(props.frame.Buttons) do
        tinsert(result.children, { "ProxyButton", frame = v })
    end

    return result
end)

gen:Element("settings/frames/SettingsKeybindingSectionTemplate", function(props)
    if not props.frame:IsShown() then
        return nil
    end

    local result = {
        "List",
        label = props.frame.Button.Text:GetText(),
        layout = true,
        children = {
            { "ProxyButton", frame = props.frame.Button, label = L["Expand/Collapse"] },
        },
    }

    for _, v in ipairs(props.frame.Controls) do
        tinsert(result.children, { "settings/frames/KeyBindingFrameBindingTemplate", frame = v })
    end

    return result
end)

gen:Element("settings/frames/AutoLootDropdownControlTemplate", function(props)
    return { "settings/frames/SettingsDropdownControlTemplate", frame = props.frame, data = props.data }
end)

gen:Element("settings/frames/SettingsCheckboxSliderControlTemplate", function(props)
    local data = props.frame:GetData().data
    local checkboxLabel = data.cbLabel
    local checkboxTooltip = data.cbTooltip
    local sliderLabel = data.sliderLabel
    local sliderTooltip = data.sliderTooltip
    local sliderOptions = data.sliderOptions
    local result = {
        "List",
        layout = true,
        shouldAnnounce = false,
        children = {
            {
                "ProxyCheckButton",
                frame = props.frame.Checkbox,
                label = checkboxLabel,
                tooltip = checkboxTooltip,
                useGameTooltip = false,
            },
        },
    }
    if props.frame.Checkbox:GetChecked() then
        if sliderOptions.minValue then
            sliderLabel = sliderLabel .. " " .. L["Minimum"] .. " " .. sliderOptions.minValue
        end
        if sliderOptions.maxValue then
            sliderLabel = sliderLabel .. " " .. L["Maximum"] .. " " .. sliderOptions.maxValue
        end
        tinsert(result.children, {
            "EditBox",
            label = sliderLabel,
            tooltip = sliderTooltip,
            type = "decimal",
            autoInputOnFocus = false,
            bind = {
                props.frame:GetData():GetData().sliderSetting,
                getType = "function",
                getName = "GetValue",
                setType = "function",
                setName = "SetValue",
            },
        })
    end
    return result
end)

gen:Element("settings/frames/SettingsCheckboxDropdownControlTemplate", function(props)
    local options = props.data.data
    local checkboxLabel = options.cbLabel
    local dropdownLabel = options.dropDownLabel
    local result = {
        "List",
        layout = true,
        shouldAnnounce = false,
        children = {
            {
                "ProxyCheckButton",
                frame = props.frame.Checkbox,
                label = options.cbLabel,
                tooltip = options.cbTooltip,
                useGameTooltip = false,
            },
        },
    }
    if props.frame.Checkbox:GetChecked() then
        tinsert(result.children, {
            "ProxyDropdownButton",
            frame = props.frame.Control.Dropdown,
            label = options.dropDownLabel,
            tooltip = options.tooltip,
            useGameTooltip = false,
            textIsValue = true,
        })
    end
    return result
end)

gen:Element("settings/frames/SettingButtonControlTemplate", function(props)
    return { "ProxyButton", frame = props.frame.Button, tooltip = getTooltip(props.frame) }
end)

gen:Element("settings/frames/VoiceTestMicrophoneTemplate", function(props)
    return {
        "ProxyButton",
        frame = props.frame.ToggleTest,
        label = props.frame.Text:GetText(),
        tooltip = getTooltip(props.frame),
    }
end)

gen:Element("settings/frames/VoicePushToTalkTemplate", function(props)
    return {
        "Panel",
        label = props.frame.Text:GetText(),
        layout = true,
        children = {
            {
                "ProxyButton",
                frame = props.frame.PushToTalkKeybindButton,
                tooltip = getTooltip(props.frame),
            },
        },
    }
end)

gen:Element("settings/frames/SettingsLanguageTemplate", function(props)
    return { "settings/frames/SettingsDropdownControlTemplate", frame = props.frame, data = props.data }
end)

gen:Element("settings/frames/SettingsAudioLocaleTemplate", function(props)
    return { "settings/frames/SettingsDropdownControlTemplate", frame = props.frame, data = props.data }
end)

gen:Element("settings/frames/SettingsLanguageRestartNeededTemplate", function(props)
    return {
        "Panel",
        label = props.frame.Text:GetText(),
        layout = true,
        children = {
            { "ProxyButton", frame = props.frame.RestartNeeded },
        },
    }
end)

module:registerWindow({
    name = "options",
    auto = true,
    generated = true,
    rootElement = "options",
    frameName = "SettingsPanel",
})
