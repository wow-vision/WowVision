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

function AudioDataSource:getElement()
    local button = WowVision.ui:CreateElement("AudioButton")
    button:setLabel(self:getLabel() or self.key)
    button:setProp("source", self)
    return button
end
