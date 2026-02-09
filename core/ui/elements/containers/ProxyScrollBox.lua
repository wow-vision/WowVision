local ProxyScrollBox, parent = WowVision.ui:CreateElementType("ProxyScrollBox", "ProxyWidget")
ProxyScrollBox:include(WowVision.SyncedContainer)

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
    parent.initialize(self)
    self:initSyncedContainer()
    self.buttons = {}
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

function ProxyScrollBox:updateButtons()
    self.buttons = { self.frame.ScrollTarget:GetChildren() }
end

function ProxyScrollBox:setCurrentIndex(index)
    if index == self.currentIndex then
        return nil
    end
    self:unfocusCurrent()
    if index < 1 or index > self:getNumEntries() then
        self.currentIndex = -1
        return nil
    end
    local element = self:findElement(index)
    if element then
        self.currentIndex = index
        local child = self:getChildRoot(element)
        self:setChild(child)
        self.childPanel:onUpdate()
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
    self:onSyncedFocus()
end

function ProxyScrollBox:onUnfocus()
    self:onSyncedUnfocus()
end

function ProxyScrollBox:setFrame(frame)
    parent.setFrame(self, frame)
    self.currentIndex = -1
end

function ProxyScrollBox:onUpdate()
    self:onSyncedUpdate()
end
