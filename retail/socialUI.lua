local module = WowVision.base.windows:createModule("socialUI")
local L = module.L
module:setLabel(L["Social"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The Social window (SocialUIFrame, Blizzard_SocialUI, the same addon on
-- Retail and WoW: Forever): where the server turns it on
-- (C_SocialUI.IsSystemEnabled; Forever does), the friends key opens it in
-- place of the old friends window. Built and tested on Forever; Retail's
-- copy differs in small ways and has not been tried there yet. A Battle.net bar on top
-- (your BattleTag, status, the menu with broadcast and ignore list), the
-- shown tab's page, and the tabs down the right side (a row here, like every
-- tab strip): Friends, Recent Allies, Quick Join, Friend Requests, Recruit a
-- Friend, Raid. Forever has the old character friend list off, so its own
-- FriendsFrame build never shows.
--
-- The list pages share one frame (SocialUIContactsFrameTemplate): a search
-- box and filter, a list of cards under collapsible headers, and an action
-- button (Add Friend, Join). A card reads its name and status from its data
-- at once, then what the card shows (character, level, class, where, last
-- seen) as soon as it is on screen. Enter on a card is a left click
-- (select), Backspace a right click (the game's menu); the card's own
-- buttons (invite, summon, accept, decline) are in its context menu.
--
-- The side windows -- ignore list, broadcast, Battle.net notice, raid info --
-- and Add Friend are windows of their own. Recruit a Friend's page is not
-- read yet.

local plainText = nodes.plainText
local fontText = nodes.fontText

-- The first of several strings that has text: game strings can exist and be
-- empty on a client, which a plain "or" takes as a name.
local function firstText(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    return nil
end

local function selectedPart(isSelected)
    return {
        text = function()
            return isSelected() and L["selected"] or nil
        end,
        kind = kinds.selected,
        live = "focus",
    }
end

local function clickBindings(target)
    return {
        { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = target },
        { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = target },
    }
end

local function addProxy(builder, button, stopKey, label)
    if button == nil then
        return
    end
    local vtable = nodes.proxyButton({ target = button, label = label })
    if vtable ~= nil then
        if stopKey ~= nil then
            builder:beginStop(stopKey)
        end
        builder:addItem(ControlId.forObject(button), vtable)
    end
end

-- Every visible text of a frame and its non-button children, in creation
-- order: what a card shows. Buttons are left out (their actions are in the
-- context menu); repeats and the skipped label are dropped.
local function frameTexts(frame, skip)
    local out, seen = {}, {}
    if skip ~= nil then
        seen[skip] = true
    end
    local function walk(current)
        for _, region in ipairs({ current:GetRegions() }) do
            if region:GetObjectType() == "FontString" and region:IsVisible() then
                local text = plainText(region:GetText())
                if text ~= nil and not seen[text] then
                    seen[text] = true
                    tinsert(out, text)
                end
            end
        end
        for _, child in ipairs({ current:GetChildren() }) do
            if child:IsVisible() and not child:IsObjectType("Button") then
                walk(child)
            end
        end
    end
    walk(frame)
    if #out == 0 then
        return nil
    end
    return table.concat(out, ", ")
end

-- ---------------------------------------------------------------------------
-- Cards
-- ---------------------------------------------------------------------------

-- A group in Quick Join: the friends in it, then what it is queued for.
local function quickJoinLabel(entry)
    local names = {}
    for _, member in ipairs(entry.displayedMembers or {}) do
        local name = SocialQueueUtil_GetRelationshipInfo(member.guid, nil, member.clubId)
        tinsert(names, plainText(name) or UNKNOWN)
    end
    local parts = { table.concat(names, ", ") }
    for _, queue in ipairs(entry.displayedQueues or {}) do
        local queueName = SocialQueueUtil_GetQueueName(queue.queueData)
        if queueName ~= nil then
            tinsert(parts, plainText(queueName))
        end
    end
    if entry.CanJoin ~= nil and not entry:CanJoin() then
        tinsert(parts, L["Disabled"])
    end
    return table.concat(parts, ", ")
end

-- What a card is, from its data: { name, status, favorite } -- the parts a
-- sighted player gets from its name line and its status icons.
local function cardInfo(data)
    if data.accountInfo ~= nil then
        local accountInfo = data.accountInfo
        local presence = SocialUIUtil.GetPresenceTypeForBattleNetAccountInfo(accountInfo)
        return {
            name = plainText(FriendsListUtil.BuildFriendNameDisplayText(accountInfo)) or accountInfo.accountName,
            status = SocialUIUtil.GetLabelForPresenceType(presence),
            favorite = accountInfo.isFavorite and L["Favorite"] or nil,
        }
    end
    if data.inviteIndex ~= nil then
        local inviteInfo = C_BattleNet.GetFriendInviteInfo(data.inviteIndex)
        return { name = inviteInfo ~= nil and inviteInfo.accountName or nil }
    end
    if data.characterData ~= nil then
        local status
        if data.stateData ~= nil and RecentAlliesUtil ~= nil then
            local presence = RecentAlliesUtil.GetBestSocialUIPresenceTypeForStateData(data.stateData)
            status = SocialUIUtil.GetLabelForPresenceType(presence)
        end
        return { name = data.characterData.fullName or data.characterData.name, status = status }
    end
    if data.displayedMembers ~= nil then
        return { name = quickJoinLabel(data) }
    end
    return {}
end

local function cardKey(data, index)
    if data.accountInfo ~= nil then
        return "card:friend:" .. tostring(data.accountInfo.battleTag or data.friendIndex)
    end
    if data.inviteIndex ~= nil then
        local inviteInfo = C_BattleNet.GetFriendInviteInfo(data.inviteIndex)
        return "card:request:" .. tostring(inviteInfo ~= nil and inviteInfo.inviteID or data.inviteIndex)
    end
    if data.characterData ~= nil then
        return "card:ally:" .. tostring(data.characterData.guid or data.characterData.fullName or index)
    end
    if data.GetGUID ~= nil then
        return "card:group:" .. tostring(data:GetGUID())
    end
    return "card:" .. index
end

-- A card's own buttons, by the keys the card templates use, for its
-- context menu: invite (friends, recent allies), summon (Recruit a Friend),
-- accept and decline (friend requests; decline is a menu).
local CARD_BUTTONS = {
    { key = "PartyButton", label = function()
        return L["Invite"]
    end },
    { key = "RAFSummonButton", label = function()
        return L["Summon"]
    end },
    { key = "AcceptButton", label = function()
        return ACCEPT
    end },
    { key = "DeclineButton", label = function()
        return DECLINE
    end, menu = true },
}

local function cardButton(target, key)
    return function()
        local row = target()
        local child = row ~= nil and row[key] or nil
        if child ~= nil and child:IsShown() then
            return child
        end
        return nil
    end
end

local function emitCard(builder, node, data, index, helpers)
    local target = helpers.target
    local rowActions = nodes.proxyContextActions(target)
    builder:addItem(ControlId.structural(cardKey(data, index)), {
        controlType = graph.controlTypes.button,
        announcements = {
            {
                text = function()
                    return cardInfo(data).name or UNKNOWN
                end,
                kind = kinds.label,
            },
            {
                text = function()
                    return cardInfo(data).favorite
                end,
                kind = kinds.value,
            },
            {
                text = function()
                    return cardInfo(data).status
                end,
                kind = kinds.value,
            },
            -- The card's own lines, once it is on screen.
            {
                text = function()
                    local row = target()
                    if row == nil then
                        return nil
                    end
                    return frameTexts(row, cardInfo(data).name)
                end,
                kind = kinds.value,
                live = "focus",
            },
            selectedPart(function()
                -- Quick Join selects a group by its id, the other lists
                -- through their selection behavior.
                if data.GetGUID ~= nil then
                    local quickJoin = SocialUIFrame.QuickJoinFrame
                    return quickJoin ~= nil and quickJoin:GetSelectedGroup() == data:GetGUID()
                end
                return SelectionBehaviorMixin.IsElementDataIntrusiveSelected(node) == true
            end),
        },
        bindings = clickBindings(target),
        contextActions = function(add)
            for _, entry in ipairs(CARD_BUTTONS) do
                local button = cardButton(target, entry.key)
                if button() ~= nil then
                    if entry.menu then
                        add({
                            label = entry.label(),
                            onActivate = function()
                                local frame = button()
                                if frame ~= nil then
                                    nodes.openDropdown(frame)
                                end
                            end,
                        })
                    else
                        add({ label = entry.label(), click = { emulatedKey = "LeftButton", target = button } })
                    end
                end
            end
            rowActions(add)
        end,
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
        tooltipFrame = target,
    })
end

local function emitListElement(builder, element, index, helpers)
    -- Tree lists hand out nodes, Quick Join's linear list its entries.
    local data = element
    if type(element) == "table" and element.GetData ~= nil then
        data = element:GetData()
    end
    if type(data) ~= "table" or data.isSpacer then
        return
    end
    if data.headerText ~= nil then
        -- A header ("Friends (3/10)"): a left click folds its cards.
        builder:addItem(ControlId.structural("header:" .. tostring(data.headerType or data.headerText:gsub("%d", ""))), {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        return plainText(data.headerText)
                    end,
                    kind = kinds.label,
                },
                {
                    text = function()
                        if element.IsCollapsed == nil then
                            return nil
                        end
                        return element:IsCollapsed() and L["Collapsed"] or L["Expanded"]
                    end,
                    kind = kinds.value,
                    live = "focus",
                },
            },
            bindings = { { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target } },
            onFocus = helpers.onFocus,
            onFocusTick = helpers.onFocusTick,
            onUnfocus = helpers.onUnfocus,
        })
        return
    end
    local isCard = data.accountInfo ~= nil
        or data.inviteIndex ~= nil
        or data.characterData ~= nil
        or data.displayedMembers ~= nil
    if isCard then
        emitCard(builder, element, data, index, helpers)
    end
end

-- A list page: search box and filter, a notice where the page shows one
-- (Battle.net down, loading), the list, the action button.
local function renderContacts(builder, frame, title)
    local filterBar = frame.FilterBar
    if filterBar ~= nil and filterBar:IsShown() then
        builder:beginStop("filterBar")
        builder:pushContext("filterBar", SEARCH)
        builder:startRow()
        if filterBar.SearchBar ~= nil and filterBar.SearchBar:IsShown() then
            builder:addItem(
                ControlId.forObject(filterBar.SearchBar),
                nodes.proxyEditBox({ editBox = filterBar.SearchBar, label = SEARCH })
            )
        end
        local filter = filterBar.SearchFilterDropdown
        if filter ~= nil then
            local vtable = nodes.proxyDropdown({ target = filter, label = FILTER })
            if vtable ~= nil then
                builder:addItem(ControlId.forObject(filter), vtable)
            end
        end
        builder:endRow()
        builder:popContext()
    end

    for _, notice in ipairs({ frame.FriendsDisabledText }) do
        if notice ~= nil and notice:IsShown() then
            builder:beginStop("notice")
            builder:addItem(ControlId.forObject(notice), nodes.text({ label = fontText(notice) }))
        end
    end
    if frame.LoadingSpinner ~= nil and frame.LoadingSpinner:IsShown() then
        builder:beginStop("loading")
        builder:addItem(ControlId.structural("loading"), nodes.text({ label = L["Loading"] }))
    end

    -- The friend requests page warns once about Real ID requests.
    local warning = frame.RealIDWarning
    if warning ~= nil and warning:IsShown() then
        builder:beginStop("realIDWarning")
        builder:addItem(
            ControlId.structural("realIDWarning"),
            nodes.text({ label = SOCIAL_UI_FRIEND_REQUESTS_REAL_ID_WARNING })
        )
        addProxy(builder, warning.ContinueButton, "realIDContinue")
    end

    if frame.ScrollBox ~= nil and frame.ScrollBox:IsShown() then
        -- A fresh open lands on the list.
        builder:beginStop("list")
        builder:setStartStop("list")
        nodes.scrollBoxList(builder, {
            scrollBox = frame.ScrollBox,
            key = "list",
            label = title,
            emit = emitListElement,
        })
    end

    addProxy(builder, frame.ActionButton, "actionButton")
end

-- ---------------------------------------------------------------------------
-- Raid tab
-- ---------------------------------------------------------------------------

local function raidMemberLabel(index)
    local name, rank, _, level, class, _, zone, online, isDead, role = GetRaidRosterInfo(index)
    if name == nil then
        return UNKNOWN
    end
    local parts = { name }
    if level ~= nil and level > 0 then
        tinsert(parts, format(FRIENDS_LEVEL_TEMPLATE, level, class or ""))
    end
    if rank == 2 then
        tinsert(parts, RAID_LEADER)
    elseif rank == 1 then
        tinsert(parts, RAID_ASSISTANT)
    end
    if role == "MAINTANK" then
        tinsert(parts, MAIN_TANK)
    elseif role == "MAINASSIST" then
        tinsert(parts, MAIN_ASSIST)
    end
    if not online then
        tinsert(parts, FRIENDS_LIST_OFFLINE)
    elseif isDead then
        tinsert(parts, DEAD)
    end
    if zone ~= nil and zone ~= "" then
        tinsert(parts, zone)
    end
    return table.concat(parts, ", ")
end

-- In a raid: the role counts, then each group with its members (Enter
-- targets, Backspace opens the player menu; moving members between groups
-- is drag and drop and left out). Not in a raid: the game's description
-- and Convert to Raid. Everyone is assistant and Raid Info either way.
local function renderRaid(builder, frame)
    if IsInRaid() then
        local counts = {}
        for _, entry in ipairs({
            { frame = frame.TankFrame, label = TANK },
            { frame = frame.HealerFrame, label = HEALER },
            { frame = frame.DamagerFrame, label = DAMAGER },
        }) do
            if entry.frame ~= nil and entry.frame.Count ~= nil then
                tinsert(counts, tostring(entry.label) .. " " .. tostring(entry.frame.Count:GetText() or 0))
            end
        end
        if #counts > 0 then
            builder:beginStop("roleCounts")
            builder:addItem(ControlId.structural("raid:roles"), nodes.text({ label = table.concat(counts, ", ") }))
        end

        builder:beginStop("raidGroups")
        for _, group in ipairs(frame.groups or {}) do
            local members = {}
            for _, player in ipairs(frame.players or {}) do
                if player.subgroup == group.id and player:IsShown() then
                    tinsert(members, player)
                end
            end
            if #members > 0 then
                builder:pushContext("raidGroup:" .. tostring(group.id), format(GROUP_NUMBER, group.id))
                for _, player in ipairs(members) do
                    local captured = player
                    builder:addItem(ControlId.structural("raid:" .. tostring(player.name or player.id)), {
                        controlType = graph.controlTypes.button,
                        announcements = {
                            {
                                text = function()
                                    return raidMemberLabel(captured.id)
                                end,
                                kind = kinds.label,
                            },
                        },
                        bindings = clickBindings(player),
                        contextActions = function(add)
                            add({ label = L["Left Click"], click = { emulatedKey = "LeftButton", target = captured } })
                            add({ label = L["Right Click"], click = { emulatedKey = "RightButton", target = captured } })
                        end,
                    })
                end
                builder:popContext()
            end
        end
    elseif frame.RaidDescription ~= nil then
        builder:beginStop("raidDescription")
        builder:addItem(ControlId.structural("raid:description"), nodes.text({ label = fontText(frame.RaidDescription) }))
    end

    builder:beginStop("raidControls")
    builder:pushContext("raidControls", L["Controls"])
    builder:startRow()
    local allAssist = frame.AllAssistCheckButton
    if allAssist ~= nil and allAssist:IsShown() then
        builder:addItem(
            ControlId.forObject(allAssist),
            nodes.proxyCheckButton({ target = allAssist, label = fontText(allAssist.text or allAssist.Text) })
        )
    end
    for _, button in ipairs({ frame.ConvertToRaidButton, frame.RaidInfoButton }) do
        addProxy(builder, button)
    end
    builder:endRow()
    builder:popContext()
end

-- ---------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------

local function renderBattleNetBar(builder, frame)
    local container = frame.BattleNetBar ~= nil and frame.BattleNetBar.ControlsContainer or nil
    if container == nil or not container:IsShown() then
        return
    end
    builder:beginStop("battlenet")
    builder:pushContext("battlenet", L["Battle.net"])
    builder:startRow()
    local display = container.PersonalBattleTagDisplay
    if display ~= nil and display:IsShown() then
        if display.DisplayText ~= nil and display.DisplayText:IsShown() then
            builder:addItem(ControlId.structural("battlenet:tag"), nodes.text({ label = fontText(display.DisplayText) }))
        end
        addProxy(builder, display.CopyBattleTagToClipboardButton, nil, L["Copy BattleTag"])
        addProxy(builder, display.BattleNetUnavailableNoticeButton, nil, BATTLENET_UNAVAILABLE)
    end
    local status = container.OnlineStatusDropdown
    if status ~= nil then
        local vtable = nodes.proxyDropdown({
            target = status,
            label = function()
                return nodes.joinLabel(L["Status"], SocialUIUtil.GetLabelForPresenceType(status.presenceTypeSelf))
            end,
        })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(status), vtable)
        end
    end
    local menu = container.BattleNetMenuButton
    if menu ~= nil then
        -- Named by its tooltip, whose string is empty on the Forever client.
        -- Not "Battle.net": a control named like its bar drops its name.
        local vtable = nodes.proxyDropdown({
            target = menu,
            label = firstText(SOCIAL_UI_BATTLE_NET_BAR_MENU_BUTTON_LABEL, CONTACTS_MENU_NAME) or L["Menu"],
        })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(menu), vtable)
        end
    end
    builder:endRow()
    builder:popContext()
