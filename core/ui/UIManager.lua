local UI = WowVision.Class("UIManager")

function UI:initialize()
    self.elementTypes = WowVision.Registry:new()
    self.generator = WowVision.Generator:new()
end

function UI:CreateElementType(typeKey, parentKey)
    local parent = self.elementTypes:get(parentKey)
    if parent == nil then
        error("Parent " .. parentKey .. " not found.")
    end
    local newElement = WowVision.Class(typeKey, parent.class):include(WowVision.InfoClass)
    newElement.typeKey = typeKey

    -- Deep copy liveFields from parent (middleclass only does shallow copy)
    if parent.class.liveFields then
        newElement.liveFields = {}
        for k, v in pairs(parent.class.liveFields) do
            newElement.liveFields[k] = v
        end
    end

    local newData = {
        class = newElement,
        generationConditions = {},
    }
    for k, v in pairs(parent.generationConditions) do
        newData.generationConditions[k] = v
    end
    self.elementTypes:register(typeKey, newData)
    return newElement, parent.class, newData
end

function UI:CreateElement(typeKey, config)
    local elementType = self.elementTypes:get(typeKey)
    if elementType == nil then
        error("Element of type " .. typeKey .. " not found.")
    end
    local element = elementType.class:new()
    element.ui = self
    -- When no config provided (e.g., from Generator), ignore required field validation
    -- since Generator will set props via setProp() after creation
    local ignoreRequired = config == nil
    element:setInfo(config or {}, ignoreRequired)
    return element
end

WowVision.ui = UI:new()
