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

-- The who tab (LFGWhoListFrame): the search box (Enter in it searches), the
-- search button and filter menu, the results, and the totals line. A result
-- row selects on a left click and opens the player menu on a right click;
-- its invite button sits beside it.
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

    builder:beginStop("whoControls")
    builder:startRow()
    builder:addItem(
        ControlId.forObject(frame.WhoSearch),
        nodes.proxyButton({ target = frame.WhoSearch, label = L["Search"] })
    )
    builder:addItem(
        ControlId.forObject(frame.FilterDropdown),
        nodes.proxyDropdown({ target = frame.FilterDropdown, label = L["Filter"] })
    )
    builder:endRow()

    builder:beginStop("whoList")
    nodes.scrollBoxList(builder, {
        scrollBox = frame.ScrollBox,
        key = "who",
        label = LFGParentFrame.WhoListingTab ~= nil and LFGParentFrame.WhoListingTab.tooltipText or WHO_LIST,
        id = function(data, index)
            local info = type(data) == "table" and data.info or nil
            return ControlId.structural("who:" .. tostring(info ~= nil and info.fullName or index))
        end,
        emit = function(builder, data, index, helpers)
            local info = type(data) == "table" and data.info or nil
            local name = tostring(info ~= nil and info.fullName or index)
            builder:startRow()
            builder:addItem(helpers.id, {
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
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
                tooltipFrame = helpers.target,
            })
            builder:addItem(ControlId.structural("whoInvite:" .. name), {
                controlType = graph.controlTypes.button,
                announcements = {
                    { text = L["Invite"], kind = kinds.label },
                },
                bindings = {
                    {
                        binding = "leftClick",
                        type = "Click",
                        emulatedKey = "LeftButton",
                        target = function()
                            local row = helpers.target()
                            return row ~= nil and row.InviteButton or nil
                        end,
                    },
                },
                onFocus = helpers.onFocus,
                onFocusTick = helpers.onFocusTick,
                onUnfocus = helpers.onUnfocus,
            })
            builder:endRow()
        end,
    })

    if frame.WhoFrameTotals ~= nil then
        builder:beginStop("whoTotals")
        builder:addItem(
            ControlId.structural("who:totals"),
            nodes.text({ label = fontText(frame.WhoFrameTotals) })
        )
    end
end

module.addTab(3, renderWhoTab)
