local module = WowVision.base.windows:createModule("friends")
local L = module.L
module:setLabel(L["Friends"])

-- The social panel (FriendsFrame): friends list, ignore list, who, and the
-- guild tab (classic/guild.lua, shown when the game uses the classic guild
-- window).
-- Shared by Vanilla, TBC, and Mists -- Blizzard ships the identical
-- FriendsFrame file on all classic clients; only a few Battle.net WRITE
-- calls differ (C_BattleNet.SetAFK vs BNSetAFK), and this file reads
-- through APIs present on all of them.
--
-- Interaction replicates Blizzard's model: Enter on a row selects it (a
-- real left click), the bottom-bar buttons act on the selection from the
-- controls stop, and Backspace right-clicks the row so Blizzard's own
-- dropdown menu (whisper, set note, invite, remove...) opens; the dropdown
-- watcher turns that menu into a navigable screen.

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

if FriendsFrame == nil then
    return
end

-- Shared with the tab files loaded after this one (classic/guild.lua), which
-- add their render functions here.
WowVision.classic = WowVision.classic or {}
local friends = {
    module = module,
    L = L,
}
WowVision.classic.friends = friends

local function bnFriendCounts()
    if BNGetNumFriends == nil then
        return 0, 0
    end
    local total, online = BNGetNumFriends()
    return total or 0, online or 0
end

-- ---------------------------------------------------------------------------
-- Friends list (HybridScrollFrame with variable-height rows)
-- ---------------------------------------------------------------------------

-- Mirror of Blizzard's FriendsList_Update entry construction: the real list
-- (FriendListEntries) is file-local in their code, so the same order is
-- rebuilt here -- invites, online WoW, online BNet, offline WoW, offline
-- BNet, with headers and dividers -- along with each entry's pixel offset
-- for exact scrolling despite the mixed row heights.
local function friendEntries()
    local entries = {}
    local offsets = {}
    local height = 0
    local function add(buttonType, id)
        tinsert(entries, { buttonType = buttonType, id = id })
        offsets[#entries] = height
        height = height + (FRIENDS_BUTTON_HEIGHTS[buttonType] or 34)
    end

    local numBNetTotal, numBNetOnline = bnFriendCounts()
    local numBNetOffline = numBNetTotal - numBNetOnline
    local numWoWTotal = C_FriendList.GetNumFriends()
    local numWoWOnline = C_FriendList.GetNumOnlineFriends()
    local numWoWOffline = numWoWTotal - numWoWOnline

    local numInvites = BNGetNumFriendInvites ~= nil and BNGetNumFriendInvites() or 0
    if numInvites > 0 then
        add(FRIENDS_BUTTON_TYPE_INVITE_HEADER, nil)
        if not GetCVarBool("friendInvitesCollapsed") then
            for i = 1, numInvites do
                add(FRIENDS_BUTTON_TYPE_INVITE, i)
            end
            if numBNetTotal + numWoWTotal > 0 then
                add(FRIENDS_BUTTON_TYPE_DIVIDER, nil)
            end
        end
    end
    for i = 1, numWoWOnline do
        add(FRIENDS_BUTTON_TYPE_WOW, i)
    end
    for i = 1, numBNetOnline do
        add(FRIENDS_BUTTON_TYPE_BNET, i)
    end
    if (numBNetOnline > 0 or numWoWOnline > 0) and (numBNetOffline > 0 or numWoWOffline > 0) then
        add(FRIENDS_BUTTON_TYPE_DIVIDER, nil)
    end
    for i = 1, numWoWOffline do
        add(FRIENDS_BUTTON_TYPE_WOW, i + numWoWOnline)
    end
    for i = 1, numBNetOffline do
        add(FRIENDS_BUTTON_TYPE_BNET, i + numBNetOnline)
    end
    return entries, offsets
end

local function wowFriendLabel(id)
    local info = C_FriendList.GetFriendInfoByIndex(id)
    if info == nil then
        return UNKNOWN
    end
    if info.connected then
        return info.name .. ", " .. string.format(FRIENDS_LEVEL_TEMPLATE, info.level, info.className)
    end
    return info.name
end

local function wowFriendStatus(id)
    local info = C_FriendList.GetFriendInfoByIndex(id)
    if info == nil then
        return nil
    end
    if not info.connected then
        return FRIENDS_LIST_OFFLINE
    end
    if info.afk then
        return L["Away"]
    end
    if info.dnd then
        return L["Busy"]
    end
    return nil
end

local function wowFriendInfo(id)
    local info = C_FriendList.GetFriendInfoByIndex(id)
    if info == nil or not info.connected then
        return nil
    end
    return info.area
end

local function wowFriendNote(id)
    local info = C_FriendList.GetFriendInfoByIndex(id)
    if info ~= nil and info.notes ~= nil and info.notes ~= "" then
        return L["Note"] .. " " .. info.notes
    end
    return nil
end

local function bnetFriendLabel(id)
    local _, accountName, battleTag, _, characterName, _, client, isOnline = BNGetFriendInfo(id)
    local label = accountName or battleTag or UNKNOWN
    if isOnline and characterName ~= nil and characterName ~= "" then
        label = label .. ", " .. characterName
    end
    if isOnline and client ~= nil and client ~= "" and client ~= BNET_CLIENT_WOW then
        label = label .. ", " .. client
    end
    return label
end

local function bnetFriendStatus(id)
    local _, _, _, _, _, _, _, isOnline, lastOnline, isAFK, isDND = BNGetFriendInfo(id)
    if not isOnline then
        if lastOnline == nil or lastOnline == 0 then
            return FRIENDS_LIST_OFFLINE
        end
        return string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnline))
    end
    if isAFK then
        return L["Away"]
    end
    if isDND then
        return L["Busy"]
    end
    return nil
