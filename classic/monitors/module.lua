local module = WowVision.base:createModule("monitors")
local L = module.L
module:setLabel(L["Monitors"])

local monitorsField = WowVision.classes.newField({
    type = "ComponentArray",
    key = "monitors",
    label = L["Monitors"],
    persist = true,
    factory = function(config)
        return WowVision.monitors.registry:createTemporaryComponent(config)
    end,
    getTypeKey = function(instance)
        local className = instance.class.name
        if className:sub(-7) == "Monitor" then
            return className:sub(1, -8)
        end
        return className
    end,
    availableTypes = function()
        local types = {}
        for i, item in ipairs(WowVision.monitors.registry.types.items) do
            local key = WowVision.monitors.registry.types.itemKeys[i]
            tinsert(types, { key = key, label = item.label or key })
        end
        return types
    end,
})

-- Container object for the ComponentArray field to operate on
local container = { monitors = {} }

function module:getDefaultData()
    return { monitors = { _type = "array" } }
end

function module:onFullEnable()
    container.db = self.db.data
    monitorsField:setDB(container, self.db.data)
end

function module:getGraphMenuItems(builder)
    builder:addItem(
        WowVision.graph.ControlId.structural("monitors"),
        WowVision.graph.settings.controlFor(monitorsField, container)
    )
end

module:hasUpdate(function(self)
    for _, monitor in ipairs(container.monitors or {}) do
        if monitor and monitor.update then
            monitor:update()
        end
    end
end)

module:registerBinding({
    type = "Function",
    key = "monitors/toggleAll",
    inputs = {},
    label = L["Toggle All Monitors"],
    func = function()
        for _, monitor in ipairs(container.monitors or {}) do
            if monitor then
                monitor.enabled = not monitor.enabled
            end
        end
    end,
})
