local dataBinding = WowVision.dataBinding

local PropertyDataBinding, parent = dataBinding:createType("property")

PropertyDataBinding.info:addFields({
    { key = "property", required = true },
})

function PropertyDataBinding:get()
    return self.target[self.property]
end

function PropertyDataBinding:_set(value)
    self.target[self.property] = value
end
