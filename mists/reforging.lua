local module = WowVision.base.windows:createModule("reforging")
local L = module.L
module:setLabel(L["Reforging"])
local gen = module:hasUI()

gen:Element("reforging", function(props)
    local frame = props.frame
    local result = {
        "Panel",
        label = L["Reforging"],
        wrap = true,
        children = {
            { "reforging/ItemButton" },
            { "reforging/Stats", prefix = "ReforgingFrameLeftStat", titleFrame = ReforgingFrameTitleTextLeft },
            { "reforging/Stats", prefix = "ReforgingFrameRightStat", titleFrame = ReforgingFrameTitleTextRight },
        },
    }
    if ReforgingFrameRestoreMessage:IsVisible() then
        tinsert(result.children, { "Text", text = ReforgingFrameRestoreMessage:GetText() })
    end
    if ReforgingFrameMoneyFrame:IsVisible() and ReforgingFrameMoneyFrame.staticMoney > 0 then
        tinsert(result.children, {
            "Text",
            text = C_CurrencyInfo.GetCoinText(ReforgingFrameMoneyFrame.staticMoney),
        })
    end
    tinsert(result.children, { "ProxyButton", frame = ReforgingFrameReforgeButton })
    tinsert(result.children, { "ProxyButton", frame = ReforgingFrameRestoreButton })
    return result
end)

gen:Element("reforging/ItemButton", function(props)
    local button = ReforgingFrameItemButton
    if not button or not button:IsShown() then
        return nil
    end
    local label
    if button.missingText:IsVisible() then
        label = button.missingText:GetText()
    else
        label = button.name:GetText()
    end
    return { "ItemButton", frame = button, label = label }
end)

gen:Element("reforging/Stats", function(props)
    local prefix = props.prefix
    local result = { "List", label = props.titleFrame:GetText(), children = {} }
    for i = 1, REFORGE_MAX_STATS_SHOWN do
        local stat = _G[prefix .. i]
        if stat and stat:IsShown() then
            label = stat.text:GetText()
            tinsert(result.children, { "ProxyCheckButton", frame = stat, label = label })
        end
    end
    return result
end)

module:registerWindow({
    type = "FrameWindow",
    name = "reforging",
    generated = true,
    rootElement = "reforging",
    frameName = "ReforgingFrame",
    conflictingAddons = { "Sku" },
})
