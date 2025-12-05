local Context, parent = WowVision.ui:CreateElementType("Context", "Container")

function Context:initialize()
    parent.initialize(self)
    self.layout = true
    self.shouldAnnounce = false
    self.direction = nil
end
