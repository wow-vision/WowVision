local module = WowVision.base.windows.bars
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local MainActionBar = WowVision.components.createType("bars", { key = "MainActionBar" })

function MainActionBar:renderGraph(builder)
    builder:pushContext(self.key, self.label)
    builder:startRow()
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            builder:addItem(ControlId.forObject(button), module.actionButtonNode(button))
        end
    end
    builder:endRow()
    builder:popContext()
end
