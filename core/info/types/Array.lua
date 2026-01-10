local info = WowVision.info

local ArrayField, parent = info:CreateFieldClass("Array")

function ArrayField:setup(config)
    parent.setup(self, config)

    -- elementField can be a Field object or a table definition
    local elementField = config.elementField
    if not elementField then
        error("Array field must have an 'elementField' property.")
    end

    if type(elementField) == "table" and not elementField.isInstanceOf then
        -- It's a definition table, create a Field from it
        local FieldClass = info.Field
        if elementField.type then
            local registeredClass = info.fieldTypes:get(elementField.type)
            if registeredClass then
                FieldClass = registeredClass
            end
        end
        -- Use a generated key for the element field
        local elementInfo = {}
        for k, v in pairs(elementField) do
            elementInfo[k] = v
        end
        elementInfo.key = elementInfo.key or "_element"
        self.elementField = FieldClass:new(elementInfo)
        self.elementFieldIsInline = true
    else
        -- It's already a Field object
        self.elementField = elementField
        self.elementFieldIsInline = false
    end
end

function ArrayField:getInfo()
    local result = parent.getInfo(self)
    if self.elementFieldIsInline then
        result.elementField = self.elementField:getInfo()
    else
        result.elementField = self.elementField
    end
    return result
end

-- Get array or element at index
function ArrayField:get(obj, index)
    local arr = obj[self.key]
    if index then
        if arr then
            return arr[index]
        end
        return nil
    end
    return arr
end

-- Set array or element at index
function ArrayField:set(obj, value, index)
    if index then
        -- Setting a specific element
        local arr = obj[self.key]
        if not arr then
            arr = {}
            obj[self.key] = arr
        end
        arr[index] = self:validateElement(value)
    else
        -- Setting entire array
        if value then
            local validated = {}
            for i, v in ipairs(value) do
                validated[i] = self:validateElement(v)
            end
            obj[self.key] = validated
        else
            obj[self.key] = {}
        end
    end
end

-- Validate a single element using the elementField
function ArrayField:validateElement(value)
    return self.elementField:validate(value)
end

-- Default is empty array
function ArrayField:getDefault(obj)
    return {}
end

-- Default DB is empty array
function ArrayField:getDefaultDB(obj)
    return {}
end

-- Restore array from DB
function ArrayField:setDB(obj, db)
    local arr = db[self.key]
    if not arr then
        obj[self.key] = {}
        return
    end
    -- Validate each element during restore
    local validated = {}
    for i, v in ipairs(arr) do
        validated[i] = self:validateElement(v)
    end
    obj[self.key] = validated
end

-- Add element to end of array
function ArrayField:addElement(obj, value)
    local arr = obj[self.key]
    if not arr then
        arr = {}
        obj[self.key] = arr
    end
    tinsert(arr, self:validateElement(value))
    return #arr
end

-- Remove element at index
function ArrayField:removeElement(obj, index)
    local arr = obj[self.key]
    if arr and arr[index] then
        return tremove(arr, index)
    end
    return nil
end

-- Get array length
function ArrayField:getLength(obj)
    local arr = obj[self.key]
    if arr then
        return #arr
    end
    return 0
end

-- Get element field for external use
function ArrayField:getElementField()
    return self.elementField
end

-- No meaningful value string for an array
function ArrayField:getValueString(obj, value)
    if not value then
        return "0 items"
    end
    return #value .. " items"
end
