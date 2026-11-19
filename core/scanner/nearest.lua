-- The scanner's "nearest entry" pick (pure, no WoW API, so the headless tests run it): Backspace or the context
-- menu on a category navigates to the closest thing in it.
--
-- pick(nodes, distanceTo, resolve) -> node, distance
--   nodes       the category's children (scanner nodes, see core/scanner/module.lua)
--   distanceTo  function(x, y) -> yards from the player, or nil when the player has no position
--   resolve     function(node) -> its children list (resolving a lazy `children` function); defaults to the
--               plain list, calling a function once
--
-- A node with a position is a candidate (its position already is its nearest spawn). A node without a position
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

local function walk(nodes, distanceTo, resolve, best, bestDistance)
    for _, node in ipairs(nodes or {}) do
        if node.x ~= nil then
            local distance = distanceTo(node.x, node.y)
            if distance ~= nil and (bestDistance == nil or distance < bestDistance) then
                best, bestDistance = node, distance
            end
        elseif node.children ~= nil then
            best, bestDistance = walk(resolve(node), distanceTo, resolve, best, bestDistance)
        end
    end
    return best, bestDistance
end

function nearest.pick(nodes, distanceTo, resolve)
    return walk(nodes, distanceTo, resolve or defaultResolve, nil, nil)
end
