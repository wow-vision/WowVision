local Object = WowVision.Class("Object")

function Object:initialize(type, params)
    self.type = type
    self.params = params or {}
end

function Object:getParam(key)
    return self.params[key]
end

function Object:exists()
    return self.type:exists(self.params)
end

function Object:get(field)
    return self.type:get(self.params, field)
end

function Object:getLabel()
    return self.type:getLabel(self.params)
end

function Object:getFocusString()
    return self.type:getFocusString(self.params)
end

function Object:serialize()
    return {
        type = self.type.key,
        params = self.params,
    }
end

local Objects = WowVision.Class("Objects")

function Objects:initialize()
    self.fieldTypes = WowVision.Registry:new()
    self.types = WowVision.Registry:new()
end

function Objects:create(typeKey, params)
    local objType = self.types:get(typeKey)
    if not objType then
        error("Unknown object type: " .. typeKey)
    end
    return self.Object:new(objType, params)
end

function Objects:createObjectType(key)
    local class = self.ObjectType:new(key)
    self.types:register(key, class)
    return class
end

function Objects:createGlobalType(key)
    local class = self.GlobalType:new(key)
    self.types:register(key, class)
    return class
end

function Objects:createUnitType(key)
    local class = self.UnitType:new(key)
    self.types:register(key, class)
    return class
end

-- Deserialize from saved data format { type = "TypeName", params = {...} }
function Objects:deserialize(data)
    return self:create(data.type, data.params)
end

function Objects:track(info)
    local objectType = self.types:get(info.type)
    if objectType == nil then
        error("No object type " .. info.type .. " found.")
    end
    return objectType:track(info)
end

-- Each type updates on its own (utils.guardedCall): one that throws is
-- reported once and the types after it still update.
function Objects:update()
    local guardedCall = WowVision.utils.guardedCall
    for _, objectType in ipairs(self.types.items) do
        guardedCall(objectType, objectType.onUpdate, objectType)
    end
end

WowVision.objects = Objects:new()
WowVision.objects.Object = Object
