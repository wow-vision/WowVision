-- Forever's sound options have three volume sliders more than the classic
-- clients: gameplay sound effects, pings and combat warnings. WowVision's
-- sounds may play on any of them. The default is the ping channel: a blind
-- player gains little from the ping sounds, so its slider is free to be
-- WowVision's own volume.
local L = WowVision:getLocale()
local channels = WowVision.audio.channels
tinsert(channels, { label = L["Gameplay Sound Effects"], value = "Gameplay SFX" })
tinsert(channels, { label = L["Ping Sounds"], value = "Ping" })
tinsert(channels, { label = L["Combat Warnings"], value = "Encounter Warnings" })
WowVision.audio.defaultChannel = "Ping"
