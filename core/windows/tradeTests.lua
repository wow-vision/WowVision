-- The Accept Trade key (trade.lua): why its click did nothing, and "Trade accepted" only once the game reports the
-- acceptance. The harness in tools/headless-tests.lua loads trade.lua against a stand-in window module.
local testRunner = WowVision.testing.testRunner
local trade = WowVision._popupsTestHarness.trade

-- The game's trade frame and its Trade button, the speech, and the clock, as one test needs them.
local function withTrade(state, fn)
    local saved = {
        frame = TradeFrame,
        button = TradeFrameTradeButton,
        name = TradeFrameRecipientNameText,
        visible = StaticPopup_Visible,
        notify = WowVision.notify,
        getTime = GetTime,
        loaded = WowVision.loadedAddons,
    }
    local said = {}
    local clock = { now = 10 }
    TradeFrame = {
        shown = state.open ~= false,
        acceptState = state.accepted and 1 or 0,
    }
    function TradeFrame:IsShown()
        return self.shown
    end
    TradeFrameTradeButton = { enabled = state.enabled ~= false }
    function TradeFrameTradeButton:IsEnabled()
        return self.enabled
    end
    TradeFrameRecipientNameText = {
        GetText = function()
            return "Bob"
        end,
    }
    StaticPopup_Visible = function(which)
        return which == "TRADE_POTENTIAL_BIND_ENCHANT" and state.enchantPopup == true
    end
    WowVision.notify = function(_, text)
        tinsert(said, text)
    end
    GetTime = function()
        return clock.now
    end
    WowVision.loadedAddons = {}
    local ok, err = pcall(fn, said, clock)
    trade:onEvent("TRADE_CLOSED")
    TradeFrame, TradeFrameTradeButton, TradeFrameRecipientNameText = saved.frame, saved.button, saved.name
    StaticPopup_Visible, WowVision.notify, GetTime = saved.visible, saved.notify, saved.getTime
    WowVision.loadedAddons = saved.loaded
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("AcceptTrade", {
    ["without a trade it says so"] = function(t)
        withTrade({ open = false }, function(said)
            trade.afterAccept()
            t:assertEqual(said[1], "No trade open")
        end)
    end,

    ["an enabled button waits for the game's answer before saying accepted"] = function(t)
        withTrade({}, function(said, clock)
            trade.afterAccept()
            t:assertNil(said[1], "nothing yet: the click may still be refused")
            clock.now = clock.now + 0.5
            trade:onEvent("TRADE_ACCEPT_UPDATE", 1, 0)
            t:assertEqual(said[1], "Trade accepted")
        end)
    end,

    ["the other player's acceptance alone says nothing"] = function(t)
        withTrade({}, function(said)
            trade:onEvent("TRADE_ACCEPT_UPDATE", 1, 1)
            t:assertNil(said[1], "no key was pressed")
        end)
    end,

    ["your acceptance standing: waiting for the other player"] = function(t)
        withTrade({ enabled = false, accepted = true }, function(said)
            trade.afterAccept()
            t:assertEqual(said[1], "Already accepted, waiting for Bob")
        end)
    end,

    ["the enchant popup holds the button"] = function(t)
        withTrade({ enabled = false, enchantPopup = true }, function(said)
            trade.afterAccept()
            t:assertEqual(said[1], "Answer the popup about the enchant first")
        end)
    end,

    ["the security confirmation is said, and the key says it again"] = function(t)
        withTrade({}, function(said)
            trade:onEvent("SECURE_TRANSFER_CONFIRM_TRADE_ACCEPT")
            trade.afterAccept()
            t:assertEqual(said[1], said[2])
            t:assertEqual(said[1], "Security confirmation WowVision cannot reach: use the mouse, or cancel and trade again")
            trade:onEvent("SECURE_TRANSFER_CANCEL")
            t:assertNil(trade.acceptRefusal())
        end)
    end,

    ["with Sku loaded the events are Sku's"] = function(t)
        withTrade({}, function(said)
            WowVision.loadedAddons = { Sku = true }
            trade:onEvent("SECURE_TRANSFER_CONFIRM_TRADE_ACCEPT")
            t:assertNil(said[1])
        end)
    end,
})
