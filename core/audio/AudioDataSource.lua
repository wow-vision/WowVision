local AudioDataSource = WowVision.Class("AudioDataSource", WowVision.DataSource)
WowVision.audio.AudioDataSource = AudioDataSource

function AudioDataSource:getValue()
    if self.filePath then
        return self.filePath
    end
    return WowVision.DataSource.getValue(self)
end

-- The game sound channels WowVision's sounds can play on, each with a volume
-- slider in the game's sound options. A version adds its own channels and
-- may pick another default (camelot/soundChannels.lua).
local L = WowVision:getLocale()
WowVision.audio.channels = {
    { label = L["Master"], value = "Master" },
    { label = L["Sound Effects"], value = "SFX" },
    { label = L["Music"], value = "Music" },
    { label = L["Ambience"], value = "Ambience" },
    { label = L["Dialog"], value = "Dialog" },
}
WowVision.audio.defaultChannel = "SFX"

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

function AudioDataSource:play(channel)
    local path = self:getValue()
    if not path then
        return nil
    end
    local channel = channel or WowVision.audio.channel()
    return PlaySoundFile(path, channel)
end

function AudioDataSource:preview(channel)
    -- Stop previous preview sound
    if WowVision.audio._previewHandle then
        StopSound(WowVision.audio._previewHandle, 0)
        WowVision.audio._previewHandle = nil
    end
    local willPlay, soundHandle = self:play(channel)
    if willPlay then
        WowVision.audio._previewHandle = soundHandle
    end
    return willPlay, soundHandle
end

