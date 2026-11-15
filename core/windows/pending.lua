local module = WowVision.base.windows.popups
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId

-- Pending windows: a window that waits for an answer can be put aside without answering it, and taken up again from
-- Pending in the WowVision menu.
--
-- The game's own frame is never touched: it stays on screen exactly as for a sighted player who leaves it there, and
-- only WowVision's window over it closes (the keys are the game's again). Hiding the frame would answer some of them
-- (the group invitation's OnHide declines it unless inviteAccepted is set, the bind-on-equip question's OnHide
-- cancels the equip: GameDialogDefs.lua), and a hidden popup's countdown stops (StaticPopup_OnUpdate) while showing
-- it again starts it afresh. Left on screen the game answers, cancels and times it out as ever.
--
-- An entry belongs to one showing of its frame: it goes when the frame hides, and a frame shown again (the game reuses
-- a shown dialog for a second resurrection offer, the next ready check, a new invitation) is a new question that
-- comes to the front.
--
-- Which windows: those whose frame ignores Escape in the game (a static popup without hideOnEscape: the group
-- invitation, a summon, death, a resurrection; the role invitation; the ready check). A popup that takes Escape
-- (Really delete this item?) keeps the game's Escape, which cancels it.
--
-- UI setting Pending Windows: Escape and the Close All Windows key put them aside, only that key (Shift-Escape), or
-- off (nothing is put aside). Other closes (a route start closing every window) leave them in front.

local pending = {}
WowVision.pending = pending

-- frame -> entry { window, frame, which, label }: the frames put aside now, in order
local aside = {}
local order = {}

-- frames whose show and hide are watched (from their first put aside on)
local watched = {}

local function setting()
    local ui = WowVision.base ~= nil and WowVision.base.ui or nil
    return ui ~= nil and ui.settings ~= nil and ui.settings.pendingWindows or "on"
end