end

local function bnetFriendInfo(id)
    local _, _, _, _, _, bnetIDGameAccount, client, isOnline = BNGetFriendInfo(id)
    if not isOnline or bnetIDGameAccount == nil then
        return nil
    end
    if client == BNET_CLIENT_WOW and C_BattleNet ~= nil and C_BattleNet.GetGameAccountInfoByID ~= nil then
        local gameInfo = C_BattleNet.GetGameAccountInfoByID(bnetIDGameAccount)
        if gameInfo ~= nil and gameInfo.areaName ~= nil and gameInfo.areaName ~= "" then
            return gameInfo.areaName
        end
    end
    return nil
end

local function bnetFriendNote(id)
    local _, _, _, _, _, _, _, _, _, _, _, messageText, noteText = BNGetFriendInfo(id)
    local parts = {}
    if noteText ~= nil and noteText ~= "" then
        tinsert(parts, L["Note"] .. " " .. noteText)
    end
    if messageText ~= nil and messageText ~= "" then
        tinsert(parts, messageText)
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ", ")
end

-- The pending-invite frames live in a released-and-reacquired pool; find
-- the active frame for an invite so its REAL buttons can be clicked
-- (proxied clicks run Blizzard's secure handlers -- calling the APIs
-- ourselves risks "addon action blocked").
local function inviteFrame(inviteIndex)
    local pool = FriendsFrameFriendsScrollFrame.invitePool
    if pool == nil then
        return nil
    end
    for frame in pool:EnumerateActive() do
        if frame.inviteIndex == inviteIndex then
            return frame
        end
    end
    return nil
end

