local module = WowVision.base.scanner
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The scanner window (F9): the provider tree as expandable groups, one
-- tab stop, then a Refresh button. The tree is built once when the window
-- opens and again on Refresh; expansion state persists across opens.
-- With Scanner as Tree off, the same tree reads as a menu instead (one
-- screen per level, see "menu mode" below).

local WINDOW = "scanner"

-- Expansion memory outlives the screen (a fresh screen per open).
module._expanded = nil

local function maps()
    return WowVision.base.navigation and WowVision.base.navigation.maps or nil
end

local function ensureTree(screen)
    if screen._tree ~= nil then
        return screen._tree
    end
    if module._expanded == nil then
        screen._seedExpansion = true
    else
        -- Inherit the last open's expansion into this screen's own set (the
        -- builder already holds that table, so copy in rather than swap).
        for key in pairs(module._expanded) do
            screen.state.expanded[key] = true
        end
    end
    module._expanded = screen.state.expanded
    screen._tree = module:buildTree()
    -- opened from the quest log: the path to that quest unfolds and the
    -- scanner lands on it
    local questId = module.focusQuest
    module.focusQuest = nil
    local quests = WowVision.base.quests
    if questId ~= nil and quests ~= nil and quests.scannerQuestPath ~= nil then
        local key = "scanner"
        for _, part in ipairs(quests:scannerQuestPath(questId)) do
            key = key .. "/" .. part
            screen.state.expanded[key] = true
        end
        screen.state.expanded[key] = nil
        screen.state.nextSuggestedMove = ControlId.structural(key)
    end
    return screen._tree
end

local function isTree()
    return module.settings == nil or module.settings.asTree ~= false
end

-- F9. From the quest log the scanner lands on the quest the log is on.
function module:openFromKey()
    local quests = WowVision.base.quests
    self.focusQuest = quests ~= nil and quests.safeLogQuest ~= nil and quests:safeLogQuest() or nil
    local instance = WowVision.UIHost:openWindow(WINDOW)
    if not isTree() then
        -- the menu walks to the quest here; the tree unfolds it as it renders
        local questId = self.focusQuest
        self.focusQuest = nil
        if questId ~= nil and instance ~= nil and instance.stack ~= nil
            and quests ~= nil and quests.scannerQuestPath ~= nil then
            module:openMenuPath(instance.stack, quests:scannerQuestPath(questId))
        end
    end
end

local function resolveChildren(node)
    if type(node.children) == "function" then
        local ok, list = pcall(node.children)
        if not ok then
            geterrorhandler()(list)
            list = { { key = "error", label = L["Error"] .. " " .. tostring(list) } }
        end
        node.children = list or {}
    end
    return node.children
end

-- A label may be a function, read each time it is spoken (live state on a
-- snapshot node); the beacon and the details title take its current text.
local function labelText(node)
    if type(node.label) == "function" then
        local ok, text = pcall(node.label)
        return ok and text or nil
    end
    return node.label
end

-- A list of entries known to be empty (a category with nothing in it):
-- it reads Empty and does not open, in the tree as in the menu. Entries
-- built only when opened are known once opened.
local function knownEmpty(node)
    return type(node.children) == "table" and #node.children == 0
end

local function emptyText(node)
    if knownEmpty(node) then
        return L["Empty"]
    end
    return nil
end

local function whereText(node)
    local m = maps()
    if m == nil or node.x == nil then
        return nil
    end
    return m:whereText(node.x, node.y)
end

-- Enter on a placed node: the navigation window opens aimed at it, with the
-- closest entry point and the node as destination preselected, so Enter
-- there routes through the waypoint network (a straight beacon when the
-- continent has no map data).
local function beaconTo(node)
    local m = maps()
    if m == nil then
        return
    end
    WowVision.UIHost:closeWindow(WINDOW)
    if m.openNavigationTo ~= nil then
        m:openNavigationTo(node.x, node.y, labelText(node), node.onArrive, node.routeData, node.match)
    else
        m:beaconTo(node.x, node.y, labelText(node), node.onArrive)
    end
end

-- Backspace (or the context menu) on a category: the nearest placed entry in
-- it, subcategories included, is announced and routed to like Enter on it.
local function navigateNearest(node)
    local m = maps()
    if m == nil then
        return
    end
    local nearest, distance = WowVision.scannerNearest.pick(resolveChildren(node), function(x, y)
        return m:distanceTo(x, y)
    end, resolveChildren)
    if nearest == nil then
        WowVision:notify(L["Nothing to navigate to"])
        return
    end
    local text = labelText(nearest) or ""
    local where = whereText(nearest)
    if where ~= nil then
        text = text .. ", " .. where
    end
    WowVision:notify(text)
    beaconTo(nearest)
end

local function pushDetails(node)
    local host = WowVision.graphHost
    local stack = host:focusedStack()
    if stack == nil then
        return
    end
    host:push(stack, {
        key = "details",
        render = function(builder)
            local lines = node.details
            if type(lines) == "function" then
                lines = lines()
            end
            builder:pushContext("details", labelText(node))
            if lines == nil or #lines == 0 then
                builder:addItem(ControlId.structural("empty"), nodes.text({ label = L["Empty"] }))
            end
            for index, line in ipairs(lines or {}) do
                builder:addItem(ControlId.structural("line:" .. index), nodes.text({ label = line }))
            end
            builder:popContext()
        end,
    })
