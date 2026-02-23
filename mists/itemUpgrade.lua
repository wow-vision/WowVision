local module = WowVision.base.windows:createModule("itemUpgrade")
local L = module.L
module:setLabel(L["Item Upgrade"])
local gen = module:hasUI()

local function getUpgradeLabel(frame)
    local label = ItemUpgradeFrameUpgradeButton:GetText()
    local itemButton = frame.ItemButton
    if itemButton.Cost:IsVisible() then
        local currencyID = itemButton.Cost.currencyID
        if not currencyID then
            return label
        end
        local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        label = label .. " " .. info.name .. " " .. itemButton.Cost.Amount:GetText()
    end
    return label
end

gen:Element("itemUpgrade", function(props)
    local frame = props.frame
    local result = {
        "Panel",
        label = L["Item Upgrade"],
        wrap = true,
        children = {
            { "itemUpgrade/ItemButton", frame = frame.ItemButton },
        },
    }
    if frame.UpgradeStatus:IsVisible() then
        tinsert(result.children, { "Text", text = frame.UpgradeStatus:GetText() })
    end
    if frame.TitleTextLeft:IsVisible() then
        tinsert(result.children, {
            "itemUpgrade/Stats",
            statsFrame = frame.LeftStat,
            titleFrame = frame.TitleTextLeft,
            ilevelFrame = frame.LeftItemLevel,
        })
    end
    if frame.TitleTextRight:IsVisible() then
        tinsert(result.children, {
            "itemUpgrade/Stats",
            statsFrame = frame.RightStat,
            titleFrame = frame.TitleTextRight,
            ilevelFrame = frame.RightItemLevel,
        })
    end
    tinsert(result.children, {
        "ProxyButton",
        frame = ItemUpgradeFrameUpgradeButton,
        label = getUpgradeLabel(frame),
    })
    return result
end)

gen:Element("itemUpgrade/ItemButton", function(props)
    local button = props.frame
    local label
    if button.MissingText:IsVisible() then
        label = button.MissingText:GetText()
    else
        label = button.ItemName:GetText()
    end
    return { "ItemButton", frame = button, label = label }
end)

gen:Element("itemUpgrade/Stats", function(props)
    local result = {
        "List",
        label = props.titleFrame:GetText(),
        children = {
            {
                "Text",
                text = props.ilevelFrame.ItemLevelText:GetText() .. " " .. props.ilevelFrame.iLvlText:GetText(),
            },
        },
    }
    for i = 1, ITEM_UPGRADE_MAX_STATS_SHOWN do
        local stat = props.statsFrame[i]
        if stat and stat:IsVisible() then
            local label = stat.ItemText:GetText() .. " " .. stat.ItemLevelText:GetText()
            if stat.ItemIncText then
                label = label .. " " .. stat.ItemIncText:GetText()
            end
            tinsert(result.children, { "Text", text = label })
        end
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "itemUpgrade",
    generated = true,
    rootElement = "itemUpgrade",
    frameName = "ItemUpgradeFrame",
    conflictingAddons = { "Sku" },
})
