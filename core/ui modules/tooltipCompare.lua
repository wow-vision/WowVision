local module = WowVision.base.ui.tooltip:createModule("compare")
local L = module.L
module:setLabel(L["Compare"])

-- What an item tooltip says after the game's own lines (gameDB/itemCompare.lua): Pawn's upgrade summary, and a
-- comparison with the item worn in the same slot. Disabling the module, or one box, drops that part only; the rest of
-- the tooltip is untouched.
local settings = module:hasSettings()
settings:add({ type = "Bool", key = "pawn", label = L["Pawn Summary"], default = true })
settings:add({ type = "Bool", key = "equipped", label = L["Compare With Equipped Item"], default = true })

function WowVision.items.compareEnabled(part)
    if not module:getEnabled() then
        return false
    end
    return module.settings[part] ~= false
end
