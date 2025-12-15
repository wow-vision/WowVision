local gen = WowVision.ui.generator
local L = LibStub("AceLocale-3.0"):GetLocale("WowVision")

gen:Element("money/MoneyFrame", function(props)
    local frame = props.frame
    local money = 0
    local label = (props.label .. ": ") or ""
    local updateFunc = GetMoneyTypeInfoField(frame.moneyType, "UpdateFunc")
    if updateFunc then
        money = updateFunc(frame) or money
    end
    return { "Text", text = label .. C_CurrencyInfo.GetCoinText(money) }
end)