end

-- The tabs down the side: icons whose names are their tooltips, with a
-- count where the tab shows one (Quick Join's groups).
local function renderTabs(builder, frame)
    if frame.socialTabPool == nil then
        return
    end
    local tabs = {}
    for tab in frame.socialTabPool:EnumerateActive() do
        if tab.tabData ~= nil then
            tinsert(tabs, tab)
        end
    end
    table.sort(tabs, function(a, b)
        return (a.tabData.tabOrder or 0) < (b.tabData.tabOrder or 0)
    end)
    -- A row, like every tab strip, though the game draws these down the side.
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for _, tab in ipairs(tabs) do
        local captured = tab
        local tabType = tab.tabData.tabType
        builder:addItem(ControlId.structural("tab:" .. tostring(tabType)), {
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        return captured.tabData ~= nil and captured.tabData.tabName or nil
                    end,
                    kind = kinds.label,
                },
                {
                    text = function()
                        return captured.Count ~= nil and captured.Count:IsShown() and plainText(captured.Count:GetText())
                            or nil
                    end,
                    kind = kinds.value,
                },
                selectedPart(function()
                    return frame:GetSelectedTab() == tabType
                end),
                {
                    text = function()
                        if captured:IsEnabled() then
                            return nil
                        end
                        return nodes.joinLabel(L["Disabled"], captured.disabledReason)
                    end,
                    kind = kinds.enabled,
                },
            },
            bindings = { { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = captured } },
        })
    end
    builder:endRow()
    builder:popContext()