-- Whether a close for this reason puts waiting windows aside: "escape" (the window's close key) or "closeAllKey"
-- (the Close All Windows key). Any other close (nil: a route start) leaves them in front.
function pending.puts(reason)
    local mode = setting()
    if mode == "off" then
        return false
    end
    if reason == "closeAllKey" then
        return true
    end
    return reason == "escape" and mode == "on"
end

-- The close key of a waiting window: held while Escape puts it aside.
function pending.holdsEscape()
    return pending.puts("escape")
end

-- Whether a static popup's frame takes Escape in the game (StaticPopup_EscapePressed hides only those). The dialog's
-- definition decides, not the frame's copy: the game turns that off for its first half second on some dialogs
-- (SetupLockOnDeclineButtonAndEscape).
function pending.takesEscape(frame)
    local info = frame.which ~= nil and StaticPopupDialogs ~= nil and StaticPopupDialogs[frame.which] or nil
    return info ~= nil and info.hideOnEscape and true or false
end

local function drop(frame)
    if aside[frame] == nil then
        return
    end
    aside[frame] = nil
    for i, entry in ipairs(order) do
        if entry.frame == frame then
            table.remove(order, i)
            break
        end
    end
end

-- From its first put aside on, a frame drops its entry when it hides or is shown again (a new question).
local function watch(frame)
    if watched[frame] then
        return
    end
    watched[frame] = true
    frame:HookScript("OnShow", function(self)
        drop(self)
    end)
    frame:HookScript("OnHide", function(self)
        drop(self)
    end)
end

-- The game shows the role invitation again for a new inviter without hiding it (LFGInvitePopup_Update).
if hooksecurefunc ~= nil and LFGInvitePopup_Update ~= nil then
    hooksecurefunc("LFGInvitePopup_Update", function()
        if LFGInvitePopup ~= nil then
            drop(LFGInvitePopup)
        end
    end)
end

-- Whether this frame is put aside now (the windows treat it as closed). A pooled frame showing another dialog is not.
function pending.isAside(frame)
    local entry = aside[frame]
    if entry == nil then
        return false
    end
    if entry.which ~= nil and frame.which ~= entry.which then
        drop(frame)
        return false
    end
    return true
end

-- Put a waiting frame aside. entry: { window = window name, frame = frame, which = dialog key or nil,
-- label = function }.
function pending.putAside(entry)
    if aside[entry.frame] ~= nil then
        return
    end
    watch(entry.frame)
    aside[entry.frame] = entry
    tinsert(order, entry)
end

-- A waiting window's close request (its onRequestClose): with a reason that puts aside, its waiting frames go to
-- Pending and "Pending" is said; then WowVision's window closes. The frames' window opens again on the next check
-- for any frame still in front. entries: the put-aside entries (an empty list puts nothing aside). Without a reason
-- that puts aside, otherwise() closes as before, or the window just closes.
function pending.closeRequest(windowName, entries, reason, otherwise)
    local manager = WowVision.UIHost.windowManager
    if not pending.puts(reason) then
        if otherwise ~= nil then
            otherwise()
        else
            manager:closeWindow(windowName)
        end
        return
    end
    for _, entry in ipairs(entries) do
        entry.window = windowName
        pending.putAside(entry)
    end
    manager:closeWindow(windowName)
    -- after the close: Interrupt Speech on Window Close would cut it off
    if #entries > 0 and reason == "escape" then
        WowVision:notify(L["Pending"])
    end
end

function pending.list()
    return order
end

-- Take a waiting window up again in front: a closed window opens on the next check and takes the focus; one already
-- open (another popup in front) gets the focus.
function pending.reopen(entry)
    drop(entry.frame)
    C_Timer.After(0, function()
        local window = WowVision.UIHost.windowManager:getWindow(entry.window)
        local instance = window ~= nil and window:getOpenInstance() or nil
        if instance ~= nil and instance.stack ~= nil then
            WowVision.graphHost:focusStack(function(stack)
                return stack == instance.stack
            end)
        end
    end)
end

-- ---- the WowVision menu ----

local function renderPending(builder)
    builder:pushContext("pending", L["Pending"])
    for i, entry in ipairs(pending.list()) do
        local captured = entry
        builder:addItem(
            ControlId.structural("pending:" .. i),
            nodes.button({
                label = function()
                    return captured.label()
                end,
                onActivate = function()
                    pending.reopen(captured)
                end,
            })
        )
    end
    builder:popContext()
end

-- First in the WowVision menu while something waits.
WowVision.graph.settings.registerRootEntry(function(builder)
    if #pending.list() == 0 then
        return
    end
    builder:addItem(
        ControlId.structural("pending"),
        nodes.button({
            label = function()
                return L["Pending"] .. ", " .. #pending.list()
            end,
            opensLevel = true,
            onActivate = function()
                local host = WowVision.graphHost
                local stack = host:focusedStack()
                if stack ~= nil then
                    host:push(stack, { key = "pending", render = renderPending })
                end
            end,
        })
    )
end)

-- ---- trying it alone ----
--
-- /wv pendingtest shows a harmless popup that waits like a group invitation: it ignores Escape and runs out after a
-- minute; its buttons only print. Being shown by addon code it taints the game's own Escape while it is open
-- (StaticPopup.lua says as much on addon-initiated dialogs): an Escape that reaches the game then has its stop casting
-- refused (ADDON_ACTION_FORBIDDEN, SpellStopCasting), also once it is put aside. The command says so first. The
-- game's own popups do not do this.
StaticPopupDialogs["WOWVISION_PENDING_TEST"] = {
    text = "WowVision: " .. L["Pending test"],
    button1 = ACCEPT,
    button2 = DECLINE,
    timeout = 60,
    whileDead = true,
    OnAccept = function()
        print("WowVision: " .. L["Pending test"] .. ", " .. tostring(ACCEPT))
    end,
    OnCancel = function(_, _, reason)
        print("WowVision: " .. L["Pending test"] .. ", " .. tostring(reason == "timeout" and L["timed out"] or DECLINE))
    end,
}

module:registerCommand({
    name = "pendingtest",
    description = "Show a test popup that waits like a group invitation",
    func = function()
        local warning = L["While this test popup is open, an Escape that goes to the game reports a blocked action"]
        print("WowVision: " .. warning)
        StaticPopup_Show("WOWVISION_PENDING_TEST")
    end,
})
