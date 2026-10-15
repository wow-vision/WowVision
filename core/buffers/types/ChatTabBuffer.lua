local L = WowVision:getLocale()

-- One of the game's chat tabs as a buffer: the same lines the chat reader
-- (Shift-F3) shows for that tab, read with the buffer keys from anywhere.
-- The tab's content is set where the game sets it, in its chat settings.
local ChatTabBuffer = WowVision.buffers.registry:createType({ key = "ChatTab", parent = "Message" })

-- Chat tabs open after the buffers restore, and close while a buffer still
-- points at them, so the list reads the game's windows each time: the open
-- tabs by name, the whisper tabs as one, and the current choice always.
local function tabChoices(obj)
    local chatTabs = WowVision.chatTabs
    local choices = {}
    local current = obj ~= nil and obj.tab or nil
    for index = 1, chatTabs.MAX_WINDOWS do
        local key = chatTabs.storeKey(index)
        local frame = _G["ChatFrame" .. index]
        local open = frame ~= nil and FCF_IsValidChatFrame ~= nil and FCF_IsValidChatFrame(frame)
        if open or key == current then
            tinsert(choices, { value = key, label = chatTabs.tabLabel(index) })
        end
    end
    tinsert(choices, { value = chatTabs.WHISPERS_KEY, label = L["Whisper Tabs"] })
    return choices
end

ChatTabBuffer:addFields({
    {
        key = "tab",
        type = "Choice",
        label = L["Chat Tab"],
        persist = true,
        sortPriority = 2,
        default = "chat.1",
        choices = tabChoices,
    },
})

function ChatTabBuffer:initialize(obj)
    WowVision.buffers.MessageBuffer.initialize(self, obj)
    self.class:getField("tab").events.valueChange:subscribe(self, function(subscriber, event, target, key, value)
        if target == subscriber then
            subscriber:setSourceKey(value)
        end
    end)
    self:setSourceKey(self.tab)
end

-- Unnamed, the buffer is called by its tab.
function ChatTabBuffer:getLabel()
    if self.label ~= nil and self.label ~= "" then
        return self.label
    end
    if self.tab == WowVision.chatTabs.WHISPERS_KEY then
        return L["Whisper Tabs"]
    end
    local index = self.tab ~= nil and tonumber(self.tab:match("^chat%.(%d+)$")) or nil
    if index ~= nil then
        return WowVision.chatTabs.tabLabel(index)
    end
    return L["Chat Tab"]
end
