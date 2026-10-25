local module = WowVision.base.windows:createModule("communities")
local L = module.L
module:setLabel(L["Guild and Communities"])

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local secrets = WowVision.secrets

-- The guild and communities window (CommunitiesFrame, Blizzard_Communities):
-- the same window on Retail and WoW: Forever, opened by the guild key. On the
-- left the list of guilds and communities (and the finder entries), in the
-- middle the page the side tabs pick, down the right side the tabs: Chat,
-- Roster, Guild Benefits, Guild Info, Preferred Play (a row here, like every
-- tab strip). The buttons along the bottom follow the page: Invite, Guild
-- Control, Guild Recruitment, Community Settings, View Log; then Maximize or
-- Minimize.
--
-- Pages:
-- - Chat: the channel dropdown, the latest messages, the chat box (the
--   game's own: Enter in it sends), the short member list.
-- - Roster: the column dropdown, the sort headers, every member with level,
--   class, where, rank and note as the columns show them; Show Offline.
-- - Guild Info: challenges, message of the day, guild information with
--   their edit buttons, the news list and its filters.
-- - Guild Benefits: perks, rewards, the reputation bar.
-- - An invitation to a community shown in the window: its lines, Accept,
--   Decline.
-- The guild and community finder, the applicant lists and the preferred play
-- settings are not read yet.
--
-- Everything goes through the game: a left click on a club selects it, a
-- left click on a member opens the guild member card (a window of its own
-- here), a right click opens the game's menu for a club or a member. The
-- side windows -- member card, the edit box for the message of the day and
-- the guild information, the event log, the news filters -- are windows of
-- their own below.
--
-- Member, club and message fields can be secret on these clients (the
-- club API hides them in chat messaging lockdown): labels never compare or
-- format a secret, they pass it through to speech or leave the part out.

local plainText = nodes.plainText
local fontText = nodes.fontText

-- Display text as speech, links reduced to their text the way the chat
-- reader does it (news, chat and invitation lines carry item and player
-- links). A secret passes through as it is.
local function speechText(text)
    if text == nil then
        return nil
    end
    if secrets.isSecret(text) then
        return text
    end
    return plainText(WowVision.chatLinks.plainText(tostring(text)))
end

-- Comma-joined parts, skipping nil, false and empty ones; carries secret
-- strings (joinLabel's table.concat refuses them).
local function join(...)
    local out = {}
    for i = 1, select("#", ...) do
        local part = select(i, ...)
        if part ~= nil and part ~= false and secrets.hasText(part) then
            tinsert(out, part)
        end
    end
    if #out == 0 then
        return nil
    end
    return secrets.join(out, ", ")
end

-- value == expected, false for a secret (a secret cannot be compared).
local function is(value, expected)
    if value == nil or secrets.isSecret(value) then
        return false
    end
    return value == expected
end

-- A label built from game data, or the fallback when a part of the data
-- refuses (a secret where a number was formatted).
local function safeLabel(build, fallback)
    local ok, label = pcall(build)
    if ok and label ~= nil then
        return label
    end
    return fallback
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

local function addDropdown(builder, dropdown, label)
    if dropdown == nil then
        return
    end
    local vtable = nodes.proxyDropdown({ target = dropdown, label = label })
    if vtable ~= nil then
        builder:addItem(ControlId.forObject(dropdown), vtable)
    end
end

-- A font string as a line when it shows text.
local function addFontLine(builder, key, fontString)
    if fontString ~= nil and fontString:IsShown() and speechText(fontString:GetText()) ~= nil then
        builder:addItem(
            ControlId.structural(key),
            nodes.text({
                label = function()
                    return speechText(fontString:GetText())
                end,
            })
        )
    end
end

-- Every visible text under a frame, one line each, walking nested frames
-- but not buttons (they are added as controls).
local function addTexts(builder, frame, prefix)
    local index = 0
    local function walk(current)
        for _, region in ipairs({ current:GetRegions() }) do
            local isText = region:GetObjectType() == "FontString" and region:IsVisible()
            if isText and speechText(region:GetText()) ~= nil then
                index = index + 1
                local captured = region
                builder:addItem(
                    ControlId.structural(prefix .. index),
                    nodes.text({
                        label = function()
                            return speechText(captured:GetText())
                        end,
                    })
                )
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

local function unsupported(builder, key)
    builder:beginStop(key)
    builder:addItem(ControlId.structural(key), nodes.text({ label = L["This tab is not supported yet"] }))
end

-- ---------------------------------------------------------------------------
-- Members
-- ---------------------------------------------------------------------------

local function presenceText(presence)
    local presences = Enum.ClubMemberPresence
    if is(presence, presences.Away) then
        return L["Away"]
    elseif is(presence, presences.Busy) then
        return L["Busy"]
    elseif is(presence, presences.OnlineMobile) then
        return COMMUNITIES_PRESENCE_MOBILE_CHAT
    elseif is(presence, presences.Offline) then
        return L["Offline"]
    end
    return nil
end

local function roleName(role)
    if role == nil or secrets.isSecret(role) or COMMUNITY_MEMBER_ROLE_NAMES == nil then
        return nil
    end
    return COMMUNITY_MEMBER_ROLE_NAMES[role]
end

-- The leader and moderator marks the short list shows as icons.
local function roleMark(role)
    local roles = Enum.ClubRoleIdentifier
    if is(role, roles.Owner) or is(role, roles.Leader) or is(role, roles.Moderator) then
        return roleName(role)
    end
    return nil
end

local function className(classID)
    if classID == nil or secrets.isSecret(classID) then
        return nil
    end
    local classInfo = C_CreatureInfo.GetClassInfo(classID)
    return classInfo ~= nil and classInfo.className or nil
end

-- What the roster's zone column shows: mobile, last online, or the zone.
local function whereText(info)
    local presences = Enum.ClubMemberPresence
    if is(info.presence, presences.OnlineMobile) then
        return COMMUNITIES_PRESENCE_MOBILE_CHAT
    end
    if is(info.presence, presences.Offline) then
        if info.lastOnlineYear ~= nil then
            return TimeUtil.GetRecentTimeDate(
                info.lastOnlineYear,
                info.lastOnlineMonth,
                info.lastOnlineDay,
                info.lastOnlineHour
            )
        end
        return COMMUNITIES_PRESENCE_OFFLINE
    end
    return info.zone
end

-- The extra guild column the roster dropdown picks (achievement points,
-- dungeon score); the profession column only shows a link, left out.
local EXTRA_COLUMN_FIELDS = { [1] = "achievementPoints", [5] = "overallDungeonScore" }

local function memberLabel(info, expanded, clubInfo, extraColumn)
    return safeLabel(function()
        if not expanded then
            return join(info.name, roleMark(info.role), presenceText(info.presence))
        end
        local clubTypes = Enum.ClubType
        local isBattleNet = clubInfo ~= nil and is(clubInfo.clubType, clubTypes.BattleNet)
        local isGuild = clubInfo == nil or is(clubInfo.clubType, clubTypes.Guild)
        local level = nil
        if not isBattleNet and info.level ~= nil then
            level = format(FRIENDS_LEVEL_TEMPLATE, info.level, className(info.classID) or "")
        end
        local where = isBattleNet and presenceText(info.presence) or whereText(info)
        local rank = isGuild and info.guildRank or roleName(info.role)
        local extraField = extraColumn ~= nil and EXTRA_COLUMN_FIELDS[extraColumn] or nil
        local extra = extraField ~= nil and info[extraField] or nil
        return join(info.name, level, where, rank, info.memberNote, extra)
    end, info.name or RETRIEVING_DATA)
end

local function professionName(info)
    return safeLabel(function()
        return info.professionHeaderName or C_TradeSkillUI.GetTradeSkillDisplayName(info.professionHeaderId)
    end, UNKNOWN)
end

local function emitMember(builder, data, index, helpers, frame, expanded)
    local list = frame.MemberList
    local target = helpers.target
    local common = {
        onFocus = helpers.onFocus,
        onFocusTick = helpers.onFocusTick,
        onUnfocus = helpers.onUnfocus,
    }
    local function vtable(fields)
        for key, value in pairs(common) do
            fields[key] = value
        end
        return fields
    end

    if data.invitationHeaderCount ~= nil then
        builder:addItem(
            helpers.id,
            nodes.text({
                label = safeLabel(function()
                    return format(COMMUNITIES_MEMBER_LIST_PENDING_INVITE_HEADER, data.invitationHeaderCount)
                end, nil) or "",
            })
        )
        return
    end

    if data.invitationInfo ~= nil then
        -- A pending invitation: the row takes no clicks; its Cancel button
        -- is in the context menu.
        local invitee = data.invitationInfo.invitee or {}
        builder:addItem(
            helpers.id,
            vtable({
                controlType = graph.controlTypes.text,
                announcements = { { text = invitee.name or RETRIEVING_DATA, kind = kinds.label } },
                contextActions = function(add)
                    add({
                        label = CANCEL,
                        click = {
                            emulatedKey = "LeftButton",
                            target = function()
                                local row = target()
                                return row ~= nil and row.CancelInvitationButton or nil
                            end,
                        },
                    })
                end,
            })
        )
        return
    end

    local info = data.memberInfo
    if info == nil then
        return
    end
    if info.professionHeaderId ~= nil then
        -- A profession heading of the profession column: a click folds it.
        local header = function()
            local row = target()
            return row ~= nil and row.ProfessionHeader or nil
        end
        builder:addItem(
            helpers.id,
            vtable({
                controlType = graph.controlTypes.button,
                announcements = {
                    { text = professionName(info), kind = kinds.label },
                    {
                        text = function()
                            local row = target()
                            local collapsed = info.professionHeaderCollapsed
                            if row ~= nil and row.isCollapsed ~= nil then
                                collapsed = row.isCollapsed
                            end
                            return collapsed and L["Collapsed"] or L["Expanded"]
                        end,
                        kind = kinds.value,
                        live = "focus",
                    },
                },
                bindings = { { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = header } },
                contextActions = function(add)
                    local headerFrame = header()
                    local allRecipes = headerFrame ~= nil and headerFrame.AllRecipes or nil
                    if allRecipes ~= nil and allRecipes:IsShown() then
                        add({
                            label = GUILD_VIEW_ALL_RECIPES_LINK,
                            click = { emulatedKey = "LeftButton", target = allRecipes },
                        })
                    end
                end,
            })
        )
        return
    end

    builder:addItem(
        helpers.id,
        vtable({
            controlType = graph.controlTypes.button,
            announcements = {
                {
                    text = function()
                        local clubInfo = list.GetSelectedClubInfo ~= nil and list:GetSelectedClubInfo() or nil
                        local extra = list.GetGuildColumnIndex ~= nil and list:GetGuildColumnIndex() or nil
                        return memberLabel(info, expanded, clubInfo, extra)
                    end,
                    kind = kinds.label,
                },
            },
            -- Left: the guild member card (guilds) or the recipes of a
            -- member under a profession; right: the player menu.
            bindings = clickBindings(target),
            contextActions = nodes.proxyContextActions(target),
            tooltipFrame = target,
        })
    )
end

local function renderMemberList(builder, frame, expanded)
    local list = frame.MemberList
    if list == nil or not list:IsShown() or list.ScrollBox == nil then
        return
    end
    builder:beginStop("memberHeader")
    addFontLine(builder, "memberCount", list.MemberCount)
    local showOffline = list.ShowOfflineButton
    if showOffline ~= nil and showOffline:IsShown() then
        builder:addItem(
            ControlId.forObject(showOffline),
            nodes.proxyCheckButton({ target = showOffline, label = fontText(showOffline.Text) })
        )
    end

    -- The roster's column headers: a click sorts by that column.
    local columns = list.ColumnDisplay
    if expanded and columns ~= nil and columns:IsShown() and columns.columnHeaders ~= nil then
        local headers = {}
        for header in columns.columnHeaders:EnumerateActive() do
            tinsert(headers, header)
        end
        table.sort(headers, function(a, b)
            return a:GetID() < b:GetID()
        end)
        if #headers > 0 then
            builder:beginStop("columns")
            builder:pushContext("columns", L["Sort By"])
            builder:startRow()
            for _, header in ipairs(headers) do
                addProxy(builder, header)
            end
            builder:endRow()
            builder:popContext()
        end
    end

    if list.Spinner ~= nil and list.Spinner:IsShown() then
        builder:beginStop("membersLoading")
        builder:addItem(ControlId.structural("membersLoading"), nodes.text({ label = L["Loading"] }))
    end

    builder:beginStop("members")
    nodes.scrollBoxList(builder, {
        scrollBox = list.ScrollBox,
        key = "members",
        label = L["Members"],
        emit = function(b, data, index, helpers)
            if type(data) == "table" then
                emitMember(b, data, index, helpers, frame, expanded)
            end
        end,
    })
end

-- ---------------------------------------------------------------------------
-- The club list
-- ---------------------------------------------------------------------------

local FINDER_ENTRIES = {
    {
        key = "setGuildFinder",
        label = function()
            return COMMUNITIES_GUILD_FINDER
        end,
    },
    {
        key = "setFindCommunity",
        label = function()
            return COMMUNITY_FINDER_FIND_COMMUNITY
        end,
    },
    {
        key = "setJoinCommunity",
        label = function()
            return COMMUNITIES_JOIN_COMMUNITY
        end,
    },
}

local function finderEntry(data)
    for _, entry in ipairs(FINDER_ENTRIES) do
        if data[entry.key] then
            return entry
        end
    end
    return nil
end

-- The club an entry shows: tickets keep it one level down.
local function entryClub(data)
    local clubInfo = data.clubInfo
    if clubInfo ~= nil and clubInfo.isTicket then
        return clubInfo.clubInfo, clubInfo
    end
    return clubInfo, clubInfo
end

local function clubLabel(data)
    local club, entry = entryClub(data)
    if club == nil then
        local finder = finderEntry(data)
        return finder ~= nil and finder.label() or UNKNOWN
    end
    if entry.isInvitation or entry.isClubFinderInvitation then
        return safeLabel(function()
            return format(COMMUNITIES_LIST_INVITATION_DISPLAY, club.name)
        end, club.name)
    end
    return club.name
end

local function clubId(data)
    local club = entryClub(data)
    return club ~= nil and club.clubId or nil
end

local function renderClubList(builder, frame)
    local list = frame.CommunitiesList
    if list == nil or not list:IsShown() or list.ScrollBox == nil then
        return
    end
    builder:beginStop("clubs")
    nodes.scrollBoxList(builder, {
        scrollBox = list.ScrollBox,
        key = "clubs",
        label = L["Guild and Communities"],
        id = function(data, index)
            local id = type(data) == "table" and clubId(data) or nil
            if id ~= nil then
                return ControlId.structural("club:" .. tostring(id))
            end
            local finder = type(data) == "table" and finderEntry(data) or nil
            return ControlId.structural("club:entry:" .. (finder ~= nil and finder.key or tostring(index)))
        end,
        row = function(data, index, helpers)
            local target = helpers.target
            return {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return clubLabel(data)
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            local club = entryClub(data)
                            if club ~= nil and is(club.clubType, Enum.ClubType.Guild) then
                                return GUILD
                            end
                            return nil
                        end,
                        kind = kinds.value,
                    },
                    {
                        text = function()
                            local club, entry = entryClub(data)
                            if club ~= nil and entry.isClub and list:IsClubFavorite(club) then
                                return L["Favorite"]
                            end
                            return nil
                        end,
                        kind = kinds.value,
                    },
                    {
                        text = function()
                            local id = clubId(data)
                            if id ~= nil and frame:GetSelectedClubId() == id then
                                return L["selected"]
                            end
                            return nil
                        end,
                        kind = kinds.selected,
                        live = "focus",
                    },
                    {
                        -- A finder the account cannot use is greyed out.
                        text = function()
                            local row = target()
                            if row ~= nil and row.IsEnabled ~= nil and not row:IsEnabled() then
                                return L["Disabled"]
                            end
                            return nil
                        end,
                        kind = kinds.enabled,
                    },
                },
                bindings = clickBindings(target),
                contextActions = nodes.proxyContextActions(target),
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
                tooltipFrame = target,
            }
        end,
    })
