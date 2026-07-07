local info = WowVision.info
local L = WowVision:getLocale()

local DataBrowseField, parent = info:CreateFieldClass("DataBrowse")

function DataBrowseField:setup(config)
    parent.setup(self, config)
    self.directory = config.directory
end

function DataBrowseField:getInfo()
    local result = parent.getInfo(self)
    result.directory = self.directory
    return result
end

function DataBrowseField:getDirectory(obj)
    if type(self.directory) == "function" then
        return self.directory(obj)
    end
    return self.directory
end

function DataBrowseField:getValueString(obj, value)
    if self.getValueStringFunc then
        return self.getValueStringFunc(obj, value)
    end
    if value == nil then
        return nil
    end
    -- Try to resolve the path to a DataSource for a friendly label
    local directory = self:getDirectory(obj)
    if directory then
        local source = directory:getPath(value)
        if source and source.getLabel then
            return source:getLabel()
        end
    end
    return tostring(value)
end
