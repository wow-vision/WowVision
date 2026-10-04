local module = WowVision.base.windows.containers
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- The modern bank (retail and WoW: Forever): one BankFrame whose BankPanel
-- shows the selected bank type, character or account (warband), with the
-- item buttons pooled and carrying their bank tab (a bag id) and slot.
--
-- Two shapes of the same frame family:
--
-- Retail: a tab system picks the bank type, side tabs pick ONE bank tab
-- whose slots fill the panel, and a purchase tab buys the next one.
--
-- Forever (ShouldUsePlayerBagsInBank): every purchased bank tab of the
-- type shows at once, paged, with page tabs down the side (one set per
-- bank type), the bank bag slot buttons along the bottom, and the next
-- bag's price with a purchase button.
--
-- Stops: the tabs (bank type, side tabs, pages), one stop per bank tab
-- holding slots on the page (the slots of a tab read as one bag, like a
-- bank bag on classic), the bank bag slot buttons, the search box, then
-- the controls (sort, money and the money transfer buttons of the
-- account bank, the purchase of the next tab or bag). A locked or
-- unpurchased bank shows its prompt text instead of slots.
local Bank = WowVision.components.createType("containers", { key = "RetailBank" })

local function bankPanel()
    return BankFrame ~= nil and BankFrame.BankPanel or nil
end

function Bank:isOpen()
    return BankFrame ~= nil and BankFrame:IsShown() and BankFrame.BankPanel ~= nil
end

local function activeBankType()
    if BankFrame.GetActiveBankType ~= nil then
        return BankFrame:GetActiveBankType()
    end
    return nil
end

-- A pool's shown frames, sorted.
local function sortedActive(pool, less)
    local list = {}
    if pool ~= nil and pool.EnumerateActive ~= nil then
        for frame in pool:EnumerateActive() do
            if frame:IsShown() then
                tinsert(list, frame)
            end
        end
    end
    table.sort(list, less)
    return list
end

local function fontText(fontString)
    if fontString == nil or not fontString:IsShown() then
        return nil
    end
    local text = fontString:GetText()
    if text == nil or text == "" then
        return nil
    end
    return text
end

-- ---- tabs ----

local function findPageTab(bankType, pageNumber)
    local pool = BankFrame.bankPageTabPool
    if pool == nil then
        return nil
    end
    for tab in pool:EnumerateActive() do
        if tab:IsShown() and tab.bankType == bankType and tab.pageNumber == pageNumber then
            return tab
        end
    end
    return nil
end

local function isCurrentPage(bankType, pageNumber)
    local panel = bankPanel()
    return bankType == activeBankType() and pageNumber == (panel.currentPage or 1)
end

local function findSideTab(tabID)
    local panel = bankPanel()
    local pool = panel ~= nil and panel.bankTabPool or nil
    if pool == nil then
        return nil
    end
    for tab in pool:EnumerateActive() do
        if tab:IsShown() and tab.tabData ~= nil and tab.tabData.ID == tabID then
            return tab
        end
    end
    return nil
end

