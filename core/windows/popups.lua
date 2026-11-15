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

-- The game's list of shown dialogs also holds the special popups shown with
-- StaticPopupSpecial_Show (StaticPopup_SetUpPosition inserts every dialog):
-- the role popups, the role invitation, the guild invite and others. They
-- have no `which`, no dialog text and no dialog buttons; the role popups
-- have their own windows (RolePoll.lua). This window takes the static
-- dialogs only.
local function forEachStaticDialog(func)
    forEachShownDialog(function(frame)
        if frame.which ~= nil then
            func(frame)
        end
    end)
end

-- The static dialogs in front: those not put aside to Pending (pending.lua).
local function forEachFrontDialog(func)
    forEachStaticDialog(function(frame)
        if WowVision.pending == nil or not WowVision.pending.isAside(frame) then
            func(frame)
        end
    end)
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

-- The dialogs whose buttons may run their own click from addon code in combat (graph/Host.lua combatKey): their
-- handlers call nothing protected (AcceptGroup, DeclineGroup, the summon and resurrection answers, RepopMe,
-- DeleteCursorItem; GameDialogDefs.lua), and the delete questions were answered so in a fight in game. Any other
-- dialog's buttons say Not available in combat: a handler that calls a protected function (AcceptBattlefieldPort)
-- would be blocked from addon code.
local COMBAT_CLICKS = {
    PARTY_INVITE = true,
    CONFIRM_SUMMON = true,
    CONFIRM_SUMMON_SCENARIO = true,
    CONFIRM_SUMMON_STARTING_AREA = true,
    RESURRECT = true,
    RESURRECT_NO_SICKNESS = true,
    RESURRECT_NO_TIMER = true,
    DEATH = true,
    HARDCORE_DEATH = true,
    DELETE_ITEM = true,
    DELETE_GOOD_ITEM = true,
    DELETE_QUEST_ITEM = true,
    DELETE_GOOD_QUEST_ITEM = true,
    WOWVISION_PENDING_TEST = true,
}

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
                    combatClick = COMBAT_CLICKS[frame.which],
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

    -- The buttons are plain game buttons, not protected: in combat their own click runs from addon code for the
    -- dialogs known to call nothing protected (COMBAT_CLICKS), as the Accept Group Invitation key does.
    local combatClick = COMBAT_CLICKS[frame.which]
    for _, button in ipairs(getPopupButtons(frame)) do
        if button:IsShown() then
            builder:beginStop()
            builder:addItem(
                ControlId.forObject(button),
                nodes.proxyButton({ target = button, combatClick = combatClick })
            )
        end
    end

    builder:popContext()
end

local function render(builder, screen)
    local index = 0
    forEachFrontDialog(function(frame)
        index = index + 1
        renderDialog(builder, frame, index)
    end)
end

-- Accepting a group invitation without the popups window. In combat the
-- window cannot take over the keyboard, so the invitation could not be
-- answered until the fight ended. The popup's own buttons are not
-- protected: clicking Accept runs the dialog's OnAccept (AcceptGroup, and
-- the flag that keeps its OnHide from declining), in or out of combat.
-- An invitation that asks for a role comes in its own window
-- (LFGInvitePopup, see RolePoll.lua), a special popup the static dialog walk
-- skips, so it is checked by name; its Accept takes the checked role and
-- stays disabled until one is checked (the game checks it when only one is
-- open), so then the role has to be picked in that window first.
local INVITE_POPUPS = { PARTY_INVITE = true, PARTY_INVITE_XREALM = true }

function module.acceptInvite()
    local accept = nil
    forEachStaticDialog(function(frame)
        if accept == nil and INVITE_POPUPS[frame.which] then
            accept = firstShownButton(frame)
        end
    end)
    local rolePopup = LFGInvitePopup
    if accept == nil and rolePopup ~= nil and rolePopup:IsShown() then
        accept = LFGInvitePopupAcceptButton
        if accept ~= nil and not accept:IsEnabled() then
            WowVision:notify(L["Choose a role first"])
            return false
        end
    end
    if accept == nil then
        WowVision:notify(L["No group invitation"])
        return false
    end
    accept:Click()
    WowVision:notify(L["Group invitation accepted"])
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

-- Pending windows (pending.lua): Escape is WowVision's only while every dialog in front ignores Escape in the game
-- (one that takes it, Really delete this item?, keeps the game's Escape, which cancels it).
local function holdsEscape()
    local pending = WowVision.pending
    if pending == nil or not pending.holdsEscape() then
        return false
    end
    local any, all = false, true
    forEachFrontDialog(function(frame)
        any = true
        if pending.takesEscape(frame) then
            all = false
        end
    end)
    return any and all
end

-- A put-aside dialog's short name, said with Pending (its text was read when it opened).
local TITLES = {
    PARTY_INVITE = "Group Invitation",
    CONFIRM_SUMMON = "Summon",
    CONFIRM_SUMMON_SCENARIO = "Summon",
    CONFIRM_SUMMON_STARTING_AREA = "Summon",
    RESURRECT = "Resurrection",
    RESURRECT_NO_SICKNESS = "Resurrection",
    RESURRECT_NO_TIMER = "Resurrection",
    DEATH = "Death",
    HARDCORE_DEATH = "Death",
    WOWVISION_PENDING_TEST = "Pending test",
}

local function dialogTitle(frame)
    local key = frame.which ~= nil and TITLES[frame.which] or nil
    return L[key or "Popup"]
end

-- Escape (or the Close All Windows key) on the window: the dialogs in front that ignore Escape go to Pending, their
-- frames left on screen, labelled with their text (read live: a countdown the game shows in it reads as it runs).
-- In a fight WowVision holds Escape: on a dialog that takes Escape in the game its Escape only gives the keys back
-- (graph/combatKeys.lua), and the next Escape reaches the game, which cancels the dialog its own way. Calling the
-- game's StaticPopup_EscapePressed from addon code would taint the dialogs and the game's later Escape. Waiting
-- dialogs go to Pending, as out of combat.
local function takesEscapeInFront()
    local any = false
    forEachFrontDialog(function(frame)
        if WowVision.pending.takesEscape(frame) then
            any = true
        end
    end)
    return any
end

local function requestClose(_, reason)
    if reason == "escape" and InCombatLockdown() and takesEscapeInFront() then
        return
    end
    local entries = {}
    forEachFrontDialog(function(frame)
        if not WowVision.pending.takesEscape(frame) then
            local text = getPopupText(frame)
            tinsert(entries, {
                frame = frame,
                which = frame.which,
                title = dialogTitle(frame),
                label = function()
                    return text ~= nil and text:GetText() or L["Popup"]
                end,
            })
        end
    end)
    WowVision.pending.closeRequest("popups", entries, reason)
end

module:registerWindow({
    type = "CustomWindow",
    name = "popups",
    isOpen = function(self)
        local any = false
        forEachFrontDialog(function()
            any = true
        end)
        return any
    end,
    conflictingAddons = { "Sku" },
    graphScreen = {
        render = render,
        captureClose = holdsEscape,
        onRequestClose = requestClose,
        waits = true,
        -- a dialog in front waits for an answer and ignores Escape (graph/combatKeys.lua puts it aside in a fight)
        hasWaiting = function()
            local any = false
            forEachFrontDialog(function(frame)
                if not WowVision.pending.takesEscape(frame) then
                    any = true
                end
            end)
            return any
        end,
    },
})
