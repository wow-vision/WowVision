local info = WowVision.info
local L = WowVision:getLocale()

local TemplateField, parent = info:CreateFieldClass("Template")

function TemplateField:setup(config)
    parent.setup(self, config)
    self.getTemplates = config.getTemplates
end

function TemplateField:getInfo()
    local result = parent.getInfo(self)
    result.getTemplates = self.getTemplates
    return result
end

-- Value is nil (use default), { key = "templateKey" }, or { format = "custom string" }
function TemplateField:getDefault(obj)
    return nil
end

function TemplateField:validate(value)
    if value == nil then
        return nil
    end
    if type(value) ~= "table" then
        return nil
    end
    if value.format then
        return { format = value.format }
    end
    if value.key then
        return { key = value.key }
    end
    return nil
end

function TemplateField:getValueString(obj, value)
    if not value then
        return L["Default"]
    end
    if value.format then
        return L["Custom"]
    end
    if value.key then
        local templates = self:getAvailableTemplates(obj)
        if templates then
            local template = templates:get(value.key)
            if template then
                return template.name
            end
        end
        return value.key
    end
    return L["Default"]
end

function TemplateField:getAvailableTemplates(obj)
    if self.getTemplates then
        return self.getTemplates(obj)
    end
    return nil
end

-- Resolve the template value to a renderable format string or Template instance
-- Returns: template instance, or nil to use default
function TemplateField:resolve(obj)
    local value = self:get(obj)
    if not value then
        return nil
    end
    if value.format then
        return value.format
    end
    if value.key then
        local templates = self:getAvailableTemplates(obj)
        if templates then
            return templates:get(value.key)
        end
    end
    return nil
end
