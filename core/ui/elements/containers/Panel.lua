local Panel, parent = WowVision.ui:CreateElementType("Panel", "Container")

function Panel:initialize()
    parent.initialize(self)
    self.direction = "tab"
end
