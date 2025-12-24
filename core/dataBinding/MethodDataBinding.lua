local dataBinding = WowVision.dataBinding

local MethodDataBinding, parent = dataBinding:createType("method")

MethodDataBinding.info:addFields({
    { key = "getter", required = true },
    { key = "setter" }, -- Optional, defaults to getter
})

function MethodDataBinding:get()
    return self.target[self.getter](self.target)
end

function MethodDataBinding:_set(value)
    local setter = self.setter or self.getter
    self.target[setter](self.target, value)
end