end

local function vtableFor(node, screen, id)
    if node.toggle ~= nil then
        local vtable = nodes.toggle({ label = node.label, get = node.toggle.get, set = node.toggle.set })
        if node.details ~= nil then
            vtable.onSecondary = function()
                pushDetails(node)
            end
        end
        return vtable
    end
    local announcements = { { text = node.label, kind = kinds.label } }
    if node.nameDetail ~= nil then
        -- A label part: it reads right after the name, before the role word.
        tinsert(announcements, { text = node.nameDetail, kind = kinds.label })
    end
    if node.detail ~= nil then
        tinsert(announcements, { text = node.detail, kind = kinds.value })
    end
    if node.x ~= nil then
        -- A value part, not a position part: the auto-stamped "n of m"
        -- still reads after it.
        tinsert(announcements, {
            text = function()
                return whereText(node)
            end,
            kind = kinds.value,
        })
    end
    if node.children ~= nil then
        -- "Empty" when there is nothing to open (known before opening for a
        -- category, after it for entries built when opened)
        tinsert(announcements, {
            text = function()
                return emptyText(node)
            end,
            kind = kinds.value,
        })
    end
    local vtable = { announcements = announcements }
    if node.children ~= nil then
        vtable.controlType = graph.controlTypes.group
    elseif node.x ~= nil or node.onActivate ~= nil or node.unit ~= nil then
        vtable.controlType = graph.controlTypes.button
    else
        vtable.controlType = graph.controlTypes.text
    end
    if node.unit ~= nil then
        -- Enter targets the unit; targeting is protected, so it is the
        -- game's own secure target action bound to Enter.
        vtable.bindings = { { binding = "leftClick", type = "Target", unit = node.unit } }
    elseif node.onActivate ~= nil then
        vtable.onActivate = node.onActivate
    elseif node.x ~= nil then
        vtable.onActivate = function()
            beaconTo(node)
        end
    elseif knownEmpty(node) then
        -- nothing to open: Enter says Empty again
        vtable.onActivate = function() end
        vtable.stateText = function()
            return L["Empty"]
        end
    elseif node.children ~= nil then
        -- Enter on a plain category toggles it, like right and left do.
        vtable.onActivate = function()
            if screen.state.expanded[id.key] then
                screen.state.expanded[id.key] = nil
            else
                screen.state.expanded[id.key] = true
            end
        end
        vtable.stateText = function()
            local expanded = screen.state.expanded[id.key] == true
            return graph.announcer.expandedStateText(expanded)
        end
        -- Backspace on a category routes to its nearest entry; the context
        -- menu (Shift-F10) offers the same.
        vtable.onSecondary = function()
            navigateNearest(node)
        end
        vtable.contextActions = {
            {
                label = L["Navigate to Nearest"],
                onActivate = function()
                    navigateNearest(node)
                end,
            },
        }
    end
    if node.details ~= nil then
        vtable.onSecondary = function()
            pushDetails(node)
        end
    end
    vtable.tooltip = node.tooltip
    return vtable
end

local function emit(builder, screen, node, path)
    local key = path .. "/" .. tostring(node.key)
    local id = ControlId.structural(key)
    if node.children == nil or knownEmpty(node) then
        builder:addItem(id, vtableFor(node, screen, id))
        return
    end
    if node.expanded and screen._seedExpansion then
        screen.state.expanded[key] = true
    end
    builder:beginGroup(id, vtableFor(node, screen, id))
    if builder:isExpanded(id) then
        local children = resolveChildren(node)
        if #children == 0 then
            builder:addItem(ControlId.structural(key .. "/empty"), nodes.text({ label = L["Empty"] }))
        end
        for _, child in ipairs(children) do
            emit(builder, screen, child, key)
        end
    end
    builder:endGroup()
end

-- ---- menu mode (Scanner as Tree off) ----
--
-- One screen per level, like the WowVision menu: the root lists the
-- categories, Enter (or Right) on an entry with children opens a screen
-- with them, Escape (or Left) goes back. Enter goes deeper as long as an
-- entry has children, so the menu reaches every level the tree does; only
-- on the last level does Enter run the entry's action (the navigation
-- window for a place). All levels of one open
-- share a session holding the tree; each level finds its entries by the
-- keys of its path, so Refresh on any level rebuilds them all.

local function pathKey(path)
    if #path == 0 then
        return "scanner"
    end
    return "scanner/" .. table.concat(path, "/")
end

local function sessionTree(session)
    if session.tree == nil then
        session.tree = module:buildTree()
    end
    return session.tree
end

