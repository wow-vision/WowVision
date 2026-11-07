-- The equipped items an item tooltip compares with (see
-- WowVision.tooltips.comparison): the game fills two shopping tooltips with
-- SetCompareItem, as GameTooltip_ShowCompareItem does when a sighted player
-- holds Shift, into our own boxes (comparison.frames). The game decides
-- which slots (both rings, both hands for a two-hander) and what goes into
-- each box.
function WowVision.tooltips.comparison.fill(source)
    -- An item that is on already (the character window) is not compared
    -- with itself, as the game skips it for its own automatic comparison.
    if source.IsEquippedItem ~= nil and source:IsEquippedItem() then
        return nil
    end
    local frames = WowVision.tooltips.comparison.frames()
    local primary, secondary = unpack(frames)
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
