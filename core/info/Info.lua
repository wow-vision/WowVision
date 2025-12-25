local InfoManager = WowVision.Class("InfoManager")

local info = {
    InfoManager = InfoManager,
    fieldTypes = WowVision.Registry:new(), -- Stores Field subclasses by type key
}

-- Creates a new Field subclass and registers it
function info:CreateFieldClass(key, parentKey)
    local parentClass = parentKey and self.fieldTypes:get(parentKey) or self.Field
    local newClass = WowVision.Class(key .. "Field", parentClass)
    newClass.typeKey = key

    -- Copy parent operators to child
    newClass.operators = {}
    if parentClass.operators then
        for opKey, operator in pairs(parentClass.operators) do
            newClass.operators[opKey] = operator
        end
    end

    self.fieldTypes:register(key, newClass)
    return newClass, parentClass
end

WowVision.info = info

function InfoManager:initialize()
    self.fields = {}
    self.config = {
        applyMode = "merge", -- "merge" (preserve unspecified) or "replace" (reset to defaults)
    }
end

function InfoManager:addField(info)
    local FieldClass = WowVision.info.Field
    if info.type then
        local registeredClass = WowVision.info.fieldTypes:get(info.type)
        if registeredClass then
            FieldClass = registeredClass
        end
    end
    local field = FieldClass:new(info)
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

    -- Create new field with merged info using appropriate class
    local FieldClass = WowVision.info.Field
    if existingInfo.type then
        local registeredClass = WowVision.info.fieldTypes:get(existingInfo.type)
        if registeredClass then
            FieldClass = registeredClass
        end
    end
    local newField = FieldClass:new(existingInfo)
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
    -- Copy config
    for k, v in pairs(self.config) do
        clone.config[k] = v
    end
    -- Copy fields
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
    local applyMode = self.config.applyMode or "merge"
    for _, field in pairs(self.fields) do
        field:setInfo(obj, info, ignoreRequired, applyMode)
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