end

-- ---------------------------------------------------------------------------
-- Chat page
-- ---------------------------------------------------------------------------

-- The latest lines of the chat page, oldest first, like the page reads.
local MESSAGE_LINES = 50

local function renderChat(builder, frame)
    -- The channel dropdown, Add to Chat (an arrow without text, named by its
    -- menu's title) and the calendar button (named by its tooltip title).
    local controls = {}
    for _, entry in ipairs({
        { frame = frame.StreamDropdown, dropdown = true },
        { frame = frame.AddToChatButton, dropdown = true, label = COMMUNITIES_ADD_TO_CHAT_DROP_DOWN_TITLE },
        { frame = frame.CommunitiesCalendarButton, label = COMMUNITIES_CALENDAR_TOOLTIP_TITLE },
    }) do
        if entry.frame ~= nil and entry.frame:IsShown() then
            tinsert(controls, entry)
        end
    end
    if #controls > 0 then
        builder:beginStop("chatControls")
        builder:startRow()
        for _, entry in ipairs(controls) do
            if entry.dropdown then
                addDropdown(builder, entry.frame, entry.label)
            else
                addProxy(builder, entry.frame, nil, entry.label)
            end
        end
        builder:endRow()
    end

    local chat = frame.Chat
    local messages = chat ~= nil and chat.MessageFrame or nil
    if messages ~= nil and chat:IsShown() then
        builder:beginStop("messages")
        builder:pushContext("messages", L["Messages"])
        local count = messages:GetNumMessages()
        if count == 0 then
            builder:addItem(ControlId.structural("messages:empty"), nodes.text({ label = L["Empty"] }))
        end
        local last = nil
        for i = math.max(1, count - MESSAGE_LINES + 1), count do
            local text, _, _, _, _, _, messageId = messages:GetMessageInfo(i)
            local key
            if type(messageId) == "table" and messageId.epoch ~= nil then
                key = "message:" .. tostring(messageId.epoch) .. ":" .. tostring(messageId.position)
            else
                key = "message:line:" .. i
            end
            last = ControlId.structural(key)
            builder:addItem(last, nodes.text({ label = speechText(text) or "" }))
        end
        builder:popContext()
        -- Newest first in reach: focus starts on the latest message.
        if last ~= nil then
            builder:setStart(last)
        end
        addProxy(builder, JumpToUnreadButton, "jumpToUnread")
    end

    local editBox = frame.ChatEditBox
    if editBox ~= nil and editBox:IsShown() then
        builder:beginStop("chatBox")
        local vtable = nodes.proxyEditBox({ editBox = editBox, label = L["Chat"] })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(editBox), vtable)
        end
    end

    renderMemberList(builder, frame, false)
