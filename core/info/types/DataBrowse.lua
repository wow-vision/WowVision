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

function DataBrowseField:getGenerator(obj)
    local field = self
    local value = self:get(obj)
    local label = self:getLabel() or self.key
    local valueStr = self:getValueString(obj, value)

    return {
        "Button",
        label = label,
        extras = valueStr,
        events = {
            click = function(event, button)
                local directory = field:getDirectory(obj)
                if not directory then
                    return
                end
                local browseContext = WowVision.ui:CreateElement("DataBrowseContext", {
                    directory = directory,
                })
                browseContext.events.confirm:subscribe(nil, function(event, context, source, path)
                    field:set(obj, path)
                    button.context:pop()
                end)
                browseContext.events.cancel:subscribe(nil, function(event, context)
                    button.context:pop()
                end)
                button.context:add(browseContext)
            end,
        },
    }
end
