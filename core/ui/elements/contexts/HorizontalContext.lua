local Context, parent = WowVision.ui:CreateElementType("HorizontalContext", "Context")

Context.preserveChildNodes = true

-- Override defaults for HorizontalContext
Context.info:updateFields({
    { key = "direction", default = "control-tab" },
    { key = "wrap", default = true },
})

function Context:initialize()
    parent.initialize(self)
end

function Context:getDesiredFocus()
    if #self.children > 0 then
        return self.children[#self.children]
    end
    return nil
end

function Context:add(element, index)
    parent.add(self, element, index)
end

function Context:onRemove()
    for i = #self.children, 1, -1 do
        self:remove(self.children[i])
    end
end
