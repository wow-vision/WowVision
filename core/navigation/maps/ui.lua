local module = WowVision.base.navigation.maps
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Prototype atlas window (not yet reachable from any binding): lists the 20
-- closest Sku waypoints to the player, computed once per open.

local function distance(x1, y1, x2, y2)
    return (x2 - x1) ^ 2 + (y2 - y1) ^ 2
end

local function closestWaypoints()
    local wp = {}
    local x, y = UnitPosition("player")
    for _, point in ipairs(module.datasets.items.sku.data) do
        local doNotInsert = false
        local dist = distance(x, y, point.x, point.y)
        for i, v in ipairs(wp) do
            if i > 20 then
                doNotInsert = true
                wp[i] = nil
                break
            end
            if dist < v[1] then
                tinsert(wp, i, { dist, point })
                doNotInsert = true
                if #wp > 20 then
                    wp[21] = nil
                end
                break
            end
        end
        if not doNotInsert then
            tinsert(wp, { dist, point })
        end
    end
    local points = {}
    for _, v in ipairs(wp) do
        tinsert(points, v[2])
    end
    return points
end

local function render(builder, screen)
    if screen._closest == nil then
        screen._closest = closestWaypoints()
    end
    builder:pushContext("atlas", "Maps")

    builder:beginStop("points")
    builder:pushContext("points", "Entrypoint")
    if #screen._closest == 0 then
        builder:addItem(ControlId.structural("pointsEmpty"), nodes.text({ label = L["Empty"] }))
    end
    for i, point in ipairs(screen._closest) do
        builder:addItem(ControlId.structural("point:" .. i), nodes.text({ label = point.name }))
    end
    builder:popContext()

    builder:popContext()
end

module:registerWindow({
    type = "ManualWindow",
    name = "atlas",
    graphScreen = { render = render, captureClose = true },
})
