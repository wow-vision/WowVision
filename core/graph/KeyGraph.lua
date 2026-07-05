local graph = WowVision.graph
local resolveText = graph.resolveText
local kinds = graph.kinds

-- The navigation engine: a directed graph of controls rebuilt from a render
-- callback on each operation, with focus persisting in an external state table
-- (graph.newState). The engine never speaks -- operations return results the
-- host announces. Two invariants:
--
-- Down-right total order (computeOrder): from the start node, go right until
-- stuck, queueing each down -- visits a planar UI in reading order. Nodes the
-- walk can't reach (later tab stops) append in declaration order.
--
-- Focus recovery on rebuild (reconcile): if the focused control vanished, land
-- on the nearest survivor rather than the start -- following the backing object
-- that moved (tier 1) or the structural key whose object was rebuilt (tier 2)
-- first.
local KeyGraph = WowVision.Class("KeyGraph")
graph.KeyGraph = KeyGraph

function KeyGraph:initialize(renderCallback, state)
    self.renderCallback = renderCallback
    self.state = state
    self.current = nil -- the most recent render, or nil if not rendered / empty
end

function KeyGraph:currentNode()
    if self.current == nil then
        return nil
    end
    return self.current:nodeAt(self.state.curKey)
end

-- Rebuild the render and reconcile focus into it. False when the callback
-- produced nothing (the caller should treat the graph as closed/empty).
function KeyGraph:rerender()
    local render = self.renderCallback()
    if render == nil or #render.order == 0 then
        self.current = nil
        return false
    end
    self.current = render
    KeyGraph.reconcile(render, self.state)
    return true
end

local function indexOf(order, id)
    for i, key in ipairs(order) do
        if key == id then
            return i
        end
    end
    return nil
end

local function rememberStop(state, node)
    if node.stopKey ~= nil then
        state.stopMemory[node.stopKey] = node.id
    end
end

-- The first node in a stop that reads as SELECTED -- carries a non-empty
-- selected-kind part (the checked radio, the current tab) -- or nil.
function KeyGraph.selectedNodeInStop(render, stopKey)
    for _, node in ipairs(render.order) do
        if node.stopKey == stopKey and node.vtable ~= nil and node.vtable.announcements ~= nil then
            for _, part in ipairs(node.vtable.announcements) do
                if part ~= nil and part.kind == kinds.selected then
                    local text = resolveText(part)
                    if text ~= nil and text ~= "" then
                        return node
                    end
                end
            end
        end
    end
    return nil
end

-- Where focus lands entering a stop with no active cursor: the remembered
-- position, else the selected member, else the stop's first node.
function KeyGraph.stopLanding(render, state, stopKey)
    local remembered = state.stopMemory[stopKey]
    if remembered ~= nil then
        local node = render:nodeAt(remembered)
        if node ~= nil and node.stopKey == stopKey then
            return node
        end
    end
    local selected = KeyGraph.selectedNodeInStop(render, stopKey)
    if selected ~= nil then
        return selected
    end
    for _, node in ipairs(render.order) do
        if node.stopKey == stopKey then
            return node
        end
    end
    return nil
end

-- Move focus from state.curKey to a valid control in the render, then
-- recompute the traversal order.
function KeyGraph.reconcile(render, state)
    -- Honor a pending suggested move first, if its target still exists
    -- (consumed either way).
    if state.nextSuggestedMove ~= nil then
        local suggested = render:nodeAt(state.nextSuggestedMove)
        if suggested ~= nil then
            state.curKey = suggested.id
        end
        state.nextSuggestedMove = nil
    end

    local old = state.curKey
    local resolved = nil

    if old ~= nil then
        -- Tier 1: the same backing object, even if its structural key changed
        -- (the object moved).
        if old.reference ~= nil then
            for _, node in ipairs(render.order) do
                if node.id:referenceMatches(old.reference) then
                    resolved = node.id
                    break
                end
            end
        end

        -- Tier 2: the same structural key, even if the backing object was
        -- rebuilt.
        if resolved == nil then
            local structural = render.nodes[old.key]
            if structural ~= nil then
                resolved = structural.id
            end
        end

        -- Fallback: nearest survivor walking the previous order backward.
        if resolved == nil and state.keyOrder ~= nil then
            local oldIndex = indexOf(state.keyOrder, old)
            if oldIndex ~= nil then
                for i = oldIndex, 1, -1 do
                    local survivor = render.nodes[state.keyOrder[i].key]
                    if survivor ~= nil then
                        resolved = survivor.id
                        break
                    end
                end
            end
        end
    end

    -- Nothing matched (or first render): the start node, preferring the
    -- SELECTED member of its stop.
    if resolved == nil then
        local startNode = render:nodeAt(render.startKey)
        local selected = startNode ~= nil and KeyGraph.selectedNodeInStop(render, startNode.stopKey) or nil
        resolved = (selected ~= nil and selected.id) or (startNode ~= nil and startNode.id) or render.startKey
    end

    state.curKey = resolved
    local node = render:nodeAt(resolved)
    if node ~= nil then
        rememberStop(state, node)
    end
    state.keyOrder = KeyGraph.computeOrder(render)