end

local function render(builder, screen)
    local frame = SocialUIFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    local title = frame.GetTitleText ~= nil and plainText(frame:GetTitleText():GetText()) or nil
    builder:pushContext("social", title or L["Social"])
    renderBattleNetBar(builder, frame)

    local content = frame.activeContentFrame
    if content ~= nil and content:IsShown() then
        if content == frame.RaidFrame then
            renderRaid(builder, content)
        elseif content.ScrollBox ~= nil then
            renderContacts(builder, content, title)
        else
            builder:beginStop("body")
            builder:addItem(ControlId.structural("unsupported"), nodes.text({ label = L["This tab is not supported yet"] }))
        end
    end

    renderTabs(builder, frame)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "socialUI",
    frameName = "SocialUIFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})

-- ---------------------------------------------------------------------------
-- Side windows: frames without global names on SocialUIFrame, looked up
-- when polled.
-- ---------------------------------------------------------------------------

local function sideWindow(key)
    local frame = SocialUIFrame
    return frame ~= nil and frame[key] or nil
end

local function registerSideWindow(name, key, render)
    module:registerWindow({
        type = "CustomWindow",
        name = name,
        isOpen = function()
            local window = sideWindow(key)
            return window ~= nil and window:IsVisible()
        end,
        conflictingAddons = { "Sku" },
        graphScreen = { render = render },
    })
