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

-- The channel WowVision's sounds play on: the UI module's setting, or the
-- default when the saved channel is not in this version's list.
function WowVision.audio.channel()
    local ui = WowVision.base.ui
    local channel = ui and ui.settings and ui.settings.soundChannel
    for _, choice in ipairs(WowVision.audio.channels) do
        if choice.value == channel then
            return channel
        end
    end
    return WowVision.audio.defaultChannel
end
