local dataBinding = WowVision.dataBinding

local FunctionDataBinding, parent = dataBinding:createType("Function")

FunctionDataBinding.info:addFields({
    { key = "getter", required = true },
    { key = "setter", required = true },
})

function FunctionDataBinding:readValue()
    return self.getter()
end

function FunctionDataBinding:writeValue(value)
    self.setter(value)
end
