local L = WowVision:getLocale()
local Output = WowVision.alerts.Output
local tts = WowVision.alerts:createOutput("TTS")
tts:addFields({
    { key = "buildMessage" },
    { key = "message" },
    -- A game TTS voice index: when set, the text is spoken by the game (at the speech module's rate
    -- and volume) instead of through the speech module, with the voice the output's Voice setting
    -- picks; this index is that setting's default. For announcements made while walking: a screen
    -- reader cuts its own speech off at every key press.
    { key = "voice" },
    {
        key = "interrupt",
        default = false,
        get = function(obj, key)
            return obj.defaultInterrupt
        end,
        set = function(obj, key, value)
            obj.defaultInterrupt = value
        end,
    },
})

function tts:initialize(info)
    Output.initialize(self, info)
    if self.voice == nil then
        self:addParameter({
            key = "interrupt",
            type = "Bool",
            label = L["Priority Message (interrupts)"],
            default = function()
                return self.defaultInterrupt
            end,
        })
        -- Spoken in the queue like all speech. Until a voice of its own is
        -- picked here, it follows the Speech Voice setting (and shows it).
        self:addParameter({
            key = "voice",
            type = "TtsVoice",
            label = L["Voice"],
            followVoice = function()
                return WowVision.base.speech.settings.voiceID
            end,
            default = WowVision.classes.SPEECH_VOICE,
        })
    else
        self:addParameter({
            key = "voice",
            type = "TtsVoice",
            label = L["Voice"],
            default = self.voice,
        })
    end
    if not self.buildMessage then
        self:addParameter({
            key = "message",
            type = "String",
            label = L["Message"],
            default = function()
                return self.message
            end,
        })
    end
end

function tts:onFire(message)
    local text
    if self.buildMessage then
        text = self:buildMessage(message)
    elseif self.db and self.db.message and self.db.message ~= "" then
        text = self.db.message
    else
        text = message.text
    end
    if not text then
        return
    end
    if self.voice ~= nil then
        local settings = WowVision.base.speech.settings
        local volume = math.max(0, math.min(100, settings.speechVolume or 100))
        local voice = self.parameters:getFieldValue("voice")
        if voice == nil then
            voice = self.voice
        end
        C_VoiceChat.SpeakText(voice, WowVision.ttsCacheBust.bust(text), settings.speechRate, volume, false)
        return
    end
    local voice = self.parameters:getFieldValue("voice")
    if voice == WowVision.classes.SPEECH_VOICE then
        voice = nil
    end
    if self.db.interrupt then
        WowVision.base.speech:uiStop()
        if WowVision.consts.UI_DELAY > 0 then
            C_Timer.After(0.05, function()
                WowVision:speak(text, voice)
            end)
        else
            WowVision:speak(text, voice)
        end
    else
        WowVision:speak(text, voice)
    end
end

local Sound = WowVision.alerts:createOutput("Sound")
Sound:addFields({
    { key = "getPath" },
    { key = "path" },
})

function Sound:initialize(info)
    Output.initialize(self, info)
    if not self.getPath then
        self:addParameter({
            key = "path",
            type = "DataBrowse",
            label = L["Sound"],
            directory = WowVision.audio.directory,
            default = function()
                return self.path
            end,
        })
    end
end

function Sound:onFire(message)
    local path
    if self.getPath then
        path = self:getPath(message)
    elseif self.db and self.db.path then
        path = self.db.path
    else
        return
    end
    WowVision:play(path)
end

local Voice = WowVision.alerts:createOutput("Voice")
Voice:addFields({
    { key = "getPath", required = true },
    {
        key = "voicePack",
        required = true,
        default = "Matthew",
        get = function(obj, key)
            return obj.defaultVoicePack
        end,
        set = function(obj, key, value)
            obj.defaultVoicePack = value
        end,
    },
})

function Voice:initialize(info)
    Output.initialize(self, info)
    self:addParameter({
        key = "voicePack",
        type = "VoicePack",
        default = function()
            return self.defaultVoicePack
        end,
    })
end

function Voice:fire(message)
    if not self.getPath then
        return
    end
    local speechType, speechPath = self:getPath(message)
    if speechType and speechPath then
        speechPath = "Voice/" .. self.db.voicePack .. "/" .. speechPath
        WowVision:play(speechPath)
    end
end

-- Directional beacon output. Unlike Sound, it picks a beacon soundset and plays
-- the file matching the message's angle/distance (a continuously-pinged,
-- spatialized sound). message = { angle = degrees in (-180,180], distance = yards }.
local floor = math.floor

local Beacon = WowVision.alerts:createOutput("Beacon")
Beacon:addFields({
    { key = "beacon" },
})

local function beaconDirectory()
    return WowVision.audio:getPath("Beacon")
end

function Beacon:initialize(info)
    Output.initialize(self, info)
    self:addParameter({
        key = "beacon",
        type = "DataBrowse",
        label = L["Beacon Sound"],
        directory = beaconDirectory,
        default = function()
            return self.beacon
        end,
    })
end

function Beacon:onFire(message)
    if not self.db or not self.db.beacon then
        return
    end
    local directory = beaconDirectory()
    if not directory then
        return
    end
    local source = directory:getPath(self.db.beacon)
    if not source or not source.play then
        return
    end
    -- The file's distance index is a compressed proximity bucket (~6 yards per
    -- step), not raw yards, so the beacon stays audible out to a long range.
    local fileDistance = floor((message.distance + 5) / 6)
    if fileDistance < 1 then
        fileDistance = 1
    end
    source:play(message.angle, fileDistance)
end
