local module = WowVision.base.windows.bars
local L = module.L

local MainActionBar = WowVision.components.createType("bars", { key = "MainActionBar" })

function MainActionBar:getGenerator()
    local result = { "List", direction = "horizontal", label = self.label, children = {} }
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            tinsert(result.children, { "bars/ActionButton", frame = button })
        end
    end
    return result
end
