local ObjectType = WowVision.Class("ObjectType")

function ObjectType:initialize(key)
    self.key = key
    self.parameters = WowVision.info.InfoManager:new()
    self.fields = WowVision.info.InfoManager:new()
end

function ObjectType:addField(info)
    local getCached = info.getCached
    local get = info.get
    if self.getCache and getCached then
        info.get = function(params, key)
            local cache = self:getCache(params)
            if cache then
                return getCached(cache)
            end
            return get(params)
        end
    end
    self.fields:addField(info)
end

function ObjectType:addParameter(obj)
    self.parameters:addField(obj)
end

function ObjectType:exists(params)
    return true
end

function ObjectType:get(params, field)
    return self.fields:getFieldValue(params, field)
end

function ObjectType:getKey(data)
    return self.type.key
end

function ObjectType:getLabel(params)
    return self.label or "Unknown"
end

function ObjectType:setLabel(label)
    self.label = label
end

function ObjectType:getFocusString(params)
    return self:getLabel(params)
end

function ObjectType:track(info)
    local set = WowVision.objects.ObjectTracker:new()
    local obj = WowVision.objects.Object:new(self, info.params or {})
    set:add(obj)
    return set
end

function ObjectType:untrack(set)
    return
end

function ObjectType:onUpdate() end

WowVision.objects.ObjectType = ObjectType

local UnitType = WowVision.Class("UnitType", ObjectType)

function UnitType:initialize(key)
    ObjectType.initialize(self, key)
    self.units = {}
    self:addParameter({
        key = "unit",
        required = true,
    })
end

function UnitType:exists(params)
    return UnitExists(params.unit)
end

function UnitType:getCache(params)
    local unitTable = self.units[params.unit]
    if unitTable then
        local ref = unitTable.objects[self.key]
        if ref then
            return ref.data
        end
    end
    return nil
end

function UnitType:getObjectParams(unit, data)
    return {
        type = self.key,
        unit = unit.id,
    }
end

function UnitType:addUnit(id)
    local unitTable = self.units[id]
    if unitTable == nil then
        unitTable = { id = id, guid = UnitGUID(id), trackers = {}, objects = {} }
        unitTable.frame = CreateFrame("Frame")
        self.units[id] = unitTable
        self:onUnitAdd(unitTable)
        self:onUnitChange(unitTable)
    end
    return unitTable
end

function UnitType:changeUnit(unit, guid)
    local removedKeys = {}
    for key, _ in pairs(unit.objects) do
        tinsert(removedKeys, key)
    end
    for _, key in ipairs(removedKeys) do
        self:removeObject(unit, key)
    end
    unit.guid = guid
    self:onUnitChange(unit)
end

function UnitType:removeUnit(id)
    local unitTable = self.units[id]
    if unitTable == nil then
        return
    end
    unitTable.frame:UnregisterAllEvents()
    self:onUnitRemove(unitTable)
    local removedKeys = {}
    for key, _ in pairs(unitTable.objects) do
        tinsert(removedKeys, key)
    end
    for _, key in ipairs(removedKeys) do
        self:removeObject(unitTable, key)
    end
    self.units[id] = nil
end

function UnitType:onUnitAdd(unit) end

function UnitType:onUnitRemove(unit) end

function UnitType:onUnitChange(unit) end

function UnitType:addTracker(unit, tracker)
    unit.trackers[tracker] = true
    for _, ref in pairs(unit.objects) do
        tracker:add(ref.object)
    end
end

function UnitType:removeTracker(unit, tracker)
    unit.trackers[tracker] = nil
    for _, ref in pairs(unit.objects) do
        tracker:remove(ref.object)
    end
end

function UnitType:addObject(unit, key, data)
    if unit.objects[key] then
        error("Tried to cache object data for " .. key .. "; object already exists.")
    end
    local ref = {
        object = WowVision.objects:create(self.key, self:getObjectParams(unit, data)),
        data = data or {},
    }
    unit.objects[key] = ref
    for tracker, _ in pairs(unit.trackers) do
        tracker:add(ref.object)
    end
end

function UnitType:modifyObject(unit, key, newData)
    local ref = unit.objects[key]
    if ref == nil then
        error("Tried to update object (" .. unit.id .. ", " .. key .. ").")
    end
    local data = ref.data
    for k, v in pairs(newData) do
        data[k] = v
    end
    for tracker, _ in pairs(unit.trackers) do
        tracker:modify(ref.object)
    end
end

function UnitType:removeObject(unit, key)
    local ref = unit.objects[key]
    if ref == nil then
        error("Tried to remove object with key " .. key .. " which does not exist.")
    end
    unit.objects[key] = nil
    for tracker, _ in pairs(unit.trackers) do
        tracker:remove(ref.object)
    end
end

function UnitType:track(info)
    local units = info.units
    local set = WowVision.objects.ObjectTracker:new(info)
    set.manager = self
    for _, unit in ipairs(units) do
        local unitTable = self:addUnit(unit)
        self:addTracker(unitTable, set)
    end
    return set
end

function UnitType:untrack(tracker)
    local unitsToRemove = {}
    if tracker.trackingInfo == nil then
        error("Set has no tracking info.")
    end
    local units = tracker.trackingInfo.units
    for _, unit in ipairs(units) do
        local unitTable = self.units[unit]
        if unitTable == nil or unitTable.trackers[tracker] == nil then
            error("Unit " .. unit .. " was not being tracked.")
        end
        self:removeTracker(unitTable, tracker)
        if next(unitTable.trackers) == nil then
            tinsert(unitsToRemove, unitTable.id)
        end
    end
    for _, id in ipairs(unitsToRemove) do
        self:removeUnit(id)
    end
end

function UnitType:onUpdate()
    for id, unitTable in pairs(self.units) do
        local newGUID = UnitGUID(id)
        if newGUID ~= unitTable.guid then
            self:changeUnit(unitTable, newGUID)
        end
    end
end

WowVision.objects.UnitType = UnitType
