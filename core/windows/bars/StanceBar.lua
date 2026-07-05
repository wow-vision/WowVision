local module = WowVision.base.windows.bars
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local StanceBar = WowVision.components.createType("bars", { key = "StanceBar" })

function StanceBar:isVisible()
    return module.StanceBarFrame:IsShown()
end

function StanceBar:renderGraph(builder)
    builder:pushContext(self.key, self.label)
    builder:startRow()
    for i, button in ipairs(module.stanceButtons) do
        if button:IsShown() then
            local formIndex = i
            builder:addItem(
                ControlId.forObject(button),
                module.actionButtonNode(button, function()
                    local _, _, _, spellID = GetShapeshiftFormInfo(formIndex)
                    return module.GetSpellInfo(spellID)
                end)
            )
        end
    end
    builder:endRow()
    builder:popContext()
end