end

-- ---------------------------------------------------------------------------
-- Roster page
-- ---------------------------------------------------------------------------

local function renderRoster(builder, frame)
    local guildList, communityList = frame.GuildMemberListDropdown, frame.CommunityMemberListDropdown
    if (guildList ~= nil and guildList:IsShown()) or (communityList ~= nil and communityList:IsShown()) then
        builder:beginStop("memberColumn")
        builder:startRow()
        for _, dropdown in ipairs({ guildList, communityList }) do
            if dropdown ~= nil and dropdown:IsShown() then
                addDropdown(builder, dropdown)
            end
        end
        builder:endRow()
    end
    renderMemberList(builder, frame, true)
end

-- ---------------------------------------------------------------------------
-- Guild info page
-- ---------------------------------------------------------------------------

local function newsLabel(data)
    return safeLabel(function()
        if data.motd ~= nil then
            return speechText(format(GUILD_NEWS_MOTD, data.motd))
        end
        if data.event then
            local event = C_Calendar.GetGuildEventInfo(data.index)
            if event == nil then
                return UNKNOWN
            end
            local day = CALENDAR_WEEKDAY_NAMES ~= nil and CALENDAR_WEEKDAY_NAMES[event.weekday] or nil
            return join(day, GameTime_GetFormattedTime(event.hour, event.minute, true), speechText(event.title))
        end
        local news = C_GuildInfo.GetGuildNewsInfo(data.index)
        if news == nil then
            return UNKNOWN
        end
        if news.isHeader then
            return format(GUILD_NEWS_DATE, CALENDAR_WEEKDAY_NAMES[news.weekday + 1], news.day + 1, news.month + 1)
        end
        -- The line the news button shows (GuildNewsButton_SetNews).
        local who, what = news.whoText or UNKNOWN, nil
        local newsType = news.newsType
        if news.whatText ~= nil then
            if newsType == NEWS_GUILD_ACHIEVEMENT then
                who = news.whatText
            elseif newsType == NEWS_PLAYER_ACHIEVEMENT then
                what = "[" .. news.whatText .. "]"
            elseif newsType == NEWS_DUNGEON_ENCOUNTER then
                local difficulty = news.data ~= nil and news.data[3] or nil
                local displayHeroic, displayMythic = select(5, GetDifficultyInfo(difficulty))
                local formatString = GUILD_NEWS_DUNGEON_ENCOUNTER_NORMAL
                if displayHeroic then
                    formatString = GUILD_NEWS_DUNGEON_ENCOUNTER_HEROIC
                elseif displayMythic then
                    formatString = GUILD_NEWS_DUNGEON_ENCOUNTER_MYTHIC
                end
                what = format(formatString, news.whatText)
            else
                what = news.whatText
            end
        elseif newsType ~= NEWS_GUILD_CREATE then
            what = UNKNOWN
        end
        return speechText(format(_G["GUILD_NEWS_FORMAT" .. newsType], who, what))
    end, UNKNOWN)
