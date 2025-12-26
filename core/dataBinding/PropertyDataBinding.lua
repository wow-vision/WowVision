local dataBinding = WowVision.dataBinding

local PropertyDataBinding, parent = dataBinding:createType("Property")
PropertyDataBinding.info:addFields({
    { key = "target", required = true },
    { key = "property", required = true },
})

function PropertyDataBinding:readValue()
    return self.target[self.property]
end

function PropertyDataBinding:writeValue(value)
    self.target[self.property] = value
end
