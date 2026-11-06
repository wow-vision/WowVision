-- The equipped items an item tooltip compares with (see
-- WowVision.tooltips.comparison): the game fills two shopping tooltips with
-- SetCompareItem, as GameTooltip_ShowCompareItem does when a sighted player
-- holds Shift. Our own frames, so the game's ShoppingTooltip1 and 2 stay
-- untouched. The game decides which slots (both rings, both hands for a
-- two-hander) and what goes into each box.
local frames = nil

local function getFrames()
    if frames == nil then
        frames = {
            CreateFrame("GameTooltip", "WowVisionCompareTooltip1", nil, "ShoppingTooltipTemplate"),
            CreateFrame("GameTooltip", "WowVisionCompareTooltip2", nil, "ShoppingTooltipTemplate"),
        }
    end
    return frames
end

function WowVision.tooltips.comparison.fill(source)
    local primary, secondary = unpack(getFrames())
    primary:SetOwner(WorldFrame, "ANCHOR_NONE")
    secondary:SetOwner(WorldFrame, "ANCHOR_NONE")
    primary:SetCompareItem(secondary, source)
    -- The game's header ("Currently Equipped") is the box's first line;
    -- comparison.append adds it only where that line is missing.
    local blocks = {}
    for _, frame in ipairs(frames) do
        if frame:NumLines() > 0 then
            tinsert(blocks, { frame = frame, header = CURRENTLY_EQUIPPED })
        end
    end
    return blocks
end
