local FieldType = WowVision.Class("FieldType")
WowVision.info.FieldType = FieldType

function FieldType:initialize(key, parent)
    self.key = key
    self.operators = {}
    if parent then
        self.parameters = parent.parameters:clone()
        for _, operator in ipairs(parent.operators) do
            self:addOperator(operator:getInfo())
        end
    else
        self.parameters = WowVision.info.InfoManager:new()
    end
end

function FieldType:addOperator(info)
    local operator = WowVision.info.Operator:new(info)
    self.operators[info.key] = operator
    return operator
end

function FieldType:validate(field, value)
    return value
end

function FieldType:getDefaultDB(field, obj)
    return field:getDefault(obj)
end

function FieldType:setDB(field, obj, db)
    obj.db = nil
    local value = db[field.key]
    field:set(obj, value)
        obj.db = db
end

local Operator = WowVision.Class("InfoFieldOperator"):include(WowVision.InfoClass)
WowVision.info.Operator = Operator
Operator.info:addFields({
    { key = "key", required = true },
    { key = "label" },
    { key = "symbol" },
    {
        key = "operands",
        required = true,
        default = function()
            return {}
        end,
    },
    { key = "func", required = true },
})

function Operator:initialize(info)
    self:setInfo(info)
end

function Operator:evaluate(...)
    return self.func(...)
end
