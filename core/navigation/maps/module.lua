local module = WowVision.base.navigation:createModule("maps")
local L = module.L
module:setLabel(L["Maps"])

module.datasets = WowVision.Registry:new()

function module:newDataset(key)
    local data = WowVision.Dataset:new()
    self.datasets:register(key, data)
    return data
end

function module:pathfind(path)
    self.beacon = nil
    self.path = path
    self.path:start()
end

function module:updatePath()
    if self.path then
        self.path:update()
    end
end

function module:onEnable()
    self:hasUpdate(function(self)
        self:updatePath()
    end)
end