local function renderTabs(builder)
    local panel = bankPanel()
    local entries = {}
    local function add(id, vtable)
        if vtable ~= nil then
            tinsert(entries, { id = id, vtable = vtable })
        end
    end

    -- Bank type tabs (retail: a tab system across the top).
    if BankFrame.TabSystem ~= nil and BankFrame.GetTabSet ~= nil then
        for _, tabID in ipairs(BankFrame:GetTabSet()) do
            local button = BankFrame:GetTabButton(tabID)
            if button ~= nil and button:IsShown() then
                local id = tabID
                add(
                    ControlId.structural("bank:typeTab:" .. id),
                    nodes.proxyFoundButton({
                        find = function()
                            return BankFrame:GetTabButton(id)
                        end,
                        label = function(tab)
                            return tab.tabText or nodes.frameText(tab)
                        end,
                        selected = function()
                            return BankFrame:GetTab() == id
                        end,
                        rightClick = false,
                    })
                )
            end
        end
    end

    -- Page tabs (Forever: plain frames reacting to mouse up, one per page
    -- and bank type; the label names both). Enter runs the frame's own
    -- mouse-up script, which is what a click does.
    local pages = sortedActive(BankFrame.bankPageTabPool, function(a, b)
        if a.bankType ~= b.bankType then
            return (a.bankType or 0) < (b.bankType or 0)
        end
        return (a.pageNumber or 0) < (b.pageNumber or 0)
    end)
    for _, tab in ipairs(pages) do
        local bankType, pageNumber = tab.bankType, tab.pageNumber
        add(
            ControlId.structural("bank:page:" .. tostring(bankType) .. ":" .. tostring(pageNumber)),
            nodes.button({
                label = function()
                    local current = findPageTab(bankType, pageNumber)
                    return current ~= nil and current.tooltipText or L["Page"]
                end,
                selected = function()
                    return isCurrentPage(bankType, pageNumber)
                end,
                onActivate = function()
                    local current = findPageTab(bankType, pageNumber)
                    local script = current ~= nil and current:GetScript("OnMouseUp") or nil
                    if script ~= nil then
                        script(current, "LeftButton", true)
                    end
                end,
            })
        )
    end

    -- Side tabs (retail: one bank tab shown at a time; right click opens
    -- its settings).
    local sideTabs = sortedActive(panel.bankTabPool, function(a, b)
        return (a.tabData ~= nil and a.tabData.ID or 0) < (b.tabData ~= nil and b.tabData.ID or 0)
    end)
    for _, tab in ipairs(sideTabs) do
        local tabID = tab.tabData ~= nil and tab.tabData.ID or nil
        if tabID ~= nil then
            add(
                ControlId.structural("bank:sideTab:" .. tabID),
                nodes.proxyFoundButton({
                    find = function()
                        return findSideTab(tabID)
                    end,
                    label = function(current)
                        return current.tabData ~= nil and current.tabData.name or BANK
                    end,
                    selected = function()
                        return panel.GetSelectedTabID ~= nil and panel:GetSelectedTabID() == tabID
                    end,
                })
            )
        end
    end
    if panel.PurchaseTab ~= nil and panel.PurchaseTab:IsShown() then
        add(
            ControlId.forObject(panel.PurchaseTab),
            nodes.proxyButton({
                target = panel.PurchaseTab,
                label = panel.PurchaseTab.tooltipText or BANKSLOTPURCHASE or L["Purchase"],
            })
        )
    end

    if #entries == 0 then
        return
    end
    builder:beginStop("bank:tabs")
    builder:pushContext("bank:tabs", L["Bank Tabs"])
    builder:startRow()
    for _, entry in ipairs(entries) do
        builder:addItem(entry.id, entry.vtable)
    end
    builder:endRow()
    builder:popContext()
end

-- ---- slots ----

local function tabLabel(panel, tabID)
    local data = panel.GetTabData ~= nil and panel:GetTabData(tabID) or nil
    if data ~= nil and data.name ~= nil and data.name ~= "" then
        return data.name
    end
    local name = C_Container.GetBagName(tabID)
    if name ~= nil and name ~= "" then
        return name
    end
    return BANK
end

local function renderPrompt(builder, panel)
    local lines = {}
    local lock = panel.LockPrompt
    if lock ~= nil and lock:IsShown() then
        tinsert(lines, fontText(lock.Title))
        tinsert(lines, fontText(lock.PromptText))
    end
    local purchase = panel.PurchasePrompt
    if purchase ~= nil and purchase:IsShown() then
        tinsert(lines, fontText(purchase.Title))
        tinsert(lines, fontText(purchase.PromptText))
    end
    if #lines == 0 then
        return
    end
    builder:beginStop("bank:prompt")
    builder:pushContext("bank:prompt", BANK)
    for i, line in ipairs(lines) do
        builder:addItem(ControlId.structural("bank:prompt:" .. i), nodes.text({ label = line }))
    end
    builder:popContext()
end

-- The shown item buttons grouped by bank tab, one stop per tab.
local function renderSlots(builder, panel)
    local groups = {}
    local order = {}
    if panel.EnumerateValidItems ~= nil then
        for itemButton in panel:EnumerateValidItems() do
            if itemButton:IsShown() and itemButton.GetBankTabID ~= nil then
                local tabID = itemButton:GetBankTabID()
                local list = groups[tabID]
                if list == nil then
                    list = {}
                    groups[tabID] = list
                    tinsert(order, tabID)
                end
                tinsert(list, itemButton)
            end
        end
    end
    table.sort(order)
    for _, tabID in ipairs(order) do
        builder:beginStop("bank:tab:" .. tabID)
        builder:pushContext("bank:tab:" .. tabID, tabLabel(panel, tabID))
        module.renderSlots(builder, groups[tabID])
        builder:popContext()
    end
    if #order == 0 then
        renderPrompt(builder, panel)
    end
end

-- ---- bank bag slots (Forever) ----

local function findBagButton(slot)
    local pool = BankFrame.itemButtonBagPool
    if pool == nil then
        return nil
    end
    for button in pool:EnumerateActive() do
        if button:IsShown() and button.bagSlotID == slot then
            return button
        end
    end
    return nil
end

