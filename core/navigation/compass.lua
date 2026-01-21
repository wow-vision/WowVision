local module = WowVision.base.navigation:createModule("compass")
local L = module.L
module:setLabel(L["Compass"])
local pi = math.pi
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

module:registerEvent("event", "ZONE_CHANGED_NEW_AREA")
module:registerEvent("event", "ZONE_CHANGED")
module:registerEvent("event", "ZONE_CHANGED_INDOORS")

settings:addRef("direction", directionAlert.parameters)
settings:addRef("zoneChanged", zoneChanged.parameters)
settings:addRef("subzoneChanged", subzoneChanged.parameters)
settings:addRef("outdoors", outdoorsAlert.parameters)
settings:addRef("indoors", indoorsAlert.parameters)
settings:addRef("flyingStarted", flyingStartedAlert.parameters)
settings:addRef("flyingEnded", flyingEndedAlert.parameters)
settings:addRef("swimming", swimmingAlert.parameters)
settings:addRef("diving", divingAlert.parameters)

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

function module:onEnable()
    self.angle = GetPlayerFacing()
    self.direction = self:getDirection(self.angle)
    self.isOutdoors = IsOutdoors()
    self.isFlying = IsFlying()
    self.isSwimming = IsSwimming()
    self.isSubmerged = IsSubmerged()
    self:hasUpdate(function(self)
        local angle = GetPlayerFacing()
        if not angle then
            return
        end
        local direction = self:getDirection(angle)
        if direction and direction ~= self.direction then
            directionAlert:fire({
                angle = angle,
                direction = direction,
            })
        end
        self.angle, self.direction = angle, direction

        local isOutdoors = IsOutdoors()
        if isOutdoors ~= self.isOutdoors then
            if isOutdoors then
                outdoorsAlert:fire({})
            else
                indoorsAlert:fire({})
            end
            self.isOutdoors = isOutdoors
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
    end)
end

function module:onEvent(event, ...)
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
