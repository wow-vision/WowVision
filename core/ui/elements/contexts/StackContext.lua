local Context, parent = WowVision.ui:CreateElementType("StackContext", "Context")

Context.preserveChildNodes = true

function Context:initialize()
    parent.initialize(self)
end

function Context:getDesiredFocus()
    if #self.children > 0 then
        return self.children[#self.children]
    end
    return nil
end

function Context:getNavigatorChildren()
    local result = {}
    for i, child in ipairs(self.children) do
        result[i] = { index = i, element = child }
    end
    return result
end

function Context:add(element, index)
    parent.add(self, element, index)
    element:setContext(self)
end

function Context:addGenerated(element, index, generator)
    local panel = WowVision.ui:CreateElement("GeneratorPanel", {
        generator = generator or WowVision.ui.generator,
        startingElement = element,
    })
    self:add(panel, index)
end

function Context:remove(element)
    if #self.children <= 0 then
        return
    end
    if element ~= self.children[#self.children] then
        return
    end
    parent.remove(self, element)
end

function Context:pop()
    if #self.children > 0 then
        local peak = self.children[#self.children]
        self:remove(peak)
        return peak
    end
    return nil
end

function Context:onRemove()
    while #self.children > 0 do
        self:pop()
    end
end
