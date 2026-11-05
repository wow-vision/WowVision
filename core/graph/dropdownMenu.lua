local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local L = WowVision:getLocale()

-- Dropdown menus, graph-side: watches the modern Menu manager for an open
-- menu anywhere and presents the whole open chain as one stack. Every open
-- menu level (root, then each submenu) is its own tab stop; the per-tick
-- rebuild picks up submenus opening and closing with no extra plumbing.
--
-- Menu items get NO hover attach: the menu manager opens and collapses
-- submenus on mouse-enter, so hovering rows as focus moves would churn the
-- open chain. Submenu rows open explicitly through their element
-- description on Enter instead.
local dropdown = {
    stack = nil,
    frame = nil,
    overrides = {},
    active = nil,
}
graph.dropdown = dropdown

-- Per-menu item overrides for menus whose rows need custom handling:
-- emitters[index] = function(builder, itemFrame, index). Registered through
-- Module:registerDropdownMenu; mirrored into Menu.ModifyMenu so the active
-- set follows whichever menu generated last.
function dropdown.registerMenu(menuKey, emitters)
    if dropdown.overrides[menuKey] ~= nil then
        dropdown.overrides[menuKey] = emitters
        return
    end
    dropdown.overrides[menuKey] = emitters
    Menu.ModifyMenu(menuKey, function()
        dropdown.active = dropdown.overrides[menuKey]
    end)
end

function dropdown.unregisterMenu(menuKey)
    dropdown.overrides[menuKey] = nil
end

-- The legacy check texture (UIDropDownMenu-era rows): shown means checked.
local LEGACY_CHECK_TEXTURE = 136810

local function descriptionOf(item)
    if item.GetElementDescription == nil then
        return nil
    end
    local ok, description = pcall(item.GetElementDescription, item)
    if ok then
        return description
    end
    return nil
end

local function isSubmenuRow(item)
    local description = descriptionOf(item)
    if description == nil or description.CanOpenSubmenu == nil then
        return false
    end
    local ok, canOpen = pcall(description.CanOpenSubmenu, description)
    return ok and canOpen or false
end

-- Data-first row semantics from the element description proxy (the same
-- object ForceOpenSubmenu uses). A description built by CreateCheckbox or
-- CreateRadio stores its isSelected predicate as a plain field, so its
-- presence is what marks a selectable row -- no texture guessing. IsSelected
-- runs the predicate for live checked state; IsEnabled covers disabled rows.
local function selectionState(description)
    if description.isSelected == nil or description.IsSelected == nil then
        return nil
    end
    local ok, selected = pcall(description.IsSelected, description)
    if not ok then
        return nil
    end
    return selected == true
end

local function isDescriptionEnabled(description)
    if description.IsEnabled == nil then
        return true
    end
    local ok, enabled = pcall(description.IsEnabled, description)
    return not ok or enabled ~= false
end

local function itemRegions(item)
    local fontStrings, legacyCheck = {}, nil
    for _, region in ipairs({ item:GetRegions() }) do
        local kind = region:GetObjectType()
        if kind == "FontString" then
            tinsert(fontStrings, region)
        elseif kind == "Texture" and region:GetTexture() == LEGACY_CHECK_TEXTURE then
            legacyCheck = region
        end
    end
    return fontStrings, legacyCheck
end

-- A row's text: every text region in order, empties skipped. Most rows have
-- one; a cooldown alert row writes the event under the sound name, so it
-- reads "Low Thud, On Aura Applied".
local function rowLabel(fontStrings)
    return function()
        local parts = {}
        for _, fontString in ipairs(fontStrings) do
            local text = fontString:GetText()
            if text ~= nil and text ~= "" then
                tinsert(parts, text)
            end
        end
        if #parts == 0 then
            return nil
        end
        return table.concat(parts, ", ")
    end
end

