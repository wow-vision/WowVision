local module = WowVision.base.windows:createModule("itemUpgrade")
local L = module.L
module:setLabel(L["Item Upgrade"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The item upgrade window: the item slot, the upgrade status, the current
-- and upgraded stat columns, and the upgrade button carrying its currency
-- cost. Live throughout: placing an item rewrites the columns.

local function getUpgradeLabel()
    local label = ItemUpgradeFrameUpgradeButton:GetText() or ""
    local itemButton = ItemUpgradeFrame.ItemButton
    if itemButton.Cost:IsVisible() then
        local currencyID = itemButton.Cost.currencyID
        if not currencyID then
            return label
        end
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        label = label .. " " .. info.name .. " " .. (itemButton.Cost.Amount:GetText() or "")
    end
    return label
end

local function statColumn(builder, stopKey, statsFrame, titleFrame, ilevelFrame)
    builder:beginStop(stopKey)
    builder:pushContext(stopKey, titleFrame:GetText() or "")
    builder:addItem(
        ControlId.structural(stopKey .. ":ilevel"),
        nodes.text({
            label = function()
                return (ilevelFrame.ItemLevelText:GetText() or "") .. " " .. (ilevelFrame.iLvlText:GetText() or "")
            end,
        })
    )
    for i = 1, ITEM_UPGRADE_MAX_STATS_SHOWN do
        local stat = statsFrame[i]
        if stat ~= nil and stat:IsVisible() then
            local captured = stat
            builder:addItem(
                ControlId.structural(stopKey .. ":stat:" .. i),
                nodes.text({
                    label = function()
                        local label = (captured.ItemText:GetText() or "")
                            .. " "
                            .. (captured.ItemLevelText:GetText() or "")
                        if captured.ItemIncText then
                            label = label .. " " .. (captured.ItemIncText:GetText() or "")
                        end
                        return label
                    end,
                })
            )
        end
    end
    builder:popContext()
end

local function render(builder, screen)
    local frame = ItemUpgradeFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("itemUpgrade", L["Item Upgrade"])

    builder:beginStop("item")
    local itemButton = frame.ItemButton
    local vtable = nodes.proxyButton({
        target = itemButton,
        label = function()
            if itemButton.MissingText:IsVisible() then
                return itemButton.MissingText:GetText()
            end
            return itemButton.ItemName:GetText()
        end,
    })
    if vtable ~= nil then
        tinsert(vtable.bindings, {
            binding = "drag",
            type = "Function",
            func = function()
                local script = itemButton:GetScript("OnDragStart")
                if script ~= nil then
                    script(itemButton)
                end
            end,
        })
        builder:addItem(ControlId.forObject(itemButton), vtable)
    end

    if frame.UpgradeStatus:IsVisible() then
        builder:beginStop("status")
        builder:addItem(
            ControlId.structural("status"),
            nodes.text({
                label = function()
                    return frame.UpgradeStatus:GetText()
                end,
            })
        )
    end

    if frame.TitleTextLeft:IsVisible() then
        statColumn(builder, "currentItem", frame.LeftStat, frame.TitleTextLeft, frame.LeftItemLevel)
    end
    if frame.TitleTextRight:IsVisible() then
        statColumn(builder, "upgradedItem", frame.RightStat, frame.TitleTextRight, frame.RightItemLevel)
    end

    builder:beginStop("upgrade")
    builder:addItem(
        ControlId.forObject(ItemUpgradeFrameUpgradeButton),
        nodes.proxyButton({ target = ItemUpgradeFrameUpgradeButton, label = getUpgradeLabel })
    )

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "itemUpgrade",
    frameName = "ItemUpgradeFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
