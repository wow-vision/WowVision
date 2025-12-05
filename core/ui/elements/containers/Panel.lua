local Panel, parent = WowVision.ui:CreateElementType("Panel", "Container")

-- Override default direction for Panel
Panel.info:updateFields({
    { key = "direction", default = "tab" },
})

function Panel:initialize()
    parent.initialize(self)
end
