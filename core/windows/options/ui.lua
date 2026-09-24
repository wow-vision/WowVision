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
    -- Button rows may carry an empty name (the caption is on the button):
    -- an empty name is no name.
    if ok and name ~= nil and name ~= "" then
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

-- Normalized { value, label } entries from a dropdown's options (a list, or
-- a function returning a container with GetData). Plain dropdown rows keep
-- them at data.options; compound rows at data.dropdownOptions -- the caller
-- passes whichever.
local function optionsList(options)
    local result = {}
    pcall(function()
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
                -- Checkbox entries make the dropdown a multi-select over a
                -- bitmask setting: bit 1 << (value - offset).
                checkbox = Settings ~= nil
                    and Settings.ControlType ~= nil
                    and entry.controlType == Settings.ControlType.Checkbox,
                enumValueOffset = entry.enumValueOffset,
            })
        end
    end)
    return result
end

local function bitIsSet(mask, bitIndex)
    if bit ~= nil and bit.band ~= nil then
        return bit.band(mask, bit.lshift(1, bitIndex)) ~= 0
    end
    return math.floor(mask / (2 ^ bitIndex)) % 2 == 1
end

-- The spoken value of a dropdown: for radio options the picked entry's
-- label; for checkbox options (a bitmask) the labels of every set entry
-- joined as Blizzard joins them, after the initializer's own selection
-- text function when it has one ("All", "None"); the raw value when
-- nothing matches.
local function dropdownValueText(elementData, setting, options)
    return function()
        local value = settingValue(setting)
        if value == nil then
            return nil
        end
        local entries = optionsList(options)
        local multi = false
        for _, entry in ipairs(entries) do
            if entry.checkbox then
                multi = true
                break
            end
        end
        if not multi then
            for _, entry in ipairs(entries) do
                if entry.value == value then
                    return entry.label
                end
            end
            return tostring(value)
        end
        local selected = {}
        local labels = {}
        if type(value) == "number" then
            for _, entry in ipairs(entries) do
                if type(entry.value) == "number" and bitIsSet(value, entry.value - (entry.enumValueOffset or 1)) then
                    tinsert(selected, entry)
                    tinsert(labels, entry.label)
                end
            end
        end
        local custom = elementData ~= nil and elementData.getSelectionTextFunc or nil
        if type(custom) == "function" then
            local ok, text = pcall(custom, selected)
            if ok and text ~= nil and text ~= "" then
                return text
            end
        end
        if #labels == 0 then
            return L["None"]
        end
        return table.concat(labels, LIST_DELIMITER or ", ")
    end
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

-- Social's Discord sign-in row computes its caption, tooltip and enabled
-- state through C_Discord.IsUserOAuthed, which is protected: calling any of
-- them from addon code is ADDON_ACTION_FORBIDDEN (pcall does not stop it),
-- and so is evaluating the modify predicate of the display-name row under
-- it. Blizzard writes the caption onto the button itself, so the sign-in
-- state is read from there and remembered for the child row.
local DISCORD_AUTH_TAG = "SOCIAL_ENABLE_DISCORD_FUNCTIONALITY"
local discordSignedIn = nil

local function isDiscordAuth(elementData)
    local d = elementData ~= nil and dataOf(elementData) or nil
    return d ~= nil and d.newTagID == DISCORD_AUTH_TAG
end

local function readDiscordSignedIn(helpers)
    local caption = frameChildText(helpers, "Button")()
    if caption ~= nil and caption ~= "" then
        discordSignedIn = caption == SOCIAL_DISCORD_DISCONNECT
    end
    return discordSignedIn
end

local function discordAuthTooltip(helpers)
    local text = OPTION_TOOLTIP_SOCIAL_ENABLE_DISCORD_FUNCTIONALITY
    if readDiscordSignedIn(helpers) then
        text = OPTION_TOOLTIP_SOCIAL_DISCONNECT_DISCORD
    end
    return { type = "Text", text = text or "" }
end

-- Whether a row is enabled, per Blizzard's own rule (SettingsControlMixin:
-- IsEnabled): the initializer's modify predicates all hold -- a child
-- setting greys out while its parent checkbox is off. Rows without
-- predicates are always enabled.
local function rowEnabled(elementData)
    if elementData == nil or elementData.EvaluateModifyPredicates == nil then
        return true
    end
    if isDiscordAuth(elementData) then
        return discordSignedIn ~= true
    end
    if isDiscordAuth(elementData.parentInitializer) then
        return discordSignedIn == true
    end
    local ok, enabled = pcall(elementData.EvaluateModifyPredicates, elementData)
    return not ok or enabled ~= false
