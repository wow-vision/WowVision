local module = WowVision.base.windows.lfg
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- WoW: Forever's group finder: the TBC tool (tbc/lfg.lua) on a newer build
-- of the same Blizzard addon. This build draws three side tabs (listing,
-- browse, who) in place of the bottom ones, adds play style, level range
-- and voice chat controls to the listing, and holds the who list as its
-- third tab -- Forever's friends window has no who tab.

-- The game key that opens the group finder on a tab, where the tab has one.
local TAB_COMMANDS = {
    [1] = "TOGGLEGROUPFINDER",
    [3] = "TOGGLEWHOTAB",
}

local function plainText(text)
    if text == nil then
        return nil
    end
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- A live label for a font string (nodes.frameText walks regions, which font
-- strings do not have).
local function fontText(fontString)
    return function()
        return fontString:GetText()
    end
end

-- The side tabs are plain frames that switch on mouse up through a custom
-- handler, so a secure click cannot reach them, and the hidden bottom tab
-- buttons cannot stand in: their click handler calls a tab switch the addon
-- keeps local to another file, so clicking them errors. The listing and who
-- tabs open through their game keys, run securely as their own keys would:
-- posting a listing refuses values that addon code has touched. Those keys
-- toggle (on their own tab they close the window), so a tab's key is bound
-- only while the tab is not selected; a second Enter right after switching
-- closes the window as the key does. The browse tab has no key: Enter runs
-- its own mouse up script, as a left click releases it.
function module.renderTabBar(builder)
    local frame = LFGParentFrame
    for _, tab in ipairs({ frame.ListingTab, frame.BrowsingTab, frame.WhoListingTab }) do
        if tab ~= nil and tab:IsShown() then
            local captured = tab
            local tabIndex = tab:GetID()
            local function selected()
                return PanelTemplates_GetSelectedTab(frame) == tabIndex
            end
            local vtable = nodes.button({
                label = tab.tooltipText or tostring(tabIndex),
                selected = selected,
                onActivate = function()
                    local script = captured:GetScript("OnMouseUp")
                    if script ~= nil then
                        script(captured, "LeftButton", true)
                    end
                end,
            })
            local command = TAB_COMMANDS[tabIndex]
            if command ~= nil then
                vtable.onActivate = nil
                vtable.bindings = {}
                if not selected() then
                    tinsert(vtable.bindings, { binding = "leftClick", type = "Command", command = command })
                end
            end
            builder:addItem(ControlId.forObject(captured), vtable)
        end
    end
end

-- The listing controls only this build has: the play style a listing must
-- name before it can post, the level range filter of the activity list,
-- and the voice chat the group uses.
function module.renderListingOptions(builder)
    local view = LFGListingFrameActivityView
    if view == nil or not view:IsShown() then
        return
    end

    local playStyle = view.PlayStyleDropdown
    if playStyle ~= nil and playStyle:IsShown() then
        local current = nodes.frameText(playStyle)
        builder:beginStop("playStyle")
        builder:addItem(
            ControlId.forObject(playStyle),
            nodes.proxyDropdown({
                target = playStyle,
                label = function()
                    return nodes.joinLabel(L["Play Style"], plainText(current()))
                end,
            })
        )
    end

    local levelRanges = view.LevelRangesCheckbox
    if levelRanges ~= nil and levelRanges:IsShown() and levelRanges.Checkbox ~= nil then
        builder:beginStop("levelRanges")
        builder:addItem(
            ControlId.forObject(levelRanges.Checkbox),
            nodes.proxyCheckButton({ target = levelRanges.Checkbox, label = fontText(levelRanges.Text) })
        )
    end

    local voiceChat = view.VoiceChatDropdown
    if voiceChat ~= nil and voiceChat:IsShown() then
        local name = fontText(view.VoiceChatLabel)
        local current = nodes.frameText(voiceChat)
        builder:beginStop("voiceChat")
        builder:addItem(
            ControlId.forObject(voiceChat),
            nodes.proxyDropdown({
                target = voiceChat,
                label = function()
                    return nodes.joinLabel(name(), plainText(current()))
                end,
            })
        )
    end
end

local function whoLabel(info)
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

-- The who tab (LFGWhoListFrame): the search box (Enter in it searches with
-- the box's text and the filters, so the search button beside it is left
-- out, like other search boxes' extra buttons), the filter menu (class,
-- race, zone, sort order), then the results. A result highlights on a left
-- click and opens the player menu (whisper, invite) on a right click; its
-- invite button leads the result's context menu, so the results stay one
-- list with their positions. The totals line reads only when the server found more players
-- than it sent (it sends 50 at most); otherwise the list's size says it.
local function renderWhoTab(builder)
    local frame = LFGWhoListFrame
    if frame == nil or not frame:IsShown() then
        return
    end

    builder:beginStop("whoSearch")
    builder:addItem(
        ControlId.forObject(frame.EditBox),
        nodes.proxyEditBox({ editBox = frame.EditBox, label = L["Search"] })
    )

    builder:beginStop("whoFilter")
    builder:addItem(
        ControlId.forObject(frame.FilterDropdown),
        nodes.proxyDropdown({ target = frame.FilterDropdown, label = L["Filter"] })
    )

    builder:beginStop("whoList")
    nodes.scrollBoxList(builder, {
        scrollBox = frame.ScrollBox,
        key = "who",
        label = LFGParentFrame.WhoListingTab ~= nil and LFGParentFrame.WhoListingTab.tooltipText or WHO_LIST,
        id = function(data, index)
            local info = type(data) == "table" and data.info or nil
            return ControlId.structural("who:" .. tostring(info ~= nil and info.fullName or index))
        end,
        row = function(data, index, helpers)
            local info = type(data) == "table" and data.info or nil
            local inviteButton = function()
                local row = helpers.target()
                return row ~= nil and row.InviteButton or nil
            end
            local rowActions = nodes.proxyContextActions(helpers.target)
            return {
                controlType = graph.controlTypes.button,
                announcements = {
                    {
                        text = function()
                            return whoLabel(info)
                        end,
                        kind = kinds.label,
                    },
                    {
                        text = function()
                            local selection = frame.selectionBehavior
                            if selection ~= nil and selection:IsElementDataSelected(data) then
                                return L["selected"]
                            end
                            return nil
                        end,
                        kind = kinds.selected,
                        live = "focus",
                    },
                },
                bindings = {
                    { binding = "leftClick", type = "Click", emulatedKey = "LeftButton", target = helpers.target },
                    { binding = "rightClick", type = "Click", emulatedKey = "RightButton", target = helpers.target },
                },
                contextActions = function(add)
                    add({ label = L["Invite"], click = { emulatedKey = "LeftButton", target = inviteButton } })
                    rowActions(add)
                end,
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
                tooltipFrame = helpers.target,
            }
        end,
    })

    local numWhos, totalCount = C_FriendList.GetNumWhoResults()
    if frame.WhoFrameTotals ~= nil and (totalCount or 0) > (numWhos or 0) then
        builder:beginStop("whoTotals")
        builder:addItem(
            ControlId.structural("who:totals"),
            nodes.text({ label = fontText(frame.WhoFrameTotals) })
        )
    end
end

module.addTab(3, renderWhoTab)
