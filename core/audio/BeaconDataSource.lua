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

-- A beacon file for a direction and loudness level, on WowVision's channel
-- unless one is given (the Beacon output plays the pings this way).
function BeaconDataSource:playAt(angle, level, channel)
    local path = self:getFile(angle, level)
    return PlaySoundFile(path, channel or WowVision.audio.channel())
end

-- play(channel) as every audio source has it, so a beacon file picked where
-- a sound plays works too: a sample straight ahead (angle 0), at level 5 or
-- the level given. preview is AudioDataSource's, over this play.
local SAMPLE_LEVEL = 5
function BeaconDataSource:play(channel, level)
    return self:playAt(0, level or SAMPLE_LEVEL, channel)
end