end

-- The ignore list: ignored players and blocked Battle.net invites under
-- their headers; Ignore (the target, or a name), Remove for the selection.
local function blockedName(data)
    if data.blockType == Enum.SocialUIBlockType.Ignore then
        return C_FriendList.GetIgnoreName(data.blockIndex)
    end
    local _, blockName = BNGetBlockedInfo(data.blockIndex)
    return blockName
end

local function renderIgnoreList(builder, screen)
    local window = sideWindow("IgnoreListFrame")
    if window == nil or not window:IsShown() then
        return
    end
    builder:pushContext("ignoreList", plainText(window:GetTitleText():GetText()) or IGNORE_LIST)
    builder:beginStop("blocked")
    nodes.scrollBoxList(builder, {
        scrollBox = window.ScrollBox,
        key = "blocked",
        id = function(data, index)
            if data.headerText ~= nil then
                return ControlId.structural("blocked:header:" .. data.headerText)
            end
            return ControlId.structural("blocked:" .. tostring(data.blockType) .. ":" .. tostring(blockedName(data) or index))
        end,
        emit = function(b, data, index, helpers)
            if data.headerText ~= nil then
                b:addItem(helpers.id, nodes.text({ label = plainText(data.headerText) }))
                return
            end
            b:addItem(helpers.id, {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return blockedName(data) or UNKNOWN
                        end,
                        kind = kinds.label,
                    },
                    selectedPart(function()
                        return window.selectionBehavior ~= nil and window.selectionBehavior:IsElementDataSelected(data)
                    end),
                },
                bindings = clickBindings(helpers.target),
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
            })
        end,
    })
    addProxy(builder, window.BlockButton, "block")
    addProxy(builder, window.UnblockButton, "unblock")
    builder:popContext()
