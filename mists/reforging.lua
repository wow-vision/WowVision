local module = WowVision.base.windows:createModule("reforging")
local L = module.L
module:setLabel(L["Reforging"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The reforging window: the item slot, the two stat columns (pick a stat to
-- reduce, pick one to gain) as check-button lists, the cost, and the
-- reforge and restore buttons. Everything reads live: dropping an item in
-- rewrites the columns in place.

local function statColumn(builder, stopKey, prefix, titleFrame)
    builder:beginStop(stopKey)
    builder:pushContext(stopKey, titleFrame ~= nil and titleFrame:GetText() or "")
    for i = 1, REFORGE_MAX_STATS_SHOWN do
        local stat = _G[prefix .. i]
        if stat ~= nil and stat:IsShown() then
            local captured = stat
            builder:addItem(
                ControlId.forObject(captured),
                nodes.proxyCheckButton({
                    target = captured,
                    label = function()
                        return captured.text:GetText()
                    end,
                })
            )
        end
    end
    builder:popContext()
end

local function render(builder, screen)
    if ReforgingFrame == nil or not ReforgingFrame:IsShown() then
        return
    end
    builder:pushContext("reforging", L["Reforging"])

    local itemButton = ReforgingFrameItemButton
    if itemButton ~= nil and itemButton:IsShown() then
        builder:beginStop("item")
        local vtable = nodes.proxyButton({
            target = itemButton,
            label = function()
                if itemButton.missingText:IsVisible() then
                    return itemButton.missingText:GetText()
                end
                return itemButton.name:GetText()
            end,
        })
        if vtable ~= nil then
            tinsert(vtable.bindings, {
                binding = "drag",
                type = "Function",
                func = function()
                    local script = itemButton:GetScript("OnDragStart")
                    if script ~= nil then
                        script(itemButton)
                    end
                end,
            })
            builder:addItem(ControlId.forObject(itemButton), vtable)
        end
    end

    statColumn(builder, "currentStats", "ReforgingFrameLeftStat", ReforgingFrameTitleTextLeft)
    statColumn(builder, "newStats", "ReforgingFrameRightStat", ReforgingFrameTitleTextRight)

    if ReforgingFrameRestoreMessage:IsVisible() then
        builder:beginStop("restoreMessage")
        builder:addItem(
            ControlId.structural("restoreMessage"),
            nodes.text({
                label = function()
                    return ReforgingFrameRestoreMessage:GetText()
                end,
            })
        )
    end
    if ReforgingFrameMoneyFrame:IsVisible() and (ReforgingFrameMoneyFrame.staticMoney or 0) > 0 then
        builder:beginStop("cost")
        builder:addItem(
            ControlId.structural("cost"),
            nodes.text({
                label = function()
                    return C_CurrencyInfo.GetCoinText(ReforgingFrameMoneyFrame.staticMoney or 0)
                end,
            })
        )
    end

    for _, button in ipairs({ ReforgingFrameReforgeButton, ReforgingFrameRestoreButton }) do
        if button ~= nil and button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "reforging",
    frameName = "ReforgingFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
