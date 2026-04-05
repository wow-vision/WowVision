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
        local id = button:GetID()
        if id == nil then
            return nil
        end
        local label, price, count
        local numInStock = -1
        if props.buyback then
            label, _, price, count = GetBuybackItemInfo(id)
        else
            label, _, price, count, numInStock = GetMerchantItemInfo(id)
        end

        --Account for single frames where data isn't yet populated for label text
        if label == nil or label == "" then
            label = ""
        end

        if count > 1 then
            label = label .. " x " .. count
        end

        if price > 0 then
            label = label .. ", " .. C_CurrencyInfo.GetCoinText(price)
        end

        if numInStock >= 0 then
            label = label .. ", " .. numInStock .. " " .. L["in stock"]
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
