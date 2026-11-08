-- The game sound channels WowVision's sounds can play on, each named as the
-- game names its volume slider in the sound options, so the player finds the
-- slider that sets WowVision's volume. A version's setup.lua adds the
-- channels only its sound options have (consts.SOUND_CHANNELS) and may pick
-- another default (consts.DEFAULT_SOUND_CHANNEL).
local consts = WowVision.consts or {}

WowVision.audio.channels = {
    { label = MASTER_VOLUME, value = "Master" },
    { label = FX_VOLUME, value = "SFX" },
    { label = MUSIC_VOLUME, value = "Music" },
    { label = AMBIENCE_VOLUME, value = "Ambience" },
    { label = DIALOG_VOLUME, value = "Dialog" },
}
for _, channel in ipairs(consts.SOUND_CHANNELS or {}) do
    tinsert(WowVision.audio.channels, channel)
end
WowVision.audio.defaultChannel = consts.DEFAULT_SOUND_CHANNEL or "SFX"

-- The channel WowVision's sounds play on: the UI module's setting keeps
-- selectedChannel current (core/ui modules/module.lua).
function WowVision.audio.channel()
    return WowVision.audio.selectedChannel or WowVision.audio.defaultChannel
end

-- The sound channel setting's validate: a saved channel this version does
-- not offer (an older build's choice) reads as the default.
function WowVision.audio.validateChannel(field, value)
    if value ~= nil and field:getChoiceByValue(nil, value) == nil then
        return WowVision.audio.defaultChannel
    end
    return value
end
