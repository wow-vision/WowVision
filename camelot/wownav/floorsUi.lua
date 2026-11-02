-- The target's floor choice for a WowNav route (his /vn ebene): opens only when floors are stacked at the target and
-- nothing tells which one is meant (no height of the target, or a target over several certified floors). One button
-- per floor, lowest first, with its height (his prompt names the height of each band or level); a floor without a
-- network path from the start says so (his band_no_path). Enter picks it and the route request goes on with that
-- floor. Where a module knows the floors there by name (maps.floorName(x, y, height), optional), the name stands in
-- for the height; two floors of one name keep it. The player's own floor is never asked: the route starts at the
-- entry point picked in F10.

local module = WowVision.base.navigation.wownav
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local FLOORS = "wownavFloors"

local maps = WowVision.base.navigation.maps

-- The floors' names where a module knows them (maps.floorName), nil for the rest and for names two floors share.
local function floorNames(floors)
    local names, count = {}, {}
    for i, floor in ipairs(floors) do
        local name = maps.floorName ~= nil and floor.x ~= nil and floor.z ~= nil
            and maps.floorName(floor.x, floor.y, floor.z) or nil
        if name ~= nil and name ~= "" then
            names[i] = name
            count[name] = (count[name] or 0) + 1
        end
    end
    for i, name in pairs(names) do
        if count[name] > 1 then
            names[i] = nil
        end
    end
    return names
end

local function floorLabel(floor, index, count, name)
    local text = string.format(L["Floor %d of %d"], index, count)
    if name ~= nil then
        text = text .. ", " .. name
    end
    if index == 1 then
        text = text .. ", " .. L["lowest"]
    elseif index == count then
        text = text .. ", " .. L["highest"]
    end
    if floor.z ~= nil and name == nil then
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
    builder:pushContext("floors", L["Choose the target's floor"])
    if choice == nil then
        builder:addItem(ControlId.structural("empty"), nodes.text({ label = L["Empty"] }))
    else
        local count = #choice.floors
        local names = floorNames(choice.floors)
        for index, floor in ipairs(choice.floors) do
            local captured = floor
            builder:addItem(ControlId.structural("floor:" .. index), nodes.button({
                label = floorLabel(floor, index, count, names[index]),
                onActivate = function()
                    module:chooseFloor(captured)
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