end

-- The down-right total order: go right until stuck (recording each node),
-- queue every down for a later pass, repeat -- then append any node the walk
-- never reached in declaration order, so the order is total.
function KeyGraph.computeOrder(render)
    local order = {}
    local seen = {}
    local fringe = { render.startKey }

    local i = 1
    while i <= #fringe do
        local key = fringe[i]
        while key ~= nil and not seen[key.key] do
            seen[key.key] = true
            tinsert(order, key)
            local node = render.nodes[key.key]
            if node == nil then
                break
            end
            local down = node.transitions.down
            if down ~= nil then
                tinsert(fringe, down.destination)
            end
            local right = node.transitions.right
            if right == nil then
                break
            end
            key = right.destination
        end
        i = i + 1
    end

    for _, node in ipairs(render.order) do
        if not seen[node.id.key] then
            seen[node.id.key] = true
            tinsert(order, node.id)
        end
    end
    return order
end

function KeyGraph:_setCurrent(node)
    self.state.curKey = node.id
    rememberStop(self.state, node)
end

-- Operation results are plain tables:
--   move result: { moved, from, to, transitionLabel }
--     not moved (at an edge / empty) -> to == from
--   tree result: { kind, move } where kind is "none" (not applicable; the
--     caller decides consume/bubble), "expanded", "collapsed", "emptyGroup",
--     "descended", "ascended", or "leaf"; move is set for descended/ascended.

-- One step in a direction. next/previous follow an explicit tab edge when the
-- node has one, else cycle tab stops (landing on the remembered position).
function KeyGraph:move(dir)
    local result = { moved = false }
    if not self:rerender() then
        return result
    end
    local node = self:currentNode()
    result.from = node
    result.to = node
    if node == nil then
        return result
    end

    local transition = node.transitions[dir]
    if transition == nil and (dir == "next" or dir == "previous") then
        return self:_moveStop(node, dir == "next" and 1 or -1, true)
    end

    local dest = transition ~= nil and self.current:nodeAt(transition.destination) or nil
    if dest == nil or dest == node then
        return result
    end
    self:_setCurrent(dest)
    result.to = dest
    result.moved = true
    result.transitionLabel = transition.label
    return result
end

-- As far as possible in a direction (home/end within a row or column).
function KeyGraph:moveToEdge(dir)
    local result = { moved = false }
    if not self:rerender() then
        return result
    end
    local node = self:currentNode()
    result.from = node
    result.to = node
    if node == nil then
        return result
    end

    local cur = node
    while true do
        local transition = cur.transitions[dir]
        if transition == nil then
            break
        end
        local dest = self.current:nodeAt(transition.destination)
        if dest == nil or dest == cur then
            break
        end
        cur = dest
    end

    if cur ~= node then
        self:_setCurrent(cur)
        result.to = cur
        result.moved = true
    end
    return result
end

function KeyGraph:_stopOrder()
    local stops = {}
    local seen = {}
    for _, node in ipairs(self.current.order) do
        if node.stopKey ~= nil and not seen[node.stopKey] then
            seen[node.stopKey] = true
            tinsert(stops, node.stopKey)
        end
    end
    return stops
end

-- Cycle to the next/previous tab stop (declaration order), landing on the
-- stop's remembered position (else its selected member, else its first node).
function KeyGraph:moveStop(dir, wrap)
    local result = { moved = false }
    if not self:rerender() then
        return result
    end
    local node = self:currentNode()
    if node == nil then
        return result
    end
    return self:_moveStop(node, dir, wrap)
end

