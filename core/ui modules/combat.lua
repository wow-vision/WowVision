local module = WowVision.base.ui:createModule("combat")
local L = module.L
module:setLabel(L["Combat"])
local settings = module:hasSettings()

local combatStartedAlert = module:addAlert({
    key = "combatStarted",
    label = L["Combat Started Alert"],
})

combatStartedAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["combat started"]
    end,
})

local combatEndedAlert = module:addAlert({
    key = "combatEnded",
    label = L["Combat Ended Alert"],
})

combatEndedAlert:addOutput({
    type = "TTS",
    key = "tts",
    label = L["TTS Alert"],
    buildMessage = function(self, message)
        return L["combat ended"]
    end,
})

settings:addRef("combatStarted", combatStartedAlert.parameters)
settings:addRef("combatEnded", combatEndedAlert.parameters)

module:registerEvent("event", "PLAYER_REGEN_DISABLED")
module:registerEvent("event", "PLAYER_REGEN_ENABLED")

function module:onEvent(event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        combatStartedAlert:fire({})
    elseif event == "PLAYER_REGEN_ENABLED" then
        combatEndedAlert:fire({})
    end
end
