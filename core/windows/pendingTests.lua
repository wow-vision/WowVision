-- Headless only (tools/headless-tests.lua; not in modules.xml): which closes put a waiting window aside, which
-- dialogs keep the game's Escape, and the list following the frames: an entry goes when its frame hides or is shown
-- again.
local testRunner = WowVision.testing.testRunner
local pending = WowVision.pending

-- A dialog frame as the game shows it: which key, shown or not, and the scripts hooked on it.
local function dialog(which)
    local frame = { which = which, shown = true, hooks = {} }
    function frame:IsShown()
        return self.shown
    end
    function frame:HookScript(script, func)
        self.hooks[script] = self.hooks[script] or {}
        tinsert(self.hooks[script], func)
    end
    local function run(self, script)
        for _, func in ipairs(self.hooks[script] or {}) do
            func(self)
        end
    end
    function frame:hide()
        self.shown = false
        run(self, "OnHide")
    end
    function frame:show()
        self.shown = true
        run(self, "OnShow")
    end
    return frame
end

local function entry(frame)
    return {
        window = "popups",
        frame = frame,
        which = frame.which,
        label = function()
            return "Invite"
        end,
    }
end

-- The setting, the window manager and the speech, as the game has them; what was said and closed is kept.
local function withGame(value, fn)
    local saved = { base = WowVision.base, host = WowVision.UIHost, notify = WowVision.notify }
    local said, closed = {}, {}
    WowVision.base = { ui = { settings = { pendingWindows = value } } }
    WowVision.UIHost = {
        windowManager = {
            closeWindow = function(_, name)
                tinsert(closed, name)
            end,
        },
    }
    WowVision.notify = function(_, text)
        tinsert(said, text)
    end
    local ok, err = pcall(fn, said, closed)
    WowVision.base, WowVision.UIHost, WowVision.notify = saved.base, saved.host, saved.notify
    for i = #pending.list(), 1, -1 do
        pending.list()[i].frame:hide()
    end
    if not ok then
        error(err, 0)
    end
end

testRunner:addSuite("PendingWindows", {
    ["escape and the close all key put aside, by default"] = function(t)
        withGame("on", function()
            t:assertTrue(pending.puts("escape"))
            t:assertTrue(pending.puts("closeAllKey"))
            t:assertTrue(pending.holdsEscape())
        end)
    end,

    ["only the close all key: escape keeps them in front"] = function(t)
        withGame("closeAll", function()
            t:assertFalse(pending.puts("escape"))
            t:assertFalse(pending.holdsEscape())
            t:assertTrue(pending.puts("closeAllKey"))
        end)
    end,

    ["off: nothing is put aside"] = function(t)
        withGame("off", function()
            t:assertFalse(pending.puts("escape"))
            t:assertFalse(pending.puts("closeAllKey"))
        end)
    end,

    ["a route start closing every window leaves them in front"] = function(t)
        withGame("on", function()
            t:assertFalse(pending.puts(nil))
        end)
    end,

    ["the dialog's definition says whether it takes escape"] = function(t)
        local saved = StaticPopupDialogs
        StaticPopupDialogs = { TEST_DELETE = { hideOnEscape = 1 }, TEST_INVITE = {} }
        local delete, invite = dialog("TEST_DELETE"), dialog("TEST_INVITE")
        -- the game turns the frame's copy off for a moment (SetupLockOnDeclineButtonAndEscape): not asked
        delete.hideOnEscape = false
        local takes, ignores = pending.takesEscape(delete), pending.takesEscape(invite)
        StaticPopupDialogs = saved
        t:assertTrue(takes)
        t:assertFalse(ignores)
    end,

    ["a close request puts aside, closes, then says pending"] = function(t)
        withGame("on", function(said, closed)
            local invite = dialog("TEST_INVITE")
            pending.closeRequest("popups", { entry(invite) }, "escape")
            t:assertTrue(pending.isAside(invite))
            t:assertEqual(closed[1], "popups")
            t:assertEqual(said[1], "Pending")
        end)
    end,

    ["the close all key puts aside quietly"] = function(t)
        withGame("on", function(said)
            local invite = dialog("TEST_INVITE")
            pending.closeRequest("popups", { entry(invite) }, "closeAllKey")
            t:assertTrue(pending.isAside(invite))
            t:assertNil(said[1])
        end)
    end,

    ["a close that does not put aside closes as before"] = function(t)
        withGame("off", function(said, closed)
            local invite = dialog("TEST_INVITE")
            local before = false
            pending.closeRequest("ReadyCheck", { entry(invite) }, "escape", function()
                before = true
            end)
            t:assertFalse(pending.isAside(invite))
            t:assertTrue(before)
            t:assertNil(closed[1])
        end)
    end,

    ["a frame that hides drops its entry; shown again it is in front"] = function(t)
        withGame("on", function()
            local check = dialog(nil)
            pending.putAside(entry(check))
            t:assertTrue(pending.isAside(check))
            check:hide()
            t:assertEqual(#pending.list(), 0)
            check:show()
            t:assertFalse(pending.isAside(check), "the next ready check comes to the front")
        end)
    end,

    ["a shown dialog shown again with a new question comes to the front"] = function(t)
        withGame("on", function()
            local resurrect = dialog("TEST_INVITE")
            pending.putAside(entry(resurrect))
            -- the game reuses the shown dialog for a second offer: shown again in one call
            resurrect:show()
            t:assertFalse(pending.isAside(resurrect))
        end)
    end,

    ["a pooled frame showing another dialog is no longer aside"] = function(t)
        withGame("on", function()
            local frame = dialog("TEST_INVITE")
            pending.putAside(entry(frame))
            frame.which = "TEST_DELETE"
            t:assertFalse(pending.isAside(frame))
        end)
    end,

    ["putting aside twice keeps one entry"] = function(t)
        withGame("on", function()
            local frame = dialog("TEST_INVITE")
            local one = entry(frame)
            pending.putAside(one)
            pending.putAside(one)
            t:assertEqual(#pending.list(), 1)
        end)
    end,
})
