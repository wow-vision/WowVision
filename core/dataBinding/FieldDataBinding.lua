local dataBinding = WowVision.dataBinding

local FieldDataBinding, parent = dataBinding:createType("field")
FieldDataBinding.info:addFields({
    { key = "target", required = true },
    { key = "field", required = true },
})

function FieldDataBinding:readValue()
    return self.field:get(self.target)
end

function FieldDataBinding:writeValue(value)
    self.field:set(self.target, value)
end