end

-- Disabled controls are still emitted -- a greyed-out row is still a row
-- the user should find -- and announce their state, live, so toggling the
-- parent speaks the change. `extra` adds a control-specific condition (the
-- compound rows disable their second control while the checkbox is off).
local function disabledPart(elementData, extra)
    return {
        text = function()
            if not rowEnabled(elementData) or (extra ~= nil and not extra()) then
                return L["Disabled"]
            end
            return nil
        end,
        kind = kinds.enabled,
    }
end

-- Disabled synthetic controls refuse interaction, as Blizzard's greyed
-- sliders and dropdowns do, and answer the attempt with "Disabled" so the
-- keypress is not silent; real buttons already ignore clicks while
-- disabled.
local function guardDisabled(vtable, elementData, extra)
    local function enabled()
        return rowEnabled(elementData) and (extra == nil or extra())
    end
    local stateText = vtable.stateText
    vtable.stateText = function(...)
        if not enabled() then
            return L["Disabled"]
        end
        if stateText ~= nil then
            return stateText(...)
        end
        return nil
    end
    local onActivate = vtable.onActivate
    if onActivate ~= nil then
        vtable.onActivate = function(...)
            if enabled() then
                return onActivate(...)
            end
        end
    end
    local onAdjust = vtable.onAdjust
    if onAdjust ~= nil then
        vtable.onAdjust = function(...)
            if enabled() then
                return onAdjust(...)
            end
        end
    end
    return vtable
end

-- A row child reached lazily through the row frame (materialized only
-- while on screen): a parentKey string, a function(rowFrame) -> frame for
-- nested children, or nil for the row itself.
local function childResolver(helpers, child)
    return function()
        local rowFrame = helpers.target()
        if rowFrame == nil then
            return nil
        end
        if type(child) == "function" then
            return child(rowFrame)
        end
        if child == nil then
            return rowFrame
        end
        return rowFrame[child] or rowFrame
    end
end

