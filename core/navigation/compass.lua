local module = WowVision.base.navigation:createModule("compass")
local L = module.L
-- Named for what it holds: facing, zone, indoors, flying, water and breath
-- alerts. The key stays "compass" so saved settings carry over.
module:setLabel(L["Environmental Alerts"])
local pi = math.pi
local breathSteps = WowVision.breathSteps
local settings = module:hasSettings()

local directionAlert = module:addAlert({
    key = "direction",
    label = L["Speak Compass Direction"],
})

directionAlert:addOutput({
    type = "Voice",
    key = "voice",
    label = L["Voice Alert"],
    getPath = function(self, message)
        return "Path", "directions/" .. message.direction .. ".mp3"
    end,
})

directionAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    enabled = false,
    buildMessage = function(self, message)
        return L[message.direction]
    end,
})

local zoneChanged = module:addAlert({
    key = "zoneChanged",
    label = L["Zone Changed Alert"],
})

zoneChanged:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    shouldFire = function(self, message)
        return message.zone ~= ""
    end,
    buildMessage = function(self, message)
        return message.zone
    end,
})

zoneChanged:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

local subzoneChanged = module:addAlert({
    key = "subzoneChanged",
    label = L["Subzone Changed Alert"],
})

subzoneChanged:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    shouldFire = function(self, message)
        return message.subzone ~= ""
    end,
    buildMessage = function(self, message)
        return message.subzone
    end,
})

subzoneChanged:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

local outdoorsAlert = module:addAlert({
    key = "outdoors",
    label = L["Outdoors Alert"],
})

outdoorsAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["outdoors"]
    end,
})

outdoorsAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

local indoorsAlert = module:addAlert({
    key = "indoors",
    label = L["Indoors Alert"],
})

indoorsAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["indoors"]
    end,
})

indoorsAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

local flyingStartedAlert = module:addAlert({
    key = "flyingStarted",
    label = L["Flying Started Alert"],
})

flyingStartedAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["flying"]
    end,
})

flyingStartedAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

local flyingEndedAlert = module:addAlert({
    key = "flyingEnded",
    label = L["Flying Ended Alert"],
})

flyingEndedAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["flying ended"]
    end,
})

flyingEndedAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

local swimmingAlert = module:addAlert({
    key = "swimming",
    label = L["Swimming Alert"],
})

swimmingAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["swimming"]
    end,
})

swimmingAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

local divingAlert = module:addAlert({
    key = "diving",
    label = L["Diving Alert"],
})

divingAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["diving"]
    end,
})

divingAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

-- The game's timer bars: breath underwater, fatigue in deep water, feign
-- death. Spoken as the game's own bar name plus how full the bar is, one
-- line per step down (breathSteps.lua). The game voice speaks it, as the
-- player is pressing movement keys and NVDA cuts its voice on each.
local breathAlert = module:addAlert({
    key = "breath",
    label = L["Breath Alert"],
})

breathAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    voice = 0,
    buildMessage = function(self, message)
        return message.label .. " " .. message.percent
    end,
})

breathAlert:addOutput({
    type = "Voice",
    key = "voice",
    label = L["Voice Alert"],
    enabled = false,
    -- The voice pack's numbers start at 1: an empty bar is left to TTS.
    shouldFire = function(self, message)
        return message.percent > 0
    end,
    getPath = function(self, message)
        return "Path", "numbers/" .. message.percent .. ".mp3"
    end,
})

breathAlert:addOutput({
    type = "Sound",
    key = "sound",
    label = L["Sound Alert"],
    enabled = false,
})

settings:add({
    key = "breathStep",
    type = "Choice",
    label = L["Breath Step"],
    default = 10,
    choices = {
        { label = "5%", value = 5 },
        { label = "10%", value = 10 },
        { label = "20%", value = 20 },
        { label = "25%", value = 25 },
    },
})

module:registerEvent("event", "ZONE_CHANGED_NEW_AREA")
module:registerEvent("event", "ZONE_CHANGED")
module:registerEvent("event", "ZONE_CHANGED_INDOORS")
module:registerEvent("event", "MIRROR_TIMER_START")
module:registerEvent("event", "MIRROR_TIMER_STOP")
module:registerEvent("event", "MIRROR_TIMER_PAUSE")
module:registerEvent("event", "PLAYER_ENTERING_WORLD")

settings:addRef("direction", directionAlert.parameters)
settings:addRef("zoneChanged", zoneChanged.parameters)
settings:addRef("subzoneChanged", subzoneChanged.parameters)
settings:addRef("outdoors", outdoorsAlert.parameters)
settings:addRef("indoors", indoorsAlert.parameters)
settings:addRef("flyingStarted", flyingStartedAlert.parameters)
settings:addRef("flyingEnded", flyingEndedAlert.parameters)
settings:addRef("swimming", swimmingAlert.parameters)
settings:addRef("diving", divingAlert.parameters)
settings:addRef("breath", breathAlert.parameters)

