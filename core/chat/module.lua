local module = WowVision.base:createModule("chat")
local L = module.L
module:setLabel(L["Chat"])
local settings = module:hasSettings()

local messageAlert = module:addAlert({
    key = "message",
    label = L["Message Alert"],
})

messageAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return message.message
    end,
})

messageAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    getPath = function(self, message)
        return "Sound/WowVision/alerts/chat.mp3"
    end,
})

settings:addRef("messageAlert", messageAlert.parameters)

function module:getDefaultData()
    return {
        frames = {},
    }
end

function module.getMessageString(data)
    return data.message .. " " .. data.datetime
end

function module.onMessage(frame, message, r, g, b, typeID)
    local index = frame:GetID()
    local ref = module.frames[index]
    if not ref then
        return
    end
    local chatType = nil
    if typeID then
        chatType = C_ChatInfo.GetChatTypeName(typeID)
    end
    local data = {
        message = message,
        chatType = chatType,
        datetime = date("%m/%d/%y %H:%M:%S"),
    }
    ref.buffer:add(data)
    if frame:IsShown() then
        messageAlert:fire(data)
    end
end

function module:onDisable()
    local frameCount = FCF_GetNumActiveChatFrames() + 1
    for i = 1, frameCount do
        local frame = _G["ChatFrame" .. i]
        WowVision.UIHost:unhookFunc(frame, "AddMessage", self.onMessage)
    end
end

function module:addFrame(frame, index)
    local data = self.data[index]
    if not data then
        self.data[index] = { history = {} }
        data = self.data[index]
    end
    local ref = {
        frame = frame,
        exists = true,
        data = data,
        buffer = WowVision.buffers:create("Message", {
            messages = data.history,
            maxMessages = 5000,
            getDataString = self.getMessageString,
        }),
    }
    WowVision.UIHost:hookFunc(frame, "AddMessage", self.onMessage)
    self.frames[index] = ref

    --add any messages in the frame before it was registered
    for i = 1, frame:GetNumMessages() do
        local message, r, g, b, id = frame:GetMessageInfo(i)
        self.onMessage(frame, message, r, g, b, id)
    end
end

function module:removeFrame(frame, index)
    local ref = self.frames[index]
    WowVision.UIHost:unhookFunc(ref.frame, "AddChatMessage", self.onMessage)
    self.frames[index] = nil
    self.data[index] = nil
end

function module:runCompareFrames(frame, i)
    local ref = self.frames[i]
    local validFrame = FCF_IsValidChatFrame(frame)
    if not ref and validFrame then
        self:addFrame(frame, i)
        return
    end
    if ref and not validFrame then
        self:removeFrame(frame, i)
    end
end

function module:onEnable()
    self.frames = {}
    self:hasUpdate(function(self)
        for i = 1, 10 do
            local frame = _G["ChatFrame" .. i]
            self:runCompareFrames(frame, i)
        end
    end)
end
