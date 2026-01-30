local L = WowVision:getLocale()
local Output = WowVision.alerts.Output
local tts = WowVision.alerts:createOutput("TTS")
tts.info:addFields({
    { key = "buildMessage" },
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
    self:addParameter({
        key = "interrupt",
        type = "Bool",
        label = L["Priority Message (interrupts)"],
        default = function()
            return self.defaultInterrupt
        end,
    })
end

function tts:onFire(message)
    local message = message
    if self.buildMessage then
        message = self:buildMessage(message)
    else
        message = message.text
    end
    if self.db.interrupt then
        WowVision.base.speech:uiStop()
        if WowVision.consts.UI_DELAY > 0 then
            C_Timer.After(0.05, function()
                WowVision:speak(message)
            end)
        else
            WowVision:speak(message)
        end
    else
        WowVision:speak(message)
    end
end

local Sound = WowVision.alerts:createOutput("Sound")
Sound.info:addFields({
    { key = "getPath", required = true },
})

function Sound:onFire(message)
    local path
    if self.getPath then
        path = self:getPath(message)
    else
        return
    end
    WowVision:play(path)
end

local Voice = WowVision.alerts:createOutput("Voice")
Voice.info:addFields({
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
