local module = WowVision.base.windows.mail
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Shared by Vanilla, TBC, Mists and WoW: Forever (camelot/modules.xml loads it
-- too), which use the same Classic SendMail UI. Bail out on any client whose
-- mail frames differ so we neither error at load nor when the mail window
-- opens; that client keeps core's basic mail handling.
if not SendMailFrame then
    return
end

-- Safe accessor for the body: MailEditBox may be a ScrollingEditBox wrapper
-- or a plain EditBox; WoW: Forever has no MailEditBox and keeps the Classic
-- Era SendMailBodyEditBox instead.
local function getBodyEditBox()
    if MailEditBox ~= nil then
        if MailEditBox.GetEditBox then
            return MailEditBox:GetEditBox()
        end
        return MailEditBox
    end
    return SendMailBodyEditBox
end

-- An attachment slot: the SendMailAttachments array where the client keeps
-- one, else the numbered globals.
local function getAttachmentSlot(i)
    local slots = SendMailFrame.SendMailAttachments
    if slots ~= nil then
        return slots[i]
    end
    return _G["SendMailAttachment" .. i]
end

-- Route Tab presses on a Blizzard EditBox to the graph host instead of
-- cycling through Blizzard's built-in EditBox tab chain.
local function routeTabToWV(editBox)
    if not editBox or not editBox.SetScript then
        return
    end
    editBox:SetScript("OnTabPressed", function()
        editBox:ClearFocus()
        if IsShiftKeyDown() then
            WowVision.graphHost:onKey("previous")
        else
            WowVision.graphHost:onKey("next")
        end
    end)
end

-- Enter in the recipient and subject boxes: Blizzard moves focus to the next
-- box, but WV hands a box the keyboard ON Enter, and that same press then
-- reaches the box and jumps on, so typing landed in the next box. The press
-- that arrives right with the focus is swallowed; a later Enter accepts an
-- open autocomplete pick (recipient) or leaves typing and stays on the box.
-- Tab moves on.
local FOCUS_ENTER_WINDOW = 0.1
local function keepEnterInBox(editBox)
    if not editBox or not editBox.SetScript then
        return
    end
    local focusedAt = 0
    editBox:HookScript("OnEditFocusGained", function()
        focusedAt = GetTime()
    end)
    editBox:SetScript("OnEnterPressed", function(self)
        if GetTime() - focusedAt < FOCUS_ENTER_WINDOW then
            return
        end
        if self.autoCompleteContext ~= nil and AutoCompleteEditBox_OnEnterPressed ~= nil then
            if AutoCompleteEditBox_OnEnterPressed(self) then
                return
            end
        end
        self:ClearFocus()
    end)
end

local mailEditBoxesGuarded = false
SendMailFrame:HookScript("OnShow", function()
    if not mailEditBoxesGuarded then
        mailEditBoxesGuarded = true
        -- Disable autoFocus and route Tab to WV on all mail EditBoxes
        local editBoxes = {
            SendMailMoneyGold,
            SendMailMoneySilver,
            SendMailMoneyCopper,
            SendMailNameEditBox,
            SendMailSubjectEditBox,
            getBodyEditBox(),
        }
        for _, editBox in ipairs(editBoxes) do
            if editBox then
                editBox:SetAutoFocus(false)
                routeTabToWV(editBox)
            end
        end
        keepEnterInBox(SendMailNameEditBox)
        keepEnterInBox(SendMailSubjectEditBox)
        -- Break Blizzard's Lua-level focus chain links on the money frame
        if SendMailMoney ~= nil then
            SendMailMoney.previousFocus = nil
            SendMailMoney.nextFocus = nil
        end
        -- Unregister the ScrollingEditBox wrapper's OnTabPressed callback.
        -- MailEditBox is a ScrollingEditBoxTemplate (Frame, not EditBox).
        -- Blizzard registers: MailEditBox:RegisterCallback("OnTabPressed", SendMailEditBox_OnTabPressed, MailEditBox)
        -- This fires EditBox_HandleTabbing(self, SEND_MAIL_TAB_LIST) INDEPENDENTLY of the
        -- inner EditBox's OnTabPressed (which WV overrides via routeTabToWV).  Both fire on
        -- every Tab press, causing Blizzard's tab list to simultaneously set focus on
        -- Gold (forward) or Subject (backward) while WV navigates elsewhere.
        if MailEditBox ~= nil and MailEditBox.UnregisterCallback then
            MailEditBox:UnregisterCallback("OnTabPressed", MailEditBox)
        end
        -- Remove body/money entries from the tab list as a safety net.
        -- WV overrides OnTabPressed on all mail EditBoxes, so this list should
        -- never be consulted, but nil the dangerous entries just in case.
        if SEND_MAIL_TAB_LIST ~= nil then
            SEND_MAIL_TAB_LIST[3] = nil -- MailEditBox
            SEND_MAIL_TAB_LIST[4] = nil -- SendMailMoneyGold
            SEND_MAIL_TAB_LIST[5] = nil -- SendMailMoneyCopper
        end
    end
    -- Runs every show: Blizzard's OnShow calls SetFocus(), steal it back
    SendMailNameEditBox:ClearFocus()
end)

