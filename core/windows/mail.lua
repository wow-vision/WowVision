local module = WowVision.base.windows:createModule("mail")
local L = module.L
module:setLabel(L["Mail"])
local gen = module:hasUI()

gen:Element("mail", function(props)
    local result = {
        "Panel",
        label = L["Mail"],
        wrap = true,
        children = {
            { "mail/tabs", frame = MailFrame },
        },
    }
    if InboxFrame:IsShown() then
        tinsert(result.children, { "mail/inbox", frame = InboxFrame })
    end
    return result
end)

gen:Element("mail/tabs", function(props)
    return {
        "List",
        label = L["Tabs"],
        direction = "horizontal",
        children = {
            { "mail/tab", frame = MailFrameTab1, selected = MailFrame.selectedTab == 1 },
            { "mail/tab", frame = MailFrameTab2, selected = MailFrame.selectedTab == 2 },
        },
    }
end)

gen:Element("mail/tab", function(props)
    return { "ProxyButton", frame = props.frame, selected = props.selected }
end)

gen:Element("mail/inbox", function(props)
    local result = { "Panel", shouldAnnounce = false, children = {
        { "mail/inbox/MailList" },
    } }
    if OpenMailFrame:IsShown() then
        tinsert(result.children, { "mail/inbox/open", frame = OpenMailFrame })
    end
    return result
end)

local function getInboxItemLabel(item)
    local elementName = item:GetName()
    local sender = _G[elementName .. "Sender"]:GetText()
    local subject = _G[elementName .. "Subject"]:GetText()
    local label = L["From"] .. ": " .. sender .. ", " .. L["Subject"] .. ": " .. subject
    return label
end

gen:Element("mail/inbox/MailList", function(props)
    local result = { "Panel", label = L["Inbox"], children = {
        { "ProxyButton", frame = OpenAllMail },
    } }
    local items = { "List", children = {} }
    for i = 1, INBOXITEMS_TO_DISPLAY do
        local item = _G["MailItem" .. i]
        if item.Button:IsShown() then
            tinsert(items.children, {
                "ProxyButton",
                frame = item.Button,
                label = getInboxItemLabel(item),
            })
        end
    end
    tinsert(result.children, items)
    tinsert(result.children, { "ProxyButton", frame = InboxPrevPageButton, label = L["Previous Page"] })
    tinsert(result.children, { "ProxyButton", frame = InboxNextPageButton, label = L["Next Page"] })
    return result
end)

gen:Element("mail/inbox/open", function(props)
    local result = {
        "Panel",
        label = L["Mail"],
        children = {
            { "mail/inbox/open/list" },
            { "ProxyButton", frame = OpenMailReplyButton },
            { "ProxyButton", frame = OpenMailDeleteButton },
            { "ProxyButton", frame = OpenMailCloseButton },
            { "ProxyButton", frame = OpenMailReportSpamButton },
        },
    }
    return result
end)

gen:Element("mail/inbox/open/list", function(props)
    local result = {
        "List",
        children = {
            { "Text", text = OpenMailSender.Name:GetText() },
            { "Text", text = L["Subject"] .. ": " .. OpenMailSubject:GetText() },
        },
    }
    if OpenMailBodyText:IsShown() then
        local text = GetInboxText(InboxFrame.openMailID)
        if text and text ~= "" then
            tinsert(result.children, { "Text", text = text })
        end
    end
    local frame = OpenMailInvoiceFrame
    if frame:IsShown() then
        tinsert(result.children, { "Text", text = OpenMailInvoiceItemLabel:GetText() })
        tinsert(result.children, {
            "Text",
            text = OpenMailInvoicePurchaser:GetText() .. " " .. (OpenMailInvoiceBuyMode:GetText() or "Unknown"),
        })
        tinsert(
            result.children,
            { "money/static", frame = OpenMailSalePriceMoneyFrame, label = OpenMailInvoiceSalePrice:GetText() }
        )
        tinsert(
            result.children,
            { "money/static", frame = OpenMailDepositMoneyFrame, label = OpenMailInvoiceDeposit:GetText() }
        )
        tinsert(
            result.children,
            { "money/static", frame = OpenMailHouseCutMoneyFrame, label = OpenMailInvoiceHouseCut:GetText() }
        )
        tinsert(result.children, {
            "money/static",
            frame = OpenMailTransactionAmountMoneyFrame,
            label = OpenMailInvoiceAmountReceived:GetText(),
        })
    end
    for _, button in ipairs(OpenMailFrame.activeAttachmentButtons) do
        if button == OpenMailLetterButton then
            tinsert(result.children, { "ProxyButton", frame = button, label = L["Letter"] })
        elseif button == OpenMailMoneyButton then
            local label = L["Empty"]
            if OpenMailFrame.money and OpenMailFrame.money > 0 then
                label = C_CurrencyInfo.GetCoinText(OpenMailFrame.money)
            end
            tinsert(result.children, { "ProxyButton", frame = button, label = label })
        else
            tinsert(result.children, { "ItemButton", frame = button, itemType = "Mail" })
        end
    end
    return result
end)

module:registerWindow({
    type = "PlayerInteractionWindow",
    name = "mail",
    generated = true,
    rootElement = "mail",
    conflictingAddons = { "Sku" },
    interactionType = Enum.PlayerInteractionType.MailInfo,
})
