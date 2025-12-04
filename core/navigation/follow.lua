local module = WowVision.base.navigation:createModule("follow")
local L = module.L
module:setLabel(L["Follow"])
local settings = module:hasSettings()

settings:add({
    type = "Bool",
    key = "playSounds",
    label = L["Play Sound on Follow or Unfollow"],
    default = true,
})

module:registerEvent("event", "AUTOFOLLOW_BEGIN")
module:registerEvent("event", "AUTOFOLLOW_END")

function module:onEvent(event, name)
    if event == "AUTOFOLLOW_BEGIN" then
        if self.settings.playSounds then
            WowVision:play("Sound/WowVision/alerts/start_small.mp3")
        end
    end
    if event == "AUTOFOLLOW_END" then
        if self.settings.playSounds then
            WowVision:play("Sound/WowVision/alerts/stop_small.mp3")
        end
    end
end
