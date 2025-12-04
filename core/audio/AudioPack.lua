local AudioPack = WowVision.Class("AudioPack")
WowVision.audio.AudioPack = AudioPack

function AudioPack:initialize(info)
    self.key = info.key
    self.label = info.label
    self.filePath = info.filePath
    self.directory = WowVision.DataDirectory:new(info)
    self.directory.entryClass = WowVision.audio.AudioDataSource
end

function AudioPack:getDirectory()
    return self.directory
end

function AudioPack:getLabel()
    return self.label
end

WowVision.audio:registerPackType({
    key = "Sound",
    class = AudioPack,
})

local VoicePack = WowVision.Class("VoicePack", AudioPack)

function VoicePack:initialize(info)
    AudioPack.initialize(self, info)
    self:setup()
end

function VoicePack:setup()
    local root = self:getDirectory()
    local directions = root:addSubdirectory({
        key = "directions",
        label = "directions",
    })

    directions:addFiles({
        "north.mp3",
        "northeast.mp3",
        "east.mp3",
        "southeast.mp3",
        "south.mp3",
        "southwest.mp3",
        "west.mp3",
        "northwest.mp3",
    })

    local numbers = root:addSubdirectory({
        key = "numbers",
        label = "numbers",
    })
    for i = 1, 100 do
        numbers:addFile(i .. ".mp3")
    end
end

WowVision.audio:registerPackType({
    key = "Voice",
    class = VoicePack,
})
