local BufferGroup, parent = WowVision.buffers:createType("Group")

function BufferGroup:initialize(config)
    parent.initialize(self, config)
    self.wrap = true
end

WowVision.buffers.BufferGroup = BufferGroup
