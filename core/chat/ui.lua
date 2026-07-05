local module = WowVision.base.chat
local L = module.L

local graph = WowVision.graph
local nodes = graph.nodes
local ControlId = graph.ControlId
local kinds = graph.kinds

-- The chat reader (Shift-F3): the message log is ONE node holding a cursor
-- over the message buffer (up to 5000 entries), not a node per message --
-- per-node bindings take over up, down, home, and end while it is focused
-- and speak messages directly, so the per-tick rebuild cost is constant.
-- The label is not live: movement speech is manual, and buffer eviction
-- shifting indices under the cursor must not re-announce.

local function currentBuffer()
    local frame = SELECTED_CHAT_FRAME
    local index = frame ~= nil and frame:GetID() or nil
    local entry = index ~= nil and module.frames[index] or nil
    return entry ~= nil and entry.buffer or nil
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
        speak()
    end

    return {
        controlType = graph.controlTypes.text,
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
            -- Land on the latest message.
            local buffer = currentBuffer()
            screen._chatIndex = buffer ~= nil and #buffer.items or 0
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
        },
    }
end

local function renderChat(builder, screen)
    builder:pushContext("chat", L["Chat"])

    builder:beginStop("messages")
    builder:pushContext("messages", SELECTED_CHAT_FRAME ~= nil and SELECTED_CHAT_FRAME.name or L["Chat"], nil, false)
    builder:addItem(ControlId.structural("messages"), messagesNode(screen))
    builder:popContext()

    builder:beginStop("tabs")
    builder:pushContext("tabs", L["Tabs"])
    builder:startRow()
    local remaining = FCF_GetNumActiveChatFrames()
    for i = 1, 10 do
        if remaining < 1 then
            break
        end
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab ~= nil and tab:IsShown() then
            remaining = remaining - 1
            local frameIndex = i
            local vtable = nodes.proxyButton({ target = tab })
            if vtable ~= nil then
                tinsert(vtable.announcements, {
                    text = function()
                        local frame = _G["ChatFrame" .. frameIndex]
                        if frame ~= nil and frame:IsShown() then
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
