local friends = WowVision.classic ~= nil and WowVision.classic.friends or nil
if friends == nil or GuildFrame == nil then
    return
end
local module = friends.module
local L = friends.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The guild tab of the friends window (GuildFrame) and its side windows:
-- the classic guild window, which the game uses instead of the Guild and
-- Communities window while the CVar useClassicGuildUI is on (the friends
-- window only shows the Guild tab then; on TBC Anniversary it is on).
--
-- The tab: guild name, member totals, the message of the day (Enter edits it
-- when you may, through the game's own box), the roster (Faux pool over the
-- roster API; each row reads name, level and class, zone or last online,
-- rank and note -- both column sets the window can show), Show Offline, the
-- column view toggle and its sort headers, Add Member, Guild Control, Guild
-- Information.
--
-- Everything goes through the game: a left click on a member selects them
-- and opens the member card, a right click opens the game's member menu.
-- The member card, the guild information, the event log and guild control
-- are windows of their own below (they open beside the friends window).

local function shownText(fontString)
    return function()
        if fontString == nil or not fontString:IsShown() then
            return nil
        end
        local text = fontString:GetText()
        if text ~= nil and text ~= "" then
            return text
        end
        return nil
    end
end

local function addProxy(builder, button, key, label)
    if button == nil or not button:IsShown() then
        return
    end
    local vtable = nodes.proxyButton({ target = button, label = label })
    if vtable ~= nil then
        builder:beginStop(key)
        builder:addItem(ControlId.forObject(button), vtable)
    end
end

-- The buttons that show, as one row.
local function addButtonRow(builder, buttons)
    builder:startRow()
    for _, button in ipairs(buttons) do
        if button ~= nil and button:IsShown() then
            local vtable = nodes.proxyButton({ target = button })
            if vtable ~= nil then
                builder:addItem(ControlId.forObject(button), vtable)
            end
        end
    end
    builder:endRow()
end

local function addCheck(builder, button, label)
    if button == nil or not button:IsShown() then
        return
    end
    local vtable = nodes.proxyCheckButton({ target = button, label = label })
    if vtable ~= nil then
        builder:addItem(ControlId.forObject(button), vtable)
    end
end

-- ---------------------------------------------------------------------------
-- The roster
-- ---------------------------------------------------------------------------

-- Which of the two column sets shows: player status (zone, level, class) or
-- guild status (rank, note, online). The toggle button flips it.
local function playerView()
    return FriendsFrame.playerStatusFrame ~= nil
end

local function rowButtons()
    local prefix = playerView() and "GuildFrameButton" or "GuildFrameGuildStatusButton"
    local pool = {}
    for i = 1, GUILDMEMBERS_TO_DISPLAY do
        pool[i] = _G[prefix .. i]
    end
    return pool
end

local function memberCount()
    local total, online = GetNumGuildMembers()
    if GetGuildRosterShowOffline() then
        return total or 0
    end
    return online or 0
end

local function memberId(index)
    local fullName = GetGuildRosterInfo(index)
    return ControlId.structural("guildMember:" .. tostring(fullName or index))
end

local function memberLabel(index)
    local fullName, rank, _, level, class, zone, note, _, online, isAway = GetGuildRosterInfo(index)
    if fullName == nil then
        return UNKNOWN
    end
    local where
    if online then
        if isAway == 2 then
            where = nodes.joinLabel(zone, CHAT_FLAG_DND)
        elseif isAway == 1 then
            where = nodes.joinLabel(zone, CHAT_FLAG_AFK)
        else
            where = zone
        end
    else
        where = GuildFrame_GetLastOnline(index)
    end
    return nodes.joinLabel(
        Ambiguate(fullName, "guild"),
        format(FRIENDS_LEVEL_TEMPLATE, level or 0, class or ""),
        where,
        rank,
        note
    )
end

local function renderRoster(builder)
    builder:beginStop("list")
    nodes.hybridScrollList(builder, {
        scrollFrame = GuildListScrollFrame,
        key = "guild",
        label = L["Members"],
        tainted = true,
        rowHeight = FRIENDS_FRAME_GUILD_HEIGHT,
        count = memberCount,
        -- Must mirror the ids emit assigns (tainted mode).
        id = memberId,
        buttons = rowButtons,
        indexOf = function(button)
            return button.guildIndex
        end,
        emit = function(b, index, helpers)
            b:addItem(memberId(index), {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return memberLabel(index)
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            if GetGuildRosterSelection() == index then
                                return L["selected"]
                            end
                            return nil
                        end,
                        kind = kinds.selected,
                    },
                },
                bindings = friends.withEdgeBindings({
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                    { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
                }, helpers),
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
            })
        end,
    })
