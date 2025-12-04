local Panel, parent = WowVision.ui:CreateElementType("Panel", "Container")

function Panel:initialize()
    parent.initialize(self, "Panel")
    self.direction = "tab"
end
