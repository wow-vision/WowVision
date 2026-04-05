local module = WowVision.base.windows.mail
local L = module.L
local gen = module:hasUI()

-- Blizzard's SendMailFrame OnShow calls SendMailNameEditBox:SetFocus(),
-- which steals keyboard input from WV. Hook it to clear that forced focus.
SendMailFrame:HookScript("OnShow", function()
    SendMailNameEditBox:ClearFocus()
end)

-- Override core root element to also show the SendMail tab
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
    if SendMailFrame:IsShown() then
        tinsert(result.children, { "mail/send" })
    end
    return result
end)

local function getAttachmentLabel(i)
    local itemName, _, _, stackCount = GetSendMailItem(i)
    if itemName then
        local label = itemName
        if stackCount and stackCount > 1 then
            label = label .. " x " .. stackCount
        end
        return label
    end
    return nil
end

local function getFirstEmptySlot()
    for i = 1, ATTACHMENTS_MAX_SEND do
        if not HasSendMailItem(i) then
            local slot = SendMailFrame.SendMailAttachments[i]
            if slot and slot:IsShown() then
                return slot
            end
        end
    end
    return nil
end

gen:Element("mail/send", function(props)
    local children = {
        { "ProxyEditBox", frame = SendMailNameEditBox, label = L["Send To"] },
        { "ProxyEditBox", frame = SendMailSubjectEditBox, label = L["Subject"] },
        { "ProxyEditBox", frame = MailEditBox:GetEditBox(), label = L["Body"], hookEnter = true },
    }
    -- Filled attachments in a navigable list (only if any exist)
    local attachments = { "List", label = L["Attachments"], children = {} }
    for i = 1, ATTACHMENTS_MAX_SEND do
        if HasSendMailItem(i) then
            local slot = SendMailFrame.SendMailAttachments[i]
            if slot then
                tinsert(attachments.children, {
                    "ProxyButton",
                    frame = slot,
                    label = getAttachmentLabel(i),
                    draggable = true,
                })
            end
        end
    end
    if #attachments.children > 0 then
        tinsert(children, attachments)
    end
    -- First empty slot as drop area
    local emptySlot = getFirstEmptySlot()
    if emptySlot then
        tinsert(children, {
            "ProxyButton",
            frame = emptySlot,
            label = L["Drop Item"],
            draggable = true,
        })
    end
    -- Money fields (flat, no wrapper panel)
    tinsert(children, { "ProxyCheckButton", frame = SendMailSendMoneyButton, label = L["Send Money"] })
    if SendMailCODButton:IsEnabled() then
        tinsert(children, { "ProxyCheckButton", frame = SendMailCODButton, label = L["COD"] })
    end
    tinsert(children, { "ProxyEditBox", frame = SendMailMoneyGold, label = L["Gold"] })
    tinsert(children, { "ProxyEditBox", frame = SendMailMoneySilver, label = L["Silver"] })
    tinsert(children, { "ProxyEditBox", frame = SendMailMoneyCopper, label = L["Copper"] })
    -- Postage and action buttons
    tinsert(children, { "money/MoneyFrame", frame = SendMailCostMoneyFrame, label = L["Postage"] })
    tinsert(children, { "ProxyButton", frame = SendMailMailButton })
    tinsert(children, { "ProxyButton", frame = SendMailCancelButton })
    return { "Panel", label = L["Send Mail"], children = children }
end)