-- Edge rows carry secure scroll bindings from the adapter (see
-- hybridScroll.lua's taint notes); every row splices them in.
local function withEdgeBindings(bindings, helpers)
    if helpers.edgeBindings ~= nil then
        for _, spec in ipairs(helpers.edgeBindings) do
            tinsert(bindings, spec)
        end
    end
    return bindings
end
friends.withEdgeBindings = withEdgeBindings

-- A friend row: Enter selects (Blizzard's left click), Backspace opens the
-- row's own dropdown menu (right click). Focusing any friend row clears
-- the contextual invite stops.
local function friendRow(entry, helpers, screen)
    local buttonType = entry.buttonType
    local id = entry.id
    local label, status, info, note
    if buttonType == FRIENDS_BUTTON_TYPE_WOW then
        label = function()
            return wowFriendLabel(id)
        end
        status = function()
            return wowFriendStatus(id)
        end
        info = function()
            return wowFriendInfo(id)
        end
        note = function()
            return wowFriendNote(id)
        end
    else
        label = function()
            return bnetFriendLabel(id)
        end
        status = function()
            return bnetFriendStatus(id)
        end
        info = function()
            return bnetFriendInfo(id)
        end
        note = function()
            return bnetFriendNote(id)
        end
    end
    return {
        controlType = graph.controlTypes.button,
        announcements = {
            { text = label, kind = kinds.label },
            { text = status, kind = kinds.value },
            { text = info, kind = kinds.value },
            { text = note, kind = kinds.value },
            {
                text = function()
                    if FriendsFrame.selectedFriendType == buttonType and FriendsFrame.selectedFriend == id then
                        return L["selected"]
                    end
                    return nil
                end,
                kind = kinds.selected,
            },
        },
        bindings = withEdgeBindings({
            { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
            { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
        }, helpers),
        onFocus = function()
            screen.focusedInvite = nil
            helpers.onFocus()
        end,
        onFocusTick = helpers.onFocusTick,
    }
end

-- A stable id per person: focus follows the friend, not the list slot, when
-- someone logging on or off reorders the list.
local function friendRowId(entry)
    if entry.buttonType == FRIENDS_BUTTON_TYPE_WOW then
        local info = C_FriendList.GetFriendInfoByIndex(entry.id)
        return ControlId.structural("friend:wow:" .. tostring(info ~= nil and info.name or entry.id))
    end
    local _, accountName, battleTag = BNGetFriendInfo(entry.id)
    return ControlId.structural("friend:bnet:" .. tostring(battleTag or accountName or entry.id))
end

local function renderFriendsList(builder, screen)
    local entries, offsets = friendEntries()

    -- Drop the contextual invite stops when their invite is gone.
    local numInvites = BNGetNumFriendInvites ~= nil and BNGetNumFriendInvites() or 0
    if screen.focusedInvite ~= nil and screen.focusedInvite > numInvites then
        screen.focusedInvite = nil
    end

    builder:beginStop("list")
    nodes.hybridScrollList(builder, {
        scrollFrame = FriendsFrameFriendsScrollFrame,
        key = "friends",
        label = FRIENDS_LIST,
        count = function()
            return #entries
        end,
        offsetOf = function(index)
            return offsets[index]
        end,
        tainted = true,
        -- Must mirror the ids emit assigns: the page-scroll focus snap
        -- looks rows up by this.
        id = function(index)
            local entry = entries[index]
            if entry == nil then
                return ControlId.structural("friends:" .. index)
            end
            if entry.buttonType == FRIENDS_BUTTON_TYPE_INVITE_HEADER then
                return ControlId.structural("friend:inviteHeader")
            end
            if entry.buttonType == FRIENDS_BUTTON_TYPE_INVITE then
                return ControlId.structural("friend:invite:" .. entry.id)
            end
            if entry.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER then
                return ControlId.structural("friends:divider:" .. index)
            end
            return friendRowId(entry)
        end,
        emit = function(b, index, helpers)
            local entry = entries[index]
            if entry == nil or entry.buttonType == FRIENDS_BUTTON_TYPE_DIVIDER then
                return
            end
            if entry.buttonType == FRIENDS_BUTTON_TYPE_INVITE_HEADER then
                -- The collapsible "Friend Requests (N)" header: Enter clicks
                -- Blizzard's real header button, which owns the toggle.
                b:addItem(ControlId.structural("friend:inviteHeader"), {
                    controlType = graph.controlTypes.button,
                    announcements = {
                        {
                            text = function()
                                local count = BNGetNumFriendInvites ~= nil and BNGetNumFriendInvites() or 0
                                return string.format(FRIEND_REQUESTS, count)
                            end,
                            kind = kinds.label,
                        },
                    },
                    bindings = withEdgeBindings({
                        {
                            binding = "leftClick",
                            type = "Click",
                            emulatedKey = "LeftButton",
                            target = function()
                                return FriendsFrameFriendsScrollFrame.PendingInvitesHeaderButton
                            end,
                        },
                    }, helpers),
                    onFocus = function()
                        screen.focusedInvite = nil
                        helpers.onFocus()
                    end,
                    onFocusTick = helpers.onFocusTick,
                })
                return
            end
            if entry.buttonType == FRIENDS_BUTTON_TYPE_INVITE then
                -- Focusing a request swaps the contextual stops to Accept
                -- and Decline (rendered after the list).
                local inviteIndex = entry.id
                b:addItem(ControlId.structural("friend:invite:" .. inviteIndex), {
                    controlType = graph.controlTypes.text,
                    announcements = {
                        {
                            text = function()
                                local inviteID, accountName = BNGetFriendInviteInfo(inviteIndex)
                                return L["Friend request"] .. " " .. tostring(accountName or inviteID or "")
                            end,
                            kind = kinds.label,
                        },
                    },
                    bindings = withEdgeBindings({}, helpers),
                    onFocus = function()
                        screen.focusedInvite = inviteIndex
                        helpers.onFocus()
                    end,
                    onFocusTick = helpers.onFocusTick,
                })
                return
            end
            b:addItem(friendRowId(entry), friendRow(entry, helpers, screen))
        end,
    })

    -- Contextual stops for the focused friend request: Tab reaches Accept,
    -- Tab again the Decline dropdown (decline, block, report). Both click
    -- the invite frame's REAL buttons.
    if screen.focusedInvite ~= nil then
        local inviteIndex = screen.focusedInvite
        local inviteName = function()
            local _, accountName = BNGetFriendInviteInfo(inviteIndex)
            return accountName
        end
        builder:beginStop("inviteAccept")
        builder:addItem(ControlId.structural("invite:accept"), {
            controlType = graph.controlTypes.button,
            announcements = {
                { text = ACCEPT, kind = kinds.label },
                { text = inviteName, kind = kinds.value },
            },
            bindings = {
                {
                    binding = "leftClick",
                    type = "Click",
                    emulatedKey = "LeftButton",
                    target = function()
                        local frame = inviteFrame(inviteIndex)
                        return frame ~= nil and frame.AcceptButton or nil
                    end,
                },
            },
        })
        builder:beginStop("inviteDecline")
        builder:addItem(ControlId.structural("invite:decline"), {
            controlType = graph.controlTypes.dropdown,
            announcements = {
                { text = DECLINE, kind = kinds.label },
                { text = inviteName, kind = kinds.value },
            },
            bindings = {
                {
                    binding = "leftClick",
                    type = "Click",
                    emulatedKey = "LeftButton",
                    target = function()
                        local frame = inviteFrame(inviteIndex)
                        return frame ~= nil and frame.DeclineButton or nil
                    end,
                },
            },
        })
    end

    builder:beginStop("controls")
    builder:pushContext("controls", L["Controls"])
    builder:startRow()
    builder:addItem(
        ControlId.forObject(FriendsFrameSendMessageButton),
        nodes.proxyButton({ target = FriendsFrameSendMessageButton })
    )
    builder:addItem(
        ControlId.forObject(FriendsFrameAddFriendButton),
        nodes.proxyButton({ target = FriendsFrameAddFriendButton })
    )
    local statusDropdown = FriendsTabHeader ~= nil and FriendsTabHeader.StatusDropdown or nil
    if statusDropdown ~= nil then
        local vtable = nodes.proxyDropdown({ target = statusDropdown, label = L["Status"] })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(statusDropdown), vtable)
        end
    end
    builder:endRow()
    builder:popContext()
end

-- ---------------------------------------------------------------------------
-- Ignore list (FauxScrollFrame, fixed button pool, inline section headers)
-- ---------------------------------------------------------------------------

local function renderIgnoreList(builder)
    local numIgnores = C_FriendList.GetNumIgnores()
    local numBlocks = BNGetNumBlocked ~= nil and BNGetNumBlocked() or 0
    local ignoredHeader = numIgnores > 0 and 1 or 0
    local blockedHeader = numBlocks > 0 and 1 or 0
    local lastIgnoredIndex = numIgnores + ignoredHeader
    local numEntries = lastIgnoredIndex + numBlocks + blockedHeader

    builder:beginStop("list")
    nodes.hybridScrollList(builder, {
        scrollFrame = FriendsFrameIgnoreScrollFrame,
        key = "ignore",
        label = IGNORE_LIST,
        tainted = true,
        id = function(index)
            if index == ignoredHeader and ignoredHeader == 1 then
                return ControlId.structural("ignore:header")
            end
            if blockedHeader == 1 and index == lastIgnoredIndex + 1 then
                return ControlId.structural("ignore:blockedHeader")
            end
            local name
            if index <= lastIgnoredIndex then
                name = C_FriendList.GetIgnoreName(index - ignoredHeader)
            else
                local _, blockName = BNGetBlockedInfo(index - lastIgnoredIndex - blockedHeader)
                name = blockName
            end
            return ControlId.structural("ignore:" .. tostring(name or UNKNOWN))
        end,
        rowHeight = FRIENDS_FRAME_IGNORE_HEIGHT,
        count = function()
            return numEntries
        end,
        buttons = function()
            local pool = {}
            for i = 1, IGNORES_TO_DISPLAY do
                pool[i] = _G["FriendsFrameIgnoreButton" .. i]
            end
            return pool
        end,
        indexOf = function(button)
            local slot = tonumber(button:GetName():match("%d+$"))
            return slot + FauxScrollFrame_GetOffset(FriendsFrameIgnoreScrollFrame)
        end,
        emit = function(b, index, helpers)
            -- Section headers occupy list slots, exactly like Blizzard.
            if index == ignoredHeader and ignoredHeader == 1 then
                b:addItem(ControlId.structural("ignore:header"), nodes.text({ label = IGNORE_LIST }))
                return
            end
            if blockedHeader == 1 and index == lastIgnoredIndex + 1 then
                b:addItem(ControlId.structural("ignore:blockedHeader"), nodes.text({ label = BLOCKED_INVITES or L["Blocked"] }))
                return
            end
            local label
            if index <= lastIgnoredIndex then
                local nameIndex = index - ignoredHeader
                label = function()
                    return C_FriendList.GetIgnoreName(nameIndex) or UNKNOWN
                end
            else
                local blockIndex = index - lastIgnoredIndex - blockedHeader
                label = function()
                    local _, blockName = BNGetBlockedInfo(blockIndex)
                    return blockName or UNKNOWN
                end
            end
            b:addItem(ControlId.structural("ignore:" .. tostring(label())), {
                controlType = graph.controlTypes.button,
                announcements = {
                    { text = label, kind = kinds.label },
                },
                bindings = withEdgeBindings({
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                    { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
                }, helpers),
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
            })
        end,
    })

    builder:beginStop("controls")
    builder:pushContext("controls", L["Controls"])
    builder:startRow()
    builder:addItem(
        ControlId.forObject(FriendsFrameIgnorePlayerButton),
        nodes.proxyButton({ target = FriendsFrameIgnorePlayerButton })
    )
    builder:addItem(
        ControlId.forObject(FriendsFrameUnsquelchButton),
        nodes.proxyButton({ target = FriendsFrameUnsquelchButton })
    )
    builder:endRow()
    builder:popContext()
end

-- ---------------------------------------------------------------------------
-- Who (FauxScrollFrame, search box, totals, sort dropdown)
-- ---------------------------------------------------------------------------

local function renderWho(builder)
    builder:beginStop("search")
    builder:addItem(
        ControlId.forObject(WhoFrameEditBox),
        nodes.proxyEditBox({ editBox = WhoFrameEditBox, label = L["Search"] })
    )

    local numWhos, totalCount = C_FriendList.GetNumWhoResults()
    builder:beginStop("list")
    nodes.hybridScrollList(builder, {
        scrollFrame = WhoListScrollFrame,
        key = "who",
        label = WHO_LIST,
        tainted = true,
        id = function(index)
            local info = C_FriendList.GetWhoInfo(index)
            return ControlId.structural("who:" .. tostring(info ~= nil and info.fullName or index))
        end,
        count = function()
            return numWhos
        end,
        buttons = function()
            local pool = {}
            for i = 1, WHOS_TO_DISPLAY do
                pool[i] = _G["WhoFrameButton" .. i]
            end
            return pool
        end,
        indexOf = function(button)
            return button.whoIndex
        end,
        emit = function(b, index, helpers)
            local function whoLabel()
                local info = C_FriendList.GetWhoInfo(index)
                if info == nil then
                    return UNKNOWN
                end
                local parts = { info.fullName }
                tinsert(parts, string.format(FRIENDS_LEVEL_TEMPLATE, info.level, info.classStr or ""))
                if info.raceStr ~= nil and info.raceStr ~= "" then
                    tinsert(parts, info.raceStr)
                end
                if info.area ~= nil and info.area ~= "" then
                    tinsert(parts, info.area)
                end
                if info.fullGuildName ~= nil and info.fullGuildName ~= "" then
                    tinsert(parts, info.fullGuildName)
                end
                return table.concat(parts, ", ")
            end
            local info = C_FriendList.GetWhoInfo(index)
            b:addItem(ControlId.structural("who:" .. tostring(info ~= nil and info.fullName or index)), {
                controlType = graph.controlTypes.button,
                announcements = {
                    { text = whoLabel, kind = kinds.label },
                    {
                        text = function()
                            if WhoFrame.selectedWho == index then
                                return L["selected"]
                            end
                            return nil
                        end,
                        kind = kinds.selected,
                    },
                },
                bindings = withEdgeBindings({
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                    { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
                }, helpers),
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
            })
        end,
    })

    builder:beginStop("controls")
    builder:pushContext("controls", L["Controls"])
    builder:addItem(
        ControlId.structural("who:totals"),
        nodes.text({ label = nodes.frameText(WhoFrameTotals) })
    )
    builder:startRow()
    builder:addItem(ControlId.forObject(WhoFrameWhoButton), nodes.proxyButton({ target = WhoFrameWhoButton }))
    builder:addItem(
        ControlId.forObject(WhoFrameAddFriendButton),
        nodes.proxyButton({ target = WhoFrameAddFriendButton })
    )
    builder:addItem(
        ControlId.forObject(WhoFrameGroupInviteButton),
        nodes.proxyButton({ target = WhoFrameGroupInviteButton })
    )
    if WhoFrameDropdown ~= nil then
        local vtable = nodes.proxyDropdown({ target = WhoFrameDropdown, label = L["Column"] })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(WhoFrameDropdown), vtable)
        end
    end
    builder:endRow()
    builder:popContext()
end

-- ---------------------------------------------------------------------------
-- The window: body first, then sub-tabs, then the main tab strip.
-- ---------------------------------------------------------------------------

local function addTabStrip(builder, config)
    builder:beginStop(config.stop)
    builder:pushContext(config.stop, L["Tabs"])
    builder:startRow()
    for i = 1, config.count do
        local tab = _G[config.prefix .. i]
        local tabIndex = i
        if tab ~= nil and tab:IsShown() then
            local vtable = nodes.proxyButton({ target = tab })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        if PanelTemplates_GetSelectedTab(config.frame) == tabIndex then
                            return L["selected"]
                        end
                        return nil
                    end,
                    kind = kinds.selected,
                })
                builder:addItem(ControlId.forObject(tab), vtable)
            end
        end
    end
    builder:endRow()
    builder:popContext()
end
friends.addTabStrip = addTabStrip

local function render(builder, screen)
    if FriendsFrame == nil or not FriendsFrame:IsShown() then
        return
    end
    builder:pushContext("friends", L["Friends"])

    if FriendsListFrame ~= nil and FriendsListFrame:IsShown() then
        renderFriendsList(builder, screen)
    elseif IgnoreListFrame ~= nil and IgnoreListFrame:IsShown() then
        renderIgnoreList(builder)
    elseif WhoFrame ~= nil and WhoFrame:IsShown() then
        renderWho(builder)
    elseif GuildFrame ~= nil and GuildFrame:IsShown() and friends.renderGuild ~= nil then
        friends.renderGuild(builder, screen)
    else
        builder:beginStop("body")
        builder:addItem(
            ControlId.structural("unsupported"),
            nodes.text({ label = L["This tab is not supported yet"] })
        )
    end

    -- The Friends/Ignore sub-tab strip, shown only on the Friends tab.
    if FriendsTabHeader ~= nil and FriendsTabHeader:IsShown() then
        addTabStrip(builder, {
            stop = "subtabs",
            prefix = "FriendsTabHeaderTab",
            frame = FriendsTabHeader,
            count = 2,
        })
    end

    addTabStrip(builder, {
        stop = "tabs",
        prefix = "FriendsFrameTab",
        frame = FriendsFrame,
        count = FRIEND_TAB_COUNT or 4,
    })

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "friends",
    frameName = "FriendsFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})
