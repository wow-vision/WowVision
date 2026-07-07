local info = WowVision.info
local L = WowVision:getLocale()

local NumberField, parent = info:CreateFieldClass("Number")
NumberField.resolveFunctions = true

function NumberField:setup(config)
    parent.setup(self, config)
    self.minimum = config.minimum
    self.maximum = config.maximum
end

function NumberField:getInfo()
    local result = parent.getInfo(self)
    result.minimum = self.minimum
    result.maximum = self.maximum
    return result
end

function NumberField:validate(value)
    local number = tonumber(value)
    if number == nil then
        error("Could not validate " .. tostring(value) .. " as Number.")
    end
    local minimum = self.minimum
    if type(minimum) == "function" then
        minimum = minimum(value)
    end
    if minimum and number < minimum then
        number = minimum
    end
    local maximum = self.maximum
    if type(maximum) == "function" then
        maximum = maximum(value)
    end
    if maximum and number > maximum then
        number = maximum
    end
    return number
end
