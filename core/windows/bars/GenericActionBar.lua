local module = WowVision.base.windows.bars
local L = module.L

local GenericActionBar = WowVision.components.createType("bars", { key = "GenericActionBar" })
GenericActionBar.info:addFields({
    { key = "frame", required = true },
})

function GenericActionBar:isVisible()
    return self.frame and self.frame:IsShown()
end

function GenericActionBar:getGenerator()
    local result = { "List", direction = "horizontal", label = self.label, children = {} }
    local children = self.frame.actionButtons
    if not children then
        children = { self.frame:GetChildren() }
    end
    for _, button in ipairs(children) do
        tinsert(result.children, { "bars/ActionButton", frame = button })
    end
    return result
end
