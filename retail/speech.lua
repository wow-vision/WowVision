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

-- Speech beside the queue (module:speakAside) plays at once and may overlap
-- anything; its playback events must not end the queue's turn. WoW: Forever
-- sends only playback started and finished with an utterance id, no text
-- update naming the call (measured 2026-10-03), so each start is matched to
-- the calls in the order they were made. A call whose start has not come
-- within two seconds is dropped from the line, and a stop of all speech
-- empties it (see the hook below). Speech the game starts by itself
-- (Combat Audio Alerts) is not announced and can shift the matching while
-- the line is busy; it heals once the line runs empty.
local START_WAIT = 2
local pendingStarts = {}
local asideUtterances = {}

-- `silent`: called at volume 0 (it may wait without anything to hear).
-- atMs: the call on debugprofilestop's clock, for whoever asks who started
-- (module:startOwner).
local function expectStart(owner, silent)
    tinsert(pendingStarts, { owner = owner, at = GetTime(), atMs = debugprofilestop(), silent = silent })
end

-- The engine never starts an utterance sooner after its call (34 to 56 ms
-- measured): a start sooner after the oldest waiting call is not that
-- call's but someone's who calls the engine without us (Blizzard's Combat
-- Audio Alerts), and leaves the line as it is. Measured on
-- debugprofilestop's clock: GetTime() moves once a frame, and a start can
-- be handled a frame "sooner" than it happened (first game test,
-- 2026-10-14: own starts taken for someone else's, every match after them
-- shifted, a third of the checks lost).
local FIRST_START_MS = 30