end

local function renderGuildInfo(builder, frame)
    local details = frame.GuildDetailsFrame
    if details == nil or not details:IsShown() then
        return
    end
    local info = details.Info
    if info ~= nil and info:IsShown() then
        -- Challenges, where the guild has them (the game turns the block
        -- into the message of the day heading when it has none).
        local challenges = {}
        for _, challenge in ipairs(info.Challenges or {}) do
            if challenge:IsShown() and challenge.orderIndex ~= nil then
                tinsert(challenges, challenge)
            end
        end
        if #challenges > 0 then
            builder:beginStop("challenges")
            builder:pushContext("challenges", GUILD_FRAME_CHALLENGES)
            for _, challenge in ipairs(challenges) do
                local captured = challenge
                builder:addItem(
                    ControlId.structural("challenge:" .. tostring(challenge.orderIndex)),
                    nodes.text({
                        label = function()
                            local progress = captured.count:IsShown() and plainText(captured.count:GetText())
                                or COMPLETE
                            return join(plainText(captured.label:GetText()), progress)
                        end,
                    })
                )
            end
            builder:popContext()
        end

        builder:beginStop("motd")
        builder:pushContext("motd", GUILD_MOTD_LABEL)
        builder:addItem(
            ControlId.structural("motd:text"),
            nodes.text({
                label = function()
                    local ok, motd = pcall(C_GuildInfo.GetMOTD)
                    return ok and speechText(motd) or L["Empty"]
                end,
            })
        )
        addProxy(builder, info.EditMOTDButton, nil, join(GUILD_EDIT_TEXT_LINK, GUILD_MOTD_LABEL))
        builder:popContext()

        builder:beginStop("guildDetails")
        builder:pushContext("guildDetails", GUILD_INFORMATION)
        local scrollChild = info.DetailsFrame ~= nil and info.DetailsFrame:GetScrollChild() or nil
        local detailsText = scrollChild ~= nil and scrollChild.Details or nil
        builder:addItem(
            ControlId.structural("guildDetails:text"),
            nodes.text({
                label = function()
                    return detailsText ~= nil and speechText(detailsText:GetText()) or L["Empty"]
                end,
            })
        )
        addProxy(builder, info.EditDetailsButton, nil, join(GUILD_EDIT_TEXT_LINK, GUILD_INFORMATION))
        builder:popContext()
    end

    local news = details.News
    if news ~= nil and news:IsShown() then
        -- Set Filters, and the request to replace an inactive guild master
        -- when the game offers it.
        local filters, impeach = news.SetFiltersButton, news.GMImpeachButton
        if (filters ~= nil and filters:IsShown()) or (impeach ~= nil and impeach:IsShown()) then
            builder:beginStop("newsControls")
            builder:startRow()
            addProxy(builder, filters)
            if impeach ~= nil then
                addProxy(builder, impeach, nil, fontText(impeach.Text))
            end
            builder:endRow()
        end
        if news.NoNews ~= nil and news.NoNews:IsShown() then
            builder:beginStop("noNews")
            addFontLine(builder, "noNews", news.NoNews)
        else
            builder:beginStop("news")
            nodes.scrollBoxList(builder, {
                scrollBox = news.ScrollBox,
                key = "news",
                label = GUILD_NEWS_TITLE,
                rowLabel = function(data)
                    return newsLabel(data)
                end,
            })
        end
    end