end

registerSideWindow("socialIgnoreList", "IgnoreListFrame", renderIgnoreList)

-- The broadcast box: the message friends see under your name.
local function renderBroadcast(builder, screen)
    local window = sideWindow("BattleNetBroadcastFrame")
    if window == nil or not window:IsShown() then
        return
    end
    local title = window.Title ~= nil and plainText(window.Title:GetText()) or nil
    builder:pushContext("broadcast", title or L["Battle.net"])
    builder:beginStop("broadcastText")
    builder:addItem(ControlId.forObject(window.EditBox), nodes.proxyEditBox({ editBox = window.EditBox, label = title }))
    addProxy(builder, window.UpdateButton, "update")
    addProxy(builder, window.CancelButton, "cancel")
    builder:popContext()
end

registerSideWindow("socialBroadcast", "BattleNetBroadcastFrame", renderBroadcast)

-- The Battle.net notice (the info button when Battle.net is down).
local function renderUnavailable(builder, screen)
    local window = sideWindow("BattleNetUnavailableNoticeFrame")
    if window == nil or not window:IsShown() then
        return
    end
    builder:pushContext("unavailable", BATTLENET_UNAVAILABLE)
    builder:beginStop("unavailableText")
    for _, text in ipairs({ window.HeaderText, window.Text }) do
        if text ~= nil and text:IsShown() then
            builder:addItem(ControlId.forObject(text), nodes.text({ label = fontText(text) }))
        end
    end
    builder:popContext()