local function bagButtonLabel(button)
    local name = nil
    if button.DisabledOverlay ~= nil and button.DisabledOverlay:IsShown() then
        name = button.tooltipText
    else
        if button.GetExactBankTabSlot ~= nil then
            name = C_Container.GetBagName(button:GetExactBankTabSlot())
        end
        if name == nil or name == "" then
            name = button.tooltipText
        end
    end
    return L["Bag Slot"] .. " " .. (name or L["Empty"])
end

local function renderBagSlots(builder)
    local buttons = sortedActive(BankFrame.itemButtonBagPool, function(a, b)
        return (a.bagSlotID or 0) < (b.bagSlotID or 0)
    end)
    if #buttons == 0 then
        return
    end
    builder:beginStop("bank:bagSlots")
    builder:pushContext("bank:bagSlots", L["Bank Bag Slots"])
    builder:startRow()
    for _, button in ipairs(buttons) do
        local slot = button.bagSlotID
        builder:addItem(
            ControlId.structural("bank:bagSlot:" .. slot),
            nodes.proxyFoundButton({
                find = function()
                    return findBagButton(slot)
                end,
                label = bagButtonLabel,
                drag = true,
            })
        )
    end
    builder:endRow()
    builder:popContext()
end

-- ---- controls ----

local function moneyLabel()
    local bankType = activeBankType()
    if bankType == Enum.BankType.Account and C_Bank ~= nil and C_Bank.FetchDepositedMoney ~= nil then
        return module.moneyLabel(C_Bank.FetchDepositedMoney(bankType))
    end
    return module.moneyLabel(GetMoney())
end

local function nextTabCostLabel()
    local bankType = activeBankType()
    local data = bankType ~= nil and C_Bank ~= nil and C_Bank.FetchNextPurchasableBankTabData ~= nil
            and C_Bank.FetchNextPurchasableBankTabData(bankType)
        or nil
    local cost = data ~= nil and module.coinText(data.tabCost) or nil
    if cost == nil then
        return COSTS_LABEL or L["Money"]
    end
    return (COSTS_LABEL or "") .. " " .. cost
end

local function renderControls(builder, panel)
    local searchBox = BankFrame.BankItemSearchBox
    if searchBox ~= nil and searchBox:IsShown() then
        builder:beginStop("bank:search")
        builder:addItem(ControlId.forObject(searchBox), nodes.proxyEditBox({ editBox = searchBox, label = L["Search"] }))
    end

    builder:beginStop("bank:controls")
    builder:pushContext("bank:controls", L["Bank Controls"])
    if panel.AutoSortButton ~= nil then
        builder:addItem(
            ControlId.forObject(panel.AutoSortButton),
            nodes.proxyButton({ target = panel.AutoSortButton, label = L["Sort Bank"] })
        )
    end
    local money = panel.MoneyFrame
    if money ~= nil and money:IsShown() then
        builder:addItem(ControlId.structural("bank:money"), nodes.text({ label = moneyLabel, live = "focus" }))
        if money.WithdrawButton ~= nil then
            builder:addItem(ControlId.forObject(money.WithdrawButton), nodes.proxyButton({ target = money.WithdrawButton }))
        end
        if money.DepositButton ~= nil then
            builder:addItem(ControlId.forObject(money.DepositButton), nodes.proxyButton({ target = money.DepositButton }))
        end
    end
    -- Forever: the next bank bag's price and its purchase button sit on the
    -- frame; retail shows them in the purchase prompt instead.
    local purchaseButton = panel.PurchaseButton
    if purchaseButton ~= nil and purchaseButton:IsShown() then
        builder:addItem(ControlId.structural("bank:nextCost"), nodes.text({ label = nextTabCostLabel, live = "focus" }))
        builder:addItem(
            ControlId.forObject(purchaseButton),
            nodes.proxyButton({ target = purchaseButton, label = BANKSLOTPURCHASE or L["Purchase"] })
        )
    end
    local prompt = panel.PurchasePrompt
    if prompt ~= nil and prompt:IsShown() and prompt.TabCostFrame ~= nil then
        builder:addItem(ControlId.structural("bank:promptCost"), nodes.text({ label = nextTabCostLabel, live = "focus" }))
        if prompt.TabCostFrame.PurchaseButton ~= nil then
            builder:addItem(
                ControlId.forObject(prompt.TabCostFrame.PurchaseButton),
                nodes.proxyButton({ target = prompt.TabCostFrame.PurchaseButton, label = BANKSLOTPURCHASE or L["Purchase"] })
            )
        end
    end
    builder:popContext()
end

function Bank:renderGraph(builder)
    local panel = bankPanel()
    if panel == nil then
        return
    end
    renderTabs(builder)
    renderSlots(builder, panel)
    renderBagSlots(builder)
    renderControls(builder, panel)
end
