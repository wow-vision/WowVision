local module = WowVision.base.ui.tooltip:createModule("compare")
local L = module.L
module:setLabel(L["Compare"])

-- What an item tooltip says after the game's own lines:
--   * Pawn's upgrade summary (gameDB/itemCompare.lua), a checkbox;
--   * a comparison with the item worn in the same slot, one of three:
--     the game's own (the shopping tooltips sighted players get on Shift,
--     ui/tooltip/Tooltip.lua and the version folders' tooltipCompare.lua),
--     WowVision's spelled-out stat differences (gameDB/itemCompare.lua), or
--     none.
-- Disabling the module drops both parts; the rest of the tooltip is untouched.
local settings = module:hasSettings()
settings:add({ type = "Bool", key = "pawn", label = L["Pawn Summary"], default = true })

local COMPARISONS = {
    { label = L["None"], value = "none" },
    { label = L["Game"], value = "game" },
    { label = L["WowVision"], value = "wowvision" },
}
local DEFAULT_COMPARISON = "game"

settings:add({
    type = "Choice",
    key = "comparison",
    label = L["Compare With Equipped Item"],
    default = DEFAULT_COMPARISON,
    choices = COMPARISONS,
})

local function comparison()
    if not module:getEnabled() then
        return "none"
    end
    return module.settings.comparison or DEFAULT_COMPARISON
end

function WowVision.items.compareEnabled(part)
    if part == "equipped" then
        return comparison() == "wowvision"
    end
    return module:getEnabled() and module.settings[part] ~= false
end

function WowVision.tooltips.comparison.isEnabled()
    return comparison() == "game"
end
