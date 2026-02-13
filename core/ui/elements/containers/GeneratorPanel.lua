local GeneratorPanel, parent = WowVision.ui:CreateElementType("GeneratorPanel", "Panel")

-- Define InfoClass fields at class level
GeneratorPanel.info:addFields({
    { key = "generator", default = nil, compareMode = "direct" },
    {
        key = "startingElement",
        default = nil,
        set = function(obj, key, value)
            obj:setStartingElement(value)
        end,
    },
})

-- Override inherited defaults
GeneratorPanel.info:updateFields({
    { key = "layout", default = true },
    { key = "shouldAnnounce", default = false },
})

function GeneratorPanel:initialize()
    parent.initialize(self)
    self.tree = nil
    self.dirtyElements = {} -- tracks which element types need regeneration
end

function GeneratorPanel:onAdd()
    parent.onAdd(self)
    if self.generator then
        self.generator:registerPanel(self)
    end
end

function GeneratorPanel:onRemove()
    if self.generator then
        self.generator:unregisterPanel(self)
    end
    parent.onRemove(self)
end

function GeneratorPanel:iterate()
    local tree1 = self.tree
    local tree2 = self.generator:generateNode(nil, self.startingElement, tree1, self)
    self:batch()
    self.generator:reconcile(self, tree1, tree2)
    self:endBatch()
    self.tree = tree2
end

function GeneratorPanel:setStartingElement(element)
    if element == nil then
        self.startingElement = nil
        return
    end
    if type(element) == "table" then
        self.startingElement = element
    else
        self.startingElement = { element }
    end
end

function GeneratorPanel:onUpdate()
    self:iterate()
end