-- A checkbox backed by a Setting: value speaks from the setting, Enter
-- genuinely clicks the row's real Checkbox button. childKey may be a
-- parentKey or a resolver function (see childResolver).
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
            disabledPart(elementData),
        },
        bindings = {
            {
                binding = "leftClick",
                type = "Click",
                emulatedKey = "LeftButton",
                target = childResolver(helpers, childKey or "Checkbox"),
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
-- `tooltip` overrides the row's own tooltip (see the Discord row).
local function rowButtonNode(elementData, helpers, label, childKey, tooltip)
    return {
        controlType = graph.controlTypes.button,
        announcements = { { text = label, kind = kinds.label }, disabledPart(elementData) },
        bindings = {
            {
                binding = "leftClick",
                type = "Click",
                emulatedKey = "LeftButton",
                target = childResolver(helpers, childKey),
            },
        },
        onFocus = helpers.onFocus,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = helpers.target,
        tooltip = tooltip or rowTooltip(elementData),
    }
end

-- `extraEnabled` is a control-specific enable condition on top of the row's
-- own (a compound row's checkbox), for the slider and dropdown builders.
local function sliderNode(elementData, helpers, label, setting, options, extraEnabled)
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
    tinsert(vtable.announcements, disabledPart(elementData, extraEnabled))
    guardDisabled(vtable, elementData, extraEnabled)
    vtable.onFocus = helpers.onFocus
    vtable.onUnfocus = helpers.onUnfocus
    vtable.tooltipFrame = helpers.target
    vtable.tooltip = rowTooltip(elementData)
    return vtable
end

-- A dropdown row: the label and current pick read from the row DATA (the
-- setting and its options), since the row frame may be offscreen at
-- announce time; Enter opens the row's REAL dropdown menu (the focus
-- lifecycle has scrolled the row into view, so its frame exists), and the
-- dropdown watcher turns the open menu into a navigable screen -- the same
-- path every other dropdown in the game takes. The synthetic choice list
-- remains only as a fallback when no frame is available.
local function dropdownNode(elementData, helpers, label, setting, options, extraEnabled)
    if label == nil and type(setting.GetName) == "function" then
        label = function()
            return setting:GetName()
        end
    end
    local vtable = nodes.choice({
        label = label,
        get = function()
            return settingValue(setting)
        end,
        set = function(value)
            setting:SetValue(value)
        end,
        choices = function()
            return optionsList(options)
        end,
        valueText = dropdownValueText(elementData, setting, options),
    })
    local openChoiceList = vtable.onActivate
    vtable.onActivate = function()
        local rowFrame = helpers.target()
        local dropdown = rowFrame ~= nil and rowFrame.Control ~= nil and rowFrame.Control.Dropdown or nil
        if dropdown ~= nil and dropdown.OpenMenu ~= nil then
            dropdown:OpenMenu()
            return
        end
        openChoiceList()
    end
    tinsert(vtable.announcements, disabledPart(elementData, extraEnabled))
    guardDisabled(vtable, elementData, extraEnabled)
    vtable.onFocus = helpers.onFocus
    vtable.onUnfocus = helpers.onUnfocus
    vtable.tooltipFrame = helpers.target
    vtable.tooltip = rowTooltip(elementData)
    return vtable
end

-- ---- category list ----

local categoryTemplates = {}

categoryTemplates["SettingsCategoryListSpacerTemplate"] = function()
    -- purely visual gap; nothing to hear
end

categoryTemplates["SettingsCategoryListHeaderTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(
        helpers.id,
        headerNode(helpers, function()
            return categoryName(elementData)
        end, "Label")
    )
end

-- Every other row is a category button.
local function categoryButtonRow(builder, elementData, index, helpers)
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

-- Rows holding two controls announce as a bar named for the row, so
-- entering one says there is something to the right: "Click to Move, bar,
-- checkbox, unchecked, 1 of 2". (The announcer drops the leading control's
-- own label when the bar already spoke it.) The cells are ALSO wired
-- vertically, so plain up and down through the settings list walk
-- through the second control instead of skipping it -- a horizontal-only
-- bar proved too easy to miss. Keybinding slot pairs keep the plain bar.
local function beginBar(builder, helpers, label)
    builder:pushContext(tostring(helpers.id.key) .. ":bar", label)
    builder:startRow()
    return {}
end

local function endBar(builder, ids)
    builder:endRow()
    builder:popContext()
    for i = 1, #ids - 1 do
        builder:connect(ids[i], "down", ids[i + 1])
        builder:connect(ids[i + 1], "up", ids[i])
    end
end

local function addBarItem(builder, ids, id, vtable)
    builder:addItem(id, vtable)
    if vtable ~= nil then
        tinsert(ids, id)
    end
end

settingEmitters["SettingsCheckboxWithButtonControlTemplate"] = function(builder, elementData, index, helpers)
    local label = function()
        return settingName(elementData)
    end
    local ids = beginBar(builder, helpers, label)
    addBarItem(builder, ids, helpers.id, checkboxNode(elementData, helpers, label, settingObject(elementData)))
    addBarItem(
        builder,
        ids,
        ControlId.structural("srow:" .. index .. ":button"),
        rowButtonNode(elementData, helpers, frameChildText(helpers, "Button"), "Button")
    )
    endBar(builder, ids)
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
    local d = dataOf(elementData)
    builder:addItem(
        helpers.id,
        dropdownNode(elementData, helpers, function()
            return settingName(elementData)
        end, setting, d.options)
    )
end

settingEmitters["AutoLootDropdownControlTemplate"] = settingEmitters["SettingsDropdownControlTemplate"]
settingEmitters["SettingsLanguageTemplate"] = settingEmitters["SettingsDropdownControlTemplate"]
settingEmitters["SettingsAudioLocaleTemplate"] = settingEmitters["SettingsDropdownControlTemplate"]

-- A button row: the row's name plus the button's caption ("Cooldown
-- Manager, Open Edit Mode"), or the caption alone when the row has no
-- name (Blizzard registers several that way). The caption lives in the
-- row data as text or a function, so it reads even before the row frame
-- exists; the frame's button text is the last resort.
-- Social's Discord sign-in row: see discordSignedIn above.
settingEmitters["SettingButtonControlTemplate"] = function(builder, elementData, index, helpers)
    local discordAuth = isDiscordAuth(elementData)
    local label = function()
        local d = dataOf(elementData) or {}
        local caption = d.buttonText
        if type(caption) == "function" then
            if discordAuth then
                caption = nil
            else
                local ok, text = pcall(caption)
                caption = ok and text or nil
            end
        end
        if caption == nil or caption == "" then
            caption = frameChildText(helpers, "Button")()
        end
        local name = settingName(elementData)
        if name ~= nil and caption ~= nil and caption ~= "" and caption ~= name then
            return name .. ", " .. caption
        end
        return name or caption
    end
    local tooltip = discordAuth and discordAuthTooltip(helpers) or nil
    builder:addItem(helpers.id, rowButtonNode(elementData, helpers, label, "Button", tooltip))
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
    local cbLabel = d.cbLabel or settingName(elementData)
    local ids = beginBar(builder, helpers, cbLabel)
    local cbNode = checkboxNode(elementData, helpers, cbLabel, cbSetting)
    cbNode.tooltip = textTooltip(d.cbTooltip) or cbNode.tooltip
    addBarItem(builder, ids, helpers.id, cbNode)
    -- The second control always emits; it reads Disabled while the checkbox
    -- is off, as Blizzard greys it out.
    if d.sliderSetting ~= nil then
        local checked = function()
            return cbSetting ~= nil and settingValue(cbSetting) == true
        end
        local slider = sliderNode(elementData, helpers, d.sliderLabel, d.sliderSetting, d.sliderOptions, checked)
        slider.tooltip = textTooltip(d.sliderTooltip) or slider.tooltip
        addBarItem(builder, ids, ControlId.structural("srow:" .. index .. ":slider"), slider)
    end
    endBar(builder, ids)
end

settingEmitters["SettingsCheckboxDropdownControlTemplate"] = function(builder, elementData, index, helpers)
    local d = dataOf(elementData)
    local cbSetting = d.setting or d.cbSetting
    local cbLabel = d.cbLabel or settingName(elementData)
    local ids = beginBar(builder, helpers, cbLabel)
    local cbNode = checkboxNode(elementData, helpers, cbLabel, cbSetting)
    cbNode.tooltip = textTooltip(d.cbTooltip) or cbNode.tooltip
    addBarItem(builder, ids, helpers.id, cbNode)
    local dropdownSetting = d.dropdownSetting or d.dropDownSetting
    if dropdownSetting ~= nil then
        local checked = function()
            return cbSetting ~= nil and settingValue(cbSetting) == true
        end
        local vtable = dropdownNode(
            elementData,
            helpers,
            d.dropDownLabel or d.dropdownLabel,
            dropdownSetting,
            d.dropdownOptions or d.dropDownOptions,
            checked
        )
        vtable.tooltip = textTooltip(d.tooltip or d.dropDownTooltip) or vtable.tooltip
        addBarItem(builder, ids, ControlId.structural("srow:" .. index .. ":dropdown"), vtable)
    end
    endBar(builder, ids)
end

-- ---- rows with nested controls: graphics quality, subtext checkboxes,
-- colour swatches, previews ----

-- A real dropdown inside a row, reached lazily: Enter opens its menu (the
-- dropdown watcher presents it); the current pick reads through the
-- materialized dropdown's own text, else the setting's raw value.
local function lazyDropdownNode(elementData, helpers, label, setting, resolve, extraEnabled)
    local vtable = {
        controlType = graph.controlTypes.dropdown,
        announcements = {
            { text = label, kind = kinds.label },
            {
                text = function()
                    local frame = resolve()
                    if frame ~= nil and frame.GetText ~= nil then
                        local text = frame:GetText()
                        if text ~= nil and text ~= "" then
                            return text
                        end
                    end
                    local value = setting ~= nil and settingValue(setting) or nil
                    return value ~= nil and tostring(value) or nil
                end,
                kind = kinds.value,
                live = "focus",
            },
            disabledPart(elementData, extraEnabled),
        },
        onActivate = function()
            local frame = resolve()
            if frame ~= nil and frame.OpenMenu ~= nil then
                frame:OpenMenu()
            end
        end,
        onFocus = helpers.onFocus,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = resolve,
    }
    guardDisabled(vtable, elementData, extraEnabled)
    return vtable
end

-- The Graphics Quality section: one row holding a Base tab and a Raid and
-- Battlegrounds tab, each with a quality slider (the raid one behind an
-- enable checkbox) and thirteen quality dropdowns. Settings arrive in the
-- row data keyed by variable name; the controls live under the row's
-- BaseQualityControls or RaidQualityControls frame, whichever tab shows.
local QUALITY_CONTROLS = {
    "ShadowQuality",
    "LiquidDetail",
    "ParticleDensity",
    "SSAO",
    "DepthEffects",
    "ComputeEffects",
    "OutlineMode",
    "TextureResolution",
    "SpellDensity",
    "ProjectedTextures",
    "ViewDistance",
    "EnvironmentDetail",
    "GroundClutter",
}
local QUALITY_SLIDERS = { ViewDistance = true, EnvironmentDetail = true, GroundClutter = true }

-- The quality slider runs 0 to 9 and the game labels it 1 to 10.
local function qualitySliderNode(elementData, helpers, label, setting, resolve)
    local vtable = nodes.number({
        label = label,
        get = function()
            local value = settingValue(setting)
            return value ~= nil and value + 1 or nil
        end,
        set = function(value)
            value = math.floor(value + 0.5) - 1
            if value < 0 then
                value = 0
            elseif value > 9 then
                value = 9
            end
            setting:SetValue(value)
        end,
        step = 1,
    })
    tinsert(vtable.announcements, disabledPart(elementData))
    guardDisabled(vtable, elementData)
    vtable.onFocus = helpers.onFocus
    vtable.onUnfocus = helpers.onUnfocus
    vtable.tooltipFrame = resolve
    return vtable
end

settingEmitters["SettingsAdvancedQualitySectionTemplate"] = function(builder, elementData, index, helpers)
    local d = dataOf(elementData)
    local prefix = "srow:" .. index
    local rowFrame = helpers.target()
    local raid = rowFrame ~= nil
        and rowFrame.RaidQualityControls ~= nil
        and rowFrame.RaidQualityControls:IsShown()
        and not (rowFrame.BaseQualityControls ~= nil and rowFrame.BaseQualityControls:IsShown())
    local controlsKey = raid and "RaidQualityControls" or "BaseQualityControls"
    local settingPrefix = raid and "raidGraphics" or "graphics"
    local settings = (raid and d.raidSettings or d.settings) or {}
    local function control(key)
        return function(frame)
            local group = frame[controlsKey]
            return group ~= nil and group[key] or nil
        end
    end

    builder:pushContext(prefix .. ":quality", d.name or GRAPHICS_LABEL or "")
    builder:pushContext(prefix .. ":tabs", L["Tabs"])
    builder:startRow()
    builder:addItem(
        ControlId.structural(prefix .. ":tab:base"),
        rowButtonNode(elementData, helpers, BASE_GRAPHICS_QUALITY, "BaseTab")
    )
    builder:addItem(
        ControlId.structural(prefix .. ":tab:raid"),
        rowButtonNode(elementData, helpers, SETTINGS_RAID_GRAPHICS_QUALITY, "RaidTab")
    )
    builder:endRow()
    builder:popContext()

    local qualityLabel = raid and SETTINGS_RAID_GRAPHICS_QUALITY or BASE_GRAPHICS_QUALITY
    if raid then
        -- The enable checkbox has no setting in the row data: its state
        -- reads from the real check button.
        local resolveCheckbox = childResolver(helpers, function(frame)
            local group = frame[controlsKey]
            return group ~= nil and group.GraphicsQuality ~= nil and group.GraphicsQuality.Checkbox or nil
        end)
        local checkbox = checkboxNode(elementData, helpers, qualityLabel .. ", " .. L["Enabled"], nil, function(frame)
            return resolveCheckbox()
        end)
        tinsert(checkbox.announcements, {
            text = function()
                local button = resolveCheckbox()
                if button == nil or button.GetChecked == nil then
                    return nil
                end
                return button:GetChecked() and L["Checked"] or L["Unchecked"]
            end,
            kind = kinds.value,
            live = "focus",
        })
        builder:addItem(ControlId.structural(prefix .. ":raidEnabled"), checkbox)
    end
    local qualitySetting = settings[settingPrefix .. "Quality"]
    if qualitySetting ~= nil then
        builder:addItem(
            ControlId.structural(prefix .. ":" .. settingPrefix .. "Quality"),
            qualitySliderNode(
                elementData,
                helpers,
                qualityLabel,
                qualitySetting,
                childResolver(helpers, control("GraphicsQuality"))
            )
        )
    end
    for _, key in ipairs(QUALITY_CONTROLS) do
        local setting = settings[settingPrefix .. key]
        -- A control the game hides (spell density on clients without that
        -- system) is not offered.
        local child = rowFrame ~= nil and control(key)(rowFrame) or nil
        local hidden = child ~= nil and child.IsShown ~= nil and not child:IsShown()
        if setting ~= nil and not hidden then
            local label = function()
                local ok, name = pcall(setting.GetName, setting)
                return ok and name or key
            end
            local id = ControlId.structural(prefix .. ":" .. settingPrefix .. key)
            if QUALITY_SLIDERS[key] then
                -- View distance, environment detail, and ground clutter are
                -- sliders on the same 0 to 9 scale as the quality slider.
                builder:addItem(
                    id,
                    qualitySliderNode(elementData, helpers, label, setting, childResolver(helpers, control(key)))
                )
            else
                local resolve = childResolver(helpers, function(frame)
                    local dropdownHost = control(key)(frame)
                    return dropdownHost ~= nil and dropdownHost.Control ~= nil and dropdownHost.Control.Dropdown or nil
                end)
                builder:addItem(id, lazyDropdownNode(elementData, helpers, label, setting, resolve))
            end
        end
    end
    builder:popContext()
end

-- A checkbox with an explanatory line beside it (speech to text,
-- arachnophobia mode): the line reads as an extra part of the checkbox.
local function subtextCheckboxEmitter(builder, elementData, index, helpers)
    local node = checkboxNode(elementData, helpers, function()
        return settingName(elementData)
    end, settingObject(elementData))
    tinsert(node.announcements, {
        text = function()
            local rowFrame = helpers.target()
            local container = rowFrame ~= nil and rowFrame.SubTextContainer or nil
            return container ~= nil and textOf(container.SubText) or nil
        end,
        live = false,
    })
    builder:addItem(helpers.id, node)
end
settingEmitters["STTTemplate"] = subtextCheckboxEmitter
settingEmitters["ArachnophobiaTemplate"] = subtextCheckboxEmitter

-- Remote text-to-speech voice: a dropdown with a sample button beside it.
settingEmitters["RTTSTemplate"] = function(builder, elementData, index, helpers)
    local setting = settingObject(elementData)
    if setting == nil then
        unimplementedRow(builder, helpers.id, elementData.frameTemplate)
        return
    end
    local d = dataOf(elementData)
    local label = function()
        return settingName(elementData)
    end
    local ids = beginBar(builder, helpers, label)
    addBarItem(builder, ids, helpers.id, dropdownNode(elementData, helpers, label, setting, d.options))
    addBarItem(
        builder,
        ids,
        ControlId.structural("srow:" .. index .. ":button"),
        rowButtonNode(elementData, helpers, frameChildText(helpers, "Button"), "Button")
    )
    endBar(builder, ids)
end

-- A colour swatch button: Enter clicks the real swatch, which opens the
-- game's colour picker (its own window). An optional value reads the
-- current colour.
local function swatchButtonNode(elementData, helpers, label, resolveSwatch, valueText)
    local node = rowButtonNode(elementData, helpers, label, resolveSwatch)
    if valueText ~= nil then
        tinsert(node.announcements, { text = valueText, kind = kinds.value, live = "focus" })
    end
    return node
end

settingEmitters["SettingsColorSwatchControlTemplate"] = function(builder, elementData, index, helpers)
    local setting = settingObject(elementData)
    builder:addItem(
        helpers.id,
        swatchButtonNode(elementData, helpers, function()
            return settingName(elementData)
        end, function(rowFrame)
            return rowFrame.ColorSwatch
        end, setting ~= nil and function()
            local value = settingValue(setting)
            return value ~= nil and tostring(value) or nil
        end or nil)
    )
end

settingEmitters["SettingsCheckboxWithColorSwatchControlTemplate"] = function(builder, elementData, index, helpers)
    local label = function()
        return settingName(elementData)
    end
    local ids = beginBar(builder, helpers, label)
    addBarItem(builder, ids, helpers.id, checkboxNode(elementData, helpers, label, settingObject(elementData), "Checkbox"))
    addBarItem(
        builder,
        ids,
        ControlId.structural("srow:" .. index .. ":swatch"),
        swatchButtonNode(elementData, helpers, L["Color"], function(rowFrame)
            return rowFrame.ColorSwatch
        end)
    )
    endBar(builder, ids)
end

-- Item quality colour overrides (Colorblind category): one swatch per
-- quality, labelled from the game's quality names, clicking the pooled
-- swatch frame for that quality.
settingEmitters["ItemQualityColorOverrides"] = function(builder, elementData, index, helpers)
    local overrides = ItemQualityColorOverrideMixin ~= nil and ItemQualityColorOverrideMixin.OverrideData or {}
    builder:pushContext("srow:" .. index .. ":qualities", L["Item Quality Colors"])
    if #overrides == 0 then
        builder:addItem(helpers.id, nodes.text({ label = L["Item Quality Colors"] }))
    end
    for _, data in ipairs(overrides) do
        local quality = data.qualityBase
        builder:addItem(
            ControlId.structural("srow:" .. index .. ":quality:" .. tostring(quality)),
            swatchButtonNode(
                elementData,
                helpers,
                _G["ITEM_QUALITY" .. tostring(quality) .. "_DESC"] or tostring(quality),
                function(rowFrame)
                    local pool = rowFrame.ItemQualities
                    if pool == nil then
                        return nil
                    end
                    for _, child in ipairs({ pool:GetChildren() }) do
                        if child.data ~= nil and child.data.qualityBase == quality and child.ColorSwatch ~= nil then
                            return child.ColorSwatch
                        end
                    end
                    return nil
                end
            )
        )
    end
    builder:popContext()
end

-- Informational rows: a label the Interface category shows when its
-- add-on is disabled, and the raid frame and nameplate previews (pure
-- visuals, but a place to land so positions stay honest).
settingEmitters["SettingsAddOnDisabledLabelTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(
        helpers.id,
        nodes.text({
            label = function()
                return frameChildText(helpers, "Text")() or ADDON_DISABLED or ""
            end,
        })
    )
end
settingEmitters["RaidFramePreviewTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(helpers.id, nodes.text({ label = L["Raid Frame Preview"] }))
end
settingEmitters["NamePlatePreviewTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(helpers.id, nodes.text({ label = L["Nameplate Preview"] }))
end
settingEmitters["MacMicrophoneAccessWarningTemplate"] = function(builder, elementData, index, helpers)
    builder:addItem(helpers.id, nodes.text({ label = frameChildText(helpers, "Label") }))
    builder:addItem(
        ControlId.structural("srow:" .. index .. ":button"),
        rowButtonNode(elementData, helpers, frameChildText(helpers, "OpenAccessButton"), "OpenAccessButton")
    )
end

-- ---- keybindings (structure per Blizzard_SettingsDefinitions_Frame/Keybindings.lua) ----
--
-- A keybinding section is ONE provider element: its data carries name,
-- expanded, and bindingsCategories (entries are {bindingIndex, action},
-- {prefaceText}, or the KeybindingSpacer sentinel), and its frame builds one
-- Controls subframe per entry, shown while expanded. Clicking frame.Button
-- toggles data.expanded. Provider-level KeyBindingFrameBindingTemplate
-- elements exist only in search results.

-- Two slot buttons for one binding, as a bar named for the binding: the
-- slots read their key live from the binding API ("Jump, bar, Space,
-- button, 1 of 2"), Enter starts the rebind, Backspace unbinds (the
-- template's right-click).
local function emitBindingSlots(builder, helpers, idPrefix, bindingIndex, action, resolveRow)
    local bindingName = function()
        if action ~= nil then
            local ok, resolved = pcall(GetBindingName, action)
            if ok and resolved ~= nil and resolved ~= "" then
                return resolved
            end
        end
        return action or tostring(bindingIndex)
    end
    builder:pushContext(idPrefix .. ":bar", bindingName)
    builder:startRow()
    for slot = 1, 2 do
        local slotIndex = slot
        local resolveSlot = function()
            local rowFrame = resolveRow()
            if rowFrame == nil then
                return nil
            end
            if rowFrame.Buttons ~= nil then
                return rowFrame.Buttons[slotIndex]
            end
            if slotIndex == 1 then
                return rowFrame.Button1
            end
            return rowFrame.Button2
        end
        builder:addItem(ControlId.structural(idPrefix .. ":" .. slotIndex), {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        local slotKey = nil
                        local ok = pcall(function()
                            local _, _, key1, key2 = GetBinding(bindingIndex)
                            slotKey = slotIndex == 1 and key1 or key2
                        end)
                        if ok and slotKey ~= nil then
                            return GetBindingText(slotKey)
                        end
                        return NOT_BOUND
                    end,
                    kind = kinds.label,
                    live = "focus",
                },
            },
            bindings = {
                { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = resolveSlot },
                { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = resolveSlot },
            },
            onFocus = helpers.onFocus,
            onUnfocus = helpers.onUnfocus,
            tooltipFrame = resolveSlot,
        })
    end
    builder:endRow()
    builder:popContext()
end

settingEmitters["SettingsKeybindingSectionTemplate"] = function(builder, elementData, index, helpers)
    local d = dataOf(elementData)
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
            {
                text = function()
                    return d.expanded and L["Expanded"] or L["Collapsed"]
                end,
                kind = kinds.value,
                live = "focus",
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

    if not d.expanded or d.bindingsCategories == nil then
        return
    end
    for controlIndex, entry in ipairs(d.bindingsCategories) do
        local capturedControl = controlIndex
        local resolveRow = function()
            local rowFrame = helpers.target()
            if rowFrame ~= nil and rowFrame.Controls ~= nil then
                return rowFrame.Controls[capturedControl]
            end
            return nil
        end
        if type(entry) == "table" and entry.prefaceText ~= nil then
            local preface = entry.prefaceText
            builder:addItem(
                ControlId.structural("srow:" .. index .. ":" .. controlIndex),
                nodes.text({
                    label = function()
                        local localized = _G[preface]
                        return type(localized) == "string" and localized or preface
                    end,
                })
            )
        elseif type(entry) == "table" and entry[1] ~= nil then
            emitBindingSlots(
                builder,
                helpers,
                "srow:" .. index .. ":" .. controlIndex,
                entry[1],
                entry[2],
                resolveRow
            )
        end
        -- The KeybindingSpacer sentinel matches neither shape and emits nothing.
    end
end

settingEmitters["SettingsExpandableSectionTemplate"] = settingEmitters["SettingsKeybindingSectionTemplate"]

-- Search results surface bindings as their own provider elements with
-- data.bindingIndex.
settingEmitters["KeyBindingFrameBindingTemplate"] = function(builder, elementData, index, helpers)
    local d = dataOf(elementData)
    local bindingIndex = d ~= nil and d.bindingIndex or nil
    if bindingIndex == nil then
        return
    end
    local action = nil
    pcall(function()
        action = (GetBinding(bindingIndex))
    end)
    emitBindingSlots(builder, helpers, "srow:" .. index, bindingIndex, action, helpers.target)
end

-- ---- the window ----

local function render(builder, screen)
    local frame = SettingsPanel
    if frame == nil or not frame:IsShown() then
        return
    end

    -- The panel hides both tabs when no addon has registered a settings
    -- category (a fresh Forever install), and hidden proxies emit nothing,
    -- so the row only exists while a tab is showing.
    if (frame.GameTab ~= nil and frame.GameTab:IsShown()) or (frame.AddOnsTab ~= nil and frame.AddOnsTab:IsShown()) then
        builder:beginStop("tabs")
        builder:pushContext("tabs", L["Tabs"])
        builder:startRow()
        builder:addItem(ControlId.forObject(frame.GameTab), nodes.proxyButton({ target = frame.GameTab }))
        builder:addItem(ControlId.forObject(frame.AddOnsTab), nodes.proxyButton({ target = frame.AddOnsTab }))
        builder:endRow()
        builder:popContext()
    end

    -- Focus the real search box and let the player type into it: a SetText
    -- from addon code runs the panel's OnTextChanged search tainted, and the
    -- rebuilt result rows then hit protected calls (C_Discord.IsUserOAuthed
    -- in the Social category) -> ADDON_ACTION_FORBIDDEN.
    if frame.SearchBox ~= nil then
        builder:beginStop("search")
        builder:addItem(
            ControlId.structural("search"),
            nodes.proxyEditBox({ editBox = frame.SearchBox, label = L["Search"] })
        )
    end

    if frame.CategoryList ~= nil and frame.CategoryList:IsShown() then
        builder:beginStop("categories")
        nodes.scrollBoxList(builder, {
            scrollBox = frame.CategoryList.ScrollBox,
            key = "categories",
            label = L["Categories"],
            templates = categoryTemplates,
            defaultTemplate = categoryButtonRow,
        })
    end

    local list = frame.GetSettingsList ~= nil and frame:GetSettingsList() or nil
    if list ~= nil and list:IsShown() then
        builder:beginStop("settings")
        local title = nil
        pcall(function()
            title = list.Header.Title:GetText()
        end)
        -- A new category is a new list: forget where the settings stop was
        -- so tabbing back lands at the top, as the game scrolls to the top.
        -- Row ids are index-based, so without this the old position would
        -- silently map onto the new category's rows.
        local categoryKey = title
        pcall(function()
            local category = frame:GetCurrentCategory()
            if category ~= nil then
                categoryKey = category.GetID ~= nil and category:GetID() or category
            end
        end)
        if screen._settingsCategory ~= categoryKey then
            if screen._settingsCategory ~= nil then
                screen.state.stopMemory["settings"] = nil
            end
            screen._settingsCategory = categoryKey
        end
        nodes.scrollBoxList(builder, {
            scrollBox = list.ScrollBox,
            key = "settings",
            label = title or L["Options"],
            templates = settingEmitters,
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
