-- The equipped items an item tooltip compares with (see
-- WowVision.tooltips.comparison), filled the way the game's
-- TooltipComparisonManager fills the shopping tooltips sighted players get
-- on Shift: C_TooltipComparison picks the equipped items, C_TooltipInfo
-- gives their lines, GetItemComparisonDelta the stat changes. Only data
-- calls; C_TooltipComparison.CompareItem, which shows the game's own boxes,
-- is protected. Both read functions refuse a secret argument from addon
-- code: the link is checked before (Tooltip:addComparison), the guid here.
-- The boxes are our own (comparison.frames).

-- The shown item as the game compares it: by guid where the tooltip has
-- one (a bag item, with its upgrades), else by link (chat, vendor).
local function getComparisonItem(source, link)
    local data = source.GetPrimaryTooltipData ~= nil and source:GetPrimaryTooltipData() or nil
    if data ~= nil and data.guid ~= nil and not WowVision.isSecret(data.guid) then
        return { guid = data.guid, overrideItemLevel = data.overrideItemLevel }
    end
    return { hyperlink = link }
end

local function getItemData(item)
    if item.guid ~= nil then
        return C_TooltipInfo.GetItemByGUID(item.guid)
    elseif item.hyperlink ~= nil then
        return C_TooltipInfo.GetHyperlink(item.hyperlink)
    end
    return nil
end

-- One box, in the game's order: the equipped item, then the stat changes
-- (always for the first box, for the second only when it is compared on
-- its own). The game's line about its cycling key is left out: that key
-- swaps the boxes on screen and does nothing here.
local function fillBox(frame, compared, info, isPrimary)
    local displayed = isPrimary and info.item or info.additionalItems[1]
    local data = displayed ~= nil and getItemData(displayed) or nil
    if data == nil then
        return nil
    end
    local method = info.method
    local single = Enum.TooltipComparisonMethod.Single
    local isPaired = method == Enum.TooltipComparisonMethod.WithBagMainHandItem
        or method == Enum.TooltipComparisonMethod.WithBagOffHandItem

    frame:SetOwner(WorldFrame, "ANCHOR_NONE")
    frame:ClearLines()
    frame:ProcessInfo({ tooltipData = data, append = true })

    if isPrimary or method == single then
        local additional = method ~= single and info.additionalItems[1] or nil
        local delta = C_TooltipComparison.GetItemComparisonDelta(compared, displayed, additional, isPaired)
        if delta ~= nil and #delta > 0 then
            local summary = ITEM_DELTA_DESCRIPTION
            if isPrimary and method == Enum.TooltipComparisonMethod.WithBothHands then
                summary = ITEM_DELTA_MULTIPLE_COMPARISON_DESCRIPTION
            end
            GameTooltip_AddBlankLineToTooltip(frame)
            GameTooltip_AddNormalLine(frame, summary)
            if isPaired and additional ~= nil then
                local formatString = ITEM_DELTA_DUAL_WIELD_COMPARISON_MAINHAND_DESCRIPTION
                if method == Enum.TooltipComparisonMethod.WithBagOffHandItem then
                    formatString = ITEM_DELTA_DUAL_WIELD_COMPARISON_OFFHAND_DESCRIPTION
                end
                local itemName = C_Item.GetItemNameByID(additional.guid or additional.hyperlink)
                local itemQuality = C_Item.GetItemQualityByID(additional.guid or additional.hyperlink)
                if itemName ~= nil then
                    GameTooltip_AddBlankLineToTooltip(frame)
                    local colorData = ColorManager.GetColorDataForItemQuality(itemQuality)
                    if colorData ~= nil then
                        GameTooltip_AddNormalLine(frame, formatString:format(colorData.color:GenerateHexColor(), itemName))
                    else
                        GameTooltip_AddNormalLine(frame, itemName)
                    end
                end
            end
            for _, line in ipairs(delta) do
                GameTooltip_AddHighlightLine(frame, line)
            end
        end
    end

    local header = EQUIPPED
    if not isPrimary and isPaired then
        header = IF_EQUIPPED_TOGETHER
    end
    return { frame = frame, header = header }
end

function WowVision.tooltips.comparison.fill(source, link)
    local compared = getComparisonItem(source, link)
    local info = C_TooltipComparison.GetItemComparisonInfo(compared)
    if info == nil or info.item == nil then
        return nil
    end
    -- An item that is on already (the character window) is not compared
    -- with itself.
    if compared.guid ~= nil and info.item.guid == compared.guid then
        return nil
    end
    local primary, secondary = unpack(WowVision.tooltips.comparison.frames())
    local blocks = {}
    for index, frame in ipairs({ primary, secondary }) do
        local block = fillBox(frame, compared, info, index == 1)
        if block ~= nil then
            tinsert(blocks, block)
        end
    end
    return blocks
end
