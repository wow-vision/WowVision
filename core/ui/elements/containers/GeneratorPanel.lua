local GeneratorPanel, parent = WowVision.ui:CreateElementType("GeneratorPanel", "Panel")

function GeneratorPanel:initialize(generator, startingElement)
    parent.initialize(self)
    self.generator = generator
    self:setStartingElement(startingElement)
    self.tree = nil
    self.layout = true
    self.shouldAnnounce = false
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
    local tree2 = self.generator:generateNode(nil, self.startingElement, tree1)
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
