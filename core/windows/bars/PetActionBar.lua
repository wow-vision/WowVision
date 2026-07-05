local module = WowVision.base.windows.bars
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

local PetActionBar = WowVision.components.createType("bars", { key = "PetActionBar" })

function PetActionBar:isVisible()
    return PetHasActionBar()
end

function PetActionBar:renderGraph(builder)
    builder:pushContext(self.key, self.label)
    builder:startRow()
    for i = 1, NUM_PET_ACTION_SLOTS do
        local button = _G["PetActionButton" .. i]
        local slot = i
        if button then
            builder:addItem(
                ControlId.forObject(button),
                module.actionButtonNode(button, function()
                    local _, _, _, _, autoCastAllowed, autoCastEnabled = GetPetActionInfo(slot)
                    local label = button.tooltipName or L["Empty"]
                    if autoCastAllowed then
                        if autoCastEnabled then
                            label = label .. " " .. L["Auto Casting"]
                        else
                            label = label .. " " .. L["Not Auto Casting"]
                        end
                    end
                    return label
                end)
            )
        end
    end
    builder:endRow()
    builder:popContext()
end
