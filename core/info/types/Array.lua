local info = WowVision.info
local L = WowVision:getLocale()

local ArrayField, parent = info:CreateFieldClass("Array")

function ArrayField:setup(config)
    parent.setup(self, config)

    -- elementField can be a Field object or a table definition
    local elementField = config.elementField
    if not elementField then
        error("Array field must have an 'elementField' property.")
    end

    local isFieldInstance = type(elementField) == "table"
        and type(elementField.isInstanceOf) == "function"
        and elementField:isInstanceOf(info.Field)
    if not isFieldInstance then
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

-- Helper to persist array to db and emit change event
function ArrayField:onArrayChanged(obj)
    local arr = obj[self.key]
    if self.persist and obj.db then
        -- Deep copy array to db for persistence
        local dbArr = {}
        if arr then
            for i, v in ipairs(arr) do
                dbArr[i] = v
            end
        end
        obj.db[self.key] = dbArr
    end
    self.events.valueChange:emit(obj, self.key, arr)
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
    self:onArrayChanged(obj)
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
    obj.db = nil -- Temporarily disable db to avoid re-persisting during restore
    local arr = db[self.key]
    if not arr then
        self:set(obj, {})
    else
        self:set(obj, arr)
    end
    obj.db = db -- Re-enable db
end

-- Add element to end of array
function ArrayField:addElement(obj, value)
    local arr = obj[self.key]
    if not arr then
        arr = {}
        obj[self.key] = arr
    end
    tinsert(arr, self:validateElement(value))
    self:onArrayChanged(obj)
    return #arr
end

-- Remove element at index
function ArrayField:removeElement(obj, index)
    local arr = obj[self.key]
    if arr and arr[index] then
        local removed = tremove(arr, index)
        self:onArrayChanged(obj)
        return removed
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

-- UI Generation

-- Lazily register virtual elements on first use
function ArrayField:ensureVirtualElements()
    local gen = WowVision.ui.generator
    if gen:hasElement("ArrayField/list") then
        return
    end

    gen:Element("ArrayField/list", function(props)
        return props.arrayField:buildArrayList(props.obj)
    end)

    gen:Element("ArrayField/item", function(props)
        return props.arrayField:buildArrayItem(props.obj, props.index)
    end)
end

-- Creates a proxy object that redirects reads/writes to a specific array index
-- This allows elementField:getGenerator() to work with array elements
function ArrayField:createElementProxy(obj, index)
    local arrayField = self
    local elementKey = self.elementField.key
    return setmetatable({}, {
        __index = function(t, k)
            if k == elementKey then
                return arrayField:get(obj, index)
            end
        end,
        __newindex = function(t, k, v)
            if k == elementKey then
                arrayField:set(obj, v, index)
            end
        end,
    })
end

-- Click handler for opening the array editor
local function arrayButton_Click(event, button)
    local arrayField = button.userdata.arrayField
    local obj = button.userdata.obj
    button.context:addGenerated({
        "ArrayField/list",
        arrayField = arrayField,
        obj = obj,
    })
end

-- Click handler for removing an element
local function removeButton_Click(event, button)
    local arrayField = button.userdata.arrayField
    local obj = button.userdata.obj
    local index = button.userdata.index
    arrayField:removeElement(obj, index)
end

-- Click handler for adding a new element
local function addButton_Click(event, button)
    local arrayField = button.userdata.arrayField
    local obj = button.userdata.obj
    local defaultValue = arrayField.elementField:getDefault({})
    arrayField:addElement(obj, defaultValue)
end

-- Builds a single array item row (element editor + remove button)
function ArrayField:buildArrayItem(obj, index)
    local proxy = self:createElementProxy(obj, index)
    local elementGen = self.elementField:getGenerator(proxy)
    elementGen.key = "element"

    -- Get a label for this item
    local elementValue = self:get(obj, index)
    local itemLabel = self.elementField:getValueString(proxy, elementValue)
    if not itemLabel or itemLabel == "" then
        itemLabel = "Item " .. index
    end

    return {
        "List",
        label = itemLabel,
        children = {
            elementGen,
            {
                "Button",
                key = "remove",
                label = L["Remove"],
                userdata = { arrayField = self, obj = obj, index = index },
                events = { click = removeButton_Click },
            },
        },
    }
end

-- Builds the full array editor list
function ArrayField:buildArrayList(obj)
    local arr = self:get(obj) or {}
    local label = self:getLabel() or self.key
    local result = {
        "List",
        label = label,
        children = {},
    }

    -- Add each element using virtual element references
    for i = 1, #arr do
        tinsert(result.children, {
            "ArrayField/item",
            key = "item_" .. i,
            arrayField = self,
            obj = obj,
            index = i,
        })
    end

    -- Add button at the end
    tinsert(result.children, {
        "Button",
        key = "add",
        label = L["Add"],
        userdata = { arrayField = self, obj = obj },
        events = { click = addButton_Click },
    })

    return result
end

-- Returns a button that opens the array editor
function ArrayField:getGenerator(obj)
    self:ensureVirtualElements()
    local arr = self:get(obj) or {}
    local label = self:getLabel() or self.key
    local countStr = self:getValueString(obj, arr)

    return {
        "Button",
        label = label .. " (" .. countStr .. ")",
        userdata = { arrayField = self, obj = obj },
        events = { click = arrayButton_Click },
    }
end
