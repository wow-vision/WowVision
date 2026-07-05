local graph = WowVision.graph

--[[
Nodes and vtables are plain tables (they are rebuilt every tick; keep them lean).

A node:
  id             ControlId
  vtable         see below
  transitions    { up/down/left/right/next/previous = { destination = ControlId, label = string? } }
  parent         parent node within THIS render (the announcement hierarchy), or nil
  focusable      false only for pure-structure context levels (never in nodes/order)
  expandable     true for a group header that can expand/collapse
  expanded       the group's state at this render
  stopKey        tab stop membership
  positionIndex / positionCount   auto-stamped "n of m" (absent = none)
  suppressChildPositions          on a parent: its direct children get no auto position

A vtable:
  announcements  required, at least one part; the first part is the label.
                 part = { text = string|function, live = bool?, kind = string? }
  controlType    a registry value from graph.controlTypes, or nil
  onActivate / onSecondary        primary/secondary activation
  onAdjust(sign, large)           horizontal value adjust; when set, left/right do not navigate
  stateText      function: synchronous feedback line after activate/adjust (host speaks, interrupting)
  onExpand / onCollapse           override how a group's expansion state changes
  speaksOwnExpansion / speaksOwnPosition   the announcements already include these
  bindings       input binding declarations activated while focused (host layer)
  onFocus / onUnfocus             lifecycle hooks (host layer)
]]

-- Announcement part kinds: a part's kind drives the control type's speak order,
-- lets a node part override the type's common part of the same kind, and keys
-- the user's per-kind announcement settings.
graph.kinds = {
    label = "label",
    role = "role",
    value = "value",
    selected = "selected",
    enabled = "enabled",
    position = "position",
}

-- Edge directions. next/previous are the tab edges; when a node has no explicit
-- tab transition, KeyGraph falls back to cycling tab stops.
graph.directions = {
    up = true,
    right = true,
    down = true,
    left = true,
    next = true,
    previous = true,
}

-- A part's text may be a plain string or a function resolved at speak time.
function graph.resolveText(part)
    if part == nil then
        return nil
    end
    local text = part.text
    if type(text) == "function" then
        local ok, value = pcall(text)
        if ok then
            return value
        end
        return nil
    end
    return text
end

local Render = {}
Render.__index = Render

function Render:nodeAt(id)
    if id == nil then
        return nil
    end
    return self.nodes[id.key]
end

-- One built snapshot of a graph: nodes keyed by structural key, declaration
-- order, and where focus starts with no prior position. Rebuilt per operation
-- and thrown away; live state belongs in node callbacks, not here.
function graph.newRender()
    return setmetatable({ startKey = nil, nodes = {}, order = {} }, Render)
end

-- The persistent cursor for a graph, the only thing that survives between
-- renders.
function graph.newState()
    return {
        curKey = nil, -- focused ControlId (carries its reference for tier-1 recovery)
        curStopKey = nil, -- the focused node's stop, for whole-stop-vanished recovery
        keyOrder = nil, -- down-right total order from the previous render
        nextSuggestedMove = nil, -- one-shot focus jump, consumed on next reconcile
        stopMemory = {}, -- stopKey -> ControlId: where tab lands re-entering a stop
        expanded = {}, -- structural key -> true: the expanded groups
    }
end
