local module = WowVision.base.chat
module:hasUI()
local gen = module.elementGenerator
local L = module.L

gen:Element("chat", function(props)
    local result = {
        "Panel",
        label = L["Chat"],
        children = {
            { "chat/Messages" },
            { "chat/Tabs" },
        },
    }
    return result
end)

gen:Element("chat/Tabs", function(props)
    local result = { "List", label = L["Tabs"], direction = "horizontal", children = {} }
    local frameCount = FCF_GetNumActiveChatFrames()
    local count = frameCount
    if count == 0 then
        return result
    end
    for i = 1, 10 do
        local frame = _G["ChatFrame" .. i .. "Tab"]
        if frame:IsShown() then
            tinsert(result.children, { "ProxyButton", frame = frame, selected = _G["ChatFrame" .. i]:IsShown() })
            count = count - 1
            if count < 1 then
                return result
            end
        end
    end
    return result
end)

gen:Element("chat/Messages", function(props)
    local frame = SELECTED_CHAT_FRAME
    local index = frame:GetID()
    if not module.frames[index] then
        return nil
    end
    local buffer = module.frames[index].buffer
    if not buffer then
        return nil
    end
    local result = { "MessageBufferView", label = frame.name, buffer = buffer }
    return result
end)

gen:Element("ChatConfig", function(props)
    local frame = ChatConfigFrame
    local result = {
        "Panel",
        label = "Chat Settings",
        children = {
            --This is temporarily commented out due to a bug
            --{"ChatConfig/ChatTabManager", frame = frame.ChatTabManager},
        },
    }
    if ChatConfigCategoryFrame:IsShown() then
        tinsert(result.children, { "ChatConfig/ChatConfigCategoryFrame", frame = ChatConfigCategoryFrame })
    end
    tinsert(result.children, { "ChatConfig/Checkboxes", frame = ChatConfigChatSettings, containingFrame = true })
    tinsert(result.children, { "ChatConfig/ChatConfigChannelSettings", frame = ChatConfigChannelSettings })
    tinsert(result.children, { "ChatConfig/ChatConfigOtherSettings", frame = ChatConfigOtherSettings })
    return result
end)

gen:Element("ChatConfig/ChatTabManager", function(props)
    local result = { "List", direction = "horizontal", label = L["Tabs"], children = {} }
    local children = { props.frame:GetChildren() }
    for _, v in ipairs(children) do
        tinsert(result.children, { "ProxyButton", frame = v })
    end
    return result
end)

gen:Element("ChatConfig/ChatConfigCategoryFrame", function(props)
    local result = { "List", label = "Categories", children = {} }
    local children = { props.frame:GetChildren() }
    for i = 2, #children do
        local button = children[i]
        local regions = { button:GetRegions() }
        tinsert(result.children, { "ProxyButton", frame = button, label = regions[1]:GetText() })
    end
    return result
end)

gen:Element("ChatConfig/Checkboxes", function(props)
    if not props.frame or not props.frame:IsShown() then
        return nil
    end
    local frame = props.frame
    if props.containingFrame then
        frame = _G[props.frame:GetName() .. "Left"]
    end
    local result = { "List", label = frame.header:GetText(), children = {} }
    local children = { frame:GetChildren() }
    for i = 2, #children do
        if children[i]:IsShown() then
            local button = children[i].CheckButton
            tinsert(result.children, { "ProxyCheckButton", frame = button })
        end
    end
    return result
end)

gen:Element("ChatConfig/ChatConfigChannelSettings", function(props)
    if not ChatConfigChannelSettings:IsShown() then
        return nil
    end
    local result = {
        "Panel",
        layout = true,
        children = {
            { "ChatConfig/Checkboxes", frame = props.frame, containingFrame = true },
        },
    }
    local children = { props.frame:GetChildren() }
    local globalChannelsFrame = children[3]
    if not globalChannelsFrame then
        return result
    end
    local channelList = { "List", children = {} }
    local channels = { globalChannelsFrame:GetChildren() }
    for i = 2, #channels do
        local channel = channels[i]
        if channel:IsShown() then
            tinsert(channelList.children, {
                "List",
                displayType = "",
                label = channel.Text:GetText(),
                children = {
                    { "ProxyButton", frame = channel.Button },
                },
            })
        end
    end
    tinsert(result.children, channelList)
    return result
end)

gen:Element("ChatConfig/ChatConfigOtherSettings", function(props)
    if not props.frame:IsShown() then
        return nil
    end
    local result = { "List", children = {} }
    local children = { props.frame:GetChildren() }
    for _, v in ipairs(children) do
        tinsert(result.children, { "ChatConfig/Checkboxes", frame = v })
    end

    return result
end)

module:registerWindow({
    name = "chat",
    auto = false,
    innate = true,
    generated = true,
    rootElement = "chat",
    hookEscape = true,
    isOpen = function()
        for i = 1, FCF_GetNumActiveChatFrames() do
            local frame = _G["ChatFrame" .. i]
            if frame and frame.editBox:IsShown() then
                return true
            end
        end
        return false
    end,
})

module:registerWindow({
    name = "ChatConfigFrame",
    auto = true,
    generated = true,
    rootElement = "ChatConfig",
    frameName = "ChatConfigFrame",
})

module:registerBinding({
    type = "Script",
    key = "chat/openWindow",
    label = L["Chat"],
    inputs = { "SHIFT-F3" },
    script = "/run WowVision.UIHost:openWindow('chat')",
})
