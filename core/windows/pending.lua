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
-- it again starts it afresh. Left on screen the game answers, cancels and times it out as ever, and the entry goes
-- when its frame does.
--
-- Which windows: those whose frame ignores Escape in the game (a static popup without hideOnEscape: the group
-- invitation, a summon, death, a resurrection; the role invitation; the ready check). A popup that takes Escape
-- (Really delete this item?) keeps the game's Escape, which cancels it.
--
-- UI setting Pending Windows: on (Escape and Close All Windows put them aside), close all (only Close All Windows,
-- Shift-Escape), off (they wait in front, as before).

local pending = {}
WowVision.pending = pending

-- frame -> { window, frame, which, label }: the frames put aside now
local aside = {}
local order = {}

local function setting()
    local ui = WowVision.base ~= nil and WowVision.base.ui or nil
    return ui ~= nil and ui.settings ~= nil and ui.settings.pendingWindows or "on"
end

-- Whether a close of this kind puts waiting windows aside: "escape" or "closeAll".
function pending.puts(how)
    local mode = setting()
    if mode == "off" then
        return false
    end
    return how == "closeAll" or mode == "on"
end

-- Whether a static popup's frame takes Escape in the game (StaticPopup_EscapePressed hides only those). The dialog's
-- definition decides, not the frame's copy: the game turns that off for its first half second on some dialogs
-- (SetupLockOnDeclineButtonAndEscape).
function pending.takesEscape(frame)
    local info = frame.which ~= nil and StaticPopupDialogs ~= nil and StaticPopupDialogs[frame.which] or nil
    return info ~= nil and info.hideOnEscape and true or false
end

-- Drop what no longer waits: the frame closed, or it shows another dialog now.
local function prune()
    for i = #order, 1, -1 do
        local entry = order[i]
        local frame = entry.frame
        if not frame:IsShown() or (entry.which ~= nil and frame.which ~= entry.which) then
            aside[frame] = nil
            table.remove(order, i)
        end
    end
end

-- Whether this frame is put aside now (the windows treat it as closed).
function pending.isAside(frame)
    if aside[frame] == nil then
        return false
    end
    prune()
    return aside[frame] ~= nil
end

-- Put a waiting frame aside. entry: { window = name, frame = frame, which = dialog key or nil, label = function }.
function pending.putAside(entry)
    if aside[entry.frame] ~= nil then
        return
    end
    aside[entry.frame] = entry
    tinsert(order, entry)
end

-- Say it once for a close that put something aside.
function pending.announce()
    WowVision:notify(L["Pending"])
end

function pending.list()
    prune()
    return order
end

-- Take a waiting window up again: its window opens on the next check, focused.
function pending.reopen(entry)
    aside[entry.frame] = nil
    for i, candidate in ipairs(order) do
        if candidate == entry then
            table.remove(order, i)
            break
        end
    end
end

-- A countdown the game shows on a static popup (timeleft), as words.
function pending.timeLeft(frame)
    local seconds = frame.timeleft
    if type(seconds) ~= "number" or seconds <= 0 then
        return nil
    end
    return math.floor(seconds + 0.5) .. " " .. L["seconds left"]
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
-- /wv pendingtest shows a harmless popup that waits like a group invitation: it ignores Escape and counts down a
-- minute; its buttons only print.
StaticPopupDialogs = StaticPopupDialogs or {}
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
        StaticPopup_Show("WOWVISION_PENDING_TEST")
    end,
})
