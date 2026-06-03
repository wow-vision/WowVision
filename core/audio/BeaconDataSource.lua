local BeaconDataSource = WowVision.Class("BeaconDataSource", WowVision.audio.AudioDataSource)
WowVision.audio.BeaconDataSource = BeaconDataSource

local floor = math.floor

local function roundToStep(value, step)
    return floor(value / step + 0.5) * step
end

function BeaconDataSource:initialize(info)
    WowVision.audio.AudioDataSource.initialize(self, info)
    self.beaconName = info.beaconName or info.key
    self.degreesStep = info.degreesStep or 5
    self.maxDistance = info.maxDistance or 30
end

-- Build the file path for a specific angle/distance combination.
-- angle: -180 to +180 (relative to player facing); will be rounded to nearest step
-- distance: yards from player; clamped to [1, maxDistance]
function BeaconDataSource:getFile(angle, distance)
    angle = roundToStep(angle or 0, self.degreesStep)
    if angle < -180 then angle = -180 end
    if angle > 180 then angle = 180 end

    distance = floor((distance or 1) + 0.5)
    if distance < 1 then distance = 1 end
    if distance > self.maxDistance then distance = self.maxDistance end

    return self.filePath .. "/" .. self.beaconName .. ";" .. angle .. ";" .. distance .. ".mp3"
end

function BeaconDataSource:play(angle, distance, channel)
    local path = self:getFile(angle, distance)
    return PlaySoundFile(path, channel or "SFX")
end

-- Preview plays a sample so users can hear the beacon (angle 0 = facing it)
function BeaconDataSource:preview(channel)
    if WowVision.audio._previewHandle then
        StopSound(WowVision.audio._previewHandle, 0)
        WowVision.audio._previewHandle = nil
    end
    local willPlay, soundHandle = self:play(0, 5, channel)
    if willPlay then
        WowVision.audio._previewHandle = soundHandle
    end
    return willPlay, soundHandle
end
