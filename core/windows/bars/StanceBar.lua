local module = WowVision.base.windows.bars
local L = module.L

local StanceBar = WowVision.components.createType("bars", { key = "StanceBar" })

function StanceBar:isVisible()
    return module.StanceBarFrame:IsShown()
end

function StanceBar:getGenerator()
    local result = { "List", label = self.label, direction = "horizontal", children = {} }
    for i, button in ipairs(module.stanceButtons) do
        if button:IsShown() then
            local _, _, _, spellID = GetShapeshiftFormInfo(i)
            local label = module.GetSpellInfo(spellID)
            tinsert(result.children, { "ProxyButton", frame = button, label = label, draggable = true})
        end
    end
    return result
end
