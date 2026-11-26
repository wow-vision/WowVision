-- The scanner's "nearest entry" pick (pure, no WoW API, so the headless tests run it): Backspace or the context
-- menu on a category navigates to the closest thing in it.
--
-- pick(nodes, distanceTo, resolve, place) -> node, distance, x, y
--   nodes       the category's children (scanner nodes, see core/scanner/module.lua)
--   distanceTo  function(x, y) -> yards from the player, or nil when the player has no position
--   resolve     function(node) -> its children list (resolving a lazy `children` function); defaults to the
--               plain list, calling a function once
--   place       function(node) -> x, y where the node is now, or nil (a moving node, see `position` in
--               core/scanner/module.lua); defaults to its fixed x, y. Read once per node, so the x, y returned are
--               the ones the distance was weighed on.
--
-- A node with a position (or a `position` function) is a candidate (its position already is its nearest spawn). A node without a position
-- but with children is a subcategory (Quests > Nearby, NPCs > Vendors): its children are searched instead, so
-- Backspace on "Quests" finds the nearest quest of every subcategory. Nodes without either (Loading, Empty, a
-- toggle) are skipped.
local nearest = {}
WowVision.scannerNearest = nearest

local function defaultResolve(node)
    if type(node.children) == "function" then
        node.children = node.children() or {}
    end
    return node.children or {}
end

local function fixedPlace(node)
    return node.x, node.y
end

local function walk(nodes, distanceTo, resolve, place, best)
    for _, node in ipairs(nodes or {}) do
        if node.x ~= nil or node.position ~= nil then
            local x, y = place(node)
            local distance = x ~= nil and distanceTo(x, y) or nil
            if distance ~= nil and (best.distance == nil or distance < best.distance) then
                best.node, best.distance, best.x, best.y = node, distance, x, y
            end
        elseif node.children ~= nil then
            walk(resolve(node), distanceTo, resolve, place, best)
        end
    end
end

function nearest.pick(nodes, distanceTo, resolve, place)
    local best = {}
    walk(nodes, distanceTo, resolve or defaultResolve, place or fixedPlace, best)
    return best.node, best.distance, best.x, best.y
end
