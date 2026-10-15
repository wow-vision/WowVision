local module = WowVision.base.chat
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds
local chatLinks = WowVision.chatLinks
local chatTabs = WowVision.chatTabs

-- The chat reader (Shift-F3): the message log is ONE node holding a cursor
-- over the message buffer (up to 5000 entries), not a node per message --
-- per-node bindings take over up, down, home, and end while it is focused
-- and speak messages directly, so the per-tick rebuild cost is constant.
-- The label is not live: movement speech is manual, and buffer eviction
-- shifting indices under the cursor must not re-announce.
--
-- Within a message a second cursor walks its clickable PARTS -- channel,
-- sender, links, in line order (chatLinks.parse). Enter, Backspace, and the
-- shift click act on the selected part exactly as a mouse click on that
-- piece of the line would; the tooltip keys read a selected link.
--
-- Left and right switch the chat tab from the message log, by a real click
-- on the neighbouring tab (the tab strip stop does the same with Enter), and
-- land on its newest message.

-- Keymaps for the part cursor; engaged per node, so they only hold their
-- keys while the message log is focused.
module:registerBinding({
    type = "Flexible",
    key = "chat/previousPart",
    dorment = true,
    label = L["Previous Link in Message"],
    inputs = { "CTRL-LEFT" },
})
module:registerBinding({
    type = "Flexible",
    key = "chat/nextPart",
    dorment = true,
    label = L["Next Link in Message"],
    inputs = { "CTRL-RIGHT" },
})
module:registerBinding({
    type = "Flexible",
    key = "chat/shiftClick",
    dorment = true,
    label = L["Shift Click"],
    inputs = { "SHIFT-ENTER" },
})

local function currentBuffer()
    local frame = SELECTED_CHAT_FRAME
    local index = frame ~= nil and frame:GetID() or nil
    local entry = index ~= nil and module.frames ~= nil and module.frames[index] or nil
    return entry ~= nil and entry.buffer or nil
end

local function tabButton(frame)
    return _G[frame:GetName() .. "Tab"]
end

-- The tabs a sighted player can click, in screen order.
local function visibleTabFrames()
    local result = {}
    for _, frame in ipairs(module:orderedFrames()) do
        local tab = tabButton(frame)
        if tab ~= nil and tab:IsShown() then
            tinsert(result, frame)
        end
    end
    return result
end

-- The tab button beside the selected tab, or nil at either end.
local function neighbourTab(step)
    local frames = visibleTabFrames()
    for i, frame in ipairs(frames) do
        if frame == SELECTED_CHAT_FRAME then
            local target = frames[i + step]
            return target ~= nil and tabButton(target) or nil
        end
    end
    return nil
end