end

-- ---------------------------------------------------------------------------
-- Guild benefits page
-- ---------------------------------------------------------------------------

local function rewardLabel(index)
    return safeLabel(function()
        local achievementID, _, itemName, _, repLevel, moneyCost = GetGuildRewardInfo(index)
        local cost = nil
        if moneyCost ~= nil and moneyCost > 0 then
            cost = GetMoneyString(moneyCost)
        end
        local requirement = nil
        if achievementID ~= nil and achievementID > 0 then
            local _, achievementName = GetAchievementInfo(achievementID)
            requirement = REQUIRES_LABEL .. " " .. tostring(achievementName)
        else
            local faction = C_Reputation.GetGuildFactionData()
            if faction ~= nil and repLevel ~= nil and repLevel > faction.reaction then
                local standing = GetText("FACTION_STANDING_LABEL" .. repLevel, UnitSex("player"))
                requirement = format(REQUIRES_GUILD_FACTION, standing)
            end
        end
        return join(itemName, cost, requirement)
    end, UNKNOWN)
end

local function renderBenefits(builder, frame)
    local benefits = frame.GuildBenefitsFrame
    if benefits == nil or not benefits:IsShown() then
        return
    end
    local perks = benefits.Perks
    if perks ~= nil and perks:IsShown() and perks.ScrollBox ~= nil then
        builder:beginStop("perks")
        nodes.scrollBoxList(builder, {
            scrollBox = perks.ScrollBox,
            key = "perks",
            label = GUILD_PERKS_TITLE,
            rowLabel = function(data)
                local index = type(data) == "table" and data.index or data
                return GetGuildPerkInfo(index) or UNKNOWN
            end,
        })
    end
    local rewards = benefits.Rewards
    if rewards ~= nil and rewards:IsShown() and rewards.ScrollBox ~= nil then
        builder:beginStop("rewards")
        nodes.scrollBoxList(builder, {
            scrollBox = rewards.ScrollBox,
            key = "rewards",
            label = GUILD_REWARDS_TITLE,
            rowLabel = function(data)
                local index = type(data) == "table" and data.index or data
                return rewardLabel(index)
            end,
        })
    end
    for _, part in ipairs({ benefits.GuildAchievementPointDisplay, benefits.FactionFrame }) do
        if part ~= nil and part:IsShown() then
            local key = "benefits:" .. tostring(part:GetParentKey())
            builder:beginStop(key)
            addTexts(builder, part, key .. ":")
        end
    end
