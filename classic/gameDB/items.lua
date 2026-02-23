local L = WowVision:getLocale()
local db = WowVision.gameDB:get("Item")

local function getCountText(button)
    if button.Count then
        if button.Count:IsShown() and button.Count:IsVisible() then
            return button.Count:GetText()
        end
    end
    return nil
end

db:register("TradePlayer", {
    getLabel = function(button, props)
        local name, _, count, _, _, _ = GetTradePlayerItemInfo(props.id)
        local label = name or L["Empty"]
        if label and count and count > 0 then
            label = label .. " x" .. count
        end
        return label
    end,
})

db:register("TradeTarget", {
    getLabel = function(button, props)
        local name, _, count, _, _, _ = GetTradeTargetItemInfo(props.id)
        local label = name or L["Empty"]
        if label and count and count > 0 then
            label = label .. " x" .. count
        end
        return label
    end,
})

db:register("Merchant", {
    getLabel = function(button, props)
        local parent = button:GetParent()
        local label = parent.Name:GetText() or ""
        local count = getCountText(button)
        local id = button:GetID()
        if count then
            label = label .. " x " .. count
        end
        if button.price then
            label = label .. ", " .. C_CurrencyInfo.GetCoinText(button.price)
        end
        if button.numInStock and button.numInStock > 0 then
            label = label .. ", " .. button.numInStock .. " " .. L["in stock"]
        end
        local alternativeCount = GetMerchantItemCostInfo(id)
        for i = 1, alternativeCount do
            local _, count, itemLink, currencyName = GetMerchantItemCostItem(id, i)
            if currencyName then
                label = label .. ", " .. currencyName .. " " .. count
            elseif itemLink then
                local name = C_Item.GetItemInfo(itemLink)
                if name then
                    label = label .. ", " .. name .. " " .. count
                end
            end
        end
        return label
    end,
})

db:register("Mail", {
    getLabel = function(button, props)
        local label = button.name
        if button.Count:IsShown() then
            label = label .. " x " .. button.Count:GetText()
        end
        return label
    end,
})