end

-- The sort headers of the column set that shows, in screen order.
local function renderSortHeaders(builder)
    local prefix = playerView() and "GuildFrameColumnHeader" or "GuildFrameGuildStatusColumnHeader"
    builder:pushContext("sort", L["Sort"])
    local headers = {}
    for i = 1, 4 do
        tinsert(headers, _G[prefix .. i])
    end
    addButtonRow(builder, headers)
    builder:popContext()
end

function friends.renderGuild(builder, screen)
    builder:beginStop("guild")
    builder:pushContext("guild", GetGuildInfo("player") or GUILD)
    builder:addItem(
        ControlId.structural("guild:totals"),
        nodes.text({
            label = function()
                return nodes.joinLabel(GuildFrameTotals:GetText(), GuildFrameOnlineTotals:GetText())
            end,
        })
    )
    -- The message of the day; its edit button lies over the text.
    local motdLabel = function()
        return GuildFrameNotesLabel:GetText()
    end
    local motdText = function()
        local text = GuildFrameNotesText:GetText()
        if text ~= nil and text ~= "" then
            return text
        end
        return L["Empty"]
    end
    if GuildMOTDEditButton ~= nil and GuildMOTDEditButton:IsShown() and GuildMOTDEditButton:IsEnabled() then
        local vtable = nodes.proxyButton({
            target = GuildMOTDEditButton,
            label = function()
                return nodes.joinLabel(motdLabel(), motdText())
            end,
        })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(GuildMOTDEditButton), vtable)
        end
    else
        builder:addItem(
            ControlId.structural("guild:motd"),
            nodes.text({
                label = function()
                    return nodes.joinLabel(motdLabel(), motdText())
                end,
            })
        )
    end
    builder:popContext()

    renderRoster(builder)

    builder:beginStop("guildControls")
    builder:pushContext("guildControls", L["Controls"])
    addCheck(builder, GuildFrameLFGButton)
    if GuildFrameGuildListToggleButton ~= nil and GuildFrameGuildListToggleButton:IsShown() then
        -- The game names the column set that shows only in the button's
        -- tooltip: Player Status or Guild Status.
        local vtable = nodes.proxyButton({
            target = GuildFrameGuildListToggleButton,
            label = function()
                return playerView() and PLAYER_STATUS or GUILD_STATUS
            end,
            hover = false,
        })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(GuildFrameGuildListToggleButton), vtable)
        end
    end
    renderSortHeaders(builder)
    addButtonRow(builder, {
        GuildFrameAddMemberButton,
        GuildFrameControlButton,
        GuildFrameGuildInformationButton,
        GuildFrameImpeachButton,
    })
    builder:popContext()
end

-- ---------------------------------------------------------------------------
-- The member card (GuildMemberDetailFrame): name, level and class, zone,
-- rank with Promote and Demote, online or last online, the notes (Enter
-- edits a note you may edit: the note frame's own mouse script, as a click
-- does), Remove, Group Invite, Close.
-- ---------------------------------------------------------------------------

local function labelled(labelString, valueString)
    return function()
        return nodes.joinLabel(labelString:GetText(), valueString:GetText())
    end
end

local function addNote(builder, key, background, labelString, noteString)
    if background == nil or not background:IsShown() then
        return
    end
    builder:beginStop(key)
    if background:IsMouseEnabled() then
        builder:addItem(
            ControlId.forObject(background),
            nodes.button({
                label = nodes.fontText(labelString),
                value = function()
                    return noteString:GetText()
                end,
                onActivate = function()
                    local script = background:GetScript("OnMouseUp")
                    if script ~= nil then
                        script(background, "LeftButton", true)
                    end
                end,
            })
        )
    else
        builder:addItem(ControlId.forObject(background), nodes.text({ label = labelled(labelString, noteString) }))
    end
end