local function messagesNode(screen)
    local function clampedIndex()
        local buffer = currentBuffer()
        local count = buffer ~= nil and #buffer.items or 0
        local index = screen._chatIndex or count
        if index > count then
            index = count
        end
        if index < 1 then
            index = count > 0 and 1 or 0
        end
        screen._chatIndex = index
        return buffer, index, count
    end

    local function speak()
        local buffer, index = clampedIndex()
        local item = buffer ~= nil and buffer.items[index] or nil
        if item ~= nil then
            WowVision:speak(item:getFocusString())
        end
    end

    -- Parts of the message under the cursor, parsed once per message. nil
    -- parts mean the text is secret (chat messaging lockdown).
    local function currentParts()
        local buffer, index = clampedIndex()
        local item = buffer ~= nil and buffer.items[index] or nil
        local data = item ~= nil and item:getData() or nil
        if type(data) ~= "table" then
            return {}, 0
        end
        if screen._chatPartsData ~= data then
            screen._chatPartsData = data
            screen._chatParts = chatLinks.parse(data.message)
            screen._chatPart = chatLinks.defaultIndex(screen._chatParts)
        end
        return screen._chatParts, screen._chatPart, data
    end

    local function currentPart()
        local parts, index = currentParts()
        if parts == nil then
            return nil, true
        end
        return parts[index], false
    end

    -- Re-point the tooltip reader at the newly selected part.
    local function refreshTooltip()
        local node = screen.keyGraph ~= nil and screen.keyGraph:currentNode() or nil
        if node ~= nil then
            WowVision.graphHost:_setTooltipFor(node)
        end
    end

    local function movePart(step)
        local parts, index = currentParts()
        if parts == nil then
            WowVision:speak(L["Links unavailable here"])
            return
        end
        local target = index + step
        if target < 1 or target > #parts then
            return -- boundary bump (or no parts at all): silent
        end
        screen._chatPart = target
        refreshTooltip()
        WowVision:speak(chatLinks.partLabel(parts[target]))
    end

    local function withPart(func)
        local part, secret = currentPart()
        if secret then
            WowVision:speak(L["Links unavailable here"])
        elseif part ~= nil then
            func(part)
        end
    end

    -- A left click on a link shows its tooltip; here that is reading it. A
    -- link with no tooltip form (a Retail talent build, a calendar event)
    -- falls through to the game's own click handling.
    local function leftClick(part)
        if part.kind == "link" then
            local text = WowVision.UIHost.tooltip:getText()
            if text ~= nil and text ~= "" then
                WowVision:speak(text)
                return
            end
        end
        chatLinks.click(part, "LeftButton")
    end

    -- The game's own menu for the part. A player menu opened from here is
    -- tainted, which blocks its "Copy Character Name" row; hand the dropdown
    -- reader the name so that row can copy through an edit box instead.
    local function rightClick(part)
        if part.kind == "player" then
            graph.dropdown.copyName = chatLinks.playerName(part)
        end
        chatLinks.click(part, "RightButton")
    end

    local function copyLine()
        local _, _, data = currentParts()
        if data == nil then
            return
        end
        local text = chatLinks.plainText(data.message)
        if text == nil then
            WowVision:speak(L["Links unavailable here"])
            return
        end
        -- Shortly after: the context menu pops its screens once this
        -- returns and the message node re-announces on refocus; the entry
        -- box and its cue must come after that settles. The line itself is
        -- not re-read -- the user just heard it.
        C_Timer.After(0.2, function()
            WowVision.graphHost:openCopyBox(text)
        end)
    end

    -- After a tab click: the new tab's name and its newest message. Nothing
    -- changed (the first or last tab): silent, like any boundary bump.
    local function afterTabSwitch()
        local buffer = currentBuffer()
        if buffer == screen._chatBuffer then
            return
        end
        screen._chatBuffer = buffer
        screen._chatIndex = buffer ~= nil and #buffer.items or 0
        currentParts()
        refreshTooltip()
        local item = buffer ~= nil and buffer.items[screen._chatIndex] or nil
        local line = item ~= nil and item:getFocusString() or L["Empty"]
        WowVision.base.speech:stop()
        WowVision:speak(WowVision.secrets.join({ chatTabs.tabName(SELECTED_CHAT_FRAME), line }, ", "))
    end

    local function moveTo(target)
        local buffer, index, count = clampedIndex()
        if count == 0 then
            return
        end
        if target < 1 then
            target = 1
        end
        if target > count then
            target = count
        end
        if target == index then
            return -- boundary bump: silent, like the graph's own moves
        end
        screen._chatIndex = target
        currentParts()
        refreshTooltip()
        speak()
    end

    return {
        controlType = graph.controlTypes.text,
        tooltip = {
            type = "Hyperlink",
            link = function()
                local part = currentPart()
                if part ~= nil and part.kind == "link" then
                    return part.link
                end
                return nil
            end,
        },
        onActivate = function()
            withPart(leftClick)
        end,
        onSecondary = function()
            withPart(rightClick)
        end,
        contextActions = function(add)
            -- The game never labels what clicking a chat link does -- sighted
            -- players know it by convention -- so the entries say it, with
            -- the click that does the same from the line as a reminder.
            local part = currentPart()
            if part ~= nil then
                local left, right, shift
                if part.kind == "player" then
                    left = L["Whisper %s"]
                    right = L["Player Menu for %s"]
                    shift = L["Who %s"]
                elseif part.kind == "channel" then
                    left = L["Write to %s"]
                    right = L["Channel Menu for %s"]
                else
                    left = L["Read Tooltip of %s"]
                    shift = L["Link %s in Chat"]
                end
                add({
                    label = left:format(part.display) .. ", " .. L["Left Click"],
                    onActivate = function()
                        leftClick(part)
                    end,
                })
                if right ~= nil then
                    add({
                        label = right:format(part.display) .. ", " .. L["Right Click"],
                        onActivate = function()
                            rightClick(part)
                        end,
                    })
                end
                if shift ~= nil and part.linkType ~= "BNplayer" and part.linkType ~= "BNplayerCommunity" then
                    add({
                        label = shift:format(part.display) .. ", " .. L["Shift Click"],
                        onActivate = function()
                            chatLinks.shiftClick(part)
                        end,
                    })
                end
            end
            add({ label = L["Copy Line"], onActivate = copyLine })
        end,
        announcements = {
            {
                text = function()
                    local buffer, index = clampedIndex()
                    local item = buffer ~= nil and buffer.items[index] or nil
                    return item ~= nil and item:getFocusString() or L["Empty"]
                end,
                kind = kinds.label,
                live = false,
            },
            {
                text = function()
                    local _, index, count = clampedIndex()
                    if count == 0 then
                        return nil
                    end
                    return index .. " / " .. count
                end,
                kind = kinds.position,
                live = false,
            },
        },
        onFocus = function()
            -- Land on the latest message when the window opens or the chat
            -- tab changed. Focus RETURNING (a context menu or dropdown
            -- closing over it) keeps the place.
            local buffer = currentBuffer()
            if screen._chatBuffer ~= buffer or screen._chatIndex == nil then
                screen._chatBuffer = buffer
                screen._chatIndex = buffer ~= nil and #buffer.items or 0
            end
        end,
        bindings = {
            {
                binding = "up",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    moveTo((screen._chatIndex or 0) - 1)
                end,
            },
            {
                binding = "down",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    moveTo((screen._chatIndex or 0) + 1)
                end,
            },
            {
                binding = "home",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    moveTo(1)
                end,
            },
            {
                binding = "end",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    local buffer = currentBuffer()
                    moveTo(buffer ~= nil and #buffer.items or 0)
                end,
            },
            {
                binding = "left",
                type = "Click",
                emulatedKey = "LeftButton",
                target = function()
                    return neighbourTab(-1)
                end,
                postClick = afterTabSwitch,
            },
            {
                binding = "right",
                type = "Click",
                emulatedKey = "LeftButton",
                target = function()
                    return neighbourTab(1)
                end,
                postClick = afterTabSwitch,
            },
            {
                binding = "chat/previousPart",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    movePart(-1)
                end,
            },
            {
                binding = "chat/nextPart",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    movePart(1)
                end,
            },
            {
                binding = "chat/shiftClick",
                type = "Function",
                interruptSpeech = true,
                func = function()
                    withPart(chatLinks.shiftClick)
                end,
            },
        },
    }
end

local function renderChat(builder, screen)
    builder:pushContext("chat", L["Chat"])

    builder:beginStop("messages")
    builder:pushContext(
        "messages",
        SELECTED_CHAT_FRAME ~= nil and chatTabs.tabName(SELECTED_CHAT_FRAME) or L["Chat"],
        nil,
        false
    )
    builder:addItem(ControlId.structural("messages"), messagesNode(screen))
    builder:popContext()

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    for _, frame in ipairs(visibleTabFrames()) do
        local tab = tabButton(frame)
        -- The label comes from the frame: a whisper tab's text can be a
        -- secret, which the button's own text reader would compare.
        local vtable = nodes.proxyButton({
            target = tab,
            label = function()
                return chatTabs.tabName(frame)
            end,
        })
        if vtable ~= nil then
            tinsert(vtable.announcements, {
                text = function()
                    if frame:IsShown() then
                        return L["selected"]
                    end
                    return nil
                end,
                kind = kinds.selected,
            })
            builder:addItem(ControlId.forObject(tab), vtable)
        end
    end
    builder:endRow()
    builder:popContext()

    builder:popContext()
end

module:registerWindow({
    type = "ManualWindow", -- Only opened via Shift-F3 binding, not polled
    name = "chat",
    innate = true,
    graphScreen = { render = renderChat, captureClose = true },
})

module:registerBinding({
    type = "Script",
    key = "chat/openWindow",
    label = L["Chat"],
    inputs = { "SHIFT-F3" },
    script = "/run WowVision.UIHost:openWindow('chat')",
})

------------------------------------------------------------
-- Chat settings (ChatConfigFrame)
------------------------------------------------------------

local function checkboxGroup(builder, stopKey, frame, useLeft)
    if frame == nil or not frame:IsShown() then
        return
    end
    local groupFrame = frame
    if useLeft then
        groupFrame = _G[frame:GetName() .. "Left"]
    end
    if groupFrame == nil then
        return
    end
    builder:beginStop(stopKey)
    builder:pushContext(stopKey, groupFrame.header ~= nil and groupFrame.header:GetText() or "")
    local children = { groupFrame:GetChildren() }
    for i = 2, #children do
        if children[i]:IsShown() and children[i].CheckButton ~= nil then
            builder:addItem(
                ControlId.forObject(children[i].CheckButton),
                nodes.proxyCheckButton({ target = children[i].CheckButton })
            )
        end
    end
    builder:popContext()
end

local function renderChatConfig(builder, screen)
    if ChatConfigFrame == nil or not ChatConfigFrame:IsShown() then
        return
    end
    builder:pushContext("chatConfig", "Chat Settings")

    if ChatConfigCategoryFrame ~= nil and ChatConfigCategoryFrame:IsShown() then
        builder:beginStop("categories")
        builder:pushContext("categories", L["Categories"])
        local children = { ChatConfigCategoryFrame:GetChildren() }
        for i = 2, #children do
            local button = children[i]
            if button:IsShown() then
                local captured = button
                builder:addItem(
                    ControlId.forObject(captured),
                    nodes.proxyButton({
                        target = captured,
                        label = function()
                            local regions = { captured:GetRegions() }
                            return regions[1] ~= nil and regions[1]:GetText() or nil
                        end,
                    })
                )
            end
        end
        builder:popContext()
    end

    checkboxGroup(builder, "chatSettings", ChatConfigChatSettings, true)

    if ChatConfigChannelSettings ~= nil and ChatConfigChannelSettings:IsShown() then
        checkboxGroup(builder, "channelSettings", ChatConfigChannelSettings, true)
        local children = { ChatConfigChannelSettings:GetChildren() }
        local globalChannelsFrame = children[3]
        if globalChannelsFrame ~= nil then
            builder:beginStop("channels")
            builder:pushContext("channels", CHANNELS or "Channels")
            local channels = { globalChannelsFrame:GetChildren() }
            for i = 2, #channels do
                local channel = channels[i]
                if channel:IsShown() and channel.Button ~= nil then
                    local captured = channel
                    builder:addItem(
                        ControlId.forObject(captured.Button),
                        nodes.proxyButton({
                            target = captured.Button,
                            label = function()
                                return captured.Text ~= nil and captured.Text:GetText() or nil
                            end,
                        })
                    )
                end
            end
            builder:popContext()
        end
    end

    if ChatConfigOtherSettings ~= nil and ChatConfigOtherSettings:IsShown() then
        for i, child in ipairs({ ChatConfigOtherSettings:GetChildren() }) do
            checkboxGroup(builder, "other:" .. i, child, false)
        end
    end

    builder:popContext()
end

module:registerWindow({
    type = "FrameWindow",
    name = "ChatConfigFrame",
    frameName = "ChatConfigFrame",
    graphScreen = { render = renderChatConfig },
})
