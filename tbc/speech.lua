local module = WowVision.base:createModule("speech")
local L = module.L
module:setLabel(L["Speech"])
module:setVital(true)
local settings = module:hasSettings()

-- Mists Classic's StopSpeakingText does not reliably clear Blizzard's internal
-- TTS queue, so we can manage our own: only one utterance is ever in flight with
-- the client at a time, and we advance on the playback events. This works by
-- replacing C_VoiceChat.SpeakText so every caller (ours, Blizzard, other addons)
-- is routed through the queue. Because that global replacement can interfere with
-- other addons, it is gated behind the "Speech Queue" setting (on by default);
-- when the setting is off we leave C_VoiceChat.SpeakText untouched and speak
-- directly through it.
local oldSpeak = C_VoiceChat.SpeakText
module.queue = {}
module.speaking = false

local function pollQueue()
    if module.speaking then
        return
    end
    local item = tremove(module.queue, 1)
    if item == nil then
        return
    end
    -- Mark busy immediately so a poll triggered before PLAYBACK_STARTED arrives
    -- does not dispatch a second utterance on top of this one.
    module.speaking = true
    oldSpeak(item.voice, item.text, item.rate, item.volume, true)
end

local function enqueue(voice, text, rate, volume)
    tinsert(module.queue, { voice = voice, text = text, rate = rate, volume = volume })
    pollQueue()
end

-- Replacement for C_VoiceChat.SpeakText that routes all TTS through our queue.
-- Blizzard's own queueing (the overlap arg) is the thing we are replacing, so it
-- is intentionally ignored.
local function queuedSpeak(id, text, rate, volume, overlap)
    enqueue(id, text, rate, volume)
end

-- Install or remove the global queue depending on the setting. When disabled we
-- restore Blizzard's original function and drop any queue state so the client
-- speaks directly with no interference.
local function applyQueueSetting(enabled)
    if enabled then
        C_VoiceChat.SpeakText = queuedSpeak
    else
        C_VoiceChat.SpeakText = oldSpeak
        module.queue = {}
        module.speaking = false
    end
end

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

local queueSetting = settings:add({
    type = "Bool",
    key = "speechQueue",
    label = L["Speech Queue"],
    default = true,
})

queueSetting.events.valueChange:subscribe(nil, function(event, obj, key, value)
    applyQueueSetting(value)
end)

local function frame_OnEvent(frame, event, utteranceID)
    if event == "VOICE_CHAT_TTS_PLAYBACK_STARTED" then
        module.speaking = true
    elseif event == "VOICE_CHAT_TTS_PLAYBACK_FINISHED" or event == "VOICE_CHAT_TTS_PLAYBACK_FAILED" then
        -- FAILED fires instead of FINISHED for rejected utterances (too short,
        -- too long, internal error). Without handling it the queue stalls forever.
        module.speaking = false
        pollQueue()
    end
end

function module:createFrame()
    if self.frame then
        return
    end
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_STARTED")
    self.frame:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED")
    self.frame:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FAILED")
    self.frame:SetScript("OnEvent", frame_OnEvent)
end

function module:onEnable()
    self:createFrame()
    applyQueueSetting(self.settings.speechQueue ~= false)
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
    local text = string.gsub(text, "/", " / ")
    -- Volume above 100 silences TTS entirely in Mists Classic, so clamp it.
    local volume = self.settings.speechVolume or 100
    if volume < 0 then
        volume = 0
    elseif volume > 100 then
        volume = 100
    end
    -- Route through the (possibly replaced) global so the Speech Queue setting is
    -- the single switch: when on, this hits our queue; when off, Blizzard's
    -- original SpeakText runs directly.
    C_VoiceChat.SpeakText(self.settings.voiceID, text, self.settings.speechRate, volume, false)
end

function module:stop()
    self.queue = {}
    C_VoiceChat.StopSpeakingText()
    self.speaking = false
end

function module:uiStop()
    self:stop()
    return true
end