local function getAttachmentLabel(i)
    local itemName, _, _, stackCount, quality = GetSendMailItem(i)
    if itemName then
        local label = WowVision.items.formatName(itemName, quality)
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
            local slot = getAttachmentSlot(i)
            -- Slot may not exist yet if Blizzard creates them lazily
            if slot then
                return slot
            end
        end
    end
    return nil
end

local function attachmentNode(slot, label)
    local vtable = nodes.proxyButton({ target = slot, label = label })
    if vtable == nil then
        return nil
    end
    tinsert(vtable.bindings, {
        binding = "drag",
        type = "Function",
        func = function()
            local script = slot:GetScript("OnDragStart")
            if script ~= nil then
                script(slot)
            end
        end,
    })
    return vtable
end

-- The send tab, slotted into core's mail render.
function module.renderSend(builder, screen)
    builder:beginStop("sendTo")
    builder:addItem(ControlId.structural("sendTo"), module.editBoxNode(SendMailNameEditBox, L["Send To"]))
    builder:beginStop("subject")
    builder:addItem(ControlId.structural("subject"), module.editBoxNode(SendMailSubjectEditBox, L["Subject"]))
    local bodyFrame = getBodyEditBox()
    if bodyFrame then
        builder:beginStop("body")
        builder:addItem(ControlId.structural("body"), module.editBoxNode(bodyFrame, L["Body"]))
    end

    builder:beginStop("attachments")
    builder:pushContext("attachments", L["Attachments"])
    local emitted = 0
    for i = 1, ATTACHMENTS_MAX_SEND do
        if HasSendMailItem(i) then
            local slot = getAttachmentSlot(i)
            if slot then
                local index = i
                builder:addItem(
                    ControlId.structural("attachment:" .. i),
                    attachmentNode(slot, function()
                        return getAttachmentLabel(index) or ""
                    end)
                )
                emitted = emitted + 1
            end
        end
    end
    local emptySlot = getFirstEmptySlot()
    if emptySlot then
        builder:addItem(ControlId.structural("drop"), attachmentNode(emptySlot, L["Drop Item"]))
        emitted = emitted + 1
    end
    if emitted == 0 then
        builder:addItem(ControlId.structural("attachmentsEmpty"), nodes.text({ label = L["Empty"] }))
    end
    builder:popContext()

    -- Send Money and COD are a RADIO pair: clicking one unchecks the other,
    -- and clicking the already-selected one is a no-op. COD is disabled
    -- until an item is attached; it stays visible with its state spoken.
    builder:beginStop("sendMoney")
    builder:addItem(
        ControlId.forObject(SendMailSendMoneyButton),
        module.checkButtonNode(SendMailSendMoneyButton, L["Send Money"])
    )
    builder:beginStop("cod")
    -- The proxy factories announce disabled state themselves.
    builder:addItem(ControlId.forObject(SendMailCODButton), module.checkButtonNode(SendMailCODButton, L["COD"]))

    -- Each coin box is its own stop: tabbing into a box starts typing, and
    -- Tab out goes to the NEXT STOP, so boxes sharing a stop would be
    -- unreachable. The section label follows the mode: Amount to Send or
    -- COD Amount.
    builder:pushContext(
        "money",
        SendMailMoneyText ~= nil and SendMailMoneyText:GetText() or L["Money"]
    )
    builder:beginStop("gold")
    builder:addItem(ControlId.structural("gold"), module.editBoxNode(SendMailMoneyGold, L["Gold"]))
    builder:beginStop("silver")
    builder:addItem(ControlId.structural("silver"), module.editBoxNode(SendMailMoneySilver, L["Silver"]))
    builder:beginStop("copper")
    builder:addItem(ControlId.structural("copper"), module.editBoxNode(SendMailMoneyCopper, L["Copper"]))
    builder:popContext()

    builder:beginStop("postage")
    builder:addItem(
        ControlId.structural("postage"),
        nodes.text({
            label = function()
                return L["Postage"] .. " " .. (module.moneyText(SendMailCostMoneyFrame) or "")
            end,
        })
    )

    builder:beginStop("send")
    builder:addItem(ControlId.forObject(SendMailMailButton), nodes.proxyButton({ target = SendMailMailButton }))
    builder:beginStop("cancel")
    builder:addItem(ControlId.forObject(SendMailCancelButton), nodes.proxyButton({ target = SendMailCancelButton }))
end

-- Override core's PlayerInteractionWindow with a TBC-standard FrameWindow.
-- PlayerInteractionWindow opens on event before frames are fully initialized;
-- FrameWindow polls visibility, matching all other TBC modules.
module:unregisterWindow("mail")

module:registerWindow({
    type = "FrameWindow",
    name = "mail",
    frameName = "MailFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = module.renderMail },
})
