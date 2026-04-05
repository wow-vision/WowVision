local lsm = LibStub("LibSharedMedia-3.0")

local pack = WowVision.audio.AudioPack:new({
    key = "LibSharedMedia",
    label = "LibSharedMedia",
})

local directory = pack:getDirectory()

-- Populate directory with all LSM sound entries, sorted alphabetically
local sounds = lsm:HashTable("sound")
if sounds then
    local sorted = {}
    for name, path in pairs(sounds) do
        tinsert(sorted, { name = name, path = path })
    end
    table.sort(sorted, function(a, b)
        return a.name < b.name
    end)
    for _, entry in ipairs(sorted) do
        directory:addEntry({
            key = entry.name,
            label = entry.name,
            value = entry.path,
            filePath = entry.path,
        })
    end
end

WowVision.audio:registerPack("Sound", pack)
