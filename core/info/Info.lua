local InfoManager = WowVision.Class("InfoManager")

local info = {
    InfoManager = InfoManager,
    fieldTypes = WowVision.Registry:new(),
}

function info:createFieldType(key, parentKey)
    local parent = self.fieldTypes:get(key)
    local instance = self.FieldType:new(key, parent)
    self.fieldTypes:register(key, instance)
    return instance
end

WowVision.info = info

function InfoManager:initialize()
    self.fields = {}
end

function InfoManager:addField(info)
    local field = WowVision.info.Field:new(info)
    self.fields[field.key] = field
    return field
end

function InfoManager:addFields(fields)
    local result = {}
    for _, field in ipairs(fields) do
        local field = self:addField(field)
        tinsert(result, field)
    end
    return result
end

function InfoManager:updateField(updates)
    if not updates.key then
        error("updateField requires a key.")
    end
    local existingField = self.fields[updates.key]
    if not existingField then
        error("No field to update matching " .. updates.key .. ".")
    end

    -- Merge existing field info with updates
    local existingInfo = existingField:getInfo()
    for k, v in pairs(updates) do
        existingInfo[k] = v
    end

    -- Create new field with merged info
    local newField = WowVision.info.Field:new(existingInfo)
    self.fields[updates.key] = newField
    return newField
end

function InfoManager:updateFields(fields)
    local result = {}
    for _, field in ipairs(fields) do
        local updated = self:updateField(field)
        tinsert(result, updated)
    end
    return result
end

function InfoManager:clone()
    local clone = InfoManager:new()
    for k, field in pairs(self.fields) do
        clone:addField(field:getInfo())
    end
    return clone
end

function InfoManager:getField(key)
    return self.fields[key]
end

function InfoManager:getFieldValue(obj, key)
    local field = self.fields[key]
    if field == nil then
        error("Info has no field " .. key .. ".")
    end
    return field:get(obj)
end

function InfoManager:setFieldValue(obj, key, value)
    local field = self.fields[key]
    if field == nil then
        error("Info has no field " .. key .. ".")
    end
    field:set(obj, key, value)
end

function InfoManager:get(obj)
    local result = {}
    for k, field in pairs(self.fields) do
        result[k] = field:get(self)
    end
    return result
end

function InfoManager:set(obj, info, ignoreRequired)
    for _, field in pairs(self.fields) do
        field:setInfo(obj, info, ignoreRequired)
    end
end

--Mixin for info classes
local InfoClass = {}
WowVision.InfoClass = InfoClass

function InfoClass:included(class)
    if class.info ~= nil then
        --Inheriting info from parent class so clone to allow for new fields
        local newInfo = class.info:clone()
        class.info = newInfo
    else
        class.info = InfoManager:new()
    end
end

function InfoClass:getInfo()
    return self.class.info:get(self)
end

function InfoClass:setInfo(info, ignoreRequired)
    if info then
        self.class.info:set(self, info, ignoreRequired)
    end
end