local function renderMemberDetail(builder, screen)
    local frame = GuildMemberDetailFrame
    if frame == nil or not frame:IsVisible() then
        return
    end
    builder:pushContext("memberDetail", nodes.fontText(GuildMemberDetailName))
    builder:beginStop("memberDetail:info")
    builder:addItem(
        ControlId.structural("memberDetail:level"),
        nodes.text({ label = shownText(GuildMemberDetailLevel) })
    )
    builder:addItem(
        ControlId.structural("memberDetail:zone"),
        nodes.text({ label = labelled(GuildMemberDetailZoneLabel, GuildMemberDetailZoneText) })
    )
    builder:addItem(
        ControlId.structural("memberDetail:rank"),
        nodes.text({ label = labelled(GuildMemberDetailRankLabel, GuildMemberDetailRankText) })
    )
    builder:addItem(
        ControlId.structural("memberDetail:online"),
        nodes.text({ label = labelled(GuildMemberDetailOnlineLabel, GuildMemberDetailOnlineText) })
    )
    if GuildFramePromoteButton:IsShown() then
        builder:beginStop("memberDetail:rankButtons")
        addButtonRow(builder, { GuildFramePromoteButton, GuildFrameDemoteButton })
    end
    addNote(builder, "memberDetail:note", GuildMemberNoteBackground, GuildMemberDetailNoteLabel, PersonalNoteText)
    addNote(
        builder,
        "memberDetail:officerNote",
        GuildMemberOfficerNoteBackground,
        GuildMemberDetailOfficerNoteLabel,
        OfficerNoteText
    )
    builder:beginStop("memberDetail:buttons")
    addButtonRow(builder, { GuildMemberRemoveButton, GuildMemberGroupInviteButton })
    addProxy(builder, GuildMemberDetailCloseButton, "memberDetail:close", CLOSE)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "GuildMemberDetail",
    frameName = "GuildMemberDetailFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderMemberDetail },
})

-- ---------------------------------------------------------------------------
-- Guild information (GuildInfoFrame): the text (an edit box when you may
-- edit it, Save and Cancel then), the event log button, Close.
-- ---------------------------------------------------------------------------

local function renderGuildInfo(builder, screen)
    local frame = GuildInfoFrame
    if frame == nil or not frame:IsVisible() then
        return
    end
    builder:pushContext("guildInfo", nodes.fontText(GuildInfoTitle))
    builder:beginStop("guildInfo:text")
    if CanEditGuildInfo() then
        local vtable = nodes.proxyEditBox({ editBox = GuildInfoEditBox, label = nodes.fontText(GuildInfoTitle) })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(GuildInfoEditBox), vtable)
        end
    else
        builder:addItem(
            ControlId.structural("guildInfo:text"),
            nodes.text({
                label = function()
                    local text = GuildInfoEditBox:GetText()
                    if text ~= nil and text ~= "" then
                        return text
                    end
                    return L["Empty"]
                end,
            })
        )
    end
    builder:beginStop("guildInfo:buttons")
    addButtonRow(builder, { GuildInfoSaveButton, GuildInfoCancelButton, GuildInfoGuildEventButton })
    addProxy(builder, GuildInfoCloseButton, "guildInfo:close", CLOSE)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "GuildInfo",
    frameName = "GuildInfoFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderGuildInfo },
})

-- ---------------------------------------------------------------------------
-- The guild event log (GuildEventLogFrame): the lines the log shows, newest
-- first, one per entry, then Close.
-- ---------------------------------------------------------------------------

