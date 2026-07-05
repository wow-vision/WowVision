local module = WowVision.base.windows:createModule("trade")
local L = module.L
module:setLabel(L["Trade"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The trade window: your six slots and the other player's six, each side a
-- stop under the trader's name. Slot labels read live from the trade API --
-- the other side's offers appear and change mid-trade -- with real clicks
-- and drag for placing items. Your money entry boxes and their offered
-- money round it out before Trade and Cancel.

local function slotLabel(getInfo, id)
    return function()
        local name, _, count = getInfo(id)
        local label = name or L["Empty"]
        if name ~= nil and count ~= nil and count > 0 then
            label = label .. " x" .. count
        end
        return label
    end
end

local function slotNode(button, label)
    local vtable = nodes.proxyButton({ target = button, label = label })
    if vtable == nil then
        return nil
    end
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local script = button:GetScript("OnDragStart")
            if script ~= nil then
                script(button)
            end
        end,
    })
    return vtable
end

local function renderSide(builder, stopKey, nameText, buttonPrefix, getInfo)
    builder:beginStop(stopKey)
    builder:pushContext(stopKey, nameText ~= nil and nameText:GetText() or "")
    for i = 1, 6 do
        local button = _G[buttonPrefix .. i .. "ItemButton"]
        if button ~= nil then
            builder:addItem(
                ControlId.forObject(button),
                slotNode(button, slotLabel(getInfo, i))
            )
        end
    end
    builder:popContext()
end

local function render(builder, screen)
    if TradeFrame == nil or not TradeFrame:IsShown() then
        return
    end
    builder:pushContext("trade", L["Trade"])

    renderSide(builder, "playerItems", TradeFramePlayerNameText, "TradePlayerItem", GetTradePlayerItemInfo)

    builder:beginStop("playerMoney")
    builder:pushContext("playerMoney", L["Money"])
    builder:addItem(
        ControlId.structural("gold"),
        nodes.proxyEditBox({ editBox = TradePlayerInputMoneyFrameGold, label = L["Gold"] })
    )
    builder:addItem(
        ControlId.structural("silver"),
        nodes.proxyEditBox({ editBox = TradePlayerInputMoneyFrameSilver, label = L["Silver"] })
    )
    builder:addItem(
        ControlId.structural("copper"),
        nodes.proxyEditBox({ editBox = TradePlayerInputMoneyFrameCopper, label = L["Copper"] })
    )
    builder:popContext()

    renderSide(builder, "targetItems", TradeFrameRecipientNameText, "TradeRecipientItem", GetTradeTargetItemInfo)

    builder:beginStop("targetMoney")
    builder:addItem(
        ControlId.structural("targetMoney"),
        nodes.text({
            label = function()
                local money = GetTargetTradeMoney()
                if money ~= nil and money > 0 then
                    return L["Money"] .. " " .. C_CurrencyInfo.GetCoinText(money)
                end
                return L["Money"] .. " " .. L["Empty"]
            end,
        })
    )

    builder:beginStop("trade")
    builder:addItem(ControlId.forObject(TradeFrameTradeButton), nodes.proxyButton({ target = TradeFrameTradeButton }))
    builder:beginStop("cancel")
    builder:addItem(ControlId.forObject(TradeFrameCancelButton), nodes.proxyButton({ target = TradeFrameCancelButton }))

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "trade",
    frameName = "TradeFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