-- Who each recent start belonged to: the call it was matched to (false:
-- none, someone else's), the last 64.
local startOwners = {}
local startOrder = {}
local START_OWNERS_KEPT = 64

-- Utterances playing now (started, not ended; a stop ends them all, and
-- a stopped one never reports its end), by id, with when they started.
local playing = {}
-- Longer than any utterance plays: an entry this old lost its end.
local PLAYING_FORGET = 30

-- Who can tell that an utterance of theirs is silent (the group health
-- monitor's timing samples, readback.lua): function(id) true when silent.
local silentJudges = {}

function module:addSilentJudge(judge)
    tinsert(silentJudges, judge)
end

local function knownSilent(id)
    for _, judge in ipairs(silentJudges) do
        if judge(id) then
            return true
        end
    end
    return false
end

-- Whether anything that can be heard is playing or about to: our queue,
-- anything else playing (other speech, Blizzard's alerts, numbers beside
-- the queue), or speech called and not started yet that is not silent.
function module:audibleNow()
    if self.speaking or #self.queue > 0 then
        return true
    end
    local now = GetTime()
    for id, startedAt in pairs(playing) do
        if now - startedAt > PLAYING_FORGET then
            playing[id] = nil
        elseif not knownSilent(id) then
            return true
        end
    end
    for _, entry in ipairs(pendingStarts) do
        if not entry.silent and now - entry.at <= START_WAIT then
            return true
        end
    end
    return false
end

local function takeStart()
    local now = GetTime()
    while pendingStarts[1] ~= nil and now - pendingStarts[1].at > START_WAIT do
        tremove(pendingStarts, 1)
    end
    local head = pendingStarts[1]
    if head == nil or debugprofilestop() - head.atMs < FIRST_START_MS then
        return nil
    end
    return tremove(pendingStarts, 1)
end

-- Matches a start to its call once; whoever sees the start first (this
-- module's frame or the group health monitor) does it.
local function resolveStart(id)
    local known = startOwners[id]
    if known ~= nil then
        return known or nil
    end
    local entry = takeStart()
    startOwners[id] = entry or false
    tinsert(startOrder, id)
    while #startOrder > START_OWNERS_KEPT do
        startOwners[tremove(startOrder, 1)] = nil
    end
    return entry
end

-- Who started utterance `id` (call it when its start comes): "queue" (our
-- queue: WowVision's speech, Blizzard's chat speech), "aside" (beside the
-- queue: the group health monitor) or nil (no call of ours: Blizzard's
-- Combat Audio Alerts), and when it was called (debugprofilestop ms).
-- Matched by order, so speech we cannot see can shift it: the group health
-- monitor uses it only where the order of the ids confirms it.
function module:startOwner(id)
    local entry = resolveStart(id)
    if entry == nil then
        return nil
    end
    return entry.owner, entry.atMs
end

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
    expectStart("queue")
    oldSpeak(item.voice, item.text, item.rate, item.volume, true)
end

local function enqueue(voice, text, rate, volume)
    tinsert(module.queue, { voice = voice, text = text, rate = rate, volume = volume })
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

-- The game's sounds around text-to-speech (see core/speechSounds.lua): two
-- toggles that are the game's own settings, and the line-break sound
-- turned off once per character.
WowVision.speechSounds.attach(module, settings, L)

local function frame_OnEvent(frame, event, utteranceID)
    if event == "VOICE_CHAT_TTS_PLAYBACK_STARTED" then
        playing[utteranceID] = GetTime()
    else
        playing[utteranceID] = nil
    end
    if event == "VOICE_CHAT_TTS_PLAYBACK_STARTED" then
        local entry = resolveStart(utteranceID)
        if entry ~= nil and entry.owner == "aside" then
            asideUtterances[utteranceID] = true
            return
        end
        module.speaking = true
    elseif event == "VOICE_CHAT_TTS_PLAYBACK_FINISHED" or event == "VOICE_CHAT_TTS_PLAYBACK_FAILED" then
        if asideUtterances[utteranceID] then
            asideUtterances[utteranceID] = nil
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
function module:speak(text)
    -- Volume above 100 silences TTS entirely in Mists Classic, so clamp it.
    local volume = self.settings.speechVolume or 100
    if volume < 0 then
        volume = 0
    elseif volume > 100 then
        volume = 100
    end
    -- Route through the (possibly replaced) global so the Speech Queue setting is
    -- the single switch: when on, this hits our queue; when off, Blizzard's
    -- original SpeakText runs directly. Busted here so both paths get it.
    text = WowVision.ttsCacheBust.bust(text)
    C_VoiceChat.SpeakText(self.settings.voiceID, text, self.settings.speechRate, volume, false)
end

-- Speaks straight through the engine with overlap, beside the queue: for
-- announcements that must not wait behind other speech and are mostly
-- silent (the group health monitor gates its numbers by volume, and a
-- silent word takes as long as a spoken one). The caller picks the voice:
-- markup like <pitch> needs a real SAPI voice. The text is passed as is,
-- so the caller busts the engine's audio cache itself.
function module:speakAside(voice, text, rate, volume)
    if volume == nil or volume > 100 then
        volume = 100
    elseif volume < 0 then
        volume = 0
    end
    expectStart("aside", volume == 0)
    -- (Returned for the probe: the engine documents no return.)
    return oldSpeak(voice, text, rate or 0, volume, true)
end

-- Stops all speech; the game has only one stop, for every utterance at
-- once. With nothing to hear playing (only the group health monitor's
-- silent timing samples) there is nothing to stop, and the stop is left
-- out: those samples go on (2026-10-14; a stop costs the monitor every
-- check out, and keys and Ctrl come often). What can be heard is stopped
-- exactly as before.
function module:stop()
    self.queue = {}
    if self:audibleNow() then
        C_VoiceChat.StopSpeakingText()
    end
    self.speaking = false
end

-- Whoever stops all speech: a stopped utterance never reports its end
-- (Blizzard's TextToSpeechFrame.lua), and calls cut before their start
-- never start. Without this a stale entry would take the queue's next
-- start as speech beside it, swallow its end and stall the queue.
hooksecurefunc(C_VoiceChat, "StopSpeakingText", function()
    wipe(playing)
    wipe(pendingStarts)
    wipe(asideUtterances)
    module.speaking = false
    pollQueue()
end)

function module:uiStop()
    self:stop()
    return true
end
