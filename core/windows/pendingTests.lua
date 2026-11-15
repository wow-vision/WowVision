-- Headless only (tools/headless-tests.lua; not in modules.xml): which closes put a waiting window aside, which
-- dialogs keep the game's Escape, and the list dropping what no longer waits.
local testRunner = WowVision.testing.testRunner
local pending = WowVision.pending

-- A dialog frame as the game shows it: which key and whether it is shown.
local function dialog(which)
    local frame = { which = which, shown = true }
    function frame:IsShown()
        return self.shown
    end
    return frame
end

local function withSetting(value, fn)
    local saved = WowVision.base
    WowVision.base = { ui = { settings = { pendingWindows = value } } }
    local ok, err = pcall(fn)
    WowVision.base = saved
    if not ok then
        error(err, 0)
    end
end

local function clear()
    for _, entry in ipairs(pending.list()) do
        entry.frame.shown = false
    end
    pending.list()
end

testRunner:addSuite("PendingWindows", {
    ["on: escape and close all put aside"] = function(t)
        withSetting("on", function()
            t:assertTrue(pending.puts("escape"))
            t:assertTrue(pending.puts("closeAll"))
        end)
    end,

    ["close all only: escape keeps them in front"] = function(t)
        withSetting("closeAll", function()
            t:assertFalse(pending.puts("escape"))
            t:assertTrue(pending.puts("closeAll"))
        end)
    end,

    ["off: nothing is put aside"] = function(t)
        withSetting("off", function()
            t:assertFalse(pending.puts("escape"))
            t:assertFalse(pending.puts("closeAll"))
        end)
    end,

    ["the dialog's definition says whether it takes escape"] = function(t)
        StaticPopupDialogs.TEST_DELETE = { hideOnEscape = 1 }
        StaticPopupDialogs.TEST_INVITE = {}
        local delete, invite = dialog("TEST_DELETE"), dialog("TEST_INVITE")
        -- the game turns the frame's copy off for a moment (SetupLockOnDeclineButtonAndEscape): not asked
        delete.hideOnEscape = false
        t:assertTrue(pending.takesEscape(delete))
        t:assertFalse(pending.takesEscape(invite))
    end,

    ["a frame put aside waits until it closes"] = function(t)
        clear()
        local invite = dialog("TEST_INVITE")
        pending.putAside({ window = "popups", frame = invite, which = "TEST_INVITE", label = function()
            return "Invite"
        end })
        t:assertTrue(pending.isAside(invite))
        t:assertEqual(#pending.list(), 1)
        invite.shown = false
        t:assertFalse(pending.isAside(invite))
        t:assertEqual(#pending.list(), 0)
    end,

    ["a pooled frame showing another dialog is no longer aside"] = function(t)
        clear()
        local frame = dialog("TEST_INVITE")
        pending.putAside({ window = "popups", frame = frame, which = "TEST_INVITE", label = function()
            return "Invite"
        end })
        frame.which = "TEST_DELETE"
        t:assertFalse(pending.isAside(frame))
    end,

    ["reopening takes it off the list, once"] = function(t)
        clear()
        local frame = dialog("TEST_INVITE")
        local entry = { window = "popups", frame = frame, which = "TEST_INVITE", label = function()
            return "Invite"
        end }
        pending.putAside(entry)
        pending.putAside(entry)
        t:assertEqual(#pending.list(), 1)
        pending.reopen(entry)
        t:assertFalse(pending.isAside(frame))
        t:assertEqual(#pending.list(), 0)
    end,

    ["the countdown reads in whole seconds"] = function(t)
        local frame = dialog("TEST_INVITE")
        frame.timeleft = 41.6
        t:assertEqual(pending.timeLeft(frame), "42 seconds left")
        frame.timeleft = 0
        t:assertNil(pending.timeLeft(frame))
    end,
})
