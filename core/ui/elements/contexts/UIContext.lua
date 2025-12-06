local Context, parent = WowVision.ui:CreateElementType("Context", "Container")

-- Override defaults for Context
-- Note: direction must be false (not nil) because pairs() skips nil values in updateFields,
-- so nil would leave the inherited "vertical" default from Container
Context.info:updateFields({
    { key = "layout", default = true },
    { key = "shouldAnnounce", default = false },
    { key = "direction", default = false },
})

function Context:initialize()
    parent.initialize(self)
end
