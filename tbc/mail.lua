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

local mailEditBoxesGuarded = false
SendMailFrame:HookScript("OnShow", function()
    if not mailEditBoxesGuarded then
        mailEditBoxesGuarded = true
        -- Disable autoFocus and route Tab to WV on all mail EditBoxes
        local editBoxes = {
            SendMailMoneyGold, SendMailMoneySilver, SendMailMoneyCopper,
            SendMailNameEditBox, SendMailSubjectEditBox, getBodyEditBox(),
        }
        for _, editBox in ipairs(editBoxes) do
            if editBox then
                editBox:SetAutoFocus(false)
                routeTabToWV(editBox)
            end
        end
        -- Break Blizzard's Lua-level focus chain links on the money frame
        SendMailMoney.previousFocus = nil
        SendMailMoney.nextFocus = nil
        -- Unregister the ScrollingEditBox wrapper's OnTabPressed callback.
        -- MailEditBox is a ScrollingEditBoxTemplate (Frame, not EditBox).
        -- Blizzard registers: MailEditBox:RegisterCallback("OnTabPressed", SendMailEditBox_OnTabPressed, MailEditBox)
        -- This fires EditBox_HandleTabbing(self, SEND_MAIL_TAB_LIST) INDEPENDENTLY of the
        -- inner EditBox's OnTabPressed (which WV overrides via routeTabToWV).  Both fire on
        -- every Tab press, causing Blizzard's tab list to simultaneously set focus on
        -- Gold (forward) or Subject (backward) while WV navigates elsewhere.
        if MailEditBox.UnregisterCallback then
            MailEditBox:UnregisterCallback("OnTabPressed", MailEditBox)
        end
        -- Remove body/money entries from the tab list as a safety net.
        -- WV overrides OnTabPressed on all mail EditBoxes, so this list should
        -- never be consulted, but nil the dangerous entries just in case.
        SEND_MAIL_TAB_LIST[3] = nil  -- MailEditBox
        SEND_MAIL_TAB_LIST[4] = nil  -- SendMailMoneyGold
        SEND_MAIL_TAB_LIST[5] = nil  -- SendMailMoneyCopper
    end
    -- Runs every show: Blizzard's OnShow calls SetFocus(), steal it back
    SendMailNameEditBox:ClearFocus()
end)

local function getInboxItemLabel(item)
    local name = item:GetName()
    local sender = _G[name .. "Sender"]:GetText()
    local subject = _G[name .. "Subject"]:GetText()
    return L["From"] .. ": " .. sender .. ", " .. L["Subject"] .. ": " .. subject
end

-- Override inbox list to regenerate when mail data arrives.
-- On first open the MailItem buttons aren't shown yet because WoW fires
-- MAIL_INBOX_UPDATE after the frame becomes visible.
gen:Element("mail/inbox/MailList", {
    regenerateOn = {
        events = { "MAIL_INBOX_UPDATE" },
    },
}, function(props)
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
            -- Slot may not exist yet if Blizzard creates them lazily
            if slot then
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
                    label = getAttachmentLabel(i) or "",
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
    -- Money options and input fields
    tinsert(children, { "ProxyCheckButton", key = "sendMoney", frame = SendMailSendMoneyButton, label = L["Send Money"] })
    if SendMailCODButton:IsEnabled() then
        tinsert(children, { "ProxyCheckButton", key = "cod", frame = SendMailCODButton, label = L["COD"] })
    end
    tinsert(children, { "Panel", key = "money", label = L["Money"], layout = true, children = {
        { "ProxyEditBox", key = "gold", frame = SendMailMoneyGold, label = L["Gold"] },
        { "ProxyEditBox", key = "silver", frame = SendMailMoneySilver, label = L["Silver"] },
        { "ProxyEditBox", key = "copper", frame = SendMailMoneyCopper, label = L["Copper"] },
    } })
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