end

registerSideWindow("socialUnavailable", "BattleNetUnavailableNoticeFrame", renderUnavailable)

-- Raid info: saved instances and world bosses with difficulty and time to
-- reset; Extend for the selection.
local function savedLabel(data)
    local name, reset, difficulty, locked, extended
    if data.isInstance then
        local instanceName, _, instanceReset, _, instanceLocked, instanceExtended, _, _, _, difficultyName =
            GetSavedInstanceInfo(data.index)
        name, reset, difficulty, locked, extended =
            instanceName, instanceReset, difficultyName, instanceLocked, instanceExtended
    else
        local bossName, _, bossReset = GetSavedWorldBossInfo(data.index)
        name, reset, difficulty, locked, extended = bossName, bossReset, RAID_INFO_WORLD_BOSS, true, false
    end
    local parts = { name or UNKNOWN }
    if difficulty ~= nil and difficulty ~= "" then
        tinsert(parts, difficulty)
    end
    if locked or extended then
        tinsert(parts, SecondsToTime(reset or 0, true, nil, 3))
    else
        tinsert(parts, RAID_INSTANCE_EXPIRES_EXPIRED)
    end
    if extended then
        tinsert(parts, EXTENDED or L["Extended"])
    end
    return table.concat(parts, ", ")
end

local function renderRaidInfo(builder, screen)
    local window = sideWindow("RaidInfoFrame")
    if window == nil or not window:IsShown() then
        return
    end
    builder:pushContext("raidInfo", RAID_INFO)
    builder:beginStop("saved")
    nodes.scrollBoxList(builder, {
        scrollBox = window.ScrollBox,
        key = "saved",
        id = function(data, index)
            return ControlId.structural("saved:" .. tostring(data.isInstance) .. ":" .. tostring(data.index))
        end,
        row = function(data, index, helpers)
            return {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return savedLabel(data)
                        end,
                        kind = kinds.label,
                    },
                    selectedPart(function()
                        return window.selectedIndex == data.index and window.selectedIsInstance == data.isInstance
                    end),
                },
                bindings = clickBindings(helpers.target),
                contextActions = nodes.proxyContextActions(helpers.target),
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
                tooltipFrame = helpers.target,
            }
        end,
    })
    addProxy(builder, window.ExtendButton, "extend")
    addProxy(builder, window.CloseButton, "close", CLOSE)
    builder:popContext()
