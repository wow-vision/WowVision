local Context, parent = WowVision.ui:CreateElementType("HorizontalContext", "Context")

function Context:initialize()
    parent.initialize(self)
    self.direction = "control-tab"
    self.wrap = true
end

function Context:add(element, index)
    parent.add(self, element, index)
    self:setFocus(element)
end

function Context:onRemove()
    for i = #self.children, 1, -1 do
        self:remove(self.children[i])
    end
end
