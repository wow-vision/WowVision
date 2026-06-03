local BeaconPack = WowVision.Class("BeaconPack", WowVision.audio.AudioPack)
WowVision.audio.BeaconPack = BeaconPack

function BeaconPack:initialize(info)
    WowVision.audio.AudioPack.initialize(self, info)
    self.directory.entryClass = WowVision.audio.BeaconDataSource
end

-- Register a beacon by name. info.key is the beacon folder/file prefix.
function BeaconPack:addBeacon(info)
    return self.directory:addEntry({
        key = info.key,
        label = info.label or info.key,
        value = info.key,
        beaconName = info.key,
        degreesStep = info.degreesStep or 5,
        maxDistance = info.maxDistance or 30,
    })
end

WowVision.audio:registerPackType({
    key = "Beacon",
    class = BeaconPack,
})
