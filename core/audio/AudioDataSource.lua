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
    local channel = channel or "SFX"
    return PlaySoundFile(path, channel)
end
