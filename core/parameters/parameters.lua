local Parameters = WowVision.Class("Parameters")
local L = WowVision:getLocale()

function Parameters:initialize()
    self.types = WowVision.Registry:new()
end

function Parameters:createType(key)
    local class = WowVision.Class(key .. "Parameter", self.Parameter):include(WowVision.InfoClass)
    self.types:register(key, class)
    return class
end

local Parameter = WowVision.Class("Parameter"):include(WowVision.InfoClass)
local parameters = Parameters:new()
WowVision.parameters = parameters
parameters.Parameter = Parameter
Parameter.info:addFields({
    { key = "key", required = true, once = true },
    { key = "label" },
    { key = "description" },
    { key = "default" },
    { key = "static", default = false },
})

function Parameter:initialize(info)
    self.events = {
        valueChange = WowVision.Event:new("valueChange"),
    }
    self:onInitialize(info)
    self:setInfo(info)
end

function Parameter:onInitialize(info) end

function Parameter:getLabel()
    return self.label
end

function Parameter:getDefaultDB()
    if type(self.default) == "function" then
        return self:default()
    end
    return self.default
end

function Parameter:setDB(db)
    self.db = db
    self:setValue(self.db[self.key])
end

function Parameter:getValue()
    return self.db[self.key]
end

function Parameter:setValue(value)
    self.db[self.key] = value
    self.events.valueChange:emit(self, value)
end

function Parameter:getGenerator()
    return nil
end

--mark
local ParameterCategory = parameters:createType("Category")
parameters.Category = ParameterCategory

function ParameterCategory:onInitialize(info)
    Parameter.onInitialize(self, info)
    self.children = {}
    self.category = true
end

function ParameterCategory:getDefaultDB()
    local result = {}
    for _, v in ipairs(self.children) do
        if not v.ref then
            result[v.key] = v:getDefaultDB()
        end
    end
    return result
end

function ParameterCategory:setDB(db)
    self.db = db
    for _, v in ipairs(self.children) do
        if not v.ref then
            if v.category then
                v:setDB(db[v.key])
            else
                v:setDB(db)
            end
        end
    end
end

function ParameterCategory:get(key)
    return self.children[key]
end

local function CategoryButton_Click(event, button)
    button.context:addGenerated(button.userdata:getGenerator())
end

function ParameterCategory:getGenerator()
    local result = { "List", label = self.label, children = {} }
    for _, v in ipairs(self.children) do
        if v.category then
            tinsert(result.children, {
                "Button",
                label = v.label,
                userdata = v,
                events = {
                    click = CategoryButton_Click,
                },
            })
        else
            tinsert(result.children, v:getGenerator())
        end
    end
    return result
end

function ParameterCategory:add(info)
    if self.children[info.key] then
        error("A parameter with key " .. info.key .. " already exists.")
    end
    local parameterClass = WowVision.parameters.types:get(info.type)
    if not parameterClass then
        error("Unknown parameter type " .. (info.type or "Nil"))
    end
    local parameter = parameterClass:new(info)
    self.children[info.key] = parameter
    tinsert(self.children, parameter)
    return parameter
end

function ParameterCategory:addRef(key, target)
    return self:add({
        type = "Ref",
        key = key,
        target = target,
    })
end

local BoolParameter = parameters:createType("Bool")

function BoolParameter:toggle()
    local value = self:getValue()
    self:setValue(not value)
    return self:getValue()
end

function BoolParameter:getGenerator()
    return {
        "Checkbox",
        label = self.label,
        enabled = not self.static,
        bind = { type = "Method", target = self, getter = "getValue", setter = "setValue" },
    }
end

local StringParameter = parameters:createType("String")

function StringParameter:getGenerator()
    return {
        "EditBox",
        label = self.label,
        autoInputOnFocus = false,
        enabled = not self.static,
        bind = { type = "Property", target = self.db, property = self.key },
    }
end

local NumberParameter = parameters:createType("Number")

function NumberParameter:getGenerator()
    return {
        "EditBox",
        label = self.label,
        autoInputOnFocus = false,
        type = "decimal",
        enabled = not self.static,
        bind = { type = "Property", target = self.db, property = self.key },
    }
end

local ChoiceParameter = parameters:createType("Choice")
ChoiceParameter.info:addFields({
    {
        key = "choices",
        default = function(obj, key)
            return {}
        end,
    },
})

function ChoiceParameter:addChoice(choice)
    tinsert(self.choices, choice)
end

local function choiceButton_Click(event, button)
    button.context:pop()
end

function ChoiceParameter:buildDropdown()
    local result = { "List", label = self.label, children = {} }
    for _, v in ipairs(self.choices) do
        tinsert(result.children, {
            "Button",
            label = v.label,
            bind = { type = "Method", target = self, getter = "getValue", setter = "setValue", fixedValue = v.value },
            events = {
                click = choiceButton_Click,
            },
        })
    end

    return result
end

local function dropdownButton_Click(event, button)
    button.context:addGenerated(button.userdata)
end

function ChoiceParameter:getGenerator()
    return {
        "Button",
        label = self.label,
        userdata = self:buildDropdown(),
        enabled = not self.static,
        events = {
            click = dropdownButton_Click,
        },
    }
end

local ParameterRef = parameters:createType("Ref")
ParameterRef.info:addFields({
    { key = "target", required = true },
})

function ParameterRef:onInitialize(info)
    Parameter.onInitialize(self, info)
    self.ref = true
end

function ParameterRef:getDefaultDB()
    return nil
end

function ParameterRef:setDB(db)
    return
end

function ParameterRef:getGenerator()
    if self.target.category then
        return {
            "Button",
            label = self.target.label,
            userdata = self.target,
            events = {
                click = CategoryButton_Click,
            },
        }
    end
    return self.target:getGenerator()
end

local VoicePackParameter = parameters:createType("VoicePack")

local function VoicePack_Click(event, button)
    button.context:pop()
end

function VoicePackParameter:buildDropdown()
    local result = { "List", label = L["Voice Pack"], children = {} }
    local voicePacks = WowVision.audio.packs:get("Voice")
    for _, v in ipairs(voicePacks.packs.items) do
        tinsert(result.children, {
            "Button",
            label = v:getLabel(),
            bind = { type = "Method", target = self, getter = "getValue", setter = "setValue", fixedValue = v.key },
            events = {
                click = VoicePack_Click,
            },
        })
    end
    return result
end

function VoicePackParameter:getGenerator()
    return {
        "Button",
        label = self:getLabel(),
        userdata = self:buildDropdown(),
        enabled = not self.static,
        events = {
            click = dropdownButton_Click,
        },
    }
end

function VoicePackParameter:getLabel()
    return self.label or L["Voice Pack"]
end
