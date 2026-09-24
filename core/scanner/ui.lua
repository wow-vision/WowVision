local module = WowVision.base.scanner
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The scanner window (F9): the provider tree as expandable groups, one
-- tab stop, then a Refresh button. The tree is built once when the window
-- opens and again on Refresh; expansion state persists across opens.

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
    return screen._tree
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

local function whereText(node)
    local m = maps()
    if m == nil or node.x == nil then
        return nil
    end
    return m:whereText(node.x, node.y)
end

local function beaconTo(node)
    local m = maps()
    if m == nil then
        return
    end
    m:beaconTo(node.x, node.y, node.label, node.onArrive)
    WowVision.UIHost:closeWindow(WINDOW)
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
            builder:pushContext("details", node.label)
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
    local vtable = { announcements = announcements }
    if node.children ~= nil then
        vtable.controlType = graph.controlTypes.group
    elseif node.x ~= nil or node.onActivate ~= nil then
        vtable.controlType = graph.controlTypes.button
    else
        vtable.controlType = graph.controlTypes.text
    end
    if node.onActivate ~= nil then
        vtable.onActivate = node.onActivate
    elseif node.x ~= nil then
        vtable.onActivate = function()
            beaconTo(node)
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
    end
    if node.details ~= nil then
        vtable.onSecondary = function()
            pushDetails(node)
        end
    end
    return vtable
end

local function emit(builder, screen, node, path)
    local key = path .. "/" .. tostring(node.key)
    local id = ControlId.structural(key)
    if node.children == nil then
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

local function render(builder, screen)
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
    script = "/run WowVision.UIHost:openWindow('scanner')",
})
