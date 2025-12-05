local Context, parent = WowVision.ui:CreateElementType("Context", "Container")

-- Override defaults for Context
Context.info:updateFields({
    { key = "layout", default = true },
    { key = "shouldAnnounce", default = false },
    { key = "direction", default = nil },
})

function Context:initialize()
    parent.initialize(self)
end
