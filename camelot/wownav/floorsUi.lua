-- The floor choice for a WowNav route (his /vn ebene): opens only when floors are stacked at the start or at the
-- target and nothing tells which one is meant (no height from the game, no route state, no height of the target, or
-- a target over several certified floors). One button per floor, lowest first, with its height (his prompt names
-- the height of each band or level); a floor without a network path from here says so (his band_no_path). Enter
-- picks it and the route request goes on with that floor.
--
-- For the player's own floor there is also his start-point mode (/vn hier): "Start from a nearby point" lists the
-- nearest waypoints of the network with their type, height and distance; the one picked is where the route starts.

local module = WowVision.base.navigation.wownav
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local FLOORS = "wownavFloors"
local START = "wownavStart"

local function floorLabel(floor, index, count)
    local text = string.format(L["Floor %d of %d"], index, count)
    if index == 1 then
        text = text .. ", " .. L["lowest"]
    elseif index == count then
        text = text .. ", " .. L["highest"]
    end
    if floor.z ~= nil then
        text = text .. ", " .. string.format(L["height %d"], math.floor(floor.z + 0.5))
    end
    if floor.reachable == false then
        text = text .. ", " .. L["no path from here"]
    end
    return text
end

local function renderFloors(builder, screen)
    local choice = module:floorChoice()
    builder:beginStop("floors")
    local title = choice ~= nil and choice.kind == "start" and L["Choose your floor"] or L["Choose the target's floor"]
    builder:pushContext("floors", title)
    if choice == nil then
        builder:addItem(ControlId.structural("empty"), nodes.text({ label = L["Empty"] }))
    else
        local count = #choice.floors
        for index, floor in ipairs(choice.floors) do
            local captured = floor
            builder:addItem(ControlId.structural("floor:" .. index), nodes.button({
                label = floorLabel(floor, index, count),
                onActivate = function()
                    module:chooseFloor(captured)
                end,
            }))
        end
        if choice.kind == "start" and choice.request ~= nil then
            local request = choice.request
            builder:addItem(ControlId.structural("startPoints"), nodes.button({
                label = L["Start from a nearby point"],
                onActivate = function()
                    module:openStartPoints(request)
                end,
            }))
        end
    end
    builder:popContext()
end

module:registerWindow({
    type = "ManualWindow",
    name = FLOORS,
    graphScreen = { render = renderFloors, captureClose = true },
})

local function renderStart(builder, screen)
    local choice = module:startChoice()
    builder:beginStop("startPoints")
    builder:pushContext("startPoints", L["Where are you standing?"])
    if choice == nil or #choice.points == 0 then
        builder:addItem(ControlId.structural("empty"), nodes.text({ label = L["No waypoint nearby"] }))
    else
        for index, point in ipairs(choice.points) do
            local captured = point
            builder:addItem(ControlId.structural("point:" .. index), nodes.button({
                label = string.format("%s, %d %s", point.n, math.floor(point.distance + 0.5), L["yards"]),
                onActivate = function()
                    module:chooseStartPoint(captured)
                end,
            }))
        end
    end
    builder:popContext()
end

module:registerWindow({
    type = "ManualWindow",
    name = START,
    graphScreen = { render = renderStart, captureClose = true },
})
