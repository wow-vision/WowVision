local info = WowVision.info
local L = WowVision:getLocale()

local CategoryField, parent = info:CreateFieldClass("Category")

function CategoryField:setup(config)
    parent.setup(self, config)
    -- Create a field manager for child fields
    self.fieldManager = info.InfoManager:new()
    -- Add any fields specified in config
    if config.fields then
        self.fieldManager:addFields(config.fields)
    end
end

function CategoryField:getInfo()
    local result = parent.getInfo(self)
    -- Serialize child fields for cloning
    local fields = {}
    for _, field in ipairs(self.fieldManager.fields) do
        tinsert(fields, field:getInfo())
    end
    result.fields = fields
    return result
end

-- Delegate field management to fieldManager
function CategoryField:addField(fieldInfo)
    return self.fieldManager:addField(fieldInfo)
end

function CategoryField:addFields(fields)
    return self.fieldManager:addFields(fields)
end

function CategoryField:getField(key)
    return self.fieldManager:getField(key)
end

function CategoryField:getFieldValue(obj, key)
    local nested = self:get(obj)
    if not nested then
        return nil
    end
    return self.fieldManager:getFieldValue(nested, key)
end

function CategoryField:setFieldValue(obj, key, value)
    local nested = self:get(obj)
    if not nested then
        obj[self.key] = {}
        nested = obj[self.key]
    end
    self.fieldManager:setFieldValue(nested, key, value)
end

-- Get the nested object
function CategoryField:get(obj, ...)
    return obj[self.key]
end

-- Set the nested object
function CategoryField:set(obj, ...)
    local value = ...
    obj[self.key] = value or {}
end

-- Build default object from children's defaults
function CategoryField:getDefault(obj)
    local result = {}
    for _, field in ipairs(self.fieldManager.fields) do
        local default = field:getDefault(obj)
        if default ~= nil then
            result[field.key] = default
        end
    end
    return result
end

-- Build default DB structure recursively
function CategoryField:getDefaultDB(obj)
    local result = {}
    for _, field in ipairs(self.fieldManager.fields) do
        result[field.key] = field:getDefaultDB(obj)
    end
    return result
end

-- Set up children from DB values
function CategoryField:setDB(obj, db)
    local nestedDB = db[self.key]
    if not nestedDB then
        return
    end
    -- Ensure the nested object exists
    if not obj[self.key] then
        obj[self.key] = {}
    end
    local nested = obj[self.key]
    -- Set each child field from db
    for _, field in ipairs(self.fieldManager.fields) do
        field:setDB(nested, nestedDB)
    end
end

-- UI Generation
local function categoryButton_Click(event, button)
    button.context:addGenerated(button.userdata)
end

function CategoryField:buildChildList(obj)
    local nested = self:get(obj) or {}
    local result = { "List", label = self:getLabel(), children = {} }
    for _, field in ipairs(self.fieldManager.fields) do
        tinsert(result.children, field:getGenerator(nested))
    end
    return result
end

function CategoryField:getGenerator(obj)
    return {
        "Button",
        label = self:getLabel(),
        userdata = self:buildChildList(obj),
        events = {
            click = categoryButton_Click,
        },
    }
end

-- No meaningful value string for a category
function CategoryField:getValueString(obj, value)
    return nil
end
