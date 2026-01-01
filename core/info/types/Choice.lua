local info = WowVision.info
local L = WowVision:getLocale()

local ChoiceField, parent = info:CreateFieldClass("Choice")

function ChoiceField:setup(config)
    parent.setup(self, config)
    self.choices = config.choices or {}
    self.allowNil = config.allowNil or false
end

function ChoiceField:getInfo()
    local result = parent.getInfo(self)
    result.choices = self.choices
    result.allowNil = self.allowNil
    return result
end

function ChoiceField:getChoices(obj)
    if type(self.choices) == "function" then
        return self.choices(obj)
    end
    return self.choices
end

function ChoiceField:getDefault(obj)
    -- Use explicit default if provided
    if self.default ~= nil then
        if type(self.default) == "function" then
            return self.default(obj)
        end
        return self.default
    end
    -- Fall back to first choice's value
    local choices = self:getChoices(obj)
    if choices and choices[1] then
        return choices[1].value
    end
    return nil
end

function ChoiceField:getChoiceByKey(obj, key)
    for _, choice in ipairs(self:getChoices(obj)) do
        if choice.key == key then
            return choice
        end
    end
    return nil
end

function ChoiceField:getChoiceByValue(obj, value)
    for _, choice in ipairs(self:getChoices(obj)) do
        if choice.value == value then
            return choice
        end
    end
    return nil
end

function ChoiceField:getValueString(obj, value)
    if self.getValueStringFunc then
        return self.getValueStringFunc(obj, value)
    end
    local choice = self:getChoiceByValue(obj, value)
    if choice then
        return choice.label
    end
    if value == nil then
        return nil
    end
    return tostring(value)
end

local function choiceButton_Click(event, button)
    button.context:pop()
end

local function dropdownButton_Click(event, button)
    button.context:addGenerated(button.userdata)
end

function ChoiceField:buildDropdown(obj)
    local result = { "List", label = self:getLabel(), children = {} }
    for _, choice in ipairs(self:getChoices(obj)) do
        tinsert(result.children, {
            "Button",
            label = choice.label,
            bind = { type = "Field", target = obj, field = self, fixedValue = choice.value },
            events = {
                click = choiceButton_Click,
            },
        })
    end
    return result
end

function ChoiceField:getGenerator(obj)
    return {
        "Button",
        label = self:getLabel(),
        userdata = self:buildDropdown(obj),
        events = {
            click = dropdownButton_Click,
        },
    }
end

ChoiceField:addOperator({
    key = "eq",
    label = L["equal to"],
    operands = { "Choice", "Choice" },
    func = function(a, b)
        return a == b
    end,
})
