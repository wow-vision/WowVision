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
    local labelRegion, legacyCheck
    for _, region in ipairs({ item:GetRegions() }) do
        local kind = region:GetObjectType()
        if kind == "FontString" and labelRegion == nil then
            labelRegion = region
        elseif kind == "Texture" and region:GetTexture() == LEGACY_CHECK_TEXTURE then
            legacyCheck = region
        end
    end
    return labelRegion, legacyCheck
end

local function emitItem(builder, item)
    local labelRegion, legacyCheck = itemRegions(item)
    local label = function()
        return labelRegion ~= nil and labelRegion:GetText() or nil
    end

    if item:GetObjectType() ~= "Button" then
        if labelRegion ~= nil then
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

local function renderOneMenu(builder, menuFrame, levelIndex)
    builder:beginStop("menu:" .. levelIndex)
    builder:pushContext("menu:" .. levelIndex, L["Dropdown"])
    local frames = { menuFrame:GetChildren() }
    for i = 3, #frames do
        local item = frames[i]
        local index = i - 2
        local override = levelIndex == 1 and dropdown.active ~= nil and dropdown.active[index] or nil
        if type(override) == "function" then
            local ok, err = pcall(override, builder, item, index)
            if not ok then
                geterrorhandler()(err)
            end
        elseif item:IsShown() then
            emitItem(builder, item)
        end
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
