local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local L = WowVision:getLocale()

-- The graph context menu: a pushed screen of actions for the focused node,
-- opened by the contextMenu binding. Entries come from two places:
--
-- * The node's own vtable: `contextActions` -- a list of entries or a
--   function(add, node) that calls add(entry) for each. Proxy factories
--   supply Left Click / Right Click / Drag by default.
-- * TAG HOOKS: a node's vtable lists `contextTags`; modules extend menus
--   for a tag with contextMenu.registerTagHook(tag, handler) where
--   handler(add, node) contributes entries.
--
-- Entry shapes:
--   { label = ..., onActivate = fn }                  -- plain action; menu closes after
--   { label = ..., click = { emulatedKey = "LeftButton", target = frameOrFn } }
--                                                     -- SECURE click on a real frame;
--                                                     -- menu stays open (hardware event)
--   { label = ..., submenu = function(add) ... end }  -- nested pushed screen
--   { label = ..., radio = true, isChecked = fn, onActivate = fn }
--                                                     -- state entry; menu closes after
local contextMenu = {
    tagHooks = {},
}
graph.contextMenu = contextMenu

function contextMenu.registerTagHook(tag, handler)
    if contextMenu.tagHooks[tag] == nil then
        contextMenu.tagHooks[tag] = {}
    end
    tinsert(contextMenu.tagHooks[tag], handler)
end

function contextMenu.collect(node)
    local entries = {}
    local function add(entry)
        tinsert(entries, entry)
    end
    local actions = node.vtable.contextActions
    if type(actions) == "function" then
        actions(add, node)
    elseif type(actions) == "table" then
        for _, entry in ipairs(actions) do
            add(entry)
        end
    end
    for _, tag in ipairs(node.vtable.contextTags or {}) do
        for _, hook in ipairs(contextMenu.tagHooks[tag] or {}) do
            hook(add, node)
        end
    end
    return entries
end

-- Pop every context-menu screen off the focused stack (after a leaf action).
local function closeMenus()
    local host = WowVision.graphHost
    local stack = host:focusedStack()
    while stack ~= nil and #stack.screens > 1 and stack.screens[#stack.screens].config._contextMenu do
        host:pop(stack)
    end
end

local function entryNode(entry, index)
    if entry.submenu ~= nil then
        return {
            controlType = graph.controlTypes.dropdown,
            announcements = { { text = entry.label, kind = kinds.label } },
            onActivate = function()
                contextMenu.pushEntries(entry.label, entry.submenu)
            end,
        }
    end
    if entry.click ~= nil then
        return {
            controlType = graph.controlTypes.button,
            announcements = { { text = entry.label, kind = kinds.label } },
            bindings = {
                {
                    binding = "leftClick",
                    type = "Click",
                    emulatedKey = entry.click.emulatedKey or "LeftButton",
                    target = entry.click.target,
                },
            },
        }
    end
    if entry.radio then
        return {
            controlType = graph.controlTypes.radio,
            announcements = {
                { text = entry.label, kind = kinds.label },
                {
                    text = function()
                        return entry.isChecked() and L["Checked"] or L["Unchecked"]
                    end,
                    kind = kinds.value,
                },
            },
            onActivate = function()
                entry.onActivate()
                closeMenus()
            end,
        }
    end
    return {
        controlType = graph.controlTypes.button,
        announcements = { { text = entry.label, kind = kinds.label } },
        onActivate = function()
            entry.onActivate()
            closeMenus()
        end,
    }
end

-- Push one menu level: label for the level, and either a ready entry list
-- or a function(add) contributing them. Entries re-collect every rebuild,
-- so radio states stay live.
function contextMenu.pushEntries(label, entriesOrFn)
    local host = WowVision.graphHost
    local stack = host:focusedStack()
    if stack == nil then
        return
    end
    host:push(stack, {
        key = "contextMenu:" .. tostring(label),
        _contextMenu = true,
        render = function(builder)
            local entries
            if type(entriesOrFn) == "function" then
                entries = {}
                entriesOrFn(function(entry)
                    tinsert(entries, entry)
                end)
            else
                entries = entriesOrFn
            end
            if #entries == 0 then
                return
            end
            builder:pushContext("contextMenu", label or L["Menu"])
            for index, entry in ipairs(entries) do
                builder:addItem(ControlId.structural("entry:" .. tostring(entry.label)), entryNode(entry, index))
            end
            builder:popContext()
        end,
    })
end

-- Open the context menu for the focused node.
function contextMenu.open()
    local host = WowVision.graphHost
    local screen = host:focusedScreen()
    if screen == nil then
        return
    end
    local node = screen.keyGraph:currentNode()
    if node == nil then
        return
    end
    local entries = contextMenu.collect(node)
    if #entries == 0 then
        WowVision:speak(L["Menu"] .. " " .. L["Empty"])
        return
    end
    contextMenu.pushEntries(L["Menu"], entries)
end
