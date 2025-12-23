local dataBinding = WowVision.dataBinding

local PropertyDataBinding, parent = dataBinding:createType("name")

PropertyDataBinding.info:addFields({
    { key = "key" },
})

function PropertyDataBinding:initialize(config)
    parent.initialize(self, config)
    -- Handle both old format (name) and new format (getName)
    self.key = config.name or config.getName or config.key
end

function PropertyDataBinding:get()
    return self.target[self.key]
end

function PropertyDataBinding:_set(value)
    self.target[self.key] = value
end
