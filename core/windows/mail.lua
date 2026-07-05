local module = WowVision.base.windows:createModule("mail")
local L = module.L
module:setLabel(L["Mail"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The mailbox: tabs, the inbox page, and the open letter. Version modules
-- may define module.renderSend(builder, screen) for the send tab and
-- re-register the window (classic clients poll MailFrame instead of the
-- interaction event). Inbox labels read live; the per-tick rebuild picks up
-- MAIL_INBOX_UPDATE arrivals without event plumbing.

-- A real Blizzard edit box as a node: Enter hands it keyboard focus and its
-- own handlers take over; the current text reads as the value.
function module.editBoxNode(editBox, label)
    return {
        controlType = graph.controlTypes.editBox,
        announcements = {
            { text = label, kind = kinds.label },
            {
                text = function()
                    return editBox:GetText()
                end,
                kind = kinds.value,
            },
        },
        onActivate = function()
            editBox:SetFocus()
        end,
        tooltipFrame = editBox,
    }
end

-- A real check button with its checked state as the live value.
function module.checkButtonNode(button, label)
    local vtable = nodes.proxyButton({ target = button, label = label })
    vtable.controlType = graph.controlTypes.toggle
    tinsert(vtable.announcements, {
        text = function()
            return button:GetChecked() and L["Checked"] or L["Unchecked"]
        end,
        kind = kinds.value,
    })
    return vtable
end

function module.moneyText(frame)
    local money = frame ~= nil and (frame.staticMoney or frame.money) or nil
    if money == nil then
        return nil
    end
    return C_CurrencyInfo.GetCoinText(money)
end

local function getInboxItemLabel(item)
    local elementName = item:GetName()
    local sender = _G[elementName .. "Sender"]:GetText() or ""
    local subject = _G[elementName .. "Subject"]:GetText() or ""
    return L["From"] .. ": " .. sender .. ", " .. L["Subject"] .. ": " .. subject
end

local function renderTabs(builder)
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for i = 1, 2 do
        local tab = _G["MailFrameTab" .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            tinsert(vtable.announcements, {
                text = function()
                    if MailFrame.selectedTab == tabIndex then
                        return L["selected"]
                    end
                    return nil
                end,
                kind = kinds.selected,
            })
            builder:addItem(ControlId.forObject(tab), vtable)
        end
    end
    builder:endRow()
    builder:popContext()
end

local function renderInbox(builder)
    if OpenAllMail ~= nil and OpenAllMail:IsShown() then
        builder:beginStop("openAll")
        builder:addItem(ControlId.forObject(OpenAllMail), nodes.proxyButton({ target = OpenAllMail }))
    end

    builder:beginStop("inboxItems")
    builder:pushContext("inbox", L["Inbox"])
    local emitted = 0
    for i = 1, INBOXITEMS_TO_DISPLAY do
        local item = _G["MailItem" .. i]
        if item ~= nil and item.Button:IsShown() then
            local captured = item
            builder:addItem(
                ControlId.forObject(item.Button),
                nodes.proxyButton({
                    target = item.Button,
                    label = function()
                        return getInboxItemLabel(captured)
                    end,
                })
            )
            emitted = emitted + 1
        end
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("inboxEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    if InboxPrevPageButton ~= nil and InboxPrevPageButton:IsShown() then
        builder:beginStop("prevPage")
        builder:addItem(
            ControlId.forObject(InboxPrevPageButton),
            nodes.proxyButton({ target = InboxPrevPageButton, label = L["Previous Page"] })
        )
    end
    if InboxNextPageButton ~= nil and InboxNextPageButton:IsShown() then
        builder:beginStop("nextPage")
        builder:addItem(
            ControlId.forObject(InboxNextPageButton),
            nodes.proxyButton({ target = InboxNextPageButton, label = L["Next Page"] })
        )
    end
end

local function invoiceText(builder, id, label)
    builder:addItem(id, nodes.text({ label = label }))
end

local function renderOpenMail(builder)
    builder:beginStop("letter")
    builder:pushContext("letter", L["Mail"])

    invoiceText(builder, ControlId.structural("sender"), function()
        return OpenMailSender.Name:GetText()
    end)
    invoiceText(builder, ControlId.structural("subject"), function()
        return L["Subject"] .. ": " .. (OpenMailSubject:GetText() or "")
    end)
    if OpenMailBodyText ~= nil and OpenMailBodyText:IsShown() then
        invoiceText(builder, ControlId.structural("body"), function()
            return GetInboxText(InboxFrame.openMailID)
        end)
    end

    if OpenMailInvoiceFrame ~= nil and OpenMailInvoiceFrame:IsShown() then
        invoiceText(builder, ControlId.structural("invoiceItem"), function()
            return OpenMailInvoiceItemLabel:GetText()
        end)
        invoiceText(builder, ControlId.structural("invoiceBuyer"), function()
            return (OpenMailInvoicePurchaser:GetText() or "")
                .. " "
                .. (OpenMailInvoiceBuyMode:GetText() or "")
        end)
        invoiceText(builder, ControlId.structural("invoiceSale"), function()
            return (OpenMailInvoiceSalePrice:GetText() or "") .. " " .. (module.moneyText(OpenMailSalePriceMoneyFrame) or "")
        end)
        invoiceText(builder, ControlId.structural("invoiceDeposit"), function()
            return (OpenMailInvoiceDeposit:GetText() or "") .. " " .. (module.moneyText(OpenMailDepositMoneyFrame) or "")
        end)
        invoiceText(builder, ControlId.structural("invoiceCut"), function()
            return (OpenMailInvoiceHouseCut:GetText() or "") .. " " .. (module.moneyText(OpenMailHouseCutMoneyFrame) or "")
        end)
        invoiceText(builder, ControlId.structural("invoiceTotal"), function()
            return (OpenMailInvoiceAmountReceived:GetText() or "")
                .. " "
                .. (module.moneyText(OpenMailTransactionAmountMoneyFrame) or "")
        end)
    end

    for i, button in ipairs(OpenMailFrame.activeAttachmentButtons or {}) do
        local captured = button
        local label
        if captured == OpenMailLetterButton then
            label = L["Letter"]
        elseif captured == OpenMailMoneyButton then
            label = function()
                if OpenMailFrame.money ~= nil and OpenMailFrame.money > 0 then
                    return C_CurrencyInfo.GetCoinText(OpenMailFrame.money)
                end
                return L["Empty"]
            end
        else
            -- Data-first: the buttons are plain ItemButtonTemplates whose
            -- Count fontstring is a global, not a keyed child, so read the
            -- attachment straight from the inbox API by slot id.
            label = function()
                local name, _, _, count = GetInboxItem(InboxFrame.openMailID, captured:GetID())
                if name == nil then
                    return L["Empty"]
                end
                if count ~= nil and count > 1 then
                    return name .. " x " .. count
                end
                return name
            end
        end
        builder:addItem(ControlId.forObject(captured), nodes.proxyButton({ target = captured, label = label }))
    end
    builder:popContext()

    for _, button in ipairs({
        OpenMailReplyButton,
        OpenMailDeleteButton,
        OpenMailCloseButton,
        OpenMailReportSpamButton,
    }) do
        if button ~= nil and button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end
end

function module.renderMail(builder, screen)
    if MailFrame == nil or not MailFrame:IsShown() then
        return
    end
    builder:pushContext("mail", L["Mail"])

    renderTabs(builder)

    if InboxFrame ~= nil and InboxFrame:IsShown() then
        renderInbox(builder)
        if OpenMailFrame ~= nil and OpenMailFrame:IsShown() then
            renderOpenMail(builder)
        end
    end

    if module.renderSend ~= nil and SendMailFrame ~= nil and SendMailFrame:IsShown() then
        module.renderSend(builder, screen)
    end

    builder:popContext()
end

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "mail",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.MailInfo,
    graphScreen = { render = module.renderMail },
})
