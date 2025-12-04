local Context, parent = WowVision.ui:CreateElementType("Context", "Container")

function Context:initialize(key)
    parent.initialize(self, key)
    self.layout = true
    self.shouldAnnounce = false
    self.direction = nil
end