function KeyGraph:_moveStop(node, dir, wrap)
    local result = { moved = false, from = node, to = node }

    local stops = self:_stopOrder()
    if #stops <= 1 then
        return result
    end
    local idx = nil
    for i, stop in ipairs(stops) do
        if stop == node.stopKey then
            idx = i
            break
        end
    end
    if idx == nil then
        return result
    end
    local target = idx + dir
    if wrap then
        target = ((target - 1) % #stops) + 1
    end
    if target < 1 or target > #stops or target == idx then
        return result
    end

    local dest = KeyGraph.stopLanding(self.current, self.state, stops[target])
    if dest == nil then
        return result
    end
    self:_setCurrent(dest)
    result.to = dest
    result.moved = true
    return result
end

-- Move focus to a specific control (a node just revealed, a screen's chosen
-- landing). False when it isn't in the render.
function KeyGraph:focus(id)
    if id == nil or not self:rerender() then
        return false
    end
    local node = self.current:nodeAt(id)
    if node == nil then
        return false
    end
    self:_setCurrent(node)
    return true
end

-- Tier-1 focus sync from the game: if a node's backing object is `reference`,
-- move focus there. True if focus changed nodes.
function KeyGraph:focusByReference(reference)
    if reference == nil or self.current == nil then
        return false
    end
    for _, node in ipairs(self.current.order) do
        if node.id:referenceMatches(reference) then
            local changed = self.state.curKey ~= node.id
            self:_setCurrent(node)
            return changed
        end
    end
    return false
end

-- ---- tree operations (right/left semantics for expandable groups) ----

-- Is this node part of an expandable structure (itself a group, or under one)?
-- The host uses this to decide whether left/right get tree semantics.
function KeyGraph.inTree(node)
    local n = node
    while n ~= nil do
        if n.expandable then
            return true
        end
        n = n.parent
    end
    return false
end

-- Change a group's expansion: through its vtable override when declared, else
-- the persistent set.
function KeyGraph:_setExpanded(group, expanded)
    if expanded and group.vtable.onExpand ~= nil then
        group.vtable.onExpand()
        return
    end
    if not expanded and group.vtable.onCollapse ~= nil then
        group.vtable.onCollapse()
        return
    end
    if expanded then
        self.state.expanded[group.id.key] = true
    else
        self.state.expanded[group.id.key] = nil
    end
end

function KeyGraph:_firstChildOf(group)
    for _, node in ipairs(self.current.order) do
        if node.parent == group then
            return node
        end
    end
    return nil
end

-- Right on a group: expand (auto-recollapse when it turns out empty), or
-- descend into an expanded one. Right elsewhere in a tree: leaf (consume).
function KeyGraph:treeRight()
    local result = { kind = "none" }
    if not self:rerender() then
        return result
    end
    local node = self:currentNode()
    if node == nil then
        return result
    end

    if node.expandable and not node.expanded then
        self:_setExpanded(node, true)
        if not self:rerender() then
            return result
        end
        local header = self.current:nodeAt(node.id)
        if header == nil then
            return result
        end
        if self:_firstChildOf(header) == nil then
            -- A lazy drill-in that resolved to nothing: don't leave a silent
            -- empty-expanded node.
            self:_setExpanded(header, false)
            self:rerender()
            result.kind = "emptyGroup"
            return result
        end
        result.kind = "expanded"
        return result
    end

    if node.expandable and node.expanded then
        local child = self:_firstChildOf(node)
        if child == nil then
            result.kind = "leaf"
            return result
        end
        self:_setCurrent(child)
        result.kind = "descended"
        result.move = { moved = true, from = node, to = child }
        return result
    end

    result.kind = KeyGraph.inTree(node) and "leaf" or "none"
    return result
end

-- Left on an expanded group: collapse. Left elsewhere in a tree: ascend to the
-- nearest focusable ancestor.
function KeyGraph:treeLeft()
    local result = { kind = "none" }
    if not self:rerender() then
        return result
    end
    local node = self:currentNode()
    if node == nil then
        return result
    end

    if node.expandable and node.expanded then
        self:_setExpanded(node, false)
        self:rerender() -- focus stays on the header by identity
        result.kind = "collapsed"
        return result
    end

    local p = node.parent
    while p ~= nil do
        if p.focusable ~= false and self.current.nodes[p.id.key] ~= nil then
            local target = self.current:nodeAt(p.id)
            self:_setCurrent(target)
            result.kind = "ascended"
            result.move = { moved = true, from = node, to = target }
            return result
        end
        p = p.parent
    end

    result.kind = KeyGraph.inTree(node) and "leaf" or "none"
    return result
end

-- Home/end inside a tree: the first/last node sharing the focused node's
-- parent (its siblings at the current depth).
function KeyGraph:moveToSiblingEdge(first)
    local result = { moved = false }
    if not self:rerender() then
        return result
    end
    local node = self:currentNode()
    result.from = node
    result.to = node
    if node == nil then
        return result
    end

    local target = nil
    for _, n in ipairs(self.current.order) do
        if n.parent == node.parent then
            target = n
            if first then
                break
            end
        end
    end
    if target == nil or target == node then
        return result
    end
    self:_setCurrent(target)
    result.to = target
    result.moved = true
    return result
end

-- ---- behavior invokers (the host announces fallbacks / state) ----

-- Run the focused control's primary activation. False = it has none.
function KeyGraph:activate()
    if not self:rerender() then
        return false
    end
    local node = self:currentNode()
    if node == nil or node.vtable.onActivate == nil then
        return false
    end
    node.vtable.onActivate()
    return true
end

-- Run the focused control's secondary activation. False = it has none.
function KeyGraph:secondary()
    if not self:rerender() then
        return false
    end
    local node = self:currentNode()
    if node == nil or node.vtable.onSecondary == nil then
        return false
    end
    node.vtable.onSecondary()
    return true
end

-- If the focused control adjusts horizontally (a slider), adjust and return
-- true; false = the caller should navigate instead.
function KeyGraph:tryAdjust(sign, large)
    if not self:rerender() then
        return false
    end
    local node = self:currentNode()
    if node == nil or node.vtable.onAdjust == nil then
        return false
    end
    node.vtable.onAdjust(sign, large)
    return true
end
