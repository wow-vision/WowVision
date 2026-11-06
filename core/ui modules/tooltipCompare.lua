local module = WowVision.base.ui.tooltip:createModule("compare")
local L = module.L
module:setLabel(L["Compare with Equipped"])

-- Item tooltips end with the equipped items they compare with, as the
-- game's shopping tooltips show them on Shift. Disabling the module drops
-- those blocks.
function WowVision.tooltips.comparison.isEnabled()
    return module:getEnabled()
end