-- focus (scrolling menus, see menuRowFocus): { onFocus, onFocusTick } run
-- before a node's own hooks.
local function withFocus(vtable, focus)
    if focus == nil then
        return vtable
    end
    for _, key in ipairs({ "onFocus", "onFocusTick" }) do
        local own, extra = vtable[key], focus[key]
        if own == nil then
            vtable[key] = extra
        else
            vtable[key] = function(...)
                extra(...)
                return own(...)
            end
        end
    end
    return vtable
end

-- A row's tooltip, read on the tooltip key like any control's. Blizzard shows
-- it from the row's mouse-enter: the element description's onEnter
-- (MenuUtil's SetTooltip, the unit menus' tooltip text). Running the row's
-- whole OnEnter would also open and collapse submenus (the reason rows are
-- never hovered), so only the description's onEnter runs, filling the menu's
-- own tooltip frame, which is read and hidden again. Rows without one get no
-- tooltip.
local function attachMenuTooltip(vtable, item)
    local description = descriptionOf(item)
    if description == nil then
        return vtable
    end
    local okEnter, onEnter = pcall(function()
        if description.GetOnEnter ~= nil then
            return description:GetOnEnter()
        end
        return description.onEnter
    end)
    if not okEnter or type(onEnter) ~= "function" then
        return vtable
    end
    local okFrame, tooltipFrame = pcall(description.GetTooltipFrame, description)
    vtable.tooltipFrame = item
    vtable.tooltip = {
        type = "Game",
        mode = "immediate",
        frame = okFrame and tooltipFrame or nil,
        populate = function(_, frame)
            onEnter(frame, description)
        end,
    }
    return vtable
end

-- Controls inside a custom row (rootDescription:CreateTemplate / CreateFrame
-- with an attached template): the level range's Min and Max edit boxes (the
-- auction house filter, the Group Finder, crafting orders), the voice volume
-- rows' toggle button and slider. Shown edit boxes, check buttons, buttons and
-- sliders down to three levels deep, in screen order (left to right, then top
-- to bottom).
local ROW_CONTROL_KINDS = { EditBox = true, CheckButton = true, Button = true, Slider = true }

-- The unit menu's voice volume sliders (UnitPopupCustomControls.lua) have no
-- label of their own: named with the game's strings, by the mixin they carry.
local function voiceSliderLabel(slider)
    local named = {
        { mixin = UnitPopupVoiceSpeakerVolumeSliderMixin, text = VOICE_CHAT_VOLUME },
        { mixin = UnitPopupVoiceMicrophoneVolumeSliderMixin, text = VOICE_CHAT_MIC_VOLUME },
        { mixin = UnitPopupVoiceUserVolumeSliderMixin, text = VOLUME },
    }
    for _, entry in ipairs(named) do
        if entry.mixin ~= nil and entry.mixin.OnLoad ~= nil and slider.OnLoad == entry.mixin.OnLoad then
            return entry.text
        end
    end
    return nil
end

-- Labels for controls Blizzard leaves unlabelled, by their parentKey.
local ROW_CONTROL_LABELS = { MinLevel = "Minimum", MaxLevel = "Maximum" }

local function parentKeyOf(parent, child)
    for key, value in pairs(parent) do
        if value == child and type(key) == "string" then
            return key
        end
    end
    return nil
end

