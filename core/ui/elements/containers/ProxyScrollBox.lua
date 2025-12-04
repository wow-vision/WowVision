local ProxyScrollBox, parent = WowVision.ui:CreateElementType("ProxyScrollBox", "ProxyWidget")

-- Define InfoClass fields at class level
ProxyScrollBox.info:addFields({
    {
        key = "getNumEntries",
        default = function()
            return function(self)
                return self.frame:GetDataProviderSize()
            end
        end,
    },
    { key = "getElement", default = nil },
    {
        key = "getSelectedIndex",
        default = function(self)
            return -1
        end,
    },
    {
        key = "selectedElement",
        default = nil,
        set = function(obj, key, value)
            obj.selectedElement = value
            if not obj.proxyButton or not obj.proxyButton.frame.GetRowData then
                return
            end
            obj.proxyButton.selected = WowVision:recursiveComp(obj.proxyButton.frame:GetRowData(), value)
        end,
    },
    { key = "clicks", default = nil },
    { key = "ordered", default = true },
})

function ProxyScrollBox:initialize()
    parent.initialize(self, "List")
    self.childPanel = WowVision.ui:CreateElement("GeneratorPanel", WowVision.ui.generator)
    self.buttons = {}
    self.currentElement = nil
    self.currentIndex = -1
    self.sync = true
    self.direction = "vertical"

    self:addProp({
        key = "getNumEntries",
        default = function()
            return function(self)
                return self.frame:GetDataProviderSize()
            end
        end,
    })
    self:addProp({
        key = "getElement",
    })
    self:addProp({
        key = "getSelectedIndex",
        default = function(self)
            return -1
        end,
    })
    self:addProp({
        key = "selectedElement",
        default = nil,
        set = function(value)
            self.selectedElement = value
            if not self.proxyButton or not self.proxyButton.frame.GetRowData then
                return
            end
            self.proxyButton.selected = WowVision:recursiveComp(self.proxyButton.frame:GetRowData(), value)
        end,
    })
    self:addProp({
        key = "clicks",
        default = nil,
    })
    self:addProp({
        key = "ordered",
        default = true,
    })

    self.focus = nil
end

function ProxyScrollBox:getFocus()
    if self.childPanel and self.childPanel:getFocused() then
        return self.childPanel
    end
    return nil
end

function ProxyScrollBox:focusCurrent()
    if self.currentElement then
        self.childPanel:focus()
    end
end

function ProxyScrollBox:unfocusCurrent()
    if self.focus then
        self.childPanel:unfocus()
        self.focus = nil
    end
end

function ProxyScrollBox:getGameButton(index)
    if index < self.frame:GetDataIndexBegin() or index > self.frame:GetDataIndexEnd() then
        return nil
    end
    if self.ordered then
        return self.buttons[self.currentIndex - self.frame:GetDataIndexBegin() + 1]
    else
        for _, v in ipairs(self.buttons) do
            if v.GetElementDataIndex and index == v:GetElementDataIndex() then
                return v
            end
        end
    end
    return nil
end

function ProxyScrollBox:getChildRoot(gameButton)
    if gameButton == nil then
        return nil
    end
    local childRoot = self:getElement(gameButton)
    return childRoot
end

function ProxyScrollBox:setChild(root)
    self.childPanel:setStartingElement(root)
end

function ProxyScrollBox:updateButtons()
    self.buttons = { self.frame.ScrollTarget:GetChildren() }
end

function ProxyScrollBox:setCurrentIndex(index)
    if index == self.currentIndex then
        return nil
        --return self.currentElement
    end
    self:unfocusCurrent()
    if index < 1 or index > self:getNumEntries() then
        self.currentElement = nil
        self.currentIndex = -1
        return nil
    end
    local element = self:findElement(index)
    if element then
        self.currentElement = element:GetData()
        self.currentIndex = index
        local child = self:getChildRoot(element)
        self:setChild(child)
    end
end

function ProxyScrollBox:findElement(index)
    if index < 1 or index > self:getNumEntries() then
        return nil
    end
    self.frame:ScrollToElementDataIndex(index)
    self:updateButtons()
    if self.ordered then
        local gameButton = self.buttons[index - self.frame:GetDataIndexBegin() + 1]
        return gameButton
    end
    local direction = 1
    local finalIndex = self.frame:GetDataIndexEnd()
    if index < self.currentIndex then
        direction = -1
        finalIndex = self.frame:GetDataIndexBegin()
    end
    for _, button in ipairs(self.buttons) do
        if button.GetElementDataIndex and button:GetElementDataIndex() == index then
            return button
        end
    end
    error("Error finding corresponding ScrollBox button for index" .. index)
end

function ProxyScrollBox:setupChildElement(index)
    if self:getFocused() then
        self.childPanel:unfocus()
    end
    local gameButton = self:getGameButton(index)
    local childRoot = self:getChildRoot(gameButton)
    if not childRoot then
        return nil
    end
    self:setChild(childRoot)
end

function ProxyScrollBox:onFocus(key, newlyFocused)
    self:updateButtons()
    if self.currentIndex < 1 or self.currentIndex > self:getNumEntries() then
        self:setCurrentIndex(1)
    end
end

function ProxyScrollBox:onUnfocus()
    self.childPanel:unfocus()
    self:setChild(nil)
    self.currentElement = nil
    self.currentIndex = -1
end

function ProxyScrollBox:setFrame(frame)
    parent.setFrame(self, frame)
    self.currentElement = nil
    self.currentIndex = -1
end

function ProxyScrollBox:onUpdate()
    self.childPanel:onUpdate()
end

function ProxyScrollBox:getDirectionKeys()
    if self.direction == "vertical" then
        return "up", "down"
    elseif self.direction == "horizontal" then
        return "left", "right"
    elseif self.direction == "tab" then
        return "previous", "next"
    elseif self.direction == "grid" then
        return "up", "right", "down", "left"
    end
    return nil
end

function ProxyScrollBox:isContainer()
    return true
end
