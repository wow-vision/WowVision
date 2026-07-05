local graph = WowVision.graph
local ControlId = graph.ControlId

-- Builds a render. Two construction styles, freely mixable in one build:
--
-- MENU MODE: rows of controls wired automatically -- left/right within a row,
-- up/down between consecutive rows of the same stop. Rows sharing a non-nil
-- row key get column-preserving vertical navigation. Items added outside an
-- explicit row become single-item rows (a plain vertical menu).
--
-- RAW MODE: addNode + connect for arbitrary topologies.
--
-- Orthogonal to both: beginStop groups nodes into tab stops (arrows never
-- cross a stop; tab cycles them), and the PARENT STACK builds the presentation
-- hierarchy: pushContext pushes a non-focusable structural level ("Categories,
-- list" -- announced when focus enters from outside), beginGroup pushes a
-- focusable, EXPANDABLE group header (a tree section) whose children only emit
-- while it is expanded. Nesting recurses; a collapsed ancestor suppresses
-- everything beneath it.
local Builder = WowVision.Class("GraphBuilder")
graph.Builder = Builder

-- `expansion` is the persistent expanded-group set (state.expanded); nil means
-- groups manage state via explicit expanded arguments only.
function Builder:initialize(expansion)
    self.expansion = expansion
    self.rows = {}
    self.currentRow = nil
    self.rawCount = 0
    self.rawEdges = {}
    self.declared = {} -- every node in declaration order, regardless of mode
    self.rowOf = {} -- node -> its menu row (absent for raw nodes)
    self.ids = {} -- structural key -> true, for duplicate detection
    self.start = nil
    self.stopKey = "stop#0"
    self.stopAuto = 1
    -- The parent stack: structural levels (pushContext) and group headers
    -- (beginGroup). A frame whose group is collapsed suppresses every
    -- declaration beneath it (the stack stays balanced regardless).
    self.parents = {}
end

function Builder:_currentParent()
    local top = self.parents[#self.parents]
    if top ~= nil then
        return top.node
    end
    return nil
end

function Builder:_isSuppressed()
    local top = self.parents[#self.parents]
    return top ~= nil and top.suppressed == true
end

-- ---- stops ----

-- Start a new tab stop; nodes added from here belong to it. The key must be
-- stable across rebuilds (it keys the stop's remembered position); nil
-- auto-assigns by index, which is stable when the screen builds its stops in a
-- fixed order.
function Builder:beginStop(key)
    if self.currentRow ~= nil then
        error("Cannot begin a stop inside an open row")
    end
    if key == nil then
        key = "stop#" .. self.stopAuto
    end
    self.stopKey = key
    self.stopAuto = self.stopAuto + 1
    return self
end

-- ---- the parent stack: contexts + groups ----

-- Push one NON-FOCUSABLE level of presentation hierarchy ("Categories",
-- "list") onto nodes added from here -- pure structure: never navigable,
-- announced when focus enters from outside. positions=false suppresses auto
-- positions on direct children. Close with popContext.
function Builder:pushContext(label, role, positions)
    local parent = self:_currentParent()
    local announcements = { { text = label } }
    if role ~= nil and role ~= "" then
        tinsert(announcements, { text = role })
    end
    local parentKey = parent ~= nil and tostring(parent.id.key) or ""
    local node = {
        -- Stable synthetic identity (label-pathed) so cross-render chain
        -- diffs match up.
        id = ControlId.structural("ctx:" .. parentKey .. "/" .. tostring(label)),
        vtable = { announcements = announcements },
        transitions = {},
        parent = parent,
        focusable = false,
    }
    if positions == false then
        node.suppressChildPositions = true
    end
    tinsert(self.parents, { node = node, suppressed = self:_isSuppressed() })
    return self
end

function Builder:popContext()
    if #self.parents == 0 then
        error("No context/group to pop")
    end
    table.remove(self.parents)
    return self
end

-- Push a FOCUSABLE, expandable group header (a tree section): the header
-- emits as a navigable node here, and the children declared before endGroup
-- emit only while the group is expanded. Expansion state: `expanded` when
-- given, else the persistent expansion set, else defaultExpanded. The engine's
-- tree operations expand/collapse via the vtable's onExpand/onCollapse
-- overrides when set, else by mutating the persistent set.
function Builder:beginGroup(id, vtable, expanded, defaultExpanded)
    if id == nil then
        error("beginGroup requires an id")
    end
    if self.currentRow ~= nil then
        error("Cannot begin a group inside an open row")
    end
    local isExpanded
    if expanded ~= nil then
        isExpanded = expanded == true
    elseif self.expansion ~= nil then
        isExpanded = self.expansion[id.key] == true
    else
        isExpanded = defaultExpanded == true
    end

    local header = nil
    if not self:_isSuppressed() then
        header = self:_makeNode(id, vtable)
        header.expandable = true
        header.expanded = isExpanded
        local row = { items = { header }, stopKey = self.stopKey }
        tinsert(self.rows, row)
        self.rowOf[header] = row
    end
    tinsert(self.parents, {
        -- Suppressed subtree: keep chaining from the outer parent so the
        -- stack stays coherent.
        node = header or self:_currentParent(),
        suppressed = self:_isSuppressed() or not isExpanded,
    })
    return self
end

function Builder:endGroup()
    return self:popContext()
end

-- Whether a group id is expanded in the persistent set -- for screens that
-- must avoid even BUILDING a collapsed group's children (a lazy hierarchy).
-- Groups with an explicit expanded argument manage their own state instead.
function Builder:isExpanded(id)
    return self.expansion ~= nil and id ~= nil and self.expansion[id.key] == true
end

-- Focus starts here when the graph has no prior position (defaults to the
-- first node).
function Builder:setStart(id)
    self.start = id
    return self
end

-- ---- menu mode ----

-- Open a horizontal row. Rows sharing a non-nil rowKey with the row
-- above/below get column-preserving vertical navigation.
function Builder:startRow(rowKey)
    if self.currentRow ~= nil then
        error("Cannot start a row while another is open")
    end
    self.currentRow = { items = {}, key = rowKey, stopKey = self.stopKey }
    return self
end

function Builder:endRow()
    if self.currentRow == nil then
        error("No row to end")
    end
    if #self.currentRow.items == 0 and not self:_isSuppressed() then
        error("Row cannot be empty")
    end
    if #self.currentRow.items > 0 then
        tinsert(self.rows, self.currentRow)
    end
    self.currentRow = nil
    return self
end

-- Add a control -- into the open row, or as its own single-item row. A no-op
-- inside a collapsed group's subtree.
function Builder:addItem(id, vtable)
    if self:_isSuppressed() then
        return self
    end
    local node = self:_makeNode(id, vtable)
    if self.currentRow ~= nil then
        tinsert(self.currentRow.items, node)
        self.rowOf[node] = self.currentRow
    else
        local row = { items = { node }, stopKey = self.stopKey }
        tinsert(self.rows, row)
        self.rowOf[node] = row
    end
    return self
end

-- Add a read-only line (label only; no actions). label may be a string or a
-- function.
function Builder:addLabel(id, label)
    return self:addItem(id, { announcements = { { text = label } } })
end

-- ---- raw mode ----

-- Add a node with no automatic wiring (wire with connect). A no-op inside a
-- collapsed group's subtree.
function Builder:addNode(id, vtable)
    if self:_isSuppressed() then
        return self
    end
    self:_makeNode(id, vtable)
    self.rawCount = self.rawCount + 1
    return self
end

-- Directed edge from -> to, with an optional spoken transition line ("lane
-- change"). Edges to/from undeclared nodes are dropped at build. dir may be
-- any direction, including the tab edges next/previous.
function Builder:connect(from, dir, to, label)
    if from == nil or to == nil then
        error("connect requires from and to")
    end
    if not graph.directions[dir] then
        error("Unknown direction: " .. tostring(dir))
    end
    tinsert(self.rawEdges, { from = from, dir = dir, to = to, label = label })
    return self
end

function Builder:_makeNode(id, vtable)
    if id == nil then
        error("A control requires an id")
    end
    if vtable == nil or vtable.announcements == nil or #vtable.announcements == 0 then
        error("A control must have at least one announcement")
    end
    if self.ids[id.key] ~= nil then
        error("Duplicate control id: " .. tostring(id.key))
    end
    self.ids[id.key] = true
    local node = {
        id = id,
        vtable = vtable,
        transitions = {},
        parent = self:_currentParent(),
        stopKey = self.stopKey,
    }
    tinsert(self.declared, node)
    return node
end

-- ---- build ----

-- Finalize into a render, or nil when nothing was declared (treat as closed).
-- Menu rows and raw nodes/edges may coexist in one build: rows wire
-- themselves; raw edges may reference any node.
function Builder:build()
    if self.currentRow ~= nil then
        error("Unclosed row - call endRow()")
    end
    if self.rawCount == 0 and #self.rows == 0 then
        return nil
    end

    local render = graph.newRender()
    for _, node in ipairs(self.declared) do
        render.nodes[node.id.key] = node
        tinsert(render.order, node)
    end

    self:_wireMenuEdges()
    for _, edge in ipairs(self.rawEdges) do
        local fromNode = render.nodes[edge.from.key]
        if fromNode ~= nil and render.nodes[edge.to.key] ~= nil then
            fromNode.transitions[edge.dir] = { destination = edge.to, label = edge.label }
        end
    end
    self:_stitchModeBoundaries()

    if self.start ~= nil and render.nodes[self.start.key] ~= nil then
        render.startKey = self.start
    else
        render.startKey = render.order[1].id
    end
    self:_stampPositions()
    return render
end

-- Where vertical navigation from a position lands in the adjacent row: the
-- same position when the rows share a non-nil key (column nav) and it exists
-- there, else the first item.
local function verticalTarget(fromRow, toRow, pos)
    if fromRow.key ~= nil and toRow.key ~= nil and fromRow.key == toRow.key and pos <= #toRow.items then
        return toRow.items[pos].id
    end
    return toRow.items[1].id
end

-- Left/right within a row; up/down between consecutive rows OF THE SAME STOP
-- (arrows never cross a tab stop). Segments break where raw content
-- interleaves between menu rows -- the stitcher wires those seams; without the
-- break, menu edges would skip straight over the raw block and leave it an
-- unreachable island.
function Builder:_wireMenuEdges()
    local segments = {}
    local openSegment = {} -- stopKey -> its currently-open segment
    for _, node in ipairs(self.declared) do
        local row = self.rowOf[node]
        if row ~= nil then
            local segment = openSegment[node.stopKey]
            if segment == nil then
                segment = {}
                openSegment[node.stopKey] = segment
                tinsert(segments, segment)
            end
            if segment[#segment] ~= row then
                tinsert(segment, row)
            end
        else
            openSegment[node.stopKey] = nil -- raw node: close this stop's segment
        end
    end

    for _, rows in ipairs(segments) do
        for r, row in ipairs(rows) do
            for pos, node in ipairs(row.items) do
                if r > 1 then
                    node.transitions.up = { destination = verticalTarget(row, rows[r - 1], pos) }
                end
                if r < #rows then
                    node.transitions.down = { destination = verticalTarget(row, rows[r + 1], pos) }
                end
                if pos > 1 then
                    node.transitions.left = { destination = row.items[pos - 1].id }
                end
                if pos < #row.items then
                    node.transitions.right = { destination = row.items[pos + 1].id }
                end
            end
        end
    end
end

-- Where a stop mixes MENU rows with RAW content (filter controls above a
-- sheet), the two wiring systems don't see each other, leaving a vertical gap
-- arrows can't cross. Stitch each boundary in declaration order, filling only
-- MISSING edges -- the raw content's own wiring is never overridden.
function Builder:_stitchModeBoundaries()
    local byStop = {}
    local stops = {}
    for _, node in ipairs(self.declared) do
        local list = byStop[node.stopKey]
        if list == nil then
            list = {}
            byStop[node.stopKey] = list
            tinsert(stops, node.stopKey)
        end
        tinsert(list, node)
    end

    for _, stop in ipairs(stops) do
        local nodes = byStop[stop]
        for i = 2, #nodes do
            local prev = nodes[i - 1]
            local cur = nodes[i]
            local prevMenu = self.rowOf[prev] ~= nil
            local curMenu = self.rowOf[cur] ~= nil
            if prevMenu ~= curMenu then
                if prevMenu then
                    -- Menu row above raw content: the row's cells gain down
                    -- edges into the first raw node still missing an up edge,
                    -- and that node gains the up back.
                    if cur.transitions.up == nil then
                        local row = self.rowOf[prev]
                        for _, cell in ipairs(row.items) do
                            if cell.transitions.down == nil then
                                cell.transitions.down = { destination = cur.id }
                            end
                        end
                        cur.transitions.up = { destination = row.items[1].id }
                    end
                else
                    -- Raw content above a menu row: the latest raw node
                    -- (walking back) missing a down edge wires into the row,
                    -- and the row's cells wire back up.
                    local row = self.rowOf[cur]
                    local bottom = nil
                    local j = i - 1
                    while j >= 1 and self.rowOf[nodes[j]] == nil do
                        if nodes[j].transitions.down == nil then
                            bottom = nodes[j]
                            break
                        end
                        j = j - 1
                    end
                    if bottom ~= nil then
                        bottom.transitions.down = { destination = row.items[1].id }
                        for _, cell in ipairs(row.items) do
                            if cell.transitions.up == nil then
                                cell.transitions.up = { destination = bottom.id }
                            end
                        end
                    end
                end
            end
        end
    end
end

local function stamp(siblings)
    if #siblings < 2 then
        return
    end
    for i, node in ipairs(siblings) do
        node.positionIndex = i
        node.positionCount = #siblings
    end
end

-- Auto-stamp "n of m" positions: a multi-item row's members are positioned
-- within their row; single-item-row nodes among the siblings sharing their
-- (parent, stop) -- the vertical level arrows actually traverse. Raw nodes get
-- none. Announced only when m > 1.
function Builder:_stampPositions()
    local groups = {}
    local groupIndex = {} -- parent (or false) -> stopKey -> sibling list
    for _, row in ipairs(self.rows) do
        if #row.items > 1 then
            stamp(row.items)
        else
            local node = row.items[1]
            if not (node.parent ~= nil and node.parent.suppressChildPositions) then
                local parentKey = node.parent or false
                local byStop = groupIndex[parentKey]
                if byStop == nil then
                    byStop = {}
                    groupIndex[parentKey] = byStop
                end
                local list = byStop[node.stopKey]
                if list == nil then
                    list = {}
                    byStop[node.stopKey] = list
                    tinsert(groups, list)
                end
                tinsert(list, node)
            end
        end
    end
    for _, list in ipairs(groups) do
        stamp(list)
    end
end
