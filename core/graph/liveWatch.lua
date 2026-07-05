local graph = WowVision.graph
local announcer = graph.announcer
local GraphHost = graph.GraphHost

-- The live announcement watches, run by the host each tick.

-- The focused node's readout is inherently live: EVERY part (label, value,
-- selected, expanded state) is watched by default, so screens never need
-- per-part flags for the focused case. live = false opts a part out;
-- live = "always" additionally watches it while unfocused.
local function isWatched(part)
    return part.live ~= false
end

-- Watch the focused node's parts and speak a part when its resolved text
-- changes. Baselines silently whenever focus lands on a new identity (the
-- focus announcement already spoke the initial state). Arrays cannot hold nil,
-- so absent values cache as false.
function GraphHost:_watchLive(screen, node)
    local parts = announcer.effectiveAnnouncements(node)
    if #parts == 0 then
        return
    end
    local baseline = screen._liveKey == nil
        or screen._liveKey ~= node.id
        or #screen._liveValues ~= #parts
    if baseline then
        screen._liveKey = node.id
        screen._liveValues = {}
    end

    for i, part in ipairs(parts) do
        if not isWatched(part) then
            if baseline then
                screen._liveValues[i] = false
            end
        else
            local value = graph.resolveText(part)
            local cached = value == nil and false or value
            if baseline then
                screen._liveValues[i] = cached
            elseif screen._liveValues[i] ~= cached then
                screen._liveValues[i] = cached
                if value ~= nil and value ~= "" then
                    self:_speak(value)
                end
            end
        end
    end
end

-- Watch always-scoped parts across the whole render, focused or not. Nodes
-- baseline silently when they first appear; the focused node is skipped here
-- because the focus watch above already owns it.
function GraphHost:_watchAlways(screen, focusedNode)
    local render = screen.keyGraph.current
    if render == nil then
        return
    end
    local old = screen._alwaysValues
    local fresh = nil
    local focusedKey = focusedNode ~= nil and focusedNode.id.key or nil

    for _, node in ipairs(render.order) do
        local parts = node.vtable.announcements
        if parts ~= nil then
            for i, part in ipairs(parts) do
                if part ~= nil and part.live == "always" then
                    local value = graph.resolveText(part)
                    local cached = value == nil and false or value
                    if fresh == nil then
                        fresh = {}
                    end
                    local byNode = fresh[node.id.key]
                    if byNode == nil then
                        byNode = {}
                        fresh[node.id.key] = byNode
                    end
                    byNode[i] = cached
                    local oldByNode = old ~= nil and old[node.id.key] or nil
                    if
                        oldByNode ~= nil
                        and oldByNode[i] ~= nil
                        and oldByNode[i] ~= cached
                        and value ~= nil
                        and value ~= ""
                        and node.id.key ~= focusedKey
                    then
                        self:_speak(value)
                    end
                end
            end
        end
    end
    screen._alwaysValues = fresh
end