end

registerSideWindow("socialRaidInfo", "RaidInfoFrame", renderRaidInfo)

-- ---------------------------------------------------------------------------
-- Add Friend (AddFriendFrame, the Add Friend button on the list pages): the
-- name or BattleTag box, Send Request and Cancel; the first time, an info
-- page with Okay comes first.
-- ---------------------------------------------------------------------------

-- Every visible text under a frame, one line each, walking nested
-- containers (the dialog's explanations sit two or three levels down).
local function addTexts(builder, frame, prefix)
    local index = 0
    local function walk(current)
        for _, region in ipairs({ current:GetRegions() }) do
            if region:GetObjectType() == "FontString" and region:IsVisible() and plainText(region:GetText()) ~= nil then
                index = index + 1
                builder:addItem(ControlId.structural(prefix .. index), nodes.text({ label = fontText(region) }))
            end
        end
        for _, child in ipairs({ current:GetChildren() }) do
            if child:IsVisible() and not child:IsObjectType("Button") and not child:IsObjectType("EditBox") then
                walk(child)
            end
        end
    end
    walk(frame)
end

local function renderAddFriend(builder, screen)
    local frame = AddFriendFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("addFriend", ADD_FRIEND)
    local entry = frame.EntryFrame
    local info = frame.InfoFrame
    if entry ~= nil and entry:IsShown() then
        -- The name box, Send Request, Cancel and the messages sit in the
        -- entry page's EditBoxContainer; the page above them explains what
        -- a BattleTag and a character name each add.
        local container = entry.EditBoxContainer
        local editBox = container ~= nil and container.NameEditBox or AddFriendNameEditBox
        if editBox ~= nil then
            builder:beginStop("name")
            builder:addItem(
                ControlId.forObject(editBox),
                nodes.proxyEditBox({ editBox = editBox, label = ENTER_CHARACTER_NAME_OR_BATTLETAG })
            )
        end
        if container ~= nil then
            for _, text in ipairs({ container.ErrorMessage, container.RequestInfoText }) do
                if text ~= nil and text:IsShown() then
                    builder:beginStop("text:" .. tostring(text:GetParentKey()))
                    builder:addItem(ControlId.forObject(text), nodes.text({ label = fontText(text) }))
                end
            end
            addProxy(builder, container.AcceptButton, "accept")
            addProxy(builder, container.CancelButton, "cancel")
        end
        if entry.OptionsContainer ~= nil and entry.OptionsContainer:IsShown() then
            builder:beginStop("options")
            addTexts(builder, entry.OptionsContainer, "options:")
        end
    elseif info ~= nil and info:IsShown() then
        builder:beginStop("info")
        addTexts(builder, info, "info:")
        addProxy(builder, info.OkayButton, "okay")
    end
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "addFriend",
    frameName = "AddFriendFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderAddFriend },
})

-- ---------------------------------------------------------------------------
-- Friend request confirmation (BattleNetInviteFrame, Blizzard_AddFriend): a
-- unit menu's Add Friend row on a Battle.net account is a submenu (Send
-- BattleTag Request, Add WoW Friend; Forever has no character friend row).
-- Picking one closes the menu and asks the server, which answers with this
-- dialog: the kind of request, the player's name, what the other side sees,
-- then Send Request and Cancel. Nothing is sent until Send Request. It is
-- shown with StaticPopupSpecial_Show, so the popups window never sees it;
-- Escape cancels, as in the game.
-- ---------------------------------------------------------------------------

local function renderBattleNetInvite(builder, screen)
    local frame = BattleNetInviteFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    local title = frame.InviteText ~= nil and plainText(frame.InviteText:GetText()) or nil
    builder:pushContext("battleNetInvite", title or ADD_FRIEND)
    builder:beginStop("text")
    for _, key in ipairs({ "InviteeName", "InfoText" }) do
        local text = frame[key]
        if text ~= nil and text:IsShown() and plainText(text:GetText()) ~= nil then
            builder:addItem(ControlId.structural("battleNetInvite:" .. key), nodes.text({ label = fontText(text) }))
        end
    end
    addProxy(builder, frame.SendButton, "send")
    addProxy(builder, frame.CancelButton, "cancel")
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "battleNetInvite",
    frameName = "BattleNetInviteFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderBattleNetInvite },
})
