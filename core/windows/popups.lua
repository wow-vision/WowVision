local module = WowVision.base.windows:createModule("popups")
local L = module.L
module:setLabel(L["Popups"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- StaticPopup dialogs. Modern clients pool them (StaticPopup_ForEachShownDialog
-- is the authority on what is shown); older clients keep the numbered frames.
-- One window renders every shown dialog: each dialog is a context holding its
-- text (live: countdown popups rewrite it in place), its edit box when
-- present (the real one -- Enter hands it keyboard focus and the popup's own
-- handlers take Enter and Escape from there), and its buttons as stops.

local function forEachShownDialog(func)
    if StaticPopup_ForEachShownDialog ~= nil then
        StaticPopup_ForEachShownDialog(func)
        return
    end
    for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
        local frame = _G["StaticPopup" .. i]
        if frame ~= nil and frame:IsShown() then
            func(frame)
        end
    end
end

local function getPopupText(frame)
    if frame.GetTextFontString ~= nil then
        return frame:GetTextFontString()
    end
    return frame.text
end

local function getPopupEditBox(frame)
    if frame.GetEditBox ~= nil then
        return frame:GetEditBox()
    end
    return frame.editBox
end

local function getPopupButtons(frame)
    if frame.GetButtons ~= nil then
        return frame:GetButtons()
    end
    local buttons = {}
    for i = 1, frame.numButtons or 0 do
        local button = _G[frame:GetName() .. "Button" .. i]
        if button ~= nil then
            tinsert(buttons, button)
        end
    end
    return buttons
end

-- Retail's dialog template enables keyboard input on the dialog and on its
-- full-screen cover (shown for dialogs like the unapplied-settings
-- prompt). A keyboard-enabled frame swallows every key it does not
-- handle, so Tab and the arrows never reached our bindings. Release it:
-- Escape still reaches the dialog through UIParent's escape cascade, and
-- Enter goes through the focused node (the text node clicks the first
-- button when the dialog asks for that).
local function releaseKeyboard(frame)
    if frame ~= nil and frame.IsKeyboardEnabled ~= nil and frame:IsKeyboardEnabled() then
        frame:EnableKeyboard(false)
    end
end

local function firstShownButton(frame)
    for _, button in ipairs(getPopupButtons(frame)) do
        if button:IsShown() then
            return button
        end
    end
    return nil
end

local function renderDialog(builder, frame, index)
    local contextKey = "popup:" .. tostring(frame.which or index)
    builder:pushContext(contextKey, L["Popup"])
    releaseKeyboard(frame)
    releaseKeyboard(frame.CoverFrame)
    releaseKeyboard(frame.Cover)

    local text = getPopupText(frame)
    if text ~= nil and text:IsShown() then
        builder:beginStop()
        local vtable = nodes.text({
            label = function()
                return text:GetText()
            end,
        })
        local info = StaticPopupDialogs ~= nil and frame.which ~= nil and StaticPopupDialogs[frame.which] or nil
        if info ~= nil and info.enterClicksFirstButton and firstShownButton(frame) ~= nil then
            vtable.controlType = graph.controlTypes.button
            vtable.bindings = {
                {
                    binding = "leftClick",
                    type = "Click",
                    emulatedKey = "LeftButton",
                    target = function()
                        return firstShownButton(frame)
                    end,
                },
            }
        end
        builder:addItem(ControlId.structural(contextKey .. ":text"), vtable)
    end

    local editBox = getPopupEditBox(frame)
    if editBox ~= nil and editBox:IsShown() then
        builder:beginStop()
        builder:addItem(
            ControlId.forObject(editBox),
            nodes.button({
                label = function()
                    if editBox.Instructions ~= nil then
                        return editBox.Instructions:GetText()
                    end
                    return nil
                end,
                value = function()
                    return editBox:GetText()
                end,
                onActivate = function()
                    editBox:SetFocus()
                end,
            })
        )
    end

    for _, button in ipairs(getPopupButtons(frame)) do
        if button:IsShown() then
            builder:beginStop()
            builder:addItem(ControlId.forObject(button), nodes.proxyButton({ target = button }))
        end
    end

    builder:popContext()
end

local function render(builder, screen)
    local index = 0
    forEachShownDialog(function(frame)
        index = index + 1
        renderDialog(builder, frame, index)
    end)
end

-- Accepting a group invitation without the popups window. In combat the
-- window cannot take over the keyboard, so the invitation could not be
-- answered until the fight ended. The popup's own buttons are not
-- protected: clicking Accept runs the dialog's OnAccept (AcceptGroup, and
-- the flag that keeps its OnHide from declining), in or out of combat.
local INVITE_POPUPS = { PARTY_INVITE = true, PARTY_INVITE_XREALM = true }

function module.acceptInvite()
    local accept = nil
    forEachShownDialog(function(frame)
        if accept == nil and INVITE_POPUPS[frame.which] then
            accept = firstShownButton(frame)
        end
    end)
    if accept == nil then
        WowVision:speak(L["No group invitation"])
        return false
    end
    accept:Click()
    WowVision:speak(L["Group invitation accepted"])
    return true
end

module:registerCommand({
    name = "accept",
    description = "Accept the pending group invitation, also in combat",
    func = function()
        module.acceptInvite()
    end,
})

module:registerBinding({
    type = "Function",
    key = "popups/acceptInvite",
    inputs = {},
    label = L["Accept Group Invitation"],
    interruptSpeech = true,
    func = function()
        module.acceptInvite()
    end,
})

module:registerWindow({
    type = "CustomWindow",
    name = "popups",
    isOpen = function(self)
        local any = false
        forEachShownDialog(function()
            any = true
        end)
        return any
    end,
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