end

-- ---------------------------------------------------------------------------
-- Invitation page (an invitation or invite link to a community)
-- ---------------------------------------------------------------------------

local function renderInvitation(builder, frame)
    local shown = false
    for _, page in ipairs({ frame.InvitationFrame, frame.TicketFrame }) do
        if page ~= nil and page:IsShown() then
            shown = true
            local key = "invitation:" .. tostring(page:GetParentKey())
            builder:beginStop(key)
            for _, part in ipairs({ "InvitationText", "Name", "Type", "MemberCount", "Leader", "Description" }) do
                addFontLine(builder, key .. ":" .. part, page[part])
            end
            addProxy(builder, page.AcceptButton, key .. ":accept")
            addProxy(builder, page.DeclineButton, key .. ":decline")
        end
    end
    if not shown then
        unsupported(builder, "invitationUnsupported")
    end
end

-- ---------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------

local TABS = { "ChatTab", "RosterTab", "GuildBenefitsTab", "GuildInfoTab", "GuildPreferredPlaySettingsTab" }

-- The side tabs: icons named by their tooltips; the chat tab can be locked
-- (chat muted or turned off), its reason is the tooltip's second line.
local function renderTabs(builder, frame)
    local tabs = {}
    for _, key in ipairs(TABS) do
        local tab = frame[key]
        if tab ~= nil and tab:IsShown() then
            tinsert(tabs, tab)
        end
    end
    if #tabs == 0 then
        return
    end
    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for _, tab in ipairs(tabs) do
        local captured = tab
        builder:addItem(ControlId.forObject(tab), {
            controlType = graph.controlTypes.button,
            announcements = {
                { text = plainText(tab.tooltip) or UNKNOWN, kind = kinds.label },
                {
                    text = function()
                        return captured:GetChecked() and L["selected"] or nil
                    end,
                    kind = kinds.selected,
                    live = "focus",
                },
                {
                    text = function()
                        if captured.IconOverlay ~= nil and captured.IconOverlay:IsShown() then
                            return join(L["Disabled"], plainText(captured.tooltip2))
                        end
                        return nil
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

-- The buttons along the bottom, whichever the page shows.
local function renderButtons(builder, frame)
    local control = frame.CommunitiesControlFrame
    local maxMin = frame.MaximizeMinimizeFrame
    local candidates = {
        { button = frame.InviteButton },
        { button = control ~= nil and control:IsShown() and control.CommunitiesSettingsButton or nil },
        { button = control ~= nil and control:IsShown() and control.GuildRecruitmentButton or nil },
        { button = control ~= nil and control:IsShown() and control.GuildControlButton or nil },
        { button = frame.GuildLogButton },
        { button = maxMin ~= nil and maxMin.MaximizeButton or nil, label = L["Maximize"] },
        { button = maxMin ~= nil and maxMin.MinimizeButton or nil, label = L["Minimize"] },
    }
    local shown = {}
    for _, candidate in ipairs(candidates) do
        if candidate.button ~= nil and candidate.button:IsShown() then
            tinsert(shown, candidate)
        end
    end
    if #shown == 0 then
        return
    end
    builder:beginStop("buttons")
    builder:pushContext("buttons", L["Controls"])
    builder:startRow()
    for _, candidate in ipairs(shown) do
        addProxy(builder, candidate.button, nil, candidate.label)
    end
    builder:endRow()
    builder:popContext()
end

local function render(builder, screen)
    local frame = CommunitiesFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    local title = frame.GetTitleText ~= nil and plainText(frame:GetTitleText():GetText()) or nil
    builder:pushContext("communities", title or L["Guild and Communities"])

    -- The banner a guild leader gets when the guild must be renamed.
    local alert = frame.GuildNameAlertFrame
    if alert ~= nil and alert:IsShown() then
        builder:beginStop("nameAlert")
        addTexts(builder, alert, "nameAlert:")
        addProxy(builder, alert)
    end

    local modes = COMMUNITIES_FRAME_DISPLAY_MODES
    local mode = frame:GetDisplayMode()
    if mode == modes.MINIMIZED then
        builder:beginStop("clubDropdown")
        addDropdown(builder, frame.CommunitiesListDropdown)
    else
        renderClubList(builder, frame)
    end

    if mode == modes.CHAT or mode == modes.MINIMIZED then
        renderChat(builder, frame)
    elseif mode == modes.ROSTER then
        renderRoster(builder, frame)
    elseif mode == modes.GUILD_INFO then
        renderGuildInfo(builder, frame)
    elseif mode == modes.GUILD_BENEFITS then
        renderBenefits(builder, frame)
    elseif mode == modes.INVITATION or mode == modes.TICKET then
        renderInvitation(builder, frame)
    elseif mode ~= nil then
        -- Guild and community finder, applicant lists, preferred play.
        unsupported(builder, "pageUnsupported")
    end

    renderButtons(builder, frame)
    renderTabs(builder, frame)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "CommunitiesFrame",
    frameName = "CommunitiesFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = render },
})

-- ---------------------------------------------------------------------------
-- The guild member card (a left click on a guild member): name, level and
-- class, zone, rank (a dropdown when you may promote or demote), last
-- online, the notes, Remove, Group Invite, Close. A note you may edit opens
-- the game's note box (its frame's own mouse script, as a click on it does).
-- ---------------------------------------------------------------------------

local function memberDetail()
    local frame = CommunitiesFrame
    return frame ~= nil and frame.GuildMemberDetailFrame or nil
end

local function labelled(labelString, valueString)
    return function()
        return join(plainText(labelString:GetText()), speechText(valueString:GetText()))
    end
end

-- noteKey names the note's font string on the background frame; it is
-- looked up only once the background is known to be there.
local function addNote(builder, key, background, labelString, noteKey)
    if background == nil or not background:IsShown() then
        return
    end
    local noteString = background[noteKey]
    if noteString == nil then
        return
    end
    builder:beginStop(key)
    if background:IsMouseEnabled() then
        builder:addItem(
            ControlId.forObject(background),
            nodes.button({
                label = fontText(labelString),
                value = function()
                    return speechText(noteString:GetText())
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
    local card = memberDetail()
    if card == nil or not card:IsShown() then
        return
    end
    builder:pushContext("memberDetail", fontText(card.Name))
    builder:beginStop("memberDetail:info")
    addFontLine(builder, "memberDetail:level", card.Level)
    builder:addItem(
        ControlId.structural("memberDetail:zone"),
        nodes.text({ label = labelled(card.ZoneLabel, card.ZoneText) })
    )
    if card.RankDropdown ~= nil and card.RankDropdown:IsShown() then
        -- The dropdown shows the rank; the label names it.
        addDropdown(builder, card.RankDropdown, function()
            return join(plainText(card.RankLabel:GetText()), plainText(nodes.frameText(card.RankDropdown)()))
        end)
    else
        builder:addItem(
            ControlId.structural("memberDetail:rank"),
            nodes.text({ label = labelled(card.RankLabel, card.RankText) })
        )
    end
    builder:addItem(
        ControlId.structural("memberDetail:online"),
        nodes.text({ label = labelled(card.OnlineLabel, card.OnlineText) })
    )
    addNote(builder, "memberDetail:note", card.NoteBackground, card.NoteLabel, "PersonalNoteText")
    addNote(builder, "memberDetail:officerNote", card.OfficerNoteBackground, card.OfficerNoteLabel, "OfficerNoteText")
    addProxy(builder, card.RemoveButton, "memberDetail:remove")
    addProxy(builder, card.GroupInviteButton, "memberDetail:invite")
    addProxy(builder, card.CloseButton, "memberDetail:close", CLOSE)
    builder:popContext()
end

module:registerWindow({
    type = "CustomWindow",
    name = "CommunitiesGuildMemberDetail",
    isOpen = function()
        local card = memberDetail()
        return card ~= nil and card:IsVisible()
    end,
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderMemberDetail },
})

-- ---------------------------------------------------------------------------
-- Editing the message of the day or the guild information: the text, Accept,
-- Close. Enter in the message of the day box accepts (the game's own box);
-- in the information box it starts a new line.
-- ---------------------------------------------------------------------------

local function renderTextEdit(builder, screen)
    local frame = CommunitiesGuildTextEditFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    local title = fontText(frame.Title)
    builder:pushContext("guildTextEdit", title)
    local scrollFrame = frame.Container ~= nil and frame.Container.ScrollFrame or nil
    local editBox = scrollFrame ~= nil and scrollFrame.EditBox or nil
    if editBox ~= nil then
        builder:beginStop("guildTextEdit:text")
        local vtable = nodes.proxyEditBox({ editBox = editBox, label = title })
        if vtable ~= nil then
            builder:addItem(ControlId.forObject(editBox), vtable)
        end
    end
    addProxy(builder, CommunitiesGuildTextEditFrameAcceptButton, "guildTextEdit:accept")
    addProxy(builder, CommunitiesGuildTextEditFrameCloseButton, "guildTextEdit:close", CLOSE)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "CommunitiesGuildTextEdit",
    frameName = "CommunitiesGuildTextEditFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderTextEdit },
})

-- ---------------------------------------------------------------------------
-- The guild event log (View Log): who invited, joined, was promoted,
-- demoted, removed or left, newest first, the lines the log shows.
-- ---------------------------------------------------------------------------

-- Each takes the two players and the rank, as many as its text uses
-- (format ignores the rest).
local EVENT_FORMATS = {
    invite = GUILDEVENT_TYPE_INVITE,
    join = GUILDEVENT_TYPE_JOIN,
    promote = GUILDEVENT_TYPE_PROMOTE,
    demote = GUILDEVENT_TYPE_DEMOTE,
    remove = GUILDEVENT_TYPE_REMOVE,
    quit = GUILDEVENT_TYPE_QUIT,
}

local function eventLine(index)
    return safeLabel(function()
        local eventType, player1, player2, rank, year, month, day, hour = GetGuildEventInfo(index)
        local eventFormat = EVENT_FORMATS[eventType]
        if eventFormat == nil then
            return nil
        end
        local text = format(eventFormat, player1 or UNKNOWN, player2 or UNKNOWN, rank or "")
        local when = format(GUILD_BANK_LOG_TIME, TimeUtil.GetRecentTimeDate(year, month, day, hour))
        return join(text, plainText(when))
    end, nil)
end

local function renderGuildLog(builder, screen)
    local frame = CommunitiesGuildLogFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("guildLog", GUILD_EVENT_LOG)
    builder:beginStop("guildLog:events")
    local any = false
    for index = GetNumGuildEvents(), 1, -1 do
        local line = eventLine(index)
        if line ~= nil then
            any = true
            builder:addItem(ControlId.structural("guildLog:" .. index), nodes.text({ label = line }))
        end
    end
    if not any then
        builder:addItem(ControlId.structural("guildLog:empty"), nodes.text({ label = L["Empty"] }))
    end
    addProxy(builder, CommunitiesGuildLogFrameCloseButton, "guildLog:close", CLOSE)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "CommunitiesGuildLog",
    frameName = "CommunitiesGuildLogFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderGuildLog },
})

-- ---------------------------------------------------------------------------
-- The news filters (Set Filters on the news list): one check box per kind
-- of news.
-- ---------------------------------------------------------------------------

local function renderNewsFilters(builder, screen)
    local frame = CommunitiesGuildNewsFiltersFrame
    if frame == nil or not frame:IsShown() then
        return
    end
    builder:pushContext("newsFilters", fontText(frame.Title))
    builder:beginStop("newsFilters:list")
    for _, check in ipairs(frame.GuildNewsFilterButtons or {}) do
        if check:IsShown() then
            builder:addItem(
                ControlId.forObject(check),
                nodes.proxyCheckButton({ target = check, label = fontText(check.Text) })
            )
        end
    end
    addProxy(builder, frame.CloseButton, "newsFilters:close", CLOSE)
    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "CommunitiesGuildNewsFilters",
    frameName = "CommunitiesGuildNewsFiltersFrame",
    conflictingAddons = { "Sku" },
    graphScreen = { render = renderNewsFilters },
})
