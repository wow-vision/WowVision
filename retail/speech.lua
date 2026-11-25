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
-- Tagged lines: module:withTag, module:dropQueued (core/speechTags.lua).
WowVision.speechTags.install(module)

-- After a stop the next line cuts a screen reader bridge voice (core/speechInterrupt.lua).
local handOver = WowVision.speechInterrupt.handOver

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
    oldSpeak(item.voice, handOver(item.text), item.rate, item.volume, true)
end

local function enqueue(voice, text, rate, volume)
    tinsert(module.queue, { voice = voice, text = text, rate = rate, volume = volume, tag = module.queueTag })
    pollQueue()
end

-- Replacement for C_VoiceChat.SpeakText that routes all TTS through our queue.
-- Blizzard's own queueing (the overlap arg) is the thing we are replacing, so it
-- is intentionally ignored. Other callers' text gets the cache-buster too (see
-- core/ttsCacheBust.lua); ours arrives already busted and passes through.
local function queuedSpeak(id, text, rate, volume, overlap)
    enqueue(id, WowVision.ttsCacheBust.bustForeign(text), rate, volume)
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

-- Saved by the voice's name, so installing voices keeps it (core/fieldTypes.lua).
settings:add({
    type = "TtsVoice",
    key = "voiceID",
    label = L["Speech Voice"],
    default = 0,
})

settings:add({
    type = "Number",
    key = "speechVolume",
    label = L["Speech Volume"],
    default = 100,
    min = 0,
    max = 100,
})

settings:add({
    type = "Number",
    key = "speechRate",
    label = L["Speech Rate"],
    default = 0,
    -- The range the game's voices take.
    min = -10,
    max = 10,
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

-- The game's sounds around text-to-speech (see core/speechSounds.lua): two
-- toggles that are the game's own settings, and the line-break sound
-- turned off once per character.
WowVision.speechSounds.attach(module, settings, L)

-- The chat's own channel ------------------------------------------------------
-- With Chat Voice on Its Own Channel, a chat message read in a voice other than the speech voice goes to the engine on
-- its own, beside the queue: the engine plays it while WowVision's lines play, chat lines one after the other (overlap
-- false). While one plays, WowVision's stops leave it alone (Keep Chat Messages When Speech Stops); Stop Chat Voice
-- cuts it. Nothing in the engine's events tells a chat line apart, so how long one plays is estimated from its length
-- and rate, leaning long: holding a stop back a little too long costs nothing, cutting a message loses it.
settings:add({
    type = "Bool",
    key = "chatChannel",
    label = L["Chat Voice on Its Own Channel"],
    default = false,
})
settings:add({
    type = "Bool",
    key = "chatProtect",
    label = L["Keep Chat Messages When Speech Stops"],
    default = true,
})
settings:add({
    type = "Number",
    key = "chatRateOffset",
    label = L["Chat Voice Rate Difference"],
    default = 0,
    min = -10,
    max = 10,
})
-- A SAPI pitch tag around the message, as the group health monitor's numbers (a real Windows voice honours it, the
-- screen reader bridge ignores it).
settings:add({
    type = "Number",
    key = "chatPitch",
    label = L["Chat Voice Pitch"],
    default = 0,
    min = -10,
    max = 10,
})

local ASIDE_SPEED = 12 -- characters per second at rate 0
local ASIDE_MARGIN = 1
local ASIDE_UNKNOWN = 8 -- a hidden text, whose length cannot be read

-- Until when chat lines are estimated to play, and the utterance ids of chat lines seen starting.
module.asideUntil = 0
module.asideIds = {}

function module:asideBusy()
    return self.asideUntil > 0 and GetTime() < self.asideUntil
end

function module:asideRate()
    local rate = (self.settings.speechRate or 0) + (self.settings.chatRateOffset or 0)
    return math.max(-10, math.min(10, rate))
end

function module.asideSeconds(text, rate)
    if WowVision.secrets.isSecret(text) then
        return ASIDE_UNKNOWN
    end
    return #text / (ASIDE_SPEED * 3 ^ (rate / 10)) + ASIDE_MARGIN
