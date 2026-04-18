local navigation = WowVision.base.navigation
local module = navigation:createModule("atlas")
local L = module.L
module:setLabel(L["Atlas"])

local atlas = {
    datasets = WowVision.Registry:new(),
    events = {
        datasetAdded = WowVision.Event:new("datasetAdded"),
    },
}

-- Create and register a new map dataset. Called by map data addons.
function atlas:createDataset(config)
    if not config.key then
        error("MapDataset requires a key.")
    end
    if self.datasets:get(config.key) then
        error("Dataset with key '" .. config.key .. "' already exists.")
    end
    local dataset = WowVision.MapDataset:new(config)
    self.datasets:register(config.key, dataset)
    self.events.datasetAdded:emit(dataset)
    return dataset
end

function atlas:getDataset(key)
    return self.datasets:get(key)
end

function atlas:getDatasets()
    return self.datasets.items
end

-- Iterate all enabled datasets
function atlas:forEachEnabledDataset(callback)
    for _, dataset in ipairs(self.datasets.items) do
        if dataset.enabled then
            callback(dataset)
        end
    end
end

WowVision.atlas = atlas
module.atlas = atlas
