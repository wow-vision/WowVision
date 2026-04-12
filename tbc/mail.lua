local module = WowVision.base.windows.mail
local L = module.L
local gen = module:hasUI()

-- Safe accessor: MailEditBox may be a ScrollingEditBox wrapper or a plain EditBox
local function getBodyEditBox()
    if MailEditBox.GetEditBox then
        return MailEditBox:GetEditBox()
    end
    return MailEditBox
end

-- Route Tab presses on a Blizzard EditBox to WV's navigator instead of
-- cycling through Blizzard's built-in EditBox tab chain.
local function routeTabToWV(editBox)
    if not editBox or not editBox.SetScript then return end
    editBox:SetScript("OnTabPressed", function()
        local binding
        if IsShiftKeyDown() then
            binding = WowVision.input:getBinding("previous")
        else
            binding = WowVision.input:getBinding("next")
        end
        WowVision.UIHost:onBindingPressed(binding)
    end)
end

-- Blizzard's SendMailFrame OnShow calls SendMailNameEditBox:SetFocus(),
-- which steals keyboard input from WV. Clear focus on ALL mail EditBoxes
-- and pre-route their Tab handling to WV so Blizzard's tab chain
-- (Body → Gold → Silver → Copper → Name) can't consume Tab presses
-- before WV has focused those elements.
SendMailFrame:HookScript("OnShow", function()
    local editBoxes = {
        SendMailNameEditBox, SendMailSubjectEditBox,
        SendMailMoneyGold, SendMailMoneySilver, SendMailMoneyCopper,
    }
    local body = getBodyEditBox()
    if body then tinsert(editBoxes, body) end
    for _, eb in ipairs(editBoxes) do
        if eb.ClearFocus then eb:ClearFocus() end
        routeTabToWV(eb)
    end
end)

-- Override core root element to also show the SendMail tab
gen:Element("mail", {
    regenerateOn = {
        values = function(props)
            return { tab = MailFrame.selectedTab }
        end,
    },
}, function(props)
    local result = {
        "Panel",
        label = L["Mail"],
        wrap = true,
        children = {
            { "mail/tabs", key = "tabs", frame = MailFrame },
        },
    }
    if InboxFrame:IsShown() then
        tinsert(result.children, { "mail/inbox", key = "inbox", frame = InboxFrame })
    end
    if SendMailFrame:IsShown() then
        tinsert(result.children, { "mail/send", key = "send" })
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

gen:Element("mail/send", {
    regenerateOn = {
        events = { "MAIL_SEND_INFO_UPDATE" },
        values = function(props)
            return { codEnabled = SendMailCODButton:IsEnabled() }
        end,
    },
}, function(props)
    local bodyFrame = getBodyEditBox()
    local children = {
        { "ProxyEditBox", key = "sendTo", frame = SendMailNameEditBox, label = L["Send To"] },
        { "ProxyEditBox", key = "subject", frame = SendMailSubjectEditBox, label = L["Subject"] },
    }
    if bodyFrame then
        tinsert(children, { "ProxyEditBox", key = "body", frame = bodyFrame, label = L["Body"], hookEnter = true })
    end
    -- Filled attachments in a navigable list (only if any exist)
    local attachments = { "List", key = "attachments", label = L["Attachments"], children = {} }
    for i = 1, ATTACHMENTS_MAX_SEND do
        if HasSendMailItem(i) then
            local slot = SendMailFrame.SendMailAttachments[i]
            if slot then
                tinsert(attachments.children, {
                    "ProxyButton",
                    key = "attachment_" .. i,
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
            key = "drop",
            frame = emptySlot,
            label = L["Drop Item"],
            draggable = true,
        })
    end
    -- Money fields (flat, no wrapper panel)
    tinsert(children, { "ProxyCheckButton", key = "sendMoney", frame = SendMailSendMoneyButton, label = L["Send Money"] })
    if SendMailCODButton:IsEnabled() then
        tinsert(children, { "ProxyCheckButton", key = "cod", frame = SendMailCODButton, label = L["COD"] })
    end
    tinsert(children, { "ProxyEditBox", key = "gold", frame = SendMailMoneyGold, label = L["Gold"] })
    tinsert(children, { "ProxyEditBox", key = "silver", frame = SendMailMoneySilver, label = L["Silver"] })
    tinsert(children, { "ProxyEditBox", key = "copper", frame = SendMailMoneyCopper, label = L["Copper"] })
    -- Postage and action buttons
    tinsert(children, { "money/MoneyFrame", key = "postage", frame = SendMailCostMoneyFrame, label = L["Postage"] })
    tinsert(children, { "ProxyButton", key = "send", frame = SendMailMailButton })
    tinsert(children, { "ProxyButton", key = "cancel", frame = SendMailCancelButton })
    return { "Panel", label = L["Send Mail"], children = children }
end)

-- Override core's PlayerInteractionWindow with TBC-standard FrameWindow.
-- PlayerInteractionWindow opens on event before frames are fully initialized;
-- FrameWindow polls visibility, matching all other TBC modules.
local oldWindow = module.registeredWindows["mail"]
if oldWindow then
    oldWindow._hasConflictingAddon = true
end

module:registerWindow({
    type = "FrameWindow",
    name = "mail",
    generated = true,
    rootElement = "mail",
    frameName = "MailFrame",
    conflictingAddons = { "Sku" },
})
