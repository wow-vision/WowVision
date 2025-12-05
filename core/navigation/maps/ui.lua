local module = WowVision.base.navigation.maps
local gen = module:hasUI()
local L = module.L

local function getMapButton(self, data)
    return { "Button", label = data.name }
end

local closest = WowVision.Dataset:new()

local function distance(x1, y1, x2, y2)
    return (x2 - x1) ^ 2 + (y2 - y1) ^ 2
end

local function Maps_onMount()
    closest:clear()
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
    for _, v in ipairs(wp) do
        closest:addPoint(v[2])
    end
end

gen:Element("maps/Atlas", function(props)
    local data = { "DataList", dataset = closest, label = "Entrypoint", getElement = getMapButton }
    return {
        "Panel",
        label = "Maps",
        hooks = {
            mount = Maps_onMount,
        },
        children = {
            { "Text", text = "Maps go here" },
            data,
        },
    }
end)

module:registerWindow({
    type = "ManualWindow",
    name = "atlas",
    generated = true,
    rootElement = "maps/Atlas",
    hookEscape = true,
})
