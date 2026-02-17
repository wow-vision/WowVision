local module = WowVision.base:createModule("speech")
local L = module.L
module:setLabel(L["Speech"])
module:setVital(true)
local settings = module:hasSettings()

local voiceSetting = settings:add({
    type = "Choice",
    key = "voiceID",
    label = L["Speech Voice"],
    default = 0,
})

for _, v in ipairs(C_VoiceChat.GetTtsVoices()) do
    voiceSetting:addChoice({
        label = v.name,
        value = v.voiceID,
    })
end

settings:add({
    type = "Number",
    key = "speechVolume",
    label = L["Speech Volume"],
    default = 100,
})

settings:add({
    type = "Number",
    key = "speechRate",
    label = L["Speech Rate"],
    default = 0,
})

function module:onEnable()
    self.speechDelay = 0.1
    self.pendingInterrupt = false
    self.speechQueue = {}
    if not self.interruptFrame then
        self.interruptFrame = CreateFrame("Frame")
        self.interruptFrame:EnableKeyboard(true)
        self.interruptFrame:SetPropagateKeyboardInput(true)
        self.interruptFrame:SetScript("OnKeyDown", function(frame, key)
            if key == "LCTRL" or key == "RCTRL" then
                WowVision.base.speech:uiStop()
            end
        end)
    end
    self.interruptFrame:Show()
end

function module:onDisable()
    self.interruptFrame:Hide()
end

function module:speak(text)
    if self.pendingInterrupt then
        tinsert(self.speechQueue, text)
        return
    end
    local text = string.gsub(text, "/", " / ")
    local destination = Enum.VoiceTtsDestination.QueuedLocalPlayback
    C_VoiceChat.SpeakText(
        self.settings.voiceID,
        text,
        destination,
        self.settings.speechRate,
        self.settings.speechVolume
    )
end

function module:flushSpeechQueue()
    self.pendingInterrupt = false
    local queue = self.speechQueue
    self.speechQueue = {}
    for _, text in ipairs(queue) do
        self:speak(text)
    end
end

function module:stop()
    C_VoiceChat.StopSpeakingText()
end

function module:uiStop()
    self:stop()
    self.pendingInterrupt = true
    self.speechQueue = {}
    C_Timer.After(0, function()
        self:flushSpeechQueue()
    end)
    return true
end
