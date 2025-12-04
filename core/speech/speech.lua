local Speech = WowVision.base:createModule("speech")
local L = Speech.L
Speech:setLabel(L["Speech"])
Speech:setVital(true)
local settings = Speech:hasSettings()

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

function Speech:onEnable()
    self.speechDelay = 0.1
    self.queueIndex = 1
    self.queue = {}
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

function Speech:onDisable()
    self.interruptFrame:Hide()
end

function Speech:speak(text)
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

function Speech:speakOld(text)
    if text == nil then
        return
    end
    if WowVision.emergency then
        C_VoiceChat.SpeakText(2, text, Enum.VoiceTtsDestination.ScreenReader, 0, 100)
        return
    end
    local destination = Enum.VoiceTtsDestination.QueuedLocalPlayback
    if self.settings.screenReader == true then
        destination = Enum.VoiceTtsDestination.ScreenReader
    end

    if self.settings.screenReader == false and self.speechDelay > 0 then
        local timer = C_Timer.NewTimer(self.speechDelay * self.queueIndex, function()
            C_VoiceChat.SpeakText(
                self.settings.voiceID,
                text,
                destination,
                self.settings.speechRate,
                self.settings.speechVolume
            )
            self.queueIndex = self.queueIndex - 1
        end)
        self.queueIndex = self.queueIndex + 1
        tinsert(self.queue, timer)
    else
        C_VoiceChat.SpeakText(
            self.settings.voiceID,
            text,
            destination,
            self.settings.speechRate,
            self.settings.speechVolume
        )
    end
end

function Speech:stop()
    C_VoiceChat.StopSpeakingText()
    for i, v in ipairs(self.queue) do
        v:Cancel()
    end
    self.queue = {}
    self.queueIndex = 1
end

function Speech:uiStop()
    self:stop()
    return true
end
