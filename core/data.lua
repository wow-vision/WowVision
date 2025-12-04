local utils = WowVision.utils
local DataSource = WowVision.Class("DataSource"):include(WowVision.InfoClass)
WowVision.DataSource = DataSource
DataSource.info:addFields({
    { key = "key", required = true, once = true },
    { key = "label" },
    { key = "value", required = true },
    { key = "filePath" },
})

function DataSource:initialize(info)
    self:setInfo(info)
end

function DataSource:getLabel()
    return self.label
end

function DataSource:getValue()
    return self.value
end

local DataDirectory = WowVision.Class("DataDirectory"):include(WowVision.InfoClass)
WowVision.DataDirectory = DataDirectory
DataDirectory.info:addFields({
    { key = "key", required = true, once = true },
    { key = "label" },
    { key = "filePath" },
    { key = "entryClass" },
})

function DataDirectory:initialize(info)
    self.subdirectories = {}
    self.entries = {}
    self.data = {}
    self:setInfo(info)
end

function DataDirectory:addSubdirectory(info, isRef)
    if isRef then
        tinsert(self.subdirectories, info)
        self.data[info.key] = info
        return info
    end
    info.entryClass = self.entryClass
    if self.filePath then
        info.filePath = self.filePath .. "/" .. info.key
    end
    local subdir = self.class:new(info)
    tinsert(self.subdirectories, subdir)
    self.data[subdir.key] = subdir
    return subdir
end

function DataDirectory:addEntry(info)
    if self.filePath then
        info.filePath = self.filePath .. "/" .. info.key
    end
    local entry = self.entryClass:new(info)
    tinsert(self.entries, entry)
    self.data[entry.key] = entry
    return entry
end

function DataDirectory:get(key)
    return self.data[key]
end

function DataDirectory:getPath(path)
    local path = utils.splitString(path, "/")
    local target = self
    local i = 1
    while target do
        target = target:get(path[i])
        i = i + 1
        if i > #path then
            break
        end
    end
    return target
end

function DataDirectory:addFile(file)
    return self:addEntry({
        key = file,
        label = file,
        value = file,
    })
end

function DataDirectory:addFiles(files)
    for _, v in ipairs(files) do
        self:addFile(v)
    end
end
