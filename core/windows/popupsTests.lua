-- Group invitations: /wv accept (popups.acceptInvite) on the plain invitation
-- popup and on the invitation that asks for a role (LFGInvitePopup), and the
-- role popup screen's render on the invitation (title, warning, roles,
-- buttons). The harness in tools/headless-tests.lua loads popups.lua and
-- RolePoll.lua against a stand-in window module and hands over what they
-- registered.

local testRunner = WowVision.testing.testRunner
local harness = WowVision._popupsTestHarness
local popups = harness.popups

local function fakeButton(options)
    options = options or {}
    local button = {
        shown = options.shown ~= false,
        enabled = options.enabled ~= false,
        checked = options.checked or false,
        text = options.text,
        clicks = 0,
    }
    function button:IsShown()
        return self.shown
    end
    function button:IsEnabled()
        return self.enabled
    end
    function button:GetChecked()
        return self.checked
    end
    function button:GetText()
        return self.text
    end
    function button:Click()
        self.clicks = self.clicks + 1
    end
    return button
end

local function fakeFontString(text, shown)
    return {
        GetObjectType = function()
            return "FontString"
        end,
        GetText = function()
            return text
        end,
        IsShown = function()
            return shown ~= false
        end,
    }
end

-- The game's globals for one test: static popup dialogs (each { which,
-- buttons }), the invite popup with its role buttons, and notify recorded.
-- Returns the spoken lines and a restore function. The restore also runs
-- after a test that throws (see the suite's wrapper at the end), so a failing
-- test never leaves the stand-ins for later suites.
local GLOBALS = {
    "StaticPopup_ForEachShownDialog",
    "LFGInvitePopup",
    "LFGInvitePopupText",
    "LFGInvitePopupAcceptButton",
    "LFGInvitePopupDeclineButton",
    "LFGInvitePopupCloseButton",
    "LFGInvitePopupRoleButtonTank",
    "LFGInvitePopupRoleButtonHealer",
    "LFGInvitePopupRoleButtonDPS",
}

local activeRestore = nil

local function installGame(game)
    local saved = {}
    for _, name in ipairs(GLOBALS) do
        saved[name] = _G[name]
        _G[name] = nil
    end
    local savedNotify = WowVision.notify
    local spoken = {}
    WowVision.notify = function(_, text)
        table.insert(spoken, text)
    end

    -- As in the game, the shown special popups (the role invitation) are in
    -- the same list as the static dialogs, without a `which`.
    local dialogs = game.dialogs or {}
    local invite = game.invite
    _G.StaticPopup_ForEachShownDialog = function(func)
        for _, dialog in ipairs(dialogs) do
            func({
                which = dialog.which,
                GetButtons = function()
                    return dialog.buttons
                end,
            })
        end
        if invite ~= nil and invite.shown ~= false then
            func(_G.LFGInvitePopup)
        end
    end

    if invite ~= nil then
        -- The queue warning is an ARTWORK font string too, ahead of the
        -- title in region order: the title must come from its name.
        local warningString = invite.warning ~= nil and fakeFontString(invite.warning, invite.warningShown) or nil
        local regions = { warningString or fakeFontString("not the title") }
        _G.LFGInvitePopupText = fakeFontString(invite.title)
        _G.LFGInvitePopup = {
            special = true,
            GetName = function()
                return "LFGInvitePopup"
            end,
            QueueWarningText = warningString,
            IsShown = function()
                return invite.shown ~= false
            end,
            GetRegions = function()
                return unpack(regions)
            end,
        }
        _G.LFGInvitePopupAcceptButton = invite.accept
        _G.LFGInvitePopupDeclineButton = invite.decline
        for key, checkButton in pairs(invite.roles or {}) do
            _G["LFGInvitePopupRoleButton" .. key] = { checkButton = checkButton }
        end
    end

    local function restore()
        if activeRestore ~= restore then
            return
        end
        activeRestore = nil
        for _, name in ipairs(GLOBALS) do
            _G[name] = saved[name]
        end
        WowVision.notify = savedNotify
    end
    activeRestore = restore
    return spoken, restore
end

-- A builder that records the render: contexts, stops and item labels.
local function recordingBuilder()
    local record = { contexts = {}, stops = {}, labels = {} }
    local builder = {}
    function builder:pushContext(key, label)
        table.insert(record.contexts, { key = key, label = label })
    end
    function builder:popContext() end
    function builder:beginStop(key)
        table.insert(record.stops, key or "?")
    end
    function builder:addItem(_, vtable)
        local label = vtable.announcements[1].text
        if type(label) == "function" then
            label = label()
        end
        table.insert(record.labels, label)
    end
    return builder, record
end

local tests = {
    ["accept clicks the plain invitation popup's first shown button"] = function(t)
        local hidden, accept = fakeButton({ shown = false }), fakeButton()
        local spoken, restore = installGame({
            dialogs = { { which = "PARTY_INVITE", buttons = { hidden, accept, fakeButton() } } },
        })
        local ok = popups.acceptInvite()
        restore()
        t:assertTrue(ok)
        t:assertEqual(accept.clicks, 1)
        t:assertEqual(hidden.clicks, 0)
        t:assertEqual(spoken[1], "Group invitation accepted")
    end,

    ["accept takes the role invitation when a role is checked"] = function(t)
        local accept = fakeButton()
        local spoken, restore = installGame({ invite = { title = "Ann invites you", accept = accept } })
        local ok = popups.acceptInvite()
        restore()
        t:assertTrue(ok)
        t:assertEqual(accept.clicks, 1)
        t:assertEqual(spoken[1], "Group invitation accepted")
    end,

    ["accept on the role invitation without a checked role asks for one"] = function(t)
        local accept = fakeButton({ enabled = false })
        local spoken, restore = installGame({ invite = { title = "Ann invites you", accept = accept } })
        local ok = popups.acceptInvite()
        restore()
        t:assertFalse(ok)
        t:assertEqual(accept.clicks, 0)
        t:assertEqual(spoken[1], "Choose a role first")
    end,

    ["accept takes the plain invitation when the role invitation is listed too"] = function(t)
        local plain, roleAccept = fakeButton(), fakeButton()
        local spoken, restore = installGame({
            dialogs = { { which = "PARTY_INVITE", buttons = { plain } } },
            invite = { title = "Ann invites you", accept = roleAccept },
        })
        local ok = popups.acceptInvite()
        restore()
        t:assertTrue(ok)
        t:assertEqual(plain.clicks, 1)
        t:assertEqual(roleAccept.clicks, 0)
        t:assertEqual(spoken[1], "Group invitation accepted")
    end,

    ["the popups window leaves the special role invitation to its own window"] = function(t)
        local popupsWindow = harness.windows.popups
        local _, restore = installGame({ invite = { title = "Ann invites you", accept = fakeButton() } })
        local open = popupsWindow.isOpen(popupsWindow)
        local builder, record = recordingBuilder()
        popupsWindow.graphScreen.render(builder)
        restore()
        t:assertFalse(open)
        t:assertNil(record.contexts[1])
    end,

    ["the popups window still opens for a static dialog next to the role invitation"] = function(t)
        local popupsWindow = harness.windows.popups
        local _, restore = installGame({
            dialogs = { { which = "CONFIRM_LEAVE", buttons = {} } },
            invite = { title = "Ann invites you", accept = fakeButton() },
        })
        local open = popupsWindow.isOpen(popupsWindow)
        local builder, record = recordingBuilder()
        popupsWindow.graphScreen.render(builder)
        restore()
        t:assertTrue(open)
        t:assertEqual(#record.contexts, 1)
        t:assertEqual(record.contexts[1].key, "popup:CONFIRM_LEAVE")
    end,

    ["accept without an invitation says so"] = function(t)
        local accept = fakeButton()
        local spoken, restore = installGame({
            dialogs = { { which = "CONFIRM_LEAVE", buttons = { fakeButton() } } },
            invite = { title = "Ann invites you", accept = accept, shown = false },
        })
        local ok = popups.acceptInvite()
        restore()
        t:assertFalse(ok)
        t:assertEqual(accept.clicks, 0)
        t:assertEqual(spoken[1], "No group invitation")
    end,

    ["the invitation screen: title without markup, warning, playable roles, buttons"] = function(t)
        local _, restore = installGame({
            invite = {
                title = "|A:QuestSharing-QuestLog-Replay:19:16|aAnn invites you to a group.",
                warning = "Accepting this invitation will remove you from all queues.",
                accept = fakeButton({ text = "Accept" }),
                decline = fakeButton({ text = "Decline" }),
                roles = {
                    Tank = fakeButton({ shown = false }),
                    Healer = fakeButton(),
                    DPS = fakeButton({ checked = true }),
                },
            },
        })
        local builder, record = recordingBuilder()
        harness.windows.LFGInvitePopup.graphScreen.render(builder)
        restore()
        t:assertEqual(record.contexts[1].label, "Ann invites you to a group.")
        t:assertEqual(record.stops[1], "warning")
        t:assertEqual(record.labels[1], "Accepting this invitation will remove you from all queues.")
        t:assertEqual(record.labels[2], "Healer")
        t:assertEqual(record.labels[3], "Damage Dealer")
        t:assertEqual(record.labels[4], "Accept")
        t:assertEqual(record.labels[5], "Decline")
        t:assertNil(record.labels[6])
    end,

    ["an empty warning is left out (the game shows the line with no text)"] = function(t)
        local _, restore = installGame({
            invite = {
                title = "Ann invites you to a group.",
                warning = "",
                accept = fakeButton({ text = "Accept" }),
                roles = { Healer = fakeButton() },
            },
        })
        local builder, record = recordingBuilder()
        harness.windows.LFGInvitePopup.graphScreen.render(builder)
        restore()
        t:assertEqual(record.stops[1], "roles")
        t:assertEqual(record.labels[1], "Healer")
    end,
}

-- Each test restores the game's globals even when it throws.
for name, test in pairs(tests) do
    tests[name] = function(t)
        local ok, err = pcall(test, t)
        if activeRestore ~= nil then
            activeRestore()
        end
        if not ok then
            error(err, 0)
        end
    end
end

testRunner:addSuite("GroupInvite", tests)
