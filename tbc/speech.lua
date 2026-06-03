-- Base class for speech output strategies
local SpeechStyle = WowVision.Class("SpeechStyle")

function SpeechStyle:initialize(config)
    self.module = config.module
end

function SpeechStyle:output(text)
    local text = string.gsub(text, "/", " / ")
    local destination = Enum.VoiceTtsDestination.QueuedLocalPlayback
    C_VoiceChat.SpeakText(
        self.module.settings.voiceID,
        text,
        destination,
        self.module.settings.speechRate,
        self.module.settings.speechVolume
    )
end

function SpeechStyle:speak(text) end
function SpeechStyle:uiStop() end
function SpeechStyle:destroy() end

-- Module setup
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

-- Speech style registry and setting
local styles = module:createComponentRegistry({
    key = "styles",
    type = "class",
    baseClass = SpeechStyle,
    classNamePrefix = "SpeechStyle_",
})

local styleSetting = settings:add({
    type = "Choice",
    key = "speechStyle",
    label = L["Speech Style"],
    default = "direct",
})

-- Direct style: pendingInterrupt flag + next-frame flush
local Direct = styles:createType({ key = "direct" })
styleSetting:addChoice({ label = L["Direct"], value = "direct" })

function Direct:initialize(config)
    SpeechStyle.initialize(self, config)
    self.pendingInterrupt = false
    self.speechQueue = {}
end

function Direct:speak(text)
    if self.pendingInterrupt then
        tinsert(self.speechQueue, text)
        return
    end
    self:output(text)
end

function Direct:uiStop()
    C_VoiceChat.StopSpeakingText()
    if self.pendingInterrupt then
        return
    end
    self.pendingInterrupt = true
    self.speechQueue = {}
    C_Timer.After(0, function()
        self.pendingInterrupt = false
        local queue = self.speechQueue
        self.speechQueue = {}
        for _, text in ipairs(queue) do
            self:speak(text)
        end
    end)
end

-- Queued style: OnUpdate-driven queue with delay after stop
local QUEUE_RESET = {} -- unique sentinel marker for interrupt
local Queued = styles:createType({ key = "queued" })
styleSetting:addChoice({ label = L["Buffered"], value = "queued" })

function Queued:initialize(config)
    SpeechStyle.initialize(self, config)
    self.queue = {}
    self.waitTimer = 0
    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnUpdate", function(_, elapsed)
        self:onUpdate(elapsed)
    end)
end

function Queued:speak(text)
    tinsert(self.queue, text)
end

function Queued:uiStop()
    tinsert(self.queue, QUEUE_RESET)
end

function Queued:onUpdate(elapsed)
    if #self.queue == 0 then
        return
    end

    -- Find last queuereset marker, discard everything before it
    local lastReset
    for i = 1, #self.queue do
        if self.queue[i] == QUEUE_RESET then
            lastReset = i
        end
    end
    if lastReset then
        for i = 1, lastReset - 1 do
            tremove(self.queue, 1)
        end
    end

    -- Wait after stop before speaking (skip wait if multiple items are queued)
    if self.waitTimer > 0 then
        if #self.queue <= 1 then
            self.waitTimer = self.waitTimer - elapsed
            return
        end
        self.waitTimer = 0
    end

    -- Drain all ready items
    while #self.queue > 0 do
        local front = self.queue[1]
        tremove(self.queue, 1)

        if front == QUEUE_RESET then
            C_VoiceChat.StopSpeakingText()
            self.waitTimer = 0.1
            return
        else
            self:output(front)
        end
    end
end

function Queued:destroy()
    self.frame:SetScript("OnUpdate", nil)
    self.frame = nil
    self.queue = {}
end

-- Module lifecycle
styleSetting.events.valueChange:subscribe(nil, function(event, proxy, value)
    if module.activeStyle then
        module.activeStyle:destroy()
    end
    module.activeStyle = styles:createTemporaryComponent({ type = value, module = module })
end)

function module:onEnable()
    self.activeStyle = styles:createTemporaryComponent({ type = self.settings.speechStyle, module = self })
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
    if self.activeStyle then
        self.activeStyle:destroy()
        self.activeStyle = nil
    end
end

function module:speak(text)
    self.activeStyle:speak(text)
end

function module:stop()
    C_VoiceChat.StopSpeakingText()
end

function module:uiStop()
    self.activeStyle:uiStop()
    return true
end