function dropdown.rowControls(row)
    local found = {}
    local function walk(frame, depth)
        for _, child in ipairs({ frame:GetChildren() }) do
            local okKind, kind = pcall(child.GetObjectType, child)
            if okKind and child:IsShown() then
                if ROW_CONTROL_KINDS[kind] then
                    tinsert(found, { frame = child, kind = kind, parent = frame, order = #found })
                elseif depth < 3 then
                    walk(child, depth + 1)
                end
            end
        end
    end
    walk(row, 1)
    table.sort(found, function(a, b)
        local la, lb = a.frame:GetLeft(), b.frame:GetLeft()
        local ta, tb = a.frame:GetTop(), b.frame:GetTop()
        if ta ~= nil and tb ~= nil and math.abs(ta - tb) > 4 then
            return ta > tb
        end
        if la ~= nil and lb ~= nil and la ~= lb then
            return la < lb
        end
        return a.order < b.order
    end)
    return found
end

local function rowControlLabel(control)
    local key = parentKeyOf(control.parent, control.frame)
    local known = key ~= nil and ROW_CONTROL_LABELS[key] or nil
    if known ~= nil then
        return L[known]
    end
    if control.kind == "Slider" then
        local slider = control.frame
        local voice = voiceSliderLabel(slider)
        if voice ~= nil then
            return voice
        end
        -- a slider template's own label (UISliderTemplateWithLabels: Text)
        for _, key in ipairs({ "Label", "Text" }) do
            local region = slider[key]
            if region ~= nil and region.GetText ~= nil and (region:GetText() or "") ~= "" then
                return region:GetText()
            end
        end
        return nil
    end
    if control.kind == "EditBox" then
        local instructions = control.frame.Instructions
        if instructions ~= nil and instructions.GetText ~= nil then
            return instructions:GetText()
        end
        return nil
    end
    -- a button's own text, else its tooltip's title (icon buttons)
    local button = control.frame
    local tooltipLabel = dropdown.rowButtonLabel(button)
    return function()
        local text = button.GetText ~= nil and button:GetText() or nil
        if text ~= nil and text ~= "" then
            return text
        end
        return tooltipLabel()
    end
end

-- Sliders each get a line of their own after the row: on a slider, left and
-- right move it (GraphHost:_arrow adjusts first), so one in a row would trap
-- focus between its neighbours.
local function emitRowControls(builder, item, controls, label, hasText, focus)
    local inRow, sliders = {}, {}
    for _, control in ipairs(controls) do
        tinsert(control.kind == "Slider" and sliders or inRow, control)
    end
    if hasText or #inRow > 0 then
        builder:startRow()
        if hasText then
            builder:addItem(ControlId.forObject(item), withFocus(nodes.text({ label = label }), focus))
        end
    end
    for _, control in ipairs(inRow) do
        local controlLabel = rowControlLabel(control)
        local vtable
        if control.kind == "EditBox" then
            -- Enter leaves the box, where Blizzard gives it nothing to do on
            -- Enter (the level range's boxes only clear focus on Escape)
            local editBox = control.frame
            if editBox.GetScript ~= nil and editBox:GetScript("OnEnterPressed") == nil then
                editBox:SetScript("OnEnterPressed", function(self)
                    self:ClearFocus()
                end)
            end
            vtable = nodes.proxyEditBox({
                editBox = control.frame,
                label = controlLabel,
                autoInput = false,
                allowHidden = true,
            })
        elseif control.kind == "CheckButton" then
            vtable = nodes.proxyCheckButton({ target = control.frame, label = controlLabel, allowHidden = true })
        else
            vtable = nodes.proxyButton({ target = control.frame, label = controlLabel, allowHidden = true })
        end
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(control.frame), withFocus(vtable, focus))
        end
    end
    if hasText or #inRow > 0 then
        builder:endRow()
    end
    for _, control in ipairs(sliders) do
        builder:addItem(
            ControlId.forObject(control.frame),
            withFocus(nodes.proxySlider({ slider = control.frame, label = rowControlLabel(control) }), focus)
        )
    end
end

-- The marker a row of the Raid Target Icon submenu sets: 1 to 8, 0 for None,
-- nil for any other row. opener: the text of the row that opened its menu.
function dropdown.raidMarkerOf(text, opener)
    if text == nil or RAID_TARGET_ICON == nil or opener ~= RAID_TARGET_ICON then
        return nil
    end
    if text == RAID_TARGET_NONE then
        return 0
    end
    for marker = 1, 8 do
        if text == _G["RAID_TARGET_" .. marker] then
            return marker
        end
    end
    return nil
end

local function emitItem(builder, item, focus)
    local fontStrings, legacyCheck = itemRegions(item)
    local label = rowLabel(fontStrings)

    if item:GetObjectType() ~= "Button" then
        local controls = dropdown.rowControls(item)
        if #controls > 0 then
            emitRowControls(builder, item, controls, label, #fontStrings > 0 and label() ~= nil, focus)
        elseif #fontStrings > 0 then
            builder:addItem(ControlId.forObject(item), withFocus(nodes.text({ label = label }), focus))
        end
        return
    end

    if isSubmenuRow(item) then
        -- A submenu parent: Enter opens its child menu, which the watcher
        -- pushes as a new screen (landing on its first item).
        -- ForceOpenSubmenu bypasses the manager's IsMouseOver gate (the
        -- reason synthetic hover can never work).
        local captured = item
        builder:addItem(ControlId.forObject(item), withFocus(attachMenuTooltip({
            controlType = graph.controlTypes.dropdown,
            announcements = { { text = label, kind = kinds.label } },
            onActivate = function()
                local description = descriptionOf(captured)
                if description == nil or description.ForceOpenSubmenu == nil then
                    geterrorhandler()("dropdown submenu: no usable element description")
                    return
                end
                local ok, err = pcall(description.ForceOpenSubmenu, description)
                if not ok then
                    geterrorhandler()("dropdown submenu: " .. tostring(err))
                end
            end,
        }, captured), focus))
        return
    end

    -- "Copy Character Name" calls the protected CopyToClipboard. In a menu
    -- OPENED by addon code (a chat line's player menu) the menu's own data is
    -- tainted, so even a secure click on the row is blocked. The opener
    -- leaves the name in dropdown.copyName and the row copies through an
    -- edit box instead. Menus opened by secure clicks keep the real row.
    if dropdown.copyName ~= nil and COPY_CHARACTER_NAME ~= nil and label() == COPY_CHARACTER_NAME then
        local name = dropdown.copyName
        builder:addItem(ControlId.forObject(item), withFocus({
            controlType = graph.controlTypes.button,
            announcements = { { text = label, kind = kinds.label } },
            onActivate = function()
                if dropdown.frame ~= nil and dropdown.frame.Close ~= nil then
                    pcall(dropdown.frame.Close, dropdown.frame)
                end
                C_Timer.After(0.2, function()
                    WowVision.graphHost:openCopyBox(name)
                end)
            end,
        }, focus))
        return
    end

    local vtable = {
        controlType = graph.controlTypes.button,
        announcements = { { text = label, kind = kinds.label } },
        bindings = {
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = item },
        },
    }
    local description = descriptionOf(item)
    if description ~= nil then
        -- Modern rows: the description says what the row IS. Only rows
        -- carrying a selection predicate are toggles; plain buttons never
        -- read as checkboxes regardless of what textures they show.
        if selectionState(description) ~= nil then
            local okRadio, isRadio = pcall(function()
                return description.IsRadio ~= nil and description:IsRadio() == true
            end)
            vtable.controlType = (okRadio and isRadio) and graph.controlTypes.radio
                or graph.controlTypes.toggle
            local captured = description
            tinsert(vtable.announcements, {
                text = function()
                    return selectionState(captured) and L["Checked"] or L["Unchecked"]
                end,
                kind = kinds.value,
            })
        end
        local captured = description
        tinsert(vtable.announcements, {
            text = function()
                if not isDescriptionEnabled(captured) then
                    return L["Disabled"]
                end
                return nil
            end,
            kind = kinds.enabled,
        })
    elseif legacyCheck ~= nil then
        -- Legacy UIDropDownMenu rows have no descriptions; the shown check
        -- texture stays the signal there.
        vtable.controlType = graph.controlTypes.toggle
        local capturedRegion = legacyCheck
        tinsert(vtable.announcements, {
            text = function()
                return capturedRegion:IsShown() and L["Checked"] or L["Unchecked"]
            end,
            kind = kinds.value,
        })
    end
    -- ForceOpenSubmenu above runs in WowVision's stack, so a submenu's rows are
    -- built tainted and even a secure click on one cannot reach the protected
    -- SetRaidTarget. No secure way opens a submenu, so these rows take the
    -- game's secure raid target action instead. Only the target's menu has
    -- them (unitMenus.lua), so the unit is the target.
    local marker = dropdown.raidMarkerOf(label(), dropdown.openerText(item))
    if marker ~= nil then
        vtable.bindings = {
            {
                binding = "leftClick",
                type = "RaidTarget",
                emulatedKey = "LeftButton",
                marker = marker,
                unit = "target",
                after = function()
                    C_Timer.After(0, function()
                        if dropdown.frame ~= nil and dropdown.frame.Close ~= nil then
                            pcall(dropdown.frame.Close, dropdown.frame)
                        end
                    end)
                end,
            },
        }
    end
    builder:addItem(ControlId.forObject(item), withFocus(attachMenuTooltip(vtable, item), focus))
end

-- Buttons the menu attaches to a row: the gear and delete buttons on a layout
-- row, play sample / edit / delete on a cooldown alert row. They are real
-- Button children of the row carrying a click script (MenuTemplates'
-- utility buttons), returned in screen order, left to right. Most are hidden
-- until the mouse is over the row, so they are clicked while hidden.
function dropdown.rowButtons(item)
    local buttons = {}
    if item.GetChildren == nil then
        return buttons
    end
    for _, child in ipairs({ item:GetChildren() }) do
        if
            child.GetObjectType ~= nil
            and child:GetObjectType() == "Button"
            and child.GetScript ~= nil
            and child:GetScript("OnClick") ~= nil
        then
            tinsert(buttons, child)
        end
    end
    local lefts, order, placed = {}, {}, true
    for index, button in ipairs(buttons) do
        local left = button.GetLeft ~= nil and button:GetLeft() or nil
        if left == nil then
            placed = false
        end
        lefts[button] = left
        order[button] = index
    end
    if placed then
        table.sort(buttons, function(a, b)
            if lefts[a] ~= lefts[b] then
                return lefts[a] < lefts[b]
            end
            return order[a] < order[b]
        end)
    end
    return buttons
end

-- A row button's name lives only in its tooltip: MenuUtil.HookTooltipScripts
-- writes the title from an OnEnter closure and stores nothing on the frame.
-- The label runs the hover scripts once and takes the tooltip's first line,
-- cached per frame time so a tick probes each button once. A tooltip the
-- button already owns (focus hovered it) is read as is, so the probe never
-- hides the tooltip the reader is about to speak.
local labelCache = setmetatable({}, { __mode = "k" })
function dropdown.rowButtonLabel(button)
    return function()
        local now = GetTime ~= nil and GetTime() or 0
        local cached = labelCache[button]
        if cached ~= nil and cached.time == now then
            return cached.text
        end
        local text = nil
        local tooltip = GameTooltip
        if tooltip ~= nil and ExecuteFrameScript ~= nil and button.HasScript ~= nil and button:HasScript("OnEnter") then
            local owned = tooltip.IsShown ~= nil and tooltip:IsShown()
                and tooltip.GetOwner ~= nil and tooltip:GetOwner() == button
            if not owned then
                pcall(ExecuteFrameScript, button, "OnEnter")
            end
            local line = GameTooltipTextLeft1
            text = line ~= nil and line:GetText() or nil
            if not owned then
                pcall(ExecuteFrameScript, button, "OnLeave")
            end
        end
        if text == "" then
            text = nil
        end
        labelCache[button] = { time = now, text = text }
        return text
    end
end

-- A menu row with attached buttons is a horizontal row: the row first, then
-- each button on the right arrow. Up and down between rows land on the row
-- text. A row without buttons stays a single item.
function dropdown.emitRow(builder, item, focus)
    local buttons = dropdown.rowButtons(item)
    if #buttons == 0 then
        emitItem(builder, item, focus)
        return
    end
    builder:startRow()
    emitItem(builder, item, focus)
    for _, button in ipairs(buttons) do
        builder:addItem(
            ControlId.forObject(button),
            withFocus(
                nodes.proxyButton({
                    target = button,
                    allowHidden = true,
                    label = dropdown.rowButtonLabel(button),
                }),
                focus
            )
        )
    end
    builder:endRow()
end

-- Menu frames attach through the Window API, not SetParent, so neither
-- parent walks nor EnumerateFrames can find them reliably. Instead, capture
-- every menu frame at creation: MenuProxyMixin is the global mixin on
-- MenuTemplateBase, its OnLoad runs once per pooled frame, and
-- hooksecurefunc on the mixin propagates to every frame built from it.
-- Pooled menu frames are never destroyed, so a weak registry stays exact.
local trackedMenus = setmetatable({}, { __mode = "k" })
if MenuProxyMixin ~= nil and MenuProxyMixin.OnLoad ~= nil then
    hooksecurefunc(MenuProxyMixin, "OnLoad", function(frame)
        trackedMenus[frame] = true
    end)
end

-- The menu a submenu frame hangs from: a submenu is anchored to the row that
-- opened it (MenuManagerMixin:GenerateSubmenuInternal, TOPLEFT to the row's
-- TOPRIGHT), and that row lies in its menu: a child of it, or in a scrolling
-- menu a child of its ScrollBox's scroll target, so the parents are walked up
-- to the first menu frame. A submenu that would run off the screen is flipped
-- to the row's other side, still anchored to it.
local function anchorMenu(frame)
    local ok, _, row = pcall(frame.GetPoint, frame, 1)
    if not ok or type(row) ~= "table" or row.GetParent == nil then
        return nil
    end
    local current = row
    for _ = 1, 4 do
        local okParent, parent = pcall(current.GetParent, current)
        if not okParent or parent == nil then
            return nil
        end
        if trackedMenus[parent] or parent == dropdown.frame then
            return parent
        end
        current = parent
    end
    return nil
end

-- The text of the row that opened the menu a row lies in, nil in a root menu.
function dropdown.openerText(item)
    local current = item
    for _ = 1, 4 do
        local ok, parent = pcall(current.GetParent, current)
        if not ok or parent == nil then
            return nil
        end
        if trackedMenus[parent] then
            local okPoint, _, row = pcall(parent.GetPoint, parent, 1)
            if not okPoint or type(row) ~= "table" or row.GetElementDescription == nil then
                return nil
            end
            return rowLabel((itemRegions(row)))()
        end
        current = parent
    end
    return nil
end

-- The chain in order, root first: each level is the shown menu anchored to a
-- row of the level before. NOT by left edge: a flipped submenu (a menu opened
-- at the cursor near the screen's right edge) lies left of its parent, and
-- sorting by position read the root again as level 2 (Set Loot
-- Specialization "opened the same menu"). Menus whose anchor cannot be
-- followed come last, by left edge, as before. anchorOf(frame) -> parent menu.
function dropdown.chainMenus(root, shown, anchorOf, leftOf)
    local menus = { root }
    local remaining = {}
    for _, frame in ipairs(shown) do
        if frame ~= root then
            tinsert(remaining, frame)
        end
    end
    local found = true
    while found and #remaining > 0 do
        found = false
        local last = menus[#menus]
        for i, frame in ipairs(remaining) do
            if anchorOf(frame) == last then
                tinsert(menus, frame)
                table.remove(remaining, i)
                found = true
                break
            end
        end
    end
    table.sort(remaining, function(a, b)
        return (leftOf(a) or 0) < (leftOf(b) or 0)
    end)
    for _, frame in ipairs(remaining) do
        tinsert(menus, frame)
    end
    return menus
end

-- Every open menu frame in the chain: the root from the manager plus every
-- tracked menu frame currently shown, in chain order.
local function openMenuFrames(root)
    local shown = {}
    for frame in pairs(trackedMenus) do
        if frame ~= root and frame:IsShown() then
            tinsert(shown, frame)
        end
    end
    return dropdown.chainMenus(root, shown, anchorMenu, function(frame)
        return frame:GetLeft()
    end)
end
graph.dropdown.openMenuFrames = openMenuFrames

-- A title row (the player's name, "Interact", "Other Options"): a shown
-- non-button row carrying text. Returns its text, or nil for anything else
-- (buttons, dividers, spacers).
local function titleText(item, shown)
    if not shown or item:GetObjectType() == "Button" then
        return nil
    end
    -- a custom row with controls in it is a row, not a title
    if #dropdown.rowControls(item) > 0 then
        return nil
    end
    return rowLabel(itemRegions(item))()
end

-- A menu's rows in order, and whether they all count as shown. A menu
-- taller than its scroll extent (rootDescription:SetScrollMode) moves EVERY
-- row frame into its ScrollBox's data provider (MenuMixin's layout:
-- dataProvider:Insert(frame)): the rows are all built and initialized, but
-- only those scrolled into view are shown, and they are no longer the menu
-- frame's own children past the ScrollBox and ScrollBar. The provider holds
-- the real row frames, so every row is read and clicked as in a short menu;
-- rows out of view count as shown. A short menu: the frame's children after
-- the ScrollBox and ScrollBar (the first two), shown ones only.
local function menuRows(menuFrame)
    local scrollBox = menuFrame.ScrollBox
    if
        scrollBox ~= nil
        and scrollBox:IsShown()
        and scrollBox.HasDataProvider ~= nil
        and scrollBox:HasDataProvider()
    then
        local rows = {}
        for _, frame in scrollBox:GetDataProvider():Enumerate() do
            tinsert(rows, frame)
        end
        return rows, true
    end
    local children = { menuFrame:GetChildren() }
    local rows = {}
    for i = 3, #children do
        tinsert(rows, children[i])
    end
    return rows, false
end
dropdown.menuRows = menuRows

-- Scrolling menus, two ways to reach a row out of view:
-- - true (the scroll way, as nodes.scrollBoxList in scrollBox.lua): focus
--   scrolls the row into view with ScrollToElementDataIndex, and each tick
--   pulls it back if it slipped out, so the screen follows focus and the
--   click lands on a shown row. Not scrollBoxList itself: its focus also
--   hovers the row, and menu rows are never hovered (see the top of the file).
-- - false (the direct way): never scroll; rows out of view stay hidden and
--   are clicked hidden. The menu's ScrollBox holds the real, initialized row
--   frames, so that works too, and it never writes the scroll position. Set
--   this to false if scrolling a menu ever taints its rows (addon-driven
--   scrolling tainted the old hybrid scroll lists: wow-taint-scrolling).
dropdown.SCROLL_INTO_VIEW = true

-- The focus hooks that keep a scrolling menu's row in view (the scroll way).
-- Scrolling only when the row is out of view: every scroll of a menu
-- collapses its submenus (MenuMixin's OnScroll callback).
local function menuRowFocus(menuFrame, index, item)
    local scrollBox = menuFrame.ScrollBox
    local function bringIntoView()
        if not item:IsVisible() then
            scrollBox:ScrollToElementDataIndex(index)
        end
    end
    return { onFocus = bringIntoView, onFocusTick = bringIntoView }
end

-- Title rows are structure, not stops: each becomes the CONTEXT of the rows
-- under it, announced once when focus crosses into its section, never
-- landed on. A title with no rows under it (an informational line closing
-- a menu) has nothing to announce it, so it stays a readable text stop.
-- Menus that register row overrides keep their row numbering: titles still
-- occupy their index.
local function renderOneMenu(builder, menuFrame, levelIndex)
    builder:beginStop("menu:" .. levelIndex)
    builder:pushContext("menu:" .. levelIndex, L["Dropdown"])
    local rows, allShown = menuRows(menuFrame)
    local pendingTitle, pendingItem, pendingFocus = nil, nil, nil
    local sectionOpen = false
    local sections = 0

    local function flushPendingAsText()
        if pendingTitle ~= nil then
            emitItem(builder, pendingItem, pendingFocus)
            pendingTitle, pendingItem, pendingFocus = nil, nil, nil
        end
    end

    local function beforeRow()
        if pendingTitle == nil then
            return
        end
        if sectionOpen then
            builder:popContext()
        end
        sections = sections + 1
        builder:pushContext("section:" .. sections, pendingTitle)
        sectionOpen = true
        pendingTitle, pendingItem, pendingFocus = nil, nil, nil
    end

    local scrollInto = allShown and dropdown.SCROLL_INTO_VIEW
    for index, item in ipairs(rows) do
        local shown = allShown or item:IsShown()
        local focus = scrollInto and menuRowFocus(menuFrame, index, item) or nil
        local override = levelIndex == 1 and dropdown.active ~= nil and dropdown.active[index] or nil
        if type(override) == "function" then
            beforeRow()
            local ok, err = pcall(override, builder, item, index)
            if not ok then
                geterrorhandler()(err)
            end
        elseif shown then
            local title = titleText(item, shown)
            if title ~= nil then
                -- Back-to-back titles (the player's name, then "Interact")
                -- read as one: "Xynayya, Interact".
                if pendingTitle ~= nil then
                    title = pendingTitle .. ", " .. title
                end
                pendingTitle, pendingItem, pendingFocus = title, item, focus
            elseif item:GetObjectType() == "Button" then
                beforeRow()
                dropdown.emitRow(builder, item, focus)
            else
                -- a custom row with controls (the level range) is a row of
                -- its title's section, like a button row; without this its
                -- title merged into the next one ("Level Range, Armor")
                if #dropdown.rowControls(item) > 0 then
                    beforeRow()
                end
                emitItem(builder, item, focus)
            end
        end
    end
    flushPendingAsText()
    if sectionOpen then
        builder:popContext()
    end
    builder:popContext()
end

-- One screen per menu level. If this level vanished mid-tick (the sync
-- pops momentarily), render the deepest surviving menu so an empty render
-- never closes the whole stack.
local function renderLevel(level)
    return function(builder, screen)
        local root = dropdown.frame
        if root == nil or not root:IsShown() then
            return
        end
        local menus = openMenuFrames(root)
        local menuFrame = menus[level] or menus[#menus]
        if menuFrame == nil then
            return
        end
        renderOneMenu(builder, menuFrame, level)
    end
end

local function closeMenuFrame(menuFrame)
    if menuFrame ~= nil and menuFrame.Close ~= nil then
        pcall(menuFrame.Close, menuFrame)
    end
end

-- Called every frame from UIHost's update. Each open menu level is one
-- screen on the dropdown stack, synced both ways: Blizzard opening a
-- submenu pushes a screen (landing on its first item); the user popping a
-- screen (Escape) closes Blizzard's deepest menu; Blizzard collapsing
-- levels pops our screens.
function dropdown.update()
    local manager = Menu ~= nil and Menu.GetManager ~= nil and Menu:GetManager() or nil
    local open = manager ~= nil and manager:GetOpenMenu() or nil
    dropdown.frame = open
    if open == nil then
        if dropdown.stack ~= nil then
            WowVision.graphHost:close(dropdown.stack)
            dropdown.stack = nil
        end
        dropdown.depth = 0
        dropdown.active = nil
        dropdown.copyName = nil
        return
    end

    local host = WowVision.graphHost
    if dropdown.stack == nil then
        dropdown.stack = host:open({
            key = "dropdown",
            captureClose = true,
            -- an open dropdown menu takes letters (letter navigation, Host.lua)
            letterNavigation = true,
            onRequestClose = function()
                closeMenuFrame(dropdown.frame)
            end,
            render = renderLevel(1),
        })
        dropdown.depth = 1
    end

    local menus = openMenuFrames(open)
    local levels = #menus
    local screens = #dropdown.stack.screens
    if screens < dropdown.depth then
        -- The user popped a submenu screen: close Blizzard's deepest levels
        -- to match.
        for level = levels, screens + 1, -1 do
            closeMenuFrame(menus[level])
        end
        dropdown.depth = screens
    elseif levels > dropdown.depth then
        for level = dropdown.depth + 1, levels do
            host:push(dropdown.stack, { key = "dropdown:" .. level, render = renderLevel(level) })
        end
        dropdown.depth = levels
    elseif levels < dropdown.depth then
        -- Blizzard collapsed submenus (a pick, a hover elsewhere): pop ours.
        for _ = levels + 1, dropdown.depth do
            host:pop(dropdown.stack)
        end
        dropdown.depth = levels
    end
end
