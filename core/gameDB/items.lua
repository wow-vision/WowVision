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
        local name, _, count, quality = GetTradePlayerItemInfo(props.id)
        local label = WowVision.items.formatName(name, quality) or L["Empty"]
        if label and count and count > 0 then
            label = label .. " x" .. count
        end
        return label
    end,
})

db:register("TradeTarget", {
    getLabel = function(button, props)
        local name, _, count, quality = GetTradeTargetItemInfo(props.id)
        local label = WowVision.items.formatName(name, quality) or L["Empty"]
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
        elseif C_MerchantFrame ~= nil and C_MerchantFrame.GetItemInfo ~= nil then
            -- GetMerchantItemInfo was deprecated in 11.0.5 and removed in
            -- 12.0.0 (Retail and WoW: Forever); Classic/TBC/Mists still
            -- have it.
            local info = C_MerchantFrame.GetItemInfo(id)
            if info ~= nil then
                label = info.name
                price = info.price
                count = info.stackCount
                numInStock = info.numAvailable or -1
            end
        else
            label, _, price, count, numInStock = GetMerchantItemInfo(id)
        end

        --Account for single frames where data isn't yet populated for label text
        if label == nil or label == "" then
            label = ""
        else
            local getLink = props.buyback and GetBuybackItemLink or GetMerchantItemLink
            local link = getLink ~= nil and getLink(id) or nil
            label = WowVision.items.formatName(label, WowVision.items.getQuality(link))
        end

        if count ~= nil and count > 1 then
            label = label .. " x " .. count
        end

        if price ~= nil and price > 0 then
            label = label .. ", " .. C_CurrencyInfo.GetCoinText(price)
        end

        if numInStock ~= nil and numInStock >= 0 then
            label = label .. ", " .. numInStock .. " " .. L["in stock"]
        end

        -- Buying back costs gold only; the cost functions read the goods
        -- list, so a buyback slot would get the extra costs of a good.
        local alternativeCount = props.buyback and 0 or GetMerchantItemCostInfo(id)
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
