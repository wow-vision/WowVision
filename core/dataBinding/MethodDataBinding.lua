local dataBinding = WowVision.dataBinding

local MethodDataBinding, parent = dataBinding:createType("function")

MethodDataBinding.info:addFields({
    { key = "getter" },
    { key = "setter" },
})

function MethodDataBinding:initialize(config)
    parent.initialize(self, config)
    -- Handle both old format (name) and new format (getName/setName)
    self.getter = config.name or config.getName or config.getter
    self.setter = config.setName or config.name or config.getName or config.setter or self.getter
end

function MethodDataBinding:get()
    return self.target[self.getter](self.target)
end

function MethodDataBinding:_set(value)
    self.target[self.setter](self.target, value)
end
