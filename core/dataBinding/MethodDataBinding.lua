local dataBinding = WowVision.dataBinding

local MethodDataBinding, parent = dataBinding:createType("Method")

MethodDataBinding.info:addFields({
    { key = "target", required = true },
    { key = "getter", required = true },
    { key = "setter", required = true },
})

function MethodDataBinding:readValue()
    return self.target[self.getter](self.target)
end

function MethodDataBinding:writeValue(value)
    self.target[self.setter](self.target, value)
end
