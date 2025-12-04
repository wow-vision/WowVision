local gen = WowVision.ui.generator
local L = LibStub("AceLocale-3.0"):GetLocale("WowVision")

gen:Element("money/static", function(props)
    local label = (props.label .. ": ") or ""
    return { "Text", text = label .. C_CurrencyInfo.GetCoinText(props.frame.staticMoney) }
end)