function module:getDirection(angle)
    if angle == nil then
        return nil
    end
    if angle >= 15 * pi / 8 or angle < pi / 8 then
        return "north"
    elseif angle >= pi / 8 and angle < 3 * pi / 8 then
        return "northwest"
    elseif angle >= 3 * pi / 8 and angle < 5 * pi / 8 then
        return "west"
    elseif angle >= 5 * pi / 8 and angle < 7 * pi / 8 then
        return "southwest"
    elseif angle >= 7 * pi / 8 and angle < 9 * pi / 8 then
        return "south"
    elseif angle >= 9 * pi / 8 and angle < 11 * pi / 8 then
        return "southeast"
    elseif angle >= 11 * pi / 8 and angle < 13 * pi / 8 then
        return "east"
    elseif angle >= 13 * pi / 8 and angle < 15 * pi / 8 then
        return "northeast"
    end
    error("Malformed player angle")
end

function module:getOutdoorsIndoors()
    if IsOutdoors() then
        return "outdoors"
    end
    if IsIndoors() then
        return "indoors"
    end
    return nil
end

function module:onEnable()
    self.angle = GetPlayerFacing()
    self.direction = self:getDirection(self.angle)
    self.outdoorsIndoors = self:getOutdoorsIndoors()
    self.isFlying = IsFlying()
    self.isSwimming = IsSwimming()
    self.isSubmerged = IsSubmerged()
    self:hasUpdate(function(self)
        -- GetPlayerFacing is nil inside instances. Only the facing alert
        -- needs it; returning here used to silence the indoors/outdoors,
        -- flying, swimming, and diving checks below as well.
        local angle = GetPlayerFacing()
        if angle then
            local direction = self:getDirection(angle)
            if direction and direction ~= self.direction then
                directionAlert:fire({
                    angle = angle,
                    direction = direction,
                })
            end
            self.angle, self.direction = angle, direction
        end

        local outdoorsIndoors = self:getOutdoorsIndoors()
        if outdoorsIndoors ~= self.outdoorsIndoors and outdoorsIndoors ~= nil then
            if outdoorsIndoors == "outdoors" then
                outdoorsAlert:fire({})
            elseif outdoorsIndoors == "indoors" then
                indoorsAlert:fire({})
            end
            self.outdoorsIndoors = outdoorsIndoors
        end

        local isFlying = IsFlying()
        if isFlying ~= self.isFlying then
            if isFlying then
                flyingStartedAlert:fire({})
            else
                flyingEndedAlert:fire({})
            end
            self.isFlying = isFlying
        end

        local isSwimming = IsSwimming()
        if isSwimming and not self.isSwimming then
            swimmingAlert:fire({})
        end
        self.isSwimming = isSwimming

        local isSubmerged = IsSubmerged()
        if isSubmerged and not self.isSubmerged then
            divingAlert:fire({})
        end
        self.isSubmerged = isSubmerged

        self:updateTimerBars()
    end)
    self:loadTimerBars()
end

-- Timer bars running now, by the game's timer name (BREATH, EXHAUSTION,
-- FEIGNDEATH, DEATH): { label, paused, steps }.
module.timerBars = {}

function module:startTimerBar(timer, value, maxValue, paused, label)
    self.timerBars[timer] = {
        label = label,
        -- A number: above 0 means the bar stands still (Blizzard's own bar).
        paused = paused ~= nil and paused > 0,
        steps = breathSteps.new(value, maxValue, self.settings.breathStep),
    }
end

-- Pick up bars that already run: after a reload or a loading screen while
-- underwater no start event comes. The game has three bar slots.
function module:loadTimerBars()
    self.timerBars = {}
    for index = 1, 3 do
        local timer, value, maxValue, _, paused, label = GetMirrorTimerInfo(index)
        if timer and timer ~= "UNKNOWN" then
            self:startTimerBar(timer, value, maxValue, paused, label)
        end
    end
end

function module:updateTimerBars()
    if next(self.timerBars) == nil then
        return
    end
    local stepSize = self.settings.breathStep
    for timer, bar in pairs(self.timerBars) do
        if not bar.paused then
            local percent = breathSteps.update(bar.steps, GetMirrorTimerProgress(timer), stepSize)
            if percent then
                breathAlert:fire({ timer = timer, label = bar.label, percent = percent })
            end
        end
    end
end

function module:onEvent(event, ...)
    if event == "MIRROR_TIMER_START" then
        local timer, value, maxValue, _, paused, label = ...
        self:startTimerBar(timer, value, maxValue, paused, label)
        return
    elseif event == "MIRROR_TIMER_STOP" then
        local timer = ...
        self.timerBars[timer] = nil
        return
    elseif event == "MIRROR_TIMER_PAUSE" then
        local timer, paused = ...
        local bar = self.timerBars[timer]
        if bar then
            bar.paused = paused ~= nil and paused > 0
        end
        return
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:loadTimerBars()
        return
    end
    if event == "ZONE_CHANGED_NEW_AREA" then
        zoneChanged:fire({
            zone = GetRealZoneText(),
        })
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        subzoneChanged:fire({
            subzone = GetSubZoneText(),
        })
    end
end
