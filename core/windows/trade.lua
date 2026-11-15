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
        local name, _, count, quality = getInfo(id)
        local label = WowVision.items.formatName(name, quality) or L["Empty"]
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
            WowVision.cursor = WowVision.cursor or {}
            WowVision.cursor.pickupIsActionBar = false
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

    -- Each coin box is its own stop: tabbing into a box starts typing, and
    -- Tab out goes to the NEXT STOP, so boxes sharing a stop would be
    -- unreachable.
    builder:pushContext("playerMoney", L["Money"])
    -- Trade money is SEALED from addons on this client: the input frame is
    -- forbidden (SetForbidden in TradeFrame.lua) AND the SetTradeMoney API
    -- is a forbidden function -- anti-scam hardening at both layers. The
    -- offered amount reads live; entering it is only possible with the
    -- mouse in the default UI.
    builder:beginStop("playerMoney")
    builder:addItem(
        ControlId.structural("playerMoney"),
        nodes.text({
            label = function()
                local money = GetPlayerTradeMoney()
                if money ~= nil and money > 0 then
                    return C_CurrencyInfo.GetCoinText(money)
                end
                return L["Empty"]
            end,
        })
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

-- ---- accepting the trade with a key ----
--
-- The Accept Trade key accepts the open trade without the trade window, also in combat (the window cannot take the
-- keys in a fight). The game's AcceptTrade is protected in combat (learned by Sku in game: an addon's own click of
-- the Trade button is blocked there), so the key is a secure macro: a /click of the Trade button, the click a mouse
-- user makes, then afterAccept below says what came of it. The game reports the acceptance itself
-- (TRADE_ACCEPT_UPDATE): only then is "Trade accepted" said.
--
-- Left to Sku when it is loaded: Sku binds the same key to its own trade accept.
local ACCEPT_WAIT = 3
local SECURE_CONFIRM = "Security confirmation WowVision cannot reach: use the mouse, or cancel and trade again"
local acceptPressedAt = nil
local securePending = false
local offerWarned = false

local function sku()
    local loaded = WowVision.loadedAddons
    return loaded ~= nil and (loaded.Sku or loaded.sku) and true or false
end

local function partnerName()
    return TradeFrameRecipientNameText ~= nil and TradeFrameRecipientNameText:GetText() or nil
end

-- Why the key's click did nothing, or nil when the trade could be accepted. Read right after the click: the game's
-- answer comes later, so this is still the state the click met.
function module.acceptRefusal()
    if TradeFrame == nil or not TradeFrame:IsShown() then
        return L["No trade open"]
    end
    if securePending then
        return L[SECURE_CONFIRM]
    end
    if TradeFrameTradeButton:IsEnabled() then
        return nil
    end
    -- the button is disabled while your acceptance stands (TradeFrame_SetAcceptState)
    if TradeFrame.acceptState == 1 then
        return WowVision.secrets.join({ L["Already accepted, waiting for"], partnerName() }, " ")
    end
    -- a soulbinding enchant offered: the game disables the button until its popup is answered
    if StaticPopup_Visible ~= nil and StaticPopup_Visible("TRADE_POTENTIAL_BIND_ENCHANT") then
        return L["Answer the popup about the enchant first"]
    end
    return L["Trade cannot be accepted now"]
end

-- After the key's /click (the secure macro's /run): a refusal is said now, an acceptance when the game reports it.
function module.afterAccept()
    local refusal = module.acceptRefusal()
    if refusal ~= nil then
        acceptPressedAt = nil
        WowVision:notify(refusal)
        return
    end
    acceptPressedAt = GetTime()
end

module:registerBinding({
    type = "Script",
    key = "trade/accept",
    inputs = { "ALT-CTRL-T" },
    label = L["Accept Trade"],
    conflictingAddons = { "Sku" },
    script = "/click TradeFrameTradeButton\n/run WowVision.base.windows.trade.afterAccept()",
})

-- The changed-offer warning sighted players see on the Trade button (TradeFrame_UpdateWarnings shows its icon), said
-- when it appears. A changed offer after an acceptance makes the server ask for the game's security confirmation
-- (Blizzard_SecureTransferUI), a dialog addons cannot touch and the keyboard cannot answer: said, so the trade does
-- not seem stuck.
module:registerEvent("event", "TRADE_ACCEPT_UPDATE")
module:registerEvent("event", "TRADE_UPDATE_WARNINGS")
module:registerEvent("event", "TRADE_CLOSED")
module:registerEvent("event", "SECURE_TRANSFER_CONFIRM_TRADE_ACCEPT")
module:registerEvent("event", "SECURE_TRANSFER_CANCEL")

function module:onEvent(event, ...)
    if sku() then
        return
    end
    if event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted = ...
        securePending = false
        if playerAccepted == 1 and acceptPressedAt ~= nil and GetTime() - acceptPressedAt < ACCEPT_WAIT then
            WowVision:notify(L["Trade accepted"])
        end
        acceptPressedAt = nil
    elseif event == "TRADE_UPDATE_WARNINGS" then
        local warn = C_TradeInfo ~= nil
            and C_TradeInfo.ShouldShowTradeOfferWarning ~= nil
            and C_TradeInfo.ShouldShowTradeOfferWarning()
            or false
        if warn and not offerWarned then
            local partner = partnerName() or ""
            local text = TRADE_WARNING_CHANGED_OFFER ~= nil and format(TRADE_WARNING_CHANGED_OFFER, partner)
                or WowVision.secrets.join({ partner, L["changed the offer"] }, " ")
            WowVision:notify(text)
        end
        offerWarned = warn and true or false
    elseif event == "TRADE_CLOSED" then
        securePending, offerWarned, acceptPressedAt = false, false, nil
    elseif event == "SECURE_TRANSFER_CONFIRM_TRADE_ACCEPT" then
        securePending = true
        acceptPressedAt = nil
        WowVision:notify(L[SECURE_CONFIRM])
    elseif event == "SECURE_TRANSFER_CANCEL" then
        securePending = false
    end
end

module:registerWindow({
    type = "FrameWindow",
    name = "trade",
    frameName = "TradeFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