end

local function pitched(text, pitch)
    if pitch == 0 or WowVision.secrets.isSecret(text) then
        return text
    end
    local escaped = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    return '<pitch absmiddle="' .. pitch .. '">' .. escaped .. "</pitch>"
end

-- Speaks a chat line beside the queue when the player wants that and the voice is one of its own. True when taken.
function module:speakAside(text, voice)
    if not self.settings.chatChannel or voice == nil or voice == self.settings.voiceID then
        return false
    end
    local rate = self:asideRate()
    local volume = math.max(0, math.min(100, self.settings.speechVolume or 100))
    local seconds = module.asideSeconds(text, rate)
    oldSpeak(voice, WowVision.ttsCacheBust.bust(pitched(text, self.settings.chatPitch or 0)), rate, volume, false)
    self.asideUntil = math.max(self.asideUntil, GetTime()) + seconds
    return true
end

local function frame_OnEvent(frame, event, _, utteranceID)
    if event == "VOICE_CHAT_TTS_PLAYBACK_STARTED" then
        -- Every line of ours is marked as playing when it is handed over: a start that finds nothing marked while a chat
        -- line plays is that chat line, and must not hold the queue.
        if not module.speaking and module:asideBusy() then
            if utteranceID ~= nil then
                module.asideIds[utteranceID] = true
            end
            return
        end
        module.speaking = true
    elseif event == "VOICE_CHAT_TTS_PLAYBACK_FINISHED" or event == "VOICE_CHAT_TTS_PLAYBACK_FAILED" then
        -- A chat line ending says nothing about WowVision's line.
        if utteranceID ~= nil and module.asideIds[utteranceID] then
            module.asideIds[utteranceID] = nil
            return
        end
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

-- No string handling on the text here: retail hands addons SECRET values
-- (unit health among them) that survive concatenation into a label but
-- throw on any string operation. The speech API accepts secret strings,
-- so the text goes through untouched (the cache-buster only concatenates
-- onto a secret, from a shared counter it cannot key by text).
--
-- voice, rate and volume are optional: the Speech settings apply where a
-- caller gives none (the group health monitor speaks with a voice, rate and
-- volume of its own).
function module:speak(text, voice, rate, volume)
    -- Volume above 100 silences TTS entirely in Mists Classic, so clamp it.
    volume = volume or self.settings.speechVolume or 100
    if volume < 0 then
        volume = 0
    elseif volume > 100 then
        volume = 100
    end
    -- Route through the (possibly replaced) global so the Speech Queue setting is
    -- the single switch: when on, this hits our queue; when off, Blizzard's
    -- original SpeakText runs directly. Busted here so both paths get it.
    text = WowVision.ttsCacheBust.bust(text)
    if C_VoiceChat.SpeakText ~= queuedSpeak then
        -- (without the queue this is the hand-over)
        text = handOver(text)
    end
    C_VoiceChat.SpeakText(voice or self.settings.voiceID, text, rate or self.settings.speechRate, volume, false)
end

-- Whether nothing is queued or playing. The group health monitor sends its
-- repeat one announcement at a time only while this holds, so its mostly
-- silent announcements never hold back other speech.
function module:idle()
    return not self.speaking and #self.queue == 0
end

-- force: cut a chat line of its own channel too (Stop Chat Voice).
function module:stop(force)
    self.queue = {}
    if not force and self.asideUntil ~= nil and self:asideBusy() and self.settings.chatProtect ~= false then
        -- The engine's stop would cut the chat line as well: not called. The next line still cuts a screen reader.
        WowVision.speechInterrupt.noteStop()
    else
        self.asideUntil = 0
        self.asideIds = {}
        C_VoiceChat.StopSpeakingText()
    end
    self.speaking = false
end

function module:uiStop()
    self:stop()
    return true
end

module:registerBinding({
    type = "Function",
    key = "speech/stopChat",
    inputs = { "ALT-SHIFT-C" },
    label = L["Stop Chat Voice"],
    func = function()
        module:stop(true)
        WowVision:speak(L["Chat voice stopped."])
    end,
})
