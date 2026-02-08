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

-- UI Generation

function TemplateField:ensureVirtualElements()
    local gen = WowVision.ui.generator
    if gen:hasElement("TemplateField/editor") then
        return
    end

    gen:Element("TemplateField/editor", function(props)
        return props.field:buildEditor(props.obj)
    end)

    gen:Element("TemplateField/formatEditor", function(props)
        return props.field:buildFormatEditor(props.obj)
    end)
end

local function templateButton_Click(event, button)
    button.context:pop()
end

function TemplateField:buildEditor(obj)
    local field = self
    local children = {}

    -- Registered templates
    local templates = self:getAvailableTemplates(obj)
    if templates then
        for _, template in ipairs(templates.items) do
            tinsert(children, {
                "Button",
                key = template.key,
                label = template.name,
                events = {
                    click = function(event, button)
                        field:set(obj, { key = template.key })
                        button.context:pop()
                    end,
                },
            })
        end
    end

    -- Custom option
    tinsert(children, {
        "Button",
        key = "custom",
        label = L["Custom"],
        events = {
            click = function(event, button)
                button.context:pop()
                button.context:addGenerated({
                    "TemplateField/formatEditor",
                    field = field,
                    obj = obj,
                })
            end,
        },
    })

    return {
        "List",
        label = field:getLabel() or field.key,
        children = children,
    }
end

function TemplateField:buildFormatEditor(obj)
    local field = self
    local value = field:get(obj)
    local currentFormat = value and value.format or ""

    return {
        "List",
        label = L["Custom"] .. " " .. (field:getLabel() or field.key),
        children = {
            {
                "EditBox",
                key = "format",
                label = L["Format"],
                value = currentFormat,
                autoInputOnFocus = true,
                events = {
                    valueChange = function(event, editBox, newValue)
                        if newValue and newValue ~= "" then
                            field:set(obj, { format = newValue })
                        else
                            field:set(obj, nil)
                        end
                    end,
                },
            },
        },
    }
end

function TemplateField:getGenerator(obj)
    self:ensureVirtualElements()
    local field = self
    local value = self:get(obj)
    local label = self:getLabel() or self.key
    local valueStr = self:getValueString(obj, value)

    return {
        "Button",
        label = label .. ": " .. valueStr,
        events = {
            click = function(event, button)
                button.context:addGenerated({
                    "TemplateField/editor",
                    field = field,
                    obj = obj,
                })
            end,
        },
    }
end
