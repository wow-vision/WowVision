local L = WowVision:getLocale()
local Output = WowVision.alerts.Output
local tts = WowVision.alerts:createOutput("TTS")
tts.info:addFields({
    { key = "buildMessage" },
    { key = "message" },
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
    if self.db.interrupt then
        WowVision.base.speech:uiStop()
        if WowVision.consts.UI_DELAY > 0 then
            C_Timer.After(0.05, function()
                WowVision:speak(text)
            end)
        else
            WowVision:speak(text)
        end
    else
        WowVision:speak(text)
    end
end

local Sound = WowVision.alerts:createOutput("Sound")
Sound.info:addFields({
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
