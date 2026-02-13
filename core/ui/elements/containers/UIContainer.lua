local Container, parent = WowVision.ui:CreateElementType("Container", "Widget")

-- Define InfoClass fields at class level
Container.info:addFields({
    { key = "direction", default = "vertical" },
    { key = "wrap", default = false },
})

function Container:initialize()
    parent.initialize(self)
    self.children = {}
end

function Container:setupUniqueBindings() end

function Container:add(child, index)
    if self:getBatching() then
        child:batch()
    end
    local index = index or #self.children + 1
    child:setParent(self)
    child:setContext(self.context)
    tinsert(self.children, index, child)
    if child.onAdd then
        child:onAdd()
    end
    if not self:getBatching() then
        self:updateIndexes()
    end
end

function Container:remove(child)
    local childIndex = -1
    for i, v in ipairs(self.children) do
        if v == child then
            childIndex = i
            break
        end
    end
    if childIndex < 1 then
        error("Attempted to remove element from container that does not exist")
    end
    table.remove(self.children, childIndex)
    self.children[child] = nil
    if child.onRemove then
        child:onRemove()
    end
    child:unfocus()

    if not self:getBatching() then
        self:updateIndexes()
    else
        child:endBatch()
    end
end

function Container:getChildren()
    return self.children
end

function Container:getNavigatorChildren()
    local children = self:getChildren()
    local result = {}
    for i, child in ipairs(children) do
        result[i] = { index = i, element = child }
    end
    return result
end

function Container:updateIndexes()
    for i, v in ipairs(self.children) do
        self.children[v] = i
    end
end

function Container:reorderChildren(orderedChildren)
    -- Build a set of provided children for quick lookup
    local providedSet = {}
    for _, child in ipairs(orderedChildren) do
        providedSet[child] = true
    end

    -- Start with the ordered children
    local newChildren = {}
    for _, child in ipairs(orderedChildren) do
        tinsert(newChildren, child)
    end

    -- Append any children not in the provided list (preserve their relative order)
    for _, child in ipairs(self.children) do
        if not providedSet[child] then
            tinsert(newChildren, child)
        end
    end

    self.children = newChildren
    self:updateIndexes()
end

function Container:batch()
    parent.batch(self)
    for _, child in ipairs(self.children) do
        child:batch()
    end
end

function Container:endBatch()
    parent.endBatch(self)
    self:updateIndexes()
    for _, child in ipairs(self.children) do
        child:endBatch()
    end
end

function Container:onFocus(key, newlyFocused)
    -- Container's own activation only; child focus is managed by Navigator
end

function Container:onUnfocus()
    -- Cascade unfocus to all focused children for binding cleanup
    for _, child in ipairs(self.children) do
        if child:getFocused() then
            child:unfocus()
        end
    end
end

function Container:onUpdate() end

function Container:update()
    parent.update(self)
    for _, child in ipairs(self.children) do
        child:update()
    end
end

function Container:getDirectionKeys()
    if self.direction == "vertical" then
        return "up", "down"
    elseif self.direction == "horizontal" then
        return "left", "right"
    elseif self.direction == "tab" then
        return "previous", "next"
    elseif self.direction == "control-tab" then
        return "previousWindow", "nextWindow"
    elseif self.direction == "grid" then
        return "up", "right", "down", "left"
    end
    return nil
end

function Container:getDesiredFocus()
    return nil
end

function Container:isContainer()
    return true
end
