local module = WowVision.base.windows.bars
local L = module.L

local PetActionBar = WowVision.components.createType("bars", { key = "PetActionBar" })

function PetActionBar:isVisible()
    return PetHasActionBar()
end

function PetActionBar:getGenerator()
    local result = { "List", label = self.label, direction = "horizontal", children = {} }
    for i = 1, NUM_PET_ACTION_SLOTS do
        local button = _G["PetActionButton" .. i]
        local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(i)
        local label = button.tooltipName or L["Empty"]
        if autoCastAllowed then
            if autoCastEnabled then
                label = label .. " " .. L["Auto Casting"]
            else
                label = label .. " " .. L["Not Auto Casting"]
            end
        end
        tinsert(result.children, {
            "ProxyButton",
            frame = button,
            label = label,
            ignoreRequiresFrameShown = true,
            draggable = true
        })
    end
    return result
end
