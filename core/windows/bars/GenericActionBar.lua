local module = WowVision.base.windows.bars
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local GenericActionBar = WowVision.components.createType("bars", { key = "GenericActionBar" })
GenericActionBar.info:addFields({
    { key = "frame", required = true },
})

function GenericActionBar:isVisible()
    return self.frame and self.frame:IsShown()
end

function GenericActionBar:renderGraph(builder)
    builder:pushContext(self.key, self.label)
    builder:startRow()
    local children = self.frame.actionButtons
    if not children then
        children = { self.frame:GetChildren() }
    end
    for _, button in ipairs(children) do
        builder:addItem(ControlId.forObject(button), module.actionButtonNode(button))
    end
    builder:endRow()
    builder:popContext()
end
