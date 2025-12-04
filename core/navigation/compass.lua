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

module:registerEvent("event", "ZONE_CHANGED_NEW_AREA")
module:registerEvent("event", "ZONE_CHANGED")
module:registerEvent("event", "ZONE_CHANGED_INDOORS")

settings:addRef("direction", directionAlert.parameters)
settings:addRef("zoneChanged", zoneChanged.parameters)
settings:addRef("subzoneChanged", subzoneChanged.parameters)

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
    self:hasUpdate(function(self)
        if IsInInstance() then
            return
        end
        local angle = GetPlayerFacing()
        local direction = self:getDirection(angle)
        if direction and direction ~= self.direction then
            directionAlert:fire({
                angle = angle,
                direction = direction,
            })
        end
        self.angle, self.direction = angle, direction
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
