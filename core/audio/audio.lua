local AudioManager = WowVision.Class("AudioManager")

function AudioManager:initialize()
    self.directory = WowVision.DataDirectory:new({
        key = "audio",
    })
    self.packs = WowVision.Registry:new()
end

function AudioManager:registerPackType(info)
    self.packs:register(info.key, info)
    info.directory = WowVision.DataDirectory:new(info)
    info.packs = WowVision.Registry:new()
    self.directory:addSubdirectory(info.directory, true)
end

function AudioManager:registerPack(packType, pack)
    local typeRegistry = self.packs:get(packType)
    if not typeRegistry then
        error("No audio pack type " .. packType .. ".")
    end
    typeRegistry.packs:register(pack.key, pack)
    typeRegistry.directory:addSubdirectory(pack:getDirectory(), true)
end

function AudioManager:getPath(path)
    return self.directory:getPath(path)
end

function AudioManager:registerVoicePack(info)
    local VoicePack = self.packs:get("Voice")
    local pack = VoicePack.class:new(info)
    self:registerPack("Voice", pack)
end

WowVision.audio = AudioManager:new()
