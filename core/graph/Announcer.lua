local graph = WowVision.graph
local resolveText = graph.resolveText
local kinds = graph.kinds

-- Composes the spoken line for a focus change by diffing the old and new focus
-- PATHS: each node's ancestor chain (parent pointers) plus the node itself,
-- compared by identity. Newly-entered levels read outermost-first, then the
-- landing control ("Categories, list, Combat, 9 of 13"). Sibling moves share
-- the whole prefix and read just the control; ascends likewise; descending from
-- a group onto its own child re-announces nothing but the child, because the
-- group is on the child's chain AND is the from-node, so the prefix swallows it.
local announcer = {
    -- Pluggable hooks, installed by the host (nil = tests/boot defaults):
    -- partFilter(controlType, part) -> false drops the part from readouts AND
    -- the live watch (the user's per-type, per-kind announcement settings).
    partFilter = nil,
    -- positionText(index, count) -> localized "n of m"; nil = no auto positions.
    positionText = nil,
    -- expandedStateText(expanded) -> localized state word for group headers.
    expandedStateText = nil,
}
graph.announcer = announcer

-- Stand-in part handed to partFilter so the user's position-kind toggle governs
-- the auto-stamped position too.
local autoPositionProbe = { text = nil, kind = kinds.position }

local function hasKind(parts, kind)
    if parts == nil or kind == nil then
        return false
    end
    for _, part in ipairs(parts) do
        if part ~= nil and part.kind == kind then
            return true
        end
    end
    return false
end

local function orderIndex(order, kind)
    if kind ~= nil then
        for i, k in ipairs(order) do
            if k == kind then
                return i
            end
        end
    end
    return #order + 1
end

-- A node's EFFECTIVE announcement parts: the control type's common parts (the
-- role word) merged with the node's own -- a node part overrides a common part
-- of the same kind -- sorted by the type's kind order (unknown/kindless parts
-- append in declaration order), then filtered by the user's settings. Readouts
-- and the live watch both operate on this list.
function announcer.effectiveAnnouncements(node)
    local result = {}
    local vtable = node and node.vtable
    if vtable == nil then
        return result
    end
    local controlType = vtable.controlType

    local common = controlType and controlType.common and controlType.common()
    if common ~= nil then
        for _, part in ipairs(common) do
            if part ~= nil and not hasKind(vtable.announcements, part.kind) then
                tinsert(result, part)
            end
        end
    end
    if vtable.announcements ~= nil then
        for _, part in ipairs(vtable.announcements) do
            if part ~= nil then
                tinsert(result, part)
            end
        end
    end

    local order = controlType and controlType.order
    if order ~= nil and #order > 0 and #result > 1 then
        -- Stable sort: composite rank of (kind's order index, declaration index).
        local keyed = {}
        for i, part in ipairs(result) do
            keyed[i] = { rank = orderIndex(order, part.kind) * 1000 + i, part = part }
        end
        table.sort(keyed, function(a, b)
            return a.rank < b.rank
        end)
        result = {}
        for i, entry in ipairs(keyed) do
            result[i] = entry.part
        end
    end

    if announcer.partFilter ~= nil then
        local filtered = {}
        for _, part in ipairs(result) do
            if announcer.partFilter(controlType, part) then
                tinsert(filtered, part)
            end
        end
        result = filtered
    end
    return result
end

-- A node's own readout: its effective parts resolved live, non-empty ones
-- joined -- plus a group's expanded/collapsed state word and the auto-stamped
-- sibling position (unless the node carries its own).
function announcer.leafText(node)
    if node == nil then
        return nil
    end
    local parts = announcer.effectiveAnnouncements(node)
    local out = {}
    for _, part in ipairs(parts) do
        local text = resolveText(part)
        if text ~= nil and text ~= "" then
            tinsert(out, text)
        end
    end

    if node.expandable and not node.vtable.speaksOwnExpansion and announcer.expandedStateText ~= nil then
        local state = announcer.expandedStateText(node.expanded and true or false)
        if state ~= nil and state ~= "" then
            tinsert(out, state)
        end
    end

    if
        (node.positionCount or 0) > 1
        and announcer.positionText ~= nil
        and not node.vtable.speaksOwnPosition
        and not hasKind(node.vtable.announcements, kinds.position)
        and (announcer.partFilter == nil or announcer.partFilter(node.vtable.controlType, autoPositionProbe))
    then
        local pos = announcer.positionText(node.positionIndex, node.positionCount)
        if pos ~= nil and pos ~= "" then
            tinsert(out, pos)
        end
    end

    if #out == 0 then
        return nil
    end
    return table.concat(out, ", ")
end

-- The first announcement part's text (the label) -- for path dedupe.
function announcer.firstPartText(node)
    local parts = node and node.vtable and node.vtable.announcements
    if parts == nil or #parts == 0 then
        return nil
    end
    return resolveText(parts[1])
end

-- The next path level's readout starts as this label: equal, or its first
-- comma-separated segment is the label (a readout leads with its label).
local function duplicatesNext(label, nextText)
    if type(label) ~= "string" or type(nextText) ~= "string" then
        return false
    end
    if nextText:sub(1, #label) ~= label then
        return false
    end
    return #nextText == #label or nextText:sub(#label + 1, #label + 1) == ","
end

-- The node's path: ancestors outermost-first, then the node itself.
local function pathOf(node)
    local path = {}
    local n = node
    while n ~= nil do
        tinsert(path, 1, n)
        n = n.parent
    end
    return path
end

-- The line for landing on `to` having come from `from` (nil = from nothing: the
-- full path reads). transitionLabel is the crossed edge's spoken line, when it
-- had one. Nil when there is nothing to say.
function announcer.compose(from, to, transitionLabel)
    if to == nil then
        return nil
    end
    local toPath = pathOf(to)
    local fromPath = from ~= nil and pathOf(from) or {}

    -- Common prefix by identity: levels we were already inside (or ON:
    -- descending from a group onto its child keeps the group in the prefix)
    -- stay silent.
    local i = 1
    while i <= #fromPath and i <= #toPath and fromPath[i].id == toPath[i].id do
        i = i + 1
    end

    local parts = {}
    if transitionLabel ~= nil and transitionLabel ~= "" then
        tinsert(parts, transitionLabel)
    end

    if i > #toPath then
        -- Ascended (or same node): just the now-innermost focus.
        local text = announcer.leafText(to)
        if text ~= nil then
            tinsert(parts, text)
        end
    else
        for j = i, #toPath do
            local text = announcer.leafText(toPath[j])
            if text ~= nil then
                local skip = false
                if j < #toPath then
                    -- Skip a level whose label just duplicates the next level
                    -- down (a section wrapping a control of the same name).
                    local label = announcer.firstPartText(toPath[j])
                    local nextLabel = announcer.firstPartText(toPath[j + 1])
                    if label ~= nil and nextLabel ~= nil and duplicatesNext(label, nextLabel) then
                        skip = true
                    end
                end
                if not skip then
                    tinsert(parts, text)
                end
            end
        end
    end

    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ", ")
end

-- The full readout for a landing with no prior focus (screen entry, restore).
function announcer.composeFull(to)
    return announcer.compose(nil, to)
end
