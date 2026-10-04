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

local function emitItem(builder, item)
    local fontStrings, legacyCheck = itemRegions(item)
    local label = rowLabel(fontStrings)

    if item:GetObjectType() ~= "Button" then
        if #fontStrings > 0 then
            builder:addItem(ControlId.forObject(item), nodes.text({ label = label }))
        end
        return
    end

    if isSubmenuRow(item) then
        -- A submenu parent: Enter opens its child menu, which the watcher
        -- pushes as a new screen (landing on its first item).
        -- ForceOpenSubmenu bypasses the manager's IsMouseOver gate (the
        -- reason synthetic hover can never work).
        local captured = item
        builder:addItem(ControlId.forObject(item), {
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
        })
        return
    end

    -- "Copy Character Name" calls the protected CopyToClipboard. In a menu
    -- OPENED by addon code (a chat line's player menu) the menu's own data is
    -- tainted, so even a secure click on the row is blocked. The opener
    -- leaves the name in dropdown.copyName and the row copies through an
    -- edit box instead. Menus opened by secure clicks keep the real row.
    if dropdown.copyName ~= nil and COPY_CHARACTER_NAME ~= nil and label() == COPY_CHARACTER_NAME then
        local name = dropdown.copyName
        builder:addItem(ControlId.forObject(item), {
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
        })
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
    builder:addItem(ControlId.forObject(item), vtable)
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
function dropdown.emitRow(builder, item)
    local buttons = dropdown.rowButtons(item)
    if #buttons == 0 then
        emitItem(builder, item)
        return
    end
    builder:startRow()
    emitItem(builder, item)
    for _, button in ipairs(buttons) do
        builder:addItem(
            ControlId.forObject(button),
            nodes.proxyButton({
                target = button,
                allowHidden = true,
                label = dropdown.rowButtonLabel(button),
            })
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

-- Every open menu frame in the chain: the root from the manager plus every
-- tracked menu frame currently shown. Sorted by left edge -- submenus
-- anchor to their parent row's right, so this is chain order.
local function openMenuFrames(root)
    local menus = { root }
    for frame in pairs(trackedMenus) do
        if frame ~= root and frame:IsShown() then
            tinsert(menus, frame)
        end
    end
    table.sort(menus, function(a, b)
        return (a:GetLeft() or 0) < (b:GetLeft() or 0)
    end)
    return menus
end
graph.dropdown.openMenuFrames = openMenuFrames

-- A title row (the player's name, "Interact", "Other Options"): a shown
-- non-button row carrying text. Returns its text, or nil for anything else
-- (buttons, dividers, spacers).
local function titleText(item)
    if not item:IsShown() or item:GetObjectType() == "Button" then
        return nil
    end
    return rowLabel(itemRegions(item))()
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
    local frames = { menuFrame:GetChildren() }
    local pendingTitle, pendingItem = nil, nil
    local sectionOpen = false
    local sections = 0

    local function flushPendingAsText()
        if pendingTitle ~= nil then
            emitItem(builder, pendingItem)
            pendingTitle, pendingItem = nil, nil
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
        pendingTitle, pendingItem = nil, nil
    end

    for i = 3, #frames do
        local item = frames[i]
        local index = i - 2
        local override = levelIndex == 1 and dropdown.active ~= nil and dropdown.active[index] or nil
        if type(override) == "function" then
            beforeRow()
            local ok, err = pcall(override, builder, item, index)
            if not ok then
                geterrorhandler()(err)
            end
        elseif item:IsShown() then
            local title = titleText(item)
            if title ~= nil then
                -- Back-to-back titles (the player's name, then "Interact")
                -- read as one: "Xynayya, Interact".
                if pendingTitle ~= nil then
                    title = pendingTitle .. ", " .. title
                end
                pendingTitle, pendingItem = title, item
            elseif item:GetObjectType() == "Button" then
                beforeRow()
                dropdown.emitRow(builder, item)
            else
                emitItem(builder, item)
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