local function eventLines()
    local lines = {}
    local text = GuildEventMessage:GetText()
    if text == nil then
        return lines
    end
    -- Blizzard ends every entry with the |n line break.
    local position = 1
    while position <= #text do
        local first, last = string.find(text, "|n", position, true)
        local line = string.sub(text, position, (first or (#text + 1)) - 1)
        if line ~= "" then
            tinsert(lines, line)
        end
        if first == nil then
            break
        end
        position = last + 1
    end
    return lines
end

local function renderEventLog(builder, screen)
    local frame = GuildEventLogFrame
    if frame == nil or not frame:IsVisible() then
        return
    end
    builder:pushContext("guildLog", nodes.fontText(GuildEventLogTitle))
    builder:beginStop("guildLog:events")
    local lines = eventLines()
    if #lines == 0 then
        builder:addItem(ControlId.structural("guildLog:empty"), nodes.text({ label = L["Empty"] }))
    end
    for index, line in ipairs(lines) do
        builder:addItem(ControlId.structural("guildLog:" .. index), nodes.text({ label = line }))
    end
    addProxy(builder, GuildEventLogCancelButton, "guildLog:close", CLOSE)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "GuildEventLog",
    frameName = "GuildEventLogFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderEventLog },
})

-- ---------------------------------------------------------------------------
-- Guild control (GuildControlPopupFrame, the guild master's Guild Control
-- button): the rank dropdown, the rank name, Add Rank and Remove Rank, the
-- rank's permissions, the gold it may withdraw per day, and per guild bank
-- tab what it may do there; Accept and Cancel. The guild bank part only
-- shows where the guild bank is on.
-- ---------------------------------------------------------------------------

local function addEditBox(builder, editBox, label)
    if editBox == nil or not editBox:IsVisible() then
        return
    end
    local vtable = nodes.proxyEditBox({ editBox = editBox, label = label })
    if vtable ~= nil then
        builder:addItem(ControlId.forObject(editBox), vtable)
    end
end

local function renderGuildControl(builder, screen)
    local frame = GuildControlPopupFrame
    if frame == nil or not frame:IsVisible() then
        return
    end
    builder:pushContext("guildControl", GUILDCONTROL)

    builder:beginStop("guildControl:rank")
    builder:pushContext("guildControl:rank", RANK)
    local dropdown = GuildControlPopupFrameDropdown
    if dropdown ~= nil and dropdown:IsShown() then
        local vtable = nodes.proxyDropdown({ target = dropdown })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(dropdown), vtable)
        end
    end
    addEditBox(builder, GuildControlPopupFrameEditBox, L["Rank Name"])
    addButtonRow(builder, { GuildControlPopupFrameAddRankButton, GuildControlPopupFrameRemoveRankButton })
    builder:popContext()

    builder:beginStop("guildControl:permissions")
    builder:pushContext("guildControl:permissions", L["Permissions"])
    local checkboxes = {}
    for _, checkbox in pairs(GuildControlPopupFrameCheckboxes.PermissionCheckboxes or {}) do
        tinsert(checkboxes, checkbox)
    end
    table.sort(checkboxes, function(a, b)
        return a:GetID() < b:GetID()
    end)
    for _, checkbox in ipairs(checkboxes) do
        addCheck(builder, checkbox)
    end
    addEditBox(builder, GuildControlWithdrawGoldEditBox, function()
        return nodes.joinLabel(GuildControlWithdrawGoldText:GetText(), GuildControlWithdrawGoldAmountText:GetText())
    end)
    builder:popContext()

    if GuildControlPopupFrameTabPermissions ~= nil and GuildControlPopupFrameTabPermissions:IsVisible() then
        builder:beginStop("guildControl:bankTabs")
        builder:pushContext("guildControl:bankTabs", L["Bank Tabs"])
        builder:startRow()
        for i = 1, MAX_GUILDBANK_TABS or 6 do
            local tab = _G["GuildBankTabPermissionsTab" .. i]
            if tab ~= nil and tab:IsShown() then
                local tabIndex = i
                local vtable = nodes.proxyButton({
                    target = tab,
                    label = function()
                        local name = GetGuildBankTabInfo(tabIndex)
                        if name ~= nil and name ~= "" then
                            return name
                        end
                        return tostring(tabIndex)
                    end,
                    hover = false,
                })
                if vtable ~= nil then
                    tinsert(vtable.announcements, {
                        text = function()
                            return GuildControlPopupFrameTabPermissions.selectedTab == tabIndex and L["selected"] or nil
                        end,
                        kind = kinds.selected,
                    })
                    builder:addItem(ControlId.forObject(tab), vtable)
                end
            end
        end
        builder:endRow()
        builder:popContext()

        builder:beginStop("guildControl:bankTab")
        builder:pushContext("guildControl:bankTab", nodes.fontText(GuildBankTabLabel))
        addCheck(builder, GuildControlTabPermissionsViewTab)
        addCheck(builder, GuildControlTabPermissionsDepositItems)
        addCheck(builder, GuildControlTabPermissionsUpdateText)
        addEditBox(
            builder,
            GuildControlWithdrawItemsEditBox,
            nodes.fontText(GuildControlTabPermissionsWithdrawItemsText)
        )
        builder:popContext()
    end

    builder:beginStop("guildControl:buttons")
    addButtonRow(builder, { GuildControlPopupAcceptButton, GuildControlPopupFrameCancelButton })
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "GuildControlPopup",
    frameName = "GuildControlPopupFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderGuildControl },
})