-- The entries at a path of keys ({} = the categories); nil when a level on
-- the way is gone (after a Refresh).
local function entriesAt(session, path)
    local list = sessionTree(session)
    for _, key in ipairs(path) do
        local found = nil
        for _, node in ipairs(list) do
            if tostring(node.key) == key then
                found = node
                break
            end
        end
        if found == nil or found.children == nil then
            return nil
        end
        list = resolveChildren(found)
    end
    return list
end

local function nodeAt(session, path)
    if #path == 0 then
        return nil
    end
    local parent = {}
    for i = 1, #path - 1 do
        parent[i] = path[i]
    end
    for _, node in ipairs(entriesAt(session, parent) or {}) do
        if tostring(node.key) == path[#path] then
            return node
        end
    end
    return nil
end

local renderMenuLevel

local function pushMenuLevel(stack, session, path, label)
    return WowVision.graphHost:push(stack, {
        key = pathKey(path),
        letterNavigation = true,
        render = function(builder, screen)
            renderMenuLevel(builder, screen, session, path, label)
        end,
    })
end

local function menuVtable(node, screen, session, path, id)
    local vtable = vtableFor(node, screen, id)
    local host = WowVision.graphHost
    if node.children ~= nil and node.toggle == nil then
        local childPath = {}
        for i, key in ipairs(path) do
            childPath[i] = key
        end
        tinsert(childPath, tostring(node.key))
        -- An empty entry stays where it is: Enter reads its state (Empty),
        -- Right says Empty itself.
        local function descend()
            local stack = host:focusedStack()
            if stack ~= nil and #resolveChildren(node) > 0 then
                pushMenuLevel(stack, session, childPath, node.label)
                return true
            end
            return false
        end
        -- Enter goes one level deeper as long as there is one, as in the
        -- tree; a place to walk to is reached on the last level (the
        -- quest's objective, its target, the target's spawn).
        vtable.controlType = graph.controlTypes.button
        vtable.stateText = function()
            return emptyText(node)
        end
        vtable.onActivate = descend
        vtable.onRight = function()
            if not descend() then
                host:_speak(L["Empty"])
            end
        end
    end
    if #path > 0 then
        vtable.onLeft = function()
            local stack = host:focusedStack()
            if stack ~= nil then
                host:pop(stack)
            end
        end
    end
    return vtable
end

local function addRefresh(builder, session)
    builder:beginStop("refresh")
    builder:addItem(
        ControlId.structural("refresh"),
        nodes.button({
            label = L["Refresh"],
            onActivate = function()
                session.tree = nil
                WowVision:speak(L["Refreshed"])
            end,
        })
    )
end

renderMenuLevel = function(builder, screen, session, path, label)
    local base = pathKey(path)
    builder:beginStop("tree")
    builder:pushContext(base, label)
    local entries = entriesAt(session, path)
    if entries == nil or #entries == 0 then
        builder:addItem(ControlId.structural(base .. "/empty"), nodes.text({ label = L["Empty"] }))
    end
    for _, node in ipairs(entries or {}) do
        local id = ControlId.structural(base .. "/" .. tostring(node.key))
        builder:addItem(id, menuVtable(node, screen, session, path, id))
    end
    builder:popContext()
    addRefresh(builder, session)
end

-- Opened from the quest log: one level per step of the quest's path, each
-- on the entry the next one opened, the last on the quest itself.
function module:openMenuPath(stack, keys)
    local root = stack.screens[1]
    if root == nil then
        return
    end
    root._session = root._session or {}
    local session = root._session
    local path = {}
    local screen = root
    for index, key in ipairs(keys) do
        screen.state.nextSuggestedMove = ControlId.structural(pathKey(path) .. "/" .. key)
        if index == #keys then
            break
        end
        tinsert(path, key)
        local node = nodeAt(session, path)
        if node == nil or node.children == nil then
            break
        end
        local levelPath = {}
        for i, part in ipairs(path) do
            levelPath[i] = part
        end
        screen = pushMenuLevel(stack, session, levelPath, node.label)
    end
end

local function renderMenu(builder, screen)
    screen._session = screen._session or {}
    renderMenuLevel(builder, screen, screen._session, {}, L["Scanner"])
end

local function render(builder, screen)
    -- the menu takes letters like the WowVision menu; the tree does not
    screen.config.letterNavigation = not isTree()
    if not isTree() then
        renderMenu(builder, screen)
        return
    end
    local tree = ensureTree(screen)

    builder:beginStop("tree")
    builder:pushContext("scanner", L["Scanner"])
    for _, category in ipairs(tree) do
        emit(builder, screen, category, "scanner")
    end
    screen._seedExpansion = nil
    builder:popContext()

    builder:beginStop("refresh")
    builder:addItem(
        ControlId.structural("refresh"),
        nodes.button({
            label = L["Refresh"],
            onActivate = function()
                screen._tree = nil
                WowVision:speak(L["Refreshed"])
            end,
        })
    )
end

module:registerWindow({
    type = "ManualWindow",
    name = WINDOW,
    graphScreen = { render = render, captureClose = true },
})

module:registerBinding({
    type = "Script",
    key = "scanner/open",
    label = L["Scanner"],
    inputs = { "F9" },
    script = "/run WowVision.base.scanner:openFromKey()",
})
