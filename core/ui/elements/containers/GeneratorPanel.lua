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

function GeneratorPanel:getFocusList()
    local focusList = {}
    local focus = self:getFocus()
    while focus do
        tinsert(focusList, focus)
        if focus.getFocus then
            focus = focus:getFocus()
        else
            break
        end
    end

    return focusList
end

function GeneratorPanel:getNewFocus(a, b)
    local focus = self
    local i = 1
    while 1 do
        local u, v = a[i], b[i]
        if u and v then
            if u == v then
                focus = v
                i = i + 1
            else
                return v, true
            end
        elseif not u and v then
            return v, true
        elseif u and not v then
            return focus, true
        else
            return focus, false
        end
    end
end

function GeneratorPanel:iterate()
    local startTime = debugprofilestop()
    local tree1 = self.tree
    local tree2 = self.generator:generateNode(nil, self.startingElement, tree1, self)
    local focusListFirst = self:getFocusList()
    self:batch()
    -- Single-pass reconciliation (combines old generateCompareNode + reconcile)
    self.generator:reconcileDirect(self, tree1, tree2)
    self:endBatch()
    local endTime = debugprofilestop()
    --print("It took ", endTime - startTime, " ms")
    local focusListSecond = self:getFocusList()
    local newFocus, shouldRefocus = self:getNewFocus(focusListFirst, focusListSecond)
    if shouldRefocus then
        newFocus:refocus()
    end
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
