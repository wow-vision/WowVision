local AudioDataSource = WowVision.Class("AudioDataSource", WowVision.DataSource)
WowVision.audio.AudioDataSource = AudioDataSource

function AudioDataSource:getValue()
    if self.filePath then
        return self.filePath
    end
    return WowVision.DataSource.getValue(self)
end

function AudioDataSource:play(channel)
    local path = self:getValue()
    if not path then
        return nil
    end
    local channel = channel or WowVision.audio.channel()
    return PlaySoundFile(path, channel)
end

-- Further arguments go to play (a beacon source takes a level).
function AudioDataSource:preview(channel, ...)
    -- Stop previous preview sound
    if WowVision.audio._previewHandle then
        StopSound(WowVision.audio._previewHandle, 0)
        WowVision.audio._previewHandle = nil
    end
    local willPlay, soundHandle = self:play(channel, ...)
    if willPlay then
        WowVision.audio._previewHandle = soundHandle
    end
    return willPlay, soundHandle
end

