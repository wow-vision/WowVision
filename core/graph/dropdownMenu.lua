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

-- Modern check and radio rows swap their mark texture's atlas by state.
local function atlasState(item)
    local mark = item.leftTexture1
    if mark == nil or mark.GetAtlas == nil then
        return nil
    end
    local atlas = mark:GetAtlas()
    if atlas == nil then
        return nil
    end
    if atlas:find("checkmark") ~= nil or atlas:find("radialtick") ~= nil then
        return true
    end
    if atlas:find("ticksquare") ~= nil or atlas:find("tickradial") ~= nil then
        return false
    end
    return nil
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
        -- A submenu parent: Enter opens its child menu, which appears as
        -- the next tab stop. ForceOpenSubmenu bypasses the manager's
        -- IsMouseOver gate (the reason synthetic hover can never work).
        local captured = item
        builder:addItem(ControlId.forObject(item), {
            controlType = graph.controlTypes.dropdown,
            announcements = { { text = label, kind = kinds.label } },
            onActivate = function()
                local description = descriptionOf(captured)
                if description == nil then
                    geterrorhandler()("dropdown submenu: no element description")
                    return
                end
                if description.ForceOpenSubmenu == nil then
                    geterrorhandler()("dropdown submenu: proxy lacks ForceOpenSubmenu")
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
    local checked = atlasState(item)
    if checked ~= nil then
        vtable.controlType = graph.controlTypes.toggle
        local captured = item
        tinsert(vtable.announcements, {
            text = function()
                return atlasState(captured) and L["Checked"] or L["Unchecked"]
            end,
            kind = kinds.value,
        })
    elseif legacyCheck ~= nil then
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

-- A frame counts as an open menu if it is shown and holds menu item
-- children (frames exposing GetElementDescription). No parent or ID
-- assumptions: both vary by client.
local function looksLikeMenu(frame)
    if not frame:IsShown() or frame.GetChildren == nil then
        return false
    end
    local children = { frame:GetChildren() }
    for i = 1, #children do
        if children[i].GetElementDescription ~= nil then
            return true
        end
    end
    return false
end

-- Every open menu frame in the chain: the root from the manager plus any
-- other live menu found by walking all frames. Sorted by left edge --
-- submenus anchor to their parent row's right, so this is chain order.
local function openMenuFrames(root)
    local menus = { root }
    local frame = EnumerateFrames()
    while frame ~= nil do
        if frame ~= root and looksLikeMenu(frame) then
            tinsert(menus, frame)
        end
        frame = EnumerateFrames(frame)
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

local function render(builder, screen)
    local root = dropdown.frame
    if root == nil or not root:IsShown() then
        return
    end
    for levelIndex, menuFrame in ipairs(openMenuFrames(root)) do
        renderOneMenu(builder, menuFrame, levelIndex)
    end
end

-- Called every frame from UIHost's update. The stack lives as long as ANY
-- menu is open; submenu levels come and go inside the per-tick rebuild.
function dropdown.update()
    local manager = Menu ~= nil and Menu.GetManager ~= nil and Menu:GetManager() or nil
    local open = manager ~= nil and manager:GetOpenMenu() or nil
    dropdown.frame = open
    if open == nil then
        if dropdown.stack ~= nil then
            WowVision.graphHost:close(dropdown.stack)
            dropdown.stack = nil
        end
        dropdown.active = nil
        return
    end
    if dropdown.stack == nil then
        dropdown.stack = WowVision.graphHost:open({ key = "dropdown", render = render })
    end
end
